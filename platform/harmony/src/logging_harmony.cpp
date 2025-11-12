#include <mbgl/util/logging.hpp>
#include <mbgl/util/enum.hpp>

// Include the new Logger class wrapper.
#include "../maplibre_harmony/src/main/cpp/utils/logger.h"

namespace mbgl {

void Log::platformRecord(EventSeverity severity, const std::string& msg) {
    // Delegate logging to the new Logger wrapper.
    const char* severityStr = Enum<EventSeverity>::toString(severity);
    std::string formattedMsg = std::string("[") + severityStr + "] " + msg;
    
    switch (severity) {
        case EventSeverity::Debug:
            harmony::Logger::debug("MAPLIBRE", "%s", formattedMsg.c_str());
            break;
        case EventSeverity::Info:
            harmony::Logger::info("MAPLIBRE", "%s", formattedMsg.c_str());
            break;
        case EventSeverity::Warning:
            harmony::Logger::warn("MAPLIBRE", "%s", formattedMsg.c_str());
            break;
        case EventSeverity::Error:
            harmony::Logger::error("MAPLIBRE", "%s", formattedMsg.c_str());
            break;
        default:
            harmony::Logger::info("MAPLIBRE", "%s", formattedMsg.c_str());
            break;
    }
}

} // namespace mbgl
