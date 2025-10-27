#include "geojson_source_napi.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"
#include "geojson/geometry_napi.hpp"
#include "geojson/feature_napi.hpp"
#include "geojson/feature_collection_napi.hpp"
#include "geojson/util.hpp"
#include <mbgl/style/conversion/json.hpp>
#include <mbgl/style/conversion/geojson.hpp>
#include <mbgl/style/conversion/geojson_options.hpp>
#include <mbgl/util/geojson.hpp>

using namespace mbgl::harmony::napi;
using mbgl::harmony::Logger;
using namespace maplibre::harmony::geojson;

namespace maplibre {
namespace harmony {

// Static member initialization
napi_ref GeoJsonSourceNAPI::constructor = nullptr;

GeoJsonSourceNAPI::GeoJsonSourceNAPI(const std::string& id, std::unique_ptr<mbgl::style::GeoJSONSource> source)
    : id(id), source(std::move(source)), ownsSource(true) {
    Logger::info("GeoJsonSourceNAPI", "GeoJsonSource instance created: %s", id.c_str());
}

GeoJsonSourceNAPI::~GeoJsonSourceNAPI() {
    Logger::info("GeoJsonSourceNAPI", "GeoJsonSource instance destroyed: %s", id.c_str());
}

void GeoJsonSourceNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    Logger::debug("GeoJsonSourceNAPI", "Destructor called");
    GeoJsonSourceNAPI* sourceNapi = static_cast<GeoJsonSourceNAPI*>(nativeObject);
    delete sourceNapi;
}

napi_value GeoJsonSourceNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("GeoJsonSourceNAPI", "Initializing GeoJsonSource NAPI class");
    
    napi_property_descriptor properties[] = {
        // Getters
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // 数据管理
        { "setGeoJson", nullptr, SetGeoJson, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setGeoJsonSync", nullptr, SetGeoJsonSync, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setUrl", nullptr, SetUrl, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getUrl", nullptr, GetUrl, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // 查询功能
        { "querySourceFeatures", nullptr, QuerySourceFeatures, nullptr, nullptr, nullptr, napi_default, nullptr },
        
        // 聚类功能
        { "getClusterChildren", nullptr, GetClusterChildren, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getClusterLeaves", nullptr, GetClusterLeaves, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getClusterExpansionZoom", nullptr, GetClusterExpansionZoom, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "GeoJsonSource", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("GeoJsonSourceNAPI", "Failed to define GeoJsonSource class");
        return nullptr;
    }
    
    // 创建构造函数引用
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("GeoJsonSourceNAPI", "Failed to create constructor reference");
        return nullptr;
    }
    
    // 将构造函数添加到 exports
    status = napi_set_named_property(env, exports, "GeoJsonSource", cons);
    if (status != napi_ok) {
        Logger::error("GeoJsonSourceNAPI", "Failed to set GeoJsonSource property");
        return nullptr;
    }
    
    Logger::info("GeoJsonSourceNAPI", "GeoJsonSource NAPI class initialized successfully");
    return exports;
}

napi_value GeoJsonSourceNAPI::New(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "GeoJsonSource requires sourceId argument");
        return nullptr;
    }
    
    // 解析参数
    NapiArgs napiArgs(env, info);
    std::string sourceId = napiArgs.GetString(0, "sourceId");
    
    if (napiArgs.HasError()) {
        napi_throw_error(env, nullptr, "Failed to parse sourceId");
        return nullptr;
    }
    
    try {
        // 解析选项
        mbgl::Immutable<mbgl::style::GeoJSONOptions> options = mbgl::style::GeoJSONOptions::defaultOptions();
        
        if (argc >= 2) {
            // TODO: 解析 options 对象
            // 暂时使用默认选项
            Logger::debug("GeoJsonSourceNAPI", "Options parsing not yet implemented, using defaults");
        }
        
        // 创建 GeoJSONSource
        auto source = std::make_unique<mbgl::style::GeoJSONSource>(sourceId, std::move(options));
        
        // 创建 C++ NAPI 对象
        GeoJsonSourceNAPI* sourceNapi = new GeoJsonSourceNAPI(sourceId, std::move(source));
        
        // Wrap 到 JS 对象
        napi_status status = napi_wrap(env, jsThis, sourceNapi, Destructor, nullptr, nullptr);
        if (status != napi_ok) {
            delete sourceNapi;
            napi_throw_error(env, nullptr, "Failed to wrap GeoJsonSource object");
            return nullptr;
        }
        
        Logger::info("GeoJsonSourceNAPI", "GeoJsonSource created: %s", sourceId.c_str());
        return jsThis;
    } catch (const std::exception& e) {
        Logger::error("GeoJsonSourceNAPI", "Failed to create GeoJsonSource: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

// ==================== Getters ====================

napi_value GeoJsonSourceNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    GeoJsonSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        return CreateStringValue(env, "");
    }
    
    return CreateStringValue(env, sourceNapi->id);
}

// ==================== 数据管理 ====================

napi_value GeoJsonSourceNAPI::SetGeoJson(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    GeoJsonSourceNAPI* sourceNapi = nullptr;
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
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "SetGeoJson requires data argument");
        return nullptr;
    }
    
    try {
        // 检测参数类型
        if (IsString(env, args[0])) {
            // 字符串类型：解析 JSON
            NapiArgs napiArgs(env, info);
            std::string geoJsonString = napiArgs.GetString(0, "geoJson");
            
            if (napiArgs.HasError()) {
                return nullptr;
            }
            
            mbgl::style::conversion::Error error;
            auto geoJson = mbgl::style::conversion::convertJSON<mbgl::GeoJSON>(geoJsonString, error);
            
            if (geoJson) {
                source->setGeoJSON(std::move(*geoJson));
                Logger::info("GeoJsonSourceNAPI", "SetGeoJson (string): %s", sourceNapi->id.c_str());
            } else {
                napi_throw_error(env, nullptr, error.message.c_str());
            }
        } else if (IsObject(env, args[0])) {
            // 对象类型：根据 type 属性判断
            std::string type;
            if (HasProperty(env, args[0], "type")) {
                type = GetStringProperty(env, args[0], "type");
            }
            
            if (type == "FeatureCollection") {
                // FeatureCollection 对象
                auto features = FeatureCollectionNAPI::convert(env, args[0]);
                mbgl::FeatureCollection collection;
                collection.reserve(features.size());
                
                for (auto& feature : features) {
                    mbgl::Feature f;
                    f.geometry = std::move(feature.geometry);
                    f.properties = std::move(feature.properties);
                    f.id = feature.id;
                    collection.push_back(std::move(f));
                }
                
                source->setGeoJSON(mbgl::GeoJSON{std::move(collection)});
                Logger::info("GeoJsonSourceNAPI", "SetGeoJson (FeatureCollection): %s", sourceNapi->id.c_str());
            } else if (type == "Feature") {
                // Feature 对象
                auto feature = FeatureNAPI::convert(env, args[0]);
                source->setGeoJSON(mbgl::GeoJSON{std::move(feature)});
                Logger::info("GeoJsonSourceNAPI", "SetGeoJson (Feature): %s", sourceNapi->id.c_str());
            } else {
                // Geometry 对象
                auto geometry = GeometryNAPI::convert(env, args[0]);
                source->setGeoJSON(mbgl::GeoJSON{std::move(geometry)});
                Logger::info("GeoJsonSourceNAPI", "SetGeoJson (Geometry): %s, type: %s", 
                           sourceNapi->id.c_str(), type.c_str());
            }
        } else {
            napi_throw_error(env, nullptr, "GeoJson data must be a string or object");
        }
    } catch (const std::exception& e) {
        Logger::error("GeoJsonSourceNAPI", "SetGeoJson failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
    }
    
    return nullptr;
}

napi_value GeoJsonSourceNAPI::SetGeoJsonSync(napi_env env, napi_callback_info info) {
    // 同步版本与异步版本相同
    return SetGeoJson(env, info);
}

napi_value GeoJsonSourceNAPI::SetUrl(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    GeoJsonSourceNAPI* sourceNapi = nullptr;
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
    
    NapiArgs args(env, info);
    std::string url = args.GetString(0, "url");
    
    if (args.HasError()) {
        return nullptr;
    }
    
    try {
        source->setURL(url);
        Logger::info("GeoJsonSourceNAPI", "SetUrl: %s -> %s", sourceNapi->id.c_str(), url.c_str());
    } catch (const std::exception& e) {
        Logger::error("GeoJsonSourceNAPI", "SetUrl failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
    }
    
    return nullptr;
}

napi_value GeoJsonSourceNAPI::GetUrl(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    GeoJsonSourceNAPI* sourceNapi = nullptr;
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
        Logger::error("GeoJsonSourceNAPI", "GetUrl failed: %s", e.what());
    }
    
    return CreateStringValue(env, "");
}

// ==================== 查询功能 ====================

napi_value GeoJsonSourceNAPI::QuerySourceFeatures(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    GeoJsonSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi) {
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
    
    auto* source = sourceNapi->getSource();
    if (!source) {
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
    
    try {
        // TODO: 需要访问 rendererFrontend 来查询要素
        // 类似 Android 实现：
        // features = rendererFrontend->querySourceFeatures(source.getID(), {{}, filter});
        
        // 暂时返回空数组
        Logger::warn("GeoJsonSourceNAPI", "QuerySourceFeatures: rendererFrontend access not yet implemented");
        
        std::vector<mbgl::Feature> features;
        // 这里需要从 rendererFrontend 获取 features
        
        // 将结果转换为 NAPI 数组
        return FeatureNAPI::NewArray(env, features);
    } catch (const std::exception& e) {
        Logger::error("GeoJsonSourceNAPI", "QuerySourceFeatures failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
}

// ==================== 聚类功能 ====================

napi_value GeoJsonSourceNAPI::GetClusterChildren(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    GeoJsonSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi || !sourceNapi->source) {
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "GetClusterChildren requires clusterId or feature argument");
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
    
    try {
        // 解析 clusterId（可以是数字或 Feature 对象）
        uint64_t clusterId = 0;
        
        if (IsNumber(env, args[0])) {
            double value = 0;
            napi_get_value_double(env, args[0], &value);
            clusterId = static_cast<uint64_t>(value);
        } else if (IsObject(env, args[0])) {
            // Feature 对象，从 properties 中提取 cluster_id
            auto feature = FeatureNAPI::convert(env, args[0]);
            if (feature.properties.count("cluster_id")) {
                auto& idValue = feature.properties["cluster_id"];
                if (idValue.is<double>()) {
                    clusterId = static_cast<uint64_t>(idValue.get<double>());
                } else if (idValue.is<uint64_t>()) {
                    clusterId = idValue.get<uint64_t>();
                }
            }
        }
        
        // TODO: 需要访问 rendererFrontend 来查询聚类子项
        // 类似 Android 实现：
        // featureExtension = rendererFrontend->queryFeatureExtensions(
        //     source.getID(), feature, "supercluster", "children", {});
        
        Logger::warn("GeoJsonSourceNAPI", "GetClusterChildren: rendererFrontend access not yet implemented (clusterId: %llu)", 
                    clusterId);
        
        std::vector<mbgl::Feature> features;
        return FeatureNAPI::NewArray(env, features);
    } catch (const std::exception& e) {
        Logger::error("GeoJsonSourceNAPI", "GetClusterChildren failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
}

napi_value GeoJsonSourceNAPI::GetClusterLeaves(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 3;
    napi_value args[3];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    GeoJsonSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi || !sourceNapi->source) {
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
    
    if (argc < 3) {
        napi_throw_error(env, nullptr, "GetClusterLeaves requires clusterId, limit, and offset arguments");
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
    
    try {
        // 解析参数
        uint64_t clusterId = 0;
        if (IsNumber(env, args[0])) {
            double value = 0;
            napi_get_value_double(env, args[0], &value);
            clusterId = static_cast<uint64_t>(value);
        } else if (IsObject(env, args[0])) {
            auto feature = FeatureNAPI::convert(env, args[0]);
            if (feature.properties.count("cluster_id")) {
                auto& idValue = feature.properties["cluster_id"];
                if (idValue.is<double>()) {
                    clusterId = static_cast<uint64_t>(idValue.get<double>());
                } else if (idValue.is<uint64_t>()) {
                    clusterId = idValue.get<uint64_t>();
                }
            }
        }
        
        double limitValue = 10, offsetValue = 0;
        napi_get_value_double(env, args[1], &limitValue);
        napi_get_value_double(env, args[2], &offsetValue);
        
        uint64_t limit = static_cast<uint64_t>(limitValue);
        uint64_t offset = static_cast<uint64_t>(offsetValue);
        
        // TODO: 需要访问 rendererFrontend 来查询聚类叶子节点
        // 类似 Android 实现：
        // options = {{"limit", limit}, {"offset", offset}};
        // featureExtension = rendererFrontend->queryFeatureExtensions(
        //     source.getID(), feature, "supercluster", "leaves", options);
        
        Logger::warn("GeoJsonSourceNAPI", 
                    "GetClusterLeaves: rendererFrontend access not yet implemented (clusterId: %llu, limit: %llu, offset: %llu)", 
                    clusterId, limit, offset);
        
        std::vector<mbgl::Feature> features;
        return FeatureNAPI::NewArray(env, features);
    } catch (const std::exception& e) {
        Logger::error("GeoJsonSourceNAPI", "GetClusterLeaves failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        napi_value result;
        napi_create_array(env, &result);
        return result;
    }
}

napi_value GeoJsonSourceNAPI::GetClusterExpansionZoom(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    GeoJsonSourceNAPI* sourceNapi = nullptr;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&sourceNapi));
    
    if (!sourceNapi || !sourceNapi->source) {
        return CreateDoubleValue(env, 0.0);
    }
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "GetClusterExpansionZoom requires clusterId or feature argument");
        return CreateDoubleValue(env, 0.0);
    }
    
    try {
        // 解析 clusterId
        uint64_t clusterId = 0;
        if (IsNumber(env, args[0])) {
            double value = 0;
            napi_get_value_double(env, args[0], &value);
            clusterId = static_cast<uint64_t>(value);
        } else if (IsObject(env, args[0])) {
            auto feature = FeatureNAPI::convert(env, args[0]);
            if (feature.properties.count("cluster_id")) {
                auto& idValue = feature.properties["cluster_id"];
                if (idValue.is<double>()) {
                    clusterId = static_cast<uint64_t>(idValue.get<double>());
                } else if (idValue.is<uint64_t>()) {
                    clusterId = idValue.get<uint64_t>();
                }
            }
        }
        
        // TODO: 需要访问 rendererFrontend 来查询聚类展开缩放级别
        // 类似 Android 实现：
        // featureExtension = rendererFrontend->queryFeatureExtensions(
        //     source.getID(), feature, "supercluster", "expansion-zoom", {});
        
        Logger::warn("GeoJsonSourceNAPI", 
                    "GetClusterExpansionZoom: rendererFrontend access not yet implemented (clusterId: %llu)", 
                    clusterId);
        
        return CreateDoubleValue(env, 0.0);
    } catch (const std::exception& e) {
        Logger::error("GeoJsonSourceNAPI", "GetClusterExpansionZoom failed: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return CreateDoubleValue(env, 0.0);
    }
}

} // namespace harmony
} // namespace maplibre

