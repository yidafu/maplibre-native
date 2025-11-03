/**
 * Point/PixelCoordinate - 像素坐标
 * ETS 类实现
 */

/**
 * IPixelCoordinate - 像素坐标接口
 * 用于对象字面量
 */
export interface IPixelCoordinate {
  x: number;
  y: number;
}

/**
 * PixelCoordinate - 像素坐标类
 * 表示屏幕上的一个点
 */
export class PixelCoordinate implements IPixelCoordinate {
  x: number;
  y: number;

  constructor(x: number = 0, y: number = 0) {
    this.x = x;
    this.y = y;
  }

  /**
   * 从对象字面量创建 PixelCoordinate 实例
   */
  static fromObject(obj: IPixelCoordinate): PixelCoordinate {
    return new PixelCoordinate(obj.x, obj.y);
  }

  /**
   * 转换为对象字面量
   */
  toObject(): IPixelCoordinate {
    return {
      x: this.x,
      y: this.y
    };
  }

  /**
   * 创建像素坐标（静态工厂方法）
   */
  static create(x: number, y: number): PixelCoordinate {
    return new PixelCoordinate(x, y);
  }

  /**
   * 从逻辑像素创建物理像素坐标
   * 
   * 统一处理 DPI 转换
   * 
   * @param x 逻辑像素 X 坐标
   * @param y 逻辑像素 Y 坐标
   * @param pixelRatio 像素比率（DPI）
   * @returns 物理像素坐标
   */
  static fromLogicalPixels(x: number, y: number, pixelRatio: number): PixelCoordinate {
    return new PixelCoordinate(x * pixelRatio, y * pixelRatio);
  }

  /**
   * 转换为物理像素
   * 
   * @param pixelRatio 像素比率（DPI）
   * @returns 新的物理像素坐标
   */
  toPhysicalPixels(pixelRatio: number): PixelCoordinate {
    return new PixelCoordinate(this.x * pixelRatio, this.y * pixelRatio);
  }

  /**
   * 计算到另一个点的距离
   */
  distanceTo(other: PixelCoordinate): number {
    const dx = this.x - other.x;
    const dy = this.y - other.y;
    return Math.sqrt(dx * dx + dy * dy);
  }

  /**
   * 计算与另一个点的中点
   */
  midpoint(other: PixelCoordinate): PixelCoordinate {
    return new PixelCoordinate(
      (this.x + other.x) / 2,
      (this.y + other.y) / 2
    );
  }
}

// Point 是 PixelCoordinate 的别名，用于 ArkTS 代码
export type Point = PixelCoordinate;
export type ScreenCoordinate = PixelCoordinate;  // 屏幕坐标别名

