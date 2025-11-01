#pragma once

#include <mbgl/map/map.hpp>
#include <mbgl/util/noncopyable.hpp>
#include <mbgl/actor/scheduler.hpp>
#include <mbgl/util/identity.hpp>
#include <mbgl/util/geo.hpp>
#include <mbgl/util/feature.hpp>
#include <mbgl/renderer/query.hpp>
#include <native_window/external_window.h>
#include <memory>
#include <functional>

namespace mbgl {
namespace harmony {

// Forward declarations - use the appropriate backend based on build configuration
#if MLN_RENDER_BACKEND_VULKAN
class HarmonyVulkanRendererBackend;
using HarmonyRendererBackendImpl = HarmonyVulkanRendererBackend;
#else
class HarmonyGLRendererBackend;
using HarmonyRendererBackendImpl = HarmonyGLRendererBackend;
#endif

class HarmonyMapRenderThread;

class HarmonyRenderer : public mbgl::util::noncopyable, public mbgl::Scheduler, public mbgl::MapObserver {
public:
    HarmonyRenderer();
    ~HarmonyRenderer();
    
    // 初始化渲染器
    void initialize(int width, int height, float pixelRatio = 1.0f, const std::string& cachePath = "", 
                   const std::optional<std::string>& localIdeographFontFamily = std::nullopt);
    
    // 设置OHNativeWindow
    void setNativeWindow(OHNativeWindow* window);
    
    // 获取 Map 引用（用于外部访问）
    Map* getMap();
    
    // 调整大小
    void resize(int width, int height);
    
    // 请求渲染
    void requestRender();
    
    // 设置渲染模式
    void setRenderingMode(MapObserver::RenderMode mode);
    
    // 暂停渲染
    void pause();
    
    // 恢复渲染
    void resume();
    
    // 停止所有网络请求
    void stopAllRequests();
    
    // 异步停止所有请求（参考 Android/iOS，使用回调而不是硬编码等待）
    // onComplete: 所有异步操作停止后的回调
    void stopAllRequestsAsync(std::function<void()> onComplete);
    
    // 清理资源
    void cleanup();
    
    // 获取渲染后端
    HarmonyRendererBackendImpl* getRendererBackend() const;
    
    // 查询渲染特征
    std::vector<Feature> queryRenderedFeatures(const ScreenCoordinate& point,
                                               const RenderedQueryOptions& options = {}) const;
    std::vector<Feature> queryRenderedFeatures(const ScreenBox& box,
                                               const RenderedQueryOptions& options = {}) const;
    
    // 📝 实例标识
    std::string getInstanceId() const { return instanceId_; }
    
    // 🔀 便利的线程切换方法（不需要 tag 参数）
    void runOnRenderThread(std::function<void()>&& fn);
    bool isOnRenderThread() const;

    // Scheduler interface implementation
    void schedule(std::function<void()>&& fn) override;
    void schedule(const util::SimpleIdentity, std::function<void()>&& fn) override;
    mapbox::base::WeakPtr<Scheduler> makeWeakPtr() override;
    void runOnRenderThread(const util::SimpleIdentity tag, std::function<void()>&& fn) override;
    void runRenderJobs(const util::SimpleIdentity tag, bool closeQueue = false) override;
    void waitForEmpty(const util::SimpleIdentity = util::SimpleIdentity::Empty) override;

private:
    std::string instanceId_;  // 唯一标识符
    std::unique_ptr<HarmonyMapRenderThread> mapRenderThread_;  // Map+渲染线程
    int width = 0;
    int height = 0;
    float pixelRatio = 1.0f;
    bool initialized = false;
    
    // Scheduler support
    util::SimpleIdentity uniqueID;
    std::shared_ptr<mapbox::base::WeakPtrFactory<Scheduler>> weakFactory;
};

} // namespace harmony
} // namespace mbgl


