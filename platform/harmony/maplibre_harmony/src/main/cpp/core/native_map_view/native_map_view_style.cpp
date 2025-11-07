#include "native_map_view_harmony.hpp"
#include "rendering/harmony_renderer.hpp"
#include "napi/bindings/style/style_napi.hpp"
#include "napi/bindings/image/image_napi.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "style/transition_options_harmony.hpp"
#include "style/layer_source_factory_harmony.hpp"
#include <mbgl/style/style.hpp>
#include <mbgl/style/image.hpp>
#include <mbgl/style/layer.hpp>
#include <mbgl/style/source.hpp>
#include <mbgl/style/light.hpp>
// 用于资源就绪 gating 的等待
#include <chrono>
#include <thread>

using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;
using maplibre::harmony::ImageNAPI;

namespace mbgl {
namespace harmony {

napi_value NativeMapView::getStyleUrl(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::setStyleUrl(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取this对象
    napi_value thisObj;
    if (napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "setStyleUrl: Failed to get this object");
        return undefined;
    }
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok) {
        Logger::error("NativeMapView", "setStyleUrl: Failed to unwrap instance");
        return undefined;
    }
    
    // 检查 Map 对象是否已初始化
    if (!instance->map) {
        Logger::error("NativeMapView", "setStyleUrl: Map not initialized! Please call setNativeWindow first.");
        return undefined;
    }
    
    // 获取样式URL参数
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
    
    // 提取样式URL字符串
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

    // 资源就绪 gating：等待渲染线程与窗口/上下文和后台资源子系统完成重建
    if (instance->harmonyRenderer) {
        // 等待 500ms；未就绪则尝试自愈重建
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

    // 加载样式 - 必须在 Map+Render Thread 执行
    Logger::info("NativeMapView", "Dispatching loadURL to Map+Render Thread...");
    
    instance->invokeOnMapThread([styleUrl](Map* m) {
        auto* scheduler = Scheduler::GetCurrent();
        auto threadId = std::this_thread::get_id();
        
        Logger::error("DIAGNOSTIC", "===== loadURL THREAD DIAGNOSTIC =====");
        Logger::error("DIAGNOSTIC", "Thread ID: %lu", std::hash<std::thread::id>{}(threadId));
        Logger::error("DIAGNOSTIC", "Scheduler: %p", scheduler);
        Logger::error("DIAGNOSTIC", "Scheduler Type: %s", scheduler ? typeid(*scheduler).name() : "null");
        Logger::error("DIAGNOSTIC", "Map pointer: %p", m);
        Logger::error("DIAGNOSTIC", "About to call loadURL(%s)", styleUrl.c_str());
        
        m->getStyle().loadURL(styleUrl);
        
        Logger::error("DIAGNOSTIC", "loadURL returned");
        Logger::error("DIAGNOSTIC", "Triggering repaint...");
        
        m->triggerRepaint();
        
        Logger::error("DIAGNOSTIC", "Repaint triggered");
        Logger::error("DIAGNOSTIC", "======================================");
    });
    
    Logger::info("NativeMapView", "setStyleUrl: Style URL load dispatched successfully");
    
    return undefined;
}

napi_value NativeMapView::getStyleJson(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取NativeMapView实例
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
    
    // 获取this对象
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
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setStyleJson: Failed to get instance or map not initialized");
        return undefined;
    }
    
    // 获取JSON字符串
    size_t jsonLength = 0;
    napi_get_value_string_utf8(env, args[0], nullptr, 0, &jsonLength);
    std::string json(jsonLength, '\0');
    napi_get_value_string_utf8(env, args[0], &json[0], jsonLength + 1, &jsonLength);
    json.resize(jsonLength);
    
    Logger::info("NativeMapView", "setStyleJson: Loading style JSON (%zu bytes)", json.length());
    
    try {
        instance->invokeOnMapThread([json](mbgl::Map* m){ m->getStyle().loadJSON(json); m->triggerRepaint(); });
        Logger::info("NativeMapView", "setStyleJson: Style JSON loaded successfully");
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "setStyleJson: Failed - %s", e.what());
    }
    
    return undefined;
}

napi_value NativeMapView::setLatLngBounds(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setLatLngBounds: Map not initialized");
        return args.Undefined();
    }
    
    // 检查参数是否为 null（允许清除边界限制）
    if (!args.Has(0)) {
        // 清除边界限制
        instance->invokeOnMapThread([](mbgl::Map* m){ m->setBounds(mbgl::BoundOptions()); });
        Logger::info("NativeMapView", "setLatLngBounds: Bounds cleared (no argument)");
        return args.Undefined();
    }
    
    // TODO: 实现解析 LatLngBounds 参数并设置边界
    Logger::warn("NativeMapView", "setLatLngBounds: LatLngBounds parameter parsing not yet implemented");
    
    return args.Undefined();
}

// Note: setDebug, getDebug, setDebugActive, and isDebugActive are now implemented in native_map_view_debug.cpp

napi_value NativeMapView::getActionJournalLogFiles(napi_env env, napi_callback_info info) {
    // Action journal 需要 ActionJournal 支持，未在 Harmony 配置
    // Action journal requires ActionJournal support, not configured for Harmony
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getActionJournalLog(napi_env env, napi_callback_info info) {
    // Action journal 需要 ActionJournal 支持，未在 Harmony 配置
    // Action journal requires ActionJournal support, not configured for Harmony
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::clearActionJournalLog(napi_env env, napi_callback_info info) {
    // Action journal 需要 ActionJournal 支持，未在 Harmony 配置
    // Action journal requires ActionJournal support, not configured for Harmony
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::isFullyLoaded(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_get_boolean(env, false, &result);
    
    // 获取NativeMapView实例
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

napi_value NativeMapView::getStyle(napi_env env, napi_callback_info info) {
    // 获取NativeMapView实例
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
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 检查是否已有缓存的 Style 实例
    if (instance->styleRef_ != nullptr) {
        napi_value cachedStyle;
        napi_status status = napi_get_reference_value(env, instance->styleRef_, &cachedStyle);
        if (status == napi_ok && cachedStyle != nullptr) {
            return cachedStyle;
        }

        // Cached reference is no longer valid, clean it up and recreate.
        napi_delete_reference(env, instance->styleRef_);
        instance->styleRef_ = nullptr;
    }

    // 检查 Style 构造函数引用是否已初始化
    if (maplibre::harmony::StyleNAPI::constructor == nullptr) {
        Logger::error("NativeMapView", "getStyle: StyleNAPI::constructor is nullptr - Style class not initialized");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 获取 Style 构造函数
    napi_value styleConstructor;
    napi_status status = napi_get_reference_value(env, maplibre::harmony::StyleNAPI::constructor, &styleConstructor);
    if (status != napi_ok) {
        Logger::error("NativeMapView", "getStyle: Failed to get Style constructor reference, status=%d", status);
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 检查构造函数是否有效
    napi_valuetype constructorType;
    napi_typeof(env, styleConstructor, &constructorType);
    if (constructorType != napi_function) {
        Logger::error("NativeMapView", "getStyle: Style constructor is not a function, type=%d", constructorType);
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 创建参数：mapPtr
    napi_value args[1];
    int64_t mapPtr = reinterpret_cast<int64_t>(instance->map);
    napi_create_int64(env, mapPtr, &args[0]);
    // 创建 StyleNAPI 实例
    napi_value styleInstance;
    status = napi_new_instance(env, styleConstructor, 1, args, &styleInstance);
    if (status != napi_ok) {
        Logger::error("NativeMapView", "getStyle: Failed to create Style instance, status=%d", status);
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Cache Style instance to avoid recreating wrappers during polling.
    status = napi_create_reference(env, styleInstance, 1, &instance->styleRef_);
    if (status != napi_ok) {
        Logger::warn("NativeMapView", "getStyle: Failed to create reference for Style instance, status=%d", status);
    }

    return styleInstance;
}

napi_value NativeMapView::getTransitionOptions(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取NativeMapView实例
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
    
    // 获取NativeMapView实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "setTransitionOptions: Map not initialized");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // 解析 TransitionOptions
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
    
    // 获取NativeMapView实例
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
        
        // Create a simple object with light properties
        // TODO: Implement full Light NAPI wrapper class for property modification
        napi_value lightObj;
        napi_create_object(env, &lightObj);
        
        // Add anchor property
        auto anchor = light->getAnchor();
        napi_value anchorValue;
        const char* anchorStr = (anchor == mbgl::style::LightAnchorType::Map) ? "map" : "viewport";
        napi_create_string_utf8(env, anchorStr, NAPI_AUTO_LENGTH, &anchorValue);
        napi_set_named_property(env, lightObj, "anchor", anchorValue);
        
        Logger::info("NativeMapView", "getLight: Returned light object");
        return lightObj;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getLight: Exception - %s", e.what());
        return args.Undefined();
    }
}

napi_value NativeMapView::getLayers(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // 获取NativeMapView实例
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
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getLayer: Map not initialized");
        return args.Undefined();
    }
    
    // 获取layerId参数
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
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // TODO: 需要实现 Layer 的 NAPI 包装类
    // 参考 Android: platform/android/MapLibreAndroid/src/cpp/native_map_view.cpp:1052-1064
    Logger::warn("NativeMapView", "addLayer: Not implemented - requires Layer wrapper classes");
    
    return undefined;
}

napi_value NativeMapView::addLayerAbove(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // TODO: 需要实现 Layer 的 NAPI 包装类
    // 参考 Android: platform/android/MapLibreAndroid/src/cpp/native_map_view.cpp:1066-1103
    Logger::warn("NativeMapView", "addLayerAbove: Not implemented - requires Layer wrapper classes");
    
    return undefined;
}

napi_value NativeMapView::addLayerAt(napi_env env, napi_callback_info info) {
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // TODO: 需要实现 Layer 的 NAPI 包装类
    // 参考 Android: platform/android/MapLibreAndroid/src/cpp/native_map_view.cpp:1105-1128
    Logger::warn("NativeMapView", "addLayerAt: Not implemented - requires Layer wrapper classes");
    
    return undefined;
}

napi_value NativeMapView::removeLayerAt(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_get_boolean(env, false, &result);
    
    // TODO: 需要实现 Layer 的 NAPI 包装类
    // 参考 Android: platform/android/MapLibreAndroid/src/cpp/native_map_view.cpp:1133-1150
    Logger::warn("NativeMapView", "removeLayerAt: Not implemented - requires Layer wrapper classes");
    
    return result;
}

napi_value NativeMapView::removeLayer(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value result;
    napi_get_boolean(env, false, &result);
    
    if (args.HasError()) return result;
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "removeLayer: Map not initialized");
        return result;
    }
    
    // 获取layerId参数
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
    
    // 获取NativeMapView实例
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
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "getSource: Map not initialized");
        return args.Undefined();
    }
    
    // 获取sourceId参数
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
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // TODO: 需要实现 Source 的 NAPI 包装类
    // 参考 Android: platform/android/MapLibreAndroid/src/cpp/native_map_view.cpp:1194-1204
    Logger::warn("NativeMapView", "addSource: Not implemented - requires Source wrapper classes");
    
    return undefined;
}

napi_value NativeMapView::removeSource(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    
    napi_value result;
    napi_get_boolean(env, false, &result);
    
    if (args.HasError()) return result;
    
    // 获取NativeMapView实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "removeSource: Map not initialized");
        return result;
    }
    
    // 获取sourceId参数
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
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    if (args.HasError()) {
        Logger::error("NativeMapView", "addImage: Invalid arguments");
        return undefined;
    }
    
    // 获取 NativeMapView 实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "addImage: Map not initialized");
        return undefined;
    }
    
    try {
        // TODO: 实现从 PixelMap 创建图像
        // 参考 Android bitmap.cpp 和 iOS UIImage+MLNAdditions.mm
        // 需要实现 PixelMap -> PremultipliedImage 的转换
        Logger::warn("NativeMapView", "addImage: PixelMap conversion not implemented yet");
        Logger::info("NativeMapView", "addImage: Please use Image class or Style.addImage() instead");
        
        return undefined;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "addImage: Failed - %s", e.what());
        return undefined;
    }
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
    
    // 获取 NativeMapView 实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "addImages: Map not initialized");
        return undefined;
    }
    
    try {
        // 获取 Image 数组参数
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
        
        // 遍历数组，逐个添加图像
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
    
    // 获取NativeMapView实例和参数
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
    
    // 获取图片名称
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
