import { NativeMapView } from 'libmaplibre.so';
import { LatLng } from '../geometry/LatLng';
import {
  NativeViewAnnotationAnchorImpl,
  NativeViewAnnotationCenterOffsetImpl,
  NativeViewAnnotationFrame,
  NativeViewAnnotationOptions,
  NativeViewAnnotationOptionsImpl
} from './NativeViewAnnotationTypes';
import { ViewAnnotationRenderState } from './NativeViewAnnotationOverlay';
import { CenterOffset } from './AnnotationView';

interface PartialNativeOptionFlags {
  visible?: boolean;
  allowOverlap?: boolean;
  draggable?: boolean;
  scalesWithViewingDistance?: boolean;
  rotatesWithCamera?: boolean;
  minZoom?: number;
  maxZoom?: number;
}

/**
 * Configuration options for creating a ViewAnnotation via ViewAnnotationManager.
 */
export interface ViewAnnotationAddOptions {
  anchor: LatLng;
  viewName?: string;
  width?: number;
  height?: number;
  anchorHeight?: number;  // Height for anchor positioning (e.g., marker icon height)
  centerOffset?: CenterOffset;
  visible?: boolean;
  allowOverlap?: boolean;
  draggable?: boolean;
  scalesWithViewingDistance?: boolean;
  rotatesWithCamera?: boolean;
  minZoom?: number;
  maxZoom?: number;
  anchorU?: number;
  anchorV?: number;
  zIndex?: number;
}

/**
 * Partial configuration used when updating an existing ViewAnnotation.
 */
export interface ViewAnnotationUpdateOptions {
  anchor?: LatLng;
  viewName?: string;
  width?: number;
  height?: number;
  anchorHeight?: number | null;
  centerOffset?: CenterOffset | null;
  visible?: boolean;
  allowOverlap?: boolean;
  draggable?: boolean;
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
  anchorHeight?: number;
  centerOffset?: CenterOffset;
  visible: boolean;
  allowOverlap: boolean;
  draggable: boolean;
  scalesWithViewingDistance: boolean;
  rotatesWithCamera: boolean;
  minZoom?: number;
  maxZoom?: number;
  anchorU: number;
  anchorV: number;
  zIndex?: number;
}

/**
 * ViewAnnotationManager coordinates ViewAnnotation entries with the native API.
 */
export class ViewAnnotationManager {
  private nativeMapView: NativeMapView | null = null;
  private pixelRatio: number = 1;
  private entries: Map<number, ViewAnnotationEntry> = new Map();
  private renderStates: ViewAnnotationRenderState[] = [];
  private renderCallback?: (states: ViewAnnotationRenderState[]) => void;

  /**
   * Binds the manager to the underlying native map view.
   * Pass null when disposing the manager.
   */
  setNativeMapView(mapView: NativeMapView | null): void {
    console.info(`[ViewAnnotationManager] setNativeMapView: ${mapView ? 'attach' : 'detach'} native map view`);
    this.nativeMapView = mapView;
    this.pixelRatio = this.readPixelRatio(mapView);
    console.info(`[ViewAnnotationManager] setNativeMapView: pixelRatio=${this.pixelRatio}`);
  }

  /**
   * Registers a render callback that receives normalized render states for ArkUI.
   */
  setRenderCallback(callback: ((states: ViewAnnotationRenderState[]) => void) | null): void {
    console.info(`[ViewAnnotationManager] setRenderCallback: ${callback ? 'register' : 'clear'} callback`);
    this.renderCallback = callback ?? undefined;
    if (callback) {
      console.info(`[ViewAnnotationManager] setRenderCallback: emitting initial ${this.renderStates.length} states`);
      callback(this.renderStates.slice());
    }
  }

  /**
   * Updates the pixel ratio used when converting logical dimensions to device pixels.
   */
  updatePixelRatio(pixelRatio: number): void {
    if (!Number.isFinite(pixelRatio) || pixelRatio <= 0) {
      console.warn(`[ViewAnnotationManager] updatePixelRatio: ignore invalid value ${pixelRatio}`);
      return;
    }
    this.pixelRatio = pixelRatio;
    console.info(`[ViewAnnotationManager] updatePixelRatio: pixelRatio=${this.pixelRatio}`);
  }

  /**
   * Creates a ViewAnnotation using the supplied builder and returns the generated identifier.
   */
  addViewAnnotation(options: ViewAnnotationAddOptions): number {
    if (!this.nativeMapView) {
      console.warn('[ViewAnnotationManager] addViewAnnotation: native map view is not available');
      return -1;
    }
    const anchor = options.anchor;
    if (!anchor) {
      console.error('[ViewAnnotationManager] addViewAnnotation: anchor is required');
      return -1;
    }

    const nativeOptions = this.buildNativeOptions(options);

    try {
      const rawId: number | string | boolean | null | undefined = this.nativeMapView.addViewAnnotation(nativeOptions);
      const id = typeof rawId === 'number' ? rawId : -1;
      if (id <= 0) {
        console.error(`[ViewAnnotationManager] addViewAnnotation: invalid id returned: ${rawId}`);
        return -1;
      }

      const entry: ViewAnnotationEntry = {
        id,
        anchor,
        viewName: options.viewName ?? 'maplibre_view_annotation',
        width: options.width,
        height: options.height,
        anchorHeight: options.anchorHeight,
        centerOffset: options.centerOffset,
        visible: options.visible !== false,
        allowOverlap: options.allowOverlap === undefined ? true : options.allowOverlap,
        draggable: options.draggable === true,
        scalesWithViewingDistance: options.scalesWithViewingDistance === true,
        rotatesWithCamera: options.rotatesWithCamera === true,
        minZoom: options.minZoom,
        maxZoom: options.maxZoom,
        anchorU: options.anchorU !== undefined ? options.anchorU : 0.5,
        anchorV: options.anchorV !== undefined ? options.anchorV : 1.0,
        zIndex: options.zIndex
      };

      this.entries.set(id, entry);
      console.info(`[ViewAnnotationManager] addViewAnnotation: entry ${id} added, total entries=${this.entries.size}`);
      this.refreshRenderStates();
      return id;
    } catch (error) {
      const reason = error instanceof Error ? error.message : `${error}`;
      console.error(`[ViewAnnotationManager] addViewAnnotation failed: ${reason}`);
      return -1;
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
      entry.width = options.width;
    }
    if (options.height !== undefined) {
      entry.height = options.height;
    }

    if (options.anchorHeight !== undefined) {
      entry.anchorHeight = options.anchorHeight === null ? undefined : options.anchorHeight;
    }

    if (options.centerOffset !== undefined) {
      entry.centerOffset = options.centerOffset ?? undefined;
    }

    if (options.visible !== undefined) {
      entry.visible = options.visible;
    }

    if (options.allowOverlap !== undefined) {
      entry.allowOverlap = options.allowOverlap;
    }

    if (options.draggable !== undefined) {
      entry.draggable = options.draggable;
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
      console.info(`[ViewAnnotationManager] updateViewAnnotation: entry ${id} updated, total entries=${this.entries.size}`);
      this.refreshRenderStates();
      return updated;
    } catch (error) {
      const reason = error instanceof Error ? error.message : `${error}`;
      console.error(`[ViewAnnotationManager] updateViewAnnotation failed: ${reason}`);
      return false;
    }
  }

  /**
   * Removes a ViewAnnotation from the map.
   */
  removeViewAnnotation(id: number): boolean {
    if (!this.entries.has(id)) {
      return true;
    }

    if (!this.nativeMapView) {
      console.warn('[ViewAnnotationManager] removeViewAnnotation: native map view is not available');
      this.entries.delete(id);
      this.removeRenderStateById(id);
      return false;
    }

    try {
      const rawResult: boolean | number | string | undefined = this.nativeMapView.removeViewAnnotation(id);
      const removed = typeof rawResult === 'boolean' ? rawResult : false;
      this.entries.delete(id);
      console.info(`[ViewAnnotationManager] removeViewAnnotation: entry ${id} removed, total entries=${this.entries.size}`);
      this.removeRenderStateById(id);
      if (!removed) {
        console.warn(`[ViewAnnotationManager] removeViewAnnotation: native returned ${rawResult}`);
      }
      return removed;
    } catch (error) {
      const reason = error instanceof Error ? error.message : `${error}`;
      console.error(`[ViewAnnotationManager] removeViewAnnotation failed: ${reason}`);
      this.entries.delete(id);
      this.removeRenderStateById(id);
      return false;
    }
  }

  /**
   * Removes all managed ViewAnnotations and clears cached state.
   */
  clear(): void {
    this.entries.clear();
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
    this.renderStates = [];
    this.notifyRenderCallback();
  }

  /**
   * Returns the latest render states that can be bound directly to ArkUI overlays.
   */
  getRenderStates(): ViewAnnotationRenderState[] {
    return this.renderStates.slice();
  }

  /**
   * Pulls frame data from native and recomputes ArkUI render states.
   */
  refreshRenderStates(): void {
    if (!this.nativeMapView) {
      this.renderStates = [];
      this.notifyRenderCallback();
      return;
    }

    let frames: NativeViewAnnotationFrame[] = [];
    try {
      const rawFrames = this.nativeMapView.getViewAnnotationFrames();
      if (Array.isArray(rawFrames)) {
        frames = rawFrames;
      }
    } catch (error) {
      const reason = error instanceof Error ? error.message : `${error}`;
      console.error(`[ViewAnnotationManager] refreshRenderStates failed: ${reason}`);
      this.renderStates = [];
      this.notifyRenderCallback();
      return;
    }

    const safeRatio = this.pixelRatio > 0 ? this.pixelRatio : 1;
    const nextStates: ViewAnnotationRenderState[] = [];

    // Debug: log raw frame data from C++
    console.info(`[ViewAnnotationManager] Raw frames from C++: ${frames.length} frames, safeRatio=${safeRatio.toFixed(2)}`);
    frames.forEach((frame, idx) => {
      console.info(`[ViewAnnotationManager] Raw frame[${idx}]: id=${frame.id}, x=${frame.x?.toFixed(2)}, y=${frame.y?.toFixed(2)}, ` +
        `width=${frame.width}, height=${frame.height}, pixelRatio=${frame.pixelRatio}, visible=${frame.visible}`);
    });

    frames.forEach((frame) => {
      const entry = this.entries.get(frame.id);
      if (!entry) {
        console.warn(`[ViewAnnotationManager] refreshRenderStates: skip frame ${frame.id} (entry missing)`);
        return;
      }

      // Phase 2: positionX/positionY are pre-computed by C++ buildFrame()
      // No pixelRatio division or anchor math needed on the ArkTS side
      const frameRatio = this.resolveFramePixelRatio(frame.pixelRatio, safeRatio, frame.id);
      const logicalWidth = frame.width > 0 ? frame.width / frameRatio : (entry.width ?? 0);
      const logicalHeight = frame.height > 0 ? frame.height / frameRatio : (entry.height ?? 0);

      nextStates.push(new ViewAnnotationRenderState({
        id: frame.id,
        positionX: frame.positionX,
        positionY: frame.positionY,
        width: logicalWidth,
        height: logicalHeight,
        scale: Number.isFinite(frame.scale) && frame.scale > 0 ? frame.scale : 1,
        rotation: Number.isFinite(frame.rotation) ? frame.rotation : 0,
        opacity: this.normalizeOpacity(frame.opacity),
        visible: entry.visible && frame.visible,
        viewName: entry.viewName,
        zIndex: entry.zIndex
      }));
    });

    this.renderStates = nextStates;
    this.notifyRenderCallback();
  }

  private resolveFramePixelRatio(frameRatio: number, fallback: number, frameId: number): number {
    const safeFallback = fallback > 0 ? fallback : 1;
    if (!Number.isFinite(frameRatio) || frameRatio <= 0) {
      return safeFallback;
    }

    const MAX_RATIO_MULTIPLIER = 4;
    const MIN_RATIO_MULTIPLIER = 0.25;
    if (frameRatio > safeFallback * MAX_RATIO_MULTIPLIER || frameRatio < safeFallback * MIN_RATIO_MULTIPLIER) {
      console.warn(`[ViewAnnotationManager] resolveFramePixelRatio: frame ${frameId} pixelRatio ${frameRatio.toFixed(2)} out of expected range, fallback=${safeFallback.toFixed(2)}`);
      return safeFallback;
    }
    return frameRatio;
  }

  private normalizeOpacity(value: number): number {
    if (!Number.isFinite(value)) {
      return 1;
    }
    if (value <= 0) {
      return 0;
    }
    if (value >= 1) {
      return 1;
    }
    return value;
  }

  private notifyRenderCallback(): void {
    if (this.renderCallback) {
      console.info(`[ViewAnnotationManager] notifyRenderCallback: emitting ${this.renderStates.length} states`);
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

  private buildNativeOptions(source: ViewAnnotationAddOptions | ViewAnnotationEntry): NativeViewAnnotationOptions {
    const safeRatio = this.pixelRatio > 0 ? this.pixelRatio : 1;
    const anchorLatitude = source.anchor.latitude;
    const anchorLongitude = source.anchor.longitude;

    const nativeOptions = new NativeViewAnnotationOptionsImpl(new NativeViewAnnotationAnchorImpl(anchorLatitude, anchorLongitude));

    if (source.width !== undefined) {
      nativeOptions.width = Math.max(0, source.width * safeRatio);
    }

    if (source.height !== undefined) {
      nativeOptions.height = Math.max(0, source.height * safeRatio);
    }

    // Pass anchorHeight for anchor positioning calculation
    if (source.anchorHeight !== undefined) {
      nativeOptions.anchorHeight = Math.max(0, source.anchorHeight * safeRatio);
    }

    const centerOffset = source.centerOffset;
    if (centerOffset) {
      nativeOptions.centerOffset = new NativeViewAnnotationCenterOffsetImpl(centerOffset.dx, centerOffset.dy);
    }

    const partial = source as PartialNativeOptionFlags;
    const visibility = partial.visible;
    if (visibility !== undefined) {
      nativeOptions.visible = visibility;
    }

    const overlapOption = partial.allowOverlap;
    if (overlapOption !== undefined) {
      nativeOptions.allowOverlap = overlapOption;
    }

    const draggableOption = partial.draggable;
    if (draggableOption !== undefined) {
      nativeOptions.draggable = draggableOption;
    }

    const scalesOption = partial.scalesWithViewingDistance;
    if (scalesOption !== undefined) {
      nativeOptions.scalesWithViewingDistance = scalesOption;
    }

    const rotatesOption = partial.rotatesWithCamera;
    if (rotatesOption !== undefined) {
      nativeOptions.rotatesWithCamera = rotatesOption;
    }

    const minZoomValue = partial.minZoom;
    if (minZoomValue !== undefined) {
      nativeOptions.minZoom = minZoomValue;
    }

    const maxZoomValue = partial.maxZoom;
    if (maxZoomValue !== undefined) {
      nativeOptions.maxZoom = maxZoomValue;
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


