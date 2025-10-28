#include "harmony_renderer_thread_manager.hpp"
#include "utils/logger.h"

#include <sstream>
#include <iomanip>

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

namespace {
// 格式化线程 ID 为可读字符串
std::string formatThreadId(std::thread::id id) {
    std::ostringstream oss;
    oss << "T-" << std::setfill('0') << std::setw(5) 
        << (std::hash<std::thread::id>{}(id) % 100000);
    return oss.str();
}

// 格式化时间间隔
std::string formatDuration(std::chrono::steady_clock::duration duration) {
    auto seconds = std::chrono::duration_cast<std::chrono::seconds>(duration).count();
    if (seconds < 60) {
        return std::to_string(seconds) + "s";
    } else if (seconds < 3600) {
        return std::to_string(seconds / 60) + "m " + std::to_string(seconds % 60) + "s";
    } else {
        return std::to_string(seconds / 3600) + "h " + std::to_string((seconds % 3600) / 60) + "m";
    }
}
} // anonymous namespace

HarmonyRendererThreadManager& HarmonyRendererThreadManager::getInstance() {
    static HarmonyRendererThreadManager instance;
    return instance;
}

void HarmonyRendererThreadManager::registerRendererThread(
    const std::string& instanceId,
    util::RunLoop* runLoop,
    std::thread::id threadId) {
    
    std::lock_guard<std::mutex> lock(mutex_);
    
    // 检查是否已存在
    if (threads_.find(instanceId) != threads_.end()) {
        Logger::warn("ThreadMgr", "Thread already registered: %s, replacing...", instanceId.c_str());
    }
    
    // 注册线程
    threads_[instanceId] = ThreadInfo(runLoop, threadId);
    
    Logger::info("ThreadMgr", "➕ Register thread: %s (%s)", 
                 instanceId.c_str(), 
                 formatThreadId(threadId).c_str());
    Logger::debug("ThreadMgr", "  Total threads: %zu", threads_.size());
}

void HarmonyRendererThreadManager::unregisterRendererThread(const std::string& instanceId) {
    std::lock_guard<std::mutex> lock(mutex_);
    
    auto it = threads_.find(instanceId);
    if (it == threads_.end()) {
        Logger::warn("ThreadMgr", "Cannot unregister: thread not found: %s", instanceId.c_str());
        return;
    }
    
    // 标记为非活跃
    it->second.active = false;
    
    // 移除线程
    threads_.erase(it);
    
    Logger::info("ThreadMgr", "➖ Unregister thread: %s", instanceId.c_str());
    Logger::debug("ThreadMgr", "  Remaining threads: %zu", threads_.size());
}

bool HarmonyRendererThreadManager::invokeOnThread(
    const std::string& instanceId,
    std::function<void()>&& fn) {
    
    std::lock_guard<std::mutex> lock(mutex_);
    
    auto it = threads_.find(instanceId);
    if (it == threads_.end() || !it->second.active) {
        Logger::warn("ThreadMgr", "Cannot invoke: thread not found or inactive: %s", instanceId.c_str());
        return false;
    }
    
    auto& threadInfo = it->second;
    if (!threadInfo.runLoop) {
        Logger::error("ThreadMgr", "Cannot invoke: RunLoop is null for: %s", instanceId.c_str());
        return false;
    }
    
    Logger::debug("ThreadMgr", "🌉 Invoke on thread: %s (%s)", 
                  instanceId.c_str(),
                  formatThreadId(threadInfo.threadId).c_str());
    
    // 通过 RunLoop 调度任务
    threadInfo.runLoop->invoke(std::move(fn));
    
    return true;
}

bool HarmonyRendererThreadManager::isOnRendererThread(const std::string& instanceId) const {
    std::lock_guard<std::mutex> lock(mutex_);
    
    auto it = threads_.find(instanceId);
    if (it == threads_.end() || !it->second.active) {
        return false;
    }
    
    return std::this_thread::get_id() == it->second.threadId;
}

std::optional<std::string> HarmonyRendererThreadManager::getCurrentInstanceId() const {
    std::lock_guard<std::mutex> lock(mutex_);
    
    auto currentThreadId = std::this_thread::get_id();
    
    for (const auto& [instanceId, threadInfo] : threads_) {
        if (threadInfo.active && threadInfo.threadId == currentThreadId) {
            return instanceId;
        }
    }
    
    return std::nullopt;
}

std::optional<HarmonyRendererThreadManager::ThreadInfo> 
HarmonyRendererThreadManager::getThreadInfo(const std::string& instanceId) const {
    std::lock_guard<std::mutex> lock(mutex_);
    
    auto it = threads_.find(instanceId);
    if (it == threads_.end()) {
        return std::nullopt;
    }
    
    return it->second;
}

size_t HarmonyRendererThreadManager::getThreadCount() const {
    std::lock_guard<std::mutex> lock(mutex_);
    
    // 只计数活跃线程
    size_t count = 0;
    for (const auto& [_, threadInfo] : threads_) {
        if (threadInfo.active) {
            count++;
        }
    }
    
    return count;
}

std::vector<std::string> HarmonyRendererThreadManager::getAllInstanceIds() const {
    std::lock_guard<std::mutex> lock(mutex_);
    
    std::vector<std::string> ids;
    ids.reserve(threads_.size());
    
    for (const auto& [instanceId, threadInfo] : threads_) {
        if (threadInfo.active) {
            ids.push_back(instanceId);
        }
    }
    
    return ids;
}

void HarmonyRendererThreadManager::dumpAllThreads() const {
    std::lock_guard<std::mutex> lock(mutex_);
    
    Logger::info("Debug", "======= THREAD DUMP =======");
    Logger::info("Debug", "Total threads: %zu", threads_.size());
    
    if (threads_.empty()) {
        Logger::info("Debug", "(No threads registered)");
    } else {
        auto now = std::chrono::steady_clock::now();
        
        for (const auto& [instanceId, threadInfo] : threads_) {
            Logger::info("Debug", "[%s]", instanceId.c_str());
            Logger::info("Debug", "  Thread ID: %s", formatThreadId(threadInfo.threadId).c_str());
            Logger::info("Debug", "  Active: %s", threadInfo.active ? "Yes" : "No");
            Logger::info("Debug", "  Created: %s ago", 
                        formatDuration(now - threadInfo.createdAt).c_str());
            Logger::info("Debug", "  RunLoop: %p", threadInfo.runLoop);
        }
    }
    
    Logger::info("Debug", "===========================");
}

} // namespace harmony
} // namespace mbgl

