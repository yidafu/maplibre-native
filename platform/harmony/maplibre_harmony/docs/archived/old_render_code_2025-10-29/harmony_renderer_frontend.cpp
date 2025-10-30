#include "harmony_renderer_frontend.hpp"
#include "backends/harmony_renderer_backend.hpp"
#include "vsync/harmony_vsync_manager.hpp"
#include "harmony_render_thread.hpp"
#include "forwarding_renderer_observer.hpp"
#include "../utils/logger.h"
#include "../utils/anr_detector.hpp"

#include <mbgl/gfx/backend_scope.hpp>
#include <mbgl/gl/renderer_backend.hpp>
#include <mbgl/renderer/update_parameters.hpp>
#include <mbgl/util/logging.hpp>
#include <mbgl/util/thread_local.hpp>
#include <mbgl/actor/actor_ref.hpp>
#include <mbgl/actor/scheduler.hpp>
#include <thread>
#include <chrono>
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

HarmonyRendererFrontend::HarmonyRendererFrontend(std::unique_ptr<gfx::Backend> backend,
                                                 float pixelRatio_,
                                                 const std::string& instanceId)
    : instanceId_(instanceId.empty() ? generateInstanceId() : instanceId),
      pixelRatio(pixelRatio_),
      rendererBackend(std::move(backend)) {
    currentRendererFrontend.set(this);
    
    Logger::info("Frontend", "🚀 [%s] Creating renderer frontend (NEW ARCHITECTURE)", instanceId_.c_str());
    Logger::debug("Frontend", "  Pixel ratio: %.2f", pixelRatio);
    Logger::debug("Frontend", "  Current thread: %lu", 
                  std::hash<std::thread::id>{}(std::this_thread::get_id()));
    
    // 1. 保存 Map RunLoop 引用（当前线程必须有 RunLoop）
    mapRunLoop_ = util::RunLoop::Get();
    if (!mapRunLoop_) {
        throw std::runtime_error("HarmonyRendererFrontend must be created on a thread with RunLoop");
    }
    Logger::debug("Frontend", "  Map RunLoop: %p", mapRunLoop_);
    
    // 2. 创建 Renderer（在当前线程，Map RunLoop 线程）
    try {
        Logger::debug("Frontend", "Creating Renderer...");
        auto* harmonyBackend = static_cast<HarmonyRendererBackend*>(rendererBackend.get());
        gfx::RendererBackend& glBackend = harmonyBackend->getImpl();
        renderer = std::make_unique<Renderer>(glBackend, pixelRatio);
        Logger::info("Frontend", "Renderer created successfully: %p", renderer.get());
    } catch (const std::exception& e) {
        Logger::error("Frontend", "Failed to create Renderer: %s", e.what());
        throw;
    }
    
    // 3. 创建并启动渲染线程（替代 RunLoop thread）
    Logger::info("Frontend", "Creating render thread...");
    renderThread_ = std::make_unique<HarmonyRenderThread>();
    
    // 4. 启动渲染线程
    Logger::info("Frontend", "Starting render thread...");
    renderThread_->start();
    Logger::info("Frontend", "Render thread started, ID: %lu",
                 std::hash<std::thread::id>{}(renderThread_->getRenderThreadId()));
    
    // 注意：EGL Context 初始化将在 setNativeWindow() 后，
    // 在首次 activate() 调用时自动完成（Backend 的备份机制）
    
    // 5. 设置渲染回调
    renderThread_->setRenderCallback([this]() {
        performRender();
    });
    
    // 6. 创建线程池
    auto backgroundScheduler = Scheduler::GetBackground();
    threadPool_ = std::make_unique<TaggedScheduler>(backgroundScheduler, util::SimpleIdentity::Empty);
    Logger::debug("Frontend", "ThreadPool created: %p", threadPool_.get());
    
    // 7. 初始化 VSync 管理器
    try {
        Logger::info("Frontend", "Creating HarmonyVSyncManager...");
        vsyncManager_ = std::make_unique<HarmonyVSyncManager>();
        
        if (vsyncManager_->isAvailable()) {
            useVSync_ = true;
            Logger::info("Frontend", "✅ VSync enabled - using system-level frame synchronization");
        } else {
            Logger::warn("Frontend", "⚠️ VSync not available - falling back to manual throttling");
            useVSync_ = false;
            vsyncManager_.reset();
        }
    } catch (const std::exception& e) {
        Logger::error("Frontend", "Failed to create VSync manager: %s - falling back to manual throttling", e.what());
        useVSync_ = false;
        vsyncManager_.reset();
    }
    
    Logger::info("Frontend", "========== Constructor END (NEW ARCHITECTURE) ==========");
}

HarmonyRendererFrontend::~HarmonyRendererFrontend() {
    ANRDetector detector("HarmonyRendererFrontend destructor", 100, 1000);
    
    Logger::info("Frontend", "========== Destructor START [%s] ==========", instanceId_.c_str());
    
    // 1. 停止 VSync
    if (vsyncManager_) {
        Logger::debug("Frontend", "Stopping VSync manager...");
        vsyncManager_->stop();
        vsyncManager_.reset();
    }
    
    // 2. 通知 Backend 停止渲染
    if (rendererBackend) {
        Logger::debug("Frontend", "Pausing backend rendering...");
        auto* harmonyBackend = static_cast<HarmonyRendererBackend*>(rendererBackend.get());
        harmonyBackend->pauseRendering();
    }
    
    // 3. 清除渲染请求
    renderRequested = false;
    pendingRequests = 0;
    needsRender = false;
    
    // 4. 停止渲染线程
    if (renderThread_) {
        Logger::info("Frontend", "Stopping render thread...");
        renderThread_->stop();
        renderThread_.reset();
        Logger::info("Frontend", "Render thread stopped");
    }
    
    // 5. 清理资源
    forwardingObserver_.reset();
    renderer.reset();
    threadPool_.reset();
    rendererBackend.reset();
    
    currentRendererFrontend.set(nullptr);
    Logger::info("Frontend", "========== Destructor END [%s] ==========", instanceId_.c_str());
}

void HarmonyRendererFrontend::reset() {
    Logger::info("Frontend", "reset() called");
    if (renderer) {
        // Renderer cleanup is handled by unique_ptr
    }
}

void HarmonyRendererFrontend::setObserver(RendererObserver& observer) {
    Logger::info("Frontend", "========== setObserver() START ==========");
    Logger::debug("Frontend", "Setting observer with ForwardingRendererObserver");
    
    if (!mapRunLoop_) {
        Logger::error("Frontend", "Cannot set observer: Map RunLoop is null");
        return;
    }
    
    if (!renderer) {
        Logger::error("Frontend", "Cannot set observer: renderer is null");
        return;
    }
    
    // 创建转发观察者（在 Map RunLoop 线程）
    // 使用 shared_ptr 来管理生命周期
    auto forwardingObs = std::make_shared<ForwardingRendererObserver>(*mapRunLoop_, observer);
    
    // 在渲染线程设置观察者
    renderThread_->queueEvent([this, obs = forwardingObs]() {
        renderer->setObserver(obs.get());
        // 保存 shared_ptr，确保生命周期
        forwardingObserver_ = obs;
        Logger::info("Frontend", "Observer set successfully on render thread");
    });
    
    Logger::info("Frontend", "========== setObserver() END ==========");
}

void HarmonyRendererFrontend::update(std::shared_ptr<UpdateParameters> params) {
    Logger::info("Frontend", "🔄 [%s] update() called", instanceId_.c_str());
    
    if (!params) {
        Logger::warn("Frontend", "update() called with null params");
        return;
    }
    
    Logger::debug("Frontend", "  styleLoaded=%d, mode=%d", 
                  params->styleLoaded, static_cast<int>(params->mode));
    
    // 保存最新的参数
    {
        std::lock_guard<std::mutex> lock(updateParamsMutex);
        updateParams = std::move(params);
    }
    
    // 增加待处理请求计数
    pendingRequests++;
    
    Logger::debug("Frontend", "  pendingRequests=%d", pendingRequests.load());
    
    // 调度渲染
    scheduleRender();
}

void HarmonyRendererFrontend::scheduleRender() {
    Logger::info("Frontend", "📅 [%s] scheduleRender() called", instanceId_.c_str());
    
    // 防抖机制：如果已经有渲染请求在队列中，不重复添加
    bool expected = false;
    if (!renderRequested.compare_exchange_strong(expected, true)) {
        Logger::debug("Frontend", "  Already has pending render request, skipping");
        return;
    }
    
    Logger::debug("Frontend", "  useVSync_=%d, vsyncManager_=%p", useVSync_, vsyncManager_.get());
    
    // 使用 VSync 同步（优先）
    if (useVSync_ && vsyncManager_) {
        Logger::debug("Frontend", "  Requesting VSync frame...");
        vsyncManager_->requestFrame([this]() {
            Logger::debug("Frontend", "🔔 VSync callback triggered");
            
            // VSync 回调在系统线程，需要调度到渲染线程
            if (!renderThread_) {
                Logger::error("Frontend", "RenderThread is null in VSync callback");
                renderRequested = false;
                return;
            }
            
            renderThread_->queueEvent([this]() {
                Logger::debug("Frontend", "  VSync→RenderThread: resetting renderRequested");
                renderRequested = false;
                
                if (pendingRequests > 0) {
                    int count = pendingRequests.exchange(0);
                    Logger::info("Frontend", "  Requesting render (pending: %d)", count);
                    renderThread_->requestRender();
                } else {
                    Logger::warn("Frontend", "  VSync triggered but no pending requests");
                }
            });
        });
    } else {
        Logger::debug("Frontend", "  Using direct render thread queue (no VSync)");
        
        // 降级方案：直接调度到渲染线程
        if (!renderThread_) {
            Logger::error("Frontend", "Cannot schedule render: RenderThread not initialized");
            renderRequested = false;
            return;
        }
        
        renderThread_->queueEvent([this]() {
            renderRequested = false;
            
            if (pendingRequests > 0) {
                int count = pendingRequests.exchange(0);
                Logger::info("Frontend", "  Requesting render (pending: %d)", count);
                renderThread_->requestRender();
            }
        });
    }
    
    Logger::debug("Frontend", "  scheduleRender() completed");
}

void HarmonyRendererFrontend::performRender() {
    Logger::info("Frontend", "🎬 [%s] performRender() START", instanceId_.c_str());
    
    // 必须在渲染线程
    if (!renderThread_ || !renderThread_->isOnRenderThread()) {
        Logger::error("Frontend", "performRender() called from wrong thread!");
        return;
    }
    
    Logger::debug("Frontend", "  On render thread: %lu", 
                  std::hash<std::thread::id>{}(std::this_thread::get_id()));
    
    // 检查是否暂停
    if (renderingPaused) {
        Logger::warn("Frontend", "  Rendering paused, skipping");
        return;
    }
    
    // 手动节流（如果不使用 VSync）
    if (!useVSync_) {
        auto now = std::chrono::steady_clock::now();
        auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - lastFrameTime);
        
        if (elapsed < minFrameInterval) {
            return;  // 跳过此帧
        }
        
        lastFrameTime = now;
    }
    
    if (needsRender) {
        needsRender = false;
    }
    
    // 获取最新的更新参数
    std::shared_ptr<UpdateParameters> params;
    {
        std::lock_guard<std::mutex> lock(updateParamsMutex);
        params = updateParams;
    }
    
    Logger::debug("Frontend", "  params=%p, renderer=%p, backend=%p", 
                  params.get(), renderer.get(), rendererBackend.get());
    
    if (renderingPaused) {
        Logger::warn("Frontend", "  Rendering paused (check 1), returning");
        return;
    }
    
    if (!params) {
        Logger::error("Frontend", "  No update params, cannot render");
        return;
    }
    
    if (!renderer) {
        Logger::error("Frontend", "  No renderer, cannot render");
        return;
    }
    
    if (!rendererBackend) {
        Logger::error("Frontend", "  No renderer backend, cannot render");
        return;
    }
    
    Logger::info("Frontend", "  ✅ All prerequisites OK, proceeding to render");
    Logger::debug("Frontend", "    styleLoaded=%d, mode=%d", 
                  params->styleLoaded, static_cast<int>(params->mode));
    
    // 执行渲染
    try {
        if (renderingPaused) {
            Logger::warn("Frontend", "  Rendering paused (check 2), returning");
            return;
        }
        
        // 激活 OpenGL context
        Logger::debug("Frontend", "  Activating OpenGL context...");
        auto* harmonyBackend = static_cast<HarmonyRendererBackend*>(rendererBackend.get());
        gfx::RendererBackend& backendImpl = harmonyBackend->getImpl();
        
        Logger::debug("Frontend", "  Creating BackendScope...");
        gfx::BackendScope backendGuard{backendImpl};
        Logger::debug("Frontend", "  ✅ BackendScope created (EGL context activated)");
        
        if (renderingPaused) {
            Logger::warn("Frontend", "  Rendering paused (check 3), returning");
            return;
        }
        
        // 小延迟确保 EGL 上下文就绪
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
        
        Logger::info("Frontend", "  🎨 Calling Renderer::render()...");
        renderer->render(params);
        Logger::info("Frontend", "  ✅ Renderer::render() completed successfully");
        
        // 渲染成功，重置错误计数
        consecutiveErrors = 0;
        
        Logger::info("Frontend", "🎬 [%s] performRender() END - SUCCESS", instanceId_.c_str());
        
    } catch (const std::runtime_error& e) {
        consecutiveErrors++;
        Logger::error("Frontend", "Render failed (%d/%d): %s", 
                      consecutiveErrors.load(), 10, e.what());
        
        if (consecutiveErrors >= 10) {
            Logger::error("Frontend", "Too many consecutive errors, pausing rendering");
            renderingPaused = true;
        }
    } catch (const std::exception& e) {
        consecutiveErrors++;
        Logger::error("Frontend", "Render failed (%d/%d): %s", 
                      consecutiveErrors.load(), 10, e.what());
        
        if (consecutiveErrors >= 10) {
            Logger::error("Frontend", "Too many consecutive errors, pausing rendering");
            renderingPaused = true;
        }
    }
}

const TaggedScheduler& HarmonyRendererFrontend::getThreadPool() const {
    if (!threadPool_) {
        Logger::error("Frontend", "[%s] ThreadPool is null!", instanceId_.c_str());
        throw std::runtime_error("ThreadPool not initialized");
    }
    return *threadPool_;
}

void HarmonyRendererFrontend::runOnRenderThread(std::function<void()>&& fn) {
    Logger::debug("Frontend", "🔀 [%s] runOnRenderThread() called", instanceId_.c_str());
    
    if (isOnRenderThread()) {
        Logger::debug("Frontend", "  ✓ Already on render thread, executing directly");
        fn();
    } else {
        Logger::debug("Frontend", "  ↗️ Cross-thread call, queueing to render thread");
        
        if (renderThread_) {
            renderThread_->queueEvent(std::move(fn));
        } else {
            Logger::error("Frontend", "[%s] RenderThread is null, cannot invoke", instanceId_.c_str());
        }
    }
}

bool HarmonyRendererFrontend::isOnRenderThread() const {
    return renderThread_ && renderThread_->isOnRenderThread();
}

std::thread::id HarmonyRendererFrontend::getRenderThreadId() const {
    return renderThread_ ? renderThread_->getRenderThreadId() : std::thread::id();
}

void HarmonyRendererFrontend::setMap(Map* map_) {
    Logger::debug("Frontend", "setMap() called: %p", map_);
    map = map_;
}

void HarmonyRendererFrontend::render(Map& /* map */) {
    if (renderingPaused) {
        return;
    }
    try {
        Logger::debug("Frontend", "render() called");
    } catch (const std::exception& ex) {
        Log::Error(Event::OpenGL, "Error during rendering: " + std::string(ex.what()));
    }
}

void HarmonyRendererFrontend::setRenderingMode(MapObserver::RenderMode mode) {
    Logger::debug("Frontend", "setRenderingMode: %d", static_cast<int>(mode));
    renderingMode = mode;
}

void HarmonyRendererFrontend::requestRender() {
    if (renderingPaused) {
        return;
    }
    
    if (needsRender) {
        return;
    }
    
    needsRender = true;
    
    if (!map) {
        Logger::warn("Frontend", "Cannot trigger render: map is null");
    }
}

void HarmonyRendererFrontend::processRenderRequest() {
    if (!needsRender || renderingPaused || !map) {
        return;
    }
    needsRender = false;
    Logger::debug("Frontend", "processRenderRequest()");
}

void HarmonyRendererFrontend::pause() {
    Logger::info("Frontend", "pause() called");
    renderingPaused = true;
    if (renderThread_) {
        renderThread_->pause();
    }
}

void HarmonyRendererFrontend::resume() {
    Logger::info("Frontend", "resume() called");
    if (renderingPaused) {
        renderingPaused = false;
        consecutiveErrors = 0;
        Logger::info("Frontend", "Rendering resumed, error count reset");
        if (renderThread_) {
            renderThread_->resume();
        }
        if (map) {
            requestRender();
        }
    }
}

gfx::Backend& HarmonyRendererFrontend::getRendererBackend() {
    return *rendererBackend;
}

std::vector<mbgl::Feature> HarmonyRendererFrontend::queryRenderedFeatures(
    const mbgl::ScreenBox& box,
    const mbgl::RenderedQueryOptions& options) const {
    
    Logger::debug("Frontend", "queryRenderedFeatures(box) called");
    
    if (!renderer) {
        Logger::error("Frontend", "Renderer is null, returning empty results");
        return {};
    }
    
    try {
        auto result = renderer->queryRenderedFeatures(box, options);
        Logger::debug("Frontend", "queryRenderedFeatures(box) returned %zu features", result.size());
        return result;
    } catch (const std::exception& e) {
        Logger::error("Frontend", "queryRenderedFeatures(box) failed: %s", e.what());
        return {};
    }
}

std::vector<mbgl::Feature> HarmonyRendererFrontend::queryRenderedFeatures(
    const mbgl::ScreenCoordinate& point,
    const mbgl::RenderedQueryOptions& options) const {
    
    Logger::debug("Frontend", "queryRenderedFeatures(point) called: x=%.2f, y=%.2f", point.x, point.y);
    
    if (!renderer) {
        Logger::error("Frontend", "Renderer is null, returning empty results");
        return {};
    }
    
    try {
        auto result = renderer->queryRenderedFeatures(point, options);
        Logger::debug("Frontend", "queryRenderedFeatures(point) returned %zu features", result.size());
        return result;
    } catch (const std::exception& e) {
        Logger::error("Frontend", "queryRenderedFeatures(point) failed: %s", e.what());
        return {};
    }
}

} // namespace harmony
} // namespace mbgl
