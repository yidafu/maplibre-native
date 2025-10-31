/**
 * Style - 样式管理类封装
 * 
 * 封装 NAPI Style 类，避免暴露内部类型
 */
import maplibre from 'libmaplibre.so';

/**
 * 内部标记，防止外部直接构造 Style
 */
class InternalMarker {
  static readonly INSTANCE = new InternalMarker();
  private constructor() {}
}

/**
 * Style - 地图样式管理类
 * 
 * 通过 MapLibreMap.getStyle() 获取实例
 * 不应该直接构造此类
 */
export class Style {
  private nativeInstance: maplibre.Style;

  /**
   * 私有构造函数，仅允许通过 fromNative 创建
   */
  constructor(marker: InternalMarker, nativeInstance: maplibre.Style) {
    if (marker !== InternalMarker.INSTANCE) {
      throw new Error('Style cannot be constructed directly. Use MapLibreMap.getStyle() instead.');
    }
    this.nativeInstance = nativeInstance;
  }

  /**
   * 从 NAPI 实例创建封装对象（内部使用）
   */
  static fromNative(nativeInstance: maplibre.Style): Style {
    return new Style(InternalMarker.INSTANCE, nativeInstance);
  }

  /**
   * 获取 NAPI 实例（内部使用）
   */
  getNative(): maplibre.Style {
    return this.nativeInstance;
  }

  // ========== 基本方法 ==========

  /**
   * 获取样式 URI
   */
  getUri(): string {
    return this.nativeInstance.getUri();
  }

  /**
   * 获取样式 JSON
   */
  getJson(): string {
    return this.nativeInstance.getJson();
  }

  /**
   * 样式是否完全加载
   */
  isFullyLoaded(): boolean {
    return this.nativeInstance.isFullyLoaded();
  }

  // ========== 数据源管理 ==========

  /**
   * 添加数据源
   */
  addSource(source: Object): void {
    this.nativeInstance.addSource(source);
  }

  /**
   * 移除数据源
   */
  removeSource(sourceId: string): boolean {
    return this.nativeInstance.removeSource(sourceId);
  }

  /**
   * 获取指定数据源
   */
  getSource(sourceId: string): Object | null {
    return this.nativeInstance.getSource(sourceId);
  }

  /**
   * 获取所有数据源
   */
  getSources(): Object[] {
    return this.nativeInstance.getSources();
  }

  // ========== 图层管理 ==========

  /**
   * 添加图层（添加到顶部）
   */
  addLayer(layer: Object): void {
    this.nativeInstance.addLayer(layer);
  }

  /**
   * 在指定图层下方添加图层
   */
  addLayerBelow(layer: Object, belowLayerId: string): void {
    this.nativeInstance.addLayerBelow(layer, belowLayerId);
  }

  /**
   * 在指定图层上方添加图层
   */
  addLayerAbove(layer: Object, aboveLayerId: string): void {
    this.nativeInstance.addLayerAbove(layer, aboveLayerId);
  }

  /**
   * 在指定索引位置添加图层
   */
  addLayerAt(layer: Object, index: number): void {
    this.nativeInstance.addLayerAt(layer, index);
  }

  /**
   * 移除指定图层
   */
  removeLayer(layerId: string): boolean {
    return this.nativeInstance.removeLayer(layerId);
  }

  /**
   * 移除指定索引位置的图层
   */
  removeLayerAt(index: number): boolean {
    return this.nativeInstance.removeLayerAt(index);
  }

  /**
   * 获取指定图层
   */
  getLayer(layerId: string): Object | null {
    return this.nativeInstance.getLayer(layerId);
  }

  /**
   * 获取所有图层
   */
  getLayers(): Object[] {
    return this.nativeInstance.getLayers();
  }

  // ========== 图像管理 ==========

  /**
   * 添加图像
   */
  addImage(name: string, imageData: ArrayBuffer | Uint8Array, width: number, height: number, sdf?: boolean): void {
    this.nativeInstance.addImage(name, imageData, width, height, sdf);
  }

  /**
   * 移除图像
   */
  removeImage(name: string): boolean {
    return this.nativeInstance.removeImage(name);
  }

  /**
   * 获取图像
   */
  getImage(name: string): Object | null {
    return this.nativeInstance.getImage(name);
  }

  // ========== 光照管理 ==========

  /**
   * 获取光照设置
   */
  getLight(): Object | null {
    return this.nativeInstance.getLight();
  }

  /**
   * 设置光照
   */
  setLight(lightJson: string): void {
    this.nativeInstance.setLight(lightJson);
  }

  // ========== 过渡效果管理 ==========

  /**
   * 获取过渡效果设置
   */
  getTransition(): Object | null {
    return this.nativeInstance.getTransition();
  }

  /**
   * 设置过渡效果
   */
  setTransition(transitionJson: string): void {
    this.nativeInstance.setTransition(transitionJson);
  }
}

/**
 * StyleBuilder - 重新导出 NAPI StyleBuilder
 */
export { StyleBuilder } from 'libmaplibre.so';
