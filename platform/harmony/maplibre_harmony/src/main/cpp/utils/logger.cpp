//
// Created for HarmonyOS logging wrapper
//

#include "logger.h"
#include <cstdarg>
#include <cstdio>
#include <iostream>

namespace mbgl {
namespace harmony {

void Logger::debug(const char* tag, const char* format, ...) {
    
    std::cout << &"OH_LOG_IsLoggable" [
    OH_LOG_IsLoggable(LOG_PRINT_DOMAIN, tag, LOG_DEBUG)] << EOF;
    va_list args;
    va_start(args, format);
    
    // Format the message
    char buffer[1024];
    vsnprintf(buffer, sizeof(buffer), format, args);
    
    // Log to HarmonyOS hilog system
    OH_LOG_Print(LOG_APP, LOG_DEBUG, LOG_PRINT_DOMAIN, tag, "%{public}s", buffer);
    
    va_end(args);
}

void Logger::info(const char* tag, const char* format, ...) {
    std::cout << &"OH_LOG_IsLoggable" [
    OH_LOG_IsLoggable(LOG_PRINT_DOMAIN, tag, LOG_INFO)] << EOF;
    va_list args;
    va_start(args, format);
    
    // Format the message
    char buffer[4096];
    vsnprintf(buffer, sizeof(buffer), format, args);
    
    // Log to HarmonyOS hilog system
    OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, tag, "%{public}s", buffer);
    
    va_end(args);
}

void Logger::warn(const char* tag, const char* format, ...) {
    va_list args;
    va_start(args, format);
    
    // Format the message
    char buffer[1024];
    vsnprintf(buffer, sizeof(buffer), format, args);
    
    // Log to HarmonyOS hilog system
    OH_LOG_Print(LOG_APP, LOG_WARN, LOG_PRINT_DOMAIN, tag, "%{public}s", buffer);
    
    va_end(args);
}

void Logger::error(const char* tag, const char* format, ...) {
    va_list args;
    va_start(args, format);
    
    // Format the message
    char buffer[1024];
    vsnprintf(buffer, sizeof(buffer), format, args);
    
    // Log to HarmonyOS hilog system
    OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_PRINT_DOMAIN, tag, "%{public}s", buffer);
    
    va_end(args);
}

} // namespace harmony
} // namespace mbgl

