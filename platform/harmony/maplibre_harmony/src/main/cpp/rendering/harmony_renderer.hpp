#pragma once

#include <mbgl/map/map.hpp>
#include <mbgl/util/noncopyable.hpp>
#include <mbgl/actor/scheduler.hpp>
#include <mbgl/util/identity.hpp>
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

class HarmonyRendererFrontend;

class HarmonyRenderer : public mbgl::util::noncopyable, public mbgl::Scheduler {
public:
    HarmonyRenderer();
    ~HarmonyRenderer();
    
    // 初始化渲染器
    void initialize(int width, int height, float pixelRatio = 1.0f, const std::string& cachePath = "");
    
    // 设置OHNativeWindow
    void setNativeWindow(OHNativeWindow* window);
    
    // 设置地图（接受裸指针，不持有所有权）
    void setMap(Map* map);
    
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
    
    // 清理资源
    void cleanup();
    
    // 获取渲染后端
    HarmonyRendererBackendImpl* getRendererBackend() const;
    
    // 获取渲染前端
    HarmonyRendererFrontend* getRendererFrontend() const;
    
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
    std::unique_ptr<HarmonyRendererBackendImpl> rendererBackend;
    std::unique_ptr<HarmonyRendererFrontend> rendererFrontend;
    Map* map = nullptr;  // 不持有所有权，只保存引用
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


