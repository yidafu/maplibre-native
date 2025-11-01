/**
 * MultiPolygon - GeoJSON MultiPolygon 类
 */
import type { IMultiPolygon, Position } from './types';

/**
 * MultiPolygon 类
 * 
 * 表示一个多多边形几何对象
 */
export class MultiPolygon implements IMultiPolygon {
  type: 'MultiPolygon' = 'MultiPolygon';
  coordinates: Position[][][];

  /**
   * 构造函数
   * 
   * @param coordinates 坐标数组
   * 
   * @example
   * ```typescript
   * const multiPolygon = new MultiPolygon([
   *   [ // 第一个多边形
   *     [[116.3, 39.8], [116.5, 39.8], [116.5, 40.0], [116.3, 40.0], [116.3, 39.8]]
   *   ],
   *   [ // 第二个多边形
   *     [[121.4, 31.1], [121.6, 31.1], [121.6, 31.3], [121.4, 31.3], [121.4, 31.1]]
   *   ]
   * ]);
   * ```
   */
  constructor(coordinates: Position[][][]) {
    this.coordinates = coordinates;
  }

  /**
   * 获取坐标数组
   * 
   * @returns 坐标数组
   */
  getCoordinates(): Position[][][] {
    return this.coordinates;
  }

  /**
   * 设置坐标数组
   * 
   * @param coordinates 坐标数组
   * @returns this，支持链式调用
   */
  setCoordinates(coordinates: Position[][][]): MultiPolygon {
    this.coordinates = coordinates;
    return this;
  }

  /**
   * 添加多边形
   * 
   * @param polygon 多边形坐标数组
   * @returns this，支持链式调用
   */
  addPolygon(polygon: Position[][]): MultiPolygon {
    this.coordinates.push(polygon);
    return this;
  }

  /**
   * 在指定位置插入多边形
   * 
   * @param index 插入位置
   * @param polygon 多边形坐标数组
   * @returns this，支持链式调用
   */
  insertPolygon(index: number, polygon: Position[][]): MultiPolygon {
    this.coordinates.splice(index, 0, polygon);
    return this;
  }

  /**
   * 移除指定索引的多边形
   * 
   * @param index 多边形索引
   * @returns 被移除的多边形，如果索引无效则返回 undefined
   */
  removePolygon(index: number): Position[][] | undefined {
    if (index >= 0 && index < this.coordinates.length) {
      return this.coordinates.splice(index, 1)[0];
    }
    return undefined;
  }

  /**
   * 获取多边形数量
   * 
   * @returns 多边形数量
   */
  getPolygonCount(): number {
    return this.coordinates.length;
  }

  /**
   * 获取指定索引的多边形
   * 
   * @param index 多边形索引
   * @returns 多边形坐标数组，如果索引无效则返回 undefined
   */
  getPolygon(index: number): Position[][] | undefined {
    return this.coordinates[index];
  }

  /**
   * 转换为标准 GeoJSON 对象
   * 
   * @returns IMultiPolygon 对象
   */
  toJSON(): IMultiPolygon {
    return {
      type: 'MultiPolygon',
      coordinates: this.coordinates
    };
  }

  /**
   * 从普通对象创建 MultiPolygon
   * 
   * @param obj 普通对象
   * @returns MultiPolygon 实例
   */
  static fromObject(obj: IMultiPolygon): MultiPolygon {
    return new MultiPolygon(obj.coordinates);
  }
}

