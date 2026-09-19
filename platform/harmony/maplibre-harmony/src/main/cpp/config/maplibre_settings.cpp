#include "maplibre_settings.hpp"
#include <mln/util/logging.hpp>

namespace mln {
namespace harmony {

MapLibreSettings::MapLibreSettings() {
    // Default to the MapLibre open-source configuration
    tileServerOptions_ = mln::TileServerOptions::MapLibreConfiguration();
    apiKey_ = "";
}

MapLibreSettings& MapLibreSettings::getInstance() {
    static MapLibreSettings instance;
    return instance;
}

void MapLibreSettings::setTileServerOptions(const mln::TileServerOptions& options) {
    std::lock_guard<std::mutex> lock(mutex_);
    tileServerOptions_ = options.clone();
    
    Log::Info(mln::Event::General, 
        "MapLibreSettings: TileServerOptions updated - baseURL: " + tileServerOptions_.baseURL() + 
        ", uriScheme: " + tileServerOptions_.uriSchemeAlias());
}

mln::TileServerOptions MapLibreSettings::getTileServerOptions() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return tileServerOptions_.clone();
}

void MapLibreSettings::useMapboxConfiguration() {
    std::lock_guard<std::mutex> lock(mutex_);
    tileServerOptions_ = mln::TileServerOptions::MapboxConfiguration();
    
    Log::Info(mln::Event::General, "MapLibreSettings: Switched to Mapbox configuration");
}

void MapLibreSettings::useMapTilerConfiguration() {
    std::lock_guard<std::mutex> lock(mutex_);
    tileServerOptions_ = mln::TileServerOptions::MapTilerConfiguration();
    
    Log::Info(mln::Event::General, "MapLibreSettings: Switched to MapTiler configuration");
}

void MapLibreSettings::useMapLibreConfiguration() {
    std::lock_guard<std::mutex> lock(mutex_);
    tileServerOptions_ = mln::TileServerOptions::MapLibreConfiguration();
    
    Log::Info(mln::Event::General, "MapLibreSettings: Switched to MapLibre configuration");
}

void MapLibreSettings::setApiKey(const std::string& apiKey) {
    std::lock_guard<std::mutex> lock(mutex_);
    apiKey_ = apiKey;
    
    // Log only whether a token is set—never the value (security)
    if (!apiKey_.empty()) {
        Log::Info(mln::Event::General, 
            "MapLibreSettings: API Key set (length: " + std::to_string(apiKey_.length()) + ")");
    } else {
        Log::Info(mln::Event::General, "MapLibreSettings: API Key cleared");
    }
}

std::string MapLibreSettings::getApiKey() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return apiKey_;
}

void MapLibreSettings::setBaseURL(const std::string& baseURL) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto newOptions = tileServerOptions_.clone().withBaseURL(baseURL);
    tileServerOptions_ = std::move(newOptions);
    
    Log::Info(mln::Event::General, "MapLibreSettings: Base URL set to: " + baseURL);
}

std::string MapLibreSettings::getBaseURL() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return tileServerOptions_.baseURL();
}

mln::ResourceOptions MapLibreSettings::applyToResourceOptions(mln::ResourceOptions options) const {
    std::lock_guard<std::mutex> lock(mutex_);
    
    // Apply the TileServerOptions
    options.withTileServerOptions(tileServerOptions_.clone());
    
    // Apply the API key
    if (!apiKey_.empty()) {
        options.withApiKey(apiKey_);
    }
    
    Log::Info(mln::Event::General, 
        "MapLibreSettings: Applied configuration to ResourceOptions - baseURL: " + 
        tileServerOptions_.baseURL() + ", hasApiKey: " + (apiKey_.empty() ? "false" : "true"));
    
    return options;
}

} // namespace harmony
} // namespace mln

