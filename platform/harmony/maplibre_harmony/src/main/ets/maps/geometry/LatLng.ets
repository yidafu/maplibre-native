/**
 * LatLng - 经纬度坐标
 * 使用 NAPI 模块中的类定义
 */
import maplibre from 'libmaplibre_native.so';

export type LatLng = maplibre.LatLng;

/**
 * 创建 LatLng 对象
 */
export function createLatLng(latitude: number, longitude: number): LatLng {
  return new maplibre.LatLng(latitude, longitude);
}

/**
 * 检查坐标是否有效
 */
export function isValidLatLng(latLng: LatLng): boolean {
  return latLng.latitude >= -90 && latLng.latitude <= 90 && 
         latLng.longitude >= -180 && latLng.longitude <= 180;
}

/**
 * 计算两点之间的距离（米）
 */
export function distanceBetween(from: LatLng, to: LatLng): number {
  const R = 6371000; // 地球半径（米）
  const dLat = toRadians(to.latitude - from.latitude);
  const dLon = toRadians(to.longitude - from.longitude);
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(toRadians(from.latitude)) * Math.cos(toRadians(to.latitude)) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/**
 * 比较两个坐标是否相等
 */
export function latLngEquals(a: LatLng, b: LatLng): boolean {
  return Math.abs(a.latitude - b.latitude) < 1e-10 &&
         Math.abs(a.longitude - b.longitude) < 1e-10;
}

/**
 * 角度转弧度
 */
function toRadians(degrees: number): number {
  return degrees * (Math.PI / 180);
}
