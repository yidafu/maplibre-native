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
#include <cstdlib>
#include <optional>
#include <map>

#include "utils/logger.h"

using mbgl::harmony::Logger;

namespace {

void handleError(CURLcode code) {
    if (code != CURLE_OK) {
        throw std::runtime_error(std::string("CURL easy error: ") + curl_easy_strerror(code));
    }
}

void handleError(CURLMcode code) {
    if (code != CURLM_OK) {
        throw std::runtime_error(std::string("CURL multi error: ") + curl_multi_strerror(code));
    }
}

} // namespace

namespace mbgl {

class HTTPFileSource::Impl {
public:
    Impl(const ResourceOptions &resourceOptions_, const ClientOptions &clientOptions_);
    ~Impl();

    // CURL socket 事件处理（集成到 RunLoop）
    void perform(curl_socket_t socket, util::RunLoop::Event event);
    void onTimeout();
    
    // CURL 回调
    static int handleSocket(CURL *handle, curl_socket_t s, int action, void *userp, void *socketp);
    static int handleTimer(CURLM *multi, long timeout_ms, void *userp);

    CURL *getHandle();
    void returnHandle(CURL *handle);
    void checkMultiInfo();

    // CURL multi handle - 现在由 RunLoop 管理
    CURLM *multi = nullptr;

    // CURL share handles for sharing session state
    CURLSH *share = nullptr;

    // Reusable CURL easy handles
    std::queue<CURL *> handles;
    
    // Timeout timer（使用 RunLoop 的 Timer）
    std::unique_ptr<util::Timer> timeoutTimer;
    
    // Socket watchers 映射
    std::map<curl_socket_t, int> socketActions;

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

// ====================
// HTTPFileSource::Impl
// ====================

HTTPFileSource::Impl::Impl(const ResourceOptions &resourceOptions_, const ClientOptions &clientOptions_)
    : resourceOptions(resourceOptions_.clone()),
      clientOptions(clientOptions_.clone()) {
    
    Logger::info("Network", "========== HTTPFileSource::Impl Constructor ==========");
    Logger::info("Network", "Thread ID: %lu", (unsigned long)std::hash<std::thread::id>{}(std::this_thread::get_id()));
    
    // 检查当前线程的 RunLoop
    auto* currentLoop = util::RunLoop::Get();
    Logger::info("Network", "Current RunLoop: %p", currentLoop);
    
    if (!currentLoop) {
        Logger::error("Network", "❌ CRITICAL: NO RunLoop in current thread!");
        Logger::error("Network", "❌ HTTPFileSource REQUIRES RunLoop to function!");
    } else {
        Logger::info("Network", "✅ RunLoop exists in current thread");
    }
    
    if (curl_global_init(CURL_GLOBAL_ALL)) {
        Logger::error("Network", "Failed to initialize CURL");
        throw std::runtime_error("Could not init cURL");
    }

    share = curl_share_init();
    
    // 创建 CURL multi handle
    multi = curl_multi_init();
    if (!multi) {
        Logger::error("Network", "Failed to create CURL multi handle");
        if (share) curl_share_cleanup(share);
        curl_global_cleanup();
        throw std::runtime_error("Failed to create CURL multi handle");
    }
    
    // 设置 CURL 回调函数（集成到 RunLoop）
    curl_multi_setopt(multi, CURLMOPT_SOCKETFUNCTION, handleSocket);
    curl_multi_setopt(multi, CURLMOPT_SOCKETDATA, this);
    curl_multi_setopt(multi, CURLMOPT_TIMERFUNCTION, handleTimer);
    curl_multi_setopt(multi, CURLMOPT_TIMERDATA, this);
    
    // 创建 timeout timer
    timeoutTimer = std::make_unique<util::Timer>();
    
    Logger::info("Network", "✅ HTTPFileSource initialized with RunLoop integration");
}

HTTPFileSource::Impl::~Impl() {
    Logger::info("Network", "Cleaning up HTTPFileSource");
    
    // 移除所有 socket watchers
    for (const auto& pair : socketActions) {
        util::RunLoop::Get()->removeWatch(pair.first);
    }
    socketActions.clear();
    
    // 停止 timeout timer
    if (timeoutTimer) {
        timeoutTimer->stop();
        timeoutTimer.reset();
    }
    
    // 清理 CURL multi handle
    if (multi) {
        curl_multi_cleanup(multi);
        multi = nullptr;
    }
    
    // 清理 CURL easy handles
    while (!handles.empty()) {
        curl_easy_cleanup(handles.front());
        handles.pop();
    }
    
    // 清理 CURL share handle
    if (share) {
        curl_share_cleanup(share);
        share = nullptr;
    }
    
    // 清理 CURL 全局状态
    curl_global_cleanup();
    
    Logger::info("Network", "✅ HTTPFileSource cleanup complete");
}

void HTTPFileSource::Impl::perform(curl_socket_t socket, util::RunLoop::Event event) {
    int action = 0;
    if (event == util::RunLoop::Event::Read) {
        action = CURL_CSELECT_IN;
    } else if (event == util::RunLoop::Event::Write) {
        action = CURL_CSELECT_OUT;
    } else if (event == util::RunLoop::Event::ReadWrite) {
        action = CURL_CSELECT_IN | CURL_CSELECT_OUT;
    }
    
    int running = 0;
    curl_multi_socket_action(multi, socket, action, &running);
    
    // 检查完成的请求
    checkMultiInfo();
}

void HTTPFileSource::Impl::onTimeout() {
    Logger::debug("Network", "CURL timeout triggered");
    
    int running = 0;
    curl_multi_socket_action(multi, CURL_SOCKET_TIMEOUT, 0, &running);
    
    // 检查完成的请求
    checkMultiInfo();
}

int HTTPFileSource::Impl::handleSocket(CURL* /*easy*/, curl_socket_t s, int action, void* userp, void* /*socketp*/) {
    auto* impl = static_cast<Impl*>(userp);
    
    Logger::info("Network", "🔌 handleSocket: socket=%d, action=%d", s, action);
    Logger::debug("Network", "Thread ID: %lu", (unsigned long)std::hash<std::thread::id>{}(std::this_thread::get_id()));
    
    auto* runLoop = util::RunLoop::Get();
    Logger::debug("Network", "Current RunLoop: %p", runLoop);
    
    if (!runLoop) {
        Logger::error("Network", "❌ No RunLoop available for socket handling!");
        return -1;
    }
    
    if (action == CURL_POLL_REMOVE) {
        Logger::debug("Network", "Removing socket watch: %d", s);
        runLoop->removeWatch(s);
        impl->socketActions.erase(s);
    } else {
        util::RunLoop::Event event = util::RunLoop::Event::None;
        
        if ((action & CURL_POLL_IN) && (action & CURL_POLL_OUT)) {
            event = util::RunLoop::Event::ReadWrite;
        } else if (action & CURL_POLL_IN) {
            event = util::RunLoop::Event::Read;
        } else if (action & CURL_POLL_OUT) {
            event = util::RunLoop::Event::Write;
        }
        
        Logger::debug("Network", "Adding/updating socket watch: %d, action=%d", s, action);
        
        // 如果已存在，先移除旧的 watcher
        if (impl->socketActions.find(s) != impl->socketActions.end()) {
            runLoop->removeWatch(s);
        }
        
        // 添加新的 watcher
        runLoop->addWatch(s, event, [impl, s](int, util::RunLoop::Event e) {
            impl->perform(s, e);
        });
        
        impl->socketActions[s] = action;
    }
    
    return 0;
}

int HTTPFileSource::Impl::handleTimer(CURLM* /*multi*/, long timeout_ms, void* userp) {
    auto* impl = static_cast<Impl*>(userp);
    
    Logger::info("Network", "⏱️ handleTimer: timeout=%ld ms", timeout_ms);
    Logger::debug("Network", "Thread ID: %lu", (unsigned long)std::hash<std::thread::id>{}(std::this_thread::get_id()));
    
    auto* runLoop = util::RunLoop::Get();
    Logger::debug("Network", "Current RunLoop: %p", runLoop);
    
    if (!runLoop) {
        Logger::error("Network", "❌ No RunLoop available for timer handling!");
        return -1;
    }
    
    if (timeout_ms < 0) {
        // 取消 timer
        Logger::debug("Network", "Cancelling CURL timeout timer");
        impl->timeoutTimer->stop();
    } else {
        // 设置 timer
        Logger::debug("Network", "Setting CURL timeout: %ld ms", timeout_ms);
        impl->timeoutTimer->start(
            std::chrono::milliseconds(timeout_ms),
            std::chrono::milliseconds(0),  // 不重复
            [impl]() {
                impl->onTimeout();
            }
        );
    }
    
    return 0;
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
                HTTPRequest *request = nullptr;
                curl_easy_getinfo(message->easy_handle, CURLINFO_PRIVATE, (char *)&request);
                
                if (request) {
                    request->handleResult(message->data.result);
                }
                
                // 从 multi handle 中移除
                curl_multi_remove_handle(multi, message->easy_handle);
            } break;

            default:
                Logger::error("Network", "Unknown CURL message type: %d", message->msg);
                break;
        }
    }
}

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

// ====================
// HTTPRequest
// ====================

HTTPRequest::HTTPRequest(HTTPFileSource::Impl *context_, Resource resource_, FileSource::Callback callback_)
    : context(context_),
      resource(std::move(resource_)),
      callback(std::move(callback_)),
      handle(context->getHandle()) {
    
    Logger::info("HTTP", "========== HTTPRequest Constructor ==========");
    Logger::info("HTTP", "📤 Request: %s", resource.url.c_str());
    Logger::info("HTTP", "Thread ID: %lu", (unsigned long)std::hash<std::thread::id>{}(std::this_thread::get_id()));
    
    // 检查当前线程的 RunLoop
    auto* currentLoop = util::RunLoop::Get();
    Logger::info("HTTP", "Current RunLoop: %p", currentLoop);
    
    if (!currentLoop) {
        Logger::error("HTTP", "❌ CRITICAL: NO RunLoop in current thread!");
        Logger::error("HTTP", "❌ CURL events will NOT work without RunLoop!");
    } else {
        Logger::info("HTTP", "✅ RunLoop exists, CURL events will be registered");
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

        Logger::info("HTTP", "📤 Request: %s", resource.url.c_str());

        // 添加到 CURL multi handle
        CURLMcode result = curl_multi_add_handle(context->multi, handle);
        if (result != CURLM_OK) {
            Logger::error("Network", "Failed to add handle to multi: %s", curl_multi_strerror(result));
            throw std::runtime_error(std::string("curl_multi_add_handle failed: ") + curl_multi_strerror(result));
        }
        
    } catch (const std::exception& e) {
        Logger::error("Network", "Exception in HTTPRequest constructor: %s", e.what());
        throw;
    }
}

HTTPRequest::~HTTPRequest() {
    Logger::debug("HTTP", "Destroying HTTPRequest: %p", this);
    
    // 清除回调指针，防止野指针访问
    if (handle) {
        curl_easy_setopt(handle, CURLOPT_WRITEDATA, nullptr);
        curl_easy_setopt(handle, CURLOPT_HEADERDATA, nullptr);
        curl_easy_setopt(handle, CURLOPT_PRIVATE, nullptr);
        
        // 从 multi handle 中移除（如果还在）
        if (context && context->multi) {
            curl_multi_remove_handle(context->multi, handle);
        }
    }
    
    // 返回句柄到池中
    if (context && handle) {
        context->returnHandle(handle);
        handle = nullptr;
    }
    
    // 清理 HTTP 头
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
// (zero-terminated!) header string.
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
    Logger::info("HTTP", "📥 Response: %s, CURL_code=%d (%s)", 
        resource.url.c_str(), 
        code, 
        curl_easy_strerror(code));
    
    // Make sure a response object exists
    if (!response) {
        response = std::make_unique<Response>();
    }

    using Error = Response::Error;

    if (code != CURLE_OK) {
        Logger::error("Network", "❌ Request FAILED: %s (CURL code=%d)", 
            curl_easy_strerror(code), code);
        
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
        
        Logger::info("HTTP", "✅ CURL OK - HTTP Status: %ld", responseCode);

        if (responseCode == 200 || responseCode == 206) {
            if (data) {
                Logger::info("HTTP", "✅ Success! Data size: %zu bytes", data->size());
                response->data = std::move(data);
            } else {
                Logger::warn("HTTP", "⚠️ Success but no data!");
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
            Logger::error("HTTP", "❌ Unexpected HTTP status: %ld", responseCode);
            response->error = std::make_unique<Error>(Error::Reason::Other,
                                                      std::string{"HTTP status code "} + util::toString(responseCode));
        }
    }
    
    // 调用回调前记录最终状态
    if (response->error) {
        Logger::error("HTTP", "❌ Final response has ERROR: %s", response->error->message.c_str());
    } else if (response->data) {
        Logger::info("HTTP", "✅ Final response OK with data");
    } else if (response->notModified) {
        Logger::info("HTTP", "✅ Final response: 304 Not Modified");
    } else if (response->noContent) {
        Logger::info("HTTP", "✅ Final response: No Content");
    } else {
        Logger::warn("HTTP", "⚠️ Final response: Unknown state");
    }
    
    // ✅ 直接调用回调（已经在 Map RunLoop 线程）
    // 不需要 RunLoop::invoke() 包装，因为 CURL 现在集成到 RunLoop
    Logger::info("HTTP", "📞 Calling response callback...");
    callback(*response);
    Logger::info("HTTP", "✅ Callback completed");
}

// ====================
// HTTPFileSource
// ====================

HTTPFileSource::HTTPFileSource(const ResourceOptions &resourceOptions, const ClientOptions &clientOptions)
    : impl(std::make_unique<Impl>(resourceOptions, clientOptions)) {
}

HTTPFileSource::~HTTPFileSource() = default;

std::unique_ptr<AsyncRequest> HTTPFileSource::request(const Resource &resource, Callback callback) {
    Logger::info("HTTP", "========== HTTPFileSource::request() ==========");
    Logger::info("HTTP", "URL: %s", resource.url.c_str());
    Logger::info("HTTP", "Thread ID: %lu", (unsigned long)std::hash<std::thread::id>{}(std::this_thread::get_id()));
    
    try {
        if (!impl) {
            Logger::error("Network", "❌ HTTPFileSource impl is null");
            return nullptr;
        }
        
        Logger::debug("HTTP", "Creating HTTPRequest...");
        auto request = std::make_unique<HTTPRequest>(impl.get(), resource, callback);
        Logger::info("HTTP", "✅ HTTPRequest created: %p", request.get());
        return request;
        
    } catch (const std::exception& e) {
        Logger::error("Network", "❌ Exception in HTTPFileSource::request: %s", e.what());
        return nullptr;
    } catch (...) {
        Logger::error("Network", "❌ Unknown exception in HTTPFileSource::request");
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
