#include "feature_collection_napi.hpp"
#include "feature_napi.hpp"
#include "geometry_napi.hpp"
#include "util.hpp"
#include "napi/core/napi_args.hpp"
#include "utils/logger.h"

using mbgl::harmony::Logger;
using namespace mbgl::harmony::napi;

namespace maplibre {
namespace harmony {
namespace geojson {

napi_ref FeatureCollectionNAPI::constructor = nullptr;

FeatureCollectionNAPI::FeatureCollectionNAPI() : features_() {}

FeatureCollectionNAPI::FeatureCollectionNAPI(const std::vector<mbgl::GeoJSONFeature>& features)
    : features_(features) {}

FeatureCollectionNAPI::~FeatureCollectionNAPI() {}

void FeatureCollectionNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    delete static_cast<FeatureCollectionNAPI*>(nativeObject);
}

napi_value FeatureCollectionNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("FeatureCollectionNAPI", "Initializing FeatureCollection NAPI class");
    
    napi_property_descriptor properties[] = {
        { "getFeatures", nullptr, GetFeatures, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setFeatures", nullptr, SetFeatures, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "addFeature", nullptr, AddFeature, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getFeatureCount", nullptr, GetFeatureCount, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "toJSON", nullptr, ToJSON, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "FeatureCollection", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("FeatureCollectionNAPI", "Failed to define FeatureCollection class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("FeatureCollectionNAPI", "Failed to create constructor reference");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "FeatureCollection", cons);
    if (status != napi_ok) {
        Logger::error("FeatureCollectionNAPI", "Failed to set FeatureCollection property");
        return nullptr;
    }
    
    Logger::info("FeatureCollectionNAPI", "FeatureCollection NAPI class initialized successfully");
    return exports;
}

napi_value FeatureCollectionNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    FeatureCollectionNAPI* featureCollection = nullptr;
    
    try {
        if (args.Count() == 0) {
            featureCollection = new FeatureCollectionNAPI();
        } else {
            // 第一个参数可以是 features 数组
            napi_value arg0 = args.GetValue(0);
            bool isArray = false;
            napi_is_array(env, arg0, &isArray);
            
            if (isArray) {
                // 将数组转换为 features
                uint32_t length;
                napi_get_array_length(env, arg0, &length);
                std::vector<mbgl::GeoJSONFeature> features;
                
                for (uint32_t i = 0; i < length; i++) {
                    napi_value element;
                    napi_get_element(env, arg0, i, &element);
                    
                    // 尝试从元素解析 feature
                    // 简化处理：如果元素是对象，尝试将其转换为 feature
                    napi_valuetype type;
                    napi_typeof(env, element, &type);
                    if (type == napi_object) {
                        mbgl::GeoJSONFeature feature;
                        
                        // 获取 geometry
                        bool hasGeometry;
                        napi_has_named_property(env, element, "geometry", &hasGeometry);
                        if (hasGeometry) {
                            napi_value geometryValue;
                            napi_get_named_property(env, element, "geometry", &geometryValue);
                            napi_valuetype geomType;
                            napi_typeof(env, geometryValue, &geomType);
                            if (geomType == napi_object) {
                                feature.geometry = GeometryNAPI::convert(env, geometryValue);
                            }
                        }
                        
                        // 获取 properties
                        bool hasProperties;
                        napi_has_named_property(env, element, "properties", &hasProperties);
                        if (hasProperties) {
                            napi_value propertiesValue;
                            napi_get_named_property(env, element, "properties", &propertiesValue);
                            napi_valuetype propType;
                            napi_typeof(env, propertiesValue, &propType);
                            if (propType == napi_object) {
                                feature.properties = NapiObjectToPropertyMap(env, propertiesValue);
                            }
                        }
                        
                        features.push_back(feature);
                    }
                }
                
                featureCollection = new FeatureCollectionNAPI(features);
            } else {
                featureCollection = new FeatureCollectionNAPI();
            }
        }
        
        napi_status status = napi_wrap(env, jsThis, featureCollection, Destructor, nullptr, nullptr);
        if (status != napi_ok) {
            delete featureCollection;
            napi_throw_error(env, nullptr, "Failed to wrap FeatureCollection object");
            return nullptr;
        }
        
        return jsThis;
    } catch (const std::exception& e) {
        if (featureCollection) delete featureCollection;
        Logger::error("FeatureCollectionNAPI", "Failed to create FeatureCollection: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value FeatureCollectionNAPI::GetFeatures(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    FeatureCollectionNAPI* featureCollection = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&featureCollection));
    
    if (status != napi_ok || !featureCollection) {
        napi_throw_error(env, nullptr, "Failed to unwrap FeatureCollection object");
        return nullptr;
    }
    
    return FeatureNAPI::NewArray(env, featureCollection->features_);
}

napi_value FeatureCollectionNAPI::SetFeatures(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    FeatureCollectionNAPI* featureCollection = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&featureCollection));
    
    if (status != napi_ok || !featureCollection) {
        napi_throw_error(env, nullptr, "Failed to unwrap FeatureCollection object");
        return nullptr;
    }
    
    // 简化实现：清空并重新设置
    featureCollection->features_.clear();
    return jsThis;
}

napi_value FeatureCollectionNAPI::AddFeature(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    FeatureCollectionNAPI* featureCollection = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&featureCollection));
    
    if (status != napi_ok || !featureCollection) {
        napi_throw_error(env, nullptr, "Failed to unwrap FeatureCollection object");
        return nullptr;
    }
    
    // 简化实现
    return jsThis;
}

napi_value FeatureCollectionNAPI::GetFeatureCount(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    FeatureCollectionNAPI* featureCollection = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&featureCollection));
    
    if (status != napi_ok || !featureCollection) {
        napi_throw_error(env, nullptr, "Failed to unwrap FeatureCollection object");
        return nullptr;
    }
    
    napi_value result;
    napi_create_uint32(env, featureCollection->features_.size(), &result);
    return result;
}

napi_value FeatureCollectionNAPI::ToJSON(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    FeatureCollectionNAPI* featureCollection = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&featureCollection));
    
    if (status != napi_ok || !featureCollection) {
        napi_throw_error(env, nullptr, "Failed to unwrap FeatureCollection object");
        return nullptr;
    }
    
    napi_value result;
    napi_create_object(env, &result);
    
    // type: "FeatureCollection"
    napi_value type;
    napi_create_string_utf8(env, Type(), NAPI_AUTO_LENGTH, &type);
    napi_set_named_property(env, result, "type", type);
    
    // features
    napi_value features = FeatureNAPI::NewArray(env, featureCollection->features_);
    napi_set_named_property(env, result, "features", features);
    
    return result;
}

napi_value FeatureCollectionNAPI::FromMbglFeatures(napi_env env, const std::vector<mbgl::Feature>& features) {
    std::vector<mbgl::GeoJSONFeature> geoJsonFeatures;
    for (const auto& feature : features) {
        mbgl::GeoJSONFeature geoJsonFeature;
        geoJsonFeature.geometry = feature.geometry;
        geoJsonFeature.properties = feature.properties;
        geoJsonFeature.id = feature.id;
        geoJsonFeatures.push_back(geoJsonFeature);
    }
    
    return FromMbglGeoJSONFeatures(env, geoJsonFeatures);
}

napi_value FeatureCollectionNAPI::FromMbglGeoJSONFeatures(napi_env env, const std::vector<mbgl::GeoJSONFeature>& features) {
    if (constructor == nullptr) {
        Logger::error("FeatureCollectionNAPI", "FeatureCollection constructor not initialized");
        return nullptr;
    }
    
    napi_value cons;
    napi_status status = napi_get_reference_value(env, constructor, &cons);
    if (status != napi_ok) {
        Logger::error("FeatureCollectionNAPI", "Failed to get FeatureCollection constructor");
        return nullptr;
    }
    
    napi_value instance;
    status = napi_new_instance(env, cons, 0, nullptr, &instance);
    if (status != napi_ok) {
        Logger::error("FeatureCollectionNAPI", "Failed to create FeatureCollection instance");
        return nullptr;
    }
    
    FeatureCollectionNAPI* featureCollection = nullptr;
    status = napi_unwrap(env, instance, reinterpret_cast<void**>(&featureCollection));
    if (status == napi_ok && featureCollection) {
        featureCollection->features_ = features;
    }
    
    return instance;
}

std::vector<mbgl::GeoJSONFeature> FeatureCollectionNAPI::convert(napi_env env, napi_value value) {
    std::vector<mbgl::GeoJSONFeature> features;
    
    // 简化实现：假设 value 是对象，包含 features 数组
    bool hasFeatures;
    napi_has_named_property(env, value, "features", &hasFeatures);
    if (hasFeatures) {
        napi_value featuresValue;
        napi_get_named_property(env, value, "features", &featuresValue);
        
        bool isArray;
        napi_is_array(env, featuresValue, &isArray);
        if (isArray) {
            uint32_t length;
            napi_get_array_length(env, featuresValue, &length);
            
            for (uint32_t i = 0; i < length; i++) {
                napi_value element;
                napi_get_element(env, featuresValue, i, &element);
                
                // 从元素解析 feature
                mbgl::GeoJSONFeature feature;
                
                bool hasGeometry;
                napi_has_named_property(env, element, "geometry", &hasGeometry);
                if (hasGeometry) {
                    napi_value geometryValue;
                    napi_get_named_property(env, element, "geometry", &geometryValue);
                    feature.geometry = GeometryNAPI::convert(env, geometryValue);
                }
                
                bool hasProperties;
                napi_has_named_property(env, element, "properties", &hasProperties);
                if (hasProperties) {
                    napi_value propertiesValue;
                    napi_get_named_property(env, element, "properties", &propertiesValue);
                    feature.properties = NapiObjectToPropertyMap(env, propertiesValue);
                }
                
                features.push_back(feature);
            }
        }
    }
    
    return features;
}

mbgl::FeatureCollection FeatureCollectionNAPI::convertToFeatureCollection(napi_env env, napi_value value) {
    auto geoJsonFeatures = convert(env, value);
    mbgl::FeatureCollection featureCollection;
    
    for (const auto& geoJsonFeature : geoJsonFeatures) {
        mbgl::Feature feature{geoJsonFeature.geometry};
        feature.properties = geoJsonFeature.properties;
        feature.id = geoJsonFeature.id;
        featureCollection.push_back(feature);
    }
    
    return featureCollection;
}

} // namespace geojson
} // namespace harmony
} // namespace maplibre
