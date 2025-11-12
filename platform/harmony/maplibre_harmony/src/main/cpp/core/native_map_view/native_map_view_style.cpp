#include "native_map_view_harmony.hpp"
#include "rendering/harmony_renderer.hpp"
#include "napi/bindings/style/style_napi.hpp"
#include "napi/bindings/image/image_napi.hpp"
#include "napi/core/napi_args.hpp"
#include "geometry/lat_lng_bounds_harmony.hpp"
#include "utils/logger.h"
#include "style/transition_options_harmony.hpp"
#include "style/layer_source_factory_harmony.hpp"
#include <mbgl/map/bound_options.hpp>
#include <mbgl/style/style.hpp>
#include <mbgl/style/image.hpp>
#include <mbgl/style/layer.hpp>
#include <mbgl/style/source.hpp>
#include <mbgl/style/light.hpp>
#include "style/light_harmony.hpp"
// Support waiting for resource readiness gating
#include <chrono>
#include <thread>
#include <cstring>
#include <multimedia/image_framework/image_pixel_map_napi.h>
#include <multimedia/image_framework/image_pixel_map_mdk.h>

using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;
using maplibre::harmony::ImageNAPI;

namespace mbgl {
namespace harmony {

bool CallStyleMethod(napi_env env,
                     NativeMapView* instance,
                     const char* methodName,
                     size_t argc,
                     napi_value* argv) {
    if (!instance || !instance->map) {
        Logger::error("NativeMapView", "CallStyleMethod: Map not initialized");
        return false;
    }

    napi_value styleObject = NativeMapView::ensureStyleWrapper(env, instance);
    if (styleObject == nullptr) {
        Logger::error("NativeMapView", "CallStyleMethod: Failed to acquire Style wrapper");
        return false;
    }

    napi_value method;
    napi_status status = napi_get_named_property(env, styleObject, methodName, &method);
    if (status != napi_ok) {
        Logger::error("NativeMapView", "CallStyleMethod: Failed to get method '%s', status=%d", methodName, status);
        return false;
    }

    napi_valuetype type;
    status = napi_typeof(env, method, &type);
    if (status != napi_ok || type != napi_function) {
        Logger::error("NativeMapView", "CallStyleMethod: Property '%s' is not a function", methodName);
        return false;
    }

    status = napi_call_function(env, styleObject, method, argc, argv, nullptr);
    if (status != napi_ok) {
        bool hasException = false;
        napi_is_exception_pending(env, &hasException);
        if (hasException) {
            napi_value exception;
            napi_get_and_clear_last_exception(env, &exception);
            Logger::error("NativeMapView", "CallStyleMethod: Exception thrown while calling '%s'", methodName);
            // Re-throw to ETS layer so it can handle the error
            napi_throw(env, exception);
        } else {
            Logger::error("NativeMapView", "CallStyleMethod: napi_call_function failed for '%s', status=%d", methodName,
                          status);
        }
        return false;
    }

    return true;
}

napi_value NativeMapView::getStyleUrl(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::setStyleUrl(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // Retrieve the this object
    napi_value thisObj;
    if (napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "setStyleUrl: Failed to get this object");
        return undefined;
    }
    
    // Obtain the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "setStyleUrl: Failed to unwrap instance");
        return undefined;
    }
    
    // Verify that the map object has been initialized
    if (!instance->map) {
        Logger::error("NativeMapView", "setStyleUrl: Map not initialized! Please call setNativeWindow first.");
        return undefined;
    }
    
    // Retrieve the style URL argument
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, nullptr, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "setStyleUrl: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 1) {
        Logger::error("NativeMapView", "setStyleUrl: Missing style URL argument");
        return undefined;
    }
    
    // Extract the style URL string
    size_t strSize;
    if (napi_get_value_string_utf8(env, args[0], nullptr, 0, &strSize) != napi_ok) {
        Logger::error("NativeMapView", "setStyleUrl: Failed to get style URL string size");
        return undefined;
    }
    
    std::string styleUrl(strSize + 1, '\0');
    if (napi_get_value_string_utf8(env, args[0], &styleUrl[0], strSize + 1, &strSize) != napi_ok) {
        Logger::error("NativeMapView", "setStyleUrl: Failed to get style URL string");
        return undefined;
    }
    styleUrl.resize(strSize);
    
    Logger::info("NativeMapView", "Setting style URL: %s", styleUrl.c_str());

    // Resource readiness gating: wait for the render thread, surface/context, and background subsystems to finish rebuilding
    if (instance->harmonyRenderer) {
        // Wait 500 ms; attempt self-healing recovery if still not ready
        const auto start = std::chrono::steady_clock::now();
        const auto timeout = std::chrono::milliseconds(500);
//        while (!instance->harmonyRenderer->isResourcesReady() &&
//               std::chrono::steady_clock::now() - start < timeout) {
//            std::this_thread::sleep_for(std::chrono::milliseconds(20));
//        }
//        if (!instance->harmonyRenderer->isResourcesReady()) {
//            Logger::warn("NativeMapView", "setStyleUrl: resources not ready after 500ms, attempting self-heal");
//            instance->ensureResourcesReadyOrRecover(300 /* extra wait after rebuild */);
//        }
    }

    // 样式即将重新加载，重置已加载标记
    instance->styleLoadedOnce.store(false, std::memory_order_release);

    // Load the style; must run on the map/render thread
    Logger::info("NativeMapView", "Dispatching loadURL to map thread");
    
    instance->invokeOnMapThread([styleUrl](Map* m) {
        m->getStyle().loadURL(styleUrl);
        m->triggerRepaint();
    });
    
    Logger::info("NativeMapView", "setStyleUrl: load dispatched");
    
    return undefined;
}

napi_value NativeMapView::getStyleJson(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // Obtain the NativeMapView instance
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getStyleJson: Failed to get instance or map not initialized");
        return undefined;
    }
    
    try {
        std::string json = instance->invokeOnMapThreadSync([&](mbgl::Map* m){ return m->getStyle().getJSON(); }, std::string{});
        napi_value result;
        napi_create_string_utf8(env, json.c_str(), json.length(), &result);
        return result;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getStyleJson: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::setStyleJson(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // Retrieve the this object
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "setStyleJson: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 1) {
        Logger::error("NativeMapView", "setStyleJson: Missing JSON argument");
        return undefined;
    }
    
    // Obtain the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setStyleJson: Failed to get instance or map not initialized");
        return undefined;
    }
    
    // Retrieve the JSON string
    size_t jsonLength = 0;
    napi_get_value_string_utf8(env, args[0], nullptr, 0, &jsonLength);
    std::string json(jsonLength, '\0');
    napi_get_value_string_utf8(env, args[0], &json[0], jsonLength + 1, &jsonLength);
    json.resize(jsonLength);
    
    Logger::info("NativeMapView", "setStyleJson: Loading style JSON (%zu bytes)", json.length());
    
    try {
        instance->styleLoadedOnce.store(false, std::memory_order_release);
        instance->invokeOnMapThread([json](mbgl::Map* m){ m->getStyle().loadJSON(json); m->triggerRepaint(); });
        Logger::info("NativeMapView", "setStyleJson: Style JSON loaded successfully");
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setStyleJson: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::setLatLngBounds(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Obtain the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setLatLngBounds: Map not initialized");
        return args.Undefined();
    }
    
    // Check whether the argument is null or undefined (allows clearing the bound constraint)
    if (!args.Has(0) || args.IsNullOrUndefined(0)) {
        // Clear the boundary constraint
        instance->invokeOnMapThread([](mbgl::Map* m){
            m->setBounds(mbgl::BoundOptions().withLatLngBounds(mbgl::LatLngBounds()));
        });
        Logger::info("NativeMapView", "setLatLngBounds: Bounds cleared");
        return args.Undefined();
    }
    
    auto boundsValue = args.GetObject(0, "bounds");
    if (args.HasError()) {
        Logger::error("NativeMapView", "setLatLngBounds: Failed to retrieve bounds object - %s", args.GetError().c_str());
        return args.Undefined();
    }
    
    mbgl::LatLngBounds bounds;
    if (!LatLngBoundsHarmony::ParseLatLngBounds(env, boundsValue, bounds)) {
        Logger::error("NativeMapView", "setLatLngBounds: Invalid LatLngBounds argument");
        return args.Undefined();
    }
    
    try {
        instance->invokeOnMapThread([bounds](mbgl::Map* m){
            m->setBounds(mbgl::BoundOptions().withLatLngBounds(bounds));
        });
        Logger::info("NativeMapView", "setLatLngBounds: Applied bounds "
                                      "(north=%.6f, east=%.6f, south=%.6f, west=%.6f)",
                      bounds.north(), bounds.east(), bounds.south(), bounds.west());
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setLatLngBounds: Failed - %s", e.what());
    }
    
    return args.Undefined();
}

// Note: setDebug, getDebug, setDebugActive, and isDebugActive are now implemented in native_map_view_debug.cpp

napi_value NativeMapView::getActionJournalLogFiles(napi_env env, napi_callback_info info) {
    // Action journal requires ActionJournal support, which is not configured on Harmony
    // Action journal requires ActionJournal support, not configured for Harmony
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getActionJournalLog(napi_env env, napi_callback_info info) {
    // Action journal requires ActionJournal support, which is not configured on Harmony
    // Action journal requires ActionJournal support, not configured for Harmony
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::clearActionJournalLog(napi_env env, napi_callback_info info) {
    // Action journal requires ActionJournal support, which is not configured on Harmony
    // Action journal requires ActionJournal support, not configured for Harmony
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::isFullyLoaded(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_get_boolean(env, false, &result);
    
    // Obtain the NativeMapView instance
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::warn("NativeMapView", "isFullyLoaded: Map not initialized, returning false");
        return result;
    }
    
    try {
        bool loaded = instance->invokeOnMapThreadSync([&](mbgl::Map* m){ return m->isFullyLoaded(); }, false);
        napi_get_boolean(env, loaded, &result);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "isFullyLoaded: Failed - %s", e.what());
    }
    
    return result;
}

napi_value NativeMapView::ensureStyleWrapper(napi_env env, NativeMapView* instance) {
    if (!instance) {
        Logger::error("NativeMapView", "ensureStyleWrapper: instance is null");
        return nullptr;
    }
    
    if (!instance->map) {
        Logger::warn("NativeMapView", "ensureStyleWrapper: Map not initialized");
        return nullptr;
    }

    if (instance->styleRef_ != nullptr) {
        napi_value cachedStyle = nullptr;
        napi_status status = napi_get_reference_value(env, instance->styleRef_, &cachedStyle);
        if (status == napi_ok && cachedStyle != nullptr) {
            return cachedStyle;
        }

        Logger::info("NativeMapView", "ensureStyleWrapper: Cached Style reference invalid, recreating");
        napi_delete_reference(env, instance->styleRef_);
        instance->styleRef_ = nullptr;
    }

    if (maplibre::harmony::StyleNAPI::constructor == nullptr) {
        Logger::error("NativeMapView", "ensureStyleWrapper: StyleNAPI::constructor is nullptr");
        return nullptr;
    }

    napi_value constructor;
    napi_status status =
        napi_get_reference_value(env, maplibre::harmony::StyleNAPI::constructor, &constructor);
    if (status != napi_ok) {
        Logger::error("NativeMapView", "ensureStyleWrapper: Failed to get Style constructor reference, status=%d",
                      status);
        return nullptr;
    }

    napi_valuetype constructorType;
    napi_typeof(env, constructor, &constructorType);
    if (constructorType != napi_function) {
        Logger::error("NativeMapView", "ensureStyleWrapper: Style constructor is not a function");
        return nullptr;
    }

    napi_value args[1];
    int64_t mapPtr = reinterpret_cast<int64_t>(instance->map);
    status = napi_create_int64(env, mapPtr, &args[0]);
    if (status != napi_ok) {
        Logger::error("NativeMapView", "ensureStyleWrapper: Failed to create mapPtr argument, status=%d", status);
        return nullptr;
    }

    napi_value styleInstance;
    status = napi_new_instance(env, constructor, 1, args, &styleInstance);
    if (status != napi_ok) {
        Logger::error("NativeMapView", "ensureStyleWrapper: Failed to create Style instance, status=%d", status);
        return nullptr;
    }

    status = napi_create_reference(env, styleInstance, 1, &instance->styleRef_);
    if (status != napi_ok) {
        Logger::warn("NativeMapView",
                     "ensureStyleWrapper: Failed to create reference for Style instance, status=%d", status);
    }

    return styleInstance;
}

napi_value NativeMapView::getStyle(napi_env env, napi_callback_info info) {
    // Obtain the NativeMapView instance
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::warn("NativeMapView", "getStyle: Failed to unwrap instance");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    if (!instance->map) {
        Logger::warn("NativeMapView", "getStyle: Map not initialized");
        napi_value nullValue;
        napi_get_null(env, &nullValue);
        return nullValue;
    }

    napi_value styleInstance = ensureStyleWrapper(env, instance);
    if (styleInstance == nullptr) {
        napi_value nullValue;
        napi_get_null(env, &nullValue);
        return nullValue;
    }

    return styleInstance;
}

napi_value NativeMapView::getTransitionOptions(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // Obtain the NativeMapView instance
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getTransitionOptions: Map not initialized");
        return undefined;
    }
    
    try {
        const auto transitionOptions = instance->invokeOnMapThreadSync([&](mbgl::Map* m){ return m->getStyle().getTransitionOptions(); }, mbgl::style::TransitionOptions{});
        napi_value result = TransitionOptionsHarmony::CreateTransitionOptionsObject(env, transitionOptions);
        return result;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getTransitionOptions: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::setTransitionOptions(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // Obtain the NativeMapView instance
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setTransitionOptions: Map not initialized");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // Parse the TransitionOptions
    napi_value optionsObj = args.GetObject(0, "options");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    mbgl::style::TransitionOptions transitionOptions;
    if (!TransitionOptionsHarmony::ParseTransitionOptions(env, optionsObj, transitionOptions)) {
        Logger::error("NativeMapView", "setTransitionOptions: Failed to parse options");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        instance->invokeOnMapThread([transitionOptions](mbgl::Map* m){ m->getStyle().setTransitionOptions(transitionOptions); });
        Logger::info("NativeMapView", "setTransitionOptions: Set transition options");
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setTransitionOptions: Failed - %s", e.what());
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getLight(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Obtain the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getLight: Map not initialized");
        return args.Undefined();
    }
    
    try {
        mbgl::style::Light* light = instance->map->getStyle().getLight();
        if (!light) {
            Logger::warn("NativeMapView", "getLight: No light in style");
            return args.Undefined();
        }
        
        return mbgl::harmony::LightHarmony::CreateLightPeer(env, *instance->map, *light);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getLight: Exception - %s", e.what());
        return args.Undefined();
    }
}

napi_value NativeMapView::getLayers(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Obtain the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getLayers: Map not initialized");
        return args.Undefined();
    }
    
    try {
        // Get all layers from style
        std::vector<mbgl::style::Layer*> layers = instance->map->getStyle().getLayers();
        
        // Create array
        napi_value layersArray;
        napi_create_array_with_length(env, layers.size(), &layersArray);
        
        // Convert each layer to NAPI object
        for (size_t i = 0; i < layers.size(); i++) {
            napi_value layerObj = LayerSourceFactory::createLayerWrapper(env, layers[i]);
            napi_set_element(env, layersArray, i, layerObj);
        }
        
        Logger::info("NativeMapView", "getLayers: Returned %zu layers", layers.size());
        return layersArray;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getLayers: Exception - %s", e.what());
        return args.Undefined();
    }
}

napi_value NativeMapView::getLayer(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();
    
    // Obtain the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getLayer: Map not initialized");
        return args.Undefined();
    }
    
    // Retrieve the layerId argument
    std::string layerId = args.GetString(0, "layerId");
    if (args.HasError()) return args.Undefined();
    
    try {
        mbgl::style::Layer* layer = instance->map->getStyle().getLayer(layerId);
        if (!layer) {
            Logger::warn("NativeMapView", "getLayer: Layer '%s' not found", layerId.c_str());
            return args.Undefined();
        }
        
        napi_value layerObj = LayerSourceFactory::createLayerWrapper(env, layer);
        Logger::info("NativeMapView", "getLayer: Returned layer '%s'", layerId.c_str());
        return layerObj;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getLayer: Exception - %s", e.what());
        return args.Undefined();
    }
}

napi_value NativeMapView::addLayer(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);

    napi_value undefined = args.Undefined();
    if (args.HasError()) {
        Logger::error("NativeMapView", "addLayer: Invalid arguments");
        return undefined;
    }

    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance || !instance->map) {
        Logger::error("NativeMapView", "addLayer: Map not initialized");
        return undefined;
    }

    napi_value layerValue = args.GetValue(0);
    if (args.HasError()) {
        Logger::error("NativeMapView", "addLayer: Failed to obtain layer argument");
        return undefined;
    }

    napi_value argv[1] = {layerValue};
    if (!CallStyleMethod(env, instance, "addLayer", 1, argv)) {
        Logger::error("NativeMapView", "addLayer: Failed to delegate to Style.addLayer");
    }
    
    return undefined;
}

napi_value NativeMapView::addLayerAbove(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);

    napi_value undefined = args.Undefined();
    if (args.HasError()) {
        Logger::error("NativeMapView", "addLayerAbove: Invalid arguments");
        return undefined;
    }

    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance || !instance->map) {
        Logger::error("NativeMapView", "addLayerAbove: Map not initialized");
        return undefined;
    }

    napi_value layerValue = args.GetValue(0);
    napi_value aboveLayerIdValue = args.GetValue(1);
    if (args.HasError()) {
        Logger::error("NativeMapView", "addLayerAbove: Failed to obtain arguments");
        return undefined;
    }

    napi_value argv[2] = {layerValue, aboveLayerIdValue};
    if (!CallStyleMethod(env, instance, "addLayerAbove", 2, argv)) {
        Logger::error("NativeMapView", "addLayerAbove: Failed to delegate to Style.addLayerAbove");
    }
    
    return undefined;
}

napi_value NativeMapView::addLayerAt(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);

    napi_value undefined = args.Undefined();
    if (args.HasError()) {
        Logger::error("NativeMapView", "addLayerAt: Invalid arguments");
        return undefined;
    }

    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance || !instance->map) {
        Logger::error("NativeMapView", "addLayerAt: Map not initialized");
        return undefined;
    }

    napi_value layerValue = args.GetValue(0);
    napi_value indexValue = args.GetValue(1);
    if (args.HasError()) {
        Logger::error("NativeMapView", "addLayerAt: Failed to obtain arguments");
        return undefined;
    }

    napi_value argv[2] = {layerValue, indexValue};
    if (!CallStyleMethod(env, instance, "addLayerAt", 2, argv)) {
        Logger::error("NativeMapView", "addLayerAt: Failed to delegate to Style.addLayerAt");
    }
    
    return undefined;
}

napi_value NativeMapView::removeLayerAt(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_get_boolean(env, false, &result);
    
    // TODO: Implement the Layer NAPI wrapper
    // Reference Android: platform/android/MapLibreAndroid/src/cpp/native_map_view.cpp:1133-1150
    Logger::warn("NativeMapView", "removeLayerAt: Not implemented - requires Layer wrapper classes");
    
    return result;
}

napi_value NativeMapView::removeLayer(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value result;
    napi_get_boolean(env, false, &result);
    
    if (args.HasError()) return result;
    
    // Obtain the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "removeLayer: Map not initialized");
        return result;
    }
    
    // Retrieve the layerId argument
    std::string layerId = args.GetString(0, "layerId");
    if (args.HasError()) return result;
    
    try {
        // Remove layer from style
        instance->map->getStyle().removeLayer(layerId);
        instance->map->triggerRepaint();
        
        napi_get_boolean(env, true, &result);
        Logger::info("NativeMapView", "removeLayer: Removed layer '%s'", layerId.c_str());
        return result;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "removeLayer: Exception - %s", e.what());
        return result;
    }
}

napi_value NativeMapView::getSources(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Obtain the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getSources: Map not initialized");
        return args.Undefined();
    }
    
    try {
        // Get all sources from style
        std::vector<mbgl::style::Source*> sources = instance->map->getStyle().getSources();
        
        // Create array
        napi_value sourcesArray;
        napi_create_array_with_length(env, sources.size(), &sourcesArray);
        
        // Convert each source to NAPI object
        for (size_t i = 0; i < sources.size(); i++) {
            napi_value sourceObj = LayerSourceFactory::createSourceWrapper(env, sources[i]);
            napi_set_element(env, sourcesArray, i, sourceObj);
        }
        
        Logger::info("NativeMapView", "getSources: Returned %zu sources", sources.size());
        return sourcesArray;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getSources: Exception - %s", e.what());
        return args.Undefined();
    }
}

napi_value NativeMapView::getSource(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();
    
    // Obtain the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getSource: Map not initialized");
        return args.Undefined();
    }
    
    // Retrieve the sourceId argument
    std::string sourceId = args.GetString(0, "sourceId");
    if (args.HasError()) return args.Undefined();
    
    try {
        mbgl::style::Source* source = instance->map->getStyle().getSource(sourceId);
        if (!source) {
            Logger::warn("NativeMapView", "getSource: Source '%s' not found", sourceId.c_str());
            return args.Undefined();
        }
        
        napi_value sourceObj = LayerSourceFactory::createSourceWrapper(env, source);
        Logger::info("NativeMapView", "getSource: Returned source '%s'", sourceId.c_str());
        return sourceObj;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getSource: Exception - %s", e.what());
        return args.Undefined();
    }
}

napi_value NativeMapView::addSource(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);

    napi_value undefined = args.Undefined();
    if (args.HasError()) {
        Logger::error("NativeMapView", "addSource: Invalid arguments");
        return undefined;
    }

    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance || !instance->map) {
        Logger::error("NativeMapView", "addSource: Map not initialized");
        return undefined;
    }

    napi_value sourceValue = args.GetValue(0);
    if (args.HasError()) {
        Logger::error("NativeMapView", "addSource: Failed to obtain source argument");
        return undefined;
    }

    napi_value argv[1] = {sourceValue};
    if (!CallStyleMethod(env, instance, "addSource", 1, argv)) {
        Logger::error("NativeMapView", "addSource: Failed to delegate to Style.addSource");
    }
    
    return undefined;
}

napi_value NativeMapView::removeSource(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value result;
    napi_get_boolean(env, false, &result);
    
    if (args.HasError()) return result;
    
    // Obtain the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "removeSource: Map not initialized");
        return result;
    }
    
    // Retrieve the sourceId argument
    std::string sourceId = args.GetString(0, "sourceId");
    if (args.HasError()) return result;
    
    try {
        // Remove source from style
        instance->map->getStyle().removeSource(sourceId);
        instance->map->triggerRepaint();
        
        napi_get_boolean(env, true, &result);
        Logger::info("NativeMapView", "removeSource: Removed source '%s'", sourceId.c_str());
        return result;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "removeSource: Exception - %s", e.what());
        return result;
    }
}

napi_value NativeMapView::addImage(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(4);
    
    napi_value undefined = args.Undefined();
    if (args.HasError()) {
        Logger::error("NativeMapView", "addImage: Invalid arguments");
        return undefined;
    }
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance || !instance->map) {
        Logger::error("NativeMapView", "addImage: Map not initialized");
        return undefined;
    }
    
    std::string imageName = args.GetString(0, "name");
    napi_value pixelMapValue = args.GetValue(1);
    double pixelRatioDouble = args.GetDouble(2, "pixelRatio");
    bool sdf = args.GetBool(3, "sdf");
    if (args.HasError()) {
        Logger::error("NativeMapView", "addImage: Failed to parse arguments");
        return undefined;
    }

    if (pixelRatioDouble <= 0.0) {
        Logger::warn("NativeMapView", "addImage: pixelRatio <= 0 detected, defaulting to 1.0");
        pixelRatioDouble = 1.0;
    }

    NativePixelMap* nativePixelMap = OH_PixelMap_InitNativePixelMap(env, pixelMapValue);
    if (!nativePixelMap) {
        Logger::error("NativeMapView", "addImage: Failed to get native PixelMap");
        return undefined;
    }

    OhosPixelMapInfos imageInfo{};
    int32_t result = OH_PixelMap_GetImageInfo(nativePixelMap, &imageInfo);
    if (result != 0) {
        Logger::error("NativeMapView", "addImage: Failed to get PixelMap info, error=%d", result);
        return undefined;
    }

    const uint32_t width = static_cast<uint32_t>(imageInfo.width);
    const uint32_t height = static_cast<uint32_t>(imageInfo.height);
    if (width == 0 || height == 0) {
        Logger::error("NativeMapView", "addImage: PixelMap has invalid dimensions (%u x %u)", width, height);
        return undefined;
    }

    void* pixelData = nullptr;
    result = OH_PixelMap_AccessPixels(nativePixelMap, &pixelData);
    if (result != 0 || pixelData == nullptr) {
        Logger::error("NativeMapView", "addImage: Failed to access PixelMap pixels, error=%d", result);
        return undefined;
    }

    const size_t byteSize = static_cast<size_t>(width) * static_cast<size_t>(height) * 4;
    mbgl::PremultipliedImage premultiplied({width, height});
    std::memcpy(premultiplied.data.get(), pixelData, byteSize);

    OH_PixelMap_UnAccessPixels(nativePixelMap);

    try {
        auto* imagePtr = new mbgl::style::Image(
            imageName,
            std::move(premultiplied),
            static_cast<float>(pixelRatioDouble),
            sdf
        );

        std::string imageId = imageName;
        instance->invokeOnMapThread([imagePtr, imageId, width, height](mbgl::Map* map) {
            std::unique_ptr<mbgl::style::Image> image(imagePtr);
            map->getStyle().addImage(std::move(image));
            map->triggerRepaint();
            Logger::info("NativeMapView", "addImage: Added image '%s' (%ux%u)", imageId.c_str(), width, height);
        });
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "addImage: Failed to create style image - %s", e.what());
    }

    return undefined;
}

napi_value NativeMapView::addImages(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    if (args.HasError()) {
        Logger::error("NativeMapView", "addImages: Invalid arguments");
        return undefined;
    }
    
    // Obtain the NativeMapView instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "addImages: Map not initialized");
        return undefined;
    }
    
    try {
        // Retrieve the Image array argument
        napi_value imagesArray = args.GetValue(0);
        bool isArray = false;
        napi_is_array(env, imagesArray, &isArray);
        
        if (!isArray) {
            Logger::error("NativeMapView", "addImages: First argument must be an array");
            return undefined;
        }
        
        uint32_t length = 0;
        napi_get_array_length(env, imagesArray, &length);
        
        if (length == 0) {
            Logger::warn("NativeMapView", "addImages: Empty array provided");
            return undefined;
        }
        
        // Iterate through the array and add images one by one
        for (uint32_t i = 0; i < length; i++) {
            napi_value imageValue;
            napi_get_element(env, imagesArray, i, &imageValue);
            
            // Unwrap Image NAPI object
            ImageNAPI* imageNapi = ImageNAPI::Unwrap(env, imageValue);
            if (!imageNapi) {
                Logger::error("NativeMapView", "addImages: Failed to unwrap Image at index %u", i);
                continue;
            }
            
            // Convert to mbgl::style::Image
            auto styleImage = imageNapi->toStyleImage();
            if (!styleImage) {
                Logger::error("NativeMapView", "addImages: Failed to convert Image to style::Image at index %u", i);
                continue;
            }
            
            // Add to style
            std::string imageName = imageNapi->getName();
            instance->invokeOnMapThread([styleImagePtr = styleImage.release()](mbgl::Map* m) {
                std::unique_ptr<mbgl::style::Image> img(styleImagePtr);
                m->getStyle().addImage(std::move(img));
            });
            
            Logger::info("NativeMapView", "addImages: Added image '%s'", imageName.c_str());
        }
        
        Logger::info("NativeMapView", "addImages: Successfully added %u images", length);
        return undefined;
        
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "addImages: Failed - %s", e.what());
        return undefined;
    }
}

napi_value NativeMapView::removeImage(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // Obtain the NativeMapView instance and arguments
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::error("NativeMapView", "removeImage: Missing image name argument");
        return undefined;
    }
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "removeImage: Map not initialized");
        return undefined;
    }
    
    // Retrieve the image name
    size_t nameLength = 0;
    napi_get_value_string_utf8(env, args[0], nullptr, 0, &nameLength);
    std::string name(nameLength, '\0');
    napi_get_value_string_utf8(env, args[0], &name[0], nameLength + 1, &nameLength);
    name.resize(nameLength);
    
    try {
        instance->invokeOnMapThread([name](mbgl::Map* m){ m->getStyle().removeImage(name); });
        Logger::info("NativeMapView", "removeImage: Removed image '%s'", name.c_str());
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "removeImage: Failed - %s", e.what());
    }
    
    return undefined;
}

} // namespace harmony
} // namespace mbgl
