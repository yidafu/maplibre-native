#pragma once

#include <napi/native_api.h>
#include <mbgl/style/layers/custom_drawable_layer.hpp>
#include <functional>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

namespace maplibre {
namespace harmony {

/**
 * Shared drawable scene between the JS wrapper and the render-thread host.
 *
 * JS pushes draw commands (closures capturing already-converted geometry);
 * the host replays them inside CustomDrawableLayerHost::update() on the
 * render thread. The mutex protects the command list across threads.
 */
struct CustomDrawableState {
    using Interface = mbgl::style::CustomDrawableLayerHost::Interface;
    using DrawCommand = std::function<mbgl::util::SimpleIdentity(Interface&)>;

    std::mutex mutex;
    std::vector<DrawCommand> commands;
    std::vector<mbgl::util::SimpleIdentity> drawableIds;
    bool dirty = false;
};

/**
 * CustomDrawableLayerNAPI - NAPI wrapper for CustomDrawableLayer
 *
 * CustomDrawableLayerHost callbacks run on the render thread and cannot be
 * marshalled to JS synchronously, so instead of a JS-implemented host this
 * binding keeps a declarative scene: JS calls addPolyline/addFill/clear and
 * the native host rebuilds the drawables on the next frame.
 */
class CustomDrawableLayerNAPI {
public:
    CustomDrawableLayerNAPI(const std::string& layerId, std::unique_ptr<mbgl::style::CustomDrawableLayer> layer,
                            std::shared_ptr<CustomDrawableState> state);
    // Construct from an existing Layer (uses WeakPtr, does not take ownership)
    CustomDrawableLayerNAPI(mbgl::style::CustomDrawableLayer* layerPtr,
                            std::shared_ptr<CustomDrawableState> state);

    ~CustomDrawableLayerNAPI();

    // Register NAPI bindings
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value New(napi_env env, napi_callback_info info);
    // Create a NAPI instance from an existing native layer
    static napi_value CreateInstance(napi_env env, mbgl::style::CustomDrawableLayer* layerPtr);

    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);

    // Basic layer properties
    static napi_value GetId(napi_env env, napi_callback_info info);
    static napi_value GetType(napi_env env, napi_callback_info info);
    static napi_value SetVisibility(napi_env env, napi_callback_info info);
    static napi_value GetVisibility(napi_env env, napi_callback_info info);
    static napi_value SetMinZoom(napi_env env, napi_callback_info info);
    static napi_value GetMinZoom(napi_env env, napi_callback_info info);
    static napi_value SetMaxZoom(napi_env env, napi_callback_info info);
    static napi_value GetMaxZoom(napi_env env, napi_callback_info info);

    // Drawable scene management
    static napi_value AddPolyline(napi_env env, napi_callback_info info);
    static napi_value AddFill(napi_env env, napi_callback_info info);
    static napi_value Clear(napi_env env, napi_callback_info info);

    // Internal helpers
    std::string getId() const { return layerId; }
    mbgl::style::CustomDrawableLayer* getLayer() const {
        if (!layer && weakLayer) {
            return static_cast<mbgl::style::CustomDrawableLayer*>(weakLayer.get());
        }
        return layer.get();
    }

    // Release ownership (for Style.addLayer)
    std::unique_ptr<mbgl::style::Layer> releaseLayer() {
        ownsLayer = false;
        return std::unique_ptr<mbgl::style::Layer>(layer.release());
    }

    // After addLayer, keep a WeakPtr so the wrapper survives after the style
    // takes over ownership
    void attachToStyle(mbgl::style::CustomDrawableLayer* layerPtr) {
        if (layerPtr) {
            weakLayer = layerPtr->makeWeakPtr();
        }
    }

    static napi_ref constructor;

private:
    std::string layerId;
    std::unique_ptr<mbgl::style::CustomDrawableLayer> layer;
    bool ownsLayer;
    mapbox::base::WeakPtr<mbgl::style::Layer> weakLayer;
    std::shared_ptr<CustomDrawableState> state;
};

} // namespace harmony
} // namespace maplibre
