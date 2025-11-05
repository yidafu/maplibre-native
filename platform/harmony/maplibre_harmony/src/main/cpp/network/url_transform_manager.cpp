#include "url_transform_manager.hpp"
#include "utils/logger.h"

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

URLTransformManager& URLTransformManager::getInstance() {
    static URLTransformManager instance;
    return instance;
}

void URLTransformManager::setTransformCallback(TransformCallback callback) {
    std::lock_guard<std::mutex> lock(mutex_);
    callback_ = std::move(callback);
    
    if (callback_) {
        Logger::info("URLTransformManager", "URL transform callback set");
    } else {
        Logger::info("URLTransformManager", "URL transform callback cleared (null callback provided)");
    }
}

void URLTransformManager::clearTransformCallback() {
    std::lock_guard<std::mutex> lock(mutex_);
    callback_ = nullptr;
    Logger::info("URLTransformManager", "URL transform callback cleared");
}

bool URLTransformManager::hasCallback() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return callback_ != nullptr;
}

std::string URLTransformManager::transform(mbgl::Resource::Kind kind, const std::string& url) {
    std::lock_guard<std::mutex> lock(mutex_);
    
    // 如果没有设置回调，直接返回原URL
    if (!callback_) {
        return url;
    }
    
    try {
        // 调用回调函数进行URL转换
        std::string transformedUrl = callback_(kind, url);
        
        // 如果回调返回空字符串，使用原URL
        if (transformedUrl.empty()) {
            Logger::warn("URLTransformManager", "Transform callback returned empty string, using original URL");
            return url;
        }
        
        // 记录转换（仅在URL确实改变时）
        if (transformedUrl != url) {
            Logger::debug("URLTransformManager", "URL transformed:");
            Logger::debug("URLTransformManager", "  Kind: %d", static_cast<int>(kind));
            Logger::debug("URLTransformManager", "  Original: %s", url.c_str());
            Logger::debug("URLTransformManager", "  Transformed: %s", transformedUrl.c_str());
        }
        
        return transformedUrl;
        
    } catch (const std::exception& e) {
        // 捕获异常，记录错误，返回原URL
        Logger::error("URLTransformManager", "Exception in transform callback: %s", e.what());
        Logger::error("URLTransformManager", "Using original URL: %s", url.c_str());
        return url;
        
    } catch (...) {
        // 捕获所有其他异常
        Logger::error("URLTransformManager", "Unknown exception in transform callback");
        Logger::error("URLTransformManager", "Using original URL: %s", url.c_str());
        return url;
    }
}

} // namespace harmony
} // namespace mbgl

