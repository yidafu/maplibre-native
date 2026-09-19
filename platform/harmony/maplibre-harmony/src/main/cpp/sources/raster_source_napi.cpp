#include "raster_source_napi.hpp"
#include "napi/core/napi_constructor_ref.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"
#include <mln/util/tileset.hpp>
#include <mln/util/range.hpp>
#include "napi/core/napi_wrap_instance.hpp"

#include "source_napi_utils.hpp"
using namespace mln::harmony::napi;
using mln::harmony::Logger;

namespace mln {

using mln::harmony::napi::NapiArgs;
namespace harmony {

// Static member initialization
napi_ref RasterSourceNAPI::constructor = nullptr;
napi_env RasterSourceNAPI::constructorEnv = nullptr;

RasterSourceNAPI::RasterSourceNAPI(const std::string& id, std::unique_ptr<mln::style::RasterSource> source)
    : SourceNapiBase(id, std::move(source)) {
    Logger::info("RasterSourceNAPI", "RasterSource instance created: %s", id.c_str());
}

RasterSourceNAPI::RasterSourceNAPI(mln::style::RasterSource* sourcePtr)
    : SourceNapiBase(sourcePtr) {
    if (sourcePtr) {
        Logger::info("RasterSourceNAPI", "RasterSource created from existing source (WeakPtr): %s", id.c_str());
    }
}

RasterSourceNAPI::~RasterSourceNAPI() {
    // Reset weakSource before source is destroyed to avoid accessing invalidated WeakPtrFactory
    Logger::info("RasterSourceNAPI", "RasterSource instance destroyed: %s", id.c_str());
}

DEFINE_SOURCE_DESTRUCTOR(RasterSourceNAPI)

napi_value RasterSourceNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("RasterSourceNAPI", "Initializing RasterSource NAPI class");
    
    napi_property_descriptor properties[] = {
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getUrl", nullptr, GetUrl, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setUrl", nullptr, SetUrl, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTileSize", nullptr, SetTileSize, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons = RegisterNapiClass(env, exports, "RasterSource", properties,
                                        sizeof(properties) / sizeof(properties[0]), New,
                                        constructor, constructorEnv, "RasterSourceNAPI");
    if (!cons) return nullptr;

    Logger::info("RasterSourceNAPI", "RasterSource NAPI class initialized successfully");
    return exports;
}

napi_value RasterSourceNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    std::string sourceId = args.GetString(0, "sourceId");
    if (args.HasError()) {
        napi_throw_error(env, nullptr, "Failed to parse sourceId");
        return nullptr;
    }
    
    try {
        // Parse the options argument (shared with RasterDemSourceNAPI)
        TileCacheOptions cacheOptions;
        if (args.Count() >= 2) {
            napi_value optionsObj = args.GetObject(1, "options");
            if (!args.HasError() && optionsObj) {
                ParseTileCacheOptions(args, optionsObj, "RasterSourceNAPI", "RasterSource",
                                      /*tileSizeDefault=*/512, cacheOptions);
            }
        }

        // Create the RasterSource:
        // Prefer the tiles array; fall back to the URL when tiles are absent
        auto urlOrTileset = MakeUrlOrTileset(cacheOptions, "RasterSourceNAPI", "RasterSource");

        auto source = std::make_unique<mln::style::RasterSource>(
            sourceId,
            std::move(urlOrTileset),
            cacheOptions.tileSize
        );
        
        RasterSourceNAPI* sourceNapi = new RasterSourceNAPI(sourceId, std::move(source));
        
        napi_status status = napi_wrap(env, args.This(), sourceNapi, Destructor, nullptr, nullptr);
        if (status != napi_ok) {
            delete sourceNapi;
            napi_throw_error(env, nullptr, "Failed to wrap RasterSource object");
            return nullptr;
        }
        
        Logger::info("RasterSourceNAPI", "RasterSource created: %s", sourceId.c_str());
    
    // Add the _TYPE_ property for ETS type detection
    napi_value typeValue;
    napi_create_string_utf8(env, "RasterSource", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, args.This(), "_TYPE_", typeValue);
        return args.This();
    } catch (const std::exception& e) {
        Logger::error("RasterSourceNAPI", "Failed to create RasterSource: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

DEFINE_SOURCE_CREATE_INSTANCE(RasterSourceNAPI, "RasterSource", mln::style::RasterSource)

DEFINE_SOURCE_GET_ID(RasterSourceNAPI)

DEFINE_SOURCE_GET_URL(RasterSourceNAPI)

napi_value RasterSourceNAPI::SetUrl(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    RasterSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        napi_throw_error(env, nullptr, "Invalid source wrapper");
        return nullptr;
    }
    
    std::string url = args.GetString(0, "url");
    if (args.HasError()) return nullptr;
    
    auto* ownedSource = sourceNapi->source.get();
    if (!ownedSource) {
        napi_throw_error(env, nullptr, "RasterSource URL cannot be changed after adding to the map style");
        return nullptr;
    }
    
    const uint16_t tileSize = ownedSource->getTileSize();
    
    try {
        mln::variant<std::string, mln::Tileset> urlOrTileset = url;
        auto newSource = std::make_unique<mln::style::RasterSource>(
            sourceNapi->id,
            std::move(urlOrTileset),
            tileSize
        );
        sourceNapi->source = std::move(newSource);
        Logger::info("RasterSourceNAPI", "RasterSource recreated with new URL: %s -> %s",
                     sourceNapi->id.c_str(), url.c_str());
    } catch (const std::exception& e) {
        Logger::error("RasterSourceNAPI", "SetUrl failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
    }
    
    return nullptr;
}

DEFINE_SOURCE_SET_TILE_SIZE_UNSUPPORTED(RasterSourceNAPI)

} // namespace harmony
} // namespace mln

