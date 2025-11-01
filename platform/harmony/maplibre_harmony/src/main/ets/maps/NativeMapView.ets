import maplibre from 'libmaplibre.so';
import { hilog } from '@kit.PerformanceAnalysisKit';
import common from '@ohos.app.ability.common';
import { LatLng } from './geometry/LatLng';
import { DOMAIN } from '../constants/HiLogConstants';
import { MapGestureDetector } from './gestures/MapGestureDetector';
import { UiSettings } from './UiSettings';
import {
  OnMoveListener,
  OnScaleListener,
  OnRotateListener,
  OnMapClickListener,
  OnMapLongClickListener,
  OnDoubleTapListener,
  OnTiltListener,
  OnQuickZoomListener
} from './gestures/GestureListeners';
import { CompassView } from './widgets/CompassView';
import { LogoView } from './widgets/LogoView';
import { ScaleBarView, ScaleBarUnit } from './widgets/ScaleBarView';
import { CompassPosition } from './widgets/CompassPosition';
import { CompassVisibility } from './widgets/CompassVisibility';
import { RenderingStats } from './renderer/RenderingStats';
import { RenderingRefreshMode } from './types/NativeTypes';
import {
  OnCameraWillChangeListener,
  OnCameraIsChangingListener,
  OnCameraDidChangeListener,
  OnWillStartLoadingMapListener,
  OnDidFinishLoadingMapListener,
  OnDidFailLoadingMapListener,
  OnWillStartRenderingFrameListener,
  OnDidFinishRenderingFrameListener,
  OnDidFinishRenderingFrameWithStatsListener,
  OnWillStartRenderingMapListener,
  OnDidFinishRenderingMapListener,
  OnDidFinishLoadingStyleListener,
  OnStyleImageMissingListener,
  OnCanRemoveUnusedStyleImageListener,
  OnDidBecomeIdleListener,
  OnSourceChangedListener,
  OnPreCompileShaderListener,
  OnPostCompileShaderListener,
  OnShaderCompileFailedListener,
  OnGlyphsLoadedListener,
  OnGlyphsErrorListener,
  OnGlyphsRequestedListener,
  OnTileActionListener,
  OnSpriteLoadedListener,
  OnSpriteErrorListener,
  OnSpriteRequestedListener,
  OnMapReadyCallback
} from './listeners/MapEventListeners';
import { InfoWindowState, InfoWindowOverlay } from './annotations/InfoWindowOverlay';
import { InfoWindowPosition } from './annotations/InfoWindow';
import { AnnotationViewOverlay } from './annotations/AnnotationViewOverlay';
import { AnnotationViewData } from './annotations/AnnotationViewManager';
import { MapLibreMap } from './MapLibreMap';
import { MapLibreMapOptions } from './MapLibreMapOptions';

// 使用封装的 Marker 类型
import { Marker } from './annotations/Marker';
// 从 NAPI 模块导入相机选项类型
type CameraOptions = maplibre.CameraOptions;


type NullableNativeMapView = maplibre.NativeMapView | null

/**
 * 全局映射：NAPI NativeMapView -> ETS NativeMapViewController
 * 用于 MapLibreMap 找到对应的 controller 并注册自己
 */
const globalControllerMap: Map<maplibre.NativeMapView, NativeMapViewController> = new Map();

/**
 * 注册 MapLibreMap 实例到对应的 NativeMapViewController
 * 此函数由 MapLibreMap 构造函数调用
 * 
 * @param nativeMapView NAPI NativeMapView 实例
 * @param mapLibreMap MapLibreMap 实例
 * @param nativeMapViewComponent 可选的 NativeMapView 组件引用，用于设置 InfoWindow 回调
 */
export function registerMapLibreMap(
  nativeMapView: maplibre.NativeMapView, 
  mapLibreMap: MapLibreMap,
  nativeMapViewComponent?: NativeMapView
): void {
  const controller = globalControllerMap.get(nativeMapView);
  if (controller) {
    controller.setMapLibreMapInstance(mapLibreMap);
    hilog.info(DOMAIN, 'NativeMapView', 'MapLibreMap registered to controller');
    
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
      hilog.info(DOMAIN, 'NativeMapView', `Initial compass bearing: ${bearing}`);
      
      const latLng = mapLibreMap.getLatLng();
      const metersPerPixel = mapLibreMap.getMetersPerPixelAtLatitude(latLng.latitude);
      controller.updateScaleBarMetersPerPixel(metersPerPixel);
      hilog.info(DOMAIN, 'NativeMapView', `Initial ScaleBar metersPerPixel: ${metersPerPixel}`);
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
  private mapView: NullableNativeMapView = null;
  private isInitialized: boolean = false;
  private surfaceId: string = '';
  private surfaceWidth: number = 0;
  private surfaceHeight: number = 0;
  private pixelRatio: number = 1.0;  // 保存设备像素比
  private isSurfaceRectSet: boolean = false;  // 防止setXComponentSurfaceRect无限循环
  
  // 初始配置
  public styleUrl: string = "https://demotiles.maplibre.org/style.json";
  public initialLatitude: number = 30.2741;
  public initialLongitude: number = 120.1551;
  public initialZoom: number = 6;
  public initialBearing: number = 0;
  public initialPitch: number = 0;
  
  // 回调函数
  public onMapReadyCallback?: (mapView?: maplibre.NativeMapView) => void;
  
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

    hilog.warn(DOMAIN, "NativeMapView", `NativeMapView: onSurfaceCreated surfaceId: ${surfaceId}, delaying initialization`);
    this.surfaceId = surfaceId;

    try {
      // 获取应用上下文
      const context = getContext(this) as common.UIAbilityContext;
      
      // 使用应用私有缓存目录 + maplibre 子目录
      const cachePath = context.cacheDir + '/maplibre';
      hilog.info(DOMAIN, "NativeMapView", `Using cache path: ${cachePath}`);
      
      // 创建 MapView 实例并传递缓存路径
      hilog.warn(DOMAIN, "NativeMapView", `[DEBUG] Creating NativeMapView instance with cachePath...`);
      this.mapView = new maplibre.NativeMapView(cachePath);
      hilog.warn(DOMAIN, "NativeMapView", `[DEBUG] NativeMapView instance created successfully`);
      
      // 注册到全局映射
      if (this.mapView) {
        globalControllerMap.set(this.mapView, this);
        hilog.info(DOMAIN, "NativeMapView", `Controller registered to global map`);
      }

      // ✅ DPI 现在由 C++ 层直接获取（使用 OH_NativeDisplayManager_GetDefaultDisplayDensityDpi）
      // 不再需要从 ArkTS 传递
      hilog.info(DOMAIN, "NativeMapView", `DPI will be determined by C++ Native API`);

      // 🛡️ 延迟初始化：等待页面转换动画完成（通常需要 400-500ms）
      // ✅ 修复第二次进入崩溃：延迟增加到 800ms，确保 Native Window 完全稳定
      // 原因：页面转换动画可能需要更长时间，特别是在低性能设备上
      hilog.info(DOMAIN, "NativeMapView", `Scheduling delayed native window initialization (800ms delay)...`);
      
      setTimeout(() => {
        try {
          if (!this.mapView) {
            hilog.warn(DOMAIN, "NativeMapView", `mapView was destroyed before initialization`);
            return;
          }
          
          hilog.info(DOMAIN, "NativeMapView", `Setting native window after page transition (800ms elapsed)...`);
          // 设置渲染表面（使用默认方法，尺寸将在onSurfaceChanged中处理）
          this.mapView.setNativeWindow(BigInt(surfaceId));
          hilog.info(DOMAIN, "NativeMapView", `Native window set successfully`);

          hilog.info(DOMAIN, "NativeMapView", `Setting style URL: ${this.styleUrl}`);
          // 设置地图样式
          this.mapView.setStyleUrl(this.styleUrl);
          
          hilog.info(DOMAIN, "NativeMapView", `Delayed initialization completed`);
        } catch (error) {
          hilog.error(DOMAIN, "NativeMapView", `Delayed initialization failed: ${error.message}`);
        }
      }, 800); // ✅ 延迟 800ms，确保页面转换完全完成（从 500ms 增加）

      // 延迟调用 jumpTo，等待地图完全初始化
      setTimeout(() => {
        try {
          if (this.mapView && this.isInitialized) {
            hilog.info(DOMAIN, "NativeMapView", `Delayed jumpTo: bearing=${this.initialBearing}, lat=${this.initialLatitude}, lng=${this.initialLongitude}, pitch=${this.initialPitch}, zoom=${this.initialZoom}`);
            this.mapView.jumpTo(this.initialBearing, this.initialLatitude, this.initialLongitude, this.initialPitch, this.initialZoom);
            hilog.info(DOMAIN, 'NativeMapView', 'Delayed jumpTo completed successfully');
          } else {
            hilog.warn(DOMAIN, 'NativeMapView', `Delayed jumpTo skipped - mapView=${this.mapView ? 'exists' : 'null'}, initialized=${this.isInitialized}`);
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
      
      // 设置手势检测器的地图控制器引用
      this.gestureDetector.setMapController(this.mapView);
      
      hilog.info(DOMAIN, 'NativeMapView', 'Map initialized successfully');
      
      // 设置相机监听器来更新 Compass 和 AnnotationView
      this.mapView.addOnCameraMoveListener(() => {
        this.updateCompassBearing();
        this.updateAnnotationViews();
      });
      
      // ========== 注册 Android/iOS 风格的监听器回调到 C++ 层 ==========
      hilog.info(DOMAIN, 'NativeMapView', 'Registering event listeners to C++ layer...');
      
      // 相机事件监听器
      this.mapView.addOnCameraWillChangeListener((animated: boolean) => {
        for (const listener of this.onCameraWillChangeListeners) {
          try { listener.onCameraWillChange(animated); } catch (error) { 
            hilog.error(DOMAIN, 'NativeMapView', `OnCameraWillChangeListener error: ${error.message}`);
          }
        }
      });
      
      this.mapView.addOnCameraIsChangingListener(() => {
        for (const listener of this.onCameraIsChangingListeners) {
          try { listener.onCameraIsChanging(); } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnCameraIsChangingListener error: ${error.message}`);
          }
        }
      });
      
      this.mapView.addOnCameraDidChangeListener((animated: boolean) => {
        for (const listener of this.onCameraDidChangeListeners) {
          try { listener.onCameraDidChange(animated); } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnCameraDidChangeListener error: ${error.message}`);
          }
        }
      });
      
      // 地图加载事件监听器
      this.mapView.addOnWillStartLoadingMapListener(() => {
        for (const listener of this.onWillStartLoadingMapListeners) {
          try { listener.onWillStartLoadingMap(); } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnWillStartLoadingMapListener error: ${error.message}`);
          }
        }
      });
      
      this.mapView.addOnDidFinishLoadingMapListener(() => {
        for (const listener of this.onDidFinishLoadingMapListeners) {
          try { listener.onDidFinishLoadingMap(); } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnDidFinishLoadingMapListener error: ${error.message}`);
          }
        }
      });
      
      this.mapView.addOnDidFailLoadingMapListener((errorMessage: string) => {
        for (const listener of this.onDidFailLoadingMapListeners) {
          try { listener.onDidFailLoadingMap(errorMessage); } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnDidFailLoadingMapListener error: ${error.message}`);
          }
        }
      });
      
      // 渲染事件监听器
      this.mapView.addOnWillStartRenderingFrameListener(() => {
        for (const listener of this.onWillStartRenderingFrameListeners) {
          try { listener.onWillStartRenderingFrame(); } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnWillStartRenderingFrameListener error: ${error.message}`);
          }
        }
      });
      
      this.mapView.addOnDidFinishRenderingFrameListener((fully: boolean, frameEncodingTime: number, frameRenderingTime: number) => {
        // 通知简单版本的监听器
        for (const listener of this.onDidFinishRenderingFrameListeners) {
          try { listener.onDidFinishRenderingFrame(fully, frameEncodingTime, frameRenderingTime); } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnDidFinishRenderingFrameListener error: ${error.message}`);
          }
        }
        // 通知带统计信息的监听器
        const stats = new RenderingStats(fully, frameEncodingTime, frameRenderingTime);
        for (const listener of this.onDidFinishRenderingFrameWithStatsListeners) {
          try { listener.onDidFinishRenderingFrame(fully, stats); } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnDidFinishRenderingFrameWithStatsListener error: ${error.message}`);
          }
        }
      });
      
      this.mapView.addOnWillStartRenderingMapListener(() => {
        for (const listener of this.onWillStartRenderingMapListeners) {
          try { listener.onWillStartRenderingMap(); } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnWillStartRenderingMapListener error: ${error.message}`);
          }
        }
      });
      
      this.mapView.addOnDidFinishRenderingMapListener((fully: boolean) => {
        for (const listener of this.onDidFinishRenderingMapListeners) {
          try { listener.onDidFinishRenderingMap(fully); } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnDidFinishRenderingMapListener error: ${error.message}`);
          }
        }
      });
      
      // 样式事件监听器
      this.mapView.addOnDidFinishLoadingStyleListener(() => {
        for (const listener of this.onDidFinishLoadingStyleListeners) {
          try { listener.onDidFinishLoadingStyle(); } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnDidFinishLoadingStyleListener error: ${error.message}`);
          }
        }
      });
      
      this.mapView.addOnStyleImageMissingListener((id: string) => {
        for (const listener of this.onStyleImageMissingListeners) {
          try { listener.onStyleImageMissing(id); } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnStyleImageMissingListener error: ${error.message}`);
          }
        }
      });
      
      // 其他事件监听器
      this.mapView.addOnDidBecomeIdleListener(() => {
        for (const listener of this.onDidBecomeIdleListeners) {
          try { listener.onDidBecomeIdle(); } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnDidBecomeIdleListener error: ${error.message}`);
          }
        }
      });
      
      this.mapView.addOnSourceChangedListener((id: string) => {
        for (const listener of this.onSourceChangedListeners) {
          try { listener.onSourceChangedListener(id); } catch (error) {
            hilog.error(DOMAIN, 'NativeMapView', `OnSourceChangedListener error: ${error.message}`);
          }
        }
      });
      
      hilog.info(DOMAIN, 'NativeMapView', 'All event listeners registered to C++ layer');
      
      // 初始更新一次 Compass bearing
      this.updateCompassBearing();
      
      // 调用 onMapReady 回调
      if (this.onMapReadyCallback) {
        try {
          this.onMapReadyCallback(this.mapView);
          hilog.info(DOMAIN, 'NativeMapView', 'onMapReady callback invoked');
        } catch (callbackError) {
          hilog.error(DOMAIN, 'NativeMapView', `onMapReady callback error: ${callbackError.message}`);
        }
      }
      
      // 调用所有通过 getMapAsync 注册的回调
      if (this.onMapReadyCallbacks.length > 0) {
        hilog.info(DOMAIN, 'NativeMapView', `Invoking ${this.onMapReadyCallbacks.length} getMapAsync callbacks`);
        for (const callback of this.onMapReadyCallbacks) {
          try {
            callback.onMapReady(this.mapView);
          } catch (callbackError) {
            hilog.error(DOMAIN, 'NativeMapView', `getMapAsync callback error: ${callbackError.message}`);
          }
        }
        // 清空回调列表
        this.onMapReadyCallbacks = [];
      }
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `Failed to initialize map: ${error.message}`);
      hilog.error(DOMAIN, 'NativeMapView', `Error stack: ${error.stack}`);
    }
  }


  /**
   * 表面变化回调
   */
  onSurfaceChanged(surfaceId: string, rect: SurfaceRect): void {
    hilog.info(DOMAIN, "NativeMapView", `onSurfaceChanged: ${rect.surfaceWidth}x${rect.surfaceHeight}`);

    // 防止异常小的尺寸（可能是 setXComponentSurfaceRect 的副作用）
    if (rect.surfaceWidth < 100 || rect.surfaceHeight < 100) {
      hilog.warn(DOMAIN, 'NativeMapView', 
        `onSurfaceChanged: Ignoring abnormal size ${rect.surfaceWidth}x${rect.surfaceHeight}`);
      return;
    }

    // ✅ HarmonyOS的onSurfaceChanged传入的就是逻辑像素，直接使用
    this.surfaceWidth = rect.surfaceWidth;
    this.surfaceHeight = rect.surfaceHeight;

    if (this.mapView && this.isInitialized) {
      try {
        hilog.info(DOMAIN, 'NativeMapView', 
          `Resizing map to: ${rect.surfaceWidth}x${rect.surfaceHeight} (logical), pixelRatio=${this.pixelRatio.toFixed(4)}`);
        
        this.mapView.resizeView(rect.surfaceWidth, rect.surfaceHeight);
        hilog.info(DOMAIN, 'NativeMapView', `Map resized successfully`);
      } catch (error) {
        hilog.error(DOMAIN, 'NativeMapView', `Failed to resize map: ${error.message}`);
      }
    } else if (this.mapView && !this.isInitialized) {
      // 如果地图尚未初始化，使用新的尺寸重新初始化
      try {
        hilog.info(DOMAIN, 'NativeMapView', 
          `Initializing map with: ${rect.surfaceWidth}x${rect.surfaceHeight} (logical)`);
        
        this.mapView.resizeView(rect.surfaceWidth, rect.surfaceHeight);
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
    console.info(`NativeMapView: onSurfaceDestroyed surfaceId: ${surfaceId}`);

    if (this.mapView) {
      try {
        // 完整的资源清理流程
        this.cleanupMapResources();
        this.mapView = null;
        this.isInitialized = false;
        hilog.info(DOMAIN, 'NativeMapView', 'Map destroyed successfully');
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
      hilog.info(DOMAIN, 'NativeMapView', 'Starting map resource cleanup');
      
      // 1. 停止所有渲染操作
      if (this.mapView) {
        // 暂停渲染
        // this.mapView.pause();
        
        // 2. 清理OpenGL资源
        // this.mapView.cleanupGLResources();
        
        // 3. 清理网络请求
        // this.mapView.cancelAllRequests();
        
        // 4. 清理缓存
        // this.mapView.clearCache();
      }
      
      hilog.info(DOMAIN, 'NativeMapView', 'Map resource cleanup completed');
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `Error during map resource cleanup: ${error.message}`);
    }
  }

  /**
   * 获取地图实例
   */
  getMapView(): NullableNativeMapView {
    return this.mapView;
  }

  /**
   * 检查是否已初始化
   */
  isMapInitialized(): boolean {
    return this.isInitialized && this.mapView !== null;
  }

  /**
   * 清理所有资源
   */
  cleanupResources(): void {
    try {
      hilog.info(DOMAIN, 'NativeMapViewController', 'Starting resource cleanup');
      
      if (this.mapView) {
        // 清理地图资源
        this.cleanupMapResources();
        this.mapView = null;
      }
      
      this.isInitialized = false;
      this.surfaceId = '';
      this.surfaceWidth = 0;
      this.surfaceHeight = 0;
      
      hilog.info(DOMAIN, 'NativeMapViewController', 'Resource cleanup completed');
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapViewController', `Error during resource cleanup: ${error.message}`);
    }
  }

  /**
   * 设置地图样式
   */
  setStyleUrl(url: string): void {
    if (this.mapView && this.isInitialized) {
      try {
        this.mapView.setStyleUrl(url);
        hilog.info(DOMAIN, 'NativeMapView', `Style URL set to: ${url}`);
      } catch (error) {
        hilog.error(DOMAIN, 'NativeMapView', `Failed to set style URL: ${error.message}`);
      }
    }
  }

  /**
   * 设置地图位置
   */
  jumpTo(angle: number, latitude: number, longitude: number, pitch: number, zoom: number): void {
    if (this.mapView && this.isInitialized) {
      try {
        this.mapView.jumpTo(angle, latitude, longitude, pitch, zoom);
        hilog.info(DOMAIN, 'NativeMapView', `Jumped to: lat=${latitude}, lng=${longitude}, zoom=${zoom}`);
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
    if (this.mapView && this.isInitialized) {
      try {
        this.mapView.flyTo(options, duration);
        hilog.info(DOMAIN, 'NativeMapView', 
          `Flying to: center=${JSON.stringify(options.center)}, zoom=${options.zoom}, bearing=${options.bearing}, pitch=${options.pitch}, duration=${duration}ms`);
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
    if (this.mapView && this.isInitialized) {
      try {
        this.mapView.easeTo(options, duration);
        hilog.info(DOMAIN, 'NativeMapView', 
          `Easing to: center=${JSON.stringify(options.center)}, zoom=${options.zoom}, bearing=${options.bearing}, pitch=${options.pitch}, duration=${duration}ms`);
      } catch (error) {
        hilog.error(DOMAIN, 'NativeMapView', `Failed to ease to position: ${error.message}`);
      }
    }
  }

  /**
   * 添加标记
   */
  addMarkers(markers: Marker[]): number[] {
    if (this.mapView && this.isInitialized) {
      try {
        const markerIds: number[] = this.mapView.addMarkers(markers) as number[];
        hilog.info(DOMAIN, 'NativeMapView', `Added ${markers.length} markers`);
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
    if (this.mapView && this.isInitialized) {
      try {
        this.mapView.triggerRepaint();
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
    if (!this.mapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'setContentPadding: Map not initialized');
      return;
    }
    
    try {
      this.mapView.setContentPadding(padding);
      hilog.info(DOMAIN, 'NativeMapView', `setContentPadding: [${padding.join(', ')}]`);
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `setContentPadding error: ${error.message}`);
    }
  }
  
  /**
   * 获取内容边距（对齐 Android API）
   * @returns 边距数组 [top, left, bottom, right]
   */
  getContentPadding(): number[] {
    if (!this.mapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'getContentPadding: Map not initialized');
      return [0, 0, 0, 0];
    }
    
    try {
      const padding = this.mapView.getContentPadding();
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
    if (!this.mapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'getPixelRatio: Map not initialized');
      return 1.0;
    }
    
    try {
      return this.mapView.getPixelRatio() as number;
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
    if (this.mapView && this.isInitialized && this.compassBearingUpdateCallback) {
      try {
        const bearing = this.mapView.getBearing();
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
    if (this.mapView && this.isInitialized) {
      try {
        // 使用动画方式归正北（参考 Android TIME_MAP_NORTH_ANIMATION = 150ms）
        this.mapView.setBearing(0, 150);
        hilog.info(DOMAIN, 'NativeMapView', 'Reset north animation started');
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
    if (this.mapView && this.isInitialized) {
      try {
        const pitch = this.mapView.getPitch();
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
    if (this.mapView && this.isInitialized) {
      // 地图已就绪，立即回调
      try {
        callback.onMapReady(this.mapView);
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
    if (!this.mapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'queueEvent: Map not initialized');
      return;
    }
    
    // TODO: 实现真正的渲染线程队列
    // 当前作为简单实现，直接在下一个事件循环执行
    setTimeout(() => {
      try {
        runnable();
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
    if (!this.mapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'setMaximumFps: Map not initialized');
      return;
    }
    
    try {
      // TODO: C++ NAPI 绑定
      // this.mapView.setMaximumFps(maximumFps);
      hilog.info(DOMAIN, 'NativeMapView', `setMaximumFps: ${maximumFps} (Not yet implemented in C++)`);
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `setMaximumFps error: ${error.message}`);
    }
  }

  /**
   * 设置渲染刷新模式（对齐 Android setRenderingRefreshMode）
   * @param mode 渲染模式
   */
  setRenderingRefreshMode(mode: RenderingRefreshMode): void {
    if (!this.mapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'setRenderingRefreshMode: Map not initialized');
      return;
    }
    
    try {
      // TODO: C++ NAPI 绑定
      // this.mapView.setRenderingRefreshMode(mode);
      const modeName = mode === RenderingRefreshMode.CONTINUOUS ? 'CONTINUOUS' : 'WHEN_DIRTY';
      hilog.info(DOMAIN, 'NativeMapView', `setRenderingRefreshMode: ${modeName} (Not yet implemented in C++)`);
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `setRenderingRefreshMode error: ${error.message}`);
    }
  }

  /**
   * 获取渲染刷新模式（对齐 Android getRenderingRefreshMode）
   * @returns 当前渲染模式
   */
  getRenderingRefreshMode(): RenderingRefreshMode {
    // TODO: C++ NAPI 绑定
    // 当前返回默认值
    return RenderingRefreshMode.WHEN_DIRTY;
  }

  // ========== 性能和缓存配置 ==========
  
  /**
   * 设置是否预加载瓦片（对齐 Android prefetchesTiles）
   * @param enabled 是否启用预加载
   */
  setPrefetchesTiles(enabled: boolean): void {
    if (!this.mapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'setPrefetchesTiles: Map not initialized');
      return;
    }
    
    try {
      this.mapView.setPrefetchTiles(enabled);
      hilog.info(DOMAIN, 'NativeMapView', `setPrefetchesTiles: ${enabled}`);
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `setPrefetchesTiles error: ${error.message}`);
    }
  }

  /**
   * 设置是否启用瓦片缓存（对齐 Android tileCacheEnabled）
   * @param enabled 是否启用缓存
   */
  setTileCacheEnabled(enabled: boolean): void {
    if (!this.mapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'setTileCacheEnabled: Map not initialized');
      return;
    }
    
    try {
      // TODO: C++ NAPI 绑定
      // this.mapView.setTileCacheEnabled(enabled);
      hilog.info(DOMAIN, 'NativeMapView', `setTileCacheEnabled: ${enabled} (Not yet implemented in C++)`);
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `setTileCacheEnabled error: ${error.message}`);
    }
  }

  /**
   * 设置 LOD 最小半径（对齐 iOS tileLodMinRadius）
   * @param radius 最小半径（瓦片单位）
   */
  setTileLodMinRadius(radius: number): void {
    if (!this.mapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'setTileLodMinRadius: Map not initialized');
      return;
    }
    
    try {
      this.mapView.setTileLodMinRadius(radius);
      hilog.info(DOMAIN, 'NativeMapView', `setTileLodMinRadius: ${radius}`);
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `setTileLodMinRadius error: ${error.message}`);
    }
  }

  /**
   * 设置 LOD 缩放因子（对齐 iOS tileLodScale）
   * @param scale 缩放因子
   */
  setTileLodScale(scale: number): void {
    if (!this.mapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'setTileLodScale: Map not initialized');
      return;
    }
    
    try {
      this.mapView.setTileLodScale(scale);
      hilog.info(DOMAIN, 'NativeMapView', `setTileLodScale: ${scale}`);
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `setTileLodScale error: ${error.message}`);
    }
  }

  /**
   * 设置 LOD 俯仰角阈值（对齐 iOS tileLodPitchThreshold）
   * @param threshold 俯仰角阈值（弧度）
   */
  setTileLodPitchThreshold(threshold: number): void {
    if (!this.mapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'setTileLodPitchThreshold: Map not initialized');
      return;
    }
    
    try {
      this.mapView.setTileLodPitchThreshold(threshold);
      hilog.info(DOMAIN, 'NativeMapView', `setTileLodPitchThreshold: ${threshold}`);
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `setTileLodPitchThreshold error: ${error.message}`);
    }
  }

  /**
   * 设置 LOD 缩放级别偏移（对齐 iOS tileLodZoomShift）
   * @param shift 缩放级别偏移
   */
  setTileLodZoomShift(shift: number): void {
    if (!this.mapView || !this.isInitialized) {
      hilog.warn(DOMAIN, 'NativeMapView', 'setTileLodZoomShift: Map not initialized');
      return;
    }
    
    try {
      this.mapView.setTileLodZoomShift(shift);
      hilog.info(DOMAIN, 'NativeMapView', `setTileLodZoomShift: ${shift}`);
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `setTileLodZoomShift error: ${error.message}`);
    }
  }

  /**
   * 低内存警告处理（对齐 Android onLowMemory）
   */
  onLowMemory(): void {
    if (!this.mapView || !this.isInitialized) {
      return;
    }
    
    try {
      this.mapView.onLowMemory();
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
export struct NativeMapView {
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
  onMapReady?: (map: MapLibreMap) => void | Promise<void>;
  onMapLoaded?: () => void;
  onMapError?: (error: string) => void;
  
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
      hilog.info(DOMAIN, 'NativeMapView', 'Component aboutToAppear');
      this.isDestroyed = false;
      
      // 将组件的 prop 和回调传递给 controller
      if (this.controller) {
        this.controller.styleUrl = this.styleUrl;
        this.controller.initialLatitude = this.initialLatitude;
        this.controller.initialLongitude = this.initialLongitude;
        this.controller.initialZoom = this.initialZoom;
        this.controller.initialBearing = this.initialBearing;
        this.controller.initialPitch = this.initialPitch;
        
        // 包装 onMapReady 回调以设置 InfoWindowManager 回调
        this.controller.onMapReadyCallback = (mapView?: maplibre.NativeMapView) => {
          // 创建 MapLibreMap 实例
          if (mapView && !this.controller.getMapLibreMapInstance()) {
            const options = new MapLibreMapOptions();
            const mapLibreMap = new MapLibreMap(mapView, options);
            this.controller.setMapLibreMapInstance(mapLibreMap);
          }
          
          // 调用用户的回调，传入 MapLibreMap 实例
          const mapLibreMap = this.controller.getMapLibreMapInstance();
          if (this.onMapReady && mapLibreMap) {
            this.onMapReady(mapLibreMap);
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
        
        hilog.info(DOMAIN, 'NativeMapView', `Initial config: lat=${this.initialLatitude}, lng=${this.initialLongitude}, zoom=${this.initialZoom}, bearing=${this.initialBearing}, pitch=${this.initialPitch}`);
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
    hilog.info(DOMAIN, 'NativeMapView', '========== aboutToDisappear START (Android/iOS pattern) ==========');
    
    // 1. 设置销毁标志（参考 Android MapView.destroyed）
    this.isDestroyed = true;
    hilog.debug(DOMAIN, 'NativeMapView', 'Set isDestroyed flag');
    
    try {
      // 2. 取消所有动画和手势（参考 Android cancelAnimators()）
      hilog.debug(DOMAIN, 'NativeMapView', 'Cancelling all animations and gestures...');
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
        hilog.info(DOMAIN, 'NativeMapView', 'Calling native destroyAsync()...');
        
        // 使用异步方式，传入完成回调
        mapView.destroyAsync(() => {
          hilog.info(DOMAIN, 'NativeMapView', '✅ Async destroy completed');
          hilog.info(DOMAIN, 'NativeMapView', '========== aboutToDisappear END ==========');
        });
        
        hilog.debug(DOMAIN, 'NativeMapView', 'Async destroy initiated, returning immediately');
      } else {
        hilog.warn(DOMAIN, 'NativeMapView', 'MapView is null, skipping destroy');
        hilog.info(DOMAIN, 'NativeMapView', '========== aboutToDisappear END ==========');
      }
      
      // 4. 清理 UI 组件引用（立即执行，不等待异步完成）
      // Controller 的引用会在组件销毁时自动清理
      // 事件监听器会在 C++ 层的 cleanupAllResourcesAsync 中清理
      
      // 5. 清理全局映射
      if (mapView) {
        globalControllerMap.delete(mapView);
        hilog.debug(DOMAIN, 'NativeMapView', 'Removed controller from global map');
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
      case CompassPosition.TopLeft:
      case CompassPosition.BottomLeft:
        return margins.left;
      case CompassPosition.TopRight:
      case CompassPosition.BottomRight:
      default:
        return `calc(100% - 48vp - ${margins.right}vp)`; // 100% - 组件宽度 - 右边距
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
      case CompassPosition.TopLeft:
      case CompassPosition.TopRight:
      default:
        return margins.top;
      case CompassPosition.BottomLeft:
      case CompassPosition.BottomRight:
        return `calc(100% - 48vp - ${margins.bottom}vp)`; // 100% - 组件高度 - 下边距
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
      case CompassPosition.TopLeft:
      case CompassPosition.BottomLeft:
      default:
        return margins.left;
      case CompassPosition.TopRight:
      case CompassPosition.BottomRight:
        return `calc(100% - 80vp - ${margins.right}vp)`; // 100% - Logo宽度 - 右边距
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
      case CompassPosition.TopLeft:
      case CompassPosition.TopRight:
        return margins.top;
      case CompassPosition.BottomLeft:
      case CompassPosition.BottomRight:
      default:
        return `calc(100% - 40vp - ${margins.bottom}vp)`; // 100% - Logo高度 - 下边距
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
      case CompassPosition.TopLeft:
      case CompassPosition.BottomLeft:
      default:
        return margins.left;
      case CompassPosition.TopRight:
      case CompassPosition.BottomRight:
        return `calc(100% - 200vp - ${margins.right}vp)`; // 100% - ScaleBar最大宽度 - 右边距
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
      case CompassPosition.TopLeft:
      case CompassPosition.TopRight:
      default:
        return margins.top;
      case CompassPosition.BottomLeft:
      case CompassPosition.BottomRight:
        return `calc(100% - 40vp - ${margins.bottom}vp)`; // 100% - ScaleBar高度 - 下边距
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
        
        hilog.info(DOMAIN, 'NativeMapView', `InfoWindow shown for marker ${marker.getId()}`);
      });
      
      // 隐藏 InfoWindow
      infoWindowManager.setOnHideUICallback((marker: Marker) => {
        const index = this.visibleInfoWindows.findIndex(
          item => item.marker.getId() === marker.getId()
        );
        if (index >= 0) {
          this.visibleInfoWindows.splice(index, 1);
          hilog.info(DOMAIN, 'NativeMapView', `InfoWindow hidden for marker ${marker.getId()}`);
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
      
      hilog.info(DOMAIN, 'NativeMapView', 'InfoWindow callbacks setup completed');
      
      // ========== 设置 AnnotationView 回调 ==========
      const annotationViewManager = mapLibreMap.getMarkerManager().getAnnotationViewManager();
      
      // 监听 AnnotationView 数据变化，更新 UI
      // 注意：由于 AnnotationViewManager 目前没有回调机制，我们需要在相机移动时更新
      // 这将在相机监听器中实现
      
      hilog.info(DOMAIN, 'NativeMapView', 'AnnotationView callbacks setup completed');
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
              const nativeLatLng = mapView.latLngForPixel(screenX, screenY);
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
      hilog.info(DOMAIN, 'NativeMapView', `setPitch: Set pitch to ${pitch} degrees`);
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
      hilog.info(DOMAIN, 'NativeMapView', 'cancelTransitions: All transitions cancelled');
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
   * 用于恢复地图渲染、重新启动定位等
   */
  onPageShow(): void {
    hilog.info(DOMAIN, 'NativeMapView', 'onPageShow: Resuming map rendering');
    // 恢复渲染
    this.controller.triggerRepaint();
    
    // TODO: 恢复其他资源（如位置服务）
  }

  /**
   * 页面隐藏时调用（鸿蒙生命周期）
   * 用于暂停地图渲染、暂停定位等，节省资源
   */
  onPageHide(): void {
    hilog.info(DOMAIN, 'NativeMapView', 'onPageHide: Pausing map rendering');
    // TODO: 暂停渲染和其他资源
  }

  /**
   * 返回键处理（鸿蒙生命周期）
   * @returns true 表示消费了返回事件，false 表示不消费
   */
  onBackPress(): boolean {
    hilog.info(DOMAIN, 'NativeMapView', 'onBackPress: Handling back press');
    
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
}
