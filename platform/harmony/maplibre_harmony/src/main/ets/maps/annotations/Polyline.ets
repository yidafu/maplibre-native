/**
 * Polyline - 折线封装类
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
 * PolylineOptions - 折线选项接口
 */
export interface PolylineOptions {
  id?: string;
  points: LatLng[];
  color?: string;
  width?: number;
  alpha?: number;
  visible?: boolean;
  zIndex?: number;
  pattern?: number[];
  jointType?: string;
  capType?: string;
}

/**
 * 内部创建标记
 */
class InternalPolyline {
  static readonly INSTANCE = new InternalPolyline();
  private constructor() {}
}

/**
 * Polyline 封装类
 */
export class Polyline {
  private nativeInstance: maplibre.Polyline;

  /**
   * 构造函数
   * 支持两种模式：
   * 1. 从选项创建: new Polyline(options)
   * 2. 从 NAPI 实例创建（内部使用）: new Polyline(marker, nativeInstance)
   */
  constructor(optionsOrPolyline: PolylineOptions | InternalPolyline, nativeInstance?: maplibre.Polyline) {
    if (optionsOrPolyline === InternalPolyline.INSTANCE && nativeInstance) {
      // 内部模式：从 NAPI 实例创建
      this.nativeInstance = nativeInstance;
    } else if (typeof optionsOrPolyline === 'object') {
      // 正常模式：从选项对象创建
      const options = optionsOrPolyline as PolylineOptions;
      
      // 转换 LatLng 对象为原生格式
      const nativeOptions: ESObject = {
        points: options.points.map((p: LatLng): Object => {
          if (p.getNative) {
            return p.getNative();
          }
          const coord: LatLngLike = { latitude: p.latitude, longitude: p.longitude };
          return coord as Object;
        }),
        color: options.color || '#000000',
        width: options.width !== undefined ? options.width : 10,
        alpha: options.alpha !== undefined ? options.alpha : 1.0,
        visible: options.visible !== undefined ? options.visible : true,
        zIndex: options.zIndex || 0,
        pattern: options.pattern || null,
        jointType: options.jointType || 'round',
        capType: options.capType || 'round'
      };
      
      this.nativeInstance = new maplibre.Polyline(nativeOptions);
    } else {
      throw new Error('Invalid Polyline constructor arguments');
    }
  }

  /**
   * 从 NAPI 实例创建（内部使用）
   */
  static fromNative(nativeInstance: maplibre.Polyline): Polyline {
    return new Polyline(InternalPolyline.INSTANCE, nativeInstance);
  }

  /**
   * 创建 Polyline（静态工厂方法）
   */
  static createFromOptions(options: PolylineOptions): Polyline {
    return new Polyline(options);
  }

  /**
   * 获取 NAPI 实例（内部使用）
   */
  getNative(): maplibre.Polyline {
    return this.nativeInstance;
  }

  // ========== Polyline API 方法 ==========

  getPoints(): LatLng[] {
    const nativePoints: Object[] = this.nativeInstance.getPoints();
    return nativePoints.map((p: Object): LatLng => LatLng.fromNative(p as maplibre.LatLng));
  }

  setPoints(points: LatLng[]): Polyline {
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

  getColor(): string {
    return this.nativeInstance.getColor();
  }

  setColor(color: string): Polyline {
    this.nativeInstance.setColor(color);
    return this;
  }

  getWidth(): number {
    return this.nativeInstance.getWidth();
  }

  setWidth(width: number): Polyline {
    this.nativeInstance.setWidth(width);
    return this;
  }

  getAlpha(): number {
    return this.nativeInstance.getAlpha();
  }

  setAlpha(alpha: number): Polyline {
    this.nativeInstance.setAlpha(alpha);
    return this;
  }

  getVisible(): boolean {
    return this.nativeInstance.getVisible();
  }

  setVisible(visible: boolean): Polyline {
    this.nativeInstance.setVisible(visible);
    return this;
  }

  isVisible(): boolean {
    return this.getVisible();
  }

  getZIndex(): number {
    return this.nativeInstance.getZIndex();
  }

  setZIndex(zIndex: number): Polyline {
    this.nativeInstance.setZIndex(zIndex);
    return this;
  }

  getPattern(): number[] | null {
    return this.nativeInstance.getPattern();
  }

  setPattern(pattern: number[] | null): Polyline {
    this.nativeInstance.setPattern(pattern);
    return this;
  }

  getJointType(): string {
    return this.nativeInstance.getJointType();
  }

  setJointType(jointType: string): Polyline {
    this.nativeInstance.setJointType(jointType);
    return this;
  }

  getCapType(): string {
    return this.nativeInstance.getCapType();
  }

  setCapType(capType: string): Polyline {
    this.nativeInstance.setCapType(capType);
    return this;
  }

  // ========== 扩展方法（内部使用）==========

  /**
   * 获取 Polyline ID（内部使用）
   */
  getId(): number {
    return this.nativeInstance.getId();
  }

  /**
   * 设置 Polyline ID（内部使用）
   */
  setId(id: number): Polyline {
    this.nativeInstance.setId(id);
    return this;
  }

  /**
   * 设置所属的 MapLibreMap（内部使用）
   */
  setMapLibreMap(map: Object): Polyline {
    this.nativeInstance.setMapLibreMap(map);
    return this;
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return `Polyline(id=${this.getId()}, points=${this.getPoints().length}, color=${this.getColor()})`;
  }
}
