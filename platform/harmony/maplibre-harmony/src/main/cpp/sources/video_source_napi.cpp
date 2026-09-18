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

#include "source_napi_utils.hpp"
#include "image_payload_napi.hpp"
using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

namespace mbgl {

using mbgl::harmony::napi::NapiArgs;
namespace harmony {

// Static member initialization
napi_ref VideoSourceNAPI::constructor = nullptr;
napi_env VideoSourceNAPI::constructorEnv = nullptr;

namespace {

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
        auto payload = DecodeImageOrBitmap(env, imageArg, "updateImage requires an Image or Bitmap object");
        if (!payload) {
            return nullptr;
        }

        source->setImage(std::move(payload->image));
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

    napi_value cons = RegisterNapiClass(env, exports, "VideoSource", properties,
                                        sizeof(properties) / sizeof(properties[0]), New,
                                        constructor, constructorEnv, "VideoSourceNAPI");
    if (!cons) return nullptr;

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
        std::array<mbgl::LatLng, 4> coords = DefaultLatLngQuad();

        if (args.Count() >= 2) {
            napi_value coordsValue = args.GetValue(1);
            if (!ParseLatLngQuad(env, coordsValue, coords)) {
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

DEFINE_SOURCE_GET_ID(VideoSourceNAPI)

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
    if (!ParseLatLngQuad(env, coordsValue, coords)) {
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
