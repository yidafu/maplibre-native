/**
 * MapSnapshotter NAPI Bindings for HarmonyOS
 */

#include "snapshotter_napi.hpp"
#include "map_snapshotter_harmony.hpp"
#include "map_snapshot_napi.hpp"
#include "../utils/logger.h"
#include "../camera/camera_position_harmony.hpp"
#include "../geometry/lat_lng_bounds_harmony.hpp"
#include "../core/thread_safe_callback.hpp"
#include "../napi/core/napi_args.hpp"

#include <mbgl/map/camera.hpp>
#include <napi/native_api.h>
#include <string>
#include <memory>

using mbgl::harmony::ThreadSafeCallback;
using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;

namespace mbgl {
namespace harmony {

using mbgl::harmony::napi::NapiArgs;

// Forward declarations
napi_value SnapshotterStart(napi_env env, napi_callback_info info);
napi_value SnapshotterCancel(napi_env env, napi_callback_info info);
napi_value SnapshotterSetStyleUrl(napi_env env, napi_callback_info info);
napi_value SnapshotterSetStyleJson(napi_env env, napi_callback_info info);
napi_value SnapshotterSetCameraPosition(napi_env env, napi_callback_info info);
napi_value SnapshotterSetRegion(napi_env env, napi_callback_info info);
napi_value SnapshotterSetSize(napi_env env, napi_callback_info info);
napi_value SnapshotterSetObserver(napi_env env, napi_callback_info info);
napi_value SnapshotterGetLayer(napi_env env, napi_callback_info info);
napi_value SnapshotterGetSource(napi_env env, napi_callback_info info);
napi_value SnapshotterAddImage(napi_env env, napi_callback_info info);

/**
 * Internal MapSnapshotter instance wrapper.
 */
class MapSnapshotterInstance {
public:
    std::unique_ptr<MapSnapshotterHarmony> snapshotter;
    napi_env env;
    napi_ref callbackRef = nullptr;
    napi_ref errorCallbackRef = nullptr;
    
    // Replace observerRef with ThreadSafeCallback
    std::unique_ptr<ThreadSafeCallback> onDidFinishLoadingStyleCallback;
    std::unique_ptr<ThreadSafeCallback> onStyleImageMissingCallback;

    MapSnapshotterInstance(napi_env e) : env(e) {}

    ~MapSnapshotterInstance() {
        if (callbackRef) {
            napi_delete_reference(env, callbackRef);
        }
        if (errorCallbackRef) {
            napi_delete_reference(env, errorCallbackRef);
        }
        // ThreadSafeCallback releases automatically on destruction
    }
    
    /**
     * Trigger the onDidFinishLoadingStyle callback (thread-safe).
     */
    void triggerOnDidFinishLoadingStyle() {
        if (onDidFinishLoadingStyleCallback && onDidFinishLoadingStyleCallback->IsValid()) {
            onDidFinishLoadingStyleCallback->CallEmpty();
        }
    }
    
    /**
     * Trigger the onStyleImageMissing callback (thread-safe).
     */
    void triggerOnStyleImageMissing(const std::string& imageName) {
        if (onStyleImageMissingCallback && onStyleImageMissingCallback->IsValid()) {
            onStyleImageMissingCallback->CallWithString(imageName);
        }
    }
};

/**
 * Create a MapSnapshotter instance.
 *
 * JavaScript usage:
 * const snapshotter = maplibre.createMapSnapshotter(options);
 */
napi_value CreateMapSnapshotter(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();

    // Parse the options object
    napi_value optionsObj = args.GetObject(0, "options");
    if (args.HasError()) return args.Undefined();
    
    MapSnapshotterHarmony::SnapshotOptions options;
    
    // Parse required parameters
    options.width = static_cast<uint32_t>(args.GetInt64Property(optionsObj, "width", 0));
    options.height = static_cast<uint32_t>(args.GetInt64Property(optionsObj, "height", 0));
    options.pixelRatio = static_cast<float>(args.GetDoubleProperty(optionsObj, "pixelRatio", 1.0));
    options.styleURL = args.GetStringProperty(optionsObj, "styleUrl", "");
    options.showLogo = args.GetBoolProperty(optionsObj, "showLogo", true);
    
    // Parse optional styleJSON
    std::string styleJSON = args.GetStringProperty(optionsObj, "styleJSON", "");
    if (!styleJSON.empty()) {
        options.styleJSON = styleJSON;
        Logger::info("SnapshotterNAPI", "Using styleJSON: %zu bytes", styleJSON.size());
    }
    
    // Parse optional camera settings
    napi_value cameraVal;
    napi_status status = napi_get_named_property(env, optionsObj, "camera", &cameraVal);
    if (status == napi_ok) {
        napi_valuetype cameraType;
        napi_typeof(env, cameraVal, &cameraType);
        if (cameraType == napi_object) {
            mbgl::CameraOptions camera;
            
            // Parse target (LatLng)
            napi_value targetVal;
            if (napi_get_named_property(env, cameraVal, "target", &targetVal) == napi_ok) {
                double lat = args.GetDoubleProperty(targetVal, "latitude", 0.0);
                double lng = args.GetDoubleProperty(targetVal, "longitude", 0.0);
                camera.center = mbgl::LatLng(lat, lng);
            }
            
            // Parse zoom, bearing, tilt
            camera.zoom = args.GetDoubleProperty(cameraVal, "zoom", 0.0);
            camera.bearing = args.GetDoubleProperty(cameraVal, "bearing", 0.0);
            camera.pitch = args.GetDoubleProperty(cameraVal, "tilt", 0.0);
            
            options.camera = camera;
        }
    }
    
    // Parse optional region (LatLngBounds)
    napi_value regionVal;
    status = napi_get_named_property(env, optionsObj, "region", &regionVal);
    if (status == napi_ok) {
        napi_valuetype regionType;
        napi_typeof(env, regionVal, &regionType);
        if (regionType == napi_object) {
            double north = args.GetDoubleProperty(regionVal, "north", 0.0);
            double south = args.GetDoubleProperty(regionVal, "south", 0.0);
            double east = args.GetDoubleProperty(regionVal, "east", 0.0);
            double west = args.GetDoubleProperty(regionVal, "west", 0.0);
            
            mbgl::LatLngBounds bounds = mbgl::LatLngBounds::hull(
                mbgl::LatLng(north, east),
                mbgl::LatLng(south, west)
            );
            options.region = bounds;
        }
    }
    
    // Create resource options.
    // Note: simplified; ideally fetch cache path from the surrounding context.
    mbgl::ResourceOptions resourceOptions;
    resourceOptions.withCachePath("/data/storage/el2/base/haps/entry/cache/maplibre");
    
    mbgl::ClientOptions clientOptions;
    
    // Instantiate MapSnapshotterInstance
    auto* snapshotterInstance = new MapSnapshotterInstance(env);
    snapshotterInstance->snapshotter = std::make_unique<MapSnapshotterHarmony>(
        options,
        resourceOptions,
        clientOptions
    );
    
    // Register observer callbacks so C++ can trigger TypeScript observers
    snapshotterInstance->snapshotter->setObserverCallback(
        [snapshotterInstance](const std::string& event, const std::string& data) {
            if (event == "onDidFinishLoadingStyle") {
                snapshotterInstance->triggerOnDidFinishLoadingStyle();
            } else if (event == "onStyleImageMissing") {
                snapshotterInstance->triggerOnStyleImageMissing(data);
            }
        }
    );
    
    // Create the JavaScript object and attach the native pointer
    napi_value jsSnapshotter;
    napi_create_object(env, &jsSnapshotter);
    
    // Wrap the native pointer with the JavaScript object
    napi_wrap(env, jsSnapshotter, snapshotterInstance,
              [](napi_env env, void* data, void* hint) {
                  delete static_cast<MapSnapshotterInstance*>(data);
              },
              nullptr, nullptr);
    
    // Bind methods to the object
    napi_property_descriptor methods[] = {
        {"start", nullptr, SnapshotterStart, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"cancel", nullptr, SnapshotterCancel, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setStyleUrl", nullptr, SnapshotterSetStyleUrl, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setStyleJson", nullptr, SnapshotterSetStyleJson, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setCameraPosition", nullptr, SnapshotterSetCameraPosition, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setRegion", nullptr, SnapshotterSetRegion, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setSize", nullptr, SnapshotterSetSize, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setObserver", nullptr, SnapshotterSetObserver, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getLayer", nullptr, SnapshotterGetLayer, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getSource", nullptr, SnapshotterGetSource, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addImage", nullptr, SnapshotterAddImage, nullptr, nullptr, nullptr, napi_default, nullptr}
    };
    
    napi_define_properties(env, jsSnapshotter, sizeof(methods) / sizeof(methods[0]), methods);
    
    Logger::info("SnapshotterNAPI", "MapSnapshotter created: %dx%d @ %.2fx",
                 options.width, options.height, options.pixelRatio);
    
    return jsSnapshotter;
}

/**
 * Start generating a snapshot.
 *
 * JavaScript usage:
 * snapshotter.start((error, imageData) => { ... });
 */
napi_value SnapshotterStart(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();

    // Retrieve the native instance
    MapSnapshotterInstance* snapshotterInstance;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance));
    
    if (!snapshotterInstance || !snapshotterInstance->snapshotter) {
        napi_throw_error(env, nullptr, "Snapshotter not initialized");
        return nullptr;
    }

    // Create a thread-safe callback
    napi_value callback = args.GetFunction(0, "callback");
    if (args.HasError()) return args.Undefined();
    
    auto threadSafeCallback = ThreadSafeCallback::Create(env, callback, "SnapshotterCallback");
    if (!threadSafeCallback) {
        napi_throw_error(env, nullptr, "Failed to create thread-safe callback");
        return nullptr;
    }

    Logger::info("SnapshotterNAPI", "Starting snapshot");

    // Use shared_ptr so the callback survives until the async work completes
    auto sharedCallback = std::shared_ptr<ThreadSafeCallback>(std::move(threadSafeCallback));

    // Obtain pixelRatio from the snapshotter options
    float pixelRatio = 1.0f; // Default; ideally read from the snapshotter
    // TODO: Pull pixelRatio from snapshotterInstance configuration
    
    // Invoke the C++ snapshot method
    snapshotterInstance->snapshotter->snapshot(
        [sharedCallback, pixelRatio](
            std::exception_ptr err,
            mbgl::PremultipliedImage image,
            std::vector<std::string> attributions,
            mbgl::MapSnapshotter::PointForFn pointForFn,
            mbgl::MapSnapshotter::LatLngForFn latLngForFn
        ) {
            // Use ThreadSafeCallback to marshal safely onto the main thread
            Logger::info("SnapshotterNAPI", "Snapshot callback triggered");
            
            if (err) {
                // Error case
                try {
                    std::rethrow_exception(err);
                } catch (const std::exception& e) {
                    Logger::error("SnapshotterNAPI", "Snapshot error: %s", e.what());
                    
                    std::string errorMsg = e.what();
                    // Use ThreadSafeCallback to schedule onto the main thread and invoke the real callback.
                    // ThreadSafeCallback only handles scheduling; we control the invocation.
                    sharedCallback->CallWithString(errorMsg);
                }
            } else {
                // Success path — move data to the heap for use inside the thread-safe callback
                Logger::info("SnapshotterNAPI", "Snapshot success: %dx%d, %zu bytes",
                             image.size.width, image.size.height, image.bytes());
                
                // Move all data into shared_ptr for automatic lifetime management
                auto imageData = std::make_shared<mbgl::PremultipliedImage>(std::move(image));
                auto attrs = std::make_shared<std::vector<std::string>>(std::move(attributions));
                
                // Use ThreadSafeCallback to create the MapSnapshot object on the main thread
                sharedCallback->Call([imageData, attrs, pixelRatio, pointForFn, latLngForFn](napi_env env) -> napi_value {
                    // Use CreateMapSnapshotObject to build the MapSnapshot.
                    // Note: move imageData into the returned object.
                    mbgl::PremultipliedImage imageCopy = std::move(*imageData);
                    napi_value mapSnapshotObj = CreateMapSnapshotObject(
                        env,
                        std::move(imageCopy),
                        *attrs,
                        pixelRatio,
                        pointForFn,
                        latLngForFn
                    );
                    
                    // Return the MapSnapshot object (passed as the callback argument)
                    return mapSnapshotObj;
                });
            }
        }
    );

    return nullptr;
}

/**
 * Cancel snapshot generation.
 *
 * JavaScript usage:
 * snapshotter.cancel();
 */
napi_value SnapshotterCancel(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);

    // Retrieve the native instance
    MapSnapshotterInstance* snapshotterInstance;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance));
    
    if (!snapshotterInstance || !snapshotterInstance->snapshotter) {
        napi_throw_error(env, nullptr, "Snapshotter not initialized");
        return nullptr;
    }

    Logger::info("SnapshotterNAPI", "Cancelling snapshot");
    snapshotterInstance->snapshotter->cancel();

    return nullptr;
}

/**
 * Set the style URL.
 */
napi_value SnapshotterSetStyleUrl(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();

    // Retrieve the native instance
    MapSnapshotterInstance* snapshotterInstance;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance));
    
    if (!snapshotterInstance || !snapshotterInstance->snapshotter) {
        napi_throw_error(env, nullptr, "Snapshotter not initialized");
        return nullptr;
    }

    // Parse styleUrl
    std::string styleUrl = args.GetString(0, "styleUrl");
    if (args.HasError()) return args.Undefined();
    
    snapshotterInstance->snapshotter->setStyleURL(styleUrl);

    return nullptr;
}

/**
 * Set the camera position.
 */
napi_value SnapshotterSetCameraPosition(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();

    // Retrieve the native instance
    MapSnapshotterInstance* snapshotterInstance;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance));
    
    if (!snapshotterInstance || !snapshotterInstance->snapshotter) {
        napi_throw_error(env, nullptr, "Snapshotter not initialized");
        return nullptr;
    }

    // Parse CameraPosition
    napi_value cameraObj = args.GetObject(0, "cameraPosition");
    if (args.HasError()) return args.Undefined();
    
    mbgl::CameraOptions camera;
    
    // Parse target (LatLng)
    napi_value targetVal;
    if (napi_get_named_property(env, cameraObj, "target", &targetVal) == napi_ok) {
        double lat = args.GetDoubleProperty(targetVal, "latitude", 0.0);
        double lng = args.GetDoubleProperty(targetVal, "longitude", 0.0);
        camera.center = mbgl::LatLng(lat, lng);
    }
    
    // Parse zoom, bearing, tilt
    camera.zoom = args.GetDoubleProperty(cameraObj, "zoom", 0.0);
    camera.bearing = args.GetDoubleProperty(cameraObj, "bearing", 0.0);
    camera.pitch = args.GetDoubleProperty(cameraObj, "tilt", 0.0);
    
    snapshotterInstance->snapshotter->setCameraOptions(camera);
    Logger::info("SnapshotterNAPI", "Camera position set");

    return nullptr;
}

/**
 * Set the style JSON.
 */
napi_value SnapshotterSetStyleJson(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();

    // Retrieve the native instance
    MapSnapshotterInstance* snapshotterInstance;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance));
    
    if (!snapshotterInstance || !snapshotterInstance->snapshotter) {
        napi_throw_error(env, nullptr, "Snapshotter not initialized");
        return nullptr;
    }

    // Parse styleJson
    std::string styleJson = args.GetString(0, "styleJson");
    if (args.HasError()) return args.Undefined();
    
    snapshotterInstance->snapshotter->setStyleJSON(styleJson);
    Logger::info("SnapshotterNAPI", "Style JSON set");

    return nullptr;
}

/**
 * Set the region bounds.
 */
napi_value SnapshotterSetRegion(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();

    // Retrieve the native instance
    MapSnapshotterInstance* snapshotterInstance;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance));
    
    if (!snapshotterInstance || !snapshotterInstance->snapshotter) {
        napi_throw_error(env, nullptr, "Snapshotter not initialized");
        return nullptr;
    }

    // Parse LatLngBounds
    napi_value regionObj = args.GetObject(0, "region");
    if (args.HasError()) return args.Undefined();
    
    double north = args.GetDoubleProperty(regionObj, "north", 0.0);
    double south = args.GetDoubleProperty(regionObj, "south", 0.0);
    double east = args.GetDoubleProperty(regionObj, "east", 0.0);
    double west = args.GetDoubleProperty(regionObj, "west", 0.0);
    
    mbgl::LatLngBounds bounds = mbgl::LatLngBounds::hull(
        mbgl::LatLng(north, east),
        mbgl::LatLng(south, west)
    );
    
    snapshotterInstance->snapshotter->setRegion(bounds);
    Logger::info("SnapshotterNAPI", "Region set");

    return nullptr;
}

/**
 * Set the snapshot size.
 */
napi_value SnapshotterSetSize(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) return args.Undefined();

    // Retrieve the native instance
    MapSnapshotterInstance* snapshotterInstance;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance));
    
    if (!snapshotterInstance || !snapshotterInstance->snapshotter) {
        napi_throw_error(env, nullptr, "Snapshotter not initialized");
        return nullptr;
    }

    // Parse width and height
    uint32_t width = static_cast<uint32_t>(args.GetInt64(0, "width"));
    uint32_t height = static_cast<uint32_t>(args.GetInt64(1, "height"));
    if (args.HasError()) return args.Undefined();
    
    snapshotterInstance->snapshotter->setSize({width, height});
    Logger::info("SnapshotterNAPI", "Size set to %ux%u", width, height);

    return nullptr;
}

/**
 * Set the observer callbacks.
 */
napi_value SnapshotterSetObserver(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();

    // Retrieve the native instance
    MapSnapshotterInstance* snapshotterInstance;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance));
    
    if (!snapshotterInstance || !snapshotterInstance->snapshotter) {
        napi_throw_error(env, nullptr, "Snapshotter not initialized");
        return nullptr;
    }

    // Clear any previous callbacks
    snapshotterInstance->onDidFinishLoadingStyleCallback.reset();
    snapshotterInstance->onStyleImageMissingCallback.reset();

    // Retrieve the observer object
    napi_value argv[1];
    size_t argc = 1;
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    napi_value observer = argv[0];
    
    // Allow null to remove the observer
    napi_valuetype valueType;
    napi_typeof(env, observer, &valueType);
    
    if (valueType != napi_null && valueType != napi_undefined) {
        // Extract the two observer methods
        napi_value onDidFinishLoadingStyleMethod;
        napi_value onStyleImageMissingMethod;
        
        if (napi_get_named_property(env, observer, "onDidFinishLoadingStyle", &onDidFinishLoadingStyleMethod) == napi_ok) {
            snapshotterInstance->onDidFinishLoadingStyleCallback = 
                ThreadSafeCallback::Create(env, onDidFinishLoadingStyleMethod, "SnapshotterOnDidFinishLoadingStyle");
        }
        
        if (napi_get_named_property(env, observer, "onStyleImageMissing", &onStyleImageMissingMethod) == napi_ok) {
            snapshotterInstance->onStyleImageMissingCallback = 
                ThreadSafeCallback::Create(env, onStyleImageMissingMethod, "SnapshotterOnStyleImageMissing");
        }
        
        Logger::info("SnapshotterNAPI", "Observer set with ThreadSafeCallback");
    } else {
        Logger::info("SnapshotterNAPI", "Observer cleared");
    }

    return nullptr;
}

/**
 * Retrieve a layer.
 *
 * JavaScript usage:
 * const layer = snapshotter.getLayer(layerId);
 */
napi_value SnapshotterGetLayer(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();

    // Retrieve the native instance
    MapSnapshotterInstance* snapshotterInstance;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance));
    
    if (!snapshotterInstance || !snapshotterInstance->snapshotter) {
        Logger::warn("SnapshotterNAPI", "getLayer: Snapshotter not initialized");
        return args.Undefined();
    }

    // Parse layerId
    std::string layerId = args.GetString(0, "layerId");
    if (args.HasError()) return args.Undefined();

    // TODO: Implement layer retrieval.
    // Should access snapshotter->getStyle().getLayer(layerId)
    // and convert the result into a NAPI Layer object.
    Logger::warn("SnapshotterNAPI", "getLayer: Not fully implemented yet");
    
    return args.Undefined();
}

/**
 * Retrieve a source.
 *
 * JavaScript usage:
 * const source = snapshotter.getSource(sourceId);
 */
napi_value SnapshotterGetSource(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();

    // Retrieve the native instance
    MapSnapshotterInstance* snapshotterInstance;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance));
    
    if (!snapshotterInstance || !snapshotterInstance->snapshotter) {
        Logger::warn("SnapshotterNAPI", "getSource: Snapshotter not initialized");
        return args.Undefined();
    }

    // Parse sourceId
    std::string sourceId = args.GetString(0, "sourceId");
    if (args.HasError()) return args.Undefined();

    // TODO: Implement source retrieval.
    // Should access snapshotter->getStyle().getSource(sourceId)
    // and convert the result into a NAPI Source object.
    Logger::warn("SnapshotterNAPI", "getSource: Not fully implemented yet");
    
    return args.Undefined();
}

/**
 * Add an image.
 *
 * JavaScript usage:
 * snapshotter.addImage(name, imageData, sdf);
 */
napi_value SnapshotterAddImage(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(3);
    if (args.HasError()) return args.Undefined();

    // Retrieve the native instance
    MapSnapshotterInstance* snapshotterInstance;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance));
    
    if (!snapshotterInstance || !snapshotterInstance->snapshotter) {
        Logger::warn("SnapshotterNAPI", "addImage: Snapshotter not initialized");
        return args.Undefined();
    }

    // Parse arguments
    std::string name = args.GetString(0, "name");
    // napi_value imageData = args.GetValue(1); // ImageBitmap or ArrayBuffer
    bool sdf = args.GetBool(2, "sdf");
    
    if (args.HasError()) return args.Undefined();

    // TODO: Implement image addition:
    // 1. Convert ImageBitmap/ArrayBuffer into mbgl::PremultipliedImage
    // 2. Call snapshotter->getStyle().addImage(name, std::move(image), sdf)
    Logger::warn("SnapshotterNAPI", "addImage: Not fully implemented yet - name=%s, sdf=%d", 
                 name.c_str(), sdf);
    
    return args.Undefined();
}

} // namespace harmony
} // namespace mbgl

/**
 * MapSnapshotterNAPI::Init implementation.
 */
namespace mbgl {
namespace harmony {

void MapSnapshotterNAPI::Init(napi_env env, napi_value exports) {
    // Register the creation function
    napi_property_descriptor descriptors[] = {
        {"createMapSnapshotter", nullptr, CreateMapSnapshotter, nullptr, nullptr, nullptr, napi_default, nullptr}
    };
    
    napi_define_properties(env, exports, sizeof(descriptors) / sizeof(descriptors[0]), descriptors);
    
    Logger::info("SnapshotterNAPI", "MapSnapshotter APIs registered");
}

} // namespace harmony
} // namespace mbgl

