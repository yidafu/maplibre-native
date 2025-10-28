#pragma once

#include <mbgl/util/chrono.hpp>
#include <mbgl/util/noncopyable.hpp>
#include <string>
#include <map>
#include <vector>
#include <mutex>
#include <memory>
#include <functional>

namespace mbgl {
namespace harmony {

/**
 * @brief HTTP请求统计信息
 */
struct HttpRequestStats {
    size_t totalRequests = 0;
    size_t successRequests = 0;
    size_t failedRequests = 0;
    size_t pendingRequests = 0;
    
    Duration totalDuration = Duration::zero();
    Duration avgDuration = Duration::zero();
    Duration maxDuration = Duration::zero();
    Duration minDuration = Duration::max();
    
    size_t totalBytes = 0;
    
    float getSuccessRate() const {
        if (totalRequests == 0) return 0.0f;
        return static_cast<float>(successRequests) / totalRequests;
    }
};

/**
 * @brief 缓存统计信息
 */
struct CacheStats {
    size_t totalQueries = 0;
    size_t cacheHits = 0;
    size_t cacheMisses = 0;
    size_t cacheSize = 0;
    size_t maxCacheSize = 0;
    
    float getHitRate() const {
        if (totalQueries == 0) return 0.0f;
        return static_cast<float>(cacheHits) / totalQueries;
    }
};

/**
 * @brief 告警类型
 */
enum class AlertType {
    HighFailureRate,      // 失败率过高
    SlowResponse,         // 响应慢
    LowCacheHitRate,      // 缓存命中率低
    StyleLoadTimeout,     // Style加载超时
    NetworkError          // 网络错误
};

/**
 * @brief 告警信息
 */
struct AlertInfo {
    AlertType type;
    std::string message;
    TimePoint timestamp;
    std::map<std::string, std::string> details;
};

/**
 * @brief 资源监控观察者
 */
class ResourceMonitorObserver {
public:
    virtual ~ResourceMonitorObserver() = default;
    
    virtual void onAlert(const AlertInfo& alert) = 0;
    virtual void onStatsUpdated(const HttpRequestStats& httpStats,
                               const CacheStats& cacheStats) = 0;
};

/**
 * @brief 资源加载监控器
 * 
 * 集中监控所有资源加载活动，包括HTTP请求、缓存访问等
 * 提供统计数据和异常告警功能
 */
class ResourceMonitor : public util::noncopyable {
public:
    static ResourceMonitor& getInstance();
    
    ~ResourceMonitor();
    
    // 启用/禁用监控
    void enable();
    void disable();
    bool isEnabled() const { return enabled_; }
    
    // HTTP请求监控
    void trackHttpRequestStart(const std::string& url);
    void trackHttpRequestSuccess(const std::string& url, size_t bytes, Duration duration);
    void trackHttpRequestFailure(const std::string& url, const std::string& error);
    
    // 缓存监控
    void trackCacheQuery(const std::string& key, bool hit);
    void updateCacheSize(size_t size, size_t maxSize);
    
    // 获取统计信息
    HttpRequestStats getHttpStats() const;
    CacheStats getCacheStats() const;
    std::vector<AlertInfo> getAlerts() const;
    
    // 观察者模式
    void addObserver(std::shared_ptr<ResourceMonitorObserver> observer);
    void removeObserver(std::shared_ptr<ResourceMonitorObserver> observer);
    
    // 重置统计
    void reset();
    
    // 配置告警阈值
    void setFailureRateThreshold(float threshold);
    void setSlowResponseThreshold(Duration threshold);
    void setCacheHitRateThreshold(float threshold);
    void setStyleLoadTimeoutThreshold(Duration threshold);
    
    // 导出监控报告
    std::string exportReport() const;
    
private:
    ResourceMonitor();
    
    void checkAlerts();
    void triggerAlert(AlertType type, const std::string& message,
                     const std::map<std::string, std::string>& details = {});
    void updateHttpStats();
    
    mutable std::mutex mutex_;
    bool enabled_;
    
    HttpRequestStats httpStats_;
    CacheStats cacheStats_;
    std::vector<AlertInfo> alerts_;
    
    std::map<std::string, TimePoint> pendingRequests_;
    
    // 告警阈值
    float failureRateThreshold_;
    Duration slowResponseThreshold_;
    float cacheHitRateThreshold_;
    Duration styleLoadTimeoutThreshold_;
    
    // 连续失败计数
    size_t consecutiveFailures_;
    static constexpr size_t MAX_CONSECUTIVE_FAILURES = 5;
    
    std::vector<std::shared_ptr<ResourceMonitorObserver>> observers_;
};

} // namespace harmony
} // namespace mbgl

