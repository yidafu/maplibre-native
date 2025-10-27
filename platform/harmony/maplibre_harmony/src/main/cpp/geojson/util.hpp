#pragma once

#include <napi/native_api.h>
#include <mbgl/util/feature.hpp>
#include <mbgl/util/geometry.hpp>
#include <vector>
#include <string>

namespace maplibre {
namespace harmony {
namespace geojson {

/**
 * 将 NAPI 数组转换为 double 向量
 */
std::vector<double> NapiArrayToDoubleVector(napi_env env, napi_value array);

/**
 * 将 NAPI 数组转换为坐标点向量
 */
std::vector<mbgl::Point<double>> NapiArrayToPointVector(napi_env env, napi_value array);

/**
 * 将 NAPI 数组转换为 LineString 向量
 */
std::vector<mbgl::LineString<double>> NapiArrayToLineStringVector(napi_env env, napi_value array);

/**
 * 将 NAPI 数组转换为 LinearRing 向量 (用于单个 Polygon)
 */
std::vector<mbgl::LinearRing<double>> NapiArrayToLinearRingVector(napi_env env, napi_value array);

/**
 * 将 NAPI 数组转换为 Polygon 向量
 */
std::vector<mbgl::Polygon<double>> NapiArrayToPolygonVector(napi_env env, napi_value array);

/**
 * 将 double 向量转换为 NAPI 数组
 */
napi_value DoubleVectorToNapiArray(napi_env env, const std::vector<double>& vec);

/**
 * 将坐标点向量转换为 NAPI 数组
 */
napi_value PointVectorToNapiArray(napi_env env, const std::vector<mbgl::Point<double>>& points);

/**
 * 将 LineString 向量转换为 NAPI 数组
 */
napi_value LineStringVectorToNapiArray(napi_env env, const std::vector<mbgl::LineString<double>>& lineStrings);

/**
 * 将 LinearRing 向量转换为 NAPI 数组 (用于单个 Polygon 的环)
 */
napi_value LinearRingVectorToNapiArray(napi_env env, const std::vector<mbgl::LinearRing<double>>& rings);

/**
 * 将 Polygon 向量转换为 NAPI 数组
 */
napi_value PolygonVectorToNapiArray(napi_env env, const std::vector<mbgl::Polygon<double>>& polygons);

/**
 * 将 mbgl::PropertyMap 转换为 NAPI 对象
 */
napi_value PropertyMapToNapiObject(napi_env env, const mbgl::PropertyMap& properties);

/**
 * 将 NAPI 对象转换为 mbgl::PropertyMap
 */
mbgl::PropertyMap NapiObjectToPropertyMap(napi_env env, napi_value obj);

/**
 * 将 mbgl::Value 转换为 NAPI value
 */
napi_value MbglValueToNapiValue(napi_env env, const mbgl::Value& value);

/**
 * 将 NAPI value 转换为 mbgl::Value
 */
mbgl::Value NapiValueToMbglValue(napi_env env, napi_value value);

/**
 * 获取对象的字符串属性
 */
std::string GetStringProperty(napi_env env, napi_value obj, const char* key);

/**
 * 获取对象的数字属性
 */
double GetNumberProperty(napi_env env, napi_value obj, const char* key);

/**
 * 获取对象的对象属性
 */
napi_value GetObjectProperty(napi_env env, napi_value obj, const char* key);

/**
 * 检查对象是否有指定属性
 */
bool HasProperty(napi_env env, napi_value obj, const char* key);

/**
 * 检查值的类型
 */
bool IsString(napi_env env, napi_value value);
bool IsNumber(napi_env env, napi_value value);
bool IsArray(napi_env env, napi_value value);
bool IsObject(napi_env env, napi_value value);
bool IsNull(napi_env env, napi_value value);
bool IsUndefined(napi_env env, napi_value value);

} // namespace geojson
} // namespace harmony
} // namespace maplibre

