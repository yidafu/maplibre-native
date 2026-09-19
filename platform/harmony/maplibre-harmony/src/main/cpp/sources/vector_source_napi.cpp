#include "vector_source_napi.hpp"
#include "napi/core/napi_constructor_ref.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"
#include "napi/core/napi_wrap_instance.hpp"

#include "source_napi_utils.hpp"
using namespace mln::harmony::napi;
using mln::harmony::Logger;

namespace mln {

using mln::harmony::napi::NapiArgs;
namespace harmony {

// Static member initialization
napi_ref VectorSourceNAPI::constructor = nullptr;
napi_env VectorSourceNAPI::constructorEnv = nullptr;

VectorSourceNAPI::VectorSourceNAPI(const std::string& id, std::unique_ptr<mln::style::VectorSource> source)
    : SourceNapiBase(id, std::move(source)) {
    Logger::info("VectorSourceNAPI", "VectorSource instance created: %s", id.c_str());
}

VectorSourceNAPI::VectorSourceNAPI(mln::style::VectorSource* sourcePtr)
    : SourceNapiBase(sourcePtr) {
    if (sourcePtr) {
        Logger::info("VectorSourceNAPI", "VectorSource created from existing source (WeakPtr): %s", id.c_str());
    }
}

VectorSourceNAPI::~VectorSourceNAPI() {
    // Reset weakSource before source is destroyed to avoid accessing invalidated WeakPtrFactory
    Logger::info("VectorSourceNAPI", "VectorSource instance destroyed: %s", id.c_str());
}

DEFINE_SOURCE_DESTRUCTOR(VectorSourceNAPI)

napi_value VectorSourceNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("VectorSourceNAPI", "Initializing VectorSource NAPI class");
    
    napi_property_descriptor properties[] = {
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getUrl", nullptr, GetUrl, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setUrl", nullptr, SetUrl, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTiles", nullptr, SetTiles, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons = RegisterNapiClass(env, exports, "VectorSource", properties,
                                        sizeof(properties) / sizeof(properties[0]), New,
                                        constructor, constructorEnv, "VectorSourceNAPI");
    if (!cons) return nullptr;

    Logger::info("VectorSourceNAPI", "VectorSource NAPI class initialized successfully");
    return exports;
}

napi_value VectorSourceNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    std::string sourceId = args.GetString(0, "sourceId");
    if (args.HasError()) {
        napi_throw_error(env, nullptr, "Failed to parse sourceId");
        return nullptr;
    }
    
    try {
        // VectorSource requires a urlOrTileset parameter.
        // Use an empty string by default; setURL can update it later.
        mln::variant<std::string, mln::Tileset> urlOrTileset = std::string("");
        auto source = std::make_unique<mln::style::VectorSource>(
            sourceId,
            std::move(urlOrTileset)
        );
        
        VectorSourceNAPI* sourceNapi = new VectorSourceNAPI(sourceId, std::move(source));
        
        napi_status status = napi_wrap(env, args.This(), sourceNapi, Destructor, nullptr, nullptr);
        if (status != napi_ok) {
            delete sourceNapi;
            napi_throw_error(env, nullptr, "Failed to wrap VectorSource object");
            return nullptr;
        }
        
        Logger::info("VectorSourceNAPI", "VectorSource created: %s", sourceId.c_str());
    
    // Add a _TYPE_ property to help ETS perform type checks
    napi_value typeValue;
    napi_create_string_utf8(env, "VectorSource", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, args.This(), "_TYPE_", typeValue);
        return args.This();
    } catch (const std::exception& e) {
        Logger::error("VectorSourceNAPI", "Failed to create VectorSource: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

DEFINE_SOURCE_CREATE_INSTANCE(VectorSourceNAPI, "VectorSource", mln::style::VectorSource)

DEFINE_SOURCE_GET_ID(VectorSourceNAPI)

DEFINE_SOURCE_GET_URL(VectorSourceNAPI)

napi_value VectorSourceNAPI::SetUrl(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    VectorSourceNAPI* sourceNapi = nullptr;
    auto* source = ResolveSource(env, args.This(), &sourceNapi, true);
    if (!source) {
        return nullptr;
    }
    
    std::string url = args.GetString(0, "url");
    if (args.HasError()) return nullptr;
    
    // VectorSource exposes setTiles
    try {
        source->setTiles({url});
        Logger::info("VectorSourceNAPI", "SetUrl: %s -> %s", sourceNapi->id.c_str(), url.c_str());
    } catch (const std::exception& e) {
        Logger::error("VectorSourceNAPI", "SetUrl failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
    }
    
    return nullptr;
}

napi_value VectorSourceNAPI::SetTiles(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    VectorSourceNAPI* sourceNapi = nullptr;
    auto* source = ResolveSource(env, args.This(), &sourceNapi, true);
    if (!source) {
        return nullptr;
    }
    
    // Parse the tiles array through the shared string-array reader; strict
    // mode keeps the historical error for non-string elements.
    napi_value tilesArray = args.GetArray(0, "tiles");
    if (args.HasError()) return nullptr;

    std::vector<std::string> tiles;
    if (!ReadStringArray(args, tilesArray, tiles, /*strict=*/true)) {
        napi_throw_error(env, nullptr, "tiles must be an array of strings");
        return nullptr;
    }
    
    try {
        // Update tiles
        source->setTiles(tiles);
        Logger::info("VectorSourceNAPI", "SetTiles: %s (%zu tiles)", sourceNapi->id.c_str(), tiles.size());
    } catch (const std::exception& e) {
        Logger::error("VectorSourceNAPI", "SetTiles failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
    
    return nullptr;
}

} // namespace harmony
} // namespace mln

