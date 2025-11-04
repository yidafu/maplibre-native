/**
 * Marker - 标注封装类
 *
 * 符合 ArkTS 规范的封装实现
 */
import maplibre from 'libmaplibre.so';
import type { MarkerOptions as NAPIMarkerOptions } from 'libmaplibre.so';
import { LatLng } from '../geometry/LatLng';
import type { ILatLng } from '../types/NativeTypes';
import type { MapLibreMap } from '../MapLibreMap';

/**
 * 锚点接口
 */
export interface MarkerAnchor {
  u: number;
  v: number;
}

/**
 * 原生 Marker 选项接口（用于 NAPI 层交互）
 * 兼容 NAPI 层的 MarkerOptions，但 position 使用 ILatLng
 */
export interface NativeMarkerOptions {
  position: ILatLng;
  icon?: string;
  title?: string;
  snippet?: string;
  visible?: boolean;
  alpha?: number;
  rotation?: number;
  draggable?: boolean;
  zIndex?: number;
  anchor?: MarkerAnchor;
}

/**
 * 内部创建标记
 */
class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

/**
 * Marker 封装类
 */
export class Marker {
  private nativeInstance: maplibre.Marker;
  private _id: number = 0; // 存储 Marker ID（由 MarkerManager 设置）
  private _map: MapLibreMap | null = null; // 存储所属的 MapLibreMap
  private _selected: boolean = false; // 存储选中状态
  private _dragState: number = 0; // 存储拖拽状态

  /**
   * 构造函数
   * 支持两种模式：
   * 1. 从选项创建: new Marker(options)
   * 2. 从 NAPI 实例创建（内部使用）: new Marker(marker, nativeInstance)
   */
  constructor(optionsOrMarker: NativeMarkerOptions | InternalMarker, nativeInstance?: maplibre.Marker) {
    if (optionsOrMarker === InternalMarker.INSTANCE && nativeInstance) {
      // 内部模式：从 NAPI 实例创建
      this.nativeInstance = nativeInstance;
    } else if (typeof optionsOrMarker === 'object') {
      // 正常模式：从选项对象创建
      // 转换为 NAPI 层期望的 MarkerOptions 类型
      const opts = optionsOrMarker as NativeMarkerOptions;
      const napiOptions: NAPIMarkerOptions = {
        position: opts.position,
        icon: opts.icon,
        title: opts.title,
        snippet: opts.snippet,
        visible: opts.visible,
        alpha: opts.alpha,
        rotation: opts.rotation,
        draggable: opts.draggable,
        zIndex: opts.zIndex,
        anchor: opts.anchor
      };
      this.nativeInstance = new maplibre.Marker(napiOptions);
    } else {
      throw new Error('Invalid Marker constructor arguments');
    }
  }

  /**
   * 从 NAPI 实例创建（内部使用）
   */
  static fromNative(nativeInstance: maplibre.Marker): Marker {
    return new Marker(InternalMarker.INSTANCE, nativeInstance);
  }

  /**
   * 创建 Marker（静态工厂方法）
   */
  static createFromOptions(options: NativeMarkerOptions): Marker {
    return new Marker(options);
  }

  /**
   * 获取 NAPI 实例（内部使用）
   */
  getNative(): maplibre.Marker {
    return this.nativeInstance;
  }

  // ========== Marker API 方法 ==========

  getPosition(): LatLng {
    const pos = this.nativeInstance.getPosition();
    return new LatLng(pos.latitude, pos.longitude);
  }

  setPosition(position: LatLng): Marker {
    this.nativeInstance.setPosition(position.toObject());
    return this;
  }

  getIcon(): string {
    return this.nativeInstance.getIcon() || '';
  }

  setIcon(iconId: string): Marker {
    this.nativeInstance.setIcon(iconId);
    return this;
  }

  getTitle(): string {
    return this.nativeInstance.getTitle();
  }

  setTitle(title: string): Marker {
    this.nativeInstance.setTitle(title);
    return this;
  }

  getSnippet(): string {
    return this.nativeInstance.getSnippet();
  }

  setSnippet(snippet: string): Marker {
    this.nativeInstance.setSnippet(snippet);
    return this;
  }

  getRotation(): number {
    return this.nativeInstance.getRotation();
  }

  setRotation(rotation: number): Marker {
    this.nativeInstance.setRotation(rotation);
    return this;
  }

  getAlpha(): number {
    return this.nativeInstance.getAlpha();
  }

  setAlpha(alpha: number): Marker {
    this.nativeInstance.setAlpha(alpha);
    return this;
  }

  getZIndex(): number {
    return this.nativeInstance.getZIndex();
  }

  setZIndex(zIndex: number): Marker {
    this.nativeInstance.setZIndex(zIndex);
    return this;
  }

  getAnchor(): MarkerAnchor {
    return this.nativeInstance.getAnchor() as MarkerAnchor;
  }

  setAnchor(u: number, v: number): Marker {
    this.nativeInstance.setAnchor(u, v);
    return this;
  }

  getDraggable(): boolean {
    return this.nativeInstance.getDraggable();
  }

  setDraggable(draggable: boolean): Marker {
    this.nativeInstance.setDraggable(draggable);
    return this;
  }

  getVisible(): boolean {
    return this.nativeInstance.getVisible();
  }

  setVisible(visible: boolean): Marker {
    this.nativeInstance.setVisible(visible);
    return this;
  }

  isSelected(): boolean {
    return this.nativeInstance.isSelected();
  }

  showInfoWindow(): void {
    this.nativeInstance.showInfoWindow();
  }

  hideInfoWindow(): void {
    this.nativeInstance.hideInfoWindow();
  }

  isInfoWindowShown(): boolean {
    return this.nativeInstance.isInfoWindowShown();
  }

  // ========== 扩展方法（MarkerManager 需要的）==========

  /**
   * 获取 Marker ID（内部使用）
   */
  getId(): number {
    return this._id;
  }

  /**
   * 设置 Marker ID（内部使用）
   */
  setId(id: number): Marker {
    this._id = id;
    return this;
  }

  /**
   * 设置所属的 MapLibreMap（内部使用）
   */
  setMapLibreMap(map: MapLibreMap): Marker {
    this._map = map;
    return this;
  }

  /**
   * 设置选中状态（内部使用）
   */
  setSelected(selected: boolean): Marker {
    this._selected = selected;
    return this;
  }

  /**
   * 获取拖拽状态（内部使用）
   */
  getDragState(): number {
    return this._dragState;
  }

  /**
   * 设置拖拽状态（内部使用）
   */
  setDragState(state: number): Marker {
    this._dragState = state;
    return this;
  }

  /**
   * 移除 Marker（内部使用）
   */
  remove(): void {
    // MarkerManager 使用的内部方法
  }

  /**
   * 动画移动到指定位置
   */
  animateToPosition(position: LatLng, duration: number): void {
    // 动画方法
  }

  /**
   * 动画改变透明度
   */
  animateAlpha(alpha: number, duration: number): void {
    // 动画方法
  }

  /**
   * 动画旋转
   */
  animateRotation(rotation: number, duration: number): void {
    // 动画方法
  }
}
