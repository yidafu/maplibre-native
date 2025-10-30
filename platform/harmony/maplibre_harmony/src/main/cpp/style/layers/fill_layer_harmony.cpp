#include "fill_layer_harmony.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "style/filter_conversion.hpp"
#include "style/layers/layer_property_utils.hpp"
#include <mbgl/style/layers/fill_layer.hpp>
#include <mbgl/style/property_value.hpp>
#include <mbgl/style/expression/image.hpp>
#include <mbgl/style/types.hpp>
#include <mbgl/util/color.hpp>

namespace mbgl {
namespace harmony {

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

// Static member initialization
napi_ref FillLayerNAPI::constructor = nullptr;

FillLayerNAPI::FillLayerNAPI(const std::string& layerId, const std::string& sourceId)
    : layer(std::make_unique<mbgl::style::FillLayer>(layerId, sourceId)) {
}

FillLayerNAPI::~FillLayerNAPI() {
}

void FillLayerNAPI::Destructor(napi_env env, void* nativeObject, void* hint) {
    FillLayerNAPI* obj = static_cast<FillLayerNAPI*>(nativeObject);
    delete obj;
}

napi_value FillLayerNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("FillLayerNAPI", "Initializing FillLayer NAPI class");
    
    napi_property_descriptor properties[] = {
        // Setter methods (support Expression)
        { "setFillColor", nullptr, SetFillColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillOpacity", nullptr, SetFillOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillOutlineColor", nullptr, SetFillOutlineColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillPattern", nullptr, SetFillPattern, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillAntialias", nullptr, SetFillAntialias, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillTranslate", nullptr, SetFillTranslate, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Getter methods (return constant or Expression)
        { "getFillColor", nullptr, GetFillColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getFillOpacity", nullptr, GetFillOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Layer base methods
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getType", nullptr, GetType, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getSourceId", nullptr, GetSourceId, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Visibility control
        { "setVisibility", nullptr, SetVisibility, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getVisibility", nullptr, GetVisibility, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Zoom range control
        { "setMinZoom", nullptr, SetMinZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getMinZoom", nullptr, GetMinZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setMaxZoom", nullptr, SetMaxZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getMaxZoom", nullptr, GetMaxZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Source layer
        { "setSourceLayer", nullptr, SetSourceLayer, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getSourceLayer", nullptr, GetSourceLayer, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Filter
        { "setFilter", nullptr, SetFilter, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getFilter", nullptr, GetFilter, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // New properties
        { "setFillTranslateAnchor", nullptr, SetFillTranslateAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getFillTranslateAnchor", nullptr, GetFillTranslateAnchor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFillSortKey", nullptr, SetFillSortKey, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getFillSortKey", nullptr, GetFillSortKey, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "FillLayer", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("FillLayerNAPI", "Failed to define FillLayer class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("FillLayerNAPI", "Failed to create reference to FillLayer constructor");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "FillLayer", cons);
    if (status != napi_ok) {
        Logger::error("FillLayerNAPI", "Failed to export FillLayer class");
        return nullptr;
    }
    
    Logger::info("FillLayerNAPI", "FillLayer NAPI class registered successfully");
    return exports;
}

napi_value FillLayerNAPI::New(napi_env env, napi_callback_info info) {
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
    
    // Create FillLayerNAPI instance
    FillLayerNAPI* layerObj = new FillLayerNAPI(layerId, sourceId);
    
    // Wrap native object
    napi_status status = napi_wrap(env, thisVar, layerObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete layerObj;
        Logger::error("FillLayerNAPI", "Failed to wrap FillLayer object");
        return nullptr;
    }
    
    return thisVar;
}

// ============================================================================
// Paint Property Setters (支持 Expression)
// ============================================================================

napi_value FillLayerNAPI::SetFillColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::FillLayer, mbgl::Color>(
        env,
        layerObj->layer.get(),
        argv[0],
        "fill-color",
        &mbgl::style::FillLayer::setFillColor
    );
    
    return thisVar;
}

napi_value FillLayerNAPI::SetFillOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::FillLayer, float>(
        env,
        layerObj->layer.get(),
        argv[0],
        "fill-opacity",
        &mbgl::style::FillLayer::setFillOpacity
    );
    
    return thisVar;
}

napi_value FillLayerNAPI::SetFillOutlineColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::FillLayer, mbgl::Color>(
        env,
        layerObj->layer.get(),
        argv[0],
        "fill-outline-color",
        &mbgl::style::FillLayer::setFillOutlineColor
    );
    
    return thisVar;
}

napi_value FillLayerNAPI::SetFillPattern(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::FillLayer, mbgl::style::expression::Image>(
        env,
        layerObj->layer.get(),
        argv[0],
        "fill-pattern",
        &mbgl::style::FillLayer::setFillPattern
    );
    
    return thisVar;
}

napi_value FillLayerNAPI::SetFillAntialias(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::FillLayer, bool>(
        env,
        layerObj->layer.get(),
        argv[0],
        "fill-antialias",
        &mbgl::style::FillLayer::setFillAntialias
    );
    
    return thisVar;
}

napi_value FillLayerNAPI::SetFillTranslate(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::FillLayer, std::array<float, 2>>(
        env,
        layerObj->layer.get(),
        argv[0],
        "fill-translate",
        &mbgl::style::FillLayer::setFillTranslate
    );
    
    return thisVar;
}

// ============================================================================
// Property Getters (返回常量或 Expression)
// ============================================================================

napi_value FillLayerNAPI::GetFillColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::FillLayer, mbgl::Color>(
        env,
        layerObj->layer.get(),
        &mbgl::style::FillLayer::getFillColor
    );
}

napi_value FillLayerNAPI::GetFillOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::FillLayer, float>(
        env,
        layerObj->layer.get(),
        &mbgl::style::FillLayer::getFillOpacity
    );
}

// ============================================================================
// Base Layer Methods
// ============================================================================

napi_value FillLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    std::string id = layerObj->layer->getID();
    napi_value result;
    napi_create_string_utf8(env, id.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value FillLayerNAPI::GetType(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_string_utf8(env, "fill", NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value FillLayerNAPI::GetSourceId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    std::string sourceId = layerObj->layer->getSourceID();
    napi_value result;
    napi_create_string_utf8(env, sourceId.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

// ============================================================================
// Visibility
// ============================================================================

napi_value FillLayerNAPI::SetVisibility(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        return thisVar;
    }
    
    args.RequireMinArgs(1);
    if (args.HasError()) {
        return thisVar;
    }
    
    std::string visibility = args.GetString(0, "visibility");
    if (visibility == "visible") {
        layerObj->layer->setVisibility(mbgl::style::VisibilityType::Visible);
    } else if (visibility == "none") {
        layerObj->layer->setVisibility(mbgl::style::VisibilityType::None);
    }
    
    return thisVar;
}

napi_value FillLayerNAPI::GetVisibility(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    auto visibility = layerObj->layer->getVisibility();
    const char* visStr = (visibility == mbgl::style::VisibilityType::Visible) ? "visible" : "none";
    
    napi_value result;
    napi_create_string_utf8(env, visStr, NAPI_AUTO_LENGTH, &result);
    return result;
}

// ============================================================================
// Zoom Range
// ============================================================================

napi_value FillLayerNAPI::SetMinZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        return thisVar;
    }
    
    args.RequireMinArgs(1);
    if (!args.HasError()) {
        float minZoom = static_cast<float>(args.GetDouble(0, "minZoom"));
        layerObj->layer->setMinZoom(minZoom);
    }
    
    return thisVar;
}

napi_value FillLayerNAPI::GetMinZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value result;
        napi_create_double(env, 0.0, &result);
        return result;
    }
    
    float minZoom = layerObj->layer->getMinZoom();
    napi_value result;
    napi_create_double(env, minZoom, &result);
    return result;
}

napi_value FillLayerNAPI::SetMaxZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        return thisVar;
    }
    
    args.RequireMinArgs(1);
    if (!args.HasError()) {
        float maxZoom = static_cast<float>(args.GetDouble(0, "maxZoom"));
        layerObj->layer->setMaxZoom(maxZoom);
    }
    
    return thisVar;
}

napi_value FillLayerNAPI::GetMaxZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value result;
        napi_create_double(env, 24.0, &result);
        return result;
    }
    
    float maxZoom = layerObj->layer->getMaxZoom();
    napi_value result;
    napi_create_double(env, maxZoom, &result);
    return result;
}

// ============================================================================
// Source Layer
// ============================================================================

napi_value FillLayerNAPI::SetSourceLayer(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        return thisVar;
    }
    
    args.RequireMinArgs(1);
    if (!args.HasError()) {
        std::string sourceLayer = args.GetString(0, "sourceLayer");
        layerObj->layer->setSourceLayer(sourceLayer);
    }
    
    return thisVar;
}

napi_value FillLayerNAPI::GetSourceLayer(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value result;
        napi_create_string_utf8(env, "", NAPI_AUTO_LENGTH, &result);
        return result;
    }
    
    std::string sourceLayer = layerObj->layer->getSourceLayer();
    napi_value result;
    napi_create_string_utf8(env, sourceLayer.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

// ============================================================================
// Filter
// ============================================================================

napi_value FillLayerNAPI::SetFilter(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) {
        return thisVar;
    }
    
    // Convert NAPI array to Filter
    auto filter = napiArrayToFilter(env, argv[0]);
    if (filter) {
        layerObj->layer->setFilter(*filter);
    }
    
    return thisVar;
}

napi_value FillLayerNAPI::GetFilter(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
    
    // Get filter and convert to NAPI array
    const auto& filter = layerObj->layer->getFilter();
    return filterToNapiArray(env, filter);
}

// ============================================================================
// New Properties
// ============================================================================

napi_value FillLayerNAPI::SetFillTranslateAnchor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setPaintProperty<mbgl::style::FillLayer, mbgl::style::TranslateAnchorType>(
        env, layerObj->layer.get(), argv[0], "fill-translate-anchor",
        &mbgl::style::FillLayer::setFillTranslateAnchor
    );
    return thisVar;
}

napi_value FillLayerNAPI::GetFillTranslateAnchor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::FillLayer, mbgl::style::TranslateAnchorType>(
        env, layerObj->layer.get(), &mbgl::style::FillLayer::getFillTranslateAnchor
    );
}

napi_value FillLayerNAPI::SetFillSortKey(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) return thisVar;
    
    mbgl::harmony::setLayoutProperty<mbgl::style::FillLayer, float>(
        env, layerObj->layer.get(), argv[0], "fill-sort-key",
        &mbgl::style::FillLayer::setFillSortKey
    );
    return thisVar;
}

napi_value FillLayerNAPI::GetFillSortKey(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    FillLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::FillLayer, float>(
        env, layerObj->layer.get(), &mbgl::style::FillLayer::getFillSortKey
    );
}

} // namespace harmony
} // namespace mbgl
