import {
  InfoWindow,
  InfoWindowLayoutOptions,
  InfoWindowRenderContext,
  InfoWindowStyle
} from './InfoWindow';
import { InfoWindowAdapter } from './InfoWindowAdapter';
import { OnInfoWindowClickListener } from '../listeners/OnInfoWindowClickListener';
import { OnInfoWindowCloseListener } from '../listeners/OnInfoWindowCloseListener';
import { OnInfoWindowLongClickListener } from '../listeners/OnInfoWindowLongClickListener';
import { Marker } from './Marker';
import type { ViewAnnotationAddOptions, ViewAnnotationUpdateOptions } from './ViewAnnotationManager';
import { ViewAnnotationManager } from './ViewAnnotationManager';
import { INFO_WINDOW_VIEW_NAME } from './ViewAnnotationTypes';
import { CenterOffset } from './AnnotationView';
import type { ComponentContent, UIContext } from '@kit.ArkUI';
import { ComponentContentRegistry } from './ComponentContentRegistry';

/**
 * Options supplied when displaying an InfoWindow via the manager.
 */
export interface InfoWindowDisplayOptions {
  style?: InfoWindowStyle;
  centerOffset?: CenterOffset;
  anchorHeight?: number;  // Height for anchor positioning (e.g., marker icon height)
  anchorU?: number;
  anchorV?: number;
  zIndex?: number;
}

/**
 * InfoWindowManager - Controls InfoWindows backed by ViewAnnotations.
 *
 * Uses ComponentContent + the per-instance ComponentContentRegistry owned by
 * its ViewAnnotationManager for rendering, so that both default and custom
 * InfoWindows use the same pipeline. Each MapLibreMap owns one manager, so
 * multiple map instances do not share annotation state.
 */
interface MarkerSourcePosition {
  x: number;
  y: number;
}

export class InfoWindowManager {
  private infoWindowMap: Map<number, InfoWindow> = new Map();
  private adapter: InfoWindowAdapter | null = null;
  private onClickListener: OnInfoWindowClickListener | null = null;
  private onLongClickListener: OnInfoWindowLongClickListener | null = null;
  private onCloseListener: OnInfoWindowCloseListener | null = null;
  private allowConcurrentMultiple: boolean = false;
  private viewAnnotationManager: ViewAnnotationManager | null = null;
  private uiContext: UIContext | null = null;

  /**
   * Set the UIContext required for creating ComponentContent instances.
   * Must be called before any InfoWindow is shown.
   */
  setUIContext(uiContext: UIContext | null): void {
    this.uiContext = uiContext;
  }

  /**
   * Get the current UIContext (may be null if not yet set).
   */
  getUIContext(): UIContext | null {
    return this.uiContext;
  }

  /**
   * Bind the ViewAnnotationManager used to create InfoWindow annotations.
   */
  setViewAnnotationManager(manager: ViewAnnotationManager | null): void {
    if (this.viewAnnotationManager === manager) {
      return;
    }

    if (this.viewAnnotationManager) {
      const registry = this.getContentRegistry();
      this.infoWindowMap.forEach((infoWindow) => {
        const annotationId = infoWindow.getAnnotationId();
        if (annotationId > 0) {
          this.viewAnnotationManager?.removeViewAnnotation(annotationId);
          registry?.remove(annotationId);
        }
        infoWindow.resetAnnotation();
        infoWindow.setVisible(false);
      });
    }

    this.viewAnnotationManager = manager;
  }

  /**
   * Assign InfoWindowAdapter.
   */
  setAdapter(adapter: InfoWindowAdapter | null): void {
    this.adapter = adapter;
  }

  /**
   * Retrieve InfoWindowAdapter.
   */
  getAdapter(): InfoWindowAdapter | null {
    return this.adapter;
  }

  /**
   * Get the ViewAnnotationManager instance.
   */
  getViewAnnotationManager(): ViewAnnotationManager | null {
    return this.viewAnnotationManager;
  }

  /**
   * Set click listener.
   */
  setOnClickListener(listener: OnInfoWindowClickListener | null): void {
    this.onClickListener = listener;
  }

  /**
   * Get click listener.
   */
  getOnClickListener(): OnInfoWindowClickListener | null {
    return this.onClickListener;
  }

  /**
   * Set long-click listener.
   */
  setOnLongClickListener(listener: OnInfoWindowLongClickListener | null): void {
    this.onLongClickListener = listener;
  }

  /**
   * Get long-click listener.
   */
  getOnLongClickListener(): OnInfoWindowLongClickListener | null {
    return this.onLongClickListener;
  }

  /**
   * Set close listener.
   */
  setOnCloseListener(listener: OnInfoWindowCloseListener | null): void {
    this.onCloseListener = listener;
  }

  /**
   * Get close listener.
   */
  getOnCloseListener(): OnInfoWindowCloseListener | null {
    return this.onCloseListener;
  }

  /**
   * Control whether multiple InfoWindows may be shown simultaneously.
   */
  setAllowConcurrentMultiple(allow: boolean): void {
    this.allowConcurrentMultiple = allow;
  }

  /**
   * Check whether multiple InfoWindows are allowed simultaneously.
   */
  isAllowConcurrentMultiple(): boolean {
    return this.allowConcurrentMultiple;
  }

  /**
   * Show InfoWindow for a marker using the ViewAnnotation + ComponentContent pipeline.
   *
   * Idempotent: showing an already-shown marker updates the existing annotation
   * in place instead of tearing it down. The adapter is re-consulted on every
   * show (Android InfoWindowAdapter semantics) and default content params are
   * refreshed, so marker/style edits take effect on the next show.
   *
   * @param marker The marker to show InfoWindow for.
   * @param options Display options (style, offsets, anchor).
   * @returns The InfoWindow descriptor, or null on failure.
   */
  show(marker: Marker, options?: InfoWindowDisplayOptions): InfoWindow | null {
    if (!this.viewAnnotationManager) {
      console.warn('[InfoWindowManager] ViewAnnotationManager not attached, cannot show InfoWindow');
      return null;
    }

    if (!this.isValidForMarker(marker)) {
      console.warn('[InfoWindowManager] Marker has no title or snippet, cannot show InfoWindow');
      return null;
    }

    if (!this.allowConcurrentMultiple) {
      this.closeAllExcept(marker);
    }

    const markerId = marker.getId();
    let infoWindow = this.infoWindowMap.get(markerId);
    if (!infoWindow) {
      infoWindow = new InfoWindow(marker, this.createRenderContext(marker), options?.style);
      this.infoWindowMap.set(markerId, infoWindow);
    } else if (options?.style) {
      infoWindow.setStyle(options.style);
    }

    const layoutOptions: InfoWindowLayoutOptions = {
      centerOffset: options?.centerOffset,
      anchorU: options?.anchorU,
      anchorV: options?.anchorV,
      zIndex: options?.zIndex
    };
    if (options?.anchorHeight !== undefined) {
      layoutOptions.anchorHeight = options.anchorHeight;
    }
    infoWindow.setLayoutOptions(layoutOptions);

    // Resolve content on every show: consult the adapter, or refresh the
    // default ComponentContent params (title/snippet/style) via update().
    const content = this.resolveContent(infoWindow);

    const existingId = infoWindow.getAnnotationId();
    if (infoWindow.isShown() && existingId > 0) {
      this.updateShownAnnotation(infoWindow, content);
    } else {
      const createdId = this.createAnnotation(infoWindow, content);
      if (createdId <= 0) {
        return null;
      }
    }

    infoWindow.setVisible(true);
    return infoWindow;
  }

  /**
   * Close InfoWindow for specific marker.
   *
   * The cached descriptor is removed so marker removals do not leak
   * InfoWindow/ComponentContent references; the adapter is re-consulted and
   * style re-applied on the next show().
   */
  close(marker: Marker): void {
    const infoWindow = this.infoWindowMap.get(marker.getId());
    if (!infoWindow) {
      return;
    }
    this.infoWindowMap.delete(marker.getId());

    const wasShown = infoWindow.isShown();
    const annotationId = infoWindow.getAnnotationId();
    if (annotationId > 0) {
      if (this.viewAnnotationManager) {
        this.viewAnnotationManager.removeViewAnnotation(annotationId);
      }
      this.getContentRegistry()?.remove(annotationId);
    }

    infoWindow.resetAnnotation();
    infoWindow.setVisible(false);

    if (wasShown && this.onCloseListener) {
      this.onCloseListener.onInfoWindowClose(marker);
    }
  }

  /**
   * Close all InfoWindows.
   */
  closeAll(): void {
    this.closeAllExcept(null);
  }

  /**
   * Tear down the manager: close all windows, drop cached descriptors and
   * detach adapter/listeners/UIContext. Called from MapLibreMap.destroy().
   */
  destroy(): void {
    this.closeAll();
    this.infoWindowMap.clear();
    this.adapter = null;
    this.onClickListener = null;
    this.onLongClickListener = null;
    this.onCloseListener = null;
    this.uiContext = null;
    this.setViewAnnotationManager(null);
  }

  private closeAllExcept(keep: Marker | null): void {
    const entries: InfoWindow[] = [];
    this.infoWindowMap.forEach((infoWindow) => {
      entries.push(infoWindow);
    });
    entries.forEach((infoWindow) => {
      if (!keep || infoWindow.getMarker().getId() !== keep.getId()) {
        this.close(infoWindow.getMarker());
      }
    });
  }

  private createRenderContext(marker: Marker): InfoWindowRenderContext {
    return {
      onWindowClick: () => {
        if (this.onClickListener) {
          this.onClickListener.onInfoWindowClick(marker);
        }
      },
      onLongClick: () => {
        if (this.onLongClickListener) {
          this.onLongClickListener.onInfoWindowLongClick(marker);
        }
      },
      onClose: () => {
        this.close(marker);
      },
      onSizeChanged: (width: number, height: number) => {
        this.handleSizeChanged(marker, width, height);
      },
    };
  }

  /**
   * Consult the adapter (if any) and refresh the InfoWindow content.
   * Returns the ComponentContent that should be rendered, or null when no
   * content could be created (e.g. UIContext not set yet).
   */
  private resolveContent(infoWindow: InfoWindow): ComponentContent<Object> | null {
    let custom: ComponentContent<Object> | null = null;
    if (this.adapter && this.uiContext) {
      try {
        custom = this.adapter.getInfoWindow(infoWindow.getMarker(), this.uiContext);
      } catch (error) {
        const reason = error instanceof Error ? error.message : `${error}`;
        console.error(`[InfoWindowManager] Adapter getInfoWindow failed: ${reason}`);
        custom = null;
      }
    }
    infoWindow.setCustomComponentContent(custom);
    return infoWindow.getComponentContent(this.uiContext);
  }

  private updateShownAnnotation(infoWindow: InfoWindow, content: ComponentContent<Object> | null): void {
    const annotationId = infoWindow.getAnnotationId();
    const markerPosition = infoWindow.getMarker().getPosition();
    const layout = infoWindow.getLayoutOptions();

    try {
      const updateOptions = {
        anchor: markerPosition,
        viewName: INFO_WINDOW_VIEW_NAME,
        width: this.resolveDimension(infoWindow.getWidth()),
        height: this.resolveDimension(infoWindow.getHeight()),
        anchorHeight: layout.anchorHeight ?? null,
        centerOffset: layout.centerOffset ?? null,
        visible: true,
        zIndex: layout.zIndex ?? null
      } as ViewAnnotationUpdateOptions;
      this.viewAnnotationManager?.updateViewAnnotation(annotationId, updateOptions);
    } catch (error) {
      const reason = error instanceof Error ? error.message : `${error}`;
      console.error('[InfoWindowManager] updateViewAnnotation failed: ', reason);
    }

    if (content) {
      this.getContentRegistry()?.register(annotationId, content);
    }
  }

  private createAnnotation(infoWindow: InfoWindow, content: ComponentContent<Object> | null): number {
    const markerPosition = infoWindow.getMarker().getPosition();
    const layout = infoWindow.getLayoutOptions();
    const estimatedSize = infoWindow.estimateSize();

    const addOptions = {
      anchor: markerPosition,
      viewName: INFO_WINDOW_VIEW_NAME,
      width: this.resolveDimension(infoWindow.getWidth(), estimatedSize.width),
      height: this.resolveDimension(infoWindow.getHeight(), estimatedSize.height),
      anchorHeight: layout.anchorHeight,
      centerOffset: layout.centerOffset,
      visible: true,
      allowOverlap: true,
      draggable: false,
      anchorU: layout.anchorU,
      anchorV: layout.anchorV,
      zIndex: layout.zIndex
    } as ViewAnnotationAddOptions;

    try {
      const annotationId = this.viewAnnotationManager?.addViewAnnotation(addOptions) ?? -1;
      if (annotationId <= 0) {
        console.error('[InfoWindowManager] Failed to add ViewAnnotation for InfoWindow');
        return -1;
      }
      infoWindow.setAnnotationId(annotationId);

      if (content) {
        this.getContentRegistry()?.register(annotationId, content);
      } else {
        console.warn('[InfoWindowManager] No ComponentContent available for InfoWindow (UIContext not set?)');
      }

      // Trigger a re-render to ensure the overlay picks up the new annotation
      this.viewAnnotationManager?.refreshRenderStates();
      return annotationId;
    } catch (error) {
      const reason = error instanceof Error ? error.message : `${error}`;
      console.error('[InfoWindowManager] addViewAnnotation failed: ', reason);
      return -1;
    }
  }

  /**
   * Determine whether marker has InfoWindow content.
   */
  isValidForMarker(marker: Marker): boolean {
    const title = marker.getTitle();
    const snippet = marker.getSnippet();
    const hasTitle = title ? title.length > 0 : false;
    const hasSnippet = snippet ? snippet.length > 0 : false;
    return hasTitle || hasSnippet;
  }

  /**
   * Retrieve InfoWindow for marker.
   */
  get(marker: Marker): InfoWindow | null {
    return this.infoWindowMap.get(marker.getId()) || null;
  }

  /**
   * Update positions for all visible InfoWindows (no-op with ViewAnnotations).
   */
  updatePositions(_screenWidth: number, _screenHeight: number,
    _getMarkerScreenPosition: (marker: Marker) => MarkerSourcePosition): void {
    // ViewAnnotations are automatically positioned by the native engine.
  }

  /**
   * Trigger InfoWindow click event.
   */
  triggerClick(marker: Marker): boolean {
    if (this.onClickListener) {
      this.onClickListener.onInfoWindowClick(marker);
      return true;
    }
    return false;
  }

  /**
   * Trigger InfoWindow long-click event.
   */
  triggerLongClick(marker: Marker): boolean {
    if (this.onLongClickListener) {
      this.onLongClickListener.onInfoWindowLongClick(marker);
      return true;
    }
    return false;
  }

  /**
   * Get all visible InfoWindows.
   */
  getVisibleInfoWindows(): InfoWindow[] {
    const visible: InfoWindow[] = [];
    this.infoWindowMap.forEach(infoWindow => {
      if (infoWindow.isShown()) {
        visible.push(infoWindow);
      }
    });
    return visible;
  }

  /**
   * Update the custom ComponentContent of an already visible InfoWindow.
   * Pass null to revert the visible window to the default rendering.
   */
  public updateCustomComponentContent(marker: Marker, content: ComponentContent<Object> | null): boolean {
    const infoWindow = this.infoWindowMap.get(marker.getId());
    if (!infoWindow || !infoWindow.isShown()) {
      return false;
    }

    infoWindow.setCustomComponentContent(content);
    const resolved = infoWindow.getComponentContent(this.uiContext);

    const annotationId = infoWindow.getAnnotationId();
    if (annotationId > 0 && resolved) {
      this.getContentRegistry()?.register(annotationId, resolved);
      this.viewAnnotationManager?.refreshRenderStates();
      return true;
    }

    return false;
  }

  /**
   * Refresh the content of a currently shown InfoWindow after marker or style
   * edits (e.g. marker.setTitle / setSnippet / InfoWindow.setStyle).
   */
  public refreshContent(marker: Marker): boolean {
    const infoWindow = this.infoWindowMap.get(marker.getId());
    if (!infoWindow || !infoWindow.isShown()) {
      return false;
    }

    const content = this.resolveContent(infoWindow);
    const annotationId = infoWindow.getAnnotationId();
    if (annotationId > 0 && content) {
      this.getContentRegistry()?.register(annotationId, content);
      this.viewAnnotationManager?.refreshRenderStates();
    }
    return true;
  }

  private getContentRegistry(): ComponentContentRegistry | null {
    return this.viewAnnotationManager?.getContentRegistry() ?? null;
  }

  /**
   * Apply a content size reported by onAreaChange to the native annotation.
   * Sub-epsilon changes are deduplicated to avoid native update storms.
   */
  private handleSizeChanged(marker: Marker, width: number, height: number): void {
    if (!this.viewAnnotationManager) {
      return;
    }
    const infoWindow = this.infoWindowMap.get(marker.getId());
    if (!infoWindow || !infoWindow.updateSize(width, height)) {
      return;
    }
    const annotationId = infoWindow.getAnnotationId();
    if (annotationId <= 0) {
      return;
    }
    const updateOptions: ViewAnnotationUpdateOptions = {
      width: width,
      height: height
    };
    this.viewAnnotationManager.updateViewAnnotation(annotationId, updateOptions);
  }

  private resolveDimension(measured: number, fallback?: number): number | undefined {
    if (measured > 0) {
      return measured;
    }
    if (fallback !== undefined && fallback > 0) {
      return fallback;
    }
    return undefined;
  }
}
