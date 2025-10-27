#include "offline_region_napi.hpp"
#include "offline_region_definition_napi.hpp"
#include "offline_region_status_napi.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"

#include <mbgl/storage/response.hpp>
#include <mbgl/util/string.hpp>

namespace maplibre {
namespace harmony {

using Logger = mbgl::harmony::Logger;
using NapiArgs = mbgl::harmony::napi::NapiArgs;

// ========== 构造函数和析构函数 ==========

OfflineRegionNAPI::OfflineRegionNAPI(std::shared_ptr<mbgl::DatabaseFileSource> fileSource,
                                     std::unique_ptr<mbgl::OfflineRegion> region)
    : fileSource_(fileSource),
      region_(std::move(region)),
      env_(nullptr),
      wrapper_(nullptr),
      observerRef_(nullptr) {}

OfflineRegionNAPI::~OfflineRegionNAPI() {
    if (wrapper_ != nullptr) {
        napi_delete_reference(env_, wrapper_);
        wrapper_ = nullptr;
    }
    if (observerRef_ != nullptr) {
        napi_delete_reference(env_, observerRef_);
        observerRef_ = nullptr;
    }
}

void OfflineRegionNAPI::Destructor(napi_env env, void* nativeObject, void* /* finalize_hint */) {
    OfflineRegionNAPI* obj = static_cast<OfflineRegionNAPI*>(nativeObject);
    delete obj;
}

// ========== NAPI 初始化 ==========

napi_value OfflineRegionNAPI::Init(napi_env env, napi_value exports) {
    napi_status status;
    
    napi_property_descriptor properties[] = {
        {"getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getDefinition", nullptr, GetDefinition, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getMetadata", nullptr, GetMetadata, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setDownloadState", nullptr, SetDownloadState, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setObserver", nullptr, SetObserver, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getStatus", nullptr, GetStatus, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"delete", nullptr, Delete, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"invalidate", nullptr, Invalidate, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"updateMetadata", nullptr, UpdateMetadata, nullptr, nullptr, nullptr, napi_default, nullptr},
    };
    
    napi_value cons;
    status = napi_define_class(
        env, "OfflineRegion", NAPI_AUTO_LENGTH, Constructor, nullptr,
        sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("OfflineRegionNAPI", "Failed to define class");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "OfflineRegion", cons);
    if (status != napi_ok) {
        Logger::error("OfflineRegionNAPI", "Failed to export class");
        return nullptr;
    }
    
    return exports;
}

// ========== 创建 NAPI 对象 ==========

napi_value OfflineRegionNAPI::New(napi_env env, 
                                  std::shared_ptr<mbgl::DatabaseFileSource> fileSource,
                                  mbgl::OfflineRegion&& region) {
    napi_status status;
    
    // 获取构造函数
    napi_value cons;
    napi_value global;
    status = napi_get_global(env, &global);
    status = napi_get_named_property(env, global, "OfflineRegion", &cons);
    
    // 创建实例
    napi_value instance;
    status = napi_new_instance(env, cons, 0, nullptr, &instance);
    
    // 创建 C++ 对象
    auto regionPtr = std::make_unique<mbgl::OfflineRegion>(std::move(region));
    OfflineRegionNAPI* obj = new OfflineRegionNAPI(fileSource, std::move(regionPtr));
    obj->env_ = env;
    
    // 包装对象
    status = napi_wrap(env, instance, obj, OfflineRegionNAPI::Destructor, nullptr, &obj->wrapper_);
    
    if (status != napi_ok) {
        delete obj;
        return nullptr;
    }
    
    // 设置属性
    napi_value idValue;
    napi_create_int64(env, obj->region_->getID(), &idValue);
    napi_set_named_property(env, instance, "id", idValue);
    
    // 设置 definition
    napi_value definitionValue = OfflineRegionDefinitionNAPI::ToNapiObject(env, obj->region_->getDefinition());
    napi_set_named_property(env, instance, "definition", definitionValue);
    
    // 设置 metadata
    napi_value metadataValue = MetadataToArrayBuffer(env, obj->region_->getMetadata());
    napi_set_named_property(env, instance, "metadata", metadataValue);
    
    return instance;
}

// ========== 构造函数 ==========

napi_value OfflineRegionNAPI::Constructor(napi_env env, napi_callback_info info) {
    // 此构造函数不应该直接从 JS 调用
    // 只能通过 New 方法创建实例
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    return jsThis;
}

// ========== 实例方法 ==========

napi_value OfflineRegionNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    OfflineRegionNAPI* obj;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->region_) {
        napi_throw_error(env, nullptr, "Invalid OfflineRegion instance");
        return nullptr;
    }
    
    napi_value result;
    napi_create_int64(env, obj->region_->getID(), &result);
    return result;
}

napi_value OfflineRegionNAPI::GetDefinition(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    OfflineRegionNAPI* obj;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->region_) {
        napi_throw_error(env, nullptr, "Invalid OfflineRegion instance");
        return nullptr;
    }
    
    return OfflineRegionDefinitionNAPI::ToNapiObject(env, obj->region_->getDefinition());
}

napi_value OfflineRegionNAPI::GetMetadata(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    OfflineRegionNAPI* obj;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->region_) {
        napi_throw_error(env, nullptr, "Invalid OfflineRegion instance");
        return nullptr;
    }
    
    return MetadataToArrayBuffer(env, obj->region_->getMetadata());
}

napi_value OfflineRegionNAPI::SetDownloadState(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    int32_t state = args.GetInt32(0, "state");
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    OfflineRegionNAPI* obj;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->region_ || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineRegion instance");
        return nullptr;
    }
    
    mbgl::OfflineRegionDownloadState downloadState;
    if (state == 0) {
        downloadState = mbgl::OfflineRegionDownloadState::Inactive;
    } else if (state == 1) {
        downloadState = mbgl::OfflineRegionDownloadState::Active;
    } else {
        napi_throw_error(env, nullptr, "Invalid download state");
        return nullptr;
    }
    
    obj->fileSource_->setOfflineRegionDownloadState(*obj->region_, downloadState);
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value OfflineRegionNAPI::SetObserver(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    napi_value observer = args.GetObject(0, "observer");
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    OfflineRegionNAPI* obj;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->region_ || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineRegion instance");
        return nullptr;
    }
    
    // 保存观察者引用
    if (obj->observerRef_ != nullptr) {
        napi_delete_reference(env, obj->observerRef_);
    }
    napi_create_reference(env, observer, 1, &obj->observerRef_);
    
    // 创建观察者对象
    class Observer : public mbgl::OfflineRegionObserver {
    public:
        Observer(napi_env env, napi_ref observerRef)
            : env_(env), observerRef_(observerRef) {}
        
        void statusChanged(mbgl::OfflineRegionStatus status) override {
            napi_value observerObj;
            napi_get_reference_value(env_, observerRef_, &observerObj);
            
            napi_value onStatusChanged;
            napi_get_named_property(env_, observerObj, "onStatusChanged", &onStatusChanged);
            
            napi_value statusObj = OfflineRegionStatusNAPI::ToNapiObject(env_, status);
            
            napi_value global;
            napi_get_global(env_, &global);
            
            napi_value args[1] = {statusObj};
            napi_value result;
            napi_call_function(env_, observerObj, onStatusChanged, 1, args, &result);
        }
        
        void responseError(mbgl::Response::Error error) override {
            napi_value observerObj;
            napi_get_reference_value(env_, observerRef_, &observerObj);
            
            napi_value onError;
            napi_get_named_property(env_, observerObj, "onError", &onError);
            
            // 创建错误对象
            napi_value errorObj;
            napi_create_object(env_, &errorObj);
            
            // error.reason 是枚举类型，转换为字符串
            std::string reasonStr;
            switch (error.reason) {
                case mbgl::Response::Error::Reason::Success:
                    reasonStr = "Success";
                    break;
                case mbgl::Response::Error::Reason::NotFound:
                    reasonStr = "NotFound";
                    break;
                case mbgl::Response::Error::Reason::Server:
                    reasonStr = "Server";
                    break;
                case mbgl::Response::Error::Reason::Connection:
                    reasonStr = "Connection";
                    break;
                case mbgl::Response::Error::Reason::RateLimit:
                    reasonStr = "RateLimit";
                    break;
                case mbgl::Response::Error::Reason::Other:
                    reasonStr = "Other";
                    break;
                default:
                    reasonStr = "Unknown";
                    break;
            }
            
            napi_value reasonValue;
            napi_create_string_utf8(env_, reasonStr.c_str(), NAPI_AUTO_LENGTH, &reasonValue);
            napi_set_named_property(env_, errorObj, "reason", reasonValue);
            
            napi_value messageValue;
            napi_create_string_utf8(env_, error.message.c_str(), NAPI_AUTO_LENGTH, &messageValue);
            napi_set_named_property(env_, errorObj, "message", messageValue);
            
            napi_value global;
            napi_get_global(env_, &global);
            
            napi_value args[1] = {errorObj};
            napi_value result;
            napi_call_function(env_, observerObj, onError, 1, args, &result);
        }
        
        void mapboxTileCountLimitExceeded(uint64_t limit) override {
            napi_value observerObj;
            napi_get_reference_value(env_, observerRef_, &observerObj);
            
            napi_value onLimitExceeded;
            napi_get_named_property(env_, observerObj, "mapboxTileCountLimitExceeded", &onLimitExceeded);
            
            napi_value limitValue;
            napi_create_int64(env_, static_cast<int64_t>(limit), &limitValue);
            
            napi_value global;
            napi_get_global(env_, &global);
            
            napi_value args[1] = {limitValue};
            napi_value result;
            napi_call_function(env_, observerObj, onLimitExceeded, 1, args, &result);
        }
        
    private:
        napi_env env_;
        napi_ref observerRef_;
    };
    
    obj->fileSource_->setOfflineRegionObserver(
        *obj->region_,
        std::make_unique<Observer>(env, obj->observerRef_)
    );
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value OfflineRegionNAPI::GetStatus(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    napi_value callback = args.GetFunction(0, "callback");
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    OfflineRegionNAPI* obj;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->region_ || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineRegion instance");
        return nullptr;
    }
    
    napi_ref callbackRef;
    napi_create_reference(env, callback, 1, &callbackRef);
    
    obj->fileSource_->getOfflineRegionStatus(
        *obj->region_,
        [env, callbackRef](mbgl::expected<mbgl::OfflineRegionStatus, std::exception_ptr> status) {
            napi_value callback_func;
            napi_get_reference_value(env, callbackRef, &callback_func);
            
            napi_value global;
            napi_get_global(env, &global);
            
            if (status) {
                napi_value statusObj = OfflineRegionStatusNAPI::ToNapiObject(env, *status);
                napi_value args[1] = {statusObj};
                napi_value ret;
                napi_call_function(env, global, callback_func, 1, args, &ret);
            } else {
                std::string errorMsg = mbgl::util::toString(status.error());
                napi_value errorValue;
                napi_create_string_utf8(env, errorMsg.c_str(), NAPI_AUTO_LENGTH, &errorValue);
                napi_value args[1] = {errorValue};
                napi_value ret;
                napi_call_function(env, global, callback_func, 1, args, &ret);
            }
            
            napi_delete_reference(env, callbackRef);
        }
    );
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value OfflineRegionNAPI::Delete(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    napi_value callback = args.GetFunction(0, "callback");
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    OfflineRegionNAPI* obj;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->region_ || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineRegion instance");
        return nullptr;
    }
    
    napi_ref callbackRef;
    napi_create_reference(env, callback, 1, &callbackRef);
    
    obj->fileSource_->deleteOfflineRegion(
        *obj->region_,
        [env, callbackRef](std::exception_ptr error) {
            napi_value callback_func;
            napi_get_reference_value(env, callbackRef, &callback_func);
            
            napi_value global;
            napi_get_global(env, &global);
            
            if (error) {
                std::string errorMsg = mbgl::util::toString(error);
                napi_value errorValue;
                napi_create_string_utf8(env, errorMsg.c_str(), NAPI_AUTO_LENGTH, &errorValue);
                napi_value args[1] = {errorValue};
                napi_value ret;
                napi_call_function(env, global, callback_func, 1, args, &ret);
            } else {
                napi_value args[0] = {};
                napi_value ret;
                napi_call_function(env, global, callback_func, 0, args, &ret);
            }
            
            napi_delete_reference(env, callbackRef);
        }
    );
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value OfflineRegionNAPI::Invalidate(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    napi_value callback = args.GetFunction(0, "callback");
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    OfflineRegionNAPI* obj;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->region_ || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineRegion instance");
        return nullptr;
    }
    
    napi_ref callbackRef;
    napi_create_reference(env, callback, 1, &callbackRef);
    
    obj->fileSource_->invalidateOfflineRegion(
        *obj->region_,
        [env, callbackRef](std::exception_ptr error) {
            napi_value callback_func;
            napi_get_reference_value(env, callbackRef, &callback_func);
            
            napi_value global;
            napi_get_global(env, &global);
            
            if (error) {
                std::string errorMsg = mbgl::util::toString(error);
                napi_value errorValue;
                napi_create_string_utf8(env, errorMsg.c_str(), NAPI_AUTO_LENGTH, &errorValue);
                napi_value args[1] = {errorValue};
                napi_value ret;
                napi_call_function(env, global, callback_func, 1, args, &ret);
            } else {
                napi_value args[0] = {};
                napi_value ret;
                napi_call_function(env, global, callback_func, 0, args, &ret);
            }
            
            napi_delete_reference(env, callbackRef);
        }
    );
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value OfflineRegionNAPI::UpdateMetadata(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) return nullptr;
    
    // 获取原始参数
    size_t argc = 2;
    napi_value argv[2];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    
    napi_value metadataValue = argv[0];
    napi_value callback = args.GetFunction(1, "callback");
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    OfflineRegionNAPI* obj;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->region_ || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineRegion instance");
        return nullptr;
    }
    
    mbgl::OfflineRegionMetadata metadata = ArrayBufferToMetadata(env, metadataValue);
    
    napi_ref callbackRef;
    napi_create_reference(env, callback, 1, &callbackRef);
    
    obj->fileSource_->updateOfflineMetadata(
        obj->region_->getID(),
        metadata,
        [env, callbackRef](mbgl::expected<mbgl::OfflineRegionMetadata, std::exception_ptr> result) {
            napi_value callback_func;
            napi_get_reference_value(env, callbackRef, &callback_func);
            
            napi_value global;
            napi_get_global(env, &global);
            
            if (result) {
                napi_value metadataValue = OfflineRegionNAPI::MetadataToArrayBuffer(env, *result);
                napi_value args[1] = {metadataValue};
                napi_value ret;
                napi_call_function(env, global, callback_func, 1, args, &ret);
            } else {
                std::string errorMsg = mbgl::util::toString(result.error());
                napi_value errorValue;
                napi_create_string_utf8(env, errorMsg.c_str(), NAPI_AUTO_LENGTH, &errorValue);
                napi_value args[1] = {errorValue};
                napi_value ret;
                napi_call_function(env, global, callback_func, 1, args, &ret);
            }
            
            napi_delete_reference(env, callbackRef);
        }
    );
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

// ========== 辅助函数 ==========

napi_value OfflineRegionNAPI::MetadataToArrayBuffer(napi_env env, const mbgl::OfflineRegionMetadata& metadata) {
    napi_value arrayBuffer;
    void* data;
    napi_create_arraybuffer(env, metadata.size(), &data, &arrayBuffer);
    std::memcpy(data, metadata.data(), metadata.size());
    return arrayBuffer;
}

mbgl::OfflineRegionMetadata OfflineRegionNAPI::ArrayBufferToMetadata(napi_env env, napi_value arrayBuffer) {
    void* data;
    size_t length;
    napi_get_arraybuffer_info(env, arrayBuffer, &data, &length);
    
    mbgl::OfflineRegionMetadata metadata(length);
    std::memcpy(metadata.data(), data, length);
    return metadata;
}

} // namespace harmony
} // namespace maplibre

