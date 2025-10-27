#pragma once

#include <napi/native_api.h>
#include <mbgl/style/layers/fill_layer.hpp>
#include <memory>
#include <string>

namespace mbgl {
namespace harmony {

/**
 * FillLayerNAPI - NAPI wrapper for FillLayer
 * 
 * This class wraps a FillLayer object and exposes it to ETS/TypeScript via NAPI.
 * It manages the layer's state and properties in C++ layer.
 */
class FillLayerNAPI {
public:
    // NAPI registration
    static napi_value Init(napi_env env, napi_value exports);
    
    // Constructor callback
    static napi_value New(napi_env env, napi_callback_info info);
    
    // Destructor callback
    static void Destructor(napi_env env, void* nativeObject, void* hint);
    
    // Property setter methods
    static napi_value SetFillColor(napi_env env, napi_callback_info info);
    static napi_value SetFillOpacity(napi_env env, napi_callback_info info);
    static napi_value SetFillOutlineColor(napi_env env, napi_callback_info info);
    static napi_value SetFillPattern(napi_env env, napi_callback_info info);
    static napi_value SetFillAntialias(napi_env env, napi_callback_info info);
    static napi_value SetFillTranslate(napi_env env, napi_callback_info info);
    
    // Getter methods
    static napi_value GetFillColor(napi_env env, napi_callback_info info);
    static napi_value GetFillOpacity(napi_env env, napi_callback_info info);
    
    // Layer base methods
    static napi_value GetId(napi_env env, napi_callback_info info);
    static napi_value GetType(napi_env env, napi_callback_info info);
    static napi_value GetSourceId(napi_env env, napi_callback_info info);
    
    // Visibility control
    static napi_value SetVisibility(napi_env env, napi_callback_info info);
    static napi_value GetVisibility(napi_env env, napi_callback_info info);
    
    // Zoom range control
    static napi_value SetMinZoom(napi_env env, napi_callback_info info);
    static napi_value GetMinZoom(napi_env env, napi_callback_info info);
    static napi_value SetMaxZoom(napi_env env, napi_callback_info info);
    static napi_value GetMaxZoom(napi_env env, napi_callback_info info);
    
    // Source layer
    static napi_value SetSourceLayer(napi_env env, napi_callback_info info);
    static napi_value GetSourceLayer(napi_env env, napi_callback_info info);
    
    // Filter
    static napi_value SetFilter(napi_env env, napi_callback_info info);
    static napi_value GetFilter(napi_env env, napi_callback_info info);
    
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
    mbgl::style::FillLayer* getLayer() { 
        if (!layer && weakLayer) {
            return static_cast<mbgl::style::FillLayer*>(weakLayer.get());
        }
        return layer.get(); 
    }
    
    // Attach to style after adding (creates WeakPtr)
    void attachToStyle(mbgl::style::FillLayer* layerPtr) {
        if (layerPtr) {
            weakLayer = layerPtr->makeWeakPtr();
        }
    }

private:
    explicit FillLayerNAPI(const std::string& layerId, const std::string& sourceId);
    ~FillLayerNAPI();
    
    static napi_ref constructor;
    std::unique_ptr<mbgl::style::FillLayer> layer;
    mapbox::base::WeakPtr<mbgl::style::Layer> weakLayer;
};

} // namespace harmony
} // namespace mbgl
