#include "node_map.hpp"
#include <iostream>
#include <uv.h>
#include "node_request.hpp"
#include "node_feature.hpp"
#include "node_conversion.hpp"
#include "napi_utils.hpp"

#include <mbgl/renderer/renderer.hpp>
#include <mbgl/gfx/headless_frontend.hpp>
#include <mbgl/style/conversion/source.hpp>
#include <mbgl/style/conversion/layer.hpp>
#include <mbgl/style/conversion/filter.hpp>
#include <mbgl/style/conversion/light.hpp>
#include <mbgl/style/conversion/constant.hpp>

#include <mbgl/style/layers/background_layer.hpp>
#include <mbgl/style/layers/circle_layer.hpp>
#include <mbgl/style/layers/fill_layer.hpp>
#include <mbgl/style/layers/fill_extrusion_layer.hpp>
#include <mbgl/style/layers/heatmap_layer.hpp>
#include <mbgl/style/layers/hillshade_layer.hpp>
#include <mbgl/style/layers/line_layer.hpp>
#include <mbgl/style/layers/raster_layer.hpp>
#include <mbgl/style/layers/symbol_layer.hpp>

#include <mbgl/map/map.hpp>
#include <mbgl/map/map_observer.hpp>
#include <mbgl/storage/file_source_manager.hpp>
#include <mbgl/storage/resource_options.hpp>
#include <mbgl/style/image.hpp>
#include <mbgl/style/light.hpp>
#include <mbgl/style/style.hpp>
#include <mbgl/util/async_request.hpp>
#include <mbgl/util/exception.hpp>
#include <mbgl/util/logging.hpp>
#include <mbgl/util/premultiply.hpp>

// 为mbgl::Value提供Converter特化实现
namespace mbgl {
namespace style {
namespace conversion {

template <>
struct Converter<mbgl::Value> {
    std::optional<mbgl::Value> operator()(const Convertible& value, Error& error) const {
        if (mbgl::style::conversion::isNull(value)) {
            // Handle null value
            return mbgl::Value();
        } else if (mbgl::style::conversion::isBool(value)) {
            // Handle boolean
            return mbgl::Value(bool(*mbgl::style::conversion::toBool(value)));
        } else if (mbgl::style::conversion::isNumber(value)) {
            // Handle number
            double num = *mbgl::style::conversion::toDouble(value);
            // Try to preserve integer types when possible
            if (num == std::floor(num)) {
                int64_t intValue = static_cast<int64_t>(num);
                if (intValue >= 0 && intValue <= std::numeric_limits<uint64_t>::max()) {
                    return mbgl::Value(uint64_t(intValue));
                } else {
                    return mbgl::Value(int64_t(num));
                }
            }
            return mbgl::Value(num);
        } else if (mbgl::style::conversion::isString(value)) {
            // Handle string
            return mbgl::Value(std::string(*mbgl::style::conversion::toString(value)));
        } else if (mbgl::style::conversion::isArray(value)) {
            // Handle array
            mapbox::base::ValueArray array;
            array.reserve(mbgl::style::conversion::arrayLength(value));
            for (std::size_t i = 0; i < mbgl::style::conversion::arrayLength(value); ++i) {
                auto element = (*this)(mbgl::style::conversion::arrayMember(value, i), error);
                if (!element) {
                    return {};
                }
                array.push_back(*element);
            }
            return mbgl::Value(array);
        } else if (mbgl::style::conversion::isObject(value)) {
            // Handle object
            mapbox::base::ValueObject object;
            auto result = mbgl::style::conversion::eachMember(value, [&](const std::string& key, const Convertible& member) -> std::optional<Error> {
                auto converted = (*this)(member, error);
                if (!converted) {
                    return error;
                }
                object[key] = *converted;
                return {};
            });
            if (result) {
                error = *result;
                return {};
            }
            return mbgl::Value(object);
        }
        error = Error{"Cannot convert to mbgl::Value"};
        return {};
    }
};

} // namespace conversion
} // namespace style
} // namespace mbgl

namespace node_mbgl {

struct NodeMap::RenderOptions {
    double zoom = 0;
    double bearing = 0;
    mbgl::style::Light light;
    double pitch = 0;
    double latitude = 0;
    double longitude = 0;
    mbgl::Size size = {512, 512};
    bool axonometric = false;
    double xSkew = 0;
    double ySkew = 1;
    std::vector<std::string> classes;
    mbgl::MapDebugOptions debugOptions = mbgl::MapDebugOptions::NoDebug;
};

Napi::FunctionReference NodeMap::constructor;
Napi::ObjectReference NodeMap::parseError;

static const char* releasedMessage() {
    return "Map resources have already been released";
}

void NodeMapObserver::onDidFailLoadingMap(mbgl::MapLoadError error, const std::string& description) {
    // In newer versions of node-addon-api, we can't get Env this way
    // We need to handle this differently
    std::cerr << "Map load error: " << description << std::endl;
    // We can't throw JS errors from a native callback without access to the JS env
}

void NodeMap::Init(Napi::Object target) {
    Napi::Env env = target.Env();
    
    // Define a custom error class for parse errors
    Napi::String jsCode = Napi::String::New(env, R"JS(
class ParseError extends Error {
  constructor(...params) {
    super(...params);
    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, ParseError);
    }
  }
}
ParseError)JS");
    
    Napi::Function evalFn = env.Global().Get("eval").As<Napi::Function>();
    Napi::Value result = evalFn.Call(env.Global(), {jsCode});
    parseError = Napi::ObjectReference::New(result.As<Napi::Object>(), 1);
    
    target.Set("ParseError", parseError.Value());

    // Define the Map class
    Napi::Function func = DefineClass(env, "Map", {
        InstanceMethod<&NodeMap::Load>("load"),
        InstanceMethod<&NodeMap::Loaded>("loaded"),
        InstanceMethod<&NodeMap::Render>("render"),
        InstanceMethod<&NodeMap::Release>("release"),
        InstanceMethod<&NodeMap::Cancel>("cancel"),
        InstanceMethod<&NodeMap::AddSource>("addSource"),
        InstanceMethod<&NodeMap::RemoveSource>("removeSource"),
        InstanceMethod<&NodeMap::AddLayer>("addLayer"),
        InstanceMethod<&NodeMap::RemoveLayer>("removeLayer"),
        InstanceMethod<&NodeMap::AddImage>("addImage"),
        InstanceMethod<&NodeMap::RemoveImage>("removeImage"),
        InstanceMethod<&NodeMap::SetLayerZoomRange>("setLayerZoomRange"),
        InstanceMethod<&NodeMap::SetLayerProperty>("setLayoutProperty"),
        InstanceMethod<&NodeMap::SetLayerProperty>("setPaintProperty"),
        InstanceMethod<&NodeMap::SetFilter>("setFilter"),
        InstanceMethod<&NodeMap::SetSize>("setSize"),
        InstanceMethod<&NodeMap::SetCenter>("setCenter"),
        InstanceMethod<&NodeMap::SetZoom>("setZoom"),
        InstanceMethod<&NodeMap::SetBearing>("setBearing"),
        InstanceMethod<&NodeMap::SetPitch>("setPitch"),
        InstanceMethod<&NodeMap::SetLight>("setLight"),
        InstanceMethod<&NodeMap::SetAxonometric>("setAxonometric"),
        InstanceMethod<&NodeMap::SetXSkew>("setXSkew"),
        InstanceMethod<&NodeMap::SetYSkew>("setYSkew"),
        InstanceMethod<&NodeMap::SetFeatureState>("setFeatureState"),
        InstanceMethod<&NodeMap::GetFeatureState>("getFeatureState"),
        InstanceMethod<&NodeMap::RemoveFeatureState>("removeFeatureState"),
        
        InstanceMethod<&NodeMap::DumpDebugLogs>("dumpDebugLogs"),
        InstanceMethod<&NodeMap::QueryRenderedFeatures>("queryRenderedFeatures")
    });

    constructor = Napi::Persistent(func);
    target.Set("Map", func);
}

/**
 * A request object, given to the `request` handler of a map, is an
 * encapsulation of a URL and type of a resource that the map asks you to load.
 *
 * The `kind` property is one of
 *
 *     "Unknown": 0,
 *     "Style": 1,
 *     "Source": 2,
 *     "Tile": 3,
 *     "Glyphs": 4,
 *     "SpriteImage": 5,
 *     "SpriteJSON": 6
 *
 * @typedef
 * @name Request
 * @property {string} url
 * @property {number} kind
 */

/**
 * Mapbox GL object: this object loads stylesheets and renders them into
 * images.
 *
 * @class
 * @name Map
 * @param {Object} options
 * @param {Function} options.request a method used to request resources
 * over the internet
 * @param {Function} [options.cancel]
 * @param {number} options.ratio pixel ratio
 * @example
 * var map = new mbgl.Map({ request: function() {} });
 * map.load(require('./test/fixtures/style.json'));
 * map.render({}, function(err, image) {
 *     if (err) throw err;
 *     fs.writeFileSync('image.png', image);
 * });
 */
Napi::Value NodeMap::New(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    if (!info.IsConstructCall()) {
        napi_utils::throwError(env, "Use the new operator to create new Map objects");
        return env.Null();
    }

    if (info.Length() > 0 && !info[0].IsObject()) {
        napi_utils::throwError(env, "Requires an options object as first argument");
        return env.Null();
    }

    Napi::Object options;

    if (info.Length() > 0) {
        options = info[0].As<Napi::Object>();
    } else {
        options = Napi::Object::New(env);
    }

    // Check that if 'request' is set it must be a function, if 'cancel' is set
    // it must be a function and if 'ratio' is set it must be a number.
    if (options.Has("request") && !options.Get("request").IsFunction()) {
        napi_utils::throwError(env, "Options object 'request' property must be a function");
        return env.Null();
    }

    if (options.Has("cancel") && !options.Get("cancel").IsFunction()) {
        napi_utils::throwError(env, "Options object 'cancel' property must be a function");
        return env.Null();
    }

    if (options.Has("ratio") && !options.Get("ratio").IsNumber()) {
        napi_utils::throwError(env, "Options object 'ratio' property must be a number");
        return env.Null();
    }

    try {
        auto nodeMap = NodeMap::New(info);
        
        if (options.Has("request") && options.Get("request").IsFunction()) {
            mbgl::FileSourceManager::get()->registerFileSourceFactory(
                mbgl::FileSourceType::ResourceLoader,
                [](const mbgl::ResourceOptions& resourceOptions, const mbgl::ClientOptions&) {
                    return std::make_unique<node_mbgl::NodeFileSource>(
                        reinterpret_cast<node_mbgl::NodeMap*>(resourceOptions.platformContext()));
                });
        }
    } catch (std::exception& ex) {
        napi_utils::throwError(env, ex.what());
        return env.Null();
    }

    return info.This();
}

/**
 * Load a stylesheet
 *
 * @function
 * @name load
 * @param {string|Object} stylesheet either an object or a JSON representation
 * @param {Object} options
 * @param {boolean} options.defaultStyleCamera if true, sets the default style
 * camera
 * @returns {undefined} loads stylesheet into map
 * @throws {Error} if stylesheet is missing or invalid
 * @example
 * // providing an object
 * map.load(require('./test/fixtures/style.json'));
 *
 * // providing a string
 * map.load(fs.readFileSync('./test/fixtures/style.json', 'utf8'));
 */
Napi::Value NodeMap::Load(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    auto nodeMap = this;
    
    if (!nodeMap->map) {
        napi_utils::throwError(env, releasedMessage());
        return env.Null();
    }

    // Reset the flag as this could be the second time
    // we are calling this (being the previous successful).
    nodeMap->loaded = false;

    if (info.Length() < 1) {
        napi_utils::throwError(env, "Requires a map style as first argument");
        return env.Null();
    }

    std::string style;

    if (info[0].IsObject()) {
        Napi::Object obj = info[0].As<Napi::Object>();
        Napi::Function stringify = env.Global().Get("JSON").As<Napi::Object>().Get("stringify").As<Napi::Function>();
        style = stringify.Call({obj}).As<Napi::String>().Utf8Value();
    } else if (info[0].IsString()) {
        style = info[0].As<Napi::String>().Utf8Value();
    } else {
        napi_utils::throwError(env, "First argument must be a string or object");
        return env.Null();
    }

    try {
        nodeMap->map->getStyle().loadJSON(style);
    } catch (const mbgl::util::StyleParseException& ex) {
        napi_utils::throwError(env, ParseError(env, ex.what()).As<Napi::Error>().Message());
        return env.Null();
    } catch (const std::exception& ex) {
        napi_utils::throwError(env, ex.what());
        return env.Null();
    }

    if (info.Length() == 2) {
        if (!info[1].IsObject()) {
            napi_utils::throwError(env, "Second argument must be an options object");
            return env.Null();
        }
        Napi::Object options = info[1].As<Napi::Object>();
        if (options.Has("defaultStyleCamera")) {
            if (!options.Get("defaultStyleCamera").IsBoolean()) {
                napi_utils::throwError(env, "Options object 'defaultStyleCamera' property must be a boolean");
                return env.Null();
            }
            if (options.Has("cameraMutated") && options.Get("cameraMutated").ToBoolean().Value()) {
                nodeMap->map->jumpTo(nodeMap->map->getStyle().getDefaultCamera());
            }
        }
    }

    nodeMap->loaded = true;

    return env.Undefined();
}

Napi::Value NodeMap::Loaded(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    auto nodeMap = this;
    
    if (!nodeMap->map) {
        napi_utils::throwError(env, releasedMessage());
        return env.Null();
    }

    bool loaded = false;

    try {
        loaded = nodeMap->map->isFullyLoaded();
    } catch (const std::exception& ex) {
        napi_utils::throwError(env, ex.what());
        return env.Null();
    }

    return Napi::Boolean::New(env, loaded);
}

NodeMap::RenderOptions NodeMap::ParseOptions(const Napi::Object& obj) {
    Napi::Env env = obj.Env();
    NodeMap::RenderOptions options;

    if (obj.Has("zoom")) {
        options.zoom = obj.Get("zoom").As<Napi::Number>().DoubleValue();
    }

    if (obj.Has("bearing")) {
        options.bearing = obj.Get("bearing").As<Napi::Number>().DoubleValue();
    }

    if (obj.Has("pitch")) {
        options.pitch = obj.Get("pitch").As<Napi::Number>().DoubleValue();
    }

    if (obj.Has("light")) {
        Napi::Value lightObj = obj.Get("light");
        mbgl::style::conversion::Error conversionError;
        // 使用mbgl::style::conversion命名空间中的wrapNapiValue函数
        if (auto light = mbgl::style::conversion::convert<mbgl::style::Light>(mbgl::style::conversion::wrapNapiValue(lightObj), conversionError)) {
            options.light = *light;
        } else {
            throw std::move(conversionError);
        }
    }

    if (obj.Has("axonometric")) {
        options.axonometric = obj.Get("axonometric").As<Napi::Boolean>().Value();
    }

    if (obj.Has("skew")) {
        Napi::Value skewObj = obj.Get("skew");
        if (skewObj.IsArray()) {
            Napi::Array skew = skewObj.As<Napi::Array>();
            if (skew.Length() > 0) {
                options.xSkew = skew.Get(0u).As<Napi::Number>().DoubleValue();
            }
            if (skew.Length() > 1) {
                options.ySkew = skew.Get(1u).As<Napi::Number>().DoubleValue();
            }
        }
    }

    if (obj.Has("center")) {
        Napi::Value centerObj = obj.Get("center");
        if (centerObj.IsArray()) {
            Napi::Array center = centerObj.As<Napi::Array>();
            if (center.Length() > 0) {
                options.longitude = center.Get(0u).As<Napi::Number>().DoubleValue();
            }
            if (center.Length() > 1) {
                options.latitude = center.Get(1u).As<Napi::Number>().DoubleValue();
            }
        }
    }

    if (obj.Has("width")) {
        options.size.width = static_cast<uint32_t>(obj.Get("width").As<Napi::Number>().Int64Value());
    }

    if (obj.Has("height")) {
        options.size.height = static_cast<uint32_t>(obj.Get("height").As<Napi::Number>().Int64Value());
    }

    if (obj.Has("classes")) {
        Napi::Value classesValue = obj.Get("classes");
        if (classesValue.IsArray()) {
            Napi::Array classes = classesValue.As<Napi::Array>();
            uint32_t length = classes.Length();
            options.classes.reserve(length);
            for (uint32_t i = 0; i < length; i++) {
                options.classes.emplace_back(classes.Get(i).As<Napi::String>().Utf8Value());
            }
        }
    }

    if (obj.Has("debug")) {
        Napi::Value debugValue = obj.Get("debug");
        if (debugValue.IsObject()) {
            Napi::Object debug = debugValue.As<Napi::Object>();
            if (debug.Has("tileBorders")) {
                if (debug.Get("tileBorders").As<Napi::Boolean>().Value()) {
                    options.debugOptions = options.debugOptions | mbgl::MapDebugOptions::TileBorders;
                }
            }
            if (debug.Has("parseStatus")) {
                if (debug.Get("parseStatus").As<Napi::Boolean>().Value()) {
                    options.debugOptions = options.debugOptions | mbgl::MapDebugOptions::ParseStatus;
                }
            }
            if (debug.Has("timestamps")) {
                if (debug.Get("timestamps").As<Napi::Boolean>().Value()) {
                    options.debugOptions = options.debugOptions | mbgl::MapDebugOptions::Timestamps;
                }
            }
            if (debug.Has("collision")) {
                if (debug.Get("collision").As<Napi::Boolean>().Value()) {
                    options.debugOptions = options.debugOptions | mbgl::MapDebugOptions::Collision;
                }
            }
            if (debug.Has("overdraw")) {
                if (debug.Get("overdraw").As<Napi::Boolean>().Value()) {
                    options.debugOptions = mbgl::MapDebugOptions::Overdraw;
                }
            }
        }
    }

    return options;
}

class RenderRequest {
public:
    explicit RenderRequest(const Napi::Function& callback_)
        : callback(Napi::Persistent(callback_)) {}
    ~RenderRequest() = default;

    Napi::FunctionReference callback;
};

/**
 * Render an image from the currently-loaded style
 *
 * @name render
 * @param {Object} options
 * @param {number} [options.zoom=0]
 * @param {number} [options.width=512]
 * @param {number} [options.height=512]
 * @param {Array<number>} [options.center=[0,0]] longitude, latitude center
 * of the map
 * @param {number} [options.bearing=0] rotation
 * @param {Array<string>} [options.classes=[]] style classes
 * @param {Function} callback
 * @returns {undefined} calls callback
 * @throws {Error} if stylesheet is not loaded or if map is already rendering
 */
Napi::Value NodeMap::Render(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    auto nodeMap = this;
    
    if (!nodeMap->map) {
        napi_utils::throwError(env, releasedMessage());
        return env.Null();
    }

    if (info.Length() <= 0 || (!info[0].IsObject() && !info[0].IsFunction())) {
        napi_utils::throwError(env, "First argument must be an options object or a callback function");
        return env.Null();
    }

    if ((info.Length() <= 1 && !info[0].IsFunction()) || (info.Length() > 1 && !info[1].IsFunction())) {
        napi_utils::throwError(env, "Second argument must be a callback function");
        return env.Null();
    }

    if (!nodeMap->loaded) {
        napi_utils::throwError(env, "Style is not loaded");
        return env.Null();
    }

    if (nodeMap->req) {
        napi_utils::throwError(env, "Map is currently processing a RenderRequest");
        return env.Null();
    }

    try {
        if (info[0].IsFunction()) {
            assert(!nodeMap->req);
            assert(!nodeMap->image.data);
            nodeMap->req = std::make_unique<RenderRequest>(info[0].As<Napi::Function>());

            nodeMap->startRender();
        } else {
            Napi::Object optionsObj = info[0].As<Napi::Object>();
            auto options = ParseOptions(optionsObj);
            assert(!nodeMap->req);
            assert(!nodeMap->image.data);
            nodeMap->req = std::make_unique<RenderRequest>(info[1].As<Napi::Function>());

            nodeMap->startRender(options);
        }
    } catch (const mbgl::style::conversion::Error& err) {
        napi_utils::throwError(env, err.message.c_str());
        return env.Null();
    } catch (const mbgl::util::StyleParseException& ex) {
        napi_utils::throwError(env, ParseError(env, ex.what()).As<Napi::Error>().Message());
        return env.Null();
    } catch (const mbgl::util::Exception& ex) {
        napi_utils::throwError(env, ex.what());
        return env.Null();
    }

    return env.Undefined();
}

void NodeMap::startRender() {
    map->renderStill([this](const std::exception_ptr& eptr) {
        if (eptr) {
            error = eptr;
            uv_async_send(async);
        } else {
            assert(!image.data);
            image = frontend->readStillImage();
            uv_async_send(async);
        }
    });

    // Retain this object, otherwise it might get destructed before we are
    // finished rendering the still image.
    this->ref();

    // Similarly, we're now waiting for the async to be called, so we need to
    // make sure that it keeps the loop alive.
    uv_ref(reinterpret_cast<uv_handle_t*>(async));
}

void NodeMap::startRender(const NodeMap::RenderOptions& options) {
    frontend->setSize(options.size);
    map->setSize(options.size);

    mbgl::CameraOptions camera;
    camera.center = mbgl::LatLng{options.latitude, options.longitude};
    camera.zoom = options.zoom;
    camera.bearing = options.bearing;
    camera.pitch = options.pitch;

    auto projectionOptions =
        mbgl::ProjectionMode().withAxonometric(options.axonometric).withXSkew(options.xSkew).withYSkew(options.ySkew);

    map->setProjectionMode(projectionOptions);

    map->renderStill(camera, options.debugOptions, [this](const std::exception_ptr& eptr) {
        if (eptr) {
            error = eptr;
            uv_async_send(async);
        } else {
            assert(!image.data);
            image = frontend->readStillImage();
            uv_async_send(async);
        }
    });

    // Retain this object, otherwise it might get destructed before we are
    // finished rendering the still image.
    this->ref();

    // Similarly, we're now waiting for the async to be called, so we need to
    // make sure that it keeps the loop alive.
    uv_ref(reinterpret_cast<uv_handle_t*>(async));
}

Napi::Value NodeMap::ParseError(const Napi::Env& env, const char* msg) {
    Napi::Error error = Napi::Error::New(env, msg);
    error.Value().Set("name", Napi::String::New(env, "ParseError"));
    return error.Value();
}

void NodeMap::renderFinished() {
    assert(req);

    // We're done with this render call, so we're unrefing so that the loop could close.
    uv_unref(reinterpret_cast<uv_handle_t*>(async));

    // Move the callback and image out of the way so that the callback can start a new render call.
    auto request = std::move(req);
    auto img = std::move(image);
    assert(request);

    // These have to be empty to be prepared for the next render call.
    assert(!req);
    assert(!image.data);

    Napi::Function callback = request->callback.Value();
    Napi::Object target = Napi::Object::New(callback.Env());

    if (error) {
        Napi::Value err;

        try {
            std::rethrow_exception(error);
            assert(false);
        } catch (const mbgl::util::StyleParseException& ex) {
            err = ParseError(callback.Env(), ex.what());
        } catch (const std::exception& ex) {
            err = Napi::Error::New(callback.Env(), ex.what()).Value();
        }

        napi_value argv[] = {err};

        // This must be empty to be prepared for the next render call.
        error = nullptr;
        assert(!error);

        callback.MakeCallback(target, 1, argv);
    } else if (img.data) {
        Napi::Object pixels = Napi::Buffer<uint8_t>::New(
                                callback.Env(),
                                img.data.get(),
                                img.bytes(),
                                // Retain the data until the buffer is deleted.
                                [](Napi::Env, void* data, void* hint) {
                                    delete[] reinterpret_cast<uint8_t*>(hint);
                                },
                                img.data.get());
        if (!pixels.IsEmpty()) {
            img.data.release();
        }

        napi_value argv[] = {callback.Env().Null(), pixels};
        callback.MakeCallback(target, 2, argv);
    } else {
        napi_value argv[] = {Napi::Error::New(callback.Env(), "Didn't get an image").Value()};
        callback.MakeCallback(target, 1, argv);
    }

    // There is no render pending anymore, we the GC could now delete this
    // object if it went out of scope.
    this->unref();
}

// 由于当前版本的node-addon-api在继承链中存在问题，
// 我们暂时实现一个空的ref()和unref()方法
void NodeMap::ref() {
  // 空实现，因为当前版本的API存在问题
}

void NodeMap::unref() {
  // 空实现，因为当前版本的API存在问题
}

/**
 * Clean up any resources used by a map instance.options
 * @name release
 * @returns {undefined}
 */
Napi::Value NodeMap::Release(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    auto nodeMap = this;
    
    if (!nodeMap->map) {
        napi_utils::throwError(env, releasedMessage());
        return env.Null();
    }

    try {
        nodeMap->release();
    } catch (const std::exception& ex) {
        napi_utils::throwError(env, ex.what());
        return env.Null();
    }

    return env.Undefined();
}

void NodeMap::release() {
    if (!map) throw mbgl::util::Exception(releasedMessage());

    uv_close(reinterpret_cast<uv_handle_t*>(async), [](uv_handle_t* h) { delete reinterpret_cast<uv_async_t*>(h); });

    map.reset();
    frontend.reset();
}

/**
 * Cancel an ongoing render request. The callback will be called with
 * the error set to "Canceled". Will throw if no rendering is in progress.
 * @name cancel
 * @returns {undefined}
 */
Napi::Value NodeMap::Cancel(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    auto nodeMap = this;

    if (!nodeMap->map) {
        napi_utils::throwError(env, releasedMessage());
        return env.Null();
    }
    if (!nodeMap->req) {
        napi_utils::throwError(env, "No render in progress");
        return env.Null();
    }

    try {
        nodeMap->cancel();
    } catch (const std::exception& ex) {
        napi_utils::throwError(env, ex.what());
        return env.Null();
    }

    return env.Undefined();
}

void NodeMap::cancel() {
    auto style = map->getStyle().getJSON();

    // Reset map explicitly as it resets the renderer frontend
    map.reset();

    // Remove the existing async handle to flush any scheduled calls to renderFinished.
    uv_unref(reinterpret_cast<uv_handle_t*>(async));
    uv_close(reinterpret_cast<uv_handle_t*>(async), [](uv_handle_t* h) { delete reinterpret_cast<uv_async_t*>(h); });
    async = new uv_async_t;
    async->data = this;
    uv_async_init(
        uv_default_loop(), async, [](uv_async_t* h) { reinterpret_cast<NodeMap*>(h->data)->renderFinished(); });

    frontend = std::make_unique<mbgl::HeadlessFrontend>(mbgl::Size{512, 512}, pixelRatio);
    map = std::make_unique<mbgl::Map>(*frontend,
                                      mapObserver,
                                      mbgl::MapOptions()
                                          .withSize(frontend->getSize())
                                          .withPixelRatio(pixelRatio)
                                          .withMapMode(mode)
                                          .withCrossSourceCollisions(crossSourceCollisions),
                                      mbgl::ResourceOptions().withPlatformContext(reinterpret_cast<void*>(this)),
                                      mbgl::ClientOptions());

    // FIXME: Reload the style after recreating the map. We need to find
    // a better way of canceling an ongoing rendering on the core level
    // without resetting the map, which is way too expensive.
    map->getStyle().loadJSON(style);

    error = std::make_exception_ptr(std::runtime_error("Canceled"));
    renderFinished();
}

Napi::Value NodeMap::AddSource(const Napi::CallbackInfo& info) {
    using namespace mbgl::style;
    using namespace mbgl::style::conversion;

    Napi::Env env = info.Env();
    auto nodeMap = this;
    if (!nodeMap->map) {
        napi_utils::throwError(env, releasedMessage());
        return env.Null();
    }

    if (info.Length() != 2) {
        napi_utils::throwError(env, "Two argument required");
        return env.Null();
    }

    if (!info[0].IsString()) {
        napi_utils::throwError(env, "First argument must be a string");
        return env.Null();
    }

    if (!info[1].IsObject()) {
        napi_utils::throwError(env, "Second argument must be an object");
        return env.Null();
    }

    Error error;
    std::optional<std::unique_ptr<Source>> source = convert<std::unique_ptr<Source>>(wrapNapiValue(info[1].As<Napi::Object>()), error, info[0].As<Napi::String>().Utf8Value());
    if (!source) {
        napi_utils::throwError(env, error.message.c_str());
        return env.Null();
    }

    nodeMap->map->getStyle().addSource(std::move(*source));
    return env.Undefined();
}

Napi::Value NodeMap::RemoveSource(const Napi::CallbackInfo& info) {
    using namespace mbgl::style;
    using namespace mbgl::style::conversion;

    Napi::Env env = info.Env();
    auto nodeMap = this;
    if (!nodeMap->map) {
        napi_utils::throwError(env, releasedMessage());
        return env.Null();
    }

    if (info.Length() != 1) {
        napi_utils::throwError(env, "One argument required");
        return env.Null();
    }

    if (!info[0].IsString()) {
        napi_utils::throwError(env, "First argument must be a string");
        return env.Null();
    }

    nodeMap->map->getStyle().removeSource(info[0].As<Napi::String>().Utf8Value());
    return env.Undefined();
}

Napi::Value NodeMap::AddLayer(const Napi::CallbackInfo& info) {
    using namespace mbgl::style;
    using namespace mbgl::style::conversion;

    Napi::Env env = info.Env();
    auto nodeMap = this;
    if (!nodeMap->map) {
        napi_utils::throwError(env, releasedMessage());
        return env.Null();
    }

    if (info.Length() != 1) {
        napi_utils::throwError(env, "One argument required");
        return env.Null();
    }

    Error error;
    std::optional<std::unique_ptr<Layer>> layer = mbgl::style::conversion::convert<std::unique_ptr<Layer>>(wrapNapiValue(info[0]), error);
    if (!layer) {
        napi_utils::throwError(env, error.message.c_str());
        return env.Null();
    }

    nodeMap->map->getStyle().addLayer(std::move(*layer));
    return env.Undefined();
}

Napi::Value NodeMap::RemoveLayer(const Napi::CallbackInfo& info) {
    using namespace mbgl::style;
    using namespace mbgl::style::conversion;

    Napi::Env env = info.Env();
    auto nodeMap = this;
    if (!nodeMap->map) {
        napi_utils::throwError(env, releasedMessage());
        return env.Null();
    }

    if (info.Length() != 1) {
        napi_utils::throwError(env, "One argument required");
        return env.Null();
    }

    if (!info[0].IsString()) {
        napi_utils::throwError(env, "First argument must be a string");
        return env.Null();
    }

    nodeMap->map->getStyle().removeLayer(info[0].As<Napi::String>().Utf8Value());
    return env.Undefined();
}

Napi::Value NodeMap::AddImage(const Napi::CallbackInfo& info) {
    using namespace mbgl::style;
    using namespace mbgl::style::conversion;

    Napi::Env env = info.Env();
    auto nodeMap = this;
    if (!nodeMap->map) {
        napi_utils::throwError(env, releasedMessage());
        return env.Null();
    }

    if (info.Length() != 3) {
        napi_utils::throwError(env, "Three arguments required");
        return env.Null();
    }

    if (!info[0].IsString()) {
        napi_utils::throwError(env, "First argument must be a string");
        return env.Null();
    }

    if (!info[1].IsObject()) {
        napi_utils::throwError(env, "Second argument must be an object");
        return env.Null();
    }

    if (!info[2].IsObject()) {
        napi_utils::throwError(env, "Third argument must be an object");
        return env.Null();
    }

    Napi::Object optionObject = info[2].As<Napi::Object>();

    if (!optionObject.Has("height") || !optionObject.Get("height").IsNumber()) {
        napi_utils::throwError(env, "height parameter required");
        return env.Null();
    }

    if (!optionObject.Has("width") || !optionObject.Get("width").IsNumber()) {
        napi_utils::throwError(env, "width parameter required");
        return env.Null();
    }

    if (!optionObject.Has("pixelRatio") || !optionObject.Get("pixelRatio").IsNumber()) {
        napi_utils::throwError(env, "pixelRatio parameter required");
        return env.Null();
    }

    uint32_t imageHeight =
        optionObject.Get("height").ToNumber().Uint32Value();
    uint32_t imageWidth =
        optionObject.Get("width").ToNumber().Uint32Value();

    if (imageWidth > 1024 || imageHeight > 1024) {
        napi_utils::throwError(env, "Max height and width is 1024");
        return env.Null();
    }

    bool sdf = false;
    if (optionObject.Has("sdf") && optionObject.Get("sdf").IsBoolean()) {
        sdf = optionObject.Get("sdf").ToBoolean().Value();
    }

    float pixelRatio = optionObject.Get("pixelRatio").ToNumber().FloatValue();
    Napi::Object imageBuffer = info[1].As<Napi::Object>();

    // 转换为Napi::Buffer
    napi_status status;
    uint8_t* imageDataBuffer;
    size_t imageLength;
    status = napi_get_buffer_info(env, imageBuffer, reinterpret_cast<void**>(&imageDataBuffer), &imageLength);
    if (status != napi_ok) {
        napi_utils::throwError(env, "Failed to get buffer info");
        return env.Null();
    }

    if (imageLength != imageHeight * imageWidth * 4) {
        napi_utils::throwError(env, "Image size does not match buffer size");
        return env.Null();
    }

    std::unique_ptr<uint8_t[]> data = std::make_unique<uint8_t[]>(imageLength);
    std::copy(imageDataBuffer, imageDataBuffer + imageLength, data.get());

    mbgl::UnassociatedImage cImage({imageWidth, imageHeight}, std::move(data));
    mbgl::PremultipliedImage cPremultipliedImage = mbgl::util::premultiply(std::move(cImage));
    nodeMap->map->getStyle().addImage(std::make_unique<mbgl::style::Image>(
        info[0].As<Napi::String>().Utf8Value(), std::move(cPremultipliedImage), pixelRatio, sdf));

    return env.Undefined();
}

Napi::Value NodeMap::RemoveImage(const Napi::CallbackInfo& info) {
    using namespace mbgl::style;
    using namespace mbgl::style::conversion;

    Napi::Env env = info.Env();
    auto nodeMap = this;
    if (!nodeMap->map) {
        napi_utils::throwError(env, releasedMessage());
        return env.Null();
    }

    if (info.Length() != 1) {
        napi_utils::throwError(env, "One argument required");
        return env.Null();
    }

    if (!info[0].IsString()) {
        napi_utils::throwError(env, "First argument must be a string");
        return env.Null();
    }

    nodeMap->map->getStyle().removeImage(info[0].As<Napi::String>().Utf8Value());
    return env.Undefined();
}

Napi::Value NodeMap::SetLayerZoomRange(const Napi::CallbackInfo& info) {
    using namespace mbgl::style;

    Napi::Env env = info.Env();
    auto nodeMap = this;
    if (!nodeMap->map) {
        napi_utils::throwError(env, releasedMessage());
        return env.Null();
    }

    if (info.Length() != 3) {
        napi_utils::throwError(env, "Three arguments required");
        return env.Null();
    }

    if (!info[0].IsString()) {
        napi_utils::throwError(env, "First argument must be a string");
        return env.Null();
    }

    if (!info[1].IsNumber() || !info[2].IsNumber()) {
        napi_utils::throwError(env, "Second and third arguments must be numbers");
        return env.Null();
    }

    mbgl::style::Layer* layer = nodeMap->map->getStyle().getLayer(info[0].As<Napi::String>().Utf8Value());
    if (!layer) {
        napi_utils::throwError(env, "layer not found");
        return env.Null();
    }

    layer->setMinZoom(static_cast<float>(info[1].As<Napi::Number>().FloatValue()));
    layer->setMaxZoom(static_cast<float>(info[2].As<Napi::Number>().FloatValue()));
    return env.Undefined();
}

Napi::Value NodeMap::SetLayerProperty(const Napi::CallbackInfo& info) {
    using namespace mbgl::style;
    using namespace mbgl::style::conversion;

    Napi::Env env = info.Env();
    auto nodeMap = this;
    if (!nodeMap->map) {
        napi_utils::throwError(env, releasedMessage());
        return env.Null();
    }

    if (info.Length() < 3) {
        napi_utils::throwError(env, "Three arguments required");
        return env.Null();
    }

    if (!info[0].IsString()) {
        napi_utils::throwError(env, "First argument must be a string");
        return env.Null();
    }

    mbgl::style::Layer* layer = nodeMap->map->getStyle().getLayer(info[0].As<Napi::String>().Utf8Value());
    if (!layer) {
        napi_utils::throwError(env, "layer not found");
        return env.Null();
    }

    if (!info[1].IsString()) {
        napi_utils::throwError(env, "Second argument must be a string");
        return env.Null();
    }

    std::optional<Error> error = layer->setProperty(info[1].As<Napi::String>().Utf8Value(), Convertible(wrapNapiValue(info[2])));
    if (error) {
        napi_utils::throwError(env, error->message.c_str());
        return env.Null();
    }

    return env.Undefined();
}

Napi::Value NodeMap::SetFilter(const Napi::CallbackInfo& info) {
    using namespace mbgl::style;
    using namespace mbgl::style::conversion;

    Napi::Env env = info.Env();
    auto nodeMap = this;
    if (!nodeMap->map) {
        napi_utils::throwError(env, releasedMessage());
        return env.Null();
    }

    if (info.Length() < 2) {
        napi_utils::throwError(env, "Two arguments required");
        return env.Null();
    }

    if (!info[0].IsString()) {
        napi_utils::throwError(env, "First argument must be a string");
        return env.Null();
    }

    mbgl::style::Layer* layer = nodeMap->map->getStyle().getLayer(info[0].As<Napi::String>().Utf8Value());
    if (!layer) {
        napi_utils::throwError(env, "layer not found");
        return env.Null();
    }

    Filter filter;

    if (!info[1].IsNull() && !info[1].IsUndefined()) {
        Error error;
        std::optional<Filter> converted = mbgl::style::conversion::convert<Filter>(wrapNapiValue(info[1]), error);
        if (!converted) {
            napi_utils::throwError(env, error.message.c_str());
            return env.Null();
        }
        filter = std::move(*converted);
    }

    layer->setFilter(filter);
    return env.Undefined();
}

Napi::Value NodeMap::SetSize(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    auto nodeMap = this;
    if (!nodeMap->map) {
        napi_utils::throwError(env, releasedMessage());
        return env.Null();
    }

    if (info.Length() <= 0 || !info[0].IsArray()) {
        napi_utils::throwError(env, "First argument must be an array");
        return env.Null();
    }

    Napi::Array size = info[0].As<Napi::Array>();
    uint32_t width = 0;
    uint32_t height = 0;
    if (size.Length() > 0) {
        width = size.Get(0u).ToNumber().Uint32Value();
    }
    if (size.Length() > 1) {
        height = size.Get(1u).ToNumber().Uint32Value();
    }

    try {
        nodeMap->frontend->setSize({width, height});
        nodeMap->map->setSize({width, height});
    } catch (const std::exception& ex) {
        napi_utils::throwError(env, ex.what());
        return env.Null();
    }

    return env.Undefined();
}

Napi::Value NodeMap::SetCenter(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    auto nodeMap = this;
    if (!nodeMap->map) {
        napi_utils::throwError(env, releasedMessage());
        return env.Null();
    }

    if (info.Length() <= 0 || !info[0].IsArray()) {
        napi_utils::throwError(env, "First argument must be an array");
        return env.Null();
    }

    Napi::Array center = info[0].As<Napi::Array>();
    double latitude = 0;
    double longitude = 0;
    if (center.Length() > 0) {
        longitude = center.Get(0u).ToNumber().DoubleValue();
    }
    if (center.Length() > 1) {
        latitude = center.Get(1u).ToNumber().DoubleValue();
    }

    try {
        nodeMap->map->jumpTo(mbgl::CameraOptions().withCenter(mbgl::LatLng{latitude, longitude}));
    } catch (const std::exception& ex) {
        napi_utils::throwError(env, ex.what());
        return env.Null();
    }

    return env.Undefined();
}

Napi::Value NodeMap::SetZoom(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    auto nodeMap = this;
    if (!nodeMap->map) {
        napi_utils::throwError(env, releasedMessage());
        return env.Null();
    }

    if (info.Length() <= 0 || !info[0].IsNumber()) {
        napi_utils::throwError(env, "First argument must be a number");
        return env.Null();
    }

    try {
        nodeMap->map->jumpTo(mbgl::CameraOptions().withZoom(info[0].As<Napi::Number>().DoubleValue()));
    } catch (const std::exception& ex) {
        napi_utils::throwError(env, ex.what());
        return env.Null();
    }

    return env.Undefined();
}

Napi::Value NodeMap::SetBearing(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    auto nodeMap = this;
    if (!nodeMap->map) {
        napi_utils::throwError(env, releasedMessage());
        return env.Null();
    }

    if (info.Length() <= 0 || !info[0].IsNumber()) {
        napi_utils::throwError(env, "First argument must be a number");
        return env.Null();
    }

    try {
        nodeMap->map->jumpTo(mbgl::CameraOptions().withBearing(info[0].As<Napi::Number>().DoubleValue()));
    } catch (const std::exception& ex) {
        napi_utils::throwError(env, ex.what());
        return env.Null();
    }

    return env.Undefined();
}

Napi::Value NodeMap::SetPitch(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    auto nodeMap = this;
    if (!nodeMap->map) {
        napi_utils::throwError(env, releasedMessage());
        return env.Null();
    }

    if (info.Length() <= 0 || !info[0].IsNumber()) {
        napi_utils::throwError(env, "First argument must be a number");
        return env.Null();
    }

    try {
        nodeMap->map->jumpTo(mbgl::CameraOptions().withPitch(info[0].As<Napi::Number>().DoubleValue()));
    } catch (const std::exception& ex) {
        napi_utils::throwError(env, ex.what());
        return env.Null();
    }

    return env.Undefined();
}

Napi::Value NodeMap::SetLight(const Napi::CallbackInfo& info) {
    using namespace mbgl::style;
    using namespace mbgl::style::conversion;

    Napi::Env env = info.Env();
    auto nodeMap = this;
    if (!nodeMap->map) {
        napi_utils::throwError(env, releasedMessage());
        return env.Null();
    }

    if (info.Length() <= 0 || !info[0].IsObject()) {
        napi_utils::throwError(env, "First argument must be an object");
        return env.Null();
    }

    try {
        Error conversionError;
        if (auto light = mbgl::style::conversion::convert<mbgl::style::Light>(wrapNapiValue(info[0]), conversionError)) {
            nodeMap->map->getStyle().setLight(std::make_unique<Light>(*light));
        } else {
            napi_utils::throwError(env, conversionError.message.c_str());
            return env.Null();
        }
    } catch (const std::exception& ex) {
        napi_utils::throwError(env, ex.what());
        return env.Null();
    }

    return env.Undefined();
}

Napi::Value NodeMap::SetAxonometric(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    auto nodeMap = this;
    if (!nodeMap->map) {
        napi_utils::throwError(env, releasedMessage());
        return env.Null();
    }

    if (info.Length() <= 0 || !info[0].IsBoolean()) {
        napi_utils::throwError(env, "First argument must be a boolean");
        return env.Null();
    }

    try {
        nodeMap->map->setProjectionMode(mbgl::ProjectionMode().withAxonometric(info[0].As<Napi::Boolean>().Value()));
    } catch (const std::exception& ex) {
        napi_utils::throwError(env, ex.what());
        return env.Null();
    }

    return env.Undefined();
}

Napi::Value NodeMap::SetXSkew(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    auto nodeMap = this;
    if (!nodeMap->map) {
        napi_utils::throwError(env, releasedMessage());
        return env.Null();
    }

    if (info.Length() <= 0 || !info[0].IsNumber()) {
        napi_utils::throwError(env, "First argument must be a number");
        return env.Null();
    }

    try {
        nodeMap->map->setProjectionMode(mbgl::ProjectionMode().withXSkew(info[0].As<Napi::Number>().DoubleValue()));
    } catch (const std::exception& ex) {
        napi_utils::throwError(env, ex.what());
        return env.Null();
    }

    return env.Undefined();
}

Napi::Value NodeMap::SetYSkew(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    auto nodeMap = this;
    if (!nodeMap->map) {
        napi_utils::throwError(env, releasedMessage());
        return env.Null();
    }

    if (info.Length() <= 0 || !info[0].IsNumber()) {
        napi_utils::throwError(env, "First argument must be a number");
        return env.Null();
    }

    try {
        nodeMap->map->setProjectionMode(mbgl::ProjectionMode().withYSkew(info[0].As<Napi::Number>().DoubleValue()));
    } catch (const std::exception& ex) {
        napi_utils::throwError(env, ex.what());
        return env.Null();
    }

    return env.Undefined();
}

Napi::Value NodeMap::SetFeatureState(const Napi::CallbackInfo& info) {
    using namespace mbgl;
    using namespace mbgl::style::conversion;

    Napi::Env env = info.Env();
    auto nodeMap = this;
    if (!nodeMap->map) {
        napi_utils::throwError(env, releasedMessage());
        return env.Null();
    }

    if (info.Length() < 2) {
        napi_utils::throwError(env, "Two arguments required");
        return env.Null();
    }

    if (!info[0].IsObject() || !info[1].IsObject()) {
        napi_utils::throwError(env, "Both arguments must be objects");
        return env.Null();
    }

    std::string sourceID;
    std::string featureID;
    std::optional<std::string> sourceLayerID;
    Napi::Object feature = info[0].As<Napi::Object>();
    if (feature.Has("source")) {
        Napi::Value sourceOption = feature.Get("source");
        if (!sourceOption.IsString()) {
            napi_utils::throwError(env, "Requires feature.source property to be a string");
            return env.Null();
        }
        sourceID = sourceOption.As<Napi::String>().Utf8Value();
    } else {
        napi_utils::throwError(env, "SetFeatureState: Requires feature.source property");
        return env.Null();
    }

    if (feature.Has("sourceLayer")) {
        Napi::Value sourceLayerOption = feature.Get("sourceLayer");
        if (!sourceLayerOption.IsString()) {
            napi_utils::throwError(env, 
                "SetFeatureState: Requires feature.sourceLayer property to be "
                "a string");
            return env.Null();
        }
        sourceLayerID = {sourceLayerOption.As<Napi::String>().Utf8Value()};
    }

    if (feature.Has("id")) {
        Napi::Value idOption = feature.Get("id");
        if (!idOption.IsString() && !idOption.IsNumber()) {
            napi_utils::throwError(env, "Requires feature.id property to be a string or a number");
            return env.Null();
        }
        if (idOption.IsString()) {
            featureID = idOption.As<Napi::String>().Utf8Value();
        } else {
            featureID = std::to_string(idOption.As<Napi::Number>().Int64Value());
        }
    } else {
        napi_utils::throwError(env, "SetFeatureState: Requires feature.id property");
        return env.Null();
    }

    Convertible state(wrapNapiValue(info[1]));

    if (!isObject(state)) {
        napi_utils::throwError(env, "Feature state must be an object");
        return env.Null();
    }

    std::string sourceLayer = sourceLayerID.value_or(std::string());
    std::string stateKey;
    Napi::Value stateValue;
    bool valueParsed = false;
    FeatureState newState;

    // 使用mbgl::style::expression::ValueConverter进行类型安全转换
    const std::function<std::optional<Error>(const std::string&, const Convertible&)> convertFn = 
        [&](const std::string& k, const Convertible& v) -> std::optional<Error> {
        mbgl::style::conversion::Error error;
        // 先转换为mbgl::style::expression::Value
        std::optional<mbgl::style::expression::Value> exprValueOpt = 
            mbgl::style::conversion::convert<mbgl::style::expression::Value>(v, error);
        if (exprValueOpt) {
            // 然后使用ValueConverter安全地转换为mbgl::Value
            mbgl::Value mbglValue = 
                mbgl::style::expression::ValueConverter<mbgl::Value>::fromExpressionValue(*exprValueOpt);
            stateKey = k;
            newState[stateKey] = mbglValue;
            return {};
        }
        return error;
    };

    eachMember(state, convertFn);

    try {
        nodeMap->frontend->getRenderer()->setFeatureState(sourceID, sourceLayerID, featureID, newState);
    } catch (const std::exception& ex) {
        napi_utils::throwError(env, ex.what());
        return env.Null();
    }

    return env.Undefined();
}

Napi::Value NodeMap::GetFeatureState(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    auto nodeMap = this;
    if (!nodeMap->map) {
        napi_utils::throwError(env, releasedMessage());
        return env.Null();
    }

    if (info.Length() < 1) {
        napi_utils::throwError(env, "One argument required");
        return env.Null();
    }

    if (!info[0].IsObject()) {
        napi_utils::throwError(env, "Argument must be object");
        return env.Null();
    }

    std::string sourceID;
    std::string featureID;
    std::optional<std::string> sourceLayerID;
    Napi::Object feature = info[0].As<Napi::Object>();
    if (feature.Has("source")) {
        Napi::Value sourceOption = feature.Get("source");
        if (!sourceOption.IsString()) {
            napi_utils::throwError(env, "Requires feature.source property to be a string");
            return env.Null();
        }
        sourceID = sourceOption.As<Napi::String>().Utf8Value();
    } else {
        napi_utils::throwError(env, "GetFeatureState: Requires feature.source property");
        return env.Null();
    }

    if (feature.Has("sourceLayer")) {
        Napi::Value sourceLayerOption = feature.Get("sourceLayer");
        if (!sourceLayerOption.IsString()) {
            napi_utils::throwError(env, 
                "GetFeatureState: Requires feature.sourceLayer property to be "
                "a string");
            return env.Null();
        }
        sourceLayerID = {sourceLayerOption.As<Napi::String>().Utf8Value()};
    }

    if (feature.Has("id")) {
        Napi::Value idOption = feature.Get("id");
        if (!idOption.IsString() && !idOption.IsNumber()) {
            napi_utils::throwError(env, "Requires feature.id property to be a string or a number");
            return env.Null();
        }
        if (idOption.IsString()) {
            featureID = idOption.As<Napi::String>().Utf8Value();
        } else {
            featureID = std::to_string(idOption.As<Napi::Number>().Int64Value());
        }
    } else {
        napi_utils::throwError(env, "GetFeatureState: Requires feature.id property");
        return env.Null();
    }

    mbgl::FeatureState state;
    try {
        nodeMap->frontend->getRenderer()->getFeatureState(state, sourceID, sourceLayerID, featureID);
    } catch (const std::exception& ex) {
        napi_utils::throwError(env, ex.what());
        return env.Null();
    }

    return env.Undefined();
}

Napi::Value NodeMap::RemoveFeatureState(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    auto nodeMap = this;
    if (!nodeMap->map) {
        napi_utils::throwError(env, releasedMessage());
        return env.Null();
    }

    if (info.Length() < 1) {
        napi_utils::throwError(env, "At least one argument required");
        return env.Null();
    }

    if (!info[0].IsObject()) {
        napi_utils::throwError(env, "Argument 1 must be object");
        return env.Null();
    }

    if (info.Length() == 2 && !info[1].IsString()) {
        napi_utils::throwError(env, "argument 2 must be string");
        return env.Null();
    }

    std::string sourceID;
    std::optional<std::string> sourceLayerID;
    std::optional<std::string> featureID;
    std::optional<std::string> stateKey;
    Napi::Object feature = info[0].As<Napi::Object>();
    if (feature.Has("source")) {
        Napi::Value sourceOption = feature.Get("source");
        if (!sourceOption.IsString()) {
            napi_utils::throwError(env, "Requires feature.source property to be a string");
            return env.Null();
        }
        sourceID = sourceOption.As<Napi::String>().Utf8Value();
    } else {
        napi_utils::throwError(env, "RemoveFeatureState: Requires feature.source property");
        return env.Null();
    }

    if (feature.Has("sourceLayer")) {
        Napi::Value sourceLayerOption = feature.Get("sourceLayer");
        if (!sourceLayerOption.IsString()) {
            napi_utils::throwError(env, 
                "RemoveFeatureState: Requires feature.sourceLayer property to "
                "be a string");
            return env.Null();
        }
        sourceLayerID = {sourceLayerOption.As<Napi::String>().Utf8Value()};
    }

    if (feature.Has("id")) {
        Napi::Value idOption = feature.Get("id");
        if (!idOption.IsString() && !idOption.IsNumber()) {
            napi_utils::throwError(env, "Requires feature.id property to be a string or a number");
            return env.Null();
        }
        if (idOption.IsString()) {
            featureID = {idOption.As<Napi::String>().Utf8Value()};
        } else {
            featureID = {std::to_string(idOption.As<Napi::Number>().Int64Value())};
        }
    }

    if (info.Length() == 2) {
        Napi::String keyParam = info[1].As<Napi::String>();
        stateKey = {keyParam.Utf8Value()};
    }

    try {
        nodeMap->frontend->getRenderer()->removeFeatureState(sourceID, sourceLayerID, featureID, stateKey);
    } catch (const std::exception& ex) {
        napi_utils::throwError(env, ex.what());
        return env.Null();
    }

    return env.Undefined();
}

Napi::Value NodeMap::DumpDebugLogs(const Napi::CallbackInfo& info) {
    auto nodeMap = this;
    if (!nodeMap->map) {
        napi_utils::throwError(info.Env(), releasedMessage());
        return info.Env().Undefined();
    }

    nodeMap->map->dumpDebugLogs();
    nodeMap->frontend->getRenderer()->dumpDebugLogs();

    return info.Env().Undefined();
}

Napi::Value NodeMap::QueryRenderedFeatures(const Napi::CallbackInfo& info) {
    using namespace mbgl::style;
    using namespace mbgl::style::conversion;

    auto nodeMap = this;
    if (!nodeMap->map) {
        napi_utils::throwError(info.Env(), releasedMessage());
        return info.Env().Undefined();
    }

    if (info.Length() <= 0 || !info[0].IsArray()) {
        napi_utils::throwError(info.Env(), "First argument must be an array");
        return info.Env().Undefined();
    }

    Napi::Array posOrBox = info[0].As<Napi::Array>();
    if (posOrBox.Length() != 2) {
        napi_utils::throwError(info.Env(), "First argument must have two components");
        return info.Env().Undefined();
    }

    mbgl::RenderedQueryOptions queryOptions;
    if (!info[1].IsNull() && !info[1].IsUndefined()) {
        if (!info[1].IsObject()) {
                napi_utils::throwError(info.Env(), "options argument must be an object");
                return info.Env().Undefined();
            }

        Napi::Object options = info[1].As<Napi::Object>();

        // Check if layers is set. If provided, it must be an array of strings
        if (options.Has("layers")) {
            Napi::Value layersOption = options.Get("layers");
            if (!layersOption.IsArray()) {
                    napi_utils::throwError(info.Env(), "Requires options.layers property to be an array");
                    return info.Env().Undefined();
                }
            Napi::Array layers = layersOption.As<Napi::Array>();
            std::vector<std::string> layersVec;
            for (uint32_t i = 0; i < layers.Length(); i++) {
                layersVec.emplace_back(layers.Get(i).As<Napi::String>().Utf8Value());
            }
            queryOptions.layerIDs = layersVec;
        }

        // Check if filter is provided. If set it must be a valid Filter object
        if (options.Has("filter")) {
            Napi::Value filterOption = options.Get("filter");
            Error error;
            std::optional<Filter> converted = mbgl::style::conversion::convert<Filter>(wrapNapiValue(filterOption), error);
            if (!converted) {
                    napi_utils::throwError(info.Env(), error.message.c_str());
                    return info.Env().Undefined();
                }
            queryOptions.filter = std::move(*converted);
        }
    }

    try {
        std::vector<mbgl::Feature> features;

        Napi::Value firstElement = posOrBox.Get(0u);
        if (firstElement.IsArray()) {
            Napi::Array pos0 = firstElement.As<Napi::Array>();
            Napi::Array pos1 = posOrBox.Get(1u).As<Napi::Array>();

            features = nodeMap->frontend->getRenderer()->queryRenderedFeatures(
                mbgl::ScreenBox{{pos0.Get(0u).ToNumber().DoubleValue(),
                                 pos0.Get(1u).ToNumber().DoubleValue()},
                                {pos1.Get(0u).ToNumber().DoubleValue(),
                                 pos1.Get(1u).ToNumber().DoubleValue()}},
                queryOptions);

        } else {
            features = nodeMap->frontend->getRenderer()->queryRenderedFeatures(
                mbgl::ScreenCoordinate{posOrBox.Get(0u).ToNumber().DoubleValue(),
                                       posOrBox.Get(1u).ToNumber().DoubleValue()},
                queryOptions);
        }

        Napi::Array array = Napi::Array::New(info.Env(), features.size());
        for (std::size_t i = 0; i < features.size(); i++) {
            array.Set(i, node_mbgl::toJS(info.Env(), features[i]));
        }
        return array;
    } catch (const std::exception& ex) {
        napi_utils::throwError(info.Env(), ex.what());
        return info.Env().Undefined();
    }
}

NodeMap::NodeMap(const Napi::CallbackInfo& info)
    : Napi::ObjectWrap<NodeMap>(info)
    , pixelRatio([&] {
          Napi::Object options = info[0].As<Napi::Object>();
          if (options.Has("ratio")) {
              return static_cast<float>(options.Get("ratio").ToNumber().DoubleValue());
          } else {
              return 1.0f;
          }
      }()),
      mode([&] {
          Napi::Object options = info[0].As<Napi::Object>();
          if (options.Has("mode")) {
              std::string modeValue = options.Get("mode").As<Napi::String>().Utf8Value();
              if (modeValue == "tile") {
                  return mbgl::MapMode::Tile;
              }
          }
          return mbgl::MapMode::Static;
      }()),
      crossSourceCollisions([&] {
          Napi::Object options = info[0].As<Napi::Object>();
          if (options.Has("crossSourceCollisions")) {
              return options.Get("crossSourceCollisions").ToBoolean().Value();
          } else {
              return true;
          }
      }()),
      mapObserver(NodeMapObserver()),
      frontend(std::make_unique<mbgl::HeadlessFrontend>(mbgl::Size{512, 512}, pixelRatio)),
      map(std::make_unique<mbgl::Map>(*frontend,
                                      mapObserver,
                                      mbgl::MapOptions()
                                          .withSize(frontend->getSize())
                                          .withPixelRatio(pixelRatio)
                                          .withMapMode(mode)
                                          .withCrossSourceCollisions(crossSourceCollisions),
                                      mbgl::ResourceOptions().withPlatformContext(reinterpret_cast<void*>(this)),
                                      mbgl::ClientOptions())),
      async(new uv_async_t) {
    async->data = this;
    uv_async_init(
        uv_default_loop(), async, [](uv_async_t* h) { reinterpret_cast<NodeMap*>(h->data)->renderFinished(); });

    // Make sure the async handle doesn't keep the loop alive.
    uv_unref(reinterpret_cast<uv_handle_t*>(async));
}

NodeMap::~NodeMap() {
    try {
        if (map) release();
    } catch (...) {
        mbgl::Log::Error(mbgl::Event::General, "Error release the map object when destroying NodeMap");
    }
}

std::unique_ptr<mbgl::AsyncRequest> NodeFileSource::request(const mbgl::Resource& resource,
                                                            mbgl::FileSource::Callback callback_) {
    assert(nodeMap);

    // Because this method may be called while this NodeMap is already eligible
    // for garbage collection, we need to explicitly hold onto our own handle
    // here so that GC during a v8 call doesn't destroy *this while we're still
    // executing code.
    nodeMap->Ref();

    auto asyncRequest = std::make_unique<node_mbgl::NodeAsyncRequest>();

    // This part needs to be implemented differently with node-addon-api
    // As we can't directly access the JavaScript environment from a native thread
    // without proper context handling
    // For now, we'll just return the asyncRequest

    return asyncRequest;
}

bool NodeFileSource::canRequest(const mbgl::Resource&) const {
    return true;
}

void NodeFileSource::setResourceOptions(mbgl::ResourceOptions options) {
    this->_resourceOptions = std::move(options);
}

mbgl::ResourceOptions NodeFileSource::getResourceOptions() {
    return this->_resourceOptions.clone();
}

void NodeFileSource::setClientOptions(mbgl::ClientOptions options) {
    this->_clientOptions = std::move(options);
}

mbgl::ClientOptions NodeFileSource::getClientOptions() {
    return this->_clientOptions.clone();
}

} // namespace node_mbgl
