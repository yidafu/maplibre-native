#include "icon_factory_napi.hpp"
#include "../icon/icon_napi.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "icon/icon_factory.hpp"
#include "bitmap/bitmap_harmony.hpp"

#include <rawfile/raw_file_manager.h>
#include <rawfile/raw_file.h>
#include <multimedia/image_framework/image_source_mdk.h>
#include <multimedia/image_framework/image_pixel_map_napi.h>
#include <fstream>
#include <vector>

using namespace OHOS::Media;

namespace maplibre {
namespace harmony {

using mbgl::harmony::Logger;
using mbgl::harmony::napi::NapiArgs;

// Static member initialization
int IconFactoryNAPI::nextIconId = 0;

std::string IconFactoryNAPI::generateIconId() {
    return "com.maplibre.icons.icon_" + std::to_string(++nextIconId);
}

napi_value IconFactoryNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("IconFactoryNAPI", "Initializing IconFactory NAPI class");
    
    napi_property_descriptor properties[] = {
        { "fromArrayBuffer", nullptr, FromArrayBuffer, nullptr, nullptr, nullptr, napi_static, nullptr },
        { "fromResourceData", nullptr, FromResourceData, nullptr, nullptr, nullptr, napi_static, nullptr },
        { "fromRawfile", nullptr, FromRawfile, nullptr, nullptr, nullptr, napi_static, nullptr },
        { "fromFilePath", nullptr, FromFilePath, nullptr, nullptr, nullptr, napi_static, nullptr },
        { "createDefaultMarker", nullptr, CreateDefaultMarker, nullptr, nullptr, nullptr, napi_static, nullptr },
    };
    
    napi_value iconFactoryClass;
    napi_status status = napi_define_class(
        env, "IconFactory", NAPI_AUTO_LENGTH,
        [](napi_env env, napi_callback_info info) -> napi_value {
            // Constructor is not meant to be called directly
            napi_throw_error(env, nullptr, 
                "IconFactory constructor is not accessible. Use static methods like IconFactory.fromArrayBuffer()");
            return nullptr;
        },
        nullptr,
        sizeof(properties) / sizeof(properties[0]),
        properties,
        &iconFactoryClass
    );
    
    if (status != napi_ok) {
        Logger::error("IconFactoryNAPI", "Failed to define IconFactory class");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "IconFactory", iconFactoryClass);
    if (status != napi_ok) {
        Logger::error("IconFactoryNAPI", "Failed to export IconFactory class");
        return nullptr;
    }
    
    Logger::info("IconFactoryNAPI", "IconFactory NAPI class registered successfully");
    return exports;
}

napi_value IconFactoryNAPI::FromArrayBuffer(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);

    // Signature: fromArrayBuffer(data: ArrayBuffer, iconId?: string, scale?: number): Icon
    if (args.Count() < 1) {
        Logger::error("IconFactoryNAPI", "fromArrayBuffer requires at least 1 argument");
        napi_throw_error(env, nullptr, "fromArrayBuffer requires at least 1 argument (data: ArrayBuffer)");
        return nullptr;
    }

    // Get ArrayBuffer data
    void* data = nullptr;
    size_t byteLength = 0;
    napi_value arrayBuffer = args.GetValue(0);
    napi_status status = napi_get_arraybuffer_info(env, arrayBuffer, &data, &byteLength);

    if (status != napi_ok || !data || byteLength == 0) {
        Logger::error("IconFactoryNAPI", "Invalid ArrayBuffer");
        napi_throw_error(env, nullptr, "First argument must be a valid ArrayBuffer");
        return nullptr;
    }

    // Get optional iconId
    std::string iconId = args.Count() >= 2 ? args.GetString(1, "iconId") : generateIconId();

    // Get optional scale
    float scale = args.Count() >= 3 ? static_cast<float>(args.GetDouble(2, "scale")) : 1.0f;

    Logger::info("IconFactoryNAPI", "Creating icon from ArrayBuffer: id=%s, size=%zu bytes, scale=%f",
                 iconId.c_str(), byteLength, scale);

    try {
        // Decode image using OH_ImageSource_CreateFromData (5 args)
        napi_value pixelMap = nullptr;
        int32_t decodeResult = OH_ImageSource_CreateFromData(env, static_cast<uint8_t*>(data), byteLength, nullptr, &pixelMap);
        if (decodeResult != OHOS_IMAGE_RESULT_SUCCESS || !pixelMap) {
            std::string errMsg = "Failed to decode image from ArrayBuffer, error code: " + std::to_string(decodeResult);
            Logger::error("IconFactoryNAPI", "%s", errMsg.c_str());
            napi_throw_error(env, nullptr, errMsg.c_str());
            return nullptr;
        }

        // Convert PixelMap to PremultipliedImage using BitmapHarmony
        auto image = std::make_shared<mbgl::PremultipliedImage>(
            std::move(mbgl::harmony::BitmapHarmony::GetImage(env, pixelMap))
        );

        // Create Icon NAPI object with scale
        return IconNAPI::CreateFromImage(env, iconId, image, scale);
    } catch (const std::exception& e) {
        Logger::error("IconFactoryNAPI", "Failed to create icon from ArrayBuffer: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value IconFactoryNAPI::FromResourceData(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);

    // Signature: fromResourceData(data: Uint8Array, iconId?: string, scale?: number): Icon
    if (args.Count() < 1) {
        Logger::error("IconFactoryNAPI", "fromResourceData requires at least 1 argument");
        napi_throw_error(env, nullptr, "fromResourceData requires at least 1 argument (data: Uint8Array)");
        return nullptr;
    }

    // Get Uint8Array data
    napi_value typedArray = args.GetValue(0);
    napi_typedarray_type type;
    size_t byteLength;
    void* data;
    napi_value existingArrayBuffer;
    size_t byteOffset;

    napi_status status = napi_get_typedarray_info(
        env, typedArray, &type, &byteLength, &data, &existingArrayBuffer, &byteOffset
    );

    if (status != napi_ok || type != napi_uint8_array || !data || byteLength == 0) {
        Logger::error("IconFactoryNAPI", "Invalid Uint8Array");
        napi_throw_error(env, nullptr, "First argument must be a valid Uint8Array");
        return nullptr;
    }

    // Get optional iconId
    std::string iconId = args.Count() >= 2 ? args.GetString(1, "iconId") : generateIconId();

    // Get optional scale
    float scale = args.Count() >= 3 ? static_cast<float>(args.GetDouble(2, "scale")) : 1.0f;

    Logger::info("IconFactoryNAPI", "Creating icon from Uint8Array: id=%s, size=%zu bytes, scale=%f",
                 iconId.c_str(), byteLength, scale);

    try {
        // Create a new ArrayBuffer that copies the typed array data so it's contiguous
        napi_value arrayBuffer;
        void* bufferData = nullptr;
        status = napi_create_arraybuffer(env, byteLength, &bufferData, &arrayBuffer);
        if (status != napi_ok || !bufferData) {
            throw std::runtime_error("Failed to create ArrayBuffer for image decoding");
        }
        std::memcpy(bufferData, data, byteLength);

        // Decode image using OH_ImageSource_CreateFromData (5 args)
        napi_value pixelMap = nullptr;
        int32_t decodeResult = OH_ImageSource_CreateFromData(env, static_cast<uint8_t*>(bufferData), byteLength, nullptr, &pixelMap);
        if (decodeResult != OHOS_IMAGE_RESULT_SUCCESS || !pixelMap) {
            std::string errMsg = "Failed to decode image from resource data, error code: " + std::to_string(decodeResult);
            Logger::error("IconFactoryNAPI", "%s", errMsg.c_str());
            napi_throw_error(env, nullptr, errMsg.c_str());
            return nullptr;
        }

        // Convert PixelMap to PremultipliedImage using BitmapHarmony
        auto image = std::make_shared<mbgl::PremultipliedImage>(
            std::move(mbgl::harmony::BitmapHarmony::GetImage(env, pixelMap))
        );

        // Create Icon NAPI object with scale
        return IconNAPI::CreateFromImage(env, iconId, image, scale);
    } catch (const std::exception& e) {
        Logger::error("IconFactoryNAPI", "Failed to create icon from Uint8Array: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value IconFactoryNAPI::FromRawfile(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);

    // Signature: fromRawfile(fileName: string, iconId?: string, scale?: number): Icon
    if (args.Count() < 1) {
        Logger::error("IconFactoryNAPI", "fromRawfile requires at least 1 argument");
        napi_throw_error(env, nullptr, "fromRawfile requires at least 1 argument (fileName: string)");
        return nullptr;
    }

    // Get file name
    std::string fileName = args.GetString(0, "fileName");
    if (args.HasError()) {
        Logger::error("IconFactoryNAPI", "Failed to get fileName");
        return nullptr;
    }

    // Get optional iconId
    std::string iconId = args.Count() >= 2 ? args.GetString(1, "iconId") : generateIconId();

    // Get optional scale
    float scale = args.Count() >= 3 ? static_cast<float>(args.GetDouble(2, "scale")) : 1.0f;

    Logger::info("IconFactoryNAPI", "Creating icon from rawfile: file=%s, id=%s, scale=%f",
                 fileName.c_str(), iconId.c_str(), scale);

    try {
        // Get ResourceManager from napi_env (passed via callback)
        // OH_ResourceManager_InitNativeResourceManager expects the JS module's exports object
        // We find it by walking up from the function arguments
        NativeResourceManager* resourceMgr = nullptr;

        // Use callback info to get the ResourceManager
        size_t argcHint;
        napi_value thisArg;
        napi_value* argv = nullptr;
        napi_get_cb_info(env, info, &argcHint, argv, &thisArg, nullptr);

        // Get the exports object from thisArg
        napi_value exportsObj;
        napi_get_named_property(env, thisArg, "constructor", &exportsObj);
        if (exportsObj) {
            // Some napi objects have an internal resource manager ref
            resourceMgr = OH_ResourceManager_InitNativeResourceManager(env, exportsObj);
        }

        // Fallback: try using the global object
        if (!resourceMgr) {
            napi_value global;
            napi_get_global(env, &global);
            napi_value resourceManager;
            napi_status mgrStatus = napi_get_named_property(env, global, "resourceManager", &resourceManager);
            if (mgrStatus == napi_ok && resourceManager) {
                // Create a temporary object to pass to the native resource manager
                napi_value tempExports;
                napi_create_object(env, &tempExports);
                napi_set_named_property(env, tempExports, "resourceManager", resourceManager);
                resourceMgr = OH_ResourceManager_InitNativeResourceManager(env, tempExports);
            }
        }

        if (!resourceMgr) {
            // Fallback: read the rawfile directly using ETS-provided path
            // Try common rawfile base paths
            std::string errorMsg =
                "fromRawfile: Cannot access ResourceManager. "
                "Pass rawfile data via fromResourceData(Uint8Array, iconId) instead, "
                "or use ETS IconFactory.fromRawfile().";
            throw std::runtime_error(errorMsg);
        }

        // Open the raw file
        RawFile* rawFile = OH_ResourceManager_OpenRawFile(resourceMgr, fileName.c_str());
        if (!rawFile) {
            std::string errorMsg = "fromRawfile: Cannot open rawfile: " + fileName;
            Logger::error("IconFactoryNAPI", "%s", errorMsg.c_str());
            napi_throw_error(env, nullptr, errorMsg.c_str());
            return nullptr;
        }

        // Get file size and read data
        long rawFileSize = OH_ResourceManager_GetRawFileSize(rawFile);
        if (rawFileSize <= 0) {
            OH_ResourceManager_CloseRawFile(rawFile);
            throw std::runtime_error("fromRawfile: Empty rawfile: " + fileName);
        }

        std::vector<uint8_t> fileData(rawFileSize);
        long bytesRead = OH_ResourceManager_ReadRawFile(rawFile, fileData.data(), rawFileSize);
        OH_ResourceManager_CloseRawFile(rawFile);

        if (bytesRead != rawFileSize) {
            throw std::runtime_error("fromRawfile: Failed to read rawfile: " + fileName);
        }

        // Create ArrayBuffer from the raw file data for image decoding
        napi_value arrayBuffer;
        void* bufferData = nullptr;
        napi_status status = napi_create_arraybuffer(env, rawFileSize, &bufferData, &arrayBuffer);
        if (status != napi_ok || !bufferData) {
            throw std::runtime_error("fromRawfile: Failed to create ArrayBuffer");
        }
        std::memcpy(bufferData, fileData.data(), rawFileSize);

        // Decode image using OH_ImageSource_CreateFromData (5 args)
        napi_value pixelMap = nullptr;
        int32_t decodeResult = OH_ImageSource_CreateFromData(env, static_cast<uint8_t*>(bufferData), rawFileSize, nullptr, &pixelMap);
        if (decodeResult != OHOS_IMAGE_RESULT_SUCCESS || !pixelMap) {
            std::string errMsg = "fromRawfile: Failed to decode image, error code: " + std::to_string(decodeResult);
            Logger::error("IconFactoryNAPI", "%s", errMsg.c_str());
            napi_throw_error(env, nullptr, errMsg.c_str());
            return nullptr;
        }

        // Convert PixelMap to PremultipliedImage
        auto image = std::make_shared<mbgl::PremultipliedImage>(
            std::move(mbgl::harmony::BitmapHarmony::GetImage(env, pixelMap))
        );

        // Create Icon NAPI object
        return IconNAPI::CreateFromImage(env, iconId, image, scale);
    } catch (const std::exception& e) {
        Logger::error("IconFactoryNAPI", "Failed to create icon from rawfile: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value IconFactoryNAPI::FromFilePath(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);

    // Signature: fromFilePath(path: string, iconId?: string, scale?: number): Icon
    if (args.Count() < 1) {
        Logger::error("IconFactoryNAPI", "fromFilePath requires at least 1 argument");
        napi_throw_error(env, nullptr, "fromFilePath requires at least 1 argument (path: string)");
        return nullptr;
    }

    // Get file path
    std::string path = args.GetString(0, "path");
    if (args.HasError()) {
        Logger::error("IconFactoryNAPI", "Failed to get path");
        return nullptr;
    }

    // Get optional iconId
    std::string iconId = args.Count() >= 2 ? args.GetString(1, "iconId") : generateIconId();

    // Get optional scale
    float scale = args.Count() >= 3 ? static_cast<float>(args.GetDouble(2, "scale")) : 1.0f;

    Logger::info("IconFactoryNAPI", "Creating icon from file path: path=%s, id=%s, scale=%f",
                 path.c_str(), iconId.c_str(), scale);

    try {
        // Read file from filesystem
        std::ifstream file(path, std::ios::binary | std::ios::ate);
        if (!file.is_open()) {
            std::string errorMsg = "fromFilePath: Cannot open file: " + path;
            Logger::error("IconFactoryNAPI", "%s", errorMsg.c_str());
            napi_throw_error(env, nullptr, errorMsg.c_str());
            return nullptr;
        }

        // Get file size
        std::streamsize fileSize = file.tellg();
        if (fileSize <= 0) {
            throw std::runtime_error("fromFilePath: Empty or invalid file: " + path);
        }
        file.seekg(0, std::ios::beg);

        // Read file contents
        std::vector<uint8_t> fileData(fileSize);
        if (!file.read(reinterpret_cast<char*>(fileData.data()), fileSize)) {
            throw std::runtime_error("fromFilePath: Failed to read file: " + path);
        }
        file.close();

        // Create ArrayBuffer for image decoding
        napi_value arrayBuffer;
        void* bufferData = nullptr;
        napi_status status = napi_create_arraybuffer(env, fileSize, &bufferData, &arrayBuffer);
        if (status != napi_ok || !bufferData) {
            throw std::runtime_error("fromFilePath: Failed to create ArrayBuffer");
        }
        std::memcpy(bufferData, fileData.data(), fileSize);

        // Decode image using OH_ImageSource_CreateFromData (5 args)
        napi_value pixelMap = nullptr;
        int32_t decodeResult = OH_ImageSource_CreateFromData(env, static_cast<uint8_t*>(bufferData), fileSize, nullptr, &pixelMap);
        if (decodeResult != OHOS_IMAGE_RESULT_SUCCESS || !pixelMap) {
            std::string errMsg = "fromFilePath: Failed to decode image, error code: " + std::to_string(decodeResult);
            Logger::error("IconFactoryNAPI", "%s", errMsg.c_str());
            napi_throw_error(env, nullptr, errMsg.c_str());
            return nullptr;
        }

        // Convert PixelMap to PremultipliedImage
        auto image = std::make_shared<mbgl::PremultipliedImage>(
            std::move(mbgl::harmony::BitmapHarmony::GetImage(env, pixelMap))
        );

        // Create Icon NAPI object with scale
        return IconNAPI::CreateFromImage(env, iconId, image, scale);
    } catch (const std::exception& e) {
        Logger::error("IconFactoryNAPI", "Failed to create icon from file: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value IconFactoryNAPI::CreateDefaultMarker(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    // Signature: createDefaultMarker(iconId?: string, size?: number): Icon
    // NOTE: ResourceManager parameter removed - rawfile loading handled in ETS layer
    
    // Get optional iconId
    std::string iconId = args.Count() >= 1 ? args.GetString(0, "iconId") : "com.maplibre.marker.default";
    
    // Get optional size
    uint32_t size = args.Count() >= 2 ? static_cast<uint32_t>(args.GetInt32(1, "size")) : 48;
    
    Logger::info("IconFactoryNAPI", "Creating programmatic default marker (RED pin): id=%s, size=%u",
                 iconId.c_str(), size);
    
    try {
        // Generate a programmatic red pin-shaped icon
        auto image = mbgl::harmony::IconFactory::createDefaultMarker(size);
        
        // Create Icon NAPI object with scale 1.0
        return IconNAPI::CreateFromImage(env, iconId, image, 1.0f);
    } catch (const std::exception& e) {
        Logger::error("IconFactoryNAPI", "Failed to create default marker: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

} // namespace harmony
} // namespace maplibre

