import maplibre, { EdgeInsets, MapViewSnapshotPayload, NativeMapView } from 'libmaplibre.so';
import image from '@ohos.multimedia.image';
import type { Icon, ExpressionLiteral as NapiExpressionLiteral, Geometry } from 'libmaplibre.so';
import { MapLibreMapOptions } from './MapLibreMapOptions';
import { CameraPosition } from './camera/CameraPosition';
import { LatLng } from './geometry/LatLng';
import { LatLngBounds } from './geometry/LatLngBounds';
import { IPixelCoordinate, PixelCoordinate, Point } from './geometry/Point';
import { Rect } from './geometry/Rect';
import { IProjectedMeters, ProjectedMeters } from './geometry/ProjectedMeters';
// Layer and Source type imports for type-safe layer and data source operations
import type { Layer } from './style/layers/Layer';
import type { Source } from './style/sources/Source';
import { Image } from './style/images/Image';
import { IFeature } from './geojson';
import { TransitionOptions } from './style/layers/TransitionOptions';
import { Light } from './style/light/Light';
import { Polyline } from './annotations/Polyline';
import { Polygon } from './annotations/Polygon';
import { MarkerManager } from './annotations/MarkerManager';
import { PolygonManager } from './annotations/PolygonManager';
import { PolylineManager } from './annotations/PolylineManager';
import { MarkerOptions } from './annotations/MarkerOptions';
import { Annotation } from './annotations/Annotation';
import { OnMarkerClickListener } from './listeners/OnMarkerClickListener';
import { OnMarkerLongClickListener } from './listeners/OnMarkerLongClickListener';
import { OnMarkerDragListener } from './listeners/OnMarkerDragListener';
import { OnInfoWindowClickListener } from './listeners/OnInfoWindowClickListener';
import { OnInfoWindowCloseListener } from './listeners/OnInfoWindowCloseListener';
import { OnMarkerSelectListener } from './listeners/OnMarkerSelectListener';
import { InfoWindowManager } from './annotations/InfoWindowManager';
import { OnStyleLoadedListener } from './listeners/OnStyleLoadedListener';
import { OnStyleLoadErrorListener } from './listeners/OnStyleLoadErrorListener';
import { InfoWindowAdapter } from './annotations/InfoWindowAdapter';
import { AnnotationViewData, AnnotationViewManager } from './annotations/AnnotationViewManager';
import { AnnotationViewConfig, AnnotationViewDelegate } from './annotations/AnnotationViewDelegate';
import { ViewAnnotationManager } from './annotations/ViewAnnotationManager';
import { ViewAnnotationRenderState } from './annotations/NativeViewAnnotationOverlay';
import { CameraChangeDispatcher } from './camera/CameraChangeDispatcher';
import {
  OnCameraIdleListener,
  OnCameraMoveCanceledListener,
  OnCameraMoveListener,
  OnCameraMoveStartedListener
} from './camera/CameraListener';
import { CameraMoveReason } from './camera/CameraMoveReason';
import { UiSettings } from './UiSettings';
import {
  OnMapClickListener,
  OnMapLongClickListener,
  OnTouchMoveListener,
  OnTouchUpListener
} from './gestures/GestureListeners';
import { LocationComponent } from './location/LocationComponent';
import { Projection } from './projection/Projection';
import { CameraAnimationCallback } from './camera/CameraAnimationCallback';
import { registerMapLibreMap } from './mapview/NativeMapView';
import { Marker } from './annotations/Marker';
import { Style } from './style/Style';
import { RenderingRefreshMode } from './types/NativeTypes';
import { RenderingStats } from './renderer/RenderingStats';
import { OnFpsChangedListener } from './listeners/OnFpsChangedListener';
import {
  OnCameraDidChangeListener,
  OnCameraIsChangingListener,
  OnCameraWillChangeListener,
  OnCanRemoveUnusedStyleImageListener,
  OnDidBecomeIdleListener,
  OnDidFailLoadingMapListener,
  OnDidFinishLoadingMapListener,
  OnDidFinishLoadingStyleListener,
  OnDidFinishRenderingFrameListener,
  OnDidFinishRenderingFrameWithStatsListener,
  OnDidFinishRenderingMapListener,
  OnGlyphsErrorListener,
  OnGlyphsLoadedListener,
  OnGlyphsRequestedListener,
  OnPostCompileShaderListener,
  OnPreCompileShaderListener,
  OnShaderCompileFailedListener,
  OnSourceChangedListener,
  OnSpriteErrorListener,
  OnSpriteLoadedListener,
  OnSpriteRequestedListener,
  OnTileActionListener,
  OnWillStartLoadingMapListener,
  OnWillStartRenderingFrameListener,
  OnWillStartRenderingMapListener
} from './listeners/MapEventListeners';

function logListenerError(eventName: string, message: string): void {
  console.error('MapLibreMap', `${eventName}: ${message}`);
}



/**
 * Pending operation type
 */
type PendingOperation = () => void;

/**
 * MapLibreMap - the core controller class for the map
 *
 * Provides comprehensive map control capabilities, including:
 * - Map display and style management
 * - Camera position and animation control
 * - Layer and data source management
 * - Annotation management (Marker, Polygon, Polyline)
 * - Gesture interaction and UI component configuration
 * - Location tracking and positioning features
 *
 * **Lifecycle management**:
 * - Create and initialize in the page `aboutToAppear()`
 * - Call `destroy()` in the page `aboutToDisappear()` to release resources
 *
 * **Style loading**:
 * - Style loading is asynchronous, wait for the `onStyleLoaded` callback
 * - Adding layers/sources before the style finishes loading queues the operations and replays them once the style is ready
 *
 * @example
 * ```typescript
 * // Basic usage
 * const options = new MapLibreMapOptions({
 *   styleUrl: DEFAULT_STYLE_URLS.streets,
 *   size: { width: 800, height: 600 }
 * });
 *
 * const map = new MapLibreMap(nativeMapView, options);
 *
 * // Set the camera position
 * map.setLatLng(39.9, 116.4);
 * map.setZoom(15);
 *
 * // Add a marker
 * const marker = await map.addMarker(
 *   new MarkerOptions()
 *     .position(39.9, 116.4)
 *     .title("Beijing")
 * );
 *
 * // Listen for map events
 * map.addOnMapClickListener({
 *   onMapClick: (x, y) => {
 *     console.log(`Map clicked at: ${x}, ${y}`);
 *     return false;
 *   }
 * });
 *
 * // Clean up when the page is destroyed
 * aboutToDisappear() {
 *   this.map?.destroy();
 * }
 * ```
 *
 * @see {@link MapLibreMapOptions} Map configuration options
 * @see {@link NativeMapView} The underlying map view component
 */
export class MapLibreMap {
  private nativeMapView: NativeMapView;
  private options: MapLibreMapOptions;
  private destroyed: boolean = false;
  private markerManager: MarkerManager;
  private polygonManager: PolygonManager;
  private polylineManager: PolylineManager;
  private infoWindowManager: InfoWindowManager;
  private annotationViewManager: AnnotationViewManager;
  private viewAnnotationManager: ViewAnnotationManager;
  private viewAnnotationRenderCallback?: (states: ViewAnnotationRenderState[]) => void;
  private annotationViewDelegate: AnnotationViewDelegate | null = null;
  private style: Style | null = null;
  private styleLoaded: boolean = false;
  private cameraChangeDispatcher: CameraChangeDispatcher = new CameraChangeDispatcher();
  // UI settings
  private uiSettings: UiSettings = new UiSettings();
  // Location component
  private locationComponent: LocationComponent;
  // Projection utilities
  private projection: Projection;
  // View dimensions (used by InfoWindow and other features)
  private viewWidth: number = 0;
  private viewHeight: number = 0;
  // Style listeners
  private styleLoadedListeners: OnStyleLoadedListener[] = [];
  private styleLoadErrorListeners: OnStyleLoadErrorListener[] = [];
  private styleImageMissingListener?: (imageId: string) => void;
  private nativeStyleLoadedCallback?: () => void;
  private nativeStyleLoadErrorCallback?: (error: string) => void;
  private nativeStyleImageMissingCallback?: (imageId: string) => void;
  // Listener wrapper registries (native layer expects interface objects)
  private cameraWillChangeWrappers: Map<OnCameraWillChangeListener, OnCameraWillChangeListener> = new Map();
  private cameraIsChangingWrappers: Map<OnCameraIsChangingListener, OnCameraIsChangingListener> = new Map();
  private cameraDidChangeWrappers: Map<OnCameraDidChangeListener, OnCameraDidChangeListener> = new Map();
  private willStartLoadingMapWrappers: Map<OnWillStartLoadingMapListener, OnWillStartLoadingMapListener> = new Map();
  private didFinishLoadingMapWrappers: Map<OnDidFinishLoadingMapListener, OnDidFinishLoadingMapListener> = new Map();
  private didFailLoadingMapWrappers: Map<OnDidFailLoadingMapListener, OnDidFailLoadingMapListener> = new Map();
  private willStartRenderingFrameWrappers: Map<OnWillStartRenderingFrameListener, OnWillStartRenderingFrameListener> = new Map();
  private didFinishRenderingFrameWrappers: Map<OnDidFinishRenderingFrameListener, OnDidFinishRenderingFrameListener> = new Map();
  private didFinishRenderingFrameWithStatsWrappers: Map<OnDidFinishRenderingFrameWithStatsListener, OnDidFinishRenderingFrameWithStatsListener> = new Map();
  private willStartRenderingMapWrappers: Map<OnWillStartRenderingMapListener, OnWillStartRenderingMapListener> = new Map();
  private didFinishRenderingMapWrappers: Map<OnDidFinishRenderingMapListener, OnDidFinishRenderingMapListener> = new Map();
  private didFinishLoadingStyleWrappers: Map<OnDidFinishLoadingStyleListener, OnDidFinishLoadingStyleListener> = new Map();
  private canRemoveUnusedStyleImageWrappers: Map<OnCanRemoveUnusedStyleImageListener, OnCanRemoveUnusedStyleImageListener> = new Map();
  private didBecomeIdleWrappers: Map<OnDidBecomeIdleListener, OnDidBecomeIdleListener> = new Map();
  private sourceChangedWrappers: Map<OnSourceChangedListener, OnSourceChangedListener> = new Map();
  private preCompileShaderWrappers: Map<OnPreCompileShaderListener, OnPreCompileShaderListener> = new Map();
  private postCompileShaderWrappers: Map<OnPostCompileShaderListener, OnPostCompileShaderListener> = new Map();
  private shaderCompileFailedWrappers: Map<OnShaderCompileFailedListener, OnShaderCompileFailedListener> = new Map();
  private glyphsRequestedWrappers: Map<OnGlyphsRequestedListener, OnGlyphsRequestedListener> = new Map();
  private glyphsLoadedWrappers: Map<OnGlyphsLoadedListener, OnGlyphsLoadedListener> = new Map();
  private glyphsErrorWrappers: Map<OnGlyphsErrorListener, OnGlyphsErrorListener> = new Map();
  private spriteRequestedWrappers: Map<OnSpriteRequestedListener, OnSpriteRequestedListener> = new Map();
  private spriteLoadedWrappers: Map<OnSpriteLoadedListener, OnSpriteLoadedListener> = new Map();
  private spriteErrorWrappers: Map<OnSpriteErrorListener, OnSpriteErrorListener> = new Map();
  private tileActionWrappers: Map<OnTileActionListener, OnTileActionListener> = new Map();
  // Operation queue - cache operations before the style is ready
  private pendingOperations: PendingOperation[] = [];
  // Compass update callback (injected by the outer UI layer)
  public onCompassUpdate?: (bearing: number) => void;
  // ScaleBar update callback (injected by the outer UI layer)
  public onScaleBarUpdate?: (metersPerPixel: number) => void;
  // Animation callback management
  private pendingAnimationCallback: CameraAnimationCallback | null = null;
  private animationTimerId: number | null = null;
  private animationCancelled: boolean = false;
  // Camera move throttling - limits update frequency during gestures
  private lastCameraMoveTime: number = 0;
  private static readonly CAMERA_MOVE_THROTTLE_MS = 16; // ~60fps limit

  constructor(nativeMapView: NativeMapView, options: MapLibreMapOptions) {
    this.nativeMapView = nativeMapView;
    this.options = options;
    
    // ⚠️ Important: InfoWindowManager must be created before MarkerManager
    // Because the MarkerManager constructor calls this.mapLibreMap.getInfoWindowManager()
    this.infoWindowManager = new InfoWindowManager();
    this.annotationViewManager = new AnnotationViewManager();
    this.viewAnnotationManager = new ViewAnnotationManager();
    
    // Create annotation managers (depend on InfoWindowManager)
    this.markerManager = new MarkerManager(this);
    this.polygonManager = new PolygonManager(this);
    this.polylineManager = new PolylineManager(this);
    this.locationComponent = new LocationComponent(this);
    this.projection = new Projection(nativeMapView, 0, 0); // Start with zero size and update later

    // Set the NativeMapView for AnnotationViewManager
    this.annotationViewManager.setNativeMapView(nativeMapView);
    this.viewAnnotationManager.setNativeMapView(nativeMapView);
    this.infoWindowManager.setViewAnnotationManager(this.viewAnnotationManager);
    this.viewAnnotationManager.updatePixelRatio(this.readPixelRatioSafe(nativeMapView));
    this.viewAnnotationManager.setRenderCallback((states: ViewAnnotationRenderState[]) => {
      if (this.viewAnnotationRenderCallback) {
        this.viewAnnotationRenderCallback(states);
      }
    });

    // Set up native style listeners
    this.setupNativeStyleListeners();

    // InfoWindow positioning is now handled automatically via onUpdateRegionChange() (mirrors Android)
    // A separate CameraMoveListener is no longer required

    // Register the camera listener that updates AnnotationView positions
    this.setupAnnotationViewCameraListener();

    // Register the camera listener that updates the compass
    this.setupCompassCameraListener();

    // Register the camera listener that updates the scale bar
    this.setupScaleBarCameraListener();

    // 🔧 Register camera callbacks from the NAPI layer
    // These callbacks trigger cameraChangeDispatcher and notify all internal listeners
    this.setupNativeCameraCallbacks();

    // Register with NativeMapView to enable InfoWindow features
    registerMapLibreMap(nativeMapView, this);
  }

  /**
   * Configure style listeners on the native layer
   * @private
   */
  private setupNativeStyleListeners(): void {
    // Avoid duplicate registration when invoked multiple times
    this.teardownNativeStyleListeners();

    // Register the style loaded callback
    this.nativeStyleLoadedCallback = () => {
      this.onStyleLoaded();
    };
    this.nativeMapView.setOnStyleLoadedListener(this.nativeStyleLoadedCallback);

    // Register the style load error callback
    this.nativeStyleLoadErrorCallback = (error: string) => {
      console.error(`MapLibreMap: Native style load error callback triggered: ${error}`);
      this.onStyleLoadError(error);
    };
    this.nativeMapView.setOnStyleLoadErrorListener(this.nativeStyleLoadErrorCallback);

    // Register the style image missing callback
    this.nativeStyleImageMissingCallback = (imageId: string) => {
      if (this.styleImageMissingListener) {
        try {
          this.styleImageMissingListener(imageId);
        } catch (error) {
          console.error(`MapLibreMap: Error in onStyleImageMissing listener: ${error}`);
        }
      }
    };
    this.nativeMapView.addOnStyleImageMissingListener(this.nativeStyleImageMissingCallback);
  }

  /**
   * Remove native style listeners (used during teardown and re-registration)
   * @private
   */
  private teardownNativeStyleListeners(): void {
    if (this.nativeStyleLoadedCallback) {
      this.nativeMapView.setOnStyleLoadedListener(null);
      this.nativeStyleLoadedCallback = undefined;
    }

    if (this.nativeStyleLoadErrorCallback) {
      this.nativeMapView.setOnStyleLoadErrorListener(null);
      this.nativeStyleLoadErrorCallback = undefined;
    }

    if (this.nativeStyleImageMissingCallback) {
      this.nativeMapView.removeOnStyleImageMissingListener(this.nativeStyleImageMissingCallback);
      this.nativeStyleImageMissingCallback = undefined;
    }
  }

  /**
   * Called when the visible map region changes (mirrors Android MapLibreMap.onUpdateRegionChange)
   * Updates UI elements whenever the viewport changes due to camera moves or animations
   * @private
   */
  private onUpdateRegionChange(): void {
    console.info('[MapLibreMap] onUpdateRegionChange - updating UI elements');
    
    // Update InfoWindow positions
    this.annotationViewManager.updatePositionsWithProjector((marker: Marker) => {
      const position = marker.getPosition();
      return this.pixelForLatLng(position.latitude, position.longitude);
    });

    this.viewAnnotationManager.refreshRenderStates();
    
    // Additional UI elements can be updated here in the future
    // - Compass direction
    // - Scale bar
    // - Attribution text
  }

  private readPixelRatioSafe(mapView: NativeMapView): number {
    try {
      const ratioCandidate = mapView.getPixelRatio?.();
      if (typeof ratioCandidate === 'number' && Number.isFinite(ratioCandidate) && ratioCandidate > 0) {
        return ratioCandidate;
      }
    } catch (error) {
      const reason = error instanceof Error ? error.message : `${error}`;
      console.warn(`[MapLibreMap] readPixelRatioSafe failed: ${reason}`);
    }
    return 1;
  }

  /**
   * Set up the compass camera move listener
   * Automatically updates the compass heading when the map rotates
   * @private
   */
  private setupCompassCameraListener(): void {
    class CompassMoveListenerImpl implements OnCameraMoveListener {
      parent: MapLibreMap;

      constructor(parent: MapLibreMap) {
        this.parent = parent;
      }

      onCameraMove(): void {
        // Update the compass when the camera moves
        if (this.parent.onCompassUpdate) {
          const bearing = this.parent.getBearing();
          this.parent.onCompassUpdate(bearing);
        }
      }
    }

    this.cameraChangeDispatcher.addOnCameraMoveListener(new CompassMoveListenerImpl(this));
  }

  /**
   * Set up the scale bar camera move listener
   * Automatically updates the scale bar when the map zooms or moves
   * @private
   */
  private setupScaleBarCameraListener(): void {
    class ScaleBarMoveListenerImpl implements OnCameraMoveListener {
      parent: MapLibreMap;

      constructor(parent: MapLibreMap) {
        this.parent = parent;
      }

      onCameraMove(): void {
        // Update the scale bar when the camera moves
        if (this.parent.onScaleBarUpdate) {
          const metersPerPixel = this.parent.getMetersPerPixelAtLatitude(this.parent.getLatLng().latitude);
          this.parent.onScaleBarUpdate(metersPerPixel);
        }

        // Update AnnotationView positions at the same time
        this.parent.updateAnnotationViewPositions(false);
      }
    }

    this.cameraChangeDispatcher.addOnCameraMoveListener(new ScaleBarMoveListenerImpl(this));
  }

  /**
   * Register camera event callbacks from the NAPI layer
   *
   * This method wires up native camera callbacks. When the native map emits camera events,
   * cameraChangeDispatcher is invoked to propagate the events to all internal listeners
   * (InfoWindow, AnnotationView, Compass, ScaleBar, etc.).
   *
   * TODO: Future optimization — implement Android-style callback mapping in the ETS layer.
   * Current approach: the C++ layer triggers Android-style callbacks inside MapObserver (temporary solution).
   * Suggested approach:
   *   1. Keep only the MapLibre native callbacks on the C++ side (onCameraWillChange, onCameraIsChanging, onCameraDidChange).
   *   2. Listen to those native callbacks in ETS and convert them to Android-style callbacks here.
   *   3. Example: listen for onCameraWillChange -> trigger cameraChangeDispatcher.notifyCameraMoveStarted().
   *   4. Benefits: better separation between C++ and ETS layers, clearer architecture, easier maintenance.
   *
   * @private
   */
  private setupNativeCameraCallbacks(): void {
    // Camera move started callback (Android style)
    // TODO: Switch to listening for onCameraWillChange and convert in ETS
    this.nativeMapView.addOnCameraMoveStartedListener((reason: number) => {
      this.cameraChangeDispatcher.notifyCameraMoveStarted(reason as CameraMoveReason);
    });

    // Camera moving callback (Android style)
    // TODO: Switch to listening for onCameraIsChanging and convert in ETS
    this.nativeMapView.addOnCameraMoveListener(() => {
      this.cameraChangeDispatcher.notifyCameraMove();
    });

    // Camera idle callback (Android style)
    // TODO: Switch to listening for onCameraDidChange and convert in ETS
    this.nativeMapView.addOnCameraIdleListener(() => {
      this.cameraChangeDispatcher.notifyCameraIdle();
    });
  }

  /**
   * Set up camera listeners for AnnotationView
   * Updates positions and transforms for all AnnotationViews when the camera changes
   * @private
   */
  private setupAnnotationViewCameraListener(): void {

    // Camera move listener: update view positions
    class AnnotationViewMoveListenerImpl implements OnCameraMoveListener {
      parent: MapLibreMap;

      constructor(parent: MapLibreMap) {
        this.parent = parent;
      }

      onCameraMove(): void {
        // Update positions while the camera moves (bearing/pitch unchanged)
        this.parent.updateAnnotationViewPositions(false);
      }
    }

    // Camera idle listener: ensure the final state is correct
    class AnnotationViewIdleListenerImpl implements OnCameraIdleListener {
      parent: MapLibreMap;

      constructor(parent: MapLibreMap) {
        this.parent = parent;
      }

      onCameraIdle(): void {
        // Update when the camera stops, including bearing/pitch changes
        this.parent.updateAnnotationViewPositions(true);
      }
    }

    this.cameraChangeDispatcher.addOnCameraMoveListener(new AnnotationViewMoveListenerImpl(this));
    this.cameraChangeDispatcher.addOnCameraIdleListener(new AnnotationViewIdleListenerImpl(this));
  }

  /**
   * Calculate meters-per-pixel at the given latitude (using the current zoom level)
   * @param latitude Latitude
   * @returns Meters per pixel
   */
  public getMetersPerPixelAtLatitude(latitude: number): number;

  /**
   * Calculate meters-per-pixel at the given latitude and zoom level
   * @param latitude Latitude
   * @param zoom Zoom level
   * @returns Meters per pixel
   */
  public getMetersPerPixelAtLatitude(latitude: number, zoom: number): number;

  public getMetersPerPixelAtLatitude(latitude: number, zoom?: number): number {
    if (this.destroyed) {
      return 0;
    }
    const actualZoom = zoom !== undefined ? zoom : this.getZoom();
    return this.nativeMapView.getMetersPerPixelAtLatitude(latitude, actualZoom);
  }

  /**
   * Mark the style as loaded (called externally, typically from the style loaded callback)
   */
  public onStyleLoaded(): void {
    this.styleLoaded = true;

    // Execute pending operations
    if (this.pendingOperations.length > 0) {
      this.pendingOperations.forEach(operation => {
        try {
          operation();
        } catch (error) {
          console.error(`MapLibreMap: Error executing pending operation: ${error}`);
        }
      });
      this.pendingOperations = [];
    }

    // Notify listeners
    if (this.styleLoadedListeners.length > 0) {
      this.styleLoadedListeners.forEach(listener => {
        try {
          // Note: Pass null for the Style object because NativeMapView has no getStyle() method yet
          // Listeners can interact with layers/sources directly via NativeMapView
          listener.onStyleLoaded(null);
        } catch (error) {
          console.error(`MapLibreMap: Error in onStyleLoaded listener: ${error}`);
        }
      });
    }
  }

  /**
   * Mark the style as failed to load (called externally)
   */
  public onStyleLoadError(error: string): void {
    this.styleLoaded = false;
    this.style = null;

    // Clear pending operations
    if (this.pendingOperations.length > 0) {
      console.warn(`MapLibreMap: Clearing ${this.pendingOperations.length} pending operations due to style load error`);
      this.pendingOperations = [];
    }

    // Notify error listeners
    if (this.styleLoadErrorListeners.length > 0) {
      this.styleLoadErrorListeners.forEach(listener => {
        try {
          listener.onStyleLoadError(error);
        } catch (err) {
          console.error(`MapLibreMap: Error in onStyleLoadError listener: ${err}`);
        }
      });
    }
  }

  /**
   * Destroy the map (mirrors Android MapLibreMap.onDestroy())
   */
  public destroy(): void {
    if (this.destroyed) {
      return;
    }

    this.destroyed = true;
    this.styleLoaded = false;
    this.style = null;
    this.teardownNativeStyleListeners();

    try {
      // 1. Clear all listener arrays (mirrors Android)
      this.styleLoadedListeners = [];
      this.styleLoadErrorListeners = [];
      this.styleImageMissingListener = undefined;
      this.pendingOperations = [];
      this.mapClickListeners = [];
      this.mapLongClickListeners = [];

      // 2. Cancel all animations
      if (this.animationTimerId !== null) {
        clearTimeout(this.animationTimerId);
        this.animationTimerId = null;
      }
      this.pendingAnimationCallback = null;
      this.animationCancelled = false;

      // 3. Clear the MarkerManager (mirrors Android)
      this.markerManager.clear();

      // 3.1 Clear the PolygonManager and PolylineManager
      this.polygonManager.clear();
      this.polylineManager.clear();

      // 4. Clear the InfoWindowManager
      this.infoWindowManager.closeAll();

      // 5. Clear the AnnotationViewManager
      this.annotationViewManager.clear();
      this.viewAnnotationManager.setRenderCallback(null);
      this.viewAnnotationManager.clear();
      this.viewAnnotationManager.setNativeMapView(null);

      // 6. Destroy the location component (mirrors Android)
      this.locationComponent.onDestroy();

      // 7. Clear the camera dispatcher
      // CameraChangeDispatcher cleans up its listeners during NativeMapView.destroy below

      // 8. Reset style references
      this.style = null;
      this.styleLoaded = false;

      // 9. Clear the NativeMapView reference (actual destruction happens in NativeMapView)
      // Native resources are released asynchronously in NativeMapView.aboutToDisappear()

    } catch (error) {
      console.error('MapLibreMap: Error during destroy:', error);
    }
  }

  /**
   * Check whether the map has been destroyed
   */
  public isDestroyed(): boolean {
    return this.destroyed;
  }

  /**
   * Get the UI settings
   */
  public getUiSettings(): UiSettings {
    return this.uiSettings;
  }

  /**
   * Get the location component
   * Used to display and track the user's location
   */
  public getLocationComponent(): LocationComponent {
    return this.locationComponent;
  }

  /**
   * Get the projection helper
   * Converts between map coordinates and screen coordinates
   *
   * @returns Projection instance
   */
  public getProjection(): Projection {
    return this.projection;
  }

  /**
   * Resize the map view
   */
  public resizeView(width: number, height: number): void {
    if (this.destroyed) {
      return;
    }
    // Store the dimensions
    this.viewWidth = width;
    this.viewHeight = height;
    console.info(`[MapLibreMap] resizeView called: ${width}x${height}`);

    // Update the Projection view size
    this.projection.updateViewSize(width, height);

    this.nativeMapView.resizeView(width, height);

    // After the view size changes, trigger a ScaleBar update (ensures initial value)
    if (this.onScaleBarUpdate) {
      try {
        const latLng = this.getLatLng();
        const metersPerPixel = this.getMetersPerPixelAtLatitude(latLng.latitude);
        this.onScaleBarUpdate(metersPerPixel);
      } catch (error) {
        console.error(`[MapLibreMap] Failed to update ScaleBar on resize: ${error}`);
      }
    }
  }

  /**
   * Get the view width
   */
  public getViewWidth(): number {
    return this.viewWidth;
  }

  /**
   * Get the view height
   */
  public getViewHeight(): number {
    return this.viewHeight;
  }

  // Style management
  public setStyleUrl(url: string): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setStyleUrl(url);
    this.styleLoaded = false;
    this.style = null; // Reset cached style reference
  }

  /**
   * Set the style and execute a callback when loading completes
   * Combines setStyleUrl and addOnStyleLoadedListener into one fluent API (mirrors Android Style.Builder pattern)
   *
   * @param url Style URL
   * @param callback Callback executed after the style finishes loading
   * @example
   * ```typescript
   * map.setStyleWithCallback(DEFAULT_STYLE_URLS.streets, (style) => {
   *   new StyleBuilder()
   *     .withSource(source)
   *     .withLayer(layer)
   *     .build(map);
   * });
   * ```
   */
  public setStyleWithCallback(
    url: string,
    callback: (style: Style | null) => void
  ): void {
    if (this.destroyed) {
      return;
    }

    // Create a one-time listener
    const self = this;
    class OneTimeStyleLoadedListener implements OnStyleLoadedListener {
      onStyleLoaded(style: Style | null): void {
        try {
          callback(style);
        } catch (error) {
          console.error(`MapLibreMap: Error in setStyleWithCallback callback: ${error}`);
        }
        // Remove the listener after the callback executes
        self.removeOnStyleLoadedListener(this);
      }
    }
    const oneTimeListener = new OneTimeStyleLoadedListener();

    // Register the listener
    this.addOnStyleLoadedListener(oneTimeListener);

    // Apply the style URL
    this.setStyleUrl(url);
  }

  public getStyleUrl(): string {
    if (this.destroyed) {
      return '';
    }
    return this.nativeMapView.getStyleUrl();
  }

  /**
   * Configure the local ideograph font family
   *
   * Enables local rendering for CJK glyphs to avoid downloading large glyph data.
   * Note: this reinitializes the renderer and reloads the style.
   *
   * @param fontFamily Font family name such as "HarmonyOS_Sans"; null disables local rendering
   */
  public setLocalIdeographFontFamily(fontFamily: string | null): void {
    if (this.destroyed) {
      return;
    }

    // Update cached state
    this.options.localIdeographFontFamily = fontFamily;

    // Call into C++ to update the font configuration and reinitialize the renderer
    // Mirrors Android/iOS where local fonts are fixed when the renderer is created
    try {
      this.nativeMapView.setLocalIdeographFontFamily(fontFamily);
      console.info('[MapLibreMap] setLocalIdeographFontFamily: Local font updated to ' +
                   (fontFamily || '(disabled)'));
    } catch (error) {
      console.error('[MapLibreMap] setLocalIdeographFontFamily: Update failed', error);
    }
  }

  /**
   * Get the currently configured local ideograph font family
   *
   * @returns Configured font family name, null if disabled
   */
  public getLocalIdeographFontFamily(): string | null {
    if (this.destroyed) {
      return null;
    }
    
    // Fetch the actual configuration from C++
    try {
      return this.nativeMapView.getLocalIdeographFontFamily();
    } catch (error) {
      console.error('[MapLibreMap] getLocalIdeographFontFamily: Failed to query value', error);
      return this.options.localIdeographFontFamily;
    }
  }

  public setStyleJson(json: string): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setStyleJson(json);
    this.styleLoaded = false;
    this.style = null; // Reset cached style reference
  }

  public getStyleJson(): string {
    if (this.destroyed) {
      return '';
    }
    return this.nativeMapView.getStyleJson();
  }

  /**
   * Get the style object
   *
   * @returns Wrapped Style instance, or null if the map is uninitialized or the style is not loaded
   */
  public getStyle(): Style | null {
    if (this.destroyed) {
      return null;
    }
    if (!this.nativeMapView) {
      return null;
    }

    try {
      const nativeStyle = this.nativeMapView.getStyle();
      if (nativeStyle) {
        return Style.fromNative(nativeStyle);
      }
      return null;
    } catch (error) {
      console.error('Failed to get style:', error);
      return null;
    }
  }

  /**
   * Check whether the style has finished loading
   */
  public isStyleLoaded(): boolean {
    return this.styleLoaded;
  }

  public setLatLngBounds(bounds?: LatLngBounds | null): void {
    if (this.destroyed) {
      return;
    }
    if (!bounds) {
      this.nativeMapView.setLatLngBounds(null);
      return;
    }
    this.nativeMapView.setLatLngBounds(bounds);
  }

  // Camera control
  public cancelTransitions(): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.cancelTransitions();
  }

  /**
   * Configure map padding
   * Shifts the logical center used for camera calculations
   *
   * Mirrors Android: MapLibreMap.setPadding()
   *
   * @param left Left padding in pixels
   * @param top Top padding in pixels
   * @param right Right padding in pixels
   * @param bottom Bottom padding in pixels
   *
   * @example
   * ```typescript
   * // Set top padding to 200px
   * map.setPadding(0, 200, 0, 0);
   *
   * // Set 100px padding on every side
   * map.setPadding(100, 100, 100, 100);
   * ```
   */
  public setPadding(left: number, top: number, right: number, bottom: number): void {
    if (this.destroyed) {
      return;
    }
    this.projection.setContentPadding(left, top, right, bottom);
  }

  /**
   * Retrieve the current map padding
   *
   * Mirrors Android: MapLibreMap.getPadding()
   *
   * @returns Padding array [left, top, right, bottom]
   */
  public getPadding(): number[] {
    if (this.destroyed) {
      return [0, 0, 0, 0];
    }
    return this.projection.getContentPadding();
  }

  public setGestureInProgress(inProgress: boolean): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setGestureInProgress(inProgress);
  }

  public moveBy(dx: number, dy: number, duration: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.moveBy(dx, dy, duration);
  }

  public jumpTo(angle: number, latitude: number, longitude: number, pitch: number, zoom: number,
    padding?: number[]): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.jumpTo(angle, latitude, longitude, pitch, zoom, padding);
  }

  /**
   * Smoothly transition to the specified camera target (easeTo) — parameter overload
   *
   * @param latitude Latitude
   * @param longitude Longitude
   * @param bearing Bearing
   * @param zoom Zoom level
   * @param duration Animation duration in milliseconds
   */
  public easeTo(latitude: number, longitude: number, bearing: number, zoom: number, duration: number): void;

  /**
   * Smoothly transition to the specified camera target (easeTo) — options overload
   *
   * @param options Camera options
   * @param duration Animation duration in milliseconds
   * @param callback Optional animation callback
   */
  public easeTo(options: maplibre.CameraOptions, duration: number, callback?: CameraAnimationCallback): void;

  /**
   * Implementation for easeTo
   */
  public easeTo(
    latitudeOrOptions: number | maplibre.CameraOptions,
    longitudeOrDuration: number,
    bearingOrCallback?: number | CameraAnimationCallback,
    zoom?: number,
    duration?: number
  ): void {
    if (this.destroyed) {
      return;
    }

    // Determine which overload is used
    if (typeof latitudeOrOptions === 'number' && typeof zoom === 'number' && typeof duration === 'number') {
      // Parameter overload: easeTo(latitude, longitude, bearing, zoom, duration)
      const centerObj: LatLng = new LatLng(latitudeOrOptions, longitudeOrDuration);
      const options: maplibre.CameraOptions = {
        center: centerObj.toObject(),
        bearing: bearingOrCallback as number,
        zoom: zoom
      };
      this.nativeMapView.easeTo(options, duration);
    } else if (typeof latitudeOrOptions === 'object') {
      // Options overload: easeTo(options, duration, callback?)
      const options: maplibre.CameraOptions = latitudeOrOptions;
      const durationMs = longitudeOrDuration;
      const callback = bearingOrCallback as CameraAnimationCallback | undefined;

      // Register animation callback if provided
      if (callback) {
        this.setupAnimationCallback(callback, durationMs);
      }

      this.nativeMapView.easeTo(options, durationMs);
    }
  }

  /**
   * Fly animation to the specified camera target (flyTo)
   *
   * @param options Camera options
   * @param duration Animation duration in milliseconds
   * @param callback Optional animation callback
   */
  public flyTo(options: maplibre.CameraOptions, duration: number, callback?: CameraAnimationCallback): void {
    if (this.destroyed) {
      return;
    }

    // Register animation callback if provided
    if (callback) {
      this.setupAnimationCallback(callback, duration);
    }

    this.nativeMapView.flyTo(options, duration);
  }

  /**
   * Camera animation (Android-style animateCamera)
   * Animates to a new position using a CameraPosition object
   *
   * @param position CameraPosition instance
   * @param durationMs Animation duration in milliseconds (optional, defaults to 300ms)
   * @param callback Optional animation callback
   *
   * Example:
   * ```typescript
   * // Basic usage
   * map.animateCamera(new CameraPosition(
   *   new LatLng(lat, lng),
   *   15,
   *   0,
   *   0
   * ), 1000);
   *
   * // With callback
   * map.animateCamera(cameraPosition, 1000, {
   * });
   * ```
   */
  public animateCamera(position: CameraPosition, durationMs?: number, callback?: CameraAnimationCallback): void {
    if (this.destroyed) {
      return;
    }

    const duration = durationMs ?? 300; // Default 300ms

    // Build camera options
    const options: maplibre.CameraOptions = {
      center: position.target ? position.target.toObject() : undefined,
      zoom: position.zoom,
      bearing: position.bearing,
      pitch: position.tilt
    };

    // Perform the animation via easeTo
    this.easeTo(options, duration, callback);
  }

  /**
   * Configure the animation callback
   *
   * @param callback Callback handler
   * @param duration Animation duration
   */
  private setupAnimationCallback(callback: CameraAnimationCallback, duration: number): void {
    // Clear previous animation callbacks
    this.clearAnimationCallback();

    this.pendingAnimationCallback = callback;
    this.animationCancelled = false;

    // Listen for camera movement cancellation
    class CancelListenerImpl implements OnCameraMoveCanceledListener {
      private parent: MapLibreMap;

      constructor(parent: MapLibreMap) {
        this.parent = parent;
      }

      onCameraMoveCanceled(): void {
        this.parent.onAnimationCancelled();
      }
    }

    const cancelListener = new CancelListenerImpl(this);

    this.cameraChangeDispatcher.addOnCameraMoveCanceledListener(cancelListener);

    // Schedule the completion callback when the animation ends
    // Adds a 50ms buffer to ensure the animation fully completes
    this.animationTimerId = setTimeout(() => {
      if (!this.animationCancelled && this.pendingAnimationCallback) {
        try {
          this.pendingAnimationCallback.onFinish();
        } catch (error) {
          console.error('[MapLibreMap] Error in animation onFinish callback:', error);
        }
      }

      // Clean up
      this.cameraChangeDispatcher.removeOnCameraMoveCanceledListener(cancelListener);
      this.clearAnimationCallback();
    }, duration + 50); // Add 50ms buffer
  }

  /**
   * Called when an animation is cancelled
   */
  private onAnimationCancelled(): void {
    if (this.pendingAnimationCallback && !this.animationCancelled) {
      this.animationCancelled = true;

      try {
        if (this.pendingAnimationCallback.onCancel) {
          this.pendingAnimationCallback.onCancel();
        }
      } catch (error) {
        console.error('[MapLibreMap] Error in animation onCancel callback:', error);
      }

      this.clearAnimationCallback();
    }
  }

  /**
   * Clear the animation callback state
   */
  private clearAnimationCallback(): void {
    if (this.animationTimerId !== null) {
      clearTimeout(this.animationTimerId);
      this.animationTimerId = null;
    }
    this.pendingAnimationCallback = null;
    this.animationCancelled = false;
  }

  // Position and camera helpers
  public getLatLng(): LatLng {
    if (this.destroyed) {
      return LatLng.create(0, 0);
    }
    const nativeLatLng: maplibre.LatLng = this.nativeMapView.getLatLng();
    return LatLng.fromNative(nativeLatLng);
  }

  public setLatLng(latitude: number, longitude: number, padding?: number[], duration?: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setLatLng(latitude, longitude, padding, duration);
  }

  public getCameraForLatLngBounds(bounds: LatLngBounds, top: number, left: number, bottom: number, right: number,
    bearing?: number, tilt?: number): CameraPosition | null {
    if (this.destroyed) {
      return null;
    }
    const result = this.nativeMapView.getCameraForLatLngBounds(bounds, top, left, bottom, right, bearing, tilt);
    // Native layer already returns an object matching the CameraPosition interface
    return result as CameraPosition;
  }

  /**
   * Get a camera position that fits the provided bounds (using current bearing/tilt)
   * Mirrors Android getCameraForLatLngBounds(LatLngBounds)
   *
   * @param bounds Bounds to fit
   * @return Camera position that fits the bounds, or null if the map is destroyed
   */
  public getCameraForBounds(bounds: LatLngBounds): CameraPosition | null {
    if (this.destroyed) {
      return null;
    }
    // Use the current camera to carry over bearing and tilt
    const currentCamera = this.getCameraPosition();
    const bearing = currentCamera ? currentCamera.bearing : 0;
    const tilt = currentCamera ? currentCamera.tilt : 0;
    
    // Use zero padding
    return this.getCameraForLatLngBounds(bounds, 0, 0, 0, 0, bearing, tilt);
  }

  /**
   * Get a camera position that fits the provided bounds and padding (using current bearing/tilt)
   * Mirrors Android getCameraForLatLngBounds(LatLngBounds, int[] padding)
   *
   * @param bounds Bounds to fit
   * @param padding EdgeInsets padding
   * @return Camera position that fits the bounds/padding, or null if the map is destroyed
   */
  public getCameraForBoundsWithPadding(bounds: LatLngBounds, padding: EdgeInsets): CameraPosition | null {
    if (this.destroyed) {
      return null;
    }
    // Use the current camera to carry over bearing and tilt
    const currentCamera = this.getCameraPosition();
    const bearing = currentCamera ? currentCamera.bearing : 0;
    const tilt = currentCamera ? currentCamera.tilt : 0;
    
    // Deconstruct EdgeInsets into individual padding values
    return this.getCameraForLatLngBounds(bounds, padding.top, padding.left, padding.bottom, padding.right, bearing, tilt);
  }

  /**
   * Get a camera position that fits bounds, padding, bearing, and tilt
   * Mirrors Android getCameraForLatLngBounds(LatLngBounds, int[] padding, double bearing, double tilt)
   *
   * @param bounds Bounds to fit
   * @param padding EdgeInsets padding
   * @param bearing Bearing in degrees (0–360, 0 is north)
   * @param tilt Tilt in degrees (0–60, 0 is top-down)
   * @return Camera position that satisfies all parameters, or null if the map is destroyed
   */
  public getCameraForBoundsWithOptions(bounds: LatLngBounds, padding: EdgeInsets, bearing: number, tilt: number): CameraPosition | null {
    if (this.destroyed) {
      return null;
    }
    // Deconstruct EdgeInsets into individual padding values
    return this.getCameraForLatLngBounds(bounds, padding.top, padding.left, padding.bottom, padding.right, bearing, tilt);
  }

  /**
   * Fit the camera to the specified bounds
   * Mirrors iOS setVisibleCoordinateBounds:animated:
   *
   * @param bounds Bounds to fit
   * @param animated Whether to animate, default true
   * @param duration Animation duration in milliseconds, default 300ms
   */
  public setCameraForBounds(bounds: LatLngBounds, animated: boolean = true, duration: number = 300): void {
    if (this.destroyed) {
      return;
    }
    
    const camera = this.getCameraForBounds(bounds);
    if (!camera) {
      return;
    }
    
    if (animated) {
      this.animateCamera(camera, duration);
    } else {
      this.jumpTo(camera.bearing, camera.target.latitude, camera.target.longitude, camera.tilt, camera.zoom);
    }
  }

  /**
   * Fit the camera to the specified bounds and padding
   * Mirrors iOS setVisibleCoordinateBounds:edgePadding:animated:
   *
   * @param bounds Bounds to fit
   * @param padding EdgeInsets padding
   * @param animated Whether to animate, default true
   * @param duration Animation duration in milliseconds, default 300ms
   */
  public setCameraForBoundsWithPadding(bounds: LatLngBounds, padding: EdgeInsets, animated: boolean = true, duration: number = 300): void {
    if (this.destroyed) {
      return;
    }
    
    const camera = this.getCameraForBoundsWithPadding(bounds, padding);
    if (!camera) {
      return;
    }
    
    if (animated) {
      this.animateCamera(camera, duration);
    } else {
      this.jumpTo(camera.bearing, camera.target.latitude, camera.target.longitude, camera.tilt, camera.zoom);
    }
  }

  /**
   * Fit the camera to bounds with padding, bearing, and tilt
   *
   * @param bounds Bounds to fit
   * @param padding EdgeInsets padding
   * @param bearing Bearing in degrees (0–360, 0 is north)
   * @param tilt Tilt in degrees (0–60, 0 is top-down)
   * @param animated Whether to animate, default true
   * @param duration Animation duration in milliseconds, default 300ms
   */
  public setCameraForBoundsWithOptions(bounds: LatLngBounds, padding: EdgeInsets, bearing: number, tilt: number, animated: boolean = true, duration: number = 300): void {
    if (this.destroyed) {
      return;
    }
    
    const camera = this.getCameraForBoundsWithOptions(bounds, padding, bearing, tilt);
    if (!camera) {
      return;
    }
    
    if (animated) {
      this.animateCamera(camera, duration);
    } else {
      this.jumpTo(camera.bearing, camera.target.latitude, camera.target.longitude, camera.tilt, camera.zoom);
    }
  }

  public getCameraForGeometry(geometry: Geometry, top: number, left: number, bottom: number, right: number,
    bearing?: number, tilt?: number): CameraPosition | null {
    if (this.destroyed) {
      return null;
    }
    const result = this.nativeMapView.getCameraForGeometry(geometry, top, left, bottom, right, bearing, tilt);
    // Native layer already returns an object matching the CameraPosition interface
    return result as CameraPosition;
  }

  public setReachability(status: boolean): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setReachability(status);
  }

  public resetPosition(): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.resetPosition();
  }

  // Tilt control
  public getPitch(): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getPitch();
  }

  public setPitch(pitch: number, duration?: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setPitch(pitch, duration);
  }

  // Zoom control
  public setZoom(zoom: number, cx?: number, cy?: number, duration?: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setZoom(zoom, cx, cy, duration);
  }

  public getZoom(): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getZoom();
  }

  public resetZoom(): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.resetZoom();
  }

  public setMinZoom(zoom: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setMinZoom(zoom);
  }

  public getMinZoom(): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getMinZoom();
  }

  public setMaxZoom(zoom: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setMaxZoom(zoom);
  }

  public getMaxZoom(): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getMaxZoom();
  }

  // Tilt limits
  public setMinPitch(pitch: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setMinPitch(pitch);
  }

  public getMinPitch(): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getMinPitch();
  }

  public setMaxPitch(pitch: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setMaxPitch(pitch);
  }

  public getMaxPitch(): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getMaxPitch();
  }

  // Rotation
  public rotateBy(sx: number, sy: number, ex: number, ey: number, duration?: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.rotateBy(sx, sy, ex, ey, duration);
  }

  // Bearing control
  public setBearing(degrees: number, duration?: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setBearing(degrees, duration);
  }

  public setBearingXY(degrees: number, fx: number, fy: number, duration?: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setBearingXY(degrees, fx, fy, duration);
  }

  public getBearing(): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getBearing();
  }

  public resetNorth(duration: number = 150): void {
    if (this.destroyed) {
      return;
    }
    // Animate back to north (mirrors Android TIME_MAP_NORTH_ANIMATION = 150ms)
    this.nativeMapView.setBearing(0, duration);
  }

  // Coordinate bounds
  public setVisibleCoordinateBounds(coordinates: LatLng[], padding: Rect, direction: number, duration: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setVisibleCoordinateBounds(coordinates, padding, direction, duration);
  }

  public getVisibleCoordinateBounds(): LatLng[] {
    if (this.destroyed) {
      return [];
    }
    const nativeLatLngs = this.nativeMapView.getVisibleCoordinateBounds();
    return nativeLatLngs.map(native => LatLng.fromNative(native));
  }

  // Snapshot
  public scheduleSnapshot(): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.scheduleSnapshot();
  }

  /**
   * Retrieve the current map snapshot as a PixelMap.
   */
  public snapshot(): Promise<image.PixelMap> {
    if (this.destroyed) {
      return Promise.reject(new Error('MapLibreMap has been destroyed'));
    }
    if (!this.nativeMapView) {
      return Promise.reject(new Error('NativeMapView not initialized'));
    }

    return new Promise((resolve, reject) => {
      let readyListener: (payload: MapViewSnapshotPayload) => Promise<void>;
      let errorListener: (message: string) => void;

      const cleanup = (): void => {
        if (!this.nativeMapView) {
          return;
        }
        this.nativeMapView.removeOnSnapshotReadyListener(readyListener);
        this.nativeMapView.removeOnSnapshotErrorListener(errorListener);
      };

      readyListener = async (payload: MapViewSnapshotPayload): Promise<void> => {
        cleanup();
        try {
          const pixelMap = await this.createPixelMapFromSnapshot(payload);
          resolve(pixelMap);
        } catch (error) {
          reject(error instanceof Error ? error : new Error(`${error}`));
        }
      };

      errorListener = (message: string): void => {
        cleanup();
        reject(new Error(message));
      };

      this.nativeMapView.addOnSnapshotReadyListener(readyListener);
      this.nativeMapView.addOnSnapshotErrorListener(errorListener);

      try {
        this.nativeMapView.scheduleSnapshot();
      } catch (error) {
        cleanup();
        reject(error instanceof Error ? error : new Error(`${error}`));
      }
    });
  }
  private async createPixelMapFromSnapshot(payload: MapViewSnapshotPayload): Promise<image.PixelMap> {
    return new Promise((resolve, reject) => {
      try {
        const imageInfo: image.ImageInfo = {
          size: { width: payload.width, height: payload.height },
          pixelFormat: image.PixelMapFormat.RGBA_8888,
          alphaType: image.AlphaType.PREMUL,
          density: 160,
          stride: payload.width * 4,
          mimeType: 'image/png',
          isHdr: false,
        };

        image.createPixelMap(payload.data, imageInfo, (err, pixelMap) => {
          if (err) {
            reject(err);
          } else {
            resolve(pixelMap);
          }
        });
      } catch (error) {
        reject(error);
      }
    });
  }

  // Camera position
  public getCameraPosition(): CameraPosition | null {
    if (this.destroyed) {
      return null;
    }
    const result = this.nativeMapView.getCameraPosition();
    return result as CameraPosition;
  }

  /**
   * Set the camera position (instant jump without animation)
   * Mirrors the simplified Android camera helper
   *
   * @param position Target camera position
   */
  public setCameraPosition(position: CameraPosition): void;
  
  /**
   * Set the camera position (with animation)
   * Mirrors the simplified Android camera helper
   *
   * @param position Target camera position
   * @param duration Animation duration in milliseconds
   */
  public setCameraPosition(position: CameraPosition, duration: number): void;
  
  /**
   * Implementation for setCameraPosition
   */
  public setCameraPosition(position: CameraPosition, duration?: number): void {
    if (this.destroyed) {
      return;
    }
    
    if (duration !== undefined && duration > 0) {
      // Animate
      this.animateCamera(position, duration);
    } else {
      // Jump immediately
      this.jumpTo(
        position.bearing,
        position.target.latitude,
        position.target.longitude,
        position.tilt,
        position.zoom
      );
    }
  }

  // Annotations
  /**
   * Update a marker
   *
   * Uses the MarkerManager GeoJSON update path to support all properties (alpha, rotation, zIndex, etc.)
   * Replaces the native updateMarker (which only handled position and icon)
   *
   * @param marker Marker to update
   */
  public updateMarker(marker: Marker): void {
    if (this.destroyed) {
      return;
    }

    try {
      // Leverage MarkerManager public APIs so all properties can be updated: position, icon, alpha, rotation, zIndex, etc.
      this.markerManager.updateMarker(marker);

    } catch (error) {
      console.error('[MapLibreMap] updateMarker: Failed -', error);
    }
  }

  public addMarkers(markers: Marker[]): number[] {
    if (this.destroyed) {
      console.warn(`[MarkerDebug] MapLibreMap: ⚠️ Map is destroyed, cannot add markers`);
      return [];
    }

    // [MarkerDebug] Log state before calling into NAPI
    for (let i = 0; i < markers.length; i++) {
      const pos = markers[i].getPosition();
      const icon = markers[i].getIcon();
    }

    // Convert wrapped markers into native marker objects
    const nativeMarkers: maplibre.Marker[] = markers.map((m: Marker): maplibre.Marker => m.getNative());
    const ids: number[] = this.nativeMapView.addMarkers(nativeMarkers);

    // [MarkerDebug] Log NAPI result

    return ids;
  }

  public addPolylines(polylines: Polyline[]): number[] {
    if (this.destroyed) {
      return [];
    }
    // Extract native objects
    const nativePolylines = polylines.map(p => p.getNative());
    return this.nativeMapView.addPolylines(nativePolylines);
  }

  public addPolygons(polygons: Polygon[]): number[] {
    if (this.destroyed) {
      return [];
    }
    // Extract native objects
    const nativePolygons = polygons.map(p => p.getNative());
    return this.nativeMapView.addPolygons(nativePolygons);
  }

  public updatePolyline(polyline: Polyline): void {
    if (this.destroyed) {
      return;
    }
    if (!polyline) {
      console.error('MapLibreMap.updatePolyline: polyline is null or undefined');
      return;
    }

    try {
      const nativePolyline = polyline.getNative();
      if (!nativePolyline) {
        console.error('MapLibreMap.updatePolyline: nativePolyline is null or undefined');
        return;
      }

      // Pass the native NAPI object so C++ can unwrap (the C++ layer reads the ID from the object)
      this.nativeMapView.updatePolyline(nativePolyline);
    } catch (error) {
      console.error(`MapLibreMap.updatePolyline: Exception - ${error}`);
      // throw error;
    }
  }

  public updatePolygon(polygon: Polygon): void {
    if (this.destroyed) {
      return;
    }
    if (!polygon) {
      console.error('MapLibreMap.updatePolygon: polygon is null or undefined');
      return;
    }

    try {
      const nativePolygon = polygon.getNative();
      if (!nativePolygon) {
        console.error('MapLibreMap.updatePolygon: nativePolygon is null or undefined');
        return;
      }

      // Pass the native NAPI object so C++ can unwrap it (C++ layer reads the ID from the object)
      this.nativeMapView.updatePolygon(nativePolygon);
    } catch (error) {
      console.error(`MapLibreMap.updatePolygon: Exception - ${error}`);
      // throw error;
    }
  }

  public removeAnnotations(ids: number[]): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.removeAnnotations(ids);
  }

  public addAnnotationIcon(symbol: string, width: number, height: number, scale: number, pixels: Uint8Array): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.addAnnotationIcon(symbol, width, height, scale, pixels);
  }

  public removeAnnotationIcon(symbol: string): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.removeAnnotationIcon(symbol);
  }

  public getTopOffsetPixelsForAnnotationSymbol(symbolName: string): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getTopOffsetPixelsForAnnotationSymbol(symbolName);
  }

  // Memory management
  public onLowMemory(): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.onLowMemory();
  }

  // Debug (deprecated, use setDebugActive or setDebugOptions instead)
  // Retained for backward compatibility but delegates to the new API
  public setDebug(debug: boolean): void {
    if (this.destroyed) {
      return;
    }
    this.setDebugActive(debug);
  }

  public getDebug(): boolean {
    if (this.destroyed) {
      return false;
    }
    return this.isDebugActive();
  }

  // Action journal
  public getActionJournalLogFiles(): string[] {
    if (this.destroyed) {
      return [];
    }
    return this.nativeMapView.getActionJournalLogFiles();
  }

  public getActionJournalLog(): string[] {
    if (this.destroyed) {
      return [];
    }
    return this.nativeMapView.getActionJournalLog();
  }

  public clearActionJournalLog(): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.clearActionJournalLog();
  }

  // Load status
  public isFullyLoaded(): boolean {
    if (this.destroyed) {
      return false;
    }
    return this.nativeMapView.isFullyLoaded();
  }

  // Coordinate transformations
  public projectedMetersForLatLng(latitude: number, longitude: number): ProjectedMeters {
    if (this.destroyed) {
      return new ProjectedMeters(0, 0);
    }
    const result: IProjectedMeters = this.nativeMapView.projectedMetersForLatLng(latitude, longitude);
    return ProjectedMeters.fromObject(result);
  }

  /**
   * Convert geographic coordinates to physical pixel coordinates (map internal coordinate system)
   *
   * ⚠️ Intended for internal map calculations (hit testing, feature queries, etc.)
   * For ArkUI positioning use pixelForLatLng()
   *
   * @param latitude Latitude
   * @param longitude Longitude
   * @returns Physical pixel coordinates
   */
  public pixelForLatLngPhysical(latitude: number, longitude: number): Point {
    if (this.destroyed) {
      return new PixelCoordinate(0, 0);
    }
    const result: IPixelCoordinate = this.nativeMapView.pixelForLatLng(latitude, longitude);
    return PixelCoordinate.fromObject(result);
  }

  /**
   * Convert geographic coordinates to logical pixel coordinates
   *
   * Used for ArkUI component positioning (InfoWindow, custom overlays, etc.)
   *
   * @param latitude Latitude
   * @param longitude Longitude
   * @returns Logical pixel coordinates
   */
  public pixelForLatLng(latitude: number, longitude: number): Point {
    const physicalPixel = this.pixelForLatLngPhysical(latitude, longitude);
    const pixelRatio = this.nativeMapView.getPixelRatio();
    return new PixelCoordinate(
      physicalPixel.x / pixelRatio,
      physicalPixel.y / pixelRatio
    );
  }

  public pixelsForLatLngs(input: number[], output: number[]): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.pixelsForLatLngs(input, output);
    const pixelRatio = this.readPixelRatioSafe(this.nativeMapView);
    const safeRatio = pixelRatio === 0 ? 1 : pixelRatio;
    for (let i = 0; i + 1 < output.length; i += 2) {
      output[i] = output[i] / safeRatio;
      output[i + 1] = output[i + 1] / safeRatio;
    }
  }

  public latLngForProjectedMeters(northing: number, easting: number): LatLng {
    if (this.destroyed) {
      return LatLng.create(0, 0);
    }
    const nativeLatLng: maplibre.LatLng = this.nativeMapView.latLngForProjectedMeters(northing, easting);
    return LatLng.fromNative(nativeLatLng);
  }

  /**
   * Convert physical pixel coordinates back to geographic coordinates (map internal coordinate system)
   *
   * ⚠️ Intended for internal map calculations.
   * For logical pixels use latLngForPixel()
   *
   * @param x Physical pixel X coordinate
   * @param y Physical pixel Y coordinate
   * @returns Geographic coordinates
   */
  public latLngForPixelPhysical(x: number, y: number): LatLng {
    if (this.destroyed) {
      return LatLng.create(0, 0);
    }
    const nativeLatLng: maplibre.LatLng = this.nativeMapView.latLngForPixel(x, y);
    return LatLng.fromNative(nativeLatLng);
  }

  /**
   * Convert logical pixel coordinates to geographic coordinates
   *
   * Used for ArkUI component coordinate conversion
   *
   * @param x Logical pixel X coordinate
   * @param y Logical pixel Y coordinate
   * @returns Geographic coordinates
   */
  public latLngForPixel(x: number, y: number): LatLng {
    const pixelRatio = this.nativeMapView.getPixelRatio();
    const physicalX = x * pixelRatio;
    const physicalY = y * pixelRatio;
    return this.latLngForPixelPhysical(physicalX, physicalY);
  }

  public latLngsForPixels(input: number[], output: number[]): void {
    if (this.destroyed) {
      return;
    }
    const pixelRatio = this.readPixelRatioSafe(this.nativeMapView);
    const safeRatio = pixelRatio === 0 ? 1 : pixelRatio;
    const physicalInput: number[] = input.slice();
    for (let i = 0; i + 1 < physicalInput.length; i += 2) {
      physicalInput[i] = physicalInput[i] * safeRatio;
      physicalInput[i + 1] = physicalInput[i + 1] * safeRatio;
    }
    this.nativeMapView.latLngsForPixels(physicalInput, output);
  }

  // Transitions
  public getTransitionOptions(): TransitionOptions {
    if (this.destroyed) {
      return new TransitionOptions(0, 0);
    }
    const result = this.nativeMapView.getTransitionOptions();
    return TransitionOptions.fromObject(result);
  }

  public setTransitionOptions(options: TransitionOptions): void {
    if (this.destroyed) {
      return;
    }
    // Convert to a plain object for NAPI
    this.nativeMapView.setTransitionOptions(options.toObject());
  }


  // Lighting
  public getLight(): Light | null {
    if (this.destroyed) {
      return null;
    }
    const nativeLight = this.nativeMapView.getLight();
    if (!nativeLight) {
      return null;
    }
    return Light.fromNative(nativeLight as maplibre.Light);
  }

  // Layer helpers — strong typed Layer
  public getLayers(): Layer[] {
    if (this.destroyed) {
      return [];
    }
    // Use Style.getLayers to return properly wrapped Layer objects
    const style = this.getStyle();
    if (style) {
      return style.getLayers();
    }
    // Return empty array if the style is not yet loaded
    return [];
  }

  public getLayer(layerId: string): Layer | null {
    if (this.destroyed) {
      return null;
    }
    // Use Style.getLayer to ensure we return a properly wrapped Layer instance
    const style = this.getStyle();
    if (style) {
      return style.getLayer(layerId);
    }
    // Return null if the style is not yet loaded
    return null;
  }

  public addLayer(layer: Layer): void {
    if (this.destroyed) {
      return;
    }
    const style = this.getStyle();
    if (style) {
      style.addLayer(layer);
    }
  }

  public addLayerAbove(layer: Layer, aboveLayerId: string): void {
    if (this.destroyed) {
      return;
    }
    const style = this.getStyle();
    if (style) {
      style.addLayerAbove(layer, aboveLayerId);
    }
  }

  public addLayerAt(layer: Layer, index: number): void {
    if (this.destroyed) {
      return;
    }
    const style = this.getStyle();
    if (style) {
      style.addLayerAt(layer, index);
    }
  }

  public removeLayerAt(index: number): boolean {
    if (this.destroyed) {
      return false;
    }
    const style = this.getStyle();
    if (style) {
      return style.removeLayerAt(index);
    }
    return false;
  }

  public removeLayer(layer: Layer | string): boolean {
    if (this.destroyed) {
      return false;
    }
    const style = this.getStyle();
    if (style) {
      const layerId = typeof layer === 'string' ? layer : layer.getId();
      return style.removeLayer(layerId);
    }
    return false;
  }

  // Source helpers — strong typed Source
  public getSources(): Source[] {
    if (this.destroyed) {
      return [];
    }
    const style = this.getStyle();
    if (style) {
      return style.getSources();
    }
    return [];
  }

  public getSource(sourceId: string): Source | null {
    if (this.destroyed) {
      return null;
    }
    const style = this.getStyle();
    if (style) {
      return style.getSource(sourceId);
    }
    return null;
  }

  public addSource(source: Source): void {
    if (this.destroyed) {
      return;
    }
    const style = this.getStyle();
    if (style) {
      style.addSource(source);
    }
  }

  public removeSource(source: Source | string): boolean {
    if (this.destroyed) {
      return false;
    }
    const style = this.getStyle();
    if (style) {
      const sourceId = typeof source === 'string' ? source : source.getId();
      return style.removeSource(sourceId);
    }
    return false;
  }

  // Images
  /**
   * Register an image resource from a PixelMap.
   *
   * @param name Image identifier.
   * @param pixelMap HarmonyOS PixelMap instance.
   * @param pixelRatio Pixel ratio, defaults to 1.0.
   * @param sdf Whether the image is an SDF asset.
   */
  public addImage(name: string, pixelMap: image.PixelMap, pixelRatio: number = 1.0, sdf: boolean = false): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.addImage(name, pixelMap, pixelRatio, sdf);
  }

  public addImages(images: Image[]): void {
    if (this.destroyed) {
      return;
    }
    const nativeImages = images.map(img => img.getNative());
    this.nativeMapView.addImages(nativeImages);
  }

  /**
   * Add images asynchronously in bulk (non-blocking for the UI thread)
   * @param images Array of image objects
   * @returns Promise<void> resolved when complete
   */
  public addImagesAsync(images: Image[]): Promise<void> {
    if (this.destroyed) {
      return Promise.reject(new Error('Map is destroyed'));
    }
    const style = this.getStyle();
    if (!style) {
      return Promise.reject(new Error('Style not loaded'));
    }
    return style.addImagesAsync(images);
  }

  public removeImage(name: string): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.removeImage(name);
  }

  public getImage(name: string): Icon | null {
    if (this.destroyed) {
      return null;
    }
    const result = this.nativeMapView.getImage(name);
    return result as Icon | null;
  }

  // Tile management
  public setPrefetchTiles(enable: boolean): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setPrefetchTiles(enable);
  }

  public getPrefetchTiles(): boolean {
    if (this.destroyed) {
      return false;
    }
    return this.nativeMapView.getPrefetchTiles();
  }

  public setPrefetchZoomDelta(delta: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setPrefetchZoomDelta(delta);
  }

  public getPrefetchZoomDelta(): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getPrefetchZoomDelta();
  }

  public setTileCacheEnabled(enabled: boolean): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setTileCacheEnabled(enabled);
  }

  public getTileCacheEnabled(): boolean {
    if (this.destroyed) {
      return false;
    }
    return this.nativeMapView.getTileCacheEnabled();
  }

  // Tile LOD
  public setTileLodMinRadius(radius: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setTileLodMinRadius(radius);
  }

  public getTileLodMinRadius(): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getTileLodMinRadius();
  }

  public setTileLodScale(scale: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setTileLodScale(scale);
  }

  public getTileLodScale(): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getTileLodScale();
  }

  public setTileLodPitchThreshold(threshold: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setTileLodPitchThreshold(threshold);
  }

  public getTileLodPitchThreshold(): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getTileLodPitchThreshold();
  }

  public setTileLodZoomShift(shift: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setTileLodZoomShift(shift);
  }

  public getTileLodZoomShift(): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getTileLodZoomShift();
  }

  // Rendering
  public triggerRepaint(): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.triggerRepaint();
  }

  public isRenderingStatsViewEnabled(): boolean {
    if (this.destroyed) {
      return false;
    }
    return this.nativeMapView.isRenderingStatsViewEnabled();
  }

  public enableRenderingStatsView(enabled: boolean): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.enableRenderingStatsView(enabled);
  }

  // Retrieve the native map view
  public getNativeMapView(): NativeMapView {
    return this.nativeMapView;
  }

  // ========== Marker management helpers ==========

  /**
   * Add a single marker
   *
   * @param options MarkerOptions instance
   * @returns Promise<Marker> The created marker
   */
  public async addMarker(options: MarkerOptions): Promise<Marker> {
    if (this.destroyed) {
      throw new Error('Map has been destroyed');
    }
    return await this.markerManager.addMarker(options);
  }

  /**
   * Add multiple markers
   *
   * @param optionsList Array of MarkerOptions
   * @returns Promise<Marker[]> Array of created markers
   */
  public async addMarkersBatch(optionsList: MarkerOptions[]): Promise<Marker[]> {
    if (this.destroyed) {
      return [];
    }
    return await this.markerManager.addMarkers(optionsList);
  }

  /**
   * Remove a single marker
   *
   * @param marker Marker to remove
   */
  public removeMarker(marker: Marker): void {
    if (this.destroyed) {
      return;
    }
    this.markerManager.removeMarker(marker);
  }

  /**
   * Remove an annotation (generic helper)
   *
   * @param annotation Annotation to remove
   */
  public removeAnnotation(annotation: Annotation | Marker): void {
    if (this.destroyed) {
      return;
    }

    // Attempt a type check: Marker provides getPosition
    try {
      const marker = annotation as Marker;
      marker.getPosition(); // Invoke method to validate
      this.markerManager.removeMarker(marker);
      return;
    } catch (e) {
      // Not a Marker, fall through to other types
    }

    // For other annotation types (Polyline, Polygon) use the original path
    const id = (annotation as Annotation).getId();
    if (id !== -1) {
      this.removeAnnotations([id]);
    }
  }

  /**
   * Remove multiple annotations
   *
   * @param annotations Array of annotations
   */
  public removeAnnotationsBatch(annotations: (Annotation | Marker)[]): void {
    if (this.destroyed) {
      return;
    }

    const markers: Marker[] = [];
    const otherIds: number[] = [];

    for (const annotation of annotations) {
      // Attempt a type check: Marker exposes getPosition
      try {
        const marker = annotation as Marker;
        marker.getPosition(); // Invoke method to validate
        markers.push(marker);
        continue;
      } catch (e) {
        // Not a Marker, continue handling other types
      }

      const id = (annotation as Annotation).getId();
      if (id !== -1) {
        otherIds.push(id);
      }
    }

    // Remove markers
    if (markers.length > 0) {
      this.markerManager.removeMarkers(markers);
    }

    // Remove other annotation types
    if (otherIds.length > 0) {
      this.removeAnnotations(otherIds);
    }
  }

  /**
   * Clear all markers
   */
  public clearMarkers(): void {
    if (this.destroyed) {
      return;
    }
    this.markerManager.clear();
  }

  /**
   * Clear all annotations (Android-style clear())
   * Removes all markers, polylines, polygons, etc.
   */
  public clear(): void {
    if (this.destroyed) {
      return;
    }

    // Clear all markers
    this.markerManager.clear();

    // Close all InfoWindows
    this.infoWindowManager.closeAll();

    // Clear all AnnotationViews
    this.annotationViewManager.clear();
  }

  /**
   * Get all markers
   *
   * @returns Array of markers
   */
  public getMarkers(): Marker[] {
    if (this.destroyed) {
      return [];
    }
    return this.markerManager.getMarkers();
  }

  /**
   * Get a marker by ID
   *
   * @param id Marker ID
   * @returns Marker instance, or null if not found
   */
  public getMarkerById(id: number): Marker | null {
    if (this.destroyed) {
      return null;
    }
    return this.markerManager.getMarker(id);
  }

// ========== Marker selection management ==========

  /**
   * Select a marker
   *
   * @param marker Marker to select
   * @param animated Whether to animate (not yet implemented)
   */
  public selectMarker(marker: Marker, animated: boolean = true): void {
    if (this.destroyed) {
      return;
    }
    this.markerManager.selectMarker(marker, true);
  }

  /**
   * Deselect a marker
   *
   * @param marker Marker to deselect
   */
  public deselectMarker(marker: Marker): void {
    if (this.destroyed) {
      return;
    }
    this.markerManager.deselectMarker(marker);
  }

  /**
   * Deselect all markers
   */
  public deselectMarkers(): void {
    if (this.destroyed) {
      return;
    }
    this.markerManager.deselectMarkers();
  }

  /**
   * Get all selected markers
   *
   * @returns Array of selected markers
   */
  public getSelectedMarkers(): Marker[] {
    if (this.destroyed) {
      return [];
    }
    return this.markerManager.getSelectedMarkers();
  }

// ========== Event listeners ==========

  /**
   * Set the marker click listener
   *
   * @param listener Listener instance
   */
  public setOnMarkerClickListener(listener: OnMarkerClickListener | null): void {
    if (this.destroyed) {
      console.warn(`[MapLibreMap] ⚠️ Map is destroyed, cannot set listener`);
      return;
    }
    this.markerManager.setOnMarkerClickListener(listener);
  }

  /**
   * Set the marker long-click listener
   *
   * @param listener Listener instance
   */
  public setOnMarkerLongClickListener(listener: OnMarkerLongClickListener | null): void {
    if (this.destroyed) {
      console.warn(`[MapLibreMap] ⚠️ Map is destroyed, cannot set listener`);
      return;
    }
    this.markerManager.setOnMarkerLongClickListener(listener);
  }

  /**
   * Set the marker drag listener
   *
   * @param listener Listener instance
   */
  public setOnMarkerDragListener(listener: OnMarkerDragListener | null): void {
    if (this.destroyed) {
      return;
    }
    this.markerManager.setOnMarkerDragListener(listener);
  }

  /**
   * Set the marker selection listener
   *
   * @param listener Listener instance
   */
  public setOnMarkerSelectListener(listener: OnMarkerSelectListener | null): void {
    if (this.destroyed) {
      return;
    }
    this.markerManager.setOnMarkerSelectListener(listener);
  }

  /**
   * Get the marker selection listener
   *
   * @returns Listener instance
   */
  public getOnMarkerSelectListener(): OnMarkerSelectListener | null {
    if (this.destroyed) {
      return null;
    }
    return this.markerManager.getOnMarkerSelectListener();
  }

  /**
   * Set the InfoWindow click listener
   *
   * @param listener Listener instance
   */
  public setOnInfoWindowClickListener(listener: OnInfoWindowClickListener | null): void {
    if (this.destroyed) {
      return;
    }
    this.markerManager.setOnInfoWindowClickListener(listener);
  }

  /**
   * Set the InfoWindow close listener
   *
   * @param listener Listener instance
   */
  public setOnInfoWindowCloseListener(listener: OnInfoWindowCloseListener | null): void {
    if (this.destroyed) {
      return;
    }
    this.markerManager.setOnInfoWindowCloseListener(listener);
  }

  /**
   * Get the InfoWindow close listener
   *
   * @returns Listener instance
   */
  public getOnInfoWindowCloseListener(): OnInfoWindowCloseListener | null {
    if (this.destroyed) {
      return null;
    }
    return this.markerManager.getOnInfoWindowCloseListener();
  }

  /**
   * Set the InfoWindow adapter
   *
   * Allows customizing InfoWindow content
   *
   * @param adapter Adapter instance
   */
  public setInfoWindowAdapter(adapter: InfoWindowAdapter | null): void {
    if (this.destroyed) {
      return;
    }
    this.markerManager.setInfoWindowAdapter(adapter);
  }

// ==================== Style listener management ====================

  /**
   * Add a style-loaded listener
   *
   * @param listener Listener instance
   */
  public addOnStyleLoadedListener(listener: OnStyleLoadedListener): void {
    if (this.destroyed) {
      return;
    }
    if (!this.styleLoadedListeners.includes(listener)) {
      this.styleLoadedListeners.push(listener);

      // If the style is already loaded, invoke immediately
      if (this.styleLoaded) {
        try {
          // Note: Style currently passes null
          listener.onStyleLoaded(null);
        } catch (error) {
          console.error(`MapLibreMap: Error in onStyleLoaded listener: ${error}`);
        }
      }
    }
  }

  /**
   * Remove a style-loaded listener
   *
   * @param listener Listener instance to remove
   */
  public removeOnStyleLoadedListener(listener: OnStyleLoadedListener): void {
    const index = this.styleLoadedListeners.indexOf(listener);
    if (index !== -1) {
      this.styleLoadedListeners.splice(index, 1);
    }
  }

  /**
   * Add a style load error listener
   *
   * @param listener Listener instance
   */
  public addOnStyleLoadErrorListener(listener: OnStyleLoadErrorListener): void {
    if (this.destroyed) {
      return;
    }
    if (!this.styleLoadErrorListeners.includes(listener)) {
      this.styleLoadErrorListeners.push(listener);
    }
  }

  /**
   * Remove a style load error listener
   *
   * @param listener Listener instance to remove
   */
  public removeOnStyleLoadErrorListener(listener: OnStyleLoadErrorListener): void {
    const index = this.styleLoadErrorListeners.indexOf(listener);
    if (index !== -1) {
      this.styleLoadErrorListeners.splice(index, 1);
    }
  }

  /**
   * Set the style image missing listener
   * Triggered when the renderer requests an image that is not available; useful for lazy-loading
   *
   * @param listener Callback invoked with the missing image ID
   */
  public setOnStyleImageMissingListener(listener: ((imageId: string) => void) | null): void {
    if (this.destroyed) {
      return;
    }
    this.styleImageMissingListener = listener ?? undefined;
  }

  /**
   * Remove the style image missing listener
   */
  public removeOnStyleImageMissingListener(): void {
    this.styleImageMissingListener = undefined;
  }

  /**
   * Add a pending operation to the queue
   *
   * Executes immediately if the style is already loaded; otherwise queues the operation until the style loads.
   *
   * @param operation Operation to execute
   */
  public waitForStyle(operation: PendingOperation): void {
    if (this.destroyed) {
      return;
    }

    if (this.styleLoaded) {
      // Style already loaded, execute now
      try {
        operation();
      } catch (error) {
        console.error(`MapLibreMap: Error executing operation: ${error}`);
      }
    } else {
      // Style not yet loaded, enqueue
      this.pendingOperations.push(operation);
    }
  }

  /**
   * Get the InfoWindow adapter
   *
   * @returns Adapter instance
   */
  public getInfoWindowAdapter(): InfoWindowAdapter | null {
    if (this.destroyed) {
      return null;
    }
    return this.markerManager.getInfoWindowAdapter();
  }

  /**
   * Get the MarkerManager instance (internal use)
   *
   * @returns MarkerManager instance
   */
  public getMarkerManager(): MarkerManager {
    return this.markerManager;
  }

  /**
   * Show the InfoWindow for a marker
   *
   * @param marker Marker to display
   */
  public showInfoWindow(marker: Marker): void {
    if (this.destroyed) {
      return;
    }
    this.markerManager.showInfoWindow(marker);
  }

  /**
   * Hide the InfoWindow for a marker
   *
   * @param marker Marker to hide
   */
  public hideInfoWindow(marker: Marker): void {
    if (this.destroyed) {
      return;
    }
    this.markerManager.hideInfoWindow(marker);
  }

// ========== Polygon management ==========

  /**
   * Get all polygons
   *
   * @returns Array of polygons
   */
  public getPolygons(): Polygon[] {
    if (this.destroyed) {
      return [];
    }
    return this.polygonManager.getPolygons();
  }

  /**
   * Clear all polygons
   */
  public clearPolygons(): void {
    if (this.destroyed) {
      return;
    }
    this.polygonManager.clear();
  }

  /**
   * Get the PolygonManager instance (internal use)
   *
   * @returns PolygonManager instance
   */
  public getPolygonManager(): PolygonManager {
    return this.polygonManager;
  }

// ========== Polyline management ==========

  /**
   * Get all polylines
   *
   * @returns Array of polylines
   */
  public getPolylines(): Polyline[] {
    if (this.destroyed) {
      return [];
    }
    return this.polylineManager.getPolylines();
  }

  /**
   * Clear all polylines
   */
  public clearPolylines(): void {
    if (this.destroyed) {
      return;
    }
    this.polylineManager.clear();
  }

  /**
   * Get the PolylineManager instance (internal use)
   *
   * @returns PolylineManager instance
   */
  public getPolylineManager(): PolylineManager {
    return this.polylineManager;
  }

  /**
   * Hide all InfoWindows
   */
  public hideAllInfoWindows(): void {
    if (this.destroyed) {
      return;
    }
    this.markerManager.hideAllInfoWindows();
  }

// ========== Camera listener helpers ==========

  /**
   * Add an on-camera-will-change listener
   * Mirrors the Android MapView.addOnCameraWillChangeListener callback
   *
   * @param listener OnCameraWillChangeListener instance
   */
  public addOnCameraWillChangeListener(listener: OnCameraWillChangeListener): void {
    if (this.destroyed) {
      return;
    }
    if (this.cameraWillChangeWrappers.has(listener)) {
      return;
    }
    const wrapper: OnCameraWillChangeListener = (animated: boolean) => {
      try {
        listener(animated);
      } catch (error) {
        const message: string = error instanceof Error ? `${error.name}: ${error.message}` : `${error}`;
        logListenerError('OnCameraWillChangeListener', message);
      }
    };
    this.cameraWillChangeWrappers.set(listener, wrapper);
    this.nativeMapView.addOnCameraWillChangeListener(wrapper);
  }

  /**
   * Remove an on-camera-will-change listener
   *
   * @param listener Listener to remove
   */
  public removeOnCameraWillChangeListener(listener: OnCameraWillChangeListener): void {
    if (this.destroyed) {
      return;
    }
    const wrapper = this.cameraWillChangeWrappers.get(listener);
    if (wrapper) {
      this.nativeMapView.removeOnCameraWillChangeListener(wrapper);
      this.cameraWillChangeWrappers.delete(listener);
    }
  }

  /**
   * Add an on-camera-is-changing listener
   * Invoked continuously while the camera is moving
   *
   * @param listener OnCameraIsChangingListener instance
   */
  public addOnCameraIsChangingListener(listener: OnCameraIsChangingListener): void {
    if (this.destroyed) {
      return;
    }
    if (this.cameraIsChangingWrappers.has(listener)) {
      return;
    }
    const wrapper: OnCameraIsChangingListener = () => {
      try {
        listener();
      } catch (error) {
        const message: string = error instanceof Error ? `${error.name}: ${error.message}` : `${error}`;
        logListenerError('OnCameraIsChangingListener', message);
      }
    };
    this.cameraIsChangingWrappers.set(listener, wrapper);
    this.nativeMapView.addOnCameraIsChangingListener(wrapper);
  }

  /**
   * Remove an on-camera-is-changing listener
   *
   * @param listener Listener to remove
   */
  public removeOnCameraIsChangingListener(listener: OnCameraIsChangingListener): void {
    if (this.destroyed) {
      return;
    }
    const wrapper = this.cameraIsChangingWrappers.get(listener);
    if (wrapper) {
      this.nativeMapView.removeOnCameraIsChangingListener(wrapper);
      this.cameraIsChangingWrappers.delete(listener);
    }
  }

  /**
   * Add an on-camera-did-change listener
   * Invoked after the camera finishes changing
   *
   * @param listener OnCameraDidChangeListener instance
   */
  public addOnCameraDidChangeListener(listener: OnCameraDidChangeListener): void {
    if (this.destroyed) {
      return;
    }
    if (this.cameraDidChangeWrappers.has(listener)) {
      return;
    }
    const wrapper: OnCameraDidChangeListener = (animated: boolean) => {
      try {
        listener(animated);
      } catch (error) {
        const message: string = error instanceof Error ? `${error.name}: ${error.message}` : `${error}`;
        logListenerError('OnCameraDidChangeListener', message);
      }
    };
    this.cameraDidChangeWrappers.set(listener, wrapper);
    this.nativeMapView.addOnCameraDidChangeListener(wrapper);
  }

  /**
   * Remove an on-camera-did-change listener
   *
   * @param listener Listener to remove
   */
  public removeOnCameraDidChangeListener(listener: OnCameraDidChangeListener): void {
    if (this.destroyed) {
      return;
    }
    const wrapper = this.cameraDidChangeWrappers.get(listener);
    if (wrapper) {
      this.nativeMapView.removeOnCameraDidChangeListener(wrapper);
      this.cameraDidChangeWrappers.delete(listener);
    }
  }

  /**
   * Add an on-camera-idle listener
   * Triggered when the camera stops moving (all animations and gestures complete)
   *
   * @param listener OnCameraIdleListener instance
   */
  public addOnCameraIdleListener(listener: OnCameraIdleListener): void {
    if (this.destroyed) {
      return;
    }

    // Register with the dispatcher
    this.cameraChangeDispatcher.addOnCameraIdleListener(listener);

    // Register with NAPI
    const callback = () => {
      this.cameraChangeDispatcher.notifyCameraIdle();
    };
    this.nativeMapView.addOnCameraIdleListener(callback);
  }

  /**
   * Remove an on-camera-idle listener
   *
   * @param listener Listener to remove
   */
  public removeOnCameraIdleListener(listener: OnCameraIdleListener): void {
    if (this.destroyed) {
      return;
    }
    this.cameraChangeDispatcher.removeOnCameraIdleListener(listener);
    // Note: NAPI callbacks cannot be removed individually—known limitation
  }

  /**
   * Add an on-camera-move-started listener
   * Triggered when the camera begins moving
   *
   * @param listener OnCameraMoveStartedListener instance
   */
  public addOnCameraMoveStartedListener(listener: OnCameraMoveStartedListener): void {
    if (this.destroyed) {
      return;
    }

    // Register with the dispatcher
    this.cameraChangeDispatcher.addOnCameraMoveStartedListener(listener);

    // Register with NAPI
    const callback = (reason: number) => {
      this.cameraChangeDispatcher.notifyCameraMoveStarted(reason as CameraMoveReason);
    };
    this.nativeMapView.addOnCameraMoveStartedListener(callback);
  }

  /**
   * Remove an on-camera-move-started listener
   *
   * @param listener Listener to remove
   */
  public removeOnCameraMoveStartedListener(listener: OnCameraMoveStartedListener): void {
    if (this.destroyed) {
      return;
    }
    this.cameraChangeDispatcher.removeOnCameraMoveStartedListener(listener);
  }

  /**
   * Add an on-camera-move listener
   * Fires repeatedly while the camera is moving
   *
   * @param listener OnCameraMoveListener instance
   */
  public addOnCameraMoveListener(listener: OnCameraMoveListener): void {
    if (this.destroyed) {
      return;
    }

    // Register with the dispatcher
    this.cameraChangeDispatcher.addOnCameraMoveListener(listener);

    // Register with NAPI
    const callback = () => {
      this.cameraChangeDispatcher.notifyCameraMove();
    };
    this.nativeMapView.addOnCameraMoveListener(callback);
  }

  /**
   * Remove an on-camera-move listener
   *
   * @param listener Listener to remove
   */
  public removeOnCameraMoveListener(listener: OnCameraMoveListener): void {
    if (this.destroyed) {
      return;
    }
    this.cameraChangeDispatcher.removeOnCameraMoveListener(listener);
  }

  /**
   * Add an on-camera-move-canceled listener
   * Triggered when a camera animation is interrupted or canceled
   *
   * @param listener OnCameraMoveCanceledListener instance
   */
  public addOnCameraMoveCanceledListener(listener: OnCameraMoveCanceledListener): void {
    if (this.destroyed) {
      return;
    }

    // Register with the dispatcher
    this.cameraChangeDispatcher.addOnCameraMoveCanceledListener(listener);

    // Register with NAPI
    const callback = () => {
      this.cameraChangeDispatcher.notifyCameraMoveCanceled();
    };
    this.nativeMapView.addOnCameraMoveCanceledListener(callback);
  }

  /**
   * Remove an on-camera-move-canceled listener
   *
   * @param listener Listener to remove
   */
  public removeOnCameraMoveCanceledListener(listener: OnCameraMoveCanceledListener): void {
    if (this.destroyed) {
      return;
    }
    this.cameraChangeDispatcher.removeOnCameraMoveCanceledListener(listener);
  }

  /**
   * Internal: notify that the camera started moving (gesture initiated)
   * Called by the gesture handler
   * @internal
   */
  public _notifyCameraMoveStartedByGesture(): void {
    if (this.destroyed) {
      return;
    }
    // Mirrors Android: update UI elements (InfoWindow, etc.) while the camera moves
    this.onUpdateRegionChange();
    this.cameraChangeDispatcher.notifyCameraMoveStarted(CameraMoveReason.GESTURE);
  }

  /**
   * Internal: notify that the camera is moving
   * Called by the gesture handler
   * @internal
   */
  public _notifyCameraMove(): void {
    if (this.destroyed) {
      console.warn('[MapLibreMap] _notifyCameraMove() called but map is destroyed, skipping');
      return;
    }
    // Throttle updates to ~60fps to avoid overwhelming the UI thread during gestures
    const now = Date.now();
    if (now - this.lastCameraMoveTime < MapLibreMap.CAMERA_MOVE_THROTTLE_MS) {
      return;
    }
    this.lastCameraMoveTime = now;
    // Mirrors Android: update UI elements (InfoWindow, etc.) while the camera moves
    this.onUpdateRegionChange();
    this.cameraChangeDispatcher.notifyCameraMove();
  }

  /**
   * Internal: notify that the camera became idle
   * Called by the gesture handler
   * @internal
   */
  public _notifyCameraIdle(): void {
    if (this.destroyed) {
      return;
    }
    // Mirrors Android: update UI elements (InfoWindow, etc.) once the camera stops
    this.onUpdateRegionChange();
    this.cameraChangeDispatcher.notifyCameraIdle();
  }

// ========== Map loading listener management ==========

  /**
   * Add a will-start-loading-map listener
   * Triggered when the map starts loading (mirrors Android MapView.OnWillStartLoadingMapListener)
   */
  public addOnWillStartLoadingMapListener(listener: OnWillStartLoadingMapListener): void {
    if (this.destroyed) {
      return;
    }
    if (this.willStartLoadingMapWrappers.has(listener)) {
      return;
    }
    const wrapper: OnWillStartLoadingMapListener = () => {
      try {
        listener();
      } catch (error) {
        const message: string = error instanceof Error ? `${error.name}: ${error.message}` : `${error}`;
        logListenerError('OnWillStartLoadingMapListener', message);
      }
    };
    this.willStartLoadingMapWrappers.set(listener, wrapper);
    this.nativeMapView.addOnWillStartLoadingMapListener(wrapper);
  }

  /**
   * Remove a will-start-loading-map listener
   */
  public removeOnWillStartLoadingMapListener(listener: OnWillStartLoadingMapListener): void {
    if (this.destroyed) {
      return;
    }
    const wrapper = this.willStartLoadingMapWrappers.get(listener);
    if (wrapper) {
      this.nativeMapView.removeOnWillStartLoadingMapListener(wrapper);
      this.willStartLoadingMapWrappers.delete(listener);
    }
  }

  /**
   * Add a did-finish-loading-map listener
   * Triggered when the map finishes loading (style and tiles loaded)
   */
  public addOnDidFinishLoadingMapListener(listener: OnDidFinishLoadingMapListener): void {
    if (this.destroyed) {
      return;
    }
    if (this.didFinishLoadingMapWrappers.has(listener)) {
      return;
    }
    const wrapper: OnDidFinishLoadingMapListener = () => {
      try {
        listener();
      } catch (error) {
        const message: string = error instanceof Error ? `${error.name}: ${error.message}` : `${error}`;
        logListenerError('OnDidFinishLoadingMapListener', message);
      }
    };
    this.didFinishLoadingMapWrappers.set(listener, wrapper);
    this.nativeMapView.addOnDidFinishLoadingMapListener(wrapper);
  }

  /**
   * Remove a did-finish-loading-map listener
   */
  public removeOnDidFinishLoadingMapListener(listener: OnDidFinishLoadingMapListener): void {
    if (this.destroyed) {
      return;
    }
    const wrapper = this.didFinishLoadingMapWrappers.get(listener);
    if (wrapper) {
      this.nativeMapView.removeOnDidFinishLoadingMapListener(wrapper);
      this.didFinishLoadingMapWrappers.delete(listener);
    }
  }

  /**
   * Add a did-fail-loading-map listener
   * Triggered when the map fails to load (network issues, style errors, etc.)
   */
  public addOnDidFailLoadingMapListener(listener: OnDidFailLoadingMapListener): void {
    if (this.destroyed) {
      return;
    }
    if (this.didFailLoadingMapWrappers.has(listener)) {
      return;
    }
    const wrapper: OnDidFailLoadingMapListener = (errorMessage: string) => {
      try {
        listener(errorMessage);
      } catch (error) {
        const message: string = error instanceof Error ? `${error.name}: ${error.message}` : `${error}`;
        logListenerError('OnDidFailLoadingMapListener', message);
      }
    };
    this.didFailLoadingMapWrappers.set(listener, wrapper);
    this.nativeMapView.addOnDidFailLoadingMapListener(wrapper);
  }

  /**
   * Remove a did-fail-loading-map listener
   */
  public removeOnDidFailLoadingMapListener(listener: OnDidFailLoadingMapListener): void {
    if (this.destroyed) {
      return;
    }
    const wrapper = this.didFailLoadingMapWrappers.get(listener);
    if (wrapper) {
      this.nativeMapView.removeOnDidFailLoadingMapListener(wrapper);
      this.didFailLoadingMapWrappers.delete(listener);
    }
  }

// ========== Rendering lifecycle listeners ==========

  /**
   * Add a will-start-rendering-frame listener
   * Invoked before each frame begins rendering
   */
  public addOnWillStartRenderingFrameListener(listener: OnWillStartRenderingFrameListener): void {
    if (this.destroyed) {
      return;
    }
    if (this.willStartRenderingFrameWrappers.has(listener)) {
      return;
    }
    const wrapper: OnWillStartRenderingFrameListener = () => {
      try {
        listener();
      } catch (error) {
        const message: string = error instanceof Error ? `${error.name}: ${error.message}` : `${error}`;
        logListenerError('OnWillStartRenderingFrameListener', message);
      }
    };
    this.willStartRenderingFrameWrappers.set(listener, wrapper);
    this.nativeMapView.addOnWillStartRenderingFrameListener(wrapper);
  }

  /**
   * Remove a will-start-rendering-frame listener
   */
  public removeOnWillStartRenderingFrameListener(listener: OnWillStartRenderingFrameListener): void {
    if (this.destroyed) {
      return;
    }
    const wrapper = this.willStartRenderingFrameWrappers.get(listener);
    if (wrapper) {
      this.nativeMapView.removeOnWillStartRenderingFrameListener(wrapper);
      this.willStartRenderingFrameWrappers.delete(listener);
    }
  }

  /**
   * Add a did-finish-rendering-frame listener (basic version)
   */
  public addOnDidFinishRenderingFrameListener(listener: OnDidFinishRenderingFrameListener): void {
    if (this.destroyed) {
      return;
    }
    if (this.didFinishRenderingFrameWrappers.has(listener)) {
      return;
    }
    const wrapper: OnDidFinishRenderingFrameListener = (
      fully: boolean,
      frameEncodingTime: number,
      frameRenderingTime: number
    ) => {
      try {
        listener(fully, frameEncodingTime, frameRenderingTime);
      } catch (error) {
        const message: string = error instanceof Error ? `${error.name}: ${error.message}` : `${error}`;
        logListenerError('OnDidFinishRenderingFrameListener', message);
      }
    };
    this.didFinishRenderingFrameWrappers.set(listener, wrapper);
    this.nativeMapView.addOnDidFinishRenderingFrameListener(wrapper);
  }

  /**
   * Remove a did-finish-rendering-frame listener (basic version)
   */
  public removeOnDidFinishRenderingFrameListener(listener: OnDidFinishRenderingFrameListener): void {
    if (this.destroyed) {
      return;
    }
    const wrapper = this.didFinishRenderingFrameWrappers.get(listener);
    if (wrapper) {
      this.nativeMapView.removeOnDidFinishRenderingFrameListener(wrapper);
      this.didFinishRenderingFrameWrappers.delete(listener);
    }
  }

  /**
   * Add a did-finish-rendering-frame listener (with rendering stats)
   */
  public addOnDidFinishRenderingFrameWithStatsListener(
    listener: OnDidFinishRenderingFrameWithStatsListener
  ): void {
    if (this.destroyed) {
      return;
    }
    if (this.didFinishRenderingFrameWithStatsWrappers.has(listener)) {
      return;
    }
    const wrapper: OnDidFinishRenderingFrameWithStatsListener = (
      fully: boolean,
      stats: RenderingStats
    ) => {
      try {
        listener(fully, stats);
      } catch (error) {
        const message: string = error instanceof Error ? `${error.name}: ${error.message}` : `${error}`;
        logListenerError('OnDidFinishRenderingFrameWithStatsListener', message);
      }
    };
    this.didFinishRenderingFrameWithStatsWrappers.set(listener, wrapper);
    this.nativeMapView.addOnDidFinishRenderingFrameWithStatsListener(wrapper);
  }

  /**
   * Remove a did-finish-rendering-frame listener (with rendering stats)
   */
  public removeOnDidFinishRenderingFrameWithStatsListener(
    listener: OnDidFinishRenderingFrameWithStatsListener
  ): void {
    if (this.destroyed) {
      return;
    }
    const wrapper = this.didFinishRenderingFrameWithStatsWrappers.get(listener);
    if (wrapper) {
      this.nativeMapView.removeOnDidFinishRenderingFrameWithStatsListener(wrapper);
      this.didFinishRenderingFrameWithStatsWrappers.delete(listener);
    }
  }

  /**
   * Add a will-start-rendering-map listener
   */
  public addOnWillStartRenderingMapListener(listener: OnWillStartRenderingMapListener): void {
    if (this.destroyed) {
      return;
    }
    if (this.willStartRenderingMapWrappers.has(listener)) {
      return;
    }
    const wrapper: OnWillStartRenderingMapListener = () => {
      try {
        listener();
      } catch (error) {
        const message: string = error instanceof Error ? `${error.name}: ${error.message}` : `${error}`;
        logListenerError('OnWillStartRenderingMapListener', message);
      }
    };
    this.willStartRenderingMapWrappers.set(listener, wrapper);
    this.nativeMapView.addOnWillStartRenderingMapListener(wrapper);
  }

  /**
   * Remove a will-start-rendering-map listener
   */
  public removeOnWillStartRenderingMapListener(listener: OnWillStartRenderingMapListener): void {
    if (this.destroyed) {
      return;
    }
    const wrapper = this.willStartRenderingMapWrappers.get(listener);
    if (wrapper) {
      this.nativeMapView.removeOnWillStartRenderingMapListener(wrapper);
      this.willStartRenderingMapWrappers.delete(listener);
    }
  }

  /**
   * Add a did-finish-rendering-map listener
   */
  public addOnDidFinishRenderingMapListener(listener: OnDidFinishRenderingMapListener): void {
    if (this.destroyed) {
      return;
    }
    if (this.didFinishRenderingMapWrappers.has(listener)) {
      return;
    }
    const wrapper: OnDidFinishRenderingMapListener = (fully: boolean) => {
      try {
        listener(fully);
      } catch (error) {
        const message: string = error instanceof Error ? `${error.name}: ${error.message}` : `${error}`;
        logListenerError('OnDidFinishRenderingMapListener', message);
      }
    };
    this.didFinishRenderingMapWrappers.set(listener, wrapper);
    this.nativeMapView.addOnDidFinishRenderingMapListener(wrapper);
  }

  /**
   * Remove a did-finish-rendering-map listener
   */
  public removeOnDidFinishRenderingMapListener(listener: OnDidFinishRenderingMapListener): void {
    if (this.destroyed) {
      return;
    }
    const wrapper = this.didFinishRenderingMapWrappers.get(listener);
    if (wrapper) {
      this.nativeMapView.removeOnDidFinishRenderingMapListener(wrapper);
      this.didFinishRenderingMapWrappers.delete(listener);
    }
  }

// ========== Style lifecycle listeners ==========

  /**
   * Add a did-finish-loading-style listener (without Style object)
   */
  public addOnDidFinishLoadingStyleListener(listener: OnDidFinishLoadingStyleListener): void {
    if (this.destroyed) {
      return;
    }
    if (this.didFinishLoadingStyleWrappers.has(listener)) {
      return;
    }
    const wrapper: OnDidFinishLoadingStyleListener = () => {
      try {
        listener();
      } catch (error) {
        const message: string = error instanceof Error ? `${error.name}: ${error.message}` : `${error}`;
        logListenerError('OnDidFinishLoadingStyleListener', message);
      }
    };
    this.didFinishLoadingStyleWrappers.set(listener, wrapper);
    this.nativeMapView.addOnDidFinishLoadingStyleListener(wrapper);
  }

  /**
   * Remove a did-finish-loading-style listener
   */
  public removeOnDidFinishLoadingStyleListener(listener: OnDidFinishLoadingStyleListener): void {
    if (this.destroyed) {
      return;
    }
    const wrapper = this.didFinishLoadingStyleWrappers.get(listener);
    if (wrapper) {
      this.nativeMapView.removeOnDidFinishLoadingStyleListener(wrapper);
      this.didFinishLoadingStyleWrappers.delete(listener);
    }
  }

  /**
   * Add a can-remove-unused-style-image listener
   * Used to control when cached style images can be released
   */
  public addOnCanRemoveUnusedStyleImageListener(listener: OnCanRemoveUnusedStyleImageListener): void {
    if (this.destroyed) {
      return;
    }
    if (this.canRemoveUnusedStyleImageWrappers.has(listener)) {
      return;
    }
    const wrapper: OnCanRemoveUnusedStyleImageListener = (id: string) => {
      try {
        return listener(id);
      } catch (error) {
        const message: string = error instanceof Error ? `${error.name}: ${error.message}` : `${error}`;
        logListenerError('OnCanRemoveUnusedStyleImageListener', message);
        return false;
      }
    };
    this.canRemoveUnusedStyleImageWrappers.set(listener, wrapper);
    this.nativeMapView.addOnCanRemoveUnusedStyleImageListener(wrapper);
  }

  /**
   * Remove a can-remove-unused-style-image listener
   */
  public removeOnCanRemoveUnusedStyleImageListener(listener: OnCanRemoveUnusedStyleImageListener): void {
    if (this.destroyed) {
      return;
    }
    const wrapper = this.canRemoveUnusedStyleImageWrappers.get(listener);
    if (wrapper) {
      this.nativeMapView.removeOnCanRemoveUnusedStyleImageListener(wrapper);
      this.canRemoveUnusedStyleImageWrappers.delete(listener);
    }
  }

// ========== Map idle & data source listeners ==========

  /**
   * Add a did-become-idle listener
   * Triggered when the map becomes completely idle
   */
  public addOnDidBecomeIdleListener(listener: OnDidBecomeIdleListener): void {
    if (this.destroyed) {
      return;
    }
    if (this.didBecomeIdleWrappers.has(listener)) {
      return;
    }
    const wrapper: OnDidBecomeIdleListener = () => {
      try {
        listener();
      } catch (error) {
        const message: string = error instanceof Error ? `${error.name}: ${error.message}` : `${error}`;
        logListenerError('OnDidBecomeIdleListener', message);
      }
    };
    this.didBecomeIdleWrappers.set(listener, wrapper);
    this.nativeMapView.addOnDidBecomeIdleListener(wrapper);
  }

  /**
   * Remove a did-become-idle listener
   */
  public removeOnDidBecomeIdleListener(listener: OnDidBecomeIdleListener): void {
    if (this.destroyed) {
      return;
    }
    const wrapper = this.didBecomeIdleWrappers.get(listener);
    if (wrapper) {
      this.nativeMapView.removeOnDidBecomeIdleListener(wrapper);
      this.didBecomeIdleWrappers.delete(listener);
    }
  }

  /**
   * Add a source-changed listener
   * Invoked when the content of a source changes
   */
  public addOnSourceChangedListener(listener: OnSourceChangedListener): void {
    if (this.destroyed) {
      return;
    }
    if (this.sourceChangedWrappers.has(listener)) {
      return;
    }
    const wrapper: OnSourceChangedListener = (id: string) => {
      try {
        listener(id);
      } catch (error) {
        const message: string = error instanceof Error ? `${error.name}: ${error.message}` : `${error}`;
        logListenerError('OnSourceChangedListener', message);
      }
    };
    this.sourceChangedWrappers.set(listener, wrapper);
    this.nativeMapView.addOnSourceChangedListener(wrapper);
  }

  /**
   * Remove a source-changed listener
   */
  public removeOnSourceChangedListener(listener: OnSourceChangedListener): void {
    if (this.destroyed) {
      return;
    }
    const wrapper = this.sourceChangedWrappers.get(listener);
    if (wrapper) {
      this.nativeMapView.removeOnSourceChangedListener(wrapper);
      this.sourceChangedWrappers.delete(listener);
    }
  }

// ========== Map click listener management ==========

  private mapClickListeners: OnMapClickListener[] = [];
  private mapLongClickListeners: OnMapLongClickListener[] = [];

  /**
   * Add a map click listener
   * Triggered when the user taps the map (mirrors Android addOnMapClickListener)
   *
   * @param listener OnMapClickListener instance
   */
  public addOnMapClickListener(listener: OnMapClickListener): void {
    if (this.destroyed) {
      return;
    }
    if (!this.mapClickListeners.includes(listener)) {
      this.mapClickListeners.push(listener);
    }
  }

  /**
   * Remove a map click listener
   *
   * @param listener Listener to remove
   */
  public removeOnMapClickListener(listener: OnMapClickListener): void {
    if (this.destroyed) {
      return;
    }
    const index = this.mapClickListeners.indexOf(listener);
    if (index > -1) {
      this.mapClickListeners.splice(index, 1);
    }
  }

  /**
   * Add a map long-click listener
   * Triggered when the user long-presses the map (mirrors Android addOnMapLongClickListener)
   *
   * @param listener OnMapLongClickListener instance
   */
  public addOnMapLongClickListener(listener: OnMapLongClickListener): void {
    if (this.destroyed) {
      return;
    }
    if (!this.mapLongClickListeners.includes(listener)) {
      this.mapLongClickListeners.push(listener);
    }
  }

  /**
   * Remove a map long-click listener
   *
   * @param listener Listener to remove
   */
  public removeOnMapLongClickListener(listener: OnMapLongClickListener): void {
    if (this.destroyed) {
      return;
    }
    const index = this.mapLongClickListeners.indexOf(listener);
    if (index > -1) {
      this.mapLongClickListeners.splice(index, 1);
    }
  }

  // Touch event listener lists (used for marker dragging and related features)
  private touchMoveListeners: OnTouchMoveListener[] = [];
  private touchUpListeners: OnTouchUpListener[] = [];

  /**
   * Add a touch-move listener
   * Used for features that require continuous touch tracking such as marker dragging
   * Mirrors Android AndroidGesturesManager.setMoveGestureListener
   *
   * Note: touch events are dispatched by NativeMapView's gesture system; this only registers the callback
   *
   * @param listener OnTouchMoveListener instance
   */
  public addOnTouchMoveListener(listener: OnTouchMoveListener): void {
    if (this.destroyed) {
      return;
    }
    if (!this.touchMoveListeners.includes(listener)) {
      this.touchMoveListeners.push(listener);
    }
  }

  /**
   * Remove a touch-move listener
   *
   * @param listener Listener to remove
   */
  public removeOnTouchMoveListener(listener: OnTouchMoveListener): void {
    if (this.destroyed) {
      return;
    }
    const index = this.touchMoveListeners.indexOf(listener);
    if (index > -1) {
      this.touchMoveListeners.splice(index, 1);
    }
  }

  /**
   * Add a touch-up listener
   * Detects touch end events for flows such as completing marker drag
   * Mirrors iOS UIPanGestureRecognizer UIGestureRecognizerStateEnded
   *
   * @param listener OnTouchUpListener instance
   */
  public addOnTouchUpListener(listener: OnTouchUpListener): void {
    if (this.destroyed) {
      return;
    }
    if (!this.touchUpListeners.includes(listener)) {
      this.touchUpListeners.push(listener);
    }
  }

  /**
   * Remove a touch-up listener
   *
   * @param listener Listener to remove
   */
  public removeOnTouchUpListener(listener: OnTouchUpListener): void {
    if (this.destroyed) {
      return;
    }
    const index = this.touchUpListeners.indexOf(listener);
    if (index > -1) {
      this.touchUpListeners.splice(index, 1);
    }
  }

  /**
   * Remove all listeners
   *
   * Clears every map event listener in bulk, including:
   * - Style listeners
   * - Camera listeners
   * - Map click/long-click listeners
   * - Touch event listeners
   * - Marker-related listeners
   *
   * Typically invoked during page teardown to avoid memory leaks
   *
   * @example
   * aboutToDisappear() {
   *   if (this.mapController) {
   *     this.mapController.removeAllListeners();
   *     this.mapController.destroy();
   *   }
   * }
   */
  public removeAllListeners(): void {
    if (this.destroyed) {
      return;
    }
    
    // Clear style listeners
    this.styleLoadedListeners = [];
    this.styleLoadErrorListeners = [];
    this.styleImageMissingListener = undefined;
    
    // Clear camera listeners via the dispatcher
    this.cameraChangeDispatcher.clearAllListeners();
    
    // Clear map interaction listeners
    this.mapClickListeners = [];
    this.mapLongClickListeners = [];
    this.touchMoveListeners = [];
    this.touchUpListeners = [];
    
    // Clear marker-related listeners
    this.markerManager.clearAllListeners();
    
    console.info('[MapLibreMap] All listeners removed');
  }

  /**
   * Internal: fire a touch-move event
   * Called by NativeMapView or the gesture system
   *
   * @param x Touch X coordinate
   * @param y Touch Y coordinate
   * @returns true if the event is consumed
   */
  public fireTouchMoveEvent(x: number, y: number): boolean {
    if (this.destroyed) {
      return false;
    }

    for (const listener of this.touchMoveListeners) {
      try {
        if (listener.onTouchMove(x, y)) {
          return true; // Event consumed
        }
      } catch (error) {
        console.error(`MapLibreMap: Error in touch move listener: ${error}`);
      }
    }
    return false;
  }

  /**
   * Internal: fire a touch-up event
   * Called by NativeMapView or the gesture system
   *
   * @param x Touch X coordinate
   * @param y Touch Y coordinate
   * @returns true if the event is consumed
   */
  public fireTouchUpEvent(x: number, y: number): boolean {
    if (this.destroyed) {
      return false;
    }

    for (const listener of this.touchUpListeners) {
      try {
        if (listener.onTouchUp(x, y)) {
          return true; // Event consumed
        }
      } catch (error) {
        console.error(`MapLibreMap: Error in touch up listener: ${error}`);
      }
    }
    return false;
  }

  /**
   * Internal: trigger a map click event
   * @param x Click X coordinate
   * @param y Click Y coordinate
   * @returns Whether any listener consumed the event
   * @internal
   */
  public _notifyMapClick(x: number, y: number): boolean {
    if (this.destroyed) {
      return false;
    }

    console.info(`[MapLibreMap] _notifyMapClick at (${x}, ${y}), listeners count: ${this.mapClickListeners.length}`);

    // Traverse every map click listener (including those from MarkerManager)
    for (const listener of this.mapClickListeners) {
      try {
        console.info(`[MapLibreMap] Calling map click listener...`);
        if (listener.onMapClick(x, y)) {
          console.info(`[MapLibreMap] Event consumed by listener`);
          return true; // Event consumed
        }
      } catch (error) {
        console.error(`MapLibreMap: Error in map click listener: ${error}`);
      }
    }
    console.info(`[MapLibreMap] No listener consumed the event`);
    return false;
  }

  /**
   * Internal: trigger a map long-click event
   * @param x Long-press X coordinate
   * @param y Long-press Y coordinate
   * @returns Whether any listener consumed the event
   * @internal
   */
  public _notifyMapLongClick(x: number, y: number): boolean {
    if (this.destroyed) {
      return false;
    }
    for (const listener of this.mapLongClickListeners) {
      try {
        if (listener.onMapLongClick(x, y)) {
          return true; // Event consumed
        }
      } catch (error) {
        console.error(`MapLibreMap: Error in map long click listener: ${error}`);
      }
    }
    return false;
  }

  /**
   * Attempt to start dragging a marker (invoked when a pan gesture begins)
   *
   * @param x Touch X coordinate (logical pixels)
   * @param y Touch Y coordinate (logical pixels)
   * @returns true if marker drag initiated
   * @internal
   */
  public tryStartMarkerDrag(x: number, y: number): boolean {
    if (this.destroyed) {
      return false;
    }

    // Delegate to MarkerManager to initiate the drag
    if (this.markerManager) {
      return this.markerManager.tryStartDrag(x, y);
    }

    return false;
  }

// ========== AnnotationView management ==========

  /**
   * Get the AnnotationViewManager instance
   * @returns AnnotationViewManager
   */
  public getAnnotationViewManager(): AnnotationViewManager {
    return this.annotationViewManager;
  }

  /**
   * Get the ViewAnnotationManager
   * @returns ViewAnnotationManager
   */
  public getViewAnnotationManager(): ViewAnnotationManager {
    return this.viewAnnotationManager;
  }

  /**
   * Set the ViewAnnotation render callback to sync the latest render states with the UI
   * @param callback Callback receiving an array of ViewAnnotationRenderState
   */
  public setViewAnnotationRenderCallback(callback: ((states: ViewAnnotationRenderState[]) => void) | null): void {
    const hasCallback = callback !== null;
    console.info(`[MapLibreMap] setViewAnnotationRenderCallback: ${hasCallback ? 'register' : 'clear'} callback`);
    this.viewAnnotationRenderCallback = callback ?? undefined;
    if (callback) {
      const states = this.viewAnnotationManager.getRenderStates();
      console.info(`[MapLibreMap] setViewAnnotationRenderCallback: invoking immediately with ${states.length} states`);
      callback(states);
    }
  }

  /**
   * Set the AnnotationViewDelegate
   * Customizes creation and event handling for AnnotationViews
   *
   * Mirrors iOS MLNMapView.delegate
   *
   * After the delegate is set, the map invokes viewForAnnotation for every marker to build custom views.
   * Existing markers will rebuild their views immediately.
   *
   * @param delegate AnnotationViewDelegate instance; pass null to clear
   *
   * @example
   * ```typescript
   * const delegate: AnnotationViewDelegate = {
   *   viewForAnnotation: (marker: Marker) => {
   *     if (marker.getSnippet() === 'restaurant') {
   *       return {
   *         reuseIdentifier: 'restaurant-pin',
   *         contentBuilder: () => {
   *           Column() {
   *             Image($r('app.media.restaurant_icon'))
   *               .width(32).height(32)
   *           }
   *         },
   *         scalesWithViewingDistance: true
   *       };
   *     }
   *     return null; // Use default icon
   *   },
   *
   *   didSelectAnnotationView: (marker: Marker) => {
   *     console.log('Selected:', marker.getTitle());
   *   }
   * };
   *
   * map.setAnnotationViewDelegate(delegate);
   * ```
   */
  public setAnnotationViewDelegate(delegate: AnnotationViewDelegate | null): void {
    if (this.destroyed) {
      return;
    }
    
    // Cache the delegate
    this.annotationViewDelegate = delegate;

    // Forward the delegate to AnnotationViewManager
    this.annotationViewManager.setDelegate(delegate);

    // Note: AnnotationViewManager.setDelegate automatically calls recreateAllViews(),
    // so existing markers will rebuild their views
  }

  /**
   * Get the AnnotationViewDelegate
   * @returns AnnotationViewDelegate or null
   */
  public getAnnotationViewDelegate(): AnnotationViewDelegate | null {
    if (this.destroyed) {
      return null;
    }
    return this.annotationViewDelegate;
  }

  /**
   * Register an AnnotationView for a marker
   *
   * @param marker Marker instance
   * @param config AnnotationViewConfig
   */
  public registerAnnotationView(marker: Marker, config: AnnotationViewConfig): void {
    if (this.destroyed) {
      return;
    }

    // Create or update the view via AnnotationViewManager
    this.annotationViewManager.createOrUpdateView(marker);

  }

  /**
   * Unregister an AnnotationView
   *
   * @param marker Marker instance
   */
  public unregisterAnnotationView(marker: Marker): void {
    if (this.destroyed) {
      return;
    }

    this.annotationViewManager.removeView(marker);

  }

  /**
   * Select an annotation
   *
   * @param marker Marker instance
   * @param animated Whether to animate
   */
  public selectAnnotation(marker: Marker, animated: boolean = true): void {
    if (this.destroyed) {
      return;
    }

    this.annotationViewManager.selectAnnotation(marker, animated);

    // Notify delegate callback
    if (this.annotationViewDelegate?.didSelectAnnotationView) {
      this.annotationViewDelegate.didSelectAnnotationView(marker);
    }
  }

  /**
   * Deselect an annotation
   *
   * @param marker Marker instance
   * @param animated Whether to animate
   */
  public deselectAnnotation(marker: Marker, animated: boolean = true): void {
    if (this.destroyed) {
      return;
    }

    this.annotationViewManager.deselectAnnotation(marker, animated);

    // Notify delegate callback
    if (this.annotationViewDelegate?.didDeselectAnnotationView) {
      this.annotationViewDelegate.didDeselectAnnotationView(marker);
    }
  }

  /**
   * Deselect all annotations
   *
   * @param animated Whether to animate
   */
  public deselectAllAnnotations(animated: boolean = true): void {
    if (this.destroyed) {
      return;
    }

    const selected = this.annotationViewManager.getSelectedAnnotations();
    selected.forEach(marker => {
      this.deselectAnnotation(marker, animated);
    });
  }

  /**
   * Get selected annotations
   * @returns Array of selected markers
   */
  public getSelectedAnnotations(): Marker[] {
    if (this.destroyed) {
      return [];
    }
    return this.annotationViewManager.getSelectedAnnotations();
  }

  /**
   * Dequeue an AnnotationView from the reuse pool
   *
   * @param identifier Reuse identifier
   * @returns AnnotationViewData or null
   */
  public dequeueReusableAnnotationView(identifier: string): AnnotationViewData | null {
    if (this.destroyed) {
      return null;
    }
    return this.annotationViewManager.dequeueReusableView(identifier);
  }

  /**
   * Check whether an annotation is selected
   *
   * @param marker Marker instance
   * @returns true if selected
   */
  public isAnnotationSelected(marker: Marker): boolean {
    if (this.destroyed) {
      return false;
    }
    return this.annotationViewManager.isAnnotationSelected(marker);
  }

  /**
   * Get all visible annotations
   *
   * Mirrors iOS MLNMapView visibleAnnotations
   *
   * @returns Array of markers currently visible on screen
   */
  public getVisibleAnnotations(): Marker[] {
    if (this.destroyed) {
      return [];
    }

    // Fetch all markers with custom views
    const allViews = this.annotationViewManager.getVisibleViews();
    // 🔒 Fix ObservedObject error: filter out entries where marker is null
    return allViews
      .filter(viewData => viewData.marker !== null)
      .map(viewData => viewData.marker!);
  }

  /**
   * Update positions for every AnnotationView
   *
   * Automatically invoked when the camera changes to keep custom view coordinates in sync
   *
   * @param cameraChanged Whether camera parameters (bearing/pitch) changed
   * @private
   */
  private updateAnnotationViewPositions(cameraChanged: boolean = false): void {
    if (this.destroyed) {
      return;
    }
    this.annotationViewManager.batchUpdatePositions(cameraChanged);
    this.viewAnnotationManager.refreshRenderStates();
  }

// ==================== Feature queries ====================

  /**
   * Query rendered features at a point
   *
   * @param x X coordinate in logical pixels (converted to physical pixels internally)
   * @param y Y coordinate in logical pixels (converted to physical pixels internally)
   * @param layerIds Optional array of layer IDs to filter the results
   * @param filter Optional filter expression
   * @returns Array of features
   *
   * @note Coordinate system:
   * - Inputs are logical pixels (same as touch coordinates)
   * - Internally multiplied by pixelRatio to convert to physical pixels for the renderer
   * - Ensures accurate results across different DPI devices
   *
   * @example
   * ```typescript
   * // Query all features at logical pixel (100, 200)
   * const features = map.queryRenderedFeaturesForPoint(100, 200);
   *
   * // Only query specific layers
   * const features = map.queryRenderedFeaturesForPoint(100, 200, ['poi-layer', 'building-layer']);
   *
   * // Query with a filter
   * const features = map.queryRenderedFeaturesForPoint(100, 200, ['poi-layer'], ['==', ['get', 'type'], 'restaurant']);
   * ```
   */
  public queryRenderedFeaturesForPoint(
    x: number,
    y: number,
    layerIds?: string[],
    filter?: NapiExpressionLiteral
  ): IFeature[] {
    if (this.destroyed) {
      console.warn('MapLibreMap', 'queryRenderedFeaturesForPoint: Map is destroyed');
      return [];
    }

    try {
      // DPI conversion: logical pixels -> physical pixels
      const pixelRatio = this.nativeMapView.getPixelRatio();
      const screenX = x * pixelRatio;
      const screenY = y * pixelRatio;

      const features = this.nativeMapView.queryRenderedFeaturesForPoint(screenX, screenY, layerIds, filter);
      return features as IFeature[];
    } catch (error) {
      console.error('MapLibreMap', `queryRenderedFeaturesForPoint failed: ${error.message}`);
      return [];
    }
  }

  /**
   * Query rendered features within a rectangle (physical pixel variant)
   *
   * **Note**: Accepts **physical pixel** coordinates and passes them directly to the renderer without DPI conversion.
   * Useful for internal map calculations and scenarios requiring exact physical pixel control.
   *
   * @param left Left boundary in physical pixels
   * @param top Top boundary in physical pixels
   * @param right Right boundary in physical pixels
   * @param bottom Bottom boundary in physical pixels
   * @param layerIds Optional array of layer IDs to filter the results
   * @param filter Optional filter expression
   * @returns Array of IFeature
   *
   * @example
   * ```typescript
   * // Internal calculations using physical pixels
   * const pixelRatio = map.getNativeMapView().getPixelRatio();
   * const physicalLeft = logicalLeft * pixelRatio;
   * const features = map.queryRenderedFeaturesForBoxPhysical(
   *   physicalLeft, physicalTop, physicalRight, physicalBottom
   * );
   * ```
   */
  public queryRenderedFeaturesForBoxPhysical(
    left: number,
    top: number,
    right: number,
    bottom: number,
    layerIds?: string[],
    filter?: NapiExpressionLiteral
  ): IFeature[] {
    if (this.destroyed) {
      console.warn('MapLibreMap', 'queryRenderedFeaturesForBoxPhysical: Map is destroyed');
      return [];
    }

    try {
      const features = this.nativeMapView.queryRenderedFeaturesForBox(
        left, top, right, bottom, layerIds, filter
      );
      return features as IFeature[];
    } catch (error) {
      console.error('MapLibreMap', `queryRenderedFeaturesForBoxPhysical failed: ${error.message}`);
      return [];
    }
  }

  /**
   * Query rendered features within a rectangle (logical pixel variant)
   *
   * **Note**: Accepts **logical pixel** coordinates (ArkUI standard) and converts them to physical pixels.
   * Intended for ArkUI component interactions, touch handling, and similar use cases.
   *
   * @param left Left boundary in logical pixels (converted to physical pixels)
   * @param top Top boundary in logical pixels (converted to physical pixels)
   * @param right Right boundary in logical pixels (converted to physical pixels)
   * @param bottom Bottom boundary in logical pixels (converted to physical pixels)
   * @param layerIds Optional array of layer IDs to filter the results
   * @param filter Optional filter expression
   * @returns Array of IFeature
   *
   * @note Coordinate system:
   * - Inputs are logical pixels (consistent with touch events)
   * - Internally multiplied by pixelRatio to convert to physical pixels for the renderer
   * - Ensures DPI accuracy across devices
   * - Keeps coordinate handling consistent with methods like handleMapClick
   *
   * @example
   * ```typescript
   * // Query all features in a rectangle (logical coordinates)
   * const features = map.queryRenderedFeaturesForBox(100, 100, 300, 300);
   *
   * // Restrict to specific layers
   * const features = map.queryRenderedFeaturesForBox(
   *   100, 100, 300, 300,
   *   ['poi-layer', 'building-layer']
   * );
   *
   * // Query with a filter
   * const features = map.queryRenderedFeaturesForBox(
   *   100, 100, 300, 300,
   *   ['poi-layer'],
   *   ['==', ['get', 'type'], 'restaurant']
   * );
   * ```
   */
  public queryRenderedFeaturesForBox(
    left: number,
    top: number,
    right: number,
    bottom: number,
    layerIds?: string[],
    filter?: NapiExpressionLiteral
  ): IFeature[] {
    if (this.destroyed) {
      console.warn('MapLibreMap', 'queryRenderedFeaturesForBox: Map is destroyed');
      return [];
    }

    try {
      // DPI conversion: logical pixels -> physical pixels
      const pixelRatio = this.nativeMapView.getPixelRatio();
      const physicalLeft = left * pixelRatio;
      const physicalTop = top * pixelRatio;
      const physicalRight = right * pixelRatio;
      const physicalBottom = bottom * pixelRatio;

      return this.queryRenderedFeaturesForBoxPhysical(
        physicalLeft, physicalTop, physicalRight, physicalBottom, layerIds, filter
      );
    } catch (error) {
      console.error('MapLibreMap', `queryRenderedFeaturesForBox failed: ${error.message}`);
      return [];
    }
  }

  /**
   * Query all features from a source
   *
   * Returns every feature in the specified source, regardless of whether it is currently rendered.
   * Particularly useful for GeoJSON sources to retrieve all added features.
   *
   * @param sourceId Source ID
   * @param sourceLayerIds Optional array of source layer IDs (for vector tile sources)
   * @param filter Optional filter expression
   * @returns Array of features
   *
   * @example
   * ```typescript
   * // Query every feature from a GeoJSON source
   * const features = map.querySourceFeatures('my-source');
   *
   * // Query a specific layer from a vector tile source
   * const features = map.querySourceFeatures('composite', ['poi-label']);
   *
   * // Query with a filter
   * const features = map.querySourceFeatures(
   *   'my-source',
   *   undefined,
   *   ['==', ['get', 'type'], 'restaurant']
   * );
   * ```
   */
  public querySourceFeatures(
    sourceId: string,
    sourceLayerIds?: string[],
    filter?: NapiExpressionLiteral
  ): IFeature[] {
    if (this.destroyed) {
      console.warn('MapLibreMap', 'querySourceFeatures: Map is destroyed');
      return [];
    }

    try {
      const features = this.nativeMapView.querySourceFeatures(
        sourceId,
        sourceLayerIds || undefined,
        filter || undefined
      );
      return features as IFeature[];
    } catch (error) {
      console.error('MapLibreMap', `querySourceFeatures failed: ${error}`);
      return [];
    }
  }

// ========== InfoWindow helper methods ==========

  /**
   * Get the InfoWindowManager (internal use)
   * @internal
   */
  public getInfoWindowManager(): InfoWindowManager {
    return this.infoWindowManager;
  }

// ========== Performance instrumentation (mirrors Android) ==========

  /**
   * Set the FPS change listener (mirrors Android MapLibreMap.setOnFpsChangedListener)
   * Useful for monitoring rendering frame rate in real time
   * @param listener Listener instance; pass null to remove
   */
  public setOnFpsChangedListener(listener: OnFpsChangedListener | null): void {
    if (this.destroyed) {
      console.warn('MapLibreMap', 'setOnFpsChangedListener: Map is destroyed');
      return;
    }

    try {
      if (listener === null) {
        this.nativeMapView.setOnFpsChangedListener(null);
      } else {
        this.nativeMapView.setOnFpsChangedListener((fps: number) => {
          listener.onFpsChanged(fps);
        });
      }
    } catch (error) {
      console.error('MapLibreMap', `setOnFpsChangedListener failed: ${error.message}`);
    }
  }

// ========== Observer event listeners (Shader, Glyph, Sprite, Tile) ==========
  
  /**
   * Add a pre-compile shader listener
   * @param listener Listener object or callback
   */
  public addOnPreCompileShaderListener(listener: OnPreCompileShaderListener): void {
    if (this.destroyed) {
      return;
    }
    if (this.preCompileShaderWrappers.has(listener)) {
      return;
    }
    const wrapper: OnPreCompileShaderListener = (shaderId: number, backendType: number, defines: string) => {
      try {
        listener(shaderId, backendType, defines);
      } catch (error) {
        const message: string = error instanceof Error ? `${error.name}: ${error.message}` : `${error}`;
        logListenerError('OnPreCompileShaderListener', message);
      }
    };
    this.preCompileShaderWrappers.set(listener, wrapper);
    this.nativeMapView.addOnPreCompileShaderListener(wrapper);
  }
  
  /**
   * Remove a pre-compile shader listener
   */
  public removeOnPreCompileShaderListener(listener: OnPreCompileShaderListener): void {
    if (this.destroyed) {
      return;
    }
    const wrapper = this.preCompileShaderWrappers.get(listener);
    if (wrapper) {
      this.nativeMapView.removeOnPreCompileShaderListener(wrapper);
      this.preCompileShaderWrappers.delete(listener);
    }
  }
  
  /**
   * Add a post-compile shader listener
   * @param listener Listener object or callback
   */
  public addOnPostCompileShaderListener(listener: OnPostCompileShaderListener): void {
    if (this.destroyed) {
      return;
    }
    if (this.postCompileShaderWrappers.has(listener)) {
      return;
    }
    const wrapper: OnPostCompileShaderListener = (shaderId: number, backendType: number, defines: string) => {
      try {
        listener(shaderId, backendType, defines);
      } catch (error) {
        const message: string = error instanceof Error ? `${error.name}: ${error.message}` : `${error}`;
        logListenerError('OnPostCompileShaderListener', message);
      }
    };
    this.postCompileShaderWrappers.set(listener, wrapper);
    this.nativeMapView.addOnPostCompileShaderListener(wrapper);
  }
  
  /**
   * Remove a post-compile shader listener
   */
  public removeOnPostCompileShaderListener(listener: OnPostCompileShaderListener): void {
    if (this.destroyed) {
      return;
    }
    const wrapper = this.postCompileShaderWrappers.get(listener);
    if (wrapper) {
      this.nativeMapView.removeOnPostCompileShaderListener(wrapper);
      this.postCompileShaderWrappers.delete(listener);
    }
  }
  
  /**
   * Add a shader compile failure listener
   * @param listener Listener object or callback
   */
  public addOnShaderCompileFailedListener(listener: OnShaderCompileFailedListener): void {
    if (this.destroyed) {
      return;
    }
    if (this.shaderCompileFailedWrappers.has(listener)) {
      return;
    }
    const wrapper: OnShaderCompileFailedListener = (shaderId: number, backendType: number, defines: string) => {
      try {
        listener(shaderId, backendType, defines);
      } catch (error) {
        const message: string = error instanceof Error ? `${error.name}: ${error.message}` : `${error}`;
        logListenerError('OnShaderCompileFailedListener', message);
      }
    };
    this.shaderCompileFailedWrappers.set(listener, wrapper);
    this.nativeMapView.addOnShaderCompileFailedListener(wrapper);
  }
  
  /**
   * Remove a shader compile failure listener
   */
  public removeOnShaderCompileFailedListener(listener: OnShaderCompileFailedListener): void {
    if (this.destroyed) {
      return;
    }
    const wrapper = this.shaderCompileFailedWrappers.get(listener);
    if (wrapper) {
      this.nativeMapView.removeOnShaderCompileFailedListener(wrapper);
      this.shaderCompileFailedWrappers.delete(listener);
    }
  }
  
  /**
   * Add a glyph request listener
   * @param listener Listener object or callback
   */
  public addOnGlyphsRequestedListener(listener: OnGlyphsRequestedListener): void {
    if (this.destroyed) {
      return;
    }
    if (this.glyphsRequestedWrappers.has(listener)) {
      return;
    }
    const wrapper: OnGlyphsRequestedListener = (fontStack: string[], rangeStart: number, rangeEnd: number) => {
      try {
        listener(fontStack, rangeStart, rangeEnd);
      } catch (error) {
        const message: string = error instanceof Error ? `${error.name}: ${error.message}` : `${error}`;
        logListenerError('OnGlyphsRequestedListener', message);
      }
    };
    this.glyphsRequestedWrappers.set(listener, wrapper);
    this.nativeMapView.addOnGlyphsRequestedListener(wrapper);
  }
  
  /**
   * Remove a glyph request listener
   */
  public removeOnGlyphsRequestedListener(listener: OnGlyphsRequestedListener): void {
    if (this.destroyed) {
      return;
    }
    const wrapper = this.glyphsRequestedWrappers.get(listener);
    if (wrapper) {
      this.nativeMapView.removeOnGlyphsRequestedListener(wrapper);
      this.glyphsRequestedWrappers.delete(listener);
    }
  }
  
  /**
   * Add a glyph loaded listener
   * @param listener Listener object or callback
   */
  public addOnGlyphsLoadedListener(listener: OnGlyphsLoadedListener): void {
    if (this.destroyed) {
      return;
    }
    if (this.glyphsLoadedWrappers.has(listener)) {
      return;
    }
    const wrapper: OnGlyphsLoadedListener = (fontStack: string[], rangeStart: number, rangeEnd: number) => {
      try {
        listener(fontStack, rangeStart, rangeEnd);
      } catch (error) {
        const message: string = error instanceof Error ? `${error.name}: ${error.message}` : `${error}`;
        logListenerError('OnGlyphsLoadedListener', message);
      }
    };
    this.glyphsLoadedWrappers.set(listener, wrapper);
    this.nativeMapView.addOnGlyphsLoadedListener(wrapper);
  }
  
  /**
   * Remove a glyph loaded listener
   */
  public removeOnGlyphsLoadedListener(listener: OnGlyphsLoadedListener): void {
    if (this.destroyed) {
      return;
    }
    const wrapper = this.glyphsLoadedWrappers.get(listener);
    if (wrapper) {
      this.nativeMapView.removeOnGlyphsLoadedListener(wrapper);
      this.glyphsLoadedWrappers.delete(listener);
    }
  }
  
  /**
   * Add a glyph error listener
   * @param listener Listener object or callback
   */
  public addOnGlyphsErrorListener(listener: OnGlyphsErrorListener): void {
    if (this.destroyed) {
      return;
    }
    if (this.glyphsErrorWrappers.has(listener)) {
      return;
    }
    const wrapper: OnGlyphsErrorListener = (fontStack: string[], rangeStart: number, rangeEnd: number) => {
      try {
        listener(fontStack, rangeStart, rangeEnd);
      } catch (error) {
        const message: string = error instanceof Error ? `${error.name}: ${error.message}` : `${error}`;
        logListenerError('OnGlyphsErrorListener', message);
      }
    };
    this.glyphsErrorWrappers.set(listener, wrapper);
    this.nativeMapView.addOnGlyphsErrorListener(wrapper);
  }
  
  /**
   * Remove a glyph error listener
   */
  public removeOnGlyphsErrorListener(listener: OnGlyphsErrorListener): void {
    if (this.destroyed) {
      return;
    }
    const wrapper = this.glyphsErrorWrappers.get(listener);
    if (wrapper) {
      this.nativeMapView.removeOnGlyphsErrorListener(wrapper);
      this.glyphsErrorWrappers.delete(listener);
    }
  }
  
  /**
   * Add a sprite request listener
   * @param listener Listener object or callback
   */
  public addOnSpriteRequestedListener(listener: OnSpriteRequestedListener): void {
    if (this.destroyed) {
      return;
    }
    if (this.spriteRequestedWrappers.has(listener)) {
      return;
    }
    const wrapper: OnSpriteRequestedListener = (spriteId: string, url: string) => {
      try {
        listener(spriteId, url);
      } catch (error) {
        const message: string = error instanceof Error ? `${error.name}: ${error.message}` : `${error}`;
        logListenerError('OnSpriteRequestedListener', message);
      }
    };
    this.spriteRequestedWrappers.set(listener, wrapper);
    this.nativeMapView.addOnSpriteRequestedListener(wrapper);
  }
  
  /**
   * Remove a sprite request listener
   */
  public removeOnSpriteRequestedListener(listener: OnSpriteRequestedListener): void {
    if (this.destroyed) {
      return;
    }
    const wrapper = this.spriteRequestedWrappers.get(listener);
    if (wrapper) {
      this.nativeMapView.removeOnSpriteRequestedListener(wrapper);
      this.spriteRequestedWrappers.delete(listener);
    }
  }
  
  /**
   * Add a sprite loaded listener
   * @param listener Listener object or callback
   */
  public addOnSpriteLoadedListener(listener: OnSpriteLoadedListener): void {
    if (this.destroyed) {
      return;
    }
    if (this.spriteLoadedWrappers.has(listener)) {
      return;
    }
    const wrapper: OnSpriteLoadedListener = (spriteId: string, url: string) => {
      try {
        listener(spriteId, url);
      } catch (error) {
        const message: string = error instanceof Error ? `${error.name}: ${error.message}` : `${error}`;
        logListenerError('OnSpriteLoadedListener', message);
      }
    };
    this.spriteLoadedWrappers.set(listener, wrapper);
    this.nativeMapView.addOnSpriteLoadedListener(wrapper);
  }
  
  /**
   * Remove a sprite loaded listener
   */
  public removeOnSpriteLoadedListener(listener: OnSpriteLoadedListener): void {
    if (this.destroyed) {
      return;
    }
    const wrapper = this.spriteLoadedWrappers.get(listener);
    if (wrapper) {
      this.nativeMapView.removeOnSpriteLoadedListener(wrapper);
      this.spriteLoadedWrappers.delete(listener);
    }
  }
  
  /**
   * Add a sprite error listener
   * @param listener Listener object or callback
   */
  public addOnSpriteErrorListener(listener: OnSpriteErrorListener): void {
    if (this.destroyed) {
      return;
    }
    if (this.spriteErrorWrappers.has(listener)) {
      return;
    }
    const wrapper: OnSpriteErrorListener = (spriteId: string, url: string) => {
      try {
        listener(spriteId, url);
      } catch (error) {
        const message: string = error instanceof Error ? `${error.name}: ${error.message}` : `${error}`;
        logListenerError('OnSpriteErrorListener', message);
      }
    };
    this.spriteErrorWrappers.set(listener, wrapper);
    this.nativeMapView.addOnSpriteErrorListener(wrapper);
  }
  
  /**
   * Remove a sprite error listener
   */
  public removeOnSpriteErrorListener(listener: OnSpriteErrorListener): void {
    if (this.destroyed) {
      return;
    }
    const wrapper = this.spriteErrorWrappers.get(listener);
    if (wrapper) {
      this.nativeMapView.removeOnSpriteErrorListener(wrapper);
      this.spriteErrorWrappers.delete(listener);
    }
  }
  
  /**
   * Add a tile action listener
   * @param listener Listener object or callback
   */
  public addOnTileActionListener(listener: OnTileActionListener): void {
    if (this.destroyed) {
      return;
    }
    if (this.tileActionWrappers.has(listener)) {
      return;
    }
    const wrapper: OnTileActionListener = (
      operation: number,
      x: number,
      y: number,
      z: number,
      wrap: number,
      overscaledZ: number,
      sourceId: string
    ) => {
      try {
        listener(operation, x, y, z, wrap, overscaledZ, sourceId);
      } catch (error) {
        const message: string = error instanceof Error ? `${error.name}: ${error.message}` : `${error}`;
        logListenerError('OnTileActionListener', message);
      }
    };
    this.tileActionWrappers.set(listener, wrapper);
    this.nativeMapView.addOnTileActionListener(wrapper);
  }
  
  /**
   * Remove a tile action listener
   */
  public removeOnTileActionListener(listener: OnTileActionListener): void {
    if (this.destroyed) {
      return;
    }
    const wrapper = this.tileActionWrappers.get(listener);
    if (wrapper) {
      this.nativeMapView.removeOnTileActionListener(wrapper);
      this.tileActionWrappers.delete(listener);
    }
  }

  /**
   * Set the maximum FPS (mirrors Android MapView.setMaximumFps)
   * @param maximumFps Target frame rate, e.g., 30 or 60
   */
  public setMaximumFps(maximumFps: number): void {
    if (this.destroyed) {
      console.warn('MapLibreMap', 'setMaximumFps: Map is destroyed');
      return;
    }

    try {
      this.nativeMapView.setMaximumFps(maximumFps);
    } catch (error) {
      console.error('MapLibreMap', `setMaximumFps failed: ${error.message}`);
    }
  }

  /**
   * Set the rendering refresh mode (mirrors Android MapView.setRenderingRefreshMode)
   * @param mode Rendering mode: CONTINUOUS or WHEN_DIRTY
   */
  public setRenderingRefreshMode(mode: RenderingRefreshMode): void {
    if (this.destroyed) {
      console.warn('MapLibreMap', 'setRenderingRefreshMode: Map is destroyed');
      return;
    }

    try {
      this.nativeMapView.setRenderingRefreshMode(mode);
    } catch (error) {
      console.error('MapLibreMap', `setRenderingRefreshMode failed: ${error.message}`);
    }
  }

  /**
   * Get the rendering refresh mode (mirrors Android MapView.getRenderingRefreshMode)
   * @returns Current rendering mode
   */
  public getRenderingRefreshMode(): RenderingRefreshMode {
    if (this.destroyed) {
      console.warn('MapLibreMap', 'getRenderingRefreshMode: Map is destroyed');
      return RenderingRefreshMode.WHEN_DIRTY;
    }

    try {
      return this.nativeMapView.getRenderingRefreshMode();
    } catch (error) {
      console.error('MapLibreMap', `getRenderingRefreshMode failed: ${error.message}`);
      return RenderingRefreshMode.WHEN_DIRTY;
    }
  }

// ========== Compatibility helpers (migrated from NativeMapView) ==========

  /**
   * Get the device pixel ratio
   * @returns Device pixel ratio
   */
  public getPixelRatio(): number {
    if (this.destroyed) {
      return 1.0;
    }
    // Retrieve pixel ratio directly from NativeMapView (already fetched via NAPI)
    return this.nativeMapView.getPixelRatio();
  }

  /**
   * Set content padding
   * Padding affects the visible region without changing map size
   * @param top Top padding
   * @param left Left padding
   * @param bottom Bottom padding
   * @param right Right padding
   */
  public setContentPadding(top: number, left: number, bottom: number, right: number): void {
    if (this.destroyed) {
      return;
    }
    // Invoke native setContentPadding
    // Note: native expects [top, left, bottom, right]
    this.nativeMapView.setContentPadding([top, left, bottom, right]);
  }

  /**
   * Get content padding
   * @returns Padding array [top, left, bottom, right]
   */
  public getContentPadding(): number[] {
    if (this.destroyed) {
      return [0, 0, 0, 0];
    }
    try {
      // Fetch padding from native layer
      const padding: number[] = this.nativeMapView.getContentPadding();
      if (padding && Array.isArray(padding) && padding.length === 4) {
        // Native returns [top, left, bottom, right]
        return padding;
      }
    } catch (error) {
      console.error('MapLibreMap', 'Failed to get content padding:', error);
    }
    return [0, 0, 0, 0];
  }

  /**
   * Get a density-dependent rectangle
   * Converts logical coordinates to physical pixels
   * @param rect Rectangle in logical coordinates
   * @returns Rectangle adjusted to physical pixels
   */
  public getDensityDependantRectangle(rect: Rect): Rect {
    const pixelRatio = this.getPixelRatio();
    return new Rect(
      rect.left * pixelRatio,
      rect.top * pixelRatio,
      rect.right * pixelRatio,
      rect.bottom * pixelRatio
    );
  }

  /**
   * Convert a native LatLng array to ETS LatLng array
   * @private
   */
  private convertNativeLatLngArray(nativeArray: import('libmaplibre.so').LatLng[]): LatLng[] {
    return nativeArray.map(native => LatLng.fromNative(native));
  }

// ========== Debug utilities ==========

  /**
   * Configure debug options
   * Uses MapDebugOptions bitmask to enable multiple debug features
   *
   * Options include:
   * - TileBoundaries: show tile boundaries (red)
   * - TileInfo: display tile coordinates (x/y/z)
   * - Timestamps: display tile load timestamps
   * - CollisionBoxes: show collision boxes (green)
   * - OverdrawVisualization: visualize overdraw
   *
   * @param debugOptions Bitmask of debug options
   * @example
   * ```typescript
   * import { MapDebugOptions } from '@ohos/maplibre';
   *
   * // Enable multiple debug options
   * map.setDebugOptions(MapDebugOptions.TileBoundaries | MapDebugOptions.CollisionBoxes);
   *
   * // Disable all debug options
   * map.setDebugOptions(MapDebugOptions.NoDebug);
   * ```
   */
  public setDebugOptions(debugOptions: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setDebug(debugOptions);
  }

  /**
   * Get current debug options
   *
   * @returns Bitmask of enabled debug options
   * @example
   * ```typescript
   * const currentOptions = map.getDebugOptions();
   * console.log('Current debug options:', currentOptions);
   * ```
   */
  public getDebugOptions(): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getDebug();
  }

  /**
   * Toggle debug mode quickly (using a default option bundle)
   *
   * Enabling debug mode turns on the following options:
   * - TileBoundaries
   * - TileInfo
   * - CollisionBoxes
   *
   * This default set helps diagnose most rendering issues.
   *
   * @param active Whether to enable debug mode
   * @example
   * ```typescript
   * // Quickly enable debug mode
   * map.setDebugActive(true);
   *
   * // Verify the state
   * if (map.isDebugActive()) {
   *   console.log('Debug mode is active');
   * }
   *
   * // Disable debug mode
   * map.setDebugActive(false);
   * ```
   */
  public setDebugActive(active: boolean): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setDebugActive(active);
  }

  /**
   * Check whether debug mode is active
   *
   * @returns true if any debug option is enabled
   * @example
   * ```typescript
   * if (map.isDebugActive()) {
   *   console.log('Debug visualizations are currently enabled');
   * }
   * ```
   */
  public isDebugActive(): boolean {
    if (this.destroyed) {
      return false;
    }
    return this.nativeMapView.isDebugActive();
  }
}

