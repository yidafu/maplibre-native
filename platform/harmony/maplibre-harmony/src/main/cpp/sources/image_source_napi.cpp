#include "image_source_napi.hpp"
#include "napi/core/napi_constructor_ref.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "napi/bindings/image/image_napi.hpp"
#include "bitmap/bitmap_napi.hpp"
#include "utils/logger.h"
#include <mbgl/util/geo.hpp>
#include "napi/core/napi_wrap_instance.hpp"

#include "source_napi_utils.hpp"
#include "image_payload_napi.hpp"
using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

namespace mbgl {

using mbgl::harmony::napi::NapiArgs;
namespace harmony {

napi_ref ImageSourceNAPI::constructor = nullptr;
napi_env ImageSourceNAPI::constructorEnv = nullptr;

ImageSourceNAPI::ImageSourceNAPI(const std::string& id, std::unique_ptr<mbgl::style::ImageSource> source)
    : id(id), source(std::move(source)), ownsSource(true) {
    Logger::info("ImageSourceNAPI", "ImageSource instance created: %s", id.c_str());
}

ImageSourceNAPI::ImageSourceNAPI(mbgl::style::ImageSource* sourcePtr)
    : ownsSource(false) {
    if (sourcePtr) {
        id = sourcePtr->getID();
        weakSource = sourcePtr->makeWeakPtr();
        Logger::info("ImageSourceNAPI", "ImageSource created from existing source (WeakPtr): %s", id.c_str());
    }
}

ImageSourceNAPI::~ImageSourceNAPI() {
    // Reset weakSource before source is destroyed to avoid accessing invalidated WeakPtrFactory
    Logger::info("ImageSourceNAPI", "ImageSource instance destroyed: %s", id.c_str());
}

void ImageSourceNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    ImageSourceNAPI* sourceNapi = static_cast<ImageSourceNAPI*>(nativeObject);
    delete sourceNapi;
}

napi_value ImageSourceNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("ImageSourceNAPI", "Initializing ImageSource NAPI class");
    
    napi_property_descriptor properties[] = {
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setUrl", nullptr, SetUrl, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setImage", nullptr, SetImage, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCoordinates", nullptr, SetCoordinates, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons = RegisterNapiClass(env, exports, "ImageSource", properties,
                                        sizeof(properties) / sizeof(properties[0]), New,
                                        constructor, constructorEnv, "ImageSourceNAPI");
    if (!cons) return nullptr;

    Logger::info("ImageSourceNAPI", "ImageSource NAPI class initialized successfully");
    return exports;
}

napi_value ImageSourceNAPI::New(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "ImageSource requires sourceId argument");
        return nullptr;
    }
    
    NapiArgs napiArgs(env, info);
    std::string sourceId = napiArgs.GetString(0, "sourceId");
    
    if (napiArgs.HasError()) {
        napi_throw_error(env, nullptr, "Failed to parse sourceId");
        return nullptr;
    }
    
    try {
        // Parse coordinates argument (four LatLng values, clockwise: top-left, top-right, bottom-right, bottom-left)
        std::array<mbgl::LatLng, 4> coords = DefaultLatLngQuad();

        if (napiArgs.Count() >= 2) {
            napi_value coordsValue = napiArgs.GetValue(1);
            bool isArray = false;
            napi_is_array(env, coordsValue, &isArray);
            if (!isArray) {
                Logger::warn("ImageSourceNAPI", "Coordinates must be an array, using default");
                coords = DefaultLatLngQuad();
            } else if (!ParseLatLngQuad(env, coordsValue, coords)) {
                if (napiArgs.GetArrayLength(coordsValue) != 4) {
                    Logger::warn("ImageSourceNAPI", "Coordinates array must have 4 elements, using default");
                }
                coords = DefaultLatLngQuad();
            }
        }
        
        auto source = std::make_unique<mbgl::style::ImageSource>(sourceId, coords);
        ImageSourceNAPI* sourceNapi = new ImageSourceNAPI(sourceId, std::move(source));
        
        napi_status status = napi_wrap(env, jsThis, sourceNapi, Destructor, nullptr, nullptr);
        if (status != napi_ok) {
            delete sourceNapi;
            napi_throw_error(env, nullptr, "Failed to wrap ImageSource object");
            return nullptr;
        }
        
        Logger::info("ImageSourceNAPI", "ImageSource created: %s", sourceId.c_str());
    
    // Add a _TYPE_ property for ETS-side type checks
    napi_value typeValue;
    napi_create_string_utf8(env, "ImageSource", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, jsThis, "_TYPE_", typeValue);
        return jsThis;
    } catch (const std::exception& e) {
        Logger::error("ImageSourceNAPI", "Failed to create ImageSource: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value ImageSourceNAPI::CreateInstance(napi_env env, mbgl::style::ImageSource* sourcePtr) {
    return mbgl::harmony::WrapExistingInstance(env, constructor, Destructor, "ImageSource",
                                sourcePtr ? new ImageSourceNAPI(sourcePtr) : nullptr);
}

DEFINE_SOURCE_GET_ID(ImageSourceNAPI)

napi_value ImageSourceNAPI::SetUrl(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    ImageSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        napi_throw_error(env, nullptr, "Invalid source wrapper");
        return nullptr;
    }
    
    auto* source = sourceNapi->getSource();
    if (!source) {
        napi_throw_error(env, nullptr, "Invalid source");
        return nullptr;
    }
    
    NapiArgs args(env, info);
    std::string url = args.GetString(0, "url");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    try {
        source->setURL(url);
        Logger::info("ImageSourceNAPI", "SetUrl: %s -> %s", sourceNapi->id.c_str(), url.c_str());
    } catch (const std::exception& e) {
        Logger::error("ImageSourceNAPI", "SetUrl failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
    }
    
    return nullptr;
}

napi_value ImageSourceNAPI::SetImage(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    ImageSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        napi_throw_error(env, nullptr, "Invalid source wrapper");
        return nullptr;
    }
    
    auto* source = sourceNapi->getSource();
    if (!source) {
        napi_throw_error(env, nullptr, "Invalid source");
        return nullptr;
    }
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "SetImage requires an image argument");
        return nullptr;
    }
    
    try {
        napi_value imageArg = args[0];

        // Shared Image/Bitmap ingestion (same dispatch as VideoSource::updateImage)
        auto payload = DecodeImageOrBitmap(env, imageArg, "SetImage requires an Image or Bitmap object");
        if (!payload) {
            return nullptr;
        }

        source->setImage(std::move(payload->image));

        if (payload->fromImageObject) {
            Logger::info("ImageSourceNAPI", "SetImage from Image object: %s -> %s",
                        sourceNapi->id.c_str(), payload->imageObjectName.c_str());
        } else {
            Logger::info("ImageSourceNAPI", "SetImage from Bitmap: %s", sourceNapi->id.c_str());
        }
    } catch (const std::exception& e) {
        Logger::error("ImageSourceNAPI", "SetImage failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
    
    return nullptr;
}

napi_value ImageSourceNAPI::SetCoordinates(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    ImageSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        napi_throw_error(env, nullptr, "Invalid source wrapper");
        return nullptr;
    }
    
    auto* source = sourceNapi->getSource();
    if (!source) {
        napi_throw_error(env, nullptr, "Invalid source");
        return nullptr;
    }
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "SetCoordinates requires coordinates argument");
        return nullptr;
    }
    
    // Parse the coordinates argument (four LatLng values)
    napi_value coordsValue = args[0];
    std::array<mbgl::LatLng, 4> coords;
    if (!ParseLatLngQuad(env, coordsValue, coords)) {
        // Keep the historical, failure-reason-specific error messages
        bool isArray = false;
        napi_is_array(env, coordsValue, &isArray);
        if (!isArray) {
            napi_throw_error(env, nullptr, "coordinates must be an array");
        } else {
            uint32_t arrayLength = 0;
            napi_get_array_length(env, coordsValue, &arrayLength);
            if (arrayLength != 4) {
                napi_throw_error(env, nullptr, "coordinates array must have exactly 4 elements");
            } else {
                napi_throw_error(env, nullptr, "Each coordinate must be a [lng, lat] array");
            }
        }
        return nullptr;
    }
    
    try {
        source->setCoordinates(coords);
        Logger::info("ImageSourceNAPI", "SetCoordinates: %s", sourceNapi->id.c_str());
    } catch (const std::exception& e) {
        Logger::error("ImageSourceNAPI", "SetCoordinates failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
    
    return nullptr;
}

} // namespace harmony
} // namespace mbgl

