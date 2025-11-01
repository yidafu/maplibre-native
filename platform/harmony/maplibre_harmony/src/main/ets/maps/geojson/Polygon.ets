/**
 * Polygon - GeoJSON Polygon 类
 */
import type { IPolygon, Position } from './types';

/**
 * Polygon 类
 * 
 * 表示一个多边形几何对象
 */
export class Polygon implements IPolygon {
  type: 'Polygon' = 'Polygon';
  coordinates: Position[][];

  /**
   * 构造函数
   * 
   * @param coordinates 坐标数组（第一个数组是外环，其余是内环/孔洞）
   * 
   * @example
   * ```typescript
   * const polygon = new Polygon([
   *   [ // 外环
   *     [116.3, 39.8],
   *     [116.5, 39.8],
   *     [116.5, 40.0],
   *     [116.3, 40.0],
   *     [116.3, 39.8]
   *   ]
   * ]);
   * ```
   */
  constructor(coordinates: Position[][]) {
    this.coordinates = coordinates;
  }

  /**
   * 获取坐标数组
   * 
   * @returns 坐标数组
   */
  getCoordinates(): Position[][] {
    return this.coordinates;
  }

  /**
   * 设置坐标数组
   * 
   * @param coordinates 坐标数组
   * @returns this，支持链式调用
   */
  setCoordinates(coordinates: Position[][]): Polygon {
    this.coordinates = coordinates;
    return this;
  }

  /**
   * 获取外环坐标
   * 
   * @returns 外环坐标数组
   */
  getExteriorRing(): Position[] {
    return this.coordinates[0] || [];
  }

  /**
   * 设置外环坐标
   * 
   * @param ring 外环坐标数组
   * @returns this，支持链式调用
   */
  setExteriorRing(ring: Position[]): Polygon {
    this.coordinates[0] = ring;
    return this;
  }

  /**
   * 获取内环（孔洞）数组
   * 
   * @returns 内环数组
   */
  getInteriorRings(): Position[][] {
    return this.coordinates.slice(1);
  }

  /**
   * 添加内环（孔洞）
   * 
   * @param ring 内环坐标数组
   * @returns this，支持链式调用
   */
  addInteriorRing(ring: Position[]): Polygon {
    this.coordinates.push(ring);
    return this;
  }

  /**
   * 移除指定索引的内环
   * 
   * @param index 内环索引（0 表示第一个内环）
   * @returns 被移除的内环，如果索引无效则返回 undefined
   */
  removeInteriorRing(index: number): Position[] | undefined {
    const actualIndex = index + 1; // 跳过外环
    if (actualIndex >= 1 && actualIndex < this.coordinates.length) {
      return this.coordinates.splice(actualIndex, 1)[0];
    }
    return undefined;
  }

  /**
   * 获取内环数量
   * 
   * @returns 内环数量
   */
  getInteriorRingCount(): number {
    return Math.max(0, this.coordinates.length - 1);
  }

  /**
   * 转换为标准 GeoJSON 对象
   * 
   * @returns IPolygon 对象
   */
  toJSON(): IPolygon {
    return {
      type: 'Polygon',
      coordinates: this.coordinates
    };
  }

  /**
   * 从普通对象创建 Polygon
   * 
   * @param obj 普通对象
   * @returns Polygon 实例
   */
  static fromObject(obj: IPolygon): Polygon {
    return new Polygon(obj.coordinates);
  }
}

