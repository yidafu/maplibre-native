#include "forwarding_renderer_observer.hpp"
#include "../utils/logger.h"

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

ForwardingRendererObserver::ForwardingRendererObserver(util::RunLoop& mapRunLoop, 
                                                       RendererObserver& delegate)
    : mailbox_(std::make_shared<Mailbox>(mapRunLoop)),
      delegate_(delegate, mailbox_) {
    Logger::info("ForwardingObserver", "Created with mailbox on Map RunLoop");
}

ForwardingRendererObserver::~ForwardingRendererObserver() {
    Logger::info("ForwardingObserver", "Closing mailbox");
    mailbox_->close();
}

void ForwardingRendererObserver::onInvalidate() {
    Logger::info("ForwardingObserver", "🔄 onInvalidate() START - forwarding to Map RunLoop");
    Logger::debug("ForwardingObserver", "  Current thread: %lu", 
                  std::hash<std::thread::id>{}(std::this_thread::get_id()));
    Logger::debug("ForwardingObserver", "  Mailbox: %p", mailbox_.get());
    Logger::debug("ForwardingObserver", "  About to invoke delegate...");
    
    delegate_.invoke(&RendererObserver::onInvalidate);
    
    Logger::info("ForwardingObserver", "  ✅ onInvalidate() delegate invoked (message sent to Mailbox)");
}

void ForwardingRendererObserver::onResourceError(std::exception_ptr err) {
    Logger::debug("ForwardingObserver", "🔄 onResourceError() - forwarding to Map RunLoop");
    delegate_.invoke(&RendererObserver::onResourceError, err);
}

void ForwardingRendererObserver::onWillStartRenderingMap() {
    Logger::debug("ForwardingObserver", "🔄 onWillStartRenderingMap() - forwarding to Map RunLoop");
    delegate_.invoke(&RendererObserver::onWillStartRenderingMap);
}

void ForwardingRendererObserver::onWillStartRenderingFrame() {
    Logger::debug("ForwardingObserver", "🔄 onWillStartRenderingFrame() - forwarding to Map RunLoop");
    delegate_.invoke(&RendererObserver::onWillStartRenderingFrame);
}

void ForwardingRendererObserver::onDidFinishRenderingFrame(RenderMode mode,
                                                           bool repaintNeeded,
                                                           bool placementChanged,
                                                           const gfx::RenderingStats& stats) {
    Logger::info("ForwardingObserver", "🔄 onDidFinishRenderingFrame() - forwarding to Map RunLoop");
    Logger::debug("ForwardingObserver", "  mode=%d, repaintNeeded=%d, placementChanged=%d", 
                  static_cast<int>(mode), repaintNeeded, placementChanged);
    
    // 需要选择正确的重载版本
    void (RendererObserver::*fn)(RenderMode, bool, bool, const gfx::RenderingStats&) 
        = &RendererObserver::onDidFinishRenderingFrame;
    
    delegate_.invoke(fn, mode, repaintNeeded, placementChanged, stats);
}

void ForwardingRendererObserver::onDidFinishRenderingMap() {
    Logger::info("ForwardingObserver", "🔄 onDidFinishRenderingMap() - forwarding to Map RunLoop");
    delegate_.invoke(&RendererObserver::onDidFinishRenderingMap);
}

void ForwardingRendererObserver::onStyleImageMissing(const std::string& id,
                                                     const StyleImageMissingCallback& done) {
    delegate_.invoke(&RendererObserver::onStyleImageMissing, id, done);
}

void ForwardingRendererObserver::onRemoveUnusedStyleImages(const std::vector<std::string>& ids) {
    delegate_.invoke(&RendererObserver::onRemoveUnusedStyleImages, ids);
}

void ForwardingRendererObserver::onPreCompileShader(shaders::BuiltIn id,
                                                    gfx::Backend::Type type,
                                                    const std::string& additionalDefines) {
    delegate_.invoke(&RendererObserver::onPreCompileShader, id, type, additionalDefines);
}

void ForwardingRendererObserver::onPostCompileShader(shaders::BuiltIn id,
                                                     gfx::Backend::Type type,
                                                     const std::string& additionalDefines) {
    delegate_.invoke(&RendererObserver::onPostCompileShader, id, type, additionalDefines);
}

void ForwardingRendererObserver::onShaderCompileFailed(shaders::BuiltIn id,
                                                       gfx::Backend::Type type,
                                                       const std::string& additionalDefines) {
    delegate_.invoke(&RendererObserver::onShaderCompileFailed, id, type, additionalDefines);
}

void ForwardingRendererObserver::onGlyphsLoaded(const FontStack& stack, const GlyphRange& range) {
    delegate_.invoke(&RendererObserver::onGlyphsLoaded, stack, range);
}

void ForwardingRendererObserver::onGlyphsError(const FontStack& stack,
                                               const GlyphRange& range,
                                               std::exception_ptr ex) {
    delegate_.invoke(&RendererObserver::onGlyphsError, stack, range, ex);
}

void ForwardingRendererObserver::onGlyphsRequested(const FontStack& stack, const GlyphRange& range) {
    delegate_.invoke(&RendererObserver::onGlyphsRequested, stack, range);
}

} // namespace harmony
} // namespace mbgl

