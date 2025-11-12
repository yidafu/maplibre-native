/**
 * Marker - ArkTS wrapper for map markers.
 *
 * Provides an ArkTS-friendly interface around the native marker implementation.
 */
import maplibre from 'libmaplibre.so';
import type { MarkerOptions as NAPIMarkerOptions } from 'libmaplibre.so';
import { LatLng } from '../geometry/LatLng';
import type { ILatLng } from '../types/NativeTypes';
import type { MapLibreMap } from '../MapLibreMap';

/**
 * Marker anchor interface.
 */
export interface MarkerAnchor {
  u: number;
  v: number;
}

/**
 * Native marker options (for NAPI interop).
 * Compatible with the NAPI `MarkerOptions`, but uses `ILatLng` for position.
 */
export interface NativeMarkerOptions {
  position: ILatLng;
  icon?: string;
  title?: string;
  snippet?: string;
  visible?: boolean;
  alpha?: number;
  rotation?: number;
  draggable?: boolean;
  zIndex?: number;
  anchor?: MarkerAnchor;
}

/**
 * Internal marker tag used for native construction.
 */
class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

/**
 * Marker wrapper.
 */
export class Marker {
  private nativeInstance: maplibre.Marker;
  private _id: number = 0; // Marker ID (set by MarkerManager)
  private _map: MapLibreMap | null = null; // Owning MapLibreMap instance
  private _selected: boolean = false; // Selection state cache
  private _dragState: number = 0; // Drag state cache

  /**
   * Constructor supporting two modes:
   * 1. Create from options: `new Marker(options)`
  * 2. Create from a native instance (internal use): `new Marker(marker, nativeInstance)`
   */
  constructor(optionsOrMarker: NativeMarkerOptions | InternalMarker, nativeInstance?: maplibre.Marker) {
    if (optionsOrMarker === InternalMarker.INSTANCE && nativeInstance) {
      // Internal mode: construct from a NAPI instance
      this.nativeInstance = nativeInstance;
    } else if (typeof optionsOrMarker === 'object') {
      // Standard mode: construct from an options object
      // Convert to the NAPI MarkerOptions structure
      const opts = optionsOrMarker as NativeMarkerOptions;
      const napiOptions: NAPIMarkerOptions = {
        position: opts.position,
        icon: opts.icon,
        title: opts.title,
        snippet: opts.snippet,
        visible: opts.visible,
        alpha: opts.alpha,
        rotation: opts.rotation,
        draggable: opts.draggable,
        zIndex: opts.zIndex,
        anchor: opts.anchor
      };
      this.nativeInstance = new maplibre.Marker(napiOptions);
    } else {
      throw new Error('Invalid Marker constructor arguments');
    }
  }

  /**
   * Construct from a NAPI instance (internal use).
   */
  static fromNative(nativeInstance: maplibre.Marker): Marker {
    return new Marker(InternalMarker.INSTANCE, nativeInstance);
  }

  /**
   * Create a marker from options (factory helper).
   */
  static createFromOptions(options: NativeMarkerOptions): Marker {
    return new Marker(options);
  }

  /**
   * Retrieve the native marker (internal use).
   */
  getNative(): maplibre.Marker {
    return this.nativeInstance;
  }

  // ========== Marker API ==========

  getPosition(): LatLng {
    const pos = this.nativeInstance.getPosition();
    return new LatLng(pos.latitude, pos.longitude);
  }

  setPosition(position: LatLng): Marker {
    this.nativeInstance.setPosition(position.toObject());
    return this;
  }

  getIcon(): string {
    return this.nativeInstance.getIcon() || '';
  }

  setIcon(iconId: string): Marker {
    this.nativeInstance.setIcon(iconId);
    return this;
  }

  getTitle(): string {
    return this.nativeInstance.getTitle();
  }

  setTitle(title: string): Marker {
    this.nativeInstance.setTitle(title);
    return this;
  }

  getSnippet(): string {
    return this.nativeInstance.getSnippet();
  }

  setSnippet(snippet: string): Marker {
    this.nativeInstance.setSnippet(snippet);
    return this;
  }

  getRotation(): number {
    return this.nativeInstance.getRotation();
  }

  setRotation(rotation: number): Marker {
    this.nativeInstance.setRotation(rotation);
    return this;
  }

  getAlpha(): number {
    return this.nativeInstance.getAlpha();
  }

  setAlpha(alpha: number): Marker {
    this.nativeInstance.setAlpha(alpha);
    return this;
  }

  getZIndex(): number {
    return this.nativeInstance.getZIndex();
  }

  setZIndex(zIndex: number): Marker {
    this.nativeInstance.setZIndex(zIndex);
    return this;
  }

  getAnchor(): MarkerAnchor {
    return this.nativeInstance.getAnchor() as MarkerAnchor;
  }

  setAnchor(u: number, v: number): Marker {
    this.nativeInstance.setAnchor(u, v);
    return this;
  }

  getDraggable(): boolean {
    return this.nativeInstance.getDraggable();
  }

  setDraggable(draggable: boolean): Marker {
    this.nativeInstance.setDraggable(draggable);
    return this;
  }

  getVisible(): boolean {
    return this.nativeInstance.getVisible();
  }

  setVisible(visible: boolean): Marker {
    this.nativeInstance.setVisible(visible);
    return this;
  }

  isSelected(): boolean {
    return this.nativeInstance.isSelected();
  }

  showInfoWindow(): void {
    // Display the InfoWindow via MapLibreMap (ETS layer implementation)
    if (this._map) {
      this._map.showInfoWindow(this);
    } else {
      console.warn('[Marker] Cannot show InfoWindow: marker not added to map');
    }
  }

  hideInfoWindow(): void {
    // Hide the InfoWindow via MapLibreMap (ETS layer implementation)
    if (this._map) {
      this._map.hideInfoWindow(this);
    }
  }

  isInfoWindowShown(): boolean {
    // Query InfoWindow state via InfoWindowManager
    if (this._map) {
      const infoWindow = this._map.getInfoWindowManager().get(this);
      return infoWindow ? infoWindow.isShown() : false;
    }
    return false;
  }

  // ========== Extended methods used by MarkerManager ==========

  /**
   * Get the marker ID (internal use).
   */
  getId(): number {
    return this._id;
  }

  /**
   * Set the marker ID (internal use).
   */
  setId(id: number): Marker {
    this._id = id;
    return this;
  }

  /**
   * Associate the marker with a MapLibreMap (internal use).
   */
  setMapLibreMap(map: MapLibreMap): Marker {
    this._map = map;
    return this;
  }

  /**
   * Set the selection state (internal use).
   */
  setSelected(selected: boolean): Marker {
    this._selected = selected;
    return this;
  }

  /**
   * Get the drag state (internal use).
   */
  getDragState(): number {
    return this._dragState;
  }

  /**
   * Set the drag state (internal use).
   */
  setDragState(state: number): Marker {
    this._dragState = state;
    return this;
  }

  /**
   * Remove the marker (internal use).
   */
  remove(): void {
    // Placeholder for MarkerManager usage
  }

  /**
   * Animate the marker to a target position.
   */
  animateToPosition(position: LatLng, duration: number): void {
    // Animation hook
  }

  /**
   * Animate marker opacity.
   */
  animateAlpha(alpha: number, duration: number): void {
    // Animation hook
  }

  /**
   * Animate marker rotation.
   */
  animateRotation(rotation: number, duration: number): void {
    // Animation hook
  }
}
