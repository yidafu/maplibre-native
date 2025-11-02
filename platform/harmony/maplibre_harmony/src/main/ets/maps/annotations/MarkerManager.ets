import type { NativeMapView } from 'libmaplibre.so';
import type { MarkerOptions } from './MarkerOptions';
import { MarkerDragState } from './MarkerDragState';
import type { LatLng } from '../geometry/LatLng';
import type { MapLibreMap } from '../MapLibreMap';
import type { OnMarkerClickListener } from '../listeners/OnMarkerClickListener';
import type { OnMarkerDragListener } from '../listeners/OnMarkerDragListener';
import type { OnInfoWindowClickListener } from '../listeners/OnInfoWindowClickListener';
import type { OnInfoWindowCloseListener } from '../listeners/OnInfoWindowCloseListener';
import type { OnMarkerSelectListener } from '../listeners/OnMarkerSelectListener';
import type { InfoWindowAdapter } from './InfoWindowAdapter';
import { InfoWindowManager } from './InfoWindowManager';
import type { AnnotationViewAdapter } from './AnnotationViewAdapter';
import { AnnotationViewManager } from './AnnotationViewManager';
import { IconManager } from './IconManager';
import { IconFactory } from './IconFactory';
import { MarkerLayerManager } from './MarkerLayerManager';
import type { InfoWindowStyle } from './InfoWindow';
import type { Icon } from './Icon';
import type { Marker } from './Marker';

/**
 * MarkerManager - Marker 管理器
 * 
 * 基于 GeoJSON Source + SymbolLayer 实现，支持所有高级功能
 * 
 * 参考:
 * - Android: AnnotationManager + MarkerContainer + IconManager
 *   使用Icon对象引用计数，Marker直接持有Icon
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
  
  // Marker ID -> Icon 映射（因为NAPI Marker不持有Icon对象引用）
  // 注意：虽然保留此映射，但IconManager使用Icon对象作为key，确保引用计数正确
  private markerIconMap: Map<number, Icon> = new Map();
  
  // Marker ID -> InfoWindowStyle 映射（存储每个 Marker 的 InfoWindow 样式配置）
  private markerInfoWindowStyleMap: Map<number, InfoWindowStyle> = new Map();
  
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
   * @returns Promise<Marker> 创建的 Marker
   * @throws Error 如果 Marker 创建失败
   */
  public async addMarker(options: MarkerOptions): Promise<Marker> {
    try {
      // 确保 MarkerLayerManager 已初始化
      if (!this.markerLayerManager.isInitialized()) {
        this.markerLayerManager.initialize();
      }
      
      // 获取Icon对象（优先使用复用标识符）
      let icon: Icon | undefined = options.getIcon();
      const reuseIdentifier = options.getReuseIdentifier();
      
      if (!icon && reuseIdentifier) {
        // 尝试从复用队列获取图标
        const reusedIcon = this.iconManager.dequeueReusableIcon(reuseIdentifier);
        if (reusedIcon) {
          icon = reusedIcon;
          console.info(`[MarkerManager] Reusing icon with identifier: ${reuseIdentifier}`);
        }
      }
      
      if (!icon) {
        // 如果没有设置图标，加载默认图标
        console.info('[MarkerManager] No icon set, loading default marker icon');
        if (!this.iconManager.iconFactory) {
          throw new Error('[MarkerManager] IconFactory is not initialized');
        }
        icon = await this.iconManager.iconFactory.defaultMarker();
        options.icon(icon);
      }
      
      // 创建 Marker 对象（getMarker()会将icon.getId()传给NAPI层）
      const marker = options.getMarker();
      
      // 添加Icon到IconManager（marker已经设置了iconId）
      await this.iconManager.addIconToManager(icon);
      
      // 添加到 MarkerLayerManager
      const featureId = this.markerLayerManager.addMarker(marker);
      
      // 设置 ID 和关联
      marker.setId(featureId);
      marker.setMapLibreMap(this.mapLibreMap);
      this.markerMap.set(featureId, marker);
      
      // 保存Marker -> Icon映射（因为NAPI Marker只存储iconId字符串）
      this.markerIconMap.set(featureId, icon);
      
      // 保存 InfoWindow 样式配置
      const infoWindowStyle = options.getInfoWindowStyle();
      if (infoWindowStyle) {
        this.markerInfoWindowStyleMap.set(featureId, infoWindowStyle);
      }
      
      console.info(`[MarkerManager] Added marker with ID=${featureId}, icon=${icon.getId()}`);
      
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
   * 批量添加 Marker
   * 
   * @param optionsList MarkerOptions 数组
   * @returns Promise<Marker[]> 创建的 Marker 数组
   * @throws Error 如果批量添加失败
   */
  public async addMarkers(optionsList: MarkerOptions[]): Promise<Marker[]> {
    try {
      // 确保 MarkerLayerManager 已初始化
      if (!this.markerLayerManager.isInitialized()) {
        this.markerLayerManager.initialize();
      }
      
      // 创建 Marker 对象数组，同时加载icons
      const markers: Marker[] = [];
      const icons: Icon[] = [];
      
      for (const options of optionsList) {
        // 获取Icon对象（从MarkerOptions）
        let icon = options.getIcon();
        if (!icon) {
          console.info('[MarkerManager] No icon set in batch, loading default marker icon');
          if (!this.iconManager.iconFactory) {
            throw new Error('[MarkerManager] IconFactory is not initialized');
          }
          icon = await this.iconManager.iconFactory.defaultMarker();
          options.icon(icon);
        }
        
        icons.push(icon);
        
        const marker = options.getMarker();
        
        // 添加Icon到IconManager（marker已经设置了iconId）
        await this.iconManager.addIconToManager(icon);
        
        markers.push(marker);
      }
      
      // 批量添加到 MarkerLayerManager
      const featureIds = this.markerLayerManager.addMarkers(markers);
      
      // 设置 ID 并注册
      for (let i = 0; i < markers.length; i++) {
        const marker = markers[i];
        const featureId = featureIds[i];
        const icon = icons[i];
        const options = optionsList[i];
        
        marker.setId(featureId);
        marker.setMapLibreMap(this.mapLibreMap);
        this.markerMap.set(featureId, marker);
        
        // 保存Marker -> Icon映射
        this.markerIconMap.set(featureId, icon);
        
        // 保存 InfoWindow 样式配置
        const infoWindowStyle = options.getInfoWindowStyle();
        if (infoWindowStyle) {
          this.markerInfoWindowStyleMap.set(featureId, infoWindowStyle);
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
    // 由于NAPI Marker不持有Icon对象，从markerIconMap获取
    const icon = this.markerIconMap.get(id);
    if (icon) {
      this.iconManager.iconCleanup(icon);
      this.markerIconMap.delete(id);
    }
    
    // 移除 InfoWindow 样式配置
    this.markerInfoWindowStyleMap.delete(id);
    
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
        const icon = this.markerIconMap.get(id);
        if (icon) {
          this.iconManager.iconCleanup(icon);
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
   * 更新 Marker
   * 
   * 更新 Marker 的所有属性到地图显示（位置、图标、透明度、旋转等）
   * 
   * @param marker 要更新的 Marker
   */
  public updateMarker(marker: Marker): void {
    try {
      const markerId = marker.getId();
      if (markerId < 0 || !this.markerMap.has(markerId)) {
        console.warn(`[MarkerManager] updateMarker: Marker ${markerId} not found in manager`);
        return;
      }
      
      // 更新 MarkerLayerManager 中的特征（更新 GeoJSON）
      this.markerLayerManager.updateMarker(markerId, marker);
      
      console.debug(`[MarkerManager] Updated marker ${markerId}`);
    } catch (e) {
      const error = e as Error;
      console.error(`[MarkerManager] Failed to update marker: ${error.message}`);
    }
  }

  /**
   * 更新 Marker 的图标
   * 
   * 自动处理旧图标的引用计数和新图标的加载
   * 
   * @param marker 要更新的 Marker
   * @param newIcon 新的 Icon 实例
   */
  public async updateMarkerIcon(marker: Marker, newIcon: Icon): Promise<void> {
    try {
      const markerId = marker.getId();
      if (markerId < 0 || !this.markerMap.has(markerId)) {
        throw new Error('Marker not found in manager');
      }
      
      // 获取旧图标
      const oldIcon = this.markerIconMap.get(markerId) || null;
      
      // 使用 IconManager 更新图标（自动处理引用计数）
      await this.iconManager.updateMarkerIcon(marker, oldIcon, newIcon);
      
      // 更新本地映射
      this.markerIconMap.set(markerId, newIcon);
      
      // 更新 MarkerLayerManager 中的特征
      this.markerLayerManager.updateMarker(markerId, marker);
      
      // 更新自定义视图
      this.annotationViewManager.createOrUpdateView(marker);
      
      console.info(`[MarkerManager] Updated marker ${markerId} icon to ${newIcon.getId()}`);
    } catch (e) {
      const error = e as Error;
      console.error(`[MarkerManager] Failed to update marker icon: ${error.message}`);
      throw new Error(`Failed to update marker icon: ${error.message}`);
    }
  }

  /**
   * 清除所有 Marker
   * 
   * 移除地图上所有的 Marker 并释放相关资源。
   * 
   * **重要提示**：
   * - 此方法会减少所有 Icon 的引用计数
   * - 当 Icon 的引用计数降为 0 时，Icon 会被自动释放（PixelMap 资源被回收）
   * - **已释放的 Icon 不能被复用**
   * - 清除后如需再次添加相同图标的 Marker，必须创建新的 Icon 实例
   * 
   * @example
   * ```typescript
   * // 清除所有 marker
   * markerManager.clear();
   * 
   * // 错误用法：复用旧的 Icon
   * const oldIcon = marker.getIcon();
   * const newMarker = new MarkerOptions().position(latLng).icon(oldIcon); // ❌ 错误！
   * 
   * // 正确用法：创建新的 Icon
   * const factory = IconFactory.getInstance();
   * const newIcon = await factory.fromResource($r('app.media.marker')); // ✓ 正确
   * const newMarker = new MarkerOptions().position(latLng).icon(newIcon);
   * ```
   */
  public clear(): void {
    // 清理每个marker
    for (const marker of this.markerMap.values()) {
      if (marker.isInfoWindowShown()) {
        marker.hideInfoWindow();
      }
      
      // Icon cleanup
      // 从markerIconMap获取Icon对象（因为NAPI Marker不持有Icon引用）
      const icon = this.markerIconMap.get(marker.getId());
      if (icon) {
        // iconCleanup使用Icon对象作为key，多个markers共享同一Icon时正确处理
        this.iconManager.iconCleanup(icon);
      }
      
      marker.setId(-1);
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
    if (!marker.getDraggable() || marker.getDragState() !== MarkerDragState.Dragging) {
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
    if (!marker.getDraggable() || this.draggingMarker !== marker) {
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
   * 获取 Marker 的 InfoWindow 样式配置
   * 
   * @param marker Marker 实例
   * @returns InfoWindowStyle 或 undefined
   */
  public getInfoWindowStyle(marker: Marker): InfoWindowStyle | undefined {
    const id = marker.getId();
    return this.markerInfoWindowStyleMap.get(id);
  }
  
  /**
   * 显示 Marker 的 InfoWindow
   */
  public showInfoWindow(marker: Marker): void {
    try {
      // 获取 Marker 屏幕坐标
      const pos = marker.getPosition();
      const screenPoint = this.mapLibreMap.pixelForLatLng(pos.latitude, pos.longitude);
      
      // 获取视图尺寸
      const viewWidth: number = this.mapLibreMap.getViewWidth();
      const viewHeight: number = this.mapLibreMap.getViewHeight();
      
      // 获取 InfoWindow 样式
      const style = this.getInfoWindowStyle(marker);
      
      // 显示 InfoWindow
      this.infoWindowManager.show(marker, viewWidth, viewHeight, screenPoint, style);
      
      console.info(`[MarkerManager] Showing InfoWindow for marker ${marker.getId()}`);
    } catch (error) {
      console.error(`[MarkerManager] Failed to show InfoWindow: ${error.message}`);
    }
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

