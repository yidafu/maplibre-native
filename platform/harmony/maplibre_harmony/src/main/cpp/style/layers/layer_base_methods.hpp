#pragma once

#include "../napi_value_wrapper.hpp"
#include "napi/core/napi_args.hpp"
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

} // namespace harmony
} // namespace mbgl

