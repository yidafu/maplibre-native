/**
 * GeoJSON Types - GeoJSON 类型导出
 * 
 * 直接导出 NAPI 类型，不进行封装
 */
import type maplibre from 'libmaplibre.so';

// 直接从 NAPI 层导出所有 GeoJSON 类型
export { 
  Point,
  LineString,
  Polygon,
  MultiPoint,
  MultiLineString,
  MultiPolygon,
  GeometryCollection,
  Feature,
  FeatureCollection
} from 'libmaplibre.so';

// Geometry 联合类型
export type Geometry = 
  | maplibre.Point 
  | maplibre.LineString 
  | maplibre.Polygon 
  | maplibre.MultiPoint 
  | maplibre.MultiLineString 
  | maplibre.MultiPolygon 
  | maplibre.GeometryCollection;
