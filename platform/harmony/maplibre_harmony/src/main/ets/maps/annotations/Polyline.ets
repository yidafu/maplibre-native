/**
 * Polyline - 折线封装类
 * 
 * 符合 ArkTS 规范的封装实现
 */
import maplibre from 'libmaplibre.so';
import { LatLng } from '../geometry/LatLng';
import { MapLibreMap } from '../MapLibreMap';
import type { ILatLng } from '../types/NativeTypes';

/**
 * PolylineOptions - 折线选项接口
 */
export interface PolylineOptions {
  /** 折线 ID（可选） */
  id?: string;
  /** 折线的点坐标数组 */
  points: LatLng[];
  /** 线条颜色（可选，默认 #000000） */
  color?: string;
  /** 线条宽度（可选，默认 10） */
  width?: number;
  /** 线条透明度（可选，默认 1.0，范围 0-1） */
  alpha?: number;
  /** 是否可见（可选，默认 true） */
  visible?: boolean;
  /** Z 轴顺序（可选，默认 0） */
  zIndex?: number;
  /** 线条样式/虚线模式（可选，如 [5, 5] 表示 5px 实线 5px 空白） */
  pattern?: number[] | null;
  /** 连接类型（可选，默认 'round'） */
  jointType?: string;
  /** 端点类型（可选，默认 'round'） */
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
        points: options.points.map((p: LatLng): ILatLng => p.toObject()),
        color: options.color || '#000000',
        width: options.width !== undefined ? options.width : 10,
        alpha: options.alpha !== undefined ? options.alpha : 1.0,
        visible: options.visible !== undefined ? options.visible : true,
        zIndex: options.zIndex || 0,
        pattern: options.pattern !== undefined ? options.pattern : null,
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

  /**
   * 获取折线的点坐标
   * @returns 点坐标数组
   */
  getPoints(): LatLng[] {
    const nativePoints: ILatLng[] = this.nativeInstance.getPoints() as ILatLng[];
    return nativePoints.map((pt: ILatLng): LatLng => new LatLng(pt.latitude, pt.longitude));
  }

  /**
   * 设置折线的点坐标
   * @param points 点坐标数组
   * @returns this（支持链式调用）
   */
  setPoints(points: LatLng[]): Polyline {
    const nativePoints: ILatLng[] = points.map((p: LatLng): ILatLng => p.toObject());
    this.nativeInstance.setPoints(nativePoints);
    return this;
  }

  /**
   * 添加一个点到折线末尾
   * @param point 点坐标
   */
  addPoint(point: LatLng): void {
    this.nativeInstance.addPoint(point.toObject());
  }

  /**
   * 在指定位置插入一个点
   * @param index 插入位置索引
   * @param point 点坐标
   */
  insertPoint(index: number, point: LatLng): void {
    this.nativeInstance.insertPoint(index, point.toObject());
  }

  /**
   * 移除指定索引的点
   * @param index 点索引
   * @returns 被移除的点坐标，如果索引无效则返回 null
   */
  removePoint(index: number): LatLng | null {
    const nativePoint = this.nativeInstance.removePoint(index);
    if (nativePoint) {
      const pt = nativePoint as ILatLng;
      return new LatLng(pt.latitude, pt.longitude);
    }
    return null;
  }

  /**
   * 获取线条颜色
   * @returns 颜色字符串
   */
  getColor(): string {
    return this.nativeInstance.getColor();
  }

  /**
   * 设置线条颜色
   * @param color 颜色字符串（如 '#FF0000' 或 'red'）
   * @returns this（支持链式调用）
   */
  setColor(color: string): Polyline {
    this.nativeInstance.setColor(color);
    return this;
  }

  /**
   * 获取线条宽度
   * @returns 宽度值（像素）
   */
  getWidth(): number {
    return this.nativeInstance.getWidth();
  }

  /**
   * 设置线条宽度
   * @param width 宽度值（像素）
   * @returns this（支持链式调用）
   */
  setWidth(width: number): Polyline {
    this.nativeInstance.setWidth(width);
    return this;
  }

  /**
   * 获取线条透明度
   * @returns 透明度值（0-1）
   */
  getAlpha(): number {
    return this.nativeInstance.getAlpha();
  }

  /**
   * 设置线条透明度
   * @param alpha 透明度值（0-1，0 为完全透明，1 为完全不透明）
   * @returns this（支持链式调用）
   */
  setAlpha(alpha: number): Polyline {
    this.nativeInstance.setAlpha(alpha);
    return this;
  }

  /**
   * 获取可见性
   * @returns 是否可见
   */
  getVisible(): boolean {
    return this.nativeInstance.getVisible();
  }

  /**
   * 设置可见性
   * @param visible 是否可见
   * @returns this（支持链式调用）
   */
  setVisible(visible: boolean): Polyline {
    this.nativeInstance.setVisible(visible);
    return this;
  }

  /**
   * 检查折线是否可见（getVisible 的别名）
   * @returns 是否可见
   */
  isVisible(): boolean {
    return this.getVisible();
  }

  /**
   * 获取 Z-index（Z 轴顺序）
   * @returns Z-index 值
   */
  getZIndex(): number {
    return this.nativeInstance.getZIndex();
  }

  /**
   * 设置 Z-index（Z 轴顺序）
   * @param zIndex Z-index 值（数值越大，显示层级越高）
   * @returns this（支持链式调用）
   */
  setZIndex(zIndex: number): Polyline {
    this.nativeInstance.setZIndex(zIndex);
    return this;
  }

  /**
   * 获取线条样式/虚线模式
   * @returns 样式数组或 null（如 [5, 5] 表示 5px 实线 5px 空白）
   */
  getPattern(): number[] | null {
    return this.nativeInstance.getPattern();
  }

  /**
   * 设置线条样式/虚线模式
   * @param pattern 样式数组或 null（如 [5, 5] 表示 5px 实线 5px 空白）
   * @returns this（支持链式调用）
   */
  setPattern(pattern: number[] | null): Polyline {
    this.nativeInstance.setPattern(pattern);
    return this;
  }

  /**
   * 获取线条连接类型
   * @returns 连接类型（'round' | 'bevel' | 'miter'）
   */
  getJointType(): string {
    return this.nativeInstance.getJointType();
  }

  /**
   * 设置线条连接类型
   * @param jointType 连接类型（'round' | 'bevel' | 'miter'）
   * @returns this（支持链式调用）
   */
  setJointType(jointType: string): Polyline {
    this.nativeInstance.setJointType(jointType);
    return this;
  }

  /**
   * 获取线条端点类型
   * @returns 端点类型（'round' | 'butt' | 'square'）
   */
  getCapType(): string {
    return this.nativeInstance.getCapType();
  }

  /**
   * 设置线条端点类型
   * @param capType 端点类型（'round' | 'butt' | 'square'）
   * @returns this（支持链式调用）
   */
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
   * @param map MapLibreMap 实例
   * @returns this（支持链式调用）
   */
  setMapLibreMap(map: MapLibreMap): Polyline {
    // Note: NAPI setMapLibreMap is called internally
    return this;
  }

  /**
   * 转换为字符串表示
   * @returns 字符串表示，包含 ID、点数量和颜色
   */
  public toString(): string {
    return `Polyline(id=${this.getId()}, points=${this.getPoints().length}, color=${this.getColor()})`;
  }
}
