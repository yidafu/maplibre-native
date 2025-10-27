#pragma once

#include <napi/native_api.h>
#include <mbgl/util/feature.hpp>
#include <mbgl/util/geojson.hpp>

namespace maplibre {
namespace harmony {
namespace geojson {

/**
 * FeatureCollectionNAPI - FeatureCollection NAPI 类
 */
class FeatureCollectionNAPI {
public:
    FeatureCollectionNAPI();
    explicit FeatureCollectionNAPI(const std::vector<mbgl::GeoJSONFeature>& features);
    ~FeatureCollectionNAPI();
    
    static constexpr const char* Type() { return "FeatureCollection"; }
    
    // NAPI 注册
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value New(napi_env env, napi_callback_info info);
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // 实例方法
    static napi_value GetFeatures(napi_env env, napi_callback_info info);
    static napi_value SetFeatures(napi_env env, napi_callback_info info);
    static napi_value AddFeature(napi_env env, napi_callback_info info);
    static napi_value GetFeatureCount(napi_env env, napi_callback_info info);
    static napi_value ToJSON(napi_env env, napi_callback_info info);
    
    // 静态工厂方法
    static napi_value FromMbglFeatures(napi_env env, const std::vector<mbgl::Feature>& features);
    static napi_value FromMbglGeoJSONFeatures(napi_env env, const std::vector<mbgl::GeoJSONFeature>& features);
    
    // 转换方法
    static std::vector<mbgl::GeoJSONFeature> convert(napi_env env, napi_value value);
    static mbgl::FeatureCollection convertToFeatureCollection(napi_env env, napi_value value);
    
    // 内部方法
    std::vector<mbgl::GeoJSONFeature> toMbglFeatures() const { return features_; }
    
    static napi_ref constructor;
    
private:
    std::vector<mbgl::GeoJSONFeature> features_;
};

} // namespace geojson
} // namespace harmony
} // namespace maplibre
