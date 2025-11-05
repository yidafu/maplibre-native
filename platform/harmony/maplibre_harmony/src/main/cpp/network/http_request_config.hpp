#pragma once

#include <string>
#include <map>
#include <mutex>
#include <memory>

namespace mbgl {
namespace harmony {

/**
 * HTTPRequestConfig - 管理HTTP请求的全局配置
 * 
 * 提供线程安全的自定义HTTP请求头管理，允许开发者为所有地图资源请求添加自定义请求头。
 * 
 * 设计说明：
 * - 单例模式：确保全局只有一个配置实例
 * - 线程安全：使用mutex保护共享数据
 * - 全局配置：所有地图实例共享同一配置
 * 
 * 参考实现：
 * - Android: HttpRequestUtil.setOkHttpClient()
 * - iOS: MLNNetworkConfiguration.sessionConfiguration.HTTPAdditionalHeaders
 */
class HTTPRequestConfig {
public:
    /**
     * 获取单例实例
     */
    static HTTPRequestConfig& getInstance();

    /**
     * 设置自定义HTTP请求头（替换所有现有请求头）
     * 
     * @param headers 请求头键值对
     */
    void setCustomHeaders(const std::map<std::string, std::string>& headers);

    /**
     * 添加单个自定义HTTP请求头
     * 
     * @param key 请求头名称
     * @param value 请求头值
     */
    void addCustomHeader(const std::string& key, const std::string& value);

    /**
     * 移除指定的自定义HTTP请求头
     * 
     * @param key 请求头名称
     * @return 如果成功移除返回true，如果不存在返回false
     */
    bool removeCustomHeader(const std::string& key);

    /**
     * 清除所有自定义HTTP请求头
     */
    void clearCustomHeaders();

    /**
     * 获取所有自定义HTTP请求头的副本
     * 
     * @return 请求头键值对的副本
     */
    std::map<std::string, std::string> getCustomHeaders() const;

    /**
     * 检查指定的请求头是否存在
     * 
     * @param key 请求头名称
     * @return 如果存在返回true，否则返回false
     */
    bool hasCustomHeader(const std::string& key) const;

    // 禁止复制和赋值
    HTTPRequestConfig(const HTTPRequestConfig&) = delete;
    HTTPRequestConfig& operator=(const HTTPRequestConfig&) = delete;

private:
    HTTPRequestConfig() = default;
    ~HTTPRequestConfig() = default;

    mutable std::mutex mutex_;
    std::map<std::string, std::string> customHeaders_;
};

} // namespace harmony
} // namespace mbgl

