import { Point } from './Point';

/**
 * Rect - 矩形类
 */
export class Rect {
  public left: number;
  public top: number;
  public right: number;
  public bottom: number;

  constructor(left: number, top: number, right: number, bottom: number) {
    this.left = left;
    this.top = top;
    this.right = right;
    this.bottom = bottom;
  }

  /**
   * 从两个点创建矩形
   */
  public static fromPoints(topLeft: Point, bottomRight: Point): Rect {
    return new Rect(topLeft.x, topLeft.y, bottomRight.x, bottomRight.y);
  }

  /**
   * 从位置和尺寸创建矩形
   */
  public static fromLTRB(left: number, top: number, right: number, bottom: number): Rect {
    return new Rect(left, top, right, bottom);
  }

  /**
   * 从位置和尺寸创建矩形
   */
  public static fromXYWH(x: number, y: number, width: number, height: number): Rect {
    return new Rect(x, y, x + width, y + height);
  }

  /**
   * 获取宽度
   */
  public getWidth(): number {
    return this.right - this.left;
  }

  /**
   * 获取高度
   */
  public getHeight(): number {
    return this.bottom - this.top;
  }

  /**
   * 获取尺寸
   */
  public getSize(): { width: number; height: number } {
    return { width: this.getWidth(), height: this.getHeight() };
  }

  /**
   * 获取左上角点
   */
  public getTopLeft(): Point {
    return new Point(this.left, this.top);
  }

  /**
   * 获取右上角点
   */
  public getTopRight(): Point {
    return new Point(this.right, this.top);
  }

  /**
   * 获取左下角点
   */
  public getBottomLeft(): Point {
    return new Point(this.left, this.bottom);
  }

  /**
   * 获取右下角点
   */
  public getBottomRight(): Point {
    return new Point(this.right, this.bottom);
  }

  /**
   * 获取中心点
   */
  public getCenter(): Point {
    return new Point((this.left + this.right) / 2, (this.top + this.bottom) / 2);
  }

  /**
   * 检查点是否在矩形内
   */
  public contains(point: Point): boolean {
    return point.x >= this.left && point.x <= this.right &&
           point.y >= this.top && point.y <= this.bottom;
  }

  /**
   * 检查点是否在矩形内（包含边界）
   */
  public containsInclusive(point: Point): boolean {
    return point.x >= this.left && point.x < this.right &&
           point.y >= this.top && point.y < this.bottom;
  }

  /**
   * 检查矩形是否包含另一个矩形
   */
  public containsRect(other: Rect): boolean {
    return this.left <= other.left && this.right >= other.right &&
           this.top <= other.top && this.bottom >= other.bottom;
  }

  /**
   * 检查矩形是否与另一个矩形相交
   */
  public intersects(other: Rect): boolean {
    return !(this.right <= other.left || this.left >= other.right ||
             this.bottom <= other.top || this.top >= other.bottom);
  }

  /**
   * 计算与另一个矩形的交集
   */
  public intersect(other: Rect): Rect | null {
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
  public union(other: Rect): Rect {
    return new Rect(
      Math.min(this.left, other.left),
      Math.min(this.top, other.top),
      Math.max(this.right, other.right),
      Math.max(this.bottom, other.bottom)
    );
  }

  /**
   * 扩展矩形以包含点
   */
  public expandToInclude(point: Point): Rect {
    return new Rect(
      Math.min(this.left, point.x),
      Math.min(this.top, point.y),
      Math.max(this.right, point.x),
      Math.max(this.bottom, point.y)
    );
  }

  /**
   * 扩展矩形以包含另一个矩形
   */
  public expandToIncludeRect(other: Rect): Rect {
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
  public isEmpty(): boolean {
    return this.left >= this.right || this.top >= this.bottom;
  }

  /**
   * 检查矩形是否有效
   */
  public isValid(): boolean {
    return !isNaN(this.left) && !isNaN(this.top) && 
           !isNaN(this.right) && !isNaN(this.bottom);
  }

  /**
   * 计算面积
   */
  public getArea(): number {
    return this.isEmpty() ? 0 : this.getWidth() * this.getHeight();
  }

  /**
   * 计算周长
   */
  public getPerimeter(): number {
    return this.isEmpty() ? 0 : 2 * (this.getWidth() + this.getHeight());
  }

  /**
   * 比较两个矩形是否相等
   */
  public equals(other: Rect): boolean {
    return Math.abs(this.left - other.left) < 1e-10 &&
           Math.abs(this.top - other.top) < 1e-10 &&
           Math.abs(this.right - other.right) < 1e-10 &&
           Math.abs(this.bottom - other.bottom) < 1e-10;
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return `Rect(${this.left}, ${this.top}, ${this.right}, ${this.bottom})`;
  }
}
