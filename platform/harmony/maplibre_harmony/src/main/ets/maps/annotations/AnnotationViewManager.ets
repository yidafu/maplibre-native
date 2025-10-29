import maplibre from 'libmaplibre.so';
// import { ComponentContent } from '@kit.ArkUI';
import { AnnotationViewAdapter } from './AnnotationViewAdapter';

type Marker = maplibre.Marker;
type NativeMapView = maplibre.NativeMapView;

/**
 * AnnotationViewData - Annotation 视图数据
 * 
 * 包含渲染自定义视图所需的所有信息
 */
export interface AnnotationViewData {
  marker: Marker;
  customView: object | null;
  screenX: number;
  screenY: number;
  anchorU: number;
  anchorV: number;
  visible: boolean;
  reuseIdentifier: string;
}

/**
 * AnnotationViewManager - 自定义 Annotation 视图管理器
 * 
 * 管理所有自定义 AnnotationView：
 * - 维护 Marker → AnnotationView 映射
 * - 处理视图复用（性能优化）
 * - 更新视图位置（地图移动时）
 * - 选中状态管理
 * - 拖拽管理
 * - 与 AnnotationViewAdapter 交互
 * 
 * 参考:
 * - iOS: MLNAnnotationView dequeue/reuse mechanism
 */
export class AnnotationViewManager {
  private adapter: AnnotationViewAdapter | null = null;
  private annotationViews: Map<number, AnnotationViewData> = new Map();
  private reusePool: Map<string, AnnotationViewData[]> = new Map();
  private nativeMapView: NativeMapView | null = null;
  
  // 选中状态管理
  private selectedAnnotations: Set<number> = new Set();
  
  // 拖拽管理
  private draggingAnnotation: Marker | null = null;
  private draggingStartPosition: ScreenCoord | null = null;
  
  // 回调
  private onSelectCallback?: (marker: Marker) => void;
  private onDeselectCallback?: (marker: Marker) => void;
  private onDragStartCallback?: (marker: Marker) => void;
  private onDragCallback?: (marker: Marker, screenX: number, screenY: number) => void;
  private onDragEndCallback?: (marker: Marker, screenX: number, screenY: number) => void;
  
  /**
   * 设置 Native MapView（用于坐标转换）
   */
  setNativeMapView(mapView: NativeMapView): void {
    this.nativeMapView = mapView;
  }
  
  /**
   * 设置 AnnotationViewAdapter
   */
  setAdapter(adapter: AnnotationViewAdapter | null): void {
    this.adapter = adapter;
    
    // 适配器改变时，清除所有视图重新创建
    if (adapter) {
      this.recreateAllViews();
    }
  }
  
  /**
   * 获取 AnnotationViewAdapter
   */
  getAdapter(): AnnotationViewAdapter | null {
    return this.adapter;
  }
  
  /**
   * 为 Marker 创建或更新 AnnotationView
   */
  createOrUpdateView(marker: Marker): void {
    if (!this.adapter) {
      // 没有适配器，移除已有的自定义视图
      this.removeView(marker);
      return;
    }
    
    const markerId = marker.getId();
    const customView = this.adapter.getAnnotationView(marker);
    
    if (!customView) {
      // 适配器返回 null，使用默认图标
      this.removeView(marker);
      return;
    }
    
    // 获取复用标识符
    const reuseIdentifier = this.adapter.getReuseIdentifier 
      ? this.adapter.getReuseIdentifier(marker)
      : (marker.getIcon() || 'default');
    
    // 计算屏幕位置
    const position = this.calculateScreenPosition(marker);
    
    // 获取锚点
    const anchor = marker.getAnchor();
    
    // 创建视图数据
    const viewData: AnnotationViewData = {
      marker: marker,
      customView: customView,
      screenX: position.x,
      screenY: position.y,
      anchorU: anchor.u,
      anchorV: anchor.v,
      visible: marker.getVisible(),
      reuseIdentifier: reuseIdentifier
    };
    
    this.annotationViews.set(markerId, viewData);
  }
  
  /**
   * 移除 Marker 的 AnnotationView
   */
  removeView(marker: Marker): void {
    const markerId = marker.getId();
    const viewData = this.annotationViews.get(markerId);
    
    if (viewData) {
      // 将视图放入复用池
      this.returnToReusePool(viewData);
      this.annotationViews.delete(markerId);
    }
  }
  
  /**
   * 更新所有视图的位置（地图移动时调用）
   */
  updateAllPositions(): void {
    this.annotationViews.forEach((viewData, markerId) => {
      const position = this.calculateScreenPosition(viewData.marker);
      viewData.screenX = position.x;
      viewData.screenY = position.y;
    });
  }
  
  /**
   * 更新单个视图
   */
  updateView(marker: Marker): void {
    const viewData = this.annotationViews.get(marker.getId());
    if (viewData) {
      const position = this.calculateScreenPosition(marker);
      viewData.screenX = position.x;
      viewData.screenY = position.y;
      viewData.visible = marker.getVisible();
      
      const anchor = marker.getAnchor();
      viewData.anchorU = anchor.u;
      viewData.anchorV = anchor.v;
    }
  }
  
  /**
   * 获取所有可见的视图数据
   */
  getVisibleViews(): AnnotationViewData[] {
    const visibleViews: AnnotationViewData[] = [];
    
    this.annotationViews.forEach(viewData => {
      if (viewData.visible) {
        visibleViews.push(viewData);
      }
    });
    
    return visibleViews;
  }
  
  /**
   * 获取所有视图数据
   */
  getAllViews(): AnnotationViewData[] {
    return Array.from(this.annotationViews.values());
  }
  
  /**
   * 清除所有视图
   */
  clear(): void {
    this.annotationViews.clear();
    this.reusePool.clear();
  }
  
  /**
   * 重新创建所有视图（适配器改变时）
   */
  private recreateAllViews(): void {
    const markers = Array.from(this.annotationViews.keys()).map(id => {
      return this.annotationViews.get(id)!.marker;
    });
    
    this.annotationViews.clear();
    
    markers.forEach(marker => {
      this.createOrUpdateView(marker);
    });
  }
  
  /**
   * 计算 Marker 的屏幕位置
   */
  private calculateScreenPosition(marker: Marker): ScreenCoord {
    if (!this.nativeMapView) {
      return new ScreenCoord(0, 0);
    }
    
    const latLng = marker.getPosition();
    
    try {
      // 调用 NAPI 方法转换坐标
      const pixelCoord = this.nativeMapView.pixelForLatLng(latLng.latitude, latLng.longitude);
      return new ScreenCoord(pixelCoord.x, pixelCoord.y);
    } catch (e) {
      console.error('[AnnotationViewManager] Failed to calculate screen position:', e);
      return new ScreenCoord(0, 0);
    }
  }
  
  /**
   * 将视图返回到复用池
   */
  private returnToReusePool(viewData: AnnotationViewData): void {
    const identifier = viewData.reuseIdentifier;
    
    if (!this.reusePool.has(identifier)) {
      this.reusePool.set(identifier, []);
    }
    
    const pool: AnnotationViewData[] | undefined = this.reusePool.get(identifier);
    if (pool) {
      // 限制复用池大小（避免内存泄漏）
      if (pool.length < 10) {
        pool.push(viewData);
      }
    }
  }
  
  /**
   * 从复用池获取视图
   */
  public dequeueReusableView(identifier: string): AnnotationViewData | null {
    const pool: AnnotationViewData[] | undefined = this.reusePool.get(identifier);
    
    if (pool && pool.length > 0) {
      const viewData = pool.pop() || null;
      if (viewData) {
        // 调用 prepareForReuse 重置状态（如果视图数据有此方法）
        // viewData.prepareForReuse?.();
      }
      return viewData;
    }
    
    return null;
  }
  
  // ========== 选中状态管理 ==========
  
  /**
   * 设置选中回调
   */
  public setOnSelectCallback(callback: (marker: Marker) => void): void {
    this.onSelectCallback = callback;
  }
  
  /**
   * 设置取消选中回调
   */
  public setOnDeselectCallback(callback: (marker: Marker) => void): void {
    this.onDeselectCallback = callback;
  }
  
  /**
   * 选中 Annotation
   */
  public selectAnnotation(marker: Marker, animated: boolean = true): void {
    const markerId = marker.getId();
    
    // 如果已经选中，不做任何操作
    if (this.selectedAnnotations.has(markerId)) {
      return;
    }
    
    // 取消其他选中的（单选模式）
    this.selectedAnnotations.forEach(id => {
      const viewData = this.annotationViews.get(id);
      if (viewData && id !== markerId) {
        this.deselectAnnotation(viewData.marker, animated);
      }
    });
    
    // 添加到选中集合
    this.selectedAnnotations.add(markerId);
    
    // 触发回调
    if (this.onSelectCallback) {
      this.onSelectCallback(marker);
    }
    
    console.info(`[AnnotationViewManager] Selected annotation: ${markerId}`);
  }
  
  /**
   * 取消选中 Annotation
   */
  public deselectAnnotation(marker: Marker, animated: boolean = true): void {
    const markerId = marker.getId();
    
    if (!this.selectedAnnotations.has(markerId)) {
      return;
    }
    
    // 从选中集合移除
    this.selectedAnnotations.delete(markerId);
    
    // 触发回调
    if (this.onDeselectCallback) {
      this.onDeselectCallback(marker);
    }
    
    console.info(`[AnnotationViewManager] Deselected annotation: ${markerId}`);
  }
  
  /**
   * 取消所有选中
   */
  public deselectAll(animated: boolean = true): void {
    const selectedIds = Array.from(this.selectedAnnotations);
    selectedIds.forEach(id => {
      const viewData = this.annotationViews.get(id);
      if (viewData) {
        this.deselectAnnotation(viewData.marker, animated);
      }
    });
  }
  
  /**
   * 获取选中的 Annotations
   */
  public getSelectedAnnotations(): Marker[] {
    const selected: Marker[] = [];
    this.selectedAnnotations.forEach(id => {
      const viewData = this.annotationViews.get(id);
      if (viewData) {
        selected.push(viewData.marker);
      }
    });
    return selected;
  }
  
  /**
   * 检查 Annotation 是否被选中
   */
  public isAnnotationSelected(marker: Marker): boolean {
    return this.selectedAnnotations.has(marker.getId());
  }
  
  // ========== 拖拽管理 ==========
  
  /**
   * 设置拖拽开始回调
   */
  public setOnDragStartCallback(callback: (marker: Marker) => void): void {
    this.onDragStartCallback = callback;
  }
  
  /**
   * 设置拖拽中回调
   */
  public setOnDragCallback(callback: (marker: Marker, screenX: number, screenY: number) => void): void {
    this.onDragCallback = callback;
  }
  
  /**
   * 设置拖拽结束回调
   */
  public setOnDragEndCallback(callback: (marker: Marker, screenX: number, screenY: number) => void): void {
    this.onDragEndCallback = callback;
  }
  
  /**
   * 开始拖拽
   */
  public startDragging(marker: Marker): void {
    if (this.draggingAnnotation) {
      console.warn('[AnnotationViewManager] Already dragging another annotation');
      return;
    }
    
    this.draggingAnnotation = marker;
    const viewData = this.annotationViews.get(marker.getId());
    
    if (viewData) {
      this.draggingStartPosition = new ScreenCoord(viewData.screenX, viewData.screenY);
    }
    
    if (this.onDragStartCallback) {
      this.onDragStartCallback(marker);
    }
    
    console.info(`[AnnotationViewManager] Start dragging: ${marker.getId()}`);
  }
  
  /**
   * 更新拖拽位置
   */
  public updateDragging(marker: Marker, screenX: number, screenY: number): void {
    if (!this.draggingAnnotation || this.draggingAnnotation.getId() !== marker.getId()) {
      return;
    }
    
    // 更新视图位置
    const viewData = this.annotationViews.get(marker.getId());
    if (viewData) {
      viewData.screenX = screenX;
      viewData.screenY = screenY;
    }
    
    if (this.onDragCallback) {
      this.onDragCallback(marker, screenX, screenY);
    }
  }
  
  /**
   * 结束拖拽
   */
  public endDragging(marker: Marker, screenX: number, screenY: number): void {
    if (!this.draggingAnnotation || this.draggingAnnotation.getId() !== marker.getId()) {
      return;
    }
    
    // 更新最终位置
    const viewData = this.annotationViews.get(marker.getId());
    if (viewData) {
      viewData.screenX = screenX;
      viewData.screenY = screenY;
    }
    
    if (this.onDragEndCallback) {
      this.onDragEndCallback(marker, screenX, screenY);
    }
    
    // 清除拖拽状态
    this.draggingAnnotation = null;
    this.draggingStartPosition = null;
    
    console.info(`[AnnotationViewManager] End dragging: ${marker.getId()}`);
  }
  
  /**
   * 取消拖拽
   */
  public cancelDragging(marker: Marker): void {
    if (!this.draggingAnnotation || this.draggingAnnotation.getId() !== marker.getId()) {
      return;
    }
    
    // 恢复到拖拽开始位置
    if (this.draggingStartPosition) {
      const viewData = this.annotationViews.get(marker.getId());
      if (viewData) {
        viewData.screenX = this.draggingStartPosition.x;
        viewData.screenY = this.draggingStartPosition.y;
      }
    }
    
    // 清除拖拽状态
    this.draggingAnnotation = null;
    this.draggingStartPosition = null;
    
    console.info(`[AnnotationViewManager] Cancel dragging: ${marker.getId()}`);
  }
  
  /**
   * 获取正在拖拽的 Annotation
   */
  public getDraggingAnnotation(): Marker | null {
    return this.draggingAnnotation;
  }
  
  /**
   * 检查是否正在拖拽
   */
  public isDragging(): boolean {
    return this.draggingAnnotation !== null;
  }
  
  // ========== 批量更新优化 ==========
  
  /**
   * 批量更新视图（性能优化）
   */
  public batchUpdateViews(markers: Marker[]): void {
    markers.forEach(marker => {
      this.updateView(marker);
    });
  }
}

// 屏幕坐标辅助类
class ScreenCoord {
  x: number;
  y: number;
  
  constructor(x: number, y: number) {
    this.x = x;
    this.y = y;
  }
}

