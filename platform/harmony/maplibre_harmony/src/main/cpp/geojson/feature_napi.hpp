#pragma once

#include <napi/native_api.h>
#include <mbgl/util/feature.hpp>

namespace maplibre {
namespace harmony {
namespace geojson {

/**
 * FeatureNAPI - Feature NAPI 转换
 */
class FeatureNAPI {
public:
    static constexpr const char* Type() { return "Feature"; }
    
    /**
     * 将 mbgl::GeoJSONFeature 转换为 NAPI 对象
     */
    static napi_value New(napi_env env, const mbgl::GeoJSONFeature& feature);
    
    /**
     * 将 NAPI 对象转换为 mbgl::GeoJSONFeature
     */
    static mbgl::GeoJSONFeature convert(napi_env env, napi_value value);
    
    /**
     * 将 mbgl::Feature 向量转换为 NAPI 数组
     */
    static napi_value NewArray(napi_env env, const std::vector<mbgl::Feature>& features);
    
    /**
     * 将 mbgl::GeoJSONFeature 向量转换为 NAPI 数组
     */
    static napi_value NewArray(napi_env env, const std::vector<mbgl::GeoJSONFeature>& features);
};

} // namespace geojson
} // namespace harmony
} // namespace maplibre

