#include "line_layer_harmony.hpp"
#include "layer_base_methods.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "style/filter_conversion.hpp"
#include "style/layers/layer_property_utils.hpp"
#include <mbgl/style/layers/line_layer.hpp>
#include <mbgl/style/property_value.hpp>
#include <mbgl/style/expression/image.hpp>
#include <mbgl/style/types.hpp>
#include <mbgl/util/color.hpp>

namespace mbgl {
namespace harmony {

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

// Static member initialization
napi_ref LineLayerNAPI::constructor = nullptr;

LineLayerNAPI::LineLayerNAPI(const std::string& layerId, const std::string& sourceId)
    : layer(std::make_unique<mbgl::style::LineLayer>(layerId, sourceId)) {
}

LineLayerNAPI::LineLayerNAPI(mbgl::style::LineLayer* layerPtr) {
    if (layerPtr) {
        weakLayer = layerPtr->makeWeakPtr();
        Logger::info("LineLayerNAPI", "LineLayer created from existing layer (WeakPtr)");
    }
}


LineLayerNAPI::~LineLayerNAPI() {
    // Reset weakLayer before layer is destroyed to avoid accessing invalidated WeakPtrFactory
}

void LineLayerNAPI::Destructor(napi_env env, void* nativeObject, void* hint) {
    LineLayerNAPI* obj = static_cast<LineLayerNAPI*>(nativeObject);
    delete obj;
}

napi_value LineLayerNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("LineLayerNAPI", "Initializing LineLayer NAPI class");
    
    napi_property_descriptor properties[] = {
        // Setter methods (support Expression)
        { "setLineColor", nullptr, SetLineColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLineWidth", nullptr, SetLineWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLineOpacity", nullptr, SetLineOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLinePattern", nullptr, SetLinePattern, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLineGapWidth", nullptr, SetLineGapWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLineDasharray", nullptr, SetLineDasharray, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLineBlur", nullptr, SetLineBlur, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLineOffset", nullptr, SetLineOffset, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLineCap", nullptr, SetLineCap, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLineJoin", nullptr, SetLineJoin, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Getter methods (return constant or Expression)
        { "getLineColor", nullptr, GetLineColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getLineWidth", nullptr, GetLineWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getLineOpacity", nullptr, GetLineOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Layer base methods
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getType", nullptr, GetType, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getSourceId", nullptr, GetSourceId, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Visibility, zoom, source layer, filter - common to all layers
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
        { "setLineTranslate", nullptr, SetLineTranslate, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getLineTranslate", nullptr, GetLineTranslate, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLineTranslateAnchor", nullptr, SetLineTranslateAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getLineTranslateAnchor", nullptr, GetLineTranslateAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLineMiterLimit", nullptr, SetLineMiterLimit, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getLineMiterLimit", nullptr, GetLineMiterLimit, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLineRoundLimit", nullptr, SetLineRoundLimit, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getLineRoundLimit", nullptr, GetLineRoundLimit, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLineGradient", nullptr, SetLineGradient, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getLineGradient", nullptr, GetLineGradient, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLineSortKey", nullptr, SetLineSortKey, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getLineSortKey", nullptr, GetLineSortKey, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Generic property methods (Android-compatible API)
        { "setProperty", nullptr, SetProperty, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setProperties", nullptr, SetProperties, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "LineLayer", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("LineLayerNAPI", "Failed to define LineLayer class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("LineLayerNAPI", "Failed to create reference to LineLayer constructor");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "LineLayer", cons);
    if (status != napi_ok) {
        Logger::error("LineLayerNAPI", "Failed to export LineLayer class");
        return nullptr;
    }
    
    Logger::info("LineLayerNAPI", "LineLayer NAPI class registered successfully");
    return exports;
}

napi_value LineLayerNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    args.RequireMinArgs(2);
    if (args.HasError()) {
        return nullptr;
    }
    
    std::string layerId = args.GetString(0, "layerId");
    std::string sourceId = args.GetString(1, "sourceId");
    if (args.HasError()) {
        return nullptr;
    }
    
    LineLayerNAPI* layerObj = new LineLayerNAPI(layerId, sourceId);
    
    napi_status status = napi_wrap(env, thisVar, layerObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete layerObj;
        Logger::error("LineLayerNAPI", "Failed to wrap LineLayer object");
        return nullptr;
    }
    

    
    // 添加 _TYPE_ 属性用于 ETS 层的类型判断
    napi_value typeValue;
    napi_create_string_utf8(env, "LineLayer", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, thisVar, "_TYPE_", typeValue);
    return thisVar;
}

napi_value LineLayerNAPI::CreateInstance(napi_env env, mbgl::style::LineLayer* layerPtr) {
    if (!layerPtr) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 获取构造函数
    napi_value cons;
    napi_status status = napi_get_reference_value(env, constructor, &cons);
    if (status != napi_ok) {
        Logger::error("LineLayerNAPI", "Failed to get constructor reference");
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
    LineLayerNAPI* napiObj = new LineLayerNAPI(layerPtr);
    
    // 包装到 JS 对象
    status = napi_wrap(env, instance, napiObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete napiObj;
        Logger::error("LineLayerNAPI", "Failed to wrap instance");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 添加 _TYPE_ 属性
    napi_value typeValue;
    napi_create_string_utf8(env, "LineLayer", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, instance, "_TYPE_", typeValue);
    
    return instance;
}


// ============================================================================
// Paint Property Setters (支持 Expression)
// ============================================================================

napi_value LineLayerNAPI::SetLineColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::LineLayer, mbgl::Color>(
        env,
        layerObj->getLayer(),
        argv[0],
        "line-color",
        &mbgl::style::LineLayer::setLineColor
    );
    
    return thisVar;
}

napi_value LineLayerNAPI::SetLineWidth(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::LineLayer, float>(
        env,
        layerObj->getLayer(),
        argv[0],
        "line-width",
        &mbgl::style::LineLayer::setLineWidth
    );
    
    return thisVar;
}

napi_value LineLayerNAPI::SetLineOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::LineLayer, float>(
        env,
        layerObj->getLayer(),
        argv[0],
        "line-opacity",
        &mbgl::style::LineLayer::setLineOpacity
    );
    
    return thisVar;
}

napi_value LineLayerNAPI::SetLinePattern(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::LineLayer, mbgl::style::expression::Image>(
        env,
        layerObj->getLayer(),
        argv[0],
        "line-pattern",
        &mbgl::style::LineLayer::setLinePattern
    );
    
    return thisVar;
}

napi_value LineLayerNAPI::SetLineGapWidth(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::LineLayer, float>(
        env,
        layerObj->getLayer(),
        argv[0],
        "line-gap-width",
        &mbgl::style::LineLayer::setLineGapWidth
    );
    
    return thisVar;
}

napi_value LineLayerNAPI::SetLineDasharray(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::LineLayer, std::vector<float>>(
        env,
        layerObj->getLayer(),
        argv[0],
        "line-dasharray",
        &mbgl::style::LineLayer::setLineDasharray
    );
    
    return thisVar;
}

napi_value LineLayerNAPI::SetLineBlur(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::LineLayer, float>(
        env,
        layerObj->getLayer(),
        argv[0],
        "line-blur",
        &mbgl::style::LineLayer::setLineBlur
    );
    
    return thisVar;
}

napi_value LineLayerNAPI::SetLineOffset(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::LineLayer, float>(
        env,
        layerObj->getLayer(),
        argv[0],
        "line-offset",
        &mbgl::style::LineLayer::setLineOffset
    );
    
    return thisVar;
}

// ============================================================================
// Layout Property Setters
// ============================================================================

napi_value LineLayerNAPI::SetLineCap(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setLayoutProperty<mbgl::style::LineLayer, mbgl::style::LineCapType>(
        env,
        layerObj->getLayer(),
        argv[0],
        "line-cap",
        &mbgl::style::LineLayer::setLineCap
    );
    
    return thisVar;
}

napi_value LineLayerNAPI::SetLineJoin(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setLayoutProperty<mbgl::style::LineLayer, mbgl::style::LineJoinType>(
        env,
        layerObj->getLayer(),
        argv[0],
        "line-join",
        &mbgl::style::LineLayer::setLineJoin
    );
    
    return thisVar;
}

// ============================================================================
// Property Getters (返回常量或 Expression)
// ============================================================================

napi_value LineLayerNAPI::GetLineColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    mbgl::style::LineLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    return mbgl::harmony::getProperty<mbgl::style::LineLayer, mbgl::Color>(
        env,
        layer,
        &mbgl::style::LineLayer::getLineColor
    );
}

napi_value LineLayerNAPI::GetLineWidth(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    mbgl::style::LineLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    return mbgl::harmony::getProperty<mbgl::style::LineLayer, float>(
        env,
        layer,
        &mbgl::style::LineLayer::getLineWidth
    );
}

napi_value LineLayerNAPI::GetLineOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    mbgl::style::LineLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    return mbgl::harmony::getProperty<mbgl::style::LineLayer, float>(
        env,
        layer,
        &mbgl::style::LineLayer::getLineOpacity
    );
}

// ============================================================================
// Base Layer Methods (common to all layers)
// ============================================================================

napi_value LineLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
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

napi_value LineLayerNAPI::GetType(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_string_utf8(env, "line", NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value LineLayerNAPI::GetSourceId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
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

napi_value LineLayerNAPI::SetVisibility(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer()) {
        return thisVar;
    }
    
    args.RequireMinArgs(1);
    if (args.HasError()) {
        return thisVar;
    }
    
    std::string visibility = args.GetString(0, "visibility");
    if (visibility == "visible") {
        layerObj->getLayer()->setVisibility(mbgl::style::VisibilityType::Visible);
    } else if (visibility == "none") {
        layerObj->getLayer()->setVisibility(mbgl::style::VisibilityType::None);
    }
    
    return thisVar;
}

napi_value LineLayerNAPI::GetVisibility(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
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

napi_value LineLayerNAPI::SetMinZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj) {
        return thisVar;
    }
    
    mbgl::style::LineLayer* layer = layerObj->getLayer();
    if (!layer) {
        return thisVar;
    }

    args.RequireMinArgs(1);
    if (!args.HasError()) {
        float minZoom = static_cast<float>(args.GetDouble(0, "minZoom"));
        layer->setMinZoom(minZoom);
    }
    
    return thisVar;
}

napi_value LineLayerNAPI::GetMinZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj) {
        napi_value result;
        napi_create_double(env, 0.0, &result);
        return result;
    }
    
    mbgl::style::LineLayer* layer = layerObj->getLayer();
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

napi_value LineLayerNAPI::SetMaxZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj) {
        return thisVar;
    }
    
    mbgl::style::LineLayer* layer = layerObj->getLayer();
    if (!layer) {
        return thisVar;
    }

    args.RequireMinArgs(1);
    if (!args.HasError()) {
        float maxZoom = static_cast<float>(args.GetDouble(0, "maxZoom"));
        layer->setMaxZoom(maxZoom);
    }
    
    return thisVar;
}

napi_value LineLayerNAPI::GetMaxZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj) {
        napi_value result;
        napi_create_double(env, 24.0, &result);
        return result;
    }

    mbgl::style::LineLayer* layer = layerObj->getLayer();
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

napi_value LineLayerNAPI::SetSourceLayer(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj) {
        return thisVar;
    }
    
    mbgl::style::LineLayer* layer = layerObj->getLayer();
    if (!layer) {
        return thisVar;
    }

    args.RequireMinArgs(1);
    if (!args.HasError()) {
        std::string sourceLayer = args.GetString(0, "sourceLayer");
        layer->setSourceLayer(sourceLayer);
    }
    
    return thisVar;
}

napi_value LineLayerNAPI::GetSourceLayer(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj) {
        napi_value result;
        napi_create_string_utf8(env, "", NAPI_AUTO_LENGTH, &result);
        return result;
    }
    
    mbgl::style::LineLayer* layer = layerObj->getLayer();
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

napi_value LineLayerNAPI::SetFilter(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || argc < 1) {
        return thisVar;
    }
    
    mbgl::style::LineLayer* layer = layerObj->getLayer();
    if (!layer) {
        return thisVar;
    }

    auto filter = napiArrayToFilter(env, argv[0]);
    if (filter) {
        layer->setFilter(*filter);
    }
    
    return thisVar;
}

napi_value LineLayerNAPI::GetFilter(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj) {
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }

    mbgl::style::LineLayer* layer = layerObj->getLayer();
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

napi_value LineLayerNAPI::SetLineTranslate(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::LineLayer, std::array<float, 2>>(
        env,
        layerObj->getLayer(),
        argv[0],
        "line-translate",
        &mbgl::style::LineLayer::setLineTranslate
    );
    
    return thisVar;
}

napi_value LineLayerNAPI::GetLineTranslate(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    mbgl::style::LineLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }

    return mbgl::harmony::getProperty<mbgl::style::LineLayer, std::array<float, 2>>(
        env,
        layer,
        &mbgl::style::LineLayer::getLineTranslate
    );
}

napi_value LineLayerNAPI::SetLineTranslateAnchor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::LineLayer, mbgl::style::TranslateAnchorType>(
        env,
        layerObj->getLayer(),
        argv[0],
        "line-translate-anchor",
        &mbgl::style::LineLayer::setLineTranslateAnchor
    );
    
    return thisVar;
}

napi_value LineLayerNAPI::GetLineTranslateAnchor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    mbgl::style::LineLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }

    return mbgl::harmony::getProperty<mbgl::style::LineLayer, mbgl::style::TranslateAnchorType>(
        env,
        layer,
        &mbgl::style::LineLayer::getLineTranslateAnchor
    );
}

napi_value LineLayerNAPI::SetLineMiterLimit(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setLayoutProperty<mbgl::style::LineLayer, float>(
        env,
        layerObj->getLayer(),
        argv[0],
        "line-miter-limit",
        &mbgl::style::LineLayer::setLineMiterLimit
    );
    
    return thisVar;
}

napi_value LineLayerNAPI::GetLineMiterLimit(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    mbgl::style::LineLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }

    return mbgl::harmony::getProperty<mbgl::style::LineLayer, float>(
        env,
        layer,
        &mbgl::style::LineLayer::getLineMiterLimit
    );
}

napi_value LineLayerNAPI::SetLineRoundLimit(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setLayoutProperty<mbgl::style::LineLayer, float>(
        env,
        layerObj->getLayer(),
        argv[0],
        "line-round-limit",
        &mbgl::style::LineLayer::setLineRoundLimit
    );
    
    return thisVar;
}

napi_value LineLayerNAPI::GetLineRoundLimit(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    mbgl::style::LineLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }

    return mbgl::harmony::getProperty<mbgl::style::LineLayer, float>(
        env,
        layer,
        &mbgl::style::LineLayer::getLineRoundLimit
    );
}

napi_value LineLayerNAPI::SetLineGradient(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) {
        return thisVar;
    }
    
    // lineGradient uses ColorRampPropertyValue which requires expression
    // TODO: Implement ColorRampPropertyValue conversion in future version
    Logger::warn("LineLayerNAPI", "setLineGradient: ColorRampPropertyValue conversion not yet fully implemented");
    
    return thisVar;
}

napi_value LineLayerNAPI::GetLineGradient(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }

    mbgl::style::LineLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // ColorRampPropertyValue requires special handling
    // Return undefined for now - gradient is expression-only
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value LineLayerNAPI::SetLineSortKey(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setLayoutProperty<mbgl::style::LineLayer, float>(
        env,
        layerObj->getLayer(),
        argv[0],
        "line-sort-key",
        &mbgl::style::LineLayer::setLineSortKey
    );
    
    return thisVar;
}

napi_value LineLayerNAPI::GetLineSortKey(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    mbgl::style::LineLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }

    return mbgl::harmony::getProperty<mbgl::style::LineLayer, float>(
        env,
        layer,
        &mbgl::style::LineLayer::getLineSortKey
    );
}

// ==================== Generic Property Methods ====================

napi_value LineLayerNAPI::SetProperty(napi_env env, napi_callback_info info) {
    return SetPropertyImpl<LineLayerNAPI, mbgl::style::LineLayer>(env, info);
}

napi_value LineLayerNAPI::SetProperties(napi_env env, napi_callback_info info) {
    return SetPropertiesImpl<LineLayerNAPI, mbgl::style::LineLayer>(env, info);
}

} // namespace harmony
} // namespace mbgl
