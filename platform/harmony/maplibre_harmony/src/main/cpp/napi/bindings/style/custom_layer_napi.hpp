#pragma once

#include <napi/native_api.h>
#include <mbgl/style/layers/custom_layer.hpp>
#include <memory>
#include <string>

namespace mbgl {
namespace harmony {

// 前向声明
class ExampleCustomLayerHost;

/**
 * CustomLayerNAPI - NAPI wrapper for CustomLayer
 * 
 * This class wraps a CustomLayer object and exposes it to ETS/TypeScript via NAPI.
 * It manages the layer's state and properties in C++ layer.
 */
class CustomLayerNAPI {
public:
    // NAPI registration
    static napi_value Init(napi_env env, napi_value exports);
    
    // Constructor callback
    static napi_value New(napi_env env, napi_callback_info info);
    
    // Destructor callback
    static void Destructor(napi_env env, void* nativeObject, void* hint);
    
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
    
    // Custom layer specific methods
    static napi_value SetColor(napi_env env, napi_callback_info info);
    static napi_value GetColor(napi_env env, napi_callback_info info);
    
    // Internal methods for Style API
    std::string getId() const { return layerId; }
    
    // Release layer ownership (for Style.addLayer)
    std::unique_ptr<mbgl::style::Layer> releaseLayer() {
        if (!layer) {
            throw std::runtime_error("Layer already added to style");
        }
        return std::move(layer);
    }
    
    // Get native layer pointer (for property access after adding)
    mbgl::style::CustomLayer* getLayer() { 
        if (!layer && weakLayer) {
            return static_cast<mbgl::style::CustomLayer*>(weakLayer.get());
        }
        return layer.get(); 
    }
    
    // Attach to style after adding (creates WeakPtr)
    void attachToStyle(mbgl::style::CustomLayer* layerPtr) {
        if (layerPtr) {
            weakLayer = layerPtr->makeWeakPtr();
        }
    }

private:
    explicit CustomLayerNAPI(const std::string& layerId, 
                            std::unique_ptr<mbgl::style::CustomLayer> layer,
                            ExampleCustomLayerHost* host);
    ~CustomLayerNAPI();
    
    static napi_ref constructor;
    std::string layerId;
    std::unique_ptr<mbgl::style::CustomLayer> layer;
    mapbox::base::WeakPtr<mbgl::style::Layer> weakLayer;
    ExampleCustomLayerHost* host;  // 保持对 host 的引用以便调用方法（由 CustomLayer 管理生命周期）
};

} // namespace harmony
} // namespace mbgl

