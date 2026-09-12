#pragma once

#include <napi/native_api.h>
#include <mbgl/style/layers/background_layer.hpp>
#include <memory>
#include <string>

namespace mbgl {
namespace harmony {

/**
 * BackgroundLayerNAPI - NAPI wrapper for BackgroundLayer
 * 
 * This class wraps a BackgroundLayer object and exposes it to ETS/TypeScript via NAPI.
 * It manages the layer's state and properties in C++ layer.
 */
class BackgroundLayerNAPI {
public:
    // NAPI registration
    static napi_value Init(napi_env env, napi_value exports);
    
    // Constructor callback
    static napi_value New(napi_env env, napi_callback_info info);
    
    // Construct from an existing layer (uses WeakPtr, does not take ownership)
    BackgroundLayerNAPI(mbgl::style::BackgroundLayer* layerPtr);

    // Create a NAPI instance from an existing native object
    static napi_value CreateInstance(napi_env env, mbgl::style::BackgroundLayer* layerPtr);
    
    // Destructor callback
    static void Destructor(napi_env env, void* nativeObject, void* hint);
    
    // Property setter methods
    static napi_value SetBackgroundColor(napi_env env, napi_callback_info info);
    static napi_value SetBackgroundOpacity(napi_env env, napi_callback_info info);
    static napi_value SetBackgroundPattern(napi_env env, napi_callback_info info);
    
    // Getter methods
    static napi_value GetBackgroundColor(napi_env env, napi_callback_info info);
    static napi_value GetBackgroundOpacity(napi_env env, napi_callback_info info);
    
    // Layer base methods
    static napi_value GetId(napi_env env, napi_callback_info info);
    static napi_value GetType(napi_env env, napi_callback_info info);
    
    // Visibility control
    static napi_value SetVisibility(napi_env env, napi_callback_info info);
    static napi_value GetVisibility(napi_env env, napi_callback_info info);
    
    // Zoom range control
    static napi_value SetMinZoom(napi_env env, napi_callback_info info);
    static napi_value GetMinZoom(napi_env env, napi_callback_info info);
    static napi_value SetMaxZoom(napi_env env, napi_callback_info info);
    static napi_value GetMaxZoom(napi_env env, napi_callback_info info);
    
    // Generic property methods (Android-compatible API)
    static napi_value SetProperty(napi_env env, napi_callback_info info);
    static napi_value SetProperties(napi_env env, napi_callback_info info);
    
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
    mbgl::style::BackgroundLayer* getLayer() { 
        if (!layer && weakLayer) {
            return static_cast<mbgl::style::BackgroundLayer*>(weakLayer.get());
        }
        return layer.get(); 
    }
    
    // Attach to style after adding (creates WeakPtr)
    void attachToStyle(mbgl::style::BackgroundLayer* layerPtr) {
        if (layerPtr) {
            weakLayer = layerPtr->makeWeakPtr();
        }
    }

private:
    explicit BackgroundLayerNAPI(const std::string& layerId);
    ~BackgroundLayerNAPI();
    
    static napi_ref constructor;
    static napi_env constructorEnv;
    std::unique_ptr<mbgl::style::BackgroundLayer> layer;
    mapbox::base::WeakPtr<mbgl::style::Layer> weakLayer;
};

} // namespace harmony
} // namespace mbgl

