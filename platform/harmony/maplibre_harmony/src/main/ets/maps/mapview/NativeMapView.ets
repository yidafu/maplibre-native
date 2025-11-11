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
import { InfoWindowOverlay, InfoWindowState } from '../annotations/InfoWindowOverlay';
import { InfoWindowPosition } from '../annotations/InfoWindow';
import { NativeViewAnnotationOverlay, ViewAnnotationRenderState } from '../annotations/NativeViewAnnotationOverlay';
import { NativeViewAnnotationOptions, NativeViewAnnotationFrame } from '../annotations/NativeViewAnnotationTypes';
import { LatLng } from '../geometry/LatLng';
import { UiSettings } from '../UiSettings';
import { CompassView } from '../widgets/CompassView';
import { LogoView } from '../widgets/LogoView';
import { ScaleBarView } from '../widgets/ScaleBarView';
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
  @State private visibleInfoWindows: InfoWindowState[] = [];
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
          console.info(`[NativeMapView] Setting up InfoWindow callbacks before onMapReady...`);
          this.setupInfoWindowCallbacks();
          console.info(`[NativeMapView] InfoWindow callbacks setup completed`);

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

      // 6. Reset InfoWindow state
      this.visibleInfoWindows = [];

      // 7. Reset AnnotationView state
      this.visibleAnnotationViews = [];
      this.controller.clearViewAnnotationRenderCallback();
      this.logViewAnnotationStateChanges([]);
      this.viewAnnotationFrames = [];

    } catch (error) {
      this.logNativeMapViewError('Error in aboutToDisappear', error);
    }
  }

  /**
   * 获取 Compass 的 X 位置
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
   * 获取 Compass 的 Y 位置
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
   * Configure InfoWindowManager UI callbacks
   */
  setupInfoWindowCallbacks(): void {
    console.info(`[NativeMapView] setupInfoWindowCallbacks called`);
    try {
      const mapLibreMap = this.controller.getMapLibreMapInstance();
      console.info(`[NativeMapView] MapLibreMap instance: ${mapLibreMap ? 'exists' : 'null'}`);
      if (!mapLibreMap) {
        hilog.warn(DOMAIN, 'NativeMapView', 'MapLibreMap instance not available for InfoWindow setup');
        return;
      }

      const infoWindowManager = mapLibreMap.getInfoWindowManager();
      console.info(`[NativeMapView] InfoWindowManager instance: ${infoWindowManager ? 'exists' : 'null'}`);

      // Show InfoWindow
      infoWindowManager.setOnShowUICallback((marker: Marker, position: InfoWindowPosition) => {
        console.info(`[NativeMapView] onShowUICallback triggered for marker: ${marker.getTitle()}, position: (${position.x}, ${position.y})`);
        console.info(`[NativeMapView] Marker details - ID: ${marker.getId()}, title: "${marker.getTitle()}", snippet: "${marker.getSnippet()}"`);
        console.info(`[NativeMapView] Position details - x: ${position.x}, y: ${position.y}, arrowOffsetX: ${position.arrowOffsetX}`);
        
        const existingIndex = this.visibleInfoWindows.findIndex(
          item => item.marker.getId() === marker.getId()
        );

        const style = mapLibreMap.getMarkerManager().getInfoWindowStyle(marker);
        console.info(`[NativeMapView] InfoWindow style: ${style ? 'exists' : 'null'}`);

        const newState: InfoWindowState = {
          marker: marker, // Keep reference for callbacks
          markerId: marker.getId(),
          markerTitle: marker.getTitle(),
          markerSnippet: marker.getSnippet(),
          position: position,
          style: style,
          key: `infowindow-${marker.getId()}-${Date.now()}`
        };

        if (existingIndex >= 0) {
          console.info(`[NativeMapView] Updating existing InfoWindow at index ${existingIndex}`);
          this.visibleInfoWindows[existingIndex] = newState;
        } else {
          console.info(`[NativeMapView] Adding new InfoWindow, total will be: ${this.visibleInfoWindows.length + 1}`);
          this.visibleInfoWindows.push(newState);
        }
        
        console.info(`[NativeMapView] visibleInfoWindows updated, count: ${this.visibleInfoWindows.length}`);
        console.info(`[NativeMapView] Last added state - marker title: "${newState.marker.getTitle()}", position: (${newState.position.x}, ${newState.position.y})`);
      });

      // Hide InfoWindow
      infoWindowManager.setOnHideUICallback((marker: Marker) => {
        const index = this.visibleInfoWindows.findIndex(
          item => item.marker.getId() === marker.getId()
        );
        if (index >= 0) {
          this.visibleInfoWindows.splice(index, 1);
        }
      });

      // Update InfoWindow position
      infoWindowManager.setOnUpdateUICallback((marker: Marker, position: InfoWindowPosition) => {
        console.info(`[NativeMapView] setOnUpdateUICallback called for marker: ${marker.getTitle()}, new position: (${position.x}, ${position.y})`);
        const index = this.visibleInfoWindows.findIndex(
          item => item.marker.getId() === marker.getId()
        );
        if (index >= 0) {
          // 🔧 Key fix: create a new array reference to trigger @State change detection
          // ArkUI @State detects reference changes, not internal property changes
          // Use slice() to create a shallow copy and replace the specific element
          const newArray = this.visibleInfoWindows.slice();
          const oldItem = newArray[index];
          // 🔧 Key fix: update the key to force ForEach re-render
          // ForEach relies on keys to decide whether to update components
          // Append a timestamp so each position change triggers re-rendering
          const newKey = `${oldItem.markerId}_${Date.now()}`;
          newArray[index] = {
            marker: oldItem.marker,
            markerId: oldItem.markerId,
            markerTitle: oldItem.markerTitle,
            markerSnippet: oldItem.markerSnippet,
            position: { x: position.x, y: position.y, arrowOffsetX: position.arrowOffsetX },
            style: oldItem.style,
            key: newKey
          };
          this.visibleInfoWindows = newArray;
          console.info(`[NativeMapView] InfoWindow position updated in @State array: (${position.x}, ${position.y}), new key: ${newKey}`);
        } else {
          console.warn(`[NativeMapView] setOnUpdateUICallback - marker not found in visibleInfoWindows: ${marker.getTitle()}`);
        }
      });

      console.info(`[NativeMapView] InfoWindow callbacks set successfully`);

      // ========== Configure AnnotationView callbacks ==========
      const annotationViewManager = mapLibreMap.getMarkerManager().getAnnotationViewManager();

      // 监听 AnnotationView 数据变化，更新 UI
      // 注意：由于 AnnotationViewManager 目前没有回调机制，我们需要在相机移动时更新
      // 这将在相机监听器中实现

    } catch (error) {
      this.logNativeMapViewError('Failed to setup InfoWindow/AnnotationView callbacks', error);
      const errorStack = this.getErrorStack(error);
      const errorMsg = this.getErrorMessage(error);
      console.error(`[NativeMapView] Error details: ${errorStack ?? errorMsg}`);
    }
  }

  /**
   * 构建组件
   */
  build() {
    Stack() {
      // 地图 XComponent
      XComponent({
        type: XComponentType.SURFACE,
        controller: this.controller,
      })
        .width('100%')
        .height('100%')
        .parallelGesture(
          // 使用 GestureGroup 组合多个手势，允许并行识别
          GestureGroup(GestureMode.Parallel,
            // 平移手势 - 单指拖动
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

            // 缩放手势 - 双指捏合
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

            // 旋转手势 - 双指旋转
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
        // 双击手势 - 使用 priorityGesture 确保优先级最高
        .priorityGesture(
          TapGesture({ count: 2 })
            .onAction((event: GestureEvent) => {
              this.controller.getGestureDetector().onDoubleTap(event);
            }),
          GestureMask.Normal
        )
        // 长按手势 - 独立绑定
        .gesture(
          LongPressGesture({ repeat: false, duration: 500 })
            .onAction((event: GestureEvent) => {
              this.controller.getGestureDetector().onLongPress(event);
            })
        )
        // 单击手势 - 独立绑定，系统会自动处理与长按的冲突
        .gesture(
          TapGesture({ count: 1 })
            .onAction((event: GestureEvent) => {
              this.controller.getGestureDetector().onSingleTap(event);
            })
        )
        .gesture(
          // Tilt 手势 - 双指垂直拖动
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

      // Compass 组件 - 根据 UiSettings 配置定位（绝对定位）
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

      // Logo 组件 - 根据 UiSettings 配置定位（绝对定位）
      if (this.controller.getUiSettings().isLogoEnabled()) {
        LogoView({
          logoEnabled: this.controller.getUiSettings().isLogoEnabled()
        })
          .width(80)
          .height(40)
          .position({ x: this.getLogoX(), y: this.getLogoY() })
      }

      // ScaleBar 组件 - 根据 UiSettings 配置定位（绝对定位）
      if (this.controller.getUiSettings().isScaleBarEnabled()) {
        ScaleBarView({
          isEnabled: this.controller.getUiSettings().isScaleBarEnabled(),
          metersPerPixel: this.scaleBarMetersPerPixel,
          unitSystem: this.controller.getUiSettings().getScaleBarUnit(),
          useDarkStyles: this.controller.getUiSettings().isScaleBarUseDarkStyles()
        })
          .position({ x: this.getScaleBarX(), y: this.getScaleBarY() })
      }

      // AnnotationView 覆盖层 - 显示所有自定义 AnnotationView
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

      // InfoWindow 覆盖层 - 显示所有 InfoWindow
      InfoWindowOverlay({
        visibleInfoWindows: this.visibleInfoWindows,
        onInfoWindowClick: (marker: Marker) => {
          try {
            const mapLibreMap = this.controller.getMapLibreMapInstance();
            if (mapLibreMap) {
              mapLibreMap.getInfoWindowManager().triggerClick(marker);
            }
          } catch (error) {
            this.logNativeMapViewError('InfoWindow click error', error);
          }
        },
        onInfoWindowLongClick: (marker: Marker) => {
          try {
            const mapLibreMap = this.controller.getMapLibreMapInstance();
            if (mapLibreMap) {
              mapLibreMap.getInfoWindowManager().triggerLongClick(marker);
            }
          } catch (error) {
            this.logNativeMapViewError('InfoWindow long click error', error);
          }
        },
        onInfoWindowClose: (marker: Marker) => {
          try {
            marker.hideInfoWindow();
          } catch (error) {
            this.logNativeMapViewError('InfoWindow close error', error);
          }
        },
        onInfoWindowSizeChanged: (marker: Marker, width: number, height: number) => {
          try {
            const mapLibreMap = this.controller.getMapLibreMapInstance();
            if (mapLibreMap) {
              const infoWindowManager = mapLibreMap.getInfoWindowManager();
              const infoWindow = infoWindowManager.get(marker);
              if (infoWindow) {
                const oldWidth = infoWindow.getWidth();
                const oldHeight = infoWindow.getHeight();
                const EPSILON = 0.1;
                if (Math.abs(width - oldWidth) < EPSILON && Math.abs(height - oldHeight) < EPSILON) {
                  return;
                }
                console.info(`[NativeMapView] InfoWindow size changed: ${oldWidth}x${oldHeight} -> ${width}x${height}, updating position`);
                infoWindow.setSize(width, height);
                const pos = marker.getPosition();
                const screenPoint = mapLibreMap.pixelForLatLng(pos.latitude, pos.longitude);
                console.info(`[NativeMapView] Recalculating position with actual size, marker pos: (${screenPoint.x}, ${screenPoint.y})`);
                const viewWidth = mapLibreMap.getViewWidth();
                const viewHeight = mapLibreMap.getViewHeight();
                infoWindow.update(viewWidth, viewHeight, screenPoint);
                console.info(`[NativeMapView] InfoWindow position updated after size change`);
              }
            }
          } catch (error) {
            this.logNativeMapViewError('InfoWindow size changed error', error);
          }
        }
      })

      // 声明式子组件渲染（Marker、Source、Layer 等）
      if (this.children) {
        this.children()
      }
    }
  }

  /**
   * 添加平移手势监听器
   */
  addOnMoveListener(listener: OnMoveListener): void {
    this.controller.getGestureDetector().addOnMoveListener(listener);
  }

  /**
   * 添加缩放手势监听器
   */
  addOnScaleListener(listener: OnScaleListener): void {
    this.controller.getGestureDetector().addOnScaleListener(listener);
  }

  /**
   * 添加旋转手势监听器
   */
  addOnRotateListener(listener: OnRotateListener): void {
    this.controller.getGestureDetector().addOnRotateListener(listener);
  }

  /**
   * 添加点击监听器
   */
  addOnMapClickListener(listener: OnMapClickListener): void {
    this.controller.getGestureDetector().addOnMapClickListener(listener);
  }

  /**
   * 添加长按监听器
   */
  addOnMapLongClickListener(listener: OnMapLongClickListener): void {
    this.controller.getGestureDetector().addOnMapLongClickListener(listener);
  }

  /**
   * 添加双击监听器
   */
  addOnDoubleTapListener(listener: OnDoubleTapListener): void {
    this.controller.getGestureDetector().addOnDoubleTapListener(listener);
  }

  /**
   * 添加倾斜监听器
   */
  addOnTiltListener(listener: OnTiltListener): void {
    this.controller.getGestureDetector().addOnTiltListener(listener);
  }

  /**
   * 添加 Quick Zoom 监听器
   */
  addOnQuickZoomListener(listener: OnQuickZoomListener): void {
    this.controller.getGestureDetector().addOnQuickZoomListener(listener);
  }

  /**
   * 获取地图俯仰角度
   * @returns 当前俯仰角度（度）
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
   * 设置地图俯仰角度
   * @param pitch 俯仰角度（度，0-60）
   * @param duration 可选的动画时长（毫秒），默认为 0（不使用动画）
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
   * 获取 UI 设置
   */
  getUiSettings(): UiSettings {
    return this.controller.getUiSettings();
  }

  /**
   * 设置 MapLibreMap 实例（用于 InfoWindow 管理）
   * 应在创建 MapLibreMap 后立即调用
   */
  setMapLibreMap(mapLibreMap: MapLibreMap): void {
    this.controller.setMapLibreMapInstance(mapLibreMap);
    // 立即设置 InfoWindow 回调
    this.setupInfoWindowCallbacks();
  }

  /**
   * 设置地图样式
   */
  setStyleUrl(url: string): void {
    this.styleUrl = url;
    this.controller.setStyleUrl(url);
  }

  /**
   * 取消所有正在进行的相机过渡动画
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
   * 跳转到指定位置
   */
  jumpTo(angle: number, latitude: number, longitude: number, pitch: number, zoom: number): void {
    this.controller.jumpTo(angle, latitude, longitude, pitch, zoom);
  }

  /**
   * 飞行到指定位置（带飞行动画）
   * @param options 相机选项
   * @param duration 动画持续时间（毫秒）
   */
  flyTo(options: CameraOptions, duration: number): void {
    this.controller.flyTo(options, duration);
  }

  /**
   * 平滑过渡到指定位置
   * @param options 相机选项
   * @param duration 动画持续时间（毫秒）
   */
  easeTo(options: CameraOptions, duration: number): void {
    this.controller.easeTo(options, duration);
  }

  /**
   * 添加标记
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
   * 触发重绘
   */
  triggerRepaint(): void {
    this.controller.triggerRepaint();
  }

  /**
   * 显示/隐藏地图
   */
  setVisible(visible: boolean): void {
    this.isVisible = visible;
  }

  /**
   * 获取地图控制器
   */
  getController(): NativeMapViewController {
    return this.controller;
  }

  /**
   * 获取视图宽度
   */
  getWidth(): number {
    return this.controller.getWidth();
  }

  /**
   * 获取视图高度
   */
  getHeight(): number {
    return this.controller.getHeight();
  }

  // ========== 监听器方法代理 ==========
  // 将 Controller 的监听器方法暴露给组件使用者

  // ===== 相机事件监听器 =====

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

  // ===== 地图加载事件监听器 =====

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

  // ===== 渲染事件监听器 =====

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

  // ===== 样式事件监听器 =====

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

  // ===== 其他事件监听器 =====

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
   * 获取地图异步（对齐 Android getMapAsync 模式）
   * @param callback 地图就绪回调
   */
  getMapAsync(callback: OnMapReadyCallback): void {
    this.controller.getMapAsync(callback);
  }

  // ========== 渲染控制方法 ==========

  /**
   * 在渲染线程上执行任务
   */
  queueEvent(runnable: () => void): void {
    this.controller.queueEvent(runnable);
  }

  /**
   * 设置最大帧率
   */
  setMaximumFps(maximumFps: number): void {
    this.controller.setMaximumFps(maximumFps);
  }

  /**
   * 设置渲染刷新模式
   */
  setRenderingRefreshMode(mode: RenderingRefreshMode): void {
    this.controller.setRenderingRefreshMode(mode);
  }

  /**
   * 获取渲染刷新模式
   */
  getRenderingRefreshMode(): RenderingRefreshMode {
    return this.controller.getRenderingRefreshMode();
  }

  /**
   * 设置 FPS 变化监听器
   */
  setOnFpsChangedListener(listener: OnFpsChangedListener | null): void {
    this.controller.setOnFpsChangedListener(listener);
  }

  // ========== 性能和缓存配置 ==========

  /**
   * 设置是否预加载瓦片
   */
  setPrefetchesTiles(enabled: boolean): void {
    this.controller.setPrefetchesTiles(enabled);
  }

  /**
   * 设置是否启用瓦片缓存
   */
  setTileCacheEnabled(enabled: boolean): void {
    this.controller.setTileCacheEnabled(enabled);
  }

  /**
   * 设置 LOD 最小半径
   */
  setTileLodMinRadius(radius: number): void {
    this.controller.setTileLodMinRadius(radius);
  }

  /**
   * 设置 LOD 缩放因子
   */
  setTileLodScale(scale: number): void {
    this.controller.setTileLodScale(scale);
  }

  /**
   * 设置 LOD 俯仰角阈值
   */
  setTileLodPitchThreshold(threshold: number): void {
    this.controller.setTileLodPitchThreshold(threshold);
  }

  /**
   * 设置 LOD 缩放级别偏移
   */
  setTileLodZoomShift(shift: number): void {
    this.controller.setTileLodZoomShift(shift);
  }

  // ========== 鸿蒙风格的生命周期方法 ==========

  /**
   * 页面显示时调用（鸿蒙生命周期）
   * 用于恢复地图渲染
   */
  onPageShow(): void {
    // 恢复渲染
    this.controller.triggerRepaint();
  }

  /**
   * 页面隐藏时调用（鸿蒙生命周期）
   * 用于暂停地图渲染、暂停定位等，节省资源
   */
  onPageHide(): void {
    // 当前实现不暂停渲染，仅记录日志
    // 未来可以添加更多资源管理逻辑
  }

  /**
   * 返回键处理（鸿蒙生命周期）
   * @returns true 表示消费了返回事件，false 表示不消费
   */
  onBackPress(): boolean {

    // 取消正在进行的相机动画
    this.controller.getMapView()?.cancelTransitions();

    // 不消费返回事件，让系统处理
    return false;
  }

  /**
   * 内存压力回调（鸿蒙风格）
   * @param level 内存压力级别
   */
  onMemoryLevel(level: number): void {
    hilog.warn(DOMAIN, 'NativeMapView', `onMemoryLevel: Memory pressure level ${level}`);

    // 根据内存压力级别采取不同措施
    if (level >= 2) {
      // 高内存压力：清理缓存
      this.controller.onLowMemory();
    }
  }

  // ========== 新增方法：对齐 Android/iOS API ==========

  /**
   * 设置内容边距（对齐 Android API）
   * @param padding 边距数组 [top, left, bottom, right]（逻辑像素）
   */
  setContentPadding(padding: number[]): void {
    this.controller.setContentPadding(padding);
  }

  /**
   * 获取内容边距（对齐 Android API）
   * @returns 边距数组 [top, left, bottom, right]
   */
  getContentPadding(): number[] {
    return this.controller.getContentPadding();
  }

  /**
   * 获取设备像素比（对齐 Android API）
   * @returns 像素比
   */
  getPixelRatio(): number {
    return this.controller.getPixelRatio();
  }

  // ========== 调试功能（Debug Mode）==========

  /**
   * 设置调试选项
   * 使用 MapDebugOptions 枚举值的位掩码来启用多个调试功能
   *
   * @param debugOptions 调试选项的位掩码
   * @example
  * ```typescript
   * // 启用多个调试选项
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
   * 获取当前调试选项
   *
   * @returns 当前启用的调试选项位掩码
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
   * 快速开关调试模式（使用默认调试选项组合）
   * 启用时会显示：瓦片边界、瓦片信息和碰撞框
   *
   * @param active 是否启用调试模式
   * @example
  * ```typescript
   * // 快速启用调试模式
   * nativeMapView.setDebugActive(true);
   *
   * // 关闭调试模式
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
   * 检查是否处于调试模式
   *
   * @returns 是否有任何调试选项被启用
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
