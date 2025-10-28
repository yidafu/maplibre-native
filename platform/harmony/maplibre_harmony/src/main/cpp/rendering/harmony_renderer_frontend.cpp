#include "harmony_renderer_frontend.hpp"
#include "backends/harmony_renderer_backend.hpp"
#include "vsync/harmony_vsync_manager.hpp"
#include "harmony_renderer_thread_manager.hpp"
#include "utils/logger.h"

#include <mbgl/gfx/backend_scope.hpp>
#include <mbgl/gl/renderer_backend.hpp>
#include <mbgl/util/logging.hpp>
#include <mbgl/util/thread_local.hpp>
#include <mbgl/actor/actor_ref.hpp>
#include <mbgl/actor/scheduler.hpp>
#include <thread>
#include <chrono>
#include <future>
#include <sstream>
#include <iomanip>

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

static util::ThreadLocal<HarmonyRendererFrontend> currentRendererFrontend;

namespace {
// 生成唯一实例 ID
std::string generateInstanceId() {
    static std::atomic<uint64_t> counter{0};
    auto count = counter.fetch_add(1);
    
    std::ostringstream oss;
    oss << "render-" << std::setfill('0') << std::setw(5) << count;
    return oss.str();
}
} // anonymous namespace

// Note: ForwardingRendererObserver was removed to avoid RunLoop dependency
// Observer callbacks are now called directly on the render thread

HarmonyRendererFrontend::HarmonyRendererFrontend(std::unique_ptr<gfx::Backend> backend,
                                                 float pixelRatio_,
                                                 const std::string& instanceId)
    : instanceId_(instanceId.empty() ? generateInstanceId() : instanceId),
      pixelRatio(pixelRatio_),
      rendererBackend(std::move(backend)) {
    currentRendererFrontend.set(this);
    
    Logger::info("Thread", "🚀 [%s] Creating renderer frontend", instanceId_.c_str());
    Logger::debug("Thread", "  Pixel ratio: %.2f", pixelRatio);
    Logger::debug("Thread", "  Main thread: %lu", 
                  std::hash<std::thread::id>{}(std::this_thread::get_id()));
    Logger::debug("Thread", "  Backend: %p", rendererBackend.get());
    
    try {
        // Create the Renderer using HarmonyRendererBackend::getImpl()
        // Note: Renderer creation must happen BEFORE starting RunLoop thread
        Logger::debug("HarmonyRendererFrontend", "Creating Renderer...");
        auto* harmonyBackend = static_cast<HarmonyRendererBackend*>(rendererBackend.get());
        gfx::RendererBackend& glBackend = harmonyBackend->getImpl();
        renderer = std::make_unique<Renderer>(glBackend, pixelRatio);
        Logger::info("HarmonyRendererFrontend", "Renderer created successfully: %p", renderer.get());
        
    } catch (const std::exception& e) {
        Logger::error("HarmonyRendererFrontend", "Failed to create Renderer: %s", e.what());
        // Re-throw to prevent using invalid renderer
        throw;
    }
    
    // Create and start RunLoop in background thread
    // IMPORTANT: AsyncTask must be created INSIDE the RunLoop thread!
    Logger::info("Thread", "▶️  [%s] Starting RunLoop thread", instanceId_.c_str());
    
    std::promise<void> runLoopReady;
    auto runLoopReadyFuture = runLoopReady.get_future();
    
    runLoopThread = std::thread([this, &runLoopReady]() {
        // Save thread ID for deadlock avoidance in update()
        runLoopThreadId = std::this_thread::get_id();
        
        Logger::debug("Thread", "  RunLoop thread ID: %lu", 
                      std::hash<std::thread::id>{}(runLoopThreadId));
        
        // Create RunLoop for this thread (will set thread-local automatically)
        runLoop = std::make_unique<util::RunLoop>();
        Logger::debug("Thread", "  RunLoop created: %p", runLoop.get());
        
        // 📝 注册到线程管理器
        Logger::info("Thread", "📝 [%s] Registering to ThreadManager", instanceId_.c_str());
        HarmonyRendererThreadManager::getInstance().registerRendererThread(
            instanceId_, runLoop.get(), runLoopThreadId);
        Logger::debug("ThreadMgr", "  Active threads: %zu", 
                      HarmonyRendererThreadManager::getInstance().getThreadCount());
        
        // Signal that RunLoop is ready (before starting the loop)
        runLoopReady.set_value();
        
        // Run the loop - this will process all invoke() calls from update()
        Logger::info("Thread", "  Starting RunLoop::run()...");
        runLoop->run();
        
        // 注销线程
        Logger::info("Thread", "  Unregistering from ThreadManager");
        HarmonyRendererThreadManager::getInstance().unregisterRendererThread(instanceId_);
        
        Logger::info("Thread", "  RunLoop thread ended");
    });
    
    // Wait for RunLoop to be fully initialized before returning
    runLoopReadyFuture.wait();
    Logger::debug("Thread", "  RunLoop thread ready");
    
    // 创建线程池（实例成员，不再使用静态）
    auto backgroundScheduler = Scheduler::GetBackground();
    threadPool_ = std::make_unique<TaggedScheduler>(backgroundScheduler, util::SimpleIdentity::Empty);
    Logger::debug("Thread", "  ThreadPool created: %p", threadPool_.get());
    
    // 🎯 启用 VSync 管理器
    try {
        Logger::info("Thread", "  Creating HarmonyVSyncManager...");
        vsyncManager_ = std::make_unique<HarmonyVSyncManager>();
        
        if (vsyncManager_->isAvailable()) {
            useVSync_ = true;
            Logger::info("Thread", "  ✅ VSync enabled - using system-level frame synchronization");
        } else {
            Logger::warn("Thread", "  ⚠️ VSync not available - falling back to manual throttling");
            useVSync_ = false;
            vsyncManager_.reset();
        }
    } catch (const std::exception& e) {
        Logger::error("Thread", "  Failed to create VSync manager: %s - falling back to manual throttling", e.what());
        useVSync_ = false;
        vsyncManager_.reset();
    }
    
    Logger::info("HarmonyRendererFrontend", "========== Constructor END ==========");
}

HarmonyRendererFrontend::~HarmonyRendererFrontend() {
    Logger::info("HarmonyRendererFrontend", "========== Destructor START ==========");
    
    // 🛡️ CRITICAL FIX: 在停止渲染线程前，先通知 Backend 停止渲染
    // 这样可以避免在析构期间发生跨线程的 EGL Context 访问
    if (rendererBackend) {
        Logger::debug("HarmonyRendererFrontend", "Notifying backend to pause rendering...");
        auto* harmonyBackend = static_cast<HarmonyRendererBackend*>(rendererBackend.get());
        harmonyBackend->pauseRendering();
        Logger::debug("HarmonyRendererFrontend", "Backend rendering paused");
    }
    
    // Stop VSync manager if exists
    if (vsyncManager_) {
        Logger::debug("HarmonyRendererFrontend", "Stopping VSync manager...");
        vsyncManager_->stop();
        vsyncManager_.reset();
        Logger::debug("HarmonyRendererFrontend", "VSync manager stopped and destroyed");
    }
    
    // 🔒 关键修复：确保 RunLoop 能够正常退出
    // 在 stop() 之前清空所有待处理的渲染请求
    renderRequested = false;
    pendingRequests = 0;
    needsRender = false;
    
    // Stop the RunLoop if it exists
    if (runLoop) {
        Logger::debug("HarmonyRendererFrontend", "Stopping RunLoop...");
        
        // 🔧 重要：stop() 会通过 invoke() 调度一个停止任务
        // 需要确保 RunLoop 线程能够处理这个任务
        runLoop->stop();
        
        // 给 RunLoop 一点时间处理 stop 命令
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
    
    // Wait for RunLoop thread to finish with timeout
    if (runLoopThread.joinable()) {
        Logger::debug("HarmonyRendererFrontend", "Waiting for RunLoop thread to join (with 5s timeout)...");
        
        // Use async + wait_for to implement timeout
        auto joinFuture = std::async(std::launch::async, [this]() {
            runLoopThread.join();
        });
        
        auto status = joinFuture.wait_for(std::chrono::seconds(5));
        
        if (status == std::future_status::ready) {
            Logger::info("Thread", "  ✅ RunLoop thread joined successfully");
        } else {
            Logger::error("Thread", "  ❌ RunLoop thread join timed out after 5s");
            Logger::error("Thread", "  This indicates RunLoop is stuck - forcing detach");
            
            // 尝试多次 stop 强制退出
            for (int i = 0; i < 3; i++) {
                Logger::warn("Thread", "  Retry stop() attempt %d/3", i + 1);
                if (runLoop) {
                    runLoop->stop();
                }
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
                
                auto retryStatus = joinFuture.wait_for(std::chrono::milliseconds(500));
                if (retryStatus == std::future_status::ready) {
                    Logger::info("Thread", "  ✅ RunLoop thread joined on retry %d", i + 1);
                    goto join_success;
                }
            }
            
            Logger::error("Thread", "  ⚠️ Detaching RunLoop thread (may cause resource leak)");
            runLoopThread.detach();
        }
join_success:
        ;
    }
    
    // 🛡️ 渲染线程已经结束，现在可以安全地清理资源
    // Backend 的析构函数会在主线程上执行，但由于我们已经设置了 isStopped_ 标志，
    // 所以不会尝试访问 EGL Context
    
    currentRendererFrontend.set(nullptr);
    Logger::info("HarmonyRendererFrontend", "========== Destructor END ==========");
}

// Implement pure virtual methods from RendererFrontend
void HarmonyRendererFrontend::reset() {
    Logger::info("HarmonyRendererFrontend", "reset() called");
    if (renderer) {
        // Renderer cleanup is handled by unique_ptr
    }
}

void HarmonyRendererFrontend::setObserver(RendererObserver& observer) {
    Logger::info("HarmonyRendererFrontend", "========== setObserver() START ==========");
    Logger::debug("HarmonyRendererFrontend", "Setting observer for Renderer (direct mode)");
    
    if (renderer) {
        // Directly set observer without ForwardingRendererObserver
        // Events will be called synchronously in render thread
        // This avoids the RunLoop dependency issue
        renderer->setObserver(&observer);
        Logger::info("HarmonyRendererFrontend", "Observer set successfully (direct mode)");
    } else {
        Logger::error("HarmonyRendererFrontend", "Cannot set observer: renderer is null");
    }
    
    Logger::info("HarmonyRendererFrontend", "========== setObserver() END ==========");
}

void HarmonyRendererFrontend::update(std::shared_ptr<UpdateParameters> params) {
    if (!params) {
        return;
    }
    
    // 🚀 请求队列机制：存储最新的参数，然后调度渲染
    {
        std::lock_guard<std::mutex> lock(updateParamsMutex);
        updateParams = std::move(params);
    }
    
    // 增加待处理请求计数
    pendingRequests++;
    
    // 调度渲染（会自动防抖）
    scheduleRender();
}

void HarmonyRendererFrontend::scheduleRender() {
    // 🔧 防抖机制：如果已经有渲染请求在队列中，不重复添加
    // 这类似于 Android 的 requestRender() 行为
    bool expected = false;
    if (!renderRequested.compare_exchange_strong(expected, true)) {
        return;
    }
    
    // 🎯 使用 VSync 同步（优先）
    if (useVSync_ && vsyncManager_) {
        // 🔒 关键修复：VSync 回调在系统线程执行，需要调度到 RunLoop 线程
        vsyncManager_->requestFrame([this]() {
            // VSync 回调在 OS_VSyncThread 执行，需要调度到渲染线程
            if (!runLoop) {
                Logger::error("VSync", "[%s] RunLoop is null in VSync callback", instanceId_.c_str());
                renderRequested = false;
                return;
            }
            
            runLoop->invoke([this]() {
                // 现在在渲染线程上执行
                // 重置请求标志，允许下次调度
                renderRequested = false;
                
                // 如果有待处理的请求，执行渲染
                if (pendingRequests > 0) {
                    pendingRequests.exchange(0);
                    performRender();
                }
            });
        });
    } else {
        // 🔧 降级方案：使用 RunLoop 异步调度（手动节流）
        if (!runLoop) {
            Logger::error("HarmonyRendererFrontend", "Cannot schedule render: RunLoop not initialized");
            renderRequested = false;  // 重置标志
            return;
        }
        
        runLoop->invoke([this]() {
            // 重置请求标志，允许下次调度
            renderRequested = false;
            
            // 如果有待处理的请求，执行渲染
            if (pendingRequests > 0) {
                pendingRequests.exchange(0);
                performRender();
            }
        });
    }
}

void HarmonyRendererFrontend::performRender() {
    // 检查是否暂停
    if (renderingPaused) {
        Logger::warn("HarmonyRendererFrontend", "performRender() - rendering paused, skipping");
        return;
    }
    
    // 🎯 VSync 模式：不需要手动节流（系统级同步）
    // 🔧 降级模式：使用手动帧率限制
    if (!useVSync_) {
        auto now = std::chrono::steady_clock::now();
        auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - lastFrameTime);
        
        if (elapsed < minFrameInterval) {
            return;  // 跳过此帧
        }
        
        lastFrameTime = now;
    }
    
    // 🔧 重要：重置 needsRender 标志
    if (needsRender) {
        needsRender = false;
    }
    
    // 获取最新的更新参数
    std::shared_ptr<UpdateParameters> params;
    {
        std::lock_guard<std::mutex> lock(updateParamsMutex);
        params = updateParams;
    }
    
    if (!params || !renderer || !rendererBackend) {
        Logger::warn("HarmonyRendererFrontend", "performRender() - missing params/renderer/backend");
        return;
    }
    
    // CRITICAL DEADLOCK FIX: Check if we're already on the RunLoop thread
    auto currentThreadId = std::this_thread::get_id();
    bool onRunLoopThread = (currentThreadId == runLoopThreadId);
    
    // 执行渲染
    try {
        // Activate the OpenGL context before rendering
        auto* harmonyBackend = static_cast<HarmonyRendererBackend*>(rendererBackend.get());
        gfx::RendererBackend& backendImpl = harmonyBackend->getImpl();
        gfx::BackendScope backendGuard{backendImpl};
        
        // HarmonyOS渲染时序优化 - 小延迟确保EGL上下文就绪
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
        
        renderer->render(params);
        
        // 🔧 渲染成功，重置错误计数
        consecutiveErrors = 0;
        
    } catch (const std::runtime_error& e) {
        // 🔧 改进的错误处理：不要立即永久停止
        consecutiveErrors++;
        Logger::error("HarmonyRendererFrontend", "Render failed (%d/%d): %s", 
                      consecutiveErrors.load(), 10, e.what());
        
        // 只有连续错误超过阈值才停止渲染
        if (consecutiveErrors >= 10) {
            Logger::error("HarmonyRendererFrontend", "Too many consecutive errors, pausing rendering");
            renderingPaused = true;
        }
    } catch (const std::exception& e) {
        consecutiveErrors++;
        Logger::error("HarmonyRendererFrontend", "Render failed (%d/%d): %s", 
                      consecutiveErrors.load(), 10, e.what());
        
        if (consecutiveErrors >= 10) {
            Logger::error("HarmonyRendererFrontend", "Too many consecutive errors, pausing rendering");
            renderingPaused = true;
        }
    }
}

const TaggedScheduler& HarmonyRendererFrontend::getThreadPool() const {
    // 返回实例成员（不再使用静态）
    if (!threadPool_) {
        // 理论上不应该发生（构造函数已创建）
        Logger::error("Frontend", "[%s] ThreadPool is null!", instanceId_.c_str());
        throw std::runtime_error("ThreadPool not initialized");
    }
    return *threadPool_;
}

// 🔀 线程切换方法实现
void HarmonyRendererFrontend::runOnRenderThread(std::function<void()>&& fn) {
    Logger::debug("Thread", "🔀 [%s] runOnRenderThread() called", instanceId_.c_str());
    
    if (isOnRenderThread()) {
        // 已在渲染线程，直接执行
        Logger::debug("Thread", "  ✓ Already on render thread, executing directly");
        fn();
    } else {
        // 跨线程调用，通过 RunLoop 调度
        Logger::debug("Thread", "  ↗️ Cross-thread call, invoking via RunLoop");
        Logger::debug("Thread", "  From: %lu -> To: %lu",
                      std::hash<std::thread::id>{}(std::this_thread::get_id()),
                      std::hash<std::thread::id>{}(runLoopThreadId));
        
        if (runLoop) {
            runLoop->invoke(std::move(fn));
        } else {
            Logger::error("Thread", "[%s] RunLoop is null, cannot invoke", instanceId_.c_str());
        }
    }
}

bool HarmonyRendererFrontend::isOnRenderThread() const {
    return std::this_thread::get_id() == runLoopThreadId;
}

void HarmonyRendererFrontend::setMap(Map* map_) {
    Logger::debug("HarmonyRendererFrontend", "setMap() called: %p", map_);
    map = map_;
}

void HarmonyRendererFrontend::render(Map& /* map */) {
    if (renderingPaused) {
        return;
    }
    try {
        // Rendering is handled through the update() mechanism
        Logger::debug("HarmonyRendererFrontend", "render() called");
    } catch (const std::exception& ex) {
        Log::Error(Event::OpenGL, "Error during rendering: " + std::string(ex.what()));
    }
}

void HarmonyRendererFrontend::setRenderingMode(MapObserver::RenderMode mode) {
    Logger::debug("HarmonyRendererFrontend", "setRenderingMode: %d", static_cast<int>(mode));
    renderingMode = mode;
}

void HarmonyRendererFrontend::requestRender() {
    if (renderingPaused) {
        return;
    }
    
    // 防抖：如果已经有待处理的渲染请求，忽略新请求
    // 这可以防止过度的渲染请求堆积
    if (needsRender) {
        return;
    }
    
    needsRender = true;
    
    // Note: Rendering is triggered through the update() mechanism
    // No need to explicitly trigger rendering here
    if (!map) {
        Logger::warn("HarmonyRendererFrontend", "Cannot trigger render: map is null");
    }
}

void HarmonyRendererFrontend::processRenderRequest() {
    if (!needsRender || renderingPaused || !map) {
        return;
    }
    needsRender = false;
    Logger::debug("HarmonyRendererFrontend", "processRenderRequest()");
}

void HarmonyRendererFrontend::pause() {
    Logger::info("HarmonyRendererFrontend", "pause() called");
    renderingPaused = true;
}

void HarmonyRendererFrontend::resume() {
    Logger::info("HarmonyRendererFrontend", "resume() called");
    if (renderingPaused) {
        renderingPaused = false;
        consecutiveErrors = 0;  // 重置错误计数
        Logger::info("HarmonyRendererFrontend", "Rendering resumed, error count reset");
        if (map) {
            requestRender();
        }
    }
}

gfx::Backend& HarmonyRendererFrontend::getRendererBackend() {
    return *rendererBackend;
}

} // namespace harmony
} // namespace mbgl

