#include "offline_region_definition_napi.hpp"
#include "geometry/lat_lng_bounds_harmony.hpp"
#include "geojson/geojson_converter.hpp"
#include "utils/logger.h"

#include <variant>

namespace mln {
namespace harmony {

using Logger = mln::harmony::Logger;

namespace {

// Read a UTF-8 string with full status checking. Throws when the value is not a
// string: an unchecked/uninitialized length would otherwise drive the allocation
// (or, with a stack buffer, an out-of-bounds read of garbage length).
std::string ReadStringProperty(napi_env env, napi_value value, const char* name) {
    size_t len = 0;
    if (value == nullptr ||
        napi_get_value_string_utf8(env, value, nullptr, 0, &len) != napi_ok) {
        throw std::runtime_error(std::string("Offline region property '") + name + "' must be a string");
    }
    std::string out(len, '\0');
    if (len > 0 &&
        napi_get_value_string_utf8(env, value, &out[0], len + 1, nullptr) != napi_ok) {
        throw std::runtime_error(std::string("Failed to read offline region property '") + name + "'");
    }
    return out;
}

// Numeric/boolean reads fall back to a default instead of using an
// uninitialized stack value when the property is missing or mistyped.
double ReadDoubleProperty(napi_env env, napi_value value, double fallback) {
    double out = fallback;
    double tmp = 0.0;
    if (napi_get_value_double(env, value, &tmp) == napi_ok) {
        out = tmp;
    }
    return out;
}

bool ReadBoolProperty(napi_env env, napi_value value, bool fallback) {
    bool out = fallback;
    bool tmp = fallback;
    if (napi_get_value_bool(env, value, &tmp) == napi_ok) {
        out = tmp;
    }
    return out;
}

// The minZoom/maxZoom/pixelRatio/includeIdeographs options shared by the
// TilePyramid and Geometry region definitions.
struct CommonRegionOptions {
    double minZoom = 0.0;
    double maxZoom = 22.0;
    double pixelRatio = 1.0;
    bool includeIdeographs = false;
};

CommonRegionOptions ReadCommonOptions(napi_env env, napi_value obj) {
    CommonRegionOptions opts;

    napi_value value;
    napi_get_named_property(env, obj, "minZoom", &value);
    opts.minZoom = ReadDoubleProperty(env, value, 0.0);

    napi_get_named_property(env, obj, "maxZoom", &value);
    opts.maxZoom = ReadDoubleProperty(env, value, 22.0);

    napi_get_named_property(env, obj, "pixelRatio", &value);
    opts.pixelRatio = ReadDoubleProperty(env, value, 1.0);

    napi_get_named_property(env, obj, "includeIdeographs", &value);
    opts.includeIdeographs = ReadBoolProperty(env, value, false);

    return opts;
}

// Works for both OfflineTilePyramidRegionDefinition and
// OfflineGeometryRegionDefinition, which share the same option members.
template <typename Definition>
void WriteCommonOptions(napi_env env, napi_value obj, const Definition& def) {
    napi_value value;

    napi_create_double(env, def.minZoom, &value);
    napi_set_named_property(env, obj, "minZoom", value);

    napi_create_double(env, def.maxZoom, &value);
    napi_set_named_property(env, obj, "maxZoom", value);

    napi_create_double(env, def.pixelRatio, &value);
    napi_set_named_property(env, obj, "pixelRatio", value);

    napi_get_boolean(env, def.includeIdeographs, &value);
    napi_set_named_property(env, obj, "includeIdeographs", value);
}

} // namespace

// ========== Convert from NAPI object to C++ definition ==========

mln::OfflineRegionDefinition OfflineRegionDefinitionNAPI::FromNapiObject(napi_env env, napi_value obj) {
    // Check object type
    napi_value typeValue;
    if (napi_get_named_property(env, obj, "type", &typeValue) != napi_ok) {
        Logger::error("OfflineRegionDefinitionNAPI", "Definition object is missing 'type'");
        throw std::runtime_error("Offline region definition is missing the 'type' property");
    }

    std::string type = ReadStringProperty(env, typeValue, "type");

    if (type == "tilePyramid") {
        return TilePyramidFromNapi(env, obj);
    } else if (type == "geometry") {
        return GeometryFromNapi(env, obj);
    } else {
        Logger::error("OfflineRegionDefinitionNAPI", "Unknown definition type: %s", type.c_str());
        throw std::runtime_error("Unknown offline region definition type");
    }
}

// ========== Convert from C++ definition to NAPI object ==========

napi_value OfflineRegionDefinitionNAPI::ToNapiObject(napi_env env, const mln::OfflineRegionDefinition& definition) {
    return std::visit([env](const auto& def) {
        using T = std::decay_t<decltype(def)>;
        if constexpr (std::is_same_v<T, mln::OfflineTilePyramidRegionDefinition>) {
            return TilePyramidToNapi(env, def);
        } else if constexpr (std::is_same_v<T, mln::OfflineGeometryRegionDefinition>) {
            return GeometryToNapi(env, def);
        }
        return static_cast<napi_value>(nullptr);
    }, definition);
}

// ========== TilePyramid definition conversion ==========

mln::OfflineTilePyramidRegionDefinition OfflineRegionDefinitionNAPI::TilePyramidFromNapi(napi_env env, napi_value obj) {
    // Get styleURL
    napi_value styleURLValue;
    napi_get_named_property(env, obj, "styleURL", &styleURLValue);
    std::string styleURL = ReadStringProperty(env, styleURLValue, "styleURL");

    // Get bounds
    napi_value boundsValue;
    napi_get_named_property(env, obj, "bounds", &boundsValue);

    mln::LatLngBounds bounds;
    if (!mln::harmony::LatLngBoundsHarmony::ParseLatLngBounds(env, boundsValue, bounds)) {
        throw std::runtime_error("Failed to parse bounds");
    }

    CommonRegionOptions opts = ReadCommonOptions(env, obj);

    return mln::OfflineTilePyramidRegionDefinition(
        std::move(styleURL),
        bounds,
        opts.minZoom,
        opts.maxZoom,
        static_cast<float>(opts.pixelRatio),
        opts.includeIdeographs
    );
}

napi_value OfflineRegionDefinitionNAPI::TilePyramidToNapi(napi_env env, const mln::OfflineTilePyramidRegionDefinition& def) {
    napi_value obj;
    napi_create_object(env, &obj);
    
    // Set type
    napi_value typeValue;
    napi_create_string_utf8(env, "tilePyramid", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, obj, "type", typeValue);
    
    // Set styleURL
    napi_value styleURLValue;
    napi_create_string_utf8(env, def.styleURL.c_str(), NAPI_AUTO_LENGTH, &styleURLValue);
    napi_set_named_property(env, obj, "styleURL", styleURLValue);
    
    // Set bounds
    napi_value boundsValue = mln::harmony::LatLngBoundsHarmony::CreateLatLngBoundsObject(env, def.bounds);
    napi_set_named_property(env, obj, "bounds", boundsValue);

    WriteCommonOptions(env, obj, def);

    return obj;
}

// ========== Geometry definition conversion ==========

mln::OfflineGeometryRegionDefinition OfflineRegionDefinitionNAPI::GeometryFromNapi(napi_env env, napi_value obj) {
    // Get styleURL
    napi_value styleURLValue;
    napi_get_named_property(env, obj, "styleURL", &styleURLValue);
    std::string styleURL = ReadStringProperty(env, styleURLValue, "styleURL");

    // Get geometry
    napi_value geometryValue;
    napi_get_named_property(env, obj, "geometry", &geometryValue);

    mln::Geometry<double> geometry = mln::harmony::geojson::GeoJsonConverter::JsObjectToGeometry(env, geometryValue);

    CommonRegionOptions opts = ReadCommonOptions(env, obj);

    return mln::OfflineGeometryRegionDefinition(
        std::move(styleURL),
        geometry,
        opts.minZoom,
        opts.maxZoom,
        static_cast<float>(opts.pixelRatio),
        opts.includeIdeographs
    );
}

napi_value OfflineRegionDefinitionNAPI::GeometryToNapi(napi_env env, const mln::OfflineGeometryRegionDefinition& def) {
    napi_value obj;
    napi_create_object(env, &obj);
    
    // Set type
    napi_value typeValue;
    napi_create_string_utf8(env, "geometry", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, obj, "type", typeValue);
    
    // Set styleURL
    napi_value styleURLValue;
    napi_create_string_utf8(env, def.styleURL.c_str(), NAPI_AUTO_LENGTH, &styleURLValue);
    napi_set_named_property(env, obj, "styleURL", styleURLValue);
    
    // Set geometry
    napi_value geometryValue = mln::harmony::geojson::GeoJsonConverter::GeometryToJsObject(env, def.geometry);
    napi_set_named_property(env, obj, "geometry", geometryValue);

    WriteCommonOptions(env, obj, def);

    return obj;
}

} // namespace harmony
} // namespace mln

