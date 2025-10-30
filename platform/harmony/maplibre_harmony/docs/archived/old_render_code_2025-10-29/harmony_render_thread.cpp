#include "harmony_render_thread.hpp"
#include "../utils/logger.h"
#include <cassert>
#include <chrono>

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

HarmonyRenderThread::HarmonyRenderThread() {
    Logger::info("RenderThread", "HarmonyRenderThread created");
}

HarmonyRenderThread::~HarmonyRenderThread() {
    Logger::info("RenderThread", "HarmonyRenderThread destructor started");
    
    // 确保线程已停止
    if (started_) {
        stop();
    }
    
    Logger::info("RenderThread", "HarmonyRenderThread destroyed");
}

void HarmonyRenderThread::start() {
    if (started_) {
        Logger::warn("RenderThread", "Render thread already started");
        return;
    }

    Logger::info("RenderThread", "Starting render thread...");
    
    shouldExit_ = false;
    
    // 启动渲染线程
    renderThread_ = std::thread([this]() {
        renderLoop();
    });
    
    started_ = true;
    
    Logger::info("RenderThread", "Render thread started, ID: %lu", 
                 std::hash<std::thread::id>{}(renderThread_.get_id()));
}

void HarmonyRenderThread::stop() {
    if (!started_) {
        Logger::warn("RenderThread", "Render thread not started");
        return;
    }

    Logger::info("RenderThread", "Stopping render thread...");
    
    // 设置退出标志并唤醒线程
    {
        std::lock_guard<std::mutex> lock(queueMutex_);
        shouldExit_ = true;
        queueCondition_.notify_all();
    }
    
    // 等待线程退出
    if (renderThread_.joinable()) {
        renderThread_.join();
        Logger::info("RenderThread", "Render thread stopped successfully");
    }
    
    started_ = false;
}

void HarmonyRenderThread::queueEvent(std::function<void()> task) {
    if (!task) {
        Logger::warn("RenderThread", "Attempted to queue null task");
        return;
    }

    std::lock_guard<std::mutex> lock(queueMutex_);
    size_t queueSize = eventQueue_.size();
    eventQueue_.push_back(std::move(task));
    queueCondition_.notify_one();
    
    Logger::debug("RenderThread", "📥 Task queued (queue size: %zu → %zu)", 
                  queueSize, eventQueue_.size());
}

void HarmonyRenderThread::setRenderCallback(std::function<void()> callback) {
    std::lock_guard<std::mutex> lock(renderCallbackMutex_);
    renderCallback_ = std::move(callback);
}

void HarmonyRenderThread::requestRender() {
    Logger::info("RenderThread", "🎨 requestRender() called");
    renderRequested_ = true;
    
    // 唤醒渲染线程
    {
        std::lock_guard<std::mutex> lock(queueMutex_);
        queueCondition_.notify_one();
    }
    
    Logger::debug("RenderThread", "  Render thread notified");
}

void HarmonyRenderThread::waitForEmpty() {
    std::unique_lock<std::mutex> lock(queueMutex_);
    
    // 等待队列为空
    while (!eventQueue_.empty() && !shouldExit_) {
        queueCondition_.wait_for(lock, std::chrono::milliseconds(10));
    }
}

void HarmonyRenderThread::pause() {
    Logger::info("RenderThread", "Pausing render thread");
    paused_ = true;
}

void HarmonyRenderThread::resume() {
    Logger::info("RenderThread", "Resuming render thread");
    paused_ = false;
    
    // 唤醒线程
    {
        std::lock_guard<std::mutex> lock(queueMutex_);
        queueCondition_.notify_one();
    }
}

bool HarmonyRenderThread::isOnRenderThread() const {
    return std::this_thread::get_id() == renderThreadId_;
}

std::thread::id HarmonyRenderThread::getRenderThreadId() const {
    return renderThreadId_;
}

void HarmonyRenderThread::renderLoop() {
    // 记录渲染线程 ID
    renderThreadId_ = std::this_thread::get_id();
    
    Logger::info("RenderThread", "Render loop started on thread: %lu",
                 std::hash<std::thread::id>{}(renderThreadId_));

    while (true) {
        std::unique_lock<std::mutex> lock(queueMutex_);
        
        size_t queueSize = eventQueue_.size();
        bool hasRenderRequest = renderRequested_;
        
        Logger::debug("RenderThread", "⏸️ Waiting... (queue: %zu, renderReq: %d)", 
                      queueSize, hasRenderRequest);
        
        // 等待事件或渲染请求
        queueCondition_.wait(lock, [this]() {
            return shouldExit_ || !eventQueue_.empty() || renderRequested_;
        });
        
        Logger::debug("RenderThread", "⏯️ Woke up (queue: %zu, renderReq: %d, exit: %d)", 
                      eventQueue_.size(), renderRequested_.load(), shouldExit_.load());
        
        // 检查是否应该退出
        if (shouldExit_) {
            Logger::info("RenderThread", "Render loop exiting");
            break;
        }
        
        // 处理所有待处理的事件
        size_t tasksProcessed = 0;
        while (!eventQueue_.empty()) {
            auto task = std::move(eventQueue_.front());
            eventQueue_.pop_front();
            tasksProcessed++;
            
            // 释放锁以执行任务
            lock.unlock();
            
            Logger::debug("RenderThread", "  📦 Executing queued task #%zu...", tasksProcessed);
            
            try {
                task();
            } catch (const std::exception& e) {
                Logger::error("RenderThread", "Exception in queued task: %s", e.what());
            } catch (...) {
                Logger::error("RenderThread", "Unknown exception in queued task");
            }
            
            // 重新获取锁以继续处理队列
            lock.lock();
        }
        
        if (tasksProcessed > 0) {
            Logger::debug("RenderThread", "  ✅ Processed %zu tasks", tasksProcessed);
        }
        
        // 通知等待队列为空的线程
        if (eventQueue_.empty()) {
            queueCondition_.notify_all();
        }
        
        lock.unlock();
        
        // 执行渲染（如果有请求且未暂停）
        if (!paused_) {
            performRenderIfRequested();
        } else {
            if (renderRequested_) {
                Logger::warn("RenderThread", "  Render requested but thread is paused");
            }
        }
    }
    
    Logger::info("RenderThread", "Render loop ended");
}

void HarmonyRenderThread::processEvents() {
    std::lock_guard<std::mutex> lock(queueMutex_);
    
    while (!eventQueue_.empty()) {
        auto task = std::move(eventQueue_.front());
        eventQueue_.pop_front();
        
        try {
            task();
        } catch (const std::exception& e) {
            Logger::error("RenderThread", "Exception in event: %s", e.what());
        } catch (...) {
            Logger::error("RenderThread", "Unknown exception in event");
        }
    }
}

void HarmonyRenderThread::performRenderIfRequested() {
    // 检查是否有渲染请求
    bool expected = true;
    if (!renderRequested_.compare_exchange_strong(expected, false)) {
        return;  // 没有渲染请求
    }
    
    Logger::info("RenderThread", "🖼️ performRenderIfRequested() - executing render callback");
    
    // 执行渲染回调
    std::function<void()> callback;
    {
        std::lock_guard<std::mutex> lock(renderCallbackMutex_);
        callback = renderCallback_;
    }
    
    if (callback) {
        try {
            Logger::debug("RenderThread", "  Invoking render callback...");
            callback();
            Logger::info("RenderThread", "  ✅ Render callback completed");
        } catch (const std::exception& e) {
            Logger::error("RenderThread", "  ❌ Exception in render callback: %s", e.what());
        } catch (...) {
            Logger::error("RenderThread", "  ❌ Unknown exception in render callback");
        }
    } else {
        Logger::warn("RenderThread", "  ⚠️ No render callback set!");
    }
}

} // namespace harmony
} // namespace mbgl

