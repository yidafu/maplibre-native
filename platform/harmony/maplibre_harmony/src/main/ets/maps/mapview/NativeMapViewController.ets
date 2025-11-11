import maplibre, { NativeMapView as NativeMapViewNAPI } from 'libmaplibre.so';
import { hilog } from '@kit.PerformanceAnalysisKit';
import common from '@ohos.app.ability.common';
import { DOMAIN } from '../../constants/HiLogConstants';
import { MapGestureDetector } from '../gestures/MapGestureDetector';
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

    // Wire up compass update callback
    mapLibreMap.onCompassUpdate = (bearing: number) => {
      controller.updateCompassBearing();
    };

    // Wire up scale bar update callback
    mapLibreMap.onScaleBarUpdate = (metersPerPixel: number) => {
      controller.updateScaleBarMetersPerPixel(metersPerPixel);
    };

    // Trigger an immediate update so compass and scale bar have correct initial values
    try {
      const bearing = mapLibreMap.getBearing();
      controller.updateCompassBearing();

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
  // Initial configuration
  public styleUrl: string = "https://demotiles.maplibre.org/style.json";
  public initialLatitude: number = 0;
  public initialLongitude: number = 0;
  public initialZoom: number = 6;
  public initialBearing: number = 0;
  public initialPitch: number = 0;
  // Callback hooks
  public onMapReadyCallback?: (mapView?: NativeMapView) => void;
  public onMapViewCreatedCallback?: (mapLibreMap: MapLibreMap) => void;
  // MapLibreMap instance reference (for InfoWindow management)
  private mapLibreMapInstance: MapLibreMap | null = null;
  // Gesture system
  private uiSettings: UiSettings = new UiSettings();
  private gestureDetector: MapGestureDetector = new MapGestureDetector(this.uiSettings);
  // UI component state hooks
  private compassBearingUpdateCallback?: (bearing: number) => void;
  private uiSettingsUpdateCallback?: () => void;
  // ========== Listener management ==========

  // Camera event listeners
  private onCameraWillChangeListeners: OnCameraWillChangeListener[] = [];
  private onCameraIsChangingListeners: OnCameraIsChangingListener[] = [];
  private onCameraDidChangeListeners: OnCameraDidChangeListener[] = [];
  // Map loading event listeners
  private onWillStartLoadingMapListeners: OnWillStartLoadingMapListener[] = [];
  private onDidFinishLoadingMapListeners: OnDidFinishLoadingMapListener[] = [];
  private onDidFailLoadingMapListeners: OnDidFailLoadingMapListener[] = [];
  // Rendering event listeners
  private onWillStartRenderingFrameListeners: OnWillStartRenderingFrameListener[] = [];
  private onDidFinishRenderingFrameListeners: OnDidFinishRenderingFrameListener[] = [];
  private onDidFinishRenderingFrameWithStatsListeners: OnDidFinishRenderingFrameWithStatsListener[] = [];
  private onWillStartRenderingMapListeners: OnWillStartRenderingMapListener[] = [];
  private onDidFinishRenderingMapListeners: OnDidFinishRenderingMapListener[] = [];
  // Style event listeners
  private onDidFinishLoadingStyleListeners: OnDidFinishLoadingStyleListener[] = [];
  private onStyleImageMissingListeners: OnStyleImageMissingListener[] = [];
  private onCanRemoveUnusedStyleImageListeners: OnCanRemoveUnusedStyleImageListener[] = [];
  // Other event listeners
  private onDidBecomeIdleListeners: OnDidBecomeIdleListener[] = [];
  private onSourceChangedListeners: OnSourceChangedListener[] = [];
  private onPreCompileShaderListeners: OnPreCompileShaderListener[] = [];
  private onPostCompileShaderListeners: OnPostCompileShaderListener[] = [];
  private onShaderCompileFailedListeners: OnShaderCompileFailedListener[] = [];
  private onGlyphsLoadedListeners: OnGlyphsLoadedListener[] = [];
  private onGlyphsErrorListeners: OnGlyphsErrorListener[] = [];
  private onGlyphsRequestedListeners: OnGlyphsRequestedListener[] = [];
  private onTileActionListeners: OnTileActionListener[] = [];
  private onSpriteLoadedListeners: OnSpriteLoadedListener[] = [];
  private onSpriteErrorListeners: OnSpriteErrorListener[] = [];
  private onSpriteRequestedListeners: OnSpriteRequestedListener[] = [];
  // Map ready callback list
  private onMapReadyCallbacks: OnMapReadyCallback[] = [];

  /**
   * Surface creation callback
   *
   * 🛡️ Fix for crash when reopening map:
   * Delay EGL initialization until page transition animation completes before setting the native window
   */
  onSurfaceCreated(surfaceId: string): void {

    hilog.warn(DOMAIN, "NativeMapView", `🌟 onSurfaceCreated START - surfaceId: ${surfaceId}`);
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

      // Provide map controller reference to gesture detector
      this.gestureDetector.setMapController(this.nativeMapView);

      // Register camera listener to update compass and annotation views
      this.nativeMapView.addOnCameraMoveListener(() => {
        this.updateCompassBearing();
        this.updateAnnotationViews();
      });

      // ========== Register Android/iOS-style callbacks with C++ layer ==========

      // ✅ Register map lifecycle callback
      // Fires after the C++ map object is created, before style loading
      this.nativeMapView.setOnMapViewCreatedCallback(() => {
        this.handleMapViewCreated();
      });

      // Camera event listeners
      this.nativeMapView.addOnCameraWillChangeListener((animated: boolean) => {
        for (const listener of this.onCameraWillChangeListeners) {
          try {
            listener(animated);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnCameraWillChangeListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnCameraIsChangingListener(() => {
        for (const listener of this.onCameraIsChangingListeners) {
          try {
            listener();
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnCameraIsChangingListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnCameraDidChangeListener((animated: boolean) => {
        for (const listener of this.onCameraDidChangeListeners) {
          try {
            listener(animated);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnCameraDidChangeListener error: ${error.message}`);
          }
        }
      });

      // Map loading event listeners
      this.nativeMapView.addOnWillStartLoadingMapListener(() => {
        for (const listener of this.onWillStartLoadingMapListeners) {
          try {
            listener();
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnWillStartLoadingMapListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnDidFinishLoadingMapListener(() => {
        for (const listener of this.onDidFinishLoadingMapListeners) {
          try {
            listener();
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnDidFinishLoadingMapListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnDidFailLoadingMapListener((errorMessage: string) => {
        for (const listener of this.onDidFailLoadingMapListeners) {
          try {
            listener(errorMessage);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnDidFailLoadingMapListener error: ${error.message}`);
          }
        }
      });

      // Rendering event listeners
      this.nativeMapView.addOnWillStartRenderingFrameListener(() => {
        for (const listener of this.onWillStartRenderingFrameListeners) {
          try {
            listener();
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnWillStartRenderingFrameListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnDidFinishRenderingFrameListener((fully: boolean, frameEncodingTime: number,
        frameRenderingTime: number) => {
        // Notify simple listener variant
        for (const listener of this.onDidFinishRenderingFrameListeners) {
          try {
            listener(fully, frameEncodingTime, frameRenderingTime);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnDidFinishRenderingFrameListener error: ${error.message}`);
          }
        }
        // Notify listener variant with rendering statistics
        const stats: RenderingStats = {
          fully, frameEncodingTime, frameRenderingTime
        };
        for (const listener of this.onDidFinishRenderingFrameWithStatsListeners) {
          try {
            listener(fully, stats);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnDidFinishRenderingFrameWithStatsListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnWillStartRenderingMapListener(() => {
        for (const listener of this.onWillStartRenderingMapListeners) {
          try {
            listener();
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnWillStartRenderingMapListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnDidFinishRenderingMapListener((fully: boolean) => {
        for (const listener of this.onDidFinishRenderingMapListeners) {
          try {
            listener(fully);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnDidFinishRenderingMapListener error: ${error.message}`);
          }
        }
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

        // ========== Notify style listeners on every style load ==========
        // Inform user-supplied OnDidFinishLoadingStyleListener handlers
        for (const listener of this.onDidFinishLoadingStyleListeners) {
          try {
            listener();
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnDidFinishLoadingStyleListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnStyleImageMissingListener((id: string) => {
        for (const listener of this.onStyleImageMissingListeners) {
          try {
            listener(id);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnStyleImageMissingListener error: ${error.message}`);
          }
        }
      });

      // Additional event listeners
      this.nativeMapView.addOnDidBecomeIdleListener(() => {
        for (const listener of this.onDidBecomeIdleListeners) {
          try {
            listener();
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnDidBecomeIdleListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnSourceChangedListener((id: string) => {
        for (const listener of this.onSourceChangedListeners) {
          try {
            listener(id);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnSourceChangedListener error: ${error.message}`);
          }
        }
      });

      // ========== Observer listeners (Shader, Glyph, Sprite, Tile) ==========
      
      // Shader compile listeners
      this.nativeMapView.addOnPreCompileShaderListener((shaderId: number, backendType: number, defines: string) => {
        for (const listener of this.onPreCompileShaderListeners) {
          try {
            listener(shaderId, backendType, defines);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnPreCompileShaderListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnPostCompileShaderListener((shaderId: number, backendType: number, defines: string) => {
        for (const listener of this.onPostCompileShaderListeners) {
          try {
            listener(shaderId, backendType, defines);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnPostCompileShaderListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnShaderCompileFailedListener((shaderId: number, backendType: number, defines: string) => {
        for (const listener of this.onShaderCompileFailedListeners) {
          try {
            listener(shaderId, backendType, defines);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnShaderCompileFailedListener error: ${error.message}`);
          }
        }
      });

      // Glyph listeners
      this.nativeMapView.addOnGlyphsLoadedListener((fontStack: string[], rangeStart: number, rangeEnd: number) => {
        for (const listener of this.onGlyphsLoadedListeners) {
          try {
            listener(fontStack, rangeStart, rangeEnd);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnGlyphsLoadedListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnGlyphsErrorListener((fontStack: string[], rangeStart: number, rangeEnd: number) => {
        for (const listener of this.onGlyphsErrorListeners) {
          try {
            listener(fontStack, rangeStart, rangeEnd);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnGlyphsErrorListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnGlyphsRequestedListener((fontStack: string[], rangeStart: number, rangeEnd: number) => {
        for (const listener of this.onGlyphsRequestedListeners) {
          try {
            listener(fontStack, rangeStart, rangeEnd);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnGlyphsRequestedListener error: ${error.message}`);
          }
        }
      });

      // Sprite listeners
      this.nativeMapView.addOnSpriteLoadedListener((spriteId: string, url: string) => {
        for (const listener of this.onSpriteLoadedListeners) {
          try {
            listener(spriteId, url);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnSpriteLoadedListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnSpriteErrorListener((spriteId: string, url: string) => {
        for (const listener of this.onSpriteErrorListeners) {
          try {
            listener(spriteId, url);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnSpriteErrorListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnSpriteRequestedListener((spriteId: string, url: string) => {
        for (const listener of this.onSpriteRequestedListeners) {
          try {
            listener(spriteId, url);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnSpriteRequestedListener error: ${error.message}`);
          }
        }
      });

      // Tile action listeners
      this.nativeMapView.addOnTileActionListener((operation: number, x: number, y: number, z: number, wrap: number, overscaledZ: number, sourceId: string) => {
        for (const listener of this.onTileActionListeners) {
          try {
            listener(operation, x, y, z, wrap, overscaledZ, sourceId);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnTileActionListener error: ${error.message}`);
          }
        }
      });

      // Perform initial compass update
      this.updateCompassBearing();

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
   */
  private cleanupMapResources(): void {
    try {

      // 1. Stop rendering operations
      if (this.nativeMapView) {
        // Pause rendering
        // this.mapView.pause();

        // 2. Release OpenGL resources
        // this.mapView.cleanupGLResources();

        // 3. Cancel network requests
        // this.mapView.cancelAllRequests();

        // 4. Clear caches
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
      hilog.warn(DOMAIN, 'NativeMapView', 'getPixelRatio: Map not initialized');
      return 1.0;
    }

    try {
      return this.nativeMapView.getPixelRatio() as number;
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `getPixelRatio error: ${error.message}`);
      return 1.0;
    }
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
  getGestureDetector(): MapGestureDetector {
    return this.gestureDetector;
  }

  /**
   * Set MapLibreMap instance (for InfoWindow management)
   */
  setMapLibreMapInstance(mapLibreMap: MapLibreMap): void {
    this.mapLibreMapInstance = mapLibreMap;

    // Bridge gesture detector to MapLibreMap (mirrors Android MapGestureDetector wiring)
    this.gestureDetector.setMapLibreMapInstance(mapLibreMap);
  }

  /**
   * Get MapLibreMap instance
   */
  getMapLibreMapInstance(): MapLibreMap | null {
    return this.mapLibreMapInstance;
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
        const options = new MapLibreMapOptions();
        this.mapLibreMapInstance = new MapLibreMap(this.nativeMapView, options);
        hilog.info(DOMAIN, 'NativeMapViewController', '✅ MapLibreMap instance created');
        
        // ⚠️ Important: sync current view size immediately (onSurfaceChanged may fire before MapLibreMap exists)
        if (this.surfaceWidth > 0 && this.surfaceHeight > 0) {
          console.info(`[NativeMapView] Syncing view size to MapLibreMap: ${this.surfaceWidth}x${this.surfaceHeight}`);
          this.mapLibreMapInstance.resizeView(this.surfaceWidth, this.surfaceHeight);
        }
        
        // Wire gesture detector to MapLibreMap
        this.gestureDetector.setMapLibreMapInstance(this.mapLibreMapInstance);

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
   * Set UI settings update callback
   */
  setUiSettingsUpdateCallback(callback: () => void): void {
    this.uiSettingsUpdateCallback = callback;
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
  updateCompassBearing(): void {
    if (this.nativeMapView && this.isInitialized && this.compassBearingUpdateCallback) {
      try {
        const bearing: number = this.nativeMapView.getBearing();
        this.compassBearingUpdateCallback(bearing);
      } catch (error) {
        hilog.error(DOMAIN, 'NativeMapView', `Failed to update compass bearing: ${error}`);
      }
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

  // ===== Camera listeners =====

  /**
   * Add a camera-will-change listener
   */
  addOnCameraWillChangeListener(listener: OnCameraWillChangeListener): void {
    if (this.onCameraWillChangeListeners.indexOf(listener) === -1) {
      this.onCameraWillChangeListeners.push(listener);
    }
  }

  /**
   * Remove a camera-will-change listener
   */
  removeOnCameraWillChangeListener(listener: OnCameraWillChangeListener): void {
    const index = this.onCameraWillChangeListeners.indexOf(listener);
    if (index !== -1) {
      this.onCameraWillChangeListeners.splice(index, 1);
    }
  }

  /**
   * Add a camera-is-changing listener
   */
  addOnCameraIsChangingListener(listener: OnCameraIsChangingListener): void {
    if (this.onCameraIsChangingListeners.indexOf(listener) === -1) {
      this.onCameraIsChangingListeners.push(listener);
    }
  }

  /**
   * Remove a camera-is-changing listener
   */
  removeOnCameraIsChangingListener(listener: OnCameraIsChangingListener): void {
    const index = this.onCameraIsChangingListeners.indexOf(listener);
    if (index !== -1) {
      this.onCameraIsChangingListeners.splice(index, 1);
    }
  }

  /**
   * Add a camera-did-change listener
   */
  addOnCameraDidChangeListener(listener: OnCameraDidChangeListener): void {
    if (this.onCameraDidChangeListeners.indexOf(listener) === -1) {
      this.onCameraDidChangeListeners.push(listener);
    }
  }

  /**
   * Remove a camera-did-change listener
   */
  removeOnCameraDidChangeListener(listener: OnCameraDidChangeListener): void {
    const index = this.onCameraDidChangeListeners.indexOf(listener);
    if (index !== -1) {
      this.onCameraDidChangeListeners.splice(index, 1);
    }
  }

  // ===== Map loading listeners =====

  /**
   * Add a will-start-loading-map listener
   */
  addOnWillStartLoadingMapListener(listener: OnWillStartLoadingMapListener): void {
    if (this.onWillStartLoadingMapListeners.indexOf(listener) === -1) {
      this.onWillStartLoadingMapListeners.push(listener);
    }
  }

  /**
   * Remove a will-start-loading-map listener
   */
  removeOnWillStartLoadingMapListener(listener: OnWillStartLoadingMapListener): void {
    const index = this.onWillStartLoadingMapListeners.indexOf(listener);
    if (index !== -1) {
      this.onWillStartLoadingMapListeners.splice(index, 1);
    }
  }

  /**
   * Add a did-finish-loading-map listener
   */
  addOnDidFinishLoadingMapListener(listener: OnDidFinishLoadingMapListener): void {
    if (this.onDidFinishLoadingMapListeners.indexOf(listener) === -1) {
      this.onDidFinishLoadingMapListeners.push(listener);
    }
  }

  /**
   * Remove a did-finish-loading-map listener
   */
  removeOnDidFinishLoadingMapListener(listener: OnDidFinishLoadingMapListener): void {
    const index = this.onDidFinishLoadingMapListeners.indexOf(listener);
    if (index !== -1) {
      this.onDidFinishLoadingMapListeners.splice(index, 1);
    }
  }

  /**
   * Add a did-fail-loading-map listener
   */
  addOnDidFailLoadingMapListener(listener: OnDidFailLoadingMapListener): void {
    if (this.onDidFailLoadingMapListeners.indexOf(listener) === -1) {
      this.onDidFailLoadingMapListeners.push(listener);
    }
  }

  /**
   * Remove a did-fail-loading-map listener
   */
  removeOnDidFailLoadingMapListener(listener: OnDidFailLoadingMapListener): void {
    const index = this.onDidFailLoadingMapListeners.indexOf(listener);
    if (index !== -1) {
      this.onDidFailLoadingMapListeners.splice(index, 1);
    }
  }

  // ===== Rendering listeners =====

  /**
   * Add a will-start-rendering-frame listener
   */
  addOnWillStartRenderingFrameListener(listener: OnWillStartRenderingFrameListener): void {
    if (this.onWillStartRenderingFrameListeners.indexOf(listener) === -1) {
      this.onWillStartRenderingFrameListeners.push(listener);
    }
  }

  /**
   * Remove a will-start-rendering-frame listener
   */
  removeOnWillStartRenderingFrameListener(listener: OnWillStartRenderingFrameListener): void {
    const index = this.onWillStartRenderingFrameListeners.indexOf(listener);
    if (index !== -1) {
      this.onWillStartRenderingFrameListeners.splice(index, 1);
    }
  }

  /**
   * Add a did-finish-rendering-frame listener (simple variant)
   */
  addOnDidFinishRenderingFrameListener(listener: OnDidFinishRenderingFrameListener): void {
    if (this.onDidFinishRenderingFrameListeners.indexOf(listener) === -1) {
      this.onDidFinishRenderingFrameListeners.push(listener);
    }
  }

  /**
   * Remove a did-finish-rendering-frame listener (simple variant)
   */
  removeOnDidFinishRenderingFrameListener(listener: OnDidFinishRenderingFrameListener): void {
    const index = this.onDidFinishRenderingFrameListeners.indexOf(listener);
    if (index !== -1) {
      this.onDidFinishRenderingFrameListeners.splice(index, 1);
    }
  }

  /**
   * Add a did-finish-rendering-frame listener (with stats)
   */
  addOnDidFinishRenderingFrameWithStatsListener(listener: OnDidFinishRenderingFrameWithStatsListener): void {
    if (this.onDidFinishRenderingFrameWithStatsListeners.indexOf(listener) === -1) {
      this.onDidFinishRenderingFrameWithStatsListeners.push(listener);
    }
  }

  /**
   * Remove a did-finish-rendering-frame listener (with stats)
   */
  removeOnDidFinishRenderingFrameWithStatsListener(listener: OnDidFinishRenderingFrameWithStatsListener): void {
    const index = this.onDidFinishRenderingFrameWithStatsListeners.indexOf(listener);
    if (index !== -1) {
      this.onDidFinishRenderingFrameWithStatsListeners.splice(index, 1);
    }
  }

  /**
   * Add a will-start-rendering-map listener
   */
  addOnWillStartRenderingMapListener(listener: OnWillStartRenderingMapListener): void {
    if (this.onWillStartRenderingMapListeners.indexOf(listener) === -1) {
      this.onWillStartRenderingMapListeners.push(listener);
    }
  }

  /**
   * Remove a will-start-rendering-map listener
   */
  removeOnWillStartRenderingMapListener(listener: OnWillStartRenderingMapListener): void {
    const index = this.onWillStartRenderingMapListeners.indexOf(listener);
    if (index !== -1) {
      this.onWillStartRenderingMapListeners.splice(index, 1);
    }
  }

  /**
   * Add a did-finish-rendering-map listener
   */
  addOnDidFinishRenderingMapListener(listener: OnDidFinishRenderingMapListener): void {
    if (this.onDidFinishRenderingMapListeners.indexOf(listener) === -1) {
      this.onDidFinishRenderingMapListeners.push(listener);
    }
  }

  /**
   * Remove a did-finish-rendering-map listener
   */
  removeOnDidFinishRenderingMapListener(listener: OnDidFinishRenderingMapListener): void {
    const index = this.onDidFinishRenderingMapListeners.indexOf(listener);
    if (index !== -1) {
      this.onDidFinishRenderingMapListeners.splice(index, 1);
    }
  }

  // ===== Style listeners =====

  /**
   * Add a did-finish-loading-style listener
   */
  addOnDidFinishLoadingStyleListener(listener: OnDidFinishLoadingStyleListener): void {
    if (this.onDidFinishLoadingStyleListeners.indexOf(listener) === -1) {
      this.onDidFinishLoadingStyleListeners.push(listener);
    }
  }

  /**
   * Remove a did-finish-loading-style listener
   */
  removeOnDidFinishLoadingStyleListener(listener: OnDidFinishLoadingStyleListener): void {
    const index = this.onDidFinishLoadingStyleListeners.indexOf(listener);
    if (index !== -1) {
      this.onDidFinishLoadingStyleListeners.splice(index, 1);
    }
  }

  /**
   * Add a style-image-missing listener
   */
  addOnStyleImageMissingListener(listener: OnStyleImageMissingListener): void {
    if (this.onStyleImageMissingListeners.indexOf(listener) === -1) {
      this.onStyleImageMissingListeners.push(listener);
    }
  }

  /**
   * Remove a style-image-missing listener
   */
  removeOnStyleImageMissingListener(listener: OnStyleImageMissingListener): void {
    const index = this.onStyleImageMissingListeners.indexOf(listener);
    if (index !== -1) {
      this.onStyleImageMissingListeners.splice(index, 1);
    }
  }

  /**
   * Add a can-remove-unused-style-image listener
   */
  addOnCanRemoveUnusedStyleImageListener(listener: OnCanRemoveUnusedStyleImageListener): void {
    if (this.onCanRemoveUnusedStyleImageListeners.indexOf(listener) === -1) {
      this.onCanRemoveUnusedStyleImageListeners.push(listener);
    }
  }

  /**
   * Remove a can-remove-unused-style-image listener
   */
  removeOnCanRemoveUnusedStyleImageListener(listener: OnCanRemoveUnusedStyleImageListener): void {
    const index = this.onCanRemoveUnusedStyleImageListeners.indexOf(listener);
    if (index !== -1) {
      this.onCanRemoveUnusedStyleImageListeners.splice(index, 1);
    }
  }

  // ===== Miscellaneous listeners =====

  /**
   * Add a did-become-idle listener
   */
  addOnDidBecomeIdleListener(listener: OnDidBecomeIdleListener): void {
    if (this.onDidBecomeIdleListeners.indexOf(listener) === -1) {
      this.onDidBecomeIdleListeners.push(listener);
    }
  }

  /**
   * Remove a did-become-idle listener
   */
  removeOnDidBecomeIdleListener(listener: OnDidBecomeIdleListener): void {
    const index = this.onDidBecomeIdleListeners.indexOf(listener);
    if (index !== -1) {
      this.onDidBecomeIdleListeners.splice(index, 1);
    }
  }

  /**
   * Add a source-changed listener
   */
  addOnSourceChangedListener(listener: OnSourceChangedListener): void {
    if (this.onSourceChangedListeners.indexOf(listener) === -1) {
      this.onSourceChangedListeners.push(listener);
    }
  }

  /**
   * Remove a source-changed listener
   */
  removeOnSourceChangedListener(listener: OnSourceChangedListener): void {
    const index = this.onSourceChangedListeners.indexOf(listener);
    if (index !== -1) {
      this.onSourceChangedListeners.splice(index, 1);
    }
  }

  /**
   * Add a pre-compile-shader listener
   */
  addOnPreCompileShaderListener(listener: OnPreCompileShaderListener): void {
    if (this.onPreCompileShaderListeners.indexOf(listener) === -1) {
      this.onPreCompileShaderListeners.push(listener);
    }
  }

  /**
   * Remove a pre-compile-shader listener
   */
  removeOnPreCompileShaderListener(listener: OnPreCompileShaderListener): void {
    const index = this.onPreCompileShaderListeners.indexOf(listener);
    if (index !== -1) {
      this.onPreCompileShaderListeners.splice(index, 1);
    }
  }

  /**
   * Add a post-compile-shader listener
   */
  addOnPostCompileShaderListener(listener: OnPostCompileShaderListener): void {
    if (this.onPostCompileShaderListeners.indexOf(listener) === -1) {
      this.onPostCompileShaderListeners.push(listener);
    }
  }

  /**
   * Remove a post-compile-shader listener
   */
  removeOnPostCompileShaderListener(listener: OnPostCompileShaderListener): void {
    const index = this.onPostCompileShaderListeners.indexOf(listener);
    if (index !== -1) {
      this.onPostCompileShaderListeners.splice(index, 1);
    }
  }

  /**
   * Add a shader-compile-failed listener
   */
  addOnShaderCompileFailedListener(listener: OnShaderCompileFailedListener): void {
    if (this.onShaderCompileFailedListeners.indexOf(listener) === -1) {
      this.onShaderCompileFailedListeners.push(listener);
    }
  }

  /**
   * Remove a shader-compile-failed listener
   */
  removeOnShaderCompileFailedListener(listener: OnShaderCompileFailedListener): void {
    const index = this.onShaderCompileFailedListeners.indexOf(listener);
    if (index !== -1) {
      this.onShaderCompileFailedListeners.splice(index, 1);
    }
  }

  /**
   * Add a glyph-loaded listener
   */
  addOnGlyphsLoadedListener(listener: OnGlyphsLoadedListener): void {
    if (this.onGlyphsLoadedListeners.indexOf(listener) === -1) {
      this.onGlyphsLoadedListeners.push(listener);
    }
  }

  /**
   * Remove a glyph-loaded listener
   */
  removeOnGlyphsLoadedListener(listener: OnGlyphsLoadedListener): void {
    const index = this.onGlyphsLoadedListeners.indexOf(listener);
    if (index !== -1) {
      this.onGlyphsLoadedListeners.splice(index, 1);
    }
  }

  /**
   * Add a glyph-error listener
   */
  addOnGlyphsErrorListener(listener: OnGlyphsErrorListener): void {
    if (this.onGlyphsErrorListeners.indexOf(listener) === -1) {
      this.onGlyphsErrorListeners.push(listener);
    }
  }

  /**
   * Remove a glyph-error listener
   */
  removeOnGlyphsErrorListener(listener: OnGlyphsErrorListener): void {
    const index = this.onGlyphsErrorListeners.indexOf(listener);
    if (index !== -1) {
      this.onGlyphsErrorListeners.splice(index, 1);
    }
  }

  /**
   * Add a glyph-requested listener
   */
  addOnGlyphsRequestedListener(listener: OnGlyphsRequestedListener): void {
    if (this.onGlyphsRequestedListeners.indexOf(listener) === -1) {
      this.onGlyphsRequestedListeners.push(listener);
    }
  }

  /**
   * Remove a glyph-requested listener
   */
  removeOnGlyphsRequestedListener(listener: OnGlyphsRequestedListener): void {
    const index = this.onGlyphsRequestedListeners.indexOf(listener);
    if (index !== -1) {
      this.onGlyphsRequestedListeners.splice(index, 1);
    }
  }

  /**
   * Add a tile-action listener
   */
  addOnTileActionListener(listener: OnTileActionListener): void {
    if (this.onTileActionListeners.indexOf(listener) === -1) {
      this.onTileActionListeners.push(listener);
    }
  }

  /**
   * Remove a tile-action listener
   */
  removeOnTileActionListener(listener: OnTileActionListener): void {
    const index = this.onTileActionListeners.indexOf(listener);
    if (index !== -1) {
      this.onTileActionListeners.splice(index, 1);
    }
  }

  /**
   * Add a sprite-loaded listener
   */
  addOnSpriteLoadedListener(listener: OnSpriteLoadedListener): void {
    if (this.onSpriteLoadedListeners.indexOf(listener) === -1) {
      this.onSpriteLoadedListeners.push(listener);
    }
  }

  /**
   * Remove a sprite-loaded listener
   */
  removeOnSpriteLoadedListener(listener: OnSpriteLoadedListener): void {
    const index = this.onSpriteLoadedListeners.indexOf(listener);
    if (index !== -1) {
      this.onSpriteLoadedListeners.splice(index, 1);
    }
  }

  /**
   * Add a sprite-error listener
   */
  addOnSpriteErrorListener(listener: OnSpriteErrorListener): void {
    if (this.onSpriteErrorListeners.indexOf(listener) === -1) {
      this.onSpriteErrorListeners.push(listener);
    }
  }

  /**
   * Remove a sprite-error listener
   */
  removeOnSpriteErrorListener(listener: OnSpriteErrorListener): void {
    const index = this.onSpriteErrorListeners.indexOf(listener);
    if (index !== -1) {
      this.onSpriteErrorListeners.splice(index, 1);
    }
  }

  /**
   * Add a sprite-requested listener
   */
  addOnSpriteRequestedListener(listener: OnSpriteRequestedListener): void {
    if (this.onSpriteRequestedListeners.indexOf(listener) === -1) {
      this.onSpriteRequestedListeners.push(listener);
    }
  }

  /**
   * Remove a sprite-requested listener
   */
  removeOnSpriteRequestedListener(listener: OnSpriteRequestedListener): void {
    const index = this.onSpriteRequestedListeners.indexOf(listener);
    if (index !== -1) {
      this.onSpriteRequestedListeners.splice(index, 1);
    }
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
    // TODO: C++ NAPI binding
      // this.mapView.setTileCacheEnabled(enabled);
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