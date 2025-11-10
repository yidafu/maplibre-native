#include "harmony_map_render_thread.hpp"
#include "backends/harmony_gl_renderer_backend.hpp"
#include "backends/egl_display_manager.hpp"
#include "../utils/logger.h"

#include <mbgl/gfx/backend_scope.hpp>
#include <mbgl/actor/scheduler.hpp>
#include <mbgl/util/thread_pool.hpp>
#include <mbgl/util/logging.hpp>

#include <future>
#include <chrono>

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

// 静态实例计数器初始化
std::atomic<uint64_t> HarmonyMapRenderThread::globalInstanceCounter_{0};

HarmonyMapRenderThread::HarmonyMapRenderThread(
    std::unique_ptr<gfx::Backend> backend,
    float pixelRatio,
    MapObserver& observer,
    MapOptions&& mapOptions,
    ResourceOptions&& resourceOptions,
    ClientOptions&& clientOptions,
    const std::optional<std::string>& localIdeographFontFamily)
    : instanceId_(++globalInstanceCounter_),
      backend_(std::move(backend)),
      pixelRatio_(pixelRatio),
      mapObserver_(&observer),
      mapOptions_(std::move(mapOptions)),
      resourceOptions_(std::move(resourceOptions)),
      clientOptions_(std::move(clientOptions)),
      localIdeographFontFamily_(localIdeographFontFamily) {
}

HarmonyMapRenderThread::~HarmonyMapRenderThread() {
    // 停止 VSync 管理器
    if (vsyncManager_) {
        vsyncManager_->stop();
    }
    
    // 确保线程已停止
    if (started_) {
        Logger::error("MapRenderThread", 
            "⚠️  IMPROPER SHUTDOWN: Thread still running in destructor!");
        Logger::error("MapRenderThread", 
            "    ALWAYS call stop() explicitly before destroying the instance.");
        stop();
    }
}

void HarmonyMapRenderThread::start() {
    if (started_) {
        Logger::error("MapRenderThread", "start() refused: already started");
        return;
    }
    
    // 使用条件变量等待初始化完成
    std::unique_lock<std::mutex> lock(mutex_);
    
    // 启动线程
    thread_ = std::thread([this]() {
        threadLoop();
    });
    
    // 等待初始化完成（最多 10 秒）
    auto timeout = std::chrono::seconds(10);
    if (!cv_.wait_for(lock, timeout, [this]() { return initialized_.load(); })) {
        Logger::error("MapRenderThread", "Thread initialization timeout!");
        throw std::runtime_error("MapRenderThread initialization timeout");
    }
}

void HarmonyMapRenderThread::threadLoop() {
    // 🎯 设置当前线程为渲染线程
    threadId_ = std::this_thread::get_id();
    started_ = true;
    
    try {
        // 初始化所有对象
        if (!initialize()) {
            Logger::error("MapRenderThread", "Initialization failed");
            // 通知初始化失败
            {
                std::lock_guard<std::mutex> lock(mutex_);
                initialized_ = false;
            }
            cv_.notify_one();
            return;
        }
        
        Logger::warn("MapRenderThread", "⚠️  EGL Context not initialized yet - waiting for setNativeWindow()");
        
        // ✅ 确认 Scheduler 设置
        auto* scheduler = Scheduler::GetCurrent();
        if (scheduler != runLoop_.get()) {
            Logger::error("MapRenderThread", "❌ SCHEDULER MISMATCH!");
        }
        
        // 通知初始化完成（必须在 runLoop_->run() 之前！）
        {
            std::lock_guard<std::mutex> lock(mutex_);
            initialized_ = true;
        }
        cv_.notify_one();
        
        // 🎯 统一线程模型：RunLoop 处理所有任务
        // - Actor 消息（FileSource 回调等）
        // - VSync 回调（通过 renderRunLoop_->invoke()）
        // - EGL 渲染操作
        runLoop_->run();
        
        // 清理资源
        cleanup();
        
    } catch (const std::exception& e) {
        Logger::error("MapRenderThread", "Exception in thread loop: %s", e.what());
    }
}

bool HarmonyMapRenderThread::initialize() {
    // 步骤 1: 创建 RunLoop（必须最先）
    runLoop_ = std::make_unique<util::RunLoop>();
    if (!runLoop_) {
        Logger::error("MapRenderThread", "Failed to create RunLoop");
        return false;
    }
    
    // 步骤 2: 创建线程池
    auto backgroundScheduler = Scheduler::GetBackground();
    if (!backgroundScheduler) {
        Logger::error("MapRenderThread", "Failed to get background scheduler");
        return false;
    }
    threadPool_ = std::make_unique<TaggedScheduler>(
        backgroundScheduler,
        util::SimpleIdentity::Empty
    );
    
    // 步骤 3: 创建 Renderer（不需要 EGL Context 即可创建）
    auto* glBackend = static_cast<HarmonyGLRendererBackend*>(backend_.get());
    if (!glBackend) {
        Logger::error("MapRenderThread", "Invalid GL backend");
        return false;
    }
    
    gfx::RendererBackend& backendImpl = glBackend->getImpl();
    renderer_ = std::make_unique<Renderer>(backendImpl, pixelRatio_, localIdeographFontFamily_);
    if (!renderer_) {
        Logger::error("MapRenderThread", "Failed to create Renderer");
        return false;
    }
    
    // 步骤 4: 创建 Map（会自动使用当前 Scheduler）
    map_ = std::make_unique<Map>(
        *this,  // RendererFrontend
        *mapObserver_,
        mapOptions_,
        resourceOptions_,
        clientOptions_
    );
    if (!map_) {
        Logger::error("MapRenderThread", "Failed to create Map");
        return false;
    }
    
    return true;
}

void HarmonyMapRenderThread::cleanup() {
    // ⚠️  Map 和 Renderer 应该已在 stop() 中销毁
    // 这里只是保险检查，正常情况下不应该执行
    if (map_) {
        Logger::warn("MapRenderThread", "⚠️  Map still exists in cleanup() - destroying now");
        map_.reset();
    }
    
    if (renderer_) {
        Logger::warn("MapRenderThread", "⚠️  Renderer still exists in cleanup() - destroying now");
        renderer_.reset();
    }
    
    // 清理 EGL 资源
    if (backend_) {
        auto* glBackend = static_cast<HarmonyGLRendererBackend*>(backend_.get());
        glBackend->cleanupEGL();
        
        // ⚡ 关键修复：手动注销实例
        // 原因：gfx::Backend 没有虚析构函数，backend_.reset() 不会调用派生类析构
        // 因此必须手动调用 unregisterInstance()，否则实例计数永远不减少
        EGLDisplayManager::getInstance().unregisterInstance();
        
        backend_.reset();
    }
    
    // 清理线程池
    if (threadPool_) {
        threadPool_.reset();
    }
    
    // VSync 的 RunLoop 引用已在 stop() 中清空
    
    // 销毁 RunLoop
    if (runLoop_) {
        runLoop_.reset();
    }
}

void HarmonyMapRenderThread::stop() {
    if (!started_) {
        Logger::warn("MapRenderThread", "Thread not started");
        return;
    }
    
    if (shouldStop_) {
        Logger::warn("MapRenderThread", "Already stopping");
        return;
    }
    
    // ✅ 步骤 1: 立即设置销毁标志，阻止新的渲染请求
    destroying_.store(true);
    
    shouldStop_ = true;
    paused_ = true;

    // ✅ 步骤 2: 停止 VSync，清理待渲染状态
    if (vsyncManager_) {
        vsyncManager_->stop();
    }
    pendingRender_ = false;
    pendingUpdateParams_.reset();
    
    // ✅ 步骤 3: 在渲染线程上清理 Map 和 Renderer
    // 确保所有 Mailbox 消息处理完后再销毁
    if (runLoop_ && map_) {
        // ⚠️  使用 shared_ptr 避免 promise 生命周期问题
        auto cleanupPromise = std::make_shared<std::promise<void>>();
        auto cleanupFuture = cleanupPromise->get_future();
        
        try {
            runLoop_->invoke([this, cleanupPromise]() {
                try {
                    // 销毁 Map（这会取消所有待处理的 Actor 消息）
                    if (map_) {
                        map_.reset();
                    }
                    
                    // 销毁 Renderer
                    if (renderer_) {
                        renderer_.reset();
                    }
                    
                    cleanupPromise->set_value();
                } catch (const std::exception& e) {
                    Logger::error("MapRenderThread", "Exception in cleanup lambda: %s", e.what());
                    cleanupPromise->set_exception(std::current_exception());
                }
            });
            
            // 等待清理完成（最多 5 秒）
            auto status = cleanupFuture.wait_for(std::chrono::seconds(5));
            if (status == std::future_status::timeout) {
                Logger::error("MapRenderThread", "⚠️  Cleanup timeout after 5 seconds!");
                Logger::error("MapRenderThread", "⚠️  Will forcibly continue with RunLoop stop");
                // ⚠️  超时后仍继续，避免永久阻塞
            } else {
                try {
                    cleanupFuture.get();  // 检查是否有异常
                } catch (const std::exception& e) {
                    Logger::error("MapRenderThread", "Exception during cleanup wait: %s", e.what());
                }
            }
        } catch (const std::exception& e) {
            Logger::error("MapRenderThread", "Exception during cleanup invoke: %s", e.what());
        }
    }
    
    // ✅ 步骤 4: 停止 RunLoop（这会处理完所有待处理的消息）
    if (runLoop_) {
        runLoop_->stop();
    }
    
    // ✅ 步骤 5: 等待线程退出
    if (thread_.joinable()) {
        thread_.join();
    }
    
    started_ = false;
    initialized_ = false;
}

void HarmonyMapRenderThread::invoke(std::function<void()> task) {
    if (!task) {
        Logger::warn("MapRenderThread", "invoke() called with null task");
        return;
    }
    
    // ✅ 检查销毁标志
    if (destroying_.load()) {
        Logger::warn("MapRenderThread", "invoke() ignored: instance is being destroyed");
        return;
    }
    
    if (shouldStop_) {
        Logger::warn("MapRenderThread", "invoke() ignored: thread is stopping");
        return;
    }

    // 检查是否已在 Map+渲染线程
    if (isOnThread()) {
        // ✅ 确保 Scheduler 正确设置
        Scheduler::SetCurrent(runLoop_.get());
        task();
    } else {
        if (!runLoop_) {
            Logger::error("MapRenderThread", "RunLoop not initialized");
            return;
        }
        
        // ✅ 调度到 RunLoop，确保在正确线程执行
        runLoop_->invoke([this, task = std::move(task)]() {
            // 任务执行前确保 Scheduler 正确
            Scheduler::SetCurrent(runLoop_.get());
            task();
        });
    }
}

bool HarmonyMapRenderThread::isOnThread() const {
    return std::this_thread::get_id() == threadId_;
}

void HarmonyMapRenderThread::update(std::shared_ptr<UpdateParameters> params) {
    // ✅ 检查销毁标志（优先级最高）
    if (destroying_.load()) {
        Logger::warn("MapRenderThread", "update() ignored: instance is being destroyed");
        return;
    }
    
    if (shouldStop_) {
        Logger::warn("MapRenderThread", "update() ignored: thread is stopping");
        return;
    }

    if (!renderer_ || !backend_) {
        Logger::error("MapRenderThread", "Renderer or backend not initialized");
        return;
    }
    
    if (paused_) {
        return;
    }
    
    // ✅ VSync 同步渲染：保存参数并请求 VSync，而不是立即执行
    invoke([this, params]() {
        // 如果有 VSync 管理器，使用 VSync 同步渲染
        if (vsyncManager_ && vsyncManager_->isAvailable()) {
            // 保存待处理的渲染参数
            pendingUpdateParams_ = params;
            pendingRender_ = true;
            
            // 请求 VSync 帧，实际渲染将在 VSync 回调中执行
            vsyncManager_->requestFrame([this]() {
                onVSyncFrame();
            });
        } else {
            // VSync 不可用时，立即执行渲染（后备方案）
            // 直接在这里执行，而不是调用 onVSyncFrame()，避免线程调度问题
            if (params && renderer_ && backend_) {
                try {
                    auto* glBackend = static_cast<HarmonyGLRendererBackend*>(backend_.get());
                    gfx::BackendScope scope{glBackend->getImpl()};
                    renderer_->render(params);
                } catch (const std::exception& e) {
                    Logger::error("MapRenderThread", "Immediate render failed: %s", e.what());
                }
            }
        }
    });
}

void HarmonyMapRenderThread::setObserver(RendererObserver& observer) {
    Logger::info("MapRenderThread", "setObserver() called");
    
    invoke([this, &observer]() {
        if (renderer_) {
            renderer_->setObserver(&observer);
        }
    });
}

void HarmonyMapRenderThread::reset() {
    Logger::info("MapRenderThread", "reset() called");
    // Note: Renderer doesn't have a reset() method in the current API
    // This method is part of RendererFrontend interface but may not be needed
}

const TaggedScheduler& HarmonyMapRenderThread::getThreadPool() const {
    if (!threadPool_) {
        throw std::runtime_error("ThreadPool not initialized");
    }
    return *threadPool_;
}

void HarmonyMapRenderThread::setNativeWindow(void* window) {
    if (!backend_) {
        Logger::error("MapRenderThread", "Backend not initialized");
        return;
    }
    
    // ⚠️ 关键修复：所有 EGL 操作必须在渲染线程执行
    // 包括 Display、Surface 和 Context 的初始化
    invoke([this, window]() {
        nativeWindow_ = window;
        
        auto* glBackend = static_cast<HarmonyGLRendererBackend*>(backend_.get());
        
        // 若已存在 EGL/Surface，先清理再重建，避免跨会话复用
        // 这里依赖 backend 内部的 setNativeWindow 实现具备幂等清理逻辑
        // 步骤 1: 初始化 Display 和 Surface（在渲染线程）
        Logger::info("MapRenderThread", "Initializing EGL Display and Surface on render thread...");
        glBackend->setNativeWindow(window);
        // 步骤 2: 不在这里初始化 Context！
        // 🎯 关键：invoke() 回调在线程池的任意线程执行，不是渲染线程
        // Context 必须在真正的渲染线程（renderLoopThread）创建
        // 将在第一次 activate() 时延迟创建
        Logger::info("MapRenderThread", "⏳ EGL Context will be created lazily on first activate() in render thread");
        Logger::info("MapRenderThread", "   Current thread: %lu (this is NOT the render thread)",
                     std::hash<std::thread::id>{}(std::this_thread::get_id()));

        // 标记 Renderer 上下文丢失，促使资源在新上下文重建
        if (renderer_) {
            Logger::info("MapRenderThread", "Marking context lost and reducing memory");
            renderer_->markContextLost();
            renderer_->reduceMemoryUse();
        }

        // 确保恢复渲染
        paused_ = false;
        
        // 初始化 VSync 管理器
        try {
            vsyncManager_ = std::make_unique<HarmonyVSyncManager>();
            vsyncManager_->setOwnerInstanceId(instanceId_);
            
            // 🎯 设置 RunLoop 引用，VSync 回调将通过 RunLoop 调度
            vsyncManager_->setRunLoop(runLoop_.get());
            
        } catch (const std::exception& e) {
            Logger::error("MapRenderThread", "Failed to initialize VSync Manager: %s", e.what());
            Logger::warn("MapRenderThread", "Continuing without VSync (will use immediate render)");
        }
        
        // ✅ 关键修复：重置 VSync 相关状态
        // 确保在重新初始化时，pendingRender_ 被正确重置
        pendingRender_ = false;
        pendingUpdateParams_.reset();
        
        // ✅ 如果已有最近尺寸，窗口建立后立即应用一次尺寸同步与首帧渲染
        if (lastWidth_ > 0 && lastHeight_ > 0) {
            auto* glBackend2 = static_cast<HarmonyGLRendererBackend*>(backend_.get());
            if (glBackend2) {
                glBackend2->resizeFramebuffer(lastWidth_, lastHeight_);
            }
            if (map_) {
                map_->setSize(Size{static_cast<uint32_t>(lastWidth_), static_cast<uint32_t>(lastHeight_)});
            }
        }

        // 触发首次渲染
        if (map_) {
            map_->triggerRepaint();
        }
    });
}

void HarmonyMapRenderThread::pause() {
    Logger::info("MapRenderThread", "pause() called");
    paused_ = true;
}

void HarmonyMapRenderThread::resume() {
    Logger::info("MapRenderThread", "resume() called");
    paused_ = false;
    
    // ✅ 关键修复：恢复时重置 VSync 状态，避免残留状态导致问题
    invoke([this]() {
        pendingRender_ = false;
        pendingUpdateParams_.reset();
    });
}

Map& HarmonyMapRenderThread::getMap() {
    if (!map_) {
        throw std::runtime_error("Map not initialized");
    }
    return *map_;
}

gfx::RendererBackend& HarmonyMapRenderThread::getRendererBackend() {
    if (!backend_) {
        throw std::runtime_error("Backend not initialized");
    }
    
    auto* glBackend = static_cast<HarmonyGLRendererBackend*>(backend_.get());
    return glBackend->getImpl();
}

void HarmonyMapRenderThread::resizeFramebuffer(int width, int height) {
    // 记录最近一次的逻辑尺寸（用于窗口重建后应用）
    lastWidth_ = width;
    lastHeight_ = height;

    invoke([this, width, height]() {
        if (!backend_) {
            Logger::error("MapRenderThread", "Backend not initialized, cannot resize");
            return;
        }
        
        auto* glBackend = static_cast<HarmonyGLRendererBackend*>(backend_.get());
        if (glBackend) {
            glBackend->resizeFramebuffer(width, height);
        } else {
            Logger::error("MapRenderThread", "Invalid backend type");
        }
    });
}

std::vector<Feature> HarmonyMapRenderThread::queryRenderedFeatures(
    const ScreenCoordinate& point,
    const RenderedQueryOptions& options) const {
    
    if (!renderer_) {
        Logger::error("MapRenderThread", "queryRenderedFeatures: Renderer not initialized");
        return {};
    }
    
    return renderer_->queryRenderedFeatures(point, options);
}

std::vector<Feature> HarmonyMapRenderThread::queryRenderedFeatures(
    const ScreenBox& box,
    const RenderedQueryOptions& options) const {
    
    if (!renderer_) {
        Logger::error("MapRenderThread", "queryRenderedFeatures: Renderer not initialized");
        return {};
    }
    
    return renderer_->queryRenderedFeatures(box, options);
}

std::vector<Feature> HarmonyMapRenderThread::querySourceFeatures(
    const std::string& sourceId,
    const SourceQueryOptions& options) const {
    
    if (!renderer_) {
        Logger::error("MapRenderThread", "querySourceFeatures: Renderer not initialized");
        return {};
    }
    
    return renderer_->querySourceFeatures(sourceId, options);
}

void HarmonyMapRenderThread::setOnFpsChangedCallback(std::function<void(double)> callback) {
    fpsCallback_ = std::move(callback);
    measureFps_ = (fpsCallback_ != nullptr);
    if (measureFps_) {
        lastFrameTime_ = std::chrono::steady_clock::now();
        Logger::info("MapRenderThread", "FPS measurement enabled");
    } else {
        Logger::info("MapRenderThread", "FPS measurement disabled");
    }
}

void HarmonyMapRenderThread::enableFpsMeasurement(bool enable) {
    measureFps_ = enable;
    if (enable && !fpsCallback_) {
        Logger::warn("MapRenderThread", "FPS measurement enabled but no callback set");
    }
}

// ==================== VSync 控制 ====================

void HarmonyMapRenderThread::onVSyncFrame() {
    // ✅ 检查销毁标志（必须在断言之前！）
    if (destroying_.load()) {
        return;
    }
    
    if (paused_) {
        return;
    }
    
    // 🎯 双线程模型：VSync 现在通过条件变量直接唤醒渲染线程
    // 断言检查：确保始终在渲染线程执行
    // ⚠️  这个检查在 destroying_ 之后，因为销毁时可能会有延迟的回调
    assert(isOnThread() && "VSync must execute on render thread");
    
    // 获取待处理的渲染参数
    if (!pendingRender_.load()) {
        return;
    }
    
    pendingRender_ = false;
    auto params = pendingUpdateParams_;
    pendingUpdateParams_.reset();
    
    // 执行实际渲染
    if (params && renderer_ && backend_) {
        try {
            // 开始帧时间测量
            auto frameStartTime = std::chrono::steady_clock::now();
            
            auto* glBackend = static_cast<HarmonyGLRendererBackend*>(backend_.get());
            gfx::BackendScope scope{glBackend->getImpl()};
            
            renderer_->render(params);
            
            // FPS 测量（参考 Android MapRenderer::updateFps）
            if (measureFps_.load() && fpsCallback_) {
                auto currentTime = std::chrono::steady_clock::now();
                auto elapsedNanos = std::chrono::duration_cast<std::chrono::nanoseconds>(
                    currentTime - lastFrameTime_).count();
                
                if (elapsedNanos > 0) {
                    // 计算 FPS：fps = 1E9 / elapsed_nanoseconds
                    double fps = 1.0e9 / static_cast<double>(elapsedNanos);
                    fpsCallback_(fps);
                }
                
                lastFrameTime_ = currentTime;
            }
            
        } catch (const std::exception& e) {
            Logger::error("MapRenderThread", "Render failed on VSync: %s", e.what());
        }
    } else if (map_) {
        // 如果没有待处理的参数，触发重新绘制（由 Map 决定是否需要）
        
        map_->triggerRepaint();
    }
    
    // 注意：如果需要继续渲染，Map 会在 onDidFinishRenderingFrame 中再次调用 update()
    // 这会再次请求 VSync，形成正确的同步渲染循环
}

} // namespace harmony
} // namespace mbgl
