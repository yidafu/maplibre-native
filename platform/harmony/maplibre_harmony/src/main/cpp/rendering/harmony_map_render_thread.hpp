#pragma once

#include <mbgl/map/map.hpp>
#include <mbgl/renderer/renderer.hpp>
#include <mbgl/renderer/renderer_frontend.hpp>
#include <mbgl/util/run_loop.hpp>
#include <mbgl/map/map_observer.hpp>
#include <mbgl/gfx/backend.hpp>
#include <mbgl/actor/scheduler.hpp>

#include <memory>
#include <thread>
#include <atomic>
#include <functional>
#include <mutex>
#include <condition_variable>

// VSync management
#include "../vsync/harmony_vsync_manager.hpp"

namespace mbgl {
namespace harmony {

class HarmonyGLRendererBackend;

/**
 * HarmonyMapRenderThread - Map 和渲染的统一线程
 * 
 * 架构设计：
 * - Map 对象和 Renderer 对象在同一线程
 * - 线程拥有 RunLoop 处理异步消息
 * - EGL Context 绑定到此线程
 * 
 * 关键特性：
 * - 无跨线程并发问题
 * - FileSource 回调正常工作
 * - 线程安全的 EGL 操作
 * 
 * 参考 iOS 架构实现
 */
class HarmonyMapRenderThread : public RendererFrontend {
public:
    // 唯一实例标识（用于日志与隔离验证）
    static std::atomic<uint64_t> globalInstanceCounter_;
    const uint64_t instanceId_;
    /**
     * 构造函数
     * 
     * @param backend GL 后端（管理 EGL）
     * @param pixelRatio 像素比率
     * @param observer Map 观察者
     * @param mapOptions Map 配置（移动）
     * @param resourceOptions 资源配置（移动）
     * @param clientOptions 客户端配置（移动）
     * @param localIdeographFontFamily 本地表意文字字体族（可选）
     */
    HarmonyMapRenderThread(
        std::unique_ptr<gfx::Backend> backend,
        float pixelRatio,
        MapObserver& observer,
        MapOptions&& mapOptions,
        ResourceOptions&& resourceOptions,
        ClientOptions&& clientOptions,
        const std::optional<std::string>& localIdeographFontFamily = std::nullopt
    );
    
    /**
     * 析构函数 - 确保线程安全清理
     */
    ~HarmonyMapRenderThread() override;

    // 禁止拷贝和移动
    HarmonyMapRenderThread(const HarmonyMapRenderThread&) = delete;
    HarmonyMapRenderThread& operator=(const HarmonyMapRenderThread&) = delete;

    // ==================== 线程管理 ====================
    
    /**
     * 启动 Map+渲染线程
     * 阻塞直到线程初始化完成
     */
    void start();
    
    /**
     * 停止线程并等待退出
     */
    void stop();
    
    /**
     * 检查当前是否在 Map+渲染线程
     */
    bool isOnThread() const;
    
    /**
     * 获取线程 ID
     */
    std::thread::id getThreadId() const { return threadId_; }

    // ==================== Map 访问 ====================
    
    /**
     * 获取 Map 引用（线程安全）
     * 注意：必须通过 invoke() 调用 Map 方法
     */
    Map& getMap();
    
    /**
     * 在 Map+渲染线程执行任务
     * 如果已在线程内，直接执行
     * 否则调度到线程执行
     */
    void invoke(std::function<void()> task);

    // ==================== RendererFrontend 接口 ====================
    
    /**
     * Map 通知需要渲染
     * 因为在同一线程，直接调用 Renderer
     */
    void update(std::shared_ptr<UpdateParameters> params) override;
    
    /**
     * 设置渲染观察者
     */
    void setObserver(RendererObserver& observer) override;
    
    /**
     * 重置渲染器
     */
    void reset() override;
    
    /**
     * 获取线程池
     */
    const TaggedScheduler& getThreadPool() const override;

    // ==================== 渲染控制 ====================
    
    /**
     * 设置原生窗口（XComponent Surface）
     */
    void setNativeWindow(void* window);
    
    /**
     * 暂停渲染
     */
    void pause();
    
    /**
     * 恢复渲染
     */
    void resume();
    
    /**
     * 获取渲染后端
     */
    gfx::RendererBackend& getRendererBackend();
    
    /**
     * 调整 framebuffer 大小
     */
    void resizeFramebuffer(int width, int height);
    
    
    // ==================== 查询功能 ====================
    
    /**
     * 查询渲染的特征（点）
     */
    std::vector<Feature> queryRenderedFeatures(const ScreenCoordinate& point,
                                               const RenderedQueryOptions& options = {}) const;
    
    /**
     * 查询渲染的特征（框）
     */
    std::vector<Feature> queryRenderedFeatures(const ScreenBox& box,
                                               const RenderedQueryOptions& options = {}) const;
    
    /**
     * 设置 FPS 回调（参考 Android MapRenderer::setOnFpsChangedListener）
     */
    void setOnFpsChangedCallback(std::function<void(double)> callback);
    
    /**
     * 启用或禁用 FPS 测量
     */
    void enableFpsMeasurement(bool enable);

private:
    // ==================== 线程函数 ====================
    
    /**
     * 线程主循环
     * 1. 创建 RunLoop
     * 2. 初始化 EGL
     * 3. 创建 Renderer
     * 4. 创建 Map
     * 5. 运行 RunLoop
     */
    void threadLoop();
    
    /**
     * 初始化序列（在线程内）
     */
    bool initialize();
    
    /**
     * 清理资源（在线程内）
     */
    void cleanup();
    
    // ==================== VSync 控制 ====================
    
    /**
     * VSync 回调处理函数（在 VSync 时触发渲染）
     */
    void onVSyncFrame();

    // ==================== 成员变量 ====================
    
    // 线程对象
    std::thread thread_;
    std::thread::id threadId_;
    
    // 同步原语
    std::mutex mutex_;
    std::condition_variable cv_;
    std::atomic<bool> started_{false};
    std::atomic<bool> shouldStop_{false};
    std::atomic<bool> initialized_{false};
    std::atomic<bool> destroying_{false};  // ✅ 销毁标志，防止竞态条件
    
    // 核心对象（在线程内创建和销毁）
    std::unique_ptr<util::RunLoop> runLoop_;
    std::unique_ptr<Map> map_;
    std::unique_ptr<Renderer> renderer_;
    std::unique_ptr<gfx::Backend> backend_;
    std::unique_ptr<TaggedScheduler> threadPool_;
    
    // 初始化参数（从构造函数保存）
    float pixelRatio_;
    MapObserver* mapObserver_;
    MapOptions mapOptions_;
    ResourceOptions resourceOptions_;
    ClientOptions clientOptions_;
    std::optional<std::string> localIdeographFontFamily_;
    
    // 渲染状态
    std::atomic<bool> paused_{false};
    
    // FPS 测量（参考 Android MapRenderer）
    std::chrono::steady_clock::time_point lastFrameTime_;
    std::atomic<bool> measureFps_{false};
    std::function<void(double)> fpsCallback_;
    void* nativeWindow_{nullptr};
    
    // VSync 管理
    std::unique_ptr<HarmonyVSyncManager> vsyncManager_;
    std::shared_ptr<UpdateParameters> pendingUpdateParams_{nullptr};
    std::atomic<bool> pendingRender_{false};

    // 最近一次的逻辑尺寸（用于窗口重建后立即应用）
    int lastWidth_{0};
    int lastHeight_{0};
};

} // namespace harmony
} // namespace mbgl

