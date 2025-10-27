#pragma once

#include <napi/native_api.h>
#include <mbgl/style/layers/fill_extrusion_layer.hpp>
#include <memory>
#include <string>

namespace mbgl {
namespace harmony {

/**
 * FillExtrusionLayerNAPI - NAPI wrapper for FillExtrusionLayer
 */
class FillExtrusionLayerNAPI {
public:
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value New(napi_env env, napi_callback_info info);
    static void Destructor(napi_env env, void* nativeObject, void* hint);
    
    // Property methods
    static napi_value SetFillExtrusionOpacity(napi_env env, napi_callback_info info);
    static napi_value SetFillExtrusionColor(napi_env env, napi_callback_info info);
    static napi_value SetFillExtrusionTranslate(napi_env env, napi_callback_info info);
    static napi_value SetFillExtrusionHeight(napi_env env, napi_callback_info info);
    static napi_value SetFillExtrusionBase(napi_env env, napi_callback_info info);
    static napi_value SetFillExtrusionPattern(napi_env env, napi_callback_info info);
    
    static napi_value GetFillExtrusionOpacity(napi_env env, napi_callback_info info);
    static napi_value GetFillExtrusionHeight(napi_env env, napi_callback_info info);
    static napi_value GetFillExtrusionBase(napi_env env, napi_callback_info info);
    
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
    static napi_value SetSourceLayer(napi_env env, napi_callback_info info);
    static napi_value GetSourceLayer(napi_env env, napi_callback_info info);
    static napi_value SetFilter(napi_env env, napi_callback_info info);
    static napi_value GetFilter(napi_env env, napi_callback_info info);
    
    std::unique_ptr<mbgl::style::Layer> releaseLayer() {
        if (!layer) throw std::runtime_error("Layer already added to style");
        return std::move(layer);
    }
    
    mbgl::style::FillExtrusionLayer* getLayer() { return layer.get(); }

private:
    explicit FillExtrusionLayerNAPI(const std::string& layerId, const std::string& sourceId);
    ~FillExtrusionLayerNAPI();
    
    static napi_ref constructor;
    std::unique_ptr<mbgl::style::FillExtrusionLayer> layer;
};

} // namespace harmony
} // namespace mbgl

