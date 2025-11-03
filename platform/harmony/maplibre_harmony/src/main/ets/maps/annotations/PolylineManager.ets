/**
 * PolylineManager - Polyline 管理器
 * 
 * 负责 Polyline 的添加、更新、删除和查询
 * 
 * 架构说明：
 * - 使用原生注解系统（通过 nativeMapView.addPolylines）
 * - 查询使用 queryShapeAnnotations API
 * - 与 MarkerManager 的 GeoJSON 模式不同
 * 
 * 参考 Android PolylineContainer 实现
 */
import type { MapLibreMap } from '../MapLibreMap';
import { Polyline, PolylineOptions } from './Polyline';
import { Rect } from '../geometry/Rect';

/**
 * PolylineManager 类
 * 
 * 管理地图上所有的 Polyline 注解（原生注解系统）
 */
export class PolylineManager {
  private mapLibreMap: MapLibreMap;
  
  // Polyline ID -> Polyline 映射
  private polylineMap: Map<number, Polyline> = new Map();
  
  /**
   * 构造函数
   * 
   * @param mapLibreMap MapLibreMap 实例
   */
  constructor(mapLibreMap: MapLibreMap) {
    this.mapLibreMap = mapLibreMap;
  }
  
  /**
   * 添加单个 Polyline
   * 
   * @param options PolylineOptions 实例
   * @returns 创建的 Polyline
   */
  public addPolyline(options: PolylineOptions): Polyline {
    try {
      // 创建 Polyline 对象
      const polyline = new Polyline(options);
      
      // 调用 native 方法添加（返回 ID 数组）
      const ids = this.mapLibreMap.getNativeMapView().addPolylines([polyline]);
      
      if (ids.length > 0) {
        const id = ids[0];
        polyline.setId(id);
        this.polylineMap.set(id, polyline);
      }
      
      return polyline;
    } catch (error) {
      console.error(`[PolylineManager] Failed to add polyline: ${error}`);
      throw new Error(`Failed to add polyline: ${error}`);
    }
  }
  
  /**
   * 批量添加 Polyline
   * 
   * @param optionsList PolylineOptions 数组
   * @returns 创建的 Polyline 数组
   */
  public addPolylines(optionsList: PolylineOptions[]): Polyline[] {
    try {
      // 创建 Polyline 对象数组
      const polylines: Polyline[] = [];
      for (const options of optionsList) {
        polylines.push(new Polyline(options));
      }
      
      // 批量添加到地图
      const ids = this.mapLibreMap.getNativeMapView().addPolylines(polylines);
      
      // 设置 ID 并注册
      for (let i = 0; i < polylines.length; i++) {
        const polyline = polylines[i];
        const id = ids[i];
        polyline.setId(id);
        this.polylineMap.set(id, polyline);
      }
      
      return polylines;
    } catch (error) {
      console.error(`[PolylineManager] Failed to add polylines batch: ${error}`);
      throw new Error(`Failed to add polylines batch: ${error}`);
    }
  }
  
  /**
   * 移除单个 Polyline
   * 
   * @param polyline 要移除的 Polyline
   */
  public removePolyline(polyline: Polyline): void {
    const id = polyline.getId();
    if (id === -1) {
      return;
    }
    
    this.mapLibreMap.getNativeMapView().removeAnnotations([id]);
    this.polylineMap.delete(id);
  }
  
  /**
   * 批量移除 Polyline
   * 
   * @param polylines 要移除的 Polyline 数组
   */
  public removePolylines(polylines: Polyline[]): void {
    const ids: number[] = [];
    
    for (const polyline of polylines) {
      const id = polyline.getId();
      if (id !== -1) {
        ids.push(id);
        this.polylineMap.delete(id);
      }
    }
    
    if (ids.length > 0) {
      this.mapLibreMap.getNativeMapView().removeAnnotations(ids);
    }
  }
  
  /**
   * 更新 Polyline
   * 
   * @param polyline 要更新的 Polyline
   */
  public updatePolyline(polyline: Polyline): void {
    const id = polyline.getId();
    if (id === -1) {
      console.warn('[PolylineManager] Cannot update polyline with id -1');
      return;
    }
    
    this.mapLibreMap.updatePolyline(polyline);
  }
  
  /**
   * 清除所有 Polyline
   */
  public clear(): void {
    const ids = Array.from(this.polylineMap.keys());
    if (ids.length > 0) {
      this.mapLibreMap.getNativeMapView().removeAnnotations(ids);
    }
    this.polylineMap.clear();
  }
  
  /**
   * 获取所有 Polyline
   * 
   * @returns Polyline 数组
   */
  public getPolylines(): Polyline[] {
    return Array.from(this.polylineMap.values());
  }
}

