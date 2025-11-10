/**
 * Style - 样式管理类封装
 *
 * 封装 NAPI Style 类，避免暴露内部类型
 */
import maplibre from 'libmaplibre.so';
import { Layer } from './layers/Layer';
import type { Source } from './sources/Source';
import type { Icon, LightSpecification, TransitionOptions } from 'libmaplibre.so';
import { Image } from './images/Image';

// Source 包装类
import { GeoJsonSource } from './sources/GeoJsonSource';
import { VectorSource } from './sources/VectorSource';
import { RasterSource } from './sources/RasterSource';
import { RasterDemSource } from './sources/RasterDemSource';
import { ImageSource } from './sources/ImageSource';

// Layer 包装类
import { FillLayer } from './layers/FillLayer';
import { LineLayer } from './layers/LineLayer';
import { CircleLayer } from './layers/CircleLayer';
import { SymbolLayer } from './layers/SymbolLayer';
import { RasterLayer } from './layers/RasterLayer';
import { BackgroundLayer } from './layers/BackgroundLayer';
import { HeatmapLayer } from './layers/HeatmapLayer';
import { HillshadeLayer } from './layers/HillshadeLayer';
import { FillExtrusionLayer } from './layers/FillExtrusionLayer';

/**
 * 内部标记，防止外部直接构造 Style
 */
class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
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

  // ========== 类型转换辅助函数 ==========

  /**
   * 将 NAPI Source 对象包装为对应的 ETS Source 类
   */
  private static wrapSource(nativeSource: Object): Source | null {
    if (!nativeSource) {
      console.warn('[Style] wrapSource: nativeSource is null/undefined');
      return null;
    }

    // 使用 _TYPE_ 属性判断类型（因为 instanceof 对 NAPI 返回的普通对象不工作）
    const sourceObj = nativeSource as Record<string, Object>;
    const napiType = sourceObj._TYPE_ as string;

    // 根据 _TYPE_ 属性匹配对应的 Source 类
    if (napiType === GeoJsonSource._TYPE_) {
      return GeoJsonSource.fromNative(nativeSource as maplibre.GeoJsonSource);
    }
    if (napiType === VectorSource._TYPE_) {
      return VectorSource.fromNative(nativeSource as maplibre.VectorSource);
    }
    if (napiType === RasterSource._TYPE_) {
      return RasterSource.fromNative(nativeSource as maplibre.RasterSource);
    }
    if (napiType === RasterDemSource._TYPE_) {
      return RasterDemSource.fromNative(nativeSource as maplibre.RasterDemSource);
    }
    if (napiType === ImageSource._TYPE_) {
      return ImageSource.fromNative(nativeSource as maplibre.ImageSource);
    }

    console.error(`[Style] wrapSource: ❌ No matching type found for source! _TYPE_=${napiType}`);
    return null;
  }

  /**
   * 将 NAPI Layer 对象包装为对应的 ETS Layer 类
   */
  private static wrapLayer(nativeLayer: Object): Layer | null {
    if (!nativeLayer) {
      console.warn('[Style] wrapLayer: nativeLayer is null/undefined');
      return null;
    }

    // 使用 _TYPE_ 属性判断类型（因为 instanceof 对 NAPI 返回的普通对象不工作）
    const layerObj = nativeLayer as Record<string, Object>;
    const napiType = layerObj._TYPE_ as string;

    // 根据 _TYPE_ 属性匹配对应的 Layer 类
    if (napiType === FillLayer._TYPE_) {
      return FillLayer.fromNative(nativeLayer as maplibre.FillLayer);
    }
    if (napiType === LineLayer._TYPE_) {
      return LineLayer.fromNative(nativeLayer as maplibre.LineLayer);
    }
    if (napiType === CircleLayer._TYPE_) {
      return CircleLayer.fromNative(nativeLayer as maplibre.CircleLayer);
    }
    if (napiType === SymbolLayer._TYPE_) {
      return SymbolLayer.fromNative(nativeLayer as maplibre.SymbolLayer);
    }
    if (napiType === RasterLayer._TYPE_) {
      return RasterLayer.fromNative(nativeLayer as maplibre.RasterLayer);
    }
    if (napiType === BackgroundLayer._TYPE_) {
      return BackgroundLayer.fromNative(nativeLayer as maplibre.BackgroundLayer);
    }
    if (napiType === HeatmapLayer._TYPE_) {
      return HeatmapLayer.fromNative(nativeLayer as maplibre.HeatmapLayer);
    }
    if (napiType === HillshadeLayer._TYPE_) {
      return HillshadeLayer.fromNative(nativeLayer as maplibre.HillshadeLayer);
    }
    if (napiType === FillExtrusionLayer._TYPE_) {
      return FillExtrusionLayer.fromNative(nativeLayer as maplibre.FillExtrusionLayer);
    }

    console.error(`[Style] wrapLayer: ❌ No matching type found for layer! _TYPE_=${napiType}`);
    return null;
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
   *
   * @param source ETS Source 包装对象
   */
  addSource(source: Source): void {
    this.nativeInstance.addSource(source.getNative());
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
  getSource(sourceId: string): Source | null {
    const nativeSource = this.nativeInstance.getSource(sourceId);
    if (nativeSource == null) {
      return null
    }
    return Style.wrapSource(nativeSource);
  }

  /**
   * 获取所有数据源
   */
  getSources(): Source[] {
    const nativeSources = this.nativeInstance.getSources();
    return nativeSources
      .map(nativeSource => Style.wrapSource(nativeSource))
      .filter(source => source !== null) as Source[];
  }

  // ========== 图层管理 ==========

  /**
   * 添加图层（添加到顶部）
   *
   * @param layer ETS Layer 包装对象
   */
  addLayer(layer: Layer): void {
    this.nativeInstance.addLayer(layer.getNative());
  }

  /**
   * 在指定图层下方添加图层
   *
   * @param layer ETS Layer 包装对象
   * @param belowLayerId 参考图层的 ID
   */
  addLayerBelow(layer: Layer, belowLayerId: string): void {
    this.nativeInstance.addLayerBelow(layer.getNative(), belowLayerId);
  }

  /**
   * 在指定图层上方添加图层
   *
   * @param layer ETS Layer 包装对象
   * @param aboveLayerId 参考图层的 ID
   */
  addLayerAbove(layer: Layer, aboveLayerId: string): void {
    this.nativeInstance.addLayerAbove(layer.getNative(), aboveLayerId);
  }

  /**
   * 在指定索引位置添加图层
   *
   * @param layer ETS Layer 包装对象
   * @param index 目标索引位置
   */
  addLayerAt(layer: Layer, index: number): void {
    this.nativeInstance.addLayerAt(layer.getNative(), index);
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
  getLayer(layerId: string): Layer | null {
    const nativeLayer = this.nativeInstance.getLayer(layerId);
    if (nativeLayer == null) {
      return null
    }
    return Style.wrapLayer(nativeLayer);
  }

  /**
   * 获取所有图层
   */
  getLayers(): Layer[] {
    const nativeLayers = this.nativeInstance.getLayers();
    return nativeLayers
      .map(nativeLayer => Style.wrapLayer(nativeLayer))
      .filter(layer => layer !== null) as Layer[];
  }

  // ========== 图像管理 ==========

  /**
   * 添加图像
   */
  addImage(name: string, imageData: ArrayBuffer | Uint8Array, width: number, height: number, sdf?: boolean): void {
    this.nativeInstance.addImage(name, imageData, width, height, sdf);
  }

  /**
   * 异步添加图像（不阻塞UI线程）
   */
  addImageAsync(name: string, imageData: ArrayBuffer | Uint8Array, width: number, height: number, sdf?: boolean): Promise<void> {
    return this.nativeInstance.addImageAsync(name, imageData, width, height, sdf);
  }

  /**
   * 异步批量添加图像（不阻塞UI线程）
   */
  addImagesAsync(images: Image[]): Promise<void> {
    const nativeImages = images.map(img => img.getNative());
    return this.nativeInstance.addImagesAsync(nativeImages);
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
  getImage(name: string): Icon | null {
    const result = this.nativeInstance.getImage(name);
    return result ? (result as Object as Icon) : null;
  }

  // ========== 光照管理 ==========

  /**
   * 获取光照设置
   */
  getLight(): LightSpecification | null {
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
  getTransition(): TransitionOptions | null {
    return this.nativeInstance.getTransition() as TransitionOptions | null;
  }

  /**
   * 设置过渡效果
   */
  setTransition(transitionJson: string): void {
    this.nativeInstance.setTransition(transitionJson);
  }

  /**
   * 获取指定 ID 的数据源并转换为特定类型
   * TODO: 实现类型安全的数据源获取
   * @param sourceId - 数据源 ID
   * @returns 数据源对象或 null
   */
  getSourceAs<T>(sourceId: string): T | null {
    const source = this.getSource(sourceId);
    return source as T | null;
  }
}

/**
 * StyleBuilder - 重新导出 NAPI StyleBuilder
 */
export { StyleBuilder } from 'libmaplibre.so';
