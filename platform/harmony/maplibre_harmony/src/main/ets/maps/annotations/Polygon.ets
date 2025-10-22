import { LatLng } from '../geometry/LatLng';
import { GeoBounds } from './Polyline';

/**
 * PolygonOptions - 多边形选项接口
 */
export interface PolygonOptions {
  id?: string;
  points: LatLng[];
  holes?: LatLng[][];
  fillColor?: string;
  strokeColor?: string;
  strokeWidth?: number;
  fillAlpha?: number;
  strokeAlpha?: number;
  visible?: boolean;
  zIndex?: number;
}

/**
 * Polygon - 多边形类
 */
export class Polygon {
  public id: string;
  public points: LatLng[];
  public holes: LatLng[][];
  public fillColor: string;
  public strokeColor: string;
  public strokeWidth: number;
  public fillAlpha: number;
  public strokeAlpha: number;
  public visible: boolean;
  public zIndex: number;

  constructor(options: PolygonOptions) {
    this.id = options.id || this.generateId();
    this.points = options.points;
    this.holes = options.holes || [];
    this.fillColor = options.fillColor || '#000000';
    this.strokeColor = options.strokeColor || '#000000';
    this.strokeWidth = options.strokeWidth || 1;
    this.fillAlpha = options.fillAlpha !== undefined ? options.fillAlpha : 0.5;
    this.strokeAlpha = options.strokeAlpha !== undefined ? options.strokeAlpha : 1.0;
    this.visible = options.visible !== undefined ? options.visible : true;
    this.zIndex = options.zIndex || 0;
  }

  /**
   * 生成唯一ID
   */
  private generateId(): string {
    return 'polygon_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
  }

  /**
   * 设置点列表
   */
  public setPoints(points: LatLng[]): void {
    this.points = points;
  }

  /**
   * 获取点列表
   */
  public getPoints(): LatLng[] {
    return this.points;
  }

  /**
   * 添加点
   */
  public addPoint(point: LatLng): void {
    this.points.push(point);
  }

  /**
   * 插入点
   */
  public insertPoint(index: number, point: LatLng): void {
    this.points.splice(index, 0, point);
  }

  /**
   * 移除点
   */
  public removePoint(index: number): LatLng | null {
    if (index >= 0 && index < this.points.length) {
      return this.points.splice(index, 1)[0];
    }
    return null;
  }

  /**
   * 设置洞
   */
  public setHoles(holes: LatLng[][]): void {
    this.holes = holes;
  }

  /**
   * 获取洞
   */
  public getHoles(): LatLng[][] {
    return this.holes;
  }

  /**
   * 添加洞
   */
  public addHole(hole: LatLng[]): void {
    this.holes.push(hole);
  }

  /**
   * 移除洞
   */
  public removeHole(index: number): LatLng[] | null {
    if (index >= 0 && index < this.holes.length) {
      return this.holes.splice(index, 1)[0];
    }
    return null;
  }

  /**
   * 设置填充颜色
   */
  public setFillColor(color: string): void {
    this.fillColor = color;
  }

  /**
   * 获取填充颜色
   */
  public getFillColor(): string {
    return this.fillColor;
  }

  /**
   * 设置描边颜色
   */
  public setStrokeColor(color: string): void {
    this.strokeColor = color;
  }

  /**
   * 获取描边颜色
   */
  public getStrokeColor(): string {
    return this.strokeColor;
  }

  /**
   * 设置描边宽度
   */
  public setStrokeWidth(width: number): void {
    this.strokeWidth = Math.max(0, width);
  }

  /**
   * 获取描边宽度
   */
  public getStrokeWidth(): number {
    return this.strokeWidth;
  }

  /**
   * 设置填充透明度
   */
  public setFillAlpha(alpha: number): void {
    this.fillAlpha = Math.max(0, Math.min(1, alpha));
  }

  /**
   * 获取填充透明度
   */
  public getFillAlpha(): number {
    return this.fillAlpha;
  }

  /**
   * 设置描边透明度
   */
  public setStrokeAlpha(alpha: number): void {
    this.strokeAlpha = Math.max(0, Math.min(1, alpha));
  }

  /**
   * 获取描边透明度
   */
  public getStrokeAlpha(): number {
    return this.strokeAlpha;
  }

  /**
   * 设置可见性
   */
  public setVisible(visible: boolean): void {
    this.visible = visible;
  }

  /**
   * 是否可见
   */
  public isVisible(): boolean {
    return this.visible;
  }

  /**
   * 设置Z轴顺序
   */
  public setZIndex(zIndex: number): void {
    this.zIndex = zIndex;
  }

  /**
   * 获取Z轴顺序
   */
  public getZIndex(): number {
    return this.zIndex;
  }

  /**
   * 计算周长（米）
   */
  public getPerimeter(): number {
    if (this.points.length < 3) {
      return 0;
    }

    let perimeter = 0;
    for (let i = 0; i < this.points.length; i++) {
      const current = this.points[i];
      const next = this.points[(i + 1) % this.points.length];
      perimeter += current.distanceTo(next);
    }
    return perimeter;
  }

  /**
   * 计算面积（平方米）
   */
  public getArea(): number {
    if (this.points.length < 3) {
      return 0;
    }

    // 使用球面几何计算面积
    const R = 6371000; // 地球半径（米）
    let area = 0;
    
    for (let i = 0; i < this.points.length; i++) {
      const current = this.points[i];
      const next = this.points[(i + 1) % this.points.length];
      
      const lat1 = current.latitude * Math.PI / 180;
      const lat2 = next.latitude * Math.PI / 180;
      const dLon = (next.longitude - current.longitude) * Math.PI / 180;
      
      area += dLon * (2 + Math.sin(lat1) + Math.sin(lat2));
    }
    
    area = Math.abs(area * R * R / 2);
    
    // 减去洞的面积
    for (const hole of this.holes) {
      if (hole.length >= 3) {
        let holeArea = 0;
        for (let i = 0; i < hole.length; i++) {
          const current = hole[i];
          const next = hole[(i + 1) % hole.length];
          
          const lat1 = current.latitude * Math.PI / 180;
          const lat2 = next.latitude * Math.PI / 180;
          const dLon = (next.longitude - current.longitude) * Math.PI / 180;
          
          holeArea += dLon * (2 + Math.sin(lat1) + Math.sin(lat2));
        }
        area -= Math.abs(holeArea * R * R / 2);
      }
    }
    
    return area;
  }

  /**
   * 计算边界框
   */
  public getBounds(): GeoBounds {
    if (this.points.length === 0) {
      return { north: 0, east: 0, south: 0, west: 0 };
    }

    let north = this.points[0].latitude;
    let east = this.points[0].longitude;
    let south = this.points[0].latitude;
    let west = this.points[0].longitude;

    for (const point of this.points) {
      north = Math.max(north, point.latitude);
      east = Math.max(east, point.longitude);
      south = Math.min(south, point.latitude);
      west = Math.min(west, point.longitude);
    }

    return { north, east, south, west };
  }

  /**
   * 检查点是否在多边形内
   */
  public contains(point: LatLng): boolean {
    if (this.points.length < 3) {
      return false;
    }

    let inside = false;
    for (let i = 0, j = this.points.length - 1; i < this.points.length; j = i++) {
      const pi = this.points[i];
      const pj = this.points[j];
      
      if (((pi.latitude > point.latitude) !== (pj.latitude > point.latitude)) &&
          (point.longitude < (pj.longitude - pi.longitude) * (point.latitude - pi.latitude) / (pj.latitude - pi.latitude) + pi.longitude)) {
        inside = !inside;
      }
    }

    // 检查是否在洞内
    for (const hole of this.holes) {
      if (this.isPointInPolygon(point, hole)) {
        inside = false;
        break;
      }
    }

    return inside;
  }

  /**
   * 检查点是否在简单多边形内
   */
  private isPointInPolygon(point: LatLng, polygon: LatLng[]): boolean {
    if (polygon.length < 3) {
      return false;
    }

    let inside = false;
    for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      const pi = polygon[i];
      const pj = polygon[j];
      
      if (((pi.latitude > point.latitude) !== (pj.latitude > point.latitude)) &&
          (point.longitude < (pj.longitude - pi.longitude) * (point.latitude - pi.latitude) / (pj.latitude - pi.latitude) + pi.longitude)) {
        inside = !inside;
      }
    }

    return inside;
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return `Polygon(id=${this.id}, points=${this.points.length}, holes=${this.holes.length})`;
  }
}
