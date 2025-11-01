#pragma once

#include <napi/native_api.h>
#include <mbgl/util/feature.hpp>
#include <mbgl/util/geometry.hpp>
#include <mbgl/util/geojson.hpp>
#include <vector>

namespace maplibre {
namespace harmony {
namespace geojson {

/**
 * GeoJSON 转换器 - 在 JavaScript 对象和 C++ GeoJSON 类型之间进行转换
 * 
 * 此转换器替代了原有的 NAPI 类绑定，使用普通的 JS 对象
 * 来表示 GeoJSON 数据结构。
 */
class GeoJsonConverter {
public:
    // ==================== JS 对象 -> C++ ====================
    
    /**
     * 将 JS 对象转换为 mbgl::Geometry
     * 
     * @param env NAPI 环境
     * @param jsObj JS 对象，应该包含 type 和 coordinates 字段
     * @return mbgl::Geometry<double>
     * @throws std::runtime_error 如果对象格式不正确
     */
    static mbgl::Geometry<double> JsObjectToGeometry(napi_env env, napi_value jsObj);
    
    /**
     * 将 JS 对象转换为 mbgl::Feature
     * 
     * @param env NAPI 环境
     * @param jsObj JS 对象，应该包含 type, geometry, properties 字段
     * @return mbgl::Feature
     * @throws std::runtime_error 如果对象格式不正确
     */
    static mbgl::Feature JsObjectToFeature(napi_env env, napi_value jsObj);
    
    /**
     * 将 JS 对象转换为 mbgl::FeatureCollection
     * 
     * @param env NAPI 环境
     * @param jsObj JS 对象，应该包含 type 和 features 字段
     * @return mbgl::FeatureCollection
     * @throws std::runtime_error 如果对象格式不正确
     */
    static mbgl::FeatureCollection JsObjectToFeatureCollection(napi_env env, napi_value jsObj);
    
    /**
     * 将 JS 对象转换为 mbgl::GeoJSON（通用转换）
     * 
     * @param env NAPI 环境
     * @param jsObj JS 对象，可以是 Geometry、Feature 或 FeatureCollection
     * @return mbgl::GeoJSON
     * @throws std::runtime_error 如果对象格式不正确
     */
    static mbgl::GeoJSON JsObjectToGeoJSON(napi_env env, napi_value jsObj);
    
    // ==================== C++ -> JS 对象 ====================
    
    /**
     * 将 mbgl::Geometry 转换为 JS 对象
     * 
     * @param env NAPI 环境
     * @param geometry C++ Geometry 对象
     * @return napi_value JS 对象
     */
    static napi_value GeometryToJsObject(napi_env env, const mbgl::Geometry<double>& geometry);
    
    /**
     * 将 mbgl::Feature 转换为 JS 对象
     * 
     * @param env NAPI 环境
     * @param feature C++ Feature 对象
     * @return napi_value JS 对象
     */
    static napi_value FeatureToJsObject(napi_env env, const mbgl::Feature& feature);
    
    /**
     * 将 mbgl::FeatureCollection 转换为 JS 对象
     * 
     * @param env NAPI 环境
     * @param features C++ FeatureCollection
     * @return napi_value JS 对象
     */
    static napi_value FeatureCollectionToJsObject(napi_env env, const mbgl::FeatureCollection& features);
    
    /**
     * 将 Feature 数组转换为 JS 数组
     * 
     * @param env NAPI 环境
     * @param features C++ Feature 向量
     * @return napi_value JS 数组
     */
    static napi_value FeatureArrayToJsArray(napi_env env, const std::vector<mbgl::Feature>& features);

private:
    // 辅助方法：根据 type 字段解析 Geometry
    static mbgl::Geometry<double> ParseGeometryByType(napi_env env, napi_value jsObj, const std::string& type);
    
    // 辅助方法：创建 Geometry JS 对象
    static napi_value CreateGeometryJsObject(napi_env env, const std::string& type, napi_value coordinates);
    
    // Geometry 类型解析方法
    static mbgl::Point<double> ParsePoint(napi_env env, napi_value coordinates);
    static mbgl::LineString<double> ParseLineString(napi_env env, napi_value coordinates);
    static mbgl::Polygon<double> ParsePolygon(napi_env env, napi_value coordinates);
    static mbgl::MultiPoint<double> ParseMultiPoint(napi_env env, napi_value coordinates);
    static mbgl::MultiLineString<double> ParseMultiLineString(napi_env env, napi_value coordinates);
    static mbgl::MultiPolygon<double> ParseMultiPolygon(napi_env env, napi_value coordinates);
    static mapbox::geometry::geometry_collection<double> ParseGeometryCollection(napi_env env, napi_value geometries);
    
    // Geometry 类型转换为 JS 方法
    static napi_value PointToJsObject(napi_env env, const mbgl::Point<double>& point);
    static napi_value LineStringToJsObject(napi_env env, const mbgl::LineString<double>& lineString);
    static napi_value PolygonToJsObject(napi_env env, const mbgl::Polygon<double>& polygon);
    static napi_value MultiPointToJsObject(napi_env env, const mbgl::MultiPoint<double>& multiPoint);
    static napi_value MultiLineStringToJsObject(napi_env env, const mbgl::MultiLineString<double>& multiLineString);
    static napi_value MultiPolygonToJsObject(napi_env env, const mbgl::MultiPolygon<double>& multiPolygon);
    static napi_value GeometryCollectionToJsObject(napi_env env, const mapbox::geometry::geometry_collection<double>& collection);
};

} // namespace geojson
} // namespace harmony
} // namespace maplibre

