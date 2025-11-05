/**
 * GeoJSON 类型定义
 *
 * 符合 GeoJSON 规范 (RFC 7946) 的类型定义
 * 
 * 注意：所有类型都从 libmaplibre.so 重新导出（已使用 I 前缀避免命名冲突）。
 * 这确保了 ETS 层和 C++ 层的类型定义完全一致。
 */

// ==================== 从 libmaplibre.so 导出所有 GeoJSON 类型 ====================

import type {
  Position,
  Position2D,
  Position3D,
  Geometry,
  IPoint,
  ILineString,
  IPolygon,
  IMultiPoint,
  IMultiLineString,
  IMultiPolygon,
  IGeometryCollection,
  IFeature,
  IFeatureCollection
} from 'libmaplibre.so';

// ==================== 重新导出所有类型 ====================

export type { Position, Position2D, Position3D };

export type { Geometry };

export type { IPoint };

export type { ILineString };

export type { IPolygon };

export type { IMultiPoint };

export type { IMultiLineString };

export type { IMultiPolygon };

export type { IGeometryCollection };

export type { IFeature };

export type { IFeatureCollection };
