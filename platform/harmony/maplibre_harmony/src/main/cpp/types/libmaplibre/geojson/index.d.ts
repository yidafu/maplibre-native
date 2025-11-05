/**
 * GeoJSON 类型定义
 * 
 * 所有 GeoJSON 类型都是 interface（C++ 层返回普通 JS 对象）。
 * 使用 I 前缀导出以避免与其他模块的类名冲突（如 annotations.Polygon）。
 */

// 基础几何类型 - 使用 I 前缀导出
export { Point as IPoint } from './Point';

export { LineString as ILineString } from './LineString';

export { Polygon as IPolygon } from './Polygon';

// Multi* 几何类型 - 使用 I 前缀导出
export { MultiPoint as IMultiPoint } from './MultiPoint';

export { MultiLineString as IMultiLineString } from './MultiLineString';

export { MultiPolygon as IMultiPolygon } from './MultiPolygon';

// GeometryCollection - 使用 I 前缀导出
export { GeometryCollection as IGeometryCollection } from './GeometryCollection';

// Feature 类型 - 使用 I 前缀导出
export { Feature as IFeature } from './Feature';

export { FeatureCollection as IFeatureCollection } from './FeatureCollection';

// Geometry 联合类型和辅助类型
export {
  Geometry, Position, Position2D, Position3D, GeoJSONObject
} from './Geometry';

