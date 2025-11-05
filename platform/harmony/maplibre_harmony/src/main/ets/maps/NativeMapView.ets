import maplibre, { NativeMapView as NativeMapViewNAPI } from 'libmaplibre.so';
import { hilog } from '@kit.PerformanceAnalysisKit';
import common from '@ohos.app.ability.common';
import { LatLng } from './geometry/LatLng';
import { DOMAIN } from '../constants/HiLogConstants';
import { MapGestureDetector } from './gestures/MapGestureDetector';
import { UiSettings } from './UiSettings';
import {
  OnDoubleTapListener,
  OnMapClickListener,
  OnMapLongClickListener,
  OnMoveListener,
  OnQuickZoomListener,
  OnRotateListener,
  OnScaleListener,
  OnTiltListener
} from './gestures/GestureListeners';
import { CompassView } from './widgets/CompassView';
import { LogoView } from './widgets/LogoView';
import { ScaleBarView } from './widgets/ScaleBarView';
import { OrnamentPosition, RenderingRefreshMode } from './types/NativeTypes';
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
} from './listeners/MapEventListeners';
import { InfoWindowOverlay, InfoWindowState } from './annotations/InfoWindowOverlay';
import { InfoWindowPosition } from './annotations/InfoWindow';
import { AnnotationViewOverlay } from './annotations/AnnotationViewOverlay';
import { AnnotationViewData } from './annotations/AnnotationViewManager';
import { MapLibreMap } from './MapLibreMap';
import { MapLibreMapOptions } from './MapLibreMapOptions';
import { Marker } from './annotations/Marker';

// 类型别名：区分 NAPI 的 NativeMapView 和 ETS 组件
type NativeMapView = NativeMapViewNAPI;

// MapView 组件接口（用于类型声明，避免循环引用）
interface MapViewComponent {
  setupInfoWindowCallbacks(): void;
}

// 从 NAPI 模块导入相机选项类型
type CameraOptions = maplibre.CameraOptions;

type NullableNativeMapView = NativeMapView | null

/**
 * 全局映射：NAPI NativeMapView -> ETS NativeMapViewController
 * 用于 MapLibreMap 找到对应的 controller 并注册自己
 */
const globalControllerMap: Map<NativeMapView, NativeMapViewController> = new Map();

/**
 * 注册 MapLibreMap 实例到对应的 NativeMapViewController
 * 此函数由 MapLibreMap 构造函数调用
 *
 * @param nativeMapView NAPI NativeMapView 实例
 * @param mapLibreMap MapLibreMap 实例
 * @param nativeMapViewComponent 可选的 MapView 组件引用（ETS 组件），用于设置 InfoWindow 回调
 */
export function registerMapLibreMap(
  nativeMapView: NativeMapView,
  mapLibreMap: MapLibreMap,
  nativeMapViewComponent?: MapViewComponent
): void {
  const controller = globalControllerMap.get(nativeMapView);
  if (controller) {
    controller.setMapLibreMapInstance(mapLibreMap);

    // 连接 Compass 更新回调
    mapLibreMap.onCompassUpdate = (bearing: number) => {
      controller.updateCompassBearing();
    };

    // 连接 ScaleBar 更新回调
    mapLibreMap.onScaleBarUpdate = (metersPerPixel: number) => {
      controller.updateScaleBarMetersPerPixel(metersPerPixel);
    };

    // 立即触发一次初始更新（确保 Compass 和 ScaleBar 有正确的初始值）
    try {
      const bearing = mapLibreMap.getBearing();
      controller.updateCompassBearing();

      const latLng = mapLibreMap.getLatLng();
      const metersPerPixel = mapLibreMap.getMetersPerPixelAtLatitude(latLng.latitude);
      controller.updateScaleBarMetersPerPixel(metersPerPixel);
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `Failed to trigger initial widget updates: ${error}`);
    }

    // 如果提供了组件引用，立即设置 InfoWindow 回调
    // 否则，延迟设置（在 aboutToAppear 中已经设置了延迟逻辑）
    if (nativeMapViewComponent) {
      nativeMapViewComponent.setupInfoWindowCallbacks();
    }
  } else {
    hilog.warn(DOMAIN, 'NativeMapView', 'Controller not found for MapLibreMap registration');
  }
}

/**
 * NativeMapViewController - 地图视图控制器
 */
class NativeMapViewController extends XComponentController {
  private nativeMapView: NullableNativeMapView = null;
  private isInitialized: boolean = false;
  private hasTriggeredMapReady: boolean = false; // 标记是否已触发过 onMapReady 回调（用于控制 onMapReady 只触发一次）
  private surfaceId: string = '';
  private surfaceWidth: number = 0;
  private surfaceHeight: number = 0;
  private pixelRatio: number = 1.0; // 保存设备像素比
  private isSurfaceRectSet: boolean = false; // 防止setXComponentSurfaceRect无限循环
  // 初始配置
  public styleUrl: string = "https://demotiles.maplibre.org/style.json";
  public initialLatitude: number = 30.2741;
  public initialLongitude: number = 120.1551;
  public initialZoom: number = 6;
  public initialBearing: number = 0;
  public initialPitch: number = 0;
  // 回调函数
  public onMapReadyCallback?: (mapView?: NativeMapView) => void;
  public onMapViewCreatedCallback?: (mapLibreMap: MapLibreMap) => void;
  // MapLibreMap 实例引用（用于 InfoWindow 管理）
  private mapLibreMapInstance: MapLibreMap | null = null;
  // 手势系统
  private uiSettings: UiSettings = new UiSettings();
  private gestureDetector: MapGestureDetector = new MapGestureDetector(this.uiSettings);
  // UI 组件状态
  private compassBearingUpdateCallback?: (bearing: number) => void;
  private uiSettingsUpdateCallback?: () => void;
  // ========== 监听器管理系统 ==========

  // 相机事件监听器
  private onCameraWillChangeListeners: OnCameraWillChangeListener[] = [];
  private onCameraIsChangingListeners: OnCameraIsChangingListener[] = [];
  private onCameraDidChangeListeners: OnCameraDidChangeListener[] = [];
  // 地图加载事件监听器
  private onWillStartLoadingMapListeners: OnWillStartLoadingMapListener[] = [];
  private onDidFinishLoadingMapListeners: OnDidFinishLoadingMapListener[] = [];
  private onDidFailLoadingMapListeners: OnDidFailLoadingMapListener[] = [];
  // 渲染事件监听器
  private onWillStartRenderingFrameListeners: OnWillStartRenderingFrameListener[] = [];
  private onDidFinishRenderingFrameListeners: OnDidFinishRenderingFrameListener[] = [];
  private onDidFinishRenderingFrameWithStatsListeners: OnDidFinishRenderingFrameWithStatsListener[] = [];
  private onWillStartRenderingMapListeners: OnWillStartRenderingMapListener[] = [];
  private onDidFinishRenderingMapListeners: OnDidFinishRenderingMapListener[] = [];
  // 样式事件监听器
  private onDidFinishLoadingStyleListeners: OnDidFinishLoadingStyleListener[] = [];
  private onStyleImageMissingListeners: OnStyleImageMissingListener[] = [];
  private onCanRemoveUnusedStyleImageListeners: OnCanRemoveUnusedStyleImageListener[] = [];
  // 其他事件监听器
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
  // 地图就绪回调列表
  private onMapReadyCallbacks: OnMapReadyCallback[] = [];

  /**
   * 表面创建回调
   *
   * 🛡️ 修复第二次进入地图崩溃问题：
   * 延迟 EGL 初始化，等待页面转换动画完成后再设置 Native Window
   */
  onSurfaceCreated(surfaceId: string): void {

    hilog.warn(DOMAIN, "NativeMapView", `🌟 onSurfaceCreated START - surfaceId: ${surfaceId}`);
    this.surfaceId = surfaceId;

    try {
      // 获取应用上下文
      const context = getContext() as common.UIAbilityContext;

      // 使用应用私有缓存目录 + maplibre 子目录
      const cachePath = context.cacheDir + '/maplibre';

      // 创建 MapView 实例并传递缓存路径
      hilog.warn(DOMAIN, "NativeMapView", `[DEBUG] Creating NativeMapView instance with cachePath...`);
      this.nativeMapView = new NativeMapViewNAPI(cachePath);
      hilog.warn(DOMAIN, "NativeMapView", `[DEBUG] NativeMapView instance created successfully`);

      // 注册到全局映射
      if (this.nativeMapView) {
        globalControllerMap.set(this.nativeMapView, this);
      }

      // ✅ DPI 现在由 C++ 层直接获取（使用 OH_NativeDisplayManager_GetDefaultDisplayDensityDpi）
      // 不再需要从 ArkTS 传递

      // 🛡️ 延迟初始化：等待页面转换动画完成（通常需要 400-500ms）
      // ✅ 修复第二次进入崩溃：延迟增加到 800ms，确保 Native Window 完全稳定
      // 原因：页面转换动画可能需要更长时间，特别是在低性能设备上

      setTimeout(() => {
        try {
          if (!this.nativeMapView) {
            hilog.warn(DOMAIN, "NativeMapView", `mapView was destroyed before initialization`);
            return;
          }

          // 设置渲染表面（使用默认方法，尺寸将在onSurfaceChanged中处理）
          this.nativeMapView.setNativeWindow(BigInt(surfaceId));

          // 设置地图样式
          this.nativeMapView.setStyleUrl(this.styleUrl);

        } catch (error) {
          hilog.error(DOMAIN, "NativeMapView", `Delayed initialization failed: ${error.message}`);
        }
      }, 800); // ✅ 延迟 800ms，确保页面转换完全完成（从 500ms 增加）

      // 延迟调用 jumpTo，等待地图完全初始化
      setTimeout(() => {
        try {
          if (this.nativeMapView && this.isInitialized) {
            this.nativeMapView.jumpTo(this.initialBearing, this.initialLatitude, this.initialLongitude, this.initialPitch,
              this.initialZoom);
          } else {
            hilog.warn(DOMAIN, 'NativeMapView', `Delayed jumpTo skipped - mapView=${this.nativeMapView ? 'exists' :
              'null'}, initialized=${this.isInitialized}`);
          }
        } catch (jumpErr) {
          hilog.error(DOMAIN, 'NativeMapView', `Delayed jumpTo failed: ${jumpErr.message}`);
          if (jumpErr.stack) {
            hilog.error(DOMAIN, 'NativeMapView', `Stack: ${jumpErr.stack}`);
          }
        }
      }, 300); // 延迟 300ms 确保地图完全初始化

      this.isInitialized = true;

      // 🔧 不再调用 setXComponentSurfaceRect
      // Native Window 会自动使用正确的尺寸
      // C++ 层通过 pixelRatio 计算物理像素用于渲染

      // 确保 mapView 已初始化
      if (!this.nativeMapView) {
        hilog.error(DOMAIN, 'NativeMapView', 'mapView is null after initialization');
        return;
      }

      // 设置手势检测器的地图控制器引用
      this.gestureDetector.setMapController(this.nativeMapView);

      // 设置相机监听器来更新 Compass 和 AnnotationView
      this.nativeMapView.addOnCameraMoveListener(() => {
        this.updateCompassBearing();
        this.updateAnnotationViews();
      });

      // ========== 注册 Android/iOS 风格的监听器回调到 C++ 层 ==========

      // ✅ 注册 Map 生命周期回调
      // 此回调在 C++ Map 对象创建完成后触发，早于样式加载
      this.nativeMapView.setOnMapViewCreatedCallback(() => {
        hilog.info(DOMAIN, 'NativeMapView', '📢 Received onMapViewCreated callback from C++');
        this.handleMapViewCreated();
      });

      // 相机事件监听器
      this.nativeMapView.addOnCameraWillChangeListener((animated: boolean) => {
        for (const listener of this.onCameraWillChangeListeners) {
          try {
            listener.onCameraWillChange(animated);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnCameraWillChangeListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnCameraIsChangingListener(() => {
        for (const listener of this.onCameraIsChangingListeners) {
          try {
            listener.onCameraIsChanging();
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnCameraIsChangingListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnCameraDidChangeListener((animated: boolean) => {
        for (const listener of this.onCameraDidChangeListeners) {
          try {
            listener.onCameraDidChange(animated);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnCameraDidChangeListener error: ${error.message}`);
          }
        }
      });

      // 地图加载事件监听器
      this.nativeMapView.addOnWillStartLoadingMapListener(() => {
        for (const listener of this.onWillStartLoadingMapListeners) {
          try {
            listener.onWillStartLoadingMap();
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnWillStartLoadingMapListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnDidFinishLoadingMapListener(() => {
        for (const listener of this.onDidFinishLoadingMapListeners) {
          try {
            listener.onDidFinishLoadingMap();
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnDidFinishLoadingMapListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnDidFailLoadingMapListener((errorMessage: string) => {
        for (const listener of this.onDidFailLoadingMapListeners) {
          try {
            listener.onDidFailLoadingMap(errorMessage);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnDidFailLoadingMapListener error: ${error.message}`);
          }
        }
      });

      // 渲染事件监听器
      this.nativeMapView.addOnWillStartRenderingFrameListener(() => {
        for (const listener of this.onWillStartRenderingFrameListeners) {
          try {
            listener.onWillStartRenderingFrame();
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnWillStartRenderingFrameListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnDidFinishRenderingFrameListener((fully: boolean, frameEncodingTime: number,
        frameRenderingTime: number) => {
        // 通知简单版本的监听器
        for (const listener of this.onDidFinishRenderingFrameListeners) {
          try {
            listener.onDidFinishRenderingFrame(fully, frameEncodingTime, frameRenderingTime);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnDidFinishRenderingFrameListener error: ${error.message}`);
          }
        }
        // 通知带统计信息的监听器
        const stats = new RenderingStats(fully, frameEncodingTime, frameRenderingTime);
        for (const listener of this.onDidFinishRenderingFrameWithStatsListeners) {
          try {
            listener.onDidFinishRenderingFrame(fully, stats);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnDidFinishRenderingFrameWithStatsListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnWillStartRenderingMapListener(() => {
        for (const listener of this.onWillStartRenderingMapListeners) {
          try {
            listener.onWillStartRenderingMap();
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnWillStartRenderingMapListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnDidFinishRenderingMapListener((fully: boolean) => {
        for (const listener of this.onDidFinishRenderingMapListeners) {
          try {
            listener.onDidFinishRenderingMap(fully);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnDidFinishRenderingMapListener error: ${error.message}`);
          }
        }
      });

      // 样式事件监听器
      this.nativeMapView.addOnDidFinishLoadingStyleListener(() => {

        if (!this.nativeMapView) {
          hilog.warn(DOMAIN, 'NativeMapView', '⚠️ MapView is null, cannot call callbacks');
          return;
        }

        // ========== 只在首次初始化时调用 onMapReady 回调 ==========
        // 参考 Android 和 iOS 实现：onMapReady 只在地图首次加载完成时触发一次
        // setStyleUrl 等后续样式切换不应重复触发 onMapReady
        if (!this.hasTriggeredMapReady) {
          this.hasTriggeredMapReady = true;
          hilog.warn(DOMAIN, 'NativeMapView', '🚀 First style loaded - triggering onMapReady callbacks');

          // 调用 onMapReady 回调
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

          // 调用所有通过 getMapAsync 注册的回调
          if (this.onMapReadyCallbacks.length > 0) {
            for (const callback of this.onMapReadyCallbacks) {
              try {
                callback.onMapReady(this.mapLibreMapInstance);
              } catch (callbackError) {
                hilog.error(DOMAIN, 'NativeMapView', `getMapAsync callback error: ${callbackError.message}`);
              }
            }
            // 清空回调列表
            this.onMapReadyCallbacks = [];
          }
        } else {
          hilog.warn(DOMAIN, 'NativeMapView', '♻️ Style reloaded - skipping onMapReady (already initialized)');
        }

        // ========== 每次样式加载完成都触发样式监听器 ==========
        // 通知用户的 OnDidFinishLoadingStyleListener
        for (const listener of this.onDidFinishLoadingStyleListeners) {
          try {
            listener.onDidFinishLoadingStyle();
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnDidFinishLoadingStyleListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnStyleImageMissingListener((id: string) => {
        for (const listener of this.onStyleImageMissingListeners) {
          try {
            listener.onStyleImageMissing(id);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnStyleImageMissingListener error: ${error.message}`);
          }
        }
      });

      // 其他事件监听器
      this.nativeMapView.addOnDidBecomeIdleListener(() => {
        for (const listener of this.onDidBecomeIdleListeners) {
          try {
            listener.onDidBecomeIdle();
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnDidBecomeIdleListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnSourceChangedListener((id: string) => {
        for (const listener of this.onSourceChangedListeners) {
          try {
            listener.onSourceChanged(id);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnSourceChangedListener error: ${error.message}`);
          }
        }
      });

      // ========== 观察者事件监听器 (Shader, Glyph, Sprite, Tile) ==========
      
      // Shader 编译监听器
      this.nativeMapView.addOnPreCompileShaderListener((shaderId: number, backendType: number, defines: string) => {
        for (const listener of this.onPreCompileShaderListeners) {
          try {
            listener.onPreCompileShader(shaderId, backendType, defines);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnPreCompileShaderListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnPostCompileShaderListener((shaderId: number, backendType: number, defines: string) => {
        for (const listener of this.onPostCompileShaderListeners) {
          try {
            listener.onPostCompileShader(shaderId, backendType, defines);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnPostCompileShaderListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnShaderCompileFailedListener((shaderId: number, backendType: number, defines: string) => {
        for (const listener of this.onShaderCompileFailedListeners) {
          try {
            listener.onShaderCompileFailed(shaderId, backendType, defines);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnShaderCompileFailedListener error: ${error.message}`);
          }
        }
      });

      // Glyph 加载监听器
      this.nativeMapView.addOnGlyphsLoadedListener((fontStack: string[], rangeStart: number, rangeEnd: number) => {
        for (const listener of this.onGlyphsLoadedListeners) {
          try {
            listener.onGlyphsLoaded(fontStack, rangeStart, rangeEnd);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnGlyphsLoadedListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnGlyphsErrorListener((fontStack: string[], rangeStart: number, rangeEnd: number) => {
        for (const listener of this.onGlyphsErrorListeners) {
          try {
            listener.onGlyphsError(fontStack, rangeStart, rangeEnd);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnGlyphsErrorListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnGlyphsRequestedListener((fontStack: string[], rangeStart: number, rangeEnd: number) => {
        for (const listener of this.onGlyphsRequestedListeners) {
          try {
            listener.onGlyphsRequested(fontStack, rangeStart, rangeEnd);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnGlyphsRequestedListener error: ${error.message}`);
          }
        }
      });

      // Sprite 加载监听器
      this.nativeMapView.addOnSpriteLoadedListener((spriteId: string, url: string) => {
        for (const listener of this.onSpriteLoadedListeners) {
          try {
            listener.onSpriteLoaded(spriteId, url);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnSpriteLoadedListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnSpriteErrorListener((spriteId: string, url: string) => {
        for (const listener of this.onSpriteErrorListeners) {
          try {
            listener.onSpriteError(spriteId, url);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnSpriteErrorListener error: ${error.message}`);
          }
        }
      });

      this.nativeMapView.addOnSpriteRequestedListener((spriteId: string, url: string) => {
        for (const listener of this.onSpriteRequestedListeners) {
          try {
            listener.onSpriteRequested(spriteId, url);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnSpriteRequestedListener error: ${error.message}`);
          }
        }
      });

      // Tile 操作监听器
      this.nativeMapView.addOnTileActionListener((operation: number, x: number, y: number, z: number, wrap: number, overscaledZ: number, sourceId: string) => {
        for (const listener of this.onTileActionListeners) {
          try {
            listener.onTileAction(operation, x, y, z, wrap, overscaledZ, sourceId);
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnTileActionListener error: ${error.message}`);
          }
        }
      });

      // 初始更新一次 Compass bearing
      this.updateCompassBearing();

      // ⚠️ 注意：onMapReady 回调已移至 OnDidFinishLoadingStyleListener 中
      // 这样可以确保 Style 完全加载后才调用回调，避免 "Style not loaded" 错误
      // 参考 Android MapView.MapCallback.initialised() 和 iOS MLNMapView 的实现
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `Failed to initialize map: ${error.message}`);
      hilog.error(DOMAIN, 'NativeMapView', `Error stack: ${error.stack}`);
    }
  }

  /**
   * 表面变化回调
   */
  onSurfaceChanged(surfaceId: string, rect: SurfaceRect): void {

    // 防止异常小的尺寸（可能是 setXComponentSurfaceRect 的副作用）
    if (rect.surfaceWidth < 100 || rect.surfaceHeight < 100) {
      hilog.warn(DOMAIN, 'NativeMapView',
        `onSurfaceChanged: Ignoring abnormal size ${rect.surfaceWidth}x${rect.surfaceHeight}`);
      return;
    }

    // ✅ HarmonyOS的onSurfaceChanged传入的就是逻辑像素，直接使用
    this.surfaceWidth = rect.surfaceWidth;
    this.surfaceHeight = rect.surfaceHeight;

    if (this.nativeMapView && this.isInitialized) {
      try {

        this.nativeMapView.resizeView(rect.surfaceWidth, rect.surfaceHeight);
      } catch (error) {
        hilog.error(DOMAIN, 'NativeMapView', `Failed to resize map: ${error.message}`);
      }
    } else if (this.nativeMapView && !this.isInitialized) {
      // 如果地图尚未初始化，使用新的尺寸重新初始化
      try {

        this.nativeMapView.resizeView(rect.surfaceWidth, rect.surfaceHeight);
        this.isInitialized = true;
      } catch (error) {
        hilog.error(DOMAIN, 'NativeMapView', `Failed to reinitialize map: ${error.message}`);
      }
    }
  }

  /**
   * 表面销毁回调
   */
  onSurfaceDestroyed(surfaceId: string): void {

    if (this.nativeMapView) {
      try {
        // 完整的资源清理流程
        this.cleanupMapResources();
        this.nativeMapView = null;
        this.isInitialized = false;
      } catch (error) {
        hilog.error(DOMAIN, 'NativeMapView', `Failed to destroy map: ${error.message}`);
      }
    }
  }

  /**
   * 清理地图资源
   */
  private cleanupMapResources(): void {
    try {

      // 1. 停止所有渲染操作
      if (this.nativeMapView) {
        // 暂停渲染
        // this.mapView.pause();

        // 2. 清理OpenGL资源
        // this.mapView.cleanupGLResources();

        // 3. 清理网络请求
        // this.mapView.cancelAllRequests();

        // 4. 清理缓存
        // this.mapView.clearCache();
      }

    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `Error during map resource cleanup: ${error.message}`);
    }
  }

  /**
   * 获取地图实例
   */
  getMapView(): NullableNativeMapView {
    return this.nativeMapView;
  }

  /**
   * 检查是否已初始化
   */
  isMapInitialized(): boolean {
    return this.isInitialized && this.nativeMapView !== null;
  }

  /**
   * 清理所有资源
   */
  cleanupResources(): void {
    try {

      if (this.nativeMapView) {
        // 清理地图资源
        this.cleanupMapResources();
        this.nativeMapView = null;
      }

      this.isInitialized = false;
      this.surfaceId = '';
      this.surfaceWidth = 0;
      this.surfaceHeight = 0;

    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapViewController', `Error during resource cleanup: ${error.message}`);
    }
  }

  /**
   * 设置地图样式
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
   * 设置地图位置
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

  /**
   * 飞行到指定位置（带飞行动画）
   * @param options 相机选项
   * @param duration 动画持续时间（毫秒）
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
   * 平滑过渡到指定位置
   * @param options 相机选项
   * @param duration 动画持续时间（毫秒）
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
   * 添加标记
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

  /**
   * 触发重绘
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

  // ========== 新增方法：对齐 Android/iOS API ==========

  /**
   * 设置内容边距（对齐 Android API）
   * @param padding 边距数组 [top, left, bottom, right]（逻辑像素）
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
   * 获取内容边距（对齐 Android API）
   * @returns 边距数组 [top, left, bottom, right]
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
   * 获取设备像素比（对齐 Android API）
   * @returns 像素比（例如：2.0、3.0）
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
   * 获取 UI 设置
   */
  getUiSettings(): UiSettings {
    return this.uiSettings;
  }

  /**
   * 获取手势检测器
   */
  getGestureDetector(): MapGestureDetector {
    return this.gestureDetector;
  }

  /**
   * 设置 MapLibreMap 实例（用于 InfoWindow 管理）
   */
  setMapLibreMapInstance(mapLibreMap: MapLibreMap): void {
    this.mapLibreMapInstance = mapLibreMap;

    // 连接手势检测器到 MapLibreMap（参考 Android MapGestureDetector 连接）
    this.gestureDetector.setMapLibreMapInstance(mapLibreMap);
  }

  /**
   * 获取 MapLibreMap 实例
   */
  getMapLibreMapInstance(): MapLibreMap | null {
    return this.mapLibreMapInstance;
  }

  /**
   * 处理 C++ Map 创建完成事件
   * 
   * 此方法在 C++ Map 对象创建完成后由 C++ 层回调触发
   * 对齐 Android: 在样式加载前创建 MapLibreMap 并触发 onMapViewCreated
   */
  handleMapViewCreated(): void {
    hilog.info(DOMAIN, 'NativeMapViewController', '📢 handleMapViewCreated: C++ Map created');
    
    try {
      // 创建 MapLibreMap 实例（仅创建一次）
      if (!this.mapLibreMapInstance && this.nativeMapView) {
        const options = new MapLibreMapOptions();
        this.mapLibreMapInstance = new MapLibreMap(this.nativeMapView, options);
        hilog.info(DOMAIN, 'NativeMapViewController', '✅ MapLibreMap instance created');
        
        // 连接手势检测器到 MapLibreMap
        this.gestureDetector.setMapLibreMapInstance(this.mapLibreMapInstance);
        
        // 触发用户的 onMapViewCreated 回调
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
   * 设置 Compass Bearing 更新回调
   */
  setCompassBearingUpdateCallback(callback: (bearing: number) => void): void {
    this.compassBearingUpdateCallback = callback;
  }

  /**
   * 设置 UI 设置更新回调
   */
  setUiSettingsUpdateCallback(callback: () => void): void {
    this.uiSettingsUpdateCallback = callback;
  }

  // ScaleBar 更新回调
  private scaleBarMetersPerPixelUpdateCallback?: (metersPerPixel: number) => void;

  /**
   * 设置 ScaleBar MetersPerPixel 更新回调
   */
  setScaleBarMetersPerPixelUpdateCallback(callback: (metersPerPixel: number) => void): void {
    this.scaleBarMetersPerPixelUpdateCallback = callback;
  }

  /**
   * 更新 ScaleBar MetersPerPixel
   */
  updateScaleBarMetersPerPixel(metersPerPixel: number): void {
    if (this.scaleBarMetersPerPixelUpdateCallback) {
      this.scaleBarMetersPerPixelUpdateCallback(metersPerPixel);
    }
  }

  /**
   * 更新 Compass Bearing
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
   * 更新 AnnotationView 位置回调
   */
  private annotationViewUpdateCallback?: (views: AnnotationViewData[]) => void;

  /**
   * 设置 AnnotationView 更新回调
   */
  setAnnotationViewUpdateCallback(callback: (views: AnnotationViewData[]) => void): void {
    this.annotationViewUpdateCallback = callback;
  }

  /**
   * 更新 AnnotationView 位置
   */
  updateAnnotationViews(): void {
    if (this.mapLibreMapInstance && this.annotationViewUpdateCallback) {
      try {
        const annotationViewManager = this.mapLibreMapInstance.getMarkerManager().getAnnotationViewManager();
        // 更新所有视图位置
        annotationViewManager.batchUpdatePositions(true);
        // 获取可见视图并通知 UI
        const visibleViews = annotationViewManager.getAllViews();
        this.annotationViewUpdateCallback(visibleViews);
      } catch (error) {
        hilog.error(DOMAIN, 'NativeMapView', `Failed to update annotation views: ${error}`);
      }
    }
  }

  /**
   * 归正北（Compass 点击处理）
   */
  resetNorth(): void {
    if (this.nativeMapView && this.isInitialized) {
      try {
        // 使用动画方式归正北（参考 Android TIME_MAP_NORTH_ANIMATION = 150ms）
        this.nativeMapView.setBearing(0, 150);
      } catch (error) {
        hilog.error(DOMAIN, 'NativeMapView', `Failed to reset north: ${error}`);
      }
    }
  }

  /**
   * 获取视图宽度
   */
  getWidth(): number {
    return this.surfaceWidth;
  }

  /**
   * 获取视图高度
   */
  getHeight(): number {
    return this.surfaceHeight;
  }

  /**
   * 获取俯仰角度
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

  // ========== 监听器注册和移除方法 ==========

  // ===== 相机事件监听器 =====

  /**
   * 添加相机即将改变的监听器
   */
  addOnCameraWillChangeListener(listener: OnCameraWillChangeListener): void {
    if (this.onCameraWillChangeListeners.indexOf(listener) === -1) {
      this.onCameraWillChangeListeners.push(listener);
    }
  }

  /**
   * 移除相机即将改变的监听器
   */
  removeOnCameraWillChangeListener(listener: OnCameraWillChangeListener): void {
    const index = this.onCameraWillChangeListeners.indexOf(listener);
    if (index !== -1) {
      this.onCameraWillChangeListeners.splice(index, 1);
    }
  }

  /**
   * 添加相机正在改变的监听器
   */
  addOnCameraIsChangingListener(listener: OnCameraIsChangingListener): void {
    if (this.onCameraIsChangingListeners.indexOf(listener) === -1) {
      this.onCameraIsChangingListeners.push(listener);
    }
  }

  /**
   * 移除相机正在改变的监听器
   */
  removeOnCameraIsChangingListener(listener: OnCameraIsChangingListener): void {
    const index = this.onCameraIsChangingListeners.indexOf(listener);
    if (index !== -1) {
      this.onCameraIsChangingListeners.splice(index, 1);
    }
  }

  /**
   * 添加相机已改变的监听器
   */
  addOnCameraDidChangeListener(listener: OnCameraDidChangeListener): void {
    if (this.onCameraDidChangeListeners.indexOf(listener) === -1) {
      this.onCameraDidChangeListeners.push(listener);
    }
  }

  /**
   * 移除相机已改变的监听器
   */
  removeOnCameraDidChangeListener(listener: OnCameraDidChangeListener): void {
    const index = this.onCameraDidChangeListeners.indexOf(listener);
    if (index !== -1) {
      this.onCameraDidChangeListeners.splice(index, 1);
    }
  }

  // ===== 地图加载事件监听器 =====

  /**
   * 添加地图即将开始加载的监听器
   */
  addOnWillStartLoadingMapListener(listener: OnWillStartLoadingMapListener): void {
    if (this.onWillStartLoadingMapListeners.indexOf(listener) === -1) {
      this.onWillStartLoadingMapListeners.push(listener);
    }
  }

  /**
   * 移除地图即将开始加载的监听器
   */
  removeOnWillStartLoadingMapListener(listener: OnWillStartLoadingMapListener): void {
    const index = this.onWillStartLoadingMapListeners.indexOf(listener);
    if (index !== -1) {
      this.onWillStartLoadingMapListeners.splice(index, 1);
    }
  }

  /**
   * 添加地图加载完成的监听器
   */
  addOnDidFinishLoadingMapListener(listener: OnDidFinishLoadingMapListener): void {
    if (this.onDidFinishLoadingMapListeners.indexOf(listener) === -1) {
      this.onDidFinishLoadingMapListeners.push(listener);
    }
  }

  /**
   * 移除地图加载完成的监听器
   */
  removeOnDidFinishLoadingMapListener(listener: OnDidFinishLoadingMapListener): void {
    const index = this.onDidFinishLoadingMapListeners.indexOf(listener);
    if (index !== -1) {
      this.onDidFinishLoadingMapListeners.splice(index, 1);
    }
  }

  /**
   * 添加地图加载失败的监听器
   */
  addOnDidFailLoadingMapListener(listener: OnDidFailLoadingMapListener): void {
    if (this.onDidFailLoadingMapListeners.indexOf(listener) === -1) {
      this.onDidFailLoadingMapListeners.push(listener);
    }
  }

  /**
   * 移除地图加载失败的监听器
   */
  removeOnDidFailLoadingMapListener(listener: OnDidFailLoadingMapListener): void {
    const index = this.onDidFailLoadingMapListeners.indexOf(listener);
    if (index !== -1) {
      this.onDidFailLoadingMapListeners.splice(index, 1);
    }
  }

  // ===== 渲染事件监听器 =====

  /**
   * 添加帧即将开始渲染的监听器
   */
  addOnWillStartRenderingFrameListener(listener: OnWillStartRenderingFrameListener): void {
    if (this.onWillStartRenderingFrameListeners.indexOf(listener) === -1) {
      this.onWillStartRenderingFrameListeners.push(listener);
    }
  }

  /**
   * 移除帧即将开始渲染的监听器
   */
  removeOnWillStartRenderingFrameListener(listener: OnWillStartRenderingFrameListener): void {
    const index = this.onWillStartRenderingFrameListeners.indexOf(listener);
    if (index !== -1) {
      this.onWillStartRenderingFrameListeners.splice(index, 1);
    }
  }

  /**
   * 添加帧渲染完成的监听器（简单版本）
   */
  addOnDidFinishRenderingFrameListener(listener: OnDidFinishRenderingFrameListener): void {
    if (this.onDidFinishRenderingFrameListeners.indexOf(listener) === -1) {
      this.onDidFinishRenderingFrameListeners.push(listener);
    }
  }

  /**
   * 移除帧渲染完成的监听器（简单版本）
   */
  removeOnDidFinishRenderingFrameListener(listener: OnDidFinishRenderingFrameListener): void {
    const index = this.onDidFinishRenderingFrameListeners.indexOf(listener);
    if (index !== -1) {
      this.onDidFinishRenderingFrameListeners.splice(index, 1);
    }
  }

  /**
   * 添加帧渲染完成的监听器（带统计信息）
   */
  addOnDidFinishRenderingFrameWithStatsListener(listener: OnDidFinishRenderingFrameWithStatsListener): void {
    if (this.onDidFinishRenderingFrameWithStatsListeners.indexOf(listener) === -1) {
      this.onDidFinishRenderingFrameWithStatsListeners.push(listener);
    }
  }

  /**
   * 移除帧渲染完成的监听器（带统计信息）
   */
  removeOnDidFinishRenderingFrameWithStatsListener(listener: OnDidFinishRenderingFrameWithStatsListener): void {
    const index = this.onDidFinishRenderingFrameWithStatsListeners.indexOf(listener);
    if (index !== -1) {
      this.onDidFinishRenderingFrameWithStatsListeners.splice(index, 1);
    }
  }

  /**
   * 添加地图即将开始渲染的监听器
   */
  addOnWillStartRenderingMapListener(listener: OnWillStartRenderingMapListener): void {
    if (this.onWillStartRenderingMapListeners.indexOf(listener) === -1) {
      this.onWillStartRenderingMapListeners.push(listener);
    }
  }

  /**
   * 移除地图即将开始渲染的监听器
   */
  removeOnWillStartRenderingMapListener(listener: OnWillStartRenderingMapListener): void {
    const index = this.onWillStartRenderingMapListeners.indexOf(listener);
    if (index !== -1) {
      this.onWillStartRenderingMapListeners.splice(index, 1);
    }
  }

  /**
   * 添加地图渲染完成的监听器
   */
  addOnDidFinishRenderingMapListener(listener: OnDidFinishRenderingMapListener): void {
    if (this.onDidFinishRenderingMapListeners.indexOf(listener) === -1) {
      this.onDidFinishRenderingMapListeners.push(listener);
    }
  }

  /**
   * 移除地图渲染完成的监听器
   */
  removeOnDidFinishRenderingMapListener(listener: OnDidFinishRenderingMapListener): void {
    const index = this.onDidFinishRenderingMapListeners.indexOf(listener);
    if (index !== -1) {
      this.onDidFinishRenderingMapListeners.splice(index, 1);
    }
  }

  // ===== 样式事件监听器 =====

  /**
   * 添加样式加载完成的监听器
   */
  addOnDidFinishLoadingStyleListener(listener: OnDidFinishLoadingStyleListener): void {
    if (this.onDidFinishLoadingStyleListeners.indexOf(listener) === -1) {
      this.onDidFinishLoadingStyleListeners.push(listener);
    }
  }

  /**
   * 移除样式加载完成的监听器
   */
  removeOnDidFinishLoadingStyleListener(listener: OnDidFinishLoadingStyleListener): void {
    const index = this.onDidFinishLoadingStyleListeners.indexOf(listener);
    if (index !== -1) {
      this.onDidFinishLoadingStyleListeners.splice(index, 1);
    }
  }

  /**
   * 添加样式图片缺失的监听器
   */
  addOnStyleImageMissingListener(listener: OnStyleImageMissingListener): void {
    if (this.onStyleImageMissingListeners.indexOf(listener) === -1) {
      this.onStyleImageMissingListeners.push(listener);
    }
  }

  /**
   * 移除样式图片缺失的监听器
   */
  removeOnStyleImageMissingListener(listener: OnStyleImageMissingListener): void {
    const index = this.onStyleImageMissingListeners.indexOf(listener);
    if (index !== -1) {
      this.onStyleImageMissingListeners.splice(index, 1);
    }
  }

  /**
   * 添加可移除未使用样式图片的监听器
   */
  addOnCanRemoveUnusedStyleImageListener(listener: OnCanRemoveUnusedStyleImageListener): void {
    if (this.onCanRemoveUnusedStyleImageListeners.indexOf(listener) === -1) {
      this.onCanRemoveUnusedStyleImageListeners.push(listener);
    }
  }

  /**
   * 移除可移除未使用样式图片的监听器
   */
  removeOnCanRemoveUnusedStyleImageListener(listener: OnCanRemoveUnusedStyleImageListener): void {
    const index = this.onCanRemoveUnusedStyleImageListeners.indexOf(listener);
    if (index !== -1) {
      this.onCanRemoveUnusedStyleImageListeners.splice(index, 1);
    }
  }

  // ===== 其他事件监听器 =====

  /**
   * 添加地图进入空闲状态的监听器
   */
  addOnDidBecomeIdleListener(listener: OnDidBecomeIdleListener): void {
    if (this.onDidBecomeIdleListeners.indexOf(listener) === -1) {
      this.onDidBecomeIdleListeners.push(listener);
    }
  }

  /**
   * 移除地图进入空闲状态的监听器
   */
  removeOnDidBecomeIdleListener(listener: OnDidBecomeIdleListener): void {
    const index = this.onDidBecomeIdleListeners.indexOf(listener);
    if (index !== -1) {
      this.onDidBecomeIdleListeners.splice(index, 1);
    }
  }

  /**
   * 添加数据源改变的监听器
   */
  addOnSourceChangedListener(listener: OnSourceChangedListener): void {
    if (this.onSourceChangedListeners.indexOf(listener) === -1) {
      this.onSourceChangedListeners.push(listener);
    }
  }

  /**
   * 移除数据源改变的监听器
   */
  removeOnSourceChangedListener(listener: OnSourceChangedListener): void {
    const index = this.onSourceChangedListeners.indexOf(listener);
    if (index !== -1) {
      this.onSourceChangedListeners.splice(index, 1);
    }
  }

  /**
   * 添加着色器编译前的监听器
   */
  addOnPreCompileShaderListener(listener: OnPreCompileShaderListener): void {
    if (this.onPreCompileShaderListeners.indexOf(listener) === -1) {
      this.onPreCompileShaderListeners.push(listener);
    }
  }

  /**
   * 移除着色器编译前的监听器
   */
  removeOnPreCompileShaderListener(listener: OnPreCompileShaderListener): void {
    const index = this.onPreCompileShaderListeners.indexOf(listener);
    if (index !== -1) {
      this.onPreCompileShaderListeners.splice(index, 1);
    }
  }

  /**
   * 添加着色器编译后的监听器
   */
  addOnPostCompileShaderListener(listener: OnPostCompileShaderListener): void {
    if (this.onPostCompileShaderListeners.indexOf(listener) === -1) {
      this.onPostCompileShaderListeners.push(listener);
    }
  }

  /**
   * 移除着色器编译后的监听器
   */
  removeOnPostCompileShaderListener(listener: OnPostCompileShaderListener): void {
    const index = this.onPostCompileShaderListeners.indexOf(listener);
    if (index !== -1) {
      this.onPostCompileShaderListeners.splice(index, 1);
    }
  }

  /**
   * 添加着色器编译失败的监听器
   */
  addOnShaderCompileFailedListener(listener: OnShaderCompileFailedListener): void {
    if (this.onShaderCompileFailedListeners.indexOf(listener) === -1) {
      this.onShaderCompileFailedListeners.push(listener);
    }
  }

  /**
   * 移除着色器编译失败的监听器
   */
  removeOnShaderCompileFailedListener(listener: OnShaderCompileFailedListener): void {
    const index = this.onShaderCompileFailedListeners.indexOf(listener);
    if (index !== -1) {
      this.onShaderCompileFailedListeners.splice(index, 1);
    }
  }

  /**
   * 添加字形加载完成的监听器
   */
  addOnGlyphsLoadedListener(listener: OnGlyphsLoadedListener): void {
    if (this.onGlyphsLoadedListeners.indexOf(listener) === -1) {
      this.onGlyphsLoadedListeners.push(listener);
    }
  }

  /**
   * 移除字形加载完成的监听器
   */
  removeOnGlyphsLoadedListener(listener: OnGlyphsLoadedListener): void {
    const index = this.onGlyphsLoadedListeners.indexOf(listener);
    if (index !== -1) {
      this.onGlyphsLoadedListeners.splice(index, 1);
    }
  }

  /**
   * 添加字形加载错误的监听器
   */
  addOnGlyphsErrorListener(listener: OnGlyphsErrorListener): void {
    if (this.onGlyphsErrorListeners.indexOf(listener) === -1) {
      this.onGlyphsErrorListeners.push(listener);
    }
  }

  /**
   * 移除字形加载错误的监听器
   */
  removeOnGlyphsErrorListener(listener: OnGlyphsErrorListener): void {
    const index = this.onGlyphsErrorListeners.indexOf(listener);
    if (index !== -1) {
      this.onGlyphsErrorListeners.splice(index, 1);
    }
  }

  /**
   * 添加字形请求的监听器
   */
  addOnGlyphsRequestedListener(listener: OnGlyphsRequestedListener): void {
    if (this.onGlyphsRequestedListeners.indexOf(listener) === -1) {
      this.onGlyphsRequestedListeners.push(listener);
    }
  }

  /**
   * 移除字形请求的监听器
   */
  removeOnGlyphsRequestedListener(listener: OnGlyphsRequestedListener): void {
    const index = this.onGlyphsRequestedListeners.indexOf(listener);
    if (index !== -1) {
      this.onGlyphsRequestedListeners.splice(index, 1);
    }
  }

  /**
   * 添加瓦片操作的监听器
   */
  addOnTileActionListener(listener: OnTileActionListener): void {
    if (this.onTileActionListeners.indexOf(listener) === -1) {
      this.onTileActionListeners.push(listener);
    }
  }

  /**
   * 移除瓦片操作的监听器
   */
  removeOnTileActionListener(listener: OnTileActionListener): void {
    const index = this.onTileActionListeners.indexOf(listener);
    if (index !== -1) {
      this.onTileActionListeners.splice(index, 1);
    }
  }

  /**
   * 添加精灵图加载完成的监听器
   */
  addOnSpriteLoadedListener(listener: OnSpriteLoadedListener): void {
    if (this.onSpriteLoadedListeners.indexOf(listener) === -1) {
      this.onSpriteLoadedListeners.push(listener);
    }
  }

  /**
   * 移除精灵图加载完成的监听器
   */
  removeOnSpriteLoadedListener(listener: OnSpriteLoadedListener): void {
    const index = this.onSpriteLoadedListeners.indexOf(listener);
    if (index !== -1) {
      this.onSpriteLoadedListeners.splice(index, 1);
    }
  }

  /**
   * 添加精灵图加载错误的监听器
   */
  addOnSpriteErrorListener(listener: OnSpriteErrorListener): void {
    if (this.onSpriteErrorListeners.indexOf(listener) === -1) {
      this.onSpriteErrorListeners.push(listener);
    }
  }

  /**
   * 移除精灵图加载错误的监听器
   */
  removeOnSpriteErrorListener(listener: OnSpriteErrorListener): void {
    const index = this.onSpriteErrorListeners.indexOf(listener);
    if (index !== -1) {
      this.onSpriteErrorListeners.splice(index, 1);
    }
  }

  /**
   * 添加精灵图请求的监听器
   */
  addOnSpriteRequestedListener(listener: OnSpriteRequestedListener): void {
    if (this.onSpriteRequestedListeners.indexOf(listener) === -1) {
      this.onSpriteRequestedListeners.push(listener);
    }
  }

  /**
   * 移除精灵图请求的监听器
   */
  removeOnSpriteRequestedListener(listener: OnSpriteRequestedListener): void {
    const index = this.onSpriteRequestedListeners.indexOf(listener);
    if (index !== -1) {
      this.onSpriteRequestedListeners.splice(index, 1);
    }
  }

  /**
   * 获取地图异步（对齐 Android getMapAsync 模式）
   * @param callback 地图就绪回调
   */
  getMapAsync(callback: OnMapReadyCallback): void {
    if (this.nativeMapView && this.isInitialized) {
      // 地图已就绪，立即回调
      try {
        callback.onMapReady(this.mapLibreMapInstance);
      } catch (error) {
        hilog.error(DOMAIN, 'NativeMapView', `getMapAsync callback error: ${error.message}`);
      }
    } else {
      // 地图未就绪，添加到回调列表
      this.onMapReadyCallbacks.push(callback);
    }
  }

  // ========== 渲染控制方法 ==========

  /**
   * 在渲染线程上执行任务（对齐 Android queueEvent）
   * @param runnable 要执行的任务
   */
  queueEvent(runnable: () => void): void {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'queueEvent: Map not initialized');
      return;
    }

    // 在渲染线程队列中执行任务
    // 使用 setTimeout(0) 确保任务在下一个事件循环执行
    // 这样可以避免在渲染过程中直接修改状态导致的问题
    setTimeout(() => {
      try {
        runnable();
        // 执行完任务后触发重绘
        this.triggerRepaint();
      } catch (error) {
        hilog.error(DOMAIN, 'NativeMapView', `queueEvent error: ${error.message}`);
      }
    }, 0);
  }

  /**
   * 设置最大帧率（对齐 Android setMaximumFps）
   * @param maximumFps 最大帧率
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
   * 设置渲染刷新模式（对齐 Android setRenderingRefreshMode）
   * @param mode 渲染模式
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
   * 获取渲染刷新模式（对齐 Android getRenderingRefreshMode）
   * @returns 当前渲染模式
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
   * 设置 FPS 变化监听器（参考 Android MapView.setOnFpsChangedListener）
   * @param listener FPS 变化监听器，传入 null 则移除监听器
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

  // ========== 性能和缓存配置 ==========

  /**
   * 设置是否预加载瓦片（对齐 Android prefetchesTiles）
   * @param enabled 是否启用预加载
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
   * 设置是否启用瓦片缓存（对齐 Android tileCacheEnabled）
   * @param enabled 是否启用缓存
   */
  setTileCacheEnabled(enabled: boolean): void {
    if (!this.nativeMapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'setTileCacheEnabled: Map not initialized');
      return;
    }

    try {
      // TODO: C++ NAPI 绑定
      // this.mapView.setTileCacheEnabled(enabled);
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `setTileCacheEnabled error: ${error.message}`);
    }
  }

  /**
   * 设置 LOD 最小半径（对齐 iOS tileLodMinRadius）
   * @param radius 最小半径（瓦片单位）
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
   * 设置 LOD 缩放因子（对齐 iOS tileLodScale）
   * @param scale 缩放因子
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
   * 设置 LOD 俯仰角阈值（对齐 iOS tileLodPitchThreshold）
   * @param threshold 俯仰角阈值（弧度）
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
   * 设置 LOD 缩放级别偏移（对齐 iOS tileLodZoomShift）
   * @param shift 缩放级别偏移
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
   * 低内存警告处理（对齐 Android onLowMemory）
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
 * NativeMapView - 地图视图组件
 */
@Component
export struct MapView {
  private controller: NativeMapViewController = new NativeMapViewController();
  @State private isVisible: boolean = true;
  @State private isDestroyed: boolean = false;
  // 组件属性
  @Prop styleUrl: string;
  @Prop initialLatitude: number = 30.2741;
  @Prop initialLongitude: number = 120.1551;
  @Prop initialZoom: number = 6;
  @Prop initialBearing: number = 0;
  @Prop initialPitch: number = 0;
  @Prop debugMode: boolean = false;
  // 回调函数
  onMapViewCreated?: (map: MapLibreMap) => void; // 早期回调：MapLibreMap 创建后立即调用（在样式加载前）
  onMapReady?: (map: MapLibreMap) => void | Promise<void>; // 常规回调：样式加载完成后调用
  onMapLoaded?: () => void;
  onMapError?: (error: string) => void;
  // 声明式子组件支持
  @BuilderParam children?: () => void;
  // 提供地图实例给子组件（声明式 API）
  @Provide('mapLibreMap') mapInstance: MapLibreMap | null = null;
  // UI 组件状态
  @State private compassBearing: number = 0;
  @State private uiSettingsVersion: number = 0;
  @State private scaleBarMetersPerPixel: number = 0;
  // InfoWindow 状态管理
  @State private visibleInfoWindows: InfoWindowState[] = [];
  // AnnotationView 状态管理
  @State private visibleAnnotationViews: AnnotationViewData[] = [];

  /**
   * 组件即将出现
   */
  aboutToAppear(): void {
    try {
      this.isDestroyed = false;

      // 将组件的 prop 和回调传递给 controller
      if (this.controller) {
        this.controller.styleUrl = this.styleUrl;
        this.controller.initialLatitude = this.initialLatitude;
        this.controller.initialLongitude = this.initialLongitude;
        this.controller.initialZoom = this.initialZoom;
        this.controller.initialBearing = this.initialBearing;
        this.controller.initialPitch = this.initialPitch;

        // ✅ 设置 onMapViewCreated 回调（C++ Map 创建完成后触发）
        this.controller.onMapViewCreatedCallback = (mapLibreMap: MapLibreMap) => {
          hilog.info(DOMAIN, 'NativeMapView', '📢 Calling user onMapViewCreated callback');
          if (this.onMapViewCreated) {
            this.onMapViewCreated(mapLibreMap);
          }
        };

        // 包装 onMapReady 回调（样式加载完成后触发）
        this.controller.onMapReadyCallback = (mapView?: NativeMapView) => {
          // ✅ MapLibreMap 已在 handleMapViewCreated 中创建
          const mapLibreMap = this.controller.getMapLibreMapInstance();

          if (!mapLibreMap) {
            hilog.error(DOMAIN, 'NativeMapView', '❌ MapLibreMap not initialized in onMapReady');
            return;
          }

          // 更新地图实例，触发声明式子组件初始化
          this.mapInstance = mapLibreMap;

          // 样式加载完成，触发 onMapReady
          if (this.onMapReady) {
            hilog.info(DOMAIN, 'NativeMapView', '📢 Calling user onMapReady callback');
            this.onMapReady(mapLibreMap);
          } else {
            hilog.warn(DOMAIN, 'NativeMapView', '⚠️ No onMapReady callback registered');
          }

          // 设置 InfoWindowManager 回调
          setTimeout(() => {
            this.setupInfoWindowCallbacks();
          }, 100);
        };

        // 设置 UI 组件更新回调
        this.controller.setCompassBearingUpdateCallback((bearing: number) => {
          this.compassBearing = bearing;
        });

        this.controller.setUiSettingsUpdateCallback(() => {
          this.uiSettingsVersion++;
        });

        this.controller.setScaleBarMetersPerPixelUpdateCallback((metersPerPixel: number) => {
          this.scaleBarMetersPerPixel = metersPerPixel;
        });

        // 设置 AnnotationView 更新回调
        this.controller.setAnnotationViewUpdateCallback((views: AnnotationViewData[]) => {
          this.visibleAnnotationViews = views;
        });

        // 设置 UiSettings 的配置变更回调
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
      hilog.error(DOMAIN, 'NativeMapView', `aboutToAppear failed: ${error.message}`);
    }
  }

  /**
   * 组件即将消失（参考 Android MapView.onDestroy() 和 iOS MLNMapView.dealloc）
   *
   * 改进：
   * 1. 使用异步 destroy 而不是同步阻塞
   * 2. 按照 Android/iOS 的顺序清理资源
   * 3. 清理所有监听器和回调
   */
  aboutToDisappear(): void {

    // 1. 设置销毁标志（参考 Android MapView.destroyed）
    this.isDestroyed = true;

    // 清理地图实例引用（用于声明式子组件）
    this.mapInstance = null;

    try {
      // 2. 取消所有动画和手势（参考 Android cancelAnimators()）
      const mapView = this.controller.getMapView();
      if (mapView) {
        try {
          mapView.cancelTransitions();
        } catch (err) {
          hilog.warn(DOMAIN, 'NativeMapView', `Error cancelling transitions: ${err}`);
        }
      }

      // 3. ✅ 使用异步 destroy（参考 Android/iOS 模式）
      // 这样可以避免阻塞主线程，同时确保资源正确释放
      if (mapView) {

        // 使用异步方式，传入完成回调
        mapView.destroyAsync(() => {
        });

      } else {
        hilog.warn(DOMAIN, 'NativeMapView', 'MapView is null, skipping destroy');
      }

      // 4. 清理 UI 组件引用（立即执行，不等待异步完成）
      // Controller 的引用会在组件销毁时自动清理
      // 事件监听器会在 C++ 层的 cleanupAllResourcesAsync 中清理

      // 5. 清理全局映射
      if (mapView) {
        globalControllerMap.delete(mapView);
      }

      // 6. 清理 InfoWindow 状态
      this.visibleInfoWindows = [];

      // 7. 清理 AnnotationView 状态
      this.visibleAnnotationViews = [];

    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `Error in aboutToDisappear: ${error}`);
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
        return `calc(100% - 48vp - ${margins.right}vp)`; // 100% - 组件宽度 - 右边距
      default:
        return `calc(100% - 48vp - ${margins.right}vp)`; // 默认右侧（与 TopRight 一致）
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
        return `calc(100% - 48vp - ${margins.bottom}vp)`; // 100% - 组件高度 - 下边距
      default:
        return margins.top; // 默认顶部（与 TopRight 一致）
    }
  }

  /**
   * 获取 Logo 的 X 位置
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
        return `calc(100% - 80vp - ${margins.right}vp)`; // 100% - Logo宽度 - 右边距
      default:
        return margins.left; // 默认左侧（与 BottomLeft 一致）
    }
  }

  /**
   * 获取 Logo 的 Y 位置
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
        return `calc(100% - 40vp - ${margins.bottom}vp)`; // 100% - Logo高度 - 下边距
      default:
        return `calc(100% - 40vp - ${margins.bottom}vp)`; // 默认底部（与 BottomLeft 一致）
    }
  }

  /**
   * 获取 ScaleBar 的 X 位置
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
        return `calc(100% - 200vp - ${margins.right}vp)`; // 100% - ScaleBar最大宽度 - 右边距
      default:
        return margins.left; // 默认左侧（与 TopLeft 一致）
    }
  }

  /**
   * 获取 ScaleBar 的 Y 位置
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
        return `calc(100% - 40vp - ${margins.bottom}vp)`; // 100% - ScaleBar高度 - 下边距
      default:
        return margins.top; // 默认顶部（与 TopLeft 一致）
    }
  }

  /**
   * 设置 InfoWindowManager 的UI回调
   */
  setupInfoWindowCallbacks(): void {
    try {
      const mapLibreMap = this.controller.getMapLibreMapInstance();
      if (!mapLibreMap) {
        hilog.warn(DOMAIN, 'NativeMapView', 'MapLibreMap instance not available for InfoWindow setup');
        return;
      }

      const infoWindowManager = mapLibreMap.getInfoWindowManager();

      // 显示 InfoWindow
      infoWindowManager.setOnShowUICallback((marker: Marker, position: InfoWindowPosition) => {
        const existingIndex = this.visibleInfoWindows.findIndex(
          item => item.marker.getId() === marker.getId()
        );

        const newState: InfoWindowState = {
          marker: marker,
          position: position,
          style: mapLibreMap.getMarkerManager().getInfoWindowStyle(marker),
          key: `infowindow-${marker.getId()}-${Date.now()}`
        };

        if (existingIndex >= 0) {
          this.visibleInfoWindows[existingIndex] = newState;
        } else {
          this.visibleInfoWindows.push(newState);
        }

      });

      // 隐藏 InfoWindow
      infoWindowManager.setOnHideUICallback((marker: Marker) => {
        const index = this.visibleInfoWindows.findIndex(
          item => item.marker.getId() === marker.getId()
        );
        if (index >= 0) {
          this.visibleInfoWindows.splice(index, 1);
        }
      });

      // 更新 InfoWindow 位置
      infoWindowManager.setOnUpdateUICallback((marker: Marker, position: InfoWindowPosition) => {
        const index = this.visibleInfoWindows.findIndex(
          item => item.marker.getId() === marker.getId()
        );
        if (index >= 0) {
          this.visibleInfoWindows[index].position = position;
        }
      });

      // ========== 设置 AnnotationView 回调 ==========
      const annotationViewManager = mapLibreMap.getMarkerManager().getAnnotationViewManager();

      // 监听 AnnotationView 数据变化，更新 UI
      // 注意：由于 AnnotationViewManager 目前没有回调机制，我们需要在相机移动时更新
      // 这将在相机监听器中实现

    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `Failed to setup AnnotationView callbacks: ${error.message}`);
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
        visibleAnnotationViews: $visibleAnnotationViews,
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
            hilog.error(DOMAIN, 'NativeMapView', `AnnotationView select error: ${error.message}`);
          }
        },
        onAnnotationDeselect: (marker: Marker) => {
          try {
            const mapLibreMap = this.controller.getMapLibreMapInstance();
            if (mapLibreMap) {
              mapLibreMap.getMarkerManager().deselectMarker(marker);
            }
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `AnnotationView deselect error: ${error.message}`);
          }
        },
        onAnnotationDragStart: (marker: Marker) => {
          try {
            const mapLibreMap = this.controller.getMapLibreMapInstance();
            if (mapLibreMap) {
              mapLibreMap.getMarkerManager().handleDragStart(marker);
            }
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `AnnotationView drag start error: ${error.message}`);
          }
        },
        onAnnotationDrag: (marker: Marker, screenX: number, screenY: number) => {
          try {
            // 将屏幕坐标转换为地理坐标
            const mapView = this.controller.getMapView();
            if (mapView) {
              const nativeLatLng: maplibre.LatLng = mapView.latLngForPixel(screenX, screenY);
              const mapLibreMap = this.controller.getMapLibreMapInstance();
              if (mapLibreMap && nativeLatLng) {
                const latLng = LatLng.fromNative(nativeLatLng);
                mapLibreMap.getMarkerManager().handleDrag(marker, latLng);
              }
            }
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `AnnotationView drag error: ${error.message}`);
          }
        },
        onAnnotationDragEnd: (marker: Marker, screenX: number, screenY: number) => {
          try {
            const mapLibreMap = this.controller.getMapLibreMapInstance();
            if (mapLibreMap) {
              mapLibreMap.getMarkerManager().handleDragEnd(marker);
            }
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `AnnotationView drag end error: ${error.message}`);
          }
        }
      })

      // InfoWindow 覆盖层 - 显示所有 InfoWindow
      InfoWindowOverlay({
        visibleInfoWindows: $visibleInfoWindows,
        onInfoWindowClick: (marker: Marker) => {
          try {
            const mapLibreMap = this.controller.getMapLibreMapInstance();
            if (mapLibreMap) {
              mapLibreMap.getInfoWindowManager().triggerClick(marker);
            }
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `InfoWindow click error: ${error.message}`);
          }
        },
        onInfoWindowLongClick: (marker: Marker) => {
          try {
            const mapLibreMap = this.controller.getMapLibreMapInstance();
            if (mapLibreMap) {
              mapLibreMap.getInfoWindowManager().triggerLongClick(marker);
            }
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `InfoWindow long click error: ${error.message}`);
          }
        },
        onInfoWindowClose: (marker: Marker) => {
          try {
            marker.hideInfoWindow();
          } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `InfoWindow close error: ${error.message}`);
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
