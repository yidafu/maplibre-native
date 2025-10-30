#pragma once

#include <mbgl/actor/actor_ref.hpp>
#include <mbgl/actor/mailbox.hpp>
#include <mbgl/renderer/renderer_observer.hpp>
#include <mbgl/util/run_loop.hpp>
#include <memory>

namespace mbgl {
namespace harmony {

/**
 * ForwardingRendererObserver - 转发渲染观察者
 * 
 * 参考 Android AndroidRendererFrontend 实现：
 * - 渲染回调在渲染线程触发
 * - 通过 Mailbox + ActorRef 转发到 Map RunLoop 线程
 * - 避免跨线程直接调用，确保线程安全
 * 
 * 工作原理：
 * 1. Renderer 在渲染线程调用观察者方法
 * 2. ForwardingObserver 通过 ActorRef 转发
 * 3. Mailbox 将调用调度到 Map RunLoop 线程
 * 4. 最终在 Map RunLoop 线程执行原始观察者
 */
class ForwardingRendererObserver : public RendererObserver {
public:
    /**
     * 构造函数
     * 
     * @param mapRunLoop Map RunLoop 线程引用
     * @param delegate 原始观察者（在 Map RunLoop 线程执行）
     */
    ForwardingRendererObserver(util::RunLoop& mapRunLoop, RendererObserver& delegate);
    
    ~ForwardingRendererObserver() override;

    // RendererObserver 接口实现
    // 所有方法在渲染线程被调用，然后转发到 Map RunLoop 线程

    void onInvalidate() override;

    void onResourceError(std::exception_ptr err) override;

    void onWillStartRenderingMap() override;

    void onWillStartRenderingFrame() override;

    void onDidFinishRenderingFrame(RenderMode mode,
                                   bool repaintNeeded,
                                   bool placementChanged,
                                   const gfx::RenderingStats& stats) override;

    void onDidFinishRenderingMap() override;

    void onStyleImageMissing(const std::string& id, 
                            const StyleImageMissingCallback& done) override;

    void onRemoveUnusedStyleImages(const std::vector<std::string>& ids) override;

    void onPreCompileShader(shaders::BuiltIn id,
                           gfx::Backend::Type type,
                           const std::string& additionalDefines) override;

    void onPostCompileShader(shaders::BuiltIn id,
                            gfx::Backend::Type type,
                            const std::string& additionalDefines) override;

    void onShaderCompileFailed(shaders::BuiltIn id,
                              gfx::Backend::Type type,
                              const std::string& additionalDefines) override;

    void onGlyphsLoaded(const FontStack& stack, const GlyphRange& range) override;

    void onGlyphsError(const FontStack& stack, 
                      const GlyphRange& range, 
                      std::exception_ptr ex) override;

    void onGlyphsRequested(const FontStack& stack, const GlyphRange& range) override;

private:
    // Mailbox 用于跨线程通信
    std::shared_ptr<Mailbox> mailbox_;
    
    // ActorRef 指向原始观察者（在 Map RunLoop 线程）
    ActorRef<RendererObserver> delegate_;
};

} // namespace harmony
} // namespace mbgl



