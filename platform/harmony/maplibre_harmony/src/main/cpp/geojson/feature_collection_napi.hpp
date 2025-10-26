#pragma once

#include <napi/native_api.h>
#include <mbgl/util/feature.hpp>

namespace maplibre {
namespace harmony {
namespace geojson {

/**
 * FeatureCollectionNAPI - FeatureCollection NAPI 转换
 */
class FeatureCollectionNAPI {
public:
    static constexpr const char* Type() { return "FeatureCollection"; }
    
    /**
     * 将 Feature 向量转换为 FeatureCollection NAPI 对象
     */
    static napi_value New(napi_env env, const std::vector<mbgl::Feature>& features);
    
    /**
     * 将 GeoJSONFeature 向量转换为 FeatureCollection NAPI 对象
     */
    static napi_value New(napi_env env, const std::vector<mbgl::GeoJSONFeature>& features);
    
    /**
     * 将 NAPI 对象转换为 GeoJSONFeature 向量
     */
    static std::vector<mbgl::GeoJSONFeature> convert(napi_env env, napi_value value);
    
    /**
     * 将 NAPI 对象转换为 FeatureCollection
     */
    static mbgl::FeatureCollection convertToFeatureCollection(napi_env env, napi_value value);
};

} // namespace geojson
} // namespace harmony
} // namespace maplibre

