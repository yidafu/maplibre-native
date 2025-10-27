/**
 * GeoJSON 类型定义
 * 所有 GeoJSON 类型都由 C++ NAPI 层实现
 */

// 基础几何类型
export { Point } from './Point';
export { LineString } from './LineString';
export { Polygon } from './Polygon';

// Multi* 几何类型
export { MultiPoint } from './MultiPoint';
export { MultiLineString } from './MultiLineString';
export { MultiPolygon } from './MultiPolygon';

// GeometryCollection
export { GeometryCollection } from './GeometryCollection';

// Feature 类型
export { Feature } from './Feature';
export { FeatureCollection } from './FeatureCollection';

// Geometry 联合类型和辅助类型
export { 
  Geometry, 
  Position, 
  Position2D, 
  Position3D, 
  GeoJSONObject 
} from './Geometry';

