#include "line_layer_harmony.hpp"
#include "../../napi_args.hpp"
#include "../../logger.h"
#include "../filter_conversion.hpp"
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
    Logger::debug("LineLayerNAPI", "LineLayer created: %s (source: %s)", layerId.c_str(), sourceId.c_str());
}

LineLayerNAPI::~LineLayerNAPI() {
    Logger::debug("LineLayerNAPI", "LineLayer destroyed");
}

void LineLayerNAPI::Destructor(napi_env env, void* nativeObject, void* hint) {
    LineLayerNAPI* obj = static_cast<LineLayerNAPI*>(nativeObject);
    delete obj;
}

napi_value LineLayerNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("LineLayerNAPI", "Initializing LineLayer NAPI class");
    
    napi_property_descriptor properties[] = {
        // Setter methods
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
        
        // Getter methods
        { "getLineColor", nullptr, GetLineColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getLineWidth", nullptr, GetLineWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getLineOpacity", nullptr, GetLineOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Layer base methods
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getType", nullptr, GetType, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getSourceId", nullptr, GetSourceId, nullptr, nullptr, nullptr, napi_default, nullptr },
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
    
    // Require 2 arguments: layerId and sourceId
    args.RequireMinArgs(2);
    if (args.HasError()) {
        return nullptr;
    }
    
    std::string layerId = args.GetString(0, "layerId");
    std::string sourceId = args.GetString(1, "sourceId");
    if (args.HasError()) {
        return nullptr;
    }
    
    // Create LineLayerNAPI instance
    LineLayerNAPI* layerObj = new LineLayerNAPI(layerId, sourceId);
    
    // Wrap native object
    napi_status status = napi_wrap(env, thisVar, layerObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete layerObj;
        Logger::error("LineLayerNAPI", "Failed to wrap LineLayer object");
        return nullptr;
    }
    
    return thisVar;
}

napi_value LineLayerNAPI::SetLineColor(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("LineLayerNAPI", "Failed to unwrap LineLayer object");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    args.RequireMinArgs(1);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    std::string colorStr = args.GetString(0, "color");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        auto color = mbgl::Color::parse(colorStr);
        if (color) {
            layerObj->layer->setLineColor(mbgl::style::PropertyValue<mbgl::Color>(*color));
            Logger::debug("LineLayerNAPI", "LineColor set to %s", colorStr.c_str());
        } else {
            Logger::error("LineLayerNAPI", "Invalid color format: %s", colorStr.c_str());
        }
    } catch (const std::exception& e) {
        Logger::error("LineLayerNAPI", "setLineColor failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value LineLayerNAPI::SetLineWidth(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("LineLayerNAPI", "Failed to unwrap LineLayer object");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    args.RequireMinArgs(1);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    double width = args.GetDouble(0, "width");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        layerObj->layer->setLineWidth(mbgl::style::PropertyValue<float>(static_cast<float>(width)));
        Logger::debug("LineLayerNAPI", "LineWidth set to %f", width);
    } catch (const std::exception& e) {
        Logger::error("LineLayerNAPI", "setLineWidth failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value LineLayerNAPI::SetLineOpacity(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("LineLayerNAPI", "Failed to unwrap LineLayer object");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    args.RequireMinArgs(1);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    double opacity = args.GetDouble(0, "opacity");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        layerObj->layer->setLineOpacity(mbgl::style::PropertyValue<float>(static_cast<float>(opacity)));
        Logger::debug("LineLayerNAPI", "LineOpacity set to %f", opacity);
    } catch (const std::exception& e) {
        Logger::error("LineLayerNAPI", "setLineOpacity failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value LineLayerNAPI::SetLinePattern(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("LineLayerNAPI", "Failed to unwrap LineLayer object");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    args.RequireMinArgs(1);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    std::string pattern = args.GetString(0, "pattern");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        layerObj->layer->setLinePattern(mbgl::style::PropertyValue<mbgl::style::expression::Image>(
            mbgl::style::expression::Image(pattern)));
        Logger::debug("LineLayerNAPI", "LinePattern set to %s", pattern.c_str());
    } catch (const std::exception& e) {
        Logger::error("LineLayerNAPI", "setLinePattern failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value LineLayerNAPI::SetLineGapWidth(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("LineLayerNAPI", "Failed to unwrap LineLayer object");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    args.RequireMinArgs(1);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    double gapWidth = args.GetDouble(0, "gapWidth");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        layerObj->layer->setLineGapWidth(mbgl::style::PropertyValue<float>(static_cast<float>(gapWidth)));
        Logger::debug("LineLayerNAPI", "LineGapWidth set to %f", gapWidth);
    } catch (const std::exception& e) {
        Logger::error("LineLayerNAPI", "setLineGapWidth failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value LineLayerNAPI::SetLineDasharray(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("LineLayerNAPI", "Failed to unwrap LineLayer object");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    args.RequireMinArgs(1);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    napi_value arrayValue = args.GetArray(0, "dasharray");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        uint32_t length;
        napi_get_array_length(env, arrayValue, &length);
        
        std::vector<float> dasharray;
        for (uint32_t i = 0; i < length; i++) {
            napi_value elem;
            napi_get_element(env, arrayValue, i, &elem);
            double value;
            napi_get_value_double(env, elem, &value);
            dasharray.push_back(static_cast<float>(value));
        }
        
        layerObj->layer->setLineDasharray(mbgl::style::PropertyValue<std::vector<float>>(dasharray));
        Logger::debug("LineLayerNAPI", "LineDasharray set with %u elements", length);
    } catch (const std::exception& e) {
        Logger::error("LineLayerNAPI", "setLineDasharray failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value LineLayerNAPI::SetLineBlur(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("LineLayerNAPI", "Failed to unwrap LineLayer object");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    args.RequireMinArgs(1);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    double blur = args.GetDouble(0, "blur");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        layerObj->layer->setLineBlur(mbgl::style::PropertyValue<float>(static_cast<float>(blur)));
        Logger::debug("LineLayerNAPI", "LineBlur set to %f", blur);
    } catch (const std::exception& e) {
        Logger::error("LineLayerNAPI", "setLineBlur failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value LineLayerNAPI::SetLineOffset(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("LineLayerNAPI", "Failed to unwrap LineLayer object");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    args.RequireMinArgs(1);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    double offset = args.GetDouble(0, "offset");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        layerObj->layer->setLineOffset(mbgl::style::PropertyValue<float>(static_cast<float>(offset)));
        Logger::debug("LineLayerNAPI", "LineOffset set to %f", offset);
    } catch (const std::exception& e) {
        Logger::error("LineLayerNAPI", "setLineOffset failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value LineLayerNAPI::SetLineCap(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("LineLayerNAPI", "Failed to unwrap LineLayer object");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    args.RequireMinArgs(1);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    std::string capStr = args.GetString(0, "cap");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        mbgl::style::LineCapType capType = mbgl::style::LineCapType::Butt;
        if (capStr == "round") {
            capType = mbgl::style::LineCapType::Round;
        } else if (capStr == "square") {
            capType = mbgl::style::LineCapType::Square;
        }
        
        layerObj->layer->setLineCap(mbgl::style::PropertyValue<mbgl::style::LineCapType>(capType));
        Logger::debug("LineLayerNAPI", "LineCap set to %s", capStr.c_str());
    } catch (const std::exception& e) {
        Logger::error("LineLayerNAPI", "setLineCap failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value LineLayerNAPI::SetLineJoin(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        Logger::error("LineLayerNAPI", "Failed to unwrap LineLayer object");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    args.RequireMinArgs(1);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    std::string joinStr = args.GetString(0, "join");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        mbgl::style::LineJoinType joinType = mbgl::style::LineJoinType::Miter;
        if (joinStr == "round") {
            joinType = mbgl::style::LineJoinType::Round;
        } else if (joinStr == "bevel") {
            joinType = mbgl::style::LineJoinType::Bevel;
        }
        
        layerObj->layer->setLineJoin(mbgl::style::PropertyValue<mbgl::style::LineJoinType>(joinType));
        Logger::debug("LineLayerNAPI", "LineJoin set to %s", joinStr.c_str());
    } catch (const std::exception& e) {
        Logger::error("LineLayerNAPI", "setLineJoin failed: %s", e.what());
    }
    
    return thisVar;  // Return this for chaining
}

napi_value LineLayerNAPI::GetLineColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    const auto& value = layerObj->layer->getLineColor();
    if (value.isConstant()) {
        const auto& color = value.asConstant();
        std::string colorStr = color.stringify();
        napi_value result;
        napi_create_string_utf8(env, colorStr.c_str(), NAPI_AUTO_LENGTH, &result);
        return result;
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value LineLayerNAPI::GetLineWidth(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    const auto& value = layerObj->layer->getLineWidth();
    if (value.isConstant()) {
        napi_value result;
        napi_create_double(env, static_cast<double>(value.asConstant()), &result);
        return result;
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value LineLayerNAPI::GetLineOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    const auto& value = layerObj->layer->getLineOpacity();
    if (value.isConstant()) {
        napi_value result;
        napi_create_double(env, static_cast<double>(value.asConstant()), &result);
        return result;
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value LineLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    LineLayerNAPI* layerObj;
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    const std::string& id = layerObj->layer->getID();
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
    napi_status status = napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    if (status != napi_ok || !layerObj) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    const std::string& sourceId = layerObj->layer->getSourceID();
    napi_value result;
    napi_create_string_utf8(env, sourceId.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

} // namespace harmony
} // namespace mbgl
