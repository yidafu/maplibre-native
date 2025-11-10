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

type ViewAnnotationBuilder = () => void;

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
  builder: ViewAnnotationBuilder;
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
  builder?: ViewAnnotationBuilder | null;
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
  builder: ViewAnnotationBuilder;
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

    const builder = options.builder;
    if (!builder) {
      console.error('[ViewAnnotationManager] addViewAnnotation: builder is required');
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
        builder,
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

    if (options.builder !== undefined) {
      if (options.builder === null) {
        console.warn('[ViewAnnotationManager] updateViewAnnotation: builder cannot be null');
      } else {
        entry.builder = options.builder;
      }
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
      this.refreshRenderStates();
      return false;
    }

    try {
      const rawResult: boolean | number | string | undefined = this.nativeMapView.removeViewAnnotation(id);
      const removed = typeof rawResult === 'boolean' ? rawResult : false;
      this.entries.delete(id);
      console.info(`[ViewAnnotationManager] removeViewAnnotation: entry ${id} removed, total entries=${this.entries.size}`);
      this.refreshRenderStates();
      if (!removed) {
        console.warn(`[ViewAnnotationManager] removeViewAnnotation: native returned ${rawResult}`);
      }
      return removed;
    } catch (error) {
      const reason = error instanceof Error ? error.message : `${error}`;
      console.error(`[ViewAnnotationManager] removeViewAnnotation failed: ${reason}`);
      this.entries.delete(id);
      this.refreshRenderStates();
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
    this.refreshRenderStates();
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

    console.info(`[ViewAnnotationManager] refreshRenderStates: start, pixelRatio=${this.pixelRatio}`);

    let frames: NativeViewAnnotationFrame[] = [];
    try {
      const rawFrames = this.nativeMapView.getViewAnnotationFrames();
      frames = Array.isArray(rawFrames) ? rawFrames as NativeViewAnnotationFrame[] : [];
    } catch (error) {
      const reason = error instanceof Error ? error.message : `${error}`;
      console.error(`[ViewAnnotationManager] refreshRenderStates failed: ${reason}`);
      this.renderStates = [];
      this.notifyRenderCallback();
      return;
    }

    console.info(`[ViewAnnotationManager] refreshRenderStates: received ${frames.length} native frames`);

    const safeRatio = this.pixelRatio > 0 ? this.pixelRatio : 1;
    const nextStates: ViewAnnotationRenderState[] = [];

    frames.forEach((frame) => {
      const entry = this.entries.get(frame.id);
      if (!entry) {
        console.warn(`[ViewAnnotationManager] refreshRenderStates: skip frame ${frame.id} (entry missing)`);
        return;
      }

      const frameRatio = frame.pixelRatio > 0 ? frame.pixelRatio : safeRatio;
      const logicalWidth = frame.width / frameRatio;
      const logicalHeight = frame.height / frameRatio;
      const logicalX = frame.x / frameRatio;
      const logicalY = frame.y / frameRatio;
      const positionX = logicalX - logicalWidth * entry.anchorU;
      const positionY = logicalY - logicalHeight * entry.anchorV;

      const anchorLat = entry.anchor?.latitude;
      const anchorLng = entry.anchor?.longitude;
      const anchorLatText = anchorLat !== undefined ? anchorLat.toFixed(6) : 'n/a';
      const anchorLngText = anchorLng !== undefined ? anchorLng.toFixed(6) : 'n/a';
      const offsetDx = entry.centerOffset?.dx ?? 0;
      const offsetDy = entry.centerOffset?.dy ?? 0;
      console.info(
        `[ViewAnnotationManager] refreshRenderStates: frame ${frame.id} anchor=(${anchorLatText}, ${anchorLngText}) ` +
        `nativePos=(${frame.x}, ${frame.y}) logicalPos=(${logicalX.toFixed(2)}, ${logicalY.toFixed(2)}) ` +
        `offset=(${offsetDx}, ${offsetDy}) size=(${logicalWidth.toFixed(2)} x ${logicalHeight.toFixed(2)}) ` +
        `position=(${positionX.toFixed(2)}, ${positionY.toFixed(2)}) scale=${frame.scale} rotation=${frame.rotation}`
      );

      nextStates.push(new ViewAnnotationRenderState({
        id: frame.id,
        positionX,
        positionY,
        width: logicalWidth,
        height: logicalHeight,
        scale: frame.scale,
        rotation: frame.rotation,
        opacity: frame.opacity,
        visible: entry.visible && frame.visible,
        builder: entry.builder,
        zIndex: entry.zIndex
      }));
    });

    this.renderStates = nextStates;
    console.info(`[ViewAnnotationManager] refreshRenderStates: computed ${this.renderStates.length} render states`);
    this.notifyRenderCallback();
  }

  private notifyRenderCallback(): void {
    if (this.renderCallback) {
      console.info(`[ViewAnnotationManager] notifyRenderCallback: emitting ${this.renderStates.length} states`);
      this.renderCallback(this.renderStates.slice());
    }
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

