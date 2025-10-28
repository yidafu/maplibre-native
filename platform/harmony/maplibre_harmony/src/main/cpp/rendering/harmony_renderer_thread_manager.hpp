#pragma once

#include <mbgl/util/run_loop.hpp>
#include <string>
#include <map>
#include <mutex>
#include <thread>
#include <chrono>
#include <vector>
#include <optional>
#include <functional>

namespace mbgl {
namespace harmony {

/**
 * HarmonyRendererThreadManager
 * 
 * 统一管理所有渲染线程，提供线程查询、注册和跨线程调用能力。
 * 
 * 设计原则：
 * 1. 单例模式 - 全局唯一实例
 * 2. 线程安全 - 使用 mutex 保护所有操作
 * 3. 支持多实例 - 每个渲染器实例独立注册
 * 4. 便于调试 - 提供完整的线程信息查询
 */
class HarmonyRendererThreadManager {
public:
    /**
     * 线程信息结构
     */
    struct ThreadInfo {
        util::RunLoop* runLoop;                              // RunLoop 指针
        std::thread::id threadId;                            // 线程 ID
        std::chrono::steady_clock::time_point createdAt;     // 创建时间
        bool active;                                         // 是否活跃
        
        ThreadInfo()
            : runLoop(nullptr)
            , threadId()
            , createdAt(std::chrono::steady_clock::now())
            , active(true) {}
            
        ThreadInfo(util::RunLoop* loop, std::thread::id tid)
            : runLoop(loop)
            , threadId(tid)
            , createdAt(std::chrono::steady_clock::now())
            , active(true) {}
    };
    
    /**
     * 获取单例实例
     */
    static HarmonyRendererThreadManager& getInstance();
    
    /**
     * 注册渲染线程
     * 
     * @param instanceId 实例唯一标识符
     * @param runLoop RunLoop 指针
     * @param threadId 线程 ID
     */
    void registerRendererThread(const std::string& instanceId,
                                util::RunLoop* runLoop,
                                std::thread::id threadId);
    
    /**
     * 注销渲染线程
     * 
     * @param instanceId 实例唯一标识符
     */
    void unregisterRendererThread(const std::string& instanceId);
    
    /**
     * 在指定渲染线程执行任务
     * 
     * @param instanceId 目标线程的实例 ID
     * @param fn 要执行的函数
     * @return 是否成功调度（线程存在返回 true）
     */
    bool invokeOnThread(const std::string& instanceId, std::function<void()>&& fn);
    
    /**
     * 检查当前线程是否是指定实例的渲染线程
     * 
     * @param instanceId 实例 ID
     * @return 如果当前线程是该实例的渲染线程返回 true
     */
    bool isOnRendererThread(const std::string& instanceId) const;
    
    /**
     * 获取当前线程对应的实例 ID（如果是渲染线程）
     * 
     * @return 实例 ID，如果当前线程不是任何渲染线程返回 nullopt
     */
    std::optional<std::string> getCurrentInstanceId() const;
    
    /**
     * 获取线程信息
     * 
     * @param instanceId 实例 ID
     * @return 线程信息，如果不存在返回 nullopt
     */
    std::optional<ThreadInfo> getThreadInfo(const std::string& instanceId) const;
    
    /**
     * 获取活跃线程数量
     */
    size_t getThreadCount() const;
    
    /**
     * 获取所有实例 ID 列表
     */
    std::vector<std::string> getAllInstanceIds() const;
    
    /**
     * 调试：打印所有线程状态
     */
    void dumpAllThreads() const;
    
private:
    // 私有构造函数（单例模式）
    HarmonyRendererThreadManager() = default;
    ~HarmonyRendererThreadManager() = default;
    
    // 禁止拷贝和赋值
    HarmonyRendererThreadManager(const HarmonyRendererThreadManager&) = delete;
    HarmonyRendererThreadManager& operator=(const HarmonyRendererThreadManager&) = delete;
    
    // 线程信息映射表
    mutable std::mutex mutex_;
    std::map<std::string, ThreadInfo> threads_;
};

} // namespace harmony
} // namespace mbgl

