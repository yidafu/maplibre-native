import { Marker } from './Marker';
import { MarkerOptions } from './MarkerOptions';
import { MarkerDragState } from './MarkerDragState';
import { LatLng } from '../geometry/LatLng';
import { MapLibreMap } from '../MapLibreMap';
import { OnMarkerClickListener } from '../listeners/OnMarkerClickListener';
import { OnMarkerDragListener } from '../listeners/OnMarkerDragListener';
import { OnInfoWindowClickListener } from '../listeners/OnInfoWindowClickListener';
import { InfoWindowAdapter } from './InfoWindowAdapter';

/**
 * MarkerManager - Marker 管理器
 * 
 * 负责管理地图上的所有 Marker，包括添加、删除、选中、拖拽等操作
 * 
 * 参考:
 * - Android: AnnotationManager + MarkerContainer
 */
export class MarkerManager {
  private markers: Map<number, Marker> = new Map();
  private selectedMarkers: Set<Marker> = new Set();
  private mapLibreMap: MapLibreMap;
  
  // 事件监听器
  private onMarkerClickListener: OnMarkerClickListener | null = null;
  private onMarkerDragListener: OnMarkerDragListener | null = null;
  private onInfoWindowClickListener: OnInfoWindowClickListener | null = null;
  private infoWindowAdapter: InfoWindowAdapter | null = null;
  
  // 拖拽相关
  private draggingMarker: Marker | null = null;
  
  /**
   * 构造函数
   * 
   * @param mapLibreMap MapLibreMap 实例
   */
  constructor(mapLibreMap: MapLibreMap) {
    this.mapLibreMap = mapLibreMap;
  }
  
  // ========== Marker 管理 ==========
  
  /**
   * 添加单个 Marker
   * 
   * @param options MarkerOptions 实例
   * @returns 创建的 Marker
   * @throws Error 如果 Marker 创建失败
   */
  public addMarker(options: MarkerOptions): Marker {
    try {
      const marker = options.getMarker();
      
      // 调用 NAPI 添加 Marker
      const ids = this.mapLibreMap.addMarkers([marker]);
      
      if (ids.length > 0) {
        const id = ids[0];
        marker.setId(id);
        marker.setMapLibreMap(this.mapLibreMap);
        this.markers.set(id, marker);
      }
      
      return marker;
    } catch (e) {
      const error = e as Error;
      console.error(`MarkerManager: Failed to add marker - ${error.message}`);
      throw new Error(`Failed to add marker: ${error.message}`);
    }
  }
  
  /**
   * 批量添加 Marker
   * 
   * @param optionsList MarkerOptions 数组
   * @returns 创建的 Marker 数组
   * @throws Error 如果批量添加失败
   */
  public addMarkers(optionsList: MarkerOptions[]): Marker[] {
    try {
      const markers: Marker[] = [];
      
      // 创建 Marker 对象
      for (const options of optionsList) {
        markers.push(options.getMarker());
      }
      
      // 批量调用 NAPI
      const ids = this.mapLibreMap.addMarkers(markers);
      
      // 设置 ID 并注册
      for (let i = 0; i < markers.length; i++) {
        if (i < ids.length) {
          const marker = markers[i];
          const id = ids[i];
          marker.setId(id);
          marker.setMapLibreMap(this.mapLibreMap);
          this.markers.set(id, marker);
        }
      }
      
      return markers;
    } catch (e) {
      const error = e as Error;
      console.error(`MarkerManager: Failed to add markers batch - ${error.message}`);
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
    
    // 从地图移除
    this.mapLibreMap.removeAnnotations([id]);
    
    // 从管理器移除
    this.markers.delete(id);
    marker.setId(-1);
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
        
        ids.push(id);
        this.markers.delete(id);
        marker.setId(-1);
      }
    }
    
    // 批量从地图移除
    if (ids.length > 0) {
      this.mapLibreMap.removeAnnotations(ids);
    }
  }
  
  /**
   * 清除所有 Marker
   */
  public clear(): void {
    const allMarkers = Array.from(this.markers.values());
    this.removeMarkers(allMarkers);
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
    marker.setSelected(false);
    marker.hideInfoWindow();
    this.selectedMarkers.delete(marker);
  }
  
  /**
   * 取消所有选中的 Marker
   */
  public deselectMarkers(): void {
    for (const marker of this.selectedMarkers) {
      marker.setSelected(false);
      marker.hideInfoWindow();
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
    return this.markers.get(id) || null;
  }
  
  /**
   * 获取所有 Marker
   * 
   * @returns Marker 数组
   */
  public getMarkers(): Marker[] {
    return Array.from(this.markers.values());
  }
  
  // ========== 拖拽处理 ==========
  
  /**
   * 处理拖拽开始
   * 
   * @param marker 正在拖拽的 Marker
   */
  public handleDragStart(marker: Marker): void {
    if (!marker.isDraggable()) {
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
   * 设置 InfoWindow 点击监听器
   * 
   * @param listener 监听器实例
   */
  public setOnInfoWindowClickListener(listener: OnInfoWindowClickListener | null): void {
    this.onInfoWindowClickListener = listener;
  }
  
  /**
   * 设置 InfoWindow 适配器
   * 
   * @param adapter 适配器实例
   */
  public setInfoWindowAdapter(adapter: InfoWindowAdapter | null): void {
    this.infoWindowAdapter = adapter;
  }
  
  /**
   * 获取 InfoWindow 适配器
   * 
   * @returns 适配器实例
   */
  public getInfoWindowAdapter(): InfoWindowAdapter | null {
    return this.infoWindowAdapter;
  }
}

