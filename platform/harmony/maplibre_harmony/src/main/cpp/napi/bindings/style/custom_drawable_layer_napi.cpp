#include "custom_drawable_layer_napi.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"
#include <mbgl/style/layers/custom_drawable_layer.hpp>
#include <mbgl/gfx/fill_generator.hpp>
#include <mbgl/util/color.hpp>
#include <mbgl/util/constants.hpp>
#include <mbgl/util/geometry.hpp>
#include <mbgl/util/projection.hpp>

#include <unordered_map>

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

namespace maplibre {
namespace harmony {

namespace {

/**
 * Render-thread host: replays the JS-authored command list in update().
 * The host owns a strong reference to the state, so the scene stays valid
 * for the lifetime of the layer even if the JS wrapper is collected first.
 */
class HarmonyDrawableLayerHost final : public mbgl::style::CustomDrawableLayerHost {
public:
    explicit HarmonyDrawableLayerHost(std::shared_ptr<CustomDrawableState> state_)
        : state(std::move(state_)) {}

    void initialize() override {}

    void update(Interface& interface) override {
        std::lock_guard<std::mutex> lock(state->mutex);
        if (!state->dirty && interface.getDrawableCount() > 0) {
            return;
        }

        // Rebuild from scratch: drop previous drawables, replay the scene
        for (auto id : state->drawableIds) {
            interface.removeDrawable(id);
        }
        state->drawableIds.clear();
        interface.finish();

        for (const auto& command : state->commands) {
            auto id = command(interface);
            if (id != mbgl::util::SimpleIdentity::Empty) {
                state->drawableIds.push_back(id);
            }
        }

        Logger::debug("CustomDrawableLayerNAPI", "update: rebuilt %zu drawables", state->drawableIds.size());
        state->dirty = false;
    }

    void deinitialize() override {}

private:
    std::shared_ptr<CustomDrawableState> state;
};

// Registry mapping layer ids to their scene state, so GetLayer/CreateInstance
// can reconnect a fresh NAPI wrapper to the live host state without reaching
// into core private headers.
std::mutex registryMutex;
std::unordered_map<std::string, std::shared_ptr<CustomDrawableState>> stateRegistry;

std::shared_ptr<CustomDrawableState> takeStateFromRegistry(const std::string& layerId) {
    std::lock_guard<std::mutex> lock(registryMutex);
    auto it = stateRegistry.find(layerId);
    if (it == stateRegistry.end()) {
        return nullptr;
    }
    auto state = it->second;
    stateRegistry.erase(it);
    return state;
}

// Parse "[r, g, b, a]" (0-1 floats) into mbgl::Color
bool parseColorArray(napi_env env, napi_value value, mbgl::Color& out) {
    bool isArray = false;
    napi_is_array(env, value, &isArray);
    if (!isArray) return false;

    uint32_t length = 0;
    napi_get_array_length(env, value, &length);
    if (length < 3) return false;

    double c[4] = {0.0, 0.0, 0.0, 1.0};
    for (uint32_t i = 0; i < length && i < 4; ++i) {
        napi_value element;
        napi_get_element(env, value, i, &element);
        napi_get_value_double(env, element, &c[i]);
    }
    out = mbgl::Color(static_cast<float>(c[0]), static_cast<float>(c[1]), static_cast<float>(c[2]),
                      static_cast<float>(c[3]));
    return true;
}

// Parse a color given as a CSS string or an [r,g,b,(a)] array
bool parseColor(napi_env env, napi_value value, mbgl::Color& out) {
    napi_valuetype type = napi_undefined;
    napi_typeof(env, value, &type);
    if (type == napi_string) {
        size_t len = 0;
        napi_get_value_string_utf8(env, value, nullptr, 0, &len);
        std::string str(len, '\0');
        napi_get_value_string_utf8(env, value, str.data(), len + 1, nullptr);
        auto parsed = mbgl::Color::parse(str);
        if (parsed) {
            out = *parsed;
            return true;
        }
        return false;
    }
    if (type == napi_object) {
        return parseColorArray(env, value, out);
    }
    return false;
}

// Read a double property from an object, with a fallback
double getNumberProperty(napi_env env, napi_value obj, const char* name, double fallback) {
    napi_value property;
    if (napi_get_named_property(env, obj, name, &property) != napi_ok) {
        return fallback;
    }
    napi_valuetype type = napi_undefined;
    napi_typeof(env, property, &type);
    if (type != napi_number) {
        return fallback;
    }
    double result = fallback;
    napi_get_value_double(env, property, &result);
    return result;
}

mbgl::style::LineCapType parseLineCap(napi_env env, napi_value value, mbgl::style::LineCapType fallback) {
    size_t len = 0;
    napi_get_value_string_utf8(env, value, nullptr, 0, &len);
    std::string str(len, '\0');
    napi_get_value_string_utf8(env, value, str.data(), len + 1, nullptr);
    if (str == "butt") return mbgl::style::LineCapType::Butt;
    if (str == "round") return mbgl::style::LineCapType::Round;
    if (str == "square") return mbgl::style::LineCapType::Square;
    return fallback;
}

mbgl::style::LineJoinType parseLineJoin(napi_env env, napi_value value, mbgl::style::LineJoinType fallback) {
    size_t len = 0;
    napi_get_value_string_utf8(env, value, nullptr, 0, &len);
    std::string str(len, '\0');
    napi_get_value_string_utf8(env, value, str.data(), len + 1, nullptr);
    if (str == "miter") return mbgl::style::LineJoinType::Miter;
    if (str == "bevel") return mbgl::style::LineJoinType::Bevel;
    if (str == "round") return mbgl::style::LineJoinType::Round;
    return fallback;
}

// Parse "[[lng, lat], ...]" into a geographic LineString
bool parseLineString(napi_env env, napi_value value, mbgl::LineString<double>& out) {
    bool isArray = false;
    napi_is_array(env, value, &isArray);
    if (!isArray) return false;

    uint32_t length = 0;
    napi_get_array_length(env, value, &length);
    if (length < 2) return false;

    out.clear();
    for (uint32_t i = 0; i < length; ++i) {
        napi_value pointValue;
        napi_get_element(env, value, i, &pointValue);

        bool isPoint = false;
        napi_is_array(env, pointValue, &isPoint);
        if (!isPoint) return false;

        napi_value lngValue, latValue;
        napi_get_element(env, pointValue, 0, &lngValue);
        napi_get_element(env, pointValue, 1, &latValue);

        double lng = 0.0, lat = 0.0;
        napi_get_value_double(env, lngValue, &lng);
        napi_get_value_double(env, latValue, &lat);

        out.emplace_back(lng, lat);
    }
    return true;
}

// Project a geographic ring to tile {0, 0, 0} coordinates (same convention as
// the Interface's geographic addPolyline overload)
mbgl::GeometryCoordinates projectRing(const std::vector<mbgl::Point<double>>& ring) {
    mbgl::GeometryCoordinates result;
    result.reserve(ring.size());
    for (const auto& point : ring) {
        const auto projected = mbgl::Projection::project(mbgl::LatLng(point.y, point.x), 0);
        result.emplace_back(static_cast<int16_t>(projected.x * mbgl::util::EXTENT),
                            static_cast<int16_t>(projected.y * mbgl::util::EXTENT));
    }
    return result;
}

// Parse "[[[lng, lat], ...], ...]" (rings, first = outer, rest = holes) into a
// tile-coordinate GeometryCollection
bool parseRings(napi_env env, napi_value value, mbgl::GeometryCollection& out) {
    bool isArray = false;
    napi_is_array(env, value, &isArray);
    if (!isArray) return false;

    uint32_t ringCount = 0;
    napi_get_array_length(env, value, &ringCount);
    if (ringCount == 0) return false;

    out.clear();
    for (uint32_t r = 0; r < ringCount; ++r) {
        napi_value ringValue;
        napi_get_element(env, value, r, &ringValue);

        mbgl::LineString<double> ring;
        if (!parseLineString(env, ringValue, ring)) {
            return false;
        }
        out.push_back(projectRing(ring));
    }
    return true;
}

// Shared option parsing for polyline items
mbgl::style::CustomDrawableLayerHost::Interface::LineOptions parseLineOptions(napi_env env, napi_value optionsObj) {
    using Interface = mbgl::style::CustomDrawableLayerHost::Interface;
    Interface::LineOptions options;

    if (!optionsObj) {
        return options;
    }

    napi_value value;
    if (napi_get_named_property(env, optionsObj, "color", &value) == napi_ok) {
        parseColor(env, value, options.color);
    }

    options.width = static_cast<float>(getNumberProperty(env, optionsObj, "width", options.width));
    options.blur = static_cast<float>(getNumberProperty(env, optionsObj, "blur", options.blur));
    options.opacity = static_cast<float>(getNumberProperty(env, optionsObj, "opacity", options.opacity));
    options.gapWidth = static_cast<float>(getNumberProperty(env, optionsObj, "gapWidth", options.gapWidth));
    options.offset = static_cast<float>(getNumberProperty(env, optionsObj, "offset", options.offset));

    if (napi_get_named_property(env, optionsObj, "beginCap", &value) == napi_ok) {
        napi_valuetype type = napi_undefined;
        napi_typeof(env, value, &type);
        if (type == napi_string) {
            options.geometry.beginCap = parseLineCap(env, value, options.geometry.beginCap);
        }
    }
    if (napi_get_named_property(env, optionsObj, "endCap", &value) == napi_ok) {
        napi_valuetype type = napi_undefined;
        napi_typeof(env, value, &type);
        if (type == napi_string) {
            options.geometry.endCap = parseLineCap(env, value, options.geometry.endCap);
        }
    }
    if (napi_get_named_property(env, optionsObj, "join", &value) == napi_ok) {
        napi_valuetype type = napi_undefined;
        napi_typeof(env, value, &type);
        if (type == napi_string) {
            options.geometry.joinType = parseLineJoin(env, value, options.geometry.joinType);
        }
    }

    return options;
}

} // namespace

// Static member initialization
napi_ref CustomDrawableLayerNAPI::constructor = nullptr;

CustomDrawableLayerNAPI::CustomDrawableLayerNAPI(const std::string& layerId,
                                                 std::unique_ptr<mbgl::style::CustomDrawableLayer> layer,
                                                 std::shared_ptr<CustomDrawableState> state_)
    : layerId(layerId),
      layer(std::move(layer)),
      ownsLayer(true),
      state(std::move(state_)) {
    Logger::info("CustomDrawableLayerNAPI", "CustomDrawableLayer created: %s", layerId.c_str());
}

CustomDrawableLayerNAPI::CustomDrawableLayerNAPI(mbgl::style::CustomDrawableLayer* layerPtr,
                                                 std::shared_ptr<CustomDrawableState> state_)
    : ownsLayer(false), state(std::move(state_)) {
    if (layerPtr) {
        layerId = layerPtr->getID();
        weakLayer = layerPtr->makeWeakPtr();
        Logger::info("CustomDrawableLayerNAPI", "CustomDrawableLayer created from existing layer (WeakPtr): %s",
                     layerId.c_str());
    }
}

CustomDrawableLayerNAPI::~CustomDrawableLayerNAPI() {
    // Drop our registry entry unless a newer wrapper already replaced it
    std::lock_guard<std::mutex> lock(registryMutex);
    auto it = stateRegistry.find(layerId);
    if (it != stateRegistry.end() && it->second == state) {
        stateRegistry.erase(it);
    }
    Logger::info("CustomDrawableLayerNAPI", "CustomDrawableLayer destroyed: %s", layerId.c_str());
}

void CustomDrawableLayerNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    CustomDrawableLayerNAPI* obj = static_cast<CustomDrawableLayerNAPI*>(nativeObject);
    delete obj;
}

napi_value CustomDrawableLayerNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("CustomDrawableLayerNAPI", "Initializing CustomDrawableLayer NAPI class");

    napi_property_descriptor properties[] = {
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getType", nullptr, GetType, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setVisibility", nullptr, SetVisibility, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getVisibility", nullptr, GetVisibility, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setMinZoom", nullptr, SetMinZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getMinZoom", nullptr, GetMinZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setMaxZoom", nullptr, SetMaxZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getMaxZoom", nullptr, GetMaxZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "addPolyline", nullptr, AddPolyline, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "addFill", nullptr, AddFill, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "clear", nullptr, Clear, nullptr, nullptr, nullptr, napi_default, nullptr },
    };

    napi_value cons;
    napi_status status = napi_define_class(env, "CustomDrawableLayer", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);

    if (status != napi_ok) {
        Logger::error("CustomDrawableLayerNAPI", "Failed to define CustomDrawableLayer class");
        return nullptr;
    }

    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("CustomDrawableLayerNAPI", "Failed to create reference to constructor");
        return nullptr;
    }

    status = napi_set_named_property(env, exports, "CustomDrawableLayer", cons);
    if (status != napi_ok) {
        Logger::error("CustomDrawableLayerNAPI", "Failed to export CustomDrawableLayer class");
        return nullptr;
    }

    Logger::info("CustomDrawableLayerNAPI", "CustomDrawableLayer NAPI class registered successfully");
    return exports;
}

napi_value CustomDrawableLayerNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value thisVar;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisVar, nullptr);

    args.RequireMinArgs(1);
    if (args.HasError()) {
        return nullptr;
    }

    std::string layerId = args.GetString(0, "layerId");
    if (args.HasError()) {
        return nullptr;
    }

    auto state = std::make_shared<CustomDrawableState>();
    auto host = std::make_unique<HarmonyDrawableLayerHost>(state);
    auto layer = std::make_unique<mbgl::style::CustomDrawableLayer>(layerId, std::move(host));

    {
        std::lock_guard<std::mutex> lock(registryMutex);
        stateRegistry[layerId] = state;
    }

    CustomDrawableLayerNAPI* layerObj =
        new CustomDrawableLayerNAPI(layerId, std::move(layer), std::move(state));

    napi_status status = napi_wrap(env, thisVar, layerObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete layerObj;
        Logger::error("CustomDrawableLayerNAPI", "Failed to wrap CustomDrawableLayer object");
        return nullptr;
    }

    // Add the _TYPE_ property for ETS type detection
    napi_value typeValue;
    napi_create_string_utf8(env, "CustomDrawableLayer", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, thisVar, "_TYPE_", typeValue);

    return thisVar;
}

napi_value CustomDrawableLayerNAPI::CreateInstance(napi_env env, mbgl::style::CustomDrawableLayer* layerPtr) {
    if (!layerPtr) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }

    napi_value cons;
    napi_status status = napi_get_reference_value(env, constructor, &cons);
    if (status != napi_ok) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }

    napi_value instance;
    status = napi_create_object(env, &instance);
    if (status != napi_ok) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }

    napi_value prototype;
    status = napi_get_named_property(env, cons, "prototype", &prototype);
    if (status != napi_ok) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }

    status = napi_set_named_property(env, instance, "__proto__", prototype);
    if (status != napi_ok) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }

    // Reconnect to the live scene state created by the original wrapper
    std::shared_ptr<CustomDrawableState> state;
    {
        std::lock_guard<std::mutex> lock(registryMutex);
        auto it = stateRegistry.find(layerPtr->getID());
        if (it != stateRegistry.end()) {
            state = it->second;
        }
    }
    if (!state) {
        Logger::warn("CustomDrawableLayerNAPI",
                     "CreateInstance: no live state for layer '%s'; returning an empty scene",
                     layerPtr->getID().c_str());
        state = std::make_shared<CustomDrawableState>();
    }

    CustomDrawableLayerNAPI* napiObj = new CustomDrawableLayerNAPI(layerPtr, std::move(state));

    status = napi_wrap(env, instance, napiObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete napiObj;
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }

    napi_value typeValue;
    napi_create_string_utf8(env, "CustomDrawableLayer", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, instance, "_TYPE_", typeValue);

    return instance;
}

napi_value CustomDrawableLayerNAPI::GetId(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);

    CustomDrawableLayerNAPI* layerObj = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&layerObj));

    if (!layerObj) {
        return CreateStringValue(env, "");
    }
    return CreateStringValue(env, layerObj->layerId);
}

napi_value CustomDrawableLayerNAPI::GetType(napi_env env, napi_callback_info info) {
    return CreateStringValue(env, "custom-drawable");
}

napi_value CustomDrawableLayerNAPI::SetVisibility(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;

    CustomDrawableLayerNAPI* layerObj = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer()) {
        return nullptr;
    }

    std::string visibility = args.GetString(0, "visibility");
    if (args.HasError()) return nullptr;

    if (visibility == "visible") {
        layerObj->getLayer()->setVisibility(mbgl::style::VisibilityType::Visible);
    } else if (visibility == "none") {
        layerObj->getLayer()->setVisibility(mbgl::style::VisibilityType::None);
    }

    return nullptr;
}

napi_value CustomDrawableLayerNAPI::GetVisibility(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);

    CustomDrawableLayerNAPI* layerObj = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer()) {
        return CreateStringValue(env, "visible");
    }

    auto visibility = layerObj->getLayer()->getVisibility();
    return CreateStringValue(env, visibility == mbgl::style::VisibilityType::Visible ? "visible" : "none");
}

napi_value CustomDrawableLayerNAPI::SetMinZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;

    CustomDrawableLayerNAPI* layerObj = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer()) {
        return nullptr;
    }

    double minZoom = args.GetDouble(0, "minZoom");
    if (args.HasError()) return nullptr;

    layerObj->getLayer()->setMinZoom(static_cast<float>(minZoom));
    return nullptr;
}

napi_value CustomDrawableLayerNAPI::GetMinZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);

    CustomDrawableLayerNAPI* layerObj = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer()) {
        napi_value result;
        napi_create_double(env, 0.0, &result);
        return result;
    }

    napi_value result;
    napi_create_double(env, layerObj->getLayer()->getMinZoom(), &result);
    return result;
}

napi_value CustomDrawableLayerNAPI::SetMaxZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;

    CustomDrawableLayerNAPI* layerObj = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer()) {
        return nullptr;
    }

    double maxZoom = args.GetDouble(0, "maxZoom");
    if (args.HasError()) return nullptr;

    layerObj->getLayer()->setMaxZoom(static_cast<float>(maxZoom));
    return nullptr;
}

napi_value CustomDrawableLayerNAPI::GetMaxZoom(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);

    CustomDrawableLayerNAPI* layerObj = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->getLayer()) {
        napi_value result;
        napi_create_double(env, 24.0, &result);
        return result;
    }

    napi_value result;
    napi_create_double(env, layerObj->getLayer()->getMaxZoom(), &result);
    return result;
}

napi_value CustomDrawableLayerNAPI::AddPolyline(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;

    CustomDrawableLayerNAPI* layerObj = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->state) {
        napi_throw_error(env, nullptr, "Invalid layer wrapper");
        return nullptr;
    }

    mbgl::LineString<double> coords;
    if (!parseLineString(env, args.GetValue(0), coords)) {
        napi_throw_error(env, nullptr, "addPolyline requires [[lng, lat], ...] coordinates");
        return nullptr;
    }

    using Interface = mbgl::style::CustomDrawableLayerHost::Interface;
    Interface::LineOptions options;
    Interface::LineShaderType shaderType = Interface::LineShaderType::Classic;
    if (args.Count() >= 2) {
        napi_value optionsObj = args.GetValue(1);
        napi_valuetype type = napi_undefined;
        napi_typeof(env, optionsObj, &type);
        if (type == napi_object) {
            options = parseLineOptions(env, optionsObj);

            // Shader flavor: "classic" (default) or "widevector". Core falls
            // back to classic on backends without the widevector shader.
            napi_value shaderValue;
            if (napi_get_named_property(env, optionsObj, "shaderType", &shaderValue) == napi_ok) {
                napi_valuetype valueType = napi_undefined;
                napi_typeof(env, shaderValue, &valueType);
                if (valueType == napi_string) {
                    size_t len = 0;
                    napi_get_value_string_utf8(env, shaderValue, nullptr, 0, &len);
                    std::string shader(len, '\0');
                    napi_get_value_string_utf8(env, shaderValue, shader.data(), len + 1, nullptr);
                    if (shader == "widevector") {
                        shaderType = Interface::LineShaderType::WideVector;
                    }
                }
            }
        }
    }

    auto coordsPtr = std::make_shared<mbgl::LineString<double>>(std::move(coords));
    auto command = [coordsPtr, options, shaderType](CustomDrawableState::Interface& interface)
        -> mbgl::util::SimpleIdentity {
        interface.setLineOptions(options);
        return interface.addPolyline(*coordsPtr, shaderType);
    };

    {
        std::lock_guard<std::mutex> lock(layerObj->state->mutex);
        layerObj->state->commands.push_back(command);
        layerObj->state->dirty = true;
    }

    return nullptr;
}

napi_value CustomDrawableLayerNAPI::AddFill(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;

    CustomDrawableLayerNAPI* layerObj = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->state) {
        napi_throw_error(env, nullptr, "Invalid layer wrapper");
        return nullptr;
    }

    mbgl::GeometryCollection rings;
    if (!parseRings(env, args.GetValue(0), rings)) {
        napi_throw_error(env, nullptr, "addFill requires [[[lng, lat], ...], ...] rings");
        return nullptr;
    }

    using Interface = mbgl::style::CustomDrawableLayerHost::Interface;
    Interface::FillOptions options;
    if (args.Count() >= 2) {
        napi_value optionsObj = args.GetValue(1);
        napi_valuetype type = napi_undefined;
        napi_typeof(env, optionsObj, &type);
        if (type == napi_object) {
            napi_value value;
            if (napi_get_named_property(env, optionsObj, "color", &value) == napi_ok) {
                parseColor(env, value, options.color);
            }
            options.opacity = static_cast<float>(getNumberProperty(env, optionsObj, "opacity", options.opacity));
        }
    }

    auto ringsPtr = std::make_shared<mbgl::GeometryCollection>(std::move(rings));
    auto command = [ringsPtr, options](CustomDrawableState::Interface& interface) -> mbgl::util::SimpleIdentity {
        interface.setFillOptions(options);
        return interface.addFill(*ringsPtr);
    };

    {
        std::lock_guard<std::mutex> lock(layerObj->state->mutex);
        layerObj->state->commands.push_back(command);
        layerObj->state->dirty = true;
    }

    return nullptr;
}

napi_value CustomDrawableLayerNAPI::Clear(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);

    CustomDrawableLayerNAPI* layerObj = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&layerObj));

    if (!layerObj || !layerObj->state) {
        return nullptr;
    }

    {
        std::lock_guard<std::mutex> lock(layerObj->state->mutex);
        layerObj->state->commands.clear();
        layerObj->state->dirty = true;
    }

    return nullptr;
}

} // namespace harmony
} // namespace maplibre
