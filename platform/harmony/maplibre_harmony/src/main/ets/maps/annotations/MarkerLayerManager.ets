/**
 * MarkerLayerManager - 基于 GeoJSON + SymbolLayer 的 Marker 管理器
 *
 * 参考 Android Annotation Plugin 和 iOS 最佳实践
 * 使用 GeoJSON Source + Data-Driven SymbolLayer 实现 Marker 的所有高级功能
 *
 * 架构:
 * - 创建内部 GeoJSON Source (marker-source)
 * - 创建 SymbolLayer (marker-layer) 使用数据驱动样式
 * - 每个 Marker 是一个 GeoJSON Feature，properties 包含所有属性
 * - 支持 rotation, alpha, zIndex, anchor, draggable 等高级功能
 */

import { MapLibreMap } from '../MapLibreMap';
import { LatLng } from '../geometry/LatLng';
import { GeoJsonSource } from '../style/sources/GeoJsonSource';
import { GeoJsonOptions } from '../style/sources/GeoJsonOptions';
import { SymbolLayer } from '../style/layers/SymbolLayer';
import { Expression } from '../style/expressions/Expression';
import { IconFactory } from './IconFactory';

import { Marker } from './Marker';
import { IconManager } from './IconManager';

/**
 * MarkerGeometry - Marker 几何对象接口
 */
interface MarkerGeometry {
  type: 'Point';
  coordinates: [number, number]; // [longitude, latitude]
}

/**
 * MarkerProperties - Marker 属性接口
 */
interface MarkerProperties {
  // 基础属性
  icon: string;
  title?: string;
  snippet?: string;

  // 高级属性
  rotation: number; // 旋转角度
  alpha: number; // 透明度 0-1
  zIndex: number; // 显示层级
  anchorU: number; // 锚点 U (0-1)
  anchorV: number; // 锚点 V (0-1)
  draggable: boolean; // 是否可拖拽
  visible: boolean; // 是否可见

  // 内部使用
  __markerId: number; // Marker 对象的唯一标识
}

/**
 * MarkerFeature - Marker 的 GeoJSON Feature 表示
 */
interface MarkerFeature {
  type: 'Feature';
  id: string | number;
  geometry: MarkerGeometry;
  properties: MarkerProperties;
}

/**
 * MarkerFeatureCollection - Marker 集合
 */
interface MarkerFeatureCollection {
  type: 'FeatureCollection';
  features: MarkerFeature[];
}

/**
 * MarkerLayerManager - 基于 GeoJSON 的 Marker 管理器
 */
export class MarkerLayerManager {
  private static readonly SOURCE_ID = 'maplibre-marker-source';
  private static readonly LAYER_ID = 'maplibre-marker-layer';
  private mapLibreMap: MapLibreMap;
  private source: GeoJsonSource | null = null;
  private layer: SymbolLayer | null = null;
  private markers: Map<number, Marker> = new Map();
  private features: Map<number, MarkerFeature> = new Map();
  private nextFeatureId: number = 1;
  private initialized: boolean = false;
  // 更新防抖 (防止频繁更新导致ANR)
  private updateTimerId: number | null = null;
  private readonly UPDATE_DEBOUNCE_MS = 16; // ~60fps, 足够快又不会过度更新

  constructor(mapLibreMap: MapLibreMap) {
    this.mapLibreMap = mapLibreMap;
  }

  /**
   * 检查是否已初始化
   */
  public isInitialized(): boolean {
    return this.initialized;
  }

  /**
   * 初始化 Marker Layer（创建 Source 和 Layer）
   */
  public initialize(): void {
    if (this.initialized && this.source && this.layer) {
      console.warn('[MarkerLayerManager] Already initialized with valid source/layer');
      return;
    }

    try {
      const style = this.mapLibreMap.getStyle();
      if (!style) {
        throw new Error('Style not loaded');
      }

      // 如果 source 或 layer 已存在于 style 中，先移除
      try {
        // 尝试移除可能存在的旧 layer 和 source
        // 不检查是否存在，直接尝试移除，失败时会被 catch 捕获
        style.removeLayer(MarkerLayerManager.LAYER_ID);
        style.removeSource(MarkerLayerManager.SOURCE_ID);
        console.warn('[MarkerLayerManager] Removed existing source/layer before re-initialization');
      } catch (e) {
        // 如果不存在则忽略错误，继续初始化
        // 这是正常情况，不需要额外处理
      }

      // 创建空的 GeoJSON Source
      const emptyFeatureCollection: MarkerFeatureCollection = {
        type: 'FeatureCollection',
        features: []
      };

      // 创建 GeoJsonSource（使用 NAPI 类）
      this.source = new GeoJsonSource(MarkerLayerManager.SOURCE_ID, {
        cluster: false,
        tolerance: 0.375,
        buffer: 128
      });

      // 设置初始数据（类型转换为 Object）
      this.source.setGeoJsonSync(emptyFeatureCollection as Object);

      // 添加 Source 到 Style（传递 ETS 包装对象，Style 内部会调用 getNative()）
      style.addSource(this.source);

      // ✅ 从 style 重新获取 source 实例（确保引用的是 style 中的对象）
      // 使用 __type 属性进行类型匹配（NAPI 修复后支持）
      const sourceFromStyle = style.getSource(MarkerLayerManager.SOURCE_ID) as GeoJsonSource | null;
      if (sourceFromStyle) {
        this.source = sourceFromStyle;
      } else {
        console.warn('[MarkerLayerManager] ⚠️ Failed to get source from style, using original reference');
      }

      // 创建 SymbolLayer 使用数据驱动样式（使用 NAPI 类）
      const tempLayer = new SymbolLayer(
        MarkerLayerManager.LAYER_ID,
        MarkerLayerManager.SOURCE_ID
      );

      // 配置 Layer 属性（数据驱动）
      this.configureLayer(tempLayer);

      // 添加 Layer 到 Style（传递 ETS 包装对象，Style 内部会调用 getNative()）
      style.addLayer(tempLayer);

      // ✅ 从 style 重新获取 layer 实例（确保引用的是 style 中的对象）
      // 使用 __type 属性进行类型匹配（NAPI 修复后支持）
      const layerFromStyle = style.getLayer(MarkerLayerManager.LAYER_ID) as SymbolLayer | null;
      if (layerFromStyle) {
        this.layer = layerFromStyle;
      } else {
        console.warn('[MarkerLayerManager] ⚠️ Failed to get layer from style, using original reference');
        this.layer = tempLayer;
      }

      this.initialized = true;
    } catch (error) {
      console.error(`[MarkerLayerManager] Failed to initialize: ${error}`);
      this.initialized = false;
      this.source = null;
      this.layer = null;
      throw new Error(String(error));
    }
  }

  /**
   * 配置 SymbolLayer 的数据驱动样式
   */
  private configureLayer(layer: SymbolLayer): void {

    // ========== Icon 布局属性 ==========

    // Icon 图像：使用 Expression 从 feature properties 动态获取
    // 每个 Marker 可以有不同的图标
    const iconImageExpr = Expression.get("icon").toArray() as import("libmaplibre.so").ExpressionLiteral;
    layer.setIconImage(iconImageExpr);

    // Icon 大小：默认 1.0
    layer.setIconSize(1.0);

    // Icon 旋转角度：使用 Expression 从 feature properties 获取
    // 支持每个 Marker 有不同的旋转角度
    const iconRotateExpr = Expression.get("rotation").toArray() as import("libmaplibre.so").ExpressionLiteral;
    layer.setIconRotate(iconRotateExpr);

    // Icon 锚点：默认 bottom（底部中心）
    layer.setIconAnchor('bottom');

    // Icon 允许重叠（确保所有 marker 都显示）
    layer.setIconAllowOverlap(true);

    // ========== Icon 绘制属性 ==========

    // Icon 透明度：使用 Expression 同时支持 visible 和 alpha
    // visible=false 时强制为 0（完全透明），visible=true 时使用 alpha 值
    // 这样可以同时支持显隐控制和透明度调整
    layer.setIconOpacity(
      Expression.caseExpression(
        Expression.eq(Expression.get("visible"), Expression.literal(false)),
        Expression.literal(0), // visible=false 时透明度为 0
        Expression.get("alpha")  // 否则使用 alpha 值
      ).toArray() as import("libmaplibre.so").ExpressionLiteral
    );

  }

  /**
   * 添加 Marker
   *
   * @param marker Marker 实例
   * @param skipUpdate 是否跳过source更新(批量添加时使用,默认false)
   * @returns feature ID
   */
  public addMarker(marker: Marker, skipUpdate: boolean = false): number {
    // 确保已初始化且 source/layer 存在
    if (!this.initialized || !this.source || !this.layer) {
      console.warn('[MarkerLayerManager] Re-initializing due to missing source/layer');
      this.initialized = false; // 重置标志以便重新初始化
      this.initialize();
    }

    const featureId = this.nextFeatureId++;
    const feature = this.markerToFeature(marker, featureId);

    this.features.set(featureId, feature);
    this.markers.set(featureId, marker);

    // 更新 GeoJSON Source (批量添加时跳过,由调用者统一更新)
    if (!skipUpdate) {
      this.updateSource();
    }

    return featureId;
  }

  /**
   * 批量添加 Markers
   *
   * **性能优化**: 批量添加时只更新一次GeoJSON source,避免重复序列化/解析
   */
  public addMarkers(markers: Marker[]): number[] {
    // 确保已初始化且 source/layer 存在
    if (!this.initialized || !this.source || !this.layer) {
      console.warn('[MarkerLayerManager] Re-initializing due to missing source/layer');
      this.initialized = false; // 重置标志以便重新初始化
      this.initialize();
    }

    const ids: number[] = [];

    for (const marker of markers) {
      const featureId = this.nextFeatureId++;
      const feature = this.markerToFeature(marker, featureId);

      this.features.set(featureId, feature);
      this.markers.set(featureId, marker);
      ids.push(featureId);
    }

    // 一次性更新 Source (批量优化! 立即生效)
    this.forceUpdateSource();

    return ids;
  }

  /**
   * 手动触发source更新
   *
   * 当使用 addMarker(marker, skipUpdate=true) 批量添加后,
   * 需要手动调用此方法更新source
   */
  /**
   * 强制立即更新 Source (跳过防抖)
   * 用于批量操作完成后立即刷新显示
   */
  public forceUpdateSource(): void {
    // 清除防抖定时器
    if (this.updateTimerId !== null) {
      clearTimeout(this.updateTimerId);
      this.updateTimerId = null;
    }
    // 立即执行更新
    this.performUpdate();
  }

  /**
   * 更新 Marker（通过 Marker 对象）
   *
   * 用于实时更新 Marker 显示（例如拖拽过程中）
   * 参考 Android: symbolsSource.setGeoJson(symbolsCollection)
   *
   * @param marker Marker 对象（必须已有 ID）
   */
  public updateMarker(marker: Marker): void {
    const featureId = marker.getId();
    if (featureId === 0 || !this.features.has(featureId)) {
      console.error(`[MarkerLayerManager] Marker not found: id=${featureId}`);
      return;
    }

    // 更新 Feature 和 Marker
    const feature = this.markerToFeature(marker, featureId);
    this.features.set(featureId, feature);
    this.markers.set(featureId, marker);

    // 🚀 拖拽过程中需要立即更新显示，跳过防抖
    // 参考 Android: symbolsSource.setGeoJson(symbolsCollection) 立即生效
    this.forceUpdateSource();
  }

  /**
   * 更新 Marker（通过 featureId）- 向后兼容
   */
  public updateMarkerById(featureId: number, marker: Marker): void {
    if (!this.features.has(featureId)) {
      console.error(`Marker feature ${featureId} not found`);
      return;
    }

    const feature = this.markerToFeature(marker, featureId);
    this.features.set(featureId, feature);
    this.markers.set(featureId, marker);

    this.updateSource();
  }

  /**
   * 删除 Marker
   *
   * @param featureId Feature ID
   * @param skipUpdate 是否跳过更新(批量删除时使用,默认false)
   */
  public removeMarker(featureId: number, skipUpdate: boolean = false): void {
    this.features.delete(featureId);
    this.markers.delete(featureId);

    if (!skipUpdate) {
      this.updateSource();
    }
  }

  /**
   * 批量删除 Markers
   */
  public removeMarkers(featureIds: number[]): void {
    // 使用 skipUpdate 避免重复更新
    for (const id of featureIds) {
      this.removeMarker(id, true); // skipUpdate = true
    }

    // 批量删除需要立即生效，跳过防抖
    this.forceUpdateSource();
  }

  /**
   * 清空所有 Markers
   */
  public clearMarkers(): void {
    this.features.clear();
    this.markers.clear();

    // 清空操作需要立即生效，跳过防抖
    this.forceUpdateSource();
  }

  /**
   * 将 Marker 转换为 GeoJSON Feature
   */
  private markerToFeature(marker: Marker, featureId: number): MarkerFeature {
    const position = marker.getPosition();
    // 获取 icon ID，如果为空字符串或 falsy 值，使用默认图标
    let icon = marker.getIcon();
    if (!icon || icon.trim() === '') {
      icon = IconFactory.DEFAULT_MARKER_ICON_ID;
    }
    const title = marker.getTitle();
    const snippet = marker.getSnippet();

    // 获取高级属性
    const rotation = marker.getRotation();
    const alpha = marker.getAlpha();
    const zIndex = marker.getZIndex();
    const anchor = marker.getAnchor();
    const draggable = marker.getDraggable();
    const visible = marker.getVisible();

    const geometry: MarkerGeometry = {
      type: 'Point',
      coordinates: [position.longitude, position.latitude]
    };

    const properties: MarkerProperties = {
      icon: icon,
      title: title,
      snippet: snippet,
      rotation: rotation,
      alpha: alpha,
      zIndex: zIndex,
      anchorU: anchor.u,
      anchorV: anchor.v,
      draggable: draggable,
      visible: visible,
      __markerId: featureId
    };

    const feature: MarkerFeature = {
      type: 'Feature',
      id: featureId,
      geometry: geometry,
      properties: properties
    };

    return feature;
  }

  /**
   * 更新 GeoJSON Source 数据 (带防抖)
   *
   * **性能优化**: 多层保护避免主线程阻塞
   * 1. **防抖**: 合并16ms内的多次更新请求为一次 (避免频繁更新)
   * 2. **异步**: 使用 setTimeout 延迟到下一个宏任务队列 (脱离当前事件循环)
   * 3. **对象传递**: 直接传 FeatureCollection 对象,无JSON序列化开销
   *
   * 注意：此方法现在是 public，允许外部调用（如 MarkerManager 在 style reload 后）
   */
  public updateSource(): void {
    // 清除已有的定时器 (防抖: 合并多次调用为一次)
    if (this.updateTimerId !== null) {
      clearTimeout(this.updateTimerId);
    }

    // 设置新的定时器
    this.updateTimerId = setTimeout(() => {
      this.updateTimerId = null;
      this.performUpdate();
    }, this.UPDATE_DEBOUNCE_MS);
  }

  /**
   * 执行实际的 Source 更新 (内部方法)
   */
  private performUpdate(): void {
    if (!this.source) {
      console.error('[MarkerLayerManager] Source not initialized, resetting initialized flag');
      this.initialized = false;
      return;
    }

    const featureCollection: MarkerFeatureCollection = {
      type: 'FeatureCollection',
      features: Array.from(this.features.values())
    };

    const featureCount = featureCollection.features.length;

    // 打印第一个 feature 的详细信息用于调试
    if (featureCount > 0) {
      const firstFeature = featureCollection.features[0];

      // 检查是否使用默认图标
      if (firstFeature.properties.icon === IconFactory.DEFAULT_MARKER_ICON_ID) {
        console.warn(`[MarkerLayerManager] ⚠️ Using default icon ID: ${IconFactory.DEFAULT_MARKER_ICON_ID}. Make sure it's loaded to style!`);
      }
    }

    // 🚀 使用 setTimeout(0) 延迟到下一个宏任务,彻底脱离当前事件循环
    setTimeout(() => {
      try {
        const updateStartTime = Date.now();

        // 直接传递 FeatureCollection 对象 (NAPI 层会处理转换,无需JSON序列化)
        this.source!.setGeoJson(featureCollection);

        // 触发地图重绘
        const nativeMapView = this.mapLibreMap.getNativeMapView();
        if (nativeMapView) {
          nativeMapView.triggerRepaint();
        }

        const updateTime = Date.now() - updateStartTime;
      } catch (error) {
        console.error(`[MarkerLayerManager] ❌ Failed to update source: ${error}`);
      }
    }, 0);
  }

  /**
   * 获取所有 Markers
   */
  public getAllMarkers(): Marker[] {
    return Array.from(this.markers.values());
  }

  /**
   * 获取 Marker 数量
   */
  public getMarkerCount(): number {
    return this.markers.size;
  }

  /**
   * 获取 Marker Layer ID
   *
   * @returns Layer ID 字符串
   */
  public getLayerId(): string {
    return MarkerLayerManager.LAYER_ID;
  }

  /**
   * 获取 Marker Source ID
   *
   * @returns Source ID 字符串
   */
  public getSourceId(): string {
    return MarkerLayerManager.SOURCE_ID;
  }

  /**
   * 销毁管理器
   */
  public destroy(): void {
    if (!this.initialized) {
      return;
    }

    try {
      const style = this.mapLibreMap.getStyle();
      if (style) {
        // 移除 Layer 和 Source
        if (this.layer) {
          style.removeLayer(MarkerLayerManager.LAYER_ID);
        }
        if (this.source) {
          style.removeSource(MarkerLayerManager.SOURCE_ID);
        }
      }

      this.markers.clear();
      this.features.clear();
      this.initialized = false;
    } catch (error) {
      console.error(`Failed to destroy MarkerLayerManager: ${error}`);
    }
  }
}

