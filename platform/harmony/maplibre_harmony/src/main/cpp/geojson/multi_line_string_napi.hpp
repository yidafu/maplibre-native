#pragma once

#include <napi/native_api.h>
#include <mbgl/util/geometry.hpp>

namespace maplibre {
namespace harmony {
namespace geojson {

/**
 * MultiLineStringNAPI - MultiLineString 几何体 NAPI 类
 */
class MultiLineStringNAPI {
public:
    MultiLineStringNAPI();
    explicit MultiLineStringNAPI(const mbgl::MultiLineString<double>& multiLineString);
    explicit MultiLineStringNAPI(const std::vector<mbgl::LineString<double>>& lineStrings);
    ~MultiLineStringNAPI();
    
    static constexpr const char* Type() { return "MultiLineString"; }
    
    // NAPI 注册
    static napi_value Init(napi_env env, napi_value exports);
    static napi_value New(napi_env env, napi_callback_info info);
    
    // 工厂方法：从 mbgl::MultiLineString 创建 NAPI 实例
    static napi_value New(napi_env env, const mbgl::MultiLineString<double>& multiLineString);
    
    static void Destructor(napi_env env, void* nativeObject, void* finalize_hint);
    
    // 实例方法
    static napi_value GetCoordinates(napi_env env, napi_callback_info info);
    static napi_value SetCoordinates(napi_env env, napi_callback_info info);
    static napi_value ToJSON(napi_env env, napi_callback_info info);
    
    // 静态工厂方法
    static napi_value FromMbglMultiLineString(napi_env env, const mbgl::MultiLineString<double>& multiLineString);
    
    // 转换方法
    static mbgl::MultiLineString<double> convert(napi_env env, napi_value value);
    
    // 内部方法
    mbgl::MultiLineString<double> toMbglMultiLineString() const { return lineStrings_; }
    
    static napi_ref constructor;
    
private:
    mbgl::MultiLineString<double> lineStrings_;
};

} // namespace geojson
} // namespace harmony
} // namespace maplibre
