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

napi_ref FeatureNAPI::constructor = nullptr;

FeatureNAPI::FeatureNAPI() : feature_() {}

FeatureNAPI::FeatureNAPI(const mbgl::GeoJSONFeature& feature)
    : feature_(feature) {}

FeatureNAPI::~FeatureNAPI() {}

void FeatureNAPI::Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    delete static_cast<FeatureNAPI*>(nativeObject);
}

napi_value FeatureNAPI::Init(napi_env env, napi_value exports) {
    Logger::info("FeatureNAPI", "Initializing Feature NAPI class");
    
    napi_property_descriptor properties[] = {
        { "getId", nullptr, GetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setId", nullptr, SetId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getProperties", nullptr, GetProperties, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setProperties", nullptr, SetProperties, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getGeometry", nullptr, GetGeometry, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setGeometry", nullptr, SetGeometry, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "toJSON", nullptr, ToJSON, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons;
    napi_status status = napi_define_class(env, "Feature", NAPI_AUTO_LENGTH, New, nullptr,
                                           sizeof(properties) / sizeof(properties[0]), properties, &cons);
    
    if (status != napi_ok) {
        Logger::error("FeatureNAPI", "Failed to define Feature class");
        return nullptr;
    }
    
    status = napi_create_reference(env, cons, 1, &constructor);
    if (status != napi_ok) {
        Logger::error("FeatureNAPI", "Failed to create constructor reference");
        return nullptr;
    }
    
    status = napi_set_named_property(env, exports, "Feature", cons);
    if (status != napi_ok) {
        Logger::error("FeatureNAPI", "Failed to set Feature property");
        return nullptr;
    }
    
    Logger::info("FeatureNAPI", "Feature NAPI class initialized successfully");
    return exports;
}

napi_value FeatureNAPI::New(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    FeatureNAPI* feature = nullptr;
    
    try {
        feature = new FeatureNAPI();
        
        // 如果提供了参数（geometry 和/或 properties）
        if (args.Count() >= 1) {
            // 第一个参数可以是对象（包含 geometry, properties, id）
            napi_value arg0 = args.GetValue(0);
            napi_valuetype type;
            napi_typeof(env, arg0, &type);
            
            if (type == napi_object) {
                // 检查是否有 geometry 属性
                bool hasGeometry;
                napi_has_named_property(env, arg0, "geometry", &hasGeometry);
                if (hasGeometry) {
                    napi_value geometryValue;
                    napi_get_named_property(env, arg0, "geometry", &geometryValue);
                    napi_valuetype geomType;
                    napi_typeof(env, geometryValue, &geomType);
                    if (geomType == napi_object) {
                        feature->feature_.geometry = GeometryNAPI::convert(env, geometryValue);
                    }
                }
                
                // 检查是否有 properties 属性
                bool hasProperties;
                napi_has_named_property(env, arg0, "properties", &hasProperties);
                if (hasProperties) {
                    napi_value propertiesValue;
                    napi_get_named_property(env, arg0, "properties", &propertiesValue);
                    napi_valuetype propType;
                    napi_typeof(env, propertiesValue, &propType);
                    if (propType == napi_object) {
                        feature->feature_.properties = NapiObjectToPropertyMap(env, propertiesValue);
                    }
                }
                
                // 检查是否有 id 属性
                bool hasId;
                napi_has_named_property(env, arg0, "id", &hasId);
                if (hasId) {
                    napi_value idValue;
                    napi_get_named_property(env, arg0, "id", &idValue);
                    napi_valuetype idType;
                    napi_typeof(env, idValue, &idType);
                    if (idType == napi_string) {
                        size_t length;
                        napi_get_value_string_utf8(env, idValue, nullptr, 0, &length);
                        std::string idStr(length, '\0');
                        napi_get_value_string_utf8(env, idValue, &idStr[0], length + 1, &length);
                        feature->feature_.id = idStr;
                    } else if (idType == napi_number) {
                        double numValue;
                        napi_get_value_double(env, idValue, &numValue);
                        if (numValue >= 0) {
                            feature->feature_.id = static_cast<uint64_t>(numValue);
                        } else {
                            feature->feature_.id = static_cast<int64_t>(numValue);
                        }
                    }
                }
            }
        }
        
        napi_status status = napi_wrap(env, jsThis, feature, Destructor, nullptr, nullptr);
        if (status != napi_ok) {
            delete feature;
            napi_throw_error(env, nullptr, "Failed to wrap Feature object");
            return nullptr;
        }
        
        return jsThis;
    } catch (const std::exception& e) {
        if (feature) delete feature;
        Logger::error("FeatureNAPI", "Failed to create Feature: %s", e.what());
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value FeatureNAPI::GetId(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    FeatureNAPI* feature = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&feature));
    
    if (status != napi_ok || !feature) {
        napi_throw_error(env, nullptr, "Failed to unwrap Feature object");
        return nullptr;
    }
    
    if (feature->feature_.id.is<mbgl::NullValue>()) {
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    napi_value result;
    if (feature->feature_.id.is<std::string>()) {
        const auto& idStr = feature->feature_.id.get<std::string>();
        napi_create_string_utf8(env, idStr.c_str(), NAPI_AUTO_LENGTH, &result);
    } else if (feature->feature_.id.is<uint64_t>()) {
        napi_create_double(env, static_cast<double>(feature->feature_.id.get<uint64_t>()), &result);
    } else if (feature->feature_.id.is<int64_t>()) {
        napi_create_double(env, static_cast<double>(feature->feature_.id.get<int64_t>()), &result);
    } else {
        napi_get_null(env, &result);
    }
    
    return result;
}

napi_value FeatureNAPI::SetId(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    FeatureNAPI* feature = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&feature));
    
    if (status != napi_ok || !feature) {
        napi_throw_error(env, nullptr, "Failed to unwrap Feature object");
        return nullptr;
    }
    
    napi_value idValue = args.GetValue(0);
    napi_valuetype type;
    napi_typeof(env, idValue, &type);
    
    if (type == napi_string) {
        feature->feature_.id = args.GetString(0, "id");
    } else if (type == napi_number) {
        double numValue = args.GetDouble(0, "id");
        if (args.HasError()) return nullptr;
        if (numValue >= 0) {
            feature->feature_.id = static_cast<uint64_t>(numValue);
        } else {
            feature->feature_.id = static_cast<int64_t>(numValue);
        }
    } else {
        feature->feature_.id = mbgl::NullValue{};
    }
    
    return jsThis;
}

napi_value FeatureNAPI::GetProperties(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    FeatureNAPI* feature = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&feature));
    
    if (status != napi_ok || !feature) {
        napi_throw_error(env, nullptr, "Failed to unwrap Feature object");
        return nullptr;
    }
    
    return PropertyMapToNapiObject(env, feature->feature_.properties);
}

napi_value FeatureNAPI::SetProperties(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    FeatureNAPI* feature = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&feature));
    
    if (status != napi_ok || !feature) {
        napi_throw_error(env, nullptr, "Failed to unwrap Feature object");
        return nullptr;
    }
    
    try {
        napi_value propertiesValue = args.GetObject(0, "properties");
        if (args.HasError()) return nullptr;
        
        feature->feature_.properties = NapiObjectToPropertyMap(env, propertiesValue);
        return jsThis;
    } catch (const std::exception& e) {
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value FeatureNAPI::GetGeometry(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    FeatureNAPI* feature = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&feature));
    
    if (status != napi_ok || !feature) {
        napi_throw_error(env, nullptr, "Failed to unwrap Feature object");
        return nullptr;
    }
    
    return GeometryNAPI::New(env, feature->feature_.geometry);
}

napi_value FeatureNAPI::SetGeometry(napi_env env, napi_callback_info info) {
    NapiArgs args(env, info);
    args.RequireMinArgs(1);
    if (args.HasError()) return nullptr;
    
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    FeatureNAPI* feature = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&feature));
    
    if (status != napi_ok || !feature) {
        napi_throw_error(env, nullptr, "Failed to unwrap Feature object");
        return nullptr;
    }
    
    try {
        // 使用 GetValue 而不是 GetObject，这样可以接受 NAPI 类实例
        napi_value geometryValue = args.GetValue(0);
        
        // GeometryNAPI::convert 会自动处理 NAPI 实例或普通对象
        feature->feature_.geometry = GeometryNAPI::convert(env, geometryValue);
        return jsThis;
    } catch (const std::exception& e) {
        napi_throw_error(env, nullptr, e.what());
        return nullptr;
    }
}

napi_value FeatureNAPI::ToJSON(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    
    FeatureNAPI* feature = nullptr;
    napi_status status = napi_unwrap(env, jsThis, reinterpret_cast<void**>(&feature));
    
    if (status != napi_ok || !feature) {
        napi_throw_error(env, nullptr, "Failed to unwrap Feature object");
        return nullptr;
    }
    
    napi_value result;
    napi_create_object(env, &result);
    
    // type: "Feature"
    napi_value type;
    napi_create_string_utf8(env, Type(), NAPI_AUTO_LENGTH, &type);
    napi_set_named_property(env, result, "type", type);
    
    // id (optional)
    if (!feature->feature_.id.is<mbgl::NullValue>()) {
        napi_value id;
        if (feature->feature_.id.is<std::string>()) {
            const auto& idStr = feature->feature_.id.get<std::string>();
            napi_create_string_utf8(env, idStr.c_str(), NAPI_AUTO_LENGTH, &id);
        } else if (feature->feature_.id.is<uint64_t>()) {
            napi_create_double(env, static_cast<double>(feature->feature_.id.get<uint64_t>()), &id);
        } else if (feature->feature_.id.is<int64_t>()) {
            napi_create_double(env, static_cast<double>(feature->feature_.id.get<int64_t>()), &id);
        } else {
            napi_get_null(env, &id);
        }
        napi_set_named_property(env, result, "id", id);
    }
    
    // geometry
    napi_value geometry = GeometryNAPI::New(env, feature->feature_.geometry);
    napi_set_named_property(env, result, "geometry", geometry);
    
    // properties
    napi_value properties = PropertyMapToNapiObject(env, feature->feature_.properties);
    napi_set_named_property(env, result, "properties", properties);
    
    return result;
}

napi_value FeatureNAPI::FromMbglFeature(napi_env env, const mbgl::GeoJSONFeature& feature) {
    if (constructor == nullptr) {
        Logger::error("FeatureNAPI", "Feature constructor not initialized");
        return nullptr;
    }
    
    napi_value cons;
    napi_status status = napi_get_reference_value(env, constructor, &cons);
    if (status != napi_ok) {
        Logger::error("FeatureNAPI", "Failed to get Feature constructor");
        return nullptr;
    }
    
    napi_value instance;
    status = napi_new_instance(env, cons, 0, nullptr, &instance);
    if (status != napi_ok) {
        Logger::error("FeatureNAPI", "Failed to create Feature instance");
        return nullptr;
    }
    
    FeatureNAPI* featureNAPI = nullptr;
    status = napi_unwrap(env, instance, reinterpret_cast<void**>(&featureNAPI));
    if (status == napi_ok && featureNAPI) {
        featureNAPI->feature_ = feature;
    }
    
    return instance;
}

napi_value FeatureNAPI::FromMbglFeature(napi_env env, const mbgl::Feature& feature) {
    mbgl::GeoJSONFeature geoJsonFeature;
    geoJsonFeature.geometry = feature.geometry;
    geoJsonFeature.properties = feature.properties;
    geoJsonFeature.id = feature.id;
    return FromMbglFeature(env, geoJsonFeature);
}

napi_value FeatureNAPI::NewArray(napi_env env, const std::vector<mbgl::Feature>& features) {
    napi_value array;
    napi_create_array_with_length(env, features.size(), &array);
    
    for (size_t i = 0; i < features.size(); i++) {
        napi_value feature = FromMbglFeature(env, features[i]);
        napi_set_element(env, array, i, feature);
    }
    
    return array;
}

napi_value FeatureNAPI::NewArray(napi_env env, const std::vector<mbgl::GeoJSONFeature>& features) {
    napi_value array;
    napi_create_array_with_length(env, features.size(), &array);
    
    for (size_t i = 0; i < features.size(); i++) {
        napi_value feature = FromMbglFeature(env, features[i]);
        napi_set_element(env, array, i, feature);
    }
    
    return array;
}

mbgl::GeoJSONFeature FeatureNAPI::convert(napi_env env, napi_value value) {
    // 首先尝试从 NAPI 类实例获取
    FeatureNAPI* feature = nullptr;
    napi_status status = napi_unwrap(env, value, reinterpret_cast<void**>(&feature));
    
    if (status == napi_ok && feature) {
        return feature->toMbglFeature();
    }
    
    // 如果不是 NAPI 实例，尝试从普通对象解析
    if (!IsObject(env, value)) {
        throw std::runtime_error("Feature must be an object");
    }
    
    mbgl::GeoJSONFeature result;
    
    // 获取 geometry
    if (HasProperty(env, value, "geometry")) {
        napi_value geometryValue = GetObjectProperty(env, value, "geometry");
        if (!IsNull(env, geometryValue) && !IsUndefined(env, geometryValue)) {
            result.geometry = GeometryNAPI::convert(env, geometryValue);
        }
    }
    
    // 获取 properties
    if (HasProperty(env, value, "properties")) {
        napi_value propertiesValue = GetObjectProperty(env, value, "properties");
        if (!IsNull(env, propertiesValue) && !IsUndefined(env, propertiesValue)) {
            result.properties = NapiObjectToPropertyMap(env, propertiesValue);
        }
    }
    
    // 获取 id（可选）
    if (HasProperty(env, value, "id")) {
        napi_value idValue = GetObjectProperty(env, value, "id");
        if (!IsNull(env, idValue) && !IsUndefined(env, idValue)) {
            if (IsString(env, idValue)) {
                result.id = GetStringProperty(env, value, "id");
            } else if (IsNumber(env, idValue)) {
                double numValue = GetNumberProperty(env, value, "id");
                // 将 double 转换为 uint64_t 或 int64_t
                if (numValue >= 0) {
                    result.id = static_cast<uint64_t>(numValue);
                } else {
                    result.id = static_cast<int64_t>(numValue);
                }
            }
        }
    }
    
    return result;
}

} // namespace geojson
} // namespace harmony
} // namespace maplibre
