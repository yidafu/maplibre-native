/**
 * Entry 模块类型定义
 * 
 * 为测试页面提供通用的类型定义，避免 ArkTS 类型限制错误
 */
import type { JSONValue } from 'libmaplibre.so';

// ==================== 通用类型别名 ====================

/**
 * JSON 对象类型 - 替代 any/unknown
 */
export type JsonObject = Record<string, JSONValue>;

/**
 * 属性映射类型 - 用于 GeoJSON properties 等
 */
export type PropertiesMap = Record<string, JSONValue>;

/**
 * 配置选项类型
 */
export type ConfigOptions = Record<string, Object>;

// ==================== GeoJSON 相关接口 ====================

/**
 * IFeatureSource 接口
 * 用于替代 maplibre_harmony 未导出的类型
 */
export interface IFeatureSource {
  setGeoJson(data: Object): void;
  getGeoJson?(): Object;
}

/**
 * GeoJSON Feature 选项接口
 */
export interface GeoJsonFeatureOptions {
  type: string;
  geometry?: Object;
  properties?: PropertiesMap;
  id?: string | number;
}

// ==================== 样式相关接口 ====================

/**
 * 地图样式选项接口
 */
export interface MapStyleOptions {
  sources?: Record<string, Object>;
  layers?: Array<Object>;
  version?: number;
  name?: string;
  metadata?: Record<string, Object>;
}

/**
 * 图层属性选项 - 使用 Record 类型替代
 */
export type LayerPropertyOptions = Record<string, Object>;

/**
 * 图层布局选项接口
 */
export class LayerLayoutOptions {
  visibility?: string;
}

/**
 * 图层绘制选项接口
 */
export class LayerPaintOptions {}

// ==================== 位置相关接口 ====================

/**
 * 位置配置接口
 */
export interface LocationConfig {
  latitude: number;
  longitude: number;
  accuracy?: number;
  altitude?: number;
  bearing?: number;
  speed?: number;
}

/**
 * 地图变化事件接口
 */
export interface MapChangeEvent {
  type: string;
  reason?: string;
  animated?: boolean;
}

/**
 * 位置信息接口
 */
export interface LocationInfo {
  latitude: number;
  longitude: number;
  zoom?: number;
  bearing?: number;
  tilt?: number;
  name?: string;
}

// ==================== 信息窗口相关接口 ====================

/**
 * 信息窗口数据接口
 */
export class InfoWindowData {
  title?: string = '';
  content?: string = '';
}

/**
 * 动态信息窗口数据接口
 */
export interface DynamicInfoData {
  id: string | number;
  title: string;
  description?: string;
  data?: PropertiesMap;
}

// ==================== 测试页面相关接口 ====================

/**
 * 测试结果接口
 */
export interface TestResult {
  success: boolean;
  message: string;
  timestamp?: number;
  data?: Object;
}

/**
 * 测试配置接口
 */
export interface TestConfig {
  enabled: boolean;
  name: string;
  options?: ConfigOptions;
}

// ==================== 离线地图相关接口 ====================

/**
 * 离线区域元数据接口
 */
export class OfflineRegionMetadata {
  name: string = '';
  description?: string;
  created?: number;
  modified?: number;
}

// ==================== 快照相关接口 ====================

/**
 * 快照位置信息接口（扩展）
 */
export interface SnapshotLocationInfo extends LocationInfo {
  latitude: number;
  longitude: number;
  zoom?: number;
  name?: string;
}

// ==================== 样式属性相关接口 ====================

/**
 * 圆形图层属性接口
 */
export class CircleLayerProperties {
  'circle-radius'?: number | Object;
  'circle-color'?: string | Object;
  'circle-opacity'?: number | Object;
  'circle-stroke-width'?: number | Object;
  'circle-stroke-color'?: string | Object;
  'circle-stroke-opacity'?: number | Object;
}

/**
 * 线条图层属性接口
 */
export class LineLayerProperties {
  'line-width'?: number | Object;
  'line-color'?: string | Object;
  'line-opacity'?: number | Object;
  'line-dasharray'?: number[] | Object;
  'line-gap-width'?: number | Object;
  'line-gradient'?: string | Object;
}

/**
 * 填充图层属性接口
 */
export class FillLayerProperties {
  'fill-color'?: string | Object;
  'fill-opacity'?: number | Object;
  'fill-outline-color'?: string | Object;
  'fill-antialias'?: boolean | Object;
}

/**
 * 符号图层属性接口
 */
export class SymbolLayerProperties {
  'icon-image'?: string | Object;
  'icon-size'?: number | Object;
  'icon-opacity'?: number | Object;
  'text-field'?: string | Object;
  'text-size'?: number | Object;
  'text-color'?: string | Object;
}

// ==================== 事件监听器相关类型 ====================

/**
 * 事件处理器类型
 */
export type EventHandler = (event: Object) => void;

/**
 * 地图事件类型
 */
export type MapEventType = 
  | 'click'
  | 'longpress'
  | 'move'
  | 'zoom'
  | 'rotate'
  | 'tilt'
  | 'load'
  | 'error';

