#pragma once

#include <string>
#include <map>
#include <mutex>
#include <memory>

namespace mbgl {
namespace harmony {

/**
 * HTTPRequestConfig - global configuration for HTTP requests.
 *
 * Provides thread-safe management of custom HTTP headers, allowing developers
 * to attach headers to every map resource request.
 *
 * Design notes:
 * - Singleton: only one configuration instance globally
 * - Thread-safe: mutex protects shared data
 * - Global scope: all map instances share the configuration
 *
 * References:
 * - Android: HttpRequestUtil.setOkHttpClient()
 * - iOS: MLNNetworkConfiguration.sessionConfiguration.HTTPAdditionalHeaders
 */
class HTTPRequestConfig {
public:
    /**
     * Retrieve the singleton instance.
     */
    static HTTPRequestConfig& getInstance();

    /**
     * Set custom HTTP headers (replacing any existing headers).
     *
     * @param headers Header key-value pairs
     */
    void setCustomHeaders(const std::map<std::string, std::string>& headers);

    /**
     * Add a single custom HTTP header.
     *
     * @param key Header name
     * @param value Header value
     */
    void addCustomHeader(const std::string& key, const std::string& value);

    /**
     * Remove a specific custom HTTP header.
     *
     * @param key Header name
     * @return true if removed, false if not present
     */
    bool removeCustomHeader(const std::string& key);

    /**
     * Clear all custom HTTP headers.
     */
    void clearCustomHeaders();

    /**
     * Retrieve a copy of all custom HTTP headers.
     *
     * @return Copy of header key-value pairs
     */
    std::map<std::string, std::string> getCustomHeaders() const;

    /**
     * Check whether a specific header exists.
     *
     * @param key Header name
     * @return true if the header exists, false otherwise
     */
    bool hasCustomHeader(const std::string& key) const;

    // Disable copying and assignment
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

