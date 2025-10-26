/**
 * Point/PixelCoordinate - 像素坐标
 * 使用 NAPI 模块中的 PixelCoordinate 类型定义
 */
import maplibre from 'libmaplibre_native.so';

// Point 是 PixelCoordinate 的别名，用于 ArkTS 代码
export type Point = maplibre.PixelCoordinate;
export type PixelCoordinate = maplibre.PixelCoordinate;

/**
 * 创建 Point/PixelCoordinate 对象
 */
export function createPoint(x: number, y: number): Point {
  return { x, y };
}

/**
 * 计算两点之间的距离
 */
export function distanceBetweenPoints(from: Point, to: Point): number {
  const dx = from.x - to.x;
  const dy = from.y - to.y;
  return Math.sqrt(dx * dx + dy * dy);
}

/**
 * 计算中点
 */
export function midpoint(from: Point, to: Point): Point {
  return { 
    x: (from.x + to.x) / 2, 
    y: (from.y + to.y) / 2 
  };
}
