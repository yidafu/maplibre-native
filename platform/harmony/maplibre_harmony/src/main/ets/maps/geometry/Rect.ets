/**
 * Rect - 矩形
 * ETS 类实现
 */
import { Point, PixelCoordinate } from './Point';
import { Size } from '../types/NativeTypes';

/**
 * IRect - 矩形接口
 * 用于对象字面量
 */
export interface IRect {
  left: number;
  top: number;
  right: number;
  bottom: number;
}

/**
 * Rect - 矩形类
 * 表示一个矩形区域
 */
export class Rect implements IRect {
  left: number;
  top: number;
  right: number;
  bottom: number;

  constructor(left: number = 0, top: number = 0, right: number = 0, bottom: number = 0) {
    this.left = left;
    this.top = top;
    this.right = right;
    this.bottom = bottom;
  }

  /**
   * 从对象字面量创建 Rect 实例
   */
  static fromObject(obj: IRect): Rect {
    return new Rect(obj.left, obj.top, obj.right, obj.bottom);
  }

  /**
   * 转换为对象字面量
   */
  toObject(): IRect {
    return {
      left: this.left,
      top: this.top,
      right: this.right,
      bottom: this.bottom
    };
  }

  /**
   * 创建矩形（静态工厂方法）
   */
  static create(left: number, top: number, right: number, bottom: number): Rect {
    return new Rect(left, top, right, bottom);
  }

  /**
   * 从两个点创建矩形
   */
  static fromPoints(topLeft: Point, bottomRight: Point): Rect {
    return new Rect(topLeft.x, topLeft.y, bottomRight.x, bottomRight.y);
  }

  /**
   * 从位置和尺寸创建矩形
   */
  static fromXYWH(x: number, y: number, width: number, height: number): Rect {
    return new Rect(x, y, x + width, y + height);
  }

  /**
   * 获取宽度
   */
  getWidth(): number {
    return this.right - this.left;
  }

  /**
   * 获取高度
   */
  getHeight(): number {
    return this.bottom - this.top;
  }

  /**
   * 获取中心点
   */
  getCenter(): Point {
    return new PixelCoordinate(
      (this.left + this.right) / 2,
      (this.top + this.bottom) / 2
    );
  }

  /**
   * 检查点是否在矩形内
   */
  containsPoint(point: Point): boolean {
    return point.x >= this.left && point.x <= this.right &&
           point.y >= this.top && point.y <= this.bottom;
  }

  /**
   * 检查矩形是否与另一个矩形相交
   */
  intersects(other: Rect): boolean {
    return !(this.right <= other.left || this.left >= other.right ||
             this.bottom <= other.top || this.top >= other.bottom);
  }

  /**
   * 计算与另一个矩形的交集
   */
  intersection(other: Rect): Rect | null {
    const left = Math.max(this.left, other.left);
    const top = Math.max(this.top, other.top);
    const right = Math.min(this.right, other.right);
    const bottom = Math.min(this.bottom, other.bottom);

    if (left >= right || top >= bottom) {
      return null; // 没有交集
    }

    return new Rect(left, top, right, bottom);
  }

  /**
   * 计算与另一个矩形的并集
   */
  union(other: Rect): Rect {
    return new Rect(
      Math.min(this.left, other.left),
      Math.min(this.top, other.top),
      Math.max(this.right, other.right),
      Math.max(this.bottom, other.bottom)
    );
  }

  /**
   * 检查矩形是否为空
   */
  isEmpty(): boolean {
    return this.left >= this.right || this.top >= this.bottom;
  }

  /**
   * 计算矩形面积
   */
  getArea(): number {
    return this.isEmpty() ? 0 : this.getWidth() * this.getHeight();
  }
}

