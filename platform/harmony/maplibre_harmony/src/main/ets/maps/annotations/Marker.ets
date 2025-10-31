/**
 * Marker - 标注封装类
 * 
 * 符合 ArkTS 规范的封装实现
 */
import maplibre from 'libmaplibre.so';
import { LatLng } from '../geometry/LatLng';

/**
 * 锚点接口
 */
export interface MarkerAnchor {
  u: number;
  v: number;
}

/**
 * 内部创建标记
 */
class InternalMarker {
  static readonly INSTANCE = new InternalMarker();
  private constructor() {}
}

/**
 * Marker 封装类
 */
export class Marker {
  private nativeInstance: maplibre.Marker;

  /**
   * 构造函数
   * 支持两种模式：
   * 1. 从选项创建: new Marker(options)
   * 2. 从 NAPI 实例创建（内部使用）: new Marker(marker, nativeInstance)
   */
  constructor(optionsOrMarker: ESObject | InternalMarker, nativeInstance?: maplibre.Marker) {
    if (optionsOrMarker === InternalMarker.INSTANCE && nativeInstance) {
      // 内部模式：从 NAPI 实例创建
      this.nativeInstance = nativeInstance;
    } else if (typeof optionsOrMarker === 'object') {
      // 正常模式：从选项对象创建
      this.nativeInstance = new maplibre.Marker(optionsOrMarker as ESObject);
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
  static createFromOptions(options: ESObject): Marker {
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
    return LatLng.fromNative(this.nativeInstance.getPosition());
  }

  setPosition(position: LatLng): Marker {
    this.nativeInstance.setPosition(position.getNative());
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
    // NAPI Marker 没有 getId 方法，这个是 MarkerManager 添加的
    // 返回一个临时值，实际 ID 由 MarkerManager 维护
    return 0;
  }

  /**
   * 设置 Marker ID（内部使用）
   */
  setId(id: number): void {
    // MarkerManager 使用的内部方法
    // 实际不修改 NAPI Marker，只是占位
  }

  /**
   * 设置所属的 MapLibreMap（内部使用）
   */
  setMapLibreMap(map: Object): void {
    // MarkerManager 使用的内部方法
    // 实际不修改 NAPI Marker，只是占位
  }

  /**
   * 设置选中状态（内部使用）
   */
  setSelected(selected: boolean): void {
    // MarkerManager 使用的内部方法
  }

  /**
   * 获取拖拽状态（内部使用）
   */
  getDragState(): number {
    // MarkerManager 使用的内部方法
    return 0;
  }

  /**
   * 设置拖拽状态（内部使用）
   */
  setDragState(state: number): void {
    // MarkerManager 使用的内部方法
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
