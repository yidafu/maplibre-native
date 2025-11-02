#include "style_builder_napi.hpp"
#include "napi/core/napi_utils.h"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include <multimedia/image_framework/image_pixel_map_napi.h>
#include <multimedia/image_framework/image_pixel_map_mdk.h>

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;

namespace maplibre {
namespace harmony {

// Static member initialization
napi_ref StyleBuilderNAPI::constructor = nullptr;

StyleBuilderNAPI::StyleBuilderNAPI()
    : styleUri(""), styleJson("") {
    Logger::info("StyleBuilderNAPI", "StyleBuilder instance created");
}

StyleBuilderNAPI::~StyleBuilderNAPI() {
    Logger::info("StyleBuilderNAPI", "StyleBuilder instance destroyed");
}

void StyleBuilderNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    StyleBuilderNAPI* builder = static_cast<StyleBuilderNAPI*>(nativeObject);
    delete builder;
}

napi_value StyleBuilderNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("StyleBuilderNAPI", "Initializing StyleBuilder NAPI class");
    
    napi_property_descriptor properties[] = {
        // Builder 方法
        { "fromUri", nullptr, FromUri, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "fromJson", nullptr, FromJson, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "withSource", nullptr, WithSource, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "withLayer", nullptr, WithLayer, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "withImage", nullptr, WithImage, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "withTransitionOptions", nullptr, WithTransitionOptions, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "StyleBuilder", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("StyleBuilderNAPI", "Failed to define StyleBuilder class");
        return nullptr;
    }
    
    // 创建构造函数引用
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("StyleBuilderNAPI", "Failed to create constructor reference");
        return nullptr;
    }
    
    // 将构造函数添加到 exports
    status = napi_set_named_property(env, exports, "StyleBuilder", cons);
    if (status != napi_ok) {
        Logger::error("StyleBuilderNAPI", "Failed to set StyleBuilder property");
        return nullptr;
    }
    
    Logger::info("StyleBuilderNAPI", "StyleBuilder NAPI class initialized successfully");
    return exports;
}

napi_value StyleBuilderNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // 创建 C++ 对象
    StyleBuilderNAPI* builder = new StyleBuilderNAPI();
    
    // Wrap 到 JS 对象
    napi_status status = napi_wrap(env, args.This(), builder, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete builder;
        napi_throw_error(env, nullptr, "Failed to wrap StyleBuilder object");
        return nullptr;
    }
    
    return args.This();
}

// ==================== Builder 方法 ====================

napi_value StyleBuilderNAPI::FromUri(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();
    
    StyleBuilderNAPI* builder = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&builder));
    
    if (!builder) {
        napi_throw_error(env, nullptr, "Invalid StyleBuilder instance");
        return nullptr;
    }
    
    builder->styleUri = args.GetString(0, "uri");
    if (args.HasError()) return args.Undefined();
    Logger::info("StyleBuilderNAPI", "fromUri: %s", builder->styleUri.c_str());
    
    // 返回 this 支持链式调用
    return args.This();
}

napi_value StyleBuilderNAPI::FromJson(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return args.Undefined();
    
    StyleBuilderNAPI* builder = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&builder));
    
    if (!builder) {
        napi_throw_error(env, nullptr, "Invalid StyleBuilder instance");
        return nullptr;
    }
    
    builder->styleJson = args.GetString(0, "json");
    if (args.HasError()) return args.Undefined();
    Logger::info("StyleBuilderNAPI", "fromJson: %zu bytes", builder->styleJson.length());
    
    // 返回 this 支持链式调用
    return args.This();
}

napi_value StyleBuilderNAPI::WithSource(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    StyleBuilderNAPI* builder = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&builder));
    
    if (!builder) {
        napi_throw_error(env, nullptr, "Invalid StyleBuilder instance");
        return nullptr;
    }
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "withSource requires source argument");
        return nullptr;
    }
    
    try {
        // 将 Source 对象序列化为 JSON 字符串以供后续使用
        // 注意：这里简化处理，实际应该从 Source 对象中提取所需信息
        napi_value sourceObj = args[0];
        
        // 获取 Source ID
        napi_value idValue;
        napi_get_named_property(env, sourceObj, "id", &idValue);
        std::string sourceId = GetStringFromValue(env, idValue);
        
        // 简单地存储 source ID，实际使用时需要完整的 source 配置
        builder->preloadedSourcesJson.push_back(sourceId);
        
        Logger::info("StyleBuilderNAPI", "withSource: added source '%s' to preload list", sourceId.c_str());
        
    } catch (const std::exception& e) {
        Logger::error("StyleBuilderNAPI", "withSource failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
    
    // 返回 this 支持链式调用
    return jsThis;
}

napi_value StyleBuilderNAPI::WithLayer(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    StyleBuilderNAPI* builder = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&builder));
    
    if (!builder) {
        napi_throw_error(env, nullptr, "Invalid StyleBuilder instance");
        return nullptr;
    }
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "withLayer requires layer argument");
        return nullptr;
    }
    
    try {
        // 将 Layer 对象序列化为 JSON 字符串以供后续使用
        napi_value layerObj = args[0];
        
        // 获取 Layer ID
        napi_value idValue;
        napi_get_named_property(env, layerObj, "id", &idValue);
        std::string layerId = GetStringFromValue(env, idValue);
        
        // 简单地存储 layer ID，实际使用时需要完整的 layer 配置
        builder->preloadedLayersJson.push_back(layerId);
        
        Logger::info("StyleBuilderNAPI", "withLayer: added layer '%s' to preload list", layerId.c_str());
        
    } catch (const std::exception& e) {
        Logger::error("StyleBuilderNAPI", "withLayer failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
    
    // 返回 this 支持链式调用
    return jsThis;
}

napi_value StyleBuilderNAPI::WithImage(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    StyleBuilderNAPI* builder = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&builder));
    
    if (!builder) {
        napi_throw_error(env, nullptr, "Invalid StyleBuilder instance");
        return nullptr;
    }
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "withImage requires at least 1 argument");
        return nullptr;
    }
    
    try {
        ImageData imageData;
        imageData.pixelRatio = 1.0f;  // 默认值
        
        // 检查第一个参数类型，判断是哪个重载
        napi_valuetype firstArgType;
        napi_typeof(env, args[0], &firstArgType);
        
        if (argc == 2 && firstArgType == napi_string) {
            // 形式 2: withImage(name: string, pixelMap: PixelMap)
            imageData.id = GetStringFromValue(env, args[0]);
            
            // 获取 PixelMap 对象
            napi_value pixelMapValue = args[1];
            
            // 获取原生 PixelMap 句柄
            NativePixelMap* nativePixelMap = OH_PixelMap_InitNativePixelMap(env, pixelMapValue);
            if (!nativePixelMap) {
                Logger::error("StyleBuilderNAPI", "Failed to get native PixelMap");
                napi_throw_error(env, nullptr, "Failed to get native PixelMap");
                return nullptr;
            }
            
            // 获取图像信息
            OhosPixelMapInfos imageInfo;
            int32_t result = OH_PixelMap_GetImageInfo(nativePixelMap, &imageInfo);
            if (result != 0) {
                Logger::error("StyleBuilderNAPI", "Failed to get PixelMap image info, error: %d", result);
                napi_throw_error(env, nullptr, "Failed to get PixelMap image info");
                return nullptr;
            }
            
            imageData.width = static_cast<uint32_t>(imageInfo.width);
            imageData.height = static_cast<uint32_t>(imageInfo.height);
            
            Logger::info("StyleBuilderNAPI", "Converting PixelMap to image data: %dx%d", imageData.width, imageData.height);
            
            // 访问像素数据
            void* pixelDataPtr = nullptr;
            result = OH_PixelMap_AccessPixels(nativePixelMap, &pixelDataPtr);
            if (result != 0 || !pixelDataPtr) {
                Logger::error("StyleBuilderNAPI", "Failed to access PixelMap pixels, error: %d", result);
                napi_throw_error(env, nullptr, "Failed to access PixelMap pixels");
                return nullptr;
            }
            
            // 复制像素数据
            size_t dataSize = imageData.width * imageData.height * 4; // RGBA
            imageData.data.resize(dataSize);
            std::memcpy(imageData.data.data(), pixelDataPtr, dataSize);
            
            // 释放像素数据访问
            OH_PixelMap_UnAccessPixels(nativePixelMap);
            
        } else if (argc == 1 && firstArgType == napi_object) {
            // 形式 1: withImage(image: Image)
            napi_value imageObj = args[0];
            
            // 从 Image 对象提取属性
            napi_value nameValue, widthValue, heightValue, dataValue, pixelRatioValue;
            
            // 获取图像名称（必需）
            if (napi_get_named_property(env, imageObj, "name", &nameValue) == napi_ok) {
                imageData.id = GetStringFromValue(env, nameValue);
            } else {
                napi_throw_error(env, nullptr, "Image object must have 'name' property");
                return nullptr;
            }
            
            // 获取宽度（必需）
            if (napi_get_named_property(env, imageObj, "width", &widthValue) == napi_ok) {
                int32_t width;
                napi_get_value_int32(env, widthValue, &width);
                imageData.width = static_cast<uint32_t>(width);
            }
            
            // 获取高度（必需）
            if (napi_get_named_property(env, imageObj, "height", &heightValue) == napi_ok) {
                int32_t height;
                napi_get_value_int32(env, heightValue, &height);
                imageData.height = static_cast<uint32_t>(height);
            }
            
            // 获取像素比率（可选）
            if (napi_get_named_property(env, imageObj, "pixelRatio", &pixelRatioValue) == napi_ok) {
                double pixelRatio;
                napi_get_value_double(env, pixelRatioValue, &pixelRatio);
                imageData.pixelRatio = static_cast<float>(pixelRatio);
            }
            
            // 获取图像数据（必需）
            if (napi_get_named_property(env, imageObj, "data", &dataValue) == napi_ok) {
                bool isDataArrayBuffer;
                napi_is_arraybuffer(env, dataValue, &isDataArrayBuffer);
                if (isDataArrayBuffer) {
                    void* bufferData;
                    size_t bufferLength;
                    napi_get_arraybuffer_info(env, dataValue, &bufferData, &bufferLength);
                    
                    imageData.data.resize(bufferLength);
                    std::memcpy(imageData.data.data(), bufferData, bufferLength);
                } else {
                    napi_throw_error(env, nullptr, "Image 'data' property must be ArrayBuffer");
                    return nullptr;
                }
            } else {
                napi_throw_error(env, nullptr, "Image object must have 'data' property");
                return nullptr;
            }
        } else {
            napi_throw_error(env, nullptr, "Invalid arguments for withImage");
            return nullptr;
        }
        
        builder->preloadedImages.push_back(std::move(imageData));
        Logger::info("StyleBuilderNAPI", "withImage: added image '%s' to preload list", imageData.id.c_str());
        
    } catch (const std::exception& e) {
        Logger::error("StyleBuilderNAPI", "withImage failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
    
    // 返回 this 支持链式调用
    return jsThis;
}

napi_value StyleBuilderNAPI::WithTransitionOptions(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    StyleBuilderNAPI* builder = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&builder));
    
    if (!builder) {
        napi_throw_error(env, nullptr, "Invalid StyleBuilder instance");
        return nullptr;
    }
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "withTransitionOptions requires options argument");
        return nullptr;
    }
    
    try {
        napi_value optionsObj = args[0];
        napi_valuetype type;
        napi_typeof(env, optionsObj, &type);
        
        if (type == napi_object) {
            // 解析 duration
            napi_value durationValue;
            if (napi_get_named_property(env, optionsObj, "duration", &durationValue) == napi_ok) {
                int64_t duration;
                napi_get_value_int64(env, durationValue, &duration);
                builder->transitionOptions.duration = static_cast<uint64_t>(duration);
            }
            
            // 解析 delay
            napi_value delayValue;
            if (napi_get_named_property(env, optionsObj, "delay", &delayValue) == napi_ok) {
                int64_t delay;
                napi_get_value_int64(env, delayValue, &delay);
                builder->transitionOptions.delay = static_cast<uint64_t>(delay);
            }
            
            // 解析 enablePlacementTransitions
            napi_value enableValue;
            if (napi_get_named_property(env, optionsObj, "enablePlacementTransitions", &enableValue) == napi_ok) {
                bool enable;
                napi_get_value_bool(env, enableValue, &enable);
                builder->transitionOptions.enablePlacementTransitions = enable;
            }
            
            Logger::info("StyleBuilderNAPI", "withTransitionOptions: configured");
        }
        
    } catch (const std::exception& e) {
        Logger::error("StyleBuilderNAPI", "withTransitionOptions failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
    
    // 返回 this 支持链式调用
    return jsThis;
}

} // namespace harmony
} // namespace maplibre

