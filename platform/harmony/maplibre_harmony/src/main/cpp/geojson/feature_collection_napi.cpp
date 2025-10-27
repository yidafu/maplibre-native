#include "feature_collection_napi.hpp"
#include "feature_napi.hpp"
#include "util.hpp"
#include "utils/logger.h"

using mbgl::harmony::Logger;

namespace maplibre {
namespace harmony {
namespace geojson {

napi_value FeatureCollectionNAPI::New(napi_env env, const std::vector<mbgl::Feature>& features) {
    napi_value obj;
    napi_create_object(env, &obj);
    
    // 设置 type
    napi_value type;
    napi_create_string_utf8(env, Type(), NAPI_AUTO_LENGTH, &type);
    napi_set_named_property(env, obj, "type", type);
    
    // 设置 features
    napi_value featuresArray = FeatureNAPI::NewArray(env, features);
    napi_set_named_property(env, obj, "features", featuresArray);
    
    return obj;
}

napi_value FeatureCollectionNAPI::New(napi_env env, const std::vector<mbgl::GeoJSONFeature>& features) {
    napi_value obj;
    napi_create_object(env, &obj);
    
    // 设置 type
    napi_value type;
    napi_create_string_utf8(env, Type(), NAPI_AUTO_LENGTH, &type);
    napi_set_named_property(env, obj, "type", type);
    
    // 设置 features
    napi_value featuresArray = FeatureNAPI::NewArray(env, features);
    napi_set_named_property(env, obj, "features", featuresArray);
    
    return obj;
}

std::vector<mbgl::GeoJSONFeature> FeatureCollectionNAPI::convert(napi_env env, napi_value value) {
    if (!IsObject(env, value)) {
        throw std::runtime_error("FeatureCollection must be an object");
    }
    
    std::vector<mbgl::GeoJSONFeature> result;
    
    // 获取 features
    if (!HasProperty(env, value, "features")) {
        return result;
    }
    
    napi_value featuresValue = GetObjectProperty(env, value, "features");
    
    if (!IsArray(env, featuresValue)) {
        throw std::runtime_error("FeatureCollection features must be an array");
    }
    
    uint32_t length = 0;
    napi_get_array_length(env, featuresValue, &length);
    result.reserve(length);
    
    for (uint32_t i = 0; i < length; i++) {
        napi_value featureValue;
        napi_get_element(env, featuresValue, i, &featureValue);
        result.push_back(FeatureNAPI::convert(env, featureValue));
    }
    
    return result;
}

mbgl::FeatureCollection FeatureCollectionNAPI::convertToFeatureCollection(napi_env env, napi_value value) {
    auto geoJsonFeatures = convert(env, value);
    mbgl::FeatureCollection collection;
    collection.reserve(geoJsonFeatures.size());
    
    for (const auto& geoJsonFeature : geoJsonFeatures) {
        mbgl::Feature feature;
        feature.geometry = geoJsonFeature.geometry;
        feature.properties = geoJsonFeature.properties;
        feature.id = geoJsonFeature.id;
        collection.push_back(std::move(feature));
    }
    
    return collection;
}

} // namespace geojson
} // namespace harmony
} // namespace maplibre

