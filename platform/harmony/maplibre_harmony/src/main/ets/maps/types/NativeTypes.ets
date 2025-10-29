/**
 * NativeTypes - 原生类型和辅助类型导出
 * 
 * 1. 导出 NAPI 提供的 maplibre namespace
 * 2. 提供辅助类型定义（用于测试页面和应用开发）
 */

import maplibre from 'libmaplibre.so';

// ========== 导出 maplibre namespace ==========
export { maplibre };

// ========== 辅助类型定义 ==========

/**
 * 坐标点字面量接口
 */
export interface LatLngLiteral {
  latitude: number;
  longitude: number;
}

/**
 * 矩形字面量接口
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
 * 相机选项字面量接口（用于测试页面）
 */
export interface CameraOptionsLiteral {
  center?: LatLngLiteral;
  zoom?: number;
  bearing?: number;
  pitch?: number;
  padding?: Padding;
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

