import { LatLng } from '../geometry/LatLng';

/**
 * CameraPosition - 相机位置类
 */
export class CameraPosition {
  public target: LatLng;
  public zoom: number;
  public bearing: number;
  public tilt: number;
  public padding: { left: number; top: number; right: number; bottom: number };

  constructor(options: {
    target: LatLng;
    zoom?: number;
    bearing?: number;
    tilt?: number;
    padding?: { left: number; top: number; right: number; bottom: number };
  }) {
    this.target = options.target;
    this.zoom = options.zoom || 0;
    this.bearing = options.bearing || 0;
    this.tilt = options.tilt || 0;
    this.padding = options.padding || { left: 0, top: 0, right: 0, bottom: 0 };
  }

  /**
   * 创建相机位置
   */
  public static fromLatLngZoom(target: LatLng, zoom: number): CameraPosition {
    return new CameraPosition({ target, zoom });
  }

  /**
   * 创建相机位置（带方位角）
   */
  public static fromLatLngZoomBearing(target: LatLng, zoom: number, bearing: number): CameraPosition {
    return new CameraPosition({ target, zoom, bearing });
  }

  /**
   * 创建相机位置（带方位角和倾斜角）
   */
  public static fromLatLngZoomBearingTilt(
    target: LatLng, 
    zoom: number, 
    bearing: number, 
    tilt: number
  ): CameraPosition {
    return new CameraPosition({ target, zoom, bearing, tilt });
  }

  /**
   * 设置目标位置
   */
  public setTarget(target: LatLng): void {
    this.target = target;
  }

  /**
   * 获取目标位置
   */
  public getTarget(): LatLng {
    return this.target;
  }

  /**
   * 设置缩放级别
   */
  public setZoom(zoom: number): void {
    this.zoom = zoom;
  }

  /**
   * 获取缩放级别
   */
  public getZoom(): number {
    return this.zoom;
  }

  /**
   * 设置方位角
   */
  public setBearing(bearing: number): void {
    this.bearing = bearing;
  }

  /**
   * 获取方位角
   */
  public getBearing(): number {
    return this.bearing;
  }

  /**
   * 设置倾斜角
   */
  public setTilt(tilt: number): void {
    this.tilt = tilt;
  }

  /**
   * 获取倾斜角
   */
  public getTilt(): number {
    return this.tilt;
  }

  /**
   * 设置内边距
   */
  public setPadding(padding: { left: number; top: number; right: number; bottom: number }): void {
    this.padding = padding;
  }

  /**
   * 获取内边距
   */
  public getPadding(): { left: number; top: number; right: number; bottom: number } {
    return this.padding;
  }

  /**
   * 比较两个相机位置是否相等
   */
  public equals(other: CameraPosition): boolean {
    return this.target.equals(other.target) &&
           Math.abs(this.zoom - other.zoom) < 1e-10 &&
           Math.abs(this.bearing - other.bearing) < 1e-10 &&
           Math.abs(this.tilt - other.tilt) < 1e-10 &&
           this.padding.left === other.padding.left &&
           this.padding.top === other.padding.top &&
           this.padding.right === other.padding.right &&
           this.padding.bottom === other.padding.bottom;
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return `CameraPosition(target=${this.target.toString()}, zoom=${this.zoom}, bearing=${this.bearing}, tilt=${this.tilt})`;
  }
}
