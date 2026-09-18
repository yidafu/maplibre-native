import maplibre, { NativeMapView as NativeMapViewNAPI } from 'libmaplibre.so';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { UIContext } from '@kit.ArkUI';
import common from '@ohos.app.ability.common';
import { DOMAIN } from '../../constants/HiLogConstants';
import { safePixelRatio } from '../common/MapUtils';
import { UiSettings } from '../UiSettings';
import type {
  NativeViewAnnotationAnchor,
  NativeViewAnnotationCenterOffset,
  NativeViewAnnotationFrame,
  NativeViewAnnotationOptions
} from '../annotations/NativeViewAnnotationTypes';
import { RenderingStats } from '../renderer/RenderingStats';
import { OnFpsChangedListener } from '../listeners/OnFpsChangedListener';
// 只保留本类真正使用的两个类型：监听器注册已交由 MapView 直连原生 view，
// 原先为 26 个 addOn*/removeOn* 转发桩而导入的监听器类型已全部不再引用。
import {
  OnDidFinishLoadingStyleListener,
  OnMapReadyCallback
} from '../listeners/MapEventListeners';
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
type NativeMapView = NativeMapViewNAPI;

// Default style applied when the component's styleUrl prop is not provided.
// Must stay in sync with the @Prop defaults in MapView / TextureMapView.
export const DEFAULT_STYLE_URL = 'https://demotiles.maplibre.org/style.json';

export interface NativeViewAnnotationApi {
  addViewAnnotation(options: NativeViewAnnotationOptions): number;
  updateViewAnnotation(annotationId: number, options: NativeViewAnnotationOptions): boolean;
  removeViewAnnotation(annotationId: number): boolean;
  getViewAnnotationFrames(): NativeViewAnnotationFrame[];
}

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
  public styleUrl: string = DEFAULT_STYLE_URL;
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
  // Labels whose "map not initialized" warning was already emitted (warn once
  // per call site to keep logs low-frequency when APIs are polled before init).
  private warnedNativeLabels: Set<string> = new Set<string>();

  /**
   * Guarded NAPI call helper.
   *
   * Collapses the recurring
   * `if (!nativeMapView || !isInitialized) { warn; return fallback }`
   * `try { return nativeMapView.X() } catch { error; return fallback }`
   * boilerplate. The "not initialized" warning is emitted at most once per
   * label (call site) — repeated invocations before initialization stay silent.
   *
   * @param label Call-site identifier used for logging.
   * @param fallback Value returned when the map is not ready or the call throws.
   * @param op Operation to run against the native map view.
   * @returns Operation result, or `fallback`.
   */
  private withNative<T>(label: string, fallback: T, op: (mapView: NativeMapView) => T): T {
    if (!this.nativeMapView || !this.isInitialized) {
      if (!this.warnedNativeLabels.has(label)) {
        this.warnedNativeLabels.add(label);
        hilog.warn(DOMAIN, 'NativeMapView', `${label}: Map not initialized`);
      }
      return fallback;
    }
    try {
      return op(this.nativeMapView);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, 'NativeMapView', `${label} error: ${errorMsg}`);
      return fallback;
    }
  }

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
    hilog.info(DOMAIN, 'NativeMapViewController', '%{public}s', `[NativeMapView] onSurfaceChanged called: ${rect.surfaceWidth}x${rect.surfaceHeight}`);

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
    this.withNative<void>('setStyleUrl', undefined, (mapView) => {
      mapView.setStyleUrl(url);
    });
  }

  /**
   * Set map position
   */
  jumpTo(angle: number, latitude: number, longitude: number, pitch: number, zoom: number): void {
    this.withNative<void>('jumpTo', undefined, (mapView) => {
      mapView.jumpTo(angle, latitude, longitude, pitch, zoom);
    });
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
    this.withNative<void>('flyTo', undefined, (mapView) => {
      mapView.flyTo(options, duration);
    });
  }

  /**
   * Smoothly ease to a target location
   * @param options Camera options
   * @param duration Animation duration in milliseconds
   */
  easeTo(options: CameraOptions, duration: number): void {
    this.withNative<void>('easeTo', undefined, (mapView) => {
      mapView.easeTo(options, duration);
    });
  }

  /**
   * Add markers
   */
  addMarkers(markers: Marker[]): number[] {
    return this.withNative<number[]>('addMarkers', [], (mapView) => {
      const markerIds: number[] = mapView.addMarkers(markers) as number[];
      return markerIds;
    });
  }

  addViewAnnotation(options: NativeViewAnnotationOptions): number {
    return this.withNative<number>('addViewAnnotation', -1, (mapView) => {
      const rawId: number | string | boolean | undefined | null = mapView.addViewAnnotation(options);
      return typeof rawId === 'number' && Number.isFinite(rawId) ? rawId : -1;
    });
  }

  updateViewAnnotation(annotationId: number, options: NativeViewAnnotationOptions): boolean {
    return this.withNative<boolean>('updateViewAnnotation', false, (mapView) => {
      const rawResult: boolean | number | string | undefined = mapView.updateViewAnnotation(annotationId, options);
      return typeof rawResult === 'boolean' ? rawResult : false;
    });
  }

  removeViewAnnotation(annotationId: number): boolean {
    return this.withNative<boolean>('removeViewAnnotation', false, (mapView) => {
      const rawResult: boolean | number | string | undefined = mapView.removeViewAnnotation(annotationId);
      return typeof rawResult === 'boolean' ? rawResult : false;
    });
  }

  getViewAnnotationFrames(): NativeViewAnnotationFrame[] {
    return this.withNative<NativeViewAnnotationFrame[]>('getViewAnnotationFrames', [], (mapView) => {
      const rawFrames = mapView.getViewAnnotationFrames();
      return Array.isArray(rawFrames) ? rawFrames as NativeViewAnnotationFrame[] : [];
    });
  }

  /**
   * Trigger a repaint
   */
  triggerRepaint(): void {
    this.withNative<void>('triggerRepaint', undefined, (mapView) => {
      mapView.triggerRepaint();
    });
  }

  // ========== Additional helpers aligned with Android/iOS APIs ==========

  /**
   * Set content padding (Android parity)
   * @param padding Padding array [top, left, bottom, right] in logical pixels
   */
  setContentPadding(padding: number[]): void {
    this.withNative<void>('setContentPadding', undefined, (mapView) => {
      mapView.setContentPadding(padding);
    });
  }

  /**
   * Get content padding (Android parity)
   * @returns Padding array [top, left, bottom, right]
   */
  getContentPadding(): number[] {
    return this.withNative<number[]>('getContentPadding', [0, 0, 0, 0], (mapView) => {
      const padding: number[] = mapView.getContentPadding();
      return padding as number[];
    });
  }

  /**
   * Get device pixel ratio (Android parity)
   * @returns Pixel ratio (e.g. 2.0, 3.0)
   */
  getPixelRatio(): number {
    return this.withNative<number>('getPixelRatio', 1.0, (mapView) => {
      const ratio = safePixelRatio(mapView, 'NativeMapViewController.getPixelRatio');
      if (ratio > 0) {
        this.pixelRatio = ratio;
      }
      return ratio;
    });
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
          hilog.info(DOMAIN, 'NativeMapViewController', '%{public}s', `[NativeMapView] Syncing view size to MapLibreMap: ${this.surfaceWidth}x${this.surfaceHeight}`);
          this.mapLibreMapInstance.resizeView(this.surfaceWidth, this.surfaceHeight);
        }
        
        // Initialize native gesture recognizers (C++ NativeGestureManager)
        this.initializeNativeGestures();

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

  private viewAnnotationRenderCallback?: (states: ViewAnnotationRenderState[]) => void;

  setViewAnnotationRenderCallback(callback: (states: ViewAnnotationRenderState[]) => void): void {
    hilog.info(DOMAIN, 'NativeMapViewController', '%{public}s', '[NativeMapViewController] setViewAnnotationRenderCallback: register callback');
    this.viewAnnotationRenderCallback = callback;
    if (this.mapLibreMapInstance) {
      hilog.info(DOMAIN, 'NativeMapViewController', '%{public}s', '[NativeMapViewController] setViewAnnotationRenderCallback: forwarding to MapLibreMap');
      this.mapLibreMapInstance.setViewAnnotationRenderCallback(callback);
    }
  }

  clearViewAnnotationRenderCallback(): void {
    hilog.info(DOMAIN, 'NativeMapViewController', '%{public}s', '[NativeMapViewController] clearViewAnnotationRenderCallback: clear callback');
    this.viewAnnotationRenderCallback = undefined;
    if (this.mapLibreMapInstance) {
      hilog.info(DOMAIN, 'NativeMapViewController', '%{public}s', '[NativeMapViewController] clearViewAnnotationRenderCallback: forwarding clear to MapLibreMap');
      this.mapLibreMapInstance.setViewAnnotationRenderCallback(null);
    }
  }

  /**
   * Reset to north (compass tap handling)
   */
  resetNorth(): void {
    // Animate back to north (mirrors Android TIME_MAP_NORTH_ANIMATION = 150ms)
    this.withNative<void>('resetNorth', undefined, (mapView) => {
      mapView.setBearing(0, 150);
    });
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
    return this.withNative<number>('getPitch', 0, (mapView) => {
      const pitch: number = mapView.getPitch();
      return pitch !== undefined ? pitch : 0;
    });
  }

  // ========== Listener registration ==========
  // 监听器由 MapView 组件直接绑定到原生 map view（见 NativeMapView.ets）。
  // controller 只负责原生 view 的生命周期，不再镜像一整套 addOn*/removeOn* 转发桩
  // —— 原先 MapView -> controller -> nativeMapView 的两跳里，中间那跳是纯噪声。
  // 需要原生 view 时通过 getMapView() 获取。


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
   * Queue a task to run on the next UI event loop tick (Android queueEvent parity).
   * Note: unlike Android, the task runs on the UI thread — not the render thread.
   * @param runnable Task to execute
   */
  queueEvent(runnable: () => void): void {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'queueEvent: Map not initialized');
      return;
    }

    // setTimeout(0) defers to the next event loop tick, avoiding state
    // mutation while a render pass is in flight on the UI thread.
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
    this.withNative<void>('setMaximumFps', undefined, (mapView) => {
      mapView.setMaximumFps(maximumFps);
    });
  }

  /**
   * Set rendering refresh mode (Android setRenderingRefreshMode parity)
   * @param mode Rendering mode
   */
  setRenderingRefreshMode(mode: RenderingRefreshMode): void {
    this.withNative<void>('setRenderingRefreshMode', undefined, (mapView) => {
      mapView.setRenderingRefreshMode(mode);
      const modeName = mode === RenderingRefreshMode.CONTINUOUS ? 'CONTINUOUS' : 'WHEN_DIRTY';
      hilog.info(DOMAIN, 'NativeMapView', `setRenderingRefreshMode: Set to ${modeName}`);
    });
  }

  /**
   * Get rendering refresh mode (Android getRenderingRefreshMode parity)
   * @returns Current rendering mode
   */
  getRenderingRefreshMode(): RenderingRefreshMode {
    return this.withNative<RenderingRefreshMode>('getRenderingRefreshMode', RenderingRefreshMode.WHEN_DIRTY, (mapView) => {
      return mapView.getRenderingRefreshMode();
    });
  }

  /**
   * Set FPS change listener (mirrors Android MapView.setOnFpsChangedListener)
   * @param listener Listener instance; pass null to remove
   */
  setOnFpsChangedListener(listener: OnFpsChangedListener | null): void {
    this.withNative<void>('setOnFpsChangedListener', undefined, (mapView) => {
      if (listener === null) {
        mapView.setOnFpsChangedListener(null);
        hilog.info(DOMAIN, 'NativeMapView', 'setOnFpsChangedListener: Listener removed');
      } else {
        mapView.setOnFpsChangedListener((fps: number) => {
          listener.onFpsChanged(fps);
        });
        hilog.info(DOMAIN, 'NativeMapView', 'setOnFpsChangedListener: Listener set');
      }
    });
  }

  // ========== Performance and cache configuration ==========

  /**
   * Enable or disable tile prefetching (Android prefetchesTiles parity)
   * @param enabled Whether prefetching is enabled
   */
  setPrefetchesTiles(enabled: boolean): void {
    this.withNative<void>('setPrefetchesTiles', undefined, (mapView) => {
      mapView.setPrefetchTiles(enabled);
    });
  }

  /**
   * Enable or disable tile cache (Android tileCacheEnabled parity)
   * @param enabled Whether caching is enabled
   */
  setTileCacheEnabled(enabled: boolean): void {
    this.withNative<void>('setTileCacheEnabled', undefined, (mapView) => {
      mapView.setTileCacheEnabled(enabled);
    });
  }

  /**
   * Set LOD minimum radius (iOS tileLodMinRadius parity)
   * @param radius Minimum radius in tile units
   */
  setTileLodMinRadius(radius: number): void {
    this.withNative<void>('setTileLodMinRadius', undefined, (mapView) => {
      mapView.setTileLodMinRadius(radius);
    });
  }

  /**
   * Set LOD scale factor (iOS tileLodScale parity)
  * @param scale Scale factor
   */
  setTileLodScale(scale: number): void {
    this.withNative<void>('setTileLodScale', undefined, (mapView) => {
      mapView.setTileLodScale(scale);
    });
  }

  /**
   * Set LOD pitch threshold (iOS tileLodPitchThreshold parity)
   * @param threshold Pitch threshold in radians
   */
  setTileLodPitchThreshold(threshold: number): void {
    this.withNative<void>('setTileLodPitchThreshold', undefined, (mapView) => {
      mapView.setTileLodPitchThreshold(threshold);
    });
  }

  /**
   * Set LOD zoom shift (iOS tileLodZoomShift parity)
   * @param shift Zoom shift
   */
  setTileLodZoomShift(shift: number): void {
    this.withNative<void>('setTileLodZoomShift', undefined, (mapView) => {
      mapView.setTileLodZoomShift(shift);
    });
  }

  // ========== Prefetch tile getters ==========

  /**
   * Check whether tile prefetching is enabled
   * @returns true if prefetching is enabled
   */
  getPrefetchTiles(): boolean {
    return this.withNative<boolean>('getPrefetchTiles', false, (mapView) => {
      return mapView.getPrefetchTiles();
    });
  }

  /**
   * Get the current prefetch zoom delta
   * @returns Prefetch zoom delta value
   */
  getPrefetchZoomDelta(): number {
    return this.withNative<number>('getPrefetchZoomDelta', 0, (mapView) => {
      return mapView.getPrefetchZoomDelta();
    });
  }

  /**
   * Set prefetch zoom delta directly
   * @param delta Prefetch zoom delta (0 disables)
   */
  setPrefetchZoomDelta(delta: number): void {
    this.withNative<void>('setPrefetchZoomDelta', undefined, (mapView) => {
      mapView.setPrefetchZoomDelta(delta);
    });
  }

  // ========== Tile LOD getters ==========

  /**
   * Get the minimum LOD radius
   * @returns Minimum radius in tile units
   */
  getTileLodMinRadius(): number {
    return this.withNative<number>('getTileLodMinRadius', 0, (mapView) => {
      return mapView.getTileLodMinRadius();
    });
  }

  /**
   * Get the LOD scale factor
   * @returns Scale factor
   */
  getTileLodScale(): number {
    return this.withNative<number>('getTileLodScale', 1.0, (mapView) => {
      return mapView.getTileLodScale();
    });
  }

  /**
   * Get the LOD pitch threshold
   * @returns Pitch threshold in radians
   */
  getTileLodPitchThreshold(): number {
    return this.withNative<number>('getTileLodPitchThreshold', 0, (mapView) => {
      return mapView.getTileLodPitchThreshold();
    });
  }

  /**
   * Get the LOD zoom shift
   * @returns Zoom shift value
   */
  getTileLodZoomShift(): number {
    return this.withNative<number>('getTileLodZoomShift', 0, (mapView) => {
      return mapView.getTileLodZoomShift();
    });
  }

  // ========== Rendering stats ==========

  /**
   * Check whether rendering stats view is enabled
   * @returns true if rendering stats view is enabled
   */
  isRenderingStatsViewEnabled(): boolean {
    return this.withNative<boolean>('isRenderingStatsViewEnabled', false, (mapView) => {
      return mapView.isRenderingStatsViewEnabled();
    });
  }

  /**
   * Enable or disable rendering stats view
   * @param enabled Whether rendering stats should be displayed
   */
  enableRenderingStatsView(enabled: boolean): void {
    this.withNative<void>('enableRenderingStatsView', undefined, (mapView) => {
      mapView.enableRenderingStatsView(enabled);
    });
  }

  // ========== Action journal ==========

  /**
   * Get action journal log file paths
   * @returns Array of log file paths
   */
  getActionJournalLogFiles(): string[] {
    return this.withNative<string[]>('getActionJournalLogFiles', [], (mapView) => {
      return mapView.getActionJournalLogFiles();
    });
  }

  /**
   * Get action journal log entries as JSON strings
   * @returns Array of JSON log entries
   */
  getActionJournalLog(): string[] {
    return this.withNative<string[]>('getActionJournalLog', [], (mapView) => {
      return mapView.getActionJournalLog();
    });
  }

  /**
   * Clear the action journal log
   */
  clearActionJournalLog(): void {
    this.withNative<void>('clearActionJournalLog', undefined, (mapView) => {
      mapView.clearActionJournalLog();
    });
  }

  // ========== Map load status ==========

  /**
   * Check whether the map is fully loaded
   * @returns true if the map is fully loaded
   */
  isFullyLoaded(): boolean {
    return this.withNative<boolean>('isFullyLoaded', false, (mapView) => {
      return mapView.isFullyLoaded();
    });
  }

  // ========== Debug options ==========

  /**
   * Get current debug options as a bitmask
   * @returns Bitmask of enabled debug options
   */
  getDebug(): number {
    return this.withNative<number>('getDebug', 0, (mapView) => {
      return mapView.getDebug();
    });
  }

  /**
   * Get a description of the active rendering backend and GPU.
   * The backend is decided at compile time (MLN_WITH_OPENGL / MLN_WITH_VULKAN);
   * this reports which one this build uses, e.g. "vulkan | Mali-G78".
   * @returns Backend and device info string, 'uninitialized' when not ready.
   */
  getRendererInfo(): string {
    return this.withNative<string>('getRendererInfo', 'uninitialized', (mapView) => {
      return mapView.getRendererInfo();
    });
  }

  /**
   * Set debug options using a bitmask
   * @param debugOptions Bitmask of debug options
   */
  setDebug(debugOptions: number): void {
    this.withNative<void>('setDebug', undefined, (mapView) => {
      mapView.setDebug(debugOptions);
    });
  }

  /**
   * Toggle debug mode quickly (uses the default option set)
   * @param active Whether to enable debug mode
   */
  setDebugActive(active: boolean): void {
    this.withNative<void>('setDebugActive', undefined, (mapView) => {
      mapView.setDebugActive(active);
    });
  }

  /**
   * Check whether debug mode is active
   * @returns True if any debug options are enabled
   */
  isDebugActive(): boolean {
    return this.withNative<boolean>('isDebugActive', false, (mapView) => {
      return mapView.isDebugActive();
    });
  }

  /**
   * Handle low memory warning (Android onLowMemory parity)
   */
  onLowMemory(): void {
    this.withNative<void>('onLowMemory', undefined, (mapView) => {
      mapView.onLowMemory();
      hilog.warn(DOMAIN, 'NativeMapView', 'onLowMemory: Low memory warning sent to C++ layer');
    });
  }
}

/**
 * NativeMapView - map view component
 */