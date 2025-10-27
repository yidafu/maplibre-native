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
    
    std::unique_ptr<mbgl::style::Layer> releaseLayer() {
        if (!layer) throw std::runtime_error("Layer already added to style");
        return std::move(layer);
    }
    
    mbgl::style::HillshadeLayer* getLayer() { return layer.get(); }

private:
    explicit HillshadeLayerNAPI(const std::string& layerId, const std::string& sourceId);
    ~HillshadeLayerNAPI();
    
    static napi_ref constructor;
    std::unique_ptr<mbgl::style::HillshadeLayer> layer;
};

} // namespace harmony
} // namespace mbgl

