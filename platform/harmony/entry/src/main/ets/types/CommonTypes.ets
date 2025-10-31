/**
 * 通用类型定义
 * 用于测试页面的常见数据结构
 */

/**
 * GeoJSON 相关类型
 */
export interface GeoJsonGeometry {
  type: string;
  coordinates: number[] | number[][] | number[][][];
}

export interface GeoJsonProperties {
  [key: string]: string | number | boolean;
}

export interface GeoJsonFeature {
  type: string;
  geometry: GeoJsonGeometry;
  properties?: GeoJsonProperties;
}

export interface GeoJsonFeatureCollection {
  type: string;
  features: GeoJsonFeature[];
}

/**
 * 位置数据类型
 */
export interface LocationData {
  name: string;
  latitude: number;
  longitude: number;
  zoom?: number;
  description?: string;
}

/**
 * 城市数据类型
 */
export interface CityData {
  name: string;
  lat: number;
  lng: number;
  zoom?: number;
}

/**
 * 相机配置类型
 */
export interface CameraConfig {
  latitude: number;
  longitude: number;
  zoom: number;
  bearing?: number;
  pitch?: number;
}

/**
 * 标记配置类型
 */
export interface MarkerConfig {
  id?: string;
  title?: string;
  snippet?: string;
  latitude: number;
  longitude: number;
  draggable?: boolean;
  iconId?: string;
}

/**
 * 测试配置类型
 */
export interface TestConfig {
  name: string;
  description: string;
  enabled: boolean;
}

/**
 * 键值对类型
 */
export interface KeyValuePair {
  key: string;
  value: string | number;
}

/**
 * 样式配置类型
 */
export interface StyleConfig {
  id: string;
  name: string;
  url: string;
  description?: string;
}

/**
 * 动画配置类型
 */
export interface AnimationConfig {
  duration: number;
  delay?: number;
  easing?: string;
}

