#include <mbgl/util/logging.hpp>
#include <mbgl/util/enum.hpp>

// 尝试包含harmony平台的hilog头文件
#if defined(__HARMONY_OS__)
#include <hilog/log.h>
constexpr unsigned int LOG_PRINT_DOMAIN = 0xFF00;
#else
// 回退到标准输出
#include <iostream>
#endif

namespace mbgl {

void Log::platformRecord(EventSeverity severity, const std::string& msg) {
    #if defined(__HARMONY_OS__)
    // Harmony平台的日志记录实现 - 使用OH_LOG_Print输出到鸿蒙hilog系统
    switch (severity) {
        case EventSeverity::Debug:
            OH_LOG_Print(LOG_APP, LOG_DEBUG, LOG_PRINT_DOMAIN, "MAPLIBRE", "[%{public}s] %{public}s", 
                        Enum<EventSeverity>::toString(severity), msg.c_str());
            break;
        case EventSeverity::Info:
            OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, "MAPLIBRE", "[%{public}s] %{public}s", 
                        Enum<EventSeverity>::toString(severity), msg.c_str());
            break;
        case EventSeverity::Warning:
            OH_LOG_Print(LOG_APP, LOG_WARN, LOG_PRINT_DOMAIN, "MAPLIBRE", "[%{public}s] %{public}s", 
                        Enum<EventSeverity>::toString(severity), msg.c_str());
            break;
        case EventSeverity::Error:
            OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_PRINT_DOMAIN, "MAPLIBRE", "[%{public}s] %{public}s", 
                        Enum<EventSeverity>::toString(severity), msg.c_str());
            break;
        default:
            OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, "MAPLIBRE", "[%{public}s] %{public}s", 
                        Enum<EventSeverity>::toString(severity), msg.c_str());
            break;
    }
    #else
    // 非Harmony平台，使用标准输出作为回退
    std::cout << "[" << Enum<EventSeverity>::toString(severity) << "] " << msg << std::endl;
    #endif
}

} // namespace mbgl