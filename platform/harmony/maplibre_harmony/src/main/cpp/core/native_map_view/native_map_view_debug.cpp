/**
 * Debug functionality for NativeMapView
 * 
 * Implements map debugging visualizations including:
 * - Tile boundaries
 * - Tile info (x/y/z coordinates)
 * - Timestamps
 * - Collision boxes
 * - Overdraw visualization
 */

#include "native_map_view_harmony.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"

#include <mbgl/map/mode.hpp>

namespace mbgl {
namespace harmony {

/**
 * Set debug options using a bitmask
 * 
 * @param options Bitmask of MapDebugOptions values
 * 
 * Example from ArkTS:
 *   mapView.setDebug(MapDebugOptions.TileBoundaries | MapDebugOptions.CollisionBoxes)
 */
napi_value NativeMapView::setDebug(napi_env env, napi_callback_info info) {
    using namespace mbgl::harmony::napi;
    NapiArgs args(env, info);
    
    // Unwrap instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "setDebug: Failed to unwrap instance");
        return args.Undefined();
    }
    
    if (!instance->map) {
        Logger::error("NativeMapView", "setDebug: Map instance is null");
        return args.Undefined();
    }
    
    // Get debug options parameter (number)
    int32_t debugOptions = args.GetInt32Or(0, 0);
    if (args.HasError()) {
        Logger::error("NativeMapView", "setDebug: Failed to get debug options parameter");
        return args.Undefined();
    }
    
    // Convert int to MapDebugOptions
    mbgl::MapDebugOptions options = static_cast<mbgl::MapDebugOptions>(debugOptions);
    
    Logger::info("NativeMapView", "setDebug: Setting debug options to %d", debugOptions);

    // Map must only be touched on the render thread — a direct call here races
    // the in-flight frame (the "SIGSEGV@0x8" crash pattern).
    instance->invokeOnMapThread([options](mbgl::Map* m) {
        m->setDebug(options);
    });

    return args.Undefined();
}

/**
 * Get current debug options as a bitmask
 * 
 * @return Number representing the bitmask of enabled debug options
 */
napi_value NativeMapView::getDebug(napi_env env, napi_callback_info info) {
    using namespace mbgl::harmony::napi;
    NapiArgs args(env, info);
    
    // Unwrap instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "getDebug: Failed to unwrap instance");
        napi_value result;
        napi_create_int32(env, 0, &result);
        return result;
    }
    
    if (!instance->map) {
        Logger::error("NativeMapView", "getDebug: Map instance is null");
        napi_value result;
        napi_create_int32(env, 0, &result);
        return result;
    }
    
    // Get debug options from the map (render thread only)
    mbgl::MapDebugOptions options = instance->invokeOnMapThreadSync(
        [](mbgl::Map* m) { return m->getDebug(); },
        mbgl::MapDebugOptions::NoDebug);
    
    // Convert to int32
    int32_t debugOptions = static_cast<int32_t>(options);
    
    Logger::debug("NativeMapView", "getDebug: Current debug options: %d", debugOptions);
    
    napi_value result;
    napi_create_int32(env, debugOptions, &result);
    return result;
}

/**
 * Get a description of the active rendering backend and GPU.
 *
 * The backend itself is chosen at compile time (MLN_WITH_OPENGL /
 * MLN_WITH_VULKAN build flags); this exposes which one the native library
 * was built with plus the GPU name, e.g. "vulkan | Mali-G78".
 *
 * @return String with backend and device info
 */
napi_value NativeMapView::getRendererInfo(napi_env env, napi_callback_info info) {
    using namespace mbgl::harmony::napi;
    NapiArgs args(env, info);

    std::string rendererInfo = HarmonyRendererBackend::backendTypeName();

    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::warn("NativeMapView", "getRendererInfo: Failed to unwrap instance, returning compile-time backend only");
    } else if (instance->harmonyRenderer) {
        rendererInfo = instance->harmonyRenderer->getRendererInfo();
    }

    napi_value result;
    napi_create_string_utf8(env, rendererInfo.c_str(), rendererInfo.size(), &result);
    return result;
}

/**
 * Simplified debug toggle - enable or disable a default set of debug options
 * 
 * When enabled, activates:
 * - TileBorders (tile boundaries)
 * - ParseStatus (tile info)
 * - Collision (collision boxes)
 * 
 * This matches the behavior of Android's setDebugActive(boolean)
 * 
 * @param active Boolean indicating whether to enable or disable debug mode
 */
napi_value NativeMapView::setDebugActive(napi_env env, napi_callback_info info) {
    using namespace mbgl::harmony::napi;
    NapiArgs args(env, info);
    
    // Unwrap instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "setDebugActive: Failed to unwrap instance");
        return args.Undefined();
    }
    
    if (!instance->map) {
        Logger::error("NativeMapView", "setDebugActive: Map instance is null");
        return args.Undefined();
    }
    
    // Get active parameter (boolean)
    bool active = args.GetBoolOr(0, false);
    if (args.HasError()) {
        Logger::error("NativeMapView", "setDebugActive: Failed to get active parameter");
        return args.Undefined();
    }
    
    // Set default debug options based on active flag
    mbgl::MapDebugOptions options = active 
        ? (mbgl::MapDebugOptions::TileBorders | 
           mbgl::MapDebugOptions::ParseStatus | 
           mbgl::MapDebugOptions::Collision)
        : mbgl::MapDebugOptions::NoDebug;
    
    Logger::info("NativeMapView", "setDebugActive: %s debug mode", active ? "Enabling" : "Disabling");

    // Map must only be touched on the render thread — a direct call here races
    // the in-flight frame (the "SIGSEGV@0x8" crash pattern).
    instance->invokeOnMapThread([options](mbgl::Map* m) {
        m->setDebug(options);
    });

    return args.Undefined();
}

/**
 * Check if debug mode is currently active
 * 
 * @return Boolean indicating whether any debug options are enabled
 */
napi_value NativeMapView::isDebugActive(napi_env env, napi_callback_info info) {
    using namespace mbgl::harmony::napi;
    NapiArgs args(env, info);
    
    // Unwrap instance
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "isDebugActive: Failed to unwrap instance");
        napi_value result;
        napi_get_boolean(env, false, &result);
        return result;
    }
    
    if (!instance->map) {
        Logger::error("NativeMapView", "isDebugActive: Map instance is null");
        napi_value result;
        napi_get_boolean(env, false, &result);
        return result;
    }
    
    // Get debug options from the map (render thread only)
    mbgl::MapDebugOptions options = instance->invokeOnMapThreadSync(
        [](mbgl::Map* m) { return m->getDebug(); },
        mbgl::MapDebugOptions::NoDebug);
    
    // Check if any debug options are enabled
    bool active = options != mbgl::MapDebugOptions::NoDebug;
    
    Logger::debug("NativeMapView", "isDebugActive: %s", active ? "true" : "false");
    
    napi_value result;
    napi_get_boolean(env, active, &result);
    return result;
}

} // namespace harmony
} // namespace mbgl

