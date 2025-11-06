/**
 * MapSnapshot - 地图快照结果类型定义
 * 
 * 对应 Android 的 MapSnapshot
 */

import { LatLng } from './NativeMapView';

/**
 * MapSnapshot 接口
 * 
 * 快照结果对象，包含图像数据和坐标转换功能
 */
export interface MapSnapshot {
  /**
   * 图像数据（ArrayBuffer 格式，RGBA）
   */
  data: ArrayBuffer;
  
  /**
   * 图像宽度（像素）
   */
  width: number;
  
  /**
   * 图像高度（像素）
   */
  height: number;
  
  /**
   * 像素比
   */
  pixelRatio: number;
  
  /**
   * 归属信息数组
   */
  attributions?: string[];
  
  /**
   * 将地理坐标转换为快照图像上的像素坐标
   * 
   * 对应 Android: `MapSnapshot.pixelForLatLng(LatLng)`
   * 
   * @param latitude 纬度
   * @param longitude 经度
   * @returns 图像上的像素坐标 {x, y}
   */
  pixelForLatLng(latitude: number, longitude: number): { x: number; y: number; };
  
  /**
   * 将快照图像上的像素坐标转换为地理坐标
   * 
   * 对应 Android: `MapSnapshot.latLngForPixel(PointF)`
   * 
   * @param x 图像上的 X 坐标
   * @param y 图像上的 Y 坐标
   * @returns 地理坐标
   */
  latLngForPixel(x: number, y: number): LatLng;
}

/**
 * SnapshotResult - 快照结果类型（NAPI 返回）
 * 
 * @deprecated 使用 MapSnapshot 替代
 */
export type SnapshotResultNAPI = MapSnapshot;

