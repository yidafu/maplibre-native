import { Marker } from './annotations/Marker';
import maplibre from 'libmaplibre_native.so'
import { hilog } from '@kit.PerformanceAnalysisKit';
import { LatLng } from './geometry/LatLng';

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
        .onClick((event: ClickEvent) => {
          this.handleMapClick(event);
        })
        .onTouch((event: TouchEvent) => {
          this.handleMapTouch(event);
        })

    }
  }

  /**
   * 处理地图点击事件
   */
  private handleMapClick(event: ClickEvent): void {
    hilog.warn(DOMAIN, "NativeMapView", "Map Click")
    if (this.controller.isMapInitialized()) {
      const mapView: NativeMapView = this.controller.getMapView();
      const latLng = new LatLng(event.x, event.y);
      console.info(`Map clicked at: ${latLng.latitude}, ${latLng.longitude}`);
    }
  }

  /**
   * 处理地图触摸事件
   */
  private handleMapTouch(event: TouchEvent): void {
    // 可以在这里处理触摸手势，如缩放、平移等
    console.info(`Map touch event: ${event.type}`);
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
