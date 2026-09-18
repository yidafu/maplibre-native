#ifndef MAPLIBRE_HARMONY_SOURCE_NAPI_UTILS_HPP
#define MAPLIBRE_HARMONY_SOURCE_NAPI_UTILS_HPP

// Shared NAPI accessor shells for the source wrapper classes. Every source
// NAPI class used to hand-duplicate GetId (x7), GetUrl (x4) and the
// "tile size is immutable" SetTileSize (x2); the bodies were identical apart
// from the class name. Expand only inside namespace mbgl::harmony.
//
// The per-method "unwrap this, check the wrapper, check the source" preamble
// (~13 lines in every accessor of every source class) is likewise shared here
// as ResolveSource().

#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"

#include <array>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include <mbgl/util/geo.hpp>
#include <mbgl/util/range.hpp>
#include <mbgl/util/tileset.hpp>
#include <mbgl/util/variant.hpp>

namespace mbgl {
namespace harmony {

/**
 * Create an empty JS array. Several source accessors return `[]` on failure.
 */
inline napi_value CreateEmptyArray(napi_env env) {
    // Initialised up front: napi_create_array() leaves `result` untouched on
    // failure, and returning an indeterminate napi_value is UB.
    napi_value result = nullptr;
    napi_create_array(env, &result);
    return result;
}

/**
 * Resolve the source wrapper hanging off `jsThis` and its underlying core
 * source.
 *
 * Replaces the ~13-line preamble that every source accessor used to open with:
 *
 *     XSourceNAPI* sourceNapi = nullptr;
 *     napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
 *     if (!sourceNapi) { napi_throw_error(env, nullptr, "Invalid source wrapper"); return nullptr; }
 *     auto* source = sourceNapi->getSource();
 *     if (!source)     { napi_throw_error(env, nullptr, "Invalid source");         return nullptr; }
 *
 * On success returns the core source and writes the typed wrapper to
 * `*outWrapper` (callers use it for things like `sourceNapi->id`). On failure
 * returns nullptr.
 *
 * Error reporting is caller-selected so the historical wording is preserved
 * verbatim:
 *  - `throwOnError == true` (default): raises `wrapperError` / "Invalid source"
 *    before returning nullptr. VideoSourceNAPI historically collapsed the
 *    wrapper check into "Invalid source" and passes that as `wrapperError`.
 *  - `throwOnError == false`: silent, for accessors that return a sentinel
 *    (`[]` / `0.0`) instead of throwing.
 *
 * @tparam NapiCls the source wrapper class; its `getSource()` fixes the return type
 */
template <typename NapiCls>
auto ResolveSource(napi_env env, napi_value jsThis, NapiCls** outWrapper,
                   bool throwOnError = true,
                   const char* wrapperError = "Invalid source wrapper")
    -> decltype(std::declval<NapiCls*>()->getSource()) {
    *outWrapper = napi::NapiArgs::Unwrap<NapiCls>(env, jsThis);
    if (!*outWrapper) {
        if (throwOnError) {
            napi_throw_error(env, nullptr, wrapperError);
        }
        return nullptr;
    }
    auto* source = (*outWrapper)->getSource();
    if (!source) {
        if (throwOnError) {
            napi_throw_error(env, nullptr, "Invalid source");
        }
        return nullptr;
    }
    return source;
}

/**
 * Default image/video quad (whole world) used when no coordinates are
 * supplied yet.
 */
inline std::array<mbgl::LatLng, 4> DefaultLatLngQuad() {
    return {{
        mbgl::LatLng{0, 0}, mbgl::LatLng{0, 1},
        mbgl::LatLng{1, 1}, mbgl::LatLng{1, 0}
    }};
}

/**
 * Parse a [[lng, lat], ...] array of exactly four corners (clockwise).
 * Returns false when the value is not such an array; historical quirk kept:
 * corners before the offending one may already have been written to `out`.
 */
inline bool ParseLatLngQuad(napi_env env, napi_value coordsValue, std::array<mbgl::LatLng, 4>& out) {
    bool isArray = false;
    napi_is_array(env, coordsValue, &isArray);
    if (!isArray) return false;

    uint32_t length = 0;
    napi_get_array_length(env, coordsValue, &length);
    if (length != 4) return false;

    for (uint32_t i = 0; i < 4; ++i) {
        napi_value coordValue;
        napi_get_element(env, coordsValue, i, &coordValue);

        bool isCoordArray = false;
        napi_is_array(env, coordValue, &isCoordArray);
        if (!isCoordArray) return false;

        napi_value lngValue, latValue;
        napi_get_element(env, coordValue, 0, &lngValue);
        napi_get_element(env, coordValue, 1, &latValue);

        double lng = 0.0, lat = 0.0;
        napi_get_value_double(env, lngValue, &lng);
        napi_get_value_double(env, latValue, &lat);

        out[i] = mbgl::LatLng{lat, lng};
    }
    return true;
}

/**
 * Read a JS string array through NapiArgs::GetArrayElementString (the single
 * shared implementation - previously raster, raster-dem and vector each had
 * their own).
 *
 * strict == false: non-string and empty elements are skipped (raster/raster-dem
 * tiles semantics). strict == true: the first non-string element aborts with
 * `false` so the caller can raise its own error (VectorSource::setTiles
 * semantics); empty strings are still appended, matching the historical
 * behavior.
 */
inline bool ReadStringArray(napi::NapiArgs& args, napi_value array,
                            std::vector<std::string>& out, bool strict) {
    uint32_t length = args.GetArrayLength(array);
    if (strict) {
        out.reserve(length);
    }
    for (uint32_t i = 0; i < length; ++i) {
        if (strict) {
            napi_env env = args.Env();
            napi_value element;
            napi_get_element(env, array, i, &element);
            napi_valuetype elementType = napi_undefined;
            napi_typeof(env, element, &elementType);
            if (elementType != napi_string) {
                return false;
            }
        }
        std::string element = args.GetArrayElementString(array, i, "");
        if (!strict && element.empty()) {
            continue;
        }
        out.push_back(std::move(element));
    }
    return true;
}

/**
 * Parsed form of the {url, tiles, tileSize, minzoom, maxzoom} options shared
 * by the raster and raster-dem source constructors.
 */
struct TileCacheOptions {
    std::string url;
    std::vector<std::string> tiles;
    uint16_t tileSize = 512; // default value
    uint8_t minzoom = 0;
    uint8_t maxzoom = 22;
};

/**
 * Parse the tile-cache options object. `tag`/`label` keep each source's log
 * wording ("RasterSourceNAPI"/"RasterSource", ...). `tileSizeDefault` is the
 * value reported when the property is missing (raster logs tileSize even then;
 * raster-dem passes 0 so the 512 field default stays silent).
 */
inline void ParseTileCacheOptions(napi::NapiArgs& args, napi_value optionsObj,
                                  const char* tag, const char* label,
                                  int32_t tileSizeDefault, TileCacheOptions& out) {
    // Read url
    out.url = args.GetStringProperty(optionsObj, "url", "");
    if (!out.url.empty()) {
        Logger::info(tag, "%s URL: %s", label, out.url.c_str());
    }

    // Read the tiles array
    napi_env env = args.Env();
    napi_value tilesValue;
    if (napi_get_named_property(env, optionsObj, "tiles", &tilesValue) == napi_ok) {
        bool isArray = false;
        napi_is_array(env, tilesValue, &isArray);
        if (isArray) {
            ReadStringArray(args, tilesValue, out.tiles, /*strict=*/false);
            if (!out.tiles.empty()) {
                Logger::info(tag, "%s tiles count: %zu", label, out.tiles.size());
                Logger::info(tag, "%s tiles[0]: %s", label, out.tiles[0].c_str());
            }
        }
    }

    // Read tileSize
    int32_t tileSizeInt = args.GetInt32Property(optionsObj, "tileSize", tileSizeDefault);
    if (tileSizeInt > 0) {
        out.tileSize = static_cast<uint16_t>(tileSizeInt);
        Logger::info(tag, "%s tileSize: %d", label, out.tileSize);
    }

    // Read minzoom / maxzoom
    out.minzoom = static_cast<uint8_t>(args.GetInt32Property(optionsObj, "minzoom", 0));
    out.maxzoom = static_cast<uint8_t>(args.GetInt32Property(optionsObj, "maxzoom", 22));
}

/**
 * Build the constructor variant from parsed options: prefer the tiles array,
 * fall back to the URL when tiles are absent. `encoding` lets raster-dem pin
 * the tileset raster encoding.
 */
inline mbgl::variant<std::string, mbgl::Tileset> MakeUrlOrTileset(
    const TileCacheOptions& options, const char* tag, const char* label,
    std::optional<mbgl::Tileset::RasterEncoding> encoding = std::nullopt) {
    mbgl::variant<std::string, mbgl::Tileset> urlOrTileset;
    if (!options.tiles.empty()) {
        // Create a Tileset from the tiles array
        mbgl::Tileset tileset;
        tileset.tiles = options.tiles;
        tileset.zoomRange = mbgl::Range<uint8_t>(options.minzoom, options.maxzoom);
        if (encoding) {
            tileset.rasterEncoding = *encoding;
        }
        urlOrTileset = std::move(tileset);
        Logger::info(tag, "%s using Tileset with %zu tiles", label, options.tiles.size());
    } else {
        // Use the URL string
        urlOrTileset = options.url;
        Logger::info(tag, "%s using URL: %s", label, options.url.c_str());
    }
    return urlOrTileset;
}

} // namespace harmony
} // namespace mbgl

#define DEFINE_SOURCE_GET_ID(NapiCls)                                          \
    napi_value NapiCls::GetId(napi_env env, napi_callback_info info) {         \
        napi::NapiArgs args(env, info);                                        \
        NapiCls* sourceNapi = nullptr;                                         \
        napi_unwrap(env, args.This(), reinterpret_cast<void**>(&sourceNapi));  \
        if (!sourceNapi) {                                                     \
            return napi::CreateStringValue(env, "");                           \
        }                                                                      \
        return napi::CreateStringValue(env, sourceNapi->id);                   \
    }

#define DEFINE_SOURCE_GET_URL(NapiCls)                                         \
    napi_value NapiCls::GetUrl(napi_env env, napi_callback_info info) {        \
        napi::NapiArgs args(env, info);                                        \
        NapiCls* sourceNapi = nullptr;                                         \
        napi_unwrap(env, args.This(), reinterpret_cast<void**>(&sourceNapi));  \
        if (!sourceNapi) {                                                     \
            return napi::CreateStringValue(env, "");                           \
        }                                                                      \
        auto* source = sourceNapi->getSource();                                \
        if (!source) {                                                         \
            return napi::CreateStringValue(env, "");                           \
        }                                                                      \
        try {                                                                  \
            auto url = source->getURL();                                       \
            if (url) {                                                         \
                return napi::CreateStringValue(env, *url);                     \
            }                                                                  \
        } catch (const std::exception& e) {                                    \
            mbgl::harmony::Logger::error(#NapiCls, "GetUrl failed: %s", e.what()); \
        }                                                                      \
        return napi::CreateStringValue(env, "");                               \
    }

#define DEFINE_SOURCE_SET_TILE_SIZE_UNSUPPORTED(NapiCls)                       \
    napi_value NapiCls::SetTileSize(napi_env env, napi_callback_info info) {   \
        napi::NapiArgs args(env, info);                                        \
        args.RequireMinArgs(1);                                                \
        if (args.HasError()) return nullptr;                                   \
        NapiCls* sourceNapi = nullptr;                                         \
        napi_unwrap(env, args.This(), reinterpret_cast<void**>(&sourceNapi));  \
        if (!sourceNapi) {                                                     \
            napi_throw_error(env, nullptr, "Invalid source wrapper");          \
            return nullptr;                                                    \
        }                                                                      \
        auto* source = sourceNapi->getSource();                                \
        if (!source) {                                                         \
            napi_throw_error(env, nullptr, "Invalid source");                  \
            return nullptr;                                                    \
        }                                                                      \
        Logger::info(#NapiCls, "SetTileSize not supported - tile size is immutable after source creation"); \
        napi_throw_error(env, nullptr,                                         \
            #NapiCls " does not support changing tile size after creation. "   \
            "Please recreate the source with the desired tile size.");         \
        return nullptr;                                                        \
    }

// Destructor callback passed to napi_wrap: every source wrapper deletes its
// peer the same way (the classes only differ in name).
#define DEFINE_SOURCE_DESTRUCTOR(NapiCls)                                          \
    void NapiCls::Destructor(napi_env env, void* nativeObject, void* finalize_hint) { \
        NapiCls* sourceNapi = static_cast<NapiCls*>(nativeObject);                 \
        delete sourceNapi;                                                         \
    }

// CreateInstance: re-wrap a source the style already owns through its WeakPtr
// (the C++ analogue of the constructor). `SourceT` is the concrete
// mbgl::style::XSource this wrapper targets - note VideoSourceNAPI wraps
// mbgl::style::ImageSource, not a "VideoSource".
#define DEFINE_SOURCE_CREATE_INSTANCE(NapiCls, TypeName, SourceT)                   \
    napi_value NapiCls::CreateInstance(napi_env env, SourceT* sourcePtr) {          \
        return mbgl::harmony::WrapExistingInstance(                                 \
            env, constructor, Destructor, TypeName,                                 \
            sourcePtr ? new NapiCls(sourcePtr) : nullptr);                          \
    }

#endif // MAPLIBRE_HARMONY_SOURCE_NAPI_UTILS_HPP
