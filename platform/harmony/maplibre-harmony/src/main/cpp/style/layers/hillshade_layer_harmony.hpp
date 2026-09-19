#pragma once

#include <napi/native_api.h>
#include <mln/style/layers/hillshade_layer.hpp>
#include <memory>
#include <string>

namespace mln {
namespace harmony {

/**
 * HillshadeLayerNAPI - NAPI wrapper for HillshadeLayer
 */
class HillshadeLayerNAPI {
public:
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value New(napi_env env, napi_callback_info info);
    
    // Construct from an existing layer (uses WeakPtr, does not take ownership)
    HillshadeLayerNAPI(mln::style::HillshadeLayer* layerPtr);

    // Create a NAPI instance from an existing native object
    static napi_value CreateInstance(napi_env env, mln::style::HillshadeLayer* layerPtr);
    
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
    
    std::unique_ptr<mln::style::Layer> releaseLayer() {
        if (!layer) throw std::runtime_error("Layer already added to style");
        return std::move(layer);
    }
    
    mln::style::HillshadeLayer* getLayer() { 
        if (!layer && weakLayer) {
            return static_cast<mln::style::HillshadeLayer*>(weakLayer.get());
        }
        return layer.get(); 
    }
    
    // Attach to style after adding (creates WeakPtr)
    void attachToStyle(mln::style::HillshadeLayer* layerPtr) {
        if (layerPtr) {
            weakLayer = layerPtr->makeWeakPtr();
        }
    }

private:
    explicit HillshadeLayerNAPI(const std::string& layerId, const std::string& sourceId);
    ~HillshadeLayerNAPI();
    
    static napi_ref constructor;
    static napi_env constructorEnv;
    std::unique_ptr<mln::style::HillshadeLayer> layer;
    mapbox::base::WeakPtr<mln::style::Layer> weakLayer;
};

} // namespace harmony
} // namespace mln

