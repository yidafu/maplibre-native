#include "circle_layer_harmony.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "style/filter_conversion.hpp"
#include "style/layers/layer_property_utils.hpp"
#include <mbgl/style/layers/circle_layer.hpp>
#include <mbgl/style/property_value.hpp>
#include <mbgl/style/types.hpp>
#include <mbgl/util/color.hpp>

namespace mbgl {
namespace harmony {

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

// Static member initialization
napi_ref CircleLayerNAPI::constructor = nullptr;

CircleLayerNAPI::CircleLayerNAPI(const std::string& layerId, const std::string& sourceId)
    : layer(std::make_unique<mbgl::style::CircleLayer>(layerId, sourceId)) {
    Logger::debug("CircleLayerNAPI", "CircleLayer created: %s (source: %s)", layerId.c_str(), sourceId.c_str());
}

CircleLayerNAPI::~CircleLayerNAPI() {
    Logger::debug("CircleLayerNAPI", "CircleLayer destroyed");
}

void CircleLayerNAPI::Destructor(napi_env env, void* nativeObject, void* hint) {
    CircleLayerNAPI* obj = static_cast<CircleLayerNAPI*>(nativeObject);
    delete obj;
}

napi_value CircleLayerNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("CircleLayerNAPI", "Initializing CircleLayer NAPI class");
    
    napi_property_descriptor properties[] = {
        // Setter methods (support Expression)
        { "setCircleRadius", nullptr, SetCircleRadius, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCircleColor", nullptr, SetCircleColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCircleOpacity", nullptr, SetCircleOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCircleBlur", nullptr, SetCircleBlur, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCircleStrokeWidth", nullptr, SetCircleStrokeWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCircleStrokeColor", nullptr, SetCircleStrokeColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCircleStrokeOpacity", nullptr, SetCircleStrokeOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Getter methods (return constant or Expression)
        { "getCircleRadius", nullptr, GetCircleRadius, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getCircleColor", nullptr, GetCircleColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getCircleOpacity", nullptr, GetCircleOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        
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
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "CircleLayer", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("CircleLayerNAPI", "Failed to define CircleLayer class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("CircleLayerNAPI", "Failed to create reference to CircleLayer constructor");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "CircleLayer", cons);
    if (status != napi_ok) {
        Logger::error("CircleLayerNAPI", "Failed to export CircleLayer class");
        return nullptr;
    }
    
    Logger::info("CircleLayerNAPI", "CircleLayer NAPI class registered successfully");
    return exports;
}

napi_value CircleLayerNAPI::New(napi_env env, napi_callback_info info) {
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
    
    // Create CircleLayerNAPI instance
    CircleLayerNAPI* layerObj = new CircleLayerNAPI(layerId, sourceId);
    
    // Wrap native object
    napi_status status = napi_wrap(env, thisVar, layerObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete layerObj;
        Logger::error("CircleLayerNAPI", "Failed to wrap CircleLayer object");
        return nullptr;
    }
    
    return thisVar;
}

// ============================================================================
// Paint Property Setters (支持 Expression)
// ============================================================================

napi_value CircleLayerNAPI::SetCircleRadius(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::CircleLayer, float>(
        env,
        layerObj->layer.get(),
        argv[0],
        "circle-radius",
        &mbgl::style::CircleLayer::setCircleRadius
    );
    
    return thisVar;
}

napi_value CircleLayerNAPI::SetCircleColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::CircleLayer, mbgl::Color>(
        env,
        layerObj->layer.get(),
        argv[0],
        "circle-color",
        &mbgl::style::CircleLayer::setCircleColor
    );
    
    return thisVar;
}

napi_value CircleLayerNAPI::SetCircleOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::CircleLayer, float>(
        env,
        layerObj->layer.get(),
        argv[0],
        "circle-opacity",
        &mbgl::style::CircleLayer::setCircleOpacity
    );
    
    return thisVar;
}

napi_value CircleLayerNAPI::SetCircleBlur(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::CircleLayer, float>(
        env,
        layerObj->layer.get(),
        argv[0],
        "circle-blur",
        &mbgl::style::CircleLayer::setCircleBlur
    );
    
    return thisVar;
}

napi_value CircleLayerNAPI::SetCircleStrokeWidth(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::CircleLayer, float>(
        env,
        layerObj->layer.get(),
        argv[0],
        "circle-stroke-width",
        &mbgl::style::CircleLayer::setCircleStrokeWidth
    );
    
    return thisVar;
}

napi_value CircleLayerNAPI::SetCircleStrokeColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::CircleLayer, mbgl::Color>(
        env,
        layerObj->layer.get(),
        argv[0],
        "circle-stroke-color",
        &mbgl::style::CircleLayer::setCircleStrokeColor
    );
    
    return thisVar;
}

napi_value CircleLayerNAPI::SetCircleStrokeOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::CircleLayer, float>(
        env,
        layerObj->layer.get(),
        argv[0],
        "circle-stroke-opacity",
        &mbgl::style::CircleLayer::setCircleStrokeOpacity
    );
    
    return thisVar;
}

// ============================================================================
// Property Getters (返回常量或 Expression)
// ============================================================================

napi_value CircleLayerNAPI::GetCircleRadius(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::CircleLayer, float>(
        env,
        layerObj->layer.get(),
        &mbgl::style::CircleLayer::getCircleRadius
    );
}

napi_value CircleLayerNAPI::GetCircleColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::CircleLayer, mbgl::Color>(
        env,
        layerObj->layer.get(),
        &mbgl::style::CircleLayer::getCircleColor
    );
}

napi_value CircleLayerNAPI::GetCircleOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    return mbgl::harmony::getProperty<mbgl::style::CircleLayer, float>(
        env,
        layerObj->layer.get(),
        &mbgl::style::CircleLayer::getCircleOpacity
    );
}

// ============================================================================
// Base Layer Methods
// ============================================================================

napi_value CircleLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
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

napi_value CircleLayerNAPI::GetType(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_string_utf8(env, "circle", NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value CircleLayerNAPI::GetSourceId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
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

napi_value CircleLayerNAPI::SetVisibility(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
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

napi_value CircleLayerNAPI::GetVisibility(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
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

napi_value CircleLayerNAPI::SetMinZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
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

napi_value CircleLayerNAPI::GetMinZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
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

napi_value CircleLayerNAPI::SetMaxZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
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

napi_value CircleLayerNAPI::GetMaxZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
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

napi_value CircleLayerNAPI::SetSourceLayer(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
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

napi_value CircleLayerNAPI::GetSourceLayer(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
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

napi_value CircleLayerNAPI::SetFilter(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));
    
    if (!layerObj || !layerObj->layer || argc < 1) {
        return thisVar;
    }
    
    // Convert NAPI array to Filter
    auto filter = napiArrayToFilter(env, argv[0]);
    if (filter) {
        layerObj->layer->setFilter(*filter);
        Logger::debug("CircleLayerNAPI", "Filter set successfully");
    }
    
    return thisVar;
}

napi_value CircleLayerNAPI::GetFilter(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    CircleLayerNAPI* layerObj;
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

} // namespace harmony
} // namespace mbgl
