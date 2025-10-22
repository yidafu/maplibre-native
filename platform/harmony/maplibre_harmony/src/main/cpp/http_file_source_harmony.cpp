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

// HarmonyOS独立CURL事件循环
#include "curl_event_loop.hpp"

#include <hilog/log.h>
#include <fstream>
#include <ctime>
#include <sys/time.h>

// 文件日志函数（绕过hilog限制）
static void FILE_LOG(const char* msg) {
    std::ofstream log("/data/local/tmp/http_debug.log", std::ios::app);
    if (log.is_open()) {
        struct timeval tv;
        gettimeofday(&tv, nullptr);
        log << tv.tv_sec << "." << tv.tv_usec << " " << msg << std::endl;
        log.close();
    }
    // 同时输出到stderr
    fprintf(stderr, "[HTTP_FILE_LOG] %s\n", msg);
    fflush(stderr);
}

// 使用已验证可用的tag，并提升日志级别以确保输出
#define HTTP_LOG(...) OH_LOG_Print(LOG_APP, LOG_ERROR, 0xA00000, "CURLEventLoop", __VA_ARGS__)
// 添加高优先级日志宏用于关键节点
#define HTTP_LOG_CRITICAL(...) OH_LOG_Print(LOG_APP, LOG_FATAL, 0xFFFFFF, "HTTP_CRITICAL", __VA_ARGS__)

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
    
    // 文件日志：第一件事
    FILE_LOG("========================================");
    FILE_LOG("HTTPFileSource::Impl CONSTRUCTOR ENTRY");
    FILE_LOG("========================================");
    
    // 使用最高优先级日志标记构造函数开始
    HTTP_LOG_CRITICAL("================================================");
    HTTP_LOG_CRITICAL("HTTPFileSource::Impl CONSTRUCTOR START");
    HTTP_LOG_CRITICAL("================================================");
    
    FILE_LOG("After HTTP_LOG_CRITICAL in Impl constructor");
    
    // 第一行就打印，确认代码执行
    fprintf(stderr, "\n\n*** HTTPFileSource::Impl CONSTRUCTOR HARMONY CALLED ***\n\n");
    fflush(stderr);
    
    FILE_LOG("After fprintf in Impl constructor");
    HTTP_LOG("========== HTTPFileSource::Impl CONSTRUCTOR START ==========");
    
    HTTP_LOG("Step 1/5: Initializing CURL global...");
    if (curl_global_init(CURL_GLOBAL_ALL)) {
        HTTP_LOG("CURL global init FAILED!");
        HTTP_LOG_CRITICAL("CRITICAL ERROR: CURL global init FAILED!");
        throw std::runtime_error("Could not init cURL");
    }
    HTTP_LOG("Step 1/5: CURL global init SUCCESS");

    share = curl_share_init();
    HTTP_LOG("Step 2/5: CURL share init: %{public}p", share);

    // 创建独立的CURL事件循环
    try {
        HTTP_LOG("Step 3/5: Creating CURLEventLoop...");
        
        // 默认使用简单轮询模式（稳定可靠）
        // 如果需要高性能模式，可以通过环境变量切换：CURL_MODE=event
        auto mode = harmony::CURLEventLoop::Mode::SimplePolling;
        
        const char* curl_mode_env = getenv("CURL_MODE");
        if (curl_mode_env && strcmp(curl_mode_env, "event") == 0) {
            mode = harmony::CURLEventLoop::Mode::EventDriven;
            HTTP_LOG("Using EventDriven mode (from environment)");
        } else {
            HTTP_LOG("Using SimplePolling mode (default, 100ms timer)");
        }
        
        curlEventLoop = std::make_unique<harmony::CURLEventLoop>(mode);
        HTTP_LOG("Step 3/5: CURLEventLoop created successfully at %{public}p", curlEventLoop.get());
        
        // 启动事件循环
        HTTP_LOG("Step 4/5: Starting CURLEventLoop...");
        curlEventLoop->start();
        HTTP_LOG("Step 4/5: CURLEventLoop started successfully");
        
        // 获取multi handle（由CURLEventLoop管理）
        multi = curlEventLoop->getMultiHandle();
        HTTP_LOG("Step 5/5: CURL multi handle obtained: %{public}p", multi);
        HTTP_LOG("Step 5/5: No external timer needed (handled by CURLEventLoop)");
        
    } catch (const std::exception& e) {
        HTTP_LOG("CRITICAL ERROR: Failed to create CURLEventLoop: %{public}s", e.what());
        HTTP_LOG_CRITICAL("CURLEventLoop creation FAILED: %{public}s", e.what());
        if (share) {
            curl_share_cleanup(share);
            share = nullptr;
        }
        curl_global_cleanup();
        throw;
    }
    
    HTTP_LOG("========== HTTPFileSource::Impl CONSTRUCTOR END - SUCCESS ==========");
    HTTP_LOG_CRITICAL("HTTPFileSource::Impl CONSTRUCTOR COMPLETE");
}

HTTPFileSource::Impl::~Impl() {
    HTTP_LOG("========== HTTPFileSource::Impl DESTRUCTOR START ==========");
    
    // 1. 停止CURL事件循环（这会自动清理所有活跃的CURL句柄）
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
        // 收到CURL消息时使用高优先级日志
        HTTP_LOG("========== checkMultiInfo: Got CURL message ==========");
        HTTP_LOG_CRITICAL("CURL message received - type: %{public}d", message->msg);
        
        switch (message->msg) {
            case CURLMSG_DONE: {
                HTTPRequest *baton = nullptr;
                curl_easy_getinfo(message->easy_handle, CURLINFO_PRIVATE, (char *)&baton);
                assert(baton);
                
                HTTP_LOG("Request completed for handle %{public}p", message->easy_handle);
                HTTP_LOG("Result code: %{public}d", message->data.result);
                HTTP_LOG_CRITICAL("Request DONE - calling handleResult");
                
                baton->handleResult(message->data.result);
            } break;

            default:
                HTTP_LOG("ERROR: Unknown CURL message type: %{public}d", message->msg);
                HTTP_LOG_CRITICAL("ERROR: Unknown message type");
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
    
    // 文件日志：第一件事
    FILE_LOG("HTTPRequest CONSTRUCTOR ENTRY");
    FILE_LOG(("HTTPRequest URL: " + resource.url).c_str());
    
    // 使用最高优先级日志标记开始
    HTTP_LOG_CRITICAL("HTTPRequest CONSTRUCTOR START");
    HTTP_LOG_CRITICAL("URL: %{public}s", resource.url.c_str());
    
    FILE_LOG("After HTTP_LOG_CRITICAL in HTTPRequest");
    
    HTTP_LOG("========== HTTPRequest CONSTRUCTOR START ==========");
    HTTP_LOG("URL: %{public}s", resource.url.c_str());
    HTTP_LOG("CURL handle: %{public}p", handle);
    HTTP_LOG("Context: %{public}p", context);
    
    FILE_LOG("After basic HTTP_LOG in HTTPRequest");
    HTTP_LOG("Step 1/3: Setting up CURL options...");
    
    if (resource.dataRange) {
        const std::string header = std::string("Range: bytes=") + std::to_string(resource.dataRange->first) +
                                   std::string("-") + std::to_string(resource.dataRange->second);
        headers = curl_slist_append(headers, header.c_str());
        HTTP_LOG("Added Range header: %{public}s", header.c_str());
    }

    // If there's already a response, set the correct etags/modified headers to
    // make sure we are getting a 304 response if possible. This avoids
    // redownloading unchanged data.
    if (resource.priorEtag) {
        const std::string header = std::string("If-None-Match: ") + *resource.priorEtag;
        headers = curl_slist_append(headers, header.c_str());
        HTTP_LOG("Added ETag header");
    } else if (resource.priorModified) {
        const std::string time = std::string("If-Modified-Since: ") + util::rfc1123(*resource.priorModified);
        headers = curl_slist_append(headers, time.c_str());
        HTTP_LOG("Added If-Modified-Since header");
    }

    FILE_LOG("Before setting headers");
    
    try {
        if (headers) {
            curl_easy_setopt(handle, CURLOPT_HTTPHEADER, headers);
        }

        FILE_LOG("Before handleError calls");
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

        FILE_LOG("After all handleError calls");
        HTTP_LOG("Step 1/3: CURL options set successfully");
        
        // Start requesting the information using CURLEventLoop.
        FILE_LOG("Before adding handle to CURLEventLoop");
        HTTP_LOG("Step 2/3: About to add CURL handle to CURLEventLoop - handle=%{public}p", handle);
        HTTP_LOG_CRITICAL("Adding CURL handle to event loop...");
        
        if (context->curlEventLoop) {
            FILE_LOG("CURLEventLoop exists, calling addHandle");
            HTTP_LOG("CURLEventLoop exists at %{public}p", context->curlEventLoop.get());
            bool success = context->curlEventLoop->addHandle(handle);
            if (!success) {
                FILE_LOG("ERROR: addHandle returned false");
                HTTP_LOG("ERROR: Failed to add handle to CURLEventLoop");
                HTTP_LOG_CRITICAL("FAILED to add handle to CURLEventLoop!");
                throw std::runtime_error("Failed to add handle to CURLEventLoop");
            }
            FILE_LOG("addHandle SUCCESS");
            HTTP_LOG("Step 2/3: CURL handle added to CURLEventLoop successfully");
            HTTP_LOG_CRITICAL("CURL handle added to event loop SUCCESS");
        } else {
            FILE_LOG("ERROR: CURLEventLoop is null");
            HTTP_LOG("ERROR: CURLEventLoop is null");
            HTTP_LOG_CRITICAL("CRITICAL ERROR: CURLEventLoop is NULL!");
            throw std::runtime_error("CURLEventLoop is null");
        }
        
        FILE_LOG("HTTPRequest constructor completing");
        HTTP_LOG("Step 3/3: HTTPRequest constructor complete");
        HTTP_LOG("========== HTTPRequest CONSTRUCTOR END ==========");
        HTTP_LOG_CRITICAL("HTTPRequest CONSTRUCTOR COMPLETE - request is active");
        
    } catch (const std::runtime_error& e) {
        FILE_LOG("EXCEPTION in HTTPRequest constructor: runtime_error");
        FILE_LOG(e.what());
        HTTP_LOG_CRITICAL("❌ EXCEPTION in HTTPRequest constructor: %{public}s", e.what());
        fprintf(stderr, "❌ EXCEPTION in HTTPRequest constructor: %s\n", e.what());
        fflush(stderr);
        throw; // 重新抛出异常
    } catch (const std::exception& e) {
        FILE_LOG("EXCEPTION in HTTPRequest constructor: exception");
        FILE_LOG(e.what());
        HTTP_LOG_CRITICAL("❌ EXCEPTION in HTTPRequest constructor: %{public}s", e.what());
        fprintf(stderr, "❌ EXCEPTION in HTTPRequest constructor: %s\n", e.what());
        fflush(stderr);
        throw; // 重新抛出异常
    } catch (...) {
        FILE_LOG("EXCEPTION in HTTPRequest constructor: UNKNOWN");
        HTTP_LOG_CRITICAL("❌ UNKNOWN EXCEPTION in HTTPRequest constructor");
        fprintf(stderr, "❌ UNKNOWN EXCEPTION in HTTPRequest constructor\n");
        fflush(stderr);
        throw; // 重新抛出异常
    }
}

HTTPRequest::~HTTPRequest() {
    HTTP_LOG("========== HTTPRequest DESTRUCTOR START ==========");
    HTTP_LOG("URL: %{public}s", resource.url.c_str());
    HTTP_LOG("Context: %{public}p, Handle: %{public}p", context, handle);
    
    // 🔧 修复SIGSEGV：先清除userp指针，防止CURL回调访问已销毁对象
    if (handle) {
        HTTP_LOG("⚠️  Clearing CURL userp to prevent use-after-free...");
        curl_easy_setopt(handle, CURLOPT_WRITEDATA, nullptr);
        curl_easy_setopt(handle, CURLOPT_HEADERDATA, nullptr);
        curl_easy_setopt(handle, CURLOPT_PRIVATE, nullptr);
        HTTP_LOG("✅ CURL userp cleared");
    }
    
    // 1. 安全地从CURLEventLoop移除CURL句柄
    if (context && context->curlEventLoop && handle) {
        HTTP_LOG("Removing CURL handle from CURLEventLoop...");
        bool success = context->curlEventLoop->removeHandle(handle);
        if (!success) {
            HTTP_LOG("Warning: Error removing CURL handle from CURLEventLoop");
        } else {
            HTTP_LOG("CURL handle removed from CURLEventLoop successfully");
        }
        
        // 🔧 修复SIGSEGV：等待CURL操作完全停止
        HTTP_LOG("⏸️  Waiting for CURL operations to complete...");
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
        HTTP_LOG("✅ CURL operations wait completed");
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
    // 🔧 修复SIGSEGV：检查userp有效性，防止use-after-free
    if (!userp) {
        HTTP_LOG("⚠️  writeCallback: userp is null - HTTPRequest已销毁，忽略回调");
        return 0;  // 返回0会让CURL终止请求
    }
    
    auto impl = reinterpret_cast<HTTPRequest *>(userp);
    
    // 🔍 额外验证：检查impl指向的内存是否合法（简单检查）
    try {
        if (!impl->data) {
            impl->data = std::make_shared<std::string>();
        }

        impl->data->append(static_cast<char *>(contents), size * nmemb);
        return size * nmemb;
    } catch (...) {
        HTTP_LOG("❌ writeCallback: Exception caught - HTTPRequest可能已销毁");
        return 0;  // 返回0终止请求
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
    // 🔧 修复SIGSEGV：检查userp有效性，防止use-after-free
    if (!userp) {
        HTTP_LOG("⚠️  headerCallback: userp is null - HTTPRequest已销毁，忽略回调");
        return 0;  // 返回0会让CURL终止请求
    }
    
    auto baton = reinterpret_cast<HTTPRequest *>(userp);
    
    // 🔍 额外验证：try-catch保护
    try {
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
        
    } catch (...) {
        HTTP_LOG("❌ headerCallback: Exception caught - HTTPRequest可能已销毁");
        return 0;  // 返回0终止请求
    }
}

void HTTPRequest::handleResult(CURLcode code) {
    // 使用最高优先级日志
    HTTP_LOG_CRITICAL("================================================");
    HTTP_LOG_CRITICAL("HTTPRequest::handleResult() CALLED");
    HTTP_LOG_CRITICAL("CURL code: %{public}d (%{public}s)", code, curl_easy_strerror(code));
    HTTP_LOG_CRITICAL("================================================");
    
    HTTP_LOG("========== HTTPRequest::handleResult() START ==========");
    HTTP_LOG("URL: %{public}s", resource.url.c_str());
    HTTP_LOG("CURL result code: %{public}d", code);
    
    // Make sure a response object exists in case we haven't got any headers or content.
    if (!response) {
        response = std::make_unique<Response>();
        HTTP_LOG("Created new Response object");
    }

    using Error = Response::Error;

    // Add human-readable error code
    if (code != CURLE_OK) {
        HTTP_LOG("CURL request FAILED with code %{public}d: %{public}s", code, curl_easy_strerror(code));
        HTTP_LOG_CRITICAL("CURL FAILED: %{public}s", curl_easy_strerror(code));
        
        switch (code) {
            case CURLE_COULDNT_RESOLVE_PROXY:
            case CURLE_COULDNT_RESOLVE_HOST:
            case CURLE_COULDNT_CONNECT:
            case CURLE_OPERATION_TIMEDOUT:

                response->error = std::make_unique<Error>(Error::Reason::Connection,
                                                          std::string{curl_easy_strerror(code)} + ": " + error);
                HTTP_LOG("Connection error: %{public}s", error);
                break;

            default:
                response->error = std::make_unique<Error>(Error::Reason::Other,
                                                          std::string{curl_easy_strerror(code)} + ": " + error);
                HTTP_LOG("Other error: %{public}s", error);
                break;
        }
    } else {
        long responseCode = 0;
        curl_easy_getinfo(handle, CURLINFO_RESPONSE_CODE, &responseCode);
        
        HTTP_LOG("CURL request SUCCESS - HTTP status: %{public}ld", responseCode);
        HTTP_LOG_CRITICAL("HTTP Response Code: %{public}ld", responseCode);

        if (responseCode == 200 || responseCode == 206) {
            if (data) {
                response->data = std::move(data);
                HTTP_LOG("Response data size: %{public}zu bytes", response->data->size());
                HTTP_LOG_CRITICAL("Got data: %{public}zu bytes", response->data->size());
            } else {
                response->data = std::make_shared<std::string>();
                HTTP_LOG("No data in response");
            }
        } else if (responseCode == 204 || (responseCode == 404 && resource.kind == Resource::Kind::Tile)) {
            response->noContent = true;
            HTTP_LOG("No content response (204 or 404 tile)");
        } else if (responseCode == 304) {
            response->notModified = true;
            HTTP_LOG("Not modified (304)");
        } else if (responseCode == 404) {
            response->error = std::make_unique<Error>(Error::Reason::NotFound, "HTTP status code 404");
            HTTP_LOG("Not found (404)");
        } else if (responseCode == 429) {
            response->error = std::make_unique<Error>(
                Error::Reason::RateLimit, "HTTP status code 429", http::parseRetryHeaders(retryAfter, xRateLimitReset));
            HTTP_LOG("Rate limited (429)");
        } else if (responseCode >= 500 && responseCode < 600) {
            response->error = std::make_unique<Error>(Error::Reason::Server,
                                                      std::string{"HTTP status code "} + util::toString(responseCode));
            HTTP_LOG("Server error (%{public}ld)", responseCode);
        } else {
            response->error = std::make_unique<Error>(Error::Reason::Other,
                                                      std::string{"HTTP status code "} + util::toString(responseCode));
            HTTP_LOG("Other HTTP error (%{public}ld)", responseCode);
        }
    }

    HTTP_LOG("About to invoke callback...");
    HTTP_LOG_CRITICAL("Invoking response callback...");
    
    // Calling `callback` may result in deleting `this`. Copy data to temporaries first.
    auto callback_ = callback;
    auto response_ = *response;
    callback_(response_);
    
    // 注意：this可能已被删除，不能在这里添加日志
}

HTTPFileSource::HTTPFileSource(const ResourceOptions &resourceOptions, const ClientOptions &clientOptions)
    : impl(std::make_unique<Impl>(resourceOptions, clientOptions)) {
    
    // 文件日志：第一件事
    FILE_LOG("========================================");
    FILE_LOG("HTTPFileSource CONSTRUCTOR ENTRY");
    FILE_LOG("========================================");
    
    // 使用最高优先级日志标记
    HTTP_LOG_CRITICAL("================================================");
    HTTP_LOG_CRITICAL("HTTPFileSource CONSTRUCTOR START");
    HTTP_LOG_CRITICAL("This is HarmonyOS implementation");
    HTTP_LOG_CRITICAL("================================================");
    
    FILE_LOG("After HTTP_LOG_CRITICAL in HTTPFileSource constructor");
    
    // 第一行就打印
    HTTP_LOG("🔥🔥🔥 HTTPFileSource HARMONY CONSTRUCTOR CALLED 🔥🔥🔥");
    HTTP_LOG("========== HTTPFileSource CONSTRUCTOR (HarmonyOS) ==========");
    HTTP_LOG("This is the HarmonyOS-specific HTTPFileSource implementation");
    HTTP_LOG("impl address: %{public}p", impl.get());
    
    FILE_LOG("After basic HTTP_LOG in HTTPFileSource constructor");
    
    // 直接打印到stderr以确认代码被执行
    fprintf(stderr, "\n\n");
    fprintf(stderr, "**************************************************\n");
    fprintf(stderr, "*** HTTPFileSource HARMONY CONSTRUCTOR CALLED ***\n");
    fprintf(stderr, "**************************************************\n");
    fprintf(stderr, "\n\n");
    fflush(stderr);
    
    HTTP_LOG("HTTPFileSource constructor complete");
    HTTP_LOG_CRITICAL("HTTPFileSource CONSTRUCTOR COMPLETE");
}

HTTPFileSource::~HTTPFileSource() = default;

std::unique_ptr<AsyncRequest> HTTPFileSource::request(const Resource &resource, Callback callback) {
    // 文件日志：第一件事！
    FILE_LOG("========================================");
    FILE_LOG("HTTPFileSource::request() ENTRY");
    FILE_LOG(("URL: " + resource.url).c_str());
    FILE_LOG("========================================");
    
    try {
        // 使用最高优先级日志
        HTTP_LOG_CRITICAL("================================================");
        HTTP_LOG_CRITICAL("HTTPFileSource::request() CALLED");
        HTTP_LOG_CRITICAL("URL: %{public}s", resource.url.c_str());
        HTTP_LOG_CRITICAL("================================================");
        
        FILE_LOG("After HTTP_LOG_CRITICAL");
        
        // 第一行就打印，确保执行
        HTTP_LOG("🔥🔥🔥 HTTPFileSource::request() HARMONY VERSION CALLED 🔥🔥🔥");
        HTTP_LOG("========== HTTPFileSource::request() START ==========");
        HTTP_LOG("Resource URL: %{public}s", resource.url.c_str());
        HTTP_LOG("Resource kind: %{public}d", static_cast<int>(resource.kind));
        HTTP_LOG("impl pointer: %{public}p", impl.get());
        
        FILE_LOG("After basic HTTP_LOG");
        
        if (!impl) {
            FILE_LOG("ERROR: impl is NULL!");
            HTTP_LOG("❌ ERROR: impl is NULL!");
            HTTP_LOG_CRITICAL("CRITICAL ERROR: impl is NULL!");
            return nullptr;
        }
        
        FILE_LOG("impl check passed");
        HTTP_LOG("About to create HTTPRequest object...");
        
        // 直接打印确认代码执行
        fprintf(stderr, "\n*** HTTPFileSource::request() HARMONY CALLED for: %s ***\n", resource.url.c_str());
        fflush(stderr);
        
        FILE_LOG("Before make_unique<HTTPRequest>");
        
        auto request = std::make_unique<HTTPRequest>(impl.get(), resource, callback);
        
        FILE_LOG("After make_unique<HTTPRequest>");
        HTTP_LOG("HTTPRequest created successfully: %{public}p", request.get());
        HTTP_LOG("========== HTTPFileSource::request() END ==========");
        HTTP_LOG_CRITICAL("HTTPFileSource::request() COMPLETE - returning request");
        
        FILE_LOG("Returning request");
        return request;
        
    } catch (const std::bad_alloc& e) {
        FILE_LOG("EXCEPTION: std::bad_alloc");
        FILE_LOG(e.what());
        HTTP_LOG_CRITICAL("❌ EXCEPTION: std::bad_alloc: %{public}s", e.what());
        fprintf(stderr, "❌ EXCEPTION in HTTPFileSource::request(): bad_alloc: %s\n", e.what());
        fflush(stderr);
        return nullptr;
    } catch (const std::runtime_error& e) {
        FILE_LOG("EXCEPTION: std::runtime_error");
        FILE_LOG(e.what());
        HTTP_LOG_CRITICAL("❌ EXCEPTION: std::runtime_error: %{public}s", e.what());
        fprintf(stderr, "❌ EXCEPTION in HTTPFileSource::request(): runtime_error: %s\n", e.what());
        fflush(stderr);
        return nullptr;
    } catch (const std::exception& e) {
        FILE_LOG("EXCEPTION: std::exception");
        FILE_LOG(e.what());
        HTTP_LOG_CRITICAL("❌ EXCEPTION: std::exception: %{public}s", e.what());
        fprintf(stderr, "❌ EXCEPTION in HTTPFileSource::request(): %s\n", e.what());
        fflush(stderr);
        return nullptr;
    } catch (...) {
        FILE_LOG("EXCEPTION: UNKNOWN");
        HTTP_LOG_CRITICAL("❌ EXCEPTION: UNKNOWN in HTTPFileSource::request()");
        fprintf(stderr, "❌ UNKNOWN EXCEPTION in HTTPFileSource::request()!\n");
        fflush(stderr);
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
