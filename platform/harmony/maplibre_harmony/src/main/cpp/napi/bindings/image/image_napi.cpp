#include "image_napi.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"
#include <mbgl/util/premultiply.hpp>

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

namespace maplibre {

using mbgl::harmony::napi::NapiArgs;
namespace harmony {

// Static member initialization
napi_ref ImageNAPI::constructor = nullptr;

ImageNAPI::ImageNAPI(
    std::string name,
    uint32_t width,
    uint32_t height,
    float pixelRatio,
    bool sdf,
    std::shared_ptr<std::vector<uint8_t>> data,
    std::optional<std::vector<mbgl::style::ImageStretches::value_type>> stretchX,
    std::optional<std::vector<mbgl::style::ImageStretches::value_type>> stretchY,
    std::optional<mbgl::style::ImageContent> content
) : name(std::move(name)),
    width(width),
    height(height),
    pixelRatio(pixelRatio),
    sdf(sdf),
    data(std::move(data)),
    stretchX(std::move(stretchX)),
    stretchY(std::move(stretchY)),
    content(std::move(content)) {
    Logger::info("ImageNAPI", "Image instance created: %s (%dx%d)", this->name.c_str(), width, height);
}

ImageNAPI::~ImageNAPI() {
    Logger::info("ImageNAPI", "Image instance destroyed: %s", name.c_str());
}

void ImageNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    ImageNAPI* image = static_cast<ImageNAPI*>(nativeObject);
    delete image;
}

napi_value ImageNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("ImageNAPI", "Initializing Image NAPI class");
    
    napi_property_descriptor properties[] = {
        { "getName", nullptr, GetName, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getWidth", nullptr, GetWidth, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getHeight", nullptr, GetHeight, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getPixelRatio", nullptr, GetPixelRatio, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getSdf", nullptr, GetSdf, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getData", nullptr, GetData, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getStretchX", nullptr, GetStretchX, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getStretchY", nullptr, GetStretchY, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getContent", nullptr, GetContent, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "Image", NAPI_AUTO_LENGTH, New, nullptr,
                                          sizeof(properties) / sizeof(properties[0]), 
                                          properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("ImageNAPI", "Failed to define Image class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("ImageNAPI", "Failed to create reference to Image constructor");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "Image", cons);
    if (status != napi_ok) {
        Logger::error("ImageNAPI", "Failed to export Image class");
        return nullptr;
    }
    
    Logger::info("ImageNAPI", "Image NAPI class registered successfully");
    return exports;
}

napi_value ImageNAPI::New(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "Image constructor requires an options object");
        return nullptr;
    }
    
    NapiArgs napiArgs(env, info);
    napi_value options = napiArgs.GetObject(0, "options");
    
    if (napiArgs.HasError()) {
        napi_throw_error(env, nullptr, "First argument must be an options object");
        return nullptr;
    }
    
    try {
        // Parse name (required)
        napi_value nameValue;
        napi_get_named_property(env, options, "name", &nameValue);
        std::string name = GetStringFromValue(env, nameValue);
        
        if (name.empty()) {
            napi_throw_error(env, nullptr, "Image name is required");
            return nullptr;
        }
        
        // Parse width (required)
        napi_value widthValue;
        napi_get_named_property(env, options, "width", &widthValue);
        uint32_t width = 0;
        napi_get_value_uint32(env, widthValue, &width);
        
        if (width == 0) {
            napi_throw_error(env, nullptr, "Image width must be greater than 0");
            return nullptr;
        }
        
        // Parse height (required)
        napi_value heightValue;
        napi_get_named_property(env, options, "height", &heightValue);
        uint32_t height = 0;
        napi_get_value_uint32(env, heightValue, &height);
        
        if (height == 0) {
            napi_throw_error(env, nullptr, "Image height must be greater than 0");
            return nullptr;
        }
        
        // Parse data (required) - Uint8Array
        napi_value dataValue;
        napi_get_named_property(env, options, "data", &dataValue);
        
        void* rawData = nullptr;
        size_t byteLength = 0;
        napi_value arrayBuffer;
        size_t byteOffset = 0;
        napi_status status = napi_get_typedarray_info(env, dataValue, nullptr, &byteLength, &rawData, &arrayBuffer, &byteOffset);
        
        if (status != napi_ok) {
            napi_throw_error(env, nullptr, "Image data must be a Uint8Array");
            return nullptr;
        }
        
        // Verify data size (RGBA = 4 bytes per pixel)
        size_t expectedSize = width * height * 4;
        if (byteLength != expectedSize) {
            Logger::error("ImageNAPI", "Data size mismatch: expected %zu, got %zu", expectedSize, byteLength);
            napi_throw_error(env, nullptr, "Image data size does not match width * height * 4");
            return nullptr;
        }
        
        // Copy data to shared vector
        auto imageData = std::make_shared<std::vector<uint8_t>>(byteLength);
        std::memcpy(imageData->data(), rawData, byteLength);
        
        // Parse pixelRatio (optional, default 1.0)
        float pixelRatio = 1.0f;
        napi_value pixelRatioValue;
        status = napi_get_named_property(env, options, "pixelRatio", &pixelRatioValue);
        if (status == napi_ok) {
            napi_valuetype valueType;
            napi_typeof(env, pixelRatioValue, &valueType);
            if (valueType == napi_number) {
                double ratio = 0.0;
                napi_get_value_double(env, pixelRatioValue, &ratio);
                pixelRatio = static_cast<float>(ratio);
            }
        }
        
        // Parse sdf (optional, default false)
        bool sdf = false;
        napi_value sdfValue;
        status = napi_get_named_property(env, options, "sdf", &sdfValue);
        if (status == napi_ok) {
            napi_valuetype valueType;
            napi_typeof(env, sdfValue, &valueType);
            if (valueType == napi_boolean) {
                napi_get_value_bool(env, sdfValue, &sdf);
            }
        }
        
        // Parse stretchX (optional)
        std::optional<std::vector<mbgl::style::ImageStretches::value_type>> stretchX;
        napi_value stretchXValue;
        status = napi_get_named_property(env, options, "stretchX", &stretchXValue);
        if (status == napi_ok) {
            bool isArray = false;
            napi_is_array(env, stretchXValue, &isArray);
            if (isArray) {
                uint32_t arrayLength = 0;
                napi_get_array_length(env, stretchXValue, &arrayLength);
                
                if (arrayLength > 0 && arrayLength % 2 == 0) {
                    std::vector<mbgl::style::ImageStretches::value_type> stretches;
                    for (uint32_t i = 0; i < arrayLength; i += 2) {
                        napi_value startVal, endVal;
                        napi_get_element(env, stretchXValue, i, &startVal);
                        napi_get_element(env, stretchXValue, i + 1, &endVal);
                        
                        double start = 0.0, end = 0.0;
                        napi_get_value_double(env, startVal, &start);
                        napi_get_value_double(env, endVal, &end);
                        
                        stretches.push_back({static_cast<float>(start), static_cast<float>(end)});
                    }
                    stretchX = stretches;
                }
            }
        }
        
        // Parse stretchY (optional)
        std::optional<std::vector<mbgl::style::ImageStretches::value_type>> stretchY;
        napi_value stretchYValue;
        status = napi_get_named_property(env, options, "stretchY", &stretchYValue);
        if (status == napi_ok) {
            bool isArray = false;
            napi_is_array(env, stretchYValue, &isArray);
            if (isArray) {
                uint32_t arrayLength = 0;
                napi_get_array_length(env, stretchYValue, &arrayLength);
                
                if (arrayLength > 0 && arrayLength % 2 == 0) {
                    std::vector<mbgl::style::ImageStretches::value_type> stretches;
                    for (uint32_t i = 0; i < arrayLength; i += 2) {
                        napi_value startVal, endVal;
                        napi_get_element(env, stretchYValue, i, &startVal);
                        napi_get_element(env, stretchYValue, i + 1, &endVal);
                        
                        double start = 0.0, end = 0.0;
                        napi_get_value_double(env, startVal, &start);
                        napi_get_value_double(env, endVal, &end);
                        
                        stretches.push_back({static_cast<float>(start), static_cast<float>(end)});
                    }
                    stretchY = stretches;
                }
            }
        }
        
        // Parse content (optional) - [left, top, right, bottom]
        std::optional<mbgl::style::ImageContent> content;
        napi_value contentValue;
        status = napi_get_named_property(env, options, "content", &contentValue);
        if (status == napi_ok) {
            bool isArray = false;
            napi_is_array(env, contentValue, &isArray);
            if (isArray) {
                uint32_t arrayLength = 0;
                napi_get_array_length(env, contentValue, &arrayLength);
                
                if (arrayLength == 4) {
                    napi_value leftVal, topVal, rightVal, bottomVal;
                    napi_get_element(env, contentValue, 0, &leftVal);
                    napi_get_element(env, contentValue, 1, &topVal);
                    napi_get_element(env, contentValue, 2, &rightVal);
                    napi_get_element(env, contentValue, 3, &bottomVal);
                    
                    double left = 0.0, top = 0.0, right = 0.0, bottom = 0.0;
                    napi_get_value_double(env, leftVal, &left);
                    napi_get_value_double(env, topVal, &top);
                    napi_get_value_double(env, rightVal, &right);
                    napi_get_value_double(env, bottomVal, &bottom);
                    
                    content = mbgl::style::ImageContent{
                        static_cast<float>(left),
                        static_cast<float>(top),
                        static_cast<float>(right),
                        static_cast<float>(bottom)
                    };
                }
            }
        }
        
        // Create ImageNAPI instance
        ImageNAPI* imageNapi = new ImageNAPI(
            name, width, height, pixelRatio, sdf, imageData,
            stretchX, stretchY, content
        );
        
        status = napi_wrap(env, jsThis, imageNapi, Destructor, nullptr, nullptr);
        if (status != napi_ok) {
            delete imageNapi;
            napi_throw_error(env, nullptr, "Failed to wrap Image object");
            return nullptr;
        }
        
        Logger::info("ImageNAPI", "Image created: %s (%dx%d, ratio: %.2f, sdf: %s)",
                    name.c_str(), width, height, pixelRatio, sdf ? "true" : "false");
        return jsThis;
        
    } catch (const std::exception& e) {
        Logger::error("ImageNAPI", "Failed to create Image: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value ImageNAPI::GetName(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    ImageNAPI* image = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&image));
    
    if (!image) {
        return CreateStringValue(env, "");
    }
    
    return CreateStringValue(env, image->name);
}

napi_value ImageNAPI::GetWidth(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    ImageNAPI* image = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&image));
    
    if (!image) {
        napi_value result;
        napi_create_uint32(env, 0, &result);
        return result;
    }
    
    napi_value result;
    napi_create_uint32(env, image->width, &result);
    return result;
}

napi_value ImageNAPI::GetHeight(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    ImageNAPI* image = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&image));
    
    if (!image) {
        napi_value result;
        napi_create_uint32(env, 0, &result);
        return result;
    }
    
    napi_value result;
    napi_create_uint32(env, image->height, &result);
    return result;
}

napi_value ImageNAPI::GetPixelRatio(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    ImageNAPI* image = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&image));
    
    if (!image) {
        napi_value result;
        napi_create_double(env, 1.0, &result);
        return result;
    }
    
    napi_value result;
    napi_create_double(env, image->pixelRatio, &result);
    return result;
}

napi_value ImageNAPI::GetSdf(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    ImageNAPI* image = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&image));
    
    if (!image) {
        return CreateBoolValue(env, false);
    }
    
    return CreateBoolValue(env, image->sdf);
}

napi_value ImageNAPI::GetData(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    ImageNAPI* image = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&image));
    
    if (!image || !image->data) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Create a new Uint8Array with a copy of the data
    size_t dataSize = image->data->size();
    void* arrayData = nullptr;
    napi_value arrayBuffer;
    napi_create_arraybuffer(env, dataSize, &arrayData, &arrayBuffer);
    std::memcpy(arrayData, image->data->data(), dataSize);
    
    napi_value typedArray;
    napi_create_typedarray(env, napi_uint8_array, dataSize, arrayBuffer, 0, &typedArray);
    return typedArray;
}

napi_value ImageNAPI::GetStretchX(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    ImageNAPI* image = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&image));
    
    if (!image || !image->stretchX) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Convert vector of stretches to array [start1, end1, start2, end2, ...]
    const auto& stretches = image->stretchX.value();
    napi_value result;
    napi_create_array_with_length(env, stretches.size() * 2, &result);
    
    for (size_t i = 0; i < stretches.size(); ++i) {
        napi_value startVal, endVal;
        napi_create_double(env, stretches[i].first, &startVal);
        napi_create_double(env, stretches[i].second, &endVal);
        napi_set_element(env, result, i * 2, startVal);
        napi_set_element(env, result, i * 2 + 1, endVal);
    }
    
    return result;
}

napi_value ImageNAPI::GetStretchY(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    ImageNAPI* image = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&image));
    
    if (!image || !image->stretchY) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Convert vector of stretches to array [start1, end1, start2, end2, ...]
    const auto& stretches = image->stretchY.value();
    napi_value result;
    napi_create_array_with_length(env, stretches.size() * 2, &result);
    
    for (size_t i = 0; i < stretches.size(); ++i) {
        napi_value startVal, endVal;
        napi_create_double(env, stretches[i].first, &startVal);
        napi_create_double(env, stretches[i].second, &endVal);
        napi_set_element(env, result, i * 2, startVal);
        napi_set_element(env, result, i * 2 + 1, endVal);
    }
    
    return result;
}

napi_value ImageNAPI::GetContent(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    ImageNAPI* image = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&image));
    
    if (!image || !image->content) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Return array [left, top, right, bottom]
    const auto& c = image->content.value();
    napi_value result;
    napi_create_array_with_length(env, 4, &result);
    
    napi_value leftVal, topVal, rightVal, bottomVal;
    napi_create_double(env, c.left, &leftVal);
    napi_create_double(env, c.top, &topVal);
    napi_create_double(env, c.right, &rightVal);
    napi_create_double(env, c.bottom, &bottomVal);
    
    napi_set_element(env, result, 0, leftVal);
    napi_set_element(env, result, 1, topVal);
    napi_set_element(env, result, 2, rightVal);
    napi_set_element(env, result, 3, bottomVal);
    
    return result;
}

std::unique_ptr<mbgl::style::Image> ImageNAPI::toStyleImage() const {
    // Create PremultipliedImage from data
    mbgl::PremultipliedImage premultipliedImage({width, height});
    std::memcpy(premultipliedImage.data.get(), data->data(), data->size());
    
    // Convert stretchX and stretchY to ImageStretches
    mbgl::style::ImageStretches imageStretchesX;
    if (stretchX) {
        imageStretchesX = stretchX.value();
    }
    
    mbgl::style::ImageStretches imageStretchesY;
    if (stretchY) {
        imageStretchesY = stretchY.value();
    }
    
    // Create style::Image with all parameters
    if (content) {
        return std::make_unique<mbgl::style::Image>(
            name,
            std::move(premultipliedImage),
            pixelRatio,
            sdf,
            imageStretchesX,
            imageStretchesY,
            content.value()
        );
    } else {
        return std::make_unique<mbgl::style::Image>(
            name,
            std::move(premultipliedImage),
            pixelRatio,
            sdf,
            imageStretchesX,
            imageStretchesY
        );
    }
}

bool ImageNAPI::IsImageObject(napi_env env, napi_value value) {
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
    return status == napi_ok && isInstance;
}

ImageNAPI* ImageNAPI::Unwrap(napi_env env, napi_value value) {
    ImageNAPI* image = nullptr;
    napi_status status = napi_unwrap(env, value, reinterpret_cast<void**>(&image));
    return (status == napi_ok) ? image : nullptr;
}

} // namespace harmony
} // namespace maplibre

