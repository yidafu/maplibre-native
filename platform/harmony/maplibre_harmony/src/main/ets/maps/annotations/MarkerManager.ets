import maplibre from 'libmaplibre_native.so';
import { MarkerOptions } from './MarkerOptions';
import { MarkerDragState } from './MarkerDragState';
import { LatLng } from '../geometry/LatLng';
import { MapLibreMap } from '../MapLibreMap';
import { OnMarkerClickListener } from '../listeners/OnMarkerClickListener';
import { OnMarkerDragListener } from '../listeners/OnMarkerDragListener';
import { OnInfoWindowClickListener } from '../listeners/OnInfoWindowClickListener';
import { OnInfoWindowCloseListener } from '../listeners/OnInfoWindowCloseListener';
import { OnMarkerSelectListener } from '../listeners/OnMarkerSelectListener';
import { InfoWindowAdapter } from './InfoWindowAdapter';
import { InfoWindowManager } from './InfoWindowManager';
import { AnnotationViewAdapter } from './AnnotationViewAdapter';
import { AnnotationViewManager } from './AnnotationViewManager';
import { Icon } from './Icon';
import { IconManager } from './IconManager';
import { IconFactory } from './IconFactory';
import { MarkerLayerManager } from './MarkerLayerManager';

// 使用 NAPI 类型
type NativeMapView = maplibre.NativeMapView;

// 使用 NAPI Marker 类型
type Marker = maplibre.Marker;

/**
 * MarkerManager - Marker 管理器
 * 
 * 基于 GeoJSON Source + SymbolLayer 实现，支持所有高级功能
 * 
 * 参考:
 * - Android Annotation Plugin: GeoJSON + SymbolLayer
 * - iOS: MLNShapeSource + MLNSymbolStyleLayer
 */
export class MarkerManager {
  private markerLayerManager: MarkerLayerManager;
  private selectedMarkers: Set<Marker> = new Set();
  private mapLibreMap: MapLibreMap;
  private infoWindowManager: InfoWindowManager;
  private annotationViewManager: AnnotationViewManager;
  private iconManager: IconManager;
  
  // Marker ID -> Marker 映射
  private markerMap: Map<number, Marker> = new Map();
  
  // Marker -> Icon 映射（用于引用计数管理）
  private markerIconMap: Map<number, Icon> = new Map();
  
  // 事件监听器
  private onMarkerClickListener: OnMarkerClickListener | null = null;
  private onMarkerDragListener: OnMarkerDragListener | null = null;
  private onInfoWindowClickListener: OnInfoWindowClickListener | null = null;
  private onMarkerSelectListener: OnMarkerSelectListener | null = null;
  private infoWindowAdapter: InfoWindowAdapter | null = null;
  
  // 拖拽相关
  private draggingMarker: Marker | null = null;
  private draggingMarkerId: number | null = null;
  
  /**
   * 构造函数
   * 
   * @param mapLibreMap MapLibreMap 实例
   */
  constructor(mapLibreMap: MapLibreMap) {
    this.mapLibreMap = mapLibreMap;
    this.infoWindowManager = new InfoWindowManager();
    this.annotationViewManager = new AnnotationViewManager();
    
    // 初始化 IconManager
    const nativeMapView = mapLibreMap.getNativeMapView();
    this.iconManager = new IconManager(nativeMapView, IconFactory.getInstance());
    
    // 初始化 MarkerLayerManager（GeoJSON + SymbolLayer）
    this.markerLayerManager = new MarkerLayerManager(mapLibreMap);
    
    console.info('[MarkerManager] Initialized with MarkerLayerManager (GeoJSON + SymbolLayer)');
  }
  
  // ========== Marker 管理 ==========
  
  /**
   * 添加单个 Marker
   * 
   * @param options MarkerOptions 实例
   * @returns 创建的 Marker
   * @throws Error 如果 Marker 创建失败
   */
  public async addMarker(options: MarkerOptions): Promise<Marker> {
    try {
      // 确保 MarkerLayerManager 已初始化
      if (!this.markerLayerManager.isInitialized()) {
        this.markerLayerManager.initialize();
      }
      
      // 获取 Icon（如果有）并确保已加载到地图
      const iconObj = options.getIcon();
      if (iconObj) {
        await this.ensureIconLoaded(iconObj);
      }
      
      // 创建 Marker 对象
      const marker = options.getMarker();
      
      // 添加到 MarkerLayerManager
      const featureId = this.markerLayerManager.addMarker(marker);
      
      // 设置 ID 和关联
      marker.setId(featureId);
      marker.setMapLibreMap(this.mapLibreMap);
      this.markerMap.set(featureId, marker);
      
      // 保存 Marker -> Icon 映射
      if (iconObj) {
        this.markerIconMap.set(featureId, iconObj);
      }
      
      console.info(`[MarkerManager] Added marker with ID=${featureId}`);
      
      // 创建自定义视图（如果有适配器）
      this.annotationViewManager.createOrUpdateView(marker);
      
      return marker;
    } catch (e) {
      const error = e as Error;
      console.error(`[MarkerManager] Failed to add marker: ${error.message}`);
      throw new Error(`Failed to add marker: ${error.message}`);
    }
  }
  
  /**
   * 确保 Icon 已加载到地图样式
   */
  private async ensureIconLoaded(icon: Icon): Promise<void> {
    try {
      const style = this.mapLibreMap.getStyle();
      if (!style) {
        throw new Error('Style not loaded');
      }
      
      // 检查 icon 是否已存在
      const existingImage = style.getImage(icon.getId());
      if (!existingImage) {
        // 添加 icon 到 style
        const bitmap = icon.getBitmap();
        const width = bitmap.width;
        const height = bitmap.height;
        const pixelRatio = 1.0; // TODO: 从设备获取
        
        // 将 bitmap 转换为 Uint8Array
        const pixels = this.bitmapToPixels(bitmap);
        
        style.addImage(icon.getId(), bitmap, pixelRatio, false);
        console.info(`[MarkerManager] Icon added to style: ${icon.getId()}`);
      }
    } catch (error) {
      console.warn(`[MarkerManager] Failed to ensure icon loaded: ${error}`);
    }
  }
  
  /**
   * 将 PixelMap 转换为像素数据（临时实现）
   */
  private bitmapToPixels(bitmap: any): Uint8Array {
    // TODO: 实现 PixelMap 到 Uint8Array 的转换
    return new Uint8Array(0);
  }
  
  /**
   * 批量添加 Marker
   * 
   * @param optionsList MarkerOptions 数组
   * @returns 创建的 Marker 数组
   * @throws Error 如果批量添加失败
   */
  public async addMarkers(optionsList: MarkerOptions[]): Promise<Marker[]> {
    try {
      // 确保 MarkerLayerManager 已初始化
      if (!this.markerLayerManager.isInitialized()) {
        this.markerLayerManager.initialize();
      }
      
      // 加载所有 icons
      for (const options of optionsList) {
        const iconObj = options.getIcon();
        if (iconObj) {
          await this.ensureIconLoaded(iconObj);
        }
      }
      
      // 创建 Marker 对象数组
      const markers: Marker[] = [];
      for (const options of optionsList) {
        markers.push(options.getMarker());
      }
      
      // 批量添加到 MarkerLayerManager
      const featureIds = this.markerLayerManager.addMarkers(markers);
      
      // 设置 ID 并注册
      for (let i = 0; i < markers.length; i++) {
        const marker = markers[i];
        const featureId = featureIds[i];
        
        marker.setId(featureId);
        marker.setMapLibreMap(this.mapLibreMap);
        this.markerMap.set(featureId, marker);
        
        const iconObj = optionsList[i].getIcon();
        if (iconObj) {
          this.markerIconMap.set(featureId, iconObj);
        }
      }
      
      console.info(`[MarkerManager] Batch added ${markers.length} markers`);
      
      return markers;
    } catch (e) {
      const error = e as Error;
      console.error(`[MarkerManager] Failed to add markers batch: ${error.message}`);
      throw new Error(`Failed to add markers batch: ${error.message}`);
    }
  }
  
  /**
   * 移除单个 Marker
   * 
   * @param marker 要移除的 Marker
   */
  public removeMarker(marker: Marker): void {
    const id = marker.getId();
    if (id === -1) {
      return;
    }
    
    // 如果正在显示 InfoWindow，先关闭
    if (marker.isInfoWindowShown()) {
      marker.hideInfoWindow();
    }
    
    // 如果是选中状态，取消选中
    if (marker.isSelected()) {
      this.deselectMarker(marker);
    }
    
    // 清理 Icon（减少引用计数）
    const iconObj = this.markerIconMap.get(id);
    if (iconObj) {
      this.iconManager.iconCleanup(iconObj);
      this.markerIconMap.delete(id);
    }
    
    // 移除自定义视图
    this.annotationViewManager.removeView(marker);
    
    // 从 MarkerLayerManager 移除
    this.markerLayerManager.removeMarker(id);
    
    // 从管理器移除
    this.markerMap.delete(id);
    marker.setId(-1);
    
    console.info(`[MarkerManager] Removed marker ID=${id}`);
  }
  
  /**
   * 批量移除 Marker
   * 
   * @param markers 要移除的 Marker 数组
   */
  public removeMarkers(markers: Marker[]): void {
    const ids: number[] = [];
    
    for (const marker of markers) {
      const id = marker.getId();
      if (id !== -1) {
        // 清理状态
        if (marker.isInfoWindowShown()) {
          marker.hideInfoWindow();
        }
        if (marker.isSelected()) {
          this.selectedMarkers.delete(marker);
        }
        
        // 清理 Icon
        const iconObj = this.markerIconMap.get(id);
        if (iconObj) {
          this.iconManager.iconCleanup(iconObj);
          this.markerIconMap.delete(id);
        }
        
        // 移除自定义视图
        this.annotationViewManager.removeView(marker);
        
        ids.push(id);
        this.markerMap.delete(id);
        marker.setId(-1);
      }
    }
    
    // 批量从 MarkerLayerManager 移除
    if (ids.length > 0) {
      this.markerLayerManager.removeMarkers(ids);
    }
    
    console.info(`[MarkerManager] Removed ${ids.length} markers`);
  }
  
  /**
   * 清除所有 Marker
   */
  public clear(): void {
    // 清理所有状态
    for (const marker of this.markerMap.values()) {
      if (marker.isInfoWindowShown()) {
        marker.hideInfoWindow();
      }
      marker.setId(-1);
    }
    
    // 清理所有 Icons
    for (const iconObj of this.markerIconMap.values()) {
      this.iconManager.iconCleanup(iconObj);
    }
    
    // 清空 MarkerLayerManager
    this.markerLayerManager.clearMarkers();
    
    // 清空本地映射
    this.markerMap.clear();
    this.markerIconMap.clear();
    this.selectedMarkers.clear();
    
    console.info('[MarkerManager] Cleared all markers');
  }
  
  // ========== 选中管理 ==========
  
  /**
   * 选中 Marker
   * 
   * @param marker 要选中的 Marker
   * @param showInfoWindow 是否显示 InfoWindow
   */
  public selectMarker(marker: Marker, showInfoWindow: boolean = true): void {
    // 先取消其他选中的 Marker
    this.deselectMarkers();
    
    // 选中当前 Marker
    marker.setSelected(true);
    this.selectedMarkers.add(marker);
    
    // 触发选中监听器
    if (this.onMarkerSelectListener) {
      this.onMarkerSelectListener.onMarkerSelect(marker);
    }
    
    // 显示 InfoWindow
    if (showInfoWindow && (marker.getTitle() || marker.getSnippet())) {
      marker.showInfoWindow();
    }
  }
  
  /**
   * 取消选中 Marker
   * 
   * @param marker 要取消选中的 Marker
   */
  public deselectMarker(marker: Marker): void {
    if (!this.selectedMarkers.has(marker)) {
      return;
    }
    
    marker.setSelected(false);
    marker.hideInfoWindow();
    this.selectedMarkers.delete(marker);
    
    // 触发取消选中监听器
    if (this.onMarkerSelectListener) {
      this.onMarkerSelectListener.onMarkerDeselect(marker);
    }
  }
  
  /**
   * 取消所有选中的 Marker
   */
  public deselectMarkers(): void {
    for (const marker of this.selectedMarkers) {
      marker.setSelected(false);
      marker.hideInfoWindow();
      
      // 触发取消选中监听器
      if (this.onMarkerSelectListener) {
        this.onMarkerSelectListener.onMarkerDeselect(marker);
      }
    }
    this.selectedMarkers.clear();
  }
  
  /**
   * 获取所有选中的 Marker
   * 
   * @returns 选中的 Marker 数组
   */
  public getSelectedMarkers(): Marker[] {
    return Array.from(this.selectedMarkers);
  }
  
  // ========== 查询 ==========
  
  /**
   * 根据 ID 获取 Marker
   * 
   * @param id Marker ID
   * @returns Marker 实例，如果不存在则返回 null
   */
  public getMarker(id: number): Marker | null {
    return this.markerMap.get(id) || null;
  }
  
  /**
   * 获取所有 Marker
   * 
   * @returns Marker 数组
   */
  public getMarkers(): Marker[] {
    return Array.from(this.markerMap.values());
  }
  
  // ========== 拖拽处理 ==========
  
  /**
   * 处理拖拽开始
   * 
   * @param marker 正在拖拽的 Marker
   */
  public handleDragStart(marker: Marker): void {
    if (!marker.getDraggable()) {
      return;
    }
    
    marker.setDragState(MarkerDragState.Starting);
    this.draggingMarker = marker;
    
    // 触发事件
    if (this.onMarkerDragListener) {
      this.onMarkerDragListener.onMarkerDragStart(marker);
    }
    
    marker.setDragState(MarkerDragState.Dragging);
  }
  
  /**
   * 处理拖拽中
   * 
   * @param marker 正在拖拽的 Marker
   * @param newPosition 新位置
   */
  public handleDrag(marker: Marker, newPosition: LatLng): void {
    if (!marker.isDraggable() || marker.getDragState() !== MarkerDragState.Dragging) {
      return;
    }
    
    // 更新位置
    marker.setPosition(newPosition);
    
    // 触发事件
    if (this.onMarkerDragListener) {
      this.onMarkerDragListener.onMarkerDrag(marker);
    }
  }
  
  /**
   * 处理拖拽结束
   * 
   * @param marker 完成拖拽的 Marker
   */
  public handleDragEnd(marker: Marker): void {
    if (!marker.isDraggable() || this.draggingMarker !== marker) {
      return;
    }
    
    marker.setDragState(MarkerDragState.Ending);
    
    // 触发事件
    if (this.onMarkerDragListener) {
      this.onMarkerDragListener.onMarkerDragEnd(marker);
    }
    
    marker.setDragState(MarkerDragState.None);
    this.draggingMarker = null;
  }
  
  /**
   * 获取正在拖拽的 Marker
   * 
   * @returns 正在拖拽的 Marker，如果没有则返回 null
   */
  public getDraggingMarker(): Marker | null {
    return this.draggingMarker;
  }
  
  // ========== 点击处理 ==========
  
  /**
   * 处理 Marker 点击事件
   * 
   * @param marker 被点击的 Marker
   * @returns true 如果事件被消费
   */
  public handleMarkerClick(marker: Marker): boolean {
    // 触发点击事件
    if (this.onMarkerClickListener) {
      const consumed = this.onMarkerClickListener.onMarkerClick(marker);
      if (consumed) {
        return true;
      }
    }
    
    // 默认行为：选中 Marker 并显示 InfoWindow
    this.selectMarker(marker, true);
    return false;
  }
  
  /**
   * 处理 InfoWindow 点击事件
   * 
   * @param marker InfoWindow 所属的 Marker
   */
  public handleInfoWindowClick(marker: Marker): void {
    if (this.onInfoWindowClickListener) {
      this.onInfoWindowClickListener.onInfoWindowClick(marker);
    }
  }
  
  // ========== 事件监听器设置 ==========
  
  /**
   * 设置 Marker 点击监听器
   * 
   * @param listener 监听器实例
   */
  public setOnMarkerClickListener(listener: OnMarkerClickListener | null): void {
    this.onMarkerClickListener = listener;
  }
  
  /**
   * 设置 Marker 拖拽监听器
   * 
   * @param listener 监听器实例
   */
  public setOnMarkerDragListener(listener: OnMarkerDragListener | null): void {
    this.onMarkerDragListener = listener;
  }
  
  /**
   * 设置 Marker 选中监听器
   * 
   * @param listener 监听器实例
   */
  public setOnMarkerSelectListener(listener: OnMarkerSelectListener | null): void {
    this.onMarkerSelectListener = listener;
  }
  
  /**
   * 获取 Marker 选中监听器
   * 
   * @returns 监听器实例
   */
  public getOnMarkerSelectListener(): OnMarkerSelectListener | null {
    return this.onMarkerSelectListener;
  }
  
  /**
   * 设置 InfoWindow 点击监听器
   * 
   * @param listener 监听器实例
   */
  public setOnInfoWindowClickListener(listener: OnInfoWindowClickListener | null): void {
    this.onInfoWindowClickListener = listener;
    this.infoWindowManager.setOnClickListener(listener);
  }
  
  /**
   * 设置 InfoWindow 关闭监听器
   * 
   * @param listener 监听器实例
   */
  public setOnInfoWindowCloseListener(listener: OnInfoWindowCloseListener | null): void {
    this.infoWindowManager.setOnCloseListener(listener);
  }
  
  /**
   * 获取 InfoWindow 关闭监听器
   * 
   * @returns 监听器实例
   */
  public getOnInfoWindowCloseListener(): OnInfoWindowCloseListener | null {
    return this.infoWindowManager.getOnCloseListener();
  }
  
  /**
   * 设置 InfoWindow 适配器
   * 
   * @param adapter 适配器实例
   */
  public setInfoWindowAdapter(adapter: InfoWindowAdapter | null): void {
    this.infoWindowAdapter = adapter;
    this.infoWindowManager.setAdapter(adapter);
  }
  
  /**
   * 获取 InfoWindow 适配器
   * 
   * @returns 适配器实例
   */
  public getInfoWindowAdapter(): InfoWindowAdapter | null {
    return this.infoWindowAdapter;
  }
  
  /**
   * 设置 AnnotationView 适配器
   * 
   * @param adapter 适配器实例
   */
  public setAnnotationViewAdapter(adapter: AnnotationViewAdapter | null): void {
    this.annotationViewManager.setAdapter(adapter);
  }
  
  /**
   * 获取 AnnotationView 适配器
   * 
   * @returns 适配器实例
   */
  public getAnnotationViewAdapter(): AnnotationViewAdapter | null {
    return this.annotationViewManager.getAdapter();
  }
  
  /**
   * 获取 AnnotationViewManager 实例（供 UI 层使用）
   */
  public getAnnotationViewManager(): AnnotationViewManager {
    return this.annotationViewManager;
  }
  
  /**
   * 设置 Native MapView（用于坐标转换）
   */
  public setNativeMapView(mapView: object): void {
    this.annotationViewManager.setNativeMapView(mapView as NativeMapView);
  }
  
  /**
   * 获取 InfoWindowManager 实例（供 UI 层使用）
   */
  public getInfoWindowManager(): InfoWindowManager {
    return this.infoWindowManager;
  }
  
  /**
   * 显示 Marker 的 InfoWindow
   */
  public showInfoWindow(marker: Marker): void {
    this.infoWindowManager.show(marker);
  }
  
  /**
   * 隐藏 Marker 的 InfoWindow
   */
  public hideInfoWindow(marker: Marker): void {
    this.infoWindowManager.close(marker);
  }
  
  /**
   * 隐藏所有 InfoWindow
   */
  public hideAllInfoWindows(): void {
    this.infoWindowManager.closeAll();
  }
}

