#include "node_request.hpp"
#include "node_map.hpp"
#include "napi_utils.hpp"
#include <node_api.h>
#include <mbgl/storage/response.hpp>
#include <mbgl/util/chrono.hpp>
#include <mbgl/util/string.hpp>
#include <mbgl/util/variant.hpp>
#include <mbgl/map/map.hpp>

#include <cmath>
#include <memory>
#include <string>

namespace node_mbgl {

NodeRequest::NodeRequest(mbgl::FileSource::Callback callback_, NodeAsyncRequest* asyncRequest_)    : callback(std::move(callback_)),
      asyncRequest(asyncRequest_) {    asyncRequest->request = this;
}

NodeRequest::~NodeRequest() {
    // When this object gets garbage collected, make sure that the
    // AsyncRequest can no longer attempt to remove the callback function
    // this object was holding (it can't be fired anymore).
    if (asyncRequest) {
        asyncRequest->request = nullptr;
    }
    
    if (wrapperRef) {
        napi_delete_reference(env, wrapperRef);
    }
    
    if (asyncContext) {
        napi_delete_async_context(env, asyncContext);
    }
}

napi_ref NodeRequest::constructor = nullptr;

napi_value NodeRequest::Init(napi_env env, napi_value exports) {
    napi_status status;
    
    napi_value constructorFunc;
    status = napi_create_function(env, "Request", NAPI_AUTO_LENGTH, New, nullptr, &constructorFunc);
    node_mbgl::napi_utils::check(status, "Failed to create constructor function");
    
    napi_value prototype;
    status = napi_get_prototype(env, constructorFunc, &prototype);
    node_mbgl::napi_utils::check(status, "Failed to get prototype");
    
    status = napi_define_method(env, prototype, "respond", NAPI_AUTO_LENGTH, HandleCallback, nullptr, nullptr);
    node_mbgl::napi_utils::check(status, "Failed to define respond method");
    
    status = napi_create_reference(env, constructorFunc, 1, &constructor);
    node_mbgl::napi_utils::check(status, "Failed to create constructor reference");
    
    status = napi_set_named_property(env, exports, "Request", constructorFunc);
    node_mbgl::napi_utils::check(status, "Failed to set Request property");
    
    return exports;
}

napi_value NodeRequest::New(napi_env env, napi_callback_info info) {
    napi_status status;
    
    // 获取回调信息中的参数
    size_t argc = 5;
    napi_value args[5];
    napi_value thisArg;
    
    status = napi_get_cb_info(env, info, &argc, args, &thisArg, nullptr);
    node_mbgl::napi_utils::check(status, "Failed to get callback info");
    
    // 从参数中获取外部值
    void* data;
    
    status = napi_get_value_external(env, args[0], &data);
    node_mbgl::napi_utils::check(status, "Failed to get target data");
    NodeMap* target = reinterpret_cast<NodeMap*>(data);
    
    status = napi_get_value_external(env, args[1], &data);
    node_mbgl::napi_utils::check(status, "Failed to get callback data");
    mbgl::FileSource::Callback* callbackPtr = reinterpret_cast<mbgl::FileSource::Callback*>(data);
    
    status = napi_get_value_external(env, args[2], &data);
    node_mbgl::napi_utils::check(status, "Failed to get async request data");
    NodeAsyncRequest* asyncRequest = reinterpret_cast<NodeAsyncRequest*>(data);
    
    // 创建NodeRequest实例
    NodeRequest* request = new NodeRequest(*callbackPtr, asyncRequest);
    request->env = env;
    
    // 创建异步上下文
    status = napi_create_async_context(env, "mbgl:execute", nullptr, nullptr, &request->asyncContext);
    node_mbgl::napi_utils::check(status, "Failed to create async context");
    
    // 将C++实例包装到JavaScript对象中
    node_mbgl::napi_utils::wrapObject(env, thisArg, request);
    
    // 设置对象的属性
    node_mbgl::napi_utils::setProperty(env, thisArg, "url", args[3]);
    node_mbgl::napi_utils::setProperty(env, thisArg, "kind", args[4]);
    
    // 创建对thisArg的引用
    status = napi_create_reference(env, thisArg, 1, &request->wrapperRef);
    node_mbgl::napi_utils::check(status, "Failed to create wrapper reference");
    
    // 运行异步回调
    napi_value global;
    status = napi_get_global(env, &global);
    node_mbgl::napi_utils::check(status, "Failed to get global object");
    
    napi_value executeAsync;
    node_mbgl::napi_utils::getProperty(env, global, "process", &executeAsync);
    node_mbgl::napi_utils::getProperty(env, executeAsync, "nextTick", &executeAsync);
    
    napi_value argv[1] = {thisArg};
    node_mbgl::napi_utils::callAsFunction(env, executeAsync, global, 1, argv, nullptr);
    
    return thisArg;
}

napi_value NodeRequest::HandleCallback(napi_env env, napi_callback_info info) {
    napi_status status;
    
    size_t argc = 2;
    napi_value args[2];
    napi_value thisArg;
    
    status = napi_get_cb_info(env, info, &argc, args, &thisArg, nullptr);
    node_mbgl::napi_utils::check(status, "Failed to get callback info");
    
    // 从JavaScript对象中获取NodeRequest实例
    NodeRequest* request = static_cast<NodeRequest*>(node_mbgl::napi_utils::unwrapObject(env, thisArg));
    
    // Move out of the object so callback() can only be fired once.
    auto callback = std::move(request->callback);
    request->callback = {};
    if (!callback) {
        request->unrefRequest();
        return node_mbgl::napi_utils::createUndefined(env);
    }

    mbgl::Response response;

    if (argc < 1) {
        response.noContent = true;
    } else if (node_mbgl::napi_utils::isObject(env, args[0])) {
        // 处理错误对象
        napi_value errorObj = args[0];
        napi_value messageValue;
        bool hasMessage = false;
        status = napi_has_named_property(env, errorObj, "message", &hasMessage);
        node_mbgl::napi_utils::check(status, "Failed to check message property");
        
        if (hasMessage) {
            status = napi_get_named_property(env, errorObj, "message", &messageValue);
            node_mbgl::napi_utils::check(status, "Failed to get message property");
            
            std::string message = node_mbgl::napi_utils::toString(env, messageValue);
            response.error = std::make_unique<mbgl::Response::Error>(
                mbgl::Response::Error::Reason::Other, message);
        }
    } else if (node_mbgl::napi_utils::isString(env, args[0])) {
        // 处理错误字符串
        std::string message = node_mbgl::napi_utils::toString(env, args[0]);
        response.error = std::make_unique<mbgl::Response::Error>(
            mbgl::Response::Error::Reason::Other, message);
    } else if (argc < 2 || !node_mbgl::napi_utils::isObject(env, args[1])) {
        // 参数错误
        request->unrefRequest();
        node_mbgl::napi_utils::throwError(env, "Second argument must be a response object");
        return nullptr;
    } else {
        // 处理响应对象
        napi_value resObj = args[1];
        
        // 处理modified字段
        bool hasModified = false;
        status = napi_has_named_property(env, resObj, "modified", &hasModified);
        node_mbgl::napi_utils::check(status, "Failed to check modified property");
        
        if (hasModified) {
            napi_value modifiedValue;
            status = napi_get_named_property(env, resObj, "modified", &modifiedValue);
            node_mbgl::napi_utils::check(status, "Failed to get modified property");
            
            double modified = node_mbgl::napi_utils::toNumber(env, modifiedValue);
            if (!std::isnan(modified)) {
                response.modified = mbgl::Timestamp{mbgl::Seconds(static_cast<mbgl::Seconds::rep>(modified / 1000))};
            }
        }
        
        // 处理expires字段
        bool hasExpires = false;
        status = napi_has_named_property(env, resObj, "expires", &hasExpires);
        node_mbgl::napi_utils::check(status, "Failed to check expires property");
        
        if (hasExpires) {
            napi_value expiresValue;
            status = napi_get_named_property(env, resObj, "expires", &expiresValue);
            node_mbgl::napi_utils::check(status, "Failed to get expires property");
            
            double expires = node_mbgl::napi_utils::toNumber(env, expiresValue);
            if (!std::isnan(expires)) {
                response.expires = mbgl::Timestamp{mbgl::Seconds(static_cast<mbgl::Seconds::rep>(expires / 1000))};
            }
        }
        
        // 处理etag字段
        bool hasETag = false;
        status = napi_has_named_property(env, resObj, "etag", &hasETag);
        node_mbgl::napi_utils::check(status, "Failed to check etag property");
        
        if (hasETag) {
            napi_value etagValue;
            status = napi_get_named_property(env, resObj, "etag", &etagValue);
            node_mbgl::napi_utils::check(status, "Failed to get etag property");
            
            std::string etag = node_mbgl::napi_utils::toString(env, etagValue);
            response.etag = std::move(etag);
        }
        
        // 处理data字段
        bool hasData = false;
        status = napi_has_named_property(env, resObj, "data", &hasData);
        node_mbgl::napi_utils::check(status, "Failed to check data property");
        
        if (hasData) {
            napi_value dataValue;
            status = napi_get_named_property(env, resObj, "data", &dataValue);
            node_mbgl::napi_utils::check(status, "Failed to get data property");
            
            // 检查是否为Buffer
            bool isBuffer = false;
            napi_value bufferValue = nullptr;
            
            // 尝试获取buffer对象的方法
            status = napi_get_named_property(env, dataValue, "buffer", &bufferValue);
            if (status == napi_ok) {
                isBuffer = true;
            } else {
                // 重置状态
                status = napi_ok;
            }
            
            if (isBuffer) {
                // 获取Buffer数据
                size_t bufferLength;
                char* bufferData;
                
                status = napi_get_buffer_info(env, bufferValue, reinterpret_cast<void**>(&bufferData), &bufferLength);
                node_mbgl::napi_utils::check(status, "Failed to get buffer info");
                
                response.data = std::make_shared<std::string>(bufferData, bufferLength);
            } else {
                request->unrefRequest();
                node_mbgl::napi_utils::throwError(env, "Response data must be a Buffer");
                return nullptr;
            }
        }
    }

    // Send the response object to the NodeFileSource object
    callback(response);
    request->unrefRequest();
    
    return node_mbgl::napi_utils::createUndefined(env);
}

void NodeRequest::unrefRequest() {
    // 在N-API中，不需要显式调用Unref
    // 引用计数由napi_ref管理
}

NodeAsyncRequest::NodeAsyncRequest() = default;

NodeAsyncRequest::~NodeAsyncRequest() {
    if (request) {
        // Remove the callback function because the AsyncRequest was
        // canceled and we are no longer interested in the result.
        if (request->callback) {
            request->callback = {};
        }
        request->asyncRequest = nullptr;
    }
}

} // namespace node_mbgl
