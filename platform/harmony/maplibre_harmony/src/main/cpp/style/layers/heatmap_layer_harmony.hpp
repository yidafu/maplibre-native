#pragma once

#include <napi/native_api.h>
#include <mbgl/style/layers/heatmap_layer.hpp>
#include <memory>
#include <string>

namespace mbgl {
namespace harmony {

/**
 * HeatmapLayerNAPI - NAPI wrapper for HeatmapLayer
 * 
 * This class wraps a HeatmapLayer object and exposes it to ETS/TypeScript via NAPI.
 */
class HeatmapLayerNAPI {
public:
    // NAPI registration
    static napi_value Init(napi_env env, napi_value exports);
    
    // Constructor callback
    static napi_value New(napi_env env, napi_callback_info info);
    // 从现有 Layer 创建（使用 WeakPtr，不拥有所有权）
    HeatmapLayerNAPI(mbgl::style::HeatmapLayer* layerPtr);

    // 从现有 native 对象创建 NAPI 实例
    static napi_value CreateInstance(napi_env env, mbgl::style::HeatmapLayer* layerPtr);

    
    // Destructor callback
    static void Destructor(napi_env env, void* nativeObject, void* hint);
    
    // Property setter methods
    static napi_value SetHeatmapRadius(napi_env env, napi_callback_info info);
    static napi_value SetHeatmapWeight(napi_env env, napi_callback_info info);
    static napi_value SetHeatmapIntensity(napi_env env, napi_callback_info info);
    static napi_value SetHeatmapColor(napi_env env, napi_callback_info info);
    static napi_value SetHeatmapOpacity(napi_env env, napi_callback_info info);
    
    // Getter methods
    static napi_value GetHeatmapRadius(napi_env env, napi_callback_info info);
    static napi_value GetHeatmapWeight(napi_env env, napi_callback_info info);
    static napi_value GetHeatmapIntensity(napi_env env, napi_callback_info info);
    static napi_value GetHeatmapColor(napi_env env, napi_callback_info info);
    static napi_value GetHeatmapOpacity(napi_env env, napi_callback_info info);
    
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
    static napi_value GetFilter(napi_env env, napi_callback_info info);    // Generic property methods (Android-compatible API)
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
    mbgl::style::HeatmapLayer* getLayer() { 
        if (!layer && weakLayer) {
            return static_cast<mbgl::style::HeatmapLayer*>(weakLayer.get());
        }
        return layer.get(); 
    }
    
    // Attach to style after adding (creates WeakPtr)
    void attachToStyle(mbgl::style::HeatmapLayer* layerPtr) {
        if (layerPtr) {
            weakLayer = layerPtr->makeWeakPtr();
        }
    }

private:
    explicit HeatmapLayerNAPI(const std::string& layerId, const std::string& sourceId);
    ~HeatmapLayerNAPI();
    
    static napi_ref constructor;
    std::unique_ptr<mbgl::style::HeatmapLayer> layer;
    mapbox::base::WeakPtr<mbgl::style::Layer> weakLayer;
};

} // namespace harmony
} // namespace mbgl

