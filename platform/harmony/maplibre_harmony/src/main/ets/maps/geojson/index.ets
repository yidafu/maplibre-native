/**
 * GeoJSON 模块
 * 所有 GeoJSON 类型都由 NAPI 导出，直接从 C++ 层实现
 * 
 * 使用方式：
 * - 类型注解：使用导出的类型别名，如 `const feature: Feature = ...`
 * - 创建实例：需要导入 maplibre，如 `new maplibre.Point(120, 30)`
 */

import maplibre from 'libmaplibre.so';

// 导出类型别名（用于类型注解）
export type Point = maplibre.Point;
export type LineString = maplibre.LineString;
export type Polygon = maplibre.Polygon;
export type MultiPoint = maplibre.MultiPoint;
export type MultiLineString = maplibre.MultiLineString;
export type MultiPolygon = maplibre.MultiPolygon;
export type GeometryCollection = maplibre.GeometryCollection;
export type Feature = maplibre.Feature;
export type FeatureCollection = maplibre.FeatureCollection;

// 导出 Geometry 联合类型
export type Geometry = Point | LineString | Polygon | MultiPoint | MultiLineString | MultiPolygon | GeometryCollection;
