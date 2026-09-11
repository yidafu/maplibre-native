#pragma once

#include <napi/native_api.h>
#include <mbgl/style/layers/location_indicator_layer.hpp>
#include <memory>
#include <string>

namespace mbgl {
namespace harmony {

/**
 * LocationIndicatorLayerNAPI - NAPI wrapper for LocationIndicatorLayer
 *
 * Layout properties:
 *   - bearingImage / shadowImage / topImage (expression::Image)
 * Paint properties:
 *   - accuracyRadius (float)
 *   - accuracyRadiusBorderColor / accuracyRadiusColor (Color)
 *   - bearing (Rotation, degrees)
 *   - bearingImageSize / shadowImageSize / topImageSize (float)
 *   - imageTiltDisplacement / perspectiveCompensation (float)
 *   - location ([latitude, longitude, altitude])
 *
 * The layer is not tied to a source (no sourceId, no filter).
 */
class LocationIndicatorLayerNAPI {
public:
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value New(napi_env env, napi_callback_info info);

    // Construct from an existing layer (uses WeakPtr, does not take ownership)
    LocationIndicatorLayerNAPI(mbgl::style::LocationIndicatorLayer* layerPtr);

    // Create a NAPI instance from an existing native object
    static napi_value CreateInstance(napi_env env, mbgl::style::LocationIndicatorLayer* layerPtr);

    static void Destructor(napi_env env, void* nativeObject, void* hint);

    // Layout property methods
    static napi_value SetBearingImage(napi_env env, napi_callback_info info);
    static napi_value GetBearingImage(napi_env env, napi_callback_info info);
    static napi_value SetShadowImage(napi_env env, napi_callback_info info);
    static napi_value GetShadowImage(napi_env env, napi_callback_info info);
    static napi_value SetTopImage(napi_env env, napi_callback_info info);
    static napi_value GetTopImage(napi_env env, napi_callback_info info);

    // Paint property methods
    static napi_value SetAccuracyRadius(napi_env env, napi_callback_info info);
    static napi_value GetAccuracyRadius(napi_env env, napi_callback_info info);
    static napi_value SetAccuracyRadiusBorderColor(napi_env env, napi_callback_info info);
    static napi_value GetAccuracyRadiusBorderColor(napi_env env, napi_callback_info info);
    static napi_value SetAccuracyRadiusColor(napi_env env, napi_callback_info info);
    static napi_value GetAccuracyRadiusColor(napi_env env, napi_callback_info info);
    static napi_value SetBearing(napi_env env, napi_callback_info info);
    static napi_value GetBearing(napi_env env, napi_callback_info info);
    static napi_value SetBearingImageSize(napi_env env, napi_callback_info info);
    static napi_value GetBearingImageSize(napi_env env, napi_callback_info info);
    static napi_value SetImageTiltDisplacement(napi_env env, napi_callback_info info);
    static napi_value GetImageTiltDisplacement(napi_env env, napi_callback_info info);
    static napi_value SetLocation(napi_env env, napi_callback_info info);
    static napi_value GetLocation(napi_env env, napi_callback_info info);
    static napi_value SetPerspectiveCompensation(napi_env env, napi_callback_info info);
    static napi_value GetPerspectiveCompensation(napi_env env, napi_callback_info info);
    static napi_value SetShadowImageSize(napi_env env, napi_callback_info info);
    static napi_value GetShadowImageSize(napi_env env, napi_callback_info info);
    static napi_value SetTopImageSize(napi_env env, napi_callback_info info);
    static napi_value GetTopImageSize(napi_env env, napi_callback_info info);

    // Base layer methods
    static napi_value GetId(napi_env env, napi_callback_info info);
    static napi_value GetType(napi_env env, napi_callback_info info);
    static napi_value SetVisibility(napi_env env, napi_callback_info info);
    static napi_value GetVisibility(napi_env env, napi_callback_info info);
    static napi_value SetMinZoom(napi_env env, napi_callback_info info);
    static napi_value GetMinZoom(napi_env env, napi_callback_info info);
    static napi_value SetMaxZoom(napi_env env, napi_callback_info info);
    static napi_value GetMaxZoom(napi_env env, napi_callback_info info);

    // Generic property methods (Android-compatible API)
    static napi_value SetProperty(napi_env env, napi_callback_info info);
    static napi_value SetProperties(napi_env env, napi_callback_info info);

    std::unique_ptr<mbgl::style::Layer> releaseLayer() {
        if (!layer) throw std::runtime_error("Layer already added to style");
        return std::move(layer);
    }

    mbgl::style::LocationIndicatorLayer* getLayer() {
        if (!layer && weakLayer) {
            return static_cast<mbgl::style::LocationIndicatorLayer*>(weakLayer.get());
        }
        return layer.get();
    }

    // Attach to style after adding (creates WeakPtr)
    void attachToStyle(mbgl::style::LocationIndicatorLayer* layerPtr) {
        if (layerPtr) {
            weakLayer = layerPtr->makeWeakPtr();
        }
    }

private:
    explicit LocationIndicatorLayerNAPI(const std::string& layerId);
    ~LocationIndicatorLayerNAPI();

    static napi_ref constructor;
    std::unique_ptr<mbgl::style::LocationIndicatorLayer> layer;
    mapbox::base::WeakPtr<mbgl::style::Layer> weakLayer;
};

} // namespace harmony
} // namespace mbgl
