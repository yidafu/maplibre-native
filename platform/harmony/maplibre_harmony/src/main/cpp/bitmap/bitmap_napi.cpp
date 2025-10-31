#include "bitmap_napi.hpp"
#include "utils/logger.h"
#include "napi/core/napi_args.hpp"

using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;

namespace mbgl {
namespace harmony {

napi_ref BitmapNAPI::constructor = nullptr;

BitmapNAPI::BitmapNAPI(std::shared_ptr<mbgl::PremultipliedImage> img) 
    : image(img) {
}

BitmapNAPI::~BitmapNAPI() {
    Logger::info("BitmapNAPI", "Bitmap destroyed");
}

napi_value BitmapNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("BitmapNAPI", "Initializing Bitmap NAPI class");
    
    napi_property_descriptor properties[] = {
        { "width", nullptr, nullptr, GetWidth, nullptr, nullptr, napi_default, nullptr },
        { "height", nullptr, nullptr, GetHeight, nullptr, nullptr, napi_default, nullptr },
        { "getPixels", nullptr, GetPixels, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getConfig", nullptr, GetConfig, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "isMutable", nullptr, IsMutable, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value bitmapClass;
    napi_status status = napi_define_class(
        env, "Bitmap", NAPI_AUTO_LENGTH,
        New,
        nullptr,
        sizeof(properties) / sizeof(properties[0]),
        properties,
        &bitmapClass
    );
    
    if (status != napi_ok) {
        Logger::error("BitmapNAPI", "Failed to define Bitmap class");
        return nullptr;
    }
    
    status = napi_create_reference(env, bitmapClass, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("BitmapNAPI", "Failed to create constructor reference");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "Bitmap", bitmapClass);
    if (status != napi_ok) {
        Logger::error("BitmapNAPI", "Failed to export Bitmap class");
        return nullptr;
    }
    
    Logger::info("BitmapNAPI", "Bitmap NAPI class registered successfully");
    return exports;
}

napi_value BitmapNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    napi_value thisObj = args.This();
    
    // Create empty bitmap (for now, actual creation is done via CreateFromImage)
    auto image = std::make_shared<mbgl::PremultipliedImage>(mbgl::Size{0, 0});
    BitmapNAPI* bitmap = new BitmapNAPI(image);
    
    napi_status status = napi_wrap(env, thisObj, bitmap, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete bitmap;
        Logger::error("BitmapNAPI", "Failed to wrap native object");
        return nullptr;
    }
    
    return thisObj;
}

void BitmapNAPI::Destructor(napi_env env, void* nativeObject, void* hint) {
    BitmapNAPI* bitmap = static_cast<BitmapNAPI*>(nativeObject);
    delete bitmap;
}

napi_value BitmapNAPI::GetWidth(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    BitmapNAPI* bitmap = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&bitmap)) != napi_ok) {
        Logger::error("BitmapNAPI", "GetWidth: Failed to unwrap");
        return args.Undefined();
    }
    
    if (!bitmap->image) {
        return args.Undefined();
    }
    
    napi_value result;
    napi_create_uint32(env, bitmap->image->size.width, &result);
    return result;
}

napi_value BitmapNAPI::GetHeight(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    BitmapNAPI* bitmap = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&bitmap)) != napi_ok) {
        Logger::error("BitmapNAPI", "GetHeight: Failed to unwrap");
        return args.Undefined();
    }
    
    if (!bitmap->image) {
        return args.Undefined();
    }
    
    napi_value result;
    napi_create_uint32(env, bitmap->image->size.height, &result);
    return result;
}

napi_value BitmapNAPI::GetPixels(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    BitmapNAPI* bitmap = nullptr;
    if (napi_unwrap(env, args.This(), reinterpret_cast<void**>(&bitmap)) != napi_ok) {
        Logger::error("BitmapNAPI", "GetPixels: Failed to unwrap");
        return args.Undefined();
    }
    
    if (!bitmap->image || !bitmap->image->data) {
        return args.Undefined();
    }
    
    // Return ArrayBuffer with pixel data
    size_t byteLength = bitmap->image->bytes();
    void* data = nullptr;
    napi_value arrayBuffer;
    
    napi_status status = napi_create_arraybuffer(env, byteLength, &data, &arrayBuffer);
    if (status != napi_ok) {
        Logger::error("BitmapNAPI", "GetPixels: Failed to create ArrayBuffer");
        return args.Undefined();
    }
    
    // Copy pixel data
    std::memcpy(data, bitmap->image->data.get(), byteLength);
    
    return arrayBuffer;
}

napi_value BitmapNAPI::GetConfig(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Return "ARGB_8888" config (standard for RGBA premultiplied)
    napi_value result;
    napi_create_string_utf8(env, "ARGB_8888", NAPI_AUTO_LENGTH, &result);
    return result;
}

napi_value BitmapNAPI::IsMutable(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Return false - our bitmaps are immutable
    napi_value result;
    napi_get_boolean(env, false, &result);
    return result;
}

napi_value BitmapNAPI::CreateFromImage(napi_env env,
                                       const std::string& id,
                                       std::shared_ptr<mbgl::PremultipliedImage> image) {
    if (!constructor) {
        Logger::error("BitmapNAPI", "CreateFromImage: Constructor not initialized");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    napi_value constructorValue;
    napi_status status = napi_get_reference_value(env, constructor, &constructorValue);
    if (status != napi_ok) {
        Logger::error("BitmapNAPI", "CreateFromImage: Failed to get constructor");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // Create new instance
    napi_value instance;
    status = napi_new_instance(env, constructorValue, 0, nullptr, &instance);
    if (status != napi_ok) {
        Logger::error("BitmapNAPI", "CreateFromImage: Failed to create instance");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // Get wrapped object and set the image
    BitmapNAPI* bitmap = nullptr;
    status = napi_unwrap(env, instance, reinterpret_cast<void**>(&bitmap));
    if (status != napi_ok) {
        Logger::error("BitmapNAPI", "CreateFromImage: Failed to unwrap");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    bitmap->image = image;
    bitmap->id = id;
    
    Logger::info("BitmapNAPI", "Created Bitmap: %ux%u, id=%s", 
                image->size.width, image->size.height, id.c_str());
    
    return instance;
}

bool BitmapNAPI::IsBitmapObject(napi_env env, napi_value value) {
    if (!constructor) {
        return false;
    }
    
    napi_value cons;
    napi_status status = napi_get_reference_value(env, constructor, &cons);
    if (status != napi_ok) {
        return false;
    }
    
    bool isInstance = false;
    status = napi_instanceof(env, value, cons, &isInstance);
    return (status == napi_ok) && isInstance;
}

BitmapNAPI* BitmapNAPI::Unwrap(napi_env env, napi_value value) {
    BitmapNAPI* bitmap = nullptr;
    napi_status status = napi_unwrap(env, value, reinterpret_cast<void**>(&bitmap));
    return (status == napi_ok) ? bitmap : nullptr;
}

} // namespace harmony
} // namespace mbgl

