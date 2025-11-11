#include <algorithm>
#include <mbgl/storage/http_file_source.hpp>
#include <mbgl/storage/resource_options.hpp>
#include <mbgl/storage/resource.hpp>
#include <mbgl/storage/response.hpp>
#include <mbgl/util/client_options.hpp>
#include <mbgl/util/logging.hpp>

#include <mbgl/util/util.hpp>
#include <mbgl/util/run_loop.hpp>
#include <mbgl/util/string.hpp>
#include <mbgl/util/timer.hpp>
#include <mbgl/util/chrono.hpp>
#include <mbgl/util/http_header.hpp>
#include <mbgl/util/async_task.hpp>

#include <curl/curl.h>

#include <dlfcn.h>
#include <queue>
#include <cassert>
#include <cstring>
#include <cstdio>
#include <cstdlib>
#include <optional>
#include <memory>
#include <mutex>
#include <atomic>
#include <thread>
#include <condition_variable>

// HarmonyOS standalone CURL event loop
#include "curl_event_loop.hpp"
#include "http_request_config.hpp"
#include "url_transform_manager.hpp"
#include "utils/logger.h"
#include "utils/anr_detector.hpp"

using mbgl::harmony::Logger;
using mbgl::harmony::ANRDetector;
using mbgl::harmony::HTTPRequestConfig;
using mbgl::harmony::URLTransformManager;

namespace {
// handleError(CURLMcode) removed; handled by CURLEventLoop now

void handleError(CURLcode code) {
    if (code != CURLE_OK) {
        throw std::runtime_error(std::string("CURL easy error: ") + curl_easy_strerror(code));
    }
}

// 🔒 Manage CURL global state (supports multiple instances)
std::once_flag curlGlobalInitFlag;
std::atomic<int> curlInstanceCount{0};
std::mutex curlGlobalMutex;

void initCURLGlobal() {
    std::call_once(curlGlobalInitFlag, []() {
        if (curl_global_init(CURL_GLOBAL_ALL)) {
            Logger::error("Network", "Failed to initialize CURL globally");
            throw std::runtime_error("Could not init cURL globally");
        }
    });
    
    curlInstanceCount.fetch_add(1);
}

void cleanupCURLGlobal() {
    int count = curlInstanceCount.fetch_sub(1) - 1;
    
    if (count == 0) {
        std::lock_guard<std::mutex> lock(curlGlobalMutex);
        // Double-check the count (double-checked locking)
        if (curlInstanceCount.load() == 0) {
            curl_global_cleanup();
        }
    }
}
} // namespace

namespace mbgl {

class HTTPFileSource::Impl {
public:
    Impl(const ResourceOptions &resourceOptions_, const ClientOptions &clientOptions_);
    ~Impl();

    // Legacy RunLoop helpers removed; now use the standalone CURLEventLoop
    // static int handleSocket(CURL *handle, curl_socket_t s, int action, void *userp, void *socketp);
    // static int startTimeout(CURLM *multi, long timeout_ms, void *userp);
    // static void onTimeout(HTTPFileSource::Impl *context);
    // void perform(curl_socket_t s, util::RunLoop::Event event);

    CURL *getHandle();
    void returnHandle(CURL *handle);
    void checkMultiInfo();

    // Use the dedicated CURL event loop
    std::shared_ptr<harmony::CURLEventLoop> curlEventLoop;

    // CURL multi handle — now managed by CURLEventLoop
    CURLM *multi = nullptr;

    // CURL share handles are used for sharing session state (e.g.)
    CURLSH *share = nullptr;

    // A queue that we use for storing reusable CURL easy handles to avoid
    // creating and destroying them all the time.
    std::queue<CURL *> handles;

    void setResourceOptions(ResourceOptions options);
    ResourceOptions getResourceOptions();

    void setClientOptions(ClientOptions options);
    ClientOptions getClientOptions();

    std::shared_ptr<harmony::CURLEventLoop> getEventLoop() const {
        return curlEventLoop;
    }

private:
    mutable std::mutex resourceOptionsMutex;
    mutable std::mutex clientOptionsMutex;
    ResourceOptions resourceOptions;
    ClientOptions clientOptions;
};

class HTTPRequest : public AsyncRequest {
public:
    HTTPRequest(HTTPFileSource::Impl *, Resource, FileSource::Callback);
    ~HTTPRequest() override;

    void handleResult(CURLcode code);

private:
    static size_t headerCallback(char *buffer, size_t size, size_t nmemb, void *userp);
    static size_t writeCallback(void *contents, size_t nmemb, size_t size, void *userp);

    HTTPFileSource::Impl *context = nullptr;
    std::shared_ptr<harmony::CURLEventLoop> eventLoop;
    Resource resource;
    FileSource::Callback callback;

    // Will store the current response.
    std::shared_ptr<std::string> data;
    std::unique_ptr<Response> response;

    std::optional<std::string> retryAfter;
    std::optional<std::string> xRateLimitReset;

    CURL *handle = nullptr;
    curl_slist *headers = nullptr;

    char error[CURL_ERROR_SIZE] = {0};

    // AsyncTask for thread-safe callback dispatch to the correct RunLoop
    util::AsyncTask async{[this] {
        // Calling `callback` may result in deleting `this`. Copy data to temporaries first.
        auto callback_ = callback;
        auto response_ = *response;
        callback_(response_);
    }};
};

// External function invoked by CURLEventLoop.
// Bridges CURLEventLoop and HTTPRequest::handleResult.
extern "C" void handleHTTPRequestResult(void* request, CURLcode code) {
    if (request) {
        HTTPRequest* httpRequest = static_cast<HTTPRequest*>(request);
        httpRequest->handleResult(code);
    }
}

HTTPFileSource::Impl::Impl(const ResourceOptions &resourceOptions_, const ClientOptions &clientOptions_)
    : resourceOptions(resourceOptions_.clone()),
      clientOptions(clientOptions_.clone()) {
    
    // 🔒 Initialize CURL global state (supports multiple instances)
    try {
        initCURLGlobal();
    } catch (const std::exception& e) {
        Logger::error("Network", "Failed to initialize CURL: %s", e.what());
        throw;
    }

    share = curl_share_init();

    // Create the standalone CURLEventLoop
    try {
        // Default to simple polling mode for stability
        auto mode = harmony::CURLEventLoop::Mode::SimplePolling;
        
        const char* curl_mode_env = getenv("CURL_MODE");
        if (curl_mode_env && strcmp(curl_mode_env, "event") == 0) {
            mode = harmony::CURLEventLoop::Mode::EventDriven;
        }
        
        curlEventLoop = std::make_shared<harmony::CURLEventLoop>(mode);
        curlEventLoop->start();
        
        // Obtain the multi handle (owned by CURLEventLoop)
        multi = curlEventLoop->getMultiHandle();
        
    } catch (const std::exception& e) {
        Logger::error("Network", "Failed to create CURLEventLoop: %s", e.what());
        if (share) {
            curl_share_cleanup(share);
            share = nullptr;
        }
        cleanupCURLGlobal();
        throw;
    }
}

HTTPFileSource::Impl::~Impl() {
    // 🔍 ANR monitoring: record HTTP teardown duration
    ANRDetector detector("HTTPFileSource::Impl destructor", 100, 500);
    
    // ⚡ ANR FIX: monitor CURL event loop shutdown.
    // Reason: stop() may wait for active requests to complete and can take time.
    // Solution: use ANRDetector (200 ms threshold) to log slow operations.
    //
    // Note: HarmonyOS standard library lacks a true std::async timeout,
    // but ANRDetector helps surface long-running operations.
    if (curlEventLoop) {
        ANRDetector stopDetector("curlEventLoop->stop", 50, 200);
        auto loopRef = std::move(curlEventLoop);
        loopRef->stop();
    }
    
    // Clean up the CURL handle queue (typically quick)
    while (!handles.empty()) {
        curl_easy_cleanup(handles.front());
        handles.pop();
    }
    
    // Clean up the CURL share handle
    if (share) {
        curl_share_cleanup(share);
        share = nullptr;
    }
    
    // 🔒 Release CURL global state (supports multiple instances)
    cleanupCURLGlobal();
}

CURL *HTTPFileSource::Impl::getHandle() {
    if (!handles.empty()) {
        auto handle = handles.front();
        handles.pop();
        return handle;
    } else {
        return curl_easy_init();
    }
}

void HTTPFileSource::Impl::returnHandle(CURL *handle) {
    curl_easy_reset(handle);
    handles.push(handle);
}

void HTTPFileSource::Impl::checkMultiInfo() {
    CURLMsg *message = nullptr;
    int pending = 0;

    while ((message = curl_multi_info_read(multi, &pending))) {
        switch (message->msg) {
            case CURLMSG_DONE: {
                HTTPRequest *baton = nullptr;
                curl_easy_getinfo(message->easy_handle, CURLINFO_PRIVATE, (char *)&baton);
                assert(baton);
                
                baton->handleResult(message->data.result);
            } break;

            default:
                Logger::error("Network", "Unknown CURL message type: %d", message->msg);
                throw std::runtime_error("CURLMsg returned unknown message type");
        }
    }
}

// perform removed; CURLEventLoop now handles socket events

// handleSocket removed; handled by CURLEventLoop

// onTimeout removed; handled by CURLEventLoop

// startTimeout removed; handled by CURLEventLoop

void HTTPFileSource::Impl::setResourceOptions(ResourceOptions options) {
    std::lock_guard lock(resourceOptionsMutex);
    resourceOptions = options;
}

ResourceOptions HTTPFileSource::Impl::getResourceOptions() {
    std::lock_guard lock(resourceOptionsMutex);
    return resourceOptions.clone();
}

void HTTPFileSource::Impl::setClientOptions(ClientOptions options) {
    std::lock_guard lock(clientOptionsMutex);
    clientOptions = options;
}

ClientOptions HTTPFileSource::Impl::getClientOptions() {
    std::lock_guard lock(clientOptionsMutex);
    return clientOptions.clone();
}

HTTPRequest::HTTPRequest(HTTPFileSource::Impl *context_, Resource resource_, FileSource::Callback callback_)
    : context(context_),
      eventLoop(context_ ? context_->getEventLoop() : nullptr),
      resource(std::move(resource_)),
      callback(std::move(callback_)),
      handle(context_ ? context_->getHandle() : nullptr) {
    if (!context) {
        throw std::runtime_error("HTTPFileSource context is null");
    }

    if (!handle) {
        throw std::runtime_error("Failed to acquire CURL easy handle");
    }

    // Apply URL transforms when a callback is provided.
    // Reference Android: platform/android/.../file_source.cpp:122-124
    // Reference iOS: platform/darwin/src/MLNOfflineStorage.mm:138-141
    auto& transformManager = URLTransformManager::getInstance();
    if (transformManager.hasCallback()) {
        std::string originalUrl = resource.url;
        std::string transformedUrl = transformManager.transform(resource.kind, resource.url);
        
        if (!transformedUrl.empty() && transformedUrl != originalUrl) {
            resource.url = transformedUrl;
        }
    }
    
    if (resource.dataRange) {
        const std::string header = std::string("Range: bytes=") + std::to_string(resource.dataRange->first) +
                                   std::string("-") + std::to_string(resource.dataRange->second);
        headers = curl_slist_append(headers, header.c_str());
    }

    if (resource.priorEtag) {
        const std::string header = std::string("If-None-Match: ") + *resource.priorEtag;
        headers = curl_slist_append(headers, header.c_str());
    } else if (resource.priorModified) {
        const std::string time = std::string("If-Modified-Since: ") + util::rfc1123(*resource.priorModified);
        headers = curl_slist_append(headers, time.c_str());
    }

    // Apply custom HTTP headers.
    // Reference iOS: platform/darwin/core/http_file_source.mm:89-96
    // Reference Android: platform/android/.../HttpRequestImpl.java:115-117
    auto& config = HTTPRequestConfig::getInstance();
    auto customHeaders = config.getCustomHeaders();
    if (!customHeaders.empty()) {
        for (const auto& [key, value] : customHeaders) {
            // Skip User-Agent (configured separately below)
            std::string lowerKey = key;
            std::transform(lowerKey.begin(), lowerKey.end(), lowerKey.begin(), ::tolower);
            if (lowerKey == "user-agent") {
                continue;
            }
            
            const std::string header = key + ": " + value;
            headers = curl_slist_append(headers, header.c_str());
        }
    }
    
    try {
        if (headers) {
            curl_easy_setopt(handle, CURLOPT_HTTPHEADER, headers);
        }

        handleError(curl_easy_setopt(handle, CURLOPT_PRIVATE, this));
        handleError(curl_easy_setopt(handle, CURLOPT_ERRORBUFFER, error));
        handleError(curl_easy_setopt(handle, CURLOPT_FOLLOWLOCATION, 1));
        handleError(curl_easy_setopt(handle, CURLOPT_URL, resource.url.c_str()));
        handleError(curl_easy_setopt(handle, CURLOPT_WRITEFUNCTION, writeCallback));
        handleError(curl_easy_setopt(handle, CURLOPT_WRITEDATA, this));
        handleError(curl_easy_setopt(handle, CURLOPT_HEADERFUNCTION, headerCallback));
        handleError(curl_easy_setopt(handle, CURLOPT_HEADERDATA, this));
#if LIBCURL_VERSION_NUM >= ((7) << 16 | (21) << 8 | 6)
        handleError(curl_easy_setopt(handle, CURLOPT_ACCEPT_ENCODING, "gzip, deflate"));
#else
        handleError(curl_easy_setopt(handle, CURLOPT_ENCODING, "gzip, deflate"));
#endif
        handleError(curl_easy_setopt(handle, CURLOPT_USERAGENT, "MapLibreNative/1.0"));
        handleError(curl_easy_setopt(handle, CURLOPT_SHARE, context->share));

        // Start requesting the information using CURLEventLoop
        if (eventLoop) {
            bool success = eventLoop->addHandle(handle);
            if (!success) {
                Logger::error("Network", "❌ Failed to add handle to CURLEventLoop");
                throw std::runtime_error("Failed to add handle to CURLEventLoop");
            }
        } else {
            Logger::error("Network", "❌ CURLEventLoop is null");
            throw std::runtime_error("CURLEventLoop is null");
        }
        
    } catch (const std::exception& e) {
        Logger::error("Network", "Exception in HTTPRequest constructor: %s", e.what());
        throw;
    }
}

HTTPRequest::~HTTPRequest() {
    // 🔒 CRASH FIX: adjust destruction order to stop callbacks before cleaning resources
    //
    // Issue:
    // Clearing userp before removing the handle allowed CURLEventLoop callbacks
    // (writeCallback/headerCallback) to dereference null pointers.
    //
    // Solution:
    // 1. Remove the handle from CURLEventLoop first (halts new callbacks).
    // 2. Wait briefly so in-flight callbacks complete.
    // 3. Clear userp and release resources.
    
    // Step 1: remove the CURL handle from CURLEventLoop (stop new callbacks)
    if (eventLoop && handle) {
        bool success = eventLoop->removeHandle(handle);
        
        // Step 2: short wait to ensure in-flight callbacks finish
        // Note: keep it brief to avoid ANR while still accommodating callbacks
        std::this_thread::sleep_for(std::chrono::microseconds(100));
    }
    
    // Step 3: safe to clear the userp pointer now
    if (handle) {
        curl_easy_setopt(handle, CURLOPT_WRITEDATA, nullptr);
        curl_easy_setopt(handle, CURLOPT_HEADERDATA, nullptr);
        curl_easy_setopt(handle, CURLOPT_PRIVATE, nullptr);
    }
    
    // Step 4: return the handle to the pool
    if (context && handle) {
        context->returnHandle(handle);
        handle = nullptr;
    }
    
    // Step 5: release HTTP headers
    if (headers) {
        curl_slist_free_all(headers);
        headers = nullptr;
    }

    eventLoop.reset();
}

size_t HTTPRequest::writeCallback(void *const contents, const size_t size, const size_t nmemb, void *userp) {
    // 🔒 CRASH FIX: strengthen null-pointer checks
    if (!userp || !contents) {
        Logger::warn("Network", "writeCallback: null pointer (userp=%p, contents=%p)", userp, contents);
        return 0;
    }
    
    auto impl = reinterpret_cast<HTTPRequest *>(userp);
    
    try {
        // Extra validation to ensure impl points to valid memory.
        // Note: not foolproof, but catches obvious issues.
        if (!impl->data) {
            impl->data = std::make_shared<std::string>();
        }

        impl->data->append(static_cast<char *>(contents), size * nmemb);
        return size * nmemb;
    } catch (const std::exception& e) {
        Logger::error("Network", "writeCallback exception: %s", e.what());
        return 0;
    } catch (...) {
        Logger::error("Network", "writeCallback unknown exception");
        return 0;
    }
}

namespace {
// Compares the beginning of the (non-zero-terminated!) data buffer with the
// (zero-terminated!) header string. If the data buffer contains the header
// string at the beginning, it returns the length of the header string == begin
// of the value, otherwise it returns npos. The comparison of the header is
// ASCII-case-insensitive.
size_t headerMatches(const char *const header, const char *const buffer, const size_t length) {
    const size_t headerLength = strlen(header);
    if (length < headerLength) {
        return std::string::npos;
    }
    size_t i = 0;
    while (i < length && i < headerLength && std::tolower(buffer[i]) == std::tolower(header[i])) {
        i++;
    }
    return i == headerLength ? i : std::string::npos;
}
} // namespace

size_t HTTPRequest::headerCallback(char *const buffer, const size_t size, const size_t nmemb, void *userp) {
    // 🔒 CRASH FIX: enhanced null-pointer validation
    if (!userp || !buffer) {
        Logger::warn("Network", "headerCallback: null pointer (userp=%p, buffer=%p)", userp, buffer);
        return 0;
    }
    
    auto baton = reinterpret_cast<HTTPRequest *>(userp);
    
    try {
        if (!baton->response) {
            baton->response = std::make_unique<Response>();
        }

        const size_t length = size * nmemb;
        size_t begin = std::string::npos;
        if ((begin = headerMatches("last-modified: ", buffer, length)) != std::string::npos) {
            const std::string value{buffer + begin, length - begin - 2};
            baton->response->modified = Timestamp{Seconds(curl_getdate(value.c_str(), nullptr))};
        } else if ((begin = headerMatches("etag: ", buffer, length)) != std::string::npos) {
            baton->response->etag = std::string(buffer + begin, length - begin - 2);
        } else if ((begin = headerMatches("cache-control: ", buffer, length)) != std::string::npos) {
            const std::string value{buffer + begin, length - begin - 2};
            const auto cc = http::CacheControl::parse(value);
            baton->response->expires = cc.toTimePoint();
            baton->response->mustRevalidate = cc.mustRevalidate;
        } else if ((begin = headerMatches("expires: ", buffer, length)) != std::string::npos) {
            const std::string value{buffer + begin, length - begin - 2};
            baton->response->expires = Timestamp{Seconds(curl_getdate(value.c_str(), nullptr))};
        } else if ((begin = headerMatches("retry-after: ", buffer, length)) != std::string::npos) {
            baton->retryAfter = std::string(buffer + begin, length - begin - 2);
        } else if ((begin = headerMatches("x-rate-limit-reset: ", buffer, length)) != std::string::npos) {
            baton->xRateLimitReset = std::string(buffer + begin, length - begin - 2);
        }

        return length;
        
    } catch (...) {
        return 0;
    }
}

void HTTPRequest::handleResult(CURLcode code) {
    // 🔒 CRASH FIX: ensure the object survives while handleResult runs
    // Note: this method may be invoked on the CURLEventLoop thread
    
    // Make sure a response object exists
    if (!response) {
        response = std::make_unique<Response>();
    }

    using Error = Response::Error;

    if (code != CURLE_OK) {
        Logger::warn("Network", "❌ Request failed: %s", curl_easy_strerror(code));
        
        switch (code) {
            case CURLE_COULDNT_RESOLVE_PROXY:
            case CURLE_COULDNT_RESOLVE_HOST:
            case CURLE_COULDNT_CONNECT:
            case CURLE_OPERATION_TIMEDOUT:
                response->error = std::make_unique<Error>(Error::Reason::Connection,
                                                          std::string{curl_easy_strerror(code)} + ": " + error);
                break;

            default:
                response->error = std::make_unique<Error>(Error::Reason::Other,
                                                          std::string{curl_easy_strerror(code)} + ": " + error);
                break;
        }
    } else {
        long responseCode = 0;
        curl_easy_getinfo(handle, CURLINFO_RESPONSE_CODE, &responseCode);

        if (responseCode == 200 || responseCode == 206) {
            if (data) {
                response->data = std::move(data);
            } else {
                response->data = std::make_shared<std::string>();
            }
        } else if (responseCode == 204 || (responseCode == 404 && resource.kind == Resource::Kind::Tile)) {
            response->noContent = true;
        } else if (responseCode == 304) {
            response->notModified = true;
        } else if (responseCode == 404) {
            response->error = std::make_unique<Error>(Error::Reason::NotFound, "HTTP status code 404");
        } else if (responseCode == 429) {
            response->error = std::make_unique<Error>(
                Error::Reason::RateLimit, "HTTP status code 429", http::parseRetryHeaders(retryAfter, xRateLimitReset));
        } else if (responseCode >= 500 && responseCode < 600) {
            response->error = std::make_unique<Error>(Error::Reason::Server,
                                                      std::string{"HTTP status code "} + util::toString(responseCode));
        } else {
            response->error = std::make_unique<Error>(Error::Reason::Other,
                                                      std::string{"HTTP status code "} + util::toString(responseCode));
        }
    }
    
    // 🔍 Diagnostics: log the response status
    if (response->error) {
        Logger::warn("HTTP", "  Error: %s", response->error->message.c_str());
    } else if (response->noContent) {
    } else if (response->data) {
    } else {
        Logger::warn("HTTP", "  Status: Unknown/Empty");
    }
    
    // Use AsyncTask to dispatch callback to the correct RunLoop thread
    // This ensures the callback runs on the thread where HTTPRequest was created
    async.send();
}

HTTPFileSource::HTTPFileSource(const ResourceOptions &resourceOptions, const ClientOptions &clientOptions)
    : impl(std::make_unique<Impl>(resourceOptions, clientOptions)) {
}

HTTPFileSource::~HTTPFileSource() = default;

std::unique_ptr<AsyncRequest> HTTPFileSource::request(const Resource &resource, Callback callback) {
    try {
        if (!impl) {
            Logger::error("Network", "HTTPFileSource impl is null");
            return nullptr;
        }
        
        return std::make_unique<HTTPRequest>(impl.get(), resource, callback);
        
    } catch (const std::exception& e) {
        Logger::error("Network", "Exception in HTTPFileSource::request: %s", e.what());
        return nullptr;
    } catch (...) {
        Logger::error("Network", "Unknown exception in HTTPFileSource::request");
        return nullptr;
    }
}

void HTTPFileSource::setResourceOptions(ResourceOptions options) {
    impl->setResourceOptions(options.clone());
}

ResourceOptions HTTPFileSource::getResourceOptions() {
    return impl->getResourceOptions();
}

void HTTPFileSource::setClientOptions(ClientOptions options) {
    impl->setClientOptions(options.clone());
}

ClientOptions HTTPFileSource::getClientOptions() {
    return impl->getClientOptions();
}

} // namespace mbgl
