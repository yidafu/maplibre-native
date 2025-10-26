#pragma once

#include <napi/native_api.h>
#include <mbgl/style/layers/raster_layer.hpp>
#include <memory>
#include <string>

namespace mbgl {
namespace harmony {

/**
 * RasterLayerNAPI - NAPI wrapper for RasterLayer
 */
class RasterLayerNAPI {
public:
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value New(napi_env env, napi_callback_info info);
    static void Destructor(napi_env env, void* nativeObject, void* hint);
    
    // Property setters
    static napi_value SetRasterOpacity(napi_env env, napi_callback_info info);
    static napi_value SetRasterHueRotate(napi_env env, napi_callback_info info);
    static napi_value SetRasterBrightnessMin(napi_env env, napi_callback_info info);
    static napi_value SetRasterBrightnessMax(napi_env env, napi_callback_info info);
    static napi_value SetRasterSaturation(napi_env env, napi_callback_info info);
    static napi_value SetRasterContrast(napi_env env, napi_callback_info info);
    
    // Layer base methods
    static napi_value GetId(napi_env env, napi_callback_info info);
    static napi_value GetType(napi_env env, napi_callback_info info);
    static napi_value GetSourceId(napi_env env, napi_callback_info info);
    
    // Internal methods for Style API
    std::string getId() const { return layer ? layer->getID() : ""; }
    
    // Release layer ownership (for Style.addLayer)
    std::unique_ptr<mbgl::style::Layer> releaseLayer() {
        if (!layer) {
            throw std::runtime_error("Layer already added to style");
        }
        return std::move(layer);
    }
    
    // Get native layer pointer (for property access after adding)
    mbgl::style::RasterLayer* getLayer() { return layer.get(); }

private:
    explicit RasterLayerNAPI(const std::string& layerId, const std::string& sourceId);
    ~RasterLayerNAPI();
    
    static napi_ref constructor;
    std::unique_ptr<mbgl::style::RasterLayer> layer;
};

} // namespace harmony
} // namespace mbgl

