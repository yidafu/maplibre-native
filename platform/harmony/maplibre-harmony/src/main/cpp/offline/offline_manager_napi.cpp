#include "offline_manager_napi.hpp"
#include "offline_region_napi.hpp"
#include "offline_region_definition_napi.hpp"
#include "napi/core/napi_args.hpp"
#include "core/thread_safe_callback.hpp"
#include "utils/logger.h"

#include <mln/storage/file_source_manager.hpp>
#include <mln/storage/resource_options.hpp>
#include <mln/util/client_options.hpp>
#include <mln/util/string.hpp>

#include <functional>

namespace mln {
namespace harmony {

using Logger = mln::harmony::Logger;
using NapiArgs = mln::harmony::napi::NapiArgs;

namespace {

// Create a named thread-safe callback, or throw into JS and return nullptr
// when creation fails.
std::shared_ptr<mln::harmony::ThreadSafeCallback> MakeTsFn(
    napi_env env, napi_value callback, const char* name) {
    auto tsfn = std::shared_ptr<mln::harmony::ThreadSafeCallback>(
        mln::harmony::ThreadSafeCallback::Create(env, callback, name).release());
    if (!tsfn) {
        napi_throw_error(env, nullptr, "Failed to create thread-safe callback");
        return nullptr;
    }
    return tsfn;
}

// Resolve `this` into the OfflineManagerNAPI instance (nullptr when unwrap
// fails); callers perform the instance/fileSource validation.
OfflineManagerNAPI* UnwrapManager(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    OfflineManagerNAPI* obj = nullptr;
    if (napi_unwrap(env, jsThis, reinterpret_cast<void**>(&obj)) != napi_ok) {
        obj = nullptr;
    }
    return obj;
}

// Build the napi_value passed to a JS callback for an error completion: the
// exception text as a UTF-8 string.
napi_value ErrorToStringValue(napi_env env, const std::exception_ptr& error) {
    std::string errorMsg = mln::util::toString(error);
    napi_value errorValue;
    napi_create_string_utf8(env, errorMsg.c_str(), NAPI_AUTO_LENGTH, &errorValue);
    return errorValue;
}

// Build an undefined napi_value.
napi_value UndefinedValue(napi_env env) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

// Completion callback shared by the DatabaseFileSource methods that only
// report success/failure: forwards the error string (or undefined) to the
// JS thread.
std::function<void(std::exception_ptr)> MakeVoidDbCallback(
    std::shared_ptr<mln::harmony::ThreadSafeCallback> tsfn) {
    return [tsfn = std::move(tsfn)](std::exception_ptr error) mutable {
        tsfn->Call([error = std::move(error)](napi_env env) -> napi_value {
            if (error) {
                return ErrorToStringValue(env, error);
            }
            return UndefinedValue(env);
        });
    };
}

} // namespace

// Shared NAPI body for the DatabaseFileSource methods that take only a
// void(std::exception_ptr) completion callback (resetDatabase, packDatabase,
// invalidateAmbientCache, clearAmbientCache, setMaximumAmbientCacheSize).
// Validates the arguments in the original order, unwraps the manager, creates
// the thread-safe callback, then hands the file source and completion to
// `invoke` to issue the actual call.
template <typename Invoke>
napi_value OfflineManagerNAPI::InvokeVoidDb(napi_env env, napi_callback_info info,
                                            size_t minArgs, size_t callbackIndex,
                                            const char* cbName, Invoke&& invoke) {
    NapiArgs args(env, info);
    args.RequireMinArgs(minArgs);
    if (args.HasError()) return nullptr;

    napi_value callback = args.GetFunction(callbackIndex, "callback");
    if (args.HasError()) return nullptr;

    OfflineManagerNAPI* obj = UnwrapManager(env, info);
    if (!obj || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineManager instance");
        return nullptr;
    }

    auto threadSafeCallback = MakeTsFn(env, callback, cbName);
    if (!threadSafeCallback) return nullptr;

    invoke(*obj->fileSource_, MakeVoidDbCallback(threadSafeCallback));

    return UndefinedValue(env);
}

// ========== Constructors and Destructors ==========

OfflineManagerNAPI::OfflineManagerNAPI(std::shared_ptr<mln::DatabaseFileSource> fileSource)
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

// ========== NAPI Initialization ==========

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

// ========== Constructor ==========

napi_value OfflineManagerNAPI::Constructor(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    // Retrieve parameters: database path and optional ResourceOptions
    std::string cachePath = args.GetString(0, "cachePath");
    if (args.HasError()) return nullptr;
    
    // Create ResourceOptions and ClientOptions
    mln::ResourceOptions resourceOptions;
    resourceOptions.withCachePath(cachePath);
    
    mln::ClientOptions clientOptions;
    
    // Acquire DatabaseFileSource instance
    auto fileSource = std::static_pointer_cast<mln::DatabaseFileSource>(
        mln::FileSourceManager::get()->getFileSource(
            mln::FileSourceType::Database,
            resourceOptions,
            clientOptions
        )
    );
    
    if (!fileSource) {
        napi_throw_error(env, nullptr, "Failed to create DatabaseFileSource");
        return nullptr;
    }
    
    // Create C++ object
    OfflineManagerNAPI* obj = new OfflineManagerNAPI(fileSource);
    obj->env_ = env;
    
    // Get this object
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    // Wrap C++ object
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

    // Retrieve callback function
    napi_value callback = args.GetFunction(0, "callback");
    if (args.HasError()) return nullptr;

    OfflineManagerNAPI* obj = UnwrapManager(env, info);
    if (!obj || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineManager instance");
        return nullptr;
    }

    // Create thread-safe callback
    auto tsfCallback = MakeTsFn(env, callback, "ListOfflineRegions");
    if (!tsfCallback) return nullptr;

    // Call into the core library
    auto fileSource = obj->fileSource_;
    fileSource->listOfflineRegions([tsfCallback, fileSource](
        mln::expected<mln::OfflineRegions, std::exception_ptr> regions) {

        // Execute on main thread via thread-safe callback
        tsfCallback->Call([regions = std::move(regions), fileSource](napi_env env) mutable -> napi_value {
            if (regions) {
                // Success - create region array
                napi_value regionsArray;
                napi_create_array_with_length(env, regions->size(), &regionsArray);

                for (size_t i = 0; i < regions->size(); i++) {
                    napi_value regionObj = OfflineRegionNAPI::New(env, fileSource, std::move((*regions)[i]));
                    napi_set_element(env, regionsArray, i, regionObj);
                }

                return regionsArray;
            } else {
                // Error case
                return ErrorToStringValue(env, regions.error());
            }
        });

        // ThreadSafeCallback releases automatically here
    });

    return UndefinedValue(env);
}

// ========== createOfflineRegion ==========

napi_value OfflineManagerNAPI::CreateOfflineRegion(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(3);
    if (args.HasError()) return nullptr;

    // Retrieve parameters: definition, metadata, callback
    napi_value definitionObj = args.GetObject(0, "definition");
    napi_value callback = args.GetFunction(2, "callback");
    if (args.HasError()) return nullptr;

    // Retrieve metadata parameter
    size_t argc = 3;
    napi_value argv[3];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    napi_value metadataValue = argv[1];

    // Parse definition
    mln::OfflineRegionDefinition definition = OfflineRegionDefinitionNAPI::FromNapiObject(env, definitionObj);

    // Parse metadata (ArrayBuffer)
    mln::OfflineRegionMetadata metadata;
    napi_valuetype metadataType;
    napi_typeof(env, metadataValue, &metadataType);
    if (metadataType != napi_null && metadataType != napi_undefined) {
        metadata = OfflineRegionNAPI::ArrayBufferToMetadata(env, metadataValue);
    }

    OfflineManagerNAPI* obj = UnwrapManager(env, info);
    if (!obj || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineManager instance");
        return nullptr;
    }

    // Create thread-safe callback
    auto tsfCallback = MakeTsFn(env, callback, "CreateOfflineRegion");
    if (!tsfCallback) return nullptr;

    // Call into the core library
    auto fileSource = obj->fileSource_;
    fileSource->createOfflineRegion(
        definition,
        metadata,
        [tsfCallback, fileSource](mln::expected<mln::OfflineRegion, std::exception_ptr> region) {

            // Execute on main thread via thread-safe callback
            tsfCallback->Call([region = std::move(region), fileSource](napi_env env) mutable -> napi_value {
                if (region) {
                    // Success - create OfflineRegion object
                    napi_value regionObj = OfflineRegionNAPI::New(env, fileSource, std::move(*region));
                    return regionObj;
                } else {
                    // Error case
                    return ErrorToStringValue(env, region.error());
                }
            });
        }
    );

    return UndefinedValue(env);
}

// ========== Other Methods ==========

napi_value OfflineManagerNAPI::GetOfflineRegion(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) return nullptr;

    int64_t regionId = args.GetInt64(0, "regionId");
    napi_value callback = args.GetFunction(1, "callback");
    if (args.HasError()) return nullptr;

    OfflineManagerNAPI* obj = UnwrapManager(env, info);
    if (!obj || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineManager instance");
        return nullptr;
    }

    // Create thread-safe callback
    auto tsfCallback = MakeTsFn(env, callback, "GetOfflineRegion");
    if (!tsfCallback) return nullptr;

    auto fileSource = obj->fileSource_;
    fileSource->getOfflineRegion(regionId, [tsfCallback, fileSource](
        mln::expected<std::optional<mln::OfflineRegion>, std::exception_ptr> result) {

        // Execute on main thread via thread-safe callback
        tsfCallback->Call([result = std::move(result), fileSource](napi_env env) mutable -> napi_value {
            if (result && result->has_value()) {
                // Region found
                napi_value regionObj = OfflineRegionNAPI::New(env, fileSource, std::move(**result));
                return regionObj;
            } else if (result) {
                // Region not found
                napi_value nullValue;
                napi_get_null(env, &nullValue);
                return nullValue;
            } else {
                // Error
                return ErrorToStringValue(env, result.error());
            }
        });
    });

    return UndefinedValue(env);
}

napi_value OfflineManagerNAPI::MergeOfflineRegions(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) return nullptr;

    std::string path = args.GetString(0, "path");
    napi_value callback = args.GetFunction(1, "callback");
    if (args.HasError()) return nullptr;

    OfflineManagerNAPI* obj = UnwrapManager(env, info);
    if (!obj || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineManager instance");
        return nullptr;
    }

    // Create thread-safe callback
    auto tsfCallback = MakeTsFn(env, callback, "MergeOfflineRegions");
    if (!tsfCallback) return nullptr;

    auto fileSource = obj->fileSource_;
    fileSource->mergeOfflineRegions(path, [tsfCallback, fileSource](
        mln::expected<mln::OfflineRegions, std::exception_ptr> regions) {

        // Execute on main thread via thread-safe callback
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
                return ErrorToStringValue(env, regions.error());
            }
        });
    });

    return UndefinedValue(env);
}

napi_value OfflineManagerNAPI::ResetDatabase(napi_env env, napi_callback_info info) {
    return InvokeVoidDb(env, info, 1, 0, "ResetDatabase",
        [](mln::DatabaseFileSource& fileSource, std::function<void(std::exception_ptr)> onDone) {
            fileSource.resetDatabase(std::move(onDone));
        });
}

napi_value OfflineManagerNAPI::PackDatabase(napi_env env, napi_callback_info info) {
    return InvokeVoidDb(env, info, 1, 0, "PackDatabase",
        [](mln::DatabaseFileSource& fileSource, std::function<void(std::exception_ptr)> onDone) {
            fileSource.packDatabase(std::move(onDone));
        });
}

napi_value OfflineManagerNAPI::InvalidateAmbientCache(napi_env env, napi_callback_info info) {
    return InvokeVoidDb(env, info, 1, 0, "InvalidateAmbientCache",
        [](mln::DatabaseFileSource& fileSource, std::function<void(std::exception_ptr)> onDone) {
            fileSource.invalidateAmbientCache(std::move(onDone));
        });
}

napi_value OfflineManagerNAPI::ClearAmbientCache(napi_env env, napi_callback_info info) {
    return InvokeVoidDb(env, info, 1, 0, "ClearAmbientCache",
        [](mln::DatabaseFileSource& fileSource, std::function<void(std::exception_ptr)> onDone) {
            fileSource.clearAmbientCache(std::move(onDone));
        });
}

napi_value OfflineManagerNAPI::SetMaximumAmbientCacheSize(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) return nullptr;

    int64_t size = args.GetInt64(0, "size");
    if (args.HasError()) return nullptr;

    return InvokeVoidDb(env, info, 2, 1, "SetMaximumAmbientCacheSize",
        [size](mln::DatabaseFileSource& fileSource, std::function<void(std::exception_ptr)> onDone) {
            fileSource.setMaximumAmbientCacheSize(static_cast<uint64_t>(size), std::move(onDone));
        });
}

napi_value OfflineManagerNAPI::SetOfflineMapboxTileCountLimit(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;

    int64_t limit = args.GetInt64(0, "limit");
    if (args.HasError()) return nullptr;

    OfflineManagerNAPI* obj = UnwrapManager(env, info);
    if (!obj || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineManager instance");
        return nullptr;
    }

    obj->fileSource_->setOfflineMapboxTileCountLimit(static_cast<uint64_t>(limit));

    return UndefinedValue(env);
}

napi_value OfflineManagerNAPI::RunPackDatabaseAutomatically(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;

    bool autopack = args.GetBool(0, "autopack");
    if (args.HasError()) return nullptr;

    OfflineManagerNAPI* obj = UnwrapManager(env, info);
    if (!obj || !obj->fileSource_) {
        napi_throw_error(env, nullptr, "Invalid OfflineManager instance");
        return nullptr;
    }

    obj->fileSource_->runPackDatabaseAutomatically(autopack);

    return UndefinedValue(env);
}

} // namespace harmony
} // namespace mln

