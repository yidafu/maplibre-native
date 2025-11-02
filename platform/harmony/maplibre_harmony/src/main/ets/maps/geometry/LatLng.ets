/**
 * LatLng - 经纬度坐标封装类
 * 
 * 纯 ETS 实现，不依赖 NAPI
 */
import type { ILatLng } from '../types/NativeTypes';

/**
 * LatLng 类
 * 表示地理坐标（纬度和经度）
 */
export class LatLng implements ILatLng {
  latitude: number;
  longitude: number;

  /**
   * 构造函数
   * @param latitude 纬度（-90 到 90）
   * @param longitude 经度（-180 到 180）
   */
  constructor(latitude: number, longitude: number) {
    this.latitude = latitude;
    this.longitude = longitude;
  }

  /**
   * 从经纬度创建（静态工厂方法）
   * @param latitude 纬度
   * @param longitude 经度
   * @returns LatLng 实例
   */
  static create(latitude: number, longitude: number): LatLng {
    return new LatLng(latitude, longitude);
  }

  /**
   * 从 Native LatLng 创建（用于 NAPI 互操作）
   * @param native Native LatLng 对象
   * @returns LatLng 实例
   */
  static fromNative(native: ILatLng): LatLng {
    return new LatLng(native.latitude, native.longitude);
  }


  /**
   * 转换为对象字面量
   * @returns 对象字面量 {latitude, longitude}
   */
  toObject(): ILatLng {
    return {
      latitude: this.latitude,
      longitude: this.longitude
    };
  }

  /**
   * 检查坐标是否有效
   * @returns 坐标是否在有效范围内
   */
  isValid(): boolean {
    return this.latitude >= -90 && this.latitude <= 90 && 
           this.longitude >= -180 && this.longitude <= 180;
  }

  /**
   * 计算到另一个坐标的距离（米）
   * 使用 Haversine 公式
   * @param other 另一个坐标
   * @returns 距离（米）
   */
  distanceTo(other: LatLng): number {
    const R = 6371000; // 地球半径（米）
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
   * @param other 另一个坐标
   * @returns 是否相等
   */
  equals(other: LatLng): boolean {
    return Math.abs(this.latitude - other.latitude) < 1e-10 &&
           Math.abs(this.longitude - other.longitude) < 1e-10;
  }

  /**
   * 转换为字符串
   * @returns 字符串表示
   */
  toString(): string {
    return `LatLng(${this.latitude}, ${this.longitude})`;
  }
}

/**
 * 角度转弧度
 * @param degrees 角度
 * @returns 弧度
 */
function toRadians(degrees: number): number {
  return degrees * (Math.PI / 180);
}

/**
 * 创建 LatLng 对象（工厂函数）
 * @param latitude 纬度
 * @param longitude 经度
 * @returns LatLng 实例
 */
export function createLatLng(latitude: number, longitude: number): LatLng {
  return LatLng.create(latitude, longitude);
}

/**
 * 检查坐标是否有效
 * @param latLng 坐标对象
 * @returns 是否有效
 */
export function isValidLatLng(latLng: LatLng): boolean {
  return latLng.isValid();
}

/**
 * 计算两点之间的距离（米）
 * @param from 起点
 * @param to 终点
 * @returns 距离（米）
 */
export function distanceBetween(from: LatLng, to: LatLng): number {
  return from.distanceTo(to);
}

/**
 * 比较两个坐标是否相等
 * @param a 坐标 A
 * @param b 坐标 B
 * @returns 是否相等
 */
export function latLngEquals(a: LatLng, b: LatLng): boolean {
  return a.equals(b);
}
