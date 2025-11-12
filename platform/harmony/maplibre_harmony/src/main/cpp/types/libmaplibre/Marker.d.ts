import { Icon } from './Icon';

/**
 * Marker - map annotation point.
 *
 * Represents a point annotation that can display icons, titles, and snippets.
 *
 * Implemented in the C++ NAPI layer and consumed directly from ETS.
 *
 * References:
 * - Android: org.maplibre.android.annotations.Marker
 * - iOS: MLNPointAnnotation
 */
export class Marker {
  /**
   * Constructor.
   *
   * @param options Marker options.
   */
  constructor(options: MarkerOptions);

  // Getter methods

  /**
   * Get the marker position.
   *
   * @returns LatLng coordinate.
   */
  getPosition(): LatLng;

  /**
   * Get the marker icon identifier.
   *
   * @returns Icon identifier or null.
   */
  getIcon(): string | null;

  /**
   * Get the marker title.
   *
   * @returns Title text.
   */
  getTitle(): string;

  /**
   * Get the marker snippet.
   *
   * @returns Snippet text.
   */
  getSnippet(): string;

  /**
   * Get the marker annotation identifier.
   *
   * @returns Annotation ID (or -1 if not added to the map).
   */
  getId(): number;

  /**
   * Determine whether the marker is visible.
   *
   * @returns True when visible.
   */
  getVisible(): boolean;

  /**
   * Get the marker alpha value.
   *
   * @returns Alpha value (0.0 - 1.0).
   */
  getAlpha(): number;

  /**
   * Get the marker rotation.
   *
   * @returns Rotation in degrees.
   */
  getRotation(): number;

  /**
   * Determine whether the marker is draggable.
   *
   * @returns True when draggable.
   */
  getDraggable(): boolean;

  /**
   * Get the marker Z-index.
   *
   * @returns Z-index value.
   */
  getZIndex(): number;

  // Setter methods

  /**
   * Set the marker position.
   *
   * @param position LatLng coordinate.
   * @returns this (chainable).
   */
  setPosition(position: LatLng): Marker;

  /**
   * Set the marker icon.
   *
   * Supports two input forms:
   * 1. Icon instance (recommended): NAPI icon created via IconFactory (best performance).
   * 2. Icon identifier string (legacy): requires calling addAnnotationIcon beforehand.
   *
   * @param icon Icon instance or icon identifier (null removes the icon).
   * @returns this (chainable).
   *
   * @example
   * ```typescript
   * // Recommended: use an Icon instance.
   * const factory = IconFactory.getInstance();
   * const icon = await factory.fromResource($r('app.media.marker'));
   * marker.setIcon(icon);
   *
   * // Legacy: use a string identifier.
   * marker.setIcon('my-icon-id');
   * ```
   */
  setIcon(icon: Icon | string | null): Marker;

  /**
   * Set the marker title.
   *
   * @param title Title text.
   * @returns this (chainable).
   */
  setTitle(title: string): Marker;

  /**
   * Set the marker snippet.
   *
   * @param snippet Snippet text.
   * @returns this (chainable).
   */
  setSnippet(snippet: string): Marker;

  /**
   * Set marker visibility.
   *
   * @param visible True when visible.
   * @returns this (chainable).
   */
  setVisible(visible: boolean): Marker;

  /**
   * Set the marker alpha.
   *
   * @param alpha Alpha value (0.0 - 1.0).
   * @returns this (chainable).
   */
  setAlpha(alpha: number): Marker;

  /**
   * Set the marker rotation.
   *
   * @param rotation Rotation in degrees.
   * @returns this (chainable).
   */
  setRotation(rotation: number): Marker;

  /**
   * Set whether the marker is draggable.
   *
   * @param draggable True when draggable.
   * @returns this (chainable).
   */
  setDraggable(draggable: boolean): Marker;

  /**
   * Set the marker Z-index.
   *
   * @param zIndex Z-index value.
   * @returns this (chainable).
   */
  setZIndex(zIndex: number): Marker;

  /**
   * Mark the marker as removed from the map.
   *
   * Note: this only flags the marker as removed.
   * The actual removal requires calling MapLibreMap.removeMarker().
   */
  remove(): void;

  // InfoWindow methods

  /**
   * Show the info window.
   */
  showInfoWindow(): void;

  /**
   * Hide the info window.
   */
  hideInfoWindow(): void;

  /**
   * Determine whether the info window is visible.
   */
  isInfoWindowShown(): boolean;

  // Selection methods

  /**
   * Check whether the marker is selected.
   */
  isSelected(): boolean;

  /**
   * Set marker selection state.
   * @returns this (chainable).
   */
  setSelected(selected: boolean): Marker;

  // Drag state methods

  /**
   * Get the drag state.
   * 0 = None, 1 = Start, 2 = Drag, 3 = End.
   */
  getDragState(): number;

  /**
   * Set the drag state.
   * @returns this (chainable).
   */
  setDragState(state: number): Marker;

  // Internal methods (used by MarkerManager)

  /**
   * Assign the annotation ID (internal use).
   * @internal
   * @returns this (chainable).
   */
  setId(id: number): Marker;

  // Note: setMapLibreMap is an internal detail and not part of the public API.
  // ETS marker wrappers manage the association with MapLibreMap.

  // Animation methods

  /**
   * Animate the marker to a target position.
   *
   * @param targetPosition Target coordinate.
   * @param duration Duration in milliseconds.
   * @param onComplete Optional completion callback.
   */
  animateToPosition(targetPosition: LatLng, duration: number, onComplete?: () => void): void;

  /**
   * Animate marker alpha.
   *
   * @param targetAlpha Target alpha (0.0-1.0).
   * @param duration Duration in milliseconds.
   * @param onComplete Optional completion callback.
   */
  animateAlpha(targetAlpha: number, duration: number, onComplete?: () => void): void;

  /**
   * Animate marker rotation.
   *
   * @param targetRotation Target rotation in degrees.
   * @param duration Duration in milliseconds.
   * @param onComplete Optional completion callback.
   */
  animateRotation(targetRotation: number, duration: number, onComplete?: () => void): void;

  // Anchor methods

  /**
   * Get the anchor.
   *
   * @returns Anchor object { u: number, v: number }.
   */
  getAnchor(): { u: number, v: number };

  /**
   * Set the anchor.
   *
   * The anchor determines how the icon aligns relative to the marker position.
   * (0.5, 1.0) means bottom-center alignment (default).
   * (0.0, 0.0) means top-left alignment.
   * (1.0, 1.0) means bottom-right alignment.
   *
   * @param u Horizontal anchor (0.0 - 1.0).
   * @param v Vertical anchor (0.0 - 1.0).
   * @returns this (chainable).
   */
  setAnchor(u: number, v: number): Marker;
}

/**
 * MarkerOptions - constructor options.
 */
export interface MarkerOptions {
  /**
   * Marker geographic position (required).
   */
  position: LatLng;

  /**
   * Icon identifier (optional).
   *
   * If omitted, the marker is invisible.
   * Requires addAnnotationIcon() to register the resource first.
   */
  icon?: string;

  /**
   * Title (optional).
   */
  title?: string;

  /**
   * Snippet text (optional).
   */
  snippet?: string;

  /**
   * Visibility flag (optional, default true).
   */
  visible?: boolean;

  /**
   * Alpha value (optional, default 1.0).
   * Range: 0.0 fully transparent – 1.0 fully opaque.
   */
  alpha?: number;

  /**
   * Rotation (optional, default 0).
   * Unit: degrees.
   */
  rotation?: number;

  /**
   * Draggable flag (optional, default false).
   */
  draggable?: boolean;

  /**
   * Z-index (optional, default 0).
   * Higher values render above lower ones.
   */
  zIndex?: number;

  /**
   * Anchor (optional, default {u: 0.5, v: 1.0}).
   * Controls icon alignment relative to the marker position.
   */
  anchor?: { u: number, v: number };
}

/**
 * LatLng - geographic coordinate.
 */
export interface LatLng {
  /**
   * Latitude.
   */
  latitude: number;

  /**
   * Longitude.
   */
  longitude: number;
}

