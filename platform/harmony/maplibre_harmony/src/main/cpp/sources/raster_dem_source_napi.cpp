#include "raster_dem_source_napi.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"
#include <mbgl/util/tileset.hpp>
#include <mbgl/util/range.hpp>

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

namespace maplibre {

using mbgl::harmony::napi::NapiArgs;
namespace harmony {

napi_ref RasterDemSourceNAPI::constructor = nullptr;

RasterDemSourceNAPI::RasterDemSourceNAPI(const std::string& id, std::unique_ptr<mbgl::style::RasterDEMSource> source)
    : id(id), source(std::move(source)), ownsSource(true) {
    Logger::info("RasterDemSourceNAPI", "RasterDemSource instance created: %s", id.c_str());
}

RasterDemSourceNAPI::RasterDemSourceNAPI(mbgl::style::RasterDEMSource* sourcePtr)
    : ownsSource(false) {
    if (sourcePtr) {
        id = sourcePtr->getID();
        weakSource = sourcePtr->makeWeakPtr();
        Logger::info("RasterDemSourceNAPI", "RasterDemSource created from existing source (WeakPtr): %s", id.c_str());
    }
}

RasterDemSourceNAPI::~RasterDemSourceNAPI() {
    // Reset weakSource before source is destroyed to avoid accessing invalidated WeakPtrFactory
    Logger::info("RasterDemSourceNAPI", "RasterDemSource instance destroyed: %s", id.c_str());
}

void RasterDemSourceNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    RasterDemSourceNAPI* sourceNapi = static_cast<RasterDemSourceNAPI*>(nativeObject);
    delete sourceNapi;
}

napi_value RasterDemSourceNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("RasterDemSourceNAPI", "Initializing RasterDemSource NAPI class");
    
    napi_property_descriptor properties[] = {
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getUrl", nullptr, GetUrl, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setUrl", nullptr, SetUrl, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTileSize", nullptr, SetTileSize, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "RasterDemSource", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("RasterDemSourceNAPI", "Failed to define RasterDemSource class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("RasterDemSourceNAPI", "Failed to create constructor reference");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "RasterDemSource", cons);
    if (status != napi_ok) {
        Logger::error("RasterDemSourceNAPI", "Failed to set RasterDemSource property");
        return nullptr;
    }
    
    Logger::info("RasterDemSourceNAPI", "RasterDemSource NAPI class initialized successfully");
    return exports;
}

napi_value RasterDemSourceNAPI::New(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "RasterDemSource requires sourceId argument");
        return nullptr;
    }
    
    NapiArgs napiArgs(env, info);
    std::string sourceId = napiArgs.GetString(0, "sourceId");
    
    if (napiArgs.HasError()) {
        napi_throw_error(env, nullptr, "Failed to parse sourceId");
        return nullptr;
    }
    
    try {
        // Parse options argument using NapiArgs
        std::string url = "";
        std::vector<std::string> tiles;
        uint16_t tileSize = 512;
        uint8_t minzoom = 0;
        uint8_t maxzoom = 22;
        std::optional<mbgl::style::SourceOptions> options = std::nullopt;

        // Get options object using NapiArgs
        napi_value optionsObj = napiArgs.GetObject(1, "options");
        if (!napiArgs.HasError() && optionsObj) {
            // Read url
            url = napiArgs.GetStringProperty(optionsObj, "url", "");
            if (!url.empty()) {
                Logger::info("RasterDemSourceNAPI", "RasterDemSource URL: %s", url.c_str());
            }

            // Read tiles array using NapiArgs helpers
            napi_value tilesValue;
            napi_status status = napi_get_named_property(env, optionsObj, "tiles", &tilesValue);
            if (status == napi_ok) {
                uint32_t length = napiArgs.GetArrayLength(tilesValue);
                for (uint32_t i = 0; i < length; i++) {
                    std::string tileStr = napiArgs.GetArrayElementString(tilesValue, i, "");
                    if (!tileStr.empty()) {
                        tiles.push_back(tileStr);
                    }
                }
                if (!tiles.empty()) {
                    Logger::info("RasterDemSourceNAPI", "RasterDemSource tiles count: %zu", tiles.size());
                }
            }

            // Read tileSize
            int32_t tileSizeInt = napiArgs.GetInt32Property(optionsObj, "tileSize", 0);
            if (tileSizeInt > 0) {
                tileSize = static_cast<uint16_t>(tileSizeInt);
                Logger::info("RasterDemSourceNAPI", "RasterDemSource tileSize: %d", tileSize);
            }

            // Read minzoom
            minzoom = static_cast<uint8_t>(napiArgs.GetInt32Property(optionsObj, "minzoom", 0));

            // Read maxzoom
            maxzoom = static_cast<uint8_t>(napiArgs.GetInt32Property(optionsObj, "maxzoom", 22));

            // Read encoding
            std::string encoding = napiArgs.GetStringProperty(optionsObj, "encoding", "");
            if (!encoding.empty()) {
                mbgl::style::SourceOptions sourceOpts;
                if (encoding == "mapbox") {
                    sourceOpts.rasterEncoding = mbgl::Tileset::RasterEncoding::Mapbox;
                } else if (encoding == "terrarium") {
                    sourceOpts.rasterEncoding = mbgl::Tileset::RasterEncoding::Terrarium;
                }
                options = sourceOpts;
                Logger::info("RasterDemSourceNAPI", "RasterDemSource encoding: %s", encoding.c_str());
            }
        }

        // Create the RasterDEMSource
        // Prefer the tiles array; fall back to the URL when tiles are absent
        mbgl::variant<std::string, mbgl::Tileset> urlOrTileset;
        if (!tiles.empty()) {
            mbgl::Tileset tileset;
            tileset.tiles = tiles;
            tileset.zoomRange = mbgl::Range<uint8_t>(minzoom, maxzoom);
            if (options && options->rasterEncoding) {
                tileset.rasterEncoding = *options->rasterEncoding;
            }
            urlOrTileset = std::move(tileset);
            Logger::info("RasterDemSourceNAPI", "RasterDemSource using Tileset with %zu tiles", tiles.size());
        } else {
            urlOrTileset = url;
            Logger::info("RasterDemSourceNAPI", "RasterDemSource using URL: %s", url.c_str());
        }

        auto source = std::make_unique<mbgl::style::RasterDEMSource>(
            sourceId,
            std::move(urlOrTileset),
            tileSize,
            std::move(options)
        );
        RasterDemSourceNAPI* sourceNapi = new RasterDemSourceNAPI(sourceId, std::move(source));
        
        napi_status status = napi_wrap(env, jsThis, sourceNapi, Destructor, nullptr, nullptr);
        if (status != napi_ok) {
            delete sourceNapi;
            napi_throw_error(env, nullptr, "Failed to wrap RasterDemSource object");
            return nullptr;
        }
        
        Logger::info("RasterDemSourceNAPI", "RasterDemSource created: %s", sourceId.c_str());
    
    // Add the _TYPE_ property for ETS type detection
    napi_value typeValue;
    napi_create_string_utf8(env, "RasterDemSource", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, jsThis, "_TYPE_", typeValue);
        return jsThis;
    } catch (const std::exception& e) {
        Logger::error("RasterDemSourceNAPI", "Failed to create RasterDemSource: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value RasterDemSourceNAPI::CreateInstance(napi_env env, mbgl::style::RasterDEMSource* sourcePtr) {
    if (!sourcePtr) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Retrieve the constructor
    napi_value cons;
    napi_status status = napi_get_reference_value(env, constructor, &cons);
    if (status != napi_ok) {
        Logger::error("RasterDemSourceNAPI", "Failed to get constructor reference");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Create a plain object and set its prototype (avoid invoking the JS constructor)
    napi_value instance;
    status = napi_create_object(env, &instance);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to create object");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Retrieve the constructor prototype
    napi_value prototype;
    status = napi_get_named_property(env, cons, "prototype", &prototype);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to get prototype");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Set the object's prototype
    status = napi_set_named_property(env, instance, "__proto__", prototype);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to set prototype");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Create the NAPI wrapper (using the WeakPtr constructor)
    RasterDemSourceNAPI* napiObj = new RasterDemSourceNAPI(sourcePtr);
    
    // Wrap into the JS object
    status = napi_wrap(env, instance, napiObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete napiObj;
        Logger::error("RasterDemSourceNAPI", "Failed to wrap instance");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Add the _TYPE_ property
    napi_value typeValue;
    napi_create_string_utf8(env, "RasterDemSource", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, instance, "_TYPE_", typeValue);
    
    return instance;
}

napi_value RasterDemSourceNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    RasterDemSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        return CreateStringValue(env, "");
    }
    
    return CreateStringValue(env, sourceNapi->id);
}

napi_value RasterDemSourceNAPI::GetUrl(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    RasterDemSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        return CreateStringValue(env, "");
    }
    
    auto* source = sourceNapi->getSource();
    if (!source) {
        return CreateStringValue(env, "");
    }
    
    try {
        auto url = source->getURL();
        if (url) {
            return CreateStringValue(env, *url);
        }
    } catch (const std::exception& e) {
        Logger::error("RasterDemSourceNAPI", "GetUrl failed: %s", e.what());
    }
    
    return CreateStringValue(env, "");
}

napi_value RasterDemSourceNAPI::SetUrl(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    RasterDemSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        napi_throw_error(env, nullptr, "Invalid source wrapper");
        return nullptr;
    }
    
    NapiArgs args(env, info);
    std::string url = args.GetString(0, "url");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    // Rebuild only while the source has not yet been added to the style (still owned by unique_ptr)
    auto* ownedSource = sourceNapi->source.get();
    if (!ownedSource) {
        napi_throw_error(env, nullptr, "RasterDEMSource URL cannot be changed after adding to the map style");
        return nullptr;
    }
    
    const uint16_t tileSize = ownedSource->getTileSize();
    
    try {
        mbgl::variant<std::string, mbgl::Tileset> urlOrTileset = url;
        auto newSource = std::make_unique<mbgl::style::RasterDEMSource>(
            sourceNapi->id,
            std::move(urlOrTileset),
            tileSize
        );
        sourceNapi->source = std::move(newSource);
        Logger::info("RasterDemSourceNAPI", "RasterDEMSource recreated with new URL: %s -> %s",
                     sourceNapi->id.c_str(), url.c_str());
    } catch (const std::exception& e) {
        Logger::error("RasterDemSourceNAPI", "SetUrl failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
    }
    
    return nullptr;
}

napi_value RasterDemSourceNAPI::SetTileSize(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;

    napi_value jsThis = args.This();
    RasterDemSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));

    if (!sourceNapi) {
        napi_throw_error(env, nullptr, "Invalid source wrapper");
        return nullptr;
    }

    auto* source = sourceNapi->getSource();
    if (!source) {
        napi_throw_error(env, nullptr, "Invalid source");
        return nullptr;
    }

    // Note: RasterDemSource does not support changing tile size after
    // creation; the operation is unsupported regardless of the argument value.
    Logger::info("RasterDemSourceNAPI", "SetTileSize not supported - tile size is immutable after source creation");
    napi_throw_error(env, nullptr, "RasterDemSource does not support changing tile size after creation. Please recreate the source with the desired tile size.");
    return nullptr;
}

} // namespace harmony
} // namespace maplibre

