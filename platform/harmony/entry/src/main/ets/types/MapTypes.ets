/**
 * MapTypes - 通用类型定义
 * 
 * 为测试页面提供通用的类型定义,避免 any 和 untyped object literal 错误
 */

/**
 * 坐标点接口
 */
export interface LatLngLiteral {
  latitude: number;
  longitude: number;
}

/**
 * 矩形接口
 */
export interface RectangleLiteral {
  left: number;
  top: number;
  right: number;
  bottom: number;
}

/**
 * 尺寸接口
 */
export interface Size {
  width: number;
  height: number;
}

/**
 * 边距接口
 */
export interface Padding {
  top: number;
  left: number;
  bottom: number;
  right: number;
}

/**
 * 相机选项接口 (用于测试页面)
 */
export interface CameraOptionsLiteral {
  center?: LatLngLiteral;
  zoom?: number;
  bearing?: number;
  pitch?: number;
  padding?: Padding;
}

/**
 * 相机选项（兼容 NAPI）
 * 注意：使用 ESObject 以兼容 maplibre.LatLng
 */
export interface CameraOptions {
  center?: ESObject;
  zoom?: number;
  bearing?: number;
  pitch?: number;
  padding?: number[];
}

/**
 * GeoJSON Geometry 类型
 */
export interface GeoJsonGeometry {
  type: string;
  coordinates: number[] | number[][] | number[][][];
}

/**
 * GeoJSON Properties
 */
export interface GeoJsonProperties {
  name?: string;
  type?: string;
  value?: number;
  intensity?: number;
  height?: number;
}

/**
 * GeoJSON Feature
 */
export interface GeoJsonFeature {
  type: string;
  geometry: GeoJsonGeometry;
  properties?: GeoJsonProperties;
}

/**
 * GeoJSON FeatureCollection
 */
export interface GeoJsonFeatureCollection {
  type: string;
  features: GeoJsonFeature[];
}

