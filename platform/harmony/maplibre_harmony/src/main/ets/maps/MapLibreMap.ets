import maplibre, { NativeMapView } from 'libmaplibre.so';
import { MapLibreMapOptions } from './MapLibreMapOptions';
import { CameraPosition } from './camera/CameraPosition';
import { LatLng } from './geometry/LatLng';
import { LatLngBounds } from './geometry/LatLngBounds';
import { Point, PixelCoordinate, IPixelCoordinate } from './geometry/Point';
import { Rect } from './geometry/Rect';
import { ProjectedMeters, IProjectedMeters } from './geometry/ProjectedMeters';
// Layer 和 Source 类型导入，用于类型安全的图层和数据源操作
import type { Layer } from './style/layers/Layer';
import type { Source } from './style/sources/Source';
import { Image } from './style/images/Image';
import { GeoJson, IFeature } from './geojson';
import { TransitionOptions } from './style/layers/TransitionOptions';
import { Light } from './style/light/Light';
import { Polyline } from './annotations/Polyline';
import { Polygon } from './annotations/Polygon';
import { MarkerManager } from './annotations/MarkerManager';
import { MarkerOptions } from './annotations/MarkerOptions';
import { Annotation } from './annotations/Annotation';
import { OnMarkerClickListener } from './listeners/OnMarkerClickListener';
import { OnMarkerDragListener } from './listeners/OnMarkerDragListener';
import { OnInfoWindowClickListener } from './listeners/OnInfoWindowClickListener';
import { OnInfoWindowLongClickListener } from './listeners/OnInfoWindowLongClickListener';
import { OnInfoWindowCloseListener } from './listeners/OnInfoWindowCloseListener';
import { OnMarkerSelectListener } from './listeners/OnMarkerSelectListener';
import { InfoWindowManager } from './annotations/InfoWindowManager';
import { OnStyleLoadedListener } from './listeners/OnStyleLoadedListener';
import { OnStyleLoadErrorListener } from './listeners/OnStyleLoadErrorListener';
import { InfoWindowAdapter } from './annotations/InfoWindowAdapter';
import { AnnotationViewManager } from './annotations/AnnotationViewManager';
import { AnnotationViewDelegate, AnnotationViewConfig } from './annotations/AnnotationViewDelegate';
import { AnnotationViewData } from './annotations/AnnotationViewManager';
import { CameraChangeDispatcher } from './camera/CameraChangeDispatcher';
import { OnCameraIdleListener, OnCameraMoveStartedListener, 
         OnCameraMoveListener, OnCameraMoveCanceledListener } from './camera/CameraListener';
import { CameraMoveReason } from './camera/CameraMoveReason';
import { UiSettings } from './UiSettings';
import { OnMapClickListener, OnMapLongClickListener } from './gestures/GestureListeners';
import { LocationComponent } from './location/LocationComponent';
import { Projection } from './projection/Projection';
import { CameraAnimationCallback } from './camera/CameraAnimationCallback';
import { registerMapLibreMap } from './NativeMapView';
import { Marker } from './annotations/Marker';
import { Style } from './style/Style';

/**
 * 操作队列项类型
 */
type PendingOperation = () => void;

/**
 * MapLibreMap - 主要的地图API类
 */
export class MapLibreMap {
  private nativeMapView: NativeMapView;
  private options: MapLibreMapOptions;
  private destroyed: boolean = false;
  private markerManager: MarkerManager;
  private infoWindowManager: InfoWindowManager;
  private annotationViewManager: AnnotationViewManager;
  private annotationViewDelegate: AnnotationViewDelegate | null = null;
  private style: Style | null = null;
  private styleLoaded: boolean = false;
  private cameraChangeDispatcher: CameraChangeDispatcher = new CameraChangeDispatcher();
  
  // UI 设置
  private uiSettings: UiSettings = new UiSettings();
  
  // 位置组件
  private locationComponent: LocationComponent;
  
  // 投影工具
  private projection: Projection;
  
  // 视图尺寸（用于 InfoWindow 等功能）
  private viewWidth: number = 0;
  private viewHeight: number = 0;
  
  // Style 监听器
  private styleLoadedListeners: OnStyleLoadedListener[] = [];
  private styleLoadErrorListeners: OnStyleLoadErrorListener[] = [];
  
  // 操作队列 - 在样式加载前缓存操作
  private pendingOperations: PendingOperation[] = [];
  
  // Compass 更新回调（由外部 UI 层注入）
  public onCompassUpdate?: (bearing: number) => void;
  
  // ScaleBar 更新回调（由外部 UI 层注入）
  public onScaleBarUpdate?: (metersPerPixel: number) => void;
  
  // 动画回调管理
  private pendingAnimationCallback: CameraAnimationCallback | null = null;
  private animationTimerId: number | null = null;
  private animationCancelled: boolean = false;

  constructor(nativeMapView: NativeMapView, options: MapLibreMapOptions) {
    this.nativeMapView = nativeMapView;
    this.options = options;
    this.markerManager = new MarkerManager(this);
    this.infoWindowManager = new InfoWindowManager();
    this.annotationViewManager = new AnnotationViewManager();
    this.locationComponent = new LocationComponent(this);
    this.projection = new Projection(nativeMapView, 0, 0); // 初始尺寸为 0，稍后更新
    
    // 设置 AnnotationViewManager 的 NativeMapView
    this.annotationViewManager.setNativeMapView(nativeMapView);
    
    // 设置 Native 层的样式监听器
    this.setupNativeStyleListeners();
    
    // 设置相机移动监听器，自动更新 InfoWindow 位置
    this.setupInfoWindowCameraListener();
    
    // 设置相机移动监听器，自动更新 AnnotationView 位置
    this.setupAnnotationViewCameraListener();
    
    // 设置相机移动监听器，自动更新 Compass
    this.setupCompassCameraListener();
    
    // 设置相机移动监听器，自动更新 ScaleBar
    this.setupScaleBarCameraListener();
    
    // 注册到 NativeMapView 以启用 InfoWindow 功能
    registerMapLibreMap(nativeMapView, this);
  }
  
  /**
   * 设置 Native 层的样式监听器
   * @private
   */
  private setupNativeStyleListeners(): void {
    // 设置样式加载完成的回调
    this.nativeMapView.setOnStyleLoadedListener(() => {
      console.info('MapLibreMap: Native style loaded callback triggered');
      this.onStyleLoaded();
    });
    
    // 设置样式加载错误的回调
    this.nativeMapView.setOnStyleLoadErrorListener((error: string) => {
      console.error(`MapLibreMap: Native style load error callback triggered: ${error}`);
      this.onStyleLoadError(error);
    });
  }
  
  /**
   * 设置 InfoWindow 相机移动监听器
   * 当地图相机移动时，自动更新所有显示中的 InfoWindow 位置
   * @private
   */
  private setupInfoWindowCameraListener(): void {
    class InfoWindowMoveListenerImpl implements OnCameraMoveListener {
      parent: MapLibreMap;
      
      constructor(parent: MapLibreMap) {
        this.parent = parent;
      }
      
      onCameraMove(): void {
        // 地图相机移动时，更新所有 InfoWindow 的位置
        // 使用内部维护的尺寸（通过 resizeView 更新）
        this.parent.infoWindowManager.updatePositions(
          this.parent.viewWidth,
          this.parent.viewHeight,
          (marker: Marker) => {
            const pos = marker.getPosition();
            return this.parent.pixelForLatLng(pos.latitude, pos.longitude);
          }
        );
      }
    }
    const infoWindowMoveListener = new InfoWindowMoveListenerImpl(this);
    this.cameraChangeDispatcher.addOnCameraMoveListener(infoWindowMoveListener);
  }
  
  /**
   * 设置 Compass 相机移动监听器
   * 当地图旋转时，自动更新指南针方向
   * @private
   */
  private setupCompassCameraListener(): void {
    class CompassMoveListenerImpl implements OnCameraMoveListener {
      parent: MapLibreMap;
      
      constructor(parent: MapLibreMap) {
        this.parent = parent;
      }
      
      onCameraMove(): void {
        // 地图相机移动时，更新指南针
        if (this.parent.onCompassUpdate) {
          const bearing = this.parent.getBearing();
          this.parent.onCompassUpdate(bearing);
        }
      }
    }
    this.cameraChangeDispatcher.addOnCameraMoveListener(new CompassMoveListenerImpl(this));
  }
  
  /**
   * 设置 ScaleBar 相机移动监听器
   * 当地图缩放或移动时，自动更新比例尺
   * @private
   */
  private setupScaleBarCameraListener(): void {
    class ScaleBarMoveListenerImpl implements OnCameraMoveListener {
      parent: MapLibreMap;
      
      constructor(parent: MapLibreMap) {
        this.parent = parent;
      }
      
      onCameraMove(): void {
        // 地图相机移动时，更新比例尺
        if (this.parent.onScaleBarUpdate) {
          const metersPerPixel = this.parent.getMetersPerPixelAtLatitude(this.parent.getLatLng().latitude);
          this.parent.onScaleBarUpdate(metersPerPixel);
        }
        
        // 同时更新 AnnotationView 位置
        this.parent.updateAnnotationViewPositions(false);
      }
    }
    this.cameraChangeDispatcher.addOnCameraMoveListener(new ScaleBarMoveListenerImpl(this));
  }
  
  /**
   * 设置 AnnotationView 相机监听器
   * 当地图相机变化时，更新所有 AnnotationView 的位置和变换
   * @private
   */
  private setupAnnotationViewCameraListener(): void {
    // 相机移动监听：更新视图位置
    class AnnotationViewMoveListenerImpl implements OnCameraMoveListener {
      parent: MapLibreMap;
      
      constructor(parent: MapLibreMap) {
        this.parent = parent;
      }
      
      onCameraMove(): void {
        // 相机移动时更新位置（bearing/pitch 没变）
        this.parent.updateAnnotationViewPositions(false);
      }
    }
    
    // 相机空闲监听：确保最终状态正确
    class AnnotationViewIdleListenerImpl implements OnCameraIdleListener {
      parent: MapLibreMap;
      
      constructor(parent: MapLibreMap) {
        this.parent = parent;
      }
      
      onCameraIdle(): void {
        // 相机停止时更新，包括 bearing/pitch 的变化
        this.parent.updateAnnotationViewPositions(true);
      }
    }
    
    this.cameraChangeDispatcher.addOnCameraMoveListener(new AnnotationViewMoveListenerImpl(this));
    this.cameraChangeDispatcher.addOnCameraIdleListener(new AnnotationViewIdleListenerImpl(this));
  }
  
  /**
   * 计算指定纬度下每像素代表的米数（使用当前缩放级别）
   * @param latitude 纬度
   * @returns 每像素米数
   */
  public getMetersPerPixelAtLatitude(latitude: number): number;
  /**
   * 计算指定纬度和缩放级别下每像素代表的米数
   * @param latitude 纬度
   * @param zoom 缩放级别
   * @returns 每像素米数
   */
  public getMetersPerPixelAtLatitude(latitude: number, zoom: number): number;
  public getMetersPerPixelAtLatitude(latitude: number, zoom?: number): number {
    if (this.destroyed) return 0;
    const actualZoom = zoom !== undefined ? zoom : this.getZoom();
    return this.nativeMapView.getMetersPerPixelAtLatitude(latitude, actualZoom);
  }

  /**
   * 标记样式已加载（由外部调用，通常在样式加载完成回调中）
   */
  public onStyleLoaded(): void {
    this.styleLoaded = true;
    
    // 执行队列中的操作
    if (this.pendingOperations.length > 0) {
      console.info(`MapLibreMap: Executing ${this.pendingOperations.length} pending operations`);
      this.pendingOperations.forEach(operation => {
        try {
          operation();
        } catch (error) {
          console.error(`MapLibreMap: Error executing pending operation: ${error}`);
        }
      });
      this.pendingOperations = [];
    }
    
    // 触发监听器
    if (this.styleLoadedListeners.length > 0) {
      console.info(`MapLibreMap: Notifying ${this.styleLoadedListeners.length} style loaded listeners`);
      this.styleLoadedListeners.forEach(listener => {
        try {
          // 注意: Style 对象暂时传 null，因为 NativeMapView 没有 getStyle() 方法
          // 监听器可以直接使用 NativeMapView 的 layer/source 方法
          listener.onStyleLoaded(null);
        } catch (error) {
          console.error(`MapLibreMap: Error in onStyleLoaded listener: ${error}`);
        }
      });
    }
  }
  
  /**
   * 标记样式加载失败（由外部调用）
   */
  public onStyleLoadError(error: string): void {
    this.styleLoaded = false;
    this.style = null;
    
    // 清空队列中的操作
    if (this.pendingOperations.length > 0) {
      console.warn(`MapLibreMap: Clearing ${this.pendingOperations.length} pending operations due to style load error`);
      this.pendingOperations = [];
    }
    
    // 触发错误监听器
    if (this.styleLoadErrorListeners.length > 0) {
      console.info(`MapLibreMap: Notifying ${this.styleLoadErrorListeners.length} style load error listeners`);
      this.styleLoadErrorListeners.forEach(listener => {
        try {
          listener.onStyleLoadError(error);
        } catch (err) {
          console.error(`MapLibreMap: Error in onStyleLoadError listener: ${err}`);
        }
      });
    }
  }

  /**
   * 销毁地图（参考 Android MapLibreMap.onDestroy()）
   */
  public destroy(): void {
    if (this.destroyed) {
      return;
    }
    
    console.info('MapLibreMap: Starting destroy sequence (Android/iOS pattern)...');
    this.destroyed = true;
    
    try {
      // 1. 清理所有监听器数组（参考 Android）
      console.debug('MapLibreMap: Clearing all listeners...');
      this.styleLoadedListeners = [];
      this.styleLoadErrorListeners = [];
      this.pendingOperations = [];
      this.mapClickListeners = [];
      this.mapLongClickListeners = [];
      
      // 2. 取消所有动画
      if (this.animationTimerId !== null) {
        clearTimeout(this.animationTimerId);
        this.animationTimerId = null;
      }
      this.pendingAnimationCallback = null;
      this.animationCancelled = false;
      
      // 3. 清理 MarkerManager（参考 Android）
      console.debug('MapLibreMap: Clearing MarkerManager...');
      this.markerManager.clear();
      
      // 4. 清理 InfoWindowManager
      console.debug('MapLibreMap: Clearing InfoWindowManager...');
      this.infoWindowManager.closeAll();
      
      // 5. 清理 AnnotationViewManager
      console.debug('MapLibreMap: Clearing AnnotationViewManager...');
      this.annotationViewManager.clear();
      
      // 6. 销毁位置组件（参考 Android）
      console.debug('MapLibreMap: Destroying LocationComponent...');
      this.locationComponent.onDestroy();
      
      // 7. 清理相机调度器
      console.debug('MapLibreMap: Clearing CameraChangeDispatcher...');
      // CameraChangeDispatcher 会在下面的 NativeMapView destroy 中清理监听器
      
      // 8. 清理样式引用
      this.style = null;
      this.styleLoaded = false;
      
      // 9. 清理 NativeMapView 引用（实际销毁在 NativeMapView 层）
      // Native 资源会在 NativeMapView.aboutToDisappear() 中异步清理
      
      console.info('MapLibreMap: ✅ Destroy sequence completed');
      
    } catch (error) {
      console.error('MapLibreMap: Error during destroy:', error);
    }
  }

  /**
   * 检查是否已销毁
   */
  public isDestroyed(): boolean {
    return this.destroyed;
  }
  
  /**
   * 获取 UI 设置
   */
  public getUiSettings(): UiSettings {
    return this.uiSettings;
  }

  /**
   * 获取位置组件
   * 用于显示和跟踪用户位置
   */
  public getLocationComponent(): LocationComponent {
    return this.locationComponent;
  }
  
  /**
   * 获取坐标投影工具
   * 用于地图坐标和屏幕坐标之间的转换
   * 
   * @returns Projection 实例
   */
  public getProjection(): Projection {
    return this.projection;
  }

  /**
   * 调整视图大小
   */
  public resizeView(width: number, height: number): void {
    if (this.destroyed) return;
    // 保存尺寸
    this.viewWidth = width;
    this.viewHeight = height;
    
    // 更新 Projection 的视图尺寸
    this.projection.updateViewSize(width, height);
    
    this.nativeMapView.resizeView(width, height);
    
    // 视图大小改变后，触发 ScaleBar 更新（确保有初始值）
    if (this.onScaleBarUpdate) {
      try {
        const latLng = this.getLatLng();
        const metersPerPixel = this.getMetersPerPixelAtLatitude(latLng.latitude);
        this.onScaleBarUpdate(metersPerPixel);
        console.info(`[MapLibreMap] resizeView triggered ScaleBar update: ${metersPerPixel}`);
      } catch (error) {
        console.error(`[MapLibreMap] Failed to update ScaleBar on resize: ${error}`);
      }
    }
  }
  
  /**
   * 获取视图宽度
   */
  public getViewWidth(): number {
    return this.viewWidth;
  }
  
  /**
   * 获取视图高度
   */
  public getViewHeight(): number {
    return this.viewHeight;
  }

  // 样式管理
  public setStyleUrl(url: string): void {
    if (this.destroyed) return;
    this.nativeMapView.setStyleUrl(url);
    this.styleLoaded = false;
    this.style = null;  // 重置 style 缓存
  }

  public getStyleUrl(): string {
    if (this.destroyed) return '';
    return this.nativeMapView.getStyleUrl();
  }

  /**
   * 设置本地表意文字字体族
   * 
   * 用于本地渲染 CJK 字符，避免从网络加载大量字形数据。
   * 注意：此设置在初始化时生效，运行时更改需要重新加载样式。
   * 
   * @param fontFamily 字体族名称，如 "sans-serif"，null 表示禁用本地渲染
   */
  public setLocalIdeographFontFamily(fontFamily: string | null): void {
    if (this.destroyed) return;
    
    // 更新内部状态
    this.options.localIdeographFontFamily = fontFamily;
    
    // 注意：运行时更改需要重新创建 Renderer
    // 当前实现：建议在初始化时通过 MapLibreMapOptions 配置
    console.warn('setLocalIdeographFontFamily: 配置已更新，但需要重新加载样式才能生效');
  }

  /**
   * 获取当前配置的本地表意文字字体族
   * 
   * @returns 当前配置的字体族名称，null 表示已禁用
   */
  public getLocalIdeographFontFamily(): string | null {
    return this.options.localIdeographFontFamily;
  }

  public setStyleJson(json: string): void {
    if (this.destroyed) return;
    this.nativeMapView.setStyleJson(json);
    this.styleLoaded = false;
    this.style = null;  // 重置 style 缓存
  }

  public getStyleJson(): string {
    if (this.destroyed) return '';
    return this.nativeMapView.getStyleJson();
  }

  /**
   * 获取样式对象
   * 
   * @returns Style 封装类对象，如果地图未初始化或样式未加载则返回 null
   */
  public getStyle(): Style | null {
    if (this.destroyed) return null;
    if (!this.nativeMapView) return null;
    
    try {
      const nativeStyle: maplibre.Style = this.nativeMapView.getStyle();
      if (nativeStyle) {
        return Style.fromNative(nativeStyle);
      }
      return null;
    } catch (error) {
      console.error('Failed to get style:', error);
      return null;
    }
  }

  /**
   * 样式是否已加载
   */
  public isStyleLoaded(): boolean {
    return this.styleLoaded;
  }

  public setLatLngBounds(bounds: LatLngBounds): void {
    if (this.destroyed) return;
    this.nativeMapView.setLatLngBounds(bounds);
  }

  // 相机控制
  public cancelTransitions(): void {
    if (this.destroyed) return;
    this.nativeMapView.cancelTransitions();
  }
  
  /**
   * 设置地图内边距
   * 影响地图中心点的计算，使地图逻辑中心偏移
   * 
   * 参考 Android: MapLibreMap.setPadding()
   * 
   * @param left 左边距（像素）
   * @param top 上边距（像素）
   * @param right 右边距（像素）
   * @param bottom 下边距（像素）
   * 
   * @example
   * ```typescript
   * // 设置上边距 200px
   * map.setPadding(0, 200, 0, 0);
   * 
   * // 设置全边距各 100px
   * map.setPadding(100, 100, 100, 100);
   * ```
   */
  public setPadding(left: number, top: number, right: number, bottom: number): void {
    if (this.destroyed) return;
    this.projection.setContentPadding(left, top, right, bottom);
  }
  
  /**
   * 获取当前地图内边距
   * 
   * 参考 Android: MapLibreMap.getPadding()
   * 
   * @returns [left, top, right, bottom] 边距数组
   */
  public getPadding(): number[] {
    if (this.destroyed) return [0, 0, 0, 0];
    return this.projection.getContentPadding();
  }

  public setGestureInProgress(inProgress: boolean): void {
    if (this.destroyed) return;
    this.nativeMapView.setGestureInProgress(inProgress);
  }

  public moveBy(dx: number, dy: number, duration: number): void {
    if (this.destroyed) return;
    this.nativeMapView.moveBy(dx, dy, duration);
  }

  public jumpTo(angle: number, latitude: number, longitude: number, pitch: number, zoom: number, padding?: number[]): void {
    if (this.destroyed) return;
    this.nativeMapView.jumpTo(angle, latitude, longitude, pitch, zoom, padding);
  }

  /**
   * 平滑过渡到指定相机位置（easeTo）- 参数形式
   * 
   * @param latitude 纬度
   * @param longitude 经度
   * @param bearing 方位角
   * @param zoom 缩放级别
   * @param duration 动画持续时间（毫秒）
   */
  public easeTo(latitude: number, longitude: number, bearing: number, zoom: number, duration: number): void;
  
  /**
   * 平滑过渡到指定相机位置（easeTo）- 对象形式
   * 
   * @param options 相机选项
   * @param duration 动画持续时间（毫秒）
   * @param callback 可选的动画回调
   */
  public easeTo(options: maplibre.CameraOptions, duration: number, callback?: CameraAnimationCallback): void;
  
  /**
   * easeTo 实现
   */
  public easeTo(
    latitudeOrOptions: number | maplibre.CameraOptions,
    longitudeOrDuration: number,
    bearingOrCallback?: number | CameraAnimationCallback,
    zoom?: number,
    duration?: number
  ): void {
    if (this.destroyed) return;
    
    // 判断调用形式
    if (typeof latitudeOrOptions === 'number' && typeof zoom === 'number' && typeof duration === 'number') {
      // 参数形式: easeTo(latitude, longitude, bearing, zoom, duration)
      const centerObj: LatLng = new LatLng(latitudeOrOptions, longitudeOrDuration);
      const options: maplibre.CameraOptions = {
        center: centerObj.getNative(),
        bearing: bearingOrCallback as number,
        zoom: zoom
      };
      this.nativeMapView.easeTo(options, duration);
    } else if (typeof latitudeOrOptions === 'object') {
      // 对象形式: easeTo(options, duration, callback?)
      const options: maplibre.CameraOptions = latitudeOrOptions;
      const durationMs = longitudeOrDuration;
      const callback = bearingOrCallback as CameraAnimationCallback | undefined;
      
      // 如果有回调，设置动画监听
      if (callback) {
        this.setupAnimationCallback(callback, durationMs);
      }
      
      this.nativeMapView.easeTo(options, durationMs);
    }
  }

  /**
   * 飞行动画到指定相机位置（flyTo）
   * 
   * @param options 相机选项
   * @param duration 动画持续时间（毫秒）
   * @param callback 可选的动画回调
   */
  public flyTo(options: maplibre.CameraOptions, duration: number, callback?: CameraAnimationCallback): void {
    if (this.destroyed) return;
    
    // 如果有回调，设置动画监听
    if (callback) {
      this.setupAnimationCallback(callback, duration);
    }
    
    this.nativeMapView.flyTo(options, duration);
  }
  
  /**
   * 相机动画（Android 风格的 animateCamera）
   * 使用 CameraPosition 对象动画到新的相机位置
   * 
   * @param position CameraPosition 对象
   * @param durationMs 动画时长（毫秒），可选，默认 300ms
   * @param callback 动画回调，可选
   * 
   * 示例：
   * ```typescript
   * // 基本用法
   * map.animateCamera(new CameraPosition(
   *   new LatLng(lat, lng),
   *   15,
   *   0,
   *   0
   * ), 1000);
   * 
   * // 使用回调
   * map.animateCamera(cameraPosition, 1000, {
   *   onFinish: () => console.log('Animation finished'),
   *   onCancel: () => console.log('Animation cancelled')
   * });
   * ```
   */
  public animateCamera(position: CameraPosition, durationMs?: number, callback?: CameraAnimationCallback): void {
    if (this.destroyed) return;
    
    const duration = durationMs ?? 300; // 默认 300ms
    
    // 构建相机选项
    const options: maplibre.CameraOptions = {
      center: position.target ? position.target.getNative() : undefined,
      zoom: position.zoom,
      bearing: position.bearing,
      pitch: position.tilt
    };
    
    // 使用 easeTo 执行动画
    this.easeTo(options, duration, callback);
  }
  
  /**
   * 设置动画回调
   * 
   * @param callback 回调函数
   * @param duration 动画持续时间
   */
  private setupAnimationCallback(callback: CameraAnimationCallback, duration: number): void {
    // 清除之前的动画回调
    this.clearAnimationCallback();
    
    this.pendingAnimationCallback = callback;
    this.animationCancelled = false;
    
    // 监听相机移动取消事件
    class CancelListenerImpl implements OnCameraMoveCanceledListener {
      private parent: MapLibreMap;
      
      constructor(parent: MapLibreMap) {
        this.parent = parent;
      }
      
      onCameraMoveCanceled(): void {
        this.parent.onAnimationCancelled();
      }
    }
    const cancelListener = new CancelListenerImpl(this);
    
    this.cameraChangeDispatcher.addOnCameraMoveCanceledListener(cancelListener);
    
    // 设置定时器，在动画结束时触发完成回调
    // 增加一个小的缓冲时间（50ms）以确保动画完全完成
    this.animationTimerId = setTimeout(() => {
      if (!this.animationCancelled && this.pendingAnimationCallback) {
        try {
          this.pendingAnimationCallback.onFinish();
        } catch (error) {
          console.error('[MapLibreMap] Error in animation onFinish callback:', error);
        }
      }
      
      // 清理
      this.cameraChangeDispatcher.removeOnCameraMoveCanceledListener(cancelListener);
      this.clearAnimationCallback();
    }, duration + 50); // 加 50ms 缓冲
  }
  
  /**
   * 动画取消时调用
   */
  private onAnimationCancelled(): void {
    if (this.pendingAnimationCallback && !this.animationCancelled) {
      this.animationCancelled = true;
      
      try {
        if (this.pendingAnimationCallback.onCancel) {
          this.pendingAnimationCallback.onCancel();
        }
      } catch (error) {
        console.error('[MapLibreMap] Error in animation onCancel callback:', error);
      }
      
      this.clearAnimationCallback();
    }
  }
  
  /**
   * 清除动画回调
   */
  private clearAnimationCallback(): void {
    if (this.animationTimerId !== null) {
      clearTimeout(this.animationTimerId);
      this.animationTimerId = null;
    }
    this.pendingAnimationCallback = null;
    this.animationCancelled = false;
  }

  // 位置和相机
  public getLatLng(): LatLng {
    if (this.destroyed) return LatLng.create(0, 0);
    const nativeLatLng: maplibre.LatLng = this.nativeMapView.getLatLng();
    return LatLng.fromNative(nativeLatLng);
  }

  public setLatLng(latitude: number, longitude: number, padding?: number[], duration?: number): void {
    if (this.destroyed) return;
    this.nativeMapView.setLatLng(latitude, longitude, padding, duration);
  }

  public getCameraForLatLngBounds(bounds: LatLngBounds, top: number, left: number, bottom: number, right: number, bearing?: number, tilt?: number): CameraPosition | null {
    if (this.destroyed) return null;
    const result: ESObject = this.nativeMapView.getCameraForLatLngBounds(bounds, top, left, bottom, right, bearing, tilt) as ESObject;
    // TODO: 将 NAPI 返回的对象转换为 CameraPosition 实例
    return result as CameraPosition;
  }

  public getCameraForGeometry(geometry: ESObject, top: number, left: number, bottom: number, right: number, bearing?: number, tilt?: number): CameraPosition | null {
    if (this.destroyed) return null;
    const result: ESObject = this.nativeMapView.getCameraForGeometry(geometry, top, left, bottom, right, bearing, tilt) as ESObject;
    // TODO: 将 NAPI 返回的对象转换为 CameraPosition 实例
    return result as CameraPosition;
  }

  public setReachability(status: boolean): void {
    if (this.destroyed) return;
    this.nativeMapView.setReachability(status);
  }

  public resetPosition(): void {
    if (this.destroyed) return;
    this.nativeMapView.resetPosition();
  }

  // 倾斜控制
  public getPitch(): number {
    if (this.destroyed) return 0;
    return this.nativeMapView.getPitch();
  }

  public setPitch(pitch: number, duration?: number): void {
    if (this.destroyed) return;
    this.nativeMapView.setPitch(pitch, duration);
  }

  // 缩放控制
  public setZoom(zoom: number, cx?: number, cy?: number, duration?: number): void {
    if (this.destroyed) return;
    this.nativeMapView.setZoom(zoom, cx, cy, duration);
  }

  public getZoom(): number {
    if (this.destroyed) return 0;
    return this.nativeMapView.getZoom();
  }

  public resetZoom(): void {
    if (this.destroyed) return;
    this.nativeMapView.resetZoom();
  }

  public setMinZoom(zoom: number): void {
    if (this.destroyed) return;
    this.nativeMapView.setMinZoom(zoom);
  }

  public getMinZoom(): number {
    if (this.destroyed) return 0;
    return this.nativeMapView.getMinZoom();
  }

  public setMaxZoom(zoom: number): void {
    if (this.destroyed) return;
    this.nativeMapView.setMaxZoom(zoom);
  }

  public getMaxZoom(): number {
    if (this.destroyed) return 0;
    return this.nativeMapView.getMaxZoom();
  }

  // 倾斜限制
  public setMinPitch(pitch: number): void {
    if (this.destroyed) return;
    this.nativeMapView.setMinPitch(pitch);
  }

  public getMinPitch(): number {
    if (this.destroyed) return 0;
    return this.nativeMapView.getMinPitch();
  }

  public setMaxPitch(pitch: number): void {
    if (this.destroyed) return;
    this.nativeMapView.setMaxPitch(pitch);
  }

  public getMaxPitch(): number {
    if (this.destroyed) return 0;
    return this.nativeMapView.getMaxPitch();
  }

  // 旋转
  public rotateBy(sx: number, sy: number, ex: number, ey: number, duration?: number): void {
    if (this.destroyed) return;
    this.nativeMapView.rotateBy(sx, sy, ex, ey, duration);
  }

  // 方位控制
  public setBearing(degrees: number, duration?: number): void {
    if (this.destroyed) return;
    this.nativeMapView.setBearing(degrees, duration);
  }

  public setBearingXY(degrees: number, fx: number, fy: number, duration?: number): void {
    if (this.destroyed) return;
    this.nativeMapView.setBearingXY(degrees, fx, fy, duration);
  }

  public getBearing(): number {
    if (this.destroyed) return 0;
    return this.nativeMapView.getBearing();
  }

  public resetNorth(duration: number = 150): void {
    if (this.destroyed) return;
    // 使用动画方式归正北（参考 Android TIME_MAP_NORTH_ANIMATION = 150ms）
    this.nativeMapView.setBearing(0, duration);
  }

  // 坐标边界
  public setVisibleCoordinateBounds(coordinates: LatLng[], padding: Rect, direction: number, duration: number): void {
    if (this.destroyed) return;
    this.nativeMapView.setVisibleCoordinateBounds(coordinates, padding, direction, duration);
  }

  public getVisibleCoordinateBounds(): LatLng[] {
    if (this.destroyed) return [];
    return this.nativeMapView.getVisibleCoordinateBounds();
  }

  // 快照
  public scheduleSnapshot(): void {
    if (this.destroyed) return;
    this.nativeMapView.scheduleSnapshot();
  }

  // 相机位置
  public getCameraPosition(): Object | null {
    if (this.destroyed) return null;
    const result: Object = this.nativeMapView.getCameraPosition() as Object;
    // TODO: 将 NAPI 返回的对象转换为 CameraPosition 实例
    return result;
  }

  // 注解
  /**
   * 更新 Marker
   * 
   * 注意：使用 MarkerManager 的 GeoJSON 更新，支持所有属性（alpha, rotation, zIndex 等）
   * 不再使用 Native 的 updateMarker（它只支持位置和图标）
   * 
   * @param marker 要更新的 Marker
   */
  public updateMarker(marker: Marker): void {
    if (this.destroyed) return;
    
    try {
      // 使用 MarkerManager 的公共方法更新
      // 这样可以更新所有属性：position, icon, alpha, rotation, zIndex 等
      this.markerManager.updateMarker(marker);
      
      console.debug(`[MapLibreMap] updateMarker: Updated marker ${marker.getId()}`);
    } catch (error) {
      console.error('[MapLibreMap] updateMarker: Failed -', error);
    }
  }

  public addMarkers(markers: Marker[]): number[] {
    if (this.destroyed) {
      console.warn(`[MarkerDebug] MapLibreMap: ⚠️ Map is destroyed, cannot add markers`);
      return [];
    }
    
    // [MarkerDebug] 记录调用 NAPI 前的状态
    console.info(`[MarkerDebug] MapLibreMap: Calling NAPI addMarkers with ${markers.length} NAPI Marker objects`);
    for (let i = 0; i < markers.length; i++) {
      const pos = markers[i].getPosition();
      const icon = markers[i].getIcon();
      console.info(`[MarkerDebug] MapLibreMap: [${i}] position={${pos.latitude}, ${pos.longitude}}, icon=${icon || 'null'}`);
    }
    
    // 将封装的 Marker 转换为 NAPI Marker 对象数组
    const nativeMarkers: maplibre.Marker[] = markers.map((m: Marker): maplibre.Marker => m.getNative());
    const ids: number[] = this.nativeMapView.addMarkers(nativeMarkers);
    
    // [MarkerDebug] 记录 NAPI 返回结果
    console.info(`[MarkerDebug] MapLibreMap: NAPI returned ${ids.length} IDs: [${ids.join(', ')}]`);
    
    return ids;
  }

  public addPolylines(polylines: Polyline[]): number[] {
    if (this.destroyed) return [];
    return this.nativeMapView.addPolylines(polylines);
  }

  public addPolygons(polygons: Polygon[]): number[] {
    if (this.destroyed) return [];
    return this.nativeMapView.addPolygons(polygons);
  }

  public updatePolyline(polylineId: number, polyline: Polyline): void {
    if (this.destroyed) return;
    this.nativeMapView.updatePolyline(polylineId, polyline);
  }

  public updatePolygon(polygonId: number, polygon: Polygon): void {
    if (this.destroyed) return;
    this.nativeMapView.updatePolygon(polygonId, polygon);
  }

  public removeAnnotations(ids: number[]): void {
    if (this.destroyed) return;
    this.nativeMapView.removeAnnotations(ids);
  }

  public addAnnotationIcon(symbol: string, width: number, height: number, scale: number, pixels: Uint8Array): void {
    if (this.destroyed) return;
    this.nativeMapView.addAnnotationIcon(symbol, width, height, scale, pixels);
  }

  public removeAnnotationIcon(symbol: string): void {
    if (this.destroyed) return;
    this.nativeMapView.removeAnnotationIcon(symbol);
  }

  public getTopOffsetPixelsForAnnotationSymbol(symbolName: string): number {
    if (this.destroyed) return 0;
    return this.nativeMapView.getTopOffsetPixelsForAnnotationSymbol(symbolName);
  }

  // 内存管理
  public onLowMemory(): void {
    if (this.destroyed) return;
    this.nativeMapView.onLowMemory();
  }

  // 调试
  public setDebug(debug: boolean): void {
    if (this.destroyed) return;
    this.nativeMapView.setDebug(debug);
  }

  public getDebug(): boolean {
    if (this.destroyed) return false;
    return this.nativeMapView.getDebug();
  }

  // 动作日志
  public getActionJournalLogFiles(): string[] {
    if (this.destroyed) return [];
    return this.nativeMapView.getActionJournalLogFiles();
  }

  public getActionJournalLog(): string[] {
    if (this.destroyed) return [];
    return this.nativeMapView.getActionJournalLog();
  }

  public clearActionJournalLog(): void {
    if (this.destroyed) return;
    this.nativeMapView.clearActionJournalLog();
  }

  // 加载状态
  public isFullyLoaded(): boolean {
    if (this.destroyed) return false;
    return this.nativeMapView.isFullyLoaded();
  }

  // 坐标转换
  public projectedMetersForLatLng(latitude: number, longitude: number): ProjectedMeters {
    if (this.destroyed) return new ProjectedMeters(0, 0);
    const result: IProjectedMeters = this.nativeMapView.projectedMetersForLatLng(latitude, longitude);
    return ProjectedMeters.fromObject(result);
  }

  public pixelForLatLng(latitude: number, longitude: number): Point {
    if (this.destroyed) return new PixelCoordinate(0, 0);
    const result: IPixelCoordinate = this.nativeMapView.pixelForLatLng(latitude, longitude);
    return PixelCoordinate.fromObject(result);
  }

  public pixelsForLatLngs(input: number[], output: number[]): void {
    if (this.destroyed) return;
    this.nativeMapView.pixelsForLatLngs(input, output);
  }

  public latLngForProjectedMeters(northing: number, easting: number): LatLng {
    if (this.destroyed) return LatLng.create(0, 0);
    const nativeLatLng: maplibre.LatLng = this.nativeMapView.latLngForProjectedMeters(northing, easting);
    return LatLng.fromNative(nativeLatLng);
  }

  public latLngForPixel(x: number, y: number): LatLng {
    if (this.destroyed) return LatLng.create(0, 0);
    const nativeLatLng: maplibre.LatLng = this.nativeMapView.latLngForPixel(x, y);
    return LatLng.fromNative(nativeLatLng);
  }

  public latLngsForPixels(input: number[], output: number[]): void {
    if (this.destroyed) return;
    this.nativeMapView.latLngsForPixels(input, output);
  }

  // 过渡
  public getTransitionOptions(): TransitionOptions {
    if (this.destroyed) return new TransitionOptions(0, 0);
    const result: TransitionOptions = this.nativeMapView.getTransitionOptions();
    return result;
  }

  public setTransitionOptions(options: TransitionOptions): void {
    if (this.destroyed) return;
    // 转换为对象字面量传递给 NAPI
    this.nativeMapView.setTransitionOptions(options.toObject());
  }

  // 查询
  public queryPointAnnotations(rect: Rect): number[] {
    if (this.destroyed) return [];
    return this.nativeMapView.queryPointAnnotations(rect.toObject());
  }

  public queryShapeAnnotations(rect: Rect): number[] {
    if (this.destroyed) return [];
    return this.nativeMapView.queryShapeAnnotations(rect.toObject());
  }

  // 光照
  public getLight(): Light | null {
    if (this.destroyed) return null;
    const result: ESObject = this.nativeMapView.getLight() as ESObject;
    return result as Light;
  }

  // 图层方法 - 使用强类型 Layer
  public getLayers(): Layer[] {
    if (this.destroyed) return [];
    return this.nativeMapView.getLayers() as Layer[];
  }

  public getLayer(layerId: string): Layer | null {
    if (this.destroyed) return null;
    const result: Object | null = this.nativeMapView.getLayer(layerId);
    return result ? (result as Layer) : null;
  }

  public addLayer(layer: Layer): void {
    if (this.destroyed) return;
    this.nativeMapView.addLayer(layer);
  }

  public addLayerAbove(layer: Layer, aboveLayerId: string): void {
    if (this.destroyed) return;
    this.nativeMapView.addLayerAbove(layer, aboveLayerId);
  }

  public addLayerAt(layer: Layer, index: number): void {
    if (this.destroyed) return;
    this.nativeMapView.addLayerAt(layer, index);
  }

  public removeLayerAt(index: number): boolean {
    if (this.destroyed) return false;
    return this.nativeMapView.removeLayerAt(index);
  }

  public removeLayer(layer: Layer | string): boolean {
    if (this.destroyed) return false;
    return this.nativeMapView.removeLayer(layer);
  }

  // 数据源方法 - 使用强类型 Source
  public getSources(): Source[] {
    if (this.destroyed) return [];
    return this.nativeMapView.getSources() as Source[];
  }

  public getSource(sourceId: string): Source | null {
    if (this.destroyed) return null;
    const result: Object | null = this.nativeMapView.getSource(sourceId);
    return result ? (result as Source) : null;
  }

  public addSource(source: Source): void {
    if (this.destroyed) return;
    this.nativeMapView.addSource(source);
  }

  public removeSource(source: Source | string): boolean {
    if (this.destroyed) return false;
    return this.nativeMapView.removeSource(source);
  }

  // 图片
  public addImage(name: string, bitmap: Object, pixelRatio: number, sdf: boolean): void {
    if (this.destroyed) return;
    this.nativeMapView.addImage(name, bitmap, pixelRatio, sdf);
  }

  public addImages(images: Image[]): void {
    if (this.destroyed) return;
    this.nativeMapView.addImages(images);
  }

  public removeImage(name: string): void {
    if (this.destroyed) return;
    this.nativeMapView.removeImage(name);
  }

  public getImage(name: string): Object | null {
    if (this.destroyed) return null;
    const result: Object = this.nativeMapView.getImage(name) as Object;
    return result;
  }

  // 瓦片管理
  public setPrefetchTiles(enable: boolean): void {
    if (this.destroyed) return;
    this.nativeMapView.setPrefetchTiles(enable);
  }

  public getPrefetchTiles(): boolean {
    if (this.destroyed) return false;
    return this.nativeMapView.getPrefetchTiles();
  }

  public setPrefetchZoomDelta(delta: number): void {
    if (this.destroyed) return;
    this.nativeMapView.setPrefetchZoomDelta(delta);
  }

  public getPrefetchZoomDelta(): number {
    if (this.destroyed) return 0;
    return this.nativeMapView.getPrefetchZoomDelta();
  }

  public setTileCacheEnabled(enabled: boolean): void {
    if (this.destroyed) return;
    this.nativeMapView.setTileCacheEnabled(enabled);
  }

  public getTileCacheEnabled(): boolean {
    if (this.destroyed) return false;
    return this.nativeMapView.getTileCacheEnabled();
  }

  // 瓦片LOD
  public setTileLodMinRadius(radius: number): void {
    if (this.destroyed) return;
    this.nativeMapView.setTileLodMinRadius(radius);
  }

  public getTileLodMinRadius(): number {
    if (this.destroyed) return 0;
    return this.nativeMapView.getTileLodMinRadius();
  }

  public setTileLodScale(scale: number): void {
    if (this.destroyed) return;
    this.nativeMapView.setTileLodScale(scale);
  }

  public getTileLodScale(): number {
    if (this.destroyed) return 0;
    return this.nativeMapView.getTileLodScale();
  }

  public setTileLodPitchThreshold(threshold: number): void {
    if (this.destroyed) return;
    this.nativeMapView.setTileLodPitchThreshold(threshold);
  }

  public getTileLodPitchThreshold(): number {
    if (this.destroyed) return 0;
    return this.nativeMapView.getTileLodPitchThreshold();
  }

  public setTileLodZoomShift(shift: number): void {
    if (this.destroyed) return;
    this.nativeMapView.setTileLodZoomShift(shift);
  }

  public getTileLodZoomShift(): number {
    if (this.destroyed) return 0;
    return this.nativeMapView.getTileLodZoomShift();
  }

  // 渲染
  public triggerRepaint(): void {
    if (this.destroyed) return;
    this.nativeMapView.triggerRepaint();
  }

  public isRenderingStatsViewEnabled(): boolean {
    if (this.destroyed) return false;
    return this.nativeMapView.isRenderingStatsViewEnabled();
  }

  public enableRenderingStatsView(enabled: boolean): void {
    if (this.destroyed) return;
    this.nativeMapView.enableRenderingStatsView(enabled);
  }

  // 获取原生地图视图
  public getNativeMapView(): NativeMapView {
    return this.nativeMapView;
  }
  
  // ========== Marker 管理方法（新增）==========
  
  /**
   * 添加单个 Marker
   * 
   * @param options MarkerOptions 实例
   * @returns Promise<Marker> 创建的 Marker
   */
  public async addMarker(options: MarkerOptions): Promise<Marker> {
    if (this.destroyed) {
      throw new Error('Map has been destroyed');
    }
    return await this.markerManager.addMarker(options);
  }
  
  /**
   * 批量添加 Marker
   * 
   * @param optionsList MarkerOptions 数组
   * @returns Promise<Marker[]> 创建的 Marker 数组
   */
  public async addMarkersBatch(optionsList: MarkerOptions[]): Promise<Marker[]> {
    if (this.destroyed) return [];
    return await this.markerManager.addMarkers(optionsList);
  }
  
  /**
   * 移除单个 Marker
   * 
   * @param marker 要移除的 Marker
   */
  public removeMarker(marker: Marker): void {
    if (this.destroyed) return;
    this.markerManager.removeMarker(marker);
  }
  
  /**
   * 移除 Annotation（通用方法）
   * 
   * @param annotation 要移除的 Annotation
   */
  public removeAnnotation(annotation: Annotation | Marker): void {
    if (this.destroyed) return;
    
    // 尝试类型检查：Marker 有 getPosition 方法
    try {
      const marker = annotation as Marker;
      marker.getPosition();  // 调用方法尝试验证
      this.markerManager.removeMarker(marker);
      return;
    } catch (e) {
      // 不是 Marker，继续处理其他类型
    }
    
    // 对于其他类型的 Annotation（Polyline, Polygon），调用原有方法
    const id = (annotation as Annotation).getId();
    if (id !== -1) {
      this.removeAnnotations([id]);
    }
  }
  
  /**
   * 批量移除 Annotation
   * 
   * @param annotations Annotation 数组
   */
  public removeAnnotationsBatch(annotations: (Annotation | Marker)[]): void {
    if (this.destroyed) return;
    
    const markers: Marker[] = [];
    const otherIds: number[] = [];
    
    for (const annotation of annotations) {
      // 尝试类型检查：Marker 有 getPosition 方法
      try {
        const marker = annotation as Marker;
        marker.getPosition();  // 调用方法尝试验证
        markers.push(marker);
        continue;
      } catch (e) {
        // 不是 Marker，继续处理其他类型
      }
      
      const id = (annotation as Annotation).getId();
      if (id !== -1) {
        otherIds.push(id);
      }
    }
    
    // 移除 Markers
    if (markers.length > 0) {
      this.markerManager.removeMarkers(markers);
    }
    
    // 移除其他类型的 Annotations
    if (otherIds.length > 0) {
      this.removeAnnotations(otherIds);
    }
  }
  
  /**
   * 清除所有 Marker
   */
  public clearMarkers(): void {
    if (this.destroyed) return;
    this.markerManager.clear();
  }
  
  /**
   * 清空所有标注（Android 风格的 clear() 方法）
   * 清除所有标记、折线、多边形等
   */
  public clear(): void {
    if (this.destroyed) return;
    
    console.info(`MapLibreMap: Clearing all annotations (Android clear pattern)`);
    // 清除所有 Marker
    this.markerManager.clear();
    
    // 关闭所有 InfoWindow
    this.infoWindowManager.closeAll();
    
    // 清除所有 AnnotationView
    this.annotationViewManager.clear();
    
    // TODO: 清除 Polyline 和 Polygon（当实现后）
    console.warn('MapLibreMap: Polyline and Polygon clearing not fully implemented');
  }
  
  /**
   * 获取所有 Marker
   * 
   * @returns Marker 数组
   */
  public getMarkers(): Marker[] {
    if (this.destroyed) return [];
    return this.markerManager.getMarkers();
  }
  
  /**
   * 根据 ID 获取 Marker
   * 
   * @param id Marker ID
   * @returns Marker 实例，如果不存在则返回 null
   */
  public getMarkerById(id: number): Marker | null {
    if (this.destroyed) return null;
    return this.markerManager.getMarker(id);
  }
  
  // ========== Marker 选中管理 ==========
  
  /**
   * 选中 Marker
   * 
   * @param marker 要选中的 Marker
   * @param animated 是否显示动画（暂未实现）
   */
  public selectMarker(marker: Marker, animated: boolean = true): void {
    if (this.destroyed) return;
    this.markerManager.selectMarker(marker, true);
  }
  
  /**
   * 取消选中 Marker
   * 
   * @param marker 要取消选中的 Marker
   */
  public deselectMarker(marker: Marker): void {
    if (this.destroyed) return;
    this.markerManager.deselectMarker(marker);
  }
  
  /**
   * 取消所有选中的 Marker
   */
  public deselectMarkers(): void {
    if (this.destroyed) return;
    this.markerManager.deselectMarkers();
  }
  
  /**
   * 获取所有选中的 Marker
   * 
   * @returns 选中的 Marker 数组
   */
  public getSelectedMarkers(): Marker[] {
    if (this.destroyed) return [];
    return this.markerManager.getSelectedMarkers();
  }
  
  // ========== 事件监听器 ==========
  
  /**
   * 设置 Marker 点击监听器
   * 
   * @param listener 监听器实例
   */
  public setOnMarkerClickListener(listener: OnMarkerClickListener | null): void {
    if (this.destroyed) return;
    this.markerManager.setOnMarkerClickListener(listener);
  }
  
  /**
   * 设置 Marker 拖拽监听器
   * 
   * @param listener 监听器实例
   */
  public setOnMarkerDragListener(listener: OnMarkerDragListener | null): void {
    if (this.destroyed) return;
    this.markerManager.setOnMarkerDragListener(listener);
  }
  
  /**
   * 设置 Marker 选中监听器
   * 
   * @param listener 监听器实例
   */
  public setOnMarkerSelectListener(listener: OnMarkerSelectListener | null): void {
    if (this.destroyed) return;
    this.markerManager.setOnMarkerSelectListener(listener);
  }
  
  /**
   * 获取 Marker 选中监听器
   * 
   * @returns 监听器实例
   */
  public getOnMarkerSelectListener(): OnMarkerSelectListener | null {
    if (this.destroyed) return null;
    return this.markerManager.getOnMarkerSelectListener();
  }
  
  /**
   * 设置 InfoWindow 点击监听器
   * 
   * @param listener 监听器实例
   */
  public setOnInfoWindowClickListener(listener: OnInfoWindowClickListener | null): void {
    if (this.destroyed) return;
    this.markerManager.setOnInfoWindowClickListener(listener);
  }
  
  /**
   * 设置 InfoWindow 关闭监听器
   * 
   * @param listener 监听器实例
   */
  public setOnInfoWindowCloseListener(listener: OnInfoWindowCloseListener | null): void {
    if (this.destroyed) return;
    this.markerManager.setOnInfoWindowCloseListener(listener);
  }
  
  /**
   * 获取 InfoWindow 关闭监听器
   * 
   * @returns 监听器实例
   */
  public getOnInfoWindowCloseListener(): OnInfoWindowCloseListener | null {
    if (this.destroyed) return null;
    return this.markerManager.getOnInfoWindowCloseListener();
  }
  
  /**
   * 设置 InfoWindow 适配器
   * 
   * 允许自定义 InfoWindow 的显示内容
   * 
   * @param adapter 适配器实例
   */
  public setInfoWindowAdapter(adapter: InfoWindowAdapter | null): void {
    if (this.destroyed) return;
    this.markerManager.setInfoWindowAdapter(adapter);
  }
  
  // ==================== Style 监听器管理 ====================
  
  /**
   * 添加样式加载完成监听器
   * 
   * @param listener 监听器实例
   */
  public addOnStyleLoadedListener(listener: OnStyleLoadedListener): void {
    if (this.destroyed) return;
    if (!this.styleLoadedListeners.includes(listener)) {
      this.styleLoadedListeners.push(listener);
      console.info('MapLibreMap: Style loaded listener added');
      
      // 如果样式已经加载，立即触发回调
      if (this.styleLoaded) {
        try {
          // 注意: Style 对象暂时传 null
          listener.onStyleLoaded(null);
        } catch (error) {
          console.error(`MapLibreMap: Error in onStyleLoaded listener: ${error}`);
        }
      }
    }
  }
  
  /**
   * 移除样式加载完成监听器
   * 
   * @param listener 要移除的监听器实例
   */
  public removeOnStyleLoadedListener(listener: OnStyleLoadedListener): void {
    const index = this.styleLoadedListeners.indexOf(listener);
    if (index !== -1) {
      this.styleLoadedListeners.splice(index, 1);
      console.info('MapLibreMap: Style loaded listener removed');
    }
  }
  
  /**
   * 添加样式加载错误监听器
   * 
   * @param listener 监听器实例
   */
  public addOnStyleLoadErrorListener(listener: OnStyleLoadErrorListener): void {
    if (this.destroyed) return;
    if (!this.styleLoadErrorListeners.includes(listener)) {
      this.styleLoadErrorListeners.push(listener);
      console.info('MapLibreMap: Style load error listener added');
    }
  }
  
  /**
   * 移除样式加载错误监听器
   * 
   * @param listener 要移除的监听器实例
   */
  public removeOnStyleLoadErrorListener(listener: OnStyleLoadErrorListener): void {
    const index = this.styleLoadErrorListeners.indexOf(listener);
    if (index !== -1) {
      this.styleLoadErrorListeners.splice(index, 1);
      console.info('MapLibreMap: Style load error listener removed');
    }
  }
  
  /**
   * 添加待处理操作到队列
   * 
   * 如果样式已加载，立即执行；否则加入队列等待样式加载后执行
   * 
   * @param operation 待执行的操作
   */
  public waitForStyle(operation: PendingOperation): void {
    if (this.destroyed) return;
    
    if (this.styleLoaded) {
      // 样式已加载，立即执行
      try {
        operation();
      } catch (error) {
        console.error(`MapLibreMap: Error executing operation: ${error}`);
      }
    } else {
      // 样式未加载，加入队列
      this.pendingOperations.push(operation);
      console.info(`MapLibreMap: Operation added to pending queue (${this.pendingOperations.length} total)`);
    }
  }
  
  /**
   * 获取 InfoWindow 适配器
   * 
   * @returns 适配器实例
   */
  public getInfoWindowAdapter(): InfoWindowAdapter | null {
    if (this.destroyed) return null;
    return this.markerManager.getInfoWindowAdapter();
  }
  
  /**
   * 获取 MarkerManager 实例（内部使用）
   * 
   * @returns MarkerManager 实例
   */
  public getMarkerManager(): MarkerManager {
    return this.markerManager;
  }
  
  /**
   * 显示指定 Marker 的 InfoWindow
   * 
   * @param marker 要显示 InfoWindow 的 Marker
   */
  public showInfoWindow(marker: Marker): void {
    if (this.destroyed) return;
    this.markerManager.showInfoWindow(marker);
  }
  
  /**
   * 隐藏指定 Marker 的 InfoWindow
   * 
   * @param marker 要隐藏 InfoWindow 的 Marker
   */
  public hideInfoWindow(marker: Marker): void {
    if (this.destroyed) return;
    this.markerManager.hideInfoWindow(marker);
  }
  
  /**
   * 隐藏所有 InfoWindow
   */
  public hideAllInfoWindows(): void {
    if (this.destroyed) return;
    this.markerManager.hideAllInfoWindows();
  }
  
  // ========== 相机监听器方法 ==========
  
  /**
   * 添加相机空闲监听器
   * 当相机停止移动（所有动画和手势结束）时触发
   * 
   * @param listener OnCameraIdleListener 实例
   */
  public addOnCameraIdleListener(listener: OnCameraIdleListener): void {
    if (this.destroyed) return;
    
    // 添加到调度器
    this.cameraChangeDispatcher.addOnCameraIdleListener(listener);
    
    // 注册到 NAPI
    const callback = () => {
      this.cameraChangeDispatcher.notifyCameraIdle();
    };
    this.nativeMapView.addOnCameraIdleListener(callback);
  }
  
  /**
   * 移除相机空闲监听器
   * 
   * @param listener 要移除的监听器
   */
  public removeOnCameraIdleListener(listener: OnCameraIdleListener): void {
    if (this.destroyed) return;
    this.cameraChangeDispatcher.removeOnCameraIdleListener(listener);
    // Note: NAPI 层的回调无法精确移除，这是一个已知限制
  }
  
  /**
   * 添加相机开始移动监听器
   * 当相机开始移动时触发
   * 
   * @param listener OnCameraMoveStartedListener 实例
   */
  public addOnCameraMoveStartedListener(listener: OnCameraMoveStartedListener): void {
    if (this.destroyed) return;
    
    // 添加到调度器
    this.cameraChangeDispatcher.addOnCameraMoveStartedListener(listener);
    
    // 注册到 NAPI
    const callback = (reason: number) => {
      this.cameraChangeDispatcher.notifyCameraMoveStarted(reason as CameraMoveReason);
    };
    this.nativeMapView.addOnCameraMoveStartedListener(callback);
  }
  
  /**
   * 移除相机开始移动监听器
   * 
   * @param listener 要移除的监听器
   */
  public removeOnCameraMoveStartedListener(listener: OnCameraMoveStartedListener): void {
    if (this.destroyed) return;
    this.cameraChangeDispatcher.removeOnCameraMoveStartedListener(listener);
  }
  
  /**
   * 添加相机移动中监听器
   * 在相机移动过程中频繁触发
   * 
   * @param listener OnCameraMoveListener 实例
   */
  public addOnCameraMoveListener(listener: OnCameraMoveListener): void {
    if (this.destroyed) return;
    
    // 添加到调度器
    this.cameraChangeDispatcher.addOnCameraMoveListener(listener);
    
    // 注册到 NAPI
    const callback = () => {
      this.cameraChangeDispatcher.notifyCameraMove();
    };
    this.nativeMapView.addOnCameraMoveListener(callback);
  }
  
  /**
   * 移除相机移动中监听器
   * 
   * @param listener 要移除的监听器
   */
  public removeOnCameraMoveListener(listener: OnCameraMoveListener): void {
    if (this.destroyed) return;
    this.cameraChangeDispatcher.removeOnCameraMoveListener(listener);
  }
  
  /**
   * 添加相机移动取消监听器
   * 当相机动画被中断或取消时触发
   * 
   * @param listener OnCameraMoveCanceledListener 实例
   */
  public addOnCameraMoveCanceledListener(listener: OnCameraMoveCanceledListener): void {
    if (this.destroyed) return;
    
    // 添加到调度器
    this.cameraChangeDispatcher.addOnCameraMoveCanceledListener(listener);
    
    // 注册到 NAPI
    const callback = () => {
      this.cameraChangeDispatcher.notifyCameraMoveCanceled();
    };
    this.nativeMapView.addOnCameraMoveCanceledListener(callback);
  }
  
  /**
   * 移除相机移动取消监听器
   * 
   * @param listener 要移除的监听器
   */
  public removeOnCameraMoveCanceledListener(listener: OnCameraMoveCanceledListener): void {
    if (this.destroyed) return;
    this.cameraChangeDispatcher.removeOnCameraMoveCanceledListener(listener);
  }
  
  /**
   * 内部方法：通知相机开始移动（手势触发）
   * 供手势处理器调用
   * @internal
   */
  public _notifyCameraMoveStartedByGesture(): void {
    if (this.destroyed) return;
    this.cameraChangeDispatcher.notifyCameraMoveStarted(CameraMoveReason.GESTURE);
  }
  
  /**
   * 内部方法：通知相机正在移动
   * 供手势处理器调用
   * @internal
   */
  public _notifyCameraMove(): void {
    if (this.destroyed) return;
    this.cameraChangeDispatcher.notifyCameraMove();
  }
  
  /**
   * 内部方法：通知相机停止移动
   * 供手势处理器调用
   * @internal
   */
  public _notifyCameraIdle(): void {
    if (this.destroyed) return;
    this.cameraChangeDispatcher.notifyCameraIdle();
  }
  
  // ========== 地图点击监听器管理 ==========
  
  private mapClickListeners: OnMapClickListener[] = [];
  private mapLongClickListeners: OnMapLongClickListener[] = [];
  
  /**
   * 添加地图点击监听器
   * 当用户点击地图时触发（参考 Android addOnMapClickListener）
   * 
   * @param listener OnMapClickListener 实例
   */
  public addOnMapClickListener(listener: OnMapClickListener): void {
    if (this.destroyed) return;
    if (!this.mapClickListeners.includes(listener)) {
      this.mapClickListeners.push(listener);
      console.info('MapLibreMap: Map click listener added');
    }
  }
  
  /**
   * 移除地图点击监听器
   * 
   * @param listener 要移除的监听器
   */
  public removeOnMapClickListener(listener: OnMapClickListener): void {
    if (this.destroyed) return;
    const index = this.mapClickListeners.indexOf(listener);
    if (index > -1) {
      this.mapClickListeners.splice(index, 1);
      console.info('MapLibreMap: Map click listener removed');
    }
  }
  
  /**
   * 添加地图长按监听器
   * 当用户长按地图时触发（参考 Android addOnMapLongClickListener）
   * 
   * @param listener OnMapLongClickListener 实例
   */
  public addOnMapLongClickListener(listener: OnMapLongClickListener): void {
    if (this.destroyed) return;
    if (!this.mapLongClickListeners.includes(listener)) {
      this.mapLongClickListeners.push(listener);
      console.info('MapLibreMap: Map long click listener added');
    }
  }
  
  /**
   * 移除地图长按监听器
   * 
   * @param listener 要移除的监听器
   */
  public removeOnMapLongClickListener(listener: OnMapLongClickListener): void {
    if (this.destroyed) return;
    const index = this.mapLongClickListeners.indexOf(listener);
    if (index > -1) {
      this.mapLongClickListeners.splice(index, 1);
      console.info('MapLibreMap: Map long click listener removed');
    }
  }
  
  /**
   * 内部方法：触发地图点击事件
   * @param x 点击位置 X 坐标
   * @param y 点击位置 Y 坐标
   * @returns 是否有监听器消费了该事件
   * @internal
   */
  public _notifyMapClick(x: number, y: number): boolean {
    if (this.destroyed) return false;
    for (const listener of this.mapClickListeners) {
      try {
        if (listener.onMapClick(x, y)) {
          return true; // 事件被消费
        }
      } catch (error) {
        console.error(`MapLibreMap: Error in map click listener: ${error}`);
      }
    }
    return false;
  }
  
  /**
   * 内部方法：触发地图长按事件
   * @param x 长按位置 X 坐标
   * @param y 长按位置 Y 坐标
   * @returns 是否有监听器消费了该事件
   * @internal
   */
  public _notifyMapLongClick(x: number, y: number): boolean {
    if (this.destroyed) return false;
    for (const listener of this.mapLongClickListeners) {
      try {
        if (listener.onMapLongClick(x, y)) {
          return true; // 事件被消费
        }
      } catch (error) {
        console.error(`MapLibreMap: Error in map long click listener: ${error}`);
      }
    }
    return false;
  }
  
  // ========== AnnotationView 管理方法 ==========
  
  /**
   * 获取 AnnotationViewManager 实例
   * @returns AnnotationViewManager 实例
   */
  public getAnnotationViewManager(): AnnotationViewManager {
    return this.annotationViewManager;
  }
  
  /**
   * 设置 AnnotationViewDelegate
   * 用于自定义 AnnotationView 的创建和事件处理
   * 
   * @param delegate AnnotationViewDelegate 实例，传 null 则清除委托
   */
  public setAnnotationViewDelegate(delegate: AnnotationViewDelegate | null): void {
    if (this.destroyed) return;
    this.annotationViewDelegate = delegate;
    
    // 设置到管理器的 adapter（如果需要）
    // 注：AnnotationViewDelegate 和 AnnotationViewAdapter 可以统一
  }
  
  /**
   * 获取 AnnotationViewDelegate
   * @returns AnnotationViewDelegate 实例或 null
   */
  public getAnnotationViewDelegate(): AnnotationViewDelegate | null {
    if (this.destroyed) return null;
    return this.annotationViewDelegate;
  }
  
  /**
   * 为 Marker 注册 AnnotationView
   * 
   * @param marker Marker 实例
   * @param config AnnotationViewConfig 配置
   */
  public registerAnnotationView(marker: Marker, config: AnnotationViewConfig): void {
    if (this.destroyed) return;
    
    // 使用 AnnotationViewManager 创建视图
    this.annotationViewManager.createOrUpdateView(marker);
    
    console.info(`[MapLibreMap] Registered AnnotationView for marker: ${marker.getId()}`);
  }
  
  /**
   * 取消注册 AnnotationView
   * 
   * @param marker Marker 实例
   */
  public unregisterAnnotationView(marker: Marker): void {
    if (this.destroyed) return;
    
    this.annotationViewManager.removeView(marker);
    
    console.info(`[MapLibreMap] Unregistered AnnotationView for marker: ${marker.getId()}`);
  }
  
  /**
   * 选中 Annotation
   * 
   * @param marker Marker 实例
   * @param animated 是否播放动画
   */
  public selectAnnotation(marker: Marker, animated: boolean = true): void {
    if (this.destroyed) return;
    
    this.annotationViewManager.selectAnnotation(marker, animated);
    
    // 触发委托回调
    if (this.annotationViewDelegate?.didSelectAnnotationView) {
      this.annotationViewDelegate.didSelectAnnotationView(marker);
    }
  }
  
  /**
   * 取消选中 Annotation
   * 
   * @param marker Marker 实例
   * @param animated 是否播放动画
   */
  public deselectAnnotation(marker: Marker, animated: boolean = true): void {
    if (this.destroyed) return;
    
    this.annotationViewManager.deselectAnnotation(marker, animated);
    
    // 触发委托回调
    if (this.annotationViewDelegate?.didDeselectAnnotationView) {
      this.annotationViewDelegate.didDeselectAnnotationView(marker);
    }
  }
  
  /**
   * 取消所有选中的 Annotations
   * 
   * @param animated 是否播放动画
   */
  public deselectAllAnnotations(animated: boolean = true): void {
    if (this.destroyed) return;
    
    const selected = this.annotationViewManager.getSelectedAnnotations();
    selected.forEach(marker => {
      this.deselectAnnotation(marker, animated);
    });
  }
  
  /**
   * 获取选中的 Annotations
   * @returns 选中的 Marker 数组
   */
  public getSelectedAnnotations(): Marker[] {
    if (this.destroyed) return [];
    return this.annotationViewManager.getSelectedAnnotations();
  }
  
  /**
   * 从复用池获取 AnnotationView
   * 
   * @param identifier 复用标识符
   * @returns AnnotationViewData 实例或 null
   */
  public dequeueReusableAnnotationView(identifier: string): AnnotationViewData | null {
    if (this.destroyed) return null;
    return this.annotationViewManager.dequeueReusableView(identifier);
  }
  
  /**
   * 检查 Annotation 是否被选中
   * 
   * @param marker Marker 实例
   * @returns true 表示已选中
   */
  public isAnnotationSelected(marker: Marker): boolean {
    if (this.destroyed) return false;
    return this.annotationViewManager.isAnnotationSelected(marker);
  }
  
  /**
   * 获取所有可见的 Annotations
   * 
   * 参考: iOS MLNMapView visibleAnnotations
   * 
   * @returns 当前屏幕可见的 Marker 数组
   */
  public getVisibleAnnotations(): Marker[] {
    if (this.destroyed) return [];
    
    // 获取所有具有自定义视图的 Marker
    const allViews = this.annotationViewManager.getVisibleViews();
    return allViews.map(viewData => viewData.marker);
  }
  
  /**
   * 更新所有 AnnotationView 的位置
   * 
   * 在地图相机变化时自动调用，更新所有自定义视图的屏幕坐标
   * 
   * @param cameraChanged 相机参数是否发生变化（bearing/pitch）
   * @private
   */
  private updateAnnotationViewPositions(cameraChanged: boolean = false): void {
    if (this.destroyed) return;
    this.annotationViewManager.batchUpdatePositions(cameraChanged);
  }
  
  // ==================== 特性查询 (Feature Query) ====================
  
  /**
   * 查询指定点的渲染要素
   * 
   * @param x X 坐标（屏幕像素）
   * @param y Y 坐标（屏幕像素）
   * @param layerIds 可选的图层 ID 数组，如果提供则只查询这些图层
   * @param filter 可选的过滤器表达式
   * @returns Feature 数组
   * 
   * @example
   * ```typescript
   * // 查询屏幕坐标 (100, 200) 处的所有要素
   * const features = map.queryRenderedFeaturesForPoint(100, 200);
   * 
   * // 只查询特定图层的要素
   * const features = map.queryRenderedFeaturesForPoint(100, 200, ['poi-layer', 'building-layer']);
   * 
   * // 使用过滤器查询
   * const features = map.queryRenderedFeaturesForPoint(100, 200, ['poi-layer'], ['==', ['get', 'type'], 'restaurant']);
   * ```
   */
  public queryRenderedFeaturesForPoint(
    x: number,
    y: number,
    layerIds?: string[],
    filter?: Object
  ): IFeature[] {
    if (this.destroyed) {
      console.warn('MapLibreMap', 'queryRenderedFeaturesForPoint: Map is destroyed');
      return [];
    }
    
    try {
      return this.nativeMapView.queryRenderedFeaturesForPoint(x, y, layerIds, filter);
    } catch (error) {
      console.error('MapLibreMap', `queryRenderedFeaturesForPoint failed: ${error.message}`);
      return [];
    }
  }
  
  /**
   * 查询矩形区域内的渲染要素
   * 
   * @param left 左边界（屏幕像素）
   * @param top 上边界（屏幕像素）
   * @param right 右边界（屏幕像素）
   * @param bottom 下边界（屏幕像素）
   * @param layerIds 可选的图层 ID 数组，如果提供则只查询这些图层
   * @param filter 可选的过滤器表达式
   * @returns IFeature 数组
   * 
   * @example
   * ```typescript
   * // 查询矩形区域内的所有要素
   * const features = map.queryRenderedFeaturesForBox(100, 100, 300, 300);
   * 
   * // 只查询特定图层的要素
   * const features = map.queryRenderedFeaturesForBox(
   *   100, 100, 300, 300,
   *   ['poi-layer', 'building-layer']
   * );
   * 
   * // 使用过滤器查询
   * const features = map.queryRenderedFeaturesForBox(
   *   100, 100, 300, 300,
   *   ['poi-layer'],
   *   ['==', ['get', 'type'], 'restaurant']
   * );
   * ```
   */
  public queryRenderedFeaturesForBox(
    left: number,
    top: number,
    right: number,
    bottom: number,
    layerIds?: string[],
    filter?: Object
  ): IFeature[] {
    if (this.destroyed) {
      console.warn('MapLibreMap', 'queryRenderedFeaturesForBox: Map is destroyed');
      return [];
    }
    
    try {
      return this.nativeMapView.queryRenderedFeaturesForBox(left, top, right, bottom, layerIds, filter);
    } catch (error) {
      console.error('MapLibreMap', `queryRenderedFeaturesForBox failed: ${error.message}`);
      return [];
    }
  }
  
  // ========== InfoWindow 支持方法 ==========
  
  /**
   * 获取 InfoWindowManager（内部使用）
   * @internal
   */
  public getInfoWindowManager(): InfoWindowManager {
    return this.infoWindowManager;
  }
  
  // ========== 兼容性方法 (从 NativeMapView 迁移) ==========
  
  /**
   * 设置调试模式激活状态
   * 启用后会显示瓦片边界、FPS 等调试信息
   * @param active 是否激活调试模式
   */
  public setDebugActive(active: boolean): void {
    if (this.destroyed) return;
    // 调用 native 层的调试方法
    this.setDebug(active);
  }
  
  /**
   * 获取设备像素比
   * @returns 设备像素比
   */
  public getPixelRatio(): number {
    if (this.destroyed) {
      return 1.0;
    }
    // 直接从 NativeMapView 获取像素比（已通过 NAPI 从底层获取）
    return this.nativeMapView.getPixelRatio();
  }
  
  /**
   * 设置内容边距（padding）
   * 内容边距影响地图的可见区域，但不影响地图的大小
   * @param top 上边距
   * @param left 左边距
   * @param bottom 下边距
   * @param right 右边距
   */
  public setContentPadding(top: number, left: number, bottom: number, right: number): void {
    if (this.destroyed) return;
    // 调用 native 层的 setPadding 方法
    // 注意：native 层的顺序是 [left, top, right, bottom]
    this.nativeMapView.setContentInsets(left, top, right, bottom);
  }
  
  /**
   * 获取内容边距
   * @returns 边距数组 [top, left, bottom, right]
   */
  public getContentPadding(): number[] {
    if (this.destroyed) return [0, 0, 0, 0];
    try {
      // 从 native 层获取边距
      const insets: number[] = this.nativeMapView.getContentInsets() as number[];
      if (insets && Array.isArray(insets) && insets.length === 4) {
        // native 返回 [left, top, right, bottom]
        // 转换为 [top, left, bottom, right]
        return [insets[1], insets[0], insets[3], insets[2]];
      }
    } catch (error) {
      console.error('MapLibreMap', 'Failed to get content padding:', error);
    }
    return [0, 0, 0, 0];
  }
  
  /**
   * 获取与密度相关的矩形
   * 将逻辑坐标转换为物理像素坐标
   * @param rect 矩形参数（逻辑坐标）
   * @returns 调整后的矩形（物理像素坐标）
   */
  public getDensityDependantRectangle(rect: Rect): Rect {
    const pixelRatio = this.getPixelRatio();
    return new Rect(
      rect.left * pixelRatio,
      rect.top * pixelRatio,
      rect.right * pixelRatio,
      rect.bottom * pixelRatio
    );
  }
}

