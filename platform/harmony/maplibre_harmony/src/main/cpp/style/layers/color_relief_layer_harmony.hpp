#pragma once

#include <napi/native_api.h>
#include <mbgl/style/layers/color_relief_layer.hpp>
#include <memory>
#include <string>

namespace mbgl {
namespace harmony {

/**
 * ColorReliefLayerNAPI - NAPI wrapper for ColorReliefLayer
 * Properties:
 *   - colorReliefColor (ColorRampPropertyValue)
 *   - colorReliefOpacity (PropertyValue<float>)
 */
class ColorReliefLayerNAPI {
public:
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value New(napi_env env, napi_callback_info info);

    // Construct from an existing layer (uses WeakPtr, does not take ownership)
    ColorReliefLayerNAPI(mbgl::style::ColorReliefLayer* layerPtr);

    // Create a NAPI instance from an existing native object
    static napi_value CreateInstance(napi_env env, mbgl::style::ColorReliefLayer* layerPtr);

    static void Destructor(napi_env env, void* nativeObject, void* hint);

    // Property methods
    static napi_value SetColorReliefColor(napi_env env, napi_callback_info info);
    static napi_value SetColorReliefOpacity(napi_env env, napi_callback_info info);

    static napi_value GetColorReliefColor(napi_env env, napi_callback_info info);
    static napi_value GetColorReliefOpacity(napi_env env, napi_callback_info info);

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

    mbgl::style::ColorReliefLayer* getLayer() {
        if (!layer && weakLayer) {
            return static_cast<mbgl::style::ColorReliefLayer*>(weakLayer.get());
        }
        return layer.get();
    }

    // Attach to style after adding (creates WeakPtr)
    void attachToStyle(mbgl::style::ColorReliefLayer* layerPtr) {
        if (layerPtr) {
            weakLayer = layerPtr->makeWeakPtr();
        }
    }

private:
    explicit ColorReliefLayerNAPI(const std::string& layerId, const std::string& sourceId);
    ~ColorReliefLayerNAPI();

    static napi_ref constructor;
    std::unique_ptr<mbgl::style::ColorReliefLayer> layer;
    mapbox::base::WeakPtr<mbgl::style::Layer> weakLayer;
};

} // namespace harmony
} // namespace mbgl
