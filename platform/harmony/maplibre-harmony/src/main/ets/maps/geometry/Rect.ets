/**
 * Rect - rectangle helper.
 * ETS class implementation.
 */
import { PixelCoordinate, Point } from './Point';

/**
 * IRect - rectangle interface.
 * Suitable for object literals.
 */
export interface IRect {
  left: number;
  top: number;
  right: number;
  bottom: number;
}

/**
 * Rect - rectangle class.
 * Represents a rectangular region.
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
   * Create a Rect instance from an object literal.
   */
  static fromObject(obj: IRect): Rect {
    return new Rect(obj.left, obj.top, obj.right, obj.bottom);
  }

  /**
   * Convert to an object literal.
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
   * Create a rectangle (static factory method).
   */
  static create(left: number, top: number, right: number, bottom: number): Rect {
    return new Rect(left, top, right, bottom);
  }

  /**
   * Create a rectangle from two points.
   */
  static fromPoints(topLeft: Point, bottomRight: Point): Rect {
    return new Rect(topLeft.x, topLeft.y, bottomRight.x, bottomRight.y);
  }

  /**
   * Create a rectangle from position and size.
   */
  static fromXYWH(x: number, y: number, width: number, height: number): Rect {
    return new Rect(x, y, x + width, y + height);
  }

  /**
   * Get the width.
   */
  getWidth(): number {
    return this.right - this.left;
  }

  /**
   * Get the height.
   */
  getHeight(): number {
    return this.bottom - this.top;
  }

  /**
   * Get the center point.
   */
  getCenter(): Point {
    return new PixelCoordinate(
      (this.left + this.right) / 2,
      (this.top + this.bottom) / 2
    );
  }

  /**
   * Check whether a point lies inside the rectangle.
   */
  containsPoint(point: Point): boolean {
    return point.x >= this.left && point.x <= this.right &&
      point.y >= this.top && point.y <= this.bottom;
  }

  /**
   * Check whether the rectangle intersects another rectangle.
   */
  intersects(other: Rect): boolean {
    return !(this.right <= other.left || this.left >= other.right ||
      this.bottom <= other.top || this.top >= other.bottom);
  }

  /**
   * Compute the intersection with another rectangle.
   */
  intersection(other: Rect): Rect | null {
    const left = Math.max(this.left, other.left);
    const top = Math.max(this.top, other.top);
    const right = Math.min(this.right, other.right);
    const bottom = Math.min(this.bottom, other.bottom);

    if (left >= right || top >= bottom) {
      return null; // No intersection
    }

    return new Rect(left, top, right, bottom);
  }

  /**
   * Compute the union with another rectangle.
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
   * Check whether the rectangle is empty.
   */
  isEmpty(): boolean {
    return this.left >= this.right || this.top >= this.bottom;
  }

  /**
   * Compute the rectangle area.
   */
  getArea(): number {
    return this.isEmpty() ? 0 : this.getWidth() * this.getHeight();
  }
}

