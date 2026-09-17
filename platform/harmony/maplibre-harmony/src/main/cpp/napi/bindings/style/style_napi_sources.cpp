#include "style_napi.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"
#include <mbgl/style/style.hpp>
#include <mbgl/style/source.hpp>
#include <mbgl/style/sources/geojson_source.hpp>
#include <mbgl/style/sources/vector_source.hpp>
#include <mbgl/style/sources/raster_source.hpp>
#include <mbgl/style/sources/raster_dem_source.hpp>
#include <mbgl/style/sources/image_source.hpp>
// Source NAPI classes
#include "sources/geojson_source_napi.hpp"
#include "sources/vector_source_napi.hpp"
#include "sources/raster_source_napi.hpp"
#include "sources/raster_dem_source_napi.hpp"
#include "sources/image_source_napi.hpp"
#include "sources/custom_geometry_source_napi.hpp"
#include <mbgl/style/sources/custom_geometry_source.hpp>

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

// ==================== Source management ====================

napi_value StyleNAPI::RemoveSource(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(1);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value jsThis = napiArgs.This();
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (!style || !style->acquireMap()) {
        Logger::error("StyleNAPI", "RemoveSource: Invalid style or map");
        napi_throw_error(env, nullptr, "Invalid style instance");
        return nullptr;
    }
    
    std::string sourceId = GetStringFromValue(env, napiArgs.GetValue(0));
    if (napiArgs.HasError()) {
        return nullptr;
    }
    if (sourceId.empty()) {
        napi_throw_error(env, nullptr, "sourceId cannot be empty");
        return nullptr;
    }
    
    try {
        bool removed = false;
        style->runOnMap([&](mbgl::Map& m) {
            if (m.getStyle().getSource(sourceId)) {
                m.getStyle().removeSource(sourceId);
                removed = true;
            }
        });
        if (!removed) {
            Logger::error("StyleNAPI", "RemoveSource: Source not found: %s", sourceId.c_str());
            napi_throw_error(env, nullptr, "Source not found");
            return nullptr;
        }
        style->sources.erase(sourceId);

        Logger::info("StyleNAPI", "RemoveSource: %s", sourceId.c_str());

        return napiArgs.Undefined();
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "RemoveSource failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value StyleNAPI::GetSource(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    napiArgs.RequireMinArgs(1);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value jsThis = napiArgs.This();
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (!style || !style->acquireMap()) {
        Logger::error("StyleNAPI", "GetSource: Invalid style or map");
        return napiArgs.Null();
    }
    
    std::string sourceId = GetStringFromValue(env, napiArgs.GetValue(0));
    if (napiArgs.HasError()) {
        return nullptr;
    }
    if (sourceId.empty()) {
        napi_throw_error(env, nullptr, "sourceId cannot be empty");
        return nullptr;
    }
    
    // Resolve the source on the render thread; the NAPI peer is built below.
    mbgl::style::Source* source = nullptr;
    try {
        style->runOnMap([&](mbgl::Map& m) {
            source = m.getStyle().getSource(sourceId);
        });
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "GetSource failed: %s", e.what());
        source = nullptr;
    }

    if (!source) {
        Logger::info("StyleNAPI", "GetSource: Source not found: %s", sourceId.c_str());
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }

    {
        // Create the corresponding NAPI instance based on the source type
        Logger::info("StyleNAPI", "GetSource: %s (type: %d)", sourceId.c_str(), static_cast<int>(source->getType()));

        switch (source->getType()) {
            case mbgl::style::SourceType::GeoJSON: {
                auto* geoJsonSource = static_cast<mbgl::style::GeoJSONSource*>(source);
                return mbgl::harmony::GeoJsonSourceNAPI::CreateInstance(env, geoJsonSource);
            }
            case mbgl::style::SourceType::Vector: {
                auto* vectorSource = static_cast<mbgl::style::VectorSource*>(source);
                return mbgl::harmony::VectorSourceNAPI::CreateInstance(env, vectorSource);
            }
            case mbgl::style::SourceType::Raster: {
                auto* rasterSource = static_cast<mbgl::style::RasterSource*>(source);
                return mbgl::harmony::RasterSourceNAPI::CreateInstance(env, rasterSource);
            }
            case mbgl::style::SourceType::RasterDEM: {
                auto* rasterDemSource = static_cast<mbgl::style::RasterDEMSource*>(source);
                return mbgl::harmony::RasterDemSourceNAPI::CreateInstance(env, rasterDemSource);
            }
            case mbgl::style::SourceType::Image: {
                auto* imageSource = static_cast<mbgl::style::ImageSource*>(source);
                return mbgl::harmony::ImageSourceNAPI::CreateInstance(env, imageSource);
            }
            case mbgl::style::SourceType::CustomVector: {
                auto* customGeometrySource = static_cast<mbgl::style::CustomGeometrySource*>(source);
                return mbgl::harmony::CustomGeometrySourceNAPI::CreateInstance(env, customGeometrySource);
            }
            default:
                Logger::warn("StyleNAPI", "GetSource: Unknown source type: %d", static_cast<int>(source->getType()));
                return napiArgs.Null();
        }
    }
}

napi_value StyleNAPI::GetSources(napi_env env, napi_callback_info info) {
    NapiArgs napiArgs(env, info);
    if (napiArgs.HasError()) {
        return nullptr;
    }

    napi_value jsThis = napiArgs.This();
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (!style || !style->acquireMap()) {
        Logger::error("StyleNAPI", "GetSources: Invalid style or map");
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
    
    try {
        // Snapshot the source list on the render thread
        std::vector<mbgl::style::Source*> sourceList;
        style->runOnMap([&](mbgl::Map& m) {
            const auto& sources = m.getStyle().getSources();
            sourceList.reserve(sources.size());
            for (const auto& source : sources) {
                sourceList.push_back(source);
            }
        });

        // Create the result array
        napi_value result;
        napi_create_array_with_length(env, sourceList.size(), &result);

        size_t index = 0;
        for (const auto& source : sourceList) {
            if (!source) continue;
            
            // Create the source info object
            napi_value sourceObj;
            napi_create_object(env, &sourceObj);
            
            napi_value idValue = CreateStringValue(env, source->getID());
            napi_set_named_property(env, sourceObj, "id", idValue);
            
            // Determine the source type
            std::string typeStr;
            switch (source->getType()) {
                case mbgl::style::SourceType::Vector:
                    typeStr = "vector";
                    break;
                case mbgl::style::SourceType::Raster:
                    typeStr = "raster";
                    break;
                case mbgl::style::SourceType::RasterDEM:
                    typeStr = "raster-dem";
                    break;
                case mbgl::style::SourceType::GeoJSON:
                    typeStr = "geojson";
                    break;
                case mbgl::style::SourceType::Image:
                    typeStr = "image";
                    break;
                case mbgl::style::SourceType::CustomVector:
                    typeStr = "custom-vector";
                    break;
                default:
                    typeStr = "unknown";
                    break;
            }
            
            napi_value typeValue = CreateStringValue(env, typeStr);
            napi_set_named_property(env, sourceObj, "type", typeValue);
            
            napi_set_element(env, result, index++, sourceObj);
        }
        
        return result;
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "GetSources failed: %s", e.what());
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
}

} // namespace harmony
} // namespace mbgl

