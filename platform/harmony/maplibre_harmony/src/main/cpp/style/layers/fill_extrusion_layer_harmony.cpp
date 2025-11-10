#include "fill_extrusion_layer_harmony.hpp"
#include "layer_base_methods.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "style/filter_conversion.hpp"
#include "style/layers/layer_property_utils.hpp"
#include <mbgl/style/layers/fill_extrusion_layer.hpp>
#include <mbgl/style/property_value.hpp>
#include <mbgl/style/expression/image.hpp>
#include <mbgl/style/types.hpp>
#include <mbgl/util/color.hpp>

namespace mbgl {
namespace harmony {

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

napi_ref FillExtrusionLayerNAPI::constructor = nullptr;

FillExtrusionLayerNAPI::FillExtrusionLayerNAPI(const std::string& layerId, const std::string& sourceId)
    : layer(std::make_unique<mbgl::style::FillExtrusionLayer>(layerId, sourceId)) {
}

FillExtrusionLayerNAPI::FillExtrusionLayerNAPI(mbgl::style::FillExtrusionLayer* layerPtr) {
    if (layerPtr) {
        weakLayer = layerPtr->makeWeakPtr();
        Logger::info("FillExtrusionLayerNAPI", "FillExtrusionLayer created from existing layer (WeakPtr)");
    }
}


FillExtrusionLayerNAPI::~FillExtrusionLayerNAPI() {
    // Reset weakLayer before layer is destroyed to avoid accessing invalidated WeakPtrFactory
}

void FillExtrusionLayerNAPI::Destructor(napi_env env, void* nativeObject, void* hint) {
    delete static_cast<FillExtrusionLayerNAPI*>(nativeObject);
}

napi_value FillExtrusionLayerNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("FillExtrusionLayerNAPI", "Initializing FillExtrusionLayer NAPI class");
    
    napi_property_descriptor properties[] = {
        { "setFillExtrusionColor", nullptr, SetFillExtrusionColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillExtrusionOpacity", nullptr, SetFillExtrusionOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillExtrusionHeight", nullptr, SetFillExtrusionHeight, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillExtrusionBase", nullptr, SetFillExtrusionBase, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillExtrusionPattern", nullptr, SetFillExtrusionPattern, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillExtrusionTranslate", nullptr, SetFillExtrusionTranslate, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getType", nullptr, GetType, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getSourceId", nullptr, GetSourceId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setVisibility", nullptr, SetVisibility, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getVisibility", nullptr, GetVisibility, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setMinZoom", nullptr, SetMinZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getMinZoom", nullptr, GetMinZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setMaxZoom", nullptr, SetMaxZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getMaxZoom", nullptr, GetMaxZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setSourceLayer", nullptr, SetSourceLayer, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getSourceLayer", nullptr, GetSourceLayer, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFilter", nullptr, SetFilter, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getFilter", nullptr, GetFilter, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // New properties
        { "setFillExtrusionTranslateAnchor", nullptr, SetFillExtrusionTranslateAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getFillExtrusionTranslateAnchor", nullptr, GetFillExtrusionTranslateAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillExtrusionVerticalGradient", nullptr, SetFillExtrusionVerticalGradient, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getFillExtrusionVerticalGradient", nullptr, GetFillExtrusionVerticalGradient, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Generic property methods (Android-compatible API)
        { "setProperty", nullptr, SetProperty, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setProperties", nullptr, SetProperties, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "FillExtrusionLayer", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) return nullptr;
    
    napi_create_reference(env, cons, 1, &constructor);
    napi_set_named_property(env, exports, "FillExtrusionLayer", cons);
    
    Logger::info("FillExtrusionLayerNAPI", "FillExtrusionLayer NAPI class registered");
    return exports;
}

napi_value FillExtrusionLayerNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    args.RequireMinArgs(2);
    if (args.HasError()) return nullptr;
    
    std::string layerId = args.GetString(0, "layerId");
    std::string sourceId = args.GetString(1, "sourceId");
    if (args.HasError()) return nullptr;
    
    FillExtrusionLayerNAPI* layerObj = new FillExtrusionLayerNAPI(layerId, sourceId);
    napi_wrap(env, thisVar, layerObj, Destructor, nullptr, nullptr);
    
    // 添加 _TYPE_ 属性用于 ETS 层的类型判断
    napi_value typeValue;
    napi_create_string_utf8(env, "FillExtrusionLayer", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, thisVar, "_TYPE_", typeValue);
    
    return thisVar;
}

napi_value FillExtrusionLayerNAPI::CreateInstance(napi_env env, mbgl::style::FillExtrusionLayer* layerPtr) {
    if (!layerPtr) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 获取构造函数
    napi_value cons;
    napi_status status = napi_get_reference_value(env, constructor, &cons);
    if (status != napi_ok) {
        Logger::error("FillExtrusionLayerNAPI", "Failed to get constructor reference");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 创建空对象并设置原型（避免调用 JS 构造函数）
    napi_value instance;
    status = napi_create_object(env, &instance);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to create object");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 获取构造函数的原型
    napi_value prototype;
    status = napi_get_named_property(env, cons, "prototype", &prototype);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to get prototype");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 设置对象的原型
    status = napi_set_named_property(env, instance, "__proto__", prototype);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to set prototype");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 创建 NAPI wrapper（使用 WeakPtr 构造函数）
    FillExtrusionLayerNAPI* napiObj = new FillExtrusionLayerNAPI(layerPtr);
    
    // 包装到 JS 对象
    status = napi_wrap(env, instance, napiObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete napiObj;
        Logger::error("FillExtrusionLayerNAPI", "Failed to wrap instance");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 添加 _TYPE_ 属性
    napi_value typeValue;
    napi_create_string_utf8(env, "FillExtrusionLayer", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, instance, "_TYPE_", typeValue);
    
    return instance;
}


napi_value FillExtrusionLayerNAPI::SetFillExtrusionColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    FillExtrusionLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::FillExtrusionLayer, mbgl::Color>(
        env, layerObj->getLayer(), argv[0], "fill-extrusion-color",
        &mbgl::style::FillExtrusionLayer::setFillExtrusionColor
    );
    return thisVar;
}

napi_value FillExtrusionLayerNAPI::SetFillExtrusionOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    FillExtrusionLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::FillExtrusionLayer, float>(
        env, layerObj->getLayer(), argv[0], "fill-extrusion-opacity",
        &mbgl::style::FillExtrusionLayer::setFillExtrusionOpacity
    );
    return thisVar;
}

napi_value FillExtrusionLayerNAPI::SetFillExtrusionHeight(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    FillExtrusionLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::FillExtrusionLayer, float>(
        env, layerObj->getLayer(), argv[0], "fill-extrusion-height",
        &mbgl::style::FillExtrusionLayer::setFillExtrusionHeight
    );
    return thisVar;
}

napi_value FillExtrusionLayerNAPI::SetFillExtrusionBase(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    FillExtrusionLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::FillExtrusionLayer, float>(
        env, layerObj->getLayer(), argv[0], "fill-extrusion-base",
        &mbgl::style::FillExtrusionLayer::setFillExtrusionBase
    );
    return thisVar;
}

napi_value FillExtrusionLayerNAPI::SetFillExtrusionPattern(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    FillExtrusionLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::FillExtrusionLayer, mbgl::style::expression::Image>(
        env, layerObj->getLayer(), argv[0], "fill-extrusion-pattern",
        &mbgl::style::FillExtrusionLayer::setFillExtrusionPattern
    );
    return thisVar;
}

napi_value FillExtrusionLayerNAPI::SetFillExtrusionTranslate(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    FillExtrusionLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::FillExtrusionLayer, std::array<float, 2>>(
        env, layerObj->getLayer(), argv[0], "fill-extrusion-translate",
        &mbgl::style::FillExtrusionLayer::setFillExtrusionTranslate
    );
    return thisVar;
}

// Common layer methods
napi_value FillExtrusionLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillExtrusionLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    std::string id = layerObj->getLayer()->getID();
    napi_value result;
    napi_create_string_utf8(env, id.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value FillExtrusionLayerNAPI::GetType(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_string_utf8(env, "fill-extrusion", NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value FillExtrusionLayerNAPI::GetSourceId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillExtrusionLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    std::string sourceId = layerObj->getLayer()->getSourceID();
    napi_value result;
    napi_create_string_utf8(env, sourceId.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value FillExtrusionLayerNAPI::SetVisibility(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillExtrusionLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) return thisVar;
    
    args.RequireMinArgs(1);
    if (!args.HasError()) {
        std::string visibility = args.GetString(0, "visibility");
        if (visibility == "visible") {
            layerObj->getLayer()->setVisibility(mbgl::style::VisibilityType::Visible);
        } else if (visibility == "none") {
            layerObj->getLayer()->setVisibility(mbgl::style::VisibilityType::None);
        }
    }
    return thisVar;
}

napi_value FillExtrusionLayerNAPI::GetVisibility(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillExtrusionLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    auto visibility = layerObj->getLayer()->getVisibility();
    const char* visStr = (visibility == mbgl::style::VisibilityType::Visible) ? "visible" : "none";
    
    napi_value result;
    napi_create_string_utf8(env, visStr, NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value FillExtrusionLayerNAPI::SetMinZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillExtrusionLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj) return thisVar;

    mbgl::style::FillExtrusionLayer* layer = layerObj->getLayer();
    if (!layer) return thisVar;
    
    args.RequireMinArgs(1);
    if (!args.HasError()) {
        float minZoom = static_cast<float>(args.GetDouble(0, "minZoom"));
        layer->setMinZoom(minZoom);
    }
    return thisVar;
}

napi_value FillExtrusionLayerNAPI::GetMinZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillExtrusionLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj) {
        napi_value result;
        napi_create_double(env, 0.0, &result);
        return result;
    }
    
    mbgl::style::FillExtrusionLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value result;
        napi_create_double(env, 0.0, &result);
        return result;
    }

    float minZoom = layer->getMinZoom();
    napi_value result;
    napi_create_double(env, minZoom, &result);
    return result;
}

napi_value FillExtrusionLayerNAPI::SetMaxZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillExtrusionLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj) return thisVar;

    mbgl::style::FillExtrusionLayer* layer = layerObj->getLayer();
    if (!layer) return thisVar;
    
    args.RequireMinArgs(1);
    if (!args.HasError()) {
        float maxZoom = static_cast<float>(args.GetDouble(0, "maxZoom"));
        layer->setMaxZoom(maxZoom);
    }
    return thisVar;
}

napi_value FillExtrusionLayerNAPI::GetMaxZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillExtrusionLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj) {
        napi_value result;
        napi_create_double(env, 24.0, &result);
        return result;
    }

    mbgl::style::FillExtrusionLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value result;
        napi_create_double(env, 24.0, &result);
        return result;
    }

    float maxZoom = layer->getMaxZoom();
    napi_value result;
    napi_create_double(env, maxZoom, &result);
    return result;
}

napi_value FillExtrusionLayerNAPI::SetSourceLayer(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillExtrusionLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj) return thisVar;

    mbgl::style::FillExtrusionLayer* layer = layerObj->getLayer();
    if (!layer) return thisVar;
    
    args.RequireMinArgs(1);
    if (!args.HasError()) {
        std::string sourceLayer = args.GetString(0, "sourceLayer");
        layer->setSourceLayer(sourceLayer);
    }
    return thisVar;
}

napi_value FillExtrusionLayerNAPI::GetSourceLayer(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillExtrusionLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj) {
        napi_value result;
        napi_create_string_utf8(env, "", NAPI_AUTO_LENGTH, &result);
        return result;
    }
    
    mbgl::style::FillExtrusionLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value result;
        napi_create_string_utf8(env, "", NAPI_AUTO_LENGTH, &result);
        return result;
    }

    std::string sourceLayer = layer->getSourceLayer();
    napi_value result;
    napi_create_string_utf8(env, sourceLayer.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value FillExtrusionLayerNAPI::SetFilter(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    FillExtrusionLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || argc < 1) return thisVar;

    mbgl::style::FillExtrusionLayer* layer = layerObj->getLayer();
    if (!layer) return thisVar;
    
    auto filter = napiArrayToFilter(env, argv[0]);
    if (filter) {
        layer->setFilter(*filter);
    }
    return thisVar;
}

napi_value FillExtrusionLayerNAPI::GetFilter(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillExtrusionLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj) {
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }

    mbgl::style::FillExtrusionLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }

    const auto& filter = layer->getFilter();
    return filterToNapiArray(env, filter);
}

// ============================================================================
// New Properties
// ============================================================================

napi_value FillExtrusionLayerNAPI::SetFillExtrusionTranslateAnchor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    FillExtrusionLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::FillExtrusionLayer, mbgl::style::TranslateAnchorType>(
        env, layerObj->getLayer(), argv[0], "fill-extrusion-translate-anchor",
        &mbgl::style::FillExtrusionLayer::setFillExtrusionTranslateAnchor
    );
    return thisVar;
}

napi_value FillExtrusionLayerNAPI::GetFillExtrusionTranslateAnchor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillExtrusionLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    mbgl::style::FillExtrusionLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }

    return mbgl::harmony::getProperty<mbgl::style::FillExtrusionLayer, mbgl::style::TranslateAnchorType>(
        env, layer, &mbgl::style::FillExtrusionLayer::getFillExtrusionTranslateAnchor
    );
}

napi_value FillExtrusionLayerNAPI::SetFillExtrusionVerticalGradient(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    FillExtrusionLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::FillExtrusionLayer, bool>(
        env, layerObj->getLayer(), argv[0], "fill-extrusion-vertical-gradient",
        &mbgl::style::FillExtrusionLayer::setFillExtrusionVerticalGradient
    );
    return thisVar;
}

napi_value FillExtrusionLayerNAPI::GetFillExtrusionVerticalGradient(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillExtrusionLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    mbgl::style::FillExtrusionLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }

    return mbgl::harmony::getProperty<mbgl::style::FillExtrusionLayer, bool>(
        env, layer, &mbgl::style::FillExtrusionLayer::getFillExtrusionVerticalGradient
    );
}

// ==================== Generic Property Methods ====================

napi_value FillExtrusionLayerNAPI::SetProperty(napi_env env, napi_callback_info info) {
    return SetPropertyImpl<FillExtrusionLayerNAPI, mbgl::style::FillExtrusionLayer>(env, info);
}

napi_value FillExtrusionLayerNAPI::SetProperties(napi_env env, napi_callback_info info) {
    return SetPropertiesImpl<FillExtrusionLayerNAPI, mbgl::style::FillExtrusionLayer>(env, info);
}

} // namespace harmony
} // namespace mbgl
