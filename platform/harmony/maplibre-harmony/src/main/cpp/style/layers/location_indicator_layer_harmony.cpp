#include "location_indicator_layer_harmony.hpp"
#include "napi/core/napi_constructor_ref.hpp"
#include "layer_base_methods.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "style/layers/layer_property_utils.hpp"
#include <mbgl/style/expression/image.hpp>
#include <mbgl/style/rotation.hpp>
#include <mbgl/util/color.hpp>
#include "napi/core/napi_wrap_instance.hpp"

#include "layer_property_macros.hpp"
namespace mbgl {
namespace harmony {

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

napi_ref LocationIndicatorLayerNAPI::constructor = nullptr;
napi_env LocationIndicatorLayerNAPI::constructorEnv = nullptr;

LocationIndicatorLayerNAPI::LocationIndicatorLayerNAPI(const std::string& layerId)
    : layer(std::make_unique<mbgl::style::LocationIndicatorLayer>(layerId)) {
}

LocationIndicatorLayerNAPI::LocationIndicatorLayerNAPI(mbgl::style::LocationIndicatorLayer* layerPtr) {
    if (layerPtr) {
        weakLayer = layerPtr->makeWeakPtr();
        Logger::info("LocationIndicatorLayerNAPI", "LocationIndicatorLayer created from existing layer (WeakPtr)");
    }
}

LocationIndicatorLayerNAPI::~LocationIndicatorLayerNAPI() {
}

void LocationIndicatorLayerNAPI::Destructor(napi_env env, void* nativeObject, void* hint) {
    delete static_cast<LocationIndicatorLayerNAPI*>(nativeObject);
}

napi_value LocationIndicatorLayerNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("LocationIndicatorLayerNAPI", "Initializing LocationIndicatorLayer NAPI class");

    napi_property_descriptor properties[] = {
        // Layout properties (images, expression supported)
        { "setBearingImage", nullptr, SetBearingImage, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getBearingImage", nullptr, GetBearingImage, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setShadowImage", nullptr, SetShadowImage, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getShadowImage", nullptr, GetShadowImage, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTopImage", nullptr, SetTopImage, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTopImage", nullptr, GetTopImage, nullptr, nullptr, nullptr, napi_default, nullptr },

        // Paint properties
        { "setAccuracyRadius", nullptr, SetAccuracyRadius, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getAccuracyRadius", nullptr, GetAccuracyRadius, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setAccuracyRadiusBorderColor", nullptr, SetAccuracyRadiusBorderColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getAccuracyRadiusBorderColor", nullptr, GetAccuracyRadiusBorderColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setAccuracyRadiusColor", nullptr, SetAccuracyRadiusColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getAccuracyRadiusColor", nullptr, GetAccuracyRadiusColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setBearing", nullptr, SetBearing, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getBearing", nullptr, GetBearing, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setBearingImageSize", nullptr, SetBearingImageSize, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getBearingImageSize", nullptr, GetBearingImageSize, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setImageTiltDisplacement", nullptr, SetImageTiltDisplacement, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getImageTiltDisplacement", nullptr, GetImageTiltDisplacement, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setLocation", nullptr, SetLocation, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getLocation", nullptr, GetLocation, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setPerspectiveCompensation", nullptr, SetPerspectiveCompensation, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getPerspectiveCompensation", nullptr, GetPerspectiveCompensation, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setShadowImageSize", nullptr, SetShadowImageSize, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getShadowImageSize", nullptr, GetShadowImageSize, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTopImageSize", nullptr, SetTopImageSize, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getTopImageSize", nullptr, GetTopImageSize, nullptr, nullptr, nullptr, napi_default, nullptr },

        // Base layer methods
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getType", nullptr, GetType, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setVisibility", nullptr, SetVisibility, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getVisibility", nullptr, GetVisibility, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setMinZoom", nullptr, SetMinZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getMinZoom", nullptr, GetMinZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setMaxZoom", nullptr, SetMaxZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getMaxZoom", nullptr, GetMaxZoom, nullptr, nullptr, nullptr, napi_default, nullptr },

        // Generic property methods (Android-compatible API)
        { "setProperty", nullptr, SetProperty, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setProperties", nullptr, SetProperties, nullptr, nullptr, nullptr, napi_default, nullptr },
    };

    napi_value cons = RegisterNapiClass(env, exports, "LocationIndicatorLayer", properties,
                                        sizeof(properties) / sizeof(properties[0]), New,
                                        constructor, constructorEnv, "LocationIndicatorLayerNAPI");
    if (!cons) return nullptr;

    Logger::info("LocationIndicatorLayerNAPI", "LocationIndicatorLayer NAPI class registered");
    return exports;
}

DEFINE_LAYER_NEW(LocationIndicatorLayerNAPI, "LocationIndicatorLayer", 1, new LocationIndicatorLayerNAPI(layerId),
        std::string layerId = args.GetString(0, "layerId");)

napi_value LocationIndicatorLayerNAPI::CreateInstance(napi_env env, mbgl::style::LocationIndicatorLayer* layerPtr) {
    return WrapExistingInstance(env, constructor, Destructor, "LocationIndicatorLayer",
                                layerPtr ? new LocationIndicatorLayerNAPI(layerPtr) : nullptr);
}

// ============================================================================
// Layout Properties (images)
// ============================================================================

DEFINE_LAYER_SETTER(LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer, SetBearingImage, setDataDrivenLayoutProperty, "bearing-image", setBearingImage, mbgl::style::expression::Image)

DEFINE_LAYER_GETTER(LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer, GetBearingImage, getBearingImage, mbgl::style::expression::Image)

DEFINE_LAYER_SETTER(LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer, SetShadowImage, setDataDrivenLayoutProperty, "shadow-image", setShadowImage, mbgl::style::expression::Image)

DEFINE_LAYER_GETTER(LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer, GetShadowImage, getShadowImage, mbgl::style::expression::Image)

DEFINE_LAYER_SETTER(LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer, SetTopImage, setDataDrivenLayoutProperty, "top-image", setTopImage, mbgl::style::expression::Image)

DEFINE_LAYER_GETTER(LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer, GetTopImage, getTopImage, mbgl::style::expression::Image)

// ============================================================================
// Paint Properties
// ============================================================================

DEFINE_LAYER_SETTER(LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer, SetAccuracyRadius, setPaintProperty, "accuracy-radius", setAccuracyRadius, float)

DEFINE_LAYER_GETTER(LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer, GetAccuracyRadius, getAccuracyRadius, float)

DEFINE_LAYER_SETTER(LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer, SetAccuracyRadiusBorderColor, setPaintProperty, "accuracy-radius-border-color", setAccuracyRadiusBorderColor, mbgl::Color)

DEFINE_LAYER_GETTER(LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer, GetAccuracyRadiusBorderColor, getAccuracyRadiusBorderColor, mbgl::Color)

DEFINE_LAYER_SETTER(LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer, SetAccuracyRadiusColor, setPaintProperty, "accuracy-radius-color", setAccuracyRadiusColor, mbgl::Color)

DEFINE_LAYER_GETTER(LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer, GetAccuracyRadiusColor, getAccuracyRadiusColor, mbgl::Color)

DEFINE_LAYER_SETTER(LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer, SetBearing, setPaintProperty, "bearing", setBearing, mbgl::style::Rotation)

DEFINE_LAYER_GETTER(LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer, GetBearing, getBearing, mbgl::style::Rotation)

DEFINE_LAYER_SETTER(LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer, SetBearingImageSize, setPaintProperty, "bearing-image-size", setBearingImageSize, float)

DEFINE_LAYER_GETTER(LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer, GetBearingImageSize, getBearingImageSize, float)

DEFINE_LAYER_SETTER(LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer, SetImageTiltDisplacement, setPaintProperty, "image-tilt-displacement", setImageTiltDisplacement, float)

DEFINE_LAYER_GETTER(LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer, GetImageTiltDisplacement, getImageTiltDisplacement, float)

DEFINE_LAYER_SETTER(LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer, SetLocation, setPaintProperty, "location", setLocation, std::array<double,3>)

DEFINE_LAYER_GETTER(LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer, GetLocation, getLocation, std::array<double,3>)

DEFINE_LAYER_SETTER(LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer, SetPerspectiveCompensation, setPaintProperty, "perspective-compensation", setPerspectiveCompensation, float)

DEFINE_LAYER_GETTER(LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer, GetPerspectiveCompensation, getPerspectiveCompensation, float)

DEFINE_LAYER_SETTER(LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer, SetShadowImageSize, setPaintProperty, "shadow-image-size", setShadowImageSize, float)

DEFINE_LAYER_GETTER(LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer, GetShadowImageSize, getShadowImageSize, float)

DEFINE_LAYER_SETTER(LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer, SetTopImageSize, setPaintProperty, "top-image-size", setTopImageSize, float)

DEFINE_LAYER_GETTER(LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer, GetTopImageSize, getTopImageSize, float)

// ============================================================================
// Base Layer Methods
// ============================================================================

napi_value LocationIndicatorLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    return LayerGetId<LocationIndicatorLayerNAPI>(env, info);
}

napi_value LocationIndicatorLayerNAPI::GetType(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_string_utf8(env, "location-indicator", NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value LocationIndicatorLayerNAPI::SetVisibility(napi_env env, napi_callback_info info) {
    return LayerSetVisibility<LocationIndicatorLayerNAPI>(env, info);
}

napi_value LocationIndicatorLayerNAPI::GetVisibility(napi_env env, napi_callback_info info) {
    return LayerGetVisibility<LocationIndicatorLayerNAPI>(env, info);
}

napi_value LocationIndicatorLayerNAPI::SetMinZoom(napi_env env, napi_callback_info info) {
    return LayerSetMinZoom<LocationIndicatorLayerNAPI>(env, info);
}

napi_value LocationIndicatorLayerNAPI::GetMinZoom(napi_env env, napi_callback_info info) {
    return LayerGetMinZoom<LocationIndicatorLayerNAPI>(env, info);
}

napi_value LocationIndicatorLayerNAPI::SetMaxZoom(napi_env env, napi_callback_info info) {
    return LayerSetMaxZoom<LocationIndicatorLayerNAPI>(env, info);
}

napi_value LocationIndicatorLayerNAPI::GetMaxZoom(napi_env env, napi_callback_info info) {
    return LayerGetMaxZoom<LocationIndicatorLayerNAPI>(env, info);
}

// ==================== Generic Property Methods ====================

napi_value LocationIndicatorLayerNAPI::SetProperty(napi_env env, napi_callback_info info) {
    return SetPropertyImpl<LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer>(env, info);
}

napi_value LocationIndicatorLayerNAPI::SetProperties(napi_env env, napi_callback_info info) {
    return SetPropertiesImpl<LocationIndicatorLayerNAPI, mbgl::style::LocationIndicatorLayer>(env, info);
}

} // namespace harmony
} // namespace mbgl
