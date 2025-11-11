#include "icon_factory_napi.hpp"
#include "../icon/icon_napi.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"
#include "icon/icon_factory.hpp"

#include <rawfile/raw_file_manager.h>

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
        // NOTE: Image decoding from raw bytes is not yet implemented
        // HarmonyOS ImageSource API requires NAPI context
        throw std::runtime_error(
            "fromArrayBuffer not yet implemented. "
            "HarmonyOS image decoding requires NAPI context. "
            "Please use createDefaultMarker() for now, or keep using ETS IconFactory.fromResource()."
        );
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
    napi_value arrayBuffer;
    size_t byteOffset;
    
    napi_status status = napi_get_typedarray_info(
        env, typedArray, &type, &byteLength, &data, &arrayBuffer, &byteOffset
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
        // NOTE: Image decoding from raw bytes is not yet implemented
        throw std::runtime_error(
            "fromResourceData not yet implemented. "
            "Please use createDefaultMarker() for now, or keep using ETS IconFactory.fromResource()."
        );
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
        // Get ResourceManager from NAPI
        // Note: This needs to be passed from ETS layer or obtained from global context
        // For now, we'll throw an error and require ETS layer to read the file
        throw std::runtime_error(
            "fromRawfile is not yet implemented. " 
            "Please use fromResourceData() with ETS layer reading the rawfile."
        );
        
        // TODO: Implement ResourceManager access
        // NativeResourceManager* resourceMgr = getGlobalResourceManager();
        // auto image = mbgl::harmony::IconFactory::createFromRawfile(resourceMgr, fileName);
        // return IconNAPI::CreateFromImage(env, iconId, image, scale);
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
        // NOTE: File path loading is not yet implemented
        throw std::runtime_error(
            "fromFilePath not yet implemented. "
            "Please use createDefaultMarker() for now, or keep using ETS IconFactory.fromPath()."
        );
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

