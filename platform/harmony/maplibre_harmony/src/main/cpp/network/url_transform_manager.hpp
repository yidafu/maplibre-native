#pragma once

#include <mbgl/storage/resource.hpp>
#include <string>
#include <functional>
#include <mutex>
#include <memory>

namespace mbgl {
namespace harmony {

/**
 * URLTransformManager - global manager for URL transformation callbacks.
 *
 * Provides thread-safe URL transformation so developers can intercept and
 * modify resource URLs at runtime.
 *
 * Design notes:
 * - Singleton: only one manager instance globally
 * - Thread-safe: mutex guards callback access
 * - Synchronous callbacks: transformations run on the requesting thread
 *
 * References:
 * - Android: FileSource.setResourceTransform()
 * - iOS: MLNOfflineStorageDelegate.offlineStorage:URLForResourceOfKind:withURL:
 *
 * Use cases:
 * - CDN switching: redirect requests to different servers
 * - Offline resource mapping: map online URLs to local files
 * - URL parameter injection: append auth tokens or query parameters
 * - Resource routing: choose services based on resource type
 */
class URLTransformManager {
public:
    /**
     * Signature for URL transformation callbacks.
     *
     * @param kind Resource kind (Style, Tile, Glyphs, etc.)
     * @param url Original URL
     * @return Transformed URL; returning an empty string keeps the original URL
     */
    using TransformCallback = std::function<std::string(mbgl::Resource::Kind kind, const std::string& url)>;

    /**
     * Retrieve the singleton instance.
     */
    static URLTransformManager& getInstance();

    /**
     * Set the URL transformation callback.
     *
     * Invoked before every resource request, allowing the URL to be modified.
     *
     * @param callback Transformation callback
     *
     * @note Return promptly to avoid blocking the request thread.
     * @note Exceptions are caught and logged; the original URL will be used.
     */
    void setTransformCallback(TransformCallback callback);

    /**
     * Clear the transformation callback.
     *
     * After clearing, all requests proceed with their original URLs.
     */
    void clearTransformCallback();

    /**
     * Determine whether a transformation callback is set.
     *
     * @return true if a callback is present, false otherwise
     */
    bool hasCallback() const;

    /**
     * Perform a URL transformation.
     *
     * If a callback is set, it is invoked; otherwise the original URL is returned.
     *
     * @param kind Resource kind
     * @param url Original URL
     * @return Transformed URL
     *
     * @note Thread-safe; may be called from any thread.
     * @note If the callback returns an empty string or throws, the original URL is used.
     */
    std::string transform(mbgl::Resource::Kind kind, const std::string& url);

    // Disable copying and assignment
    URLTransformManager(const URLTransformManager&) = delete;
    URLTransformManager& operator=(const URLTransformManager&) = delete;

private:
    URLTransformManager() = default;
    ~URLTransformManager() = default;

    mutable std::mutex mutex_;
    TransformCallback callback_;
};

} // namespace harmony
} // namespace mbgl

