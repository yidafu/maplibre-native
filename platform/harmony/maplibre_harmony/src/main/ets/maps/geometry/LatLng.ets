/**
 * LatLng - 经纬度坐标
 * 
 * 必须使用 new maplibre.LatLng(latitude, longitude) 创建
 * 不再支持普通对象 {latitude, longitude}
 * 
 * @example
 * ```typescript
 * // ✅ 正确用法
 * const position = new maplibre.LatLng(39.9042, 116.4074);
 * 
 * // ❌ 不再支持（会导致运行时错误）
 * const position = {latitude: 39.9042, longitude: 116.4074};
 * ```
 */
import maplibre from 'libmaplibre.so';

// 直接导出NAPI类，不使用type别名
export { LatLng } from 'libmaplibre.so';

/**
 * 创建 LatLng 对象
 * 
 * @param latitude 纬度 (-90 到 90)
 * @param longitude 经度 (-180 到 180)
 * @returns LatLng NAPI类实例
 */
export function createLatLng(latitude: number, longitude: number): maplibre.LatLng {
  return new maplibre.LatLng(latitude, longitude);
}

/**
 * 检查坐标是否有效
 * 
 * @param latLng LatLng NAPI类实例
 * @returns 坐标是否在有效范围内
 */
export function isValidLatLng(latLng: maplibre.LatLng): boolean {
  return latLng.latitude >= -90 && latLng.latitude <= 90 && 
         latLng.longitude >= -180 && latLng.longitude <= 180;
}

/**
 * 计算两点之间的距离（米）
 * 
 * @param from 起点 LatLng NAPI类实例
 * @param to 终点 LatLng NAPI类实例
 * @returns 距离（米）
 */
export function distanceBetween(from: maplibre.LatLng, to: maplibre.LatLng): number {
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
 * 
 * @param a LatLng NAPI类实例
 * @param b LatLng NAPI类实例  
 * @returns 是否相等
 */
export function latLngEquals(a: maplibre.LatLng, b: maplibre.LatLng): boolean {
  return Math.abs(a.latitude - b.latitude) < 1e-10 &&
         Math.abs(a.longitude - b.longitude) < 1e-10;
}

/**
 * 角度转弧度
 */
function toRadians(degrees: number): number {
  return degrees * (Math.PI / 180);
}
