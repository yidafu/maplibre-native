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

namespace mbgl {
namespace harmony {

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
    std::thread runLoopThread;  // Background thread for RunLoop
    std::thread::id runLoopThreadId;  // Thread ID for deadlock avoidance
    std::unique_ptr<gfx::Backend> rendererBackend;
    
    // Renderer components
    std::unique_ptr<Renderer> renderer;
    // Note: updateParams and updateAsyncTask removed - we now use runLoop->invoke() directly
};

} // namespace harmony
} // namespace mbgl


