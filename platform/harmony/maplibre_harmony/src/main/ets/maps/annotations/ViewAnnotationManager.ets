import { NativeMapView } from 'libmaplibre.so';
import type { ComponentContent } from '@kit.ArkUI';
import { LatLng } from '../geometry/LatLng';
import {
  NativeViewAnnotationAnchorImpl,
  NativeViewAnnotationCenterOffsetImpl,
  NativeViewAnnotationFrame,
  NativeViewAnnotationOptions,
  NativeViewAnnotationOptionsImpl
} from './NativeViewAnnotationTypes';
import { ViewAnnotationRenderState } from './NativeViewAnnotationOverlay';
import { ComponentContentRegistry } from './ComponentContentRegistry';
import { CenterOffset } from './ViewAnnotationUtils';
import { ViewAnnotationHandle } from './ViewAnnotationHandle';
import { normalizeOpacity, resolveFramePixelRatio } from './ViewAnnotationUtils';

/**
 * Configuration options for creating a ViewAnnotation via ViewAnnotationManager.
 *
 * Sizing model: width/height are OPTIONAL constraints. When omitted the
 * annotation runs in auto-size mode — the SDK measures the rendered content
 * and feeds the measured size back to the positioning engine, so anchorU/
 * anchorV always anchor the true content bounds. When provided, the content
 * is constrained to that size and no measurement feedback is applied.
 */
export interface ViewAnnotationAddOptions {
  /** Geographic coordinate the annotation is pinned to. Required. */
  anchor: LatLng;
  /** Logical tag identifying the annotation kind in the overlay. */
  viewName?: string;
  /** Optional fixed width constraint, logical pixels. */
  width?: number;
  /** Optional fixed height constraint, logical pixels. */
  height?: number;
  /** Extra offset from the anchor point, logical pixels. */
  centerOffset?: CenterOffset;
  visible?: boolean;
  /**
   * Scale the annotation with camera pitch (approximate: 1/cos(pitch),
   * uniform for all annotations — not a per-position perspective scale).
   */
  scalesWithViewingDistance?: boolean;
  /** Rotate the annotation with the camera bearing. */
  rotatesWithCamera?: boolean;
  minZoom?: number;
  maxZoom?: number;
  /** Horizontal anchor of the annotation content, 0 (left) .. 1 (right). */
  anchorU?: number;
  /** Vertical anchor of the annotation content, 0 (top) .. 1 (bottom). */
  anchorV?: number;
  /** Stacking order among annotations in the overlay. */
  zIndex?: number;
}

/**
 * Partial configuration used when updating an existing ViewAnnotation.
 *
 * width/height semantics mirror ViewAnnotationAddOptions: passing a value
 * switches the annotation to fixed-size (constrained) mode; pass null to
 * clear a constraint and return to auto-size mode.
 */
export interface ViewAnnotationUpdateOptions {
  anchor?: LatLng;
  viewName?: string;
  width?: number | null;
  height?: number | null;
  centerOffset?: CenterOffset | null;
  visible?: boolean;
  scalesWithViewingDistance?: boolean;
  rotatesWithCamera?: boolean;
  minZoom?: number | null;
  maxZoom?: number | null;
  anchorU?: number;
  anchorV?: number;
  zIndex?: number | null;
}

interface ViewAnnotationEntry {
  id: number;
  anchor: LatLng;
  viewName: string;
  width?: number;
  height?: number;
  centerOffset?: CenterOffset;
  visible: boolean;
  scalesWithViewingDistance: boolean;
  rotatesWithCamera: boolean;
  minZoom?: number;
  maxZoom?: number;
  anchorU: number;
  anchorV: number;
  zIndex?: number;
  /** Last measured content size (logical px) reported by the overlay, for dedup. */
  measuredWidth: number;
  measuredHeight: number;
}

const MEASURED_SIZE_EPSILON: number = 0.1;

/**
 * ViewAnnotationManager coordinates ViewAnnotation entries with the native API.
 *
 * One instance per MapLibreMap. It owns the content registry (annotation IDs
 * are allocated per native map) and the render-state pipeline consumed by the
 * in-map NativeViewAnnotationOverlay.
 */
export class ViewAnnotationManager {
  private nativeMapView: NativeMapView | null = null;
  private pixelRatio: number = 1;
  private entries: Map<number, ViewAnnotationEntry> = new Map();
  private renderStates: ViewAnnotationRenderState[] = [];
  private renderCallback?: (states: ViewAnnotationRenderState[]) => void;
  private contentRegistry: ComponentContentRegistry = new ComponentContentRegistry();
  /**
   * Last frame list pushed by the native positioning engine. The push channel
   * carries positions/sizes; entry metadata (visible/zIndex/viewName) is
   * re-applied from `entries` when rebuilding render states.
   */
  private lastNativeFrames: NativeViewAnnotationFrame[] = [];
  /** Guards against re-registering the native listener for the same view. */
  private listenerBoundTo: NativeMapView | null = null;

  /**
   * Content registry owned by this manager. The rendering overlay resolves it
   * through a provider so each map instance renders only its own contents.
   *
   * @internal Rendering-pipeline plumbing; applications should pass content
   * through addViewAnnotation()/setAnnotationContent() instead.
   */
  getContentRegistry(): ComponentContentRegistry {
    return this.contentRegistry;
  }

  /**
   * Creates a ViewAnnotation and returns a handle to it.
   *
   * Geometry and content are delivered together: pass the ComponentContent to
   * render (or register it later via setAnnotationContent). Fails (returns
   * null) when the native map view is not attached or the anchor is missing.
   */
  addViewAnnotation(options: ViewAnnotationAddOptions, content?: ComponentContent<Object>): ViewAnnotationHandle | null {
    if (!this.nativeMapView) {
      console.warn('[ViewAnnotationManager] addViewAnnotation: native map view is not available');
      return null;
    }
    const anchor = options.anchor;
    if (!anchor) {
      console.error('[ViewAnnotationManager] addViewAnnotation: anchor is required');
      return null;
    }

    const nativeOptions = this.buildNativeOptions(options);

    try {
      const rawId: number | string | boolean | null | undefined = this.nativeMapView.addViewAnnotation(nativeOptions);
      const id = typeof rawId === 'number' ? rawId : -1;
      if (id <= 0) {
        console.error(`[ViewAnnotationManager] addViewAnnotation: invalid id returned: ${rawId}`);
        return null;
      }

      const entry: ViewAnnotationEntry = {
        id,
        anchor,
        viewName: options.viewName ?? 'maplibre_view_annotation',
        width: options.width,
        height: options.height,
        centerOffset: options.centerOffset,
        visible: options.visible !== false,
        scalesWithViewingDistance: options.scalesWithViewingDistance === true,
        rotatesWithCamera: options.rotatesWithCamera === true,
        minZoom: options.minZoom,
        maxZoom: options.maxZoom,
        anchorU: options.anchorU !== undefined ? options.anchorU : 0.5,
        anchorV: options.anchorV !== undefined ? options.anchorV : 1.0,
        zIndex: options.zIndex,
        measuredWidth: 0,
        measuredHeight: 0
      };

      this.entries.set(id, entry);
      if (content) {
        this.contentRegistry.register(id, content);
      }
      this.refreshRenderStates();
      return new ViewAnnotationHandle(id, this);
    } catch (error) {
      const reason = error instanceof Error ? error.message : `${error}`;
      console.error(`[ViewAnnotationManager] addViewAnnotation failed: ${reason}`);
      return null;
    }
  }

  /**
   * Applies partial updates to an existing ViewAnnotation.
   */
  updateViewAnnotation(id: number, options: ViewAnnotationUpdateOptions): boolean {
    const entry = this.entries.get(id);
    if (!entry) {
      console.warn(`[ViewAnnotationManager] updateViewAnnotation: entry ${id} not found`);
      return false;
    }

    if (!this.nativeMapView) {
      console.warn('[ViewAnnotationManager] updateViewAnnotation: native map view is not available');
      return false;
    }

    if (options.anchor) {
      entry.anchor = options.anchor;
    }

    if (options.viewName !== undefined) {
      entry.viewName = options.viewName ?? 'maplibre_view_annotation';
    }

    if (options.width !== undefined) {
      entry.width = options.width === null ? undefined : Math.max(0, options.width);
    }
    if (options.height !== undefined) {
      entry.height = options.height === null ? undefined : Math.max(0, options.height);
    }

    if (options.centerOffset !== undefined) {
      entry.centerOffset = options.centerOffset ?? undefined;
    }

    if (options.visible !== undefined) {
      entry.visible = options.visible;
    }

    if (options.scalesWithViewingDistance !== undefined) {
      entry.scalesWithViewingDistance = options.scalesWithViewingDistance;
    }

    if (options.rotatesWithCamera !== undefined) {
      entry.rotatesWithCamera = options.rotatesWithCamera;
    }

    if (options.minZoom !== undefined) {
      entry.minZoom = options.minZoom === null ? undefined : options.minZoom;
    }

    if (options.maxZoom !== undefined) {
      entry.maxZoom = options.maxZoom === null ? undefined : options.maxZoom;
    }

    if (options.anchorU !== undefined) {
      entry.anchorU = options.anchorU;
    }

    if (options.anchorV !== undefined) {
      entry.anchorV = options.anchorV;
    }

    if (options.zIndex !== undefined) {
      entry.zIndex = options.zIndex === null ? undefined : options.zIndex;
    }

    const nativeOptions = this.buildNativeOptions(entry);

    try {
      const rawResult: boolean | number | string | undefined = this.nativeMapView.updateViewAnnotation(id, nativeOptions);
      const updated = typeof rawResult === 'boolean' ? rawResult : false;
      if (!updated) {
        console.warn(`[ViewAnnotationManager] updateViewAnnotation: native returned ${rawResult}`);
      }
      this.refreshRenderStates();
      return updated;
    } catch (error) {
      const reason = error instanceof Error ? error.message : `${error}`;
      console.error(`[ViewAnnotationManager] updateViewAnnotation failed: ${reason}`);
      return false;
    }
  }

  /**
   * Replaces the rendered content of an existing ViewAnnotation.
   * Pass null to detach the content (the annotation frame stays positioned
   * but renders nothing until new content is set).
   */
  setAnnotationContent(id: number, content: ComponentContent<Object> | null): boolean {
    if (!this.entries.has(id)) {
      console.warn(`[ViewAnnotationManager] setAnnotationContent: entry ${id} not found`);
      return false;
    }
    if (content) {
      this.contentRegistry.register(id, content);
    } else {
      this.contentRegistry.remove(id);
    }
    this.refreshRenderStates();
    return true;
  }

  /**
   * Removes a ViewAnnotation from the map and releases its registered content.
   */
  removeViewAnnotation(id: number): boolean {
    if (!this.entries.has(id)) {
      return true;
    }

    this.entries.delete(id);
    this.contentRegistry.remove(id);

    if (!this.nativeMapView) {
      console.warn('[ViewAnnotationManager] removeViewAnnotation: native map view is not available');
      this.removeRenderStateById(id);
      return false;
    }

    try {
      const rawResult: boolean | number | string | undefined = this.nativeMapView.removeViewAnnotation(id);
      const removed = typeof rawResult === 'boolean' ? rawResult : false;
      console.info(`[ViewAnnotationManager] removeViewAnnotation: entry ${id} removed, total entries=${this.entries.size}`);
      this.removeRenderStateById(id);
      if (!removed) {
        console.warn(`[ViewAnnotationManager] removeViewAnnotation: native returned ${rawResult}`);
      }
      return removed;
    } catch (error) {
      const reason = error instanceof Error ? error.message : `${error}`;
      console.error(`[ViewAnnotationManager] removeViewAnnotation failed: ${reason}`);
      this.removeRenderStateById(id);
      return false;
    }
  }

  /**
   * Removes all managed ViewAnnotations and clears cached state and content.
   */
  clear(): void {
    this.entries.clear();
    this.contentRegistry.clear();
    console.info('[ViewAnnotationManager] clear: all entries removed');
    if (this.nativeMapView) {
      try {
        const frames = this.nativeMapView.getViewAnnotationFrames();
        if (Array.isArray(frames)) {
          (frames as NativeViewAnnotationFrame[]).forEach((frame) => {
            this.nativeMapView?.removeViewAnnotation(frame.id);
          });
        }
      } catch (error) {
        const reason = error instanceof Error ? error.message : `${error}`;
        console.error(`[ViewAnnotationManager] clear failed: ${reason}`);
      }
    }
    this.lastNativeFrames = [];
    this.renderStates = [];
    this.notifyRenderCallback();
  }

  /**
   * Receives the measured content size for an annotation from the rendering
   * overlay (auto-size mode). The size is pushed to the native positioning
   * engine so anchor math uses the true content bounds. Fixed-size entries
   * (declared width/height) are ignored — their content is constrained and
   * the declared size is already authoritative.
   *
   * @internal Called by the in-map overlay; applications should not invoke it.
   */
  handleMeasuredSize(id: number, width: number, height: number): void {
    const entry = this.entries.get(id);
    if (!entry) {
      return;
    }
    if (!(width > 0) || !(height > 0)) {
      return;
    }
    if (entry.width !== undefined || entry.height !== undefined) {
      return;
    }
    const widthChanged = Math.abs(width - entry.measuredWidth) > MEASURED_SIZE_EPSILON;
    const heightChanged = Math.abs(height - entry.measuredHeight) > MEASURED_SIZE_EPSILON;
    if (!(widthChanged || heightChanged)) {
      return;
    }
    entry.measuredWidth = width;
    entry.measuredHeight = height;

    if (!this.nativeMapView) {
      return;
    }
    try {
      const partial = { width: width, height: height } as ViewAnnotationAddOptions;
      this.nativeMapView.updateViewAnnotation(id, this.buildNativeOptions(partial));
    } catch (error) {
      const reason = error instanceof Error ? error.message : `${error}`;
      console.warn(`[ViewAnnotationManager] handleMeasuredSize failed for ${id}: ${reason}`);
    }
  }

  /**
   * Returns the latest render states that can be bound directly to ArkUI overlays.
   *
   * @internal Rendering-pipeline plumbing.
   */
  getRenderStates(): ViewAnnotationRenderState[] {
    return this.renderStates.slice();
  }

  /**
   * Pulls frame data from native and recomputes ArkUI render states.
   *
   * Positions arrive through the native push channel (see handleNativeFrames);
   * this method only re-applies entry metadata onto the cached frames — it
   * performs no native round trip. Content-only refreshes (adapter swap, show)
   * call this so the overlay re-attaches content even when frames did not move.
   *
   * @internal Rendering-pipeline plumbing.
   */
  refreshRenderStates(): void {
    if (!this.nativeMapView) {
      this.renderStates = [];
      this.notifyRenderCallback();
      return;
    }

    // Fast path: nothing on screen (the common per-frame case).
    if (this.entries.size === 0) {
      if (this.renderStates.length !== 0) {
        this.renderStates = [];
        this.notifyRenderCallback();
      }
      return;
    }

    this.rebuildRenderStates(this.lastNativeFrames);
  }

  /**
   * Receives a frame list pushed by the native positioning engine (render
   * thread, epsilon-deduped). Replaces the previous per-camera-event pull of
   * getViewAnnotationFrames().
   *
   * @internal Called by the native frames listener bound in setNativeMapView.
   */
  private handleNativeFrames(frames: NativeViewAnnotationFrame[]): void {
    this.lastNativeFrames = Array.isArray(frames) ? frames : [];
    this.rebuildRenderStates(this.lastNativeFrames);
  }

  /**
   * Converts native frames to overlay render states, re-applying per-entry
   * metadata (visible/zIndex/viewName and size mode) that lives on the ArkTS
   * side. Frames without a matching entry are skipped: they belong to another
   * producer on the same native map (foreign annotations are left untouched).
   */
  private rebuildRenderStates(frames: NativeViewAnnotationFrame[]): void {
    const safeRatio = this.pixelRatio > 0 ? this.pixelRatio : 1;
    const nextStates: ViewAnnotationRenderState[] = [];

    frames.forEach((frame) => {
      const entry = this.entries.get(frame.id);
      if (!entry) {
        return;
      }

      // positionX/positionY are pre-computed by C++ buildFrame(): final render
      // coordinates in logical pixels. Only sizes need the ratio conversion.
      const frameRatio = resolveFramePixelRatio(frame.pixelRatio, safeRatio, frame.id);
      const logicalWidth = frame.width > 0 ? frame.width / frameRatio : (entry.width ?? 0);
      const logicalHeight = frame.height > 0 ? frame.height / frameRatio : (entry.height ?? 0);
      // Fixed-size entries constrain their content to the declared size;
      // auto-size entries hug their content and only use the size for anchor math.
      const applySize = entry.width !== undefined || entry.height !== undefined;

      nextStates.push(new ViewAnnotationRenderState({
        id: frame.id,
        positionX: frame.positionX,
        positionY: frame.positionY,
        width: logicalWidth,
        height: logicalHeight,
        applySize: applySize,
        scale: Number.isFinite(frame.scale) && frame.scale > 0 ? frame.scale : 1,
        rotation: Number.isFinite(frame.rotation) ? frame.rotation : 0,
        opacity: normalizeOpacity(frame.opacity),
        visible: entry.visible && frame.visible,
        viewName: entry.viewName,
        zIndex: entry.zIndex
      }));
    });

    this.renderStates = nextStates;
    this.notifyRenderCallback();
  }

  /**
   * Registers a render callback that receives normalized render states for ArkUI.
   *
   * @internal Rendering-pipeline plumbing.
   */
  setRenderCallback(callback: ((states: ViewAnnotationRenderState[]) => void) | null): void {
    this.renderCallback = callback ?? undefined;
    if (callback) {
      callback(this.renderStates.slice());
    }
  }

  /**
   * Binds the manager to the underlying native map view.
   * Pass null when disposing the manager.
   *
   * Binds the native frames push listener: the native engine actively
   * dispatches computed (epsilon-deduped) frames to this manager.
   *
   * @internal Called by MapLibreMap during setup/teardown.
   */
  setNativeMapView(mapView: NativeMapView | null): void {
    if (this.nativeMapView && this.nativeMapView !== mapView && this.listenerBoundTo === this.nativeMapView) {
      // Release the previous binding so its thread-safe function is not leaked.
      try {
        this.nativeMapView.setViewAnnotationFramesListener(null);
      } catch (error) {
        const reason = error instanceof Error ? error.message : `${error}`;
        console.warn(`[ViewAnnotationManager] failed to detach previous frames listener: ${reason}`);
      }
      this.listenerBoundTo = null;
    }

    this.nativeMapView = mapView;
    this.pixelRatio = this.readPixelRatio(mapView);

    if (mapView && this.listenerBoundTo !== mapView) {
      try {
        mapView.setViewAnnotationFramesListener((frames: NativeViewAnnotationFrame[]) => {
          this.handleNativeFrames(frames);
        });
        this.listenerBoundTo = mapView;
      } catch (error) {
        const reason = error instanceof Error ? error.message : `${error}`;
        console.warn(`[ViewAnnotationManager] failed to bind frames listener: ${reason}`);
      }
    }
  }

  /**
   * Updates the pixel ratio used when converting logical dimensions to device pixels.
   *
   * @internal Called by MapLibreMap during setup.
   */
  updatePixelRatio(pixelRatio: number): void {
    if (!Number.isFinite(pixelRatio) || pixelRatio <= 0) {
      console.warn(`[ViewAnnotationManager] updatePixelRatio: ignore invalid value ${pixelRatio}`);
      return;
    }
    this.pixelRatio = pixelRatio;
  }

  private notifyRenderCallback(): void {
    if (this.renderCallback) {
      this.renderCallback(this.renderStates.slice());
    }
  }

  private removeRenderStateById(id: number): void {
    if (this.renderStates.length === 0) {
      return;
    }
    const nextStates = this.renderStates.filter((state) => state.id !== id);
    if (nextStates.length === this.renderStates.length) {
      return;
    }
    this.renderStates = nextStates;
    this.notifyRenderCallback();
  }

  private buildNativeOptions(source: Partial<ViewAnnotationAddOptions> | Partial<ViewAnnotationEntry>): NativeViewAnnotationOptions {
    const safeRatio = this.pixelRatio > 0 ? this.pixelRatio : 1;

    const nativeOptions = new NativeViewAnnotationOptionsImpl();
    // Only include the anchor when provided: partial update payloads without
    // an anchor must not reset the stored native anchor to (0, 0).
    if (source.anchor) {
      nativeOptions.anchor = new NativeViewAnnotationAnchorImpl(source.anchor.latitude, source.anchor.longitude);
    }

    if (source.width !== undefined && source.width !== null) {
      nativeOptions.width = Math.max(0, source.width * safeRatio);
    }

    if (source.height !== undefined && source.height !== null) {
      nativeOptions.height = Math.max(0, source.height * safeRatio);
    }

    const centerOffset = source.centerOffset;
    if (centerOffset) {
      nativeOptions.centerOffset = new NativeViewAnnotationCenterOffsetImpl(centerOffset.dx, centerOffset.dy);
    }

    if (source.visible !== undefined) {
      nativeOptions.visible = source.visible;
    }

    if (source.scalesWithViewingDistance !== undefined) {
      nativeOptions.scalesWithViewingDistance = source.scalesWithViewingDistance;
    }

    if (source.rotatesWithCamera !== undefined) {
      nativeOptions.rotatesWithCamera = source.rotatesWithCamera;
    }

    if (source.minZoom !== undefined && source.minZoom !== null) {
      nativeOptions.minZoom = source.minZoom;
    }

    if (source.maxZoom !== undefined && source.maxZoom !== null) {
      nativeOptions.maxZoom = source.maxZoom;
    }

    return nativeOptions;
  }

  private readPixelRatio(mapView: NativeMapView | null): number {
    if (!mapView) {
      return 1;
    }

    try {
      const ratio = mapView.getPixelRatio?.();
      if (typeof ratio === 'number' && Number.isFinite(ratio) && ratio > 0) {
        return ratio;
      }
    } catch (error) {
      const reason = error instanceof Error ? error.message : `${error}`;
      console.warn(`[ViewAnnotationManager] readPixelRatio failed: ${reason}`);
    }
    return 1;
  }
}
