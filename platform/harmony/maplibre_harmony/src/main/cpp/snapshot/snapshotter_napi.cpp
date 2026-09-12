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

// Layer NAPI classes (for getLayer)
#include "../style/layers/fill_layer_harmony.hpp"
#include "../style/layers/line_layer_harmony.hpp"
#include "../style/layers/circle_layer_harmony.hpp"
#include "../style/layers/symbol_layer_harmony.hpp"
#include "../style/layers/raster_layer_harmony.hpp"
#include "../style/layers/background_layer_harmony.hpp"
#include "../style/layers/heatmap_layer_harmony.hpp"
#include "../style/layers/hillshade_layer_harmony.hpp"
#include "../style/layers/fill_extrusion_layer_harmony.hpp"
#include "../style/layers/color_relief_layer_harmony.hpp"
#include "../style/layers/location_indicator_layer_harmony.hpp"
// Source NAPI classes (for getSource)
#include "../sources/geojson_source_napi.hpp"
#include "../sources/vector_source_napi.hpp"
#include "../sources/raster_source_napi.hpp"
#include "../sources/raster_dem_source_napi.hpp"
#include "../sources/image_source_napi.hpp"
// Image/Icon NAPI classes (for addImage)
#include "../napi/bindings/image/image_napi.hpp"
#include "../napi/bindings/icon/icon_napi.hpp"

#include <mbgl/map/camera.hpp>
#include <mbgl/style/layer.hpp>
#include <mbgl/style/style.hpp>
#include <mbgl/style/source.hpp>
#include <mbgl/style/image.hpp>
#include <mbgl/style/layers/fill_layer.hpp>
#include <mbgl/style/layers/line_layer.hpp>
#include <mbgl/style/layers/circle_layer.hpp>
#include <mbgl/style/layers/symbol_layer.hpp>
#include <mbgl/style/layers/raster_layer.hpp>
#include <mbgl/style/layers/background_layer.hpp>
#include <mbgl/style/layers/heatmap_layer.hpp>
#include <mbgl/style/layers/hillshade_layer.hpp>
#include <mbgl/style/layers/fill_extrusion_layer.hpp>
#include <mbgl/style/layers/location_indicator_layer.hpp>
#include <mbgl/style/sources/geojson_source.hpp>
#include <mbgl/style/sources/vector_source.hpp>
#include <mbgl/style/sources/raster_source.hpp>
#include <mbgl/style/sources/raster_dem_source.hpp>
#include <mbgl/style/sources/image_source.hpp>
#include <napi/native_api.h>
#include <string>
#include <memory>
#include <vector>
#include <cstring>

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
    MapSnapshotterInstance* snapshotterInstance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance)) != napi_ok) {
        snapshotterInstance = nullptr;
    }
    
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

    // Pixel ratio comes from the snapshotter configuration (options.pixelRatio)
    const float pixelRatio = snapshotterInstance->snapshotter->getPixelRatio();
    
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
    MapSnapshotterInstance* snapshotterInstance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance)) != napi_ok) {
        snapshotterInstance = nullptr;
    }
    
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
    MapSnapshotterInstance* snapshotterInstance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance)) != napi_ok) {
        snapshotterInstance = nullptr;
    }
    
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
    MapSnapshotterInstance* snapshotterInstance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance)) != napi_ok) {
        snapshotterInstance = nullptr;
    }
    
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
    MapSnapshotterInstance* snapshotterInstance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance)) != napi_ok) {
        snapshotterInstance = nullptr;
    }
    
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
    MapSnapshotterInstance* snapshotterInstance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance)) != napi_ok) {
        snapshotterInstance = nullptr;
    }
    
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
    MapSnapshotterInstance* snapshotterInstance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance)) != napi_ok) {
        snapshotterInstance = nullptr;
    }
    
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
    MapSnapshotterInstance* snapshotterInstance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance)) != napi_ok) {
        snapshotterInstance = nullptr;
    }
    
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
    MapSnapshotterInstance* snapshotterInstance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance)) != napi_ok) {
        snapshotterInstance = nullptr;
    }
    
    if (!snapshotterInstance || !snapshotterInstance->snapshotter) {
        Logger::warn("SnapshotterNAPI", "getLayer: Snapshotter not initialized");
        return args.Undefined();
    }

    // Parse layerId
    std::string layerId = args.GetString(0, "layerId");
    if (args.HasError()) return args.Undefined();
    if (layerId.empty()) {
        napi_throw_error(env, nullptr, "layerId cannot be empty");
        return nullptr;
    }

    try {
        mbgl::style::Layer* layer = snapshotterInstance->snapshotter->getStyle().getLayer(layerId);
        if (!layer) {
            Logger::info("SnapshotterNAPI", "getLayer: Layer not found: %s", layerId.c_str());
            return args.Null();
        }

        const std::string layerType = layer->getTypeInfo()->type;
        Logger::info("SnapshotterNAPI", "getLayer: %s (type: %s)", layerId.c_str(), layerType.c_str());

        // Create the corresponding NAPI wrapper based on the layer type
        // (same dispatch as StyleNAPI::GetLayer)
        if (layerType == "symbol") {
            return mbgl::harmony::SymbolLayerNAPI::CreateInstance(env, static_cast<mbgl::style::SymbolLayer*>(layer));
        } else if (layerType == "fill") {
            return mbgl::harmony::FillLayerNAPI::CreateInstance(env, static_cast<mbgl::style::FillLayer*>(layer));
        } else if (layerType == "line") {
            return mbgl::harmony::LineLayerNAPI::CreateInstance(env, static_cast<mbgl::style::LineLayer*>(layer));
        } else if (layerType == "circle") {
            return mbgl::harmony::CircleLayerNAPI::CreateInstance(env, static_cast<mbgl::style::CircleLayer*>(layer));
        } else if (layerType == "raster") {
            return mbgl::harmony::RasterLayerNAPI::CreateInstance(env, static_cast<mbgl::style::RasterLayer*>(layer));
        } else if (layerType == "heatmap") {
            return mbgl::harmony::HeatmapLayerNAPI::CreateInstance(env, static_cast<mbgl::style::HeatmapLayer*>(layer));
        } else if (layerType == "hillshade") {
            return mbgl::harmony::HillshadeLayerNAPI::CreateInstance(env, static_cast<mbgl::style::HillshadeLayer*>(layer));
        } else if (layerType == "fill-extrusion") {
            return mbgl::harmony::FillExtrusionLayerNAPI::CreateInstance(env, static_cast<mbgl::style::FillExtrusionLayer*>(layer));
        } else if (layerType == "background") {
            return mbgl::harmony::BackgroundLayerNAPI::CreateInstance(env, static_cast<mbgl::style::BackgroundLayer*>(layer));
        } else if (layerType == "color-relief") {
            return mbgl::harmony::ColorReliefLayerNAPI::CreateInstance(env, static_cast<mbgl::style::ColorReliefLayer*>(layer));
        } else if (layerType == "location-indicator") {
            return mbgl::harmony::LocationIndicatorLayerNAPI::CreateInstance(env, static_cast<mbgl::style::LocationIndicatorLayer*>(layer));
        }

        Logger::warn("SnapshotterNAPI", "getLayer: Unknown layer type: %s", layerType.c_str());
        return args.Null();
    } catch (const std::exception& e) {
        Logger::error("SnapshotterNAPI", "getLayer failed: %s", e.what());
        return args.Null();
    }
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
    MapSnapshotterInstance* snapshotterInstance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance)) != napi_ok) {
        snapshotterInstance = nullptr;
    }
    
    if (!snapshotterInstance || !snapshotterInstance->snapshotter) {
        Logger::warn("SnapshotterNAPI", "getSource: Snapshotter not initialized");
        return args.Undefined();
    }

    // Parse sourceId
    std::string sourceId = args.GetString(0, "sourceId");
    if (args.HasError()) return args.Undefined();
    if (sourceId.empty()) {
        napi_throw_error(env, nullptr, "sourceId cannot be empty");
        return nullptr;
    }

    try {
        mbgl::style::Source* source = snapshotterInstance->snapshotter->getStyle().getSource(sourceId);
        if (!source) {
            Logger::info("SnapshotterNAPI", "getSource: Source not found: %s", sourceId.c_str());
            return args.Null();
        }

        Logger::info("SnapshotterNAPI", "getSource: %s (type: %d)", sourceId.c_str(),
                     static_cast<int>(source->getType()));

        // Create the corresponding NAPI wrapper based on the source type
        // (same dispatch as StyleNAPI::GetSource)
        switch (source->getType()) {
            case mbgl::style::SourceType::GeoJSON: {
                auto* geoJsonSource = static_cast<mbgl::style::GeoJSONSource*>(source);
                return maplibre::harmony::GeoJsonSourceNAPI::CreateInstance(env, geoJsonSource);
            }
            case mbgl::style::SourceType::Vector: {
                auto* vectorSource = static_cast<mbgl::style::VectorSource*>(source);
                return maplibre::harmony::VectorSourceNAPI::CreateInstance(env, vectorSource);
            }
            case mbgl::style::SourceType::Raster: {
                auto* rasterSource = static_cast<mbgl::style::RasterSource*>(source);
                return maplibre::harmony::RasterSourceNAPI::CreateInstance(env, rasterSource);
            }
            case mbgl::style::SourceType::RasterDEM: {
                auto* rasterDemSource = static_cast<mbgl::style::RasterDEMSource*>(source);
                return maplibre::harmony::RasterDemSourceNAPI::CreateInstance(env, rasterDemSource);
            }
            case mbgl::style::SourceType::Image: {
                auto* imageSource = static_cast<mbgl::style::ImageSource*>(source);
                return maplibre::harmony::ImageSourceNAPI::CreateInstance(env, imageSource);
            }
            default:
                Logger::warn("SnapshotterNAPI", "getSource: Unknown source type: %d",
                             static_cast<int>(source->getType()));
                return args.Null();
        }
    } catch (const std::exception& e) {
        Logger::error("SnapshotterNAPI", "getSource failed: %s", e.what());
        return args.Null();
    }
}

/**
 * Add an image to the snapshot style.
 *
 * Supported argument forms:
 * - addImage(name, icon, sdf?)                 — an Icon created by IconFactory
 * - addImage(name, image, sdf?)                — a style Image object
 * - addImage(name, buffer, width, height, pixelRatio?, sdf?)
 *                                              — raw RGBA (premultiplied) pixels
 *
 * Trailing optional arguments are scanned positionally: numbers fill
 * width/height/pixelRatio in order, a boolean sets `sdf`.
 *
 * Should be called before start() or from the onDidFinishLoadingStyle /
 * onStyleImageMissing observer callbacks.
 */
napi_value SnapshotterAddImage(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) return args.Undefined();

    // Retrieve the native instance
    MapSnapshotterInstance* snapshotterInstance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&snapshotterInstance)) != napi_ok) {
        snapshotterInstance = nullptr;
    }

    if (!snapshotterInstance || !snapshotterInstance->snapshotter) {
        Logger::warn("SnapshotterNAPI", "addImage: Snapshotter not initialized");
        return args.Undefined();
    }

    // Parse arguments
    std::string name = args.GetString(0, "name");
    if (args.HasError()) return args.Undefined();

    napi_value dataValue = args.GetValue(1);
    if (args.HasError()) return args.Undefined();

    // Scan the trailing optional arguments: booleans set `sdf`, numbers are
    // collected in order (width, height, pixelRatio for the raw-buffer form).
    std::vector<double> numbers;
    bool sdf = false;
    for (size_t i = 2; i < args.Count(); ++i) {
        napi_value val = args.GetValue(i);
        if (args.HasError()) return args.Undefined();

        napi_valuetype valueType;
        napi_typeof(env, val, &valueType);
        if (valueType == napi_boolean) {
            sdf = args.GetBool(i, "sdf");
            if (args.HasError()) return args.Undefined();
        } else if (valueType == napi_number) {
            numbers.push_back(args.GetDouble(i, "number"));
            if (args.HasError()) return args.Undefined();
        }
    }

    try {
        std::unique_ptr<mbgl::style::Image> styleImage;

        if (maplibre::harmony::IconNAPI::IsIconObject(env, dataValue)) {
            // Icon created by IconFactory: image data and scale live on the icon.
            maplibre::harmony::IconNAPI* icon = nullptr;
            if (napi_unwrap(env, dataValue, reinterpret_cast<void**>(&icon)) != napi_ok) {
                icon = nullptr;
            }
            if (!icon) {
                napi_throw_error(env, nullptr, "Failed to unwrap Icon object");
                return nullptr;
            }

            const auto iconImage = icon->getImage();
            if (!iconImage || !iconImage->valid()) {
                napi_throw_error(env, nullptr, "Icon has been released and cannot be added to the snapshot");
                return nullptr;
            }

            const std::string imageId = name.empty() ? icon->getId() : name;
            const float pixelRatio = icon->getScale() > 0.0f ? icon->getScale() : 1.0f;

            // Copy the pixels so the icon stays usable for other consumers.
            mbgl::PremultipliedImage copy = iconImage->clone();
            styleImage = std::make_unique<mbgl::style::Image>(imageId, std::move(copy), pixelRatio, sdf);

            Logger::info("SnapshotterNAPI", "addImage from Icon: %s (%dx%d, ratio: %.2f, sdf: %d)",
                         imageId.c_str(), icon->getWidth(), icon->getHeight(), pixelRatio, sdf);
        } else if (maplibre::harmony::ImageNAPI::IsImageObject(env, dataValue)) {
            // Style Image object: carries its own name, pixel ratio and SDF flag.
            maplibre::harmony::ImageNAPI* imageNapi = maplibre::harmony::ImageNAPI::Unwrap(env, dataValue);
            if (!imageNapi) {
                napi_throw_error(env, nullptr, "Failed to unwrap Image object");
                return nullptr;
            }

            styleImage = imageNapi->toStyleImage();
            if (!styleImage) {
                napi_throw_error(env, nullptr, "Failed to convert Image object");
                return nullptr;
            }

            // The explicit name argument wins over the Image's internal name.
            if (!name.empty() && styleImage->getID() != name) {
                styleImage = std::make_unique<mbgl::style::Image>(
                    name,
                    styleImage->getImage().clone(),
                    styleImage->getPixelRatio(),
                    styleImage->isSdf(),
                    styleImage->getStretchX(),
                    styleImage->getStretchY(),
                    styleImage->getContent()
                );
            }

            Logger::info("SnapshotterNAPI", "addImage from Image object: %s (%dx%d, sdf: %d)",
                         styleImage->getID().c_str(), imageNapi->getWidth(), imageNapi->getHeight(),
                         styleImage->isSdf());
        } else {
            // Raw RGBA (premultiplied) pixel buffer; dimensions are required.
            napi_valuetype valueType;
            napi_typeof(env, dataValue, &valueType);
            void* data = nullptr;
            size_t byteLength = 0;

            if (valueType == napi_object) {
                napi_value arrayBuffer;
                size_t byteOffset;
                napi_status status = napi_get_typedarray_info(env, dataValue, nullptr, &byteLength, &data,
                                                              &arrayBuffer, &byteOffset);
                if (status != napi_ok) {
                    status = napi_get_arraybuffer_info(env, dataValue, &data, &byteLength);
                    if (status != napi_ok) {
                        napi_throw_error(env, nullptr,
                                         "Image data must be an Icon, an Image, an ArrayBuffer or a TypedArray");
                        return nullptr;
                    }
                }
            } else {
                napi_throw_error(env, nullptr,
                                 "Image data must be an Icon, an Image, an ArrayBuffer or a TypedArray");
                return nullptr;
            }

            if (numbers.size() < 2) {
                napi_throw_error(env, nullptr,
                                 "addImage requires width and height when adding raw pixel data");
                return nullptr;
            }

            const uint32_t width = static_cast<uint32_t>(numbers[0]);
            const uint32_t height = static_cast<uint32_t>(numbers[1]);
            const float pixelRatio = numbers.size() >= 3 && numbers[2] > 0.0
                                         ? static_cast<float>(numbers[2])
                                         : 1.0f;

            if (width == 0 || height == 0) {
                napi_throw_error(env, nullptr, "Width and height must be greater than 0");
                return nullptr;
            }

            if (byteLength != static_cast<size_t>(width) * height * 4) {
                Logger::error("SnapshotterNAPI", "addImage: data size mismatch (expected: %u, got: %zu)",
                             width * height * 4, byteLength);
                napi_throw_error(env, nullptr, "Image data size does not match width * height * 4");
                return nullptr;
            }

            mbgl::PremultipliedImage premultipliedImage({width, height});
            std::memcpy(premultipliedImage.data.get(), data, byteLength);
            styleImage = std::make_unique<mbgl::style::Image>(name, std::move(premultipliedImage), pixelRatio, sdf);

            Logger::info("SnapshotterNAPI", "addImage: %s (%ux%u, ratio: %.2f, sdf: %d)",
                         name.c_str(), width, height, pixelRatio, sdf);
        }

        snapshotterInstance->snapshotter->getStyle().addImage(std::move(styleImage));
    } catch (const std::exception& e) {
        Logger::error("SnapshotterNAPI", "addImage failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }

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

