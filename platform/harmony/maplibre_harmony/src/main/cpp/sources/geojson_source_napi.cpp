#include "geojson_source_napi.hpp"
#include "napi/core/napi_args.hpp"
#include "napi/core/napi_utils.h"
#include "utils/logger.h"
#include "geojson/geojson_converter.hpp"
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

GeoJsonSourceNAPI::GeoJsonSourceNAPI(mbgl::style::GeoJSONSource* sourcePtr)
    : ownsSource(false) {
    if (sourcePtr) {
        id = sourcePtr->getID();
        weakSource = sourcePtr->makeWeakPtr();
        Logger::info("GeoJsonSourceNAPI", "GeoJsonSource created from existing source (WeakPtr): %s", id.c_str());
    }
}

GeoJsonSourceNAPI::~GeoJsonSourceNAPI() {
    // Reset weakSource before source is destroyed to avoid accessing invalidated WeakPtrFactory
    Logger::info("GeoJsonSourceNAPI", "GeoJsonSource instance destroyed: %s", id.c_str());
}

void GeoJsonSourceNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
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
        mbgl::style::GeoJSONOptions options;
        
        if (argc >= 2) {
            // 解析 options 对象
            napi_value optionsObj = args[1];
            napi_valuetype type;
            napi_typeof(env, optionsObj, &type);
            
            if (type == napi_object) {
                // 解析 cluster 选项
                if (HasProperty(env, optionsObj, "cluster")) {
                    bool cluster = false;
                    napi_value clusterValue;
                    napi_get_named_property(env, optionsObj, "cluster", &clusterValue);
                    napi_get_value_bool(env, clusterValue, &cluster);
                    options.cluster = cluster;
                }
                
                // 解析 clusterRadius
                if (HasProperty(env, optionsObj, "clusterRadius")) {
                    int32_t radius = 50;
                    napi_value radiusValue;
                    napi_get_named_property(env, optionsObj, "clusterRadius", &radiusValue);
                    napi_get_value_int32(env, radiusValue, &radius);
                    options.clusterRadius = static_cast<uint16_t>(radius);
                }
                
                // 解析 clusterMaxZoom
                if (HasProperty(env, optionsObj, "clusterMaxZoom")) {
                    int32_t maxZoom = 16;
                    napi_value maxZoomValue;
                    napi_get_named_property(env, optionsObj, "clusterMaxZoom", &maxZoomValue);
                    napi_get_value_int32(env, maxZoomValue, &maxZoom);
                    options.clusterMaxZoom = static_cast<uint8_t>(maxZoom);
                }
                
                // 解析 minzoom
                if (HasProperty(env, optionsObj, "minzoom")) {
                    int32_t minzoom = 0;
                    napi_value minzoomValue;
                    napi_get_named_property(env, optionsObj, "minzoom", &minzoomValue);
                    napi_get_value_int32(env, minzoomValue, &minzoom);
                    options.minzoom = static_cast<uint8_t>(minzoom);
                }
                
                // 解析 maxzoom
                if (HasProperty(env, optionsObj, "maxzoom")) {
                    int32_t maxzoom = 18;
                    napi_value maxzoomValue;
                    napi_get_named_property(env, optionsObj, "maxzoom", &maxzoomValue);
                    napi_get_value_int32(env, maxzoomValue, &maxzoom);
                    options.maxzoom = static_cast<uint8_t>(maxzoom);
                }
                
                // 解析 buffer
                if (HasProperty(env, optionsObj, "buffer")) {
                    int32_t buffer = 128;
                    napi_value bufferValue;
                    napi_get_named_property(env, optionsObj, "buffer", &bufferValue);
                    napi_get_value_int32(env, bufferValue, &buffer);
                    options.buffer = static_cast<uint16_t>(buffer);
                }
                
                // 解析 tolerance
                if (HasProperty(env, optionsObj, "tolerance")) {
                    double tolerance = 0.375;
                    napi_value toleranceValue;
                    napi_get_named_property(env, optionsObj, "tolerance", &toleranceValue);
                    napi_get_value_double(env, toleranceValue, &tolerance);
                    options.tolerance = tolerance;
                }
                
                // 解析 lineMetrics
                if (HasProperty(env, optionsObj, "lineMetrics")) {
                    bool lineMetrics = false;
                    napi_value lineMetricsValue;
                    napi_get_named_property(env, optionsObj, "lineMetrics", &lineMetricsValue);
                    napi_get_value_bool(env, lineMetricsValue, &lineMetrics);
                    options.lineMetrics = lineMetrics;
                }
                
                // 解析 clusterProperties
                if (HasProperty(env, optionsObj, "clusterProperties")) {
                    napi_value clusterPropsValue;
                    napi_get_named_property(env, optionsObj, "clusterProperties", &clusterPropsValue);
                    
                    napi_valuetype clusterPropsType;
                    napi_typeof(env, clusterPropsValue, &clusterPropsType);
                    
                    if (clusterPropsType == napi_object) {
                        // clusterProperties 是一个对象，格式为:
                        // { propertyName: [mapExpr, reduceExpr], ... }
                        napi_value propertyNames;
                        napi_get_property_names(env, clusterPropsValue, &propertyNames);
                        
                        uint32_t propertyCount = 0;
                        napi_get_array_length(env, propertyNames, &propertyCount);
                        
                        for (uint32_t i = 0; i < propertyCount; i++) {
                            napi_value propertyNameValue;
                            napi_get_element(env, propertyNames, i, &propertyNameValue);
                            
                            std::string propertyName;
                            size_t nameLen = 0;
                            napi_get_value_string_utf8(env, propertyNameValue, nullptr, 0, &nameLen);
                            propertyName.resize(nameLen);
                            napi_get_value_string_utf8(env, propertyNameValue, &propertyName[0], nameLen + 1, &nameLen);
                            
                            // 获取该属性的表达式数组 [mapExpr, reduceExpr]
                            napi_value expressionArray;
                            napi_get_property(env, clusterPropsValue, propertyNameValue, &expressionArray);
                            
                            bool isArray = false;
                            napi_is_array(env, expressionArray, &isArray);
                            
                            if (isArray) {
                                uint32_t arrayLength = 0;
                                napi_get_array_length(env, expressionArray, &arrayLength);
                                
                                if (arrayLength >= 2) {
                                    // 获取 map 表达式和 reduce 表达式
                                    napi_value mapExprValue, reduceExprValue;
                                    napi_get_element(env, expressionArray, 0, &mapExprValue);
                                    napi_get_element(env, expressionArray, 1, &reduceExprValue);
                                    
                                    // 转换为 mbgl Expression
                                    // TODO: clusterProperties需要特殊的Expression转换
                                    // 当前暂时跳过clusterProperties的解析
                                    // 在未来版本中可以通过JSON字符串方式传递
                                    Logger::warn("GeoJsonSourceNAPI", 
                                                "clusterProperties[\"%s\"]: Expression conversion not yet implemented", 
                                                propertyName.c_str());
                                }
                            }
                        }
                        
                    }
                }
            }
        }
        
        // 创建 GeoJSONSource
        auto immutableOptions = mbgl::makeMutable<mbgl::style::GeoJSONOptions>(std::move(options));
        auto source = std::make_unique<mbgl::style::GeoJSONSource>(sourceId, std::move(immutableOptions));
        
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
    
    // 添加 _TYPE_ 属性用于 ETS 层的类型判断
    napi_value typeValue;
    napi_create_string_utf8(env, "GeoJsonSource", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, jsThis, "_TYPE_", typeValue);
        return jsThis;
    } catch (const std::exception& e) {
        Logger::error("GeoJsonSourceNAPI", "Failed to create GeoJsonSource: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value GeoJsonSourceNAPI::CreateInstance(napi_env env, mbgl::style::GeoJSONSource* sourcePtr) {
    if (!sourcePtr) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 获取构造函数
    napi_value cons;
    napi_status status = napi_get_reference_value(env, constructor, &cons);
    if (status != napi_ok) {
        Logger::error("GeoJsonSourceNAPI", "Failed to get constructor reference");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 创建空对象并设置原型（避免调用 JS 构造函数）
    napi_value instance;
    status = napi_create_object(env, &instance);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to create object");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 获取构造函数的原型
    napi_value prototype;
    status = napi_get_named_property(env, cons, "prototype", &prototype);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to get prototype");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 设置对象的原型
    status = napi_set_named_property(env, instance, "__proto__", prototype);
    if (status != napi_ok) {
        Logger::error("CreateInstance", "Failed to set prototype");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 创建 NAPI wrapper（使用 WeakPtr 构造函数）
    GeoJsonSourceNAPI* napiObj = new GeoJsonSourceNAPI(sourcePtr);
    
    // 包装到 JS 对象
    status = napi_wrap(env, instance, napiObj, Destructor, nullptr, nullptr);
    if (status != napi_ok) {
        delete napiObj;
        Logger::error("GeoJsonSourceNAPI", "Failed to wrap instance");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 添加 _TYPE_ 属性
    napi_value typeValue;
    napi_create_string_utf8(env, "GeoJsonSource", NAPI_AUTO_LENGTH, &typeValue);
    napi_set_named_property(env, instance, "_TYPE_", typeValue);
    
    return instance;
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
                auto collection = GeoJsonConverter::JsObjectToFeatureCollection(env, args[0]);
                source->setGeoJSON(mbgl::GeoJSON(std::move(collection)));
                Logger::info("GeoJsonSourceNAPI", "SetGeoJson (FeatureCollection): %s", sourceNapi->id.c_str());
            } else if (type == "Feature") {
                // Feature 对象
                auto feature = GeoJsonConverter::JsObjectToFeature(env, args[0]);
                // 转换为 GeoJSONFeature
                mbgl::GeoJSONFeature geoJsonFeature;
                geoJsonFeature.geometry = feature.geometry;
                geoJsonFeature.properties = feature.properties;
                geoJsonFeature.id = feature.id;
                source->setGeoJSON(mbgl::GeoJSON(std::move(geoJsonFeature)));
                Logger::info("GeoJsonSourceNAPI", "SetGeoJson (Feature): %s", sourceNapi->id.c_str());
            } else {
                // Geometry 对象
                auto geometry = GeoJsonConverter::JsObjectToGeometry(env, args[0]);
                source->setGeoJSON(mbgl::GeoJSON(std::move(geometry)));
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
        return GeoJsonConverter::FeatureArrayToJsArray(env, features);
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
            auto feature = GeoJsonConverter::JsObjectToFeature(env, args[0]);
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
        return GeoJsonConverter::FeatureArrayToJsArray(env, features);
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
            auto feature = GeoJsonConverter::JsObjectToFeature(env, args[0]);
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
        return GeoJsonConverter::FeatureArrayToJsArray(env, features);
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
    
    if (!sourceNapi) {
        return CreateDoubleValue(env, 0.0);
    }
    
    auto* source = sourceNapi->getSource();
    if (!source) {
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
            auto feature = GeoJsonConverter::JsObjectToFeature(env, args[0]);
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

