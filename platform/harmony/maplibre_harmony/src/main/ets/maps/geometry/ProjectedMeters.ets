/**
 * ProjectedMeters - 投影米坐标
 * 使用 NAPI 模块中的类型定义
 */
import maplibre from 'libmaplibre_native.so';

export type ProjectedMeters = maplibre.ProjectedMeters;

/**
 * 创建 ProjectedMeters 对象
 */
export function createProjectedMeters(northing: number, easting: number): ProjectedMeters {
  return { northing, easting };
}

/**
 * 计算两点之间的距离
 */
export function distanceBetweenProjected(from: ProjectedMeters, to: ProjectedMeters): number {
  const dx = from.easting - to.easting;
  const dy = from.northing - to.northing;
  return Math.sqrt(dx * dx + dy * dy);
}
