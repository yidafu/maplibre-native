#include "http_request_config.hpp"
#include "utils/logger.h"

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

HTTPRequestConfig& HTTPRequestConfig::getInstance() {
    static HTTPRequestConfig instance;
    return instance;
}

void HTTPRequestConfig::setCustomHeaders(const std::map<std::string, std::string>& headers) {
    std::lock_guard<std::mutex> lock(mutex_);
    customHeaders_ = headers;
    
    Logger::info("HTTPRequestConfig", "Set custom headers: %zu headers configured", headers.size());
    for (const auto& [key, value] : headers) {
        // 不记录敏感信息的完整值，只记录键名
        Logger::debug("HTTPRequestConfig", "  Header: %s", key.c_str());
    }
}

void HTTPRequestConfig::addCustomHeader(const std::string& key, const std::string& value) {
    std::lock_guard<std::mutex> lock(mutex_);
    
    // 检查是否为保留的请求头
    std::string lowerKey = key;
    std::transform(lowerKey.begin(), lowerKey.end(), lowerKey.begin(), ::tolower);
    
    if (lowerKey == "user-agent") {
        Logger::warn("HTTPRequestConfig", "Cannot override User-Agent header");
        return;
    }
    
    customHeaders_[key] = value;
    Logger::debug("HTTPRequestConfig", "Added custom header: %s", key.c_str());
}

bool HTTPRequestConfig::removeCustomHeader(const std::string& key) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = customHeaders_.find(key);
    if (it != customHeaders_.end()) {
        customHeaders_.erase(it);
        Logger::debug("HTTPRequestConfig", "Removed custom header: %s", key.c_str());
        return true;
    }
    return false;
}

void HTTPRequestConfig::clearCustomHeaders() {
    std::lock_guard<std::mutex> lock(mutex_);
    size_t count = customHeaders_.size();
    customHeaders_.clear();
    Logger::info("HTTPRequestConfig", "Cleared all custom headers (removed %zu headers)", count);
}

std::map<std::string, std::string> HTTPRequestConfig::getCustomHeaders() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return customHeaders_;
}

bool HTTPRequestConfig::hasCustomHeader(const std::string& key) const {
    std::lock_guard<std::mutex> lock(mutex_);
    return customHeaders_.find(key) != customHeaders_.end();
}

} // namespace harmony
} // namespace mbgl

