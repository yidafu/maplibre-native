#include "icon_napi.hpp"
#include "utils/logger.h"
#include "napi/core/napi_args.hpp"
#include <multimedia/image_framework/image_pixel_map_napi.h>
#include <multimedia/image_framework/image_pixel_map_mdk.h>

namespace maplibre {
namespace harmony {

using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;

// Static member initialization
napi_ref IconNAPI::constructor = nullptr;

IconNAPI::IconNAPI(std::string id, int width, int height, float scale,
                   std::shared_ptr<mbgl::PremultipliedImage> image)
    : id(std::move(id)),
      width(width),
      height(height),
      scale(scale),
      image(std::move(image)) {
}

IconNAPI::~IconNAPI() {
    image.reset();
}

void IconNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    IconNAPI* icon = static_cast<IconNAPI*>(nativeObject);
    delete icon;
}

napi_value IconNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("IconNAPI", "Initializing Icon NAPI class");
    
    napi_property_descriptor properties[] = {
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getWidth", nullptr, GetWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getHeight", nullptr, GetHeight, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getScale", nullptr, GetScale, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "isReleased", nullptr, IsReleased, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "release", nullptr, Release, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "Icon", NAPI_AUTO_LENGTH, New, nullptr,
                                          sizeof(properties) / sizeof(properties[0]), 
                                          properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("IconNAPI", "Failed to define Icon class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("IconNAPI", "Failed to create reference to Icon constructor");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "Icon", cons);
    if (status != napi_ok) {
        Logger::error("IconNAPI", "Failed to export Icon class");
        return nullptr;
    }
    
    Logger::info("IconNAPI", "Icon NAPI class registered successfully");
    return exports;
}

napi_value IconNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    // Constructor signature: new Icon(id: string, pixelMap: PixelMap, scale?: number)
    if (args.Count() < 2) {
        Logger::error("IconNAPI", "Icon constructor requires at least 2 arguments (id, pixelMap)");
        napi_throw_error(env, nullptr, "Icon constructor requires at least 2 arguments (id, pixelMap)");
        return nullptr;
    }
    
    // Get icon ID
    std::string id = args.GetString(0, "id");
    if (args.HasError()) {
        Logger::error("IconNAPI", "Failed to get icon id");
        return nullptr;
    }
    
    // Get PixelMap object using NapiArgs
    napi_value pixelMapValue = args.GetObject(1, "pixelMap");
    if (args.HasError()) {
        Logger::error("IconNAPI", "Failed to get PixelMap argument");
        napi_throw_error(env, nullptr, "Second argument must be a PixelMap object");
        return nullptr;
    }
    
    // Get scale (optional, default 1.0)
    float scale = 1.0f;
    if (args.Count() >= 3) {
        scale = static_cast<float>(args.GetDouble(2, "scale"));
    }
    
    // Convert PixelMap to PremultipliedImage
    // Use OH_PixelMap APIs to read pixel data
    
    // Get the native PixelMap handle
    NativePixelMap* nativePixelMap = OH_PixelMap_InitNativePixelMap(env, pixelMapValue);
    if (!nativePixelMap) {
        Logger::error("IconNAPI", "Failed to get native PixelMap");
        napi_throw_error(env, nullptr, "Failed to get native PixelMap");
        return nullptr;
    }
    
    // Get image info
    OhosPixelMapInfos imageInfo;
    int32_t result = OH_PixelMap_GetImageInfo(nativePixelMap, &imageInfo);
    if (result != 0) {
        Logger::error("IconNAPI", "Failed to get PixelMap image info, error: %d", result);
        napi_throw_error(env, nullptr, "Failed to get PixelMap image info");
        return nullptr;
    }
    
    int width = imageInfo.width;
    int height = imageInfo.height;
    
    Logger::info("IconNAPI", "Converting PixelMap to PremultipliedImage: %dx%d", width, height);
    
    // Access pixel data
    void* pixelData = nullptr;
    result = OH_PixelMap_AccessPixels(nativePixelMap, &pixelData);
    if (result != 0 || !pixelData) {
        Logger::error("IconNAPI", "Failed to access PixelMap pixels, error: %d", result);
        napi_throw_error(env, nullptr, "Failed to access PixelMap pixels");
        return nullptr;
    }
    
    // Create PremultipliedImage and copy data
    auto image = std::make_shared<mbgl::PremultipliedImage>(
        mbgl::Size{static_cast<uint32_t>(width), static_cast<uint32_t>(height)}
    );
    
    size_t dataSize = width * height * 4; // RGBA
    std::memcpy(image->data.get(), pixelData, dataSize);
    
    // Unaccess pixels
    OH_PixelMap_UnAccessPixels(nativePixelMap);
    
    Logger::info("IconNAPI", "Icon created successfully: id=%s, size=%dx%d, scale=%f", 
                 id.c_str(), width, height, scale);
    
    // Create IconNAPI instance
    IconNAPI* icon = new IconNAPI(id, width, height, scale, image);
    
    // Wrap native object
    napi_status status = napi_wrap(env, thisVar, icon, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        Logger::error("IconNAPI", "Failed to wrap Icon object");
        delete icon;
        return nullptr;
    }
    
    return thisVar;
}

napi_value IconNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    IconNAPI* icon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&icon));
    
    if (!icon) {
        return nullptr;
    }
    
    napi_value result;
    napi_create_string_utf8(env, icon->id.c_str(), icon->id.length(), &result);
    return result;
}

napi_value IconNAPI::GetWidth(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    IconNAPI* icon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&icon));
    
    if (!icon) {
        return nullptr;
    }
    
    napi_value result;
    napi_create_int32(env, icon->width, &result);
    return result;
}

napi_value IconNAPI::GetHeight(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    IconNAPI* icon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&icon));
    
    if (!icon) {
        return nullptr;
    }
    
    napi_value result;
    napi_create_int32(env, icon->height, &result);
    return result;
}

napi_value IconNAPI::GetScale(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    IconNAPI* icon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&icon));
    
    if (!icon) {
        return nullptr;
    }
    
    napi_value result;
    napi_create_double(env, icon->scale, &result);
    return result;
}

napi_value IconNAPI::IsReleased(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    IconNAPI* icon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&icon));
    
    if (!icon) {
        napi_value result;
        napi_get_boolean(env, true, &result);
        return result;
    }
    
    napi_value result;
    napi_get_boolean(env, !icon->image, &result);
    return result;
}

napi_value IconNAPI::Release(napi_env env, napi_callback_info info) {
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);
    
    IconNAPI* icon = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&icon));
    
    if (!icon) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    if (icon->image) {
        icon->image.reset();
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

bool IconNAPI::IsIconObject(napi_env env, napi_value value) {
    napi_valuetype type;
    napi_typeof(env, value, &type);
    if (type != napi_object) {
        return false;
    }
    
    // Try to unwrap as IconNAPI
    IconNAPI* icon = nullptr;
    napi_status status = napi_unwrap(env, value, reinterpret_cast<void**>(&icon));
    return (status == napi_ok && icon != nullptr);
}

napi_value IconNAPI::CreateFromImage(napi_env env, 
                                      const std::string& id,
                                      std::shared_ptr<mbgl::PremultipliedImage> image,
                                      float scale) {
    if (!image) {
        Logger::error("IconNAPI", "Cannot create Icon from null image");
        napi_throw_error(env, nullptr, "Image is null");
        return nullptr;
    }
    
    int width = static_cast<int>(image->size.width);
    int height = static_cast<int>(image->size.height);
    
    Logger::info("IconNAPI", "Creating Icon from PremultipliedImage: id=%s, size=%dx%d, scale=%f",
                 id.c_str(), width, height, scale);
    
    // Get Icon constructor
    napi_value cons;
    napi_status status = napi_get_reference_value(env, constructor, &cons);
    if (status != napi_ok) {
        Logger::error("IconNAPI", "Failed to get Icon constructor reference");
        return nullptr;
    }
    
    // Create new Icon instance (empty constructor call)
    napi_value instance;
    status = napi_new_instance(env, cons, 0, nullptr, &instance);
    if (status != napi_ok) {
        Logger::error("IconNAPI", "Failed to create Icon instance");
        return nullptr;
    }
    
    // Create IconNAPI object
    IconNAPI* iconNapi = new IconNAPI(id, width, height, scale, image);
    
    // Wrap native object
    status = napi_wrap(env, instance, iconNapi, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        Logger::error("IconNAPI", "Failed to wrap Icon object");
        delete iconNapi;
        return nullptr;
    }
    
    Logger::info("IconNAPI", "Icon created successfully from PremultipliedImage: id=%s", id.c_str());
    return instance;
}

} // namespace harmony
} // namespace maplibre

