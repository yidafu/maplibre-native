//
// Created for HarmonyOS logging wrapper
//

#ifndef MAPLIBREHARMONY_LOGGER_H
#define MAPLIBREHARMONY_LOGGER_H

#include <hilog/log.h>

namespace mbgl {
namespace harmony {

// Log domain for MapLibre
// 在 DevEco Studio 日志窗口按需设置域过滤器（0x0000 或 All）。
constexpr unsigned int LOG_PRINT_DOMAIN = 0x0000;

/**
 * Logger class for HarmonyOS hilog system
 * Provides a clean interface for logging messages
 */
class Logger {
public:
    /**
     * Log debug message
     * @param tag Log tag (e.g., "MapLibre", "EGLCore")
     * @param format Printf-style format string
     * @param ... Format arguments
     */
    static void debug(const char* tag, const char* format, ...) __attribute__((format(printf, 2, 3)));

    /**
     * Log info message
     * @param tag Log tag (e.g., "MapLibre", "EGLCore")
     * @param format Printf-style format string
     * @param ... Format arguments
     */
    static void info(const char* tag, const char* format, ...) __attribute__((format(printf, 2, 3)));

    /**
     * Log warning message
     * @param tag Log tag (e.g., "MapLibre", "EGLCore")
     * @param format Printf-style format string
     * @param ... Format arguments
     */
    static void warn(const char* tag, const char* format, ...) __attribute__((format(printf, 2, 3)));

    /**
     * Log error message
     * @param tag Log tag (e.g., "MapLibre", "EGLCore")
     * @param format Printf-style format string
     * @param ... Format arguments
     */
    static void error(const char* tag, const char* format, ...) __attribute__((format(printf, 2, 3)));

private:
    // Private constructor to prevent instantiation
    Logger() = delete;
    ~Logger() = delete;
    Logger(const Logger&) = delete;
    Logger& operator=(const Logger&) = delete;
};

} // namespace harmony
} // namespace mbgl

// 便捷的日志宏定义
#ifndef MBGL_LOG_TAG
#define MBGL_LOG_TAG "MapLibreStyle"
#endif

#define LOGD(...) mbgl::harmony::Logger::debug(MBGL_LOG_TAG, __VA_ARGS__)
#define LOGI(...) mbgl::harmony::Logger::info(MBGL_LOG_TAG, __VA_ARGS__)
#define LOGW(...) mbgl::harmony::Logger::warn(MBGL_LOG_TAG, __VA_ARGS__)
#define LOGE(...) mbgl::harmony::Logger::error(MBGL_LOG_TAG, __VA_ARGS__)

#endif // MAPLIBREHARMONY_LOGGER_H

