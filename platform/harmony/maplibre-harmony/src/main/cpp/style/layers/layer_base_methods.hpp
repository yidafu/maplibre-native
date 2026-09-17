#pragma once

#include "../napi_value_wrapper.hpp"
#include "napi/core/napi_args.hpp"
#include "style/filter_conversion.hpp"
#include "utils/logger.h"

#include <mbgl/style/layer.hpp>
#include <napi/native_api.h>
#include <string>

namespace mbgl {
namespace harmony {

using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;

/**
 * Common Layer Base Methods
 * 
 * Provides implementation for setProperty and setProperties methods
 * that work with all layer types through the mbgl::style::Layer base class.
 */

/**
 * Set a single property on a layer
 * 
 * @param env NAPI environment
 * @param layer Layer instance (can be any concrete layer type)
 * @param propertyName Property name (e.g., "fill-color", "line-width")
 * @param value Property value (constant or expression)
 * @return true if property was set successfully
 */
template <typename LayerT>
bool SetLayerProperty(napi_env env, LayerT* layer, const std::string& propertyName, napi_value value) {
    if (!layer) {
        Logger::error("LayerBaseMethods", "Layer pointer is null");
        return false;
    }
    
    try {
        // Create NapiValue wrapper for conversion
        NapiValue napiValue(env, value);
        
        // Use Layer::setProperty which handles all property types
        auto error = layer->setProperty(propertyName, napiValue);
        
        if (error) {
            Logger::error("LayerBaseMethods", 
                         "Failed to set property '%s': %s", 
                         propertyName.c_str(), 
                         error->message.c_str());
            return false;
        }
        
        Logger::info("LayerBaseMethods", "✅ Property '%s' set successfully", propertyName.c_str());
        return true;
    } catch (const std::exception& e) {
        Logger::error("LayerBaseMethods", 
                     "Exception setting property '%s': %s", 
                     propertyName.c_str(), 
                     e.what());
        return false;
    }
}

/**
 * NAPI method: setProperty(propertyName: string, value: any)
 * 
 * Generic implementation that can be used by all layer types.
 * 
 * Usage in layer NAPI class:
 * ```cpp
 * napi_value FillLayerNAPI::SetProperty(napi_env env, napi_callback_info info) {
 *     return SetPropertyImpl<FillLayerNAPI, mbgl::style::FillLayer>(env, info);
 * }
 * ```
 */
template <typename NAPIClass, typename LayerT>
napi_value SetPropertyImpl(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Get 'this' object
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    auto* obj = NapiArgs::Unwrap<NAPIClass>(env, thisVar);

    if (!obj) {
        Logger::error("LayerBaseMethods", "Failed to unwrap layer object");
        return nullptr;
    }

    // Get layer instance
    auto layer = obj->getLayer();
    if (!layer) {
        Logger::error("LayerBaseMethods", "Layer instance is null");
        return nullptr;
    }

    // Require 2 arguments: propertyName and value
    args.RequireMinArgs(2);
    if (args.HasError()) {
        return nullptr;
    }
    
    std::string propertyName = args.GetString(0, "propertyName");
    napi_value value = args.Get(1);
    if (args.HasError()) {
        return nullptr;
    }
    
    // Set the property
    bool success = SetLayerProperty(env, layer, propertyName, value);
    
    // Return 'this' for method chaining
    if (success) {
        return thisVar;
    } else {
        return nullptr;
    }
}

/**
 * NAPI method: setProperties(properties: Record<string, any>)
 * 
 * Sets multiple properties at once from an object.
 * 
 * Usage in layer NAPI class:
 * ```cpp
 * napi_value FillLayerNAPI::SetProperties(napi_env env, napi_callback_info info) {
 *     return SetPropertiesImpl<FillLayerNAPI, mbgl::style::FillLayer>(env, info);
 * }
 * ```
 */
template <typename NAPIClass, typename LayerT>
napi_value SetPropertiesImpl(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Get 'this' object
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    auto* obj = NapiArgs::Unwrap<NAPIClass>(env, thisVar);

    if (!obj) {
        Logger::error("LayerBaseMethods", "Failed to unwrap layer object");
        return nullptr;
    }

    // Get layer instance
    auto layer = obj->getLayer();
    if (!layer) {
        Logger::error("LayerBaseMethods", "Layer instance is null");
        return nullptr;
    }

    // Require 1 argument: properties object
    args.RequireMinArgs(1);
    if (args.HasError()) {
        return nullptr;
    }
    
    napi_value propertiesObj = args.Get(0);
    
    // Check if argument is an object
    napi_valuetype valueType;
    napi_typeof(env, propertiesObj, &valueType);
    if (valueType != napi_object) {
        Logger::error("LayerBaseMethods", "Argument must be an object");
        return nullptr;
    }
    
    // Get property names
    napi_value propertyNames;
    napi_get_property_names(env, propertiesObj, &propertyNames);
    
    uint32_t propertyCount;
    napi_get_array_length(env, propertyNames, &propertyCount);
    
    Logger::info("LayerBaseMethods", "Setting %u properties", propertyCount);
    
    // Iterate through properties
    int successCount = 0;
    for (uint32_t i = 0; i < propertyCount; i++) {
        napi_value nameValue;
        napi_get_element(env, propertyNames, i, &nameValue);
        
        // Get property name as string
        size_t nameLength;
        napi_get_value_string_utf8(env, nameValue, nullptr, 0, &nameLength);
        std::string propertyName(nameLength, '\0');
        napi_get_value_string_utf8(env, nameValue, &propertyName[0], nameLength + 1, nullptr);
        
        // Get property value
        napi_value propertyValue;
        napi_get_property(env, propertiesObj, nameValue, &propertyValue);
        
        // Set the property
        if (SetLayerProperty(env, layer, propertyName, propertyValue)) {
            successCount++;
        }
    }
    
    Logger::info("LayerBaseMethods", "Successfully set %d/%u properties", successCount, propertyCount);
    
    // Return 'this' for method chaining
    return thisVar;
}


// ============================================================================
// Shared base-surface callbacks (id / type / source / visibility / zoom /
// filter). Every layer NAPI class keeps its static napi callback declaration
// and forwards to these templates; NAPI must expose `getLayer()` returning
// its concrete mbgl layer pointer (implicitly convertible to
// mbgl::style::Layer*, which owns the whole shared surface).
//
// Canonical guard semantics (previously duplicated with formatting drift in
// 11 files, normalized here):
// - getters return null / 0.0 / "" when `this` is not a live wrapper;
// - setters return `this` unchanged.
// ============================================================================

template <typename NAPI>
inline napi_value LayerGetId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<NAPI>(env, thisVar);
    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    std::string layerId = layerObj->getLayer()->getID();
    napi_value result;
    napi_create_string_utf8(env, layerId.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

inline napi_value LayerGetType(napi_env env, const char* type) {
    napi_value result;
    napi_create_string_utf8(env, type, NAPI_AUTO_LENGTH, &result);
    return result;
}

template <typename NAPI>
inline napi_value LayerGetSourceId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<NAPI>(env, thisVar);
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

template <typename NAPI>
inline napi_value LayerSetVisibility(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<NAPI>(env, thisVar);
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

template <typename NAPI>
inline napi_value LayerGetVisibility(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<NAPI>(env, thisVar);
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

template <typename NAPI>
inline napi_value LayerSetMinZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<NAPI>(env, thisVar);
    auto* layer = layerObj ? layerObj->getLayer() : nullptr;
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

template <typename NAPI>
inline napi_value LayerGetMinZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<NAPI>(env, thisVar);
    auto* layer = layerObj ? layerObj->getLayer() : nullptr;
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

template <typename NAPI>
inline napi_value LayerSetMaxZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<NAPI>(env, thisVar);
    auto* layer = layerObj ? layerObj->getLayer() : nullptr;
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

template <typename NAPI>
inline napi_value LayerGetMaxZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<NAPI>(env, thisVar);
    auto* layer = layerObj ? layerObj->getLayer() : nullptr;
    if (!layer) {
        napi_value result;
        napi_create_double(env, 0.0, &result);
        return result;
    }

    float maxZoom = layer->getMaxZoom();
    napi_value result;
    napi_create_double(env, maxZoom, &result);
    return result;
}

template <typename NAPI>
inline napi_value LayerSetSourceLayer(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<NAPI>(env, thisVar);
    auto* layer = layerObj ? layerObj->getLayer() : nullptr;
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

template <typename NAPI>
inline napi_value LayerGetSourceLayer(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<NAPI>(env, thisVar);
    auto* layer = layerObj ? layerObj->getLayer() : nullptr;
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

template <typename NAPI>
inline napi_value LayerSetFilter(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<NAPI>(env, thisVar);
    auto* layer = layerObj ? layerObj->getLayer() : nullptr;
    if (!layer || argc < 1) {
        return thisVar;
    }

    // Convert NAPI array to Filter
    auto filter = napiArrayToFilter(env, argv[0]);
    if (filter) {
        layer->setFilter(*filter);
    }

    return thisVar;
}

template <typename NAPI>
inline napi_value LayerGetFilter(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    auto* layerObj = NapiArgs::Unwrap<NAPI>(env, thisVar);
    auto* layer = layerObj ? layerObj->getLayer() : nullptr;
    if (!layer) {
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }

    // Get filter and convert to NAPI array
    const auto& filter = layer->getFilter();
    return filterToNapiArray(env, filter);
}

} // namespace harmony
} // namespace mbgl

