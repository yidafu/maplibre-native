/**
 * Polygon - 多边形封装类
 *
 * 符合 ArkTS 规范的封装实现
 */
import maplibre from 'libmaplibre.so';
import { LatLng } from '../geometry/LatLng';
import { MapLibreMap } from '../MapLibreMap';
import type { ILatLng } from '../types/NativeTypes';
/**
 * PolygonOptions - 多边形选项接口
 */
export interface PolygonOptions {
  /** 多边形 ID（可选） */
  id?: string;

  /** 多边形的点坐标数组 */
  points: LatLng[];

  /** 孔洞数组（可选） */
  holes?: LatLng[][];

  /** 填充颜色（可选，默认 #000000） */
  fillColor?: string;

  /** 描边颜色（可选，默认 #000000） */
  strokeColor?: string;

  /** 描边宽度（可选，默认 1） */
  strokeWidth?: number;

  /** 填充透明度（可选，默认 0.5，范围 0-1） */
  fillAlpha?: number;

  /** 描边透明度（可选，默认 1.0，范围 0-1） */
  strokeAlpha?: number;

  /** 是否可见（可选，默认 true） */
  visible?: boolean;

  /** Z 轴顺序（可选，默认 0） */
  zIndex?: number;
}

/**
 * 内部创建标记
 */
class InternalPolygon {
  static readonly INSTANCE = new InternalPolygon();

  private constructor() {
  }
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
        points: options.points.map((p: LatLng): ILatLng => p.toObject()),
        holes: options.holes ? options.holes.map((hole: LatLng[]): ILatLng[] =>
        hole.map((p: LatLng): ILatLng => p.toObject())
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

  /**
   * 获取多边形的点坐标
   * @returns 点坐标数组
   */
  getPoints(): LatLng[] {
    const nativePoints: ILatLng[] = this.nativeInstance.getPoints() as ILatLng[];
    return nativePoints.map((pt: ILatLng): LatLng => new LatLng(pt.latitude, pt.longitude));
  }

  /**
   * 设置多边形的点坐标
   * @param points 点坐标数组
   * @returns this（支持链式调用）
   */
  setPoints(points: LatLng[]): Polygon {
    const nativePoints: ILatLng[] = points.map((p: LatLng): ILatLng => p.toObject());
    this.nativeInstance.setPoints(nativePoints);
    return this;
  }

  /**
   * 添加一个点到多边形
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
   * 获取孔洞列表
   * @returns 孔洞数组，每个孔洞是一个点坐标数组
   */
  getHoles(): LatLng[][] {
    const nativeHoles: ILatLng[][] = this.nativeInstance.getHoles() as ILatLng[][];
    return nativeHoles.map((hole: ILatLng[]): LatLng[] =>
    hole.map((pt: ILatLng): LatLng => new LatLng(pt.latitude, pt.longitude))
    );
  }

  /**
   * 设置孔洞列表
   * @param holes 孔洞数组
   * @returns this（支持链式调用）
   */
  setHoles(holes: LatLng[][]): Polygon {
    const nativeHoles: ILatLng[][] = holes.map((hole: LatLng[]): ILatLng[] =>
    hole.map((p: LatLng): ILatLng => p.toObject())
    );
    this.nativeInstance.setHoles(nativeHoles);
    return this;
  }

  /**
   * 添加一个孔洞
   * @param hole 孔洞点坐标数组
   */
  addHole(hole: LatLng[]): void {
    const nativeHole: ILatLng[] = hole.map((p: LatLng): ILatLng => p.toObject());
    this.nativeInstance.addHole(nativeHole);
  }

  /**
   * 移除指定索引的孔洞
   * @param index 孔洞索引
   * @returns 被移除的孔洞点坐标数组，如果索引无效则返回 null
   */
  removeHole(index: number): LatLng[] | null {
    const nativeHole = this.nativeInstance.removeHole(index);
    if (!nativeHole) {
      return null;
    }
    const holes = nativeHole as ILatLng[];
    return holes.map((pt: ILatLng): LatLng => new LatLng(pt.latitude, pt.longitude));
  }

  /**
   * 获取填充颜色
   * @returns 颜色字符串
   */
  getFillColor(): string {
    return this.nativeInstance.getFillColor();
  }

  /**
   * 设置填充颜色
   * @param color 颜色字符串（如 '#FF0000' 或 'red'）
   * @returns this（支持链式调用）
   */
  setFillColor(color: string): Polygon {
    this.nativeInstance.setFillColor(color);
    return this;
  }

  /**
   * 获取描边颜色
   * @returns 颜色字符串
   */
  getStrokeColor(): string {
    return this.nativeInstance.getStrokeColor();
  }

  /**
   * 设置描边颜色
   * @param color 颜色字符串（如 '#FF0000' 或 'red'）
   * @returns this（支持链式调用）
   */
  setStrokeColor(color: string): Polygon {
    this.nativeInstance.setStrokeColor(color);
    return this;
  }

  /**
   * 获取描边宽度
   * @returns 宽度值（像素）
   */
  getStrokeWidth(): number {
    return this.nativeInstance.getStrokeWidth();
  }

  /**
   * 设置描边宽度
   * @param width 宽度值（像素）
   * @returns this（支持链式调用）
   */
  setStrokeWidth(width: number): Polygon {
    this.nativeInstance.setStrokeWidth(width);
    return this;
  }

  /**
   * 获取填充透明度
   * @returns 透明度值（0-1）
   */
  getFillAlpha(): number {
    return this.nativeInstance.getFillAlpha();
  }

  /**
   * 设置填充透明度
   * @param alpha 透明度值（0-1，0 为完全透明，1 为完全不透明）
   * @returns this（支持链式调用）
   */
  setFillAlpha(alpha: number): Polygon {
    this.nativeInstance.setFillAlpha(alpha);
    return this;
  }

  /**
   * 获取描边透明度
   * @returns 透明度值（0-1）
   */
  getStrokeAlpha(): number {
    return this.nativeInstance.getStrokeAlpha();
  }

  /**
   * 设置描边透明度
   * @param alpha 透明度值（0-1，0 为完全透明，1 为完全不透明）
   * @returns this（支持链式调用）
   */
  setStrokeAlpha(alpha: number): Polygon {
    this.nativeInstance.setStrokeAlpha(alpha);
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
  setVisible(visible: boolean): Polygon {
    this.nativeInstance.setVisible(visible);
    return this;
  }

  /**
   * 检查多边形是否可见（getVisible 的别名）
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
   * @param map MapLibreMap 实例
   * @returns this（支持链式调用）
   */
  setMapLibreMap(map: MapLibreMap): Polygon {
    // this.nativeInstance.setMapLibreMap(map);
    return this;
  }

  /**
   * 转换为字符串表示
   * @returns 字符串表示，包含 ID、点数量和孔洞数量
   */
  public toString(): string {
    return `Polygon(id=${this.getId()}, points=${this.getPoints().length}, holes=${this.getHoles().length})`;
  }
}
