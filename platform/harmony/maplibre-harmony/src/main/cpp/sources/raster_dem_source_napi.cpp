#include "raster_dem_source_napi.hpp"
#include "napi/core/napi_constructor_ref.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"
#include <mbgl/util/tileset.hpp>
#include <mbgl/util/range.hpp>
#include "napi/core/napi_wrap_instance.hpp"

#include "source_napi_utils.hpp"
using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

namespace mbgl {

using mbgl::harmony::napi::NapiArgs;
namespace harmony {

napi_ref RasterDemSourceNAPI::constructor = nullptr;
napi_env RasterDemSourceNAPI::constructorEnv = nullptr;

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
    
    napi_value cons = RegisterNapiClass(env, exports, "RasterDemSource", properties,
                                        sizeof(properties) / sizeof(properties[0]), New,
                                        constructor, constructorEnv, "RasterDemSourceNAPI");
    if (!cons) return nullptr;

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
        // Parse options argument using the shared tile-cache parser
        TileCacheOptions cacheOptions;
        std::optional<mbgl::style::SourceOptions> options = std::nullopt;

        // Get options object using NapiArgs
        napi_value optionsObj = napiArgs.GetObject(1, "options");
        if (!napiArgs.HasError() && optionsObj) {
            ParseTileCacheOptions(napiArgs, optionsObj, "RasterDemSourceNAPI", "RasterDemSource",
                                  /*tileSizeDefault=*/0, cacheOptions);

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

        std::optional<mbgl::Tileset::RasterEncoding> tileEncoding;
        if (options) {
            tileEncoding = options->rasterEncoding;
        }

        // Create the RasterDEMSource
        // Prefer the tiles array; fall back to the URL when tiles are absent
        auto urlOrTileset = MakeUrlOrTileset(cacheOptions, "RasterDemSourceNAPI", "RasterDemSource", tileEncoding);

        auto source = std::make_unique<mbgl::style::RasterDEMSource>(
            sourceId,
            std::move(urlOrTileset),
            cacheOptions.tileSize,
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
    return mbgl::harmony::WrapExistingInstance(env, constructor, Destructor, "RasterDemSource",
                                sourcePtr ? new RasterDemSourceNAPI(sourcePtr) : nullptr);
}

DEFINE_SOURCE_GET_ID(RasterDemSourceNAPI)

DEFINE_SOURCE_GET_URL(RasterDemSourceNAPI)

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

DEFINE_SOURCE_SET_TILE_SIZE_UNSUPPORTED(RasterDemSourceNAPI)

} // namespace harmony
} // namespace mbgl

