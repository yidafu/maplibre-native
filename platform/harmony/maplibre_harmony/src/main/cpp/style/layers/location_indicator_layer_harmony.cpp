#include "location_indicator_layer_harmony.hpp"
#include "layer_base_methods.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "style/layers/layer_property_utils.hpp"
#include <mbgl/style/expression/image.hpp>
#include <mbgl/style/rotation.hpp>
#include <mbgl/util/color.hpp>

namespace mbgl {
namespace harmony {

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

napi_ref LocationIndicatorLayerNAPI::constructor = nullptr;

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

    napi_value cons;
    napi_status status = napi_define_class(env, "LocationIndicatorLayer", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);

    if (status != napi_ok) {
        Logger::error("LocationIndicatorLayerNAPI", "Failed to define LocationIndicatorLayer class");
        return nullptr;
    }

    napi_create_reference(env, cons, 1, &constructor);
    napi_set_named_property(env, exports, "LocationIndicatorLayer", cons);

    Logger::info("LocationIndicatorLayerNAPI", "LocationIndicatorLayer NAPI class registered");
    return exports;
}

napi_value LocationIndicatorLayerNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;

    std::string layerId = args.GetString(0, "layerId");
    if (args.HasError()) return nullptr;

    LocationIndicatorLayerNAPI* layerObj = new LocationIndicatorLayerNAPI(layerId);
    napi_wrap(env, thisVar, layerObj, Destructor, nullptr, nullptr);

    napi_value typeValue;
    napi_create_string_utf8(env, "LocationIndicatorLayer", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, thisVar, "_TYPE_", typeValue);

    return thisVar;
}

napi_value LocationIndicatorLayerNAPI::CreateInstance(napi_env env, mbgl::style::LocationIndicatorLayer* layerPtr) {
    if (!layerPtr) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }

    napi_value cons;
    napi_status status = napi_get_reference_value(env, constructor, &cons);
    if (status != napi_ok) {
        Logger::error("LocationIndicatorLayerNAPI", "Failed to get constructor reference");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }

    napi_value instance;
    status = napi_create_object(env, &instance);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to create object");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }

    napi_value prototype;
    status = napi_get_named_property(env, cons, "prototype", &prototype);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to get prototype");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }

    status = napi_set_named_property(env, instance, "__proto__", prototype);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to set prototype");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }

    LocationIndicatorLayerNAPI* napiObj = new LocationIndicatorLayerNAPI(layerPtr);

    status = napi_wrap(env, instance, napiObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete napiObj;
        Logger::error("LocationIndicatorLayerNAPI", "Failed to wrap instance");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }

    napi_value typeValue;
    napi_create_string_utf8(env, "LocationIndicatorLayer", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, instance, "_TYPE_", typeValue);

    return instance;
}

// ============================================================================
// Layout Properties (images)
// ============================================================================

napi_value LocationIndicatorLayerNAPI::SetBearingImage(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;

    mbgl::harmony::setDataDrivenLayoutProperty<mbgl::style::LocationIndicatorLayer, mbgl::style::expression::Image>(
        env, layerObj->getLayer(), argv[0], "bearing-image",
        &mbgl::style::LocationIndicatorLayer::setBearingImage
    );
    return thisVar;
}

napi_value LocationIndicatorLayerNAPI::GetBearingImage(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    return mbgl::harmony::getProperty<mbgl::style::LocationIndicatorLayer, mbgl::style::expression::Image>(
        env, layerObj->getLayer(), &mbgl::style::LocationIndicatorLayer::getBearingImage
    );
}

napi_value LocationIndicatorLayerNAPI::SetShadowImage(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;

    mbgl::harmony::setDataDrivenLayoutProperty<mbgl::style::LocationIndicatorLayer, mbgl::style::expression::Image>(
        env, layerObj->getLayer(), argv[0], "shadow-image",
        &mbgl::style::LocationIndicatorLayer::setShadowImage
    );
    return thisVar;
}

napi_value LocationIndicatorLayerNAPI::GetShadowImage(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    return mbgl::harmony::getProperty<mbgl::style::LocationIndicatorLayer, mbgl::style::expression::Image>(
        env, layerObj->getLayer(), &mbgl::style::LocationIndicatorLayer::getShadowImage
    );
}

napi_value LocationIndicatorLayerNAPI::SetTopImage(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;

    mbgl::harmony::setDataDrivenLayoutProperty<mbgl::style::LocationIndicatorLayer, mbgl::style::expression::Image>(
        env, layerObj->getLayer(), argv[0], "top-image",
        &mbgl::style::LocationIndicatorLayer::setTopImage
    );
    return thisVar;
}

napi_value LocationIndicatorLayerNAPI::GetTopImage(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    return mbgl::harmony::getProperty<mbgl::style::LocationIndicatorLayer, mbgl::style::expression::Image>(
        env, layerObj->getLayer(), &mbgl::style::LocationIndicatorLayer::getTopImage
    );
}

// ============================================================================
// Paint Properties
// ============================================================================

napi_value LocationIndicatorLayerNAPI::SetAccuracyRadius(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;

    mbgl::harmony::setPaintProperty<mbgl::style::LocationIndicatorLayer, float>(
        env, layerObj->getLayer(), argv[0], "accuracy-radius",
        &mbgl::style::LocationIndicatorLayer::setAccuracyRadius
    );
    return thisVar;
}

napi_value LocationIndicatorLayerNAPI::GetAccuracyRadius(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    return mbgl::harmony::getProperty<mbgl::style::LocationIndicatorLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::LocationIndicatorLayer::getAccuracyRadius
    );
}

napi_value LocationIndicatorLayerNAPI::SetAccuracyRadiusBorderColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;

    mbgl::harmony::setPaintProperty<mbgl::style::LocationIndicatorLayer, mbgl::Color>(
        env, layerObj->getLayer(), argv[0], "accuracy-radius-border-color",
        &mbgl::style::LocationIndicatorLayer::setAccuracyRadiusBorderColor
    );
    return thisVar;
}

napi_value LocationIndicatorLayerNAPI::GetAccuracyRadiusBorderColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    return mbgl::harmony::getProperty<mbgl::style::LocationIndicatorLayer, mbgl::Color>(
        env, layerObj->getLayer(), &mbgl::style::LocationIndicatorLayer::getAccuracyRadiusBorderColor
    );
}

napi_value LocationIndicatorLayerNAPI::SetAccuracyRadiusColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;

    mbgl::harmony::setPaintProperty<mbgl::style::LocationIndicatorLayer, mbgl::Color>(
        env, layerObj->getLayer(), argv[0], "accuracy-radius-color",
        &mbgl::style::LocationIndicatorLayer::setAccuracyRadiusColor
    );
    return thisVar;
}

napi_value LocationIndicatorLayerNAPI::GetAccuracyRadiusColor(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    return mbgl::harmony::getProperty<mbgl::style::LocationIndicatorLayer, mbgl::Color>(
        env, layerObj->getLayer(), &mbgl::style::LocationIndicatorLayer::getAccuracyRadiusColor
    );
}

napi_value LocationIndicatorLayerNAPI::SetBearing(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;

    mbgl::harmony::setPaintProperty<mbgl::style::LocationIndicatorLayer, mbgl::style::Rotation>(
        env, layerObj->getLayer(), argv[0], "bearing",
        &mbgl::style::LocationIndicatorLayer::setBearing
    );
    return thisVar;
}

napi_value LocationIndicatorLayerNAPI::GetBearing(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    return mbgl::harmony::getProperty<mbgl::style::LocationIndicatorLayer, mbgl::style::Rotation>(
        env, layerObj->getLayer(), &mbgl::style::LocationIndicatorLayer::getBearing
    );
}

napi_value LocationIndicatorLayerNAPI::SetBearingImageSize(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;

    mbgl::harmony::setPaintProperty<mbgl::style::LocationIndicatorLayer, float>(
        env, layerObj->getLayer(), argv[0], "bearing-image-size",
        &mbgl::style::LocationIndicatorLayer::setBearingImageSize
    );
    return thisVar;
}

napi_value LocationIndicatorLayerNAPI::GetBearingImageSize(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    return mbgl::harmony::getProperty<mbgl::style::LocationIndicatorLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::LocationIndicatorLayer::getBearingImageSize
    );
}

napi_value LocationIndicatorLayerNAPI::SetImageTiltDisplacement(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;

    mbgl::harmony::setPaintProperty<mbgl::style::LocationIndicatorLayer, float>(
        env, layerObj->getLayer(), argv[0], "image-tilt-displacement",
        &mbgl::style::LocationIndicatorLayer::setImageTiltDisplacement
    );
    return thisVar;
}

napi_value LocationIndicatorLayerNAPI::GetImageTiltDisplacement(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    return mbgl::harmony::getProperty<mbgl::style::LocationIndicatorLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::LocationIndicatorLayer::getImageTiltDisplacement
    );
}

napi_value LocationIndicatorLayerNAPI::SetLocation(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;

    mbgl::harmony::setPaintProperty<mbgl::style::LocationIndicatorLayer, std::array<double, 3>>(
        env, layerObj->getLayer(), argv[0], "location",
        &mbgl::style::LocationIndicatorLayer::setLocation
    );
    return thisVar;
}

napi_value LocationIndicatorLayerNAPI::GetLocation(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    return mbgl::harmony::getProperty<mbgl::style::LocationIndicatorLayer, std::array<double, 3>>(
        env, layerObj->getLayer(), &mbgl::style::LocationIndicatorLayer::getLocation
    );
}

napi_value LocationIndicatorLayerNAPI::SetPerspectiveCompensation(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;

    mbgl::harmony::setPaintProperty<mbgl::style::LocationIndicatorLayer, float>(
        env, layerObj->getLayer(), argv[0], "perspective-compensation",
        &mbgl::style::LocationIndicatorLayer::setPerspectiveCompensation
    );
    return thisVar;
}

napi_value LocationIndicatorLayerNAPI::GetPerspectiveCompensation(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    return mbgl::harmony::getProperty<mbgl::style::LocationIndicatorLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::LocationIndicatorLayer::getPerspectiveCompensation
    );
}

napi_value LocationIndicatorLayerNAPI::SetShadowImageSize(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;

    mbgl::harmony::setPaintProperty<mbgl::style::LocationIndicatorLayer, float>(
        env, layerObj->getLayer(), argv[0], "shadow-image-size",
        &mbgl::style::LocationIndicatorLayer::setShadowImageSize
    );
    return thisVar;
}

napi_value LocationIndicatorLayerNAPI::GetShadowImageSize(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    return mbgl::harmony::getProperty<mbgl::style::LocationIndicatorLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::LocationIndicatorLayer::getShadowImageSize
    );
}

napi_value LocationIndicatorLayerNAPI::SetTopImageSize(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer() || argc < 1) return thisVar;

    mbgl::harmony::setPaintProperty<mbgl::style::LocationIndicatorLayer, float>(
        env, layerObj->getLayer(), argv[0], "top-image-size",
        &mbgl::style::LocationIndicatorLayer::setTopImageSize
    );
    return thisVar;
}

napi_value LocationIndicatorLayerNAPI::GetTopImageSize(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    return mbgl::harmony::getProperty<mbgl::style::LocationIndicatorLayer, float>(
        env, layerObj->getLayer(), &mbgl::style::LocationIndicatorLayer::getTopImageSize
    );
}

// ============================================================================
// Base Layer Methods
// ============================================================================

napi_value LocationIndicatorLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    std::string id = layerObj->getLayer()->getID();
    napi_value result;
    napi_create_string_utf8(env, id.c_str(), NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value LocationIndicatorLayerNAPI::GetType(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_string_utf8(env, "location-indicator", NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value LocationIndicatorLayerNAPI::SetVisibility(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer()) return thisVar;

    args.RequireMinArgs(1);
    if (!args.HasError()) {
        std::string visibility = args.GetString(0, "visibility");
        if (visibility == "visible") {
            layerObj->getLayer()->setVisibility(mbgl::style::VisibilityType::Visible);
        } else if (visibility == "none") {
            layerObj->getLayer()->setVisibility(mbgl::style::VisibilityType::None);
        }
    }
    return thisVar;
}

napi_value LocationIndicatorLayerNAPI::GetVisibility(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer()) {
        napi_value null_value;
        napi_get_null(env, &null_value);
        return null_value;
    }

    auto visibility = layerObj->getLayer()->getVisibility();
    const char* visStr = (visibility == mbgl::style::VisibilityType::Visible) ? "visible" : "none";

    napi_value result;
    napi_create_string_utf8(env, visStr, NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value LocationIndicatorLayerNAPI::SetMinZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer()) return thisVar;

    args.RequireMinArgs(1);
    if (!args.HasError()) {
        float minZoom = static_cast<float>(args.GetDouble(0, "minZoom"));
        layerObj->getLayer()->setMinZoom(minZoom);
    }
    return thisVar;
}

napi_value LocationIndicatorLayerNAPI::GetMinZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer()) {
        napi_value result;
        napi_create_double(env, 0.0, &result);
        return result;
    }

    float minZoom = layerObj->getLayer()->getMinZoom();
    napi_value result;
    napi_create_double(env, minZoom, &result);
    return result;
}

napi_value LocationIndicatorLayerNAPI::SetMaxZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer()) return thisVar;

    args.RequireMinArgs(1);
    if (!args.HasError()) {
        float maxZoom = static_cast<float>(args.GetDouble(0, "maxZoom"));
        layerObj->getLayer()->setMaxZoom(maxZoom);
    }
    return thisVar;
}

napi_value LocationIndicatorLayerNAPI::GetMaxZoom(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    LocationIndicatorLayerNAPI* layerObj;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer()) {
        napi_value result;
        napi_create_double(env, 24.0, &result);
        return result;
    }

    float maxZoom = layerObj->getLayer()->getMaxZoom();
    napi_value result;
    napi_create_double(env, maxZoom, &result);
    return result;
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
