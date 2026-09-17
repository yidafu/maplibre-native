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
import type { AnnotationViewConfig, AnnotationViewDelegate } from './annotations/AnnotationViewDelegate';
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
import type { UIContext } from '@kit.ArkUI';
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
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../constants/HiLogConstants';
import { ListenerGroup, NativeListenerBinding, listenerErrorMessage } from './listeners/ListenerRegistry';

function logListenerError(eventName: string, message: string): void {
  hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', `${eventName}: ${message}`);
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
 *     hilog.info(DOMAIN, 'MapLibreMap', '%{public}s', `Map clicked at: ${x}, ${y}`);
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
interface MapClickPosition {
  x: number;
  y: number;
}

/**
 * Batch camera state returned by getCameraState().
 * Combines all camera parameters in one object to minimize NAPI calls.
 */
export interface CameraState {
  bearing: number;
  latitude: number;
  longitude: number;
  zoom: number;
  pitch: number;
}

export class MapLibreMap {
  private nativeMapView: NativeMapView;
  private options: MapLibreMapOptions;
  private destroyed: boolean = false;
  private markerManager: MarkerManager;
  private polygonManager: PolygonManager;
  private polylineManager: PolylineManager;
  private infoWindowManager: InfoWindowManager;
  private viewAnnotationManager: ViewAnnotationManager;
  private viewAnnotationRenderCallback?: (states: ViewAnnotationRenderState[]) => void;
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
  private styleLoadedListeners: ListenerGroup<OnStyleLoadedListener> = new ListenerGroup<OnStyleLoadedListener>();
  private styleLoadErrorListeners: ListenerGroup<OnStyleLoadErrorListener> = new ListenerGroup<OnStyleLoadErrorListener>();
  private styleImageMissingListener?: (imageId: string) => void;
  private nativeStyleLoadedCallback?: () => void;
  private nativeStyleLoadErrorCallback?: (error: string) => void;
  private nativeStyleImageMissingCallback?: (imageId: string) => void;
  // Wrapper-based native listener registry lives in the listener section
  // (nativeListenerRegistry); the per-event wrapper Maps were removed.
  // Operation queue - cache operations before the style is ready
  private pendingOperations: PendingOperation[] = [];
  // Compass update callback (injected by the outer UI layer)
  public onCompassUpdate?: (bearing: number) => void;
  // ScaleBar update callback (injected by the outer UI layer)
  public onScaleBarUpdate?: (metersPerPixel: number) => void;
  // Pitch update callback (injected by the outer UI layer)
  // Used by NativeMapViewController to cache pitch for build()
  public onPitchUpdate?: (pitch: number) => void;
  // Animation callback management
  private pendingAnimationCallback: CameraAnimationCallback | null = null;
  private animationTimerId: number | null = null;
  private animationCancelled: boolean = false;

  // Camera state cache: populated once per camera move event and shared across all
  // internal listeners (compass, scale bar, annotation views). Cleared after the
  // current move event cycle completes to ensure freshness.
  private cachedCameraState: CameraState | null = null;
  private cameraMoveInProgress: boolean = false;

  // Native bridge callback for map tap (registered via NAPI CallbackManager)
  // Stores the function reference so it can be removed in destroy()
  // Coordinates arrive as {x, y} object because ThreadSafeCallback supports only 1 argument
  private mapClickNativeBridge: ((coords: MapClickPosition) => void) | null = null;
  private mapLongClickNativeBridge: ((coords: MapClickPosition) => void) | null = null;

  constructor(nativeMapView: NativeMapView, options: MapLibreMapOptions) {
    this.nativeMapView = nativeMapView;
    this.options = options;
    
    // ⚠️ Important: InfoWindowManager must be created before MarkerManager
    // Because the MarkerManager constructor calls this.mapLibreMap.getInfoWindowManager()
    this.infoWindowManager = new InfoWindowManager();
    this.viewAnnotationManager = new ViewAnnotationManager();
    
    // Create annotation managers (depend on InfoWindowManager)
    this.markerManager = new MarkerManager(this);
    this.polygonManager = new PolygonManager(this);
    this.polylineManager = new PolylineManager(this);
    this.locationComponent = new LocationComponent(this);
    this.projection = new Projection(nativeMapView, 0, 0); // Start with zero size and update later

    // Bind the floating-layer engine to the native map view
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

    // InfoWindow positioning is handled by the native engine: it pushes
    // (epsilon-deduped) frames to ArkTS after every camera update — no
    // camera-event-driven refresh is needed

    // Register the consolidated camera move listener (compass + scale bar + annotations)
    this.setupConsolidatedCameraMoveListener();

    // 🔧 Register camera callbacks from the NAPI layer
    // These callbacks trigger cameraChangeDispatcher and notify all internal listeners
    this.setupNativeCameraCallbacks();

    // Register with NativeMapView to enable InfoWindow features
    registerMapLibreMap(nativeMapView, this);

    // 🔧 Register native bridge callbacks for map tap / long-press gestures
    // These bridge from C++ NativeGestureManager → NAPI CallbackManager → ETS _notifyMapClick
    // The C++ gesture manager detects the tap, extracts coordinates, dispatches via CallbackManager
    // to the JS callback registered here, which then calls _notifyMapClick to notify all ETS listeners.
    this.setupMapClickNativeBridge();

    // Apply prefetch, LOD, and debug settings from MapLibreMapOptions
    try {
      if (options.prefetchTiles !== undefined) {
        this.setPrefetchTiles(options.prefetchTiles);
      }
      if (options.prefetchZoomDelta !== undefined) {
        this.setPrefetchZoomDelta(options.prefetchZoomDelta);
      }
      if (options.tileCacheEnabled !== undefined) {
        this.setTileCacheEnabled(options.tileCacheEnabled);
      }
      // LOD settings -- only apply non-default values
      if (options.tileLodMinRadius !== undefined && options.tileLodMinRadius > 0) {
        this.setTileLodMinRadius(options.tileLodMinRadius);
      }
      if (options.tileLodScale !== undefined && options.tileLodScale !== 1.0) {
        this.setTileLodScale(options.tileLodScale);
      }
      if (options.tileLodPitchThreshold !== undefined && options.tileLodPitchThreshold > 0) {
        this.setTileLodPitchThreshold(options.tileLodPitchThreshold);
      }
      if (options.tileLodZoomShift !== undefined && options.tileLodZoomShift !== 0) {
        this.setTileLodZoomShift(options.tileLodZoomShift);
      }
      if (options.debug !== undefined && options.debug) {
        this.setDebugActive(true);
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.warn(DOMAIN, 'MapLibreMap', 'Failed to apply initial options: ' + errorMsg);
    }
  }

  /**
   * Set up native bridge callbacks for map tap and long-press gestures.
   *
   * Registers closure-based callbacks with the NAPI layer so that when the
   * C++ NativeGestureManager detects a tap or long-press, the event flows
   * through to the ETS listener dispatch methods.
   *
   * @private
   */
  private setupMapClickNativeBridge(): void {
    // Map click bridge: forwards tap coordinates from C++ to ETS listeners.
    // Note: ThreadSafeCallback passes only 1 argument, so coordinates arrive as {x, y}.
    this.mapClickNativeBridge = (coords: MapClickPosition): void => {
      const validX = typeof coords?.x === 'number' ? coords.x : 0;
      const validY = typeof coords?.y === 'number' ? coords.y : 0;
      this._notifyMapClick(validX, validY);
    };
    try {
      this.nativeMapView.addOnMapClickListener(this.mapClickNativeBridge);
      hilog.info(DOMAIN, 'MapLibreMap', '%{public}s', '[MapLibreMap] Map click native bridge registered');
    } catch (error) {
      hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', `[MapLibreMap] Failed to register map click native bridge: ${error}`);
    }

    // Map long-click bridge: forwards long-press coordinates from C++ to ETS listeners
    this.mapLongClickNativeBridge = (coords: MapClickPosition): void => {
      const validX = typeof coords?.x === 'number' ? coords.x : 0;
      const validY = typeof coords?.y === 'number' ? coords.y : 0;
      this._notifyMapLongClick(validX, validY);
    };
    try {
      this.nativeMapView.addOnMapLongClickListener(this.mapLongClickNativeBridge);
      hilog.info(DOMAIN, 'MapLibreMap', '%{public}s', '[MapLibreMap] Map long-click native bridge registered');
    } catch (error) {
      hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', `[MapLibreMap] Failed to register map long-click native bridge: ${error}`);
    }
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
      hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', `MapLibreMap: Native style load error callback triggered: ${error}`);
      this.onStyleLoadError(error);
    };
    this.nativeMapView.setOnStyleLoadErrorListener(this.nativeStyleLoadErrorCallback);

    // Register the style image missing callback
    this.nativeStyleImageMissingCallback = (imageId: string) => {
      if (this.styleImageMissingListener) {
        try {
          this.styleImageMissingListener(imageId);
        } catch (error) {
          hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', `MapLibreMap: Error in onStyleImageMissing listener: ${error}`);
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
   * Consolidated camera move listener — fires once per move event.
   * Updates compass and scale bar using a single cached camera state to
   * minimise NAPI cross-boundary calls.
   * @private
   */
  private setupConsolidatedCameraMoveListener(): void {
    class ConsolidatedMoveListenerImpl implements OnCameraMoveListener {
      parent: MapLibreMap;

      constructor(parent: MapLibreMap) {
        this.parent = parent;
      }

      onCameraMove(): void {
        const state = this.parent.getOrFetchCameraState();

        // 1. Compass update
        if (this.parent.onCompassUpdate) {
          this.parent.onCompassUpdate(state.bearing);
        }

        // 2. Scale bar update
        if (this.parent.onScaleBarUpdate) {
          const metersPerPixel = this.parent.getMetersPerPixelAtLatitude(state.latitude, state.zoom);
          this.parent.onScaleBarUpdate(metersPerPixel);
        }

        // 3. Pitch cache update (for build() caching)
        if (this.parent.onPitchUpdate) {
          this.parent.onPitchUpdate(state.pitch);
        }
      }
    }

    this.cameraChangeDispatcher.addOnCameraMoveListener(new ConsolidatedMoveListenerImpl(this));
  }

  private readPixelRatioSafe(mapView: NativeMapView): number {
    try {
      const ratioCandidate = mapView.getPixelRatio?.();
      if (typeof ratioCandidate === 'number' && Number.isFinite(ratioCandidate) && ratioCandidate > 0) {
        return ratioCandidate;
      }
    } catch (error) {
      const reason = error instanceof Error ? error.message : `${error}`;
      hilog.warn(DOMAIN, 'MapLibreMap', '%{public}s', `[MapLibreMap] readPixelRatioSafe failed: ${reason}`);
    }
    return 1;
  }

  /**
   * Register camera event callbacks from the NAPI layer
   *
   * Wires up native camera callbacks (onCameraWillChange, onCameraIsChanging,
   * onCameraDidChange) and translates them to the Android-style events used
   * internally by CameraChangeDispatcher.
   *
   * @private
   */
  private setupNativeCameraCallbacks(): void {
    // Camera move started callback — translated from native onCameraWillChange
    // animated=true  → DEVELOPER_ANIMATION (3), animated=false → GESTURE (1)
    this.nativeMapView.addOnCameraWillChangeListener((animated: boolean) => {
      const reason = animated ? CameraMoveReason.DEVELOPER_ANIMATION : CameraMoveReason.GESTURE;
      this.cameraChangeDispatcher.notifyCameraMoveStarted(reason);
    });

    // Camera moving callback — translated from native onCameraIsChanging
    // Clears the intra-frame camera state cache so each frame gets fresh data.
    this.nativeMapView.addOnCameraIsChangingListener(() => {
      this.cachedCameraState = null; // Invalidate previous frame's cache
      this.cameraChangeDispatcher.notifyCameraMove();
    });

    // Camera idle callback — translated from native onCameraDidChange
    this.nativeMapView.addOnCameraDidChangeListener(() => {
      this.cameraChangeDispatcher.notifyCameraIdle();
    });
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
          hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', `MapLibreMap: Error executing pending operation: ${error}`);
        }
      });
      this.pendingOperations = [];
    }

    // Notify listeners
    if (this.styleLoadedListeners.size() > 0) {
      this.styleLoadedListeners.getListeners().forEach(listener => {
        try {
          // Note: Pass null for the Style object because NativeMapView has no getStyle() method yet
          // Listeners can interact with layers/sources directly via NativeMapView
          listener.onStyleLoaded(null);
        } catch (error) {
          hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', `MapLibreMap: Error in onStyleLoaded listener: ${error}`);
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
      hilog.warn(DOMAIN, 'MapLibreMap', '%{public}s', `MapLibreMap: Clearing ${this.pendingOperations.length} pending operations due to style load error`);
      this.pendingOperations = [];
    }

    // Notify error listeners
    if (this.styleLoadErrorListeners.size() > 0) {
      this.styleLoadErrorListeners.getListeners().forEach(listener => {
        try {
          listener.onStyleLoadError(error);
        } catch (err) {
          hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', `MapLibreMap: Error in onStyleLoadError listener: ${err}`);
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
      this.styleLoadedListeners.clear();
      this.styleLoadErrorListeners.clear();
      this.styleImageMissingListener = undefined;
      this.clearNativeListeners();
      this.pendingOperations = [];
      this.mapClickListeners.clear();
      this.mapLongClickListeners.clear();

      // 1.1 Clean up native bridge callbacks for map tap / long-press
      if (this.mapClickNativeBridge) {
        try {
          this.nativeMapView.removeOnMapClickListener(this.mapClickNativeBridge);
        } catch (error) {
          hilog.warn(DOMAIN, 'MapLibreMap', '%{public}s', `[MapLibreMap] Failed to remove map click native bridge: ${error}`);
        }
        this.mapClickNativeBridge = null;
      }
      if (this.mapLongClickNativeBridge) {
        try {
          this.nativeMapView.removeOnMapLongClickListener(this.mapLongClickNativeBridge);
        } catch (error) {
          hilog.warn(DOMAIN, 'MapLibreMap', '%{public}s', `[MapLibreMap] Failed to remove map long-click native bridge: ${error}`);
        }
        this.mapLongClickNativeBridge = null;
      }

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

      // 4. Clear the InfoWindowManager (closes windows, drops cached
      // descriptors and detaches adapter/listeners/UIContext)
      this.infoWindowManager.destroy();

      // 5. Tear down the floating-layer engine (marker custom views and
      // InfoWindows are its only producers)
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
      hilog.error(DOMAIN, 'MapLibreMap', 'MapLibreMap: Error during destroy: %{public}s', error);
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
   * Set the UI settings instance.
   *
   * Allows the controller to inject its shared UiSettings instance so that
   * runtime API calls (e.g. map.getUiSettings().setCompassEnabled())
   * affect the same instance that drives widget rendering in build().
   */
  public setUiSettings(uiSettings: UiSettings): void {
    this.uiSettings = uiSettings;
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
    hilog.info(DOMAIN, 'MapLibreMap', '%{public}s', `[MapLibreMap] resizeView called: ${width}x${height}`);

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
        hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', `[MapLibreMap] Failed to update ScaleBar on resize: ${error}`);
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
          hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', `MapLibreMap: Error in setStyleWithCallback callback: ${error}`);
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
            hilog.info(DOMAIN, 'MapLibreMap', '%{public}s', '[MapLibreMap] setLocalIdeographFontFamily: Local font updated to ' +
                   (fontFamily || '(disabled)'));
    } catch (error) {
      hilog.error(DOMAIN, 'MapLibreMap', '[MapLibreMap] setLocalIdeographFontFamily: Update failed %{public}s', error);
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
      hilog.error(DOMAIN, 'MapLibreMap', '[MapLibreMap] getLocalIdeographFontFamily: Failed to query value %{public}s', error);
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
      hilog.error(DOMAIN, 'MapLibreMap', 'Failed to get style: %{public}s', error);
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
          hilog.error(DOMAIN, 'MapLibreMap', '[MapLibreMap] Error in animation onFinish callback: %{public}s', error);
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
        hilog.error(DOMAIN, 'MapLibreMap', '[MapLibreMap] Error in animation onCancel callback: %{public}s', error);
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

  /**
   * Get all camera parameters (bearing, center, zoom, pitch) in a single NAPI call.
   * Use instead of separate getBearing() / getLatLng() / getZoom() / getPitch() calls
   * to minimize cross-boundary overhead.
   */
  public getCameraState(): CameraState {
    if (this.destroyed) {
      return { bearing: 0, latitude: 0, longitude: 0, zoom: 0, pitch: 0 };
    }
    const state = this.nativeMapView.getCameraState() as CameraState | undefined;
    if (state) {
      return state;
    }
    // Fallback: assemble from individual NAPI calls if batch method unavailable
    const latLng = this.getLatLng();
    return {
      bearing: this.getBearing(),
      latitude: latLng.latitude,
      longitude: latLng.longitude,
      zoom: this.getZoom(),
      pitch: this.getPitch()
    };
  }

  /**
   * Get camera state with intra-frame caching.
   * During a camera move event, all listeners share the same cached state
   * to avoid redundant NAPI calls. The cache is naturally cleared on the
   * next frame's onCameraIsChanging event.
   */
  private getOrFetchCameraState(): CameraState {
    if (!this.cachedCameraState) {
      this.cachedCameraState = this.getCameraState();
    }
    return this.cachedCameraState;
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
      hilog.error(DOMAIN, 'MapLibreMap', '[MapLibreMap] updateMarker: Failed - %{public}s', error);
    }
  }

  /**
   * @deprecated Legacy symbol-layer marker path. Use `addMarker` /
   * `addMarkersBatch` (MarkerManager -> ViewAnnotation engine) instead,
   * which matches the converged annotation architecture.
   */
  public addMarkers(markers: Marker[]): number[] {
    if (this.destroyed) {
      hilog.warn(DOMAIN, 'MapLibreMap', 'addMarkers: Map is destroyed, cannot add markers');
      return [];
    }

    // Convert wrapped markers into native marker objects
    const nativeMarkers: maplibre.Marker[] = markers.map((m: Marker): maplibre.Marker => m.getNative());
    return this.nativeMapView.addMarkers(nativeMarkers);
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
      hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', 'MapLibreMap.updatePolyline: polyline is null or undefined');
      return;
    }

    try {
      const nativePolyline = polyline.getNative();
      if (!nativePolyline) {
        hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', 'MapLibreMap.updatePolyline: nativePolyline is null or undefined');
        return;
      }

      // Pass the native NAPI object so C++ can unwrap (the C++ layer reads the ID from the object)
      this.nativeMapView.updatePolyline(nativePolyline);
    } catch (error) {
      hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', `MapLibreMap.updatePolyline: Exception - ${error}`);
      // throw error;
    }
  }

  public updatePolygon(polygon: Polygon): void {
    if (this.destroyed) {
      return;
    }
    if (!polygon) {
      hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', 'MapLibreMap.updatePolygon: polygon is null or undefined');
      return;
    }

    try {
      const nativePolygon = polygon.getNative();
      if (!nativePolygon) {
        hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', 'MapLibreMap.updatePolygon: nativePolygon is null or undefined');
        return;
      }

      // Pass the native NAPI object so C++ can unwrap it (C++ layer reads the ID from the object)
      this.nativeMapView.updatePolygon(nativePolygon);
    } catch (error) {
      hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', `MapLibreMap.updatePolygon: Exception - ${error}`);
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

    // Clear all markers (also removes their custom view annotations)
    this.markerManager.clear();

    // Close all InfoWindows
    this.infoWindowManager.closeAll();
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
      hilog.warn(DOMAIN, 'MapLibreMap', '%{public}s', `[MapLibreMap] ⚠️ Map is destroyed, cannot set listener`);
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
      hilog.warn(DOMAIN, 'MapLibreMap', '%{public}s', `[MapLibreMap] ⚠️ Map is destroyed, cannot set listener`);
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
    if (!this.styleLoadedListeners.getListeners().includes(listener)) {
      this.styleLoadedListeners.add(listener);

      // If the style is already loaded, invoke immediately
      if (this.styleLoaded) {
        try {
          // Note: Style currently passes null
          listener.onStyleLoaded(null);
        } catch (error) {
          hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', `MapLibreMap: Error in onStyleLoaded listener: ${error}`);
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
    this.styleLoadedListeners.remove(listener);
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
    this.styleLoadErrorListeners.add(listener);
  }

  /**
   * Remove a style load error listener
   *
   * @param listener Listener instance to remove
   */
  public removeOnStyleLoadErrorListener(listener: OnStyleLoadErrorListener): void {
    this.styleLoadErrorListeners.remove(listener);
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
        hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', `MapLibreMap: Error executing operation: ${error}`);
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

  /**
   * Refresh the content of a currently shown InfoWindow. Call this after
   * editing a marker (setTitle/setSnippet) or its InfoWindow style so the
   * visible window reflects the new state.
   *
   * @param marker Marker owning the InfoWindow
   * @returns true when a visible InfoWindow was refreshed
   */
  public refreshInfoWindowContent(marker: Marker): boolean {
    if (this.destroyed) {
      return false;
    }
    return this.infoWindowManager.refreshContent(marker);
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

// ========== Native listener registration infrastructure ==========

  // Wrapper-based native listener registry: listener -> (event key -> binding).
  // registerNativeListener() wraps each listener in an error-guarded proxy and
  // records how to detach it; remove*/removeAllListeners/destroy use the same map.
  private nativeListenerRegistry: Map<Object, Map<string, NativeListenerBinding>> = new Map();
  // One native bridge per camera-dispatcher event, registered lazily on the
  // first listener add and kept for the map's lifetime. (Re-registering a
  // native callback on every add made each event fire once per listener ever
  // added; per-listener fan-out/removal is CameraChangeDispatcher's job.)
  private cameraBridgeEvents: Set<string> = new Set();

  /**
   * Register a listener for a wrapper-based native event.
   */
  private registerNativeListener<L extends Object, W extends Object>(
    eventType: string,
    listener: L,
    wrap: (l: L) => W,
    nativeAdd: (w: W) => void,
    nativeRemove: (w: W) => void
  ): void {
    if (this.destroyed) {
      return;
    }
    let bindings = this.nativeListenerRegistry.get(listener);
    if (bindings === undefined) {
      bindings = new Map<string, NativeListenerBinding>();
      this.nativeListenerRegistry.set(listener, bindings);
    }
    if (bindings.has(eventType)) {
      return;
    }
    const wrapper = wrap(listener);
    const binding: NativeListenerBinding = {
      removeFromNative: () => {
        nativeRemove(wrapper);
      }
    };
    bindings.set(eventType, binding);
    nativeAdd(wrapper);
  }

  /**
   * Remove a listener previously registered via registerNativeListener.
   */
  private unregisterNativeListener(listener: Object, eventType: string): void {
    if (this.destroyed) {
      return;
    }
    const bindings = this.nativeListenerRegistry.get(listener);
    if (bindings === undefined) {
      return;
    }
    const binding = bindings.get(eventType);
    if (binding !== undefined) {
      binding.removeFromNative();
      bindings.delete(eventType);
      if (bindings.size === 0) {
        this.nativeListenerRegistry.delete(listener);
      }
    }
  }

  /**
   * Detach every live wrapper-based native listener (removeAllListeners/destroy).
   */
  private clearNativeListeners(): void {
    this.nativeListenerRegistry.forEach((bindings) => {
      bindings.forEach((binding) => {
        try {
          binding.removeFromNative();
        } catch (error) {
          hilog.warn(DOMAIN, 'MapLibreMap', 'clearNativeListeners: detach failed: %{public}s', `${error}`);
        }
      });
    });
    this.nativeListenerRegistry.clear();
  }

  /**
   * Lazily register the permanent native bridge for one camera-dispatcher event.
   */
  private ensureCameraDispatcherBridge(event: string): void {
    if (this.cameraBridgeEvents.has(event)) {
      return;
    }
    this.cameraBridgeEvents.add(event);
    switch (event) {
      case 'idle':
        this.nativeMapView.addOnCameraIdleListener(() => {
          this.cameraChangeDispatcher.notifyCameraIdle();
        });
        break;
      case 'moveStarted':
        this.nativeMapView.addOnCameraMoveStartedListener((reason: number) => {
          this.cameraChangeDispatcher.notifyCameraMoveStarted(reason as CameraMoveReason);
        });
        break;
      case 'move':
        this.nativeMapView.addOnCameraMoveListener(() => {
          this.cameraChangeDispatcher.notifyCameraMove();
        });
        break;
      case 'moveCanceled':
        this.nativeMapView.addOnCameraMoveCanceledListener(() => {
          this.cameraChangeDispatcher.notifyCameraMoveCanceled();
        });
        break;
      default:
        break;
    }
  }


// ========== Camera listener helpers ==========

  /**
   * Mirrors the Android MapView.addOnCameraWillChangeListener callback
   */
  public addOnCameraWillChangeListener(listener: OnCameraWillChangeListener): void {
    this.registerNativeListener<OnCameraWillChangeListener, OnCameraWillChangeListener>(
      'cameraWillChange',
      listener,
      (l) => (animated: boolean): void => {
        try {
          l(animated);
        } catch (error) {
          logListenerError('OnCameraWillChangeListener', listenerErrorMessage(error));
        }
      },
      (w) => this.nativeMapView.addOnCameraWillChangeListener(w),
      (w) => this.nativeMapView.removeOnCameraWillChangeListener(w)
    );
  }

  /**
   * Remove an on-camera-will-change listener
   */
  public removeOnCameraWillChangeListener(listener: OnCameraWillChangeListener): void {
    this.unregisterNativeListener(listener, 'cameraWillChange');
  }

  /**
   * Invoked continuously while the camera is moving
   */
  public addOnCameraIsChangingListener(listener: OnCameraIsChangingListener): void {
    this.registerNativeListener<OnCameraIsChangingListener, OnCameraIsChangingListener>(
      'cameraIsChanging',
      listener,
      (l) => (): void => {
        try {
          l();
        } catch (error) {
          logListenerError('OnCameraIsChangingListener', listenerErrorMessage(error));
        }
      },
      (w) => this.nativeMapView.addOnCameraIsChangingListener(w),
      (w) => this.nativeMapView.removeOnCameraIsChangingListener(w)
    );
  }

  /**
   * Remove an on-camera-is-changing listener
   */
  public removeOnCameraIsChangingListener(listener: OnCameraIsChangingListener): void {
    this.unregisterNativeListener(listener, 'cameraIsChanging');
  }

  /**
   * Invoked after the camera finishes changing
   */
  public addOnCameraDidChangeListener(listener: OnCameraDidChangeListener): void {
    this.registerNativeListener<OnCameraDidChangeListener, OnCameraDidChangeListener>(
      'cameraDidChange',
      listener,
      (l) => (animated: boolean): void => {
        try {
          l(animated);
        } catch (error) {
          logListenerError('OnCameraDidChangeListener', listenerErrorMessage(error));
        }
      },
      (w) => this.nativeMapView.addOnCameraDidChangeListener(w),
      (w) => this.nativeMapView.removeOnCameraDidChangeListener(w)
    );
  }

  /**
   * Remove an on-camera-did-change listener
   */
  public removeOnCameraDidChangeListener(listener: OnCameraDidChangeListener): void {
    this.unregisterNativeListener(listener, 'cameraDidChange');
  }

  /**
   * Camera dispatcher listeners: fan-out/removal is handled by CameraChangeDispatcher;
   * the native bridge is registered once per event via ensureCameraDispatcherBridge().
   */
  /**
   * Add a on camera idle listener
   */
  public addOnCameraIdleListener(listener: OnCameraIdleListener): void {
    if (this.destroyed) {
      return;
    }
    this.ensureCameraDispatcherBridge('idle');
    this.cameraChangeDispatcher.addOnCameraIdleListener(listener);
  }

  /**
   * Remove the on camera idle listener
   */
  public removeOnCameraIdleListener(listener: OnCameraIdleListener): void {
    if (this.destroyed) {
      return;
    }
    this.cameraChangeDispatcher.removeOnCameraIdleListener(listener);
  }

  /**
   * Add a on camera move started listener
   */
  public addOnCameraMoveStartedListener(listener: OnCameraMoveStartedListener): void {
    if (this.destroyed) {
      return;
    }
    this.ensureCameraDispatcherBridge('moveStarted');
    this.cameraChangeDispatcher.addOnCameraMoveStartedListener(listener);
  }

  /**
   * Remove the on camera move started listener
   */
  public removeOnCameraMoveStartedListener(listener: OnCameraMoveStartedListener): void {
    if (this.destroyed) {
      return;
    }
    this.cameraChangeDispatcher.removeOnCameraMoveStartedListener(listener);
  }

  /**
   * Add a on camera move listener
   */
  public addOnCameraMoveListener(listener: OnCameraMoveListener): void {
    if (this.destroyed) {
      return;
    }
    this.ensureCameraDispatcherBridge('move');
    this.cameraChangeDispatcher.addOnCameraMoveListener(listener);
  }

  /**
   * Remove the on camera move listener
   */
  public removeOnCameraMoveListener(listener: OnCameraMoveListener): void {
    if (this.destroyed) {
      return;
    }
    this.cameraChangeDispatcher.removeOnCameraMoveListener(listener);
  }

  /**
   * Add a on camera move canceled listener
   */
  public addOnCameraMoveCanceledListener(listener: OnCameraMoveCanceledListener): void {
    if (this.destroyed) {
      return;
    }
    this.ensureCameraDispatcherBridge('moveCanceled');
    this.cameraChangeDispatcher.addOnCameraMoveCanceledListener(listener);
  }

  /**
   * Remove the on camera move canceled listener
   */
  public removeOnCameraMoveCanceledListener(listener: OnCameraMoveCanceledListener): void {
    if (this.destroyed) {
      return;
    }
    this.cameraChangeDispatcher.removeOnCameraMoveCanceledListener(listener);
  }

// ========== Map loading listener management ==========

  /**
   * Triggered when the map starts loading (mirrors Android MapView.OnWillStartLoadingMapListener)
   */
  public addOnWillStartLoadingMapListener(listener: OnWillStartLoadingMapListener): void {
    this.registerNativeListener<OnWillStartLoadingMapListener, OnWillStartLoadingMapListener>(
      'willStartLoadingMap',
      listener,
      (l) => (): void => {
        try {
          l();
        } catch (error) {
          logListenerError('OnWillStartLoadingMapListener', listenerErrorMessage(error));
        }
      },
      (w) => this.nativeMapView.addOnWillStartLoadingMapListener(w),
      (w) => this.nativeMapView.removeOnWillStartLoadingMapListener(w)
    );
  }

  /**
   * Remove a will-start-loading-map listener
   */
  public removeOnWillStartLoadingMapListener(listener: OnWillStartLoadingMapListener): void {
    this.unregisterNativeListener(listener, 'willStartLoadingMap');
  }

  /**
   * Triggered when the map finishes loading (style and tiles loaded)
   */
  public addOnDidFinishLoadingMapListener(listener: OnDidFinishLoadingMapListener): void {
    this.registerNativeListener<OnDidFinishLoadingMapListener, OnDidFinishLoadingMapListener>(
      'didFinishLoadingMap',
      listener,
      (l) => (): void => {
        try {
          l();
        } catch (error) {
          logListenerError('OnDidFinishLoadingMapListener', listenerErrorMessage(error));
        }
      },
      (w) => this.nativeMapView.addOnDidFinishLoadingMapListener(w),
      (w) => this.nativeMapView.removeOnDidFinishLoadingMapListener(w)
    );
  }

  /**
   * Remove a did-finish-loading-map listener
   */
  public removeOnDidFinishLoadingMapListener(listener: OnDidFinishLoadingMapListener): void {
    this.unregisterNativeListener(listener, 'didFinishLoadingMap');
  }

  /**
   * Triggered when the map fails to load (network issues, style errors, etc.)
   */
  public addOnDidFailLoadingMapListener(listener: OnDidFailLoadingMapListener): void {
    this.registerNativeListener<OnDidFailLoadingMapListener, OnDidFailLoadingMapListener>(
      'didFailLoadingMap',
      listener,
      (l) => (errorMessage: string): void => {
        try {
          l(errorMessage);
        } catch (error) {
          logListenerError('OnDidFailLoadingMapListener', listenerErrorMessage(error));
        }
      },
      (w) => this.nativeMapView.addOnDidFailLoadingMapListener(w),
      (w) => this.nativeMapView.removeOnDidFailLoadingMapListener(w)
    );
  }

  /**
   * Remove a did-fail-loading-map listener
   */
  public removeOnDidFailLoadingMapListener(listener: OnDidFailLoadingMapListener): void {
    this.unregisterNativeListener(listener, 'didFailLoadingMap');
  }

  /**
   * Invoked before each frame begins rendering
   */
  public addOnWillStartRenderingFrameListener(listener: OnWillStartRenderingFrameListener): void {
    this.registerNativeListener<OnWillStartRenderingFrameListener, OnWillStartRenderingFrameListener>(
      'willStartRenderingFrame',
      listener,
      (l) => (): void => {
        try {
          l();
        } catch (error) {
          logListenerError('OnWillStartRenderingFrameListener', listenerErrorMessage(error));
        }
      },
      (w) => this.nativeMapView.addOnWillStartRenderingFrameListener(w),
      (w) => this.nativeMapView.removeOnWillStartRenderingFrameListener(w)
    );
  }

  /**
   * Remove a will-start-rendering-frame listener
   */
  public removeOnWillStartRenderingFrameListener(listener: OnWillStartRenderingFrameListener): void {
    this.unregisterNativeListener(listener, 'willStartRenderingFrame');
  }

  /**
   * Add a did-finish-rendering-frame listener (basic version)
   */
  public addOnDidFinishRenderingFrameListener(listener: OnDidFinishRenderingFrameListener): void {
    this.registerNativeListener<OnDidFinishRenderingFrameListener, OnDidFinishRenderingFrameListener>(
      'didFinishRenderingFrame',
      listener,
      (l) => (fully: boolean, frameEncodingTime: number, frameRenderingTime: number): void => {
        try {
          l(fully, frameEncodingTime, frameRenderingTime);
        } catch (error) {
          logListenerError('OnDidFinishRenderingFrameListener', listenerErrorMessage(error));
        }
      },
      (w) => this.nativeMapView.addOnDidFinishRenderingFrameListener(w),
      (w) => this.nativeMapView.removeOnDidFinishRenderingFrameListener(w)
    );
  }

  /**
   * Remove a did-finish-rendering-frame listener (basic version)
   */
  public removeOnDidFinishRenderingFrameListener(listener: OnDidFinishRenderingFrameListener): void {
    this.unregisterNativeListener(listener, 'didFinishRenderingFrame');
  }

  /**
   * Add a did-finish-rendering-frame listener (with rendering stats)
   */
  public addOnDidFinishRenderingFrameWithStatsListener(listener: OnDidFinishRenderingFrameWithStatsListener): void {
    this.registerNativeListener<OnDidFinishRenderingFrameWithStatsListener, OnDidFinishRenderingFrameWithStatsListener>(
      'didFinishRenderingFrameWithStats',
      listener,
      (l) => (stats: RenderingStats): void => {
        try {
          l(stats);
        } catch (error) {
          logListenerError('OnDidFinishRenderingFrameWithStatsListener', listenerErrorMessage(error));
        }
      },
      (w) => this.nativeMapView.addOnDidFinishRenderingFrameWithStatsListener(w),
      (w) => this.nativeMapView.removeOnDidFinishRenderingFrameWithStatsListener(w)
    );
  }

  /**
   * Remove a did-finish-rendering-frame listener (with rendering stats)
   */
  public removeOnDidFinishRenderingFrameWithStatsListener(listener: OnDidFinishRenderingFrameWithStatsListener): void {
    this.unregisterNativeListener(listener, 'didFinishRenderingFrameWithStats');
  }

  /**
   * Add a will-start-rendering-map listener
   */
  public addOnWillStartRenderingMapListener(listener: OnWillStartRenderingMapListener): void {
    this.registerNativeListener<OnWillStartRenderingMapListener, OnWillStartRenderingMapListener>(
      'willStartRenderingMap',
      listener,
      (l) => (): void => {
        try {
          l();
        } catch (error) {
          logListenerError('OnWillStartRenderingMapListener', listenerErrorMessage(error));
        }
      },
      (w) => this.nativeMapView.addOnWillStartRenderingMapListener(w),
      (w) => this.nativeMapView.removeOnWillStartRenderingMapListener(w)
    );
  }

  /**
   * Remove a will-start-rendering-map listener
   */
  public removeOnWillStartRenderingMapListener(listener: OnWillStartRenderingMapListener): void {
    this.unregisterNativeListener(listener, 'willStartRenderingMap');
  }

  /**
   * Add a did-finish-rendering-map listener
   */
  public addOnDidFinishRenderingMapListener(listener: OnDidFinishRenderingMapListener): void {
    this.registerNativeListener<OnDidFinishRenderingMapListener, OnDidFinishRenderingMapListener>(
      'didFinishRenderingMap',
      listener,
      (l) => (fully: boolean): void => {
        try {
          l(fully);
        } catch (error) {
          logListenerError('OnDidFinishRenderingMapListener', listenerErrorMessage(error));
        }
      },
      (w) => this.nativeMapView.addOnDidFinishRenderingMapListener(w),
      (w) => this.nativeMapView.removeOnDidFinishRenderingMapListener(w)
    );
  }

  /**
   * Remove a did-finish-rendering-map listener
   */
  public removeOnDidFinishRenderingMapListener(listener: OnDidFinishRenderingMapListener): void {
    this.unregisterNativeListener(listener, 'didFinishRenderingMap');
  }

  /**
   * Add a did-finish-loading-style listener (without Style object)
   */
  public addOnDidFinishLoadingStyleListener(listener: OnDidFinishLoadingStyleListener): void {
    this.registerNativeListener<OnDidFinishLoadingStyleListener, OnDidFinishLoadingStyleListener>(
      'didFinishLoadingStyle',
      listener,
      (l) => (): void => {
        try {
          l();
        } catch (error) {
          logListenerError('OnDidFinishLoadingStyleListener', listenerErrorMessage(error));
        }
      },
      (w) => this.nativeMapView.addOnDidFinishLoadingStyleListener(w),
      (w) => this.nativeMapView.removeOnDidFinishLoadingStyleListener(w)
    );
  }

  /**
   * Remove a did-finish-loading-style listener
   */
  public removeOnDidFinishLoadingStyleListener(listener: OnDidFinishLoadingStyleListener): void {
    this.unregisterNativeListener(listener, 'didFinishLoadingStyle');
  }

  /**
   * Used to control when cached style images can be released
   */
  public addOnCanRemoveUnusedStyleImageListener(listener: OnCanRemoveUnusedStyleImageListener): void {
    this.registerNativeListener<OnCanRemoveUnusedStyleImageListener, OnCanRemoveUnusedStyleImageListener>(
      'canRemoveUnusedStyleImage',
      listener,
      (l) => (id: string) => {
        try {
          return l(id);
        } catch (error) {
          logListenerError('OnCanRemoveUnusedStyleImageListener', listenerErrorMessage(error));
          return false;
        }
      },
      (w) => this.nativeMapView.addOnCanRemoveUnusedStyleImageListener(w),
      (w) => this.nativeMapView.removeOnCanRemoveUnusedStyleImageListener(w)
    );
  }

  /**
   * Remove a can-remove-unused-style-image listener
   */
  public removeOnCanRemoveUnusedStyleImageListener(listener: OnCanRemoveUnusedStyleImageListener): void {
    this.unregisterNativeListener(listener, 'canRemoveUnusedStyleImage');
  }

// ========== Map idle & data source listeners ==========

  /**
   * Triggered when the map becomes completely idle
   */
  public addOnDidBecomeIdleListener(listener: OnDidBecomeIdleListener): void {
    this.registerNativeListener<OnDidBecomeIdleListener, OnDidBecomeIdleListener>(
      'didBecomeIdle',
      listener,
      (l) => (): void => {
        try {
          l();
        } catch (error) {
          logListenerError('OnDidBecomeIdleListener', listenerErrorMessage(error));
        }
      },
      (w) => this.nativeMapView.addOnDidBecomeIdleListener(w),
      (w) => this.nativeMapView.removeOnDidBecomeIdleListener(w)
    );
  }

  /**
   * Remove a did-become-idle listener
   */
  public removeOnDidBecomeIdleListener(listener: OnDidBecomeIdleListener): void {
    this.unregisterNativeListener(listener, 'didBecomeIdle');
  }

  /**
   * Invoked when the content of a source changes
   */
  public addOnSourceChangedListener(listener: OnSourceChangedListener): void {
    this.registerNativeListener<OnSourceChangedListener, OnSourceChangedListener>(
      'sourceChanged',
      listener,
      (l) => (id: string): void => {
        try {
          l(id);
        } catch (error) {
          logListenerError('OnSourceChangedListener', listenerErrorMessage(error));
        }
      },
      (w) => this.nativeMapView.addOnSourceChangedListener(w),
      (w) => this.nativeMapView.removeOnSourceChangedListener(w)
    );
  }

  /**
   * Remove a source-changed listener
   */
  public removeOnSourceChangedListener(listener: OnSourceChangedListener): void {
    this.unregisterNativeListener(listener, 'sourceChanged');
  }

  // Plain fan-out groups for listeners dispatched by MapLibreMap itself
  // (map taps feed MarkerManager hit-testing; touch events feed marker dragging).
  private mapClickListeners: ListenerGroup<OnMapClickListener> = new ListenerGroup<OnMapClickListener>();
  private mapLongClickListeners: ListenerGroup<OnMapLongClickListener> = new ListenerGroup<OnMapLongClickListener>();

  /**
   * Add a map click listener (triggered when the user taps the map)
   */
  public addOnMapClickListener(listener: OnMapClickListener): void {
    if (this.destroyed) {
      return;
    }
    this.mapClickListeners.add(listener);
  }

  /**
   * Remove a map click listener
   */
  public removeOnMapClickListener(listener: OnMapClickListener): void {
    if (this.destroyed) {
      return;
    }
    this.mapClickListeners.remove(listener);
  }

  /**
   * Add a map long-click listener (triggered on long-press)
   */
  public addOnMapLongClickListener(listener: OnMapLongClickListener): void {
    if (this.destroyed) {
      return;
    }
    this.mapLongClickListeners.add(listener);
  }

  /**
   * Remove a map long-click listener
   */
  public removeOnMapLongClickListener(listener: OnMapLongClickListener): void {
    if (this.destroyed) {
      return;
    }
    this.mapLongClickListeners.remove(listener);
  }

  // Touch listener groups: dispatched by NativeMapView's gesture system
  private touchMoveListeners: ListenerGroup<OnTouchMoveListener> = new ListenerGroup<OnTouchMoveListener>();
  private touchUpListeners: ListenerGroup<OnTouchUpListener> = new ListenerGroup<OnTouchUpListener>();

  /**
   * Add a touch-move listener (continuous touch tracking such as marker dragging)
   */
  public addOnTouchMoveListener(listener: OnTouchMoveListener): void {
    if (this.destroyed) {
      return;
    }
    this.touchMoveListeners.add(listener);
  }

  /**
   * Remove a touch-move listener
   */
  public removeOnTouchMoveListener(listener: OnTouchMoveListener): void {
    if (this.destroyed) {
      return;
    }
    this.touchMoveListeners.remove(listener);
  }

  /**
   * Add a touch-up listener (detects touch end for flows such as completing marker drag)
   */
  public addOnTouchUpListener(listener: OnTouchUpListener): void {
    if (this.destroyed) {
      return;
    }
    this.touchUpListeners.add(listener);
  }

  /**
   * Remove a touch-up listener
   */
  public removeOnTouchUpListener(listener: OnTouchUpListener): void {
    if (this.destroyed) {
      return;
    }
    this.touchUpListeners.remove(listener);
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
    this.styleLoadedListeners.clear();
    this.styleLoadErrorListeners.clear();
    this.styleImageMissingListener = undefined;

    // Detach every wrapper-based native listener still registered
    this.clearNativeListeners();

    // Clear camera listeners via the dispatcher
    this.cameraChangeDispatcher.clearAllListeners();

    // Clear map interaction listeners
    this.mapClickListeners.clear();
    this.mapLongClickListeners.clear();
    this.touchMoveListeners.clear();
    this.touchUpListeners.clear();
    
    // Clear marker-related listeners
    this.markerManager.clearAllListeners();
    
    hilog.info(DOMAIN, 'MapLibreMap', '%{public}s', '[MapLibreMap] All listeners removed');
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

    for (const listener of this.touchMoveListeners.getListeners()) {
      try {
        if (listener.onTouchMove(x, y)) {
          return true; // Event consumed
        }
      } catch (error) {
        hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', `MapLibreMap: Error in touch move listener: ${error}`);
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

    for (const listener of this.touchUpListeners.getListeners()) {
      try {
        if (listener.onTouchUp(x, y)) {
          return true; // Event consumed
        }
      } catch (error) {
        hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', `MapLibreMap: Error in touch up listener: ${error}`);
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

    hilog.info(DOMAIN, 'MapLibreMap', '%{public}s', `[MapLibreMap] _notifyMapClick at (${x}, ${y}), listeners count: ${this.mapClickListeners.size()}`);

    // Traverse every map click listener (including those from MarkerManager)
    for (const listener of this.mapClickListeners.getListeners()) {
      try {
        hilog.info(DOMAIN, 'MapLibreMap', '%{public}s', `[MapLibreMap] Calling map click listener...`);
        if (listener.onMapClick(x, y)) {
          hilog.info(DOMAIN, 'MapLibreMap', '%{public}s', `[MapLibreMap] Event consumed by listener`);
          return true; // Event consumed
        }
      } catch (error) {
        hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', `MapLibreMap: Error in map click listener: ${error}`);
      }
    }
    hilog.info(DOMAIN, 'MapLibreMap', '%{public}s', `[MapLibreMap] No listener consumed the event`);
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
    for (const listener of this.mapLongClickListeners.getListeners()) {
      try {
        if (listener.onMapLongClick(x, y)) {
          return true; // Event consumed
        }
      } catch (error) {
        hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', `MapLibreMap: Error in map long click listener: ${error}`);
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

// ========== Marker custom views (AnnotationViewDelegate) ==========

  /**
   * Get the ViewAnnotationManager
   *
   * The single floating-layer engine: generic view annotations,
   * InfoWindows and marker custom views all render through it.
   *
   * @returns ViewAnnotationManager
   */
  public getViewAnnotationManager(): ViewAnnotationManager {
    return this.viewAnnotationManager;
  }

  /**
   * Set the ViewAnnotation render callback to sync the latest render states with the UI
   *
   * @internal Rendering-pipeline plumbing wired by NativeMapView; applications
   * should not call this — the in-map overlay is mounted automatically.
   * @param callback Callback receiving an array of ViewAnnotationRenderState
   */
  public setViewAnnotationRenderCallback(callback: ((states: ViewAnnotationRenderState[]) => void) | null): void {
    const hasCallback = callback !== null;
    this.viewAnnotationRenderCallback = callback ?? undefined;
    if (callback) {
      callback(this.viewAnnotationManager.getRenderStates());
    }
  }

  /**
   * Set the AnnotationViewDelegate
   * Customizes creation and event handling for marker custom views.
   *
   * Mirrors iOS MLNMapView.delegate
   *
   * After the delegate is set, the map invokes viewForAnnotation for every
   * marker: a config with a contentBuilder renders a marker-anchored
   * ViewAnnotation, a null result falls back to the default symbol icon.
   * Existing markers re-sync immediately.
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
   *     hilog.info(DOMAIN, 'Selected:', '%{public}s', marker.getTitle());
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
    this.markerManager.setAnnotationViewDelegate(delegate);
  }

  /**
   * Get the AnnotationViewDelegate
   * @returns AnnotationViewDelegate or null
   */
  public getAnnotationViewDelegate(): AnnotationViewDelegate | null {
    if (this.destroyed) {
      return null;
    }
    return this.markerManager.getAnnotationViewDelegate();
  }

  /**
   * Select an annotation
   *
   * Routes through the shared marker selection state (deselects the previous
   * selection) and notifies the delegate.
   *
   * @param marker Marker instance
   * @param animated Whether to animate
   */
  public selectAnnotation(marker: Marker, animated: boolean = true): void {
    if (this.destroyed) {
      return;
    }

    this.markerManager.selectMarker(marker, false);

    if (this.markerManager.getAnnotationViewDelegate()?.didSelectAnnotationView) {
      this.markerManager.getAnnotationViewDelegate()!.didSelectAnnotationView!(marker);
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

    this.markerManager.deselectMarker(marker);

    if (this.markerManager.getAnnotationViewDelegate()?.didDeselectAnnotationView) {
      this.markerManager.getAnnotationViewDelegate()!.didDeselectAnnotationView!(marker);
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

    const selected = this.markerManager.getSelectedMarkers().slice();
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
    return this.markerManager.getSelectedMarkers();
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
    return marker.isSelected();
  }

  /**
   * Get all visible annotations
   *
   * Mirrors iOS MLNMapView visibleAnnotations: markers rendering a custom
   * view annotation whose visible flag is set.
   *
   * @returns Array of markers currently visible on screen
   */
  public getVisibleAnnotations(): Marker[] {
    if (this.destroyed) {
      return [];
    }

    return this.markerManager.getCustomViewMarkers().filter(marker => marker.getVisible());
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
      hilog.warn(DOMAIN, 'MapLibreMap', '%{public}s', 'queryRenderedFeaturesForPoint: Map is destroyed');
      return [];
    }

    try {
      // Note: The renderer's internal coordinate system is in logical pixels (vp)
      // because resizeView() passes logical pixel dimensions to map.setSize().
      // So we pass logical pixel coordinates directly WITHOUT pixelRatio conversion.
      const features = this.nativeMapView.queryRenderedFeaturesForPoint(x, y, layerIds, filter);
      return features as IFeature[];
    } catch (error) {
      hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', `queryRenderedFeaturesForPoint failed: ${error.message}`);
      return [];
    }
  }

  /**
   * Query rendered features within a rectangle (direct NAPI pass-through)
   *
   * **Coordinate system**: The underlying renderer operates in logical pixels (vp) because
   * resizeView() passes logical pixel dimensions to map.setSize(). So this method accepts
   * and passes logical pixel coordinates directly to the NAPI layer WITHOUT pixelRatio conversion.
   *
   * @param left Left boundary in logical pixels
   * @param top Top boundary in logical pixels
   * @param right Right boundary in logical pixels
   * @param bottom Bottom boundary in logical pixels
   * @param layerIds Optional array of layer IDs to filter the results
   * @param filter Optional filter expression
   * @returns Array of IFeature
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
      hilog.warn(DOMAIN, 'MapLibreMap', '%{public}s', 'queryRenderedFeaturesForBoxPhysical: Map is destroyed');
      return [];
    }

    try {
      const features = this.nativeMapView.queryRenderedFeaturesForBox(
        left, top, right, bottom, layerIds, filter
      );
      return features as IFeature[];
    } catch (error) {
      hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', `queryRenderedFeaturesForBoxPhysical failed: ${error.message}`);
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
      hilog.warn(DOMAIN, 'MapLibreMap', '%{public}s', 'queryRenderedFeaturesForBox: Map is destroyed');
      return [];
    }

    try {
      // Note: The renderer's internal coordinate system is in logical pixels (vp)
      // because resizeView() passes logical pixel dimensions to map.setSize().
      // So we pass logical pixel coordinates directly WITHOUT pixelRatio conversion.
      // See HarmonyRenderer::resize() for details.
      return this.queryRenderedFeaturesForBoxPhysical(
        left, top, right, bottom, layerIds, filter
      );
    } catch (error) {
      hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', `queryRenderedFeaturesForBox failed: ${error.message}`);
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
      hilog.warn(DOMAIN, 'MapLibreMap', '%{public}s', 'querySourceFeatures: Map is destroyed');
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
      hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', `querySourceFeatures failed: ${error}`);
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

  /**
   * Set the UIContext for ComponentContent creation.
   *
   * Must be called before showing InfoWindows so that the InfoWindowManager
   * can create ComponentContent instances for rendering.
   *
   * @param uiContext The UIContext from the page/component.
   */
  public setUIContext(uiContext: UIContext): void {
    this.markerManager.setUIContext(uiContext);
  }

// ========== Performance instrumentation (mirrors Android) ==========

  /**
   * Set the FPS change listener (mirrors Android MapLibreMap.setOnFpsChangedListener)
   * Useful for monitoring rendering frame rate in real time
   * @param listener Listener instance; pass null to remove
   */
  public setOnFpsChangedListener(listener: OnFpsChangedListener | null): void {
    if (this.destroyed) {
      hilog.warn(DOMAIN, 'MapLibreMap', '%{public}s', 'setOnFpsChangedListener: Map is destroyed');
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
      hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', `setOnFpsChangedListener failed: ${error.message}`);
    }
  }

// ========== Observer event listeners (Shader, Glyph, Sprite, Tile) ==========

  /**
   * Add a pre-compile shader listener
   */
  public addOnPreCompileShaderListener(listener: OnPreCompileShaderListener): void {
    this.registerNativeListener<OnPreCompileShaderListener, OnPreCompileShaderListener>(
      'preCompileShader',
      listener,
      (l) => (shaderId: number, backendType: number, defines: string): void => {
        try {
          l(shaderId, backendType, defines);
        } catch (error) {
          logListenerError('OnPreCompileShaderListener', listenerErrorMessage(error));
        }
      },
      (w) => this.nativeMapView.addOnPreCompileShaderListener(w),
      (w) => this.nativeMapView.removeOnPreCompileShaderListener(w)
    );
  }

  /**
   * Remove a pre-compile shader listener
   */
  public removeOnPreCompileShaderListener(listener: OnPreCompileShaderListener): void {
    this.unregisterNativeListener(listener, 'preCompileShader');
  }

  /**
   * Add a post-compile shader listener
   */
  public addOnPostCompileShaderListener(listener: OnPostCompileShaderListener): void {
    this.registerNativeListener<OnPostCompileShaderListener, OnPostCompileShaderListener>(
      'postCompileShader',
      listener,
      (l) => (shaderId: number, backendType: number, defines: string): void => {
        try {
          l(shaderId, backendType, defines);
        } catch (error) {
          logListenerError('OnPostCompileShaderListener', listenerErrorMessage(error));
        }
      },
      (w) => this.nativeMapView.addOnPostCompileShaderListener(w),
      (w) => this.nativeMapView.removeOnPostCompileShaderListener(w)
    );
  }

  /**
   * Remove a post-compile shader listener
   */
  public removeOnPostCompileShaderListener(listener: OnPostCompileShaderListener): void {
    this.unregisterNativeListener(listener, 'postCompileShader');
  }

  /**
   * Add a shader compile failure listener
   */
  public addOnShaderCompileFailedListener(listener: OnShaderCompileFailedListener): void {
    this.registerNativeListener<OnShaderCompileFailedListener, OnShaderCompileFailedListener>(
      'shaderCompileFailed',
      listener,
      (l) => (shaderId: number, backendType: number, defines: string): void => {
        try {
          l(shaderId, backendType, defines);
        } catch (error) {
          logListenerError('OnShaderCompileFailedListener', listenerErrorMessage(error));
        }
      },
      (w) => this.nativeMapView.addOnShaderCompileFailedListener(w),
      (w) => this.nativeMapView.removeOnShaderCompileFailedListener(w)
    );
  }

  /**
   * Remove a shader compile failure listener
   */
  public removeOnShaderCompileFailedListener(listener: OnShaderCompileFailedListener): void {
    this.unregisterNativeListener(listener, 'shaderCompileFailed');
  }

  /**
   * Add a glyph request listener
   */
  public addOnGlyphsRequestedListener(listener: OnGlyphsRequestedListener): void {
    this.registerNativeListener<OnGlyphsRequestedListener, OnGlyphsRequestedListener>(
      'glyphsRequested',
      listener,
      (l) => (fontStack: string[], rangeStart: number, rangeEnd: number): void => {
        try {
          l(fontStack, rangeStart, rangeEnd);
        } catch (error) {
          logListenerError('OnGlyphsRequestedListener', listenerErrorMessage(error));
        }
      },
      (w) => this.nativeMapView.addOnGlyphsRequestedListener(w),
      (w) => this.nativeMapView.removeOnGlyphsRequestedListener(w)
    );
  }

  /**
   * Remove a glyph request listener
   */
  public removeOnGlyphsRequestedListener(listener: OnGlyphsRequestedListener): void {
    this.unregisterNativeListener(listener, 'glyphsRequested');
  }

  /**
   * Add a glyph loaded listener
   */
  public addOnGlyphsLoadedListener(listener: OnGlyphsLoadedListener): void {
    this.registerNativeListener<OnGlyphsLoadedListener, OnGlyphsLoadedListener>(
      'glyphsLoaded',
      listener,
      (l) => (fontStack: string[], rangeStart: number, rangeEnd: number): void => {
        try {
          l(fontStack, rangeStart, rangeEnd);
        } catch (error) {
          logListenerError('OnGlyphsLoadedListener', listenerErrorMessage(error));
        }
      },
      (w) => this.nativeMapView.addOnGlyphsLoadedListener(w),
      (w) => this.nativeMapView.removeOnGlyphsLoadedListener(w)
    );
  }

  /**
   * Remove a glyph loaded listener
   */
  public removeOnGlyphsLoadedListener(listener: OnGlyphsLoadedListener): void {
    this.unregisterNativeListener(listener, 'glyphsLoaded');
  }

  /**
   * Add a glyph error listener
   */
  public addOnGlyphsErrorListener(listener: OnGlyphsErrorListener): void {
    this.registerNativeListener<OnGlyphsErrorListener, OnGlyphsErrorListener>(
      'glyphsError',
      listener,
      (l) => (fontStack: string[], rangeStart: number, rangeEnd: number): void => {
        try {
          l(fontStack, rangeStart, rangeEnd);
        } catch (error) {
          logListenerError('OnGlyphsErrorListener', listenerErrorMessage(error));
        }
      },
      (w) => this.nativeMapView.addOnGlyphsErrorListener(w),
      (w) => this.nativeMapView.removeOnGlyphsErrorListener(w)
    );
  }

  /**
   * Remove a glyph error listener
   */
  public removeOnGlyphsErrorListener(listener: OnGlyphsErrorListener): void {
    this.unregisterNativeListener(listener, 'glyphsError');
  }

  /**
   * Add a sprite request listener
   */
  public addOnSpriteRequestedListener(listener: OnSpriteRequestedListener): void {
    this.registerNativeListener<OnSpriteRequestedListener, OnSpriteRequestedListener>(
      'spriteRequested',
      listener,
      (l) => (spriteId: string, url: string): void => {
        try {
          l(spriteId, url);
        } catch (error) {
          logListenerError('OnSpriteRequestedListener', listenerErrorMessage(error));
        }
      },
      (w) => this.nativeMapView.addOnSpriteRequestedListener(w),
      (w) => this.nativeMapView.removeOnSpriteRequestedListener(w)
    );
  }

  /**
   * Remove a sprite request listener
   */
  public removeOnSpriteRequestedListener(listener: OnSpriteRequestedListener): void {
    this.unregisterNativeListener(listener, 'spriteRequested');
  }

  /**
   * Add a sprite loaded listener
   */
  public addOnSpriteLoadedListener(listener: OnSpriteLoadedListener): void {
    this.registerNativeListener<OnSpriteLoadedListener, OnSpriteLoadedListener>(
      'spriteLoaded',
      listener,
      (l) => (spriteId: string, url: string): void => {
        try {
          l(spriteId, url);
        } catch (error) {
          logListenerError('OnSpriteLoadedListener', listenerErrorMessage(error));
        }
      },
      (w) => this.nativeMapView.addOnSpriteLoadedListener(w),
      (w) => this.nativeMapView.removeOnSpriteLoadedListener(w)
    );
  }

  /**
   * Remove a sprite loaded listener
   */
  public removeOnSpriteLoadedListener(listener: OnSpriteLoadedListener): void {
    this.unregisterNativeListener(listener, 'spriteLoaded');
  }

  /**
   * Add a sprite error listener
   */
  public addOnSpriteErrorListener(listener: OnSpriteErrorListener): void {
    this.registerNativeListener<OnSpriteErrorListener, OnSpriteErrorListener>(
      'spriteError',
      listener,
      (l) => (spriteId: string, url: string): void => {
        try {
          l(spriteId, url);
        } catch (error) {
          logListenerError('OnSpriteErrorListener', listenerErrorMessage(error));
        }
      },
      (w) => this.nativeMapView.addOnSpriteErrorListener(w),
      (w) => this.nativeMapView.removeOnSpriteErrorListener(w)
    );
  }

  /**
   * Remove a sprite error listener
   */
  public removeOnSpriteErrorListener(listener: OnSpriteErrorListener): void {
    this.unregisterNativeListener(listener, 'spriteError');
  }

  /**
   * Add a tile action listener
   */
  public addOnTileActionListener(listener: OnTileActionListener): void {
    this.registerNativeListener<OnTileActionListener, OnTileActionListener>(
      'tileAction',
      listener,
      (l) => (operation: number, x: number, y: number, z: number, wrap: number, overscaledZ: number, sourceId: string): void => {
        try {
          l(operation, x, y, z, wrap, overscaledZ, sourceId);
        } catch (error) {
          logListenerError('OnTileActionListener', listenerErrorMessage(error));
        }
      },
      (w) => this.nativeMapView.addOnTileActionListener(w),
      (w) => this.nativeMapView.removeOnTileActionListener(w)
    );
  }

  /**
   * Remove a tile action listener
   */
  public removeOnTileActionListener(listener: OnTileActionListener): void {
    this.unregisterNativeListener(listener, 'tileAction');
  }


  /**
   * Set the maximum FPS (mirrors Android MapView.setMaximumFps)
   * @param maximumFps Target frame rate, e.g., 30 or 60
   */
  public setMaximumFps(maximumFps: number): void {
    if (this.destroyed) {
      hilog.warn(DOMAIN, 'MapLibreMap', '%{public}s', 'setMaximumFps: Map is destroyed');
      return;
    }

    try {
      this.nativeMapView.setMaximumFps(maximumFps);
    } catch (error) {
      hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', `setMaximumFps failed: ${error.message}`);
    }
  }

  /**
   * Set the rendering refresh mode (mirrors Android MapView.setRenderingRefreshMode)
   * @param mode Rendering mode: CONTINUOUS or WHEN_DIRTY
   */
  public setRenderingRefreshMode(mode: RenderingRefreshMode): void {
    if (this.destroyed) {
      hilog.warn(DOMAIN, 'MapLibreMap', '%{public}s', 'setRenderingRefreshMode: Map is destroyed');
      return;
    }

    try {
      this.nativeMapView.setRenderingRefreshMode(mode);
    } catch (error) {
      hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', `setRenderingRefreshMode failed: ${error.message}`);
    }
  }

  /**
   * Get the rendering refresh mode (mirrors Android MapView.getRenderingRefreshMode)
   * @returns Current rendering mode
   */
  public getRenderingRefreshMode(): RenderingRefreshMode {
    if (this.destroyed) {
      hilog.warn(DOMAIN, 'MapLibreMap', '%{public}s', 'getRenderingRefreshMode: Map is destroyed');
      return RenderingRefreshMode.WHEN_DIRTY;
    }

    try {
      return this.nativeMapView.getRenderingRefreshMode();
    } catch (error) {
      hilog.error(DOMAIN, 'MapLibreMap', '%{public}s', `getRenderingRefreshMode failed: ${error.message}`);
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
      hilog.error(DOMAIN, 'MapLibreMap', 'Failed to get content padding: %{public}s', `${error}`);
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
   * hilog.info(DOMAIN, 'Current debug options:', '%{public}s', currentOptions);
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
   *   hilog.info(DOMAIN, 'MapLibreMap', '%{public}s', 'Debug mode is active');
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
   *   hilog.info(DOMAIN, 'MapLibreMap', '%{public}s', 'Debug visualizations are currently enabled');
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

