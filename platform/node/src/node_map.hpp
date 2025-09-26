#pragma once

#include <mbgl/map/map.hpp>
#include <mbgl/storage/file_source.hpp>
#include <mbgl/storage/resource_options.hpp>
#include <mbgl/util/async_request.hpp>
#include <mbgl/util/client_options.hpp>
#include <mbgl/util/image.hpp>

#include <exception>
#include <napi.h>
#include <uv.h>
#include "napi_utils.hpp"

namespace mbgl {
class HeadlessFrontend;
} // namespace mbgl

namespace node_mbgl {

struct NodeMapObserver : public mbgl::MapObserver {
    void onDidFailLoadingMap(mbgl::MapLoadError, const std::string&) final;
};

class RenderRequest;

class NodeMap : public Napi::ObjectWrap<NodeMap> {
public:
    struct RenderOptions;
    class RenderWorker;

    NodeMap(const Napi::CallbackInfo& info);
    ~NodeMap() override;

    static Napi::FunctionReference constructor;
    static Napi::ObjectReference parseError;

    static void Init(Napi::Object target);
    static Napi::Value New(const Napi::CallbackInfo& info);

    Napi::Value Load(const Napi::CallbackInfo& info);
    Napi::Value Loaded(const Napi::CallbackInfo& info);
    Napi::Value Render(const Napi::CallbackInfo& info);
    Napi::Value Release(const Napi::CallbackInfo& info);
    Napi::Value Cancel(const Napi::CallbackInfo& info);
    Napi::Value AddSource(const Napi::CallbackInfo& info);
    Napi::Value RemoveSource(const Napi::CallbackInfo& info);
    Napi::Value AddLayer(const Napi::CallbackInfo& info);
    Napi::Value RemoveLayer(const Napi::CallbackInfo& info);
    Napi::Value AddImage(const Napi::CallbackInfo& info);
    Napi::Value RemoveImage(const Napi::CallbackInfo& info);
    Napi::Value SetLayerZoomRange(const Napi::CallbackInfo& info);
    Napi::Value SetLayerProperty(const Napi::CallbackInfo& info);
    Napi::Value SetFilter(const Napi::CallbackInfo& info);
    Napi::Value SetSize(const Napi::CallbackInfo& info);
    Napi::Value SetCenter(const Napi::CallbackInfo& info);
    Napi::Value SetZoom(const Napi::CallbackInfo& info);
    Napi::Value SetBearing(const Napi::CallbackInfo& info);
    Napi::Value SetPitch(const Napi::CallbackInfo& info);
    Napi::Value SetLight(const Napi::CallbackInfo& info);
    Napi::Value SetAxonometric(const Napi::CallbackInfo& info);
    Napi::Value SetXSkew(const Napi::CallbackInfo& info);
    Napi::Value SetYSkew(const Napi::CallbackInfo& info);
    Napi::Value DumpDebugLogs(const Napi::CallbackInfo& info);
    Napi::Value QueryRenderedFeatures(const Napi::CallbackInfo& info);

    Napi::Value SetFeatureState(const Napi::CallbackInfo& info);
    Napi::Value GetFeatureState(const Napi::CallbackInfo& info);
    Napi::Value RemoveFeatureState(const Napi::CallbackInfo& info);

    static Napi::Value ParseError(const Napi::Env& env, const char* msg);

    void startRender();
    void startRender(const RenderOptions& options);
    void renderFinished();

    void release();
    void cancel();

    static RenderOptions ParseOptions(const Napi::Object& obj);
    
    // Helper methods for reference counting
    void ref();
    void unref();

    const float pixelRatio;
    mbgl::MapMode mode;
    bool crossSourceCollisions;
    NodeMapObserver mapObserver;
    std::unique_ptr<mbgl::HeadlessFrontend> frontend;
    std::unique_ptr<mbgl::Map> map;

    std::exception_ptr error;
    mbgl::PremultipliedImage image;
    std::unique_ptr<RenderRequest> req;

    // Async for delivering the notifications of render completion.
    uv_async_t* async;

    bool loaded = false;
};

struct NodeFileSource : public mbgl::FileSource {
    NodeFileSource(NodeMap* nodeMap_)
        : nodeMap(nodeMap_) {}
    ~NodeFileSource() override = default;
    std::unique_ptr<mbgl::AsyncRequest> request(const mbgl::Resource&, mbgl::FileSource::Callback) final;
    bool canRequest(const mbgl::Resource&) const override;
    void setResourceOptions(mbgl::ResourceOptions) override;
    mbgl::ResourceOptions getResourceOptions() override;
    void setClientOptions(mbgl::ClientOptions) override;
    mbgl::ClientOptions getClientOptions() override;
    NodeMap* nodeMap;
    mbgl::ResourceOptions _resourceOptions;
    mbgl::ClientOptions _clientOptions;
};

} // namespace node_mbgl
