#include "video_source_napi.hpp"
#include "napi/core/napi_constructor_ref.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"
#include "napi/bindings/image/image_napi.hpp"
#include "bitmap/bitmap_napi.hpp"
#include <mbgl/util/geo.hpp>
#include <array>
#include "napi/core/napi_wrap_instance.hpp"

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

namespace mbgl {

using mbgl::harmony::napi::NapiArgs;
namespace harmony {

// Static member initialization
napi_ref VideoSourceNAPI::constructor = nullptr;
napi_env VideoSourceNAPI::constructorEnv = nullptr;

namespace {

// Default quad (whole world) when no coordinates are supplied yet
std::array<mbgl::LatLng, 4> defaultCoordinates() {
    return {{
        mbgl::LatLng{0, 0}, mbgl::LatLng{0, 1},
        mbgl::LatLng{1, 1}, mbgl::LatLng{1, 0}
    }};
}

// Parse a [[lng, lat], ...] array of exactly four corners
bool parseCoordinates(napi_env env, napi_value coordsValue, std::array<mbgl::LatLng, 4>& out) {
    bool isArray = false;
    napi_is_array(env, coordsValue, &isArray);
    if (!isArray) return false;

    uint32_t length = 0;
    napi_get_array_length(env, coordsValue, &length);
    if (length != 4) return false;

    for (uint32_t i = 0; i < 4; ++i) {
        napi_value coordValue;
        napi_get_element(env, coordsValue, i, &coordValue);

        bool isCoordArray = false;
        napi_is_array(env, coordValue, &isCoordArray);
        if (!isCoordArray) return false;

        napi_value lngValue, latValue;
        napi_get_element(env, coordValue, 0, &lngValue);
        napi_get_element(env, coordValue, 1, &latValue);

        double lng = 0.0, lat = 0.0;
        napi_get_value_double(env, lngValue, &lng);
        napi_get_value_double(env, latValue, &lat);

        out[i] = mbgl::LatLng{lat, lng};
    }
    return true;
}

// Shared frame/image ingestion: accepts an Image or Bitmap NAPI object and
// forwards the pixels to the underlying ImageSource
napi_value updateImageImpl(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;

    VideoSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&sourceNapi));

    if (!sourceNapi) {
        napi_throw_error(env, nullptr, "Invalid source wrapper");
        return nullptr;
    }

    auto* source = sourceNapi->getSource();
    if (!source) {
        napi_throw_error(env, nullptr, "Invalid source");
        return nullptr;
    }

    napi_value imageArg = args.GetValue(0);

    try {
        if (ImageNAPI::IsImageObject(env, imageArg)) {
            ImageNAPI* imageNapi = ImageNAPI::Unwrap(env, imageArg);
            if (!imageNapi) {
                napi_throw_error(env, nullptr, "Failed to unwrap Image object");
                return nullptr;
            }
            auto styleImage = imageNapi->toStyleImage();
            source->setImage(styleImage->getImage().clone());
        } else if (mbgl::harmony::BitmapNAPI::IsBitmapObject(env, imageArg)) {
            mbgl::harmony::BitmapNAPI* bitmapNapi = mbgl::harmony::BitmapNAPI::Unwrap(env, imageArg);
            if (!bitmapNapi) {
                napi_throw_error(env, nullptr, "Failed to unwrap Bitmap object");
                return nullptr;
            }
            auto image = bitmapNapi->getImage();
            if (!image) {
                napi_throw_error(env, nullptr, "Bitmap has no image data");
                return nullptr;
            }
            source->setImage(image->clone());
        } else {
            napi_throw_error(env, nullptr, "updateImage requires an Image or Bitmap object");
            return nullptr;
        }
    } catch (const std::exception& e) {
        Logger::error("VideoSourceNAPI", "UpdateImage failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }

    return nullptr;
}

} // namespace

VideoSourceNAPI::VideoSourceNAPI(const std::string& id, std::unique_ptr<mbgl::style::ImageSource> source)
    : id(id), source(std::move(source)), ownsSource(true) {
    Logger::info("VideoSourceNAPI", "VideoSource instance created: %s", id.c_str());
}

VideoSourceNAPI::VideoSourceNAPI(mbgl::style::ImageSource* sourcePtr)
    : ownsSource(false) {
    if (sourcePtr) {
        id = sourcePtr->getID();
        weakSource = sourcePtr->makeWeakPtr();
        Logger::info("VideoSourceNAPI", "VideoSource created from existing source (WeakPtr): %s", id.c_str());
    }
}

VideoSourceNAPI::~VideoSourceNAPI() {
    Logger::info("VideoSourceNAPI", "VideoSource instance destroyed: %s", id.c_str());
}

void VideoSourceNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    VideoSourceNAPI* sourceNapi = static_cast<VideoSourceNAPI*>(nativeObject);
    delete sourceNapi;
}

napi_value VideoSourceNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("VideoSourceNAPI", "Initializing VideoSource NAPI class");

    napi_property_descriptor properties[] = {
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getCoordinates", nullptr, GetCoordinates, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCoordinates", nullptr, SetCoordinates, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setUrl", nullptr, SetUrl, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setImage", nullptr, UpdateImage, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "updateImage", nullptr, UpdateImage, nullptr, nullptr, nullptr, napi_default, nullptr },
    };

    napi_value cons;
    napi_status status = napi_define_class(env, "VideoSource", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);

    if (status != napi_ok) {
        Logger::error("VideoSourceNAPI", "Failed to define VideoSource class");
        return nullptr;
    }

    status = mbgl::harmony::RefreshConstructorRef(env, cons, constructor, constructorEnv);
    if (status != napi_ok) {
        Logger::error("VideoSourceNAPI", "Failed to create constructor reference");
        return nullptr;
    }

    status = napi_set_named_property(env, exports, "VideoSource", cons);
    if (status != napi_ok) {
        Logger::error("VideoSourceNAPI", "Failed to set VideoSource property");
        return nullptr;
    }

    Logger::info("VideoSourceNAPI", "VideoSource NAPI class initialized successfully");
    return exports;
}

napi_value VideoSourceNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;

    std::string sourceId = args.GetString(0, "sourceId");
    if (args.HasError()) {
        napi_throw_error(env, nullptr, "Failed to parse sourceId");
        return nullptr;
    }

    try {
        std::array<mbgl::LatLng, 4> coords = defaultCoordinates();

        if (args.Count() >= 2) {
            napi_value coordsValue = args.GetValue(1);
            if (!parseCoordinates(env, coordsValue, coords)) {
                Logger::warn("VideoSourceNAPI",
                             "Coordinates must be an array of 4 [lng, lat] corners; using default");
            }
        }

        auto source = std::make_unique<mbgl::style::ImageSource>(sourceId, coords);

        VideoSourceNAPI* sourceNapi = new VideoSourceNAPI(sourceId, std::move(source));

        napi_status status = napi_wrap(env, args.This(), sourceNapi, Destructor, nullptr, nullptr);
        if (status != napi_ok) {
            delete sourceNapi;
            napi_throw_error(env, nullptr, "Failed to wrap VideoSource object");
            return nullptr;
        }

        // Add the _TYPE_ property for ETS type detection
        napi_value typeValue;
        napi_create_string_utf8(env, "VideoSource", NAPI_AUTO_LENGTH, &typeValue);
        napi_set_named_property(env, args.This(), "_TYPE_", typeValue);

        Logger::info("VideoSourceNAPI", "VideoSource created: %s", sourceId.c_str());
        return args.This();
    } catch (const std::exception& e) {
        Logger::error("VideoSourceNAPI", "Failed to create VideoSource: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value VideoSourceNAPI::CreateInstance(napi_env env, mbgl::style::ImageSource* sourcePtr) {
    return mbgl::harmony::WrapExistingInstance(env, constructor, Destructor, "VideoSource",
                                sourcePtr ? new VideoSourceNAPI(sourcePtr) : nullptr);
}

napi_value VideoSourceNAPI::GetId(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);

    VideoSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&sourceNapi));

    if (!sourceNapi) {
        return CreateStringValue(env, "");
    }

    return CreateStringValue(env, sourceNapi->id);
}

napi_value VideoSourceNAPI::GetCoordinates(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);

    VideoSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&sourceNapi));

    if (!sourceNapi || !sourceNapi->getSource()) {
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }

    try {
        auto coordinates = sourceNapi->getSource()->getCoordinates();

        napi_value result;
        napi_create_array_with_length(env, 4, &result);
        for (size_t i = 0; i < coordinates.size() && i < 4; ++i) {
            napi_value coord;
            napi_create_array_with_length(env, 2, &coord);
            napi_value lngValue, latValue;
            napi_create_double(env, coordinates[i].longitude(), &lngValue);
            napi_create_double(env, coordinates[i].latitude(), &latValue);
            napi_set_element(env, coord, 0, lngValue);
            napi_set_element(env, coord, 1, latValue);
            napi_set_element(env, result, static_cast<int32_t>(i), coord);
        }
        return result;
    } catch (const std::exception& e) {
        Logger::error("VideoSourceNAPI", "GetCoordinates failed: %s", e.what());
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
}

napi_value VideoSourceNAPI::SetCoordinates(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;

    VideoSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&sourceNapi));

    if (!sourceNapi || !sourceNapi->getSource()) {
        napi_throw_error(env, nullptr, "Invalid source");
        return nullptr;
    }

    napi_value coordsValue = args.GetValue(0);
    std::array<mbgl::LatLng, 4> coords;
    if (!parseCoordinates(env, coordsValue, coords)) {
        napi_throw_error(env, nullptr, "Coordinates must be an array of 4 [lng, lat] corners");
        return nullptr;
    }

    try {
        sourceNapi->getSource()->setCoordinates(coords);
    } catch (const std::exception& e) {
        Logger::error("VideoSourceNAPI", "SetCoordinates failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
    }

    return nullptr;
}

napi_value VideoSourceNAPI::SetUrl(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;

    VideoSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&sourceNapi));

    if (!sourceNapi || !sourceNapi->getSource()) {
        napi_throw_error(env, nullptr, "Invalid source");
        return nullptr;
    }

    std::string url = args.GetString(0, "url");
    if (args.HasError()) return nullptr;

    try {
        sourceNapi->getSource()->setURL(url);
    } catch (const std::exception& e) {
        Logger::error("VideoSourceNAPI", "SetUrl failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
    }

    return nullptr;
}

napi_value VideoSourceNAPI::UpdateImage(napi_env env, napi_callback_info info) {
    return updateImageImpl(env, info);
}

} // namespace harmony
} // namespace mbgl
