#include "offline_region_napi.hpp"
#include "offline_region_definition_napi.hpp"
#include "offline_region_status_napi.hpp"
#include "core/thread_safe_callback.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"

#include <mbgl/storage/response.hpp>
#include <mbgl/util/string.hpp>

#include <cstring>

namespace maplibre {
namespace harmony {

using Logger = mbgl::harmony::Logger;
using NapiArgs = mbgl::harmony::napi::NapiArgs;

namespace {

// Resolve one observer method (e.g. onStatusChanged) into a thread-safe callback.
// Returns nullptr when the method is absent or not a function.
std::shared_ptr<mbgl::harmony::ThreadSafeCallback> GetObserverMethodCallback(
    napi_env env, napi_value observer, const char* methodName, const char* resource) {
    napi_value fn = nullptr;
    if (napi_get_named_property(env, observer, methodName, &fn) != napi_ok || fn == nullptr) {
        return nullptr;
    }
    napi_valuetype type = napi_undefined;
    if (napi_typeof(env, fn, &type) != napi_ok || type != napi_function) {
        return nullptr;
    }
    return std::shared_ptr<mbgl::harmony::ThreadSafeCallback>(
        mbgl::harmony::ThreadSafeCallback::Create(env, fn, resource));
}

} // namespace

// Static constructor reference initialization
napi_ref OfflineRegionNAPI::constructor_ = nullptr;

// ========== Constructors and Destructors ==========

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

// ========== NAPI Initialization ==========

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
    
    // Store constructor reference
    status = napi_create_reference(env, cons, 1, &constructor_);
    if (status != napi_ok) {
        Logger::error("OfflineRegionNAPI", "Failed to create constructor reference");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "OfflineRegion", cons);
    if (status != napi_ok) {
        Logger::error("OfflineRegionNAPI", "Failed to export class");
        return nullptr;
    }
    
    return exports;
}

// ========== Create NAPI Objects ==========

napi_value OfflineRegionNAPI::New(napi_env env, 
                                  std::shared_ptr<mbgl::DatabaseFileSource> fileSource,
                                  mbgl::OfflineRegion&& region) {
    napi_status status;
    
    // Check whether constructor reference is initialized
    if (constructor_ == nullptr) {
        Logger::error("OfflineRegionNAPI", "Constructor reference is null. Make sure Init() was called.");
        return nullptr;
    }
    
    // Obtain constructor from reference
    napi_value cons = nullptr;
    status = napi_get_reference_value(env, constructor_, &cons);
    if (status != napi_ok || cons == nullptr) {
        Logger::error("OfflineRegionNAPI", "Failed to get constructor from reference");
        return nullptr;
    }
    
    // Create instance
    napi_value instance = nullptr;
    status = napi_new_instance(env, cons, 0, nullptr, &instance);
    if (status != napi_ok || instance == nullptr) {
        Logger::error("OfflineRegionNAPI", "Failed to create instance");
        return nullptr;
    }
    
    // Create C++ object
    auto regionPtr = std::make_unique<mbgl::OfflineRegion>(std::move(region));
    OfflineRegionNAPI* obj = new OfflineRegionNAPI(fileSource, std::move(regionPtr));
    obj->env_ = env;
    
    // Wrap object
    status = napi_wrap(env, instance, obj, OfflineRegionNAPI::Destructor, nullptr, &obj->wrapper_);
    
    if (status != napi_ok) {
        Logger::error("OfflineRegionNAPI", "Failed to wrap native object");
        delete obj;
        return nullptr;
    }
    
    // Set properties
    napi_value idValue;
    napi_create_int64(env, obj->region_->getID(), &idValue);
    napi_set_named_property(env, instance, "id", idValue);
    
    // Set definition
    napi_value definitionValue = OfflineRegionDefinitionNAPI::ToNapiObject(env, obj->region_->getDefinition());
    napi_set_named_property(env, instance, "definition", definitionValue);
    
    // Set metadata
    napi_value metadataValue = MetadataToArrayBuffer(env, obj->region_->getMetadata());
    napi_set_named_property(env, instance, "metadata", metadataValue);
    
    return instance;
}

// ========== Constructor ==========

napi_value OfflineRegionNAPI::Constructor(napi_env env, napi_callback_info info) {
    // This constructor should not be invoked directly from JS
    // Instances must be created via the New method
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    return jsThis;
}

// ========== Instance Methods ==========

napi_value OfflineRegionNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    OfflineRegionNAPI* obj = nullptr;
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
    
    OfflineRegionNAPI* obj = nullptr;
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
    
    OfflineRegionNAPI* obj = nullptr;
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
    
    OfflineRegionNAPI* obj = nullptr;
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
    
    OfflineRegionNAPI* obj = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->region_ || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineRegion instance");
        return nullptr;
    }
    
    // Store observer reference (kept only for JS-side lifetime management on the JS thread)
    if (obj->observerRef_ != nullptr) {
        napi_delete_reference(env, obj->observerRef_);
        obj->observerRef_ = nullptr;
    }
    napi_create_reference(env, observer, 1, &obj->observerRef_);
    
    // Resolve each observer method into a thread-safe callback. The observer's
    // methods are invoked by DatabaseFileSource on the database thread, so all
    // N-API work must be marshalled back to the JS thread via tsfn.
    auto statusCb = GetObserverMethodCallback(env, observer, "onStatusChanged", "OfflineRegionStatusChanged");
    auto errorCb = GetObserverMethodCallback(env, observer, "onError", "OfflineRegionResponseError");
    auto limitCb = GetObserverMethodCallback(env, observer, "mapboxTileCountLimitExceeded", "OfflineRegionTileLimitExceeded");
    
    // Create observer object
    class Observer : public mbgl::OfflineRegionObserver {
    public:
        Observer(std::shared_ptr<mbgl::harmony::ThreadSafeCallback> statusCb,
                 std::shared_ptr<mbgl::harmony::ThreadSafeCallback> errorCb,
                 std::shared_ptr<mbgl::harmony::ThreadSafeCallback> limitCb)
            : statusCb_(std::move(statusCb)),
              errorCb_(std::move(errorCb)),
              limitCb_(std::move(limitCb)) {}
        
        void statusChanged(mbgl::OfflineRegionStatus status) override {
            if (!statusCb_) return;
            statusCb_->Call([status](napi_env env) -> napi_value {
                return OfflineRegionStatusNAPI::ToNapiObject(env, status);
            });
        }
        
        void responseError(mbgl::Response::Error error) override {
            if (!errorCb_) return;
            errorCb_->Call([error = std::move(error)](napi_env env) -> napi_value {
                napi_value errorObj;
                if (napi_create_object(env, &errorObj) != napi_ok) {
                    napi_get_undefined(env, &errorObj);
                    return errorObj;
                }
                
                // error.reason is an enum; convert to string
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
                napi_create_string_utf8(env, reasonStr.c_str(), NAPI_AUTO_LENGTH, &reasonValue);
                napi_set_named_property(env, errorObj, "reason", reasonValue);
                
                napi_value messageValue;
                napi_create_string_utf8(env, error.message.c_str(), NAPI_AUTO_LENGTH, &messageValue);
                napi_set_named_property(env, errorObj, "message", messageValue);
                
                return errorObj;
            });
        }
        
        void mapboxTileCountLimitExceeded(uint64_t limit) override {
            if (!limitCb_) return;
            limitCb_->Call([limit](napi_env env) -> napi_value {
                napi_value limitValue;
                napi_create_int64(env, static_cast<int64_t>(limit), &limitValue);
                return limitValue;
            });
        }
        
    private:
        std::shared_ptr<mbgl::harmony::ThreadSafeCallback> statusCb_;
        std::shared_ptr<mbgl::harmony::ThreadSafeCallback> errorCb_;
        std::shared_ptr<mbgl::harmony::ThreadSafeCallback> limitCb_;
    };
    
    obj->fileSource_->setOfflineRegionObserver(
        *obj->region_,
        std::make_unique<Observer>(std::move(statusCb), std::move(errorCb), std::move(limitCb))
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
    
    OfflineRegionNAPI* obj = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->region_ || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineRegion instance");
        return nullptr;
    }
    
    // DatabaseFileSource invokes its completion on the database thread; marshal
    // back to the JS thread via ThreadSafeCallback instead of calling NAPI directly.
    auto jsCallback = std::shared_ptr<mbgl::harmony::ThreadSafeCallback>(
        mbgl::harmony::ThreadSafeCallback::Create(env, callback, "OfflineRegionGetStatus"));
    if (!jsCallback) {
        napi_throw_error(env, nullptr, "Failed to create thread-safe callback");
        return nullptr;
    }
    
    obj->fileSource_->getOfflineRegionStatus(
        *obj->region_,
        [jsCallback](mbgl::expected<mbgl::OfflineRegionStatus, std::exception_ptr> status) {
            jsCallback->CallBlocking([status](napi_env env) -> napi_value {
                if (status) {
                    return OfflineRegionStatusNAPI::ToNapiObject(env, *status);
                }
                std::string errorMsg = mbgl::util::toString(status.error());
                napi_value errorValue;
                napi_create_string_utf8(env, errorMsg.c_str(), NAPI_AUTO_LENGTH, &errorValue);
                return errorValue;
            });
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
    
    OfflineRegionNAPI* obj = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->region_ || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineRegion instance");
        return nullptr;
    }
    
    auto jsCallback = std::shared_ptr<mbgl::harmony::ThreadSafeCallback>(
        mbgl::harmony::ThreadSafeCallback::Create(env, callback, "OfflineRegionDelete"));
    if (!jsCallback) {
        napi_throw_error(env, nullptr, "Failed to create thread-safe callback");
        return nullptr;
    }
    
    obj->fileSource_->deleteOfflineRegion(
        *obj->region_,
        [jsCallback](std::exception_ptr error) {
            jsCallback->CallBlocking([error](napi_env env) -> napi_value {
                if (error) {
                    std::string errorMsg = mbgl::util::toString(error);
                    napi_value errorValue;
                    napi_create_string_utf8(env, errorMsg.c_str(), NAPI_AUTO_LENGTH, &errorValue);
                    return errorValue;
                }
                napi_value undefined;
                napi_get_undefined(env, &undefined);
                return undefined;
            });
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
    
    OfflineRegionNAPI* obj = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->region_ || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineRegion instance");
        return nullptr;
    }
    
    auto jsCallback = std::shared_ptr<mbgl::harmony::ThreadSafeCallback>(
        mbgl::harmony::ThreadSafeCallback::Create(env, callback, "OfflineRegionInvalidate"));
    if (!jsCallback) {
        napi_throw_error(env, nullptr, "Failed to create thread-safe callback");
        return nullptr;
    }
    
    obj->fileSource_->invalidateOfflineRegion(
        *obj->region_,
        [jsCallback](std::exception_ptr error) {
            jsCallback->CallBlocking([error](napi_env env) -> napi_value {
                if (error) {
                    std::string errorMsg = mbgl::util::toString(error);
                    napi_value errorValue;
                    napi_create_string_utf8(env, errorMsg.c_str(), NAPI_AUTO_LENGTH, &errorValue);
                    return errorValue;
                }
                napi_value undefined;
                napi_get_undefined(env, &undefined);
                return undefined;
            });
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
    
    // Retrieve raw argument list
    size_t argc = 2;
    napi_value argv[2];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    
    napi_value metadataValue = argv[0];
    napi_value callback = args.GetFunction(1, "callback");
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    OfflineRegionNAPI* obj = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->region_ || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineRegion instance");
        return nullptr;
    }
    
    mbgl::OfflineRegionMetadata metadata = ArrayBufferToMetadata(env, metadataValue);
    // ArrayBufferToMetadata throws into JS on invalid input; surface it instead
    // of silently forwarding empty metadata.
    bool pending = false;
    if (napi_is_exception_pending(env, &pending) == napi_ok && pending) {
        return nullptr;
    }
    
    auto jsCallback = std::shared_ptr<mbgl::harmony::ThreadSafeCallback>(
        mbgl::harmony::ThreadSafeCallback::Create(env, callback, "OfflineRegionUpdateMetadata"));
    if (!jsCallback) {
        napi_throw_error(env, nullptr, "Failed to create thread-safe callback");
        return nullptr;
    }
    
    obj->fileSource_->updateOfflineMetadata(
        obj->region_->getID(),
        metadata,
        [jsCallback](mbgl::expected<mbgl::OfflineRegionMetadata, std::exception_ptr> result) {
            jsCallback->CallBlocking([result](napi_env env) -> napi_value {
                if (result) {
                    return OfflineRegionNAPI::MetadataToArrayBuffer(env, *result);
                }
                std::string errorMsg = mbgl::util::toString(result.error());
                napi_value errorValue;
                napi_create_string_utf8(env, errorMsg.c_str(), NAPI_AUTO_LENGTH, &errorValue);
                return errorValue;
            });
        }
    );
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

// ========== Helper Functions ==========

napi_value OfflineRegionNAPI::MetadataToArrayBuffer(napi_env env, const mbgl::OfflineRegionMetadata& metadata) {
    napi_value arrayBuffer = nullptr;
    void* data = nullptr;
    napi_status status = napi_create_arraybuffer(env, metadata.size(), &data, &arrayBuffer);
    if (status != napi_ok) {
        Logger::error("OfflineRegionNAPI", "Failed to create metadata arraybuffer");
        napi_get_undefined(env, &arrayBuffer);
        return arrayBuffer;
    }
    if (data != nullptr && !metadata.empty()) {
        std::memcpy(data, metadata.data(), metadata.size());
    }
    return arrayBuffer;
}

mbgl::OfflineRegionMetadata OfflineRegionNAPI::ArrayBufferToMetadata(napi_env env, napi_value arrayBuffer) {
    void* data = nullptr;
    size_t length = 0;
    bool isArrayBuffer = false;
    if (arrayBuffer == nullptr ||
        napi_is_arraybuffer(env, arrayBuffer, &isArrayBuffer) != napi_ok || !isArrayBuffer ||
        napi_get_arraybuffer_info(env, arrayBuffer, &data, &length) != napi_ok) {
        napi_throw_error(env, nullptr, "metadata must be an ArrayBuffer");
        return {};
    }
    
    mbgl::OfflineRegionMetadata metadata(length);
    if (data != nullptr && length > 0) {
        std::memcpy(metadata.data(), data, length);
    }
    return metadata;
}

} // namespace harmony
} // namespace maplibre
