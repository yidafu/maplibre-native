#include "harmony_renderer_frontend.hpp"
#include "backends/harmony_renderer_backend.hpp"
#include "backends/harmony_gl_renderer_backend.hpp"
#include "vsync/harmony_vsync_manager.hpp"
#include "utils/logger.h"

#include <mbgl/gfx/backend_scope.hpp>
#include <mbgl/gl/renderer_backend.hpp>
#include <mbgl/util/logging.hpp>
#include <mbgl/util/thread_local.hpp>
#include <mbgl/actor/actor_ref.hpp>
#include <mbgl/actor/scheduler.hpp>
#include <thread>
#include <chrono>
#include <sstream>
#include <mutex>
#include <condition_variable>

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

static util::ThreadLocal<HarmonyRendererFrontend> currentRendererFrontend;

// Note: ForwardingRendererObserver was removed to avoid RunLoop dependency
// Observer callbacks are now called directly on the render thread

HarmonyRendererFrontend::HarmonyRendererFrontend(std::unique_ptr<gfx::Backend> backend,
                                                 float pixelRatio_)
    : pixelRatio(pixelRatio_),
      rendererBackend(std::move(backend)) {
    currentRendererFrontend.set(this);
    
    Logger::info("HarmonyRendererFrontend", "========== Constructor START ==========");
    Logger::debug("HarmonyRendererFrontend", "pixelRatio=%.2f, backend=%p", pixelRatio, rendererBackend.get());
    
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
    
    // 🔄 Android 风格：创建专用渲染线程（线程隔离模型）
    // 关键：EGL Context 将在此线程创建，并始终在此线程使用
    Logger::info("HarmonyRendererFrontend", "Creating dedicated render thread (Android model)...");
    
    renderThread = std::thread([this]() {
        // 记录渲染线程 ID（用于线程安全验证）
        renderThreadId = std::this_thread::get_id();
        
        // 正确打印线程 ID（使用 stringstream）
        std::ostringstream oss;
        oss << renderThreadId;
        Logger::info("HarmonyRendererFrontend", "🎬 Render thread started, threadId=%s", oss.str().c_str());
        
        // 🔑 关键修复：创建独立的 RunLoop（Type::New）
        // 使用 Type::New 而不是默认类型，确保每个实例有独立的事件循环
        // Type::Default 会使用 uv_default_loop()，这是全局单例，会导致线程混乱
        runLoop = std::make_unique<util::RunLoop>(util::RunLoop::Type::New);
        Logger::info("HarmonyRendererFrontend", "RunLoop created in render thread (Type::New), loop=%p", runLoop.get());
        
        // ⚠️ 关键：EGL Context 将在首次 activate() 时在此线程创建
        // 这确保 Context 始终绑定到这个渲染线程（Android/iOS 模式）
        
        // 通知主线程：渲染线程已就绪
        {
            std::lock_guard<std::mutex> lock(initMutex);
            threadReady = true;
        }
        initCV.notify_one();
        Logger::debug("HarmonyRendererFrontend", "Render thread ready, notified main thread");
        
        // 运行渲染循环 - 处理所有渲染请求
        Logger::info("HarmonyRendererFrontend", "Starting render loop (RunLoop::run)...");
        runLoop->run();
        
        Logger::info("HarmonyRendererFrontend", "Render thread ended");
    });
    
    // 主线程等待渲染线程就绪
    {
        std::unique_lock<std::mutex> lock(initMutex);
        initCV.wait(lock, [this] { return threadReady; });
    }
    Logger::info("HarmonyRendererFrontend", "✅ Render thread initialization complete");
    
    // 🎯 初始化 VSync 管理器（尝试使用系统级 VSync）
    try {
        Logger::info("HarmonyRendererFrontend", "Creating HarmonyVSyncManager...");
        vsyncManager_ = std::make_unique<HarmonyVSyncManager>();
        
        if (vsyncManager_->isAvailable()) {
            useVSync_ = true;
            Logger::info("HarmonyRendererFrontend", "✅ VSync enabled - will use system-level frame synchronization");
        } else {
            Logger::warn("HarmonyRendererFrontend", "⚠️ VSync not available - falling back to manual throttling");
            useVSync_ = false;
            vsyncManager_.reset();
        }
    } catch (const std::exception& e) {
        Logger::error("HarmonyRendererFrontend", "Failed to create VSync manager: %s - falling back to manual throttling", e.what());
        useVSync_ = false;
        vsyncManager_.reset();
    }
    
    Logger::info("HarmonyRendererFrontend", "========== Constructor END ==========");
}

HarmonyRendererFrontend::~HarmonyRendererFrontend() {
    Logger::info("HarmonyRendererFrontend", "========== Destructor START ==========");
    
    // Stop VSync manager if exists
    if (vsyncManager_) {
        Logger::debug("HarmonyRendererFrontend", "Stopping VSync manager...");
        vsyncManager_->stop();
        vsyncManager_.reset();
        Logger::debug("HarmonyRendererFrontend", "VSync manager stopped and destroyed");
    }
    
    // 🔧 关键修复：设置停止标志，防止在析构期间activate()抛出异常
    // 这是第一优先级，必须在任何清理之前执行
    if (rendererBackend) {
        Logger::info("HarmonyRendererFrontend", "Setting backend stopped flag (prevent thread violations)...");
        auto* harmonyBackend = static_cast<HarmonyRendererBackend*>(rendererBackend.get());
        if (harmonyBackend) {
            try {
                auto& backendImpl = dynamic_cast<HarmonyGLRendererBackend&>(harmonyBackend->getImpl());
                backendImpl.pauseRendering();  // 设置 isStopped_ = true
                Logger::info("HarmonyRendererFrontend", "✅ Backend stopped flag set");
            } catch (...) {
                Logger::error("HarmonyRendererFrontend", "Failed to set backend stopped flag");
            }
        }
    }
    
    // 🔧 关键修复：在渲染线程清理资源（防止线程违规崩溃）
    // Map 和 EGL Context 都必须在创建它们的线程（渲染线程）上销毁
    if (runLoop) {
        Logger::info("HarmonyRendererFrontend", "🧹 Scheduling cleanup on render thread...");
        
        std::atomic<bool> cleanupDone{false};
        std::mutex cleanupMutex;
        std::condition_variable cleanupCV;
        
        // 在渲染线程执行清理
        // 🔧 使用 Priority::High 确保清理任务优先执行
        runLoop->invoke(util::RunLoop::Priority::High, [this, &cleanupDone, &cleanupMutex, &cleanupCV]() {
            try {
                Logger::info("HarmonyRendererFrontend", "🧹 Executing cleanup on render thread...");
                
                // 🔄 新架构：首先销毁 Map（在渲染线程）
                if (map) {
                    Logger::info("HarmonyRendererFrontend", "Destroying Map on render thread...");
                    map.reset();
                    Logger::info("HarmonyRendererFrontend", "✅ Map destroyed on render thread");
                }
                
                // 然后清理 EGL 资源
                if (rendererBackend) {
                    auto* harmonyBackend = static_cast<HarmonyRendererBackend*>(rendererBackend.get());
                    if (harmonyBackend) {
                        auto& backendImpl = dynamic_cast<HarmonyGLRendererBackend&>(harmonyBackend->getImpl());
                        
                        // 在渲染线程清理EGL资源
                        Logger::debug("HarmonyRendererFrontend", "Cleaning up EGL context on render thread...");
                        backendImpl.cleanupEGLOnRenderThread();
                        Logger::info("HarmonyRendererFrontend", "✅ EGL cleanup completed on render thread");
                    }
                }
            } catch (const std::exception& e) {
                Logger::error("HarmonyRendererFrontend", "Error during cleanup: %s", e.what());
            }
            
            // 通知清理完成
            {
                std::lock_guard<std::mutex> lock(cleanupMutex);
                cleanupDone = true;
            }
            cleanupCV.notify_one();
        });
        
        // 等待清理完成（带超时保护）
        {
            std::unique_lock<std::mutex> lock(cleanupMutex);
            bool success = cleanupCV.wait_for(lock, std::chrono::seconds(2), [&cleanupDone]() {
                return cleanupDone.load();
            });
            
            if (success) {
                Logger::info("HarmonyRendererFrontend", "✅ Cleanup confirmed");
            } else {
                Logger::warn("HarmonyRendererFrontend", "⚠️ Cleanup timeout after 2s - continuing shutdown anyway");
            }
        }
    } else {
        Logger::warn("HarmonyRendererFrontend", "Skipping cleanup - runLoop is null");
    }
    
    // Stop the RunLoop if it exists
    if (runLoop) {
        Logger::debug("HarmonyRendererFrontend", "Stopping RunLoop...");
        runLoop->stop();
    }
    
    // Wait for render thread to finish
    if (renderThread.joinable()) {
        Logger::debug("HarmonyRendererFrontend", "Waiting for render thread to join...");
        renderThread.join();
        Logger::debug("HarmonyRendererFrontend", "Render thread joined");
    }
    
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
        Logger::debug("HarmonyRendererFrontend", "🔄 scheduleRender() - already scheduled, skipping");
        return;
    }
    
    // 🔍 日志：scheduleRender 被调用
    std::ostringstream callerThread;
    callerThread << std::this_thread::get_id();
    Logger::debug("HarmonyRendererFrontend", "📥 scheduleRender() called from thread=%s", callerThread.str().c_str());
    
    // 🎯 使用 VSync 同步（优先）
    if (useVSync_ && vsyncManager_) {
        Logger::debug("HarmonyRendererFrontend", "📡 Using VSync path - requesting frame from VSync manager");
        
        // VSync 回调在 VSync 线程执行，需要转发到渲染线程
        vsyncManager_->requestFrame([this]() {
            // 🔍 日志：VSync 回调执行
            std::ostringstream vsyncThread;
            vsyncThread << std::this_thread::get_id();
            Logger::debug("HarmonyRendererFrontend", "⚡ VSync callback fired (thread=%s)", vsyncThread.str().c_str());
            
            // ✅ 关键修复：转发到渲染线程执行（通过 RunLoop）
            if (runLoop) {
                Logger::debug("HarmonyRendererFrontend", "🔀 Forwarding to render thread via RunLoop::invoke()");
                
                runLoop->invoke([this]() {
                    // 🔍 日志：RunLoop 回调执行
                    std::ostringstream runLoopThread;
                    runLoopThread << std::this_thread::get_id();
                    Logger::debug("HarmonyRendererFrontend", "🔄 RunLoop callback executing (thread=%s)", runLoopThread.str().c_str());
                    
                    // 重置请求标志，允许下次调度
                    renderRequested = false;
                    
                    // 如果有待处理的请求，执行渲染
                    if (pendingRequests > 0) {
                        pendingRequests.exchange(0);
                        Logger::debug("HarmonyRendererFrontend", "🎬 Calling performRender() from RunLoop callback");
                        performRender();  // ✅ 现在在渲染线程执行
                    } else {
                        Logger::debug("HarmonyRendererFrontend", "⏭️ No pending requests, skipping performRender");
                    }
                });
            } else {
                Logger::error("HarmonyRendererFrontend", "❌ RunLoop is null in VSync callback!");
            }
        });
    } else {
        Logger::debug("HarmonyRendererFrontend", "🔧 Using RunLoop path (VSync not available)");
        
        // 🔧 降级方案：使用 RunLoop 异步调度（手动节流）
        if (!runLoop) {
            Logger::error("HarmonyRendererFrontend", "Cannot schedule render: RunLoop not initialized");
            renderRequested = false;  // 重置标志
            return;
        }
        
        runLoop->invoke([this]() {
            // 🔍 日志：RunLoop 回调执行
            std::ostringstream runLoopThread;
            runLoopThread << std::this_thread::get_id();
            Logger::debug("HarmonyRendererFrontend", "🔄 RunLoop callback executing (thread=%s)", runLoopThread.str().c_str());
            
            // 重置请求标志，允许下次调度
            renderRequested = false;
            
            // 如果有待处理的请求，执行渲染
            if (pendingRequests > 0) {
                pendingRequests.exchange(0);
                Logger::debug("HarmonyRendererFrontend", "🎬 Calling performRender() from RunLoop callback");
                performRender();
            } else {
                Logger::debug("HarmonyRendererFrontend", "⏭️ No pending requests, skipping performRender");
            }
        });
    }
}

void HarmonyRendererFrontend::performRender() {
    // 实例标识
    static int renderInstanceCounter = 0;
    static std::map<void*, int> renderInstanceIds;
    if (renderInstanceIds.find(this) == renderInstanceIds.end()) {
        renderInstanceIds[this] = ++renderInstanceCounter;
    }
    int instanceId = renderInstanceIds[this];
    
    // 🛡️ 线程安全检查：确保在渲染线程执行
    auto currentThreadId = std::this_thread::get_id();
    if (currentThreadId != renderThreadId) {
        std::ostringstream expected, actual;
        expected << renderThreadId;
        actual << currentThreadId;
        
        Logger::error("HarmonyRendererFrontend", 
            "❌ CRITICAL: performRender called from wrong thread!\n"
            "  [Instance #%d] Expected render thread: %s\n"
            "  [Instance #%d] Called from thread:      %s\n"
            "  This indicates a threading bug!",
            instanceId, expected.str().c_str(),
            instanceId, actual.str().c_str());
        return;
    }
    
    // 检查是否暂停
    if (renderingPaused) {
        Logger::warn("HarmonyRendererFrontend", "[Instance #%d] performRender() - rendering paused, skipping", instanceId);
        return;
    }
    
    // 🔍 日志：打印当前线程和期望线程（便于对比）
    std::ostringstream current, expected;
    current << currentThreadId;
    expected << renderThreadId;
    Logger::debug("HarmonyRendererFrontend", 
        "🎬 [Instance #%d] performRender() START (this=%p)\n"
        "   Current thread: %s\n"
        "   Expected thread: %s\n"
        "   Match: %s", 
        instanceId, this,
        current.str().c_str(),
        expected.str().c_str(),
        (currentThreadId == renderThreadId) ? "✅ YES" : "❌ NO");
    
    // 🎯 VSync 模式：不需要手动节流（系统级同步）
    // 🔧 降级模式：使用手动帧率限制
    if (!useVSync_) {
        auto now = std::chrono::steady_clock::now();
        auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - lastFrameTime);
        
        if (elapsed < minFrameInterval) {
            Logger::debug("HarmonyRendererFrontend", "[Instance #%d] Skipping frame (too soon: %lldms < %lldms)", 
                         instanceId, elapsed.count(), minFrameInterval.count());
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
        Logger::warn("HarmonyRendererFrontend", "[Instance #%d] performRender() - missing params/renderer/backend", instanceId);
        return;
    }
    
    Logger::debug("HarmonyRendererFrontend", "[Instance #%d] About to render with params=%p", instanceId, params.get());
    
    // 执行渲染
    try {
        Logger::debug("HarmonyRendererFrontend", "[Instance #%d] Activating OpenGL context...", instanceId);
        
        // Activate the OpenGL context before rendering
        auto* harmonyBackend = static_cast<HarmonyRendererBackend*>(rendererBackend.get());
        gfx::RendererBackend& backendImpl = harmonyBackend->getImpl();
        gfx::BackendScope backendGuard{backendImpl};
        
        Logger::debug("HarmonyRendererFrontend", "[Instance #%d] Context activated, rendering...", instanceId);
        
        // HarmonyOS渲染时序优化 - 小延迟确保EGL上下文就绪
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
        
        renderer->render(params);
        
        Logger::debug("HarmonyRendererFrontend", "✅ [Instance #%d] Render completed successfully", instanceId);
        
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
    // Create a TaggedScheduler using the background scheduler
    static std::unique_ptr<TaggedScheduler> scheduler;
    if (!scheduler) {
        auto backgroundScheduler = Scheduler::GetBackground();
        scheduler = std::make_unique<TaggedScheduler>(backgroundScheduler, util::SimpleIdentity::Empty);
    }
    return *scheduler;
}

// 🔄 新方法：在渲染线程中创建 Map
void HarmonyRendererFrontend::initializeMap(MapObserver& observer,
                                             const MapOptions& mapOptions,
                                             const ResourceOptions& resourceOptions,
                                             const ClientOptions& clientOptions) {
    Logger::info("HarmonyRendererFrontend", "========== initializeMap() START ==========");
    
    // 确保在渲染线程调用
    if (std::this_thread::get_id() != renderThreadId) {
        Logger::error("HarmonyRendererFrontend", "❌ initializeMap() MUST be called from render thread!");
        Logger::error("HarmonyRendererFrontend", "Current thread=%lu, Render thread=%lu",
                     std::hash<std::thread::id>{}(std::this_thread::get_id()),
                     std::hash<std::thread::id>{}(renderThreadId));
        throw std::runtime_error("initializeMap() must be called from render thread");
    }
    
    if (map) {
        Logger::warn("HarmonyRendererFrontend", "Map already exists, destroying old one");
        map.reset();
    }
    
    try {
        Logger::info("HarmonyRendererFrontend", "Creating Map in render thread...");
        Logger::info("HarmonyRendererFrontend", "  - Observer: %p", &observer);
        Logger::info("HarmonyRendererFrontend", "  - Current Scheduler: %p", mbgl::Scheduler::GetCurrent());
        
        // 在渲染线程中创建 Map（与 iOS 理念一致）
        map = std::make_unique<Map>(*this, observer, mapOptions, resourceOptions, clientOptions);
        
        Logger::info("HarmonyRendererFrontend", "✅ Map created successfully: %p", map.get());
        Logger::info("HarmonyRendererFrontend", "✅ Map and Renderer now on same thread (merged architecture)");
        
    } catch (const std::exception& e) {
        Logger::error("HarmonyRendererFrontend", "Failed to create Map: %s", e.what());
        throw;
    }
    
    Logger::info("HarmonyRendererFrontend", "========== initializeMap() END ==========");
}

// 🔄 新方法：在渲染线程上执行任务
void HarmonyRendererFrontend::invokeOnRenderThread(std::function<void()>&& task) {
    if (!runLoop) {
        Logger::error("HarmonyRendererFrontend", "Cannot invoke: RunLoop is null");
        return;
    }
    
    // 使用 RunLoop::invoke 将任务调度到渲染线程
    runLoop->invoke(std::move(task));
}

void HarmonyRendererFrontend::setMap(Map* map_) {
    Logger::warn("HarmonyRendererFrontend", "⚠️ setMap(Map*) is deprecated - use initializeMap() instead");
    Logger::debug("HarmonyRendererFrontend", "setMap() called: %p", map_);
    externalMap = map_;  // 保存到 externalMap 而不是 map
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
    // 实例标识（复用performRender的计数器）
    static int requestInstanceCounter = 0;
    static std::map<void*, int> requestInstanceIds;
    if (requestInstanceIds.find(this) == requestInstanceIds.end()) {
        requestInstanceIds[this] = ++requestInstanceCounter;
    }
    int instanceId = requestInstanceIds[this];
    
    if (renderingPaused) {
        Logger::debug("HarmonyRendererFrontend", "[Instance #%d] requestRender() - paused, ignoring", instanceId);
        return;
    }
    
    // 防抖：如果已经有待处理的渲染请求，忽略新请求
    // 这可以防止过度的渲染请求堆积
    if (needsRender) {
        Logger::debug("HarmonyRendererFrontend", "[Instance #%d] requestRender() - already requested, ignoring", instanceId);
        return;
    }
    
    Logger::info("HarmonyRendererFrontend", "🎬 [Instance #%d] requestRender() - marking needsRender=true", instanceId);
    needsRender = true;
    
    // Note: Rendering is triggered through the update() mechanism
    // No need to explicitly trigger rendering here
    Map* activeMap = map ? map.get() : externalMap;
    if (!activeMap) {
        Logger::warn("HarmonyRendererFrontend", "[Instance #%d] Cannot trigger render: map is null", instanceId);
    }
}

void HarmonyRendererFrontend::processRenderRequest() {
    Map* activeMap = map ? map.get() : externalMap;
    if (!needsRender || renderingPaused || !activeMap) {
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
        Map* activeMap = map ? map.get() : externalMap;
        if (activeMap) {
            requestRender();
        }
    }
}

gfx::Backend& HarmonyRendererFrontend::getRendererBackend() {
    return *rendererBackend;
}

} // namespace harmony
} // namespace mbgl

