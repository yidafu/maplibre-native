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
    
    // If no callback is set, return the original URL
    if (!callback_) {
        return url;
    }
    
    try {
        // Invoke the callback to transform the URL
        std::string transformedUrl = callback_(kind, url);
        
        // If the callback returns an empty string, fall back to the original URL
        if (transformedUrl.empty()) {
            Logger::warn("URLTransformManager", "Transform callback returned empty string, using original URL");
            return url;
        }
        
        // Log the transformation only when the URL actually changes
        if (transformedUrl != url) {
            Logger::debug("URLTransformManager", "URL transformed:");
            Logger::debug("URLTransformManager", "  Kind: %d", static_cast<int>(kind));
            Logger::debug("URLTransformManager", "  Original: %s", url.c_str());
            Logger::debug("URLTransformManager", "  Transformed: %s", transformedUrl.c_str());
        }
        
        return transformedUrl;
        
    } catch (const std::exception& e) {
        // Catch exceptions, log the error, and return the original URL
        Logger::error("URLTransformManager", "Exception in transform callback: %s", e.what());
        Logger::error("URLTransformManager", "Using original URL: %s", url.c_str());
        return url;
        
    } catch (...) {
        // Catch any other exceptions
        Logger::error("URLTransformManager", "Unknown exception in transform callback");
        Logger::error("URLTransformManager", "Using original URL: %s", url.c_str());
        return url;
    }
}

} // namespace harmony
} // namespace mbgl

