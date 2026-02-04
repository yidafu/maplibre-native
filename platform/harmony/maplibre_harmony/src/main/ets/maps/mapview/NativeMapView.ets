import maplibre from 'libmaplibre.so';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';
import {
  NativeMapViewController,
  type NativeMapView
} from './NativeMapViewController';
import { MapLibreMap } from '../MapLibreMap';
import { Marker } from '../annotations/Marker';
import { AnnotationViewData } from '../annotations/AnnotationViewManager';
import { AnnotationViewOverlay } from '../annotations/AnnotationViewOverlay';
import { NativeViewAnnotationOverlay, ViewAnnotationRenderState } from '../annotations/NativeViewAnnotationOverlay';
import { ViewAnnotationBuilderContext } from '../annotations/ViewAnnotationTypes';
import { NativeViewAnnotationOptions, NativeViewAnnotationFrame } from '../annotations/NativeViewAnnotationTypes';
import { LatLng } from '../geometry/LatLng';
import { UiSettings } from '../UiSettings';
import { CompassView } from '../widgets/CompassView';
import { LogoView } from '../widgets/LogoView';
import { ScaleBarView } from '../widgets/ScaleBarView';
import { AttributionButton, DEFAULT_ATTRIBUTIONS } from '../widgets/AttributionButton';
import type { AttributionInfo } from '../widgets/AttributionButton';
import { OrnamentPosition, RenderingRefreshMode } from '../types/NativeTypes';
import { OnFpsChangedListener } from '../listeners/OnFpsChangedListener';
import {
  OnMoveListener,
  OnScaleListener,
  OnRotateListener,
  OnMapClickListener,
  OnMapLongClickListener,
  OnDoubleTapListener,
  OnTiltListener,
  OnQuickZoomListener
} from '../gestures/GestureListeners';
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

type NativeMapViewErrorInput = Error | string | number | boolean | object;

export { registerMapLibreMap } from './NativeMapViewController';

type CameraOptions = maplibre.CameraOptions;

@Component
export struct MapView {
  private controller: NativeMapViewController = new NativeMapViewController();
  @State private isVisible: boolean = true;
  @State private isDestroyed: boolean = false;
  // Component properties
  @Prop styleUrl: string;
  @Prop initialLatitude: number = 30.2741;
  @Prop initialLongitude: number = 120.1551;
  @Prop initialZoom: number = 6;
  @Prop initialBearing: number = 0;
  @Prop initialPitch: number = 0;
  @Prop debugMode: boolean = false;
  @State private viewAnnotationFrames: ViewAnnotationRenderState[] = [];
  // Callbacks
  onMapViewCreated?: (map: MapLibreMap) => void; // Early callback: invoked right after MapLibreMap is created (before style load)
  onMapReady?: (map: MapLibreMap) => void | Promise<void>; // Standard callback: called after style finishes loading
  onMapLoaded?: () => void;
  onMapError?: (error: string) => void;
  // Declarative child support
  @BuilderParam children?: () => void;
  // Provide map instance to child components (declarative API)
  @Provide('mapLibreMap') mapInstance: MapLibreMap | null = null;
  // UI component state
  @State private compassBearing: number = 0;
  @State private uiSettingsVersion: number = 0;
  @State private scaleBarMetersPerPixel: number = 0;
  // InfoWindow state management
  // AnnotationView state management
  @State private visibleAnnotationViews: AnnotationViewData[] = [];
  private lastViewAnnotationSnapshot: Map<number, string> = new Map();

  private getOnMapViewCreatedCallback(): ((map: MapLibreMap) => void) | undefined {
    return typeof this.onMapViewCreated === 'function' ? this.onMapViewCreated : undefined;
  }

  private getOnMapReadyCallback(): ((map: MapLibreMap) => void | Promise<void>) | undefined {
    return typeof this.onMapReady === 'function' ? this.onMapReady : undefined;
  }

  private getOnMapLoadedCallback(): (() => void) | undefined {
    return typeof this.onMapLoaded === 'function' ? this.onMapLoaded : undefined;
  }

  private getOnMapErrorCallback(): ((error: string) => void) | undefined {
    return typeof this.onMapError === 'function' ? this.onMapError : undefined;
  }

  private getErrorMessage(error: NativeMapViewErrorInput): string {
    if (error instanceof Error && error.message) {
      return error.message;
    }
    return String(error);
  }

  private getErrorStack(error: NativeMapViewErrorInput): string | undefined {
    if (error instanceof Error) {
      return error.stack;
    }
    return undefined;
  }

  private logNativeMapViewError(prefix: string, error: NativeMapViewErrorInput): void {
    const errorMsg = this.getErrorMessage(error);
    hilog.error(DOMAIN, 'NativeMapView', `${prefix}: ${errorMsg}`);
    const errorStack = this.getErrorStack(error);
    if (errorStack) {
      hilog.error(DOMAIN, 'NativeMapView', `${prefix} stack: ${errorStack}`);
    }
  }

  private syncInitialCameraProps(applyToNative: boolean = false): void {
    if (!this.controller) {
      hilog.warn(DOMAIN, 'NativeMapView', 'Controller not ready for syncing initial camera props');
      return;
    }

    this.controller.styleUrl = this.styleUrl;
    this.controller.initialLatitude = this.initialLatitude;
    this.controller.initialLongitude = this.initialLongitude;
    this.controller.initialZoom = this.initialZoom;
    this.controller.initialBearing = this.initialBearing;
    this.controller.initialPitch = this.initialPitch;

    if (applyToNative && this.controller.isMapInitialized()) {
      hilog.info(DOMAIN, 'NativeMapView', `Re-applying initial camera: lat=${this.initialLatitude}, lng=${this.initialLongitude}, zoom=${this.initialZoom}, bearing=${this.initialBearing}, pitch=${this.initialPitch}`);
      this.controller.jumpTo(this.initialBearing, this.initialLatitude, this.initialLongitude, this.initialPitch, this.initialZoom);
    }
  }

  private logViewAnnotationStateChanges(states: ViewAnnotationRenderState[]): void {
    const maxLogItems = 5;
    const nextSnapshot: Map<number, string> = new Map();
    const changes: string[] = [];
    let truncated = false;

    states.forEach((state) => {
      const summary = `pos=(${state.positionX.toFixed(2)}, ${state.positionY.toFixed(2)}), size=(${state.width.toFixed(2)} x ${state.height.toFixed(2)}), scale=${state.scale.toFixed(3)}, rotation=${state.rotation.toFixed(2)}, visible=${state.visible}`;
      nextSnapshot.set(state.id, summary);
      const previous = this.lastViewAnnotationSnapshot.get(state.id);
      if (previous !== summary) {
        if (changes.length < maxLogItems) {
          changes.push(`id=${state.id} ${summary}`);
        } else {
          truncated = true;
        }
      }
    });

    this.lastViewAnnotationSnapshot.forEach((_, id) => {
      if (!nextSnapshot.has(id)) {
        if (changes.length < maxLogItems) {
          changes.push(`id=${id} removed`);
        } else {
          truncated = true;
        }
      }
    });

    if (states.length === 0 && this.lastViewAnnotationSnapshot.size > 0 && changes.length < maxLogItems) {
      changes.push('all annotations cleared');
    }

    if (changes.length > 0) {
      if (truncated) {
        changes.push('...');
      }
      console.info(`[MapView] ViewAnnotation state changes (${states.length} states): ${changes.join(' | ')}`);
    }

    this.lastViewAnnotationSnapshot = nextSnapshot;
  }

  /**
   * Component is about to appear
   */
  aboutToAppear(): void {
    try {
      this.isDestroyed = false;

      // Propagate component props and callbacks to the controller
      if (this.controller) {
        this.syncInitialCameraProps(true);

        // ✅ Set the onMapViewCreated callback (fires after the C++ map is created)
        this.controller.onMapViewCreatedCallback = (mapLibreMap: MapLibreMap) => {
          hilog.info(DOMAIN, 'NativeMapView', '📢 Calling user onMapViewCreated callback');
          const callback = this.getOnMapViewCreatedCallback();
          if (callback) {
            callback(mapLibreMap);
          }
        };

        // Wrap the onMapReady callback (fires once the style finishes loading)
        this.controller.onMapReadyCallback = (mapView?: NativeMapView) => {
          // ✅ MapLibreMap has already been created in handleMapViewCreated
          const mapLibreMap = this.controller.getMapLibreMapInstance();

          if (!mapLibreMap) {
            hilog.error(DOMAIN, 'NativeMapView', '❌ MapLibreMap not initialized in onMapReady');
            return;
          }

          // Update the map instance to trigger declarative child initialization
          this.mapInstance = mapLibreMap;

          // ⚠️ Important: configure InfoWindowManager callbacks before onMapReady
          // Mirrors Android/iOS: user callbacks should run after internal setup
          // Prevent race conditions: if the user adds and taps markers in onMapReady, callbacks must already exist
          // Style finished loading, fire onMapReady
          const callback = this.getOnMapReadyCallback();
          if (callback) {
            hilog.info(DOMAIN, 'NativeMapView', '📢 Calling user onMapReady callback');
            callback(mapLibreMap);
          } else {
            hilog.warn(DOMAIN, 'NativeMapView', '⚠️ No onMapReady callback registered');
          }
        };

        // Register UI component update callbacks
        this.controller.setCompassBearingUpdateCallback((bearing: number) => {
          this.compassBearing = bearing;
        });

        this.controller.setUiSettingsUpdateCallback(() => {
          this.uiSettingsVersion++;
        });

        this.controller.setScaleBarMetersPerPixelUpdateCallback((metersPerPixel: number) => {
          this.scaleBarMetersPerPixel = metersPerPixel;
        });

        // Register AnnotationView update callback
        this.controller.setAnnotationViewUpdateCallback((views: AnnotationViewData[]) => {
          this.visibleAnnotationViews = views;
        });

        this.controller.setViewAnnotationRenderCallback((states: ViewAnnotationRenderState[]) => {
          console.info(`[MapView] ViewAnnotation render callback: received ${states.length} states`);
          this.logViewAnnotationStateChanges(states);
          this.viewAnnotationFrames = [...states];
        });

        // Register UiSettings configuration change callbacks
        const uiSettings = this.controller.getUiSettings();
        uiSettings.onCompassConfigChanged = () => {
          this.uiSettingsVersion++;
        };
        uiSettings.onLogoConfigChanged = () => {
          this.uiSettingsVersion++;
        };
        uiSettings.onScaleBarConfigChanged = () => {
          this.uiSettingsVersion++;
        };

      } else {
        hilog.error(DOMAIN, 'NativeMapView', 'Controller is null in aboutToAppear');
      }
    } catch (error) {
      this.logNativeMapViewError('aboutToAppear failed', error);
    }
  }

  /**
   * Component is about to disappear (mirrors Android MapView.onDestroy() and iOS MLNMapView.dealloc)
   *
   * Improvements:
   * 1. Use async destroy instead of blocking synchronously
   * 2. Clean resources following the Android/iOS order
   * 3. Clear all listeners and callbacks
   */
  aboutToDisappear(): void {

    // 1. Mark as destroyed (mirrors Android MapView.destroyed)
    this.isDestroyed = true;

    // Clear map instance reference (for declarative children)
    this.mapInstance = null;

    try {
      // 2. Cancel animations and gestures (mirrors Android cancelAnimators())
      const mapView = this.controller.getMapView();
      if (mapView) {
        try {
          mapView.cancelTransitions();
        } catch (err) {
          hilog.warn(DOMAIN, 'NativeMapView', `Error cancelling transitions: ${err}`);
        }
      }

      // 3. ✅ Use asynchronous destroy (mirrors Android/iOS)
      // Keeps the main thread responsive while releasing resources
      if (mapView) {

        // Invoke asynchronous destroy with a completion callback
        mapView.destroyAsync(() => {
        });

      } else {
        hilog.warn(DOMAIN, 'NativeMapView', 'MapView is null, skipping destroy');
      }

      // 4. Clear UI component references immediately (no need to await)
      // Controller references are cleared when the component is destroyed
      // Event listeners are cleared in C++ cleanupAllResourcesAsync

      // 5. Remove from global registry
      if (mapView) {
        const controllerWithUnregister = this.controller;
        controllerWithUnregister.unregisterFromGlobalMap?.();
      }

      // 6. Reset AnnotationView state
      this.visibleAnnotationViews = [];
      this.controller.clearViewAnnotationRenderCallback();
      this.logViewAnnotationStateChanges([]);
      this.viewAnnotationFrames = [];

    } catch (error) {
      this.logNativeMapViewError('Error in aboutToDisappear', error);
    }
  }

  /**
   * Get the compass X position
   */
  private getCompassX(): Length {
    const uiSettings = this.controller.getUiSettings();
    const position = uiSettings.getCompassPosition();
    const margins = uiSettings.getCompassMargins();

    switch (position) {
      case OrnamentPosition.TopLeft:
      case OrnamentPosition.BottomLeft:
        return margins.left;
      case OrnamentPosition.TopRight:
      case OrnamentPosition.BottomRight:
        return `calc(100% - 48vp - ${margins.right}vp)`; // 100% - component width - right margin
      default:
        return `calc(100% - 48vp - ${margins.right}vp)`; // Default right alignment (same as TopRight)
    }
  }

  /**
   * Get the compass Y position
   */
  private getCompassY(): Length {
    const uiSettings = this.controller.getUiSettings();
    const position = uiSettings.getCompassPosition();
    const margins = uiSettings.getCompassMargins();

    switch (position) {
      case OrnamentPosition.TopLeft:
      case OrnamentPosition.TopRight:
        return margins.top;
      case OrnamentPosition.BottomLeft:
      case OrnamentPosition.BottomRight:
        return `calc(100% - 48vp - ${margins.bottom}vp)`; // 100% - component height - bottom margin
      default:
        return margins.top; // Default top alignment (same as TopRight)
    }
  }

  /**
   * Get the logo X position
   */
  private getLogoX(): Length {
    const uiSettings = this.controller.getUiSettings();
    const position = uiSettings.getLogoPosition();
    const margins = uiSettings.getLogoMargins();

    switch (position) {
      case OrnamentPosition.TopLeft:
      case OrnamentPosition.BottomLeft:
        return margins.left;
      case OrnamentPosition.TopRight:
      case OrnamentPosition.BottomRight:
        return `calc(100% - 80vp - ${margins.right}vp)`; // 100% - logo width - right margin
      default:
        return margins.left; // Default left alignment (same as BottomLeft)
    }
  }

  /**
   * Get the logo Y position
   */
  private getLogoY(): Length {
    const uiSettings = this.controller.getUiSettings();
    const position = uiSettings.getLogoPosition();
    const margins = uiSettings.getLogoMargins();

    switch (position) {
      case OrnamentPosition.TopLeft:
      case OrnamentPosition.TopRight:
        return margins.top;
      case OrnamentPosition.BottomLeft:
      case OrnamentPosition.BottomRight:
        return `calc(100% - 40vp - ${margins.bottom}vp)`; // 100% - logo height - bottom margin
      default:
        return `calc(100% - 40vp - ${margins.bottom}vp)`; // Default bottom alignment (same as BottomLeft)
    }
  }

  /**
   * Get the scale bar X position
   */
  private getScaleBarX(): Length {
    const uiSettings = this.controller.getUiSettings();
    const position = uiSettings.getScaleBarPosition();
    const margins = uiSettings.getScaleBarMargins();

    switch (position) {
      case OrnamentPosition.TopLeft:
      case OrnamentPosition.BottomLeft:
        return margins.left;
      case OrnamentPosition.TopRight:
      case OrnamentPosition.BottomRight:
        return `calc(100% - 200vp - ${margins.right}vp)`; // 100% - scale bar max width - right margin
      default:
        return margins.left; // Default left alignment (same as TopLeft)
    }
  }

  /**
   * Get the scale bar Y position
   */
  private getScaleBarY(): Length {
    const uiSettings = this.controller.getUiSettings();
    const position = uiSettings.getScaleBarPosition();
    const margins = uiSettings.getScaleBarMargins();

    switch (position) {
      case OrnamentPosition.TopLeft:
      case OrnamentPosition.TopRight:
        return margins.top;
      case OrnamentPosition.BottomLeft:
      case OrnamentPosition.BottomRight:
        return `calc(100% - 40vp - ${margins.bottom}vp)`; // 100% - scale bar height - bottom margin
      default:
        return margins.top; // Default top alignment (same as TopLeft)
    }
  }

  /**
   * Get the attribution button X position
   */
  private getAttributionX(): Length {
    const uiSettings = this.controller.getUiSettings();
    const alignment = uiSettings.getAttributionAlignment();
    const margins = uiSettings.getAttributionMargins();

    switch (alignment) {
      case Alignment.TopStart:
      case Alignment.BottomStart:
        return margins.left;
      case Alignment.TopEnd:
      case Alignment.BottomEnd:
        return `calc(100% - 40vp - ${margins.right}vp)`; // 100% - button width - right margin
      default:
        return margins.left;
    }
  }

  /**
   * Get the attribution button Y position
   */
  private getAttributionY(): Length {
    const uiSettings = this.controller.getUiSettings();
    const alignment = uiSettings.getAttributionAlignment();
    const margins = uiSettings.getAttributionMargins();

    switch (alignment) {
      case Alignment.TopStart:
      case Alignment.TopEnd:
        return margins.top;
      case Alignment.BottomStart:
      case Alignment.BottomEnd:
        return `calc(100% - 40vp - ${margins.bottom}vp)`; // 100% - button height - bottom margin
      default:
        return `calc(100% - 40vp - ${margins.bottom}vp)`;
    }
  }

  /**
   * Get attributions for the attribution button
   */
  private getAttributions(): AttributionInfo[] {
    const mapLibreMap = this.controller.getMapLibreMapInstance();
    if (!mapLibreMap) {
      return DEFAULT_ATTRIBUTIONS;
    }
    // TODO: 从样式获取 attributions (需要 C++ 端支持)
    // 目前返回默认 attributions
    return DEFAULT_ATTRIBUTIONS;
  }

  /**
   * Build the component
   */
  build() {
    Stack() {
      // Map XComponent
      XComponent({
        type: XComponentType.SURFACE,
        controller: this.controller,
      })
        .width('100%')
        .height('100%')
        .parallelGesture(
          // Use GestureGroup to combine multiple gestures and allow parallel recognition
          GestureGroup(GestureMode.Parallel,
            // Pan gesture - single-finger drag
            PanGesture({ fingers: 1, distance: 5 })
              .onActionStart((event: GestureEvent) => {
                this.controller.getGestureDetector().onPanStart(event);
              })
              .onActionUpdate((event: GestureEvent) => {
                this.controller.getGestureDetector().onPanUpdate(event);
              })
              .onActionEnd((event: GestureEvent) => {
                this.controller.getGestureDetector().onPanEnd(event);
              }),

            // Pinch gesture - two-finger pinch
            PinchGesture({ fingers: 2, distance: 5 })
              .onActionStart((event: GestureEvent) => {
                this.controller.getGestureDetector().onPinchStart(event);
              })
              .onActionUpdate((event: GestureEvent) => {
                this.controller.getGestureDetector().onPinchUpdate(event);
              })
              .onActionEnd((event: GestureEvent) => {
                this.controller.getGestureDetector().onPinchEnd(event);
              }),

            // Rotation gesture - two-finger rotate
            RotationGesture({ fingers: 2, angle: 1 })
              .onActionStart((event: GestureEvent) => {
                this.controller.getGestureDetector().onRotateStart(event);
              })
              .onActionUpdate((event: GestureEvent) => {
                this.controller.getGestureDetector().onRotateUpdate(event);
              })
              .onActionEnd((event: GestureEvent) => {
                this.controller.getGestureDetector().onRotateEnd(event);
              })
          )
        )
        // Double-tap gesture - use priorityGesture to ensure the highest priority
        .priorityGesture(
          TapGesture({ count: 2 })
            .onAction((event: GestureEvent) => {
              this.controller.getGestureDetector().onDoubleTap(event);
            }),
          GestureMask.Normal
        )
        // Long-press gesture - registered separately
        .gesture(
          LongPressGesture({ repeat: false, duration: 500 })
            .onAction((event: GestureEvent) => {
              this.controller.getGestureDetector().onLongPress(event);
            })
        )
        // Single-tap gesture - registered separately; the system resolves conflicts with long press
        .gesture(
          TapGesture({ count: 1 })
            .onAction((event: GestureEvent) => {
              this.controller.getGestureDetector().onSingleTap(event);
            })
        )
        .gesture(
          // Tilt gesture - two-finger vertical drag
          PanGesture({ fingers: 2, distance: 10, direction: PanDirection.Vertical })
            .onActionStart((event: GestureEvent) => {
              this.controller.getGestureDetector().onTwoFingerPanStart(event);
            })
            .onActionUpdate((event: GestureEvent) => {
              this.controller.getGestureDetector().onTwoFingerPanUpdate(event);
            })
            .onActionEnd((event: GestureEvent) => {
              this.controller.getGestureDetector().onTwoFingerPanEnd(event);
            })
        )

      // Compass component - absolute positioning configured via UiSettings
      if (this.controller.getUiSettings().isCompassEnabled()) {
        CompassView({
          externalBearing: this.compassBearing,
          compassEnabled: this.controller.getUiSettings().isCompassEnabled(),
          compassVisibility: this.controller.getUiSettings().getCompassVisibility(),
          fadeWhenFacingNorth: this.controller.getUiSettings().isCompassFadeWhenFacingNorth(),
          onCompassClick: () => {
            this.controller.resetNorth();
          }
        })
          .width(48)
          .height(48)
          .position({ x: this.getCompassX(), y: this.getCompassY() })
      }

      // Logo component - absolute positioning configured via UiSettings
      if (this.controller.getUiSettings().isLogoEnabled()) {
        LogoView({
          logoEnabled: this.controller.getUiSettings().isLogoEnabled()
        })
          .width(80)
          .height(40)
          .position({ x: this.getLogoX(), y: this.getLogoY() })
      }

      // Scale bar component - absolute positioning configured via UiSettings
      if (this.controller.getUiSettings().isScaleBarEnabled()) {
        ScaleBarView({
          isEnabled: this.controller.getUiSettings().isScaleBarEnabled(),
          metersPerPixel: this.scaleBarMetersPerPixel,
          unitSystem: this.controller.getUiSettings().getScaleBarUnit(),
          useDarkStyles: this.controller.getUiSettings().isScaleBarUseDarkStyles()
        })
          .position({ x: this.getScaleBarX(), y: this.getScaleBarY() })
      }

      // Attribution button - absolute positioning configured via UiSettings
      if (this.controller.getUiSettings().isAttributionEnabled()) {
        AttributionButton({
          isEnabled: this.controller.getUiSettings().isAttributionEnabled(),
          attributions: this.getAttributions()
        })
          .width(40)
          .height(40)
          .position({ x: this.getAttributionX(), y: this.getAttributionY() })
      }

      // AnnotationView overlay - renders all custom AnnotationViews
      AnnotationViewOverlay({
        visibleAnnotationViews: this.visibleAnnotationViews,
        mapBearing: this.compassBearing,
        mapPitch: this.controller.getPitch(),
        screenWidth: this.controller.getWidth(),
        screenHeight: this.controller.getHeight(),
        onAnnotationSelect: (marker: Marker) => {
          try {
            const mapLibreMap = this.controller.getMapLibreMapInstance();
            if (mapLibreMap) {
              mapLibreMap.getMarkerManager().selectMarker(marker, true);
            }
          } catch (error) {
            this.logNativeMapViewError('AnnotationView select error', error);
          }
        },
        onAnnotationDeselect: (marker: Marker) => {
          try {
            const mapLibreMap = this.controller.getMapLibreMapInstance();
            if (mapLibreMap) {
              mapLibreMap.getMarkerManager().deselectMarker(marker);
            }
          } catch (error) {
            this.logNativeMapViewError('AnnotationView deselect error', error);
          }
        },
        onAnnotationDragStart: (marker: Marker) => {
          try {
            const mapLibreMap = this.controller.getMapLibreMapInstance();
            if (mapLibreMap) {
              mapLibreMap.getMarkerManager().handleDragStart(marker);
            }
          } catch (error) {
            this.logNativeMapViewError('AnnotationView drag start error', error);
          }
        },
        onAnnotationDrag: (marker: Marker, screenX: number, screenY: number) => {
          try {
            const mapView = this.controller.getMapView();
            if (mapView) {
              let pixelRatio = 1;
              try {
                const candidate = mapView.getPixelRatio?.();
                if (typeof candidate === 'number' && Number.isFinite(candidate) && candidate > 0) {
                  pixelRatio = candidate;
                }
              } catch (ratioError) {
                const reason = ratioError instanceof Error ? ratioError.message : `${ratioError}`;
                this.logNativeMapViewError('latLngForPixel pixelRatio read error', reason);
              }

              const physicalX = screenX * pixelRatio;
              const physicalY = screenY * pixelRatio;
              const nativeLatLng: maplibre.LatLng = mapView.latLngForPixel(physicalX, physicalY);
              const mapLibreMap = this.controller.getMapLibreMapInstance();
              if (mapLibreMap && nativeLatLng) {
                const latLng = LatLng.fromNative(nativeLatLng);
                mapLibreMap.getMarkerManager().handleDrag(marker, latLng);
              }
            }
          } catch (error) {
            this.logNativeMapViewError('AnnotationView drag error', error);
          }
        },
        onAnnotationDragEnd: (marker: Marker, screenX: number, screenY: number) => {
          try {
            const mapLibreMap = this.controller.getMapLibreMapInstance();
            if (mapLibreMap) {
              mapLibreMap.getMarkerManager().handleDragEnd(marker);
            }
          } catch (error) {
            this.logNativeMapViewError('AnnotationView drag end error', error);
          }
        }
      })

      NativeViewAnnotationOverlay({
        frames: this.viewAnnotationFrames
      })
        .width('100%')
        .height('100%')
        .hitTestBehavior(HitTestMode.Transparent)

      // Declarative child rendering (Marker, Source, Layer, etc.)
      if (this.children) {
        this.children()
      }
    }
  }

  /**
   * Add a pan gesture listener
   */
  addOnMoveListener(listener: OnMoveListener): void {
    this.controller.getGestureDetector().addOnMoveListener(listener);
  }

  /**
   * Add a scale gesture listener
   */
  addOnScaleListener(listener: OnScaleListener): void {
    this.controller.getGestureDetector().addOnScaleListener(listener);
  }

  /**
   * Add a rotate gesture listener
   */
  addOnRotateListener(listener: OnRotateListener): void {
    this.controller.getGestureDetector().addOnRotateListener(listener);
  }

  /**
   * Add a tap listener
   */
  addOnMapClickListener(listener: OnMapClickListener): void {
    this.controller.getGestureDetector().addOnMapClickListener(listener);
  }

  /**
   * Add a long-press listener
   */
  addOnMapLongClickListener(listener: OnMapLongClickListener): void {
    this.controller.getGestureDetector().addOnMapLongClickListener(listener);
  }

  /**
   * Add a double-tap listener
   */
  addOnDoubleTapListener(listener: OnDoubleTapListener): void {
    this.controller.getGestureDetector().addOnDoubleTapListener(listener);
  }

  /**
   * Add a tilt listener
   */
  addOnTiltListener(listener: OnTiltListener): void {
    this.controller.getGestureDetector().addOnTiltListener(listener);
  }

  /**
   * Add a quick zoom listener
   */
  addOnQuickZoomListener(listener: OnQuickZoomListener): void {
    this.controller.getGestureDetector().addOnQuickZoomListener(listener);
  }

  /**
   * Get the map pitch
   * @returns Current pitch in degrees
   */
  getPitch(): number {
    const mapView = this.controller.getMapView();
    if (!mapView) {
      hilog.warn(DOMAIN, 'NativeMapView', 'getPitch: Native map view not initialized');
      return 0;
    }
    try {
      const pitch: number | undefined = mapView.getPitch() as number | undefined;
      return pitch !== undefined ? pitch : 0;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, 'NativeMapView', `getPitch failed: ${errorMsg}`);
      return 0;
    }
  }

  /**
   * Set the map pitch
   * @param pitch Pitch in degrees (0-60)
   * @param duration Optional animation duration in milliseconds, default 0 (no animation)
   */
  setPitch(pitch: number, duration: number = 0): void {
    const mapView = this.controller.getMapView();
    if (!mapView) {
      hilog.warn(DOMAIN, 'NativeMapView', 'setPitch: Native map view not initialized');
      return;
    }
    try {
      mapView.setPitch(pitch, duration);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, 'NativeMapView', `setPitch failed: ${errorMsg}`);
    }
  }

  /**
   * Get the UI settings
   */
  getUiSettings(): UiSettings {
    return this.controller.getUiSettings();
  }

  /**
   * Set the MapLibreMap instance (used for InfoWindow management)
   * Should be called immediately after the MapLibreMap is created
   */
  setMapLibreMap(mapLibreMap: MapLibreMap): void {
    this.controller.setMapLibreMapInstance(mapLibreMap);
  }

  /**
   * Set the map style
   */
  setStyleUrl(url: string): void {
    this.styleUrl = url;
    this.controller.setStyleUrl(url);
  }

  /**
   * Cancel all ongoing camera transition animations
   */
  cancelTransitions(): void {
    const mapView = this.controller.getMapView();
    if (!mapView) {
      hilog.warn(DOMAIN, 'NativeMapView', 'cancelTransitions: Native map view not initialized');
      return;
    }
    try {
      mapView.cancelTransitions();
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, 'NativeMapView', `cancelTransitions failed: ${errorMsg}`);
    }
  }

  /**
   * Jump to the specified camera position
   */
  jumpTo(angle: number, latitude: number, longitude: number, pitch: number, zoom: number): void {
    this.controller.jumpTo(angle, latitude, longitude, pitch, zoom);
  }

  /**
   * Fly to the specified camera position (with animation)
   * @param options Camera options
   * @param duration Animation duration in milliseconds
   */
  flyTo(options: CameraOptions, duration: number): void {
    this.controller.flyTo(options, duration);
  }

  /**
   * Transition smoothly to the specified camera position
   * @param options Camera options
   * @param duration Animation duration in milliseconds
   */
  easeTo(options: CameraOptions, duration: number): void {
    this.controller.easeTo(options, duration);
  }

  /**
   * Add a marker
   */
  addMarkers(markers: Marker[]): number[] {
    return this.controller.addMarkers(markers);
  }

  addViewAnnotation(options: NativeViewAnnotationOptions): number {
    return this.controller.addViewAnnotation(options);
  }

  updateViewAnnotation(annotationId: number, options: NativeViewAnnotationOptions): boolean {
    return this.controller.updateViewAnnotation(annotationId, options);
  }

  removeViewAnnotation(annotationId: number): boolean {
    return this.controller.removeViewAnnotation(annotationId);
  }

  getViewAnnotationFrames(): NativeViewAnnotationFrame[] {
    return this.controller.getViewAnnotationFrames();
  }

  /**
   * Trigger a redraw
   */
  triggerRepaint(): void {
    this.controller.triggerRepaint();
  }

  /**
   * Show or hide the map
   */
  setVisible(visible: boolean): void {
    this.isVisible = visible;
  }

  /**
   * Get the map controller
   */
  getController(): NativeMapViewController {
    return this.controller;
  }

  /**
   * Get the view width
   */
  getWidth(): number {
    return this.controller.getWidth();
  }

  /**
   * Get the view height
   */
  getHeight(): number {
    return this.controller.getHeight();
  }

  // ========== Listener method proxies ==========
  // Expose controller listener methods to component consumers

  // ===== Camera event listeners =====

  addOnCameraWillChangeListener(listener: OnCameraWillChangeListener): void {
    this.controller.addOnCameraWillChangeListener(listener);
  }

  removeOnCameraWillChangeListener(listener: OnCameraWillChangeListener): void {
    this.controller.removeOnCameraWillChangeListener(listener);
  }

  addOnCameraIsChangingListener(listener: OnCameraIsChangingListener): void {
    this.controller.addOnCameraIsChangingListener(listener);
  }

  removeOnCameraIsChangingListener(listener: OnCameraIsChangingListener): void {
    this.controller.removeOnCameraIsChangingListener(listener);
  }

  addOnCameraDidChangeListener(listener: OnCameraDidChangeListener): void {
    this.controller.addOnCameraDidChangeListener(listener);
  }

  removeOnCameraDidChangeListener(listener: OnCameraDidChangeListener): void {
    this.controller.removeOnCameraDidChangeListener(listener);
  }

  // ===== Map loading listeners =====

  addOnWillStartLoadingMapListener(listener: OnWillStartLoadingMapListener): void {
    this.controller.addOnWillStartLoadingMapListener(listener);
  }

  removeOnWillStartLoadingMapListener(listener: OnWillStartLoadingMapListener): void {
    this.controller.removeOnWillStartLoadingMapListener(listener);
  }

  addOnDidFinishLoadingMapListener(listener: OnDidFinishLoadingMapListener): void {
    this.controller.addOnDidFinishLoadingMapListener(listener);
  }

  removeOnDidFinishLoadingMapListener(listener: OnDidFinishLoadingMapListener): void {
    this.controller.removeOnDidFinishLoadingMapListener(listener);
  }

  addOnDidFailLoadingMapListener(listener: OnDidFailLoadingMapListener): void {
    this.controller.addOnDidFailLoadingMapListener(listener);
  }

  removeOnDidFailLoadingMapListener(listener: OnDidFailLoadingMapListener): void {
    this.controller.removeOnDidFailLoadingMapListener(listener);
  }

  // ===== Rendering listeners =====

  addOnWillStartRenderingFrameListener(listener: OnWillStartRenderingFrameListener): void {
    this.controller.addOnWillStartRenderingFrameListener(listener);
  }

  removeOnWillStartRenderingFrameListener(listener: OnWillStartRenderingFrameListener): void {
    this.controller.removeOnWillStartRenderingFrameListener(listener);
  }

  addOnDidFinishRenderingFrameListener(listener: OnDidFinishRenderingFrameListener): void {
    this.controller.addOnDidFinishRenderingFrameListener(listener);
  }

  removeOnDidFinishRenderingFrameListener(listener: OnDidFinishRenderingFrameListener): void {
    this.controller.removeOnDidFinishRenderingFrameListener(listener);
  }

  addOnDidFinishRenderingFrameWithStatsListener(listener: OnDidFinishRenderingFrameWithStatsListener): void {
    this.controller.addOnDidFinishRenderingFrameWithStatsListener(listener);
  }

  removeOnDidFinishRenderingFrameWithStatsListener(listener: OnDidFinishRenderingFrameWithStatsListener): void {
    this.controller.removeOnDidFinishRenderingFrameWithStatsListener(listener);
  }

  addOnWillStartRenderingMapListener(listener: OnWillStartRenderingMapListener): void {
    this.controller.addOnWillStartRenderingMapListener(listener);
  }

  removeOnWillStartRenderingMapListener(listener: OnWillStartRenderingMapListener): void {
    this.controller.removeOnWillStartRenderingMapListener(listener);
  }

  addOnDidFinishRenderingMapListener(listener: OnDidFinishRenderingMapListener): void {
    this.controller.addOnDidFinishRenderingMapListener(listener);
  }

  removeOnDidFinishRenderingMapListener(listener: OnDidFinishRenderingMapListener): void {
    this.controller.removeOnDidFinishRenderingMapListener(listener);
  }

  // ===== Style listeners =====

  addOnDidFinishLoadingStyleListener(listener: OnDidFinishLoadingStyleListener): void {
    this.controller.addOnDidFinishLoadingStyleListener(listener);
  }

  removeOnDidFinishLoadingStyleListener(listener: OnDidFinishLoadingStyleListener): void {
    this.controller.removeOnDidFinishLoadingStyleListener(listener);
  }

  addOnStyleImageMissingListener(listener: OnStyleImageMissingListener): void {
    this.controller.addOnStyleImageMissingListener(listener);
  }

  removeOnStyleImageMissingListener(listener: OnStyleImageMissingListener): void {
    this.controller.removeOnStyleImageMissingListener(listener);
  }

  addOnCanRemoveUnusedStyleImageListener(listener: OnCanRemoveUnusedStyleImageListener): void {
    this.controller.addOnCanRemoveUnusedStyleImageListener(listener);
  }

  removeOnCanRemoveUnusedStyleImageListener(listener: OnCanRemoveUnusedStyleImageListener): void {
    this.controller.removeOnCanRemoveUnusedStyleImageListener(listener);
  }

  // ===== Other listeners =====

  addOnDidBecomeIdleListener(listener: OnDidBecomeIdleListener): void {
    this.controller.addOnDidBecomeIdleListener(listener);
  }

  removeOnDidBecomeIdleListener(listener: OnDidBecomeIdleListener): void {
    this.controller.removeOnDidBecomeIdleListener(listener);
  }

  addOnSourceChangedListener(listener: OnSourceChangedListener): void {
    this.controller.addOnSourceChangedListener(listener);
  }

  removeOnSourceChangedListener(listener: OnSourceChangedListener): void {
    this.controller.removeOnSourceChangedListener(listener);
  }

  addOnPreCompileShaderListener(listener: OnPreCompileShaderListener): void {
    this.controller.addOnPreCompileShaderListener(listener);
  }

  removeOnPreCompileShaderListener(listener: OnPreCompileShaderListener): void {
    this.controller.removeOnPreCompileShaderListener(listener);
  }

  addOnPostCompileShaderListener(listener: OnPostCompileShaderListener): void {
    this.controller.addOnPostCompileShaderListener(listener);
  }

  removeOnPostCompileShaderListener(listener: OnPostCompileShaderListener): void {
    this.controller.removeOnPostCompileShaderListener(listener);
  }

  addOnShaderCompileFailedListener(listener: OnShaderCompileFailedListener): void {
    this.controller.addOnShaderCompileFailedListener(listener);
  }

  removeOnShaderCompileFailedListener(listener: OnShaderCompileFailedListener): void {
    this.controller.removeOnShaderCompileFailedListener(listener);
  }

  addOnGlyphsLoadedListener(listener: OnGlyphsLoadedListener): void {
    this.controller.addOnGlyphsLoadedListener(listener);
  }

  removeOnGlyphsLoadedListener(listener: OnGlyphsLoadedListener): void {
    this.controller.removeOnGlyphsLoadedListener(listener);
  }

  addOnGlyphsErrorListener(listener: OnGlyphsErrorListener): void {
    this.controller.addOnGlyphsErrorListener(listener);
  }

  removeOnGlyphsErrorListener(listener: OnGlyphsErrorListener): void {
    this.controller.removeOnGlyphsErrorListener(listener);
  }

  addOnGlyphsRequestedListener(listener: OnGlyphsRequestedListener): void {
    this.controller.addOnGlyphsRequestedListener(listener);
  }

  removeOnGlyphsRequestedListener(listener: OnGlyphsRequestedListener): void {
    this.controller.removeOnGlyphsRequestedListener(listener);
  }

  addOnTileActionListener(listener: OnTileActionListener): void {
    this.controller.addOnTileActionListener(listener);
  }

  removeOnTileActionListener(listener: OnTileActionListener): void {
    this.controller.removeOnTileActionListener(listener);
  }

  addOnSpriteLoadedListener(listener: OnSpriteLoadedListener): void {
    this.controller.addOnSpriteLoadedListener(listener);
  }

  removeOnSpriteLoadedListener(listener: OnSpriteLoadedListener): void {
    this.controller.removeOnSpriteLoadedListener(listener);
  }

  addOnSpriteErrorListener(listener: OnSpriteErrorListener): void {
    this.controller.addOnSpriteErrorListener(listener);
  }

  removeOnSpriteErrorListener(listener: OnSpriteErrorListener): void {
    this.controller.removeOnSpriteErrorListener(listener);
  }

  addOnSpriteRequestedListener(listener: OnSpriteRequestedListener): void {
    this.controller.addOnSpriteRequestedListener(listener);
  }

  removeOnSpriteRequestedListener(listener: OnSpriteRequestedListener): void {
    this.controller.removeOnSpriteRequestedListener(listener);
  }

  /**
   * Get the map asynchronously (mirrors the Android getMapAsync pattern)
   * @param callback Map ready callback
   */
  getMapAsync(callback: OnMapReadyCallback): void {
    this.controller.getMapAsync(callback);
  }

  // ========== Rendering control methods ==========

  /**
   * Execute a task on the rendering thread
   */
  queueEvent(runnable: () => void): void {
    this.controller.queueEvent(runnable);
  }

  /**
   * Set the maximum frame rate
   */
  setMaximumFps(maximumFps: number): void {
    this.controller.setMaximumFps(maximumFps);
  }

  /**
   * Set the rendering refresh mode
   */
  setRenderingRefreshMode(mode: RenderingRefreshMode): void {
    this.controller.setRenderingRefreshMode(mode);
  }

  /**
   * Get the rendering refresh mode
   */
  getRenderingRefreshMode(): RenderingRefreshMode {
    return this.controller.getRenderingRefreshMode();
  }

  /**
   * Set the FPS changed listener
   */
  setOnFpsChangedListener(listener: OnFpsChangedListener | null): void {
    this.controller.setOnFpsChangedListener(listener);
  }

  // ========== Performance and cache configuration ==========

  /**
   * Enable or disable tile preloading
   */
  setPrefetchesTiles(enabled: boolean): void {
    this.controller.setPrefetchesTiles(enabled);
  }

  /**
   * Enable or disable tile caching
   */
  setTileCacheEnabled(enabled: boolean): void {
    this.controller.setTileCacheEnabled(enabled);
  }

  /**
   * Set the minimum LOD radius
   */
  setTileLodMinRadius(radius: number): void {
    this.controller.setTileLodMinRadius(radius);
  }

  /**
   * Set the LOD scale factor
   */
  setTileLodScale(scale: number): void {
    this.controller.setTileLodScale(scale);
  }

  /**
   * Set the LOD pitch threshold
   */
  setTileLodPitchThreshold(threshold: number): void {
    this.controller.setTileLodPitchThreshold(threshold);
  }

  /**
   * Set the LOD zoom level offset
   */
  setTileLodZoomShift(shift: number): void {
    this.controller.setTileLodZoomShift(shift);
  }

  // ========== Harmony-style lifecycle methods ==========

  /**
   * Called when the page becomes visible (Harmony lifecycle)
   * Used to resume map rendering
   */
  onPageShow(): void {
    // Resume rendering
    this.controller.triggerRepaint();
  }

  /**
   * Called when the page is hidden (Harmony lifecycle)
   * Used to pause map rendering and location updates to save resources
   */
  onPageHide(): void {
    // Current implementation does not pause rendering; logs only
    // Future enhancements can add more resource management logic
  }

  /**
   * Back button handling (Harmony lifecycle)
   * @returns true if the back event is consumed; false otherwise
   */
  onBackPress(): boolean {

    // Cancel ongoing camera animations
    this.controller.getMapView()?.cancelTransitions();

    // Do not consume the back event; allow the system to handle it
    return false;
  }

  /**
   * Memory pressure callback (Harmony style)
   * @param level Memory pressure level
   */
  onMemoryLevel(level: number): void {
    hilog.warn(DOMAIN, 'NativeMapView', `onMemoryLevel: Memory pressure level ${level}`);

    // Take actions based on the reported memory pressure level
    if (level >= 2) {
      // High memory pressure: clear caches
      this.controller.onLowMemory();
    }
  }

  // ========== Additional APIs aligned with Android/iOS ==========

  /**
   * Set content padding (aligned with the Android API)
   * @param padding Padding array [top, left, bottom, right] (logical pixels)
   */
  setContentPadding(padding: number[]): void {
    this.controller.setContentPadding(padding);
  }

  /**
   * Get content padding (aligned with the Android API)
   * @returns Padding array [top, left, bottom, right]
   */
  getContentPadding(): number[] {
    return this.controller.getContentPadding();
  }

  /**
   * Get the device pixel ratio (aligned with the Android API)
   * @returns Pixel ratio
   */
  getPixelRatio(): number {
    return this.controller.getPixelRatio();
  }

  // ========== Debug features (Debug Mode) ==========

  /**
   * Configure debug options
   * Use the MapDebugOptions bitmask to enable multiple debug features
   *
   * @param debugOptions Bitmask of debug options
   * @example
  * ```typescript
   * // Enable multiple debug options
   * nativeMapView.setDebug(MapDebugOptions.TileBoundaries | MapDebugOptions.CollisionBoxes);
   * ```
   */
  setDebug(debugOptions: number): void {
    const mapView = this.controller.getMapView();
    if (!mapView) {
      hilog.warn(DOMAIN, 'NativeMapView', 'setDebug: Native map view not initialized');
      return;
    }
    try {
      mapView.setDebug(debugOptions);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, 'NativeMapView', `setDebug failed: ${errorMsg}`);
    }
  }

  /**
   * Get the current debug options
   *
   * @returns Bitmask of the currently enabled debug options
   */
  getDebug(): number {
    const mapView = this.controller.getMapView();
    if (!mapView) {
      hilog.warn(DOMAIN, 'NativeMapView', 'getDebug: Native map view not initialized');
      return 0;
    }
    try {
      return mapView.getDebug();
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, 'NativeMapView', `getDebug failed: ${errorMsg}`);
      return 0;
    }
  }

  /**
   * Toggle debug mode quickly (uses the default option set)
   * When enabled, shows tile boundaries, tile info, and collision boxes
   *
   * @param active Whether to enable debug mode
   * @example
  * ```typescript
   * // Quickly enable debug mode
   * nativeMapView.setDebugActive(true);
   *
   * // Disable debug mode
   * nativeMapView.setDebugActive(false);
   * ```
   */
  setDebugActive(active: boolean): void {
    const mapView = this.controller.getMapView();
    if (!mapView) {
      hilog.warn(DOMAIN, 'NativeMapView', 'setDebugActive: Native map view not initialized');
      return;
    }
    try {
      mapView.setDebugActive(active);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, 'NativeMapView', `setDebugActive failed: ${errorMsg}`);
    }
  }

  /**
   * Check whether debug mode is active
   *
   * @returns True if any debug options are enabled
   */
  isDebugActive(): boolean {
    const mapView = this.controller.getMapView();
    if (!mapView) {
      hilog.warn(DOMAIN, 'NativeMapView', 'isDebugActive: Native map view not initialized');
      return false;
    }
    try {
      return mapView.isDebugActive();
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, 'NativeMapView', `isDebugActive failed: ${errorMsg}`);
      return false;
    }
  }
}
