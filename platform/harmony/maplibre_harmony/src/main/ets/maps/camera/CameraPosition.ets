/**
 * CameraPosition - 相机位置
 * 使用 NAPI 模块中的类型定义
 */
import { LatLng } from '../geometry/LatLng';
import maplibre from 'libmaplibre.so';

/**
 * EdgeInsets - 边距接口
 * 使用 NAPI 模块中的类型定义
 */
export type EdgeInsets = maplibre.EdgeInsets;

/**
 * CameraPosition - 相机位置
 * 使用 NAPI 模块中的类型定义
 */
export type CameraPosition = maplibre.CameraPosition;

/**
 * 创建相机位置（从经纬度和缩放级别）
 */
export function createCameraPosition(
  target: LatLng, 
  zoom: number, 
  bearing: number = 0, 
  tilt: number = 0
): CameraPosition {
  return { target, zoom, bearing, tilt };
}

/**
 * 比较两个相机位置是否相等
 */
export function cameraPositionEquals(a: CameraPosition, b: CameraPosition): boolean {
  return Math.abs(a.target.latitude - b.target.latitude) < 1e-10 &&
         Math.abs(a.target.longitude - b.target.longitude) < 1e-10 &&
         Math.abs(a.zoom - b.zoom) < 1e-10 &&
         Math.abs(a.bearing - b.bearing) < 1e-10 &&
         Math.abs(a.tilt - b.tilt) < 1e-10;
}
