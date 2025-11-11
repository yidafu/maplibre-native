#include "raster_source_napi.hpp"
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

// Static member initialization
napi_ref RasterSourceNAPI::constructor = nullptr;

RasterSourceNAPI::RasterSourceNAPI(const std::string& id, std::unique_ptr<mbgl::style::RasterSource> source)
    : id(id), source(std::move(source)), ownsSource(true) {
    Logger::info("RasterSourceNAPI", "RasterSource instance created: %s", id.c_str());
}

RasterSourceNAPI::RasterSourceNAPI(mbgl::style::RasterSource* sourcePtr)
    : ownsSource(false) {
    if (sourcePtr) {
        id = sourcePtr->getID();
        weakSource = sourcePtr->makeWeakPtr();
        Logger::info("RasterSourceNAPI", "RasterSource created from existing source (WeakPtr): %s", id.c_str());
    }
}

RasterSourceNAPI::~RasterSourceNAPI() {
    // Reset weakSource before source is destroyed to avoid accessing invalidated WeakPtrFactory
    Logger::info("RasterSourceNAPI", "RasterSource instance destroyed: %s", id.c_str());
}

void RasterSourceNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    RasterSourceNAPI* sourceNapi = static_cast<RasterSourceNAPI*>(nativeObject);
    delete sourceNapi;
}

napi_value RasterSourceNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("RasterSourceNAPI", "Initializing RasterSource NAPI class");
    
    napi_property_descriptor properties[] = {
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getUrl", nullptr, GetUrl, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setUrl", nullptr, SetUrl, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setTileSize", nullptr, SetTileSize, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "RasterSource", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("RasterSourceNAPI", "Failed to define RasterSource class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("RasterSourceNAPI", "Failed to create constructor reference");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "RasterSource", cons);
    if (status != napi_ok) {
        Logger::error("RasterSourceNAPI", "Failed to set RasterSource property");
        return nullptr;
    }
    
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
        // Parse the options argument
        std::string url = "";
        std::vector<std::string> tiles;
        uint16_t tileSize = 512; // default value
        uint8_t minzoom = 0;
        uint8_t maxzoom = 22;
        
        if (args.Count() >= 2) {
            napi_value optionsObj = args.GetObject(1, "options");
            if (!args.HasError() && optionsObj) {
                // Read url
                url = args.GetStringProperty(optionsObj, "url", "");
                if (!url.empty()) {
                    Logger::info("RasterSourceNAPI", "RasterSource URL: %s", url.c_str());
                }
                
                // Read the tiles array
                napi_value tilesValue;
                napi_status status = napi_get_named_property(env, optionsObj, "tiles", &tilesValue);
                if (status == napi_ok) {
                    bool isArray;
                    napi_is_array(env, tilesValue, &isArray);
                    if (isArray) {
                        uint32_t length;
                        napi_get_array_length(env, tilesValue, &length);
                        for (uint32_t i = 0; i < length; i++) {
                            napi_value element;
                            napi_get_element(env, tilesValue, i, &element);
                            napi_valuetype elementType;
                            napi_typeof(env, element, &elementType);
                            if (elementType == napi_string) {
                                size_t strLen;
                                napi_get_value_string_utf8(env, element, nullptr, 0, &strLen);
                                if (strLen > 0) {
                                    char* buffer = new char[strLen + 1];
                                    napi_get_value_string_utf8(env, element, buffer, strLen + 1, nullptr);
                                    tiles.push_back(std::string(buffer));
                                    delete[] buffer;
                                }
                            }
                        }
                        if (!tiles.empty()) {
                            Logger::info("RasterSourceNAPI", "RasterSource tiles count: %zu", tiles.size());
                            Logger::info("RasterSourceNAPI", "RasterSource tiles[0]: %s", tiles[0].c_str());
                        }
                    }
                }
                
                // Read tileSize
                int32_t tileSizeInt = args.GetInt32Property(optionsObj, "tileSize", 512);
                if (tileSizeInt > 0) {
                    tileSize = static_cast<uint16_t>(tileSizeInt);
                    Logger::info("RasterSourceNAPI", "RasterSource tileSize: %d", tileSize);
                }
                
                // Read minzoom
                minzoom = static_cast<uint8_t>(args.GetInt32Property(optionsObj, "minzoom", 0));
                
                // Read maxzoom
                maxzoom = static_cast<uint8_t>(args.GetInt32Property(optionsObj, "maxzoom", 22));
            }
        }
        
        // Create the RasterSource
        // Prefer the tiles array; fall back to the URL when tiles are absent
        mbgl::variant<std::string, mbgl::Tileset> urlOrTileset;
        if (!tiles.empty()) {
            // Create a Tileset from the tiles array
            mbgl::Tileset tileset;
            tileset.tiles = tiles;
            tileset.zoomRange = mbgl::Range<uint8_t>(minzoom, maxzoom);
            urlOrTileset = std::move(tileset);
            Logger::info("RasterSourceNAPI", "RasterSource using Tileset with %zu tiles", tiles.size());
        } else {
            // Use the URL string
            urlOrTileset = url;
            Logger::info("RasterSourceNAPI", "RasterSource using URL: %s", url.c_str());
        }
        
        auto source = std::make_unique<mbgl::style::RasterSource>(
            sourceId,
            std::move(urlOrTileset),
            tileSize
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

napi_value RasterSourceNAPI::CreateInstance(napi_env env, mbgl::style::RasterSource* sourcePtr) {
    if (!sourcePtr) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Retrieve the constructor
    napi_value cons;
    napi_status status = napi_get_reference_value(env, constructor, &cons);
    if (status != napi_ok) {
        Logger::error("RasterSourceNAPI", "Failed to get constructor reference");
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
    RasterSourceNAPI* napiObj = new RasterSourceNAPI(sourcePtr);
    
    // Wrap into the JS object
    status = napi_wrap(env, instance, napiObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete napiObj;
        Logger::error("RasterSourceNAPI", "Failed to wrap instance");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // Add the _TYPE_ property
    napi_value typeValue;
    napi_create_string_utf8(env, "RasterSource", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, instance, "_TYPE_", typeValue);
    
    return instance;
}

napi_value RasterSourceNAPI::GetId(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    RasterSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        return CreateStringValue(env, "");
    }
    
    return CreateStringValue(env, sourceNapi->id);
}

napi_value RasterSourceNAPI::GetUrl(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    
    RasterSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&sourceNapi));
    
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
        Logger::error("RasterSourceNAPI", "GetUrl failed: %s", e.what());
    }
    
    return CreateStringValue(env, "");
}

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
        mbgl::variant<std::string, mbgl::Tileset> urlOrTileset = url;
        auto newSource = std::make_unique<mbgl::style::RasterSource>(
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

napi_value RasterSourceNAPI::SetTileSize(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    RasterSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, args.This(), reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        napi_throw_error(env, nullptr, "Invalid source wrapper");
        return nullptr;
    }
    
    auto* source = sourceNapi->getSource();
    if (!source) {
        napi_throw_error(env, nullptr, "Invalid source");
        return nullptr;
    }
    
    uint32_t tileSize = args.GetUint32(0, "tileSize");
    if (args.HasError()) return nullptr;
    
    if (tileSize == 0 || tileSize > 1024) {
        napi_throw_error(env, nullptr, "Invalid tile size (must be between 1 and 1024)");
        return nullptr;
    }
    
    // Note: RasterSource does not support changing tile size after creation.
    // Tile size must be specified in the constructor.
    Logger::info("RasterSourceNAPI", "SetTileSize not supported - tile size is immutable after source creation");
    napi_throw_error(env, nullptr, "RasterSource does not support changing tile size after creation. Please recreate the source with the desired tile size.");
    return nullptr;
}

} // namespace harmony
} // namespace maplibre

