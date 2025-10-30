#include "style_napi.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"
#include <mbgl/style/style.hpp>
#include <mbgl/style/source.hpp>

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;

namespace maplibre {
namespace harmony {

// ==================== Source 管理 ====================

napi_value StyleNAPI::RemoveSource(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (!style || !style->map) {
        Logger::error("StyleNAPI", "RemoveSource: Invalid style or map");
        napi_throw_error(env, nullptr, "Invalid style instance");
        return nullptr;
    }
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "RemoveSource requires sourceId argument");
        return nullptr;
    }
    
    // 获取 sourceId
    std::string sourceId = GetStringFromValue(env, args[0]);
    if (sourceId.empty()) {
        napi_throw_error(env, nullptr, "sourceId cannot be empty");
        return nullptr;
    }
    
    try {
        // 从样式中移除 source
        mbgl::style::Source* source = style->map->getStyle().getSource(sourceId);
        if (!source) {
            Logger::error("StyleNAPI", "RemoveSource: Source not found: %s", sourceId.c_str());
            napi_throw_error(env, nullptr, "Source not found");
            return nullptr;
        }
        
        style->map->getStyle().removeSource(sourceId);
        style->sources.erase(sourceId);
        
        Logger::info("StyleNAPI", "RemoveSource: %s", sourceId.c_str());
        
        napi_value result;
        napi_get_undefined(env, &result);
        return result;
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "RemoveSource failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value StyleNAPI::GetSource(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (!style || !style->map) {
        Logger::error("StyleNAPI", "GetSource: Invalid style or map");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "GetSource requires sourceId argument");
        return nullptr;
    }
    
    // 获取 sourceId
    std::string sourceId = GetStringFromValue(env, args[0]);
    if (sourceId.empty()) {
        napi_throw_error(env, nullptr, "sourceId cannot be empty");
        return nullptr;
    }
    
    try {
        // 从样式获取 source
        mbgl::style::Source* source = style->map->getStyle().getSource(sourceId);
        if (!source) {
            Logger::info("StyleNAPI", "GetSource: Source not found: %s", sourceId.c_str());
            napi_value result;
            napi_get_null(env, &result);
            return result;
        }
        
        // TODO: 返回对应的 Source NAPI wrapper
        // 目前返回一个简单的对象，包含基本信息
        napi_value result;
        napi_create_object(env, &result);
        
        napi_value idValue = CreateStringValue(env, source->getID());
        napi_set_named_property(env, result, "id", idValue);
        
        // 获取 source 类型
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
            default:
                typeStr = "unknown";
                break;
        }
        
        napi_value typeValue = CreateStringValue(env, typeStr);
        napi_set_named_property(env, result, "type", typeValue);
        
        return result;
    } catch (const std::exception& e) {
        Logger::error("StyleNAPI", "GetSource failed: %s", e.what());
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
}

napi_value StyleNAPI::GetSources(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    StyleNAPI* style = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&style));
    
    if (!style || !style->map) {
        Logger::error("StyleNAPI", "GetSources: Invalid style or map");
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
    
    try {
        // 获取所有 sources
        const auto& sources = style->map->getStyle().getSources();
        
        // 创建结果数组
        napi_value result;
        napi_create_array_with_length(env, sources.size(), &result);
        
        size_t index = 0;
        for (const auto& source : sources) {
            if (!source) continue;
            
            // 创建 source 信息对象
            napi_value sourceObj;
            napi_create_object(env, &sourceObj);
            
            napi_value idValue = CreateStringValue(env, source->getID());
            napi_set_named_property(env, sourceObj, "id", idValue);
            
            // 获取 source 类型
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
} // namespace maplibre

