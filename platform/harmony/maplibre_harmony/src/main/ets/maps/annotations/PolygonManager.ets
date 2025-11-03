/**
 * PolygonManager - Polygon 管理器
 *
 * 负责 Polygon 的添加、更新、删除和查询
 *
 * 架构说明：
 * - 使用原生注解系统（通过 nativeMapView.addPolygons）
 * - 查询使用 queryShapeAnnotations API
 * - 与 MarkerManager 的 GeoJSON 模式不同
 *
 * 参考 Android PolygonContainer 实现
 */
import type { MapLibreMap } from '../MapLibreMap';
import { Polygon, PolygonOptions } from './Polygon';
import { Rect } from '../geometry/Rect';

/**
 * PolygonManager 类
 *
 * 管理地图上所有的 Polygon 注解（原生注解系统）
 */
export class PolygonManager {
  private mapLibreMap: MapLibreMap;
  // Polygon ID -> Polygon 映射
  private polygonMap: Map<number, Polygon> = new Map();

  /**
   * 构造函数
   *
   * @param mapLibreMap MapLibreMap 实例
   */
  constructor(mapLibreMap: MapLibreMap) {
    this.mapLibreMap = mapLibreMap;
  }

  /**
   * 添加单个 Polygon
   *
   * @param options PolygonOptions 实例
   * @returns 创建的 Polygon
   */
  public addPolygon(options: PolygonOptions): Polygon {
    try {
      // 创建 Polygon 对象
      const polygon = new Polygon(options);

      // 调用 native 方法添加（返回 ID 数组）
      const ids = this.mapLibreMap.getNativeMapView().addPolygons([polygon]);

      if (ids.length > 0) {
        const id = ids[0];
        polygon.setId(id);
        this.polygonMap.set(id, polygon);
      }

      return polygon;
    } catch (error) {
      console.error(`[PolygonManager] Failed to add polygon: ${error}`);
      throw new Error(`Failed to add polygon: ${error}`);
    }
  }

  /**
   * 批量添加 Polygon
   *
   * @param optionsList PolygonOptions 数组
   * @returns 创建的 Polygon 数组
   */
  public addPolygons(optionsList: PolygonOptions[]): Polygon[] {
    try {
      // 创建 Polygon 对象数组
      const polygons: Polygon[] = [];
      for (const options of optionsList) {
        polygons.push(new Polygon(options));
      }

      // 批量添加到地图
      const ids = this.mapLibreMap.getNativeMapView().addPolygons(polygons);

      // 设置 ID 并注册
      for (let i = 0; i < polygons.length; i++) {
        const polygon = polygons[i];
        const id = ids[i];
        polygon.setId(id);
        this.polygonMap.set(id, polygon);
      }

      return polygons;
    } catch (error) {
      console.error(`[PolygonManager] Failed to add polygons batch: ${error}`);
      throw new Error(`Failed to add polygons batch: ${error}`);
    }
  }

  /**
   * 移除单个 Polygon
   *
   * @param polygon 要移除的 Polygon
   */
  public removePolygon(polygon: Polygon): void {
    const id = polygon.getId();
    if (id === -1) {
      return;
    }

    this.mapLibreMap.getNativeMapView().removeAnnotations([id]);
    this.polygonMap.delete(id);
  }

  /**
   * 批量移除 Polygon
   *
   * @param polygons 要移除的 Polygon 数组
   */
  public removePolygons(polygons: Polygon[]): void {
    const ids: number[] = [];

    for (const polygon of polygons) {
      const id = polygon.getId();
      if (id !== -1) {
        ids.push(id);
        this.polygonMap.delete(id);
      }
    }

    if (ids.length > 0) {
      this.mapLibreMap.getNativeMapView().removeAnnotations(ids);
    }
  }

  /**
   * 更新 Polygon
   *
   * @param polygon 要更新的 Polygon
   */
  public updatePolygon(polygon: Polygon): void {
    const id = polygon.getId();
    if (id === -1) {
      console.warn('[PolygonManager] Cannot update polygon with id -1');
      return;
    }

    this.mapLibreMap.updatePolygon(polygon);
  }

  /**
   * 清除所有 Polygon
   */
  public clear(): void {
    const ids = Array.from(this.polygonMap.keys());
    if (ids.length > 0) {
      this.mapLibreMap.getNativeMapView().removeAnnotations(ids);
    }
    this.polygonMap.clear();
  }

  /**
   * 获取所有 Polygon
   *
   * @returns Polygon 数组
   */
  public getPolygons(): Polygon[] {
    return Array.from(this.polygonMap.values());
  }
}

