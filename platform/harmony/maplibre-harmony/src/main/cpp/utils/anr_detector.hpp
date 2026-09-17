#pragma once

#include <chrono>
#include <string>
#include "logger.h"

namespace mbgl {
namespace harmony {

/**
 * ANRDetector - monitors operation duration to catch potential ANR issues.
 *
 * Usage:
 *   void someOperation() {
 *       ANRDetector detector("someOperation");
 *       // ... perform work
 *   } // destructor logs the elapsed time automatically
 */
class ANRDetector {
public:
    /**
     * Constructor - starts timing.
     * @param operation Operation name
     * @param warnThresholdMs Warning threshold in milliseconds (default 100 ms)
     * @param errorThresholdMs Error threshold in milliseconds (default 1000 ms)
     */
    explicit ANRDetector(const char* operation, 
                        int64_t warnThresholdMs = 100,
                        int64_t errorThresholdMs = 1000)
        : operation_(operation)
        , warnThreshold_(warnThresholdMs)
        , errorThreshold_(errorThresholdMs)
        , startTime_(std::chrono::steady_clock::now()) {
    }
    
    /**
     * Destructor - measures elapsed time and logs if thresholds are exceeded.
     */
    ~ANRDetector() {
        auto elapsed = std::chrono::steady_clock::now() - startTime_;
        auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(elapsed).count();
        
        if (ms >= errorThreshold_) {
            Logger::error("ANR", "🚨 %s took %lld ms (CRITICAL - may cause ANR)", 
                         operation_, ms);
        } else if (ms >= warnThreshold_) {
            Logger::warn("ANR", "⏱️  %s took %lld ms (WARNING - approaching ANR threshold)", 
                        operation_, ms);
        } else {
        }
    }
    
    /**
     * Retrieve the elapsed time in milliseconds.
     */
    int64_t elapsedMs() const {
        auto elapsed = std::chrono::steady_clock::now() - startTime_;
        return std::chrono::duration_cast<std::chrono::milliseconds>(elapsed).count();
    }

private:
    const char* operation_;
    int64_t warnThreshold_;
    int64_t errorThreshold_;
    std::chrono::steady_clock::time_point startTime_;
};

/**
 * TimeoutGuard - lightweight timeout monitor.
 *
 * Note: due to HarmonyOS C++ standard library limitations, this guard only logs duration.
 * Actual timeout enforcement must be handled externally (e.g., thread + condition variable).
 *
 * Usage:
 *   TimeoutGuard guard("operation_name", 50);
 *   // perform time-sensitive work
 *   // on timeout, the guard logs a warning upon destruction
 */
class TimeoutGuard {
public:
    explicit TimeoutGuard(const char* operation, int64_t timeoutMs)
        : operation_(operation)
        , timeout_(timeoutMs)
        , startTime_(std::chrono::steady_clock::now()) {
    }
    
    ~TimeoutGuard() {
        auto elapsed = std::chrono::steady_clock::now() - startTime_;
        auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(elapsed).count();
        
        if (ms >= timeout_) {
            Logger::warn("ANR", "⏱️  %s exceeded timeout: %lld ms (limit: %ld ms)", 
                        operation_, ms, timeout_);
        } else {
        }
    }

private:
    const char* operation_;
    int64_t timeout_;
    std::chrono::steady_clock::time_point startTime_;
};

} // namespace harmony
} // namespace mbgl

