#include <napi.h>

#include <mbgl/util/run_loop.hpp>
#include <mbgl/gfx/backend.hpp>
#include <mbgl/gfx/backend_scope.hpp>

#include "node_map.hpp"
#include "node_logging.hpp"
#include "node_request.hpp"
#include "node_expression.hpp"
#include "napi_utils.hpp"

using namespace node_mbgl::napi_utils;

void SetBackendType(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    if (info.Length() < 1 || info[0].IsUndefined()) {
        throwError(env, "Requires a render backend name");
        return;
    }

    const std::string backendName = info[0].As<Napi::String>().Utf8Value();
    (void)backendName;
}

Napi::Object RegisterModule(Napi::Env env, Napi::Object exports) {
    // This has the effect of:
    //   a) Ensuring that the static local variable is initialized before any
    //   thread contention. b) unreffing an async handle, which otherwise would
    //   keep the default loop running.
    static mbgl::util::RunLoop nodeRunLoop;
    nodeRunLoop.stop();

    exports.Set("setBackendType", Napi::Function::New(env, SetBackendType));

    node_mbgl::NodeMap::Init(exports);
    node_mbgl::NodeRequest::Init(exports);
    node_mbgl::NodeExpression::Init(exports);

    // Exports Resource constants.
    Napi::Object resource = Napi::Object::New(env);

    resource.Set("Unknown", Napi::Number::New(env, mbgl::Resource::Unknown));
    resource.Set("Style", Napi::Number::New(env, mbgl::Resource::Style));
    resource.Set("Source", Napi::Number::New(env, mbgl::Resource::Source));
    resource.Set("Tile", Napi::Number::New(env, mbgl::Resource::Tile));
    resource.Set("Glyphs", Napi::Number::New(env, mbgl::Resource::Glyphs));
    resource.Set("SpriteImage", Napi::Number::New(env, mbgl::Resource::SpriteImage));
    resource.Set("SpriteJSON", Napi::Number::New(env, mbgl::Resource::SpriteJSON));

    exports.Set("Resource", resource);

    // Make the exported object inherit from EventEmitter
    Napi::Function require = exports.Get("require").As<Napi::Function>();
    Napi::Object events = require.Call(exports, {Napi::String::New(env, "events")}).As<Napi::Object>();
    Napi::Object EventEmitter = events.Get("EventEmitter").As<Napi::Object>();

    exports.SetPrototype(EventEmitter.Get("prototype"));
    EventEmitter.As<Napi::Function>().CallAsConstructor(exports).As<Napi::Object>();

    mbgl::Log::setObserver(std::make_unique<node_mbgl::NodeLogObserver>(exports));

    return exports;
}

NODE_API_MODULE(mapbox_gl_native, RegisterModule)
