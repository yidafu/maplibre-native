#pragma once

#include <napi/native_api.h>
#include <mbgl/style/layer.hpp>
#include <mbgl/style/source.hpp>
#include <string>

namespace mbgl {
namespace harmony {

/**
 * LayerSourceFactory - Helper class to create NAPI wrappers for layers and sources
 * 
 * This is a simplified version compared to Android's LayerManager.
 * It creates the appropriate NAPI wrapper based on the layer/source type.
 */
class LayerSourceFactory {
public:
    /**
     * Create a NAPI wrapper for a layer based on its type
     * Returns a NAPI object representing the layer, or undefined if type is not supported
     */
    static napi_value createLayerWrapper(napi_env env, mbgl::style::Layer* layer);
    
    /**
     * Create a NAPI wrapper for a source based on its type
     * Returns a NAPI object representing the source, or undefined if type is not supported
     */
    static napi_value createSourceWrapper(napi_env env, mbgl::style::Source* source);
    
private:
    LayerSourceFactory() = delete;
};

} // namespace harmony
} // namespace mbgl

