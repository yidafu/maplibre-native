#include "style_napi.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "napi/bindings/image/image_napi.hpp"
#include "utils/logger.h"
#include <mbgl/style/style.hpp>
#include <mbgl/style/image.hpp>
#include <mbgl/style/light.hpp>
#include <mbgl/style/transition_options.hpp>
#include <mbgl/util/image.hpp>
#include <vector>

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

namespace maplibre {
namespace harmony {

// ==================== Image management ====================

napi_value StyleNAPI::AddImage(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(1);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    size_t argc = napiArgs.Count();
    napi_value jsThis = napiArgs.This();

    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));

    if (!style || !style->map) {
        napi_throw_error(env, nullptr, "Invalid style instance");
        return nullptr;
    }

    napi_value firstArg = napiArgs.GetValue(0);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    // Check if first argument is an Image object
    if (ImageNAPI::IsImageObject(env, firstArg)) {
        ImageNAPI* imageNapi = ImageNAPI::Unwrap(env, firstArg);
        if (!imageNapi) {
            napi_throw_error(env, nullptr, "Failed to unwrap Image object");
            return nullptr;
        }

        try {
            auto styleImage = imageNapi->toStyleImage();
            std::string imageName = styleImage->getID();

            style->map->getStyle().addImage(std::move(styleImage));
            style->images[imageName] = true;

            Logger::info("StyleNAPI", "AddImage from Image object: %s (%dx%d)",
                         imageName.c_str(), imageNapi->getWidth(), imageNapi->getHeight());
        } catch (const std::exception& e) {
            Logger::error("StyleNAPI", "AddImage from Image object failed: %s", e.what());
            napi_throw_error(env, nullptr, e.what());
            return nullptr;
        }

        return napiArgs.Undefined();
    }

    if (argc < 5) {
        napi_throw_error(env, nullptr, "AddImage requires at least 5 arguments: name, buffer, width, height, pixelRatio");
        return nullptr;
    }

    std::string imageName = GetStringFromValue(env, firstArg);

    napi_value dataValue = napiArgs.GetValue(1);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    void* data = nullptr;
    size_t byteLength = 0;
    napi_valuetype valueType;
    napi_typeof(env, dataValue, &valueType);

    if (valueType == napi_object) {
        napi_value arrayBuffer;
        size_t byteOffset;
        napi_status status = napi_get_typedarray_info(env, dataValue, nullptr, &byteLength, &data, &arrayBuffer, &byteOffset);
        if (status != napi_ok) {
            status = napi_get_arraybuffer_info(env, dataValue, &data, &byteLength);
            if (status != napi_ok) {
                napi_throw_error(env, nullptr, "Second argument must be ArrayBuffer or TypedArray");
                return nullptr;
            }
        }
    } else {
        napi_throw_error(env, nullptr, "Second argument must be ArrayBuffer or TypedArray");
        return nullptr;
    }

    uint32_t width = napiArgs.GetUint32(2, "width");
    uint32_t height = napiArgs.GetUint32(3, "height");
    if (napiArgs.HasError()) {
        return nullptr;
    }

    if (width == 0 || height == 0) {
        napi_throw_error(env, nullptr, "Width and height must be greater than 0");
        return nullptr;
    }

    double pixelRatio = napiArgs.GetDouble(4, "pixelRatio");
    if (napiArgs.HasError()) {
        return nullptr;
    }

    bool sdf = false;
    if (argc >= 6) {
        sdf = napiArgs.GetBool(5, "sdf");
        if (napiArgs.HasError()) {
            return nullptr;
        }
    }

    if (byteLength != width * height * 4) {
        Logger::error("StyleNAPI", "AddImage: data size mismatch (expected: %d, got: %zu)", width * height * 4, byteLength);
        napi_throw_error(env, nullptr, "Image data size does not match width * height * 4");
        return nullptr;
    }

    try {
        mbgl::PremultipliedImage premultipliedImage({width, height});
        std::memcpy(premultipliedImage.data.get(), data, byteLength);

        auto image = std::make_unique<mbgl::style::Image>(
            imageName,
            std::move(premultipliedImage),
            static_cast<float>(pixelRatio),
            sdf
        );

        style->map->getStyle().addImage(std::move(image));
        style->images[imageName] = true;

        Logger::info("StyleNAPI", "AddImage: %s (%dx%d, ratio: %.2f, sdf: %s)",
                     imageName.c_str(), width, height, pixelRatio, sdf ? "true" : "false");
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "AddImage failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }

    return napiArgs.Undefined();
}

napi_value StyleNAPI::RemoveImage(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(1);
    if (napiArgs.HasError()) {
        return CreateBoolValue(env, false);
    }

    napi_value jsThis = napiArgs.This();
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));

    if (!style || !style->map) {
        return CreateBoolValue(env, false);
    }

    std::string imageName = GetStringFromValue(env, napiArgs.GetValue(0));
    if (napiArgs.HasError()) {
        return CreateBoolValue(env, false);
    }

    try {
        style->map->getStyle().removeImage(imageName);
        style->images.erase(imageName);
        Logger::info("StyleNAPI", "RemoveImage: %s", imageName.c_str());
        return CreateBoolValue(env, true);
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "RemoveImage failed: %s", e.what());
        return CreateBoolValue(env, false);
    }
}

napi_value StyleNAPI::GetImage(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(1);
    if (napiArgs.HasError()) {
        return napiArgs.Null();
    }

    napi_value jsThis = napiArgs.This();
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));

    if (!style || !style->map) {
        return napiArgs.Null();
    }

    std::string imageName = GetStringFromValue(env, napiArgs.GetValue(0));
    if (napiArgs.HasError()) {
        return napiArgs.Null();
    }

    try {
        auto imageOpt = style->map->getStyle().getImage(imageName);
        if (!imageOpt) {
            return napiArgs.Null();
        }

        const mbgl::style::Image& image = *imageOpt;
        const mbgl::PremultipliedImage& premultipliedImage = image.getImage();
        uint32_t width = premultipliedImage.size.width;
        uint32_t height = premultipliedImage.size.height;
        size_t dataSize = width * height * 4;

        void* data = nullptr;
        napi_value arrayBuffer;
        napi_create_arraybuffer(env, dataSize, &data, &arrayBuffer);
        std::memcpy(data, premultipliedImage.data.get(), dataSize);

        napi_value result;
        napi_create_object(env, &result);

        napi_value nameValue;
        napi_create_string_utf8(env, imageName.c_str(), NAPI_AUTO_LENGTH, &nameValue);
        napi_set_named_property(env, result, "name", nameValue);

        napi_value widthValue;
        napi_create_uint32(env, width, &widthValue);
        napi_set_named_property(env, result, "width", widthValue);

        napi_value heightValue;
        napi_create_uint32(env, height, &heightValue);
        napi_set_named_property(env, result, "height", heightValue);

        napi_value pixelRatioValue;
        napi_create_double(env, image.getPixelRatio(), &pixelRatioValue);
        napi_set_named_property(env, result, "pixelRatio", pixelRatioValue);

        napi_value sdfValue;
        napi_get_boolean(env, image.isSdf(), &sdfValue);
        napi_set_named_property(env, result, "sdf", sdfValue);

        napi_set_named_property(env, result, "data", arrayBuffer);

        Logger::info("StyleNAPI", "GetImage: %s (%dx%d)", imageName.c_str(), width, height);
        return result;
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "GetImage failed: %s", e.what());
        return napiArgs.Null();
    }
}

// ==================== Async Image Loading ====================

// Struct to hold async work data
struct AsyncImageData {
    napi_env env;
    napi_ref thisRef;
    napi_deferred deferred;
    
    // Image data
    std::string imageName;
    uint32_t width;
    uint32_t height;
    float pixelRatio;
    bool sdf;
    std::shared_ptr<std::vector<uint8_t>> imageData;
    std::optional<std::vector<mbgl::style::ImageStretches::value_type>> stretchX;
    std::optional<std::vector<mbgl::style::ImageStretches::value_type>> stretchY;
    std::optional<mbgl::style::ImageContent> content;
    
    // Result
    std::string errorMessage;
    bool success;
};

// Async execute callback - runs in worker thread
void AddImageAsyncExecute(napi_env env, void* data) {
    AsyncImageData* asyncData = static_cast<AsyncImageData*>(data);
    
    // Image data is already prepared, just mark as success
    // Actual processing happens in the complete callback
    asyncData->success = true;
}

// Async complete callback - runs in main thread
void AddImageAsyncComplete(napi_env env, napi_status status, void* data) {
    AsyncImageData* asyncData = static_cast<AsyncImageData*>(data);
    
    napi_value jsThis;
    napi_get_reference_value(env, asyncData->thisRef, &jsThis);
    
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (status == napi_ok && asyncData->success && style && style->getMap()) {
        try {
            // Create PremultipliedImage
            mbgl::PremultipliedImage premultipliedImage({asyncData->width, asyncData->height});
            std::memcpy(premultipliedImage.data.get(), asyncData->imageData->data(), asyncData->imageData->size());
            
            // Convert stretchX and stretchY
            mbgl::style::ImageStretches imageStretchesX;
            if (asyncData->stretchX) {
                imageStretchesX = asyncData->stretchX.value();
            }
            
            mbgl::style::ImageStretches imageStretchesY;
            if (asyncData->stretchY) {
                imageStretchesY = asyncData->stretchY.value();
            }
            
            // Create style::Image
            std::unique_ptr<mbgl::style::Image> image;
            if (asyncData->content) {
                image = std::make_unique<mbgl::style::Image>(
                    asyncData->imageName,
                    std::move(premultipliedImage),
                    asyncData->pixelRatio,
                    asyncData->sdf,
                    imageStretchesX,
                    imageStretchesY,
                    asyncData->content.value()
                );
            } else {
                image = std::make_unique<mbgl::style::Image>(
                    asyncData->imageName,
                    std::move(premultipliedImage),
                    asyncData->pixelRatio,
                    asyncData->sdf,
                    imageStretchesX,
                    imageStretchesY
                );
            }
            
            // Add to style
            style->getMap()->getStyle().addImage(std::move(image));
            style->images[asyncData->imageName] = true;
            
            Logger::info("StyleNAPI", "AddImageAsync completed: %s (%dx%d)", 
                        asyncData->imageName.c_str(), asyncData->width, asyncData->height);
            
            // Resolve promise
            napi_value undefined;
            napi_get_undefined(env, &undefined);
            napi_resolve_deferred(env, asyncData->deferred, undefined);
        } catch (const std::exception& e) {
            Logger::error("StyleNAPI", "AddImageAsync failed: %s", e.what());
            napi_value errorMsg;
            napi_create_string_utf8(env, e.what(), NAPI_AUTO_LENGTH, &errorMsg);
            napi_reject_deferred(env, asyncData->deferred, errorMsg);
        }
    } else {
        // Reject promise
        napi_value errorMsg;
        napi_create_string_utf8(env, asyncData->errorMessage.empty() ? 
                               "Failed to add image asynchronously" : asyncData->errorMessage.c_str(), 
                               NAPI_AUTO_LENGTH, &errorMsg);
        napi_reject_deferred(env, asyncData->deferred, errorMsg);
    }
    
    // Cleanup
    napi_delete_reference(env, asyncData->thisRef);
    delete asyncData;
}

napi_value StyleNAPI::AddImageAsync(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(1);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    size_t argc = napiArgs.Count();
    std::vector<napi_value> argsVec(argc);
    for (size_t i = 0; i < argc; ++i) {
        argsVec[i] = napiArgs.GetValue(i);
        if (napiArgs.HasError()) {
            return nullptr;
        }
    }
    napi_value* args = argsVec.data();

    napi_value jsThis = napiArgs.This();
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));

    if (!style || !style->getMap()) {
        napi_throw_error(env, nullptr, "Invalid style instance");
        return nullptr;
    }
    
    // Create promise
    napi_value promise;
    napi_deferred deferred;
    napi_create_promise(env, &deferred, &promise);
    
    try {
        // Prepare async data
        AsyncImageData* asyncData = new AsyncImageData();
        asyncData->env = env;
        asyncData->deferred = deferred;
        asyncData->success = false;
        
        // Create reference to this
        napi_create_reference(env, jsThis, 1, &asyncData->thisRef);
        
        // Check if first argument is an Image object
        if (ImageNAPI::IsImageObject(env, args[0])) {
            // New way: Accept Image NAPI object
            ImageNAPI* imageNapi = ImageNAPI::Unwrap(env, args[0]);
            if (!imageNapi) {
                delete asyncData;
                napi_throw_error(env, nullptr, "Failed to unwrap Image object");
                return nullptr;
            }
            
            asyncData->imageName = imageNapi->getName();
            asyncData->width = imageNapi->getWidth();
            asyncData->height = imageNapi->getHeight();
            asyncData->pixelRatio = imageNapi->getPixelRatio();
            asyncData->sdf = imageNapi->isSdf();
            // Get image data from ImageNAPI (need to expose this)
            auto styleImage = imageNapi->toStyleImage();
            
            // Copy data
            const auto& srcImage = styleImage->getImage();
            asyncData->imageData = std::make_shared<std::vector<uint8_t>>(
                srcImage.data.get(), 
                srcImage.data.get() + srcImage.bytes()
            );
            
        } else {
            // Old way: Accept raw parameters
            if (argc < 5) {
                delete asyncData;
                napi_throw_error(env, nullptr, "AddImageAsync requires at least 5 arguments");
                return nullptr;
            }
            
            // Parse arguments (same as AddImage)
            asyncData->imageName = GetStringFromValue(env, args[0]);
            
            // Get image data
            void* data = nullptr;
            size_t byteLength = 0;
            napi_valuetype valueType;
            napi_typeof(env, args[1], &valueType);
            
            if (valueType == napi_object) {
                napi_value arrayBuffer;
                size_t byteOffset;
                napi_status status = napi_get_typedarray_info(env, args[1], nullptr, &byteLength, &data, &arrayBuffer, &byteOffset);
                if (status != napi_ok) {
                    status = napi_get_arraybuffer_info(env, args[1], &data, &byteLength);
                    if (status != napi_ok) {
                        delete asyncData;
                        napi_throw_error(env, nullptr, "Second argument must be ArrayBuffer or TypedArray");
                        return nullptr;
                    }
                }
            } else {
                delete asyncData;
                napi_throw_error(env, nullptr, "Second argument must be ArrayBuffer or TypedArray");
                return nullptr;
            }
            
            napi_get_value_uint32(env, args[2], &asyncData->width);
            napi_get_value_uint32(env, args[3], &asyncData->height);
            
            double pixelRatio = 1.0;
            napi_get_value_double(env, args[4], &pixelRatio);
            asyncData->pixelRatio = static_cast<float>(pixelRatio);
            
            asyncData->sdf = false;
            if (argc >= 6) {
                napi_get_value_bool(env, args[5], &asyncData->sdf);
            }
            
            // Verify data size
            if (byteLength != asyncData->width * asyncData->height * 4) {
                delete asyncData;
                napi_throw_error(env, nullptr, "Image data size does not match width * height * 4");
                return nullptr;
            }
            
            // Copy data
            asyncData->imageData = std::make_shared<std::vector<uint8_t>>(
                static_cast<uint8_t*>(data),
                static_cast<uint8_t*>(data) + byteLength
            );
        }
        
        // Create async work
        napi_value resourceName;
        napi_create_string_utf8(env, "AddImageAsync", NAPI_AUTO_LENGTH, &resourceName);
        
        napi_async_work work;
        napi_status status = napi_create_async_work(
            env,
            nullptr,
            resourceName,
            AddImageAsyncExecute,
            AddImageAsyncComplete,
            asyncData,
            &work
        );
        
        if (status != napi_ok) {
            delete asyncData;
            napi_throw_error(env, nullptr, "Failed to create async work");
            return nullptr;
        }
        
        status = napi_queue_async_work(env, work);
        if (status != napi_ok) {
            napi_delete_async_work(env, work);
            delete asyncData;
            napi_throw_error(env, nullptr, "Failed to queue async work");
            return nullptr;
        }
        
        return promise;
        
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "AddImageAsync setup failed: %s", e.what());
        napi_value errorMsg;
        napi_create_string_utf8(env, e.what(), NAPI_AUTO_LENGTH, &errorMsg);
        napi_reject_deferred(env, deferred, errorMsg);
        return promise;
    }
}

// Struct for batch async images
struct AsyncImagesData {
    napi_env env;
    napi_ref thisRef;
    napi_deferred deferred;
    
    // Multiple images
    std::vector<std::unique_ptr<mbgl::style::Image>> images;
    std::vector<std::string> imageNames;
    
    // Result
    std::string errorMessage;
    bool success;
};

void AddImagesAsyncExecute(napi_env env, void* data) {
    AsyncImagesData* asyncData = static_cast<AsyncImagesData*>(data);
    asyncData->success = true;
}

void AddImagesAsyncComplete(napi_env env, napi_status status, void* data) {
    AsyncImagesData* asyncData = static_cast<AsyncImagesData*>(data);
    
    napi_value jsThis;
    napi_get_reference_value(env, asyncData->thisRef, &jsThis);
    
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (status == napi_ok && asyncData->success && style && style->getMap()) {
        try {
            // Add all images to style
            for (size_t i = 0; i < asyncData->images.size(); ++i) {
                std::string imageName = asyncData->imageNames[i];
                style->getMap()->getStyle().addImage(std::move(asyncData->images[i]));
                style->images[imageName] = true;
            }
            
            Logger::info("StyleNAPI", "AddImagesAsync completed: %zu images", asyncData->images.size());
            
            // Resolve promise
            napi_value undefined;
            napi_get_undefined(env, &undefined);
            napi_resolve_deferred(env, asyncData->deferred, undefined);
        } catch (const std::exception& e) {
            Logger::error("StyleNAPI", "AddImagesAsync failed: %s", e.what());
            napi_value errorMsg;
            napi_create_string_utf8(env, e.what(), NAPI_AUTO_LENGTH, &errorMsg);
            napi_reject_deferred(env, asyncData->deferred, errorMsg);
        }
    } else {
        napi_value errorMsg;
        napi_create_string_utf8(env, asyncData->errorMessage.empty() ? 
                               "Failed to add images asynchronously" : asyncData->errorMessage.c_str(), 
                               NAPI_AUTO_LENGTH, &errorMsg);
        napi_reject_deferred(env, asyncData->deferred, errorMsg);
    }
    
    // Cleanup
    napi_delete_reference(env, asyncData->thisRef);
    delete asyncData;
}

napi_value StyleNAPI::AddImagesAsync(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(1);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value jsThis = napiArgs.This();
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));

    if (!style || !style->getMap()) {
        napi_throw_error(env, nullptr, "Invalid style instance");
        return nullptr;
    }

    napi_value imagesArray = napiArgs.GetArray(0, "images");
    if (napiArgs.HasError()) {
        return nullptr;
    }
    
    // Create promise
    napi_value promise;
    napi_deferred deferred;
    napi_create_promise(env, &deferred, &promise);
    
    try {
        uint32_t arrayLength = 0;
        napi_get_array_length(env, imagesArray, &arrayLength);
        
        if (arrayLength == 0) {
            // Empty array, resolve immediately
            napi_value undefined;
            napi_get_undefined(env, &undefined);
            napi_resolve_deferred(env, deferred, undefined);
            return promise;
        }
        
        // Prepare async data
        AsyncImagesData* asyncData = new AsyncImagesData();
        asyncData->env = env;
        asyncData->deferred = deferred;
        asyncData->success = false;
        
        napi_create_reference(env, jsThis, 1, &asyncData->thisRef);
        
        // Parse all images
        for (uint32_t i = 0; i < arrayLength; ++i) {
            napi_value imageValue;
            napi_get_element(env, imagesArray, i, &imageValue);
            
            if (!ImageNAPI::IsImageObject(env, imageValue)) {
                delete asyncData;
                napi_throw_error(env, nullptr, "All array elements must be Image objects");
                return nullptr;
            }
            
            ImageNAPI* imageNapi = ImageNAPI::Unwrap(env, imageValue);
            if (!imageNapi) {
                delete asyncData;
                napi_throw_error(env, nullptr, "Failed to unwrap Image object");
                return nullptr;
            }
            
            // Convert to style::Image
            auto styleImage = imageNapi->toStyleImage();
            std::string imageName = styleImage->getID();
            
            asyncData->images.push_back(std::move(styleImage));
            asyncData->imageNames.push_back(imageName);
        }
        
        // Create async work
        napi_value resourceName;
        napi_create_string_utf8(env, "AddImagesAsync", NAPI_AUTO_LENGTH, &resourceName);
        
        napi_async_work work;
        napi_status status = napi_create_async_work(
            env,
            nullptr,
            resourceName,
            AddImagesAsyncExecute,
            AddImagesAsyncComplete,
            asyncData,
            &work
        );
        
        if (status != napi_ok) {
            delete asyncData;
            napi_throw_error(env, nullptr, "Failed to create async work");
            return nullptr;
        }
        
        status = napi_queue_async_work(env, work);
        if (status != napi_ok) {
            napi_delete_async_work(env, work);
            delete asyncData;
            napi_throw_error(env, nullptr, "Failed to queue async work");
            return nullptr;
        }
        
        return promise;
        
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "AddImagesAsync setup failed: %s", e.what());
        napi_value errorMsg;
        napi_create_string_utf8(env, e.what(), NAPI_AUTO_LENGTH, &errorMsg);
        napi_reject_deferred(env, deferred, errorMsg);
        return promise;
    }
}

// ==================== Light & Transition ====================

napi_value StyleNAPI::GetLight(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value jsThis = napiArgs.This();
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (!style || !style->map) {
        return napiArgs.Null();
    }
    
    try {
        const mbgl::style::Light* light = style->map->getStyle().getLight();
        if (!light) {
            return napiArgs.Null();
        }
        
        // Create the return object
        napi_value result;
        napi_create_object(env, &result);
        
        // Note: retrieving Light properties is involved and should use the conversion API
        // This implementation returns only basic information for now
        Logger::info("StyleNAPI", "GetLight called");
        
        // TODO: fully convert Light properties
        // Reference Android: platform/android/MapLibreAndroid/src/cpp/style/light.cpp
        
        return result;
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "GetLight failed: %s", e.what());
        return napiArgs.Null();
    }
}

napi_value StyleNAPI::SetLight(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(1);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value jsThis = napiArgs.This();
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));

    if (!style || !style->map) {
        napi_throw_error(env, nullptr, "Invalid style instance");
        return nullptr;
    }

    napi_value lightOptions = napiArgs.GetObject(0, "light");
    if (napiArgs.HasError()) {
        return nullptr;
    }
    
    try {
        // Create a new Light object
        // TODO: parse the light options object and apply every property
        // Reference Android: platform/android/MapLibreAndroid/src/cpp/style/light.cpp
        
        Logger::info("StyleNAPI", "SetLight called (implementation incomplete)");
        Logger::warn("StyleNAPI", "SetLight: Full light property parsing not yet implemented");

        (void)lightOptions; // suppress unused warning until fully implemented

        return napiArgs.Undefined();
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "SetLight failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value StyleNAPI::GetTransition(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value jsThis = napiArgs.This();
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (!style || !style->map) {
        return napiArgs.Null();
    }
    
    // TODO: getTransition is not available in mbgl::style::Style
    // Returning default transition options
    Logger::warn("StyleNAPI", "GetTransition: Not implemented - returning default values");
    
    napi_value result;
    napi_create_object(env, &result);
    
    // Return the default values
    napi_value durationValue;
    napi_create_int64(env, 300, &durationValue);  // default 300 ms
    napi_set_named_property(env, result, "duration", durationValue);
    
    napi_value delayValue;
    napi_create_int64(env, 0, &delayValue);
    napi_set_named_property(env, result, "delay", delayValue);
    
    return result;
}

napi_value StyleNAPI::SetTransition(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(1);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value jsThis = napiArgs.This();
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));

    if (!style || !style->map) {
        napi_throw_error(env, nullptr, "Invalid style instance");
        return nullptr;
    }

    napi_value transitionOptions = napiArgs.GetObject(0, "transition");
    if (napiArgs.HasError()) {
        return nullptr;
    }
    
    // TODO: setTransition is not available in mbgl::style::Style
    // Logging the attempted transition but not applying it
    Logger::warn("StyleNAPI", "SetTransition: Not implemented - transition settings not applied");
    
    // Parse arguments to record logging details
    napi_value durationValue;
    napi_status status = napi_get_named_property(env, transitionOptions, "duration", &durationValue);
    int64_t duration = 300;  // default value
    if (status == napi_ok) {
        napi_valuetype valueType;
        napi_typeof(env, durationValue, &valueType);
        if (valueType == napi_number) {
            napi_get_value_int64(env, durationValue, &duration);
        }
    }
    
    napi_value delayValue;
    status = napi_get_named_property(env, transitionOptions, "delay", &delayValue);
    int64_t delay = 0;
    if (status == napi_ok) {
        napi_valuetype valueType;
        napi_typeof(env, delayValue, &valueType);
        if (valueType == napi_number) {
            napi_get_value_int64(env, delayValue, &delay);
        }
    }
    
    Logger::info("StyleNAPI", "SetTransition (stub): duration=%ld, delay=%ld", static_cast<long>(duration), static_cast<long>(delay));
    
    return napiArgs.Undefined();
}

} // namespace harmony
} // namespace maplibre

