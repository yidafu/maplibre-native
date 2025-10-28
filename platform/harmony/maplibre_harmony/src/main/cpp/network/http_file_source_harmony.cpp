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
#include <mutex>
#include <atomic>

// HarmonyOS独立CURL事件循环
#include "curl_event_loop.hpp"
#include "utils/logger.h"

using mbgl::harmony::Logger;

namespace {
// handleError(CURLMcode)已移除，现在由CURLEventLoop处理

void handleError(CURLcode code) {
    if (code != CURLE_OK) {
        throw std::runtime_error(std::string("CURL easy error: ") + curl_easy_strerror(code));
    }
}

// 🔒 CURL 全局状态管理（支持多实例）
std::once_flag curlGlobalInitFlag;
std::atomic<int> curlInstanceCount{0};
std::mutex curlGlobalMutex;

void initCURLGlobal() {
    std::call_once(curlGlobalInitFlag, []() {
        Logger::info("Network", "🌐 Initializing CURL global state (first instance)");
        if (curl_global_init(CURL_GLOBAL_ALL)) {
            Logger::error("Network", "Failed to initialize CURL globally");
            throw std::runtime_error("Could not init cURL globally");
        }
        Logger::info("Network", "✅ CURL global state initialized");
    });
    
    int count = curlInstanceCount.fetch_add(1) + 1;
    Logger::debug("Network", "CURL instance count: %d", count);
}

void cleanupCURLGlobal() {
    int count = curlInstanceCount.fetch_sub(1) - 1;
    Logger::debug("Network", "CURL instance count: %d", count);
    
    if (count == 0) {
        std::lock_guard<std::mutex> lock(curlGlobalMutex);
        // 再次检查计数（双重检查锁定）
        if (curlInstanceCount.load() == 0) {
            Logger::info("Network", "🌐 Cleaning up CURL global state (last instance)");
            curl_global_cleanup();
            Logger::info("Network", "✅ CURL global state cleaned up");
        }
    }
}
} // namespace

namespace mbgl {

class HTTPFileSource::Impl {
public:
    Impl(const ResourceOptions &resourceOptions_, const ClientOptions &clientOptions_);
    ~Impl();

    // 移除原有的RunLoop相关方法，使用独立的CURLEventLoop
    // static int handleSocket(CURL *handle, curl_socket_t s, int action, void *userp, void *socketp);
    // static int startTimeout(CURLM *multi, long timeout_ms, void *userp);
    // static void onTimeout(HTTPFileSource::Impl *context);
    // void perform(curl_socket_t s, util::RunLoop::Event event);

    CURL *getHandle();
    void returnHandle(CURL *handle);
    void checkMultiInfo();

    // 使用独立的CURL事件循环
    std::unique_ptr<harmony::CURLEventLoop> curlEventLoop;

    // CURL multi handle - 现在由CURLEventLoop管理
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

// 外部函数供 CURLEventLoop 调用
// 这个函数桥接 CURLEventLoop 和 HTTPRequest::handleResult
extern "C" void handleHTTPRequestResult(void* request, CURLcode code) {
    if (request) {
        HTTPRequest* httpRequest = static_cast<HTTPRequest*>(request);
        httpRequest->handleResult(code);
    }
}

HTTPFileSource::Impl::Impl(const ResourceOptions &resourceOptions_, const ClientOptions &clientOptions_)
    : resourceOptions(resourceOptions_.clone()),
      clientOptions(clientOptions_.clone()) {
    
    // 🔒 初始化 CURL 全局状态（支持多实例）
    try {
        initCURLGlobal();
    } catch (const std::exception& e) {
        Logger::error("Network", "Failed to initialize CURL: %s", e.what());
        throw;
    }

    share = curl_share_init();

    // 创建独立的CURL事件循环
    try {
        // 默认使用简单轮询模式（稳定可靠）
        auto mode = harmony::CURLEventLoop::Mode::SimplePolling;
        
        const char* curl_mode_env = getenv("CURL_MODE");
        if (curl_mode_env && strcmp(curl_mode_env, "event") == 0) {
            mode = harmony::CURLEventLoop::Mode::EventDriven;
        }
        
        curlEventLoop = std::make_unique<harmony::CURLEventLoop>(mode);
        curlEventLoop->start();
        
        // 获取multi handle（由CURLEventLoop管理）
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
    // 停止CURL事件循环
    if (curlEventLoop) {
        curlEventLoop->stop();
        curlEventLoop.reset();
    }
    
    // 清理CURL句柄队列
    while (!handles.empty()) {
        curl_easy_cleanup(handles.front());
        handles.pop();
    }
    
    // 清理CURL share handle
    if (share) {
        curl_share_cleanup(share);
        share = nullptr;
    }
    
    // 🔒 清理CURL全局状态（支持多实例）
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

// perform方法已移除，现在由CURLEventLoop处理socket事件

// handleSocket方法已移除，现在由CURLEventLoop处理

// onTimeout方法已移除，现在由CURLEventLoop处理

// startTimeout方法已移除，现在由CURLEventLoop处理

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
      resource(std::move(resource_)),
      callback(std::move(callback_)),
      handle(context->getHandle()) {
    
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

        // 🔍 诊断：记录请求信息
        Logger::info("HTTP", "📤 Sending Request:");
        Logger::info("HTTP", "  URL: %s", resource.url.c_str());
        Logger::info("HTTP", "  Request: %p", this);
        Logger::info("HTTP", "  CURL Handle: %p", handle);
        if (resource.priorEtag) {
            Logger::debug("HTTP", "  Prior ETag: %s", resource.priorEtag->c_str());
        }
        if (resource.priorModified) {
            Logger::debug("HTTP", "  Prior Modified: %lld", *resource.priorModified);
        }

        // Start requesting the information using CURLEventLoop
        if (context->curlEventLoop) {
            bool success = context->curlEventLoop->addHandle(handle);
            if (!success) {
                Logger::error("Network", "❌ Failed to add handle to CURLEventLoop");
                throw std::runtime_error("Failed to add handle to CURLEventLoop");
            }
            Logger::debug("HTTP", "  ✅ Added to CURLEventLoop");
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
    // 清除CURL userp指针，防止回调访问已销毁对象
    if (handle) {
        curl_easy_setopt(handle, CURLOPT_WRITEDATA, nullptr);
        curl_easy_setopt(handle, CURLOPT_HEADERDATA, nullptr);
        curl_easy_setopt(handle, CURLOPT_PRIVATE, nullptr);
    }
    
    // 从CURLEventLoop移除CURL句柄
    if (context && context->curlEventLoop && handle) {
        bool success = context->curlEventLoop->removeHandle(handle);
        if (!success) {
            Logger::warn("Network", "Error removing CURL handle from CURLEventLoop");
        }
        
        // 等待CURL操作完全停止
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
    
    // 返回句柄到池中
    if (context && handle) {
        context->returnHandle(handle);
        handle = nullptr;
    }
    
    // 清理HTTP头
    if (headers) {
        curl_slist_free_all(headers);
        headers = nullptr;
    }
}

size_t HTTPRequest::writeCallback(void *const contents, const size_t size, const size_t nmemb, void *userp) {
    if (!userp) {
        return 0;
    }
    
    auto impl = reinterpret_cast<HTTPRequest *>(userp);
    
    try {
        if (!impl->data) {
            impl->data = std::make_shared<std::string>();
        }

        impl->data->append(static_cast<char *>(contents), size * nmemb);
        return size * nmemb;
    } catch (...) {
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
    if (!userp) {
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
    // 🔍 诊断：记录结果处理开始
    Logger::info("HTTP", "📥 Processing Result:");
    Logger::info("HTTP", "  Request: %p", this);
    Logger::info("HTTP", "  URL: %s", resource.url.c_str());
    Logger::info("HTTP", "  CURLcode: %d (%s)", code, curl_easy_strerror(code));
    
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
    
    // 🔍 诊断：记录响应状态
    Logger::info("HTTP", "📊 Response Status:");
    if (response->error) {
        Logger::warn("HTTP", "  Error: %s", response->error->message.c_str());
    } else if (response->notModified) {
        Logger::info("HTTP", "  Status: Not Modified (304)");
    } else if (response->noContent) {
        Logger::info("HTTP", "  Status: No Content");
    } else if (response->data) {
        Logger::info("HTTP", "  Status: Success, Data size: %zu bytes", response->data->size());
    } else {
        Logger::warn("HTTP", "  Status: Unknown/Empty");
    }
    
    // Use AsyncTask to dispatch callback to the correct RunLoop thread
    // This ensures the callback runs on the thread where HTTPRequest was created
    Logger::debug("HTTP", "🔄 Dispatching callback to RunLoop thread...");
    async.send();
    Logger::debug("HTTP", "✅ Callback dispatched");
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
