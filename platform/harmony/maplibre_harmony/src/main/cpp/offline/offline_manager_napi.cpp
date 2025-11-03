#include "offline_manager_napi.hpp"
#include "offline_region_napi.hpp"
#include "offline_region_definition_napi.hpp"
#include "napi/core/napi_args.hpp"
#include "core/thread_safe_callback.hpp"
#include "utils/logger.h"

#include <mbgl/storage/file_source_manager.hpp>
#include <mbgl/storage/resource_options.hpp>
#include <mbgl/util/client_options.hpp>
#include <mbgl/util/string.hpp>

namespace maplibre {
namespace harmony {

using Logger = mbgl::harmony::Logger;
using NapiArgs = mbgl::harmony::napi::NapiArgs;

// ========== 构造函数和析构函数 ==========

OfflineManagerNAPI::OfflineManagerNAPI(std::shared_ptr<mbgl::DatabaseFileSource> fileSource)
    : fileSource_(fileSource), env_(nullptr), wrapper_(nullptr) {}

OfflineManagerNAPI::~OfflineManagerNAPI() {
    if (wrapper_ != nullptr) {
        napi_delete_reference(env_, wrapper_);
        wrapper_ = nullptr;
    }
}

void OfflineManagerNAPI::Destructor(napi_env env, void* nativeObject, void* /* finalize_hint */) {
    OfflineManagerNAPI* obj = static_cast<OfflineManagerNAPI*>(nativeObject);
    delete obj;
}

// ========== NAPI 初始化 ==========

napi_value OfflineManagerNAPI::Init(napi_env env, napi_value exports) {
    napi_status status;
    
    napi_property_descriptor properties[] = {
        {"listOfflineRegions", nullptr, ListOfflineRegions, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"createOfflineRegion", nullptr, CreateOfflineRegion, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getOfflineRegion", nullptr, GetOfflineRegion, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"mergeOfflineRegions", nullptr, MergeOfflineRegions, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"resetDatabase", nullptr, ResetDatabase, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"packDatabase", nullptr, PackDatabase, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"invalidateAmbientCache", nullptr, InvalidateAmbientCache, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"clearAmbientCache", nullptr, ClearAmbientCache, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setMaximumAmbientCacheSize", nullptr, SetMaximumAmbientCacheSize, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setOfflineMapboxTileCountLimit", nullptr, SetOfflineMapboxTileCountLimit, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"runPackDatabaseAutomatically", nullptr, RunPackDatabaseAutomatically, nullptr, nullptr, nullptr, napi_default, nullptr},
    };
    
    napi_value cons;
    status = napi_define_class(
        env, "OfflineManager", NAPI_AUTO_LENGTH, Constructor, nullptr,
        sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("OfflineManagerNAPI", "Failed to define class");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "OfflineManager", cons);
    if (status != napi_ok) {
        Logger::error("OfflineManagerNAPI", "Failed to export class");
        return nullptr;
    }
    
    return exports;
}

// ========== 构造函数 ==========

napi_value OfflineManagerNAPI::Constructor(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    // 获取参数：数据库路径、可选的 ResourceOptions
    std::string cachePath = args.GetString(0, "cachePath");
    if (args.HasError()) return nullptr;
    
    // 创建 ResourceOptions 和 ClientOptions
    mbgl::ResourceOptions resourceOptions;
    resourceOptions.withCachePath(cachePath);
    
    mbgl::ClientOptions clientOptions;
    
    // 获取 DatabaseFileSource 实例
    auto fileSource = std::static_pointer_cast<mbgl::DatabaseFileSource>(
        mbgl::FileSourceManager::get()->getFileSource(
            mbgl::FileSourceType::Database,
            resourceOptions,
            clientOptions
        )
    );
    
    if (!fileSource) {
        napi_throw_error(env, nullptr, "Failed to create DatabaseFileSource");
        return nullptr;
    }
    
    // 创建 C++ 对象
    OfflineManagerNAPI* obj = new OfflineManagerNAPI(fileSource);
    obj->env_ = env;
    
    // 获取 this 对象
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    // 包装 C++ 对象
    napi_status status = napi_wrap(
        env, jsThis, obj,
        OfflineManagerNAPI::Destructor,
        nullptr, &obj->wrapper_
    );
    
    if (status != napi_ok) {
        delete obj;
        napi_throw_error(env, nullptr, "Failed to wrap native object");
        return nullptr;
    }
    
    return jsThis;
}

// ========== listOfflineRegions ==========

napi_value OfflineManagerNAPI::ListOfflineRegions(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    // 获取回调函数
    napi_value callback = args.GetFunction(0, "callback");
    if (args.HasError()) return nullptr;
    
    // 获取 this
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    OfflineManagerNAPI* obj;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineManager instance");
        return nullptr;
    }
    
    // 创建线程安全回调
    auto threadSafeCallback = std::shared_ptr<mbgl::harmony::ThreadSafeCallback>(
        mbgl::harmony::ThreadSafeCallback::Create(env, callback, "ListOfflineRegions").release()
    );
    if (!threadSafeCallback) {
        napi_throw_error(env, nullptr, "Failed to create thread-safe callback");
        return nullptr;
    }
    
    // 调用核心库方法
    auto fileSource = obj->fileSource_;
    auto tsfCallback = threadSafeCallback;  // 复制 shared_ptr
    fileSource->listOfflineRegions([tsfCallback, fileSource](
        mbgl::expected<mbgl::OfflineRegions, std::exception_ptr> regions) {
        
        // 使用线程安全回调在主线程执行
        tsfCallback->Call([regions = std::move(regions), fileSource](napi_env env) mutable -> napi_value {
            if (regions) {
                // 成功 - 创建区域数组
                napi_value regionsArray;
                napi_create_array_with_length(env, regions->size(), &regionsArray);
                
                for (size_t i = 0; i < regions->size(); i++) {
                    napi_value regionObj = OfflineRegionNAPI::New(env, fileSource, std::move((*regions)[i]));
                    napi_set_element(env, regionsArray, i, regionObj);
                }
                
                return regionsArray;
            } else {
                // 错误
                std::string errorMsg = mbgl::util::toString(regions.error());
                napi_value errorValue;
                napi_create_string_utf8(env, errorMsg.c_str(), NAPI_AUTO_LENGTH, &errorValue);
                return errorValue;
            }
        });
        
        // ThreadSafeCallback 会在这里自动释放
    });
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

// ========== createOfflineRegion ==========

napi_value OfflineManagerNAPI::CreateOfflineRegion(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(3);
    if (args.HasError()) return nullptr;
    
    // 获取参数：definition, metadata, callback
    napi_value definitionObj = args.GetObject(0, "definition");
    napi_value callback = args.GetFunction(2, "callback");
    if (args.HasError()) return nullptr;
    
    // 获取 metadata 参数
    size_t argc = 3;
    napi_value argv[3];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    napi_value metadataValue = argv[1];
    
    // 解析 definition
    mbgl::OfflineRegionDefinition definition = OfflineRegionDefinitionNAPI::FromNapiObject(env, definitionObj);
    
    // 解析 metadata (ArrayBuffer)
    mbgl::OfflineRegionMetadata metadata;
    napi_valuetype metadataType;
    napi_typeof(env, metadataValue, &metadataType);
    if (metadataType != napi_null && metadataType != napi_undefined) {
        metadata = OfflineRegionNAPI::ArrayBufferToMetadata(env, metadataValue);
    }
    
    // 获取 this
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    OfflineManagerNAPI* obj;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineManager instance");
        return nullptr;
    }
    
    // 创建线程安全回调
    auto threadSafeCallback = std::shared_ptr<mbgl::harmony::ThreadSafeCallback>(
        mbgl::harmony::ThreadSafeCallback::Create(env, callback, "CreateOfflineRegion").release()
    );
    if (!threadSafeCallback) {
        napi_throw_error(env, nullptr, "Failed to create thread-safe callback");
        return nullptr;
    }
    
    // 调用核心库方法
    auto fileSource = obj->fileSource_;
    auto tsfCallback = threadSafeCallback;  // 复制 shared_ptr
    fileSource->createOfflineRegion(
        definition,
        metadata,
        [tsfCallback, fileSource](mbgl::expected<mbgl::OfflineRegion, std::exception_ptr> region) {
            
            // 使用线程安全回调在主线程执行
            tsfCallback->Call([region = std::move(region), fileSource](napi_env env) mutable -> napi_value {
                if (region) {
                    // 成功 - 创建 OfflineRegion 对象
                    napi_value regionObj = OfflineRegionNAPI::New(env, fileSource, std::move(*region));
                    return regionObj;
                } else {
                    // 错误
                    std::string errorMsg = mbgl::util::toString(region.error());
                    napi_value errorValue;
                    napi_create_string_utf8(env, errorMsg.c_str(), NAPI_AUTO_LENGTH, &errorValue);
                    return errorValue;
                }
            });
        }
    );
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

// ========== 其他方法 ==========

napi_value OfflineManagerNAPI::GetOfflineRegion(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) return nullptr;
    
    int64_t regionId = args.GetInt64(0, "regionId");
    napi_value callback = args.GetFunction(1, "callback");
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    OfflineManagerNAPI* obj;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineManager instance");
        return nullptr;
    }
    
    // 创建线程安全回调
    auto threadSafeCallback = std::shared_ptr<mbgl::harmony::ThreadSafeCallback>(
        mbgl::harmony::ThreadSafeCallback::Create(env, callback, "GetOfflineRegion").release()
    );
    if (!threadSafeCallback) {
        napi_throw_error(env, nullptr, "Failed to create thread-safe callback");
        return nullptr;
    }
    
    auto fileSource = obj->fileSource_;
    auto tsfCallback = threadSafeCallback;  // 复制 shared_ptr
    fileSource->getOfflineRegion(regionId, [tsfCallback, fileSource](
        mbgl::expected<std::optional<mbgl::OfflineRegion>, std::exception_ptr> result) {
        
        // 使用线程安全回调在主线程执行
        tsfCallback->Call([result = std::move(result), fileSource](napi_env env) mutable -> napi_value {
            if (result && result->has_value()) {
                // 找到区域
                napi_value regionObj = OfflineRegionNAPI::New(env, fileSource, std::move(**result));
                return regionObj;
            } else if (result) {
                // Region not found
                napi_value nullValue;
                napi_get_null(env, &nullValue);
                return nullValue;
            } else {
                // Error
                std::string errorMsg = mbgl::util::toString(result.error());
                napi_value errorValue;
                napi_create_string_utf8(env, errorMsg.c_str(), NAPI_AUTO_LENGTH, &errorValue);
                return errorValue;
            }
        });
    });
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value OfflineManagerNAPI::MergeOfflineRegions(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) return nullptr;
    
    std::string path = args.GetString(0, "path");
    napi_value callback = args.GetFunction(1, "callback");
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    OfflineManagerNAPI* obj;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineManager instance");
        return nullptr;
    }
    
    // 创建线程安全回调
    auto threadSafeCallback = std::shared_ptr<mbgl::harmony::ThreadSafeCallback>(
        mbgl::harmony::ThreadSafeCallback::Create(env, callback, "MergeOfflineRegions").release()
    );
    if (!threadSafeCallback) {
        napi_throw_error(env, nullptr, "Failed to create thread-safe callback");
        return nullptr;
    }
    
    auto fileSource = obj->fileSource_;
    auto tsfCallback = threadSafeCallback;  // 复制 shared_ptr
    fileSource->mergeOfflineRegions(path, [tsfCallback, fileSource](
        mbgl::expected<mbgl::OfflineRegions, std::exception_ptr> regions) {
        
        // 使用线程安全回调在主线程执行
        tsfCallback->Call([regions = std::move(regions), fileSource](napi_env env) mutable -> napi_value {
            if (regions) {
                napi_value regionsArray;
                napi_create_array_with_length(env, regions->size(), &regionsArray);
                
                for (size_t i = 0; i < regions->size(); i++) {
                    napi_value regionObj = OfflineRegionNAPI::New(env, fileSource, std::move((*regions)[i]));
                    napi_set_element(env, regionsArray, i, regionObj);
                }
                
                return regionsArray;
            } else {
                std::string errorMsg = mbgl::util::toString(regions.error());
                napi_value errorValue;
                napi_create_string_utf8(env, errorMsg.c_str(), NAPI_AUTO_LENGTH, &errorValue);
                return errorValue;
            }
        });
    });
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value OfflineManagerNAPI::ResetDatabase(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    napi_value callback = args.GetFunction(0, "callback");
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    OfflineManagerNAPI* obj;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineManager instance");
        return nullptr;
    }
    
    auto threadSafeCallback = std::shared_ptr<mbgl::harmony::ThreadSafeCallback>(
        mbgl::harmony::ThreadSafeCallback::Create(env, callback, "ResetDatabase").release()
    );
    if (!threadSafeCallback) {
        napi_throw_error(env, nullptr, "Failed to create thread-safe callback");
        return nullptr;
    }
    
    obj->fileSource_->resetDatabase([threadSafeCallback](std::exception_ptr error) {
        threadSafeCallback->Call([error](napi_env env) -> napi_value {
            if (error) {
                std::string errorMsg = mbgl::util::toString(error);
                napi_value errorValue;
                napi_create_string_utf8(env, errorMsg.c_str(), NAPI_AUTO_LENGTH, &errorValue);
                return errorValue;
            } else {
                napi_value undefined;
                napi_get_undefined(env, &undefined);
                return undefined;
            }
        });
    });
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value OfflineManagerNAPI::PackDatabase(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    napi_value callback = args.GetFunction(0, "callback");
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    OfflineManagerNAPI* obj;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineManager instance");
        return nullptr;
    }
    
    auto threadSafeCallback = std::shared_ptr<mbgl::harmony::ThreadSafeCallback>(
        mbgl::harmony::ThreadSafeCallback::Create(env, callback, "PackDatabase").release()
    );
    if (!threadSafeCallback) {
        napi_throw_error(env, nullptr, "Failed to create thread-safe callback");
        return nullptr;
    }
    
    obj->fileSource_->packDatabase([threadSafeCallback](std::exception_ptr error) {
        threadSafeCallback->Call([error](napi_env env) -> napi_value {
            if (error) {
                std::string errorMsg = mbgl::util::toString(error);
                napi_value errorValue;
                napi_create_string_utf8(env, errorMsg.c_str(), NAPI_AUTO_LENGTH, &errorValue);
                return errorValue;
            } else {
                napi_value undefined;
                napi_get_undefined(env, &undefined);
                return undefined;
            }
        });
    });
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value OfflineManagerNAPI::InvalidateAmbientCache(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    napi_value callback = args.GetFunction(0, "callback");
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    OfflineManagerNAPI* obj;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineManager instance");
        return nullptr;
    }
    
    auto threadSafeCallback = std::shared_ptr<mbgl::harmony::ThreadSafeCallback>(
        mbgl::harmony::ThreadSafeCallback::Create(env, callback, "InvalidateAmbientCache").release()
    );
    if (!threadSafeCallback) {
        napi_throw_error(env, nullptr, "Failed to create thread-safe callback");
        return nullptr;
    }
    
    obj->fileSource_->invalidateAmbientCache([threadSafeCallback](std::exception_ptr error) {
        threadSafeCallback->Call([error](napi_env env) -> napi_value {
            if (error) {
                std::string errorMsg = mbgl::util::toString(error);
                napi_value errorValue;
                napi_create_string_utf8(env, errorMsg.c_str(), NAPI_AUTO_LENGTH, &errorValue);
                return errorValue;
            } else {
                napi_value undefined;
                napi_get_undefined(env, &undefined);
                return undefined;
            }
        });
    });
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value OfflineManagerNAPI::ClearAmbientCache(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    napi_value callback = args.GetFunction(0, "callback");
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    OfflineManagerNAPI* obj;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineManager instance");
        return nullptr;
    }
    
    // 创建线程安全回调
    auto threadSafeCallback = std::shared_ptr<mbgl::harmony::ThreadSafeCallback>(
        mbgl::harmony::ThreadSafeCallback::Create(env, callback, "ClearAmbientCache").release()
    );
    if (!threadSafeCallback) {
        napi_throw_error(env, nullptr, "Failed to create thread-safe callback");
        return nullptr;
    }
    
    obj->fileSource_->clearAmbientCache([threadSafeCallback](std::exception_ptr error) {
        threadSafeCallback->Call([error](napi_env env) -> napi_value {
            if (error) {
                std::string errorMsg = mbgl::util::toString(error);
                napi_value errorValue;
                napi_create_string_utf8(env, errorMsg.c_str(), NAPI_AUTO_LENGTH, &errorValue);
                return errorValue;
            } else {
                napi_value undefined;
                napi_get_undefined(env, &undefined);
                return undefined;
            }
        });
    });
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value OfflineManagerNAPI::SetMaximumAmbientCacheSize(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) return nullptr;
    
    int64_t size = args.GetInt64(0, "size");
    napi_value callback = args.GetFunction(1, "callback");
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    OfflineManagerNAPI* obj;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineManager instance");
        return nullptr;
    }
    
    auto threadSafeCallback = std::shared_ptr<mbgl::harmony::ThreadSafeCallback>(
        mbgl::harmony::ThreadSafeCallback::Create(env, callback, "SetMaximumAmbientCacheSize").release()
    );
    if (!threadSafeCallback) {
        napi_throw_error(env, nullptr, "Failed to create thread-safe callback");
        return nullptr;
    }
    
    obj->fileSource_->setMaximumAmbientCacheSize(static_cast<uint64_t>(size), 
        [threadSafeCallback](std::exception_ptr error) {
        threadSafeCallback->Call([error](napi_env env) -> napi_value {
            if (error) {
                std::string errorMsg = mbgl::util::toString(error);
                napi_value errorValue;
                napi_create_string_utf8(env, errorMsg.c_str(), NAPI_AUTO_LENGTH, &errorValue);
                return errorValue;
            } else {
                napi_value undefined;
                napi_get_undefined(env, &undefined);
                return undefined;
            }
        });
    });
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value OfflineManagerNAPI::SetOfflineMapboxTileCountLimit(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    int64_t limit = args.GetInt64(0, "limit");
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    OfflineManagerNAPI* obj;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineManager instance");
        return nullptr;
    }
    
    obj->fileSource_->setOfflineMapboxTileCountLimit(static_cast<uint64_t>(limit));
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value OfflineManagerNAPI::RunPackDatabaseAutomatically(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    bool autopack = args.GetBool(0, "autopack");
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    OfflineManagerNAPI* obj;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&obj));
    
    if (!obj || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineManager instance");
        return nullptr;
    }
    
    obj->fileSource_->runPackDatabaseAutomatically(autopack);
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

} // namespace harmony
} // namespace maplibre

