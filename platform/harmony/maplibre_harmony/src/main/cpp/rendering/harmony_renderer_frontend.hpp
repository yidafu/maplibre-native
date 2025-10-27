#pragma once

#include <mbgl/map/map.hpp>
#include <mbgl/map/map_observer.hpp>
#include <mbgl/renderer/renderer_frontend.hpp>
#include <mbgl/renderer/renderer.hpp>
#include <mbgl/renderer/renderer_observer.hpp>
#include <mbgl/util/run_loop.hpp>
#include <mbgl/util/async_task.hpp>
#include <mbgl/actor/mailbox.hpp>
#include <memory>
#include <thread>
#include <atomic>
#include <chrono>
#include <mutex>

namespace mbgl {
namespace harmony {

// Forward declaration
class HarmonyVSyncManager;

class HarmonyRendererFrontend : public RendererFrontend {
public:
    HarmonyRendererFrontend(std::unique_ptr<gfx::Backend>, float pixelRatio);
    ~HarmonyRendererFrontend() override;

    // Implement pure virtual methods from RendererFrontend
    void reset() override;
    void setObserver(RendererObserver&) override;
    void update(std::shared_ptr<UpdateParameters>) override;
    const TaggedScheduler& getThreadPool() const override;

    void setMap(Map* map);
    void render(Map&);
    void setRenderingMode(MapObserver::RenderMode mode);
    void requestRender();
    void processRenderRequest();
    void pause();
    void resume();
    
    // Get the renderer backend
    gfx::Backend& getRendererBackend();

private:
    Map* map = nullptr;
    float pixelRatio = 1.0f;
    bool renderingPaused = false;
    MapObserver::RenderMode renderingMode = MapObserver::RenderMode::Full;
    bool needsRender = false;
    std::unique_ptr<util::RunLoop> runLoop;
    
    // 🔄 线程隔离模型：每个实例拥有独立的渲染线程（Android 风格）
    std::thread renderThread;           // 专用渲染线程（原 runLoopThread）
    std::thread::id renderThreadId;     // 渲染线程 ID
    std::mutex initMutex;               // 初始化同步
    std::condition_variable initCV;     // 条件变量
    bool threadReady = false;           // 线程就绪标志
    
    std::unique_ptr<gfx::Backend> rendererBackend;
    
    // Renderer components
    std::unique_ptr<Renderer> renderer;
    
    // 🚀 请求队列机制（模拟 Android GLSurfaceView）
    std::atomic<bool> renderRequested{false};  // 是否有渲染请求在队列中
    std::atomic<int> pendingRequests{0};       // 待处理的请求计数
    std::mutex updateParamsMutex;              // 保护 updateParams 的互斥锁
    std::shared_ptr<UpdateParameters> updateParams;  // 存储最新的更新参数
    
    // 🎯 VSync 同步（系统级，替代手动节流）
    std::unique_ptr<HarmonyVSyncManager> vsyncManager_;  // VSync 管理器
    bool useVSync_ = true;  // 是否使用 VSync（如果创建失败则降级到手动节流）
    
    // 🔧 降级方案：手动节流（仅在 VSync 不可用时使用）
    std::chrono::steady_clock::time_point lastFrameTime{};
    const std::chrono::milliseconds minFrameInterval{10};  // 100fps 上限
    
    // 🛡️ 错误处理
    std::atomic<int> consecutiveErrors{0};     // 连续错误计数
    
    // 内部方法
    void scheduleRender();  // 调度渲染（使用 VSync 或 RunLoop）
    void performRender();   // 执行实际渲染
};

} // namespace harmony
} // namespace mbgl


