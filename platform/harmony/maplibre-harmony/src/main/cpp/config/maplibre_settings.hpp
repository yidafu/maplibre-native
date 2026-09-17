#ifndef MAPLIBRE_HARMONY_MAPLIBRE_SETTINGS_HPP
#define MAPLIBRE_HARMONY_MAPLIBRE_SETTINGS_HPP

#include <mbgl/storage/resource_options.hpp>
#include <mbgl/util/tile_server_options.hpp>
#include <string>
#include <mutex>

namespace mbgl {
namespace harmony {

/**
 * MapLibreSettings - global configuration singleton.
 *
 * Manages global tile server configuration and API keys.
 * Every map instance uses the configuration defined here when created.
 *
 * Thread-safety: all public methods are protected by a mutex.
 *
 * Usage:
 * ```cpp
 * // Configure during application startup
 * MapLibreSettings::getInstance().useMapboxConfiguration();
 * MapLibreSettings::getInstance().setApiKey("your_token");
 * 
 * // Apply configuration when creating a map
 * ResourceOptions options = MapLibreSettings::getInstance().applyToResourceOptions(resourceOptions);
 * ```
 */
class MapLibreSettings {
public:
    /**
     * Retrieve the singleton instance.
     */
    static MapLibreSettings& getInstance();
    
    /**
     * Set the tile server options.
     * @param options TileServerOptions configuration
     */
    void setTileServerOptions(const mbgl::TileServerOptions& options);
    
    /**
     * Obtain the current tile server options.
     * @return A copy of TileServerOptions
     */
    mbgl::TileServerOptions getTileServerOptions() const;
    
    /**
     * Apply Mapbox configuration (requires an access token).
     * - Supports mapbox:// URLs
     * - baseURL: https://api.mapbox.com
     * - Requires setting an API key
     */
    void useMapboxConfiguration();
    
    /**
     * Apply MapTiler configuration (requires an API key).
     * - Supports maptiler:// URLs
     * - baseURL: https://api.maptiler.com
     * - Requires setting an API key
     */
    void useMapTilerConfiguration();
    
    /**
     * Apply MapLibre default configuration (open source, no token required).
     * - Supports maplibre:// URLs
     * - baseURL: https://demotiles.maplibre.org
     * - Does not require an API key
     */
    void useMapLibreConfiguration();
    
    /**
     * Set the API key / access token.
     * @param apiKey API key string
     */
    void setApiKey(const std::string& apiKey);
    
    /**
     * Get the current API key.
     * @return API key string
     */
    std::string getApiKey() const;
    
    /**
     * Set a custom base URL.
     * @param baseURL Base URL (e.g., https://api.example.com)
     */
    void setBaseURL(const std::string& baseURL);
    
    /**
     * Get the current base URL.
     * @return Base URL string
     */
    std::string getBaseURL() const;
    
    /**
     * Apply the global configuration to ResourceOptions.
     *
     * This method copies the current TileServerOptions and API key
     * into the provided ResourceOptions object.
     *
     * @param options ResourceOptions to update
     * @return Updated ResourceOptions
     */
    mbgl::ResourceOptions applyToResourceOptions(mbgl::ResourceOptions options) const;

private:
    MapLibreSettings();
    ~MapLibreSettings() = default;
    
    // Disable copy and assignment
    MapLibreSettings(const MapLibreSettings&) = delete;
    MapLibreSettings& operator=(const MapLibreSettings&) = delete;
    
    mutable std::mutex mutex_;
    mbgl::TileServerOptions tileServerOptions_;
    std::string apiKey_;
};

} // namespace harmony
} // namespace mbgl

#endif // MAPLIBRE_HARMONY_MAPLIBRE_SETTINGS_HPP

