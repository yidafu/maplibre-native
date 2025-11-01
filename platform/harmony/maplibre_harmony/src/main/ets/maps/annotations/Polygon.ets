/**
 * Polygon - 多边形封装类
 * 
 * 符合 ArkTS 规范的封装实现
 */
import maplibre from 'libmaplibre.so';
import { LatLng } from '../geometry/LatLng';

interface LatLngLike {
  latitude: number;
  longitude: number;
}

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
 * 内部创建标记
 */
class InternalPolygon {
  static readonly INSTANCE = new InternalPolygon();
  private constructor() {}
}

/**
 * Polygon 封装类
 */
export class Polygon {
  private nativeInstance: maplibre.Polygon;

  /**
   * 构造函数
   * 支持两种模式：
   * 1. 从选项创建: new Polygon(options)
   * 2. 从 NAPI 实例创建（内部使用）: new Polygon(marker, nativeInstance)
   */
  constructor(optionsOrPolygon: PolygonOptions | InternalPolygon, nativeInstance?: maplibre.Polygon) {
    if (optionsOrPolygon === InternalPolygon.INSTANCE && nativeInstance) {
      // 内部模式：从 NAPI 实例创建
      this.nativeInstance = nativeInstance;
    } else if (typeof optionsOrPolygon === 'object') {
      // 正常模式：从选项对象创建
      const options = optionsOrPolygon as PolygonOptions;
      
      // 转换 LatLng 对象为原生格式
      const nativeOptions: ESObject = {
        points: options.points.map((p: LatLng): Object => {
          if (p.getNative) {
            return p.getNative();
          }
          const coord: LatLngLike = { latitude: p.latitude, longitude: p.longitude };
          return coord as Object;
        }),
        holes: options.holes ? options.holes.map((hole: LatLng[]): Object[] => 
          hole.map((p: LatLng): Object => {
            if (p.getNative) {
              return p.getNative();
            }
            const coord: LatLngLike = { latitude: p.latitude, longitude: p.longitude };
            return coord as Object;
          })
        ) : [],
        fillColor: options.fillColor || '#000000',
        strokeColor: options.strokeColor || '#000000',
        strokeWidth: options.strokeWidth !== undefined ? options.strokeWidth : 1,
        fillAlpha: options.fillAlpha !== undefined ? options.fillAlpha : 0.5,
        strokeAlpha: options.strokeAlpha !== undefined ? options.strokeAlpha : 1.0,
        visible: options.visible !== undefined ? options.visible : true,
        zIndex: options.zIndex || 0
      };
      
      this.nativeInstance = new maplibre.Polygon(nativeOptions);
    } else {
      throw new Error('Invalid Polygon constructor arguments');
    }
  }

  /**
   * 从 NAPI 实例创建（内部使用）
   */
  static fromNative(nativeInstance: maplibre.Polygon): Polygon {
    return new Polygon(InternalPolygon.INSTANCE, nativeInstance);
  }

  /**
   * 创建 Polygon（静态工厂方法）
   */
  static createFromOptions(options: PolygonOptions): Polygon {
    return new Polygon(options);
  }

  /**
   * 获取 NAPI 实例（内部使用）
   */
  getNative(): maplibre.Polygon {
    return this.nativeInstance;
  }

  // ========== Polygon API 方法 ==========

  getPoints(): LatLng[] {
    const nativePoints: Object[] = this.nativeInstance.getPoints();
    return nativePoints.map((p: Object): LatLng => LatLng.fromNative(p as maplibre.LatLng));
  }

  setPoints(points: LatLng[]): Polygon {
    const nativePoints: Object[] = points.map((p: LatLng): Object => {
      if (p.getNative) {
        return p.getNative();
      }
      const coord: LatLngLike = { latitude: p.latitude, longitude: p.longitude };
      return coord as Object;
    });
    this.nativeInstance.setPoints(nativePoints);
    return this;
  }

  addPoint(point: LatLng): void {
    this.nativeInstance.addPoint(point.getNative ? point.getNative() : { latitude: point.latitude, longitude: point.longitude });
  }

  insertPoint(index: number, point: LatLng): void {
    this.nativeInstance.insertPoint(index, point.getNative ? point.getNative() : { latitude: point.latitude, longitude: point.longitude });
  }

  removePoint(index: number): LatLng | null {
    const nativePoint: Object = this.nativeInstance.removePoint(index);
    return nativePoint ? LatLng.fromNative(nativePoint as maplibre.LatLng) : null;
  }

  getHoles(): LatLng[][] {
    const nativeHoles: Object[][] = this.nativeInstance.getHoles();
    return nativeHoles.map((hole: Object[]): LatLng[] => 
      hole.map((p: Object): LatLng => LatLng.fromNative(p as maplibre.LatLng))
    );
  }

  setHoles(holes: LatLng[][]): Polygon {
    const nativeHoles: Object[][] = holes.map((hole: LatLng[]): Object[] => 
      hole.map((p: LatLng): Object => {
        if (p.getNative) {
          return p.getNative();
        }
        const coord: LatLngLike = { latitude: p.latitude, longitude: p.longitude };
        return coord as Object;
      })
    );
    this.nativeInstance.setHoles(nativeHoles);
    return this;
  }

  addHole(hole: LatLng[]): void {
    const nativeHole: Object[] = hole.map((p: LatLng): Object => {
      if (p.getNative) {
        return p.getNative();
      }
      const coord: LatLngLike = { latitude: p.latitude, longitude: p.longitude };
      return coord as Object;
    });
    this.nativeInstance.addHole(nativeHole);
  }

  removeHole(index: number): LatLng[] | null {
    const nativeHole: Object[] = this.nativeInstance.removeHole(index);
    if (!nativeHole) return null;
    return nativeHole.map((p: Object) => LatLng.fromNative(p as maplibre.LatLng));
  }

  getFillColor(): string {
    return this.nativeInstance.getFillColor();
  }

  setFillColor(color: string): Polygon {
    this.nativeInstance.setFillColor(color);
    return this;
  }

  getStrokeColor(): string {
    return this.nativeInstance.getStrokeColor();
  }

  setStrokeColor(color: string): Polygon {
    this.nativeInstance.setStrokeColor(color);
    return this;
  }

  getStrokeWidth(): number {
    return this.nativeInstance.getStrokeWidth();
  }

  setStrokeWidth(width: number): Polygon {
    this.nativeInstance.setStrokeWidth(width);
    return this;
  }

  getFillAlpha(): number {
    return this.nativeInstance.getFillAlpha();
  }

  setFillAlpha(alpha: number): Polygon {
    this.nativeInstance.setFillAlpha(alpha);
    return this;
  }

  getStrokeAlpha(): number {
    return this.nativeInstance.getStrokeAlpha();
  }

  setStrokeAlpha(alpha: number): Polygon {
    this.nativeInstance.setStrokeAlpha(alpha);
    return this;
  }

  getVisible(): boolean {
    return this.nativeInstance.getVisible();
  }

  setVisible(visible: boolean): Polygon {
    this.nativeInstance.setVisible(visible);
    return this;
  }

  isVisible(): boolean {
    return this.getVisible();
  }

  getZIndex(): number {
    return this.nativeInstance.getZIndex();
  }

  setZIndex(zIndex: number): Polygon {
    this.nativeInstance.setZIndex(zIndex);
    return this;
  }

  // ========== 扩展方法（内部使用）==========

  /**
   * 获取 Polygon ID（内部使用）
   */
  getId(): number {
    return this.nativeInstance.getId();
  }

  /**
   * 设置 Polygon ID（内部使用）
   */
  setId(id: number): Polygon {
    this.nativeInstance.setId(id);
    return this;
  }

  /**
   * 设置所属的 MapLibreMap（内部使用）
   */
  setMapLibreMap(map: Object): Polygon {
    this.nativeInstance.setMapLibreMap(map);
    return this;
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return `Polygon(id=${this.getId()}, points=${this.getPoints().length}, holes=${this.getHoles().length})`;
  }
}
