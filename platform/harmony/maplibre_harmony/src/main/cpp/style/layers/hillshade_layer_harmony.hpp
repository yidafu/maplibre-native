#pragma once

#include <napi/native_api.h>
#include <mbgl/style/layers/hillshade_layer.hpp>
#include <memory>
#include <string>

namespace mbgl {
namespace harmony {

/**
 * HillshadeLayerNAPI - NAPI wrapper for HillshadeLayer
 */
class HillshadeLayerNAPI {
public:
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value New(napi_env env, napi_callback_info info);
    
    // 从现有 Layer 创建（使用 WeakPtr，不拥有所有权）
    HillshadeLayerNAPI(mbgl::style::HillshadeLayer* layerPtr);

    // 从现有 native 对象创建 NAPI 实例
    static napi_value CreateInstance(napi_env env, mbgl::style::HillshadeLayer* layerPtr);
    
    static void Destructor(napi_env env, void* nativeObject, void* hint);
    
    // Property methods
    static napi_value SetHillshadeIlluminationDirection(napi_env env, napi_callback_info info);
    static napi_value SetHillshadeIlluminationAnchor(napi_env env, napi_callback_info info);
    static napi_value SetHillshadeExaggeration(napi_env env, napi_callback_info info);
    static napi_value SetHillshadeShadowColor(napi_env env, napi_callback_info info);
    static napi_value SetHillshadeHighlightColor(napi_env env, napi_callback_info info);
    static napi_value SetHillshadeAccentColor(napi_env env, napi_callback_info info);
    
    static napi_value GetHillshadeIlluminationDirection(napi_env env, napi_callback_info info);
    static napi_value GetHillshadeExaggeration(napi_env env, napi_callback_info info);
    
    // Base layer methods
    static napi_value GetId(napi_env env, napi_callback_info info);
    static napi_value GetType(napi_env env, napi_callback_info info);
    static napi_value GetSourceId(napi_env env, napi_callback_info info);
    static napi_value SetVisibility(napi_env env, napi_callback_info info);
    static napi_value GetVisibility(napi_env env, napi_callback_info info);
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
    
    // Generic property methods (Android-compatible API)
    static napi_value SetProperty(napi_env env, napi_callback_info info);
    static napi_value SetProperties(napi_env env, napi_callback_info info);
    
    std::unique_ptr<mbgl::style::Layer> releaseLayer() {
        if (!layer) throw std::runtime_error("Layer already added to style");
        return std::move(layer);
    }
    
    mbgl::style::HillshadeLayer* getLayer() { 
        if (!layer && weakLayer) {
            return static_cast<mbgl::style::HillshadeLayer*>(weakLayer.get());
        }
        return layer.get(); 
    }
    
    // Attach to style after adding (creates WeakPtr)
    void attachToStyle(mbgl::style::HillshadeLayer* layerPtr) {
        if (layerPtr) {
            weakLayer = layerPtr->makeWeakPtr();
        }
    }

private:
    explicit HillshadeLayerNAPI(const std::string& layerId, const std::string& sourceId);
    ~HillshadeLayerNAPI();
    
    static napi_ref constructor;
    std::unique_ptr<mbgl::style::HillshadeLayer> layer;
    mapbox::base::WeakPtr<mbgl::style::Layer> weakLayer;
};

} // namespace harmony
} // namespace mbgl

