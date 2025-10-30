#pragma once

#include <napi/native_api.h>
#include <string>

namespace maplibre {
namespace harmony {

/**
 * IconFactoryNAPI - NAPI bindings for IconFactory
 * 
 * Exposes static factory methods to ETS/TypeScript for creating icons
 * with zero-copy performance optimization.
 * 
 * All methods are static and called directly from ETS:
 * - maplibre.IconFactory.fromArrayBuffer(...)
 * - maplibre.IconFactory.fromRawfile(...)
 * - maplibre.IconFactory.fromResourceData(...)
 * - maplibre.IconFactory.fromFilePath(...)
 * - maplibre.IconFactory.createDefaultMarker(...)
 */
class IconFactoryNAPI {
public:
    /**
     * Register IconFactory class with NAPI
     * 
     * @param env NAPI environment
     * @param exports Module exports object
     * @return Updated exports object
     */
    static napi_value Init(napi_env env, napi_value exports);
    
private:
    /**
     * Create Icon from ArrayBuffer (raw image file data)
     * 
     * ETS signature:
     * static fromArrayBuffer(data: ArrayBuffer, iconId?: string, scale?: number): Icon
     * 
     * @param env NAPI environment
     * @param info Callback info
     * @return Icon NAPI object
     */
    static napi_value FromArrayBuffer(napi_env env, napi_callback_info info);
    
    /**
     * Create Icon from Uint8Array (raw image file data)
     * 
     * ETS signature:
     * static fromResourceData(data: Uint8Array, iconId?: string, scale?: number): Icon
     * 
     * @param env NAPI environment
     * @param info Callback info
     * @return Icon NAPI object
     */
    static napi_value FromResourceData(napi_env env, napi_callback_info info);
    
    /**
     * Create Icon from rawfile resource
     * 
     * ETS signature:
     * static fromRawfile(fileName: string, iconId?: string, scale?: number): Icon
     * 
     * @param env NAPI environment
     * @param info Callback info
     * @return Icon NAPI object
     */
    static napi_value FromRawfile(napi_env env, napi_callback_info info);
    
    /**
     * Create Icon from file path
     * 
     * ETS signature:
     * static fromFilePath(path: string, iconId?: string, scale?: number): Icon
     * 
     * @param env NAPI environment
     * @param info Callback info
     * @return Icon NAPI object
     */
    static napi_value FromFilePath(napi_env env, napi_callback_info info);
    
    /**
     * Create default marker icon (programmatically generated)
     * 
     * ETS signature:
     * static createDefaultMarker(iconId?: string, size?: number): Icon
     * 
     * @param env NAPI environment
     * @param info Callback info
     * @return Icon NAPI object
     */
    static napi_value CreateDefaultMarker(napi_env env, napi_callback_info info);
    
    /**
     * Generate unique icon ID
     * 
     * @return Unique icon ID string
     */
    static std::string generateIconId();
    
    // Icon ID counter
    static int nextIconId;
};

} // namespace harmony
} // namespace maplibre

