/**
 * Point/PixelCoordinate - screen coordinate helper.
 * ETS class implementation.
 */

/**
 * IPixelCoordinate - interface for pixel coordinates.
 * Suitable for object literals.
 */
export interface IPixelCoordinate {
  x: number;
  y: number;
}

/**
 * PixelCoordinate - pixel coordinate class.
 * Represents a point on screen.
 */
export class PixelCoordinate implements IPixelCoordinate {
  x: number;
  y: number;

  constructor(x: number = 0, y: number = 0) {
    this.x = x;
    this.y = y;
  }

  /**
   * Create a PixelCoordinate from an object literal.
   */
  static fromObject(obj: IPixelCoordinate): PixelCoordinate {
    return new PixelCoordinate(obj.x, obj.y);
  }

  /**
   * Convert to an object literal.
   */
  toObject(): IPixelCoordinate {
    return {
      x: this.x,
      y: this.y
    };
  }

  /**
   * Create a pixel coordinate (static factory method).
   */
  static create(x: number, y: number): PixelCoordinate {
    return new PixelCoordinate(x, y);
  }

  /**
   * Create a physical pixel coordinate from logical pixels.
   *
   * Centralizes DPI conversion.
   *
   * @param x Logical pixel X.
   * @param y Logical pixel Y.
   * @param pixelRatio Pixel ratio (DPI).
   * @returns Physical pixel coordinate.
   */
  static fromLogicalPixels(x: number, y: number, pixelRatio: number): PixelCoordinate {
    return new PixelCoordinate(x * pixelRatio, y * pixelRatio);
  }

  /**
   * Convert to physical pixels.
   *
   * @param pixelRatio Pixel ratio (DPI).
   * @returns New physical pixel coordinate.
   */
  toPhysicalPixels(pixelRatio: number): PixelCoordinate {
    return new PixelCoordinate(this.x * pixelRatio, this.y * pixelRatio);
  }

  /**
   * Compute the distance to another point.
   */
  distanceTo(other: PixelCoordinate): number {
    const dx = this.x - other.x;
    const dy = this.y - other.y;
    return Math.sqrt(dx * dx + dy * dy);
  }

  /**
   * Compute the midpoint to another point.
   */
  midpoint(other: PixelCoordinate): PixelCoordinate {
    return new PixelCoordinate(
      (this.x + other.x) / 2,
      (this.y + other.y) / 2
    );
  }
}

// Point is an alias of PixelCoordinate for ArkTS usage.
export type Point = PixelCoordinate;

export type ScreenCoordinate = PixelCoordinate; // Screen coordinate alias

