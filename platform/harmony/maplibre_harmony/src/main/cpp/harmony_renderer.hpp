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

class HarmonyGLRendererBackend;
class HarmonyRendererFrontend;

class HarmonyRenderer : public mbgl::util::noncopyable, public mbgl::Scheduler {
public:
    HarmonyRenderer();
    ~HarmonyRenderer();
    
    // 初始化渲染器
    void initialize(int width, int height, float pixelRatio = 1.0f);
    
    // 设置OHNativeWindow
    void setNativeWindow(OHNativeWindow* window);
    
    // 设置地图
    void setMap(std::shared_ptr<Map> map);
    
    // 调整大小
    void resize(int width, int height);
    
    // 设置像素比例
    void setPixelRatio(float pixelRatio);
    
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
    HarmonyGLRendererBackend* getRendererBackend() const;
    
    // 获取渲染前端
    HarmonyRendererFrontend* getRendererFrontend() const;

    // Scheduler interface implementation
    void schedule(std::function<void()>&& fn) override;
    void schedule(const util::SimpleIdentity, std::function<void()>&& fn) override;
    mapbox::base::WeakPtr<Scheduler> makeWeakPtr() override;
    void runOnRenderThread(const util::SimpleIdentity tag, std::function<void()>&& fn) override;
    void runRenderJobs(const util::SimpleIdentity tag, bool closeQueue = false) override;
    void waitForEmpty(const util::SimpleIdentity = util::SimpleIdentity::Empty) override;

private:
    std::unique_ptr<HarmonyGLRendererBackend> rendererBackend;
    std::unique_ptr<HarmonyRendererFrontend> rendererFrontend;
    std::shared_ptr<Map> map;
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


