/**
 * LatLng - 经纬度坐标封装类
 * 
 * 符合 ArkTS 规范的封装实现
 */
import maplibre from 'libmaplibre.so';

/**
 * 内部创建标记（用于从 NAPI 实例创建封装类）
 */
class InternalMarker {
  static readonly INSTANCE = new InternalMarker();
  private constructor() {}
}

/**
 * LatLng 封装类
 */
export class LatLng {
  private nativeInstance: maplibre.LatLng;

  /**
   * 构造函数
   * 支持两种模式：
   * 1. 从经纬度创建: new LatLng(lat, lng)
   * 2. 从 NAPI 实例创建（内部使用）: new LatLng(marker, nativeInstance)
   */
  constructor(latOrMarker: number | InternalMarker, lngOrNative?: number | maplibre.LatLng) {
    if (latOrMarker === InternalMarker.INSTANCE && lngOrNative instanceof Object) {
      // 内部模式：从 NAPI 实例创建
      this.nativeInstance = lngOrNative as maplibre.LatLng;
    } else if (typeof latOrMarker === 'number' && typeof lngOrNative === 'number') {
      // 正常模式：从经纬度创建
      this.nativeInstance = new maplibre.LatLng(latOrMarker, lngOrNative);
    } else {
      throw new Error('Invalid LatLng constructor arguments');
    }
  }

  /**
   * 从经纬度创建（静态工厂方法）
   */
  static create(latitude: number, longitude: number): LatLng {
    return new LatLng(latitude, longitude);
  }

  /**
   * 从 NAPI 实例创建（内部使用）
   */
  static fromNative(nativeInstance: maplibre.LatLng): LatLng {
    return new LatLng(InternalMarker.INSTANCE, nativeInstance);
  }

  /**
   * 获取 NAPI 实例（内部使用）
   */
  getNative(): maplibre.LatLng {
    return this.nativeInstance;
  }

  /**
   * 获取纬度
   */
  get latitude(): number {
    return this.nativeInstance.latitude;
  }

  /**
   * 获取经度
   */
  get longitude(): number {
    return this.nativeInstance.longitude;
  }

  /**
   * 检查坐标是否有效
   */
  isValid(): boolean {
    return this.latitude >= -90 && this.latitude <= 90 && 
           this.longitude >= -180 && this.longitude <= 180;
  }

  /**
   * 计算到另一个坐标的距离（米）
   */
  distanceTo(other: LatLng): number {
    const R = 6371000;
    const dLat = toRadians(other.latitude - this.latitude);
    const dLon = toRadians(other.longitude - this.longitude);
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
              Math.cos(toRadians(this.latitude)) * Math.cos(toRadians(other.latitude)) *
              Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  /**
   * 比较是否相等
   */
  equals(other: LatLng): boolean {
    return Math.abs(this.latitude - other.latitude) < 1e-10 &&
           Math.abs(this.longitude - other.longitude) < 1e-10;
  }

  /**
   * 转换为字符串
   */
  toString(): string {
    return `LatLng(${this.latitude}, ${this.longitude})`;
  }
}

/**
 * 角度转弧度
 */
function toRadians(degrees: number): number {
  return degrees * (Math.PI / 180);
}

/**
 * 创建 LatLng 对象（工厂函数）
 */
export function createLatLng(latitude: number, longitude: number): LatLng {
  return LatLng.create(latitude, longitude);
}

/**
 * 检查坐标是否有效
 */
export function isValidLatLng(latLng: LatLng): boolean {
  return latLng.isValid();
}

/**
 * 计算两点之间的距离（米）
 */
export function distanceBetween(from: LatLng, to: LatLng): number {
  return from.distanceTo(to);
}

/**
 * 比较两个坐标是否相等
 */
export function latLngEquals(a: LatLng, b: LatLng): boolean {
  return a.equals(b);
}
