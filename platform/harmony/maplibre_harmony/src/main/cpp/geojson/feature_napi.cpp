#include "feature_napi.hpp"
#include "geometry_napi.hpp"
#include "util.hpp"
#include "utils/logger.h"

using mbgl::harmony::Logger;

namespace maplibre {
namespace harmony {
namespace geojson {

napi_value FeatureNAPI::New(napi_env env, const mbgl::GeoJSONFeature& feature) {
    napi_value obj;
    napi_create_object(env, &obj);
    
    // 设置 type
    napi_value type;
    napi_create_string_utf8(env, Type(), NAPI_AUTO_LENGTH, &type);
    napi_set_named_property(env, obj, "type", type);
    
    // 设置 id（可选）
    if (!feature.id.is<mbgl::NullValue>()) {
        napi_value id;
        if (feature.id.is<std::string>()) {
            const auto& idStr = feature.id.get<std::string>();
            napi_create_string_utf8(env, idStr.c_str(), NAPI_AUTO_LENGTH, &id);
        } else if (feature.id.is<uint64_t>()) {
            napi_create_double(env, static_cast<double>(feature.id.get<uint64_t>()), &id);
        } else if (feature.id.is<int64_t>()) {
            napi_create_double(env, static_cast<double>(feature.id.get<int64_t>()), &id);
        } else {
            napi_get_null(env, &id);
        }
        napi_set_named_property(env, obj, "id", id);
    }
    
    // 设置 geometry
    napi_value geometry = GeometryNAPI::New(env, feature.geometry);
    napi_set_named_property(env, obj, "geometry", geometry);
    
    // 设置 properties
    napi_value properties = PropertyMapToNapiObject(env, feature.properties);
    napi_set_named_property(env, obj, "properties", properties);
    
    return obj;
}

mbgl::GeoJSONFeature FeatureNAPI::convert(napi_env env, napi_value value) {
    if (!IsObject(env, value)) {
        throw std::runtime_error("Feature must be an object");
    }
    
    mbgl::GeoJSONFeature feature;
    
    // 获取 geometry
    if (HasProperty(env, value, "geometry")) {
        napi_value geometryValue = GetObjectProperty(env, value, "geometry");
        if (!IsNull(env, geometryValue) && !IsUndefined(env, geometryValue)) {
            feature.geometry = GeometryNAPI::convert(env, geometryValue);
        }
    }
    
    // 获取 properties
    if (HasProperty(env, value, "properties")) {
        napi_value propertiesValue = GetObjectProperty(env, value, "properties");
        if (!IsNull(env, propertiesValue) && !IsUndefined(env, propertiesValue)) {
            feature.properties = NapiObjectToPropertyMap(env, propertiesValue);
        }
    }
    
    // 获取 id（可选）
    if (HasProperty(env, value, "id")) {
        napi_value idValue = GetObjectProperty(env, value, "id");
        if (!IsNull(env, idValue) && !IsUndefined(env, idValue)) {
            if (IsString(env, idValue)) {
                feature.id = GetStringProperty(env, value, "id");
            } else if (IsNumber(env, idValue)) {
                double numValue = GetNumberProperty(env, value, "id");
                // 将 double 转换为 uint64_t 或 int64_t
                if (numValue >= 0) {
                    feature.id = static_cast<uint64_t>(numValue);
                } else {
                    feature.id = static_cast<int64_t>(numValue);
                }
            }
        }
    }
    
    return feature;
}

napi_value FeatureNAPI::NewArray(napi_env env, const std::vector<mbgl::Feature>& features) {
    napi_value array;
    napi_create_array_with_length(env, features.size(), &array);
    
    for (size_t i = 0; i < features.size(); i++) {
        // 将 Feature 转换为 GeoJSONFeature
        mbgl::GeoJSONFeature geoJsonFeature;
        geoJsonFeature.geometry = features[i].geometry;
        geoJsonFeature.properties = features[i].properties;
        geoJsonFeature.id = features[i].id;
        
        napi_value feature = New(env, geoJsonFeature);
        napi_set_element(env, array, i, feature);
    }
    
    return array;
}

napi_value FeatureNAPI::NewArray(napi_env env, const std::vector<mbgl::GeoJSONFeature>& features) {
    napi_value array;
    napi_create_array_with_length(env, features.size(), &array);
    
    for (size_t i = 0; i < features.size(); i++) {
        napi_value feature = New(env, features[i]);
        napi_set_element(env, array, i, feature);
    }
    
    return array;
}

} // namespace geojson
} // namespace harmony
} // namespace maplibre

