import type { NativeMapView } from 'libmaplibre.so';
import type { MarkerOptions } from './MarkerOptions';
import { MarkerDragState } from './MarkerDragState';
import type { LatLng } from '../geometry/LatLng';
import { PixelCoordinate } from '../geometry/Point';
import type { MapLibreMap } from '../MapLibreMap';
import type { OnMarkerClickListener } from '../listeners/OnMarkerClickListener';
import type { OnMarkerLongClickListener } from '../listeners/OnMarkerLongClickListener';
import type { OnMarkerDragListener } from '../listeners/OnMarkerDragListener';
import type { OnInfoWindowClickListener } from '../listeners/OnInfoWindowClickListener';
import type { OnInfoWindowCloseListener } from '../listeners/OnInfoWindowCloseListener';
import type { OnMarkerSelectListener } from '../listeners/OnMarkerSelectListener';
import type { InfoWindowAdapter } from './InfoWindowAdapter';
import { InfoWindowManager } from './InfoWindowManager';
import type { AnnotationViewAdapter } from './AnnotationViewAdapter';
import { AnnotationViewManager } from './AnnotationViewManager';
import { IconManager } from './IconManager';
import { IconFactory } from './IconFactory';
import { MarkerLayerManager } from './MarkerLayerManager';
import type { InfoWindowStyle } from './InfoWindow';
import type { Icon } from './Icon';
import type { CenterOffset } from './AnnotationView';
import type { Marker, MarkerAnchor } from './Marker';
import common from '@ohos.app.ability.common';
import type {
  OnMapClickListener,
  OnMapLongClickListener,
  OnTouchMoveListener,
  OnTouchUpListener
} from '../gestures/GestureListeners';
import type { OnStyleLoadedListener } from '../listeners/OnStyleLoadedListener';
import type { Style } from '../style/Style';

/**
 * MarkerManager - Marker management facade
 *
 * Implemented with GeoJSON sources plus SymbolLayers to support advanced marker features.
 *
 * References:
 * - Android: `AnnotationManager` + `MarkerContainer` + `IconManager`
 *   (uses icon reference counting with markers owning the icon)
 * - iOS: `MLNShapeSource` + `MLNSymbolStyleLayer`
 */
export class MarkerManager {
  private markerLayerManager: MarkerLayerManager;
  private selectedMarkers: Set<Marker> = new Set();
  private mapLibreMap: MapLibreMap;
  private infoWindowManager: InfoWindowManager;
  private annotationViewManager: AnnotationViewManager;
  private iconManager: IconManager;
  // Marker ID -> Marker
  private markerMap: Map<number, Marker> = new Map();
  // Marker ID -> Icon (NAPI markers do not retain icon references)
  // IconManager uses the Icon object as the key to ensure proper ref counting
  private markerIconMap: Map<number, Icon> = new Map();
  // Marker ID -> InfoWindowStyle (per-marker InfoWindow configuration)
  private markerInfoWindowStyleMap: Map<number, InfoWindowStyle> = new Map();
  // Event listeners
  private onMarkerClickListener: OnMarkerClickListener | null = null;
  private onMarkerLongClickListener: OnMarkerLongClickListener | null = null;
  private onMarkerDragListener: OnMarkerDragListener | null = null;
  private onInfoWindowClickListener: OnInfoWindowClickListener | null = null;
  private onMarkerSelectListener: OnMarkerSelectListener | null = null;
  private infoWindowAdapter: InfoWindowAdapter | null = null;
  // Drag state
  private draggingMarker: Marker | null = null;
  private draggingMarkerId: number | null = null;

  /**
   * Construct a MarkerManager
   *
   * @param mapLibreMap MapLibreMap instance
   */
  constructor(mapLibreMap: MapLibreMap) {
    this.mapLibreMap = mapLibreMap;
    // Reuse the MapLibreMap InfoWindowManager (already wired with UI callbacks)
    // Instead of creating a new instance that lacks those callbacks
    this.infoWindowManager = mapLibreMap.getInfoWindowManager();
    this.annotationViewManager = mapLibreMap.getAnnotationViewManager();

    // Initialize IconManager with ResourceManager for rawfile support
    const nativeMapView = mapLibreMap.getNativeMapView();

    // Acquire ResourceManager for rawfile assets (e.g., default icons)
    let iconFactory: IconFactory;
    try {
      // Fetch ResourceManager from current component context
      const context = getContext() as common.UIAbilityContext;
      const resourceMgr = context.resourceManager;
      iconFactory = IconFactory.getInstance(resourceMgr);
    } catch (error) {
      console.warn('[MarkerManager] Failed to get ResourceManager, using IconFactory without it:', error);
      iconFactory = IconFactory.getInstance();
    }

    this.iconManager = new IconManager(nativeMapView, iconFactory);

    // MarkerLayerManager setup (GeoJSON + SymbolLayer)
    this.markerLayerManager = new MarkerLayerManager(mapLibreMap);

    // Map gesture listeners (GeoJSON + SymbolLayer mode)
    this.setupMapClickListener();

    // Listen for style reloads to refresh marker layers
    this.setupStyleLoadedListener();

  }

  /**
   * Register style-loaded listener
   *
   * Style reloads drop previously created sources/layers, so we must reinitialize the
   * MarkerLayerManager and restore markers.
   */
  private setupStyleLoadedListener(): void {
    const manager = this;

    class StyleLoadedListenerImpl implements OnStyleLoadedListener {
      onStyleLoaded(style: Style | null): void {
        console.warn('[MarkerManager] Warning: style reloaded, reinitializing MarkerLayerManager...');

        // Reinitialize MarkerLayerManager
        manager.markerLayerManager.initialize();

        // Restore all markers
        if (manager.markerMap.size > 0) {

          // Collect markers explicitly
          const markersToRestore = Array.from<Marker>(manager.markerMap.values());

          // Re-add to layer
          for (const marker of markersToRestore) {
            manager.markerLayerManager.addMarker(marker, true); // skipUpdate=true

            // Recreate custom annotation views
            manager.annotationViewManager.createOrUpdateView(marker);
          }

          // Sync source in one shot
          manager.markerLayerManager.updateSource();

        }
      }
    }

    this.mapLibreMap.addOnStyleLoadedListener(new StyleLoadedListenerImpl());
  }

  /**
   * Register map interaction listeners (GeoJSON + SymbolLayer mode)
   *
   * Markers are represented by layers, so gesture callbacks combined with
   * `queryRenderedFeatures` detect interactions.
   *
   * References:
   * - Android: DraggableSymbolsManager (AndroidGesturesManager + MoveGestureDetector)
   * - iOS: UILongPressGestureRecognizer + UIPanGestureRecognizer
   */
  private setupMapClickListener(): void {

    // Tap listener
    class MapClickListenerImpl implements OnMapClickListener {
      manager: MarkerManager;

      constructor(manager: MarkerManager) {
        this.manager = manager;
      }

      onMapClick(x: number, y: number): boolean {
        return this.manager.handleMapClick(x, y);
      }
    }

    this.mapLibreMap.addOnMapClickListener(new MapClickListenerImpl(this));

    // Long-press listener (start dragging)
    class MapLongClickListenerImpl implements OnMapLongClickListener {
      manager: MarkerManager;

      constructor(manager: MarkerManager) {
        this.manager = manager;
      }

      onMapLongClick(x: number, y: number): boolean {
        return this.manager.handleMapLongClick(x, y);
      }
    }

    this.mapLibreMap.addOnMapLongClickListener(new MapLongClickListenerImpl(this));

    // Touch-move listener (drag updates) - mirrors Android MoveGestureDetector.onMove
    class TouchMoveListenerImpl implements OnTouchMoveListener {
      manager: MarkerManager;

      constructor(manager: MarkerManager) {
        this.manager = manager;
      }

      onTouchMove(x: number, y: number): boolean {
        return this.manager.handleTouchMove(x, y);
      }
    }

    this.mapLibreMap.addOnTouchMoveListener(new TouchMoveListenerImpl(this));

    // Touch-up listener (drag end) - mirrors Android onMoveEnd and iOS UIGestureRecognizerStateEnded
    class TouchUpListenerImpl implements OnTouchUpListener {
      manager: MarkerManager;

      constructor(manager: MarkerManager) {
        this.manager = manager;
      }

      onTouchUp(x: number, y: number): boolean {
        return this.manager.handleTouchUp(x, y);
      }
    }

    this.mapLibreMap.addOnTouchUpListener(new TouchUpListenerImpl(this));

  }

  /**
   * Handle map tap events
   *
   * Based on Android `AnnotationManager.onTap()`.
   *
   * @param x Screen X coordinate (logical pixels)
   * @param y Screen Y coordinate (logical pixels)
   * @returns true when the event is consumed
   */
  private handleMapClick(x: number, y: number): boolean {
    try {
      console.info(`[MarkerManager] handleMapClick at (${x}, ${y})`);
      
      // Locate marker at tap position (queryRenderedFeaturesForBox handles coordinate transforms)
      const marker = this.queryMarkerAtPoint(x, y);

      if (marker) {
        console.info(`[MarkerManager] Found marker at click position: ${marker.getTitle()}`);
        // Dispatch marker click event
        return this.handleMarkerClick(marker);
      }

      console.info(`[MarkerManager] No marker found at click position`);
      return false; // No marker hit; event not consumed
    } catch (error) {
      console.error(`[MarkerManager] Error handling map click: ${error}`);
      return false;
    }
  }

  /**
   * Query the marker at a given point (via GeoJSON layer)
   *
   * Markers are implemented with GeoJSON + SymbolLayer, so we must query GeoJSON features using
   * `queryRenderedFeatures` instead of `queryPointAnnotations` (native-only).
   *
   * Coordinate conversion is handled inside `queryRenderedFeaturesForBox`.
   *
   * Inspired by Android `AnnotationManager.getMarkerHitFromTouchArea` and `MarkerHitResolver`.
   *
   * @param x Screen X coordinate (logical pixels)
   * @param y Screen Y coordinate (logical pixels)
   * @returns Located marker, or null if none
   */
  private queryMarkerAtPoint(x: number, y: number): Marker | null {
    // Based on Android AnnotationManager.getMarkerHitFromTouchArea:
    // Use 1.5x the largest icon dimension as hit area.
    // Android reference:
    //   int touchSurfaceWidth = (int) (iconManager.getHighestIconHeight() * 1.5);
    //   int touchSurfaceHeight = (int) (iconManager.getHighestIconWidth() * 1.5);

    // Default hit area in logical pixels (Android minimalTouchSize ~32 dp)
    const DEFAULT_TOUCH_SIZE = 48;
    let touchWidth = DEFAULT_TOUCH_SIZE;
    let touchHeight = DEFAULT_TOUCH_SIZE;

    // Adapt hit area based on maximum icon size
    const iconWidthPhysical = this.iconManager.getHighestIconWidth();   // physical pixels
    const iconHeightPhysical = this.iconManager.getHighestIconHeight(); // physical pixels

    if (iconWidthPhysical > 0 || iconHeightPhysical > 0) {
      // Convert to logical pixels for hit-testing
      const pixelRatio = this.mapLibreMap.getNativeMapView().getPixelRatio();
      const iconWidthLogical = iconWidthPhysical / pixelRatio;
      const iconHeightLogical = iconHeightPhysical / pixelRatio;
      
      // Note: Android swaps width/height because markers are usually tall
      touchWidth = Math.max(iconHeightLogical * 1.5, DEFAULT_TOUCH_SIZE);
      touchHeight = Math.max(iconWidthLogical * 1.5, DEFAULT_TOUCH_SIZE);
    }

    // Build query rectangle in logical pixels (queryRenderedFeaturesForBox handles DPI)
    const left = x - touchWidth;
    const top = y - touchHeight;
    const right = x + touchWidth;
    const bottom = y + touchHeight;

    // Query GeoJSON layer for marker features (coordinate conversion handled internally)
    const features = this.mapLibreMap.queryRenderedFeaturesForBox(
      left, top, right, bottom,
      [this.markerLayerManager.getLayerId()],
      undefined
    );

    console.info(`[MarkerManager] queryMarkerAtPoint - features found: ${features ? features.length : 0}`);
    if (features && features.length > 0) {
      console.info(`[MarkerManager] Feature IDs: ${features.map(f => f.id).join(', ')}`);
      console.info(`[MarkerManager] MarkerMap has ${this.markerMap.size} markers`);
    }

    if (!features || features.length === 0) {
      return null;
    }

    // Single feature -> return the corresponding marker directly
    if (features.length === 1) {
      const featureId = features[0].id;
      console.info(`[MarkerManager] Single feature - ID: ${featureId}, type: ${typeof featureId}`);
      if (typeof featureId === 'number' && this.markerMap.has(featureId)) {
        const marker = this.markerMap.get(featureId)!;
        console.info(`[MarkerManager] Found marker: ${marker.getTitle()}`);
        return marker;
      }
      console.warn(`[MarkerManager] Feature ID ${featureId} not found in markerMap`);
      return null;
    }

    // Multiple features -> resolve closest marker via hit test
    // See Android MarkerHitResolver.execute()
    const candidateIds: number[] = [];
    for (const feature of features) {
      const featureId = feature.id;
      console.info(`[MarkerManager] Checking feature ID: ${featureId}, type: ${typeof featureId}`);
      if (typeof featureId === 'number' && this.markerMap.has(featureId)) {
        candidateIds.push(featureId);
        console.info(`[MarkerManager] Added candidate ID: ${featureId}`);
      } else {
        console.warn(`[MarkerManager] Feature ID ${featureId} not in markerMap or wrong type`);
      }
    }

    console.info(`[MarkerManager] Candidate markers: ${candidateIds.length}`);
    if (candidateIds.length === 0) {
      console.warn(`[MarkerManager] No candidate markers found from ${features.length} features`);
      return null;
    }

    return this.resolveMarkerHit(x, y, candidateIds);
  }

  /**
   * Resolve multiple marker hits, returning the closest marker to the touch point
   *
   * Mirrors the Android MarkerHitResolver implementation.
   *
   * @param x Screen X coordinate (logical pixels)
   * @param y Screen Y coordinate (logical pixels)
   * @param markerIds Candidate marker IDs
   * @returns Closest marker or null when none match
   */
  private resolveMarkerHit(x: number, y: number, markerIds: number[]): Marker | null {
    console.info(`[MarkerManager] resolveMarkerHit called with ${markerIds.length} candidates at logical (${x}, ${y})`);
    
    let closestMarker: Marker | null = null;
    let maxIntersectionArea = 0;

    // Convert logical to physical pixels (PixelCoordinate centralizes DPI handling)
    // pixelForLatLng returns physical pixels, so align coordinate systems
    const pixelRatio = this.mapLibreMap.getNativeMapView().getPixelRatio();
    const physicalPoint = PixelCoordinate.fromLogicalPixels(x, y, pixelRatio);
    console.info(`[MarkerManager] Click point - logical: (${x}, ${y}), physical: (${physicalPoint.x}, ${physicalPoint.y}), pixelRatio: ${pixelRatio}`);

    for (const markerId of markerIds) {
      const marker = this.markerMap.get(markerId);
      if (!marker) {
        console.warn(`[MarkerManager] Marker ID ${markerId} not found in markerMap`);
        continue;
      }

      // Marker screen position in physical pixels (used for hit-testing)
      const position = marker.getPosition();
      const screenPoint = this.mapLibreMap.pixelForLatLngPhysical(position.latitude, position.longitude);
      console.info(`[MarkerManager] Marker ${markerId} ("${marker.getTitle()}") - geo: (${position.latitude}, ${position.longitude}), physical screen: (${screenPoint.x}, ${screenPoint.y})`);

      // Icon dimensions
      const icon = this.markerIconMap.get(markerId);
      if (!icon) {
        console.warn(`[MarkerManager] Icon not found for marker ID ${markerId}`);
        continue;
      }


      let bitmapWidth = icon.getWidth();
      let bitmapHeight = icon.getHeight()
      console.info(`[MarkerManager] Marker ${markerId} - original icon size (physical): ${bitmapWidth}x${bitmapHeight}`);

      // Enforce minimal touch target (Android reference ~32 dp)
      const minimalTouchSize = 48;
      if (bitmapHeight < minimalTouchSize) {
        bitmapHeight = minimalTouchSize;
      }
      if (bitmapWidth < minimalTouchSize) {
        bitmapWidth = minimalTouchSize;
      }
      console.info(`[MarkerManager] Marker ${markerId} - adjusted touch size (physical): ${bitmapWidth}x${bitmapHeight}`);

      // Anchor values: default bottom-center (0.5, 1.0) per Android MarkerView
      // anchorU: horizontal (0 = left, 0.5 = center, 1 = right)
      // anchorV: vertical (0 = top, 0.5 = center, 1 = bottom)
      const anchor: MarkerAnchor = marker.getAnchor();
      const anchorU: number = anchor ? anchor.u : 0.5;
      const anchorV: number = anchor ? anchor.v : 1.0;
      console.info(`[MarkerManager] Marker ${markerId} - anchor: (${anchorU}, ${anchorV})`);

      // Build marker hit rectangle relative to anchor
      // screenPoint corresponds to the anchor position on screen
      const markerLeft = screenPoint.x - bitmapWidth * anchorU;
      const markerTop = screenPoint.y - bitmapHeight * anchorV;
      const markerRight = markerLeft + bitmapWidth;
      const markerBottom = markerTop + bitmapHeight;
      console.info(`[MarkerManager] Marker ${markerId} - hit rect (physical): [${markerLeft}, ${markerTop}, ${markerRight}, ${markerBottom}]`);

      // Check whether click lies inside marker rectangle (physical pixels)
      const isInside = physicalPoint.x >= markerLeft && physicalPoint.x <= markerRight &&
        physicalPoint.y >= markerTop && physicalPoint.y <= markerBottom;
      console.info(`[MarkerManager] Marker ${markerId} - click point (${physicalPoint.x}, ${physicalPoint.y}) isInside: ${isInside}`);
      
      if (isInside) {
        // Intersection area (approximated as marker rectangle area)
        const intersectionArea = bitmapWidth * bitmapHeight;
        console.info(`[MarkerManager] Marker ${markerId} - intersection area: ${intersectionArea}, current max: ${maxIntersectionArea}`);

        // Pick marker with largest intersection area (closest to tap)
        if (intersectionArea > maxIntersectionArea) {
          maxIntersectionArea = intersectionArea;
          closestMarker = marker;
          console.info(`[MarkerManager] Marker ${markerId} ("${marker.getTitle()}") is now the closest marker`);
        }
      }
    }

    if (closestMarker) {
      console.info(`[MarkerManager] resolveMarkerHit result: "${closestMarker.getTitle()}"`);
    } else {
      console.warn(`[MarkerManager] resolveMarkerHit result: null (no marker hit)`);
    }

    return closestMarker;
  }

  /**
   * Attempt to begin marker drag (invoked when a pan gesture starts)
   *
   * @param x Screen X coordinate (logical pixels)
   * @param y Screen Y coordinate (logical pixels)
   * @returns true when a draggable marker is found and drag begins
   */
  public tryStartDrag(x: number, y: number): boolean {
    try {
      // Locate marker at touch point (queryRenderedFeaturesForBox handles conversion)
      const marker = this.queryMarkerAtPoint(x, y);

      if (!marker || !marker.getDraggable()) {
        return false;
      }

      console.info(`[MarkerManager] Drag START: marker id=${marker.getId()}`);

      // Initiate drag
      this.draggingMarker = marker;
      this.draggingMarkerId = marker.getId();
      this.handleDragStart(marker);

      return true; // Event consumed
    } catch (error) {
      console.error(`[MarkerManager] Error starting drag: ${error}`);
      return false;
    }
  }

  /**
   * Handle map long-press (fires marker long-click callback)
   *
   * @param x Screen X coordinate (logical pixels)
   * @param y Screen Y coordinate (logical pixels)
   * @returns true when the event is consumed
   */
  private handleMapLongClick(x: number, y: number): boolean {
    try {
      // Locate marker at long-press position
      const marker = this.queryMarkerAtPoint(x, y);

      if (!marker) {
        return false;
      }

      // Invoke marker long-click callback
      if (this.onMarkerLongClickListener) {
        return this.onMarkerLongClickListener.onMarkerLongClick(marker);
      }

      return false;
    } catch (error) {
      console.error(`[MarkerManager] Error handling long click: ${error}`);
      return false;
    }
  }

  /**
   * Handle touch-move events during dragging
   *
   * Mirrors Android `MoveGestureDetector.OnMoveGestureListener.onMove`.
   *
   * @param x Touch X coordinate (logical pixels)
   * @param y Touch Y coordinate (logical pixels)
   * @returns true when the drag consumes the event
   */
  private handleTouchMove(x: number, y: number): boolean {
    // Only respond to move events while a drag is active
    if (!this.draggingMarker || !this.draggingMarkerId) {
      return false;
    }

    try {
      // Convert logical pixels to physical (PixelCoordinate centralizes DPI)
      const pixelRatio = this.mapLibreMap.getNativeMapView().getPixelRatio();
      const screenPoint = PixelCoordinate.fromLogicalPixels(x, y, pixelRatio);

      // Convert screen coordinates to geographic coordinates
      const latLng: LatLng = this.mapLibreMap.getProjection().screenLocationToLatLng(screenPoint);

      // Update marker position
      this.handleDrag(this.draggingMarker, latLng);

      // Update GeoJSON source for real-time visual refresh
      this.markerLayerManager.updateMarker(this.draggingMarker);

      return true; // Event consumed
    } catch (error) {
      console.error(`[MarkerManager] Error handling touch move: ${error}`);
      return false;
    }
  }

  /**
   * Handle touch-up events (end of drag)
   *
   * References:
   * - Android: `MoveGestureDetector.OnMoveGestureListener.onMoveEnd`
   * - iOS: `UIPanGestureRecognizer` with `UIGestureRecognizerStateEnded`
   *
   * @param x Release X coordinate
   * @param y Release Y coordinate
   * @returns true when the event is consumed
   */
  private handleTouchUp(x: number, y: number): boolean {
    // Only respond if a drag is in progress
    if (!this.draggingMarker || !this.draggingMarkerId) {
      return false;
    }

    try {
      // Finish the drag
      this.handleDragEnd(this.draggingMarker);

      // Clear drag state
      this.draggingMarker = null;
      this.draggingMarkerId = null;

      return true; // Event consumed
    } catch (error) {
      console.error(`[MarkerManager] Error handling touch up: ${error}`);

      // Ensure drag state is cleared
      this.draggingMarker = null;
      this.draggingMarkerId = null;

      return false;
    }
  }

  // ========== Marker management ==========

  /**
   * Add a single marker
   *
   * @param options MarkerOptions instance
   * @returns Promise resolving to the created marker
   * @throws Error when marker creation fails
   */
  public async addMarker(options: MarkerOptions): Promise<Marker> {
    try {
      // Ensure MarkerLayerManager is initialized
      if (!this.markerLayerManager.isInitialized()) {
        this.markerLayerManager.initialize();
      }

      // Fetch icon (prefer reuse identifier)
      let icon: Icon | undefined = options.getIcon();
      const reuseIdentifier = options.getReuseIdentifier();

      if (!icon && reuseIdentifier) {
        // Try pulling from icon reuse queue
        const reusedIcon = this.iconManager.dequeueReusableIcon(reuseIdentifier);
        if (reusedIcon) {
          icon = reusedIcon;
        }
      }

      if (!icon) {
        // Load default icon when none specified
        if (!this.iconManager.iconFactory) {
          throw new Error('[MarkerManager] IconFactory is not initialized');
        }
        icon = await this.iconManager.iconFactory.defaultMarker();
        options.icon(icon);
      }

      // Create marker (getMarker() passes icon id to NAPI)
      const marker = options.getMarker();

      // Register icon with IconManager (marker already references iconId)
      await this.iconManager.addIconToManager(icon);

      // Add to MarkerLayerManager
      const featureId = this.markerLayerManager.addMarker(marker);

      // Assign id and register
      marker.setId(featureId);
      marker.setMapLibreMap(this.mapLibreMap);
      this.markerMap.set(featureId, marker);

      // Store marker -> icon mapping (NAPI marker keeps only icon id)
      this.markerIconMap.set(featureId, icon);

      // Persist InfoWindow style
      const infoWindowStyle = options.getInfoWindowStyle();
      if (infoWindowStyle) {
        this.markerInfoWindowStyleMap.set(featureId, infoWindowStyle);
      }

      // Create custom view if adapter present
      this.annotationViewManager.createOrUpdateView(marker);

      return marker;
    } catch (e) {
      const error = e as Error;
      console.error(`[MarkerManager] Failed to add marker: ${error.message}`);
      throw new Error(`Failed to add marker: ${error.message}`);
    }
  }

  /**
   * Add multiple markers at once
   *
   * @param optionsList Array of MarkerOptions
   * @returns Promise resolving to created markers
   * @throws Error when batch creation fails
   */
  public async addMarkers(optionsList: MarkerOptions[]): Promise<Marker[]> {
    try {
      // Ensure MarkerLayerManager is initialized
      if (!this.markerLayerManager.isInitialized()) {
        this.markerLayerManager.initialize();
      }

      // Build marker array and load icons
      const markers: Marker[] = [];
      const icons: Icon[] = [];

      for (const options of optionsList) {
        // Obtain icon from options
        let icon = options.getIcon();
        if (!icon) {
          if (!this.iconManager.iconFactory) {
            throw new Error('[MarkerManager] IconFactory is not initialized');
          }
          icon = await this.iconManager.iconFactory.defaultMarker();
          options.icon(icon);
        }

        icons.push(icon);

        const marker = options.getMarker();

        // Register icon with IconManager (marker already references iconId)
        await this.iconManager.addIconToManager(icon);

        markers.push(marker);
      }

      // Add markers to layer in bulk
      const featureIds = this.markerLayerManager.addMarkers(markers);

      // Assign ids and register metadata
      for (let i = 0; i < markers.length; i++) {
        const marker = markers[i];
        const featureId = featureIds[i];
        const icon = icons[i];
        const options = optionsList[i];

        marker.setId(featureId);
        marker.setMapLibreMap(this.mapLibreMap);
        this.markerMap.set(featureId, marker);

        // Track marker -> icon mapping
        this.markerIconMap.set(featureId, icon);

        // Store InfoWindow style
        const infoWindowStyle = options.getInfoWindowStyle();
        if (infoWindowStyle) {
          this.markerInfoWindowStyleMap.set(featureId, infoWindowStyle);
        }

        // Create/update custom views in sync
        this.annotationViewManager.createOrUpdateView(marker);
      }

      return markers;
    } catch (e) {
      const error = e as Error;
      console.error(`[MarkerManager] Failed to add markers batch: ${error.message}`);
      throw new Error(`Failed to add markers batch: ${error.message}`);
    }
  }

  /**
   * Remove a single marker
   *
   * @param marker Marker to remove
   */
  public removeMarker(marker: Marker): void {
    const id = marker.getId();
    if (id === -1) {
      return;
    }

    // Close InfoWindow if visible
    if (marker.isInfoWindowShown()) {
      marker.hideInfoWindow();
    }

    // Deselect if currently selected
    if (marker.isSelected()) {
      this.deselectMarker(marker);
    }

    // Cleanup icon (decrement reference count)
    // NAPI marker does not hold icon reference; fetch from map
    const icon = this.markerIconMap.get(id);
    if (icon) {
      this.iconManager.iconCleanup(icon);
      this.markerIconMap.delete(id);
    }

    // Remove stored InfoWindow style
    this.markerInfoWindowStyleMap.delete(id);

    // Remove custom view association
    this.annotationViewManager.removeView(marker);

    // Remove from MarkerLayerManager
    this.markerLayerManager.removeMarker(id);

    // Remove from manager registry
    this.markerMap.delete(id);
    marker.setId(-1);

  }

  /**
   * Remove multiple markers
   *
   * @param markers Array of markers to remove
   */
  public removeMarkers(markers: Marker[]): void {
    const ids: number[] = [];

    for (const marker of markers) {
      const id = marker.getId();
      if (id !== -1) {
        // Reset marker UI state
        if (marker.isInfoWindowShown()) {
          marker.hideInfoWindow();
        }
        if (marker.isSelected()) {
          this.selectedMarkers.delete(marker);
        }

        // Release icon reference
        const icon = this.markerIconMap.get(id);
        if (icon) {
          this.iconManager.iconCleanup(icon);
          this.markerIconMap.delete(id);
        }

        // Remove custom view
        this.annotationViewManager.removeView(marker);

        ids.push(id);
        this.markerMap.delete(id);
        marker.setId(-1);
      }
    }

    // Remove ids from MarkerLayerManager in bulk
    if (ids.length > 0) {
      this.markerLayerManager.removeMarkers(ids);
    }

  }

  /**
   * Update a marker
   *
   * Apply all marker properties (position, icon, opacity, rotation, etc.) to the map.
   *
   * @param marker Marker to refresh
   */
  public updateMarker(marker: Marker): void {
    try {
      const markerId = marker.getId();
      if (markerId < 0 || !this.markerMap.has(markerId)) {
        console.warn(`[MarkerManager] updateMarker: Marker ${markerId} not found in manager`);
        return;
      }

      // Update GeoJSON feature via MarkerLayerManager
      this.markerLayerManager.updateMarkerById(markerId, marker);

      // Sync custom view rendering
      this.annotationViewManager.createOrUpdateView(marker);

    } catch (e) {
      const error = e as Error;
      console.error(`[MarkerManager] Failed to update marker: ${error.message}`);
    }
  }

  /**
   * Update a marker's icon
   *
   * Automatically handles reference counting for the old icon and loading of the new one.
   *
   * @param marker Marker to update
   * @param newIcon Replacement icon instance
   */
  public async updateMarkerIcon(marker: Marker, newIcon: Icon): Promise<void> {
    try {
      const markerId = marker.getId();
      if (markerId < 0 || !this.markerMap.has(markerId)) {
        throw new Error('Marker not found in manager');
      }

      // Retrieve previous icon
      const oldIcon = this.markerIconMap.get(markerId) || null;

      // Update icon via IconManager (handles reference counts)
      await this.iconManager.updateMarkerIcon(marker, oldIcon, newIcon);

      // Refresh local mapping
      this.markerIconMap.set(markerId, newIcon);

      // Update underlying GeoJSON feature
      this.markerLayerManager.updateMarkerById(markerId, marker);

      // Refresh associated custom view
      this.annotationViewManager.createOrUpdateView(marker);

    } catch (e) {
      const error = e as Error;
      console.error(`[MarkerManager] Failed to update marker icon: ${error.message}`);
      throw new Error(`Failed to update marker icon: ${error.message}`);
    }
  }

  /**
   * Clear all markers
   *
   * Removes every marker from the map and releases related resources.
   *
   * **Important**:
   * - This decrements the reference count of all icons
   * - Icons are freed when their reference count reaches zero (PixelMap is recycled)
   * - **Freed icons cannot be reused**
   * - After clearing, create new icon instances before re-adding markers
   *
   * @example
   * ```typescript
   * // Clear all markers
   * markerManager.clear();
   *
   * // Incorrect: reusing a freed icon
   * const oldIcon = marker.getIcon();
   * const newMarker = new MarkerOptions().position(latLng).icon(oldIcon); // Wrong
   *
   * // Correct: obtain a fresh icon
   * const factory = IconFactory.getInstance();
   * const newIcon = await factory.fromResource($r('app.media.marker')); // Correct
   * const newMarker = new MarkerOptions().position(latLng).icon(newIcon);
   * ```
   */
  public clear(): void {
    // Clean up each marker
    for (const marker of this.markerMap.values()) {
      if (marker.isInfoWindowShown()) {
        marker.hideInfoWindow();
      }

      // Icon cleanup
      // Obtain icon from map (NAPI marker lacks icon reference)
      const icon = this.markerIconMap.get(marker.getId());
      if (icon) {
        // iconCleanup uses Icon object keys to handle shared references
        this.iconManager.iconCleanup(icon);
      }

      marker.setId(-1);
    }

    // Reset MarkerLayerManager
    this.markerLayerManager.clearMarkers();

    // Clear local registries
    this.markerMap.clear();
    this.markerIconMap.clear();
    this.selectedMarkers.clear();
    this.markerInfoWindowStyleMap.clear();

    // Clear custom views
    this.annotationViewManager.clear();

  }

  /**
   * Remove all listeners
   *
   * Detaches every marker-related listener to prevent leaks.
   */
  public clearAllListeners(): void {
    this.onMarkerClickListener = null;
    this.onMarkerLongClickListener = null;
    this.onMarkerDragListener = null;
    this.onInfoWindowClickListener = null;
    this.onMarkerSelectListener = null;
    this.infoWindowAdapter = null;
  }

  // ========== Selection management ==========

  /**
   * Select a marker
   *
   * @param marker Marker to select
   * @param showInfoWindow Whether to display the InfoWindow
   */
  public selectMarker(marker: Marker, showInfoWindow: boolean = true): void {
    // Deselect previous selection
    this.deselectMarkers();

    // Select current marker
    marker.setSelected(true);
    this.selectedMarkers.add(marker);

    // Notify listener
    if (this.onMarkerSelectListener) {
      this.onMarkerSelectListener.onMarkerSelect(marker);
    }

    // Display InfoWindow if applicable
    const title = marker.getTitle();
    const snippet = marker.getSnippet();
    console.info(`[MarkerManager] selectMarker - title: "${title}", snippet: "${snippet}", showInfoWindow: ${showInfoWindow}`);

    if (showInfoWindow && (title || snippet)) {
      console.info(`[MarkerManager] Showing InfoWindow for marker with title: "${title}"`);
      marker.showInfoWindow();
    } else {
      console.warn(`[MarkerManager] InfoWindow not shown - showInfoWindow: ${showInfoWindow}, hasTitle: ${!!title}, hasSnippet: ${!!snippet}`);
    }
  }

  /**
   * Deselect a marker
   *
   * @param marker Marker to deselect
   */
  public deselectMarker(marker: Marker): void {
    if (!this.selectedMarkers.has(marker)) {
      return;
    }

    marker.setSelected(false);
    marker.hideInfoWindow();
    this.selectedMarkers.delete(marker);

    // Notify deselect listener
    if (this.onMarkerSelectListener) {
      this.onMarkerSelectListener.onMarkerDeselect(marker);
    }
  }

  /**
   * Deselect all markers
   */
  public deselectMarkers(): void {
    for (const marker of this.selectedMarkers) {
      marker.setSelected(false);
      marker.hideInfoWindow();

      // Notify deselect listener
      if (this.onMarkerSelectListener) {
        this.onMarkerSelectListener.onMarkerDeselect(marker);
      }
    }
    this.selectedMarkers.clear();
  }

  /**
   * Retrieve currently selected markers
   *
   * @returns Array of selected markers
   */
  public getSelectedMarkers(): Marker[] {
    return Array.from(this.selectedMarkers);
  }

  // ========== Query helpers ==========

  /**
   * Retrieve marker by id
   *
   * @param id Marker id
   * @returns Marker instance or null if absent
   */
  public getMarker(id: number): Marker | null {
    return this.markerMap.get(id) || null;
  }

  /**
   * Get all markers
   *
   * @returns Array of markers
   */
  public getMarkers(): Marker[] {
    return Array.from(this.markerMap.values());
  }

  // ========== Drag handling ==========

  /**
   * Handle drag start
   *
   * @param marker Marker being dragged
   */
  public handleDragStart(marker: Marker): void {
    if (!marker.getDraggable()) {
      return;
    }

    marker.setDragState(MarkerDragState.Starting);
    this.draggingMarker = marker;

    // Fire callback
    if (this.onMarkerDragListener) {
      this.onMarkerDragListener.onMarkerDragStart(marker);
    }

    marker.setDragState(MarkerDragState.Dragging);
  }

  /**
   * Handle drag update
   *
   * @param marker Marker being dragged
   * @param newPosition Updated position
   */
  public handleDrag(marker: Marker, newPosition: LatLng): void {
    if (!marker.getDraggable() || marker.getDragState() !== MarkerDragState.Dragging) {
      return;
    }

    // Update position
    marker.setPosition(newPosition);

    // Fire callback
    if (this.onMarkerDragListener) {
      this.onMarkerDragListener.onMarkerDrag(marker);
    }
  }

  /**
   * Handle drag end
   *
   * @param marker Marker whose drag finished
   */
  public handleDragEnd(marker: Marker): void {
    if (!marker.getDraggable() || this.draggingMarker !== marker) {
      return;
    }

    marker.setDragState(MarkerDragState.Ending);

    // Fire callback
    if (this.onMarkerDragListener) {
      this.onMarkerDragListener.onMarkerDragEnd(marker);
    }

    marker.setDragState(MarkerDragState.None);
    this.draggingMarker = null;
  }

  /**
   * Get the marker currently being dragged
   *
   * @returns Dragging marker or null if none
   */
  public getDraggingMarker(): Marker | null {
    return this.draggingMarker;
  }

  // ========== Click handling ==========

  /**
   * Handle marker tap event
   *
   * @param marker Marker that was tapped
   * @returns true if the event was consumed
   */
  public handleMarkerClick(marker: Marker): boolean {

    // Invoke click listener
    if (this.onMarkerClickListener) {
      try {
        const consumed = this.onMarkerClickListener.onMarkerClick(marker);
        if (consumed) {
          return true;
        }
      } catch (error) {
        console.error(`[MarkerManager] Error in onMarkerClickListener: ${error}`);
      }
    } else {
      console.warn('[MarkerManager] Warning: onMarkerClickListener is not set');
    }

    // Default behavior: select marker and show InfoWindow
    this.selectMarker(marker, true);
    return false;
  }

  /**
   * Handle InfoWindow tap
   *
   * @param marker Marker owning the InfoWindow
   */
  public handleInfoWindowClick(marker: Marker): void {
    if (this.onInfoWindowClickListener) {
      this.onInfoWindowClickListener.onInfoWindowClick(marker);
    }
  }

  // ========== Listener registration ==========

  /**
   * Set marker click listener
   *
   * @param listener Listener instance
   */
  public setOnMarkerClickListener(listener: OnMarkerClickListener | null): void {
    this.onMarkerClickListener = listener;
  }

  /**
   * Set marker long-click listener
   *
   * @param listener Listener instance
   */
  public setOnMarkerLongClickListener(listener: OnMarkerLongClickListener | null): void {
    this.onMarkerLongClickListener = listener;
  }

  /**
   * Set marker drag listener
   *
   * @param listener Listener instance
   */
  public setOnMarkerDragListener(listener: OnMarkerDragListener | null): void {
    this.onMarkerDragListener = listener;
  }

  /**
   * Set marker selection listener
   *
   * @param listener Listener instance
   */
  public setOnMarkerSelectListener(listener: OnMarkerSelectListener | null): void {
    this.onMarkerSelectListener = listener;
  }

  /**
   * Get marker selection listener
   *
   * @returns Listener instance
   */
  public getOnMarkerSelectListener(): OnMarkerSelectListener | null {
    return this.onMarkerSelectListener;
  }

  /**
   * Set InfoWindow click listener
   *
   * @param listener Listener instance
   */
  public setOnInfoWindowClickListener(listener: OnInfoWindowClickListener | null): void {
    this.onInfoWindowClickListener = listener;
    this.infoWindowManager.setOnClickListener(listener);
  }

  /**
   * Set InfoWindow close listener
   *
   * @param listener Listener instance
   */
  public setOnInfoWindowCloseListener(listener: OnInfoWindowCloseListener | null): void {
    this.infoWindowManager.setOnCloseListener(listener);
  }

  /**
   * Get InfoWindow close listener
   *
   * @returns Listener instance
   */
  public getOnInfoWindowCloseListener(): OnInfoWindowCloseListener | null {
    return this.infoWindowManager.getOnCloseListener();
  }

  /**
   * Set InfoWindow adapter
   *
   * @param adapter Adapter instance
   */
  public setInfoWindowAdapter(adapter: InfoWindowAdapter | null): void {
    this.infoWindowAdapter = adapter;
    this.infoWindowManager.setAdapter(adapter);
  }

  /**
   * Get InfoWindow adapter
   *
   * @returns Adapter instance
   */
  public getInfoWindowAdapter(): InfoWindowAdapter | null {
    return this.infoWindowAdapter;
  }

  /**
   * Set AnnotationView adapter
   *
   * @param adapter Adapter instance
   */
  public setAnnotationViewAdapter(adapter: AnnotationViewAdapter | null): void {
    this.annotationViewManager.setAdapter(adapter);
  }

  /**
   * Get AnnotationView adapter
   *
   * @returns Adapter instance
   */
  public getAnnotationViewAdapter(): AnnotationViewAdapter | null {
    return this.annotationViewManager.getAdapter();
  }

  /**
   * Expose AnnotationViewManager for UI layer
   */
  public getAnnotationViewManager(): AnnotationViewManager {
    return this.annotationViewManager;
  }

  /**
   * Set native MapView (required for coordinate conversion)
   */
  public setNativeMapView(mapView: object): void {
    this.annotationViewManager.setNativeMapView(mapView as NativeMapView);
  }

  /**
   * Expose InfoWindowManager for UI layer
   */
  public getInfoWindowManager(): InfoWindowManager {
    return this.infoWindowManager;
  }

  /**
   * Get marker InfoWindow style configuration
   *
   * @param marker Marker instance
   * @returns InfoWindowStyle or undefined
   */
  public getInfoWindowStyle(marker: Marker): InfoWindowStyle | undefined {
    const id = marker.getId();
    return this.markerInfoWindowStyleMap.get(id);
  }

  private cloneInfoWindowStyle(source?: InfoWindowStyle): InfoWindowStyle {
    const clone: InfoWindowStyle = {};
    if (!source) {
      return clone;
    }

    if (source.backgroundColor !== undefined) {
      clone.backgroundColor = source.backgroundColor;
    }
    if (source.borderRadius !== undefined) {
      clone.borderRadius = source.borderRadius;
    }
    if (source.shadowRadius !== undefined) {
      clone.shadowRadius = source.shadowRadius;
    }
    if (source.shadowColor !== undefined) {
      clone.shadowColor = source.shadowColor;
    }
    if (source.titleFontSize !== undefined) {
      clone.titleFontSize = source.titleFontSize;
    }
    if (source.titleFontColor !== undefined) {
      clone.titleFontColor = source.titleFontColor;
    }
    if (source.snippetFontSize !== undefined) {
      clone.snippetFontSize = source.snippetFontSize;
    }
    if (source.snippetFontColor !== undefined) {
      clone.snippetFontColor = source.snippetFontColor;
    }
    if (source.padding !== undefined) {
      clone.padding = source.padding;
    }
    if (source.maxWidth !== undefined) {
      clone.maxWidth = source.maxWidth;
    }
    if (source.animated !== undefined) {
      clone.animated = source.animated;
    }
    if (source.leftAccessoryBuilder !== undefined) {
      clone.leftAccessoryBuilder = source.leftAccessoryBuilder;
    }
    if (source.rightAccessoryBuilder !== undefined) {
      clone.rightAccessoryBuilder = source.rightAccessoryBuilder;
    }
    if (source.showCloseButton !== undefined) {
      clone.showCloseButton = source.showCloseButton;
    }
    if (source.thumbnailImage !== undefined) {
      clone.thumbnailImage = source.thumbnailImage;
    }
    if (source.offsetX !== undefined) {
      clone.offsetX = source.offsetX;
    }
    if (source.offsetY !== undefined) {
      clone.offsetY = source.offsetY;
    }
    return clone;
  }

  /**
   * Show InfoWindow for marker
   */
  public showInfoWindow(marker: Marker): void {
    try {
      const title = marker.getTitle();
      const snippet = marker.getSnippet();
      console.info(`[MarkerManager] showInfoWindow called for marker - title: "${title}", snippet: "${snippet}"`);

      const iconId = marker.getIcon();
      const iconHeightPhysical = this.iconManager.getIconHeight(iconId);
      const pixelRatio = this.mapLibreMap.getNativeMapView().getPixelRatio();
      const iconHeightLogical = iconHeightPhysical / pixelRatio;
      console.info(`[MarkerManager] Icon "${iconId}" height: ${iconHeightPhysical}px (physical) = ${iconHeightLogical}px (logical)`);

      const style = this.cloneInfoWindowStyle(this.getInfoWindowStyle(marker));
      if (style.offsetY === undefined && iconHeightLogical > 0) {
        style.offsetY = -iconHeightLogical;
        console.info(`[MarkerManager] Setting offsetY to -${iconHeightLogical} (negative icon height for top positioning)`);
      }

      const centerOffset: CenterOffset = {
        dx: style.offsetX ?? 0,
        dy: style.offsetY ?? 0
      };

      console.info(`[MarkerManager] Calling InfoWindowManager.show() with centerOffset=(${centerOffset.dx}, ${centerOffset.dy})`);
      this.infoWindowManager.show(marker, {
        style: style,
        centerOffset: centerOffset,
        anchorU: 0.5,
        anchorV: 1.0,
        zIndex: marker.getZIndex()
      });
      console.info('[MarkerManager] InfoWindow shown successfully');

    } catch (error) {
      console.error(`[MarkerManager] Failed to show InfoWindow: ${error.message}`);
    }
  }

  /**
   * Hide a marker's InfoWindow
   */
  public hideInfoWindow(marker: Marker): void {
    this.infoWindowManager.close(marker);
  }

  /**
   * Hide all InfoWindows
   */
  public hideAllInfoWindows(): void {
    this.infoWindowManager.closeAll();
  }
}

