#pragma once

#include <chrono>
#include <string>
#include "logger.h"

namespace mbgl {
namespace harmony {

/**
 * ANR检测器 - 监控操作耗时，及时发现潜在的ANR问题
 * 
 * 使用方式：
 *   void someOperation() {
 *       ANRDetector detector("someOperation");
 *       // ... 执行操作
 *   } // 析构时自动检测耗时
 */
class ANRDetector {
public:
    /**
     * 构造函数 - 开始计时
     * @param operation 操作名称
     * @param warnThresholdMs 警告阈值（毫秒），默认100ms
     * @param errorThresholdMs 错误阈值（毫秒），默认1000ms
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
     * 析构函数 - 检测耗时并记录日志
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
     * 获取已经过的时间（毫秒）
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
 * 简化的超时执行器 - 用于需要超时保护的操作
 * 
 * 注意：由于 HarmonyOS 的 C++ 标准库限制，此函数仅记录耗时
 * 实际的超时控制需要在调用方实现（例如使用 thread + 条件变量）
 * 
 * 使用方式：
 *   TimeoutGuard guard("operation_name", 50);
 *   // 执行耗时操作
 *   // 如果超时，guard 析构时会记录警告
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

