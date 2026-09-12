#include "background_layer_harmony.hpp"
#include "napi/core/napi_constructor_ref.hpp"
#include "layer_base_methods.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "style/layers/layer_property_utils.hpp"
#include <mbgl/style/layers/background_layer.hpp>
#include <mbgl/style/property_value.hpp>
#include <mbgl/style/expression/image.hpp>
#include <mbgl/util/color.hpp>
#include "napi/core/napi_wrap_instance.hpp"

namespace mbgl {
namespace harmony {

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

// Static member initialization
napi_ref BackgroundLayerNAPI::constructor = nullptr;
napi_env BackgroundLayerNAPI::constructorEnv = nullptr;

BackgroundLayerNAPI::BackgroundLayerNAPI(const std::string& layerId)
    : layer(std::make_unique<mbgl::style::BackgroundLayer>(layerId)) {
}

BackgroundLayerNAPI::BackgroundLayerNAPI(mbgl::style::BackgroundLayer* layerPtr) {
    if (layerPtr) {
        weakLayer = layerPtr->makeWeakPtr();
        Logger::info("BackgroundLayerNAPI", "BackgroundLayer created from existing layer (WeakPtr)");
    }}

BackgroundLayerNAPI::~BackgroundLayerNAPI() {
    // Reset weakLayer before layer is destroyed to avoid accessing invalidated WeakPtrFactory
}

void BackgroundLayerNAPI::Destructor(napi_env env, void* nativeObject, void* hint) {
    BackgroundLayerNAPI* obj = static_cast<BackgroundLayerNAPI*>(nativeObject);
    delete obj;
}

napi_value BackgroundLayerNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("BackgroundLayerNAPI", "Initializing BackgroundLayer NAPI class");
    
    napi_property_descriptor properties[] = {
        // Setter methods (support Expression)
        { "setBackgroundColor", nullptr, SetBackgroundColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setBackgroundOpacity", nullptr, SetBackgroundOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setBackgroundPattern", nullptr, SetBackgroundPattern, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Getter methods (return constant or Expression)
        { "getBackgroundColor", nullptr, GetBackgroundColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getBackgroundOpacity", nullptr, GetBackgroundOpacity, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Layer base methods
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getType", nullptr, GetType, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Visibility control
        { "setVisibility", nullptr, SetVisibility, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getVisibility", nullptr, GetVisibility, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Zoom range control
        { "setMinZoom", nullptr, SetMinZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getMinZoom", nullptr, GetMinZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setMaxZoom", nullptr, SetMaxZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getMaxZoom", nullptr, GetMaxZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // Generic property methods (Android-compatible API)
        { "setProperty", nullptr, SetProperty, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setProperties", nullptr, SetProperties, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "BackgroundLayer", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("BackgroundLayerNAPI", "Failed to define BackgroundLayer class");
        return nullptr;
    }
    
    status = mbgl::harmony::RefreshConstructorRef(env, cons, constructor, constructorEnv);
    if (status != napi_ok) {
        Logger::error("BackgroundLayerNAPI", "Failed to create reference to BackgroundLayer constructor");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "BackgroundLayer", cons);
    if (status != napi_ok) {
        Logger::error("BackgroundLayerNAPI", "Failed to export BackgroundLayer class");
        return nullptr;
    }
    
    Logger::info("BackgroundLayerNAPI", "BackgroundLayer NAPI class registered successfully");
    return exports;
}

napi_value BackgroundLayerNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    args.RequireMinArgs(1);
    if (args.HasError()) {
        return nullptr;
    }
    
    std::string layerId = args.GetString(0, "layerId");
    if (args.HasError()) {
        return nullptr;
    }
    
    BackgroundLayerNAPI* layerObj = new BackgroundLayerNAPI(layerId);
    
    napi_status status = napi_wrap(env, thisVar, layerObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete layerObj;
        Logger::error("BackgroundLayerNAPI", "Failed to wrap BackgroundLayer object");
        return nullptr;
    }
    

    
    // Add the _TYPE_ property for ETS type detection
    napi_value typeValue;
    napi_create_string_utf8(env, "BackgroundLayer", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, thisVar, "_TYPE_", typeValue);
    return thisVar;
}

napi_value BackgroundLayerNAPI::CreateInstance(napi_env env, mbgl::style::BackgroundLayer* layerPtr) {
    return WrapExistingInstance(env, constructor, Destructor, "BackgroundLayer",
                                layerPtr ? new BackgroundLayerNAPI(layerPtr) : nullptr);
}


// ============================================================================
// Paint Property Setters (Expression supported)
// ============================================================================

napi_value BackgroundLayerNAPI::SetBackgroundColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<BackgroundLayerNAPI>(env, thisVar);
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::BackgroundLayer, mbgl::Color>(
        env,
        layerObj->getLayer(),
        argv[0],
        "background-color",
        &mbgl::style::BackgroundLayer::setBackgroundColor
    );
    
    return thisVar;
}

napi_value BackgroundLayerNAPI::SetBackgroundOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<BackgroundLayerNAPI>(env, thisVar);
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::BackgroundLayer, float>(
        env,
        layerObj->getLayer(),
        argv[0],
        "background-opacity",
        &mbgl::style::BackgroundLayer::setBackgroundOpacity
    );
    
    return thisVar;
}

napi_value BackgroundLayerNAPI::SetBackgroundPattern(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<BackgroundLayerNAPI>(env, thisVar);
    
    if (!layerObj || !layerObj->getLayer() || argc < 1) {
        return thisVar;
    }
    
    mbgl::harmony::setPaintProperty<mbgl::style::BackgroundLayer, mbgl::style::expression::Image>(
        env,
        layerObj->getLayer(),
        argv[0],
        "background-pattern",
        &mbgl::style::BackgroundLayer::setBackgroundPattern
    );
    
    return thisVar;
}

// ============================================================================
// Property Getters (return constants or Expressions)
// ============================================================================

napi_value BackgroundLayerNAPI::GetBackgroundColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<BackgroundLayerNAPI>(env, thisVar);
    
    if (!layerObj) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    mbgl::style::BackgroundLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    return mbgl::harmony::getProperty<mbgl::style::BackgroundLayer, mbgl::Color>(
        env,
        layer,
        &mbgl::style::BackgroundLayer::getBackgroundColor
    );
}

napi_value BackgroundLayerNAPI::GetBackgroundOpacity(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    auto* layerObj = NapiArgs::Unwrap<BackgroundLayerNAPI>(env, thisVar);
    
    if (!layerObj) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }
    
    mbgl::style::BackgroundLayer* layer = layerObj->getLayer();
    if (!layer) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    return mbgl::harmony::getProperty<mbgl::style::BackgroundLayer, float>(
        env,
        layer,
        &mbgl::style::BackgroundLayer::getBackgroundOpacity
    );
}

// ============================================================================
// Base Layer Methods
// ============================================================================

napi_value BackgroundLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    return LayerGetId<BackgroundLayerNAPI>(env, info);
}

napi_value BackgroundLayerNAPI::GetType(napi_env env, napi_callback_info info) {
    return LayerGetType(env, "background");
}

// ============================================================================
// Visibility
// ============================================================================

napi_value BackgroundLayerNAPI::SetVisibility(napi_env env, napi_callback_info info) {
    return LayerSetVisibility<BackgroundLayerNAPI>(env, info);
}

napi_value BackgroundLayerNAPI::GetVisibility(napi_env env, napi_callback_info info) {
    return LayerGetVisibility<BackgroundLayerNAPI>(env, info);
}

// ============================================================================
// Zoom Range
// ============================================================================

napi_value BackgroundLayerNAPI::SetMinZoom(napi_env env, napi_callback_info info) {
    return LayerSetMinZoom<BackgroundLayerNAPI>(env, info);
}

napi_value BackgroundLayerNAPI::GetMinZoom(napi_env env, napi_callback_info info) {
    return LayerGetMinZoom<BackgroundLayerNAPI>(env, info);
}

napi_value BackgroundLayerNAPI::SetMaxZoom(napi_env env, napi_callback_info info) {
    return LayerSetMaxZoom<BackgroundLayerNAPI>(env, info);
}

napi_value BackgroundLayerNAPI::GetMaxZoom(napi_env env, napi_callback_info info) {
    return LayerGetMaxZoom<BackgroundLayerNAPI>(env, info);
}

// ==================== Generic Property Methods ====================

napi_value BackgroundLayerNAPI::SetProperty(napi_env env, napi_callback_info info) {
    return SetPropertyImpl<BackgroundLayerNAPI, mbgl::style::BackgroundLayer>(env, info);
}

napi_value BackgroundLayerNAPI::SetProperties(napi_env env, napi_callback_info info) {
    return SetPropertiesImpl<BackgroundLayerNAPI, mbgl::style::BackgroundLayer>(env, info);
}

} // namespace harmony
} // namespace mbgl
