import { InfoWindow, InfoWindowBuildContext, InfoWindowLayoutOptions, InfoWindowStyle, InfoWindowRenderContext, RenderCustomInfoWindow, RenderDefaultInfoWindow } from './InfoWindow';
import { InfoWindowAdapter } from './InfoWindowAdapter';
import { OnInfoWindowClickListener } from '../listeners/OnInfoWindowClickListener';
import { OnInfoWindowCloseListener } from '../listeners/OnInfoWindowCloseListener';
import { OnInfoWindowLongClickListener } from '../listeners/OnInfoWindowLongClickListener';
import { Marker } from './Marker';
import { ViewAnnotationManager } from './ViewAnnotationManager';
import type { ViewAnnotationAddOptions, ViewAnnotationUpdateOptions } from './ViewAnnotationManager';
import {
  INFO_WINDOW_VIEW_NAME,
  ViewAnnotationBuilderContext,
  ViewAnnotationWrappedBuilder,
  InfoWindowBuilderContext
} from './ViewAnnotationTypes';
import { CenterOffset } from './AnnotationView';
interface InfoWindowAddOptions extends ViewAnnotationAddOptions {
  viewName: string;
}

interface InfoWindowUpdateOptions extends ViewAnnotationUpdateOptions {
  viewName: string;
}

/**
 * Options supplied when displaying an InfoWindow via the manager.
 */
export interface InfoWindowDisplayOptions {
  style?: InfoWindowStyle;
  centerOffset?: CenterOffset;
  anchorU?: number;
  anchorV?: number;
  zIndex?: number;
}

interface InfoWindowBuilderPayload {
  infoWindow: InfoWindow;
  renderContext: InfoWindowRenderContext;
  customBuilder: (() => void) | null;
  notifySizeChanged: (width: number, height: number) => void;
}

const INFO_WINDOW_WRAPPED_BUILDER_INSTANCE: ViewAnnotationWrappedBuilder =
  wrapBuilder<[ViewAnnotationBuilderContext]>(InfoWindowWrappedBuilderEntry);

const infoWindowBuilderPayloads: Map<number, InfoWindowBuilderPayload> = new Map();

function setInfoWindowBuilderPayload(id: number, payload: InfoWindowBuilderPayload): void {
  if (id <= 0) {
    return;
  }
  infoWindowBuilderPayloads.set(id, payload);
}

function getInfoWindowBuilderPayload(id: number): InfoWindowBuilderPayload | undefined {
  if (id <= 0) {
    return undefined;
  }
  return infoWindowBuilderPayloads.get(id);
}

function clearInfoWindowBuilderPayload(id: number): void {
  if (id <= 0) {
    return;
  }
  infoWindowBuilderPayloads.delete(id);
}

interface ScreenPoint {
  x: number;
  y: number;
}

/**
 * InfoWindowManager - Controls InfoWindows backed by ViewAnnotations.
 */
export class InfoWindowManager {
  private infoWindows: Map<number, InfoWindow> = new Map();
  private adapter: InfoWindowAdapter | null = null;
  private onClickListener: OnInfoWindowClickListener | null = null;
  private onLongClickListener: OnInfoWindowLongClickListener | null = null;
  private onCloseListener: OnInfoWindowCloseListener | null = null;
  private allowConcurrentMultiple: boolean = false;
  private viewAnnotationManager: ViewAnnotationManager | null = null;

  /**
   * Bind the ViewAnnotationManager used to create InfoWindow annotations.
   */
  setViewAnnotationManager(manager: ViewAnnotationManager | null): void {
    if (this.viewAnnotationManager === manager) {
      return;
    }

    if (this.viewAnnotationManager) {
      this.infoWindows.forEach((infoWindow) => {
        const annotationId = infoWindow.getAnnotationId();
        if (annotationId > 0) {
          this.viewAnnotationManager?.removeViewAnnotation(annotationId);
          this.removeInfoWindowBuilderPayload(annotationId);
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
      this.closeAll();
    }

    const markerId = marker.getId();
    let infoWindow = this.infoWindows.get(markerId);

    if (!infoWindow) {
      infoWindow = new InfoWindow(marker, options?.style);
      this.infoWindows.set(markerId, infoWindow);
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

    const customBuilder = this.adapter?.getInfoWindow(marker) ?? null;
    const builderContext: InfoWindowBuildContext = {
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
      customContentBuilder: customBuilder
    };
    const renderContext: InfoWindowRenderContext = {
      onWindowClick: builderContext.onWindowClick,
      onLongClick: builderContext.onLongClick,
      onClose: builderContext.onClose,
      onSizeChanged: builderContext.onSizeChanged
    };
    const activeInfoWindow = infoWindow;
    const payload = this.buildInfoWindowBuilderPayload(activeInfoWindow, renderContext, customBuilder);
    const wrappedBuilder = this.getInfoWindowWrappedBuilder();
    const markerPosition = marker.getPosition();
    const layout = activeInfoWindow.getLayoutOptions();

    const existingId = activeInfoWindow.getAnnotationId();
    if (existingId > 0) {
      try {
        this.registerInfoWindowBuilderPayload(existingId, payload);
        const updateOptions = {
          anchor: markerPosition,
          wrappedBuilder: wrappedBuilder,
          viewName: INFO_WINDOW_VIEW_NAME,
          width: this.resolveDimensionForUpdate(activeInfoWindow.getWidth()),
          height: this.resolveDimensionForUpdate(activeInfoWindow.getHeight()),
          centerOffset: layout.centerOffset ?? null,
          visible: true,
          zIndex: layout.zIndex ?? null
        } as InfoWindowUpdateOptions;
        this.viewAnnotationManager.updateViewAnnotation(existingId, updateOptions);
      } catch (error) {
        const reason = error instanceof Error ? error.message : `${error}`;
        console.error('[InfoWindowManager] updateViewAnnotation failed: ', reason);
        return null;
      }
    } else {
      const estimatedSize = activeInfoWindow.estimateSize();
      const addOptions = {
        anchor: markerPosition,
        wrappedBuilder: wrappedBuilder,
        viewName: INFO_WINDOW_VIEW_NAME,
        width: this.resolveDimensionForAdd(activeInfoWindow.getWidth(), estimatedSize.width),
        height: this.resolveDimensionForAdd(activeInfoWindow.getHeight(), estimatedSize.height),
        centerOffset: layout.centerOffset,
        visible: true,
        allowOverlap: true,
        draggable: false,
        anchorU: layout.anchorU,
        anchorV: layout.anchorV,
        zIndex: layout.zIndex
      } as InfoWindowAddOptions;
      try {
        const annotationId = this.viewAnnotationManager.addViewAnnotation(addOptions);
        if (annotationId <= 0) {
          console.error('[InfoWindowManager] Failed to add ViewAnnotation for InfoWindow');
          return null;
        }
        activeInfoWindow.setAnnotationId(annotationId);
        this.registerInfoWindowBuilderPayload(annotationId, payload);
      } catch (error) {
        const reason = error instanceof Error ? error.message : `${error}`;
        console.error('[InfoWindowManager] addViewAnnotation failed: ', reason);
        return null;
      }
    }

    activeInfoWindow.setVisible(true);
    return activeInfoWindow;
  }

  /**
   * Close InfoWindow for specific marker.
   */
  close(marker: Marker): void {
    const infoWindow = this.infoWindows.get(marker.getId());
    if (!infoWindow || !infoWindow.isShown()) {
      return;
    }

    const annotationId = infoWindow.getAnnotationId();
    if (annotationId > 0) {
      if (this.viewAnnotationManager) {
        this.viewAnnotationManager.removeViewAnnotation(annotationId);
      }
      this.removeInfoWindowBuilderPayload(annotationId);
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
    this.infoWindows.forEach((infoWindow) => {
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
    return this.infoWindows.get(marker.getId()) || null;
  }

  /**
   * Update positions for all visible InfoWindows (no-op with ViewAnnotations).
   */
  updatePositions(_screenWidth: number, _screenHeight: number, _getMarkerScreenPosition: (marker: Marker) => ScreenPoint): void {
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
    this.infoWindows.forEach(infoWindow => {
      if (infoWindow.isShown()) {
        visible.push(infoWindow);
      }
    });
    return visible;
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

  private buildInfoWindowBuilderPayload(
    infoWindow: InfoWindow,
    renderContext: InfoWindowRenderContext,
    customBuilder: (() => void) | null
  ): InfoWindowBuilderPayload {
    const notifySizeChanged = (width: number, height: number): void => {
      const changed = infoWindow.updateSize(width, height);
      if (changed && renderContext.onSizeChanged) {
        renderContext.onSizeChanged(width, height);
      }
    };
    return {
      infoWindow,
      renderContext,
      customBuilder,
      notifySizeChanged
    };
  }

  private registerInfoWindowBuilderPayload(annotationId: number, payload: InfoWindowBuilderPayload): void {
    setInfoWindowBuilderPayload(annotationId, payload);
  }

  private removeInfoWindowBuilderPayload(annotationId: number): void {
    clearInfoWindowBuilderPayload(annotationId);
  }

  private getInfoWindowWrappedBuilder(): ViewAnnotationWrappedBuilder {
    return INFO_WINDOW_WRAPPED_BUILDER_INSTANCE;
  }
}

@Builder
function InfoWindowWrappedBuilderEntry(ctx: ViewAnnotationBuilderContext): void {
  renderInfoWindowBuilderEntry(ctx);
}

function renderInfoWindowBuilderEntry(ctx: ViewAnnotationBuilderContext): void {
  const payload = prepareInfoWindowBuilderPayload(ctx);
  if (!payload) {
    return;
  }
  RenderInfoWindowContent(payload);
}

function prepareInfoWindowBuilderPayload(ctx: ViewAnnotationBuilderContext): InfoWindowBuilderPayload | null {
  if (!(ctx instanceof InfoWindowBuilderContext)) {
    return null;
  }
  const infoCtx: InfoWindowBuilderContext = ctx;
  const payload = getInfoWindowBuilderPayload(infoCtx.annotationId);
  if (!payload) {
    return null;
  }
  const marker = payload.infoWindow.getMarker();
  infoCtx.markerId = marker.getId();
  infoCtx.title = marker.getTitle() ?? '';
  infoCtx.content = marker.getSnippet() ?? '';
  infoCtx.notifySizeChanged = payload.notifySizeChanged;
  return payload;
}

@Builder
function RenderInfoWindowContent(payload: InfoWindowBuilderPayload): void {
  if (payload.customBuilder) {
    RenderCustomInfoWindow(payload.renderContext, payload.notifySizeChanged, payload.customBuilder);
  } else {
    RenderDefaultInfoWindow(payload.infoWindow, payload.renderContext, payload.notifySizeChanged);
  }
}
