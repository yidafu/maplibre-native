import { NativeMapView } from 'libmaplibre.so';
// import { ComponentContent } from '@kit.ArkUI';
import { Point } from '../geometry/Point';
import {
  NativeViewAnnotationAnchorImpl,
  NativeViewAnnotationCenterOffset,
  NativeViewAnnotationCenterOffsetImpl,
  NativeViewAnnotationFrame,
  NativeViewAnnotationOptions,
  NativeViewAnnotationOptionsImpl
} from './NativeViewAnnotationTypes';
import { CenterOffset } from './AnnotationView';
import { AnnotationViewAdapter } from './AnnotationViewAdapter';
import { AnnotationViewConfig, AnnotationViewDelegate } from './AnnotationViewDelegate';
import { Marker } from './Marker';

const DEFAULT_VIEW_SIZE = 40;

/**
 * AnnotationViewData - Data object for annotation views
 *
 * Provides all information required to render a custom view
 */
export interface AnnotationViewData {
  marker: Marker | null; // Allow null to avoid ObservedObject issues
  customBuilder: (() => void) | null;
  screenX: number;
  screenY: number;
  annotationId?: number;
  width?: number;
  height?: number;
  nativeScale?: number;
  nativeRotation?: number;
  nativeOpacity?: number;
  pixelRatio?: number;
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
  reuseVersion: number;
}

/**
 * AnnotationViewManager - Manager for custom annotation views
 *
 * Oversees the full lifecycle of custom `AnnotationView` instances with a focus on performance.
 *
 * **Core responsibilities**:
 * - Maintain the Marker → AnnotationView mapping
 * - Handle view reuse (reuseIdentifier mechanism)
 * - Update view positions when the camera changes
 * - Manage selection state (single-selection mode)
 * - Manage drag state
 * - Communicate with `AnnotationViewDelegate`
 * - Provide performance optimizations (batch updates, virtualization)
 *
 * **Reference implementations**:
 * - iOS: MLNMapView annotation view management
 *   - `dequeueReusableAnnotationViewWithIdentifier:`
 *   - Automatic reuse pool handling
 *   - Delegate callbacks
 * - Android: AnnotationManager
 *   - Annotation container management
 *   - Event dispatch
 *
 * **Performance characteristics**:
 * - View reuse pool (reduced creation overhead)
 * - Batched position updates (fewer UI refreshes)
 * - Virtualized rendering (render only visible views)
 * - Incremental update strategy
 *
 * **Usage example**:
 * ```typescript
 * // Create manager
 * const manager = new AnnotationViewManager();
 * manager.setNativeMapView(nativeMapView);
 *
 * // Set delegate
 * manager.setDelegate(myDelegate);
 *
 * // Create view for marker
 * manager.createOrUpdateView(marker);
 *
 * // Update positions
 * manager.batchUpdatePositions(true);
 * ```
 */
export class AnnotationViewManager {
  // Delegate (preferred over adapter)
  private delegate: AnnotationViewDelegate | null = null;
  // Adapter (retained for backwards compatibility)
  private adapter: AnnotationViewAdapter | null = null;
  // View data mapping: Marker ID → AnnotationViewData
  private annotationViews: Map<number, AnnotationViewData> = new Map();
  // Reuse pool: reuseIdentifier → AnnotationViewData[]
  private reusePool: Map<string, AnnotationViewData[]> = new Map();
  // Native map view used for coordinate conversion
  private nativeMapView: NativeMapView | null = null;
  private markerToAnnotationId: Map<number, number> = new Map();
  private annotationIdToMarkerId: Map<number, number> = new Map();
  private pixelRatio: number = 1.0;
  // Selection state
  private selectedAnnotations: Set<number> = new Set();
  // Drag state
  private draggingAnnotation: Marker | null = null;
  private draggingStartPosition: ScreenCoord | null = null;
  // Callbacks
  private onSelectCallback?: (marker: Marker) => void;
  private onDeselectCallback?: (marker: Marker) => void;
  private onDragStartCallback?: (marker: Marker) => void;
  private onDragCallback?: (marker: Marker, screenX: number, screenY: number) => void;
  private onDragEndCallback?: (marker: Marker, screenX: number, screenY: number) => void;
  private onViewsUpdateCallback?: (views: AnnotationViewData[]) => void;

  /**
   * Set the native map view (required for coordinate conversion)
   */
  setNativeMapView(mapView: NativeMapView): void {
    this.nativeMapView = mapView;
    try {
      this.pixelRatio = mapView.getPixelRatio?.() ?? this.pixelRatio;
    } catch (error) {
      console.warn('[AnnotationViewManager] Failed to read pixel ratio from NativeMapView:', error);
    }
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
   * Assign the AnnotationViewDelegate (recommended)
   *
   * Mirrors the behavior of iOS `MLNMapView.delegate`.
   *
   * @param delegate AnnotationViewDelegate instance; pass null to clear
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

    // Recreate all views whenever the delegate changes
    if (delegate) {
      this.recreateAllViews();
    }
  }

  /**
   * Retrieve the current AnnotationViewDelegate
   *
   * @returns Delegate instance or null when unset
   */
  getDelegate(): AnnotationViewDelegate | null {
    return this.delegate;
  }

  /**
   * Assign the AnnotationViewAdapter (compatibility method)
   *
   * @deprecated Use {@link setDelegate} instead
   *
   * @param adapter AnnotationViewAdapter instance; pass null to clear
   */
  setAdapter(adapter: AnnotationViewAdapter | null): void {
    this.adapter = adapter;

    // Recreate all views when the adapter changes
    if (adapter) {
      this.recreateAllViews();
    }
  }

  /**
   * Retrieve the AnnotationViewAdapter
   *
   * @deprecated Use {@link getDelegate} instead
   *
   * @returns Adapter instance or null if unset
   */
  getAdapter(): AnnotationViewAdapter | null {
    return this.adapter;
  }

  /**
   * Create or update the AnnotationView for a marker
   *
   * Prefers the delegate; falls back to the adapter for legacy compatibility.
   * Mirrors the automatic view creation workflow used by iOS `MLNMapView`.
   *
   * @param marker Marker whose view should be created/updated
   *
   * Workflow:
   * 1. Invoke `delegate.viewForAnnotation` to fetch configuration
   * 2. If no delegate, attempt the adapter (legacy)
   * 3. If null is returned, remove the custom view (fall back to default icon)
   * 4. Create or update `AnnotationViewData`
   * 5. Persist inside the `annotationViews` map
   */
  createOrUpdateView(marker: Marker): void {
    const markerId = marker.getId();
    let viewConfig: AnnotationViewConfig | null = null;
    let customBuilder: (() => void) | null = null;
    let reuseIdentifier: string;

    // Prefer delegate
    if (this.delegate && this.delegate.viewForAnnotation) {
      viewConfig = this.delegate.viewForAnnotation(marker);

      if (viewConfig) {
        reuseIdentifier = viewConfig.reuseIdentifier;
        // Store contentBuilder as customBuilder; actual rendering is handled by AnnotationViewOverlay
        customBuilder = viewConfig.contentBuilder ?? null;
      } else {
        // Delegate returned null → use default icon
        this.removeView(marker);
        return;
      }
    }
    // If delegate is absent, try the adapter (legacy path)
    else if (this.adapter) {
      if (!this.adapter.getAnnotationView(marker)) {
        // Adapter returned null → use default icon
        this.removeView(marker);
        return;
      }

      // Determine reuse identifier
      reuseIdentifier = this.adapter.getReuseIdentifier
        ? this.adapter.getReuseIdentifier(marker)
        : (marker.getIcon() || 'default');
      customBuilder = null;
    }
    // Neither delegate nor adapter is available
    else {
      // Remove custom view if present; revert to default icon
      this.removeView(marker);
      return;
    }

    // Compute screen position
    const position = this.calculateScreenPosition(marker);

    // Retrieve anchor
    const anchor = marker.getAnchor();

    // Create view data
    const defaultCenterOffset: CenterOffset = { dx: 0, dy: 0 };
    let existingViewData = this.annotationViews.get(markerId);
    let reusedFromPool = false;

    if (!existingViewData) {
      const reused = this.dequeueReusableView(reuseIdentifier);
      if (reused) {
        existingViewData = reused;
        existingViewData.reuseVersion = (existingViewData.reuseVersion ?? 0) + 1;
        reusedFromPool = true;
      }
    }

    const viewData: AnnotationViewData = existingViewData ?? {
      marker: marker,
      customBuilder: customBuilder,
      screenX: position.x,
      screenY: position.y,
      annotationId: this.markerToAnnotationId.get(markerId),
      width: DEFAULT_VIEW_SIZE,
      height: DEFAULT_VIEW_SIZE,
      nativeScale: 1,
      nativeRotation: 0,
      nativeOpacity: 1,
      pixelRatio: this.pixelRatio,
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
      zIndex: marker.getZIndex() || 1,
      reuseVersion: 0
    };

    viewData.marker = marker;
    viewData.customBuilder = customBuilder;
    viewData.screenX = position.x;
    viewData.screenY = position.y;
    viewData.annotationId = this.markerToAnnotationId.get(markerId);
    viewData.pixelRatio = this.pixelRatio;
    viewData.reuseIdentifier = reuseIdentifier;
    viewData.visible = marker.getVisible();
    viewData.centerOffset = { dx: defaultCenterOffset.dx, dy: defaultCenterOffset.dy };
    viewData.draggable = marker.getDraggable();
    viewData.scalesWithViewingDistance = false;
    viewData.rotatesToMatchCamera = false;
    viewData.enabled = true;
    viewData.alpha = marker.getAlpha();
    viewData.zIndex = marker.getZIndex() || 1;

    if (reusedFromPool) {
      viewData.nativeScale = 1;
      viewData.nativeRotation = 0;
      viewData.nativeOpacity = 1;
      viewData.preferredWidth = undefined;
      viewData.preferredHeight = undefined;
      viewData.width = DEFAULT_VIEW_SIZE;
      viewData.height = DEFAULT_VIEW_SIZE;
      viewData.selected = false;
    }

    // Apply configuration overrides when provided
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
        viewData.width = viewConfig.size.width;
        viewData.height = viewConfig.size.height;
      } else {
        viewData.width = viewData.preferredWidth ?? viewData.width ?? DEFAULT_VIEW_SIZE;
        viewData.height = viewData.preferredHeight ?? viewData.height ?? DEFAULT_VIEW_SIZE;
      }

      // Propagate draggability back to the marker
      marker.setDraggable(viewData.draggable);

      if (viewConfig.selected) {
        viewData.selected = true;
        this.selectedAnnotations.add(markerId);
      }
    }

    this.annotationViews.set(markerId, viewData);
    this.syncAnnotationWithNative(marker, viewData);

    if (viewConfig?.selected) {
      this.selectAnnotation(marker, false);
    }

    this.notifyViewsUpdated();
  }

  /**
   * Remove the AnnotationView associated with a marker
   */
  removeView(marker: Marker): void {
    const markerId = marker.getId();
    const viewData = this.annotationViews.get(markerId);

    if (viewData) {
      // Return the view to the reuse pool
      this.returnToReusePool(viewData);
      this.annotationViews.delete(markerId);
      this.removeAnnotationFromNative(markerId);
      this.selectedAnnotations.delete(markerId);
      this.notifyViewsUpdated();
    }
  }

  /**
   * Update positions for every view (invoked when the map moves)
   */
  updateAllPositions(): void {
    if (this.nativeMapView) {
      this.batchUpdatePositions();
      return;
    }
    this.annotationViews.forEach((viewData) => {
      if (viewData.marker !== null) {
        const position = this.calculateScreenPosition(viewData.marker);
        viewData.screenX = position.x;
        viewData.screenY = position.y;
      }
    });
  }

  /**
   * Update a single view
   */
  updateView(marker: Marker): void {
    if (this.nativeMapView) {
      this.batchUpdatePositions();
      return;
    }
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
   * Retrieve all visible view data
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
   * Retrieve all view data
   */
  getAllViews(): AnnotationViewData[] {
    return Array.from(this.annotationViews.values());
  }

  /**
   * Clear every view
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
   * Recreate every view (called when the delegate/adapter changes)
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
   * Calculate the on-screen position of a marker
   */
  private calculateScreenPosition(marker: Marker): ScreenCoord {
    if (!this.nativeMapView) {
      return new ScreenCoord(0, 0);
    }

    const latLng = marker.getPosition();

    try {
      // Convert coordinates through NAPI
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

  private buildNativeOptions(marker: Marker, viewData: AnnotationViewData): NativeViewAnnotationOptions {
    const position = marker.getPosition();
    const pixelRatio = this.nativeMapView?.getPixelRatio?.() ?? this.pixelRatio ?? 1;
    const widthLogical = viewData.width ?? DEFAULT_VIEW_SIZE;
    const heightLogical = viewData.height ?? DEFAULT_VIEW_SIZE;
    const sourceOffset: CenterOffset = viewData.centerOffset ?? { dx: 0, dy: 0 };
    const offset: NativeViewAnnotationCenterOffset = new NativeViewAnnotationCenterOffsetImpl(
      sourceOffset.dx ?? 0,
      sourceOffset.dy ?? 0
    );

    const anchor = new NativeViewAnnotationAnchorImpl(position.latitude, position.longitude);
    const options: NativeViewAnnotationOptions = new NativeViewAnnotationOptionsImpl(anchor);
    options.width = widthLogical * pixelRatio;
    options.height = heightLogical * pixelRatio;
    options.centerOffset = offset;
    options.visible = viewData.visible;
    options.allowOverlap = true;
    options.draggable = viewData.draggable;
    options.scalesWithViewingDistance = viewData.scalesWithViewingDistance;
    options.rotatesWithCamera = viewData.rotatesToMatchCamera;
    options.minZoom = 0;
    options.maxZoom = 24;

    return options;
  }

  private syncAnnotationWithNative(marker: Marker, viewData: AnnotationViewData): void {
    if (!this.nativeMapView) {
      console.warn('[AnnotationViewManager] NativeMapView is not ready, skip annotation sync');
      return;
    }

    const markerId = marker.getId();
    const existingId = this.markerToAnnotationId.get(markerId);
    const options = this.buildNativeOptions(marker, viewData);

    try {
      if (existingId !== undefined) {
        const updated = this.nativeMapView.updateViewAnnotation(existingId, options);
        if (updated) {
          viewData.annotationId = existingId;
          return;
        }

        this.markerToAnnotationId.delete(markerId);
        this.annotationIdToMarkerId.delete(existingId);
      }

      const newId = this.nativeMapView.addViewAnnotation(options);
      if (typeof newId === 'number' && newId > 0) {
        this.markerToAnnotationId.set(markerId, newId);
        this.annotationIdToMarkerId.set(newId, markerId);
        viewData.annotationId = newId;
      } else {
        console.error('[AnnotationViewManager] addViewAnnotation returned invalid id:', newId);
      }
    } catch (error) {
      console.error('[AnnotationViewManager] Failed to sync annotation with native layer:', error);
    }
  }

  private removeAnnotationFromNative(markerId: number): void {
    if (!this.nativeMapView) {
      return;
    }

    const annotationId = this.markerToAnnotationId.get(markerId);
    if (annotationId === undefined) {
      return;
    }

    try {
      this.nativeMapView.removeViewAnnotation(annotationId);
    } catch (error) {
      console.error('[AnnotationViewManager] Failed to remove native annotation:', error);
    }

    this.markerToAnnotationId.delete(markerId);
    this.annotationIdToMarkerId.delete(annotationId);
  }

  /**
   * Return a view to the reuse pool
   */
  private returnToReusePool(viewData: AnnotationViewData): void {
    const identifier = viewData.reuseIdentifier;

    if (!this.reusePool.has(identifier)) {
      this.reusePool.set(identifier, []);
    }

    const pool: AnnotationViewData[] | undefined = this.reusePool.get(identifier);
    if (pool) {
      // Cap pool size to avoid unbounded growth
      if (pool.length < 10) {
        viewData.marker = null;
        viewData.customBuilder = null;
        viewData.annotationId = undefined;
        viewData.nativeScale = 1;
        viewData.nativeRotation = 0;
        viewData.nativeOpacity = 1;
        viewData.visible = false;
        viewData.selected = false;
        viewData.centerOffset = { dx: 0, dy: 0 };
        viewData.draggable = false;
        viewData.scalesWithViewingDistance = false;
        viewData.rotatesToMatchCamera = false;
        viewData.enabled = true;
        viewData.alpha = 1;
        viewData.zIndex = 1;
        viewData.preferredWidth = undefined;
        viewData.preferredHeight = undefined;
        pool.push(viewData);
      }
    }
  }

  /**
   * Dequeue a view from the reuse pool
   *
   * Inspired by iOS `MLNMapView.dequeueReusableAnnotationViewWithIdentifier`.
   *
   * @param identifier Reuse identifier
   * @returns Reused view data or null when none available
   */
  public dequeueReusableView(identifier: string): AnnotationViewData | null {
    const pool: AnnotationViewData[] | undefined = this.reusePool.get(identifier);

    if (pool && pool.length > 0) {
      return pool.pop() || null;
    }

    return null;
  }

  // ========== Selection management ==========

  /**
   * Set selection callback
   */
  public setOnSelectCallback(callback: (marker: Marker) => void): void {
    this.onSelectCallback = callback;
  }

  /**
   * Set deselection callback
   */
  public setOnDeselectCallback(callback: (marker: Marker) => void): void {
    this.onDeselectCallback = callback;
  }

  /**
   * Select an annotation
   */
  public selectAnnotation(marker: Marker, animated: boolean = true): void {
    const markerId = marker.getId();

    // Skip when already selected
    if (this.selectedAnnotations.has(markerId)) {
      return;
    }

    // Deselect others (single-selection mode)
    this.selectedAnnotations.forEach(id => {
      const viewData = this.annotationViews.get(id);
      // 🔒 Guard against null markers to avoid ObservedObject errors
      if (viewData && viewData.marker !== null && id !== markerId) {
        this.deselectAnnotation(viewData.marker, animated);
      }
    });

    // Track selection
    this.selectedAnnotations.add(markerId);

    // Fire callback
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
   * Deselect an annotation
   */
  public deselectAnnotation(marker: Marker, animated: boolean = true): void {
    const markerId = marker.getId();

    if (!this.selectedAnnotations.has(markerId)) {
      return;
    }

    // Remove from selection set
    this.selectedAnnotations.delete(markerId);

    // Fire callback
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
   * Deselect every annotation
   */
  public deselectAll(animated: boolean = true): void {
    const selectedIds = Array.from(this.selectedAnnotations);
    selectedIds.forEach(id => {
      const viewData = this.annotationViews.get(id);
      // 🔒 Guard against null markers to avoid ObservedObject errors
      if (viewData && viewData.marker !== null) {
        this.deselectAnnotation(viewData.marker, animated);
      }
    });
  }

  /**
   * Retrieve selected annotations
   */
  public getSelectedAnnotations(): Marker[] {
    const selected: Marker[] = [];
    this.selectedAnnotations.forEach(id => {
      const viewData = this.annotationViews.get(id);
      // 🔒 Guard against null markers to avoid ObservedObject errors
      if (viewData && viewData.marker !== null) {
        selected.push(viewData.marker);
      }
    });
    return selected;
  }

  /**
   * Check whether an annotation is selected
   */
  public isAnnotationSelected(marker: Marker): boolean {
    return this.selectedAnnotations.has(marker.getId());
  }

  // ========== Drag management ==========

  /**
   * Set drag-start callback
   */
  public setOnDragStartCallback(callback: (marker: Marker) => void): void {
    this.onDragStartCallback = callback;
  }

  /**
   * Set drag-progress callback
   */
  public setOnDragCallback(callback: (marker: Marker, screenX: number, screenY: number) => void): void {
    this.onDragCallback = callback;
  }

  /**
   * Set drag-end callback
   */
  public setOnDragEndCallback(callback: (marker: Marker, screenX: number, screenY: number) => void): void {
    this.onDragEndCallback = callback;
  }

  /**
   * Begin dragging
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
   * Update the drag position
   */
  public updateDragging(marker: Marker, screenX: number, screenY: number): void {
    if (!this.draggingAnnotation || this.draggingAnnotation.getId() !== marker.getId()) {
      return;
    }

    // Update view position
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
   * Finish dragging
   */
  public endDragging(marker: Marker, screenX: number, screenY: number): void {
    if (!this.draggingAnnotation || this.draggingAnnotation.getId() !== marker.getId()) {
      return;
    }

    // Update final position
    const viewData = this.annotationViews.get(marker.getId());
    if (viewData) {
      viewData.screenX = screenX;
      viewData.screenY = screenY;
    }

    if (this.onDragEndCallback) {
      this.onDragEndCallback(marker, screenX, screenY);
    }

    // Clear drag state
    this.draggingAnnotation = null;
    this.draggingStartPosition = null;

  }

  /**
   * Cancel dragging
   */
  public cancelDragging(marker: Marker): void {
    if (!this.draggingAnnotation || this.draggingAnnotation.getId() !== marker.getId()) {
      return;
    }

    // Restore original position
    if (this.draggingStartPosition) {
      const viewData = this.annotationViews.get(marker.getId());
      if (viewData) {
        viewData.screenX = this.draggingStartPosition.x;
        viewData.screenY = this.draggingStartPosition.y;
      }
    }

    // Clear drag state
    this.draggingAnnotation = null;
    this.draggingStartPosition = null;

  }

  /**
   * Get the annotation currently being dragged
   */
  public getDraggingAnnotation(): Marker | null {
    return this.draggingAnnotation;
  }

  /**
   * Determine whether dragging is in progress
   */
  public isDragging(): boolean {
    return this.draggingAnnotation !== null;
  }

  // ========== Batch update optimizations ==========

  /**
   * Batch update views (performance optimization)
   *
   * Reduces UI refreshes compared with updating views individually.
   *
   * @param markers Markers to refresh
   */
  public batchUpdateViews(markers: Marker[]): void {
    markers.forEach(marker => {
      this.updateView(marker);
    });
  }

  public applyNativeFrames(frames: NativeViewAnnotationFrame[]): void {
    if (!frames || frames.length === 0) {
      return;
    }

    const safePixelRatio = this.pixelRatio === 0 ? 1 : this.pixelRatio;

    frames.forEach(frame => {
      const markerId = this.annotationIdToMarkerId.get(frame.id);
      if (markerId === undefined) {
        return;
      }

      const viewData = this.annotationViews.get(markerId);
      if (!viewData || viewData.marker === null) {
        return;
      }

      viewData.annotationId = frame.id;
      viewData.screenX = frame.x / safePixelRatio;
      viewData.screenY = frame.y / safePixelRatio;
      viewData.width = Math.round(frame.width / safePixelRatio);
      viewData.height = Math.round(frame.height / safePixelRatio);
      viewData.centerOffset = {
        dx: frame.offsetX / safePixelRatio,
        dy: frame.offsetY / safePixelRatio
      };
      viewData.nativeScale = frame.scale > 0 ? frame.scale : 1;
      viewData.nativeRotation = frame.rotation;
      const opacity = frame.opacity;
      if (opacity !== undefined) {
        if (opacity <= 0) {
          viewData.nativeOpacity = 0;
        } else if (opacity >= 1) {
          viewData.nativeOpacity = 1;
        } else {
          viewData.nativeOpacity = opacity;
        }
      } else {
        viewData.nativeOpacity = 1;
      }
      viewData.pixelRatio = frame.pixelRatio;
      viewData.visible = frame.visible;
      viewData.draggable = frame.draggable;

      if (frame.pixelRatio > 0) {
        this.pixelRatio = frame.pixelRatio;
      }
    });
  }

  /**
   * Batch update positions for all visible views
   *
   * Call during map move/zoom events to efficiently refresh view positions.
   *
   * @param cameraChanged Whether the camera changed (affects transform calculations)
   */
  public batchUpdatePositions(cameraChanged: boolean = false): void {
    let updateCount = 0;
    this.annotationViews.forEach((viewData, markerId) => {
      // 🔒 Guard against null markers to avoid ObservedObject errors
      if (viewData.marker !== null) {
        const position = this.calculateScreenPosition(viewData.marker);
        viewData.screenX = position.x;
        viewData.screenY = position.y;
        updateCount++;
      }
    });

    if (updateCount > 0) {
      // External callers handle rendering callbacks
    }
  }

  /**
   * Retrieve visible views within the specified bounds
   *
   * Supports virtualization by rendering only views inside the visible screen area.
   *
   * @param bounds Screen bounds
   * @returns Array of view data inside the region
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
   * Get total view count
   *
   * @returns Number of views currently managed
   */
  public getViewCount(): number {
    return this.annotationViews.size;
  }

  /**
   * Get reuse-pool statistics
   *
   * @returns Map of reuse identifier → pool size
   */
  public getReusePoolStats(): Map<string, number> {
    const stats = new Map<string, number>();
    this.reusePool.forEach((pool, identifier) => {
      stats.set(identifier, pool.length);
    });
    return stats;
  }
}

// Helper class representing a screen coordinate
class ScreenCoord {
  x: number;
  y: number;

  constructor(x: number, y: number) {
    this.x = x;
    this.y = y;
  }
}

// Screen bounds interface
export interface ScreenBounds {
  left: number;
  top: number;
  right: number;
  bottom: number;
}

