import maplibre, { NativeMapView as NativeMapViewNAPI } from 'libmaplibre.so';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { UIContext } from '@kit.ArkUI';
import common from '@ohos.app.ability.common';
import { DOMAIN } from '../../constants/HiLogConstants';
import { UiSettings } from '../UiSettings';
import type {
  NativeViewAnnotationAnchor,
  NativeViewAnnotationCenterOffset,
  NativeViewAnnotationFrame,
  NativeViewAnnotationOptions
} from '../annotations/NativeViewAnnotationTypes';
import { RenderingStats } from '../renderer/RenderingStats';
import { OnFpsChangedListener } from '../listeners/OnFpsChangedListener';
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
  OnMapReadyCallback,
  OnPostCompileShaderListener,
  OnPreCompileShaderListener,
  OnShaderCompileFailedListener,
  OnSourceChangedListener,
  OnSpriteErrorListener,
  OnSpriteLoadedListener,
  OnSpriteRequestedListener,
  OnStyleImageMissingListener,
  OnTileActionListener,
  OnWillStartLoadingMapListener,
  OnWillStartRenderingFrameListener,
  OnWillStartRenderingMapListener
} from '../listeners/MapEventListeners';
import { AnnotationViewData } from '../annotations/AnnotationViewManager';
import type { ViewAnnotationRenderState } from '../annotations/NativeViewAnnotationOverlay';
import { MapLibreMap } from '../MapLibreMap';
import { MapLibreMapOptions } from '../MapLibreMapOptions';
import { Marker } from '../annotations/Marker';
import { RenderingRefreshMode } from '../types/NativeTypes';
import type { MapSurfaceType } from '../types/NativeTypes';

export type {
  NativeViewAnnotationAnchor,
  NativeViewAnnotationCenterOffset,
  NativeViewAnnotationFrame,
  NativeViewAnnotationOptions
} from '../annotations/NativeViewAnnotationTypes';
// Type alias: distinguish between NAPI NativeMapView and ETS component
type NativeMapViewNapiType = NativeMapViewNAPI;

export interface NativeViewAnnotationApi {
  addViewAnnotation(options: NativeViewAnnotationOptions): number;
  updateViewAnnotation(annotationId: number, options: NativeViewAnnotationOptions): boolean;
  removeViewAnnotation(annotationId: number): boolean;
  getViewAnnotationFrames(): NativeViewAnnotationFrame[];
}

export type NativeMapView = NativeMapViewNapiType ;

// MapView component interface for type declarations (avoid circular references)
interface MapViewComponent {
  setupInfoWindowCallbacks(): void;
}

// Import camera option type from NAPI module
type CameraOptions = maplibre.CameraOptions;

type NullableNativeMapView = NativeMapView | null;

// Monotonic counter for unique XComponent IDs.
// Each MapView instance gets a unique ID so initializeNativeGestures()
// can look up its own FrameNode when multiple maps are on the same page.
let nextXComponentId: number = 1;

/**
 * Global map: NAPI NativeMapView -> ETS NativeMapViewController
 * Allows MapLibreMap to find and register with its controller
 */
const globalControllerMap: Map<NativeMapView, NativeMapViewController> = new Map();

/**
 * Register a MapLibreMap instance with its NativeMapViewController
 * Called from the MapLibreMap constructor
 *
 * @param nativeMapView NAPI NativeMapView instance
 * @param mapLibreMap MapLibreMap instance
 * @param nativeMapViewComponent Optional MapView component reference (ETS component) for InfoWindow callbacks
 */
export function registerMapLibreMap(
  nativeMapView: NativeMapView,
  mapLibreMap: MapLibreMap,
  nativeMapViewComponent?: MapViewComponent
): void {
  const controller = globalControllerMap.get(nativeMapView);
  if (controller) {
    controller.setMapLibreMapInstance(mapLibreMap);

    // Sync UiSettings: make MapLibreMap use the controller's instance
    // so runtime API calls (e.g. map.getUiSettings().setCompassEnabled())
    // affect the same instance that drives widget rendering in build().
    mapLibreMap.setUiSettings(controller.getUiSettings());

    // Wire up compass update callback
    mapLibreMap.onCompassUpdate = (bearing: number) => {
      controller.updateCompassBearing(bearing);
    };

    // Wire up scale bar update callback
    mapLibreMap.onScaleBarUpdate = (metersPerPixel: number) => {
      controller.updateScaleBarMetersPerPixel(metersPerPixel);
    };

    // Wire up pitch update callback (for build() caching, avoids NAPI calls)
    mapLibreMap.onPitchUpdate = (pitch: number) => {
      controller.cachedPitch = pitch;
    };

    // Trigger an immediate update so compass, scale bar, and pitch have correct initial values
    try {
      const bearing = mapLibreMap.getBearing();
      controller.updateCompassBearing(bearing);

      const latLng = mapLibreMap.getLatLng();
      const metersPerPixel = mapLibreMap.getMetersPerPixelAtLatitude(latLng.latitude);
      controller.updateScaleBarMetersPerPixel(metersPerPixel);
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `Failed to trigger initial widget updates: ${error}`);
    }

    // If the component reference is provided, set InfoWindow callbacks immediately
    // Otherwise they will be configured later (see aboutToAppear)
    if (nativeMapViewComponent) {
      nativeMapViewComponent.setupInfoWindowCallbacks();
    }
  } else {
    hilog.warn(DOMAIN, 'NativeMapView', 'Controller not found for MapLibreMap registration');
  }
}

/**
 * NativeMapViewController - map view controller
 */
export class NativeMapViewController extends XComponentController implements NativeViewAnnotationApi {
  private nativeMapView: NullableNativeMapView = null;
  private isInitialized: boolean = false;
  private hasTriggeredMapReady: boolean = false; // Track whether onMapReady has already fired (ensures single invocation)
  private initialCameraApplied: boolean = false;
  private surfaceId: string = '';
  private surfaceWidth: number = 0;
  private surfaceHeight: number = 0;
  private pixelRatio: number = 1.0; // Cached device pixel ratio
  private isSurfaceRectSet: boolean = false; // Prevent setXComponentSurfaceRect recursion
  // Unique XComponent ID for FrameNode lookup.
  // Generated at construction time so both build() (.id()) and
  // initializeNativeGestures() (getFrameNodeById) reference the same ID.
  private xcomponentId: string = 'maplibre_xcomponent_' + (nextXComponentId++);
  // Initial configuration
  public styleUrl: string = "https://demotiles.maplibre.org/style.json";
  public initialLatitude: number = 0;
  public initialLongitude: number = 0;
  public initialZoom: number = 6;
  public initialBearing: number = 0;
  public initialPitch: number = 0;
  // User-provided MapLibreMapOptions (passed from the component layer)
  public mapOptions: MapLibreMapOptions | undefined = undefined;
  // Render surface type ('surface' | 'texture'), mirrored from the MapView prop.
  // Informational only: surface lifecycle callbacks behave identically for both
  // XComponentType.SURFACE and XComponentType.TEXTURE.
  public surfaceType: MapSurfaceType = 'surface';
  // Callback hooks
  public onMapReadyCallback?: (mapView?: NativeMapView) => void;
  public onMapViewCreatedCallback?: (mapLibreMap: MapLibreMap) => void;
  // MapLibreMap instance reference (for InfoWindow management)
  private mapLibreMapInstance: MapLibreMap | null = null;
  // Gesture system
  private uiSettings: UiSettings = new UiSettings();
  // Gesture recognition is now handled by C++ NativeGestureManager (Phase 3)
  // UI component state hooks
  private compassBearingUpdateCallback?: (bearing: number) => void;
  private pitchUpdateCallback?: (pitch: number) => void;
  private lastCompassBearing: number = 0;
  /** Cached pitch to avoid NAPI calls during ArkUI rebuilds */
  public  cachedPitch: number = 0;
  private isDestroying: boolean = false;
  // UIContext for FrameNode lookup (used by native gesture setup and InfoWindow features)
  private uiContext?: UIContext;
  // ========== Listener management ==========
  // All listener add/remove methods are thin pass-through to the C++ CallbackManager
  // which natively supports multi-dispatch for every event type.

  // Map ready callback list (deferred callback pattern, not a listener)
  private onMapReadyCallbacks: OnMapReadyCallback[] = [];

  /**
   * Surface creation callback
   *
   * 🛡️ Fix for crash when reopening map:
   * Delay EGL initialization until page transition animation completes before setting the native window
   */
  onSurfaceCreated(surfaceId: string): void {

    hilog.warn(DOMAIN, "NativeMapView", `🌟 onSurfaceCreated START - mode: ${this.surfaceType}, surfaceId: ${surfaceId}`);
    this.isDestroying = false;
    this.surfaceId = surfaceId;

    try {
      // Acquire application context
      const context = getContext() as common.UIAbilityContext;

      // Use app private cache directory plus maplibre subfolder
      const cachePath = context.cacheDir + '/maplibre';

      // Create MapView instance with cache path
      hilog.warn(DOMAIN, "NativeMapView", `[DEBUG] Creating NativeMapView instance with cachePath...`);
      this.nativeMapView = new NativeMapViewNAPI(cachePath);
      hilog.warn(DOMAIN, "NativeMapView", `[DEBUG] NativeMapView instance created successfully`);
      this.initialCameraApplied = false;
      this.hasTriggeredMapReady = false;

      // Register into global map
      if (this.nativeMapView) {
        globalControllerMap.set(this.nativeMapView, this);
      }

      // 🛡️ Deferred initialization: wait for page transition animation (typically 400-500ms)
      // ✅ Crash fix on second entry: extend delay to 800ms ensuring native window stability
      // Reason: animations may take longer, especially on low-end devices

        try {
          if (!this.nativeMapView) {
            hilog.warn(DOMAIN, "NativeMapView", `mapView was destroyed before initialization`);
            return;
          }

          // Set rendering surface (default path; size handled in onSurfaceChanged)
          this.nativeMapView.setNativeWindow(BigInt(surfaceId));

          // Apply map style
          this.nativeMapView.setStyleUrl(this.styleUrl);

        } catch (error) {
          hilog.error(DOMAIN, "NativeMapView", `Delayed initialization failed: ${error.message}`);
        }

      this.isInitialized = true;

      // 🔧 Do not call setXComponentSurfaceRect anymore
      // Native window will use the correct size automatically
      // C++ layer derives physical pixels via pixelRatio

      // Ensure mapView initialized successfully
      if (!this.nativeMapView) {
        hilog.error(DOMAIN, 'NativeMapView', 'mapView is null after initialization');
        return;
      }

      // ========== Register internal callbacks with C++ layer ==========
      // Note: User event listeners are managed directly by C++ CallbackManager.
      // Only internal lifecycle callbacks that require complex ArkTS-side logic stay here.

      // ✅ Register map lifecycle callback
      // Fires after the C++ map object is created, before style loading
      this.nativeMapView.setOnMapViewCreatedCallback(() => {
        this.handleMapViewCreated();
      });

      // Style event listeners
      this.nativeMapView.addOnDidFinishLoadingStyleListener(() => {

        if (!this.nativeMapView) {
          hilog.warn(DOMAIN, 'NativeMapView', '⚠️ MapView is null, cannot call callbacks');
          return;
        }

        if (!this.mapLibreMapInstance && this.nativeMapView) {
          hilog.warn(
            DOMAIN,
            'NativeMapView',
            '⚠️ MapLibreMap instance missing before onMapReady, invoking handleMapViewCreated directly'
          );
          this.handleMapViewCreated();
        }

        // ========== Invoke onMapReady only on first initialization ==========
        // Mirrors Android/iOS: onMapReady fires once when the map initially loads
        // Subsequent style changes (setStyleUrl, etc.) should not retrigger onMapReady
        if (!this.hasTriggeredMapReady) {
          this.hasTriggeredMapReady = true;
          hilog.warn(DOMAIN, 'NativeMapView', '🚀 First style loaded - triggering onMapReady callbacks');

          this.applyInitialCameraIfNeeded('OnDidFinishLoadingStyle');

          // Invoke onMapReady callback
          if (this.onMapReadyCallback) {
            try {
              this.onMapReadyCallback(this.nativeMapView);
            } catch (callbackError) {
              hilog.error(DOMAIN, 'NativeMapView', `❌ onMapReady callback error: ${callbackError.message}`);
              if (callbackError.stack) {
                hilog.error(DOMAIN, 'NativeMapView', `❌ Stack: ${callbackError.stack}`);
              }
            }
          } else {
            hilog.warn(DOMAIN, 'NativeMapView', '⚠️ onMapReadyCallback is NULL, not calling');
          }

          // Invoke callbacks registered through getMapAsync
          if (this.onMapReadyCallbacks.length > 0) {
            for (const callback of this.onMapReadyCallbacks) {
              try {
                callback(this.mapLibreMapInstance);
              } catch (callbackError) {
                hilog.error(DOMAIN, 'NativeMapView', `getMapAsync callback error: ${callbackError.message}`);
              }
            }
            // Clear callback list
            this.onMapReadyCallbacks = [];
          }
        } else {
          hilog.warn(DOMAIN, 'NativeMapView', '♻️ Style reloaded - skipping onMapReady (already initialized)');
        }

        // Note: User OnDidFinishLoadingStyle listeners are now dispatched
        // directly by C++ CallbackManager. This callback handles only internal
        // onMapReady lifecycle logic.
      });

      // Note: All other event listeners (StyleImageMissing, DidBecomeIdle, SourceChanged,
      // Shader, Glyph, Sprite, Tile) are now dispatched directly by C++ CallbackManager.
      // No bridge callbacks needed here.

      // Initial pitch cache (avoid NAPI call during first build())
      this.cacheCurrentPitch();

      // ⚠️ Note: onMapReady callback moved to OnDidFinishLoadingStyleListener
      // Ensures the style is fully loaded before firing, preventing "Style not loaded" errors
      // Mirrors Android MapView.MapCallback.initialised() and iOS MLNMapView implementations
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `Failed to initialize map: ${error.message}`);
      hilog.error(DOMAIN, 'NativeMapView', `Error stack: ${error.stack}`);
    }
  }

  /**
   * Surface change callback
   */
  onSurfaceChanged(surfaceId: string, rect: SurfaceRect): void {
    console.info(`[NativeMapView] onSurfaceChanged called: ${rect.surfaceWidth}x${rect.surfaceHeight}`);

    // Guard against abnormally small sizes (potential setXComponentSurfaceRect side effect)
    if (rect.surfaceWidth < 100 || rect.surfaceHeight < 100) {
      hilog.warn(DOMAIN, 'NativeMapView',
        `onSurfaceChanged: Ignoring abnormal size ${rect.surfaceWidth}x${rect.surfaceHeight}`);
      return;
    }

    // ✅ HarmonyOS onSurfaceChanged supplies logical pixels directly
    this.surfaceWidth = rect.surfaceWidth;
    this.surfaceHeight = rect.surfaceHeight;

    if (this.nativeMapView && this.isInitialized) {
      try {
        // Update view size for both NAPI and ETS layers
        this.nativeMapView.resizeView(rect.surfaceWidth, rect.surfaceHeight);
        
        // ⚠️ Important: keep MapLibreMap view size in sync (InfoWindow, ETS features)
        const mapLibreMap = this.getMapLibreMapInstance();
        if (mapLibreMap) {
          mapLibreMap.resizeView(rect.surfaceWidth, rect.surfaceHeight);
        }

        this.updateAnnotationViews(true);
        this.applyInitialCameraIfNeeded('onSurfaceChanged-initialized');
      } catch (error) {
        const err = error as Error;
        hilog.error(DOMAIN, 'NativeMapView', `Failed to resize map: ${err.message}`);
      }
    } else if (this.nativeMapView && !this.isInitialized) {
      // If the map is not yet initialized, reinitialize with new size
      try {
        this.nativeMapView.resizeView(rect.surfaceWidth, rect.surfaceHeight);
        
        // ⚠️ Important: also set MapLibreMap view size during initialization
        const mapLibreMap = this.getMapLibreMapInstance();
        if (mapLibreMap) {
          mapLibreMap.resizeView(rect.surfaceWidth, rect.surfaceHeight);
        }
        
        this.isInitialized = true;

        this.updateAnnotationViews(true);
        this.applyInitialCameraIfNeeded('onSurfaceChanged-reinitialize');
      } catch (error) {
        const err = error as Error;
        hilog.error(DOMAIN, 'NativeMapView', `Failed to reinitialize map: ${err.message}`);
      }
    }
  }

  /**
   * Surface destruction callback
   */
  onSurfaceDestroyed(surfaceId: string): void {

    this.isDestroying = true;
    if (this.nativeMapView) {
      try {
        // Run full resource cleanup routine
        this.cleanupMapResources();
        this.nativeMapView = null;
        this.isInitialized = false;
        this.initialCameraApplied = false;
        this.hasTriggeredMapReady = false;
      } catch (error) {
        hilog.error(DOMAIN, 'NativeMapView', `Failed to destroy map: ${error.message}`);
      }
    }
  }

  /**
   * Clean up map resources
   *
   * CRITICAL: This method must cancel all pending network requests before
   * destroying the map. Failing to do so will cause SIGSEGV crashes when
   * HTTPFileSource callbacks try to access destroyed objects.
   *
   * Order of operations:
   * 1. Cancel network requests FIRST (prevents crashes)
   * 2. Clear event listeners (prevents dangling callbacks)
   * 3. Release other resources
   */
  private cleanupMapResources(): void {
    try {
      this.isDestroying = true;

      // 1. Cancel all pending network requests FIRST
      // This prevents HTTPFileSource callbacks from accessing destroyed objects
      if (this.nativeMapView) {
        try {
          this.nativeMapView.cancelAllRequests();
          hilog.info(DOMAIN, 'NativeMapView', 'cleanupMapResources: All pending requests cancelled');
        } catch (error) {
          hilog.warn(DOMAIN, 'NativeMapView', `Failed to cancel requests: ${error.message}`);
        }

        // 2. Event listeners cleared automatically by C++ CallbackManager during native map destruction
        // (No ArkTS-side listener state to clean — all managed by C++)

        // 3. Stop rendering operations
        // this.mapView.pause();

        // 4. Release OpenGL resources
        // this.mapView.cleanupGLResources();

        // 5. Clear caches
        // this.mapView.clearCache();
      }

    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `Error during map resource cleanup: ${error.message}`);
    }
  }

  /**
   * Get native map instance
   */
  getMapView(): NullableNativeMapView {
    return this.nativeMapView;
  }

  /**
   * Check whether the map is initialized
   */
  isMapInitialized(): boolean {
    return this.isInitialized && this.nativeMapView !== null;
  }

  /**
   * Clean up all resources
   */
  cleanupResources(): void {
    try {

      this.isDestroying = true;
      if (this.nativeMapView) {
        // Clean up map resources
        this.cleanupMapResources();
        this.nativeMapView = null;
      }

      this.isInitialized = false;
      this.initialCameraApplied = false;
      this.hasTriggeredMapReady = false;
      this.surfaceId = '';
      this.surfaceWidth = 0;
      this.surfaceHeight = 0;

    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapViewController', `Error during resource cleanup: ${error.message}`);
    }
  }

  unregisterFromGlobalMap(): void {
    if (this.nativeMapView) {
      globalControllerMap.delete(this.nativeMapView);
    }
  }

  /**
   * Set map style
   */
  setStyleUrl(url: string): void {
    if (this.nativeMapView && this.isInitialized) {
      try {
        this.nativeMapView.setStyleUrl(url);
      } catch (error) {
        hilog.error(DOMAIN, 'NativeMapView', `Failed to set style URL: ${error.message}`);
      }
    }
  }

  /**
   * Set map position
   */
  jumpTo(angle: number, latitude: number, longitude: number, pitch: number, zoom: number): void {
    if (this.nativeMapView && this.isInitialized) {
      try {
        this.nativeMapView.jumpTo(angle, latitude, longitude, pitch, zoom);
      } catch (error) {
        hilog.error(DOMAIN, 'NativeMapView', `Failed to jump to position: ${error.message}`);
      }
    }
  }

  private applyInitialCameraIfNeeded(context: string): void {
    if (this.initialCameraApplied) {
      return;
    }

    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(
        DOMAIN,
        'NativeMapView',
        `applyInitialCameraIfNeeded skipped (${context}) - mapView=${this.nativeMapView ? 'exists' : 'null'}, initialized=${this.isInitialized}`
      );
      return;
    }

    try {
      hilog.info(
        DOMAIN,
        'NativeMapView',
        `[${context}] Applying initial camera: lat=${this.initialLatitude}, lng=${this.initialLongitude}, zoom=${this.initialZoom}, bearing=${this.initialBearing}, pitch=${this.initialPitch}`
      );
      this.nativeMapView.jumpTo(
        this.initialBearing,
        this.initialLatitude,
        this.initialLongitude,
        this.initialPitch,
        this.initialZoom
      );
      this.initialCameraApplied = true;
    } catch (error) {
      const err = error as Error;
      hilog.error(DOMAIN, 'NativeMapView', `applyInitialCameraIfNeeded failed: ${err.message}`);
      if (err.stack) {
        hilog.error(DOMAIN, 'NativeMapView', `Stack: ${err.stack}`);
      }
    }
  }

  /**
   * Fly to a target location (flight animation)
   * @param options Camera options
   * @param duration Animation duration in milliseconds
   */
  flyTo(options: CameraOptions, duration: number): void {
    if (this.nativeMapView && this.isInitialized) {
      try {
        this.nativeMapView.flyTo(options, duration);
      } catch (error) {
        hilog.error(DOMAIN, 'NativeMapView', `Failed to fly to position: ${error.message}`);
      }
    }
  }

  /**
   * Smoothly ease to a target location
   * @param options Camera options
   * @param duration Animation duration in milliseconds
   */
  easeTo(options: CameraOptions, duration: number): void {
    if (this.nativeMapView && this.isInitialized) {
      try {
        this.nativeMapView.easeTo(options, duration);
      } catch (error) {
        hilog.error(DOMAIN, 'NativeMapView', `Failed to ease to position: ${error.message}`);
      }
    }
  }

  /**
   * Add markers
   */
  addMarkers(markers: Marker[]): number[] {
    if (this.nativeMapView && this.isInitialized) {
      try {
        const markerIds: number[] = this.nativeMapView.addMarkers(markers) as number[];
        return markerIds;
      } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error);
        hilog.error(DOMAIN, 'NativeMapView', `Failed to add markers: ${errorMsg}`);
        return [];
      }
    }
    return [];
  }

  addViewAnnotation(options: NativeViewAnnotationOptions): number {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'addViewAnnotation: map is not initialized');
      return -1;
    }

    try {
      const rawId: number | string | boolean | undefined | null = this.nativeMapView.addViewAnnotation(options);
      const id = typeof rawId === 'number' && Number.isFinite(rawId) ? rawId : -1;
      if (id > 0) {
        this.updateAnnotationViews(false);
      }
      return id;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, 'NativeMapView', `Failed to add view annotation: ${errorMsg}`);
      return -1;
    }
  }

  updateViewAnnotation(annotationId: number, options: NativeViewAnnotationOptions): boolean {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'updateViewAnnotation: map is not initialized');
      return false;
    }

    try {
      const rawResult: boolean | number | string | undefined = this.nativeMapView.updateViewAnnotation(annotationId, options);
      const updated: boolean = typeof rawResult === 'boolean' ? rawResult : false;
      if (updated) {
        this.updateAnnotationViews(false);
      }
      return updated;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, 'NativeMapView', `Failed to update view annotation: ${errorMsg}`);
      return false;
    }
  }

  removeViewAnnotation(annotationId: number): boolean {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'removeViewAnnotation: map is not initialized');
      return false;
    }

    try {
      const rawResult: boolean | number | string | undefined = this.nativeMapView.removeViewAnnotation(annotationId);
      const removed: boolean = typeof rawResult === 'boolean' ? rawResult : false;
      if (removed) {
        this.updateAnnotationViews(false);
      }
      return removed;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, 'NativeMapView', `Failed to remove view annotation: ${errorMsg}`);
      return false;
    }
  }

  getViewAnnotationFrames(): NativeViewAnnotationFrame[] {
    if (!this.nativeMapView || !this.isInitialized) {
      return [];
    }

    try {
      const rawFrames = this.nativeMapView.getViewAnnotationFrames();
      if (!Array.isArray(rawFrames)) {
        return [];
      }
      return rawFrames as NativeViewAnnotationFrame[];
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, 'NativeMapView', `Failed to get view annotation frames: ${errorMsg}`);
      return [];
    }
  }

  /**
   * Trigger a repaint
   */
  triggerRepaint(): void {
    if (this.nativeMapView && this.isInitialized) {
      try {
        this.nativeMapView.triggerRepaint();
      } catch (error) {
        hilog.error(DOMAIN, 'NativeMapView', `Failed to trigger repaint: ${error.message}`);
      }
    }
  }

  // ========== Additional helpers aligned with Android/iOS APIs ==========

  /**
   * Set content padding (Android parity)
   * @param padding Padding array [top, left, bottom, right] in logical pixels
   */
  setContentPadding(padding: number[]): void {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'setContentPadding: Map not initialized');
      return;
    }

    try {
      this.nativeMapView.setContentPadding(padding);
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `setContentPadding error: ${error.message}`);
    }
  }

  /**
   * Get content padding (Android parity)
   * @returns Padding array [top, left, bottom, right]
   */
  getContentPadding(): number[] {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'getContentPadding: Map not initialized');
      return [0, 0, 0, 0];
    }

    try {
      const padding: number[] = this.nativeMapView.getContentPadding();
      return padding as number[];
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `getContentPadding error: ${error.message}`);
      return [0, 0, 0, 0];
    }
  }

  /**
   * Get device pixel ratio (Android parity)
   * @returns Pixel ratio (e.g. 2.0, 3.0)
   */
  getPixelRatio(): number {
    if (!this.nativeMapView || !this.isInitialized) {
      return 1.0;
    }

    try {
      const ratio = this.nativeMapView.getPixelRatio() as number;
      if (typeof ratio === 'number' && Number.isFinite(ratio) && ratio > 0) {
        this.pixelRatio = ratio;
      }
      return ratio;
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `getPixelRatio error: ${error.message}`);
      return 1.0;
    }
  }

  /**
   * Get cached pixel ratio without NAPI call
   * Returns the last known value; may be slightly stale if device DPI changes at runtime
   * @returns Cached pixel ratio
   */
  getCachedPixelRatio(): number {
    return this.pixelRatio > 0 ? this.pixelRatio : this.getPixelRatio();
  }

  /**
   * Get UI settings
   */
  getUiSettings(): UiSettings {
    return this.uiSettings;
  }

  /**
   * Get gesture detector
   */
  // Phase 3: getGestureDetector() removed — gesture recognition is handled by C++

  /**
   * Set MapLibreMap instance (for InfoWindow management)
   */
  setMapLibreMapInstance(mapLibreMap: MapLibreMap): void {
    this.mapLibreMapInstance = mapLibreMap;
    // Phase 3: Gesture detection now handled by C++ NativeGestureManager — no wiring needed.
  }

  /**
   * Get MapLibreMap instance
   */
  getMapLibreMapInstance(): MapLibreMap | null {
    return this.mapLibreMapInstance;
  }

  /**
   * Get the unique XComponent ID for this map view instance.
   * Used by MapView.build() for the XComponent .id() binding, and internally
   * by initializeNativeGestures() for FrameNode lookup.
   * @returns Unique XComponent ID string
   */
  getXComponentId(): string {
    return this.xcomponentId;
  }

  /**
   * Set UIContext for FrameNode lookup and InfoWindow rendering
   */
  setUIContext(context: UIContext): void {
    this.uiContext = context;
  }

  /**
   * Initialize native gesture recognizers
   *
   * Looks up the XComponent FrameNode by ID and passes it to the C++ NativeGestureManager
   * via the setupNativeGestures NAPI method.
   */
  private initializeNativeGestures(): void {
    if (!this.nativeMapView || !this.uiContext) {
      hilog.warn(DOMAIN, 'NativeMapViewController',
        'initializeNativeGestures: map or UIContext not ready');
      return;
    }
    try {
      const frameNode = this.uiContext.getFrameNodeById(this.xcomponentId);
      if (frameNode) {
        this.nativeMapView.setupNativeGestures(frameNode);
        hilog.info(DOMAIN, 'NativeMapViewController',
          '✅ Native gesture recognizers initialized');
      } else {
        hilog.warn(DOMAIN, 'NativeMapViewController',
          '⚠️ XComponent FrameNode not found for gesture init');
      }
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapViewController',
        `❌ Failed to initialize native gestures: ${error.message}`);
    }
  }

  /**
   * Handle completion of C++ map creation
   *
   * Invoked by C++ once the map object is ready.
   * Mirrors Android behavior: create MapLibreMap before style load and trigger onMapViewCreated.
   */
  handleMapViewCreated(): void {
    try {
      // Create MapLibreMap instance (only once)
      if (!this.mapLibreMapInstance && this.nativeMapView) {
        const options = this.mapOptions ? new MapLibreMapOptions(this.mapOptions) : new MapLibreMapOptions();
        this.mapLibreMapInstance = new MapLibreMap(this.nativeMapView, options);
        hilog.info(DOMAIN, 'NativeMapViewController', '✅ MapLibreMap instance created');
        
        // ⚠️ Important: sync current view size immediately (onSurfaceChanged may fire before MapLibreMap exists)
        if (this.surfaceWidth > 0 && this.surfaceHeight > 0) {
          console.info(`[NativeMapView] Syncing view size to MapLibreMap: ${this.surfaceWidth}x${this.surfaceHeight}`);
          this.mapLibreMapInstance.resizeView(this.surfaceWidth, this.surfaceHeight);
        }
        
        // Initialize native gesture recognizers (C++ NativeGestureManager)
        this.initializeNativeGestures();

        if (this.annotationViewUpdateCallback) {
          const annotationViewManager = this.mapLibreMapInstance.getMarkerManager().getAnnotationViewManager();
          annotationViewManager.setOnViewsUpdateCallback(this.annotationViewUpdateCallback);
        }

        if (this.viewAnnotationRenderCallback) {
          this.mapLibreMapInstance.setViewAnnotationRenderCallback(this.viewAnnotationRenderCallback);
        } else {
          this.mapLibreMapInstance.setViewAnnotationRenderCallback(null);
        }
        
        // Trigger user onMapViewCreated callback
        if (this.onMapViewCreatedCallback) {
          hilog.info(DOMAIN, 'NativeMapViewController', '📢 Calling user onMapViewCreated callback');
          this.onMapViewCreatedCallback(this.mapLibreMapInstance);
        } else {
          hilog.warn(DOMAIN, 'NativeMapViewController', '⚠️ No onMapViewCreatedCallback registered');
        }
      } else if (this.mapLibreMapInstance) {
        hilog.warn(DOMAIN, 'NativeMapViewController', 
          '⚠️ MapLibreMap already created, skipping duplicate creation');
      } else {
        hilog.error(DOMAIN, 'NativeMapViewController', 
          '❌ Cannot create MapLibreMap: mapView is null');
      }
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapViewController', 
        `❌ Error in handleMapViewCreated: ${error.message}`);
      if (error.stack) {
        hilog.error(DOMAIN, 'NativeMapViewController', `Stack: ${error.stack}`);
      }
    }
  }

  /**
   * Set compass bearing update callback
   */
  setCompassBearingUpdateCallback(callback: (bearing: number) => void): void {
    this.compassBearingUpdateCallback = callback;
  }

  /**
   * Set pitch update callback (used by NativeMapView to cache pitch for build())
   */
  setPitchUpdateCallback(callback: (pitch: number) => void): void {
    this.pitchUpdateCallback = callback;
  }

  /**
   * Get cached pitch value (avoids NAPI call during ArkUI rebuilds)
   */
  getCachedPitch(): number {
    return this.cachedPitch;
  }

  // Scale bar update callback
  private scaleBarMetersPerPixelUpdateCallback?: (metersPerPixel: number) => void;

  /**
   * Set scale bar meters-per-pixel update callback
   */
  setScaleBarMetersPerPixelUpdateCallback(callback: (metersPerPixel: number) => void): void {
    this.scaleBarMetersPerPixelUpdateCallback = callback;
  }

  /**
   * Update scale bar meters-per-pixel
   */
  updateScaleBarMetersPerPixel(metersPerPixel: number): void {
    if (this.scaleBarMetersPerPixelUpdateCallback) {
      this.scaleBarMetersPerPixelUpdateCallback(metersPerPixel);
    }
  }

  /**
   * Update compass bearing
   */
  updateCompassBearing(bearing: number): void {
    if (this.isDestroying) {
      return;
    }

    if (!this.compassBearingUpdateCallback) {
      return;
    }

    let resolvedBearing: number | undefined;

    if (typeof bearing === 'number' && Number.isFinite(bearing)) {
      this.lastCompassBearing = bearing;
      resolvedBearing = bearing;
    } else if (Number.isFinite(this.lastCompassBearing)) {
      resolvedBearing = this.lastCompassBearing;
    }

    if (resolvedBearing === undefined && this.nativeMapView && this.isInitialized) {
      try {
        const nativeBearing: number = this.nativeMapView.getBearing();
        if (Number.isFinite(nativeBearing)) {
          this.lastCompassBearing = nativeBearing;
          resolvedBearing = nativeBearing;
        }
      } catch (error) {
        hilog.error(DOMAIN, 'NativeMapView', `Failed to query compass bearing: ${error}`);
        return;
      }
    }

    if (resolvedBearing !== undefined) {
      this.compassBearingUpdateCallback(resolvedBearing);
    }
  }

  /**
   * Cache current pitch from native map view
   * Called on camera move to avoid NAPI calls during build() re-execution
   */
  private cacheCurrentPitch(): void {
    if (!this.nativeMapView || !this.isInitialized) {
      return;
    }

    try {
      const pitch: number = this.nativeMapView.getPitch();
      if (typeof pitch === 'number' && Number.isFinite(pitch)) {
        this.cachedPitch = pitch;
        if (this.pitchUpdateCallback) {
          this.pitchUpdateCallback(pitch);
        }
      }
    } catch (error) {
      // Silently fail — cached pitch will be stale but won't crash
    }
  }

  /**
   * AnnotationView update callback
   */
  private annotationViewUpdateCallback?: (views: AnnotationViewData[]) => void;
  private viewAnnotationRenderCallback?: (states: ViewAnnotationRenderState[]) => void;

  /**
   * Set AnnotationView update callback
   */
  setAnnotationViewUpdateCallback(callback: (views: AnnotationViewData[]) => void): void {
    this.annotationViewUpdateCallback = callback;
    if (this.mapLibreMapInstance) {
      const manager = this.mapLibreMapInstance.getMarkerManager().getAnnotationViewManager();
      manager.setOnViewsUpdateCallback(callback);
    }
  }

  setViewAnnotationRenderCallback(callback: (states: ViewAnnotationRenderState[]) => void): void {
    console.info('[NativeMapViewController] setViewAnnotationRenderCallback: register callback');
    this.viewAnnotationRenderCallback = callback;
    if (this.mapLibreMapInstance) {
      console.info('[NativeMapViewController] setViewAnnotationRenderCallback: forwarding to MapLibreMap');
      this.mapLibreMapInstance.setViewAnnotationRenderCallback(callback);
    }
  }

  clearViewAnnotationRenderCallback(): void {
    console.info('[NativeMapViewController] clearViewAnnotationRenderCallback: clear callback');
    this.viewAnnotationRenderCallback = undefined;
    if (this.mapLibreMapInstance) {
      console.info('[NativeMapViewController] clearViewAnnotationRenderCallback: forwarding clear to MapLibreMap');
      this.mapLibreMapInstance.setViewAnnotationRenderCallback(null);
    }
  }

  /**
   * Update AnnotationView positions
   */
  updateAnnotationViews(recalculate: boolean = true): void {
    if (this.mapLibreMapInstance && this.annotationViewUpdateCallback) {
      try {
        const annotationViewManager = this.mapLibreMapInstance.getMarkerManager().getAnnotationViewManager();
        const frames = this.getViewAnnotationFrames();
        if (frames.length > 0) {
          annotationViewManager.applyNativeFrames(frames);
        } else if (recalculate) {
          annotationViewManager.batchUpdatePositions(true);
        }
        const views = annotationViewManager.getAllViews();
        this.annotationViewUpdateCallback(views);
      } catch (error) {
        hilog.error(DOMAIN, 'NativeMapView', `Failed to update annotation views: ${error}`);
      }
    }
  }

  /**
   * Reset to north (compass tap handling)
   */
  resetNorth(): void {
    if (this.nativeMapView && this.isInitialized) {
      try {
        // Animate back to north (mirrors Android TIME_MAP_NORTH_ANIMATION = 150ms)
        this.nativeMapView.setBearing(0, 150);
      } catch (error) {
        hilog.error(DOMAIN, 'NativeMapView', `Failed to reset north: ${error}`);
      }
    }
  }

  /**
   * Get view width
   */
  getWidth(): number {
    return this.surfaceWidth;
  }

  /**
   * Get view height
   */
  getHeight(): number {
    return this.surfaceHeight;
  }

  /**
   * Get pitch
   */
  getPitch(): number {
    if (this.nativeMapView && this.isInitialized) {
      try {
        const pitch: number = this.nativeMapView.getPitch();
        return pitch !== undefined ? pitch : 0;
      } catch (error) {
        hilog.error(DOMAIN, 'NativeMapView', `Failed to get pitch: ${error}`);
        return 0;
      }
    }
    return 0;
  }

  // ========== Listener registration and removal ==========
  // All listener management is delegated to C++ CallbackManager which natively
  // supports multi-dispatch and identity-based removal for every event type.
  //
  // These thin pass-through methods preserve API compatibility with existing
  // callers (MapLibreMap, MapView component, external users).

  // ===== Camera listeners =====

  addOnCameraWillChangeListener(listener: OnCameraWillChangeListener): void {
    this.nativeMapView?.addOnCameraWillChangeListener(listener);
  }
  removeOnCameraWillChangeListener(listener: OnCameraWillChangeListener): void {
    this.nativeMapView?.removeOnCameraWillChangeListener(listener);
  }

  addOnCameraIsChangingListener(listener: OnCameraIsChangingListener): void {
    this.nativeMapView?.addOnCameraIsChangingListener(listener);
  }
  removeOnCameraIsChangingListener(listener: OnCameraIsChangingListener): void {
    this.nativeMapView?.removeOnCameraIsChangingListener(listener);
  }

  addOnCameraDidChangeListener(listener: OnCameraDidChangeListener): void {
    this.nativeMapView?.addOnCameraDidChangeListener(listener);
  }
  removeOnCameraDidChangeListener(listener: OnCameraDidChangeListener): void {
    this.nativeMapView?.removeOnCameraDidChangeListener(listener);
  }

  // ===== Map loading listeners =====

  addOnWillStartLoadingMapListener(listener: OnWillStartLoadingMapListener): void {
    this.nativeMapView?.addOnWillStartLoadingMapListener(listener);
  }
  removeOnWillStartLoadingMapListener(listener: OnWillStartLoadingMapListener): void {
    this.nativeMapView?.removeOnWillStartLoadingMapListener(listener);
  }

  addOnDidFinishLoadingMapListener(listener: OnDidFinishLoadingMapListener): void {
    this.nativeMapView?.addOnDidFinishLoadingMapListener(listener);
  }
  removeOnDidFinishLoadingMapListener(listener: OnDidFinishLoadingMapListener): void {
    this.nativeMapView?.removeOnDidFinishLoadingMapListener(listener);
  }

  addOnDidFailLoadingMapListener(listener: OnDidFailLoadingMapListener): void {
    this.nativeMapView?.addOnDidFailLoadingMapListener(listener);
  }
  removeOnDidFailLoadingMapListener(listener: OnDidFailLoadingMapListener): void {
    this.nativeMapView?.removeOnDidFailLoadingMapListener(listener);
  }

  // ===== Rendering listeners =====

  addOnWillStartRenderingFrameListener(listener: OnWillStartRenderingFrameListener): void {
    this.nativeMapView?.addOnWillStartRenderingFrameListener(listener);
  }
  removeOnWillStartRenderingFrameListener(listener: OnWillStartRenderingFrameListener): void {
    this.nativeMapView?.removeOnWillStartRenderingFrameListener(listener);
  }

  addOnDidFinishRenderingFrameListener(listener: OnDidFinishRenderingFrameListener): void {
    this.nativeMapView?.addOnDidFinishRenderingFrameListener(listener);
  }
  removeOnDidFinishRenderingFrameListener(listener: OnDidFinishRenderingFrameListener): void {
    this.nativeMapView?.removeOnDidFinishRenderingFrameListener(listener);
  }

  addOnDidFinishRenderingFrameWithStatsListener(listener: OnDidFinishRenderingFrameWithStatsListener): void {
    this.nativeMapView?.addOnDidFinishRenderingFrameWithStatsListener(listener);
  }
  removeOnDidFinishRenderingFrameWithStatsListener(listener: OnDidFinishRenderingFrameWithStatsListener): void {
    this.nativeMapView?.removeOnDidFinishRenderingFrameWithStatsListener(listener);
  }

  addOnWillStartRenderingMapListener(listener: OnWillStartRenderingMapListener): void {
    this.nativeMapView?.addOnWillStartRenderingMapListener(listener);
  }
  removeOnWillStartRenderingMapListener(listener: OnWillStartRenderingMapListener): void {
    this.nativeMapView?.removeOnWillStartRenderingMapListener(listener);
  }

  addOnDidFinishRenderingMapListener(listener: OnDidFinishRenderingMapListener): void {
    this.nativeMapView?.addOnDidFinishRenderingMapListener(listener);
  }
  removeOnDidFinishRenderingMapListener(listener: OnDidFinishRenderingMapListener): void {
    this.nativeMapView?.removeOnDidFinishRenderingMapListener(listener);
  }

  // ===== Style listeners =====

  addOnDidFinishLoadingStyleListener(listener: OnDidFinishLoadingStyleListener): void {
    this.nativeMapView?.addOnDidFinishLoadingStyleListener(listener);
  }
  removeOnDidFinishLoadingStyleListener(listener: OnDidFinishLoadingStyleListener): void {
    this.nativeMapView?.removeOnDidFinishLoadingStyleListener(listener);
  }

  addOnStyleImageMissingListener(listener: OnStyleImageMissingListener): void {
    this.nativeMapView?.addOnStyleImageMissingListener(listener);
  }
  removeOnStyleImageMissingListener(listener: OnStyleImageMissingListener): void {
    this.nativeMapView?.removeOnStyleImageMissingListener(listener);
  }

  addOnCanRemoveUnusedStyleImageListener(listener: OnCanRemoveUnusedStyleImageListener): void {
    this.nativeMapView?.addOnCanRemoveUnusedStyleImageListener(listener);
  }
  removeOnCanRemoveUnusedStyleImageListener(listener: OnCanRemoveUnusedStyleImageListener): void {
    this.nativeMapView?.removeOnCanRemoveUnusedStyleImageListener(listener);
  }

  // ===== Miscellaneous listeners =====

  addOnDidBecomeIdleListener(listener: OnDidBecomeIdleListener): void {
    this.nativeMapView?.addOnDidBecomeIdleListener(listener);
  }
  removeOnDidBecomeIdleListener(listener: OnDidBecomeIdleListener): void {
    this.nativeMapView?.removeOnDidBecomeIdleListener(listener);
  }

  addOnSourceChangedListener(listener: OnSourceChangedListener): void {
    this.nativeMapView?.addOnSourceChangedListener(listener);
  }
  removeOnSourceChangedListener(listener: OnSourceChangedListener): void {
    this.nativeMapView?.removeOnSourceChangedListener(listener);
  }

  // ===== Shader listeners =====

  addOnPreCompileShaderListener(listener: OnPreCompileShaderListener): void {
    this.nativeMapView?.addOnPreCompileShaderListener(listener);
  }
  removeOnPreCompileShaderListener(listener: OnPreCompileShaderListener): void {
    this.nativeMapView?.removeOnPreCompileShaderListener(listener);
  }

  addOnPostCompileShaderListener(listener: OnPostCompileShaderListener): void {
    this.nativeMapView?.addOnPostCompileShaderListener(listener);
  }
  removeOnPostCompileShaderListener(listener: OnPostCompileShaderListener): void {
    this.nativeMapView?.removeOnPostCompileShaderListener(listener);
  }

  addOnShaderCompileFailedListener(listener: OnShaderCompileFailedListener): void {
    this.nativeMapView?.addOnShaderCompileFailedListener(listener);
  }
  removeOnShaderCompileFailedListener(listener: OnShaderCompileFailedListener): void {
    this.nativeMapView?.removeOnShaderCompileFailedListener(listener);
  }

  // ===== Glyph listeners =====

  addOnGlyphsLoadedListener(listener: OnGlyphsLoadedListener): void {
    this.nativeMapView?.addOnGlyphsLoadedListener(listener);
  }
  removeOnGlyphsLoadedListener(listener: OnGlyphsLoadedListener): void {
    this.nativeMapView?.removeOnGlyphsLoadedListener(listener);
  }

  addOnGlyphsErrorListener(listener: OnGlyphsErrorListener): void {
    this.nativeMapView?.addOnGlyphsErrorListener(listener);
  }
  removeOnGlyphsErrorListener(listener: OnGlyphsErrorListener): void {
    this.nativeMapView?.removeOnGlyphsErrorListener(listener);
  }

  addOnGlyphsRequestedListener(listener: OnGlyphsRequestedListener): void {
    this.nativeMapView?.addOnGlyphsRequestedListener(listener);
  }
  removeOnGlyphsRequestedListener(listener: OnGlyphsRequestedListener): void {
    this.nativeMapView?.removeOnGlyphsRequestedListener(listener);
  }

  // ===== Sprite listeners =====

  addOnSpriteLoadedListener(listener: OnSpriteLoadedListener): void {
    this.nativeMapView?.addOnSpriteLoadedListener(listener);
  }
  removeOnSpriteLoadedListener(listener: OnSpriteLoadedListener): void {
    this.nativeMapView?.removeOnSpriteLoadedListener(listener);
  }

  addOnSpriteErrorListener(listener: OnSpriteErrorListener): void {
    this.nativeMapView?.addOnSpriteErrorListener(listener);
  }
  removeOnSpriteErrorListener(listener: OnSpriteErrorListener): void {
    this.nativeMapView?.removeOnSpriteErrorListener(listener);
  }

  addOnSpriteRequestedListener(listener: OnSpriteRequestedListener): void {
    this.nativeMapView?.addOnSpriteRequestedListener(listener);
  }
  removeOnSpriteRequestedListener(listener: OnSpriteRequestedListener): void {
    this.nativeMapView?.removeOnSpriteRequestedListener(listener);
  }

  // ===== Tile action listeners =====

  addOnTileActionListener(listener: OnTileActionListener): void {
    this.nativeMapView?.addOnTileActionListener(listener);
  }
  removeOnTileActionListener(listener: OnTileActionListener): void {
    this.nativeMapView?.removeOnTileActionListener(listener);
  }


  /**
   * Acquire map asynchronously (mirrors Android getMapAsync)
   * @param callback Map ready callback
   */
  getMapAsync(callback: OnMapReadyCallback): void {
    if (this.nativeMapView && this.isInitialized) {
      // Map already ready, invoke immediately
      try {
        callback(this.mapLibreMapInstance);
      } catch (error) {
        hilog.error(DOMAIN, 'NativeMapView', `getMapAsync callback error: ${error.message}`);
      }
    } else {
      // Map not ready yet, queue callback
      this.onMapReadyCallbacks.push(callback);
    }
  }

  // ========== Rendering control ==========

  /**
   * Queue a task on the rendering thread (Android queueEvent parity)
   * @param runnable Task to execute
   */
  queueEvent(runnable: () => void): void {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'queueEvent: Map not initialized');
      return;
    }

    // Execute task via rendering thread queue
    // Use setTimeout(0) to run on next event loop tick
    // Avoids modifying state during active rendering
    setTimeout(() => {
      try {
        runnable();
        // Trigger repaint after task completes
        this.triggerRepaint();
      } catch (error) {
        hilog.error(DOMAIN, 'NativeMapView', `queueEvent error: ${error.message}`);
      }
    }, 0);
  }

  /**
   * Set maximum FPS (Android setMaximumFps parity)
   * @param maximumFps Target FPS
   */
  setMaximumFps(maximumFps: number): void {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'setMaximumFps: Map not initialized');
      return;
    }

    try {
      this.nativeMapView.setMaximumFps(maximumFps);
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `setMaximumFps error: ${error.message}`);
    }
  }

  /**
   * Set rendering refresh mode (Android setRenderingRefreshMode parity)
   * @param mode Rendering mode
   */
  setRenderingRefreshMode(mode: RenderingRefreshMode): void {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'setRenderingRefreshMode: Map not initialized');
      return;
    }

    try {
      this.nativeMapView.setRenderingRefreshMode(mode);
      const modeName = mode === RenderingRefreshMode.CONTINUOUS ? 'CONTINUOUS' : 'WHEN_DIRTY';
      hilog.info(DOMAIN, 'NativeMapView', `setRenderingRefreshMode: Set to ${modeName}`);
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `setRenderingRefreshMode error: ${error.message}`);
    }
  }

  /**
   * Get rendering refresh mode (Android getRenderingRefreshMode parity)
   * @returns Current rendering mode
   */
  getRenderingRefreshMode(): RenderingRefreshMode {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'getRenderingRefreshMode: Map not initialized, returning default');
      return RenderingRefreshMode.WHEN_DIRTY;
    }

    try {
      return this.nativeMapView.getRenderingRefreshMode();
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `getRenderingRefreshMode error: ${error.message}`);
      return RenderingRefreshMode.WHEN_DIRTY;
    }
  }

  /**
   * Set FPS change listener (mirrors Android MapView.setOnFpsChangedListener)
   * @param listener Listener instance; pass null to remove
   */
  setOnFpsChangedListener(listener: OnFpsChangedListener | null): void {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'setOnFpsChangedListener: Map not initialized');
      return;
    }

    try {
      if (listener === null) {
        this.nativeMapView.setOnFpsChangedListener(null);
        hilog.info(DOMAIN, 'NativeMapView', 'setOnFpsChangedListener: Listener removed');
      } else {
        this.nativeMapView.setOnFpsChangedListener((fps: number) => {
          listener.onFpsChanged(fps);
        });
        hilog.info(DOMAIN, 'NativeMapView', 'setOnFpsChangedListener: Listener set');
      }
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `setOnFpsChangedListener error: ${error.message}`);
    }
  }

  // ========== Performance and cache configuration ==========

  /**
   * Enable or disable tile prefetching (Android prefetchesTiles parity)
   * @param enabled Whether prefetching is enabled
   */
  setPrefetchesTiles(enabled: boolean): void {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'setPrefetchesTiles: Map not initialized');
      return;
    }

    try {
      this.nativeMapView.setPrefetchTiles(enabled);
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `setPrefetchesTiles error: ${error.message}`);
    }
  }

  /**
   * Enable or disable tile cache (Android tileCacheEnabled parity)
   * @param enabled Whether caching is enabled
   */
  setTileCacheEnabled(enabled: boolean): void {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'setTileCacheEnabled: Map not initialized');
      return;
    }

    try {
      this.nativeMapView.setTileCacheEnabled(enabled);
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `setTileCacheEnabled error: ${error.message}`);
    }
  }

  /**
   * Set LOD minimum radius (iOS tileLodMinRadius parity)
   * @param radius Minimum radius in tile units
   */
  setTileLodMinRadius(radius: number): void {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'setTileLodMinRadius: Map not initialized');
      return;
    }

    try {
      this.nativeMapView.setTileLodMinRadius(radius);
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `setTileLodMinRadius error: ${error.message}`);
    }
  }

  /**
   * Set LOD scale factor (iOS tileLodScale parity)
  * @param scale Scale factor
   */
  setTileLodScale(scale: number): void {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'setTileLodScale: Map not initialized');
      return;
    }

    try {
      this.nativeMapView.setTileLodScale(scale);
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `setTileLodScale error: ${error.message}`);
    }
  }

  /**
   * Set LOD pitch threshold (iOS tileLodPitchThreshold parity)
   * @param threshold Pitch threshold in radians
   */
  setTileLodPitchThreshold(threshold: number): void {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'setTileLodPitchThreshold: Map not initialized');
      return;
    }

    try {
      this.nativeMapView.setTileLodPitchThreshold(threshold);
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `setTileLodPitchThreshold error: ${error.message}`);
    }
  }

  /**
   * Set LOD zoom shift (iOS tileLodZoomShift parity)
   * @param shift Zoom shift
   */
  setTileLodZoomShift(shift: number): void {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'setTileLodZoomShift: Map not initialized');
      return;
    }

    try {
      this.nativeMapView.setTileLodZoomShift(shift);
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `setTileLodZoomShift error: ${error.message}`);
    }
  }

  // ========== Prefetch tile getters ==========

  /**
   * Check whether tile prefetching is enabled
   * @returns true if prefetching is enabled
   */
  getPrefetchTiles(): boolean {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'getPrefetchTiles: Map not initialized');
      return false;
    }
    try {
      return this.nativeMapView.getPrefetchTiles();
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `getPrefetchTiles error: ${error.message}`);
      return false;
    }
  }

  /**
   * Get the current prefetch zoom delta
   * @returns Prefetch zoom delta value
   */
  getPrefetchZoomDelta(): number {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'getPrefetchZoomDelta: Map not initialized');
      return 0;
    }
    try {
      return this.nativeMapView.getPrefetchZoomDelta();
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `getPrefetchZoomDelta error: ${error.message}`);
      return 0;
    }
  }

  /**
   * Set prefetch zoom delta directly
   * @param delta Prefetch zoom delta (0 disables)
   */
  setPrefetchZoomDelta(delta: number): void {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'setPrefetchZoomDelta: Map not initialized');
      return;
    }
    try {
      this.nativeMapView.setPrefetchZoomDelta(delta);
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `setPrefetchZoomDelta error: ${error.message}`);
    }
  }

  // ========== Tile LOD getters ==========

  /**
   * Get the minimum LOD radius
   * @returns Minimum radius in tile units
   */
  getTileLodMinRadius(): number {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'getTileLodMinRadius: Map not initialized');
      return 0;
    }
    try {
      return this.nativeMapView.getTileLodMinRadius();
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `getTileLodMinRadius error: ${error.message}`);
      return 0;
    }
  }

  /**
   * Get the LOD scale factor
   * @returns Scale factor
   */
  getTileLodScale(): number {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'getTileLodScale: Map not initialized');
      return 1.0;
    }
    try {
      return this.nativeMapView.getTileLodScale();
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `getTileLodScale error: ${error.message}`);
      return 1.0;
    }
  }

  /**
   * Get the LOD pitch threshold
   * @returns Pitch threshold in radians
   */
  getTileLodPitchThreshold(): number {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'getTileLodPitchThreshold: Map not initialized');
      return 0;
    }
    try {
      return this.nativeMapView.getTileLodPitchThreshold();
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `getTileLodPitchThreshold error: ${error.message}`);
      return 0;
    }
  }

  /**
   * Get the LOD zoom shift
   * @returns Zoom shift value
   */
  getTileLodZoomShift(): number {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'getTileLodZoomShift: Map not initialized');
      return 0;
    }
    try {
      return this.nativeMapView.getTileLodZoomShift();
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `getTileLodZoomShift error: ${error.message}`);
      return 0;
    }
  }

  // ========== Rendering stats ==========

  /**
   * Check whether rendering stats view is enabled
   * @returns true if rendering stats view is enabled
   */
  isRenderingStatsViewEnabled(): boolean {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'isRenderingStatsViewEnabled: Map not initialized');
      return false;
    }
    try {
      return this.nativeMapView.isRenderingStatsViewEnabled();
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `isRenderingStatsViewEnabled error: ${error.message}`);
      return false;
    }
  }

  /**
   * Enable or disable rendering stats view
   * @param enabled Whether rendering stats should be displayed
   */
  enableRenderingStatsView(enabled: boolean): void {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'enableRenderingStatsView: Map not initialized');
      return;
    }
    try {
      this.nativeMapView.enableRenderingStatsView(enabled);
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `enableRenderingStatsView error: ${error.message}`);
    }
  }

  // ========== Action journal ==========

  /**
   * Get action journal log file paths
   * @returns Array of log file paths
   */
  getActionJournalLogFiles(): string[] {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'getActionJournalLogFiles: Map not initialized');
      return [];
    }
    try {
      return this.nativeMapView.getActionJournalLogFiles();
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `getActionJournalLogFiles error: ${error.message}`);
      return [];
    }
  }

  /**
   * Get action journal log entries as JSON strings
   * @returns Array of JSON log entries
   */
  getActionJournalLog(): string[] {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'getActionJournalLog: Map not initialized');
      return [];
    }
    try {
      return this.nativeMapView.getActionJournalLog();
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `getActionJournalLog error: ${error.message}`);
      return [];
    }
  }

  /**
   * Clear the action journal log
   */
  clearActionJournalLog(): void {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'clearActionJournalLog: Map not initialized');
      return;
    }
    try {
      this.nativeMapView.clearActionJournalLog();
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `clearActionJournalLog error: ${error.message}`);
    }
  }

  // ========== Map load status ==========

  /**
   * Check whether the map is fully loaded
   * @returns true if the map is fully loaded
   */
  isFullyLoaded(): boolean {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'isFullyLoaded: Map not initialized');
      return false;
    }
    try {
      return this.nativeMapView.isFullyLoaded();
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `isFullyLoaded error: ${error.message}`);
      return false;
    }
  }

  // ========== Debug options ==========

  /**
   * Get current debug options as a bitmask
   * @returns Bitmask of enabled debug options
   */
  getDebug(): number {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'getDebug: Map not initialized');
      return 0;
    }
    try {
      return this.nativeMapView.getDebug();
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `getDebug error: ${error.message}`);
      return 0;
    }
  }

  /**
   * Get a description of the active rendering backend and GPU.
   * The backend is decided at compile time (MLN_WITH_OPENGL / MLN_WITH_VULKAN);
   * this reports which one this build uses, e.g. "vulkan | Mali-G78".
   * @returns Backend and device info string
   */
  getRendererInfo(): string {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'getRendererInfo: Map not initialized');
      return 'uninitialized';
    }
    try {
      return this.nativeMapView.getRendererInfo();
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `getRendererInfo error: ${error.message}`);
      return 'unknown';
    }
  }

  /**
   * Set debug options using a bitmask
   * @param debugOptions Bitmask of debug options
   */
  setDebug(debugOptions: number): void {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'setDebug: Map not initialized');
      return;
    }
    try {
      this.nativeMapView.setDebug(debugOptions);
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `setDebug error: ${error.message}`);
    }
  }

  /**
   * Handle low memory warning (Android onLowMemory parity)
   */
  onLowMemory(): void {
    if (!this.nativeMapView || !this.isInitialized) {
      return;
    }

    try {
      this.nativeMapView.onLowMemory();
      hilog.warn(DOMAIN, 'NativeMapView', 'onLowMemory: Low memory warning sent to C++ layer');
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `onLowMemory error: ${error.message}`);
    }
  }
}

/**
 * NativeMapView - map view component
 */