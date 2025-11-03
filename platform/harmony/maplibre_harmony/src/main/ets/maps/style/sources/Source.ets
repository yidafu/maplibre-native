/**
 * Source - 数据源类型定义
 *
 * 数据源由 NAPI 层提供，此文件提供辅助类型定义和联合类型
 */

import type { GeoJsonSource } from './GeoJsonSource';
import type { VectorSource } from './VectorSource';
import type { RasterSource } from './RasterSource';
import type { RasterDemSource } from './RasterDemSource';
import type { ImageSource } from './ImageSource';
/**
 * Source - 所有数据源类型的联合类型
 *
 * 这个联合类型包含了所有可能的数据源类型，用于类型安全的数据源操作
 */
export type Source =
  | GeoJsonSource
    | VectorSource
    | RasterSource
    | RasterDemSource
    | ImageSource;

/**
 * SourceData - 数据源数据类型
 */
export type SourceData = Object | string | null;

/**
 * SourceMetadata - 数据源元数据类型
 */
export type SourceMetadata = Record<string, Object> | null;

/**
 * ClusterProperties - 聚合属性类型
 */
export type ClusterProperties = Record<string, Object> | null;

/**
 * SourceOptions - 数据源选项接口
 *
 * 用于构建数据源的配置选项
 */
export interface SourceOptions {
  /** 数据源 ID */
  id: string;

  /** 数据源类型: 'vector', 'raster', 'raster-dem', 'geojson', 'image', 'video' */
  type: string;

  /** 数据 (GeoJSON 数据源) */
  data?: SourceData;

  /** 最小缩放级别 */
  minZoom?: number;

  /** 最大缩放级别 */
  maxZoom?: number;

  /** 版权信息 */
  attribution?: string;

  /** 边界 [west, south, east, north] */
  bounds?: number[];

  /** 是否启用聚类 (GeoJSON) */
  cluster?: boolean;

  /** 聚类最大缩放级别 */
  clusterMaxZoom?: number;

  /** 聚类半径 (像素) */
  clusterRadius?: number;

  /** 聚类最小点数 */
  clusterMinPoints?: number;

  /** 聚类属性 */
  clusterProperties?: ClusterProperties;

  /** 是否生成要素 ID */
  generateId?: boolean;

  /** 提升为 ID 的属性名 */
  promoteId?: string;

  /** 几何简化容差 */
  tolerance?: number;

  /** 瓦片缓冲区 */
  buffer?: number;

  /** 是否启用线度量 */
  lineMetrics?: boolean;

  /** 最大缩放级别 (瓦片源) */
  maxzoom?: number;

  /** 瓦片大小 */
  tileSize?: number;

  /** TileJSON URL */
  url?: string;

  /** 瓦片 URL 模板列表 */
  tiles?: string[];

  /** 瓦片方案: 'xyz' 或 'tms' */
  scheme?: string;

  /** 元数据 */
  metadata?: SourceMetadata;
}
