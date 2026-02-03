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
import {
  ViewAnnotationBuilderContext,
  DEFAULT_VIEW_ANNOTATION_VIEW_NAME,
  DEFAULT_VIEW_ANNOTATION_WRAPPED_BUILDER
} from './ViewAnnotationTypes';
import type {
  ViewAnnotationRenderCallback,
  ViewAnnotationWrappedBuilder
} from './ViewAnnotationTypes';

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
  wrappedBuilder?: ViewAnnotationWrappedBuilder;
  // renderCallback: ViewAnnotationRenderCallback;
  viewName?: string;
  width?: number;
  height?: number;
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
  wrappedBuilder?: ViewAnnotationWrappedBuilder | null;
  renderCallback?: ViewAnnotationRenderCallback | null;
  viewName?: string;
  width?: number;
  height?: number;
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
  wrappedBuilder: ViewAnnotationWrappedBuilder;
  // renderCallback: ViewAnnotationRenderCallback;
  viewName: string;
  width?: number;
  height?: number;
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
 * ViewAnnotationManager coordinates ArkUI builders with the native ViewAnnotation API.
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
    const wrappedBuilder = options.wrappedBuilder ?? DEFAULT_VIEW_ANNOTATION_WRAPPED_BUILDER;

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
        wrappedBuilder,
        viewName: options.viewName ?? DEFAULT_VIEW_ANNOTATION_VIEW_NAME,
        width: options.width,
        height: options.height,
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

    if (options.wrappedBuilder !== undefined) {
      if (options.wrappedBuilder === null) {
        console.warn('[ViewAnnotationManager] updateViewAnnotation: wrappedBuilder cannot be null');
      } else {
        entry.wrappedBuilder = options.wrappedBuilder;
      }
    }

    if (options.viewName !== undefined) {
      entry.viewName = options.viewName ?? DEFAULT_VIEW_ANNOTATION_VIEW_NAME;
    }

    if (options.width !== undefined) {
      entry.width = options.width;
    }
    if (options.height !== undefined) {
      entry.height = options.height;
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

    frames.forEach((frame) => {
      const entry = this.entries.get(frame.id);
      if (!entry) {
        console.warn(`[ViewAnnotationManager] refreshRenderStates: skip frame ${frame.id} (entry missing)`);
        return;
      }

      const format = (value: number): string => Number.isFinite(value) ? value.toFixed(2) : 'NaN';
      const frameRatio = this.resolveFramePixelRatio(frame.pixelRatio, safeRatio, frame.id);
      const logicalWidth = frame.width > 0 ? frame.width / frameRatio : (entry.width ?? 0);
      const logicalHeight = frame.height > 0 ? frame.height / frameRatio : (entry.height ?? 0);
      const frameLogicalX = frame.x / frameRatio;
      const frameLogicalY = frame.y / frameRatio;
      const frameOffsetX = Number.isFinite(frame.offsetX) ? frame.offsetX / frameRatio : 0;
      const frameOffsetY = Number.isFinite(frame.offsetY) ? frame.offsetY / frameRatio : 0;
      const centerOffsetX = entry.centerOffset?.dx ?? 0;
      const centerOffsetY = entry.centerOffset?.dy ?? 0;
      const anchorU = entry.anchorU ?? 0.5;
      const anchorV = entry.anchorV ?? 1.0;

      const positionX = frameLogicalX - logicalWidth * anchorU + frameOffsetX + centerOffsetX;
      const positionY = frameLogicalY - logicalHeight * anchorV + frameOffsetY + centerOffsetY;

      console.info(
        `[ViewAnnotationManager] frame=${frame.id} raw=(${format(frame.x)}, ${format(frame.y)}) ` +
        `pixelRatio(raw=${format(frame.pixelRatio)}, resolved=${format(frameRatio)}) ` +
        `logical=(${format(frameLogicalX)}, ${format(frameLogicalY)}) size=(${format(logicalWidth)}, ${format(logicalHeight)}) ` +
        `offset=(${format(frameOffsetX)}, ${format(frameOffsetY)}) position=(${format(positionX)}, ${format(positionY)})`
      );

      nextStates.push(new ViewAnnotationRenderState({
        id: frame.id,
        positionX,
        positionY,
        width: logicalWidth,
        height: logicalHeight,
        scale: Number.isFinite(frame.scale) && frame.scale > 0 ? frame.scale : 1,
        rotation: Number.isFinite(frame.rotation) ? frame.rotation : 0,
        opacity: this.normalizeOpacity(frame.opacity),
        visible: entry.visible && frame.visible,
        wrappedBuilder: entry.wrappedBuilder,
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


