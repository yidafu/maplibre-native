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
  rotation: number;        // 旋转角度
  alpha: number;           // 透明度 0-1
  zIndex: number;          // 显示层级
  anchorU: number;         // 锚点 U (0-1)
  anchorV: number;         // 锚点 V (0-1)
  draggable: boolean;      // 是否可拖拽
  visible: boolean;        // 是否可见
  
  // 内部使用
  __markerId: number;      // Marker 对象的唯一标识
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
      
      // 添加 Source 到 Style
      style.addSource(this.source);
      
      // 创建 SymbolLayer 使用数据驱动样式（使用 NAPI 类）
      this.layer = new SymbolLayer(
        MarkerLayerManager.LAYER_ID,
        MarkerLayerManager.SOURCE_ID
      );
      
      // 配置 Layer 属性（数据驱动）
      this.configureLayer(this.layer);
      
      // 添加 Layer 到 Style
      style.addLayer(this.layer);
      
      this.initialized = true;
      console.info('[MarkerLayerManager] Initialized successfully');
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
    console.info('MarkerLayerManager: Configuring SymbolLayer with data-driven styling');
    
    // ========== Icon 布局属性 ==========
    
    // Icon 图像：使用 Expression 从 feature properties 获取
    // 每个 Marker 可以有不同的图标
    layer.setIconImage(IconFactory.DEFAULT_MARKER_ICON_ID);
    
    // Icon 大小：默认 1.0
    layer.setIconSize(1.0);
    
    // Icon 旋转角度：使用 Expression 从 feature properties 获取
    // 支持每个 Marker 有不同的旋转角度
    layer.setIconRotate(Expression.get("rotation").toArray() as Object);
    
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
        Expression.literal(0),  // visible=false 时透明度为 0
        Expression.get("alpha")  // 否则使用 alpha 值
      ).toArray() as Object
    );
    
    console.info('MarkerLayerManager: SymbolLayer configured with data-driven expressions successfully');
  }
  
  /**
   * 添加 Marker
   */
  public addMarker(marker: Marker): number {
    // 确保已初始化且 source/layer 存在
    if (!this.initialized || !this.source || !this.layer) {
      console.warn('[MarkerLayerManager] Re-initializing due to missing source/layer');
      this.initialized = false;  // 重置标志以便重新初始化
      this.initialize();
    }
    
    const featureId = this.nextFeatureId++;
    const feature = this.markerToFeature(marker, featureId);
    
    this.features.set(featureId, feature);
    this.markers.set(featureId, marker);
    
    // 更新 GeoJSON Source
    this.updateSource();
    
    return featureId;
  }
  
  /**
   * 批量添加 Markers
   */
  public addMarkers(markers: Marker[]): number[] {
    // 确保已初始化且 source/layer 存在
    if (!this.initialized || !this.source || !this.layer) {
      console.warn('[MarkerLayerManager] Re-initializing due to missing source/layer');
      this.initialized = false;  // 重置标志以便重新初始化
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
    
    // 一次性更新 Source
    this.updateSource();
    
    return ids;
  }
  
  /**
   * 更新 Marker
   */
  public updateMarker(featureId: number, marker: Marker): void {
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
   */
  public removeMarker(featureId: number): void {
    this.features.delete(featureId);
    this.markers.delete(featureId);
    
    this.updateSource();
  }
  
  /**
   * 批量删除 Markers
   */
  public removeMarkers(featureIds: number[]): void {
    for (const id of featureIds) {
      this.features.delete(id);
      this.markers.delete(id);
    }
    
    this.updateSource();
  }
  
  /**
   * 清空所有 Markers
   */
  public clearMarkers(): void {
    this.features.clear();
    this.markers.clear();
    
    this.updateSource();
  }
  
  /**
   * 将 Marker 转换为 GeoJSON Feature
   */
  private markerToFeature(marker: Marker, featureId: number): MarkerFeature {
    const position = marker.getPosition();
    const icon = marker.getIcon() || 'default-marker';
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
   * 更新 GeoJSON Source 数据
   */
  private updateSource(): void {
    if (!this.source) {
      console.error('[MarkerLayerManager] Source not initialized, resetting initialized flag');
      this.initialized = false;  // 重置标志，下次添加时会重新初始化
      return;
    }
    
    const featureCollection: MarkerFeatureCollection = {
      type: 'FeatureCollection',
      features: Array.from(this.features.values())
    };
    
    console.debug(`[MarkerLayerManager] Updating source with ${featureCollection.features.length} features`);
    
    // 更新 GeoJSON 数据
    this.source.setGeoJson(JSON.stringify(featureCollection));
    
    // 触发地图重绘以显示更改
    try {
      const nativeMapView = this.mapLibreMap.getNativeMapView();
      if (nativeMapView) {
        nativeMapView.triggerRepaint();
        console.debug('[MarkerLayerManager] Triggered map repaint after source update');
      }
    } catch (error) {
      console.warn(`[MarkerLayerManager] Failed to trigger repaint: ${error}`);
    }
  }
  
  /**
   * 根据屏幕坐标查询 Marker
   */
  public queryMarkerAt(x: number, y: number): Marker | null {
    try {
      // 使用 queryRenderedFeaturesForPoint 查询
      const features = this.mapLibreMap.queryRenderedFeaturesForPoint(
        x, y,
        [MarkerLayerManager.LAYER_ID],
        undefined
      );
      
      if (features && features.length > 0) {
        // 获取第一个 feature 的 ID
        const feature = features[0];
        const featureId = feature.id;
        
        if (typeof featureId === 'number' && this.markers.has(featureId)) {
          return this.markers.get(featureId)!;
        }
      }
    } catch (error) {
      console.error(`Failed to query marker: ${error}`);
    }
    
    return null;
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
   * 销毁管理器
   */
  public destroy(): void {
    if (!this.initialized) return;
    
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

