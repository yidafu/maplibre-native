/**
 * Rect - 矩形
 * 使用 NAPI 模块中的 Rect 接口，添加工具函数
 */
import maplibre from 'libmaplibre_native.so';
import { Point } from './Point';

export type Rect = maplibre.Rect;

/**
 * Size - 尺寸接口
 */
export interface Size {
  width: number;
  height: number;
}

/**
 * 创建矩形
 */
export function createRect(left: number, top: number, right: number, bottom: number): Rect {
  return { left, top, right, bottom };
}

/**
 * 从两个点创建矩形
 */
export function createRectFromPoints(topLeft: Point, bottomRight: Point): Rect {
  return { 
    left: topLeft.x, 
    top: topLeft.y, 
    right: bottomRight.x, 
    bottom: bottomRight.y 
  };
}

/**
 * 从位置和尺寸创建矩形
 */
export function createRectFromXYWH(x: number, y: number, width: number, height: number): Rect {
  return { left: x, top: y, right: x + width, bottom: y + height };
}

/**
 * 获取宽度
 */
export function getRectWidth(rect: Rect): number {
  return rect.right - rect.left;
}

/**
 * 获取高度
 */
export function getRectHeight(rect: Rect): number {
  return rect.bottom - rect.top;
}

/**
 * 获取中心点
 */
export function getRectCenter(rect: Rect): Point {
  return { 
    x: (rect.left + rect.right) / 2, 
    y: (rect.top + rect.bottom) / 2 
  };
}

/**
 * 检查点是否在矩形内
 */
export function rectContainsPoint(rect: Rect, point: Point): boolean {
  return point.x >= rect.left && point.x <= rect.right &&
         point.y >= rect.top && point.y <= rect.bottom;
}

/**
 * 检查矩形是否与另一个矩形相交
 */
export function rectsIntersect(a: Rect, b: Rect): boolean {
  return !(a.right <= b.left || a.left >= b.right ||
           a.bottom <= b.top || a.top >= b.bottom);
}

/**
 * 计算两个矩形的交集
 */
export function rectIntersection(a: Rect, b: Rect): Rect | null {
  const left = Math.max(a.left, b.left);
  const top = Math.max(a.top, b.top);
  const right = Math.min(a.right, b.right);
  const bottom = Math.min(a.bottom, b.bottom);

  if (left >= right || top >= bottom) {
    return null; // 没有交集
  }

  return { left, top, right, bottom };
}

/**
 * 计算两个矩形的并集
 */
export function rectUnion(a: Rect, b: Rect): Rect {
  return {
    left: Math.min(a.left, b.left),
    top: Math.min(a.top, b.top),
    right: Math.max(a.right, b.right),
    bottom: Math.max(a.bottom, b.bottom)
  };
}

/**
 * 检查矩形是否为空
 */
export function isRectEmpty(rect: Rect): boolean {
  return rect.left >= rect.right || rect.top >= rect.bottom;
}

/**
 * 计算矩形面积
 */
export function getRectArea(rect: Rect): number {
  return isRectEmpty(rect) ? 0 : getRectWidth(rect) * getRectHeight(rect);
}
