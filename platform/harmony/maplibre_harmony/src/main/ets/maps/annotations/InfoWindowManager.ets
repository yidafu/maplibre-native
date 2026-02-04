import {
  InfoWindow,
  InfoWindowLayoutOptions,
  InfoWindowRenderContext,
  InfoWindowStyle,
  RenderDefaultInfoWindow
} from './InfoWindow';
import { InfoWindowAdapter } from './InfoWindowAdapter';
import { OnInfoWindowClickListener } from '../listeners/OnInfoWindowClickListener';
import { OnInfoWindowCloseListener } from '../listeners/OnInfoWindowCloseListener';
import { OnInfoWindowLongClickListener } from '../listeners/OnInfoWindowLongClickListener';
import { Marker } from './Marker';
import type { ViewAnnotationAddOptions, ViewAnnotationUpdateOptions } from './ViewAnnotationManager';
import { ViewAnnotationManager } from './ViewAnnotationManager';
import {
  INFO_WINDOW_VIEW_NAME,
  InfoWindowBuilderContext,
  ViewAnnotationBuilderContext,
  ViewAnnotationWrappedBuilder,
  InfoWindowWrappedBuilder
} from './ViewAnnotationTypes';
import { CenterOffset } from './AnnotationView';

interface InfoWindowAddOptions extends ViewAnnotationAddOptions {
  viewName: string;
}

interface InfoWindowUpdateOptions extends ViewAnnotationUpdateOptions {
  viewName: string;
}

/**
 * Global reference to the current InfoWindowManager instance.
 * Used by NativeViewAnnotationOverlay to get InfoWindowBuilderContext for rendering.
 */
let currentInfoWindowManager: InfoWindowManager | null = null;

/**
 * Get the current InfoWindowManager instance.
 * Used for cross-component context access during rendering.
 */
export function getInfoWindowManagerInstance(): InfoWindowManager | null {
  return currentInfoWindowManager;
}

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


interface ScreenPoint {
  x: number;
  y: number;
}
class InfoWindowContextManager {

  private ctxMap = new Map<number, InfoWindowBuilderContext>()
  registerInfoWindowContext(annotationId: number, ctx: InfoWindowBuilderContext) {
    this.ctxMap.set(annotationId, ctx)
  }
  public getInfoWindowContext(annotation: number): InfoWindowBuilderContext | null {
    return this.ctxMap.get(annotation) ?? null;
  }
  clear() {
    this.ctxMap.clear();
  }
}

const defaultCtxMap = new InfoWindowContextManager()

/**
 * InfoWindowManager - Controls InfoWindows backed by ViewAnnotations.
 */
export class InfoWindowManager {
  private infoWindowMap: Map<number, InfoWindow> = new Map();
  private adapter: InfoWindowAdapter | null = null;
  private onClickListener: OnInfoWindowClickListener | null = null;
  private onLongClickListener: OnInfoWindowLongClickListener | null = null;
  private onCloseListener: OnInfoWindowCloseListener | null = null;
  private allowConcurrentMultiple: boolean = false;
  private viewAnnotationManager: ViewAnnotationManager | null = null;
  private ctxMap: Map<number, InfoWindowBuilderContext> = new Map();

  constructor() {
    // Set as the current global instance for cross-component access
    currentInfoWindowManager = this;
  }

  /**
   * Register an InfoWindowBuilderContext for an annotation ID.
   * Called by the rendering system to enable context lookup during view updates.
   */
  registerInfoWindowContext(annotationId: number, ctx: InfoWindowBuilderContext): void {
    this.ctxMap.set(annotationId, ctx);
  }

  /**
   * Get InfoWindowBuilderContext by annotation ID.
   * Used by NativeViewAnnotationOverlay during rendering.
   */
  public getInfoWindowContext(annotationId: number): InfoWindowBuilderContext | null {
    return this.ctxMap.get(annotationId) ?? null;
  }

  /**
   * Bind the ViewAnnotationManager used to create InfoWindow annotations.
   */
  setViewAnnotationManager(manager: ViewAnnotationManager | null): void {
    if (this.viewAnnotationManager === manager) {
      return;
    }

    if (this.viewAnnotationManager) {
      this.infoWindowMap.forEach((infoWindow) => {
        const annotationId = infoWindow.getAnnotationId();
        if (annotationId > 0) {
          this.viewAnnotationManager?.removeViewAnnotation(annotationId);
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
   * This is used by NativeViewAnnotationOverlay to access context during rendering.
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
   * Show InfoWindow for a marker using the ViewAnnotation pipeline.
   */
  show(marker: Marker, options?: InfoWindowDisplayOptions, customWrappedBuilder?: InfoWindowWrappedBuilder): InfoWindow | null {
    if (!this.viewAnnotationManager) {
      console.warn('[InfoWindowManager] ViewAnnotationManager not attached, cannot show InfoWindow');
      return null;
    }

    if (!this.isValidForMarker(marker)) {
      console.warn('[InfoWindowManager] Marker has no title or snippet, cannot show InfoWindow');
      return null;
    }

    if (!this.allowConcurrentMultiple) {
      this.closeAll();
    }

    const markerId = marker.getId();
    let infoWindow = this.infoWindowMap.get(markerId);
    if (!infoWindow) {
      const renderContext: InfoWindowRenderContext = {
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
          this.handleSizeChanged(infoWindow!, width, height);
        },
      };
      infoWindow = new InfoWindow(marker, renderContext, options?.style, customWrappedBuilder);
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
    infoWindow.setLayoutOptions(layoutOptions);


    const activeInfoWindow = infoWindow;
    const wrappedBuilder = infoWindow.getWrappedBuilder()
    const markerPosition = marker.getPosition();
    const layout = activeInfoWindow.getLayoutOptions();

    const existingId = activeInfoWindow.getAnnotationId();
    let annotationId = existingId;
    if (existingId > 0) {
      try {
        const updateOptions = {
          anchor: markerPosition,
          wrappedBuilder: wrappedBuilder,
          viewName: INFO_WINDOW_VIEW_NAME,
          width: this.resolveDimensionForUpdate(activeInfoWindow.getWidth()),
          height: this.resolveDimensionForUpdate(activeInfoWindow.getHeight()),
          anchorHeight: layout.anchorHeight ?? null,
          centerOffset: layout.centerOffset ?? null,
          visible: true,
          zIndex: layout.zIndex ?? null
        } as InfoWindowUpdateOptions;
        this.viewAnnotationManager.updateViewAnnotation(existingId, updateOptions);
      } catch (error) {
        const reason = error instanceof Error ? error.message : `${error}`;
        console.error('[InfoWindowManager] updateViewAnnotation failed: ', reason);
      }
    } else {
      const estimatedSize = activeInfoWindow.estimateSize();

      // Register context BEFORE addViewAnnotation to ensure it's available during render callback
      // Use a unique temporary key based on the marker ID since annotation ID isn't known yet
      const tempContextKey = markerId;
      const tempContext = new InfoWindowBuilderContext(activeInfoWindow, infoWindow.getRenderContext());
      this.registerInfoWindowContext(tempContextKey, tempContext);

      const addOptions = {
        anchor: markerPosition,
        wrappedBuilder: wrappedBuilder,
        viewName: INFO_WINDOW_VIEW_NAME,
        width: this.resolveDimensionForAdd(activeInfoWindow.getWidth(), estimatedSize.width),
        height: this.resolveDimensionForAdd(activeInfoWindow.getHeight(), estimatedSize.height),
        anchorHeight: layout.anchorHeight,
        centerOffset: layout.centerOffset,
        visible: true,
        allowOverlap: true,
        draggable: false,
        anchorU: layout.anchorU,
        anchorV: layout.anchorV,
        zIndex: layout.zIndex
      } as InfoWindowAddOptions;
      try {
        // Also register with ViewAnnotationManager for access during initial render callback
        // This ensures context is available when refreshRenderStates() is called inside addViewAnnotation()
        this.viewAnnotationManager.registerContextForAnnotation(-1, tempContext);

        annotationId = this.viewAnnotationManager.addViewAnnotation(addOptions);
        if (annotationId <= 0) {
          console.error('[InfoWindowManager] Failed to add ViewAnnotation for InfoWindow');
          this.ctxMap.delete(tempContextKey); // Clean up temp context
          return null;
        }
        activeInfoWindow.setAnnotationId(annotationId);

        // Re-register context with the real annotation ID
        // This ensures subsequent render callbacks use the correct ID
        const finalContext = new InfoWindowBuilderContext(activeInfoWindow, infoWindow.getRenderContext());
        this.registerInfoWindowContext(annotationId, finalContext);
        this.ctxMap.delete(tempContextKey); // Clean up temp context

        // Trigger a re-render to ensure the InfoWindow content is rendered with the correct context
        // The first render happened before context was registered, so we need to trigger another one
        this.viewAnnotationManager.refreshRenderStates();
      } catch (error) {
        const reason = error instanceof Error ? error.message : `${error}`;
        console.error('[InfoWindowManager] addViewAnnotation failed: ', reason);
        this.ctxMap.delete(tempContextKey); // Clean up temp context
        return null;
      }
    }

    // Register the InfoWindowBuilderContext for rendering
    const builderContext = new InfoWindowBuilderContext(activeInfoWindow, infoWindow.getRenderContext());
    this.registerInfoWindowContext(annotationId, builderContext);

    activeInfoWindow.setVisible(true);
    return activeInfoWindow;
  }

  /**
   * Close InfoWindow for specific marker.
   */
  close(marker: Marker): void {
    const infoWindow = this.infoWindowMap.get(marker.getId());
    if (!infoWindow || !infoWindow.isShown()) {
      return;
    }

    const annotationId = infoWindow.getAnnotationId();
    if (annotationId > 0) {
      if (this.viewAnnotationManager) {
        this.viewAnnotationManager.removeViewAnnotation(annotationId);
      }
      // Clean up the registered context
      this.ctxMap.delete(annotationId);
    }

    infoWindow.resetAnnotation();
    infoWindow.setVisible(false);

    if (this.onCloseListener) {
      this.onCloseListener.onInfoWindowClose(marker);
    }
  }

  /**
   * Close all InfoWindows.
   */
  closeAll(): void {
    this.infoWindowMap.forEach((infoWindow) => {
      if (infoWindow.isShown()) {
        const marker = infoWindow.getMarker();
        this.close(marker);
      }
    });
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
    _getMarkerScreenPosition: (marker: Marker) => ScreenPoint): void {
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
   * Update the custom wrapped builder of an already visible InfoWindow.
   */
  public updateCustomWrappedBuilder(marker: Marker, builder: InfoWindowWrappedBuilder | null): boolean {
    const infoWindow = this.infoWindowMap.get(marker.getId());
    if (!infoWindow || !infoWindow.isShown()) {
      return false;
    }

    infoWindow.setCustomWrappedBuilder(builder);

    if (infoWindow.getAnnotationId() > 0) {
      const updateOptions: ViewAnnotationUpdateOptions = {
        wrappedBuilder: infoWindow.getWrappedBuilder() as ViewAnnotationWrappedBuilder,
        viewName: INFO_WINDOW_VIEW_NAME
      };
      return this.viewAnnotationManager?.updateViewAnnotation(
        infoWindow.getAnnotationId(),
        updateOptions
      ) ?? false;
    }

    return true;
  }

  private handleSizeChanged(infoWindow: InfoWindow, width: number, height: number): void {
    if (!this.viewAnnotationManager) {
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

  private resolveDimensionForAdd(measured: number, fallback: number): number | undefined {
    if (measured > 0) {
      return measured;
    }
    if (fallback > 0) {
      return fallback;
    }
    return undefined;
  }

  private resolveDimensionForUpdate(value: number): number | undefined {
    return value > 0 ? value : undefined;
  }



}

