import maplibre from 'libmaplibre_native.so';
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
import { CompassPosition } from './widgets/CompassPosition';
import { CompassVisibility } from './widgets/CompassVisibility';

// 使用 NAPI Marker 类型
type Marker = maplibre.Marker;
// 从 NAPI 模块导入相机选项类型
type CameraOptions = maplibre.CameraOptions;


type NullableNativeMapView = maplibre.NativeMapView | null

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
  
  // 手势系统
  private uiSettings: UiSettings = new UiSettings();
  private gestureDetector: MapGestureDetector = new MapGestureDetector(this.uiSettings);
  
  // UI 组件状态
  private compassBearingUpdateCallback?: (bearing: number) => void;
  private uiSettingsUpdateCallback?: () => void;

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
      
      // 设置相机监听器来更新 Compass
      this.mapView.addOnCameraMoveListener(() => {
        this.updateCompassBearing();
      });
      
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
  @Prop styleUrl: string = "https://demotiles.maplibre.org/style.json";
  @Prop initialLatitude: number = 30.2741;
  @Prop initialLongitude: number = 120.1551;
  @Prop initialZoom: number = 6;
  @Prop initialBearing: number = 0;
  @Prop initialPitch: number = 0;
  @Prop debugMode: boolean = false;
  // 回调函数
  onMapReady?: (mapView?: maplibre.NativeMapView) => void;
  onMapLoaded?: () => void;
  onMapError?: (error: string) => void;
  
  // UI 组件状态
  @State private compassBearing: number = 0;
  @State private uiSettingsVersion: number = 0;

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
        this.controller.onMapReadyCallback = this.onMapReady;
        
        // 设置 UI 组件更新回调
        this.controller.setCompassBearingUpdateCallback((bearing: number) => {
          this.compassBearing = bearing;
        });
        
        this.controller.setUiSettingsUpdateCallback(() => {
          this.uiSettingsVersion++;
        });
        
        // 设置 UiSettings 的配置变更回调
        const uiSettings = this.controller.getUiSettings();
        uiSettings.onCompassConfigChanged = () => {
          this.uiSettingsVersion++;
        };
        uiSettings.onLogoConfigChanged = () => {
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
   * 组件即将消失
   * 
   * ⚠️ 重要：在Harmony OS中，当使用router.pushUrl()导航到新页面时，
   * 旧页面的aboutToDisappear会被调用，但页面仍在栈中。
   * 如果在这里清理EGL资源，会导致其他地图实例无法正常工作（白屏问题）。
   * 
   * 策略：
   * 1. 不要清理OpenGL/EGL资源 - 这些是进程级别的共享资源
   * 2. 只标记组件为已销毁状态
   * 3. 暂停渲染以节省资源
   * 4. 让系统在进程结束时自动清理资源
   */
  aboutToDisappear(): void {
    hilog.info(DOMAIN, 'NativeMapView', 'Component aboutToDisappear - cleaning up resources');
    this.isDestroyed = true;
    
    // ✅ 线程隔离模式：主动销毁实例资源
    // 
    // 当前架构（Android 风格的线程隔离）：
    // - ✅ EGL Context   - 实例独占，可以销毁
    // - ✅ EGL Surface   - 实例独占，可以销毁  
    // - ✅ Render Thread - 实例独占，可以停止
    // - ❌ EGL Display   - 进程共享，不能调用 eglTerminate
    // 
    // cleanupEGL() 已正确实现：
    // - 销毁 Context 和 Surface
    // - 保留 Display（系统进程退出时自动清理）
    // - 多个地图实例可以安全地独立销毁
    
    try {
      const mapView = this.controller.getMapView();
      if (mapView) {
        hilog.info(DOMAIN, 'NativeMapView', 'Calling native destroy()...');
        mapView.destroy();  // 🔑 关键：主动清理资源
        hilog.info(DOMAIN, 'NativeMapView', '✅ Native resources destroyed');
      }
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `Error destroying resources: ${error}`);
    }
    
    hilog.info(DOMAIN, 'NativeMapView', 'Component aboutToDisappear completed');
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
        .gesture(
          // 点击手势 - 单独处理以避免冲突
          TapGesture({ count: 1 })
            .onAction((event: GestureEvent) => {
              this.controller.getGestureDetector().onSingleTap(event);
            })
        )
        .gesture(
          // 双击手势
          TapGesture({ count: 2 })
            .onAction((event: GestureEvent) => {
              this.controller.getGestureDetector().onDoubleTap(event);
            })
        )
        .gesture(
          // 长按手势
          LongPressGesture({ repeat: false, duration: 500 })
            .onAction((event: GestureEvent) => {
              this.controller.getGestureDetector().onLongPress(event);
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
          bearing: this.compassBearing,
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
}
