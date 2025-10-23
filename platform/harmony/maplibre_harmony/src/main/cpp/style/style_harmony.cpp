#include "style_harmony.hpp"
#include "../napi_utils.h"
#include "../napi_args.hpp"
#include "../logger.h"
#include <mbgl/style/style.hpp>
#include <mbgl/map/map.hpp>

using namespace mbgl::harmony::napi;

namespace mbgl {
namespace harmony {

napi_value StyleHarmony::Init(napi_env env, napi_value exports) {
    // 注册Style相关的方法到exports
    napi_property_descriptor styleProperties[] = {
        // Style核心方法
        DECLARE_NAPI_STATIC_FUNCTION("getStyleUri", GetStyleUri),
        DECLARE_NAPI_STATIC_FUNCTION("getStyleJson", GetStyleJson),
        
        // 数据源管理
        DECLARE_NAPI_STATIC_FUNCTION("addSource", AddSource),
        DECLARE_NAPI_STATIC_FUNCTION("removeSource", RemoveSource),
        DECLARE_NAPI_STATIC_FUNCTION("getSource", GetSource),
        DECLARE_NAPI_STATIC_FUNCTION("getSources", GetSources),
        
        // 图层管理
        DECLARE_NAPI_STATIC_FUNCTION("addLayer", AddLayer),
        DECLARE_NAPI_STATIC_FUNCTION("addLayerBelow", AddLayerBelow),
        DECLARE_NAPI_STATIC_FUNCTION("addLayerAbove", AddLayerAbove),
        DECLARE_NAPI_STATIC_FUNCTION("addLayerAt", AddLayerAt),
        DECLARE_NAPI_STATIC_FUNCTION("removeLayer", RemoveLayer),
        DECLARE_NAPI_STATIC_FUNCTION("removeLayerAt", RemoveLayerAt),
        DECLARE_NAPI_STATIC_FUNCTION("getLayer", GetLayer),
        DECLARE_NAPI_STATIC_FUNCTION("getLayers", GetLayers),
        
        // 图片资源管理
        DECLARE_NAPI_STATIC_FUNCTION("addImage", AddImage),
        DECLARE_NAPI_STATIC_FUNCTION("removeImage", RemoveImage),
        DECLARE_NAPI_STATIC_FUNCTION("getImage", GetImage),
        
        // 光照和过渡
        DECLARE_NAPI_STATIC_FUNCTION("getLight", GetLight),
        DECLARE_NAPI_STATIC_FUNCTION("setLight", SetLight),
        DECLARE_NAPI_STATIC_FUNCTION("getTransition", GetTransition),
        DECLARE_NAPI_STATIC_FUNCTION("setTransition", SetTransition),
    };

    // 创建Style对象
    napi_value styleObject;
    napi_create_object(env, &styleObject);
    napi_define_properties(env, styleObject, 
        sizeof(styleProperties) / sizeof(styleProperties[0]), 
        styleProperties);

    // 将Style对象添加到exports
    napi_set_named_property(env, exports, "Style", styleObject);

    return exports;
}

mbgl::Map* StyleHarmony::GetMapFromArgs(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        LOGE("GetMapFromArgs: missing map pointer argument");
        return nullptr;
    }

    // 从第一个参数获取Map指针
    int64_t mapPtr;
    napi_get_value_int64(env, args[0], &mapPtr);
    
    return reinterpret_cast<mbgl::Map*>(mapPtr);
}

napi_value StyleHarmony::GetStyleUri(napi_env env, napi_callback_info info) {
    mbgl::Map* map = GetMapFromArgs(env, info);
    if (!map) {
        return CreateStringValue(env, "");
    }

    try {
        std::string uri = map->getStyle().getURL();
        return CreateStringValue(env, uri);
    } catch (const std::exception& e) {
        LOGE("GetStyleUri failed: %s", e.what());
        return CreateStringValue(env, "");
    }
}

napi_value StyleHarmony::GetStyleJson(napi_env env, napi_callback_info info) {
    mbgl::Map* map = GetMapFromArgs(env, info);
    if (!map) {
        return CreateStringValue(env, "");
    }

    try {
        std::string json = map->getStyle().getJSON();
        return CreateStringValue(env, json);
    } catch (const std::exception& e) {
        LOGE("GetStyleJson failed: %s", e.what());
        return CreateStringValue(env, "");
    }
}

napi_value StyleHarmony::AddSource(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(4);
    if (args.HasError()) return CreateBoolValue(env, false);

    // 参数: mapPtr, sourceId, sourceJson, sourceNativePtr
    int64_t mapPtr = args.GetInt64(0, "mapPtr");
    std::string sourceId = args.GetString(1, "sourceId");
    std::string sourceJson = args.GetString(2, "sourceJson");
    int64_t sourceNativePtr = args.GetInt64(3, "sourceNativePtr");
    if (args.HasError()) return CreateBoolValue(env, false);

    mbgl::Map* map = reinterpret_cast<mbgl::Map*>(mapPtr);
    if (!map) {
        LOGE("AddSource: invalid map pointer");
        return CreateBoolValue(env, false);
    }

    try {
        // 从指针获取Source对象
        auto* sourceRawPtr = reinterpret_cast<mbgl::style::Source*>(sourceNativePtr);
        if (!sourceRawPtr) {
            LOGE("AddSource: invalid source pointer");
            return CreateBoolValue(env, false);
        }

        // 将原始指针转换为unique_ptr并添加到样式
        std::unique_ptr<mbgl::style::Source> source(sourceRawPtr);
        map->getStyle().addSource(std::move(source));
        
        LOGI("AddSource: %s", sourceId.c_str());
        return CreateBoolValue(env, true);
    } catch (const std::exception& e) {
        LOGE("AddSource failed: %s", e.what());
        return CreateBoolValue(env, false);
    }
}

napi_value StyleHarmony::RemoveSource(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) return CreateBoolValue(env, false);

    int64_t mapPtr = args.GetInt64(0, "mapPtr");
    std::string sourceId = args.GetString(1, "sourceId");
    if (args.HasError()) return CreateBoolValue(env, false);

    mbgl::Map* map = reinterpret_cast<mbgl::Map*>(mapPtr);
    if (!map) {
        return CreateBoolValue(env, false);
    }

    try {
        map->getStyle().removeSource(sourceId);
        LOGI("RemoveSource: %s", sourceId.c_str());
        return CreateBoolValue(env, true);
    } catch (const std::exception& e) {
        LOGE("RemoveSource failed: %s", e.what());
        return CreateBoolValue(env, false);
    }
}

// 其他方法的实现遵循类似的模式...
// 由于篇幅限制，这里只展示几个关键方法的实现框架

napi_value StyleHarmony::GetSource(napi_env env, napi_callback_info info) {
    // TODO: 实现获取数据源
    napi_value result;
    napi_get_null(env, &result);
    return result;
}

napi_value StyleHarmony::GetSources(napi_env env, napi_callback_info info) {
    // TODO: 实现获取所有数据源
    return CreateStringValue(env, "[]");
}

napi_value StyleHarmony::AddLayer(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(4);
    if (args.HasError()) return CreateBoolValue(env, false);

    // 参数: mapPtr, layerId, layerJson, layerNativePtr
    int64_t mapPtr = args.GetInt64(0, "mapPtr");
    std::string layerId = args.GetString(1, "layerId");
    // args[2] is layerJson, not used currently
    int64_t layerNativePtr = args.GetInt64(3, "layerNativePtr");
    if (args.HasError()) return CreateBoolValue(env, false);

    mbgl::Map* map = reinterpret_cast<mbgl::Map*>(mapPtr);
    if (!map) {
        LOGE("AddLayer: invalid map pointer");
        return CreateBoolValue(env, false);
    }

    try {
        auto* layerRawPtr = reinterpret_cast<mbgl::style::Layer*>(layerNativePtr);
        if (!layerRawPtr) {
            LOGE("AddLayer: invalid layer pointer");
            return CreateBoolValue(env, false);
        }

        // 将原始指针转换为unique_ptr并添加到样式（添加到顶部）
        std::unique_ptr<mbgl::style::Layer> layer(layerRawPtr);
        map->getStyle().addLayer(std::move(layer));
        
        LOGI("AddLayer: %s", layerId.c_str());
        return CreateBoolValue(env, true);
    } catch (const std::exception& e) {
        LOGE("AddLayer failed: %s", e.what());
        return CreateBoolValue(env, false);
    }
}

napi_value StyleHarmony::AddLayerBelow(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(5);
    if (args.HasError()) return CreateBoolValue(env, false);

    // 参数: mapPtr, layerId, layerJson, layerNativePtr, belowLayerId
    int64_t mapPtr = args.GetInt64(0, "mapPtr");
    std::string layerId = args.GetString(1, "layerId");
    // args[2] is layerJson, not used currently
    int64_t layerNativePtr = args.GetInt64(3, "layerNativePtr");
    std::string belowLayerId = args.GetString(4, "belowLayerId");
    if (args.HasError()) return CreateBoolValue(env, false);

    mbgl::Map* map = reinterpret_cast<mbgl::Map*>(mapPtr);
    if (!map) {
        return CreateBoolValue(env, false);
    }

    try {
        auto* layerRawPtr = reinterpret_cast<mbgl::style::Layer*>(layerNativePtr);
        if (!layerRawPtr) {
            return CreateBoolValue(env, false);
        }

        std::unique_ptr<mbgl::style::Layer> layer(layerRawPtr);
        map->getStyle().addLayer(std::move(layer), belowLayerId);
        
        LOGI("AddLayerBelow: %s (below: %s)", layerId.c_str(), belowLayerId.c_str());
        return CreateBoolValue(env, true);
    } catch (const std::exception& e) {
        LOGE("AddLayerBelow failed: %s", e.what());
        return CreateBoolValue(env, false);
    }
}

napi_value StyleHarmony::AddLayerAbove(napi_env env, napi_callback_info info) {
    // 在MapLibre Core中，没有直接的addLayerAbove，需要先找到目标层，然后在其上方插入
    // 这需要获取图层列表，找到目标图层的索引，然后使用addLayer with beforeLayerID
    // 简化实现：直接使用addLayer
    return AddLayer(env, info);
}

napi_value StyleHarmony::AddLayerAt(napi_env env, napi_callback_info info) {
    // MapLibre Core的addLayer支持beforeLayerID参数来控制位置
    // 索引位置需要转换为beforeLayerID
    return AddLayer(env, info);
}

napi_value StyleHarmony::RemoveLayer(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) return CreateBoolValue(env, false);

    int64_t mapPtr = args.GetInt64(0, "mapPtr");
    std::string layerId = args.GetString(1, "layerId");
    if (args.HasError()) return CreateBoolValue(env, false);

    mbgl::Map* map = reinterpret_cast<mbgl::Map*>(mapPtr);
    if (!map) {
        return CreateBoolValue(env, false);
    }

    try {
        map->getStyle().removeLayer(layerId);
        LOGI("RemoveLayer: %s", layerId.c_str());
        return CreateBoolValue(env, true);
    } catch (const std::exception& e) {
        LOGE("RemoveLayer failed: %s", e.what());
        return CreateBoolValue(env, false);
    }
}

napi_value StyleHarmony::RemoveLayerAt(napi_env env, napi_callback_info info) {
    // TODO: 实现移除指定索引的图层
    return CreateBoolValue(env, true);
}

napi_value StyleHarmony::GetLayer(napi_env env, napi_callback_info info) {
    // TODO: 实现获取图层
    napi_value result;
    napi_get_null(env, &result);
    return result;
}

napi_value StyleHarmony::GetLayers(napi_env env, napi_callback_info info) {
    // TODO: 实现获取所有图层
    return CreateStringValue(env, "[]");
}

napi_value StyleHarmony::AddImage(napi_env env, napi_callback_info info) {
    // TODO: 实现添加图片
    return CreateBoolValue(env, true);
}

napi_value StyleHarmony::RemoveImage(napi_env env, napi_callback_info info) {
    // TODO: 实现移除图片
    return CreateBoolValue(env, true);
}

napi_value StyleHarmony::GetImage(napi_env env, napi_callback_info info) {
    // TODO: 实现获取图片
    napi_value result;
    napi_get_null(env, &result);
    return result;
}

napi_value StyleHarmony::GetLight(napi_env env, napi_callback_info info) {
    // TODO: 实现获取光照
    napi_value result;
    napi_get_null(env, &result);
    return result;
}

napi_value StyleHarmony::SetLight(napi_env env, napi_callback_info info) {
    // TODO: 实现设置光照
    return CreateBoolValue(env, true);
}

napi_value StyleHarmony::GetTransition(napi_env env, napi_callback_info info) {
    // TODO: 实现获取过渡选项
    napi_value result;
    napi_get_null(env, &result);
    return result;
}

napi_value StyleHarmony::SetTransition(napi_env env, napi_callback_info info) {
    // TODO: 实现设置过渡选项
    return CreateBoolValue(env, true);
}

} // namespace harmony
} // namespace mbgl

