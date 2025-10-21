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

#include <curl/curl.h>

#include <dlfcn.h>
#include <queue>
#include <cassert>
#include <cstring>
#include <cstdio>
#include <optional>

// HarmonyOS独立CURL事件循环
#include "curl_event_loop.hpp"

#include <hilog/log.h>
#define HTTP_LOG(...) OH_LOG_Print(LOG_APP, LOG_INFO, 0xA00000, "HTTPFileSource", __VA_ARGS__)

namespace {
// handleError(CURLMcode)已移除，现在由CURLEventLoop处理

void handleError(CURLcode code) {
    if (code != CURLE_OK) {
        throw std::runtime_error(std::string("CURL easy error: ") + curl_easy_strerror(code));
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
    
    // 定时器用于定期检查CURL消息
    util::Timer checkTimer;

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
    static size_t writeCallback(void *contents, size_t size, size_t nmemb, void *userp);

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
};

HTTPFileSource::Impl::Impl(const ResourceOptions &resourceOptions_, const ClientOptions &clientOptions_)
    : resourceOptions(resourceOptions_.clone()),
      clientOptions(clientOptions_.clone()) {
    
    // 第一行就打印，确认代码执行
    fprintf(stderr, "\n\n*** HTTPFileSource::Impl CONSTRUCTOR HARMONY CALLED ***\n\n");
    fflush(stderr);
    
    HTTP_LOG("========== HTTPFileSource::Impl CONSTRUCTOR START ==========");
    
    if (curl_global_init(CURL_GLOBAL_ALL)) {
        HTTP_LOG("CURL global init FAILED!");
        throw std::runtime_error("Could not init cURL");
    }
    HTTP_LOG("CURL global init SUCCESS");

    share = curl_share_init();
    HTTP_LOG("CURL share init: %{public}p", share);

    // 创建独立的CURL事件循环
    try {
        curlEventLoop = std::make_unique<harmony::CURLEventLoop>();
        HTTP_LOG("CURLEventLoop created successfully");
        
        // 启动事件循环
        curlEventLoop->start();
        HTTP_LOG("CURLEventLoop started successfully");
        
        // 获取multi handle（由CURLEventLoop管理）
        multi = curlEventLoop->getMultiHandle();
        HTTP_LOG("CURL multi handle obtained: %{public}p", multi);
        
        // 启动定时器定期检查CURL消息（在mbgl::RunLoop上运行）
        checkTimer.start(mbgl::Milliseconds(100), mbgl::Milliseconds(100), [this]() {
            this->checkMultiInfo();
        });
        HTTP_LOG("Check timer started for processing CURL messages");
        
    } catch (const std::exception& e) {
        HTTP_LOG("Failed to create CURLEventLoop: %{public}s", e.what());
        if (share) {
            curl_share_cleanup(share);
            share = nullptr;
        }
        curl_global_cleanup();
        throw;
    }
    
    HTTP_LOG("========== HTTPFileSource::Impl CONSTRUCTOR END ==========");
}

HTTPFileSource::Impl::~Impl() {
    HTTP_LOG("========== HTTPFileSource::Impl DESTRUCTOR START ==========");
    
    // 1. 停止检查定时器
    HTTP_LOG("Stopping check timer...");
    checkTimer.stop();
    HTTP_LOG("Check timer stopped");
    
    // 2. 停止CURL事件循环（这会自动清理所有活跃的CURL句柄）
    HTTP_LOG("Stopping CURLEventLoop...");
    if (curlEventLoop) {
        curlEventLoop->stop();
        HTTP_LOG("CURLEventLoop stopped successfully");
        curlEventLoop.reset();
        HTTP_LOG("CURLEventLoop destroyed");
    }
    
    // 2. 清理CURL句柄队列
    HTTP_LOG("Cleaning up CURL handles queue...");
    while (!handles.empty()) {
        curl_easy_cleanup(handles.front());
        handles.pop();
    }
    
    // 3. 清理CURL share handle
    HTTP_LOG("Cleaning up CURL share handle...");
    if (share) {
        curl_share_cleanup(share);
        share = nullptr;
    }
    
    // 4. 清理CURL全局状态
    HTTP_LOG("Cleaning up CURL global state...");
    curl_global_cleanup();
    
    HTTP_LOG("========== HTTPFileSource::Impl DESTRUCTOR END ==========");
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
                // This should never happen, because there are no other message types.
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
    HTTP_LOG("========== HTTPRequest CONSTRUCTOR START ==========");
    HTTP_LOG("URL: %{public}s", resource.url.c_str());
    HTTP_LOG("CURL handle: %{public}p", handle);
    
    if (resource.dataRange) {
        const std::string header = std::string("Range: bytes=") + std::to_string(resource.dataRange->first) +
                                   std::string("-") + std::to_string(resource.dataRange->second);
        headers = curl_slist_append(headers, header.c_str());
    }

    // If there's already a response, set the correct etags/modified headers to
    // make sure we are getting a 304 response if possible. This avoids
    // redownloading unchanged data.
    if (resource.priorEtag) {
        const std::string header = std::string("If-None-Match: ") + *resource.priorEtag;
        headers = curl_slist_append(headers, header.c_str());
    } else if (resource.priorModified) {
        const std::string time = std::string("If-Modified-Since: ") + util::rfc1123(*resource.priorModified);
        headers = curl_slist_append(headers, time.c_str());
    }

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
#if LIBCURL_VERSION_NUM >= ((7) << 16 | (21) << 8 | 6) // Renamed in 7.21.6
    handleError(curl_easy_setopt(handle, CURLOPT_ACCEPT_ENCODING, "gzip, deflate"));
#else
    handleError(curl_easy_setopt(handle, CURLOPT_ENCODING, "gzip, deflate"));
#endif
    handleError(curl_easy_setopt(handle, CURLOPT_USERAGENT, "MapLibreNative/1.0"));
    handleError(curl_easy_setopt(handle, CURLOPT_SHARE, context->share));

    // Start requesting the information using CURLEventLoop.
    HTTP_LOG("About to add CURL handle to CURLEventLoop - handle=%{public}p", handle);
    if (context->curlEventLoop) {
        bool success = context->curlEventLoop->addHandle(handle);
        if (!success) {
            HTTP_LOG("ERROR: Failed to add handle to CURLEventLoop");
            throw std::runtime_error("Failed to add handle to CURLEventLoop");
        }
        HTTP_LOG("CURL handle added to CURLEventLoop successfully");
    } else {
        HTTP_LOG("ERROR: CURLEventLoop is null");
        throw std::runtime_error("CURLEventLoop is null");
    }
    HTTP_LOG("========== HTTPRequest CONSTRUCTOR END ==========");
}

HTTPRequest::~HTTPRequest() {
    HTTP_LOG("========== HTTPRequest DESTRUCTOR START ==========");
    HTTP_LOG("URL: %{public}s", resource.url.c_str());
    HTTP_LOG("Context: %{public}p, Handle: %{public}p", context, handle);
    
    // 1. 安全地从CURLEventLoop移除CURL句柄
    if (context && context->curlEventLoop && handle) {
        HTTP_LOG("Removing CURL handle from CURLEventLoop...");
        bool success = context->curlEventLoop->removeHandle(handle);
        if (!success) {
            HTTP_LOG("Warning: Error removing CURL handle from CURLEventLoop");
        } else {
            HTTP_LOG("CURL handle removed from CURLEventLoop successfully");
        }
    }
    
    // 2. 返回句柄到池中
    if (context && handle) {
        HTTP_LOG("Returning handle to pool...");
        context->returnHandle(handle);
        handle = nullptr;
    }
    
    // 3. 清理HTTP头
    if (headers) {
        HTTP_LOG("Cleaning up HTTP headers...");
        curl_slist_free_all(headers);
        headers = nullptr;
    }
    
    HTTP_LOG("========== HTTPRequest DESTRUCTOR END ==========");
}

// This function is called when we have new data for a request. We just append
// it to the string containing the previous data.
size_t HTTPRequest::writeCallback(void *const contents, const size_t size, const size_t nmemb, void *userp) {
    assert(userp);
    auto impl = reinterpret_cast<HTTPRequest *>(userp);

    if (!impl->data) {
        impl->data = std::make_shared<std::string>();
    }

    impl->data->append(static_cast<char *>(contents), size * nmemb);
    return size * nmemb;
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
    assert(userp);
    auto baton = reinterpret_cast<HTTPRequest *>(userp);

    if (!baton->response) {
        baton->response = std::make_unique<Response>();
    }

    // NOLINTBEGIN(bugprone-assignment-in-if-condition)
    const size_t length = size * nmemb;
    size_t begin = std::string::npos;
    if ((begin = headerMatches("last-modified: ", buffer, length)) != std::string::npos) {
        // Always overwrite the modification date; We might already have a value
        // here from the Date header, but this one is more accurate.
        const std::string value{buffer + begin, length - begin - 2}; // remove \r\n
        baton->response->modified = Timestamp{Seconds(curl_getdate(value.c_str(), nullptr))};
    } else if ((begin = headerMatches("etag: ", buffer, length)) != std::string::npos) {
        baton->response->etag = std::string(buffer + begin,
                                            length - begin - 2); // remove \r\n
    } else if ((begin = headerMatches("cache-control: ", buffer, length)) != std::string::npos) {
        const std::string value{buffer + begin, length - begin - 2}; // remove \r\n
        const auto cc = http::CacheControl::parse(value);
        baton->response->expires = cc.toTimePoint();
        baton->response->mustRevalidate = cc.mustRevalidate;
    } else if ((begin = headerMatches("expires: ", buffer, length)) != std::string::npos) {
        const std::string value{buffer + begin, length - begin - 2}; // remove \r\n
        baton->response->expires = Timestamp{Seconds(curl_getdate(value.c_str(), nullptr))};
    } else if ((begin = headerMatches("retry-after: ", buffer, length)) != std::string::npos) {
        baton->retryAfter = std::string(buffer + begin,
                                        length - begin - 2); // remove \r\n
    } else if ((begin = headerMatches("x-rate-limit-reset: ", buffer, length)) != std::string::npos) {
        baton->xRateLimitReset = std::string(buffer + begin,
                                             length - begin - 2); // remove \r\n
    }
    // NOLINTEND(bugprone-assignment-in-if-condition)

    return length;
}

void HTTPRequest::handleResult(CURLcode code) {
    // Make sure a response object exists in case we haven't got any headers or content.
    if (!response) {
        response = std::make_unique<Response>();
    }

    using Error = Response::Error;

    // Add human-readable error code
    if (code != CURLE_OK) {
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

    // Calling `callback` may result in deleting `this`. Copy data to temporaries first.
    auto callback_ = callback;
    auto response_ = *response;
    callback_(response_);
}

HTTPFileSource::HTTPFileSource(const ResourceOptions &resourceOptions, const ClientOptions &clientOptions)
    : impl(std::make_unique<Impl>(resourceOptions, clientOptions)) {
    HTTP_LOG("========== HTTPFileSource CONSTRUCTOR (HarmonyOS) ==========");
    HTTP_LOG("This is the HarmonyOS-specific HTTPFileSource implementation");
    HTTP_LOG("impl address: %{public}p", impl.get());
    
    // 直接打印到stderr以确认代码被执行
    fprintf(stderr, "\n\n");
    fprintf(stderr, "**************************************************\n");
    fprintf(stderr, "*** HTTPFileSource HARMONY CONSTRUCTOR CALLED ***\n");
    fprintf(stderr, "**************************************************\n");
    fprintf(stderr, "\n\n");
    fflush(stderr);
}

HTTPFileSource::~HTTPFileSource() = default;

std::unique_ptr<AsyncRequest> HTTPFileSource::request(const Resource &resource, Callback callback) {
    HTTP_LOG("========== HTTPFileSource::request() START ==========");
    HTTP_LOG("Resource URL: %{public}s", resource.url.c_str());
    HTTP_LOG("Resource kind: %{public}d", static_cast<int>(resource.kind));
    HTTP_LOG("Creating HTTPRequest...");
    
    // 直接打印确认代码执行
    fprintf(stderr, "\n*** HTTPFileSource::request() HARMONY CALLED for: %s ***\n", resource.url.c_str());
    fflush(stderr);
    
    auto request = std::make_unique<HTTPRequest>(impl.get(), resource, callback);
    
    HTTP_LOG("HTTPRequest created: %{public}p", request.get());
    HTTP_LOG("========== HTTPFileSource::request() END ==========");
    
    return request;
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
