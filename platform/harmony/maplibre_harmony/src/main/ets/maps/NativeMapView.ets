import { Marker } from './annotations/Marker';
import maplibre from 'libmaplibre_native.so'
import { hilog } from '@kit.PerformanceAnalysisKit';
import { LatLng } from './geometry/LatLng';
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

// 日志域名
const DOMAIN = 0xFF00;

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
  
  // 手势系统
  private uiSettings: UiSettings = new UiSettings();
  private gestureDetector: MapGestureDetector = new MapGestureDetector(this.uiSettings);

  /**
   * 表面创建回调
   */
  onSurfaceCreated(surfaceId: string): void {

    hilog.warn(DOMAIN, "NativeMapView", `NativeMapView: onSurfaceCreated surfaceId: ${surfaceId}`);
    this.surfaceId = surfaceId;

    try {
      // 创建 MapView 实例
      this.mapView = new maplibre.NativeMapView();

      hilog.warn(DOMAIN, "NativeMapView", `NativeMapView: setDebug`);
      // 启用调试模式
      // this.mapView.setDebug(true);
      hilog.warn(DOMAIN, "NativeMapView", `NativeMapView: setNativeWindow`);

      // 设置渲染表面（使用默认方法，尺寸将在onSurfaceChanged中处理）
      this.mapView.setNativeWindow(BigInt(surfaceId));

      hilog.warn(DOMAIN, "NativeMapView", `NativeMapView: setStyleUrl`);
      // 设置地图样式
      this.mapView.setStyleUrl("https://demotiles.maplibre.org/style.json");

      hilog.warn(DOMAIN, "NativeMapView", `NativeMapView: jumpTo`);
      // 设置初始位置和缩放
      this.mapView.jumpTo(0, 39.9042, 116.4074, 0, 10); // 北京


      this.isInitialized = true;
      
      // 设置手势检测器的地图控制器引用
      this.gestureDetector.setMapController(this.mapView);
      
      hilog.info(DOMAIN, 'NativeMapView', 'Map initialized successfully');
    } catch (error) {
      hilog.error(DOMAIN, 'NativeMapView', `Failed to initialize map: ${error.message}`);
    }
  }

  /**
   * 表面变化回调
   */
  onSurfaceChanged(surfaceId: string, rect: SurfaceRect): void {
    console.info(`NativeMapView: onSurfaceChanged surfaceId: ${surfaceId}, rect: ${JSON.stringify(rect)}`);

    this.surfaceWidth = rect.surfaceWidth;
    this.surfaceHeight = rect.surfaceHeight;

    if (this.mapView && this.isInitialized) {
      try {
        // 调整地图大小
        this.mapView.resizeView(rect.surfaceWidth, rect.surfaceHeight);
        hilog.info(DOMAIN, 'NativeMapView', `Map resized to ${rect.surfaceWidth}x${rect.surfaceHeight}`);
      } catch (error) {
        hilog.error(DOMAIN, 'NativeMapView', `Failed to resize map: ${error.message}`);
      }
    } else if (this.mapView && !this.isInitialized) {
      // 如果地图尚未初始化，使用新的尺寸重新初始化
      try {
        hilog.info(DOMAIN, 'NativeMapView', `Reinitializing map with size ${rect.surfaceWidth}x${rect.surfaceHeight}`);
        // 使用resizeView方法调整尺寸
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
  @Prop initialLatitude: number = 39.9042;
  @Prop initialLongitude: number = 116.4074;
  @Prop initialZoom: number = 10;
  @Prop initialBearing: number = 0;
  @Prop initialPitch: number = 0;
  @Prop debugMode: boolean = false;
  // 回调函数
  onMapReady?: () => void;
  onMapLoaded?: () => void;
  onMapError?: (error: string) => void;

  /**
   * 组件即将出现
   */
  aboutToAppear(): void {
    hilog.info(DOMAIN, 'NativeMapView', 'Component aboutToAppear');
    this.isDestroyed = false;
  }

  /**
   * 组件即将消失
   */
  aboutToDisappear(): void {
    hilog.info(DOMAIN, 'NativeMapView', 'Component aboutToDisappear');
    this.isDestroyed = true;
    
    // 清理资源
    if (this.controller) {
      this.controller.cleanupResources();
    }
  }

  /**
   * 构建组件
   */
  build() {
    Stack() {
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
   * 跳转到指定位置
   */
  jumpTo(angle: number, latitude: number, longitude: number, pitch: number, zoom: number): void {
    this.controller.jumpTo(angle, latitude, longitude, pitch, zoom);
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
