/**
 * MapLibre Native for HarmonyOS - Type Definitions
 * NativeMapView C++ NAPI Bindings
 */

import image from '@ohos.multimedia.image';
import type { Style } from './Style';
import type { Icon } from './Icon';
import type { Image } from './images/Image';
import type { Marker } from './Marker';
import type { Polygon } from './annotations/Polygon';
import type { Polyline } from './annotations/Polyline';
import type { Layer } from './layers';
import type { Source } from './sources';
import type { IFeature, Geometry } from './geojson';
import type { ExpressionLiteral } from './ExpressionTypes';
import type { LightSpecification, MapSnapshotterObserver } from './CommonTypes';
import type { Light } from './light/Light';

// ==================== Type Definitions ====================

/**
 * Latitude/longitude coordinate interface.
 * Note: LatLng is implemented in the ETS layer; this interface preserves type compatibility.
 */
export interface LatLng {
  latitude: number;
  longitude: number;
}

/**
 * Latitude/longitude bounds interface.
 * Note: LatLngBounds is implemented in the ETS layer; this interface preserves type compatibility.
 */
export interface LatLngBounds {
  north: number;
  east: number;
  south: number;
  west: number;
}

/**
 * Edge insets interface.
 * Note: EdgeInsets is implemented in the ETS layer; this interface preserves type compatibility.
 */
export interface EdgeInsets {
  top: number;
  left: number;
  bottom: number;
  right: number;
}

/**
 * Camera position interface.
 * Note: CameraPosition is implemented in the ETS layer; this interface preserves type compatibility.
 */
export interface CameraPosition {
  target: LatLng;
  zoom: number;
  bearing: number;
  tilt: number;
}

/**
 * Camera options interface.
 * Used to configure camera parameters.
 */
export interface CameraOptions {
  /** Center coordinate. */
  center?: LatLng;

  /** Zoom level. */
  zoom?: number;

  /** Bearing in degrees. */
  bearing?: number;

  /** Pitch in degrees. */
  pitch?: number;

  /** Padding. */
  padding?: EdgeInsets;
}

// ========== Listener interface definitions ==========

export type OnCameraWillChangeListener = (animated: boolean) => void;

export type OnCameraIsChangingListener = () => void;

export type OnCameraDidChangeListener = (animated: boolean) => void;

export type OnWillStartLoadingMapListener = () => void;

export type OnDidFinishLoadingMapListener = () => void;

export type OnDidFailLoadingMapListener = (errorMessage: string) => void;

export type OnWillStartRenderingFrameListener = () => void;

export type OnDidFinishRenderingFrameListener = (fully: boolean, frameEncodingTime: number, frameRenderingTime: number) => void;

export interface RenderingStats {
  fully: boolean;
  frameEncodingTime: number;
  frameRenderingTime: number;
}

export type OnDidFinishRenderingFrameWithStatsListener = (fully: boolean, stats: RenderingStats) => void;

export type OnWillStartRenderingMapListener = () => void;

export type OnDidFinishRenderingMapListener = (fully: boolean) => void;

export type OnDidFinishLoadingStyleListener = () => void;

export type OnCanRemoveUnusedStyleImageListener = (id: string) => boolean;

export type OnDidBecomeIdleListener = () => void;

export type OnSourceChangedListener = (id: string) => void;

/**
 * Rectangle interface (used for queries and other operations).
 */
export interface Rect {
  left: number;
  top: number;
  right: number;
  bottom: number;
}

/**
 * Native ViewAnnotation anchor.
 */
export interface NativeViewAnnotationAnchor {
  latitude: number;
  longitude: number;
}

/**
 * Native ViewAnnotation offset.
 */
export interface NativeViewAnnotationCenterOffset {
  dx: number;
  dy: number;
}

/**
 * Native ViewAnnotation creation/update options.
 */
export interface NativeViewAnnotationOptions {
  anchor: NativeViewAnnotationAnchor;
  width?: number;
  height?: number;
  anchorHeight?: number;  // Height for anchor positioning (e.g., marker icon height)
  centerOffset?: NativeViewAnnotationCenterOffset;
  visible?: boolean;
  allowOverlap?: boolean;
  draggable?: boolean;
  scalesWithViewingDistance?: boolean;
  rotatesWithCamera?: boolean;
  minZoom?: number;
  maxZoom?: number;
}

/**
 * Native ViewAnnotation frame information.
 */
export interface NativeViewAnnotationFrame {
  id: number;
  x: number;
  y: number;
  width: number;
  height: number;
  offsetX: number;
  offsetY: number;
  scale: number;
  rotation: number;
  opacity: number;
  pixelRatio: number;
  visible: boolean;
  draggable: boolean;
}

// ==================== NativeMapView Class ====================

/**
 * MapLibre Native Map View
 * Provides the underlying C++ bindings for map rendering and interaction.
 */
export class NativeMapView {
  /**
   * Query source features.
   * @param sourceId Source identifier.
   * @param sourceLayerIds Array of source layer identifiers.
   * @param filter Filter expression.
   * @returns Array of IFeature.
   */
  querySourceFeatures(sourceId: string, sourceLayerIds: string[] | undefined, filter: ExpressionLiteral | undefined): IFeature[]
  
  /**
   * Create a NativeMapView instance.
   * @param cachePath Required application cache directory path. Suggested value: context.cacheDir + '/maplibre'.
   */
  constructor(cachePath: string);

  // ========== View Management ==========

  /**
   * Resize the map view.
   * @param width Width in logical pixels.
   * @param height Height in logical pixels.
   */
  resizeView(width: number, height: number): void;

  /**
   * Set content padding (aligned with the Android API).
   * @param padding Padding array [top, left, bottom, right] in logical pixels.
   */
  setContentPadding(padding: number[]): void;

  /**
   * Get the current content padding (aligned with the Android API).
   * @returns Padding array [top, left, bottom, right].
   */
  getContentPadding(): number[];

  /**
   * Get the device pixel ratio (aligned with the Android API).
   * @returns Pixel ratio (for example 2.0 or 3.0).
   */
  getPixelRatio(): number;

  /**
   * Adjust a rectangle based on the device pixel ratio (aligned with the Android API).
   * @param rectangle Input rectangle.
   * @returns Adjusted rectangle.
   */
  getDensityDependantRectangle(rectangle: Rect): Rect;

  /**
   * Configure the local ideograph font family (aligned with the Android/iOS API).
   * Used to render CJK glyphs locally to avoid downloading large font data sets.
   * Note: This operation reinitializes the renderer and reloads the style.
   * @param fontFamily Font family name (for example, "HarmonyOS_Sans"). Null disables the local renderer.
   */
  setLocalIdeographFontFamily(fontFamily: string | null): void;

  /**
   * Get the currently configured local ideograph font family (aligned with the Android/iOS API).
   * @returns The configured font family name, or null if disabled.
   */
  getLocalIdeographFontFamily(): string | null;

  /**
   * Set the native window.
   * @param surfaceId Surface identifier.
   */
  setNativeWindow(surfaceId: BigInt): void;

  /**
   * Set the native window with explicit dimensions.
   * @param surfaceId Surface identifier.
   * @param width Width in logical pixels.
   * @param height Height in logical pixels.
   */
  setNativeWindowWithSize(surfaceId: BigInt, width: number, height: number): void;

  /**
   * Force-reset the renderer and rendering context (hard reset).
   * - Release the current renderer/thread.
   * - Clear and rebuild the cache directory.
   * - Recreate the renderer and context.
   * - Rebind the window and restore its size if already attached.
   */
  hardReset(): void;

  /**
   * Destroy the map instance and release all resources.
   *
   * In thread-isolation mode this releases:
   * - EGL context (instance-specific).
   * - EGL surface (instance-specific).
   * - Render thread (instance-specific).
   * - Map object and related resources.
   *
   * Not released:
   * - EGL display (shared by the process).
   *
   * Notes:
   * - The map instance becomes unusable after destruction.
   * - Safe to call multiple times (re-entrancy guard in place).
   * - Recommended to call during component aboutToDisappear().
   */
  destroy(): void;

  /**
   * Destroy map resources asynchronously (similar to Android/iOS).
   * Uses an asynchronous callback instead of a blocking wait to avoid blocking the main thread.
   * @param callback Callback invoked when destruction completes.
   */
  destroyAsync(callback: () => void): void;

  /**
   * Cancel all pending network requests.
   *
   * This method cancels all ongoing HTTP requests to prevent callbacks from
   * accessing destroyed objects during page transitions. This is critical
   * for preventing SIGSEGV crashes when the map is destroyed.
   *
   * Call this method during page lifecycle transitions (onPageHide, aboutToDisappear)
   * before destroying the map controller.
   */
  cancelAllRequests(): void;

  // ========== Style Management ==========

  /**
   * Get the current style URL.
   * @returns Style URL.
   */
  getStyleUrl(): string;

  /**
   * Set the style URL.
   * @param url Style URL.
   */
  setStyleUrl(url: string): void;

  /**
   * Get the current style JSON.
   * @returns Style JSON string.
   */
  getStyleJson(): string;

  /**
   * Set the style JSON.
   * @param json Style JSON string.
   */
  setStyleJson(json: string): void;

  /**
   * Get the style object.
   * @returns Style instance, or null if the style is not loaded.
   */
  getStyle(): Style | null;

  /**
   * Set latitude/longitude bounds.
   * @param bounds Bounds object.
   */
  setLatLngBounds(bounds: LatLngBounds | null): void;

  // ========== Camera Control ==========

  /**
   * Cancel all active transitions.
   */
  cancelTransitions(): void;

  /**
   * Set gesture-in-progress state.
   * @param inProgress Whether gestures are currently active.
   */
  setGestureInProgress(inProgress: boolean): void;

  /**
   * Pan the map.
   * @param dx X-axis offset in pixels.
   * @param dy Y-axis offset in pixels.
   * @param duration Animation duration in milliseconds.
   */
  moveBy(dx: number, dy: number, duration: number): void;

  /**
   * Jump to a camera position immediately (without animation).
   * @param angle Bearing in degrees.
   * @param latitude Latitude.
   * @param longitude Longitude.
   * @param pitch Pitch in degrees.
   * @param zoom Zoom level.
   * @param padding Optional padding array [top, left, bottom, right].
   */
  jumpTo(angle: number, latitude: number, longitude: number, pitch: number, zoom: number, padding?: number[]): void;

  /**
   * Smoothly transition to a camera position.
   * @param options Camera options.
   * @param duration Animation duration in milliseconds.
   */
  easeTo(options: CameraOptions, duration: number): void;

  /**
   * Fly the camera to a position.
   * @param options Camera options.
   * @param duration Animation duration in milliseconds.
   */
  flyTo(options: CameraOptions, duration: number): void;

  // ========== Position and Camera ==========

  /**
   * Get the map center coordinate.
   * @returns Latitude/longitude coordinate.
   */
  getLatLng(): LatLng;

  /**
   * Set the map center coordinate.
   * @param latitude Latitude.
   * @param longitude Longitude.
   * @param padding Optional padding array.
   * @param duration Optional animation duration in milliseconds.
   */
  setLatLng(latitude: number, longitude: number, padding?: number[], duration?: number): void;

  /**
   * Get camera parameters that fit given latitude/longitude bounds.
   * @param bounds Bounds object.
   * @param top Top padding.
   * @param left Left padding.
   * @param bottom Bottom padding.
   * @param right Right padding.
   * @param bearing Optional bearing.
   * @param tilt Optional tilt.
   * @returns Camera position object.
   */
  getCameraForLatLngBounds(bounds: LatLngBounds, top: number, left: number, bottom: number, right: number,
    bearing?: number, tilt?: number): CameraPosition;

  /**
   * Get camera parameters that fit a geometry.
   * @param geometry Geometry object.
   * @param top Top padding.
   * @param left Left padding.
   * @param bottom Bottom padding.
   * @param right Right padding.
   * @param bearing Optional bearing.
   * @param tilt Optional tilt.
   * @returns Camera position object.
   */
  getCameraForGeometry(geometry: Geometry, top: number, left: number, bottom: number, right: number, bearing?: number,
    tilt?: number): CameraPosition;

  /**
   * Configure network reachability.
   * @param status Whether the network is reachable.
   */
  setReachability(status: boolean): void;

  /**
   * Reset the map position to its initial value.
   */
  resetPosition(): void;

  /**
   * Get the current camera position.
   * @returns Camera position object.
   */
  getCameraPosition(): CameraPosition;

  // ========== Pitch Control ==========

  /**
   * Get the current pitch.
   * @returns Pitch in degrees.
   */
  getPitch(): number;

  /**
   * Set the pitch.
   * @param pitch Pitch in degrees (0-60).
   * @param duration Optional animation duration in milliseconds.
   */
  setPitch(pitch: number, duration?: number): void;

  /**
   * Set the minimum pitch.
   * @param pitch Minimum pitch in degrees.
   */
  setMinPitch(pitch: number): void;

  /**
   * Get the minimum pitch.
   * @returns Minimum pitch in degrees.
   */
  getMinPitch(): number;

  /**
   * Set the maximum pitch.
   * @param pitch Maximum pitch in degrees.
   */
  setMaxPitch(pitch: number): void;

  /**
   * Get the maximum pitch.
   * @returns Maximum pitch in degrees.
   */
  getMaxPitch(): number;

  // ========== Zoom Control ==========

  /**
   * Set the zoom level.
   * @param zoom Zoom level.
   * @param cx Optional center X coordinate.
   * @param cy Optional center Y coordinate.
   * @param duration Optional animation duration in milliseconds.
   */
  setZoom(zoom: number, cx?: number, cy?: number, duration?: number): void;

  /**
   * Get the current zoom level.
   * @returns Zoom level.
   */
  getZoom(): number;

  /**
   * Reset the zoom level to its default value.
   */
  resetZoom(): void;

  /**
   * Set the minimum zoom level.
   * @param zoom Minimum zoom level.
   */
  setMinZoom(zoom: number): void;

  /**
   * Get the minimum zoom level.
   * @returns Minimum zoom level.
   */
  getMinZoom(): number;

  /**
   * Set the maximum zoom level.
   * @param zoom Maximum zoom level.
   */
  setMaxZoom(zoom: number): void;

  /**
   * Get the maximum zoom level.
   * @returns Maximum zoom level.
   */
  getMaxZoom(): number;

  // ========== Rotation and Bearing ==========

  /**
   * Rotate the map.
   * @param sx Start point X coordinate.
   * @param sy Start point Y coordinate.
   * @param ex End point X coordinate.
   * @param ey End point Y coordinate.
   * @param duration Optional animation duration in milliseconds.
   */
  rotateBy(sx: number, sy: number, ex: number, ey: number, duration?: number): void;

  /**
   * Set the bearing.
   * @param degrees Bearing in degrees.
   * @param duration Optional animation duration in milliseconds.
   */
  setBearing(degrees: number, duration?: number): void;

  /**
   * Set the bearing using a custom focal point.
   * @param degrees Bearing in degrees.
   * @param fx Focal point X coordinate.
   * @param fy Focal point Y coordinate.
   * @param duration Optional animation duration in milliseconds.
   */
  setBearingXY(degrees: number, fx: number, fy: number, duration?: number): void;

  /**
   * Get the current bearing.
   * @returns Bearing in degrees.
   */
  getBearing(): number;

  /**
   * Reset the bearing to due north (0 degrees).
   */
  resetNorth(): void;

  // ========== Coordinate Bounds ==========

  /**
   * Set the visible coordinate bounds.
   * @param coordinates Coordinate array.
   * @param padding Padding object.
   * @param direction Bearing in degrees.
   * @param duration Animation duration in milliseconds.
   */
  setVisibleCoordinateBounds(coordinates: LatLng[], padding: EdgeInsets, direction: number, duration: number): void;

  /**
   * Get the visible coordinate bounds.
   * @returns Coordinate array.
   */
  getVisibleCoordinateBounds(): LatLng[];

  // ========== Snapshot ==========

  /**
   * Request a single map snapshot; the callback triggers after rendering completes.
   */
  scheduleSnapshot(): void;

  /**
   * Register a snapshot completion callback.
   * @param listener Callback that receives the snapshot result.
   */
  addOnSnapshotReadyListener(listener: (result: MapViewSnapshotPayload) => void): void;

  /**
   * Remove the snapshot completion callback.
   * @param listener Callback to unregister.
   */
  removeOnSnapshotReadyListener(listener: (result: MapViewSnapshotPayload) => void): void;

  /**
   * Register a snapshot error callback.
   * @param listener Callback that receives the error message.
   */
  addOnSnapshotErrorListener(listener: (message: string) => void): void;

  /**
   * Remove the snapshot error callback.
   * @param listener Callback to unregister.
   */
  removeOnSnapshotErrorListener(listener: (message: string) => void): void;

  // ========== Annotations ==========

  /**
   * Update a marker position.
   * @param markerId Marker identifier.
   * @param lat Latitude.
   * @param lon Longitude.
   * @param iconId Icon identifier.
   */
  updateMarker(markerId: number, lat: number, lon: number, iconId: string): void;

  /**
   * Add markers.
   * @param markers Marker array.
   * @returns Array of marker identifiers.
   */
  addMarkers(markers: Marker[]): number[];

  /**
   * Add polylines.
   * @param polylines Polyline array.
   * @returns Array of polyline identifiers.
   */
  addPolylines(polylines: Polyline[]): number[];

  /**
   * Add polygons.
   * @param polygons Polygon array.
   * @returns Array of polygon identifiers.
   */
  addPolygons(polygons: Polygon[]): number[];

  /**
   * Add a ViewAnnotation.
   * @param options Annotation options.
   * @returns Annotation identifier, negative values indicate failure.
   */
  addViewAnnotation(options: NativeViewAnnotationOptions): number;

  /**
   * Update a ViewAnnotation.
   * @param annotationId Annotation identifier.
   * @param options Annotation options.
   * @returns Whether the update succeeded.
   */
  updateViewAnnotation(annotationId: number, options: NativeViewAnnotationOptions): boolean;

  /**
   * Remove a ViewAnnotation.
   * @param annotationId Annotation identifier.
   * @returns Whether the annotation was removed.
   */
  removeViewAnnotation(annotationId: number): boolean;

  /**
   * Get ViewAnnotation frame information.
   * @returns Array of ViewAnnotation frames.
   */
  getViewAnnotationFrames(): NativeViewAnnotationFrame[];

  /**
   * Update a polyline.
   * @param polyline Polyline object (must already exist on the map).
   */
  updatePolyline(polyline: Polyline): void;

  /**
   * Update a polygon.
   * @param polygon Polygon object (must already exist on the map).
   */
  updatePolygon(polygon: Polygon): void;

  /**
   * Remove annotations.
   * @param ids Array of annotation identifiers.
   */
  removeAnnotations(ids: number[]): void;

  /**
   * Add an annotation icon.
   * @param symbol Symbol name.
   * @param width Width.
   * @param height Height.
   * @param scale Scale.
   * @param pixels Pixel data.
   */
  /**
   * Add an annotation icon (recommended approach).
   *
   * Use an Icon instance to avoid extra data copies and improve performance.
   *
   * @param icon Icon instance (created by IconFactory).
   *
   * @example
  * ```typescript
   * const factory = IconFactory.getInstance();
   * const icon = await factory.fromResource($r('app.media.marker'));
   * nativeMapView.addAnnotationIcon(icon);
   * ```
   */
  addAnnotationIcon(icon: Icon): void;

  /**
   * Add an annotation icon (legacy API).
   *
   * Use a byte array converted manually from a PixelMap.
   * Retained for backward compatibility; prefer the Icon-based API.
   *
   * @param symbol Icon identifier.
   * @param width Width in pixels.
   * @param height Height in pixels.
   * @param scale Scale factor.
   * @param pixels Pixel data in RGBA Uint8Array format.
   */
  addAnnotationIcon(symbol: string, width: number, height: number, scale: number, pixels: Uint8Array): void;

  /**
   * Remove an annotation icon.
   * @param symbol Symbol name.
   */
  removeAnnotationIcon(symbol: string): void;

  /**
   * Get the top offset in pixels for an annotation symbol.
   * @param symbolName Symbol name.
   * @returns Offset value in pixels.
   */
  getTopOffsetPixelsForAnnotationSymbol(symbolName: string): number;

  // ========== Memory Management ==========

  /**
   * Handle low-memory warnings.
   */
  onLowMemory(): void;

  // ========== Debug ==========

  /**
   * Configure debug options.
   * Uses a bitmask to enable multiple flags.
   * @param debugOptions Debug options bitmask (MapDebugOptions enum).
   */
  setDebug(debugOptions: number): void;

  /**
   * Get the current debug options.
   * @returns Active debug options bitmask.
   */
  getDebug(): number;

  /**
   * Quickly toggle debug mode (uses the default debug preset).
   * Enables tile borders, tile information, and collision boxes.
   * @param active Whether to enable debug mode.
   */
  setDebugActive(active: boolean): void;

  /**
   * Check whether any debug option is active.
   * @returns True if at least one debug option is enabled.
   */
  isDebugActive(): boolean;

  // ========== Action Journal ==========

  /**
   * Get the list of action journal log files.
   * @returns Array of log file paths.
   */
  getActionJournalLogFiles(): string[];

  /**
   * Get the action journal log entries.
   * @returns Array of log entries.
   */
  getActionJournalLog(): string[];

  /**
   * Clear the action journal log.
   */
  clearActionJournalLog(): void;

  // ========== Loading Status ==========

  /**
   * Check whether the map is fully loaded.
   * @returns True if fully loaded.
   */
  isFullyLoaded(): boolean;

  // ========== Coordinate Conversion ==========

  /**
   * Get meters-per-pixel at a latitude and zoom level (after applying the device pixel ratio).
   * @param latitude Latitude.
   * @param zoom Zoom level.
   * @returns Meters per pixel.
   */
  getMetersPerPixelAtLatitude(latitude: number, zoom: number): number;

  /**
   * Convert latitude/longitude to projected meters.
   * @param latitude Latitude.
   * @param longitude Longitude.
   * @returns Object literal representing the projected meters.
   */
  projectedMetersForLatLng(latitude: number, longitude: number): { northing: number; easting: number; };

  /**
   * Convert latitude/longitude to physical pixel coordinates (after applying the device pixel ratio).
   * @param latitude Latitude.
   * @param longitude Longitude.
   * @returns Object literal representing pixel coordinates in physical pixels.
   */
  pixelForLatLng(latitude: number, longitude: number): { x: number; y: number; };

  /**
   * Bulk convert latitude/longitude values to physical pixel coordinates (after applying the device pixel ratio).
   * @param input Input latitude/longitude array [lat1, lon1, lat2, lon2, ...].
   * @param output Output pixel array [x1, y1, x2, y2, ...] in physical pixels.
   */
  pixelsForLatLngs(input: number[], output: number[]): void;

  /**
   * Convert projected meters to latitude/longitude.
   * @param northing Northing.
   * @param easting Easting.
   * @returns Latitude/longitude coordinate.
   */
  latLngForProjectedMeters(northing: number, easting: number): LatLng;

  /**
   * Convert physical pixel coordinates to latitude/longitude (after applying the device pixel ratio).
   * @param x X coordinate in physical pixels.
   * @param y Y coordinate in physical pixels.
   * @returns Latitude/longitude coordinate.
   */
  latLngForPixel(x: number, y: number): LatLng;

  /**
   * Bulk convert physical pixel coordinates to latitude/longitude (after applying the device pixel ratio).
   * @param input Input pixel array [x1, y1, x2, y2, ...] in physical pixels.
   * @param output Output latitude/longitude array [lat1, lon1, lat2, lon2, ...].
   */
  latLngsForPixels(input: number[], output: number[]): void;

  // ========== Transitions ==========

  /**
   * Get transition options.
   * @returns Object literal representing transition options.
   */
  getTransitionOptions(): { duration?: number; delay?: number; };

  /**
   * Set transition options.
   * @param options Object literal representing transition options.
   */
  setTransitionOptions(options: { duration?: number; delay?: number; }): void;

  // ========== Query ==========

  /**
   * Query rendered features at a point.
   * @param x X coordinate in pixels.
   * @param y Y coordinate in pixels.
   * @param layerIds Optional array of layer identifiers; queries all layers when undefined.
   * @param filter Optional filter expression.
   * @returns Array of GeoJSON IFeature.
   */
  queryRenderedFeaturesForPoint(x: number, y: number, layerIds?: string[], filter?: ExpressionLiteral): IFeature[];

  /**
   * Query rendered features within a bounding box.
   * @param left Left boundary in pixels.
   * @param top Top boundary in pixels.
   * @param right Right boundary in pixels.
   * @param bottom Bottom boundary in pixels.
   * @param layerIds Optional array of layer identifiers; queries all layers when undefined.
   * @param filter Optional filter expression.
   * @returns Array of GeoJSON IFeature.
   */
  queryRenderedFeaturesForBox(left: number, top: number, right: number, bottom: number, layerIds?: string[],
    filter?: ExpressionLiteral): IFeature[];

  // ========== Light ==========

  /**
   * Get the light configuration.
   * @returns Light object (NAPI Light instance) or null if not defined in the style.
   */
  getLight(): Light | null;

  // ========== Layers ==========

  /**
   * Get all layers.
   * @returns Array of layers.
   */
  getLayers(): Layer[];

  /**
   * Get a layer by identifier.
   * @param layerId Layer identifier.
   * @returns Layer instance or null if not found.
   */
  getLayer(layerId: string): Layer | null;

  /**
   * Add a layer.
   * @param layer Layer instance.
   */
  addLayer(layer: Layer): void;

  /**
   * Add a layer above another layer.
   * @param layer Layer instance.
   * @param aboveLayerId Reference layer identifier.
   */
  addLayerAbove(layer: Layer, aboveLayerId: string): void;

  /**
   * Add a layer at a specific index.
   * @param layer Layer instance.
   * @param index Target index.
   */
  addLayerAt(layer: Layer, index: number): void;

  /**
   * Remove a layer at a specific index.
   * @param index Target index.
   * @returns True if the layer was removed.
   */
  removeLayerAt(index: number): boolean;

  /**
   * Remove a layer.
   * @param layer Layer instance.
   * @returns True if the layer was removed.
   */
  removeLayer(layer: Layer): boolean;

  // ========== Sources ==========

  /**
   * Get all sources.
   * @returns Array of sources.
   */
  getSources(): Source[];

  /**
   * Get a source by identifier.
   * @param sourceId Source identifier.
   * @returns Source instance or null if not found.
   */
  getSource(sourceId: string): Source | null;

  /**
   * Add a source.
   * @param source Source instance.
   */
  addSource(source: Source): void;

  /**
   * Remove a source.
   * @param source Source instance.
   * @returns True if the source was removed.
   */
  removeSource(source: Source): boolean;

  // ========== Images ==========

  /**
   * Add an image directly from a HarmonyOS PixelMap.
   * @param name Image name.
   * @param bitmap PixelMap bitmap data (HarmonyOS PixelMap instance).
   * @param pixelRatio Pixel ratio, defaults to 1.0.
   * @param sdf Whether the image is an SDF glyph.
   *
   * @remarks
   * Internally converts the PixelMap to a `PremultipliedImage` and registers it on the render thread.
   * A successful addition automatically triggers a map repaint.
   */
  addImage(name: string, bitmap: image.PixelMap, pixelRatio: number, sdf: boolean): void;

  /**
   * Add multiple images.
   * @param images Array of Image instances.
   */
  addImages(images: Image[]): void;

  /**
   * Remove an image.
   * @param name Image name.
   */
  removeImage(name: string): void;

  /**
   * Get an image.
   * @param name Image name.
   * @returns Icon instance or null if not found.
   */
  getImage(name: string): Icon | null;

  // ========== Tile Management ==========

  /**
   * Enable or disable tile prefetching.
   * @param enable Whether to enable prefetching.
   */
  setPrefetchTiles(enable: boolean): void;

  /**
   * Query the tile prefetching state.
   * @returns True if prefetching is enabled.
   */
  getPrefetchTiles(): boolean;

  /**
   * Set the prefetch zoom delta.
   * @param delta Zoom delta.
   */
  setPrefetchZoomDelta(delta: number): void;

  /**
   * Get the prefetch zoom delta.
   * @returns Zoom delta.
   */
  getPrefetchZoomDelta(): number;

  /**
   * Enable or disable the tile cache.
   * @param enabled Whether to enable caching.
   */
  setTileCacheEnabled(enabled: boolean): void;

  /**
   * Query the tile cache state.
   * @returns True if caching is enabled.
   */
  getTileCacheEnabled(): boolean;

  // ========== Tile LOD ==========

  /**
   * Set the tile LOD minimum radius.
   * @param radius Minimum radius.
   */
  setTileLodMinRadius(radius: number): void;

  /**
   * Get the tile LOD minimum radius.
   * @returns Minimum radius.
   */
  getTileLodMinRadius(): number;

  /**
   * Set the tile LOD scale.
   * @param scale Scale factor.
   */
  setTileLodScale(scale: number): void;

  /**
   * Get the tile LOD scale.
   * @returns Scale factor.
   */
  getTileLodScale(): number;

  /**
   * Set the tile LOD pitch threshold.
   * @param threshold Pitch threshold.
   */
  setTileLodPitchThreshold(threshold: number): void;

  /**
   * Get the tile LOD pitch threshold.
   * @returns Pitch threshold.
   */
  getTileLodPitchThreshold(): number;

  /**
   * Set the tile LOD zoom shift.
   * @param shift Zoom shift.
   */
  setTileLodZoomShift(shift: number): void;

  /**
   * Get the tile LOD zoom shift.
   * @returns Zoom shift.
   */
  getTileLodZoomShift(): number;

  // ========== Rendering ==========

  /**
   * Trigger a map repaint.
   */
  triggerRepaint(): void;

  /**
   * Check whether the rendering stats overlay is enabled.
   * @returns True if enabled.
   */
  isRenderingStatsViewEnabled(): boolean;

  /**
   * Enable or disable the rendering stats overlay.
   * @param enabled Whether to enable the overlay.
   */
  enableRenderingStatsView(enabled: boolean): void;

  // ========== Performance Configuration (aligned with Android MapRenderer) ==========

  /**
   * Set the maximum frames per second (similar to Android MapView.setMaximumFps).
   * @param maximumFps Maximum FPS, for example 30 or 60.
   */
  setMaximumFps(maximumFps: number): void;

  /**
   * Set the rendering refresh mode (similar to Android MapView.setRenderingRefreshMode).
   * @param mode Rendering mode: 0 = CONTINUOUS, 1 = WHEN_DIRTY.
   */
  setRenderingRefreshMode(mode: number): void;

  /**
   * Get the rendering refresh mode (similar to Android MapView.getRenderingRefreshMode).
   * @returns Current rendering mode: 0 = CONTINUOUS, 1 = WHEN_DIRTY.
   */
  getRenderingRefreshMode(): number;

  /**
   * Set the FPS change listener (similar to Android MapView.setOnFpsChangedListener).
   * Use to monitor rendering frame rate in real time.
   * @param listener Callback receiving the current FPS; pass null to remove the listener.
   */
  setOnFpsChangedListener(listener: ((fps: number) => void) | null): void;

  // ========== Map Lifecycle Listeners ==========

  /**
   * Set the map-created callback (aligned with Android onMapViewReady).
   * 
   * Triggered after the C++ map object is created and before the style loads.
   * Use it to register observers before style initialization.
   * 
   * @param callback Callback invoked when the C++ map is ready; pass null to remove.
   */
  setOnMapViewCreatedCallback(callback: (() => void) | null): void;

  /**
   * Set the style-loaded listener.
   * @param callback Invoked when the style finishes loading.
   */
  setOnStyleLoadedListener(callback: (() => void) | null): void;

  /**
   * Set the style-load-error listener.
   * @param callback Invoked when style loading fails.
   */
  setOnStyleLoadErrorListener(callback: ((error: string) => void) | null): void;

  // ========== Camera Listeners ==========

  /**
   * Add a camera idle listener.
   * @param callback Callback function.
   */
  addOnCameraIdleListener(callback: () => void): void;

  /**
   * Remove a camera idle listener.
   * @param callback Callback function.
   */
  removeOnCameraIdleListener(callback: () => void): void;

  /**
   * Add a camera-move-start listener.
   * @param callback Callback function receiving the move reason.
   */
  addOnCameraMoveStartedListener(callback: (reason: number) => void): void;

  /**
   * Remove a camera-move-start listener.
   * @param callback Callback function.
   */
  removeOnCameraMoveStartedListener(callback: (reason: number) => void): void;

  /**
   * Add a camera-moving listener.
   * @param callback Callback function.
   */
  addOnCameraMoveListener(callback: () => void): void;

  /**
   * Remove a camera-moving listener.
   * @param callback Callback function.
   */
  removeOnCameraMoveListener(callback: () => void): void;

  /**
   * Add a camera-move-canceled listener.
   * @param callback Callback function.
   */
  addOnCameraMoveCanceledListener(callback: () => void): void;

  /**
   * Remove a camera-move-canceled listener.
   * @param callback Callback function.
   */
  removeOnCameraMoveCanceledListener(callback: () => void): void;

  // ========== Android/iOS style listeners (new additions) ==========

  // Camera event listeners
  /**
   * Add a camera-will-change listener.
   * @param callback Callback receiving whether the change is animated.
   */
  addOnCameraWillChangeListener(listener: OnCameraWillChangeListener): void;

  removeOnCameraWillChangeListener(listener: OnCameraWillChangeListener): void;

  /**
   * Add a camera-is-changing listener.
   * @param callback Callback function.
   */
  addOnCameraIsChangingListener(listener: OnCameraIsChangingListener): void;

  removeOnCameraIsChangingListener(listener: OnCameraIsChangingListener): void;

  /**
   * Add a camera-did-change listener.
   * @param callback Callback receiving whether the change was animated.
   */
  addOnCameraDidChangeListener(listener: OnCameraDidChangeListener): void;

  removeOnCameraDidChangeListener(listener: OnCameraDidChangeListener): void;

  // Map loading listeners
  /**
   * Add a will-start-loading-map listener.
   * @param callback Callback function.
   */
  addOnWillStartLoadingMapListener(listener: OnWillStartLoadingMapListener): void;

  removeOnWillStartLoadingMapListener(listener: OnWillStartLoadingMapListener): void;

  /**
   * Add a did-finish-loading-map listener.
   * @param callback Callback function.
   */
  addOnDidFinishLoadingMapListener(listener: OnDidFinishLoadingMapListener): void;

  removeOnDidFinishLoadingMapListener(listener: OnDidFinishLoadingMapListener): void;

  /**
   * Add a did-fail-loading-map listener.
   * @param callback Callback receiving the error message.
   */
  addOnDidFailLoadingMapListener(listener: OnDidFailLoadingMapListener): void;

  removeOnDidFailLoadingMapListener(listener: OnDidFailLoadingMapListener): void;

  // Rendering listeners
  /**
   * Add a will-start-rendering-frame listener.
   * @param callback Callback function.
   */
  addOnWillStartRenderingFrameListener(listener: OnWillStartRenderingFrameListener): void;

  removeOnWillStartRenderingFrameListener(listener: OnWillStartRenderingFrameListener): void;

  /**
   * Add a did-finish-rendering-frame listener.
   * @param callback Callback receiving whether rendering finished fully and the encoding/rendering timings.
   */
  addOnDidFinishRenderingFrameListener(listener: OnDidFinishRenderingFrameListener): void;

  removeOnDidFinishRenderingFrameListener(listener: OnDidFinishRenderingFrameListener): void;

  addOnDidFinishRenderingFrameWithStatsListener(listener: OnDidFinishRenderingFrameWithStatsListener): void;

  removeOnDidFinishRenderingFrameWithStatsListener(listener: OnDidFinishRenderingFrameWithStatsListener): void;

  /**
   * Add a will-start-rendering-map listener.
   * @param callback Callback function.
   */
  addOnWillStartRenderingMapListener(listener: OnWillStartRenderingMapListener): void;

  removeOnWillStartRenderingMapListener(listener: OnWillStartRenderingMapListener): void;

  /**
   * Add a did-finish-rendering-map listener.
   * @param callback Callback receiving whether rendering finished fully.
   */
  addOnDidFinishRenderingMapListener(listener: OnDidFinishRenderingMapListener): void;

  removeOnDidFinishRenderingMapListener(listener: OnDidFinishRenderingMapListener): void;

  // Style listeners
  /**
   * Add a did-finish-loading-style listener.
   * @param callback Callback function.
   */
  addOnDidFinishLoadingStyleListener(listener: OnDidFinishLoadingStyleListener): void;

  removeOnDidFinishLoadingStyleListener(listener: OnDidFinishLoadingStyleListener): void;

  /**
   * Add a style-image-missing listener.
   * @param callback Callback receiving the missing image identifier.
   */
  addOnStyleImageMissingListener(callback: (id: string) => void): void;

  removeOnStyleImageMissingListener(callback: (id: string) => void): void;

  addOnCanRemoveUnusedStyleImageListener(listener: OnCanRemoveUnusedStyleImageListener): void;

  removeOnCanRemoveUnusedStyleImageListener(listener: OnCanRemoveUnusedStyleImageListener): void;

  // Other listeners
  /**
   * Add a did-become-idle listener.
   * @param callback Callback function.
   */
  addOnDidBecomeIdleListener(listener: OnDidBecomeIdleListener): void;

  removeOnDidBecomeIdleListener(listener: OnDidBecomeIdleListener): void;

  /**
   * Add a source-changed listener.
   * @param callback Callback receiving the source identifier.
   */
  addOnSourceChangedListener(listener: OnSourceChangedListener): void;

  removeOnSourceChangedListener(listener: OnSourceChangedListener): void;

  // ========== Observer listeners (shader, glyph, sprite, tile) ==========
  
  /**
   * Add a pre-compile-shader listener.
   * @param callback Callback receiving (shaderId, backendType, defines).
   */
  addOnPreCompileShaderListener(callback: (shaderId: number, backendType: number, defines: string) => void): void;
  
  removeOnPreCompileShaderListener(callback: (shaderId: number, backendType: number, defines: string) => void): void;
  
  /**
   * Add a post-compile-shader listener.
   * @param callback Callback receiving (shaderId, backendType, defines).
   */
  addOnPostCompileShaderListener(callback: (shaderId: number, backendType: number, defines: string) => void): void;
  
  removeOnPostCompileShaderListener(callback: (shaderId: number, backendType: number, defines: string) => void): void;
  
  /**
   * Add a shader-compile-failed listener.
   * @param callback Callback receiving (shaderId, backendType, defines).
   */
  addOnShaderCompileFailedListener(callback: (shaderId: number, backendType: number, defines: string) => void): void;
  
  removeOnShaderCompileFailedListener(callback: (shaderId: number, backendType: number, defines: string) => void): void;
  
  /**
   * Add a glyphs-loaded listener.
   * @param callback Callback receiving (fontStack, rangeStart, rangeEnd).
   */
  addOnGlyphsLoadedListener(callback: (fontStack: string[], rangeStart: number, rangeEnd: number) => void): void;
  
  removeOnGlyphsLoadedListener(callback: (fontStack: string[], rangeStart: number, rangeEnd: number) => void): void;
  
  /**
   * Add a glyphs-error listener.
   * @param callback Callback receiving (fontStack, rangeStart, rangeEnd).
   */
  addOnGlyphsErrorListener(callback: (fontStack: string[], rangeStart: number, rangeEnd: number) => void): void;
  
  removeOnGlyphsErrorListener(callback: (fontStack: string[], rangeStart: number, rangeEnd: number) => void): void;
  
  /**
   * Add a glyphs-requested listener.
   * @param callback Callback receiving (fontStack, rangeStart, rangeEnd).
   */
  addOnGlyphsRequestedListener(callback: (fontStack: string[], rangeStart: number, rangeEnd: number) => void): void;
  
  removeOnGlyphsRequestedListener(callback: (fontStack: string[], rangeStart: number, rangeEnd: number) => void): void;
  
  /**
   * Add a sprite-loaded listener.
   * @param callback Callback receiving (spriteId, url).
   */
  addOnSpriteLoadedListener(callback: (spriteId: string, url: string) => void): void;
  
  removeOnSpriteLoadedListener(callback: (spriteId: string, url: string) => void): void;
  
  /**
   * Add a sprite-error listener.
   * @param callback Callback receiving (spriteId, url).
   */
  addOnSpriteErrorListener(callback: (spriteId: string, url: string) => void): void;
  
  removeOnSpriteErrorListener(callback: (spriteId: string, url: string) => void): void;
  
  /**
   * Add a sprite-requested listener.
   * @param callback Callback receiving (spriteId, url).
   */
  addOnSpriteRequestedListener(callback: (spriteId: string, url: string) => void): void;
  
  removeOnSpriteRequestedListener(callback: (spriteId: string, url: string) => void): void;
  
  /**
   * Add a tile-action listener.
   * @param callback Callback receiving (operation, x, y, z, wrap, overscaledZ, sourceId).
   */
  addOnTileActionListener(callback: (operation: number, x: number, y: number, z: number, wrap: number, overscaledZ: number, sourceId: string) => void): void;
  
  removeOnTileActionListener(callback: (operation: number, x: number, y: number, z: number, wrap: number, overscaledZ: number, sourceId: string) => void): void;
}

// ==================== MapSnapshotter API ====================

/**
 * Snapshot options (NAPI layer).
 */
export interface SnapshotOptionsNAPI {
  /** Width in pixels. */
  width: number;

  /** Height in pixels. */
  height: number;

  /** Pixel ratio. */
  pixelRatio: number;

  /** Style URL. */
  styleUrl: string;

  /** Optional style JSON string. */
  styleJson?: string;

  /** Whether to show the logo. */
  showLogo?: boolean;

  /** Local font family. */
  localFontFamily?: string;

  /** Optional camera configuration (added dynamically). */
  camera?: CameraPositionLike;

  /** Optional region bounds (added dynamically). */
  region?: LatLngBoundsLike;
}

/**
 * Pixel coordinate result.
 */
export interface PixelCoordinateResult {
  x: number;
  y: number;
}

/**
 * Geographic coordinate result.
 */
export interface LatLngResult {
  latitude: number;
  longitude: number;
}

/**
 * MapView snapshot callback payload.
 */
export interface MapViewSnapshotPayload {
  /** Image data in RGBA format. */
  data: ArrayBuffer;

  /** Image width. */
  width: number;

  /** Image height. */
  height: number;

  /** Pixel ratio. */
  pixelRatio: number;
}

/**
 * Snapshot result (NAPI layer).
 */
export interface SnapshotResultNAPI {
  /** Image data in RGBA format. */
  data: ArrayBuffer;

  /** Image width. */
  width: number;

  /** Image height. */
  height: number;

  /** Attribution strings. */
  attributions?: string[];

  /**
   * Convert geographic coordinates to pixel coordinates within the snapshot image.
   *
   * @param latitude Latitude.
   * @param longitude Longitude.
   * @returns Pixel coordinate within the snapshot image.
   */
  pixelForLatLng(latitude: number, longitude: number): PixelCoordinateResult;

  /**
   * Convert snapshot pixel coordinates back to geographic coordinates.
   *
   * @param x X coordinate in the snapshot.
   * @param y Y coordinate in the snapshot.
   * @returns Geographic coordinate.
   */
  latLngForPixel(x: number, y: number): LatLngResult;
}

/**
 * Camera position object (used for NAPI payloads).
 */
export interface CameraPositionLike {
  target: {
    latitude: number;
    longitude: number;
  };
  zoom: number;
  bearing: number;
  tilt: number;
}

/**
 * Bounds object (used for NAPI payloads).
 */
export interface LatLngBoundsLike {
  north: number;
  south: number;
  east: number;
  west: number;
}

/**
 * MapSnapshotter NAPI object.
 */
export interface MapSnapshotterNAPI {
  /**
   * Start generating a snapshot.
   * @param callback Receives one parameter:
   *                 - string error message on failure.
   *                 - SnapshotResultNAPI on success.
   */
  start(callback: (param: string | SnapshotResultNAPI | null) => void): void;

  /**
   * Cancel snapshot generation.
   */
  cancel(): void;

  /**
   * Set the style URL.
   * @param styleUrl Style URL.
   */
  setStyleUrl(styleUrl: string): void;

  /**
   * Set the style JSON.
   * @param styleJson Style JSON string.
   */
  setStyleJson(styleJson: string): void;

  /**
   * Set the camera position.
   * @param position Plain object describing the camera position.
   */
  setCameraPosition(position: CameraPositionLike): void;

  /**
   * Set the region bounds.
   * @param bounds Plain object describing the bounds.
   */
  setRegion(bounds: LatLngBoundsLike): void;

  /**
   * Set the snapshot size.
   * @param width Width.
   * @param height Height.
   */
  setSize(width: number, height: number): void;

  /**
   * Set the snapshot observer.
   * @param observer Observer instance; pass null to clear.
   */
  setObserver(observer: MapSnapshotterObserver | null): void;

  /**
   * Get a layer.
   * @param layerId Layer identifier.
   * @returns Layer instance or null if not found.
   */
  getLayer(layerId: string): Layer | null;

  /**
   * Get a source.
   * @param sourceId Source identifier.
   * @returns Source instance or null if not found.
   */
  getSource(sourceId: string): Source | null;

  /**
   * Add an image to the snapshot style.
   * @param name Image name.
   * @param imageData Image data.
   * @param sdf Whether the image is an SDF icon.
   */
  addImage(name: string, imageData: ArrayBuffer | Uint8Array, sdf: boolean): void;
}

/**
 * Create a MapSnapshotter instance.
 *
 * @param options Snapshot options.
 * @returns MapSnapshotter NAPI object.
 */
export function createMapSnapshotter(options: SnapshotOptionsNAPI): MapSnapshotterNAPI;

