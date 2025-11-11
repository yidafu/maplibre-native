#include "image_source_napi.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "napi/bindings/image/image_napi.hpp"
#include "bitmap/bitmap_napi.hpp"
#include "utils/logger.h"
#include <mbgl/util/geo.hpp>

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

namespace maplibre {

using mbgl::harmony::napi::NapiArgs;
namespace harmony {

napi_ref ImageSourceNAPI::constructor = nullptr;

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
    
    napi_value cons;
    napi_status status = napi_define_class(env, "ImageSource", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("ImageSourceNAPI", "Failed to define ImageSource class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("ImageSourceNAPI", "Failed to create constructor reference");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "ImageSource", cons);
    if (status != napi_ok) {
        Logger::error("ImageSourceNAPI", "Failed to set ImageSource property");
        return nullptr;
    }
    
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
        std::array<mbgl::LatLng, 4> coords;
        
        if (napiArgs.Count() >= 2) {
            napi_value coordsValue = napiArgs.GetValue(1);
            bool isArray = false;
            napi_is_array(env, coordsValue, &isArray);
            
            if (isArray) {
                uint32_t arrayLength = 0;
                napi_get_array_length(env, coordsValue, &arrayLength);
                
                if (arrayLength == 4) {
                    for (uint32_t i = 0; i < 4; ++i) {
                        napi_value coordValue;
                        napi_get_element(env, coordsValue, i, &coordValue);
                        
                        // Each coord should be a [lng, lat] array
                        bool isCoordArray = false;
                        napi_is_array(env, coordValue, &isCoordArray);
                        
                        if (isCoordArray) {
                            napi_value lngValue, latValue;
                            napi_get_element(env, coordValue, 0, &lngValue);
                            napi_get_element(env, coordValue, 1, &latValue);
                            
                            double lng = 0.0, lat = 0.0;
                            napi_get_value_double(env, lngValue, &lng);
                            napi_get_value_double(env, latValue, &lat);
                            
                            coords[i] = mbgl::LatLng{lat, lng};
                        }
                    }
                } else {
                    Logger::warn("ImageSourceNAPI", "Coordinates array must have 4 elements, using default");
                    coords = {{
                        mbgl::LatLng{0, 0}, mbgl::LatLng{0, 1},
                        mbgl::LatLng{1, 1}, mbgl::LatLng{1, 0}
                    }};
                }
            } else {
                Logger::warn("ImageSourceNAPI", "Coordinates must be an array, using default");
                coords = {{
                    mbgl::LatLng{0, 0}, mbgl::LatLng{0, 1},
                    mbgl::LatLng{1, 1}, mbgl::LatLng{1, 0}
                }};
            }
        } else {
            // Fallback to default coordinates
            coords = {{
                mbgl::LatLng{0, 0}, mbgl::LatLng{0, 1},
                mbgl::LatLng{1, 1}, mbgl::LatLng{1, 0}
            }};
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
    if (!sourcePtr) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Retrieve the constructor reference
    napi_value cons;
    napi_status status = napi_get_reference_value(env, constructor, &cons);
    if (status != napi_ok) {
        Logger::error("ImageSourceNAPI", "Failed to get constructor reference");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Create an empty object and assign its prototype (avoid invoking the JS constructor)
    napi_value instance;
    status = napi_create_object(env, &instance);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to create object");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Retrieve the constructor prototype
    napi_value prototype;
    status = napi_get_named_property(env, cons, "prototype", &prototype);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to get prototype");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Assign the object's prototype
    status = napi_set_named_property(env, instance, "__proto__", prototype);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to set prototype");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Create the NAPI wrapper using the WeakPtr constructor
    ImageSourceNAPI* napiObj = new ImageSourceNAPI(sourcePtr);
    
    // Wrap the native pointer in the JS object
    status = napi_wrap(env, instance, napiObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete napiObj;
        Logger::error("ImageSourceNAPI", "Failed to wrap instance");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Add the _TYPE_ property
    napi_value typeValue;
    napi_create_string_utf8(env, "ImageSource", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, instance, "_TYPE_", typeValue);
    
    return instance;
}

napi_value ImageSourceNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    ImageSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        return CreateStringValue(env, "");
    }
    
    return CreateStringValue(env, sourceNapi->id);
}

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
        
        // Check if it's an Image NAPI object
        if (ImageNAPI::IsImageObject(env, imageArg)) {
            // Unwrap ImageNAPI and get the image data
            ImageNAPI* imageNapi = ImageNAPI::Unwrap(env, imageArg);
            if (!imageNapi) {
                napi_throw_error(env, nullptr, "Failed to unwrap Image object");
                return nullptr;
            }
            
            // Convert to style::Image and get the PremultipliedImage
            auto styleImage = imageNapi->toStyleImage();
            source->setImage(styleImage->getImage().clone());
            
            Logger::info("ImageSourceNAPI", "SetImage from Image object: %s -> %s", 
                        sourceNapi->id.c_str(), imageNapi->getName().c_str());
        }
        // Check if it's a Bitmap object
        else if (mbgl::harmony::BitmapNAPI::IsBitmapObject(env, imageArg)) {
            // Get Bitmap data
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
            
            Logger::info("ImageSourceNAPI", "SetImage from Bitmap: %s", sourceNapi->id.c_str());
        }
        else {
            napi_throw_error(env, nullptr, "SetImage requires an Image or Bitmap object");
            return nullptr;
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
    std::array<mbgl::LatLng, 4> coords;
    
    napi_value coordsValue = args[0];
    bool isArray = false;
    napi_is_array(env, coordsValue, &isArray);
    
    if (!isArray) {
        napi_throw_error(env, nullptr, "coordinates must be an array");
        return nullptr;
    }
    
    uint32_t arrayLength = 0;
    napi_get_array_length(env, coordsValue, &arrayLength);
    
    if (arrayLength != 4) {
        napi_throw_error(env, nullptr, "coordinates array must have exactly 4 elements");
        return nullptr;
    }
    
    for (uint32_t i = 0; i < 4; ++i) {
        napi_value coordValue;
        napi_get_element(env, coordsValue, i, &coordValue);
        
        // Each coord should be a [lng, lat] array
        bool isCoordArray = false;
        napi_is_array(env, coordValue, &isCoordArray);
        
        if (!isCoordArray) {
            napi_throw_error(env, nullptr, "Each coordinate must be a [lng, lat] array");
            return nullptr;
        }
        
        napi_value lngValue, latValue;
        napi_get_element(env, coordValue, 0, &lngValue);
        napi_get_element(env, coordValue, 1, &latValue);
        
        double lng = 0.0, lat = 0.0;
        napi_get_value_double(env, lngValue, &lng);
        napi_get_value_double(env, latValue, &lat);
        
        coords[i] = mbgl::LatLng{lat, lng};
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
} // namespace maplibre

