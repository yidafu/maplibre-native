#pragma once

#include <napi/native_api.h>
#include <mbgl/util/feature.hpp>

namespace maplibre {
namespace harmony {
namespace geojson {

/**
 * FeatureNAPI - Feature NAPI 类
 */
class FeatureNAPI {
public:
    FeatureNAPI();
    explicit FeatureNAPI(const mbgl::GeoJSONFeature& feature);
    ~FeatureNAPI();
    
    static constexpr const char* Type() { return "Feature"; }
    
    // NAPI 注册
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value New(napi_env env, napi_callback_info info);
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // 实例方法
    static napi_value GetId(napi_env env, napi_callback_info info);
    static napi_value SetId(napi_env env, napi_callback_info info);
    static napi_value GetProperties(napi_env env, napi_callback_info info);
    static napi_value SetProperties(napi_env env, napi_callback_info info);
    static napi_value GetGeometry(napi_env env, napi_callback_info info);
    static napi_value SetGeometry(napi_env env, napi_callback_info info);
    static napi_value ToJSON(napi_env env, napi_callback_info info);
    
    // 静态工厂方法
    static napi_value FromMbglFeature(napi_env env, const mbgl::GeoJSONFeature& feature);
    static napi_value FromMbglFeature(napi_env env, const mbgl::Feature& feature);
    
    // 转换方法
    static mbgl::GeoJSONFeature convert(napi_env env, napi_value value);
    static napi_value NewArray(napi_env env, const std::vector<mbgl::Feature>& features);
    static napi_value NewArray(napi_env env, const std::vector<mbgl::GeoJSONFeature>& features);
    
    // 内部方法
    mbgl::GeoJSONFeature toMbglFeature() const { return feature_; }
    
    static napi_ref constructor;
    
private:
    mbgl::GeoJSONFeature feature_;
};

} // namespace geojson
} // namespace harmony
} // namespace maplibre
