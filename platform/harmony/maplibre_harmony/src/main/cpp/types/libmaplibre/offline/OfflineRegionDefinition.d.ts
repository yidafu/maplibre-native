/**
 * OfflineRegionDefinition - 离线区域定义类型
 *
 * 此文件定义了离线地图区域的结构，用于指定需要下载的地图范围和参数
 */

/**
 * 地理边界
 *
 * 定义一个矩形地理区域，使用经纬度坐标
 */
export interface LatLngBounds {
  /** 北纬（最大纬度，范围：-90 到 90） */
  north: number;

  /** 南纬（最小纬度，范围：-90 到 90） */
  south: number;

  /** 东经（最大经度，范围：-180 到 180） */
  east: number;

  /** 西经（最小经度，范围：-180 到 180） */
  west: number;
}

/**
 * GeoJSON 几何体类型
 *
 * 支持 Point、LineString、Polygon、MultiPoint、MultiLineString、MultiPolygon
 */
export interface GeoJSONGeometry {
  /** 几何体类型 */
  type: 'Point' | 'LineString' | 'Polygon' | 'MultiPoint' | 'MultiLineString' | 'MultiPolygon' | 'GeometryCollection';

  /** 坐标数组（格式取决于类型） */
  coordinates?: number[] | number[][] | number[][][];

  /** 几何体集合（仅用于 GeometryCollection） */
  geometries?: GeoJSONGeometry[];
}

/**
 * 基于瓦片金字塔的离线区域定义
 *
 * 使用矩形边界定义离线区域，适用于大部分场景
 * 下载指定缩放级别范围内的所有瓦片
 */
export interface OfflineTilePyramidRegionDefinition {
  /** 类型标识 */
  type: 'tilePyramid';

  /**
   * 地图样式 URL
   * 例如: "https://demotiles.maplibre.org/style.json"
   */
  styleURL: string;

  /**
   * 地理边界
   * 定义要下载的矩形区域
   */
  bounds: LatLngBounds;

  /**
   * 最小缩放级别（包含）
   * 范围：0-22，通常使用 0-16
   */
  minZoom: number;

  /**
   * 最大缩放级别（包含）
   * 范围：0-22，通常使用 0-16
   * 注意：缩放级别越高，下载的瓦片数量越多
   */
  maxZoom: number;

  /**
   * 设备像素比例
   * 通常为 1.0、2.0 或 3.0
   * 高像素比会下载更高分辨率的瓦片
   */
  pixelRatio: number;

  /**
   * 是否包含表意文字字形（CJK 字体）
   * true: 下载中日韩文字字形（增加下载量）
   * false: 不下载表意文字字形
   */
  includeIdeographs: boolean;
}

/**
 * 基于几何体的离线区域定义
 *
 * 使用 GeoJSON 几何体定义离线区域，支持复杂形状
 * 适用于需要精确控制下载范围的场景
 */
export interface OfflineGeometryRegionDefinition {
  /** 类型标识 */
  type: 'geometry';

  /**
   * 地图样式 URL
   * 例如: "https://demotiles.maplibre.org/style.json"
   */
  styleURL: string;

  /**
   * GeoJSON 几何体
   * 支持 Polygon、MultiPolygon 等类型
   * 只有与几何体相交的瓦片会被下载
   * 类型为 GeoJSONGeometry 或兼容的几何体对象
   */
  geometry: GeoJSONGeometry | object;

  /**
   * 最小缩放级别（包含）
   * 范围：0-22
   */
  minZoom: number;

  /**
   * 最大缩放级别（包含）
   * 范围：0-22
   */
  maxZoom: number;

  /**
   * 设备像素比例
   * 通常为 1.0、2.0 或 3.0
   */
  pixelRatio: number;

  /**
   * 是否包含表意文字字形（CJK 字体）
   * true: 下载中日韩文字字形
   * false: 不下载表意文字字形
   */
  includeIdeographs: boolean;
}

/**
 * 离线区域定义联合类型
 *
 * 可以是瓦片金字塔定义或几何体定义
 */
export type OfflineRegionDefinition =
  | OfflineTilePyramidRegionDefinition
    | OfflineGeometryRegionDefinition;

