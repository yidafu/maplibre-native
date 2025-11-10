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
// 类型别名：区分 NAPI 的 NativeMapView 和 ETS 组件
type NativeMapViewNapiType = NativeMapViewNAPI;

export interface NativeViewAnnotationApi {
  addViewAnnotation(options: NativeViewAnnotationOptions): number;
  updateViewAnnotation(annotationId: number, options: NativeViewAnnotationOptions): boolean;
  removeViewAnnotation(annotationId: number): boolean;
  getViewAnnotationFrames(): NativeViewAnnotationFrame[];
}

export type NativeMapView = NativeMapViewNapiType ;

// MapView 组件接口（用于类型声明，避免循环引用）
interface MapViewComponent {
  setupInfoWindowCallbacks(): void;
}

// 从 NAPI 模块导入相机选项类型
type CameraOptions = maplibre.CameraOptions;

type NullableNativeMapView = NativeMapView | null;

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
export class NativeMapViewController extends XComponentController implements NativeViewAnnotationApi {
  private nativeMapView: NullableNativeMapView = null;
  private isInitialized: boolean = false;
  private hasTriggeredMapReady: boolean = false; // 标记是否已触发过 onMapReady 回调（用于控制 onMapReady 只触发一次）
  private initialCameraApplied: boolean = false;
  private surfaceId: string = '';
  private surfaceWidth: number = 0;
  private surfaceHeight: number = 0;
  private pixelRatio: number = 1.0; // 保存设备像素比
  private isSurfaceRectSet: boolean = false; // 防止setXComponentSurfaceRect无限循环
  // 初始配置
  public styleUrl: string = "https://demotiles.maplibre.org/style.json";
  public initialLatitude: number = 0;
  public initialLongitude: number = 0;
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
      this.initialCameraApplied = false;
      this.hasTriggeredMapReady = false;

      // 注册到全局映射
      if (this.nativeMapView) {
        globalControllerMap.set(this.nativeMapView, this);
      }

      // 🛡️ 延迟初始化：等待页面转换动画完成（通常需要 400-500ms）
      // ✅ 修复第二次进入崩溃：延迟增加到 800ms，确保 Native Window 完全稳定
      // 原因：页面转换动画可能需要更长时间，特别是在低性能设备上

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

        if (!this.mapLibreMapInstance && this.nativeMapView) {
          hilog.warn(
            DOMAIN,
            'NativeMapView',
            '⚠️ MapLibreMap instance missing before onMapReady, invoking handleMapViewCreated directly'
          );
          this.handleMapViewCreated();
        }

        // ========== 只在首次初始化时调用 onMapReady 回调 ==========
        // 参考 Android 和 iOS 实现：onMapReady 只在地图首次加载完成时触发一次
        // setStyleUrl 等后续样式切换不应重复触发 onMapReady
        if (!this.hasTriggeredMapReady) {
          this.hasTriggeredMapReady = true;
          hilog.warn(DOMAIN, 'NativeMapView', '🚀 First style loaded - triggering onMapReady callbacks');

          this.applyInitialCameraIfNeeded('OnDidFinishLoadingStyle');

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
    console.info(`[NativeMapView] onSurfaceChanged called: ${rect.surfaceWidth}x${rect.surfaceHeight}`);

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
        // 同时更新 NAPI 层和 ETS 层的视图尺寸
        this.nativeMapView.resizeView(rect.surfaceWidth, rect.surfaceHeight);
        
        // ⚠️ 重要：同步更新 MapLibreMap 的视图尺寸（用于 InfoWindow 等 ETS 层功能）
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
      // 如果地图尚未初始化，使用新的尺寸重新初始化
      try {
        this.nativeMapView.resizeView(rect.surfaceWidth, rect.surfaceHeight);
        
        // ⚠️ 重要：初始化时也要设置 MapLibreMap 的视图尺寸
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
   * 表面销毁回调
   */
  onSurfaceDestroyed(surfaceId: string): void {

    if (this.nativeMapView) {
      try {
        // 完整的资源清理流程
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
    try {
      // 创建 MapLibreMap 实例（仅创建一次）
      if (!this.mapLibreMapInstance && this.nativeMapView) {
        const options = new MapLibreMapOptions();
        this.mapLibreMapInstance = new MapLibreMap(this.nativeMapView, options);
        hilog.info(DOMAIN, 'NativeMapViewController', '✅ MapLibreMap instance created');
        
        // ⚠️ 重要：立即同步当前的视图尺寸（因为 onSurfaceChanged 可能在 MapLibreMap 创建前就已经被调用）
        if (this.surfaceWidth > 0 && this.surfaceHeight > 0) {
          console.info(`[NativeMapView] Syncing view size to MapLibreMap: ${this.surfaceWidth}x${this.surfaceHeight}`);
          this.mapLibreMapInstance.resizeView(this.surfaceWidth, this.surfaceHeight);
        }
        
        // 连接手势检测器到 MapLibreMap
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
  private viewAnnotationRenderCallback?: (states: ViewAnnotationRenderState[]) => void;

  /**
   * 设置 AnnotationView 更新回调
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
   * 更新 AnnotationView 位置
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