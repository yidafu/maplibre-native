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

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

namespace maplibre {
namespace harmony {

// ==================== Image 管理 ====================

napi_value StyleNAPI::AddImage(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 6;  // Support both Image object and raw parameters
    napi_value args[6];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (!style || !style->map) {
        napi_throw_error(env, nullptr, "Invalid style instance");
        return nullptr;
    }
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "AddImage requires at least 1 argument");
        return nullptr;
    }
    
    // Check if first argument is an Image object
    if (ImageNAPI::IsImageObject(env, args[0])) {
        // New way: Accept Image NAPI object
        ImageNAPI* imageNapi = ImageNAPI::Unwrap(env, args[0]);
        if (!imageNapi) {
            napi_throw_error(env, nullptr, "Failed to unwrap Image object");
            return nullptr;
        }
        
        try {
            // Convert to style::Image
            auto styleImage = imageNapi->toStyleImage();
            std::string imageName = styleImage->getID();
            
            // Add to Style
            style->map->getStyle().addImage(std::move(styleImage));
            style->images[imageName] = true;
            
            Logger::info("StyleNAPI", "AddImage from Image object: %s (%dx%d)", 
                        imageName.c_str(), imageNapi->getWidth(), imageNapi->getHeight());
        } catch (const std::exception& e) {
            Logger::error("StyleNAPI", "AddImage from Image object failed: %s", e.what());
            napi_throw_error(env, nullptr, e.what());
            return nullptr;
        }
        
        return nullptr;
    }
    
    // Old way: Accept raw parameters (name, buffer, width, height, pixelRatio, sdf)
    if (argc < 5) {
        napi_throw_error(env, nullptr, "AddImage requires at least 5 arguments: name, buffer, width, height, pixelRatio");
        return nullptr;
    }
    
    // 1. 获取图片名称
    std::string imageName = GetStringFromValue(env, args[0]);
    
    // 2. 获取图像数据 (ArrayBuffer or TypedArray)
    void* data = nullptr;
    size_t byteLength = 0;
    bool isTypedArray = false;
    napi_valuetype valueType;
    napi_typeof(env, args[1], &valueType);
    
    if (valueType == napi_object) {
        // 尝试 TypedArray
        napi_value arrayBuffer;
        size_t byteOffset;
        napi_status status = napi_get_typedarray_info(env, args[1], nullptr, &byteLength, &data, &arrayBuffer, &byteOffset);
        if (status == napi_ok) {
            isTypedArray = true;
        } else {
            // 尝试 ArrayBuffer
            status = napi_get_arraybuffer_info(env, args[1], &data, &byteLength);
            if (status != napi_ok) {
                napi_throw_error(env, nullptr, "Second argument must be ArrayBuffer or TypedArray");
                return nullptr;
            }
        }
    } else {
        napi_throw_error(env, nullptr, "Second argument must be ArrayBuffer or TypedArray");
        return nullptr;
    }
    
    // 3. 获取宽度和高度
    uint32_t width = 0;
    uint32_t height = 0;
    napi_get_value_uint32(env, args[2], &width);
    napi_get_value_uint32(env, args[3], &height);
    
    if (width == 0 || height == 0) {
        napi_throw_error(env, nullptr, "Width and height must be greater than 0");
        return nullptr;
    }
    
    // 4. 获取 pixelRatio
    double pixelRatio = 1.0;
    napi_get_value_double(env, args[4], &pixelRatio);
    
    // 5. 获取可选的 sdf 标志
    bool sdf = false;
    if (argc >= 6) {
        napi_get_value_bool(env, args[5], &sdf);
    }
    
    // 验证数据大小
    if (byteLength != width * height * 4) {
        Logger::error("StyleNAPI", "AddImage: data size mismatch (expected: %d, got: %zu)", width * height * 4, byteLength);
        napi_throw_error(env, nullptr, "Image data size does not match width * height * 4");
        return nullptr;
    }
    
    try {
        // 创建 PremultipliedImage
        mbgl::PremultipliedImage premultipliedImage({width, height});
        std::memcpy(premultipliedImage.data.get(), data, byteLength);
        
        // 创建 Image 对象
        auto image = std::make_unique<mbgl::style::Image>(
            imageName,
            std::move(premultipliedImage),
            static_cast<float>(pixelRatio),
            sdf
        );
        
        // 添加到 Style
        style->map->getStyle().addImage(std::move(image));
        style->images[imageName] = true;
        
        Logger::info("StyleNAPI", "AddImage: %s (%dx%d, ratio: %.2f, sdf: %s)", 
                    imageName.c_str(), width, height, pixelRatio, sdf ? "true" : "false");
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "AddImage failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
    
    return nullptr;
}

napi_value StyleNAPI::RemoveImage(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (!style || !style->map) {
        return CreateBoolValue(env, false);
    }
    
    if (argc < 1) {
        return CreateBoolValue(env, false);
    }
    
    std::string imageName = GetStringFromValue(env, args[0]);
    
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
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (!style || !style->map) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    if (argc < 1) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    std::string imageName = GetStringFromValue(env, args[0]);
    
    try {
        auto imageOpt = style->map->getStyle().getImage(imageName);
        if (!imageOpt) {
            napi_value result;
            napi_get_null(env, &result);
            return result;
        }
        
        const mbgl::style::Image& image = *imageOpt;
        const mbgl::PremultipliedImage& premultipliedImage = image.getImage();
        uint32_t width = premultipliedImage.size.width;
        uint32_t height = premultipliedImage.size.height;
        size_t dataSize = width * height * 4;
        
        // 创建 ArrayBuffer 返回图像数据
        void* data = nullptr;
        napi_value arrayBuffer;
        napi_create_arraybuffer(env, dataSize, &data, &arrayBuffer);
        std::memcpy(data, premultipliedImage.data.get(), dataSize);
        
        // 创建返回对象
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
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
}

// ==================== Light & Transition ====================

napi_value StyleNAPI::GetLight(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (!style || !style->map) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    try {
        const mbgl::style::Light* light = style->map->getStyle().getLight();
        if (!light) {
            napi_value result;
            napi_get_null(env, &result);
            return result;
        }
        
        // 创建返回对象
        napi_value result;
        napi_create_object(env, &result);
        
        // 注意：Light 对象的属性获取比较复杂，需要使用 conversion API
        // 这里提供一个简化版本，返回基本信息
        Logger::info("StyleNAPI", "GetLight called");
        
        // TODO: 完整实现需要转换 Light 属性
        // 参考 Android: platform/android/MapLibreAndroid/src/cpp/style/light.cpp
        
        return result;
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "GetLight failed: %s", e.what());
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
}

napi_value StyleNAPI::SetLight(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (!style || !style->map) {
        napi_throw_error(env, nullptr, "Invalid style instance");
        return nullptr;
    }
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "SetLight requires light options argument");
        return nullptr;
    }
    
    try {
        // 创建新的 Light 对象
        // TODO: 完整实现需要解析 light options 对象并设置各个属性
        // 参考 Android: platform/android/MapLibreAndroid/src/cpp/style/light.cpp
        
        Logger::info("StyleNAPI", "SetLight called (implementation incomplete)");
        Logger::warn("StyleNAPI", "SetLight: Full light property parsing not yet implemented");
        
        // 简化实现：只记录日志
        return nullptr;
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "SetLight failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value StyleNAPI::GetTransition(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (!style || !style->map) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // TODO: getTransition is not available in mbgl::style::Style
    // Returning default transition options
    Logger::warn("StyleNAPI", "GetTransition: Not implemented - returning default values");
    
    napi_value result;
    napi_create_object(env, &result);
    
    // 返回默认值
    napi_value durationValue;
    napi_create_int64(env, 300, &durationValue);  // 默认 300ms
    napi_set_named_property(env, result, "duration", durationValue);
    
    napi_value delayValue;
    napi_create_int64(env, 0, &delayValue);
    napi_set_named_property(env, result, "delay", delayValue);
    
    return result;
}

napi_value StyleNAPI::SetTransition(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (!style || !style->map) {
        napi_throw_error(env, nullptr, "Invalid style instance");
        return nullptr;
    }
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "SetTransition requires transition options argument");
        return nullptr;
    }
    
    // TODO: setTransition is not available in mbgl::style::Style
    // Logging the attempted transition but not applying it
    Logger::warn("StyleNAPI", "SetTransition: Not implemented - transition settings not applied");
    
    // 解析参数以记录日志
    napi_value durationValue;
    napi_status status = napi_get_named_property(env, args[0], "duration", &durationValue);
    int64_t duration = 300;  // 默认值
    if (status == napi_ok) {
        napi_valuetype valueType;
        napi_typeof(env, durationValue, &valueType);
        if (valueType == napi_number) {
            napi_get_value_int64(env, durationValue, &duration);
        }
    }
    
    napi_value delayValue;
    status = napi_get_named_property(env, args[0], "delay", &delayValue);
    int64_t delay = 0;
    if (status == napi_ok) {
        napi_valuetype valueType;
        napi_typeof(env, delayValue, &valueType);
        if (valueType == napi_number) {
            napi_get_value_int64(env, delayValue, &delay);
        }
    }
    
    Logger::info("StyleNAPI", "SetTransition (stub): duration=%lld, delay=%lld", duration, delay);
    
    return nullptr;
}

} // namespace harmony
} // namespace maplibre

