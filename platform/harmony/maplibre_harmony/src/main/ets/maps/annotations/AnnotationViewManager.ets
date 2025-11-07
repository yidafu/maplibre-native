import { NativeMapView } from 'libmaplibre.so';
// import { ComponentContent } from '@kit.ArkUI';
import { Point } from '../geometry/Point';
import { CenterOffset } from './AnnotationView';
import { AnnotationViewAdapter } from './AnnotationViewAdapter';
import { AnnotationViewConfig, AnnotationViewDelegate } from './AnnotationViewDelegate';
import { Marker } from './Marker';

/**
 * AnnotationViewData - Annotation 视图数据
 *
 * 包含渲染自定义视图所需的所有信息
 */
export interface AnnotationViewData {
  marker: Marker | null; // 允许为 null，避免 ObservedObject 错误
  customBuilder: (() => void) | null;
  screenX: number;
  screenY: number;
  anchorU: number;
  anchorV: number;
  visible: boolean;
  reuseIdentifier: string;
  centerOffset: CenterOffset;
  draggable: boolean;
  scalesWithViewingDistance: boolean;
  rotatesToMatchCamera: boolean;
  enabled: boolean;
  selected: boolean;
  alpha: number;
  zIndex: number;
  preferredWidth?: number;
  preferredHeight?: number;
}

/**
 * AnnotationViewManager - 自定义 Annotation 视图管理器
 *
 * 管理所有自定义 AnnotationView 的完整生命周期，提供高性能的视图管理能力
 *
 * **核心职责**：
 * - ✅ 维护 Marker → AnnotationView 映射关系
 * - ✅ 处理视图复用（reuseIdentifier 机制）
 * - ✅ 更新视图位置（响应地图相机变化）
 * - ✅ 选中状态管理（单选模式）
 * - ✅ 拖拽状态管理
 * - ✅ 与 AnnotationViewDelegate 交互
 * - ✅ 性能优化（批量更新、虚拟化渲染）
 *
 * **参考实现**：
 * - iOS: MLNMapView 的 annotation view 管理机制
 *   - dequeueReusableAnnotationViewWithIdentifier:
 *   - 自动视图复用和池管理
 *   - 委托方法调用
 * - Android: AnnotationManager
 *   - 注解容器管理
 *   - 事件分发
 *
 * **性能特性**：
 * - 视图复用池（减少创建开销）
 * - 批量位置更新（减少 UI 刷新）
 * - 虚拟化渲染支持（只渲染可见区域）
 * - 增量更新机制
 *
 * **使用示例**：
 * ```typescript
 * // 创建管理器
 * const manager = new AnnotationViewManager();
 * manager.setNativeMapView(nativeMapView);
 *
 * // 设置委托
 * manager.setDelegate(myDelegate);
 *
 * // 为 Marker 创建视图
 * manager.createOrUpdateView(marker);
 *
 * // 更新所有视图位置
 * manager.batchUpdatePositions(true);
 * ```
 */
export class AnnotationViewManager {
  // 委托（新增，替代 adapter）
  private delegate: AnnotationViewDelegate | null = null;
  // 适配器（保留用于向后兼容）
  private adapter: AnnotationViewAdapter | null = null;
  // 视图数据映射：Marker ID → AnnotationViewData
  private annotationViews: Map<number, AnnotationViewData> = new Map();
  // 复用池：reuseIdentifier → AnnotationViewData[]
  private reusePool: Map<string, AnnotationViewData[]> = new Map();
  // Native 地图视图（用于坐标转换）
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
  private onViewsUpdateCallback?: (views: AnnotationViewData[]) => void;

  /**
   * 设置 Native MapView（用于坐标转换）
   */
  setNativeMapView(mapView: NativeMapView): void {
    this.nativeMapView = mapView;
  }

  setOnViewsUpdateCallback(callback: ((views: AnnotationViewData[]) => void) | null): void {
    this.onViewsUpdateCallback = callback ?? undefined;
  }

  private notifyViewsUpdated(): void {
    if (this.onViewsUpdateCallback) {
      this.onViewsUpdateCallback(this.getAllViews());
    }
  }

  /**
   * 设置 AnnotationViewDelegate（推荐使用）
   *
   * 参考：iOS MLNMapView.delegate
   *
   * @param delegate AnnotationViewDelegate 实例，传 null 清除委托
   *
   * @example
  * ```typescript
   * const delegate: AnnotationViewDelegate = {
   *   viewForAnnotation: (marker) => {
   *     return {
   *       reuseIdentifier: 'custom-pin',
   *       contentBuilder: () => {
   *         Column() {
   *           Image($r('app.media.marker')).width(32).height(32)
   *         }
   *       }
   *     };
   *   }
   * };
   * manager.setDelegate(delegate);
   * ```
   */
  setDelegate(delegate: AnnotationViewDelegate | null): void {
    this.delegate = delegate;

    // 委托改变时，清除所有视图重新创建
    if (delegate) {
      this.recreateAllViews();
    }
  }

  /**
   * 获取 AnnotationViewDelegate
   *
   * @returns 当前设置的 delegate，如果未设置则返回 null
   */
  getDelegate(): AnnotationViewDelegate | null {
    return this.delegate;
  }

  /**
   * 设置 AnnotationViewAdapter（兼容方法）
   *
   * @deprecated 使用 {@link setDelegate} 替代
   *
   * @param adapter AnnotationViewAdapter 实例，传 null 清除适配器
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
   *
   * @deprecated 使用 {@link getDelegate} 替代
   *
   * @returns 当前设置的 adapter，如果未设置则返回 null
   */
  getAdapter(): AnnotationViewAdapter | null {
    return this.adapter;
  }

  /**
   * 为 Marker 创建或更新 AnnotationView
   *
   * 优先使用 delegate，如果没有则尝试使用 adapter（向后兼容）
   *
   * 参考：iOS MLNMapView 自动为 annotation 创建视图的机制
   *
   * @param marker 要创建/更新视图的 Marker
   *
   * 工作流程：
   * 1. 调用 delegate.viewForAnnotation 获取配置
   * 2. 如果没有 delegate，尝试使用 adapter（兼容）
   * 3. 如果返回 null，移除已有的自定义视图（使用默认图标）
   * 4. 创建或更新 AnnotationViewData
   * 5. 存储到 annotationViews Map
   */
  createOrUpdateView(marker: Marker): void {
    const markerId = marker.getId();
    let viewConfig: AnnotationViewConfig | null = null;
    let customBuilder: (() => void) | null = null;
    let reuseIdentifier: string;

    // 优先使用 delegate
    if (this.delegate && this.delegate.viewForAnnotation) {
      viewConfig = this.delegate.viewForAnnotation(marker);

      if (viewConfig) {
        reuseIdentifier = viewConfig.reuseIdentifier;
        // 注意：这里我们存储 contentBuilder 到 customBuilder
        // 实际渲染时由 AnnotationViewOverlay 处理
        customBuilder = viewConfig.contentBuilder ?? null;
      } else {
        // delegate 返回 null，使用默认图标
        this.removeView(marker);
        return;
      }
    }
    // 如果没有 delegate，尝试使用 adapter（向后兼容）
    else if (this.adapter) {
      if (!this.adapter.getAnnotationView(marker)) {
        // adapter 返回 null，使用默认图标
        this.removeView(marker);
        return;
      }

      // 获取复用标识符
      reuseIdentifier = this.adapter.getReuseIdentifier
        ? this.adapter.getReuseIdentifier(marker)
        : (marker.getIcon() || 'default');
      customBuilder = null;
    }
    // 既没有 delegate 也没有 adapter
    else {
      // 移除已有的自定义视图，使用默认图标
      this.removeView(marker);
      return;
    }

    // 计算屏幕位置
    const position = this.calculateScreenPosition(marker);

    // 获取锚点
    const anchor = marker.getAnchor();

    // 创建视图数据
    const defaultCenterOffset: CenterOffset = { dx: 0, dy: 0 };
    const viewData: AnnotationViewData = {
      marker: marker,
      customBuilder: customBuilder,
      screenX: position.x,
      screenY: position.y,
      anchorU: anchor.u,
      anchorV: anchor.v,
      visible: marker.getVisible(),
      reuseIdentifier: reuseIdentifier,
      centerOffset: { dx: defaultCenterOffset.dx, dy: defaultCenterOffset.dy },
      draggable: marker.getDraggable(),
      scalesWithViewingDistance: false,
      rotatesToMatchCamera: false,
      enabled: true,
      selected: this.selectedAnnotations.has(markerId),
      alpha: marker.getAlpha(),
      zIndex: marker.getZIndex() || 1
    };

    // 应用配置选项（如果有）
    if (viewConfig) {
      viewData.centerOffset = viewConfig.centerOffset
        ? { dx: viewConfig.centerOffset.dx, dy: viewConfig.centerOffset.dy }
        : defaultCenterOffset;
      viewData.draggable = viewConfig.draggable ?? marker.getDraggable();
      viewData.scalesWithViewingDistance = viewConfig.scalesWithViewingDistance ?? false;
      viewData.rotatesToMatchCamera = viewConfig.rotatesToMatchCamera ?? false;
      viewData.enabled = viewConfig.enabled ?? true;
      viewData.alpha = viewConfig.alpha ?? 1;
      viewData.zIndex = viewConfig.zIndex ?? (marker.getZIndex() || 1);
      if (viewConfig.size) {
        viewData.preferredWidth = viewConfig.size.width;
        viewData.preferredHeight = viewConfig.size.height;
      }

      // 更新可拖拽属性（同时作用于 Marker）
      marker.setDraggable(viewData.draggable);

      if (viewConfig.selected) {
        viewData.selected = true;
        this.selectedAnnotations.add(markerId);
      }
    }

    this.annotationViews.set(markerId, viewData);

    if (viewConfig?.selected) {
      this.selectAnnotation(marker, false);
    }

    this.notifyViewsUpdated();
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
      this.notifyViewsUpdated();
    }
  }

  /**
   * 更新所有视图的位置（地图移动时调用）
   */
  updateAllPositions(): void {
    this.annotationViews.forEach((viewData, markerId) => {
      // 🔒 修复 ObservedObject 错误：检查 marker 是否为 null
      if (viewData.marker !== null) {
        const position = this.calculateScreenPosition(viewData.marker);
        viewData.screenX = position.x;
        viewData.screenY = position.y;
      }
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

  public updatePositionsWithProjector(projector: (marker: Marker) => Point): void {
    this.annotationViews.forEach(viewData => {
      if (viewData.marker !== null) {
        const screenPoint = projector(viewData.marker);
        viewData.screenX = screenPoint.x;
        viewData.screenY = screenPoint.y;
      }
    });
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
    this.selectedAnnotations.clear();
    this.draggingAnnotation = null;
    this.draggingStartPosition = null;
    this.notifyViewsUpdated();
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
      if (marker) {
        this.createOrUpdateView(marker);
      }
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
      const pixelCoord: Object = this.nativeMapView.pixelForLatLng(latLng.latitude, latLng.longitude);
      const pixelRatio = this.nativeMapView.getPixelRatio();
      const safePixelRatio = pixelRatio === 0 ? 1 : pixelRatio;
      const logicalX = (pixelCoord as ScreenCoord).x / safePixelRatio;
      const logicalY = (pixelCoord as ScreenCoord).y / safePixelRatio;
      return new ScreenCoord(logicalX, logicalY);
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
   *
   * 参考: iOS MLNMapView dequeueReusableAnnotationViewWithIdentifier:
   *
   * @param identifier 复用标识符
   * @returns 复用的视图数据，如果池中没有则返回 null
   */
  public dequeueReusableView(identifier: string): AnnotationViewData | null {
    const pool: AnnotationViewData[] | undefined = this.reusePool.get(identifier);

    if (pool && pool.length > 0) {
      const viewData = pool.pop() || null;
      if (viewData) {
        // 注意：prepareForReuse() 应该在重新关联 marker 后由上层调用
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
      // 🔒 修复 ObservedObject 错误：检查 marker 是否为 null
      if (viewData && viewData.marker !== null && id !== markerId) {
        this.deselectAnnotation(viewData.marker, animated);
      }
    });

    // 添加到选中集合
    this.selectedAnnotations.add(markerId);

    // 触发回调
    if (this.onSelectCallback) {
      this.onSelectCallback(marker);
    }

    const viewData = this.annotationViews.get(markerId);
    if (viewData) {
      viewData.selected = true;
    }

    this.notifyViewsUpdated();

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

    const viewData = this.annotationViews.get(markerId);
    if (viewData) {
      viewData.selected = false;
    }

    this.notifyViewsUpdated();

  }

  /**
   * 取消所有选中
   */
  public deselectAll(animated: boolean = true): void {
    const selectedIds = Array.from(this.selectedAnnotations);
    selectedIds.forEach(id => {
      const viewData = this.annotationViews.get(id);
      // 🔒 修复 ObservedObject 错误：检查 marker 是否为 null
      if (viewData && viewData.marker !== null) {
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
      // 🔒 修复 ObservedObject 错误：检查 marker 是否为 null
      if (viewData && viewData.marker !== null) {
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
   *
   * 相比逐个更新，批量更新可以减少UI刷新次数
   *
   * @param markers 要更新的 Marker 数组
   */
  public batchUpdateViews(markers: Marker[]): void {
    markers.forEach(marker => {
      this.updateView(marker);
    });
  }

  /**
   * 批量更新所有可见视图的位置
   *
   * 在地图移动/缩放时调用，高效更新所有视图位置
   *
   * @param cameraChanged 相机是否发生变化（影响 transform 计算）
   */
  public batchUpdatePositions(cameraChanged: boolean = false): void {
    let updateCount = 0;
    this.annotationViews.forEach((viewData, markerId) => {
      // 🔒 修复 ObservedObject 错误：检查 marker 是否为 null
      if (viewData.marker !== null) {
        const position = this.calculateScreenPosition(viewData.marker);
        viewData.screenX = position.x;
        viewData.screenY = position.y;
        updateCount++;
      }
    });

    if (updateCount > 0) {
      // 外部负责触发渲染更新回调
    }
  }

  /**
   * 获取指定区域内的可见视图
   *
   * 用于虚拟化渲染，只渲染屏幕可见区域的视图
   *
   * @param bounds 屏幕边界
   * @returns 可见区域内的视图数据数组
   */
  public getVisibleViewsInBounds(bounds: ScreenBounds): AnnotationViewData[] {
    const visibleViews: AnnotationViewData[] = [];

    this.annotationViews.forEach(viewData => {
      if (viewData.visible &&
        viewData.screenX >= bounds.left &&
        viewData.screenX <= bounds.right &&
        viewData.screenY >= bounds.top &&
        viewData.screenY <= bounds.bottom) {
        visibleViews.push(viewData);
      }
    });

    return visibleViews;
  }

  /**
   * 获取视图总数
   *
   * @returns 当前管理的视图总数
   */
  public getViewCount(): number {
    return this.annotationViews.size;
  }

  /**
   * 获取复用池统计信息
   *
   * @returns 每个 identifier 的复用池大小
   */
  public getReusePoolStats(): Map<string, number> {
    const stats = new Map<string, number>();
    this.reusePool.forEach((pool, identifier) => {
      stats.set(identifier, pool.length);
    });
    return stats;
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

// 屏幕边界接口
export interface ScreenBounds {
  left: number;
  top: number;
  right: number;
  bottom: number;
}

