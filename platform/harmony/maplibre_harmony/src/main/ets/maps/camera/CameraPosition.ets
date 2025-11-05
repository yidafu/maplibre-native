/**
 * CameraPosition - 相机位置
 * 简化为 interface 实现，符合 ArkTS 规范
 */
import { LatLng } from '../geometry/LatLng';

/**
 * EdgeInsets - 边距接口
 * 表示矩形的内边距
 */
export interface EdgeInsets {
  top: number;
  left: number;
  bottom: number;
  right: number;
}

/**
 * CameraPosition - 相机位置接口
 * 表示地图相机的位置和方向
 * 
 * @example
 * ```typescript
 * const position: CameraPosition = {
 *   target: { latitude: 39.9, longitude: 116.4 },
 *   zoom: 15,
 *   bearing: 30,  // 方向角度（0-360度，0表示正北）
 *   tilt: 45      // 倾斜角度（0-60度，0表示垂直俯视）
 * };
 * ```
 */
export interface CameraPosition {
  /** 目标位置（经纬度） */
  target: LatLng;
  /** 缩放级别 */
  zoom: number;
  /** 方向角度（0-360度，0表示正北） */
  bearing: number;
  /** 倾斜角度（0-60度，0表示垂直俯视） */
  tilt: number;
}

/**
 * CameraOptions - 相机选项接口
 * 用于设置相机参数（与 NAPI CameraOptions 接口兼容）
 */
export interface CameraOptions {
  /** 中心点坐标 */
  center?: LatLng;

  /** 缩放级别 */
  zoom?: number;

  /** 方位角（度） */
  bearing?: number;

  /** 俯仰角/倾斜角（度） */
  pitch?: number;

  /** 边距 */
  padding?: EdgeInsets;
}

