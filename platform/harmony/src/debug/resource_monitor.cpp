#include "resource_monitor.hpp"
#include <mbgl/util/logging.hpp>
#include <algorithm>
#include <sstream>
#include <iomanip>

namespace mbgl {
namespace harmony {

namespace {
const char* TAG = "ResourceMonitor";

const char* alertTypeToString(AlertType type) {
    switch (type) {
        case AlertType::HighFailureRate: return "HighFailureRate";
        case AlertType::SlowResponse: return "SlowResponse";
        case AlertType::LowCacheHitRate: return "LowCacheHitRate";
        case AlertType::StyleLoadTimeout: return "StyleLoadTimeout";
        case AlertType::NetworkError: return "NetworkError";
    }
    return "Unknown";
}
} // namespace

ResourceMonitor& ResourceMonitor::getInstance() {
    static ResourceMonitor instance;
    return instance;
}

ResourceMonitor::ResourceMonitor()
    : enabled_(false)
    , failureRateThreshold_(0.2f)       // 20% 失败率
    , slowResponseThreshold_(std::chrono::seconds(10))
    , cacheHitRateThreshold_(0.2f)      // 20% 缓存命中率
    , styleLoadTimeoutThreshold_(std::chrono::seconds(30))
    , consecutiveFailures_(0) {
}

ResourceMonitor::~ResourceMonitor() {
    observers_.clear();
}

void ResourceMonitor::enable() {
    std::lock_guard<std::mutex> lock(mutex_);
    enabled_ = true;
    Log::Info(Event::General, "%s: Monitoring enabled", TAG);
}

void ResourceMonitor::disable() {
    std::lock_guard<std::mutex> lock(mutex_);
    enabled_ = false;
    Log::Info(Event::General, "%s: Monitoring disabled", TAG);
}

void ResourceMonitor::trackHttpRequestStart(const std::string& url) {
    if (!enabled_) return;
    
    std::lock_guard<std::mutex> lock(mutex_);
    
    pendingRequests_[url] = Clock::now();
    httpStats_.totalRequests++;
    httpStats_.pendingRequests++;
    
    Log::Debug(Event::General, "%s: HTTP request started: %s (pending: %zu)",
               TAG, url.c_str(), httpStats_.pendingRequests);
}

void ResourceMonitor::trackHttpRequestSuccess(const std::string& url, size_t bytes, Duration duration) {
    if (!enabled_) return;
    
    std::lock_guard<std::mutex> lock(mutex_);
    
    auto it = pendingRequests_.find(url);
    if (it != pendingRequests_.end()) {
        pendingRequests_.erase(it);
        httpStats_.pendingRequests--;
    }
    
    httpStats_.successRequests++;
    httpStats_.totalBytes += bytes;
    httpStats_.totalDuration += duration;
    
    // 更新统计
    httpStats_.maxDuration = std::max(httpStats_.maxDuration, duration);
    httpStats_.minDuration = std::min(httpStats_.minDuration, duration);
    
    updateHttpStats();
    
    // 重置连续失败计数
    consecutiveFailures_ = 0;
    
    // 检查慢响应
    if (duration > slowResponseThreshold_) {
        std::map<std::string, std::string> details;
        details["url"] = url;
        details["duration"] = std::to_string(
            std::chrono::duration<double>(duration).count());
        triggerAlert(AlertType::SlowResponse,
                    "HTTP request took longer than threshold",
                    details);
    }
    
    Log::Debug(Event::General, "%s: HTTP request succeeded: %s (%.2f KB in %.2f ms)",
               TAG, url.c_str(), bytes / 1024.0,
               std::chrono::duration<double, std::milli>(duration).count());
    
    // 通知观察者
    for (auto& observer : observers_) {
        if (observer) {
            observer->onStatsUpdated(httpStats_, cacheStats_);
        }
    }
}

void ResourceMonitor::trackHttpRequestFailure(const std::string& url, const std::string& error) {
    if (!enabled_) return;
    
    std::lock_guard<std::mutex> lock(mutex_);
    
    auto it = pendingRequests_.find(url);
    if (it != pendingRequests_.end()) {
        pendingRequests_.erase(it);
        httpStats_.pendingRequests--;
    }
    
    httpStats_.failedRequests++;
    consecutiveFailures_++;
    
    updateHttpStats();
    
    // 检查失败率
    if (httpStats_.getSuccessRate() < (1.0f - failureRateThreshold_) &&
        httpStats_.totalRequests >= 10) {
        std::map<std::string, std::string> details;
        details["failureRate"] = std::to_string(1.0f - httpStats_.getSuccessRate());
        details["totalRequests"] = std::to_string(httpStats_.totalRequests);
        details["failedRequests"] = std::to_string(httpStats_.failedRequests);
        triggerAlert(AlertType::HighFailureRate,
                    "HTTP request failure rate exceeds threshold",
                    details);
    }
    
    // 检查连续失败
    if (consecutiveFailures_ >= MAX_CONSECUTIVE_FAILURES) {
        std::map<std::string, std::string> details;
        details["consecutiveFailures"] = std::to_string(consecutiveFailures_);
        details["lastError"] = error;
        details["lastUrl"] = url;
        triggerAlert(AlertType::NetworkError,
                    "Multiple consecutive HTTP request failures",
                    details);
    }
    
    Log::Warning(Event::General, "%s: HTTP request failed: %s (error: %s, consecutive failures: %zu)",
                 TAG, url.c_str(), error.c_str(), consecutiveFailures_);
    
    // 通知观察者
    for (auto& observer : observers_) {
        if (observer) {
            observer->onStatsUpdated(httpStats_, cacheStats_);
        }
    }
}

void ResourceMonitor::trackCacheQuery(const std::string& key, bool hit) {
    if (!enabled_) return;
    
    std::lock_guard<std::mutex> lock(mutex_);
    
    cacheStats_.totalQueries++;
    if (hit) {
        cacheStats_.cacheHits++;
    } else {
        cacheStats_.cacheMisses++;
    }
    
    // 检查缓存命中率
    if (cacheStats_.totalQueries >= 20 &&
        cacheStats_.getHitRate() < cacheHitRateThreshold_) {
        std::map<std::string, std::string> details;
        details["hitRate"] = std::to_string(cacheStats_.getHitRate());
        details["totalQueries"] = std::to_string(cacheStats_.totalQueries);
        details["cacheHits"] = std::to_string(cacheStats_.cacheHits);
        triggerAlert(AlertType::LowCacheHitRate,
                    "Cache hit rate is below threshold",
                    details);
    }
    
    Log::Debug(Event::General, "%s: Cache query: %s (hit: %d, hit rate: %.2f%%)",
               TAG, key.c_str(), hit, cacheStats_.getHitRate() * 100);
}

void ResourceMonitor::updateCacheSize(size_t size, size_t maxSize) {
    if (!enabled_) return;
    
    std::lock_guard<std::mutex> lock(mutex_);
    
    cacheStats_.cacheSize = size;
    cacheStats_.maxCacheSize = maxSize;
    
    Log::Debug(Event::General, "%s: Cache size updated: %zu / %zu (%.1f%%)",
               TAG, size, maxSize, (size * 100.0) / maxSize);
}

HttpRequestStats ResourceMonitor::getHttpStats() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return httpStats_;
}

CacheStats ResourceMonitor::getCacheStats() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return cacheStats_;
}

std::vector<AlertInfo> ResourceMonitor::getAlerts() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return alerts_;
}

void ResourceMonitor::addObserver(std::shared_ptr<ResourceMonitorObserver> observer) {
    if (!observer) return;
    
    std::lock_guard<std::mutex> lock(mutex_);
    observers_.push_back(observer);
    Log::Info(Event::General, "%s: Observer added (total: %zu)", TAG, observers_.size());
}

void ResourceMonitor::removeObserver(std::shared_ptr<ResourceMonitorObserver> observer) {
    if (!observer) return;
    
    std::lock_guard<std::mutex> lock(mutex_);
    observers_.erase(
        std::remove(observers_.begin(), observers_.end(), observer),
        observers_.end()
    );
    Log::Info(Event::General, "%s: Observer removed (total: %zu)", TAG, observers_.size());
}

void ResourceMonitor::reset() {
    std::lock_guard<std::mutex> lock(mutex_);
    
    httpStats_ = HttpRequestStats();
    cacheStats_ = CacheStats();
    alerts_.clear();
    pendingRequests_.clear();
    consecutiveFailures_ = 0;
    
    Log::Info(Event::General, "%s: Statistics reset", TAG);
}

void ResourceMonitor::setFailureRateThreshold(float threshold) {
    std::lock_guard<std::mutex> lock(mutex_);
    failureRateThreshold_ = threshold;
    Log::Info(Event::General, "%s: Failure rate threshold set to %.2f%%",
              TAG, threshold * 100);
}

void ResourceMonitor::setSlowResponseThreshold(Duration threshold) {
    std::lock_guard<std::mutex> lock(mutex_);
    slowResponseThreshold_ = threshold;
    Log::Info(Event::General, "%s: Slow response threshold set to %.2f seconds",
              TAG, std::chrono::duration<double>(threshold).count());
}

void ResourceMonitor::setCacheHitRateThreshold(float threshold) {
    std::lock_guard<std::mutex> lock(mutex_);
    cacheHitRateThreshold_ = threshold;
    Log::Info(Event::General, "%s: Cache hit rate threshold set to %.2f%%",
              TAG, threshold * 100);
}

void ResourceMonitor::setStyleLoadTimeoutThreshold(Duration threshold) {
    std::lock_guard<std::mutex> lock(mutex_);
    styleLoadTimeoutThreshold_ = threshold;
    Log::Info(Event::General, "%s: Style load timeout threshold set to %.2f seconds",
              TAG, std::chrono::duration<double>(threshold).count());
}

void ResourceMonitor::triggerAlert(AlertType type, const std::string& message,
                                  const std::map<std::string, std::string>& details) {
    AlertInfo alert;
    alert.type = type;
    alert.message = message;
    alert.timestamp = Clock::now();
    alert.details = details;
    
    alerts_.push_back(alert);
    
    Log::Warning(Event::General, "%s: ALERT [%s] %s",
                 TAG, alertTypeToString(type), message.c_str());
    
    // 通知观察者
    for (auto& observer : observers_) {
        if (observer) {
            observer->onAlert(alert);
        }
    }
}

void ResourceMonitor::updateHttpStats() {
    if (httpStats_.successRequests > 0) {
        httpStats_.avgDuration = httpStats_.totalDuration / httpStats_.successRequests;
    }
}

std::string ResourceMonitor::exportReport() const {
    std::lock_guard<std::mutex> lock(mutex_);
    
    std::ostringstream oss;
    oss << std::fixed << std::setprecision(2);
    
    oss << "{\n";
    oss << "  \"http\": {\n";
    oss << "    \"totalRequests\": " << httpStats_.totalRequests << ",\n";
    oss << "    \"successRequests\": " << httpStats_.successRequests << ",\n";
    oss << "    \"failedRequests\": " << httpStats_.failedRequests << ",\n";
    oss << "    \"pendingRequests\": " << httpStats_.pendingRequests << ",\n";
    oss << "    \"successRate\": " << (httpStats_.getSuccessRate() * 100) << ",\n";
    oss << "    \"totalBytes\": " << httpStats_.totalBytes << ",\n";
    oss << "    \"avgDuration\": " 
        << std::chrono::duration<double, std::milli>(httpStats_.avgDuration).count() << ",\n";
    oss << "    \"maxDuration\": " 
        << std::chrono::duration<double, std::milli>(httpStats_.maxDuration).count() << ",\n";
    oss << "    \"minDuration\": " 
        << std::chrono::duration<double, std::milli>(httpStats_.minDuration).count() << "\n";
    oss << "  },\n";
    
    oss << "  \"cache\": {\n";
    oss << "    \"totalQueries\": " << cacheStats_.totalQueries << ",\n";
    oss << "    \"cacheHits\": " << cacheStats_.cacheHits << ",\n";
    oss << "    \"cacheMisses\": " << cacheStats_.cacheMisses << ",\n";
    oss << "    \"hitRate\": " << (cacheStats_.getHitRate() * 100) << ",\n";
    oss << "    \"cacheSize\": " << cacheStats_.cacheSize << ",\n";
    oss << "    \"maxCacheSize\": " << cacheStats_.maxCacheSize << "\n";
    oss << "  },\n";
    
    oss << "  \"alerts\": [\n";
    bool first = true;
    for (const auto& alert : alerts_) {
        if (!first) oss << ",\n";
        first = false;
        oss << "    {\n";
        oss << "      \"type\": \"" << alertTypeToString(alert.type) << "\",\n";
        oss << "      \"message\": \"" << alert.message << "\",\n";
        oss << "      \"details\": {\n";
        bool firstDetail = true;
        for (const auto& detail : alert.details) {
            if (!firstDetail) oss << ",\n";
            firstDetail = false;
            oss << "        \"" << detail.first << "\": \"" << detail.second << "\"";
        }
        oss << "\n      }\n";
        oss << "    }";
    }
    oss << "\n  ]\n";
    oss << "}\n";
    
    return oss.str();
}

} // namespace harmony
} // namespace mbgl

