/**
 * CameraPosition - 相机位置
 * ETS 类实现
 */
import { LatLng } from '../geometry/LatLng';

/**
 * IEdgeInsets - 边距接口
 * 用于对象字面量
 */
export interface IEdgeInsets {
  top: number;
  left: number;
  bottom: number;
  right: number;
}

/**
 * EdgeInsets - 边距类
 * 表示矩形的内边距
 */
export class EdgeInsets implements IEdgeInsets {
  top: number;
  left: number;
  bottom: number;
  right: number;

  constructor(top: number = 0, left: number = 0, bottom: number = 0, right: number = 0) {
    this.top = top;
    this.left = left;
    this.bottom = bottom;
    this.right = right;
  }

  /**
   * 从对象字面量创建 EdgeInsets 实例
   */
  static fromObject(obj: IEdgeInsets): EdgeInsets {
    return new EdgeInsets(obj.top, obj.left, obj.bottom, obj.right);
  }

  /**
   * 转换为对象字面量
   */
  toObject(): IEdgeInsets {
    return {
      top: this.top,
      left: this.left,
      bottom: this.bottom,
      right: this.right
    };
  }
}

/**
 * ICameraPosition - 相机位置接口
 * 用于对象字面量
 */
export interface ICameraPosition {
  target: LatLng;
  zoom: number;
  bearing: number;
  tilt: number;
}

/**
 * CameraPosition - 相机位置类
 * 表示地图相机的位置和方向
 */
export class CameraPosition implements ICameraPosition {
  target: LatLng;
  zoom: number;
  bearing: number;
  tilt: number;

  constructor(target: LatLng, zoom: number, bearing: number = 0, tilt: number = 0) {
    this.target = target;
    this.zoom = zoom;
    this.bearing = bearing;
    this.tilt = tilt;
  }

  /**
   * 从对象字面量创建 CameraPosition 实例
   */
  static fromObject(obj: ICameraPosition): CameraPosition {
    return new CameraPosition(obj.target, obj.zoom, obj.bearing, obj.tilt);
  }

  /**
   * 转换为对象字面量
   */
  toObject(): ICameraPosition {
    return {
      target: this.target,
      zoom: this.zoom,
      bearing: this.bearing,
      tilt: this.tilt
    };
  }

  /**
   * 创建相机位置（静态工厂方法，类似 Android CameraPosition.Builder().build()）
   * 
   * @param target 目标位置（经纬度）
   * @param zoom 缩放级别
   * @param bearing 方向角度（0-360度，默认0表示正北）
   * @param tilt 倾斜角度（0-60度，默认0表示垂直俯视）
   * @returns CameraPosition 对象
   * 
   * @example
   * ```typescript
   * const position = CameraPosition.create(
   *   LatLng.create(39.9, 116.4),
   *   15,
   *   30,  // bearing
   *   45   // tilt
   * );
   * ```
   */
  static create(target: LatLng, zoom: number, bearing: number = 0, tilt: number = 0): CameraPosition {
    return new CameraPosition(target, zoom, bearing, tilt);
  }

  /**
   * 比较当前相机位置与另一个是否相等
   * @param other 另一个相机位置
   * @returns 是否相等
   */
  equals(other: CameraPosition): boolean {
    return Math.abs(this.target.latitude - other.target.latitude) < 1e-10 &&
           Math.abs(this.target.longitude - other.target.longitude) < 1e-10 &&
           Math.abs(this.zoom - other.zoom) < 1e-10 &&
           Math.abs(this.bearing - other.bearing) < 1e-10 &&
           Math.abs(this.tilt - other.tilt) < 1e-10;
  }
}

/**
 * CameraOptions - 相机选项接口
 * 用于设置相机参数（与 NAPI CameraOptions 接口兼容）
 */
export interface CameraOptions {
  /** 中心点坐标 */
  center?: LatLng;
  /** 缩放级别 */
  zoom?: number;
  /** 方位角（度） */
  bearing?: number;
  /** 俯仰角/倾斜角（度） */
  pitch?: number;
  /** 边距 */
  padding?: EdgeInsets;
}

