#ifndef MAPLIBRE_HARMONY_MAPLIBRE_SETTINGS_HPP
#define MAPLIBRE_HARMONY_MAPLIBRE_SETTINGS_HPP

#include <mbgl/storage/resource_options.hpp>
#include <mbgl/util/tile_server_options.hpp>
#include <string>
#include <mutex>

namespace mbgl {
namespace harmony {

/**
 * MapLibreSettings - 全局配置管理单例
 * 
 * 负责管理全局的瓦片服务器配置和 API Key。
 * 所有地图实例在创建时会自动使用这里配置的设置。
 * 
 * 线程安全：所有公共方法都使用互斥锁保护。
 * 
 * 使用方式：
 * ```cpp
 * // 在应用启动时配置
 * MapLibreSettings::getInstance().useMapboxConfiguration();
 * MapLibreSettings::getInstance().setApiKey("your_token");
 * 
 * // 在创建地图时应用配置
 * ResourceOptions options = MapLibreSettings::getInstance().applyToResourceOptions(resourceOptions);
 * ```
 */
class MapLibreSettings {
public:
    /**
     * 获取单例实例
     */
    static MapLibreSettings& getInstance();
    
    /**
     * 设置瓦片服务器配置
     * @param options TileServerOptions 配置
     */
    void setTileServerOptions(const mbgl::TileServerOptions& options);
    
    /**
     * 获取当前瓦片服务器配置
     * @return TileServerOptions 的副本
     */
    mbgl::TileServerOptions getTileServerOptions() const;
    
    /**
     * 使用 Mapbox 配置（需要 Access Token）
     * - 支持 mapbox:// 协议 URL
     * - baseURL: https://api.mapbox.com
     * - 需要设置 API Key
     */
    void useMapboxConfiguration();
    
    /**
     * 使用 MapTiler 配置（需要 API Key）
     * - 支持 maptiler:// 协议 URL
     * - baseURL: https://api.maptiler.com
     * - 需要设置 API Key
     */
    void useMapTilerConfiguration();
    
    /**
     * 使用 MapLibre 默认配置（开源，无需 token）
     * - 支持 maplibre:// 协议 URL
     * - baseURL: https://demotiles.maplibre.org
     * - 不需要 API Key
     */
    void useMapLibreConfiguration();
    
    /**
     * 设置 API Key / Access Token
     * @param apiKey API Key 字符串
     */
    void setApiKey(const std::string& apiKey);
    
    /**
     * 获取当前 API Key
     * @return API Key 字符串
     */
    std::string getApiKey() const;
    
    /**
     * 设置自定义 Base URL
     * @param baseURL 基础 URL（如 https://api.example.com）
     */
    void setBaseURL(const std::string& baseURL);
    
    /**
     * 获取当前 Base URL
     * @return Base URL 字符串
     */
    std::string getBaseURL() const;
    
    /**
     * 将全局配置应用到 ResourceOptions
     * 
     * 这个方法会将当前的 TileServerOptions 和 API Key 配置
     * 应用到传入的 ResourceOptions 对象。
     * 
     * @param options 要应用配置的 ResourceOptions
     * @return 应用配置后的 ResourceOptions
     */
    mbgl::ResourceOptions applyToResourceOptions(mbgl::ResourceOptions options) const;

private:
    MapLibreSettings();
    ~MapLibreSettings() = default;
    
    // 禁止拷贝和赋值
    MapLibreSettings(const MapLibreSettings&) = delete;
    MapLibreSettings& operator=(const MapLibreSettings&) = delete;
    
    mutable std::mutex mutex_;
    mbgl::TileServerOptions tileServerOptions_;
    std::string apiKey_;
};

} // namespace harmony
} // namespace mbgl

#endif // MAPLIBRE_HARMONY_MAPLIBRE_SETTINGS_HPP

