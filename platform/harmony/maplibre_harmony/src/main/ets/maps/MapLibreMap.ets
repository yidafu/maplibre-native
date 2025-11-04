import maplibre, { NativeMapView } from 'libmaplibre.so';
import type { Icon, ExpressionLiteral as NapiExpressionLiteral } from 'libmaplibre.so';
import { MapLibreMapOptions } from './MapLibreMapOptions';
import { CameraPosition } from './camera/CameraPosition';
import { LatLng } from './geometry/LatLng';
import { LatLngBounds } from './geometry/LatLngBounds';
import { IPixelCoordinate, PixelCoordinate, Point } from './geometry/Point';
import { Rect } from './geometry/Rect';
import { IProjectedMeters, ProjectedMeters } from './geometry/ProjectedMeters';
// Layer 和 Source 类型导入，用于类型安全的图层和数据源操作
import type { Layer } from './style/layers/Layer';
import type { Source } from './style/sources/Source';
import { Image } from './style/images/Image';
import { IFeature } from './geojson';
import { TransitionOptions } from './style/layers/TransitionOptions';
import { Light } from './style/light/Light';
import { Polyline } from './annotations/Polyline';
import { Polygon } from './annotations/Polygon';
import { MarkerManager } from './annotations/MarkerManager';
import { PolygonManager } from './annotations/PolygonManager';
import { PolylineManager } from './annotations/PolylineManager';
import { MarkerOptions } from './annotations/MarkerOptions';
import { Annotation } from './annotations/Annotation';
import { OnMarkerClickListener } from './listeners/OnMarkerClickListener';
import { OnMarkerLongClickListener } from './listeners/OnMarkerLongClickListener';
import { OnMarkerDragListener } from './listeners/OnMarkerDragListener';
import { OnInfoWindowClickListener } from './listeners/OnInfoWindowClickListener';
import { OnInfoWindowCloseListener } from './listeners/OnInfoWindowCloseListener';
import { OnMarkerSelectListener } from './listeners/OnMarkerSelectListener';
import { InfoWindowManager } from './annotations/InfoWindowManager';
import { OnStyleLoadedListener } from './listeners/OnStyleLoadedListener';
import { OnStyleLoadErrorListener } from './listeners/OnStyleLoadErrorListener';
import { InfoWindowAdapter } from './annotations/InfoWindowAdapter';
import { AnnotationViewData, AnnotationViewManager } from './annotations/AnnotationViewManager';
import { AnnotationViewConfig, AnnotationViewDelegate } from './annotations/AnnotationViewDelegate';
import { CameraChangeDispatcher } from './camera/CameraChangeDispatcher';
import {
  OnCameraIdleListener,
  OnCameraMoveCanceledListener,
  OnCameraMoveListener,
  OnCameraMoveStartedListener
} from './camera/CameraListener';
import { CameraMoveReason } from './camera/CameraMoveReason';
import { UiSettings } from './UiSettings';
import {
  OnMapClickListener,
  OnMapLongClickListener,
  OnTouchMoveListener,
  OnTouchUpListener
} from './gestures/GestureListeners';
import { LocationComponent } from './location/LocationComponent';
import { Projection } from './projection/Projection';
import { CameraAnimationCallback } from './camera/CameraAnimationCallback';
import { registerMapLibreMap } from './NativeMapView';
import { Marker } from './annotations/Marker';
import { Style } from './style/Style';
import { RenderingRefreshMode } from './types/NativeTypes';
import { OnFpsChangedListener } from './listeners/OnFpsChangedListener';
import {
  OnPreCompileShaderListener,
  OnPostCompileShaderListener,
  OnShaderCompileFailedListener,
  OnGlyphsRequestedListener,
  OnGlyphsLoadedListener,
  OnGlyphsErrorListener,
  OnSpriteRequestedListener,
  OnSpriteLoadedListener,
  OnSpriteErrorListener,
  OnTileActionListener
} from './listeners/MapEventListeners';

/**
 * 操作队列项类型
 */
type PendingOperation = () => void;

/**
 * MapLibreMap - 地图核心控制类
 * 
 * 提供完整的地图控制功能，包括：
 * - 地图显示和样式管理
 * - 相机位置和动画控制
 * - 图层和数据源管理
 * - 标注（Marker、Polygon、Polyline）管理
 * - 手势交互和UI组件配置
 * - 位置跟踪和定位功能
 * 
 * **生命周期管理**：
 * - 在页面 `aboutToAppear()` 中创建和初始化
 * - 在页面 `aboutToDisappear()` 中调用 `destroy()` 释放资源
 * 
 * **样式加载**：
 * - 样式加载是异步的，需要等待 `onStyleLoaded` 回调
 * - 在样式加载完成前添加图层/数据源会自动加入队列，样式加载后执行
 * 
 * @example
 * ```typescript
 * // 基本用法
 * const options = new MapLibreMapOptions({
 *   styleUrl: DEFAULT_STYLE_URLS.streets,
 *   size: { width: 800, height: 600 }
 * });
 * 
 * const map = new MapLibreMap(nativeMapView, options);
 * 
 * // 设置相机位置
 * map.setLatLng(39.9, 116.4);
 * map.setZoom(15);
 * 
 * // 添加 Marker
 * const marker = await map.addMarker(
 *   new MarkerOptions()
 *     .position(39.9, 116.4)
 *     .title("北京")
 * );
 * 
 * // 监听地图事件
 * map.addOnMapClickListener({
 *   onMapClick: (x, y) => {
 *     console.log(`Map clicked at: ${x}, ${y}`);
 *     return false;
 *   }
 * });
 * 
 * // 页面销毁时清理
 * aboutToDisappear() {
 *   this.map?.destroy();
 * }
 * ```
 * 
 * @see {@link MapLibreMapOptions} 地图配置选项
 * @see {@link NativeMapView} 底层地图视图组件
 */
export class MapLibreMap {
  private nativeMapView: NativeMapView;
  private options: MapLibreMapOptions;
  private destroyed: boolean = false;
  private markerManager: MarkerManager;
  private polygonManager: PolygonManager;
  private polylineManager: PolylineManager;
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
    this.polygonManager = new PolygonManager(this);
    this.polylineManager = new PolylineManager(this);
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
    if (this.destroyed) {
      return 0;
    }
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

    this.destroyed = true;

    try {
      // 1. 清理所有监听器数组（参考 Android）
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
      this.markerManager.clear();

      // 3.1 清理 PolygonManager 和 PolylineManager
      this.polygonManager.clear();
      this.polylineManager.clear();

      // 4. 清理 InfoWindowManager
      this.infoWindowManager.closeAll();

      // 5. 清理 AnnotationViewManager
      this.annotationViewManager.clear();

      // 6. 销毁位置组件（参考 Android）
      this.locationComponent.onDestroy();

      // 7. 清理相机调度器
      // CameraChangeDispatcher 会在下面的 NativeMapView destroy 中清理监听器

      // 8. 清理样式引用
      this.style = null;
      this.styleLoaded = false;

      // 9. 清理 NativeMapView 引用（实际销毁在 NativeMapView 层）
      // Native 资源会在 NativeMapView.aboutToDisappear() 中异步清理

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
    if (this.destroyed) {
      return;
    }
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
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setStyleUrl(url);
    this.styleLoaded = false;
    this.style = null; // 重置 style 缓存
  }

  /**
   * 设置样式并在加载完成后执行回调
   * 这个方法结合了 setStyleUrl 和 addOnStyleLoadedListener 的功能
   * 参考 Android Style.Builder 模式，提供更流畅的 API
   * 
   * @param url 样式 URL
   * @param callback 样式加载完成后的回调函数
   * @example
   * ```typescript
   * map.setStyleWithCallback(DEFAULT_STYLE_URLS.streets, (style) => {
   *   new StyleBuilder()
   *     .withSource(source)
   *     .withLayer(layer)
   *     .build(map);
   * });
   * ```
   */
  public setStyleWithCallback(
    url: string,
    callback: (style: Style | null) => void
  ): void {
    if (this.destroyed) {
      return;
    }

    // 创建一次性监听器
    const self = this;
    class OneTimeStyleLoadedListener implements OnStyleLoadedListener {
      onStyleLoaded(style: Style | null): void {
        try {
          callback(style);
        } catch (error) {
          console.error(`MapLibreMap: Error in setStyleWithCallback callback: ${error}`);
        }
        // 回调执行后移除监听器
        self.removeOnStyleLoadedListener(this);
      }
    }
    const oneTimeListener = new OneTimeStyleLoadedListener();

    // 添加监听器
    this.addOnStyleLoadedListener(oneTimeListener);

    // 设置样式 URL
    this.setStyleUrl(url);
  }

  public getStyleUrl(): string {
    if (this.destroyed) {
      return '';
    }
    return this.nativeMapView.getStyleUrl();
  }

  /**
   * 设置本地表意文字字体族
   *
   * 用于本地渲染 CJK 字符，避免从网络加载大量字形数据。
   * 注意：此操作会重新初始化 Renderer 并重新加载样式。
   *
   * @param fontFamily 字体族名称，如 "HarmonyOS_Sans"，null 表示禁用本地渲染
   */
  public setLocalIdeographFontFamily(fontFamily: string | null): void {
    if (this.destroyed) {
      return;
    }

    // 更新内部状态
    this.options.localIdeographFontFamily = fontFamily;

    // 调用 C++ 接口更新字体配置并重新初始化 Renderer
    // 参考 Android/iOS：本地字体是在 Renderer 创建时固定的，运行时更改需要重新创建
    try {
      this.nativeMapView.setLocalIdeographFontFamily(fontFamily);
      console.info('[MapLibreMap] setLocalIdeographFontFamily: 本地字体已更新为 ' + 
                   (fontFamily || '(禁用)'));
    } catch (error) {
      console.error('[MapLibreMap] setLocalIdeographFontFamily: 更新失败', error);
    }
  }

  /**
   * 获取当前配置的本地表意文字字体族
   *
   * @returns 当前配置的字体族名称，null 表示已禁用
   */
  public getLocalIdeographFontFamily(): string | null {
    if (this.destroyed) {
      return null;
    }
    
    // 从 C++ 层获取实际配置的字体
    try {
      return this.nativeMapView.getLocalIdeographFontFamily();
    } catch (error) {
      console.error('[MapLibreMap] getLocalIdeographFontFamily: 获取失败', error);
      return this.options.localIdeographFontFamily;
    }
  }

  public setStyleJson(json: string): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setStyleJson(json);
    this.styleLoaded = false;
    this.style = null; // 重置 style 缓存
  }

  public getStyleJson(): string {
    if (this.destroyed) {
      return '';
    }
    return this.nativeMapView.getStyleJson();
  }

  /**
   * 获取样式对象
   *
   * @returns Style 封装类对象，如果地图未初始化或样式未加载则返回 null
   */
  public getStyle(): Style | null {
    if (this.destroyed) {
      return null;
    }
    if (!this.nativeMapView) {
      return null;
    }

    try {
      const nativeStyle = this.nativeMapView.getStyle();
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
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setLatLngBounds(bounds);
  }

  // 相机控制
  public cancelTransitions(): void {
    if (this.destroyed) {
      return;
    }
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
    if (this.destroyed) {
      return;
    }
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
    if (this.destroyed) {
      return [0, 0, 0, 0];
    }
    return this.projection.getContentPadding();
  }

  public setGestureInProgress(inProgress: boolean): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setGestureInProgress(inProgress);
  }

  public moveBy(dx: number, dy: number, duration: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.moveBy(dx, dy, duration);
  }

  public jumpTo(angle: number, latitude: number, longitude: number, pitch: number, zoom: number,
    padding?: number[]): void {
    if (this.destroyed) {
      return;
    }
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
    if (this.destroyed) {
      return;
    }

    // 判断调用形式
    if (typeof latitudeOrOptions === 'number' && typeof zoom === 'number' && typeof duration === 'number') {
      // 参数形式: easeTo(latitude, longitude, bearing, zoom, duration)
      const centerObj: LatLng = new LatLng(latitudeOrOptions, longitudeOrDuration);
      const options: maplibre.CameraOptions = {
        center: centerObj.toObject(),
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
    if (this.destroyed) {
      return;
    }

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
   * });
   * ```
   */
  public animateCamera(position: CameraPosition, durationMs?: number, callback?: CameraAnimationCallback): void {
    if (this.destroyed) {
      return;
    }

    const duration = durationMs ?? 300; // 默认 300ms

    // 构建相机选项
    const options: maplibre.CameraOptions = {
      center: position.target ? position.target.toObject() : undefined,
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
    if (this.destroyed) {
      return LatLng.create(0, 0);
    }
    const nativeLatLng: maplibre.LatLng = this.nativeMapView.getLatLng();
    return LatLng.fromNative(nativeLatLng);
  }

  public setLatLng(latitude: number, longitude: number, padding?: number[], duration?: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setLatLng(latitude, longitude, padding, duration);
  }

  public getCameraForLatLngBounds(bounds: LatLngBounds, top: number, left: number, bottom: number, right: number,
    bearing?: number, tilt?: number): CameraPosition | null {
    if (this.destroyed) {
      return null;
    }
    const result: ESObject =
      this.nativeMapView.getCameraForLatLngBounds(bounds, top, left, bottom, right, bearing, tilt) as ESObject;
    return result as CameraPosition;
  }

  public getCameraForGeometry(geometry: ESObject, top: number, left: number, bottom: number, right: number,
    bearing?: number, tilt?: number): CameraPosition | null {
    if (this.destroyed) {
      return null;
    }
    const result: ESObject =
      this.nativeMapView.getCameraForGeometry(geometry, top, left, bottom, right, bearing, tilt) as ESObject;
    return result as CameraPosition;
  }

  public setReachability(status: boolean): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setReachability(status);
  }

  public resetPosition(): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.resetPosition();
  }

  // 倾斜控制
  public getPitch(): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getPitch();
  }

  public setPitch(pitch: number, duration?: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setPitch(pitch, duration);
  }

  // 缩放控制
  public setZoom(zoom: number, cx?: number, cy?: number, duration?: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setZoom(zoom, cx, cy, duration);
  }

  public getZoom(): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getZoom();
  }

  public resetZoom(): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.resetZoom();
  }

  public setMinZoom(zoom: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setMinZoom(zoom);
  }

  public getMinZoom(): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getMinZoom();
  }

  public setMaxZoom(zoom: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setMaxZoom(zoom);
  }

  public getMaxZoom(): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getMaxZoom();
  }

  // 倾斜限制
  public setMinPitch(pitch: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setMinPitch(pitch);
  }

  public getMinPitch(): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getMinPitch();
  }

  public setMaxPitch(pitch: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setMaxPitch(pitch);
  }

  public getMaxPitch(): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getMaxPitch();
  }

  // 旋转
  public rotateBy(sx: number, sy: number, ex: number, ey: number, duration?: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.rotateBy(sx, sy, ex, ey, duration);
  }

  // 方位控制
  public setBearing(degrees: number, duration?: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setBearing(degrees, duration);
  }

  public setBearingXY(degrees: number, fx: number, fy: number, duration?: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setBearingXY(degrees, fx, fy, duration);
  }

  public getBearing(): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getBearing();
  }

  public resetNorth(duration: number = 150): void {
    if (this.destroyed) {
      return;
    }
    // 使用动画方式归正北（参考 Android TIME_MAP_NORTH_ANIMATION = 150ms）
    this.nativeMapView.setBearing(0, duration);
  }

  // 坐标边界
  public setVisibleCoordinateBounds(coordinates: LatLng[], padding: Rect, direction: number, duration: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setVisibleCoordinateBounds(coordinates, padding, direction, duration);
  }

  public getVisibleCoordinateBounds(): LatLng[] {
    if (this.destroyed) {
      return [];
    }
    const nativeLatLngs = this.nativeMapView.getVisibleCoordinateBounds();
    return nativeLatLngs.map(native => LatLng.fromNative(native));
  }

  // 快照
  public scheduleSnapshot(): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.scheduleSnapshot();
  }

  // 相机位置
  public getCameraPosition(): CameraPosition | null {
    if (this.destroyed) {
      return null;
    }
    const result = this.nativeMapView.getCameraPosition();
    return result as CameraPosition;
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
    if (this.destroyed) {
      return;
    }

    try {
      // 使用 MarkerManager 的公共方法更新
      // 这样可以更新所有属性：position, icon, alpha, rotation, zIndex 等
      this.markerManager.updateMarker(marker);

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
    for (let i = 0; i < markers.length; i++) {
      const pos = markers[i].getPosition();
      const icon = markers[i].getIcon();
    }

    // 将封装的 Marker 转换为 NAPI Marker 对象数组
    const nativeMarkers: maplibre.Marker[] = markers.map((m: Marker): maplibre.Marker => m.getNative());
    const ids: number[] = this.nativeMapView.addMarkers(nativeMarkers);

    // [MarkerDebug] 记录 NAPI 返回结果

    return ids;
  }

  public addPolylines(polylines: Polyline[]): number[] {
    if (this.destroyed) {
      return [];
    }
    // 提取原生对象
    const nativePolylines = polylines.map(p => p.getNative());
    return this.nativeMapView.addPolylines(nativePolylines);
  }

  public addPolygons(polygons: Polygon[]): number[] {
    if (this.destroyed) {
      return [];
    }
    // 提取原生对象
    const nativePolygons = polygons.map(p => p.getNative());
    return this.nativeMapView.addPolygons(nativePolygons);
  }

  public updatePolyline(polyline: Polyline): void {
    if (this.destroyed) {
      return;
    }
    if (!polyline) {
      console.error('MapLibreMap.updatePolyline: polyline is null or undefined');
      return;
    }

    try {
      const nativePolyline = polyline.getNative();
      if (!nativePolyline) {
        console.error('MapLibreMap.updatePolyline: nativePolyline is null or undefined');
        return;
      }

      // 传递原生 NAPI 对象供 C++ unwrap（C++ 层会从对象获取 ID）
      this.nativeMapView.updatePolyline(nativePolyline);
    } catch (error) {
      console.error(`MapLibreMap.updatePolyline: Exception - ${error}`);
      // throw error;
    }
  }

  public updatePolygon(polygon: Polygon): void {
    if (this.destroyed) {
      return;
    }
    if (!polygon) {
      console.error('MapLibreMap.updatePolygon: polygon is null or undefined');
      return;
    }

    try {
      const nativePolygon = polygon.getNative();
      if (!nativePolygon) {
        console.error('MapLibreMap.updatePolygon: nativePolygon is null or undefined');
        return;
      }

      // 传递原生 NAPI 对象供 C++ unwrap（C++ 层会从对象获取 ID）
      this.nativeMapView.updatePolygon(nativePolygon);
    } catch (error) {
      console.error(`MapLibreMap.updatePolygon: Exception - ${error}`);
      // throw error;
    }
  }

  public removeAnnotations(ids: number[]): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.removeAnnotations(ids);
  }

  public addAnnotationIcon(symbol: string, width: number, height: number, scale: number, pixels: Uint8Array): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.addAnnotationIcon(symbol, width, height, scale, pixels);
  }

  public removeAnnotationIcon(symbol: string): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.removeAnnotationIcon(symbol);
  }

  public getTopOffsetPixelsForAnnotationSymbol(symbolName: string): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getTopOffsetPixelsForAnnotationSymbol(symbolName);
  }

  // 内存管理
  public onLowMemory(): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.onLowMemory();
  }

  // 调试 (已废弃，使用 setDebugActive 或 setDebugOptions 代替)
  // 保留此方法以保持向后兼容，但内部调用新的 API
  public setDebug(debug: boolean): void {
    if (this.destroyed) {
      return;
    }
    this.setDebugActive(debug);
  }

  public getDebug(): boolean {
    if (this.destroyed) {
      return false;
    }
    return this.isDebugActive();
  }

  // 动作日志
  public getActionJournalLogFiles(): string[] {
    if (this.destroyed) {
      return [];
    }
    return this.nativeMapView.getActionJournalLogFiles();
  }

  public getActionJournalLog(): string[] {
    if (this.destroyed) {
      return [];
    }
    return this.nativeMapView.getActionJournalLog();
  }

  public clearActionJournalLog(): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.clearActionJournalLog();
  }

  // 加载状态
  public isFullyLoaded(): boolean {
    if (this.destroyed) {
      return false;
    }
    return this.nativeMapView.isFullyLoaded();
  }

  // 坐标转换
  public projectedMetersForLatLng(latitude: number, longitude: number): ProjectedMeters {
    if (this.destroyed) {
      return new ProjectedMeters(0, 0);
    }
    const result: IProjectedMeters = this.nativeMapView.projectedMetersForLatLng(latitude, longitude);
    return ProjectedMeters.fromObject(result);
  }

  public pixelForLatLng(latitude: number, longitude: number): Point {
    if (this.destroyed) {
      return new PixelCoordinate(0, 0);
    }
    const result: IPixelCoordinate = this.nativeMapView.pixelForLatLng(latitude, longitude);
    return PixelCoordinate.fromObject(result);
  }

  public pixelsForLatLngs(input: number[], output: number[]): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.pixelsForLatLngs(input, output);
  }

  public latLngForProjectedMeters(northing: number, easting: number): LatLng {
    if (this.destroyed) {
      return LatLng.create(0, 0);
    }
    const nativeLatLng: maplibre.LatLng = this.nativeMapView.latLngForProjectedMeters(northing, easting);
    return LatLng.fromNative(nativeLatLng);
  }

  public latLngForPixel(x: number, y: number): LatLng {
    if (this.destroyed) {
      return LatLng.create(0, 0);
    }
    const nativeLatLng: maplibre.LatLng = this.nativeMapView.latLngForPixel(x, y);
    return LatLng.fromNative(nativeLatLng);
  }

  public latLngsForPixels(input: number[], output: number[]): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.latLngsForPixels(input, output);
  }

  // 过渡
  public getTransitionOptions(): TransitionOptions {
    if (this.destroyed) {
      return new TransitionOptions(0, 0);
    }
    const result = this.nativeMapView.getTransitionOptions();
    return TransitionOptions.fromObject(result);
  }

  public setTransitionOptions(options: TransitionOptions): void {
    if (this.destroyed) {
      return;
    }
    // 转换为对象字面量传递给 NAPI
    this.nativeMapView.setTransitionOptions(options.toObject());
  }


  // 光照
  public getLight(): Light | null {
    if (this.destroyed) {
      return null;
    }
    const result: ESObject = this.nativeMapView.getLight() as ESObject;
    return result as Light;
  }

  // 图层方法 - 使用强类型 Layer
  public getLayers(): Layer[] {
    if (this.destroyed) {
      return [];
    }
    // 使用 Style 的 getLayers 方法，确保返回正确封装的 Layer 对象
    const style = this.getStyle();
    if (style) {
      return style.getLayers();
    }
    // 如果 style 未加载，返回空数组
    return [];
  }

  public getLayer(layerId: string): Layer | null {
    if (this.destroyed) {
      return null;
    }
    // 使用 Style 的 getLayer 方法，确保返回正确封装的 Layer 对象
    const style = this.getStyle();
    if (style) {
      return style.getLayer(layerId);
    }
    // 如果 style 未加载，返回 null
    return null;
  }

  public addLayer(layer: Layer): void {
    if (this.destroyed) {
      return;
    }
    const style = this.getStyle();
    if (style) {
      style.addLayer(layer);
    }
  }

  public addLayerAbove(layer: Layer, aboveLayerId: string): void {
    if (this.destroyed) {
      return;
    }
    const style = this.getStyle();
    if (style) {
      style.addLayerAbove(layer, aboveLayerId);
    }
  }

  public addLayerAt(layer: Layer, index: number): void {
    if (this.destroyed) {
      return;
    }
    const style = this.getStyle();
    if (style) {
      style.addLayerAt(layer, index);
    }
  }

  public removeLayerAt(index: number): boolean {
    if (this.destroyed) {
      return false;
    }
    const style = this.getStyle();
    if (style) {
      return style.removeLayerAt(index);
    }
    return false;
  }

  public removeLayer(layer: Layer | string): boolean {
    if (this.destroyed) {
      return false;
    }
    const style = this.getStyle();
    if (style) {
      const layerId = typeof layer === 'string' ? layer : layer.getId();
      return style.removeLayer(layerId);
    }
    return false;
  }

  // 数据源方法 - 使用强类型 Source
  public getSources(): Source[] {
    if (this.destroyed) {
      return [];
    }
    const style = this.getStyle();
    if (style) {
      return style.getSources();
    }
    return [];
  }

  public getSource(sourceId: string): Source | null {
    if (this.destroyed) {
      return null;
    }
    const style = this.getStyle();
    if (style) {
      return style.getSource(sourceId);
    }
    return null;
  }

  public addSource(source: Source): void {
    if (this.destroyed) {
      return;
    }
    const style = this.getStyle();
    if (style) {
      style.addSource(source);
    }
  }

  public removeSource(source: Source | string): boolean {
    if (this.destroyed) {
      return false;
    }
    const style = this.getStyle();
    if (style) {
      const sourceId = typeof source === 'string' ? source : source.getId();
      return style.removeSource(sourceId);
    }
    return false;
  }

  // 图片
  public addImages(images: Image[]): void {
    if (this.destroyed) {
      return;
    }
    const nativeImages = images.map(img => img.getNative());
    this.nativeMapView.addImages(nativeImages as ESObject);
  }

  public removeImage(name: string): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.removeImage(name);
  }

  public getImage(name: string): Icon | null {
    if (this.destroyed) {
      return null;
    }
    const result = this.nativeMapView.getImage(name);
    return result as Icon | null;
  }

  // 瓦片管理
  public setPrefetchTiles(enable: boolean): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setPrefetchTiles(enable);
  }

  public getPrefetchTiles(): boolean {
    if (this.destroyed) {
      return false;
    }
    return this.nativeMapView.getPrefetchTiles();
  }

  public setPrefetchZoomDelta(delta: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setPrefetchZoomDelta(delta);
  }

  public getPrefetchZoomDelta(): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getPrefetchZoomDelta();
  }

  public setTileCacheEnabled(enabled: boolean): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setTileCacheEnabled(enabled);
  }

  public getTileCacheEnabled(): boolean {
    if (this.destroyed) {
      return false;
    }
    return this.nativeMapView.getTileCacheEnabled();
  }

  // 瓦片LOD
  public setTileLodMinRadius(radius: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setTileLodMinRadius(radius);
  }

  public getTileLodMinRadius(): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getTileLodMinRadius();
  }

  public setTileLodScale(scale: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setTileLodScale(scale);
  }

  public getTileLodScale(): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getTileLodScale();
  }

  public setTileLodPitchThreshold(threshold: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setTileLodPitchThreshold(threshold);
  }

  public getTileLodPitchThreshold(): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getTileLodPitchThreshold();
  }

  public setTileLodZoomShift(shift: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setTileLodZoomShift(shift);
  }

  public getTileLodZoomShift(): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getTileLodZoomShift();
  }

  // 渲染
  public triggerRepaint(): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.triggerRepaint();
  }

  public isRenderingStatsViewEnabled(): boolean {
    if (this.destroyed) {
      return false;
    }
    return this.nativeMapView.isRenderingStatsViewEnabled();
  }

  public enableRenderingStatsView(enabled: boolean): void {
    if (this.destroyed) {
      return;
    }
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
    if (this.destroyed) {
      return [];
    }
    return await this.markerManager.addMarkers(optionsList);
  }

  /**
   * 移除单个 Marker
   *
   * @param marker 要移除的 Marker
   */
  public removeMarker(marker: Marker): void {
    if (this.destroyed) {
      return;
    }
    this.markerManager.removeMarker(marker);
  }

  /**
   * 移除 Annotation（通用方法）
   *
   * @param annotation 要移除的 Annotation
   */
  public removeAnnotation(annotation: Annotation | Marker): void {
    if (this.destroyed) {
      return;
    }

    // 尝试类型检查：Marker 有 getPosition 方法
    try {
      const marker = annotation as Marker;
      marker.getPosition(); // 调用方法尝试验证
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
    if (this.destroyed) {
      return;
    }

    const markers: Marker[] = [];
    const otherIds: number[] = [];

    for (const annotation of annotations) {
      // 尝试类型检查：Marker 有 getPosition 方法
      try {
        const marker = annotation as Marker;
        marker.getPosition(); // 调用方法尝试验证
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
    if (this.destroyed) {
      return;
    }
    this.markerManager.clear();
  }

  /**
   * 清空所有标注（Android 风格的 clear() 方法）
   * 清除所有标记、折线、多边形等
   */
  public clear(): void {
    if (this.destroyed) {
      return;
    }

    // 清除所有 Marker
    this.markerManager.clear();

    // 关闭所有 InfoWindow
    this.infoWindowManager.closeAll();

    // 清除所有 AnnotationView
    this.annotationViewManager.clear();
  }

  /**
   * 获取所有 Marker
   *
   * @returns Marker 数组
   */
  public getMarkers(): Marker[] {
    if (this.destroyed) {
      return [];
    }
    return this.markerManager.getMarkers();
  }

  /**
   * 根据 ID 获取 Marker
   *
   * @param id Marker ID
   * @returns Marker 实例，如果不存在则返回 null
   */
  public getMarkerById(id: number): Marker | null {
    if (this.destroyed) {
      return null;
    }
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
    if (this.destroyed) {
      return;
    }
    this.markerManager.selectMarker(marker, true);
  }

  /**
   * 取消选中 Marker
   *
   * @param marker 要取消选中的 Marker
   */
  public deselectMarker(marker: Marker): void {
    if (this.destroyed) {
      return;
    }
    this.markerManager.deselectMarker(marker);
  }

  /**
   * 取消所有选中的 Marker
   */
  public deselectMarkers(): void {
    if (this.destroyed) {
      return;
    }
    this.markerManager.deselectMarkers();
  }

  /**
   * 获取所有选中的 Marker
   *
   * @returns 选中的 Marker 数组
   */
  public getSelectedMarkers(): Marker[] {
    if (this.destroyed) {
      return [];
    }
    return this.markerManager.getSelectedMarkers();
  }

  // ========== 事件监听器 ==========

  /**
   * 设置 Marker 点击监听器
   *
   * @param listener 监听器实例
   */
  public setOnMarkerClickListener(listener: OnMarkerClickListener | null): void {
    if (this.destroyed) {
      console.warn(`[MapLibreMap] ⚠️ Map is destroyed, cannot set listener`);
      return;
    }
    this.markerManager.setOnMarkerClickListener(listener);
  }

  /**
   * 设置 Marker 长按监听器
   *
   * @param listener 监听器实例
   */
  public setOnMarkerLongClickListener(listener: OnMarkerLongClickListener | null): void {
    if (this.destroyed) {
      console.warn(`[MapLibreMap] ⚠️ Map is destroyed, cannot set listener`);
      return;
    }
    this.markerManager.setOnMarkerLongClickListener(listener);
  }

  /**
   * 设置 Marker 拖拽监听器
   *
   * @param listener 监听器实例
   */
  public setOnMarkerDragListener(listener: OnMarkerDragListener | null): void {
    if (this.destroyed) {
      return;
    }
    this.markerManager.setOnMarkerDragListener(listener);
  }

  /**
   * 设置 Marker 选中监听器
   *
   * @param listener 监听器实例
   */
  public setOnMarkerSelectListener(listener: OnMarkerSelectListener | null): void {
    if (this.destroyed) {
      return;
    }
    this.markerManager.setOnMarkerSelectListener(listener);
  }

  /**
   * 获取 Marker 选中监听器
   *
   * @returns 监听器实例
   */
  public getOnMarkerSelectListener(): OnMarkerSelectListener | null {
    if (this.destroyed) {
      return null;
    }
    return this.markerManager.getOnMarkerSelectListener();
  }

  /**
   * 设置 InfoWindow 点击监听器
   *
   * @param listener 监听器实例
   */
  public setOnInfoWindowClickListener(listener: OnInfoWindowClickListener | null): void {
    if (this.destroyed) {
      return;
    }
    this.markerManager.setOnInfoWindowClickListener(listener);
  }

  /**
   * 设置 InfoWindow 关闭监听器
   *
   * @param listener 监听器实例
   */
  public setOnInfoWindowCloseListener(listener: OnInfoWindowCloseListener | null): void {
    if (this.destroyed) {
      return;
    }
    this.markerManager.setOnInfoWindowCloseListener(listener);
  }

  /**
   * 获取 InfoWindow 关闭监听器
   *
   * @returns 监听器实例
   */
  public getOnInfoWindowCloseListener(): OnInfoWindowCloseListener | null {
    if (this.destroyed) {
      return null;
    }
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
    if (this.destroyed) {
      return;
    }
    this.markerManager.setInfoWindowAdapter(adapter);
  }

  // ==================== Style 监听器管理 ====================

  /**
   * 添加样式加载完成监听器
   *
   * @param listener 监听器实例
   */
  public addOnStyleLoadedListener(listener: OnStyleLoadedListener): void {
    if (this.destroyed) {
      return;
    }
    if (!this.styleLoadedListeners.includes(listener)) {
      this.styleLoadedListeners.push(listener);

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
    }
  }

  /**
   * 添加样式加载错误监听器
   *
   * @param listener 监听器实例
   */
  public addOnStyleLoadErrorListener(listener: OnStyleLoadErrorListener): void {
    if (this.destroyed) {
      return;
    }
    if (!this.styleLoadErrorListeners.includes(listener)) {
      this.styleLoadErrorListeners.push(listener);
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
    if (this.destroyed) {
      return;
    }

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
    }
  }

  /**
   * 获取 InfoWindow 适配器
   *
   * @returns 适配器实例
   */
  public getInfoWindowAdapter(): InfoWindowAdapter | null {
    if (this.destroyed) {
      return null;
    }
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
    if (this.destroyed) {
      return;
    }
    this.markerManager.showInfoWindow(marker);
  }

  /**
   * 隐藏指定 Marker 的 InfoWindow
   *
   * @param marker 要隐藏 InfoWindow 的 Marker
   */
  public hideInfoWindow(marker: Marker): void {
    if (this.destroyed) {
      return;
    }
    this.markerManager.hideInfoWindow(marker);
  }

  // ========== Polygon 管理方法 ==========

  /**
   * 获取所有 Polygon
   *
   * @returns Polygon 数组
   */
  public getPolygons(): Polygon[] {
    if (this.destroyed) {
      return [];
    }
    return this.polygonManager.getPolygons();
  }

  /**
   * 清除所有 Polygon
   */
  public clearPolygons(): void {
    if (this.destroyed) {
      return;
    }
    this.polygonManager.clear();
  }

  /**
   * 获取 PolygonManager 实例（内部使用）
   *
   * @returns PolygonManager 实例
   */
  public getPolygonManager(): PolygonManager {
    return this.polygonManager;
  }

  // ========== Polyline 管理方法 ==========

  /**
   * 获取所有 Polyline
   *
   * @returns Polyline 数组
   */
  public getPolylines(): Polyline[] {
    if (this.destroyed) {
      return [];
    }
    return this.polylineManager.getPolylines();
  }

  /**
   * 清除所有 Polyline
   */
  public clearPolylines(): void {
    if (this.destroyed) {
      return;
    }
    this.polylineManager.clear();
  }

  /**
   * 获取 PolylineManager 实例（内部使用）
   *
   * @returns PolylineManager 实例
   */
  public getPolylineManager(): PolylineManager {
    return this.polylineManager;
  }

  /**
   * 隐藏所有 InfoWindow
   */
  public hideAllInfoWindows(): void {
    if (this.destroyed) {
      return;
    }
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
    if (this.destroyed) {
      return;
    }

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
    if (this.destroyed) {
      return;
    }
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
    if (this.destroyed) {
      return;
    }

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
    if (this.destroyed) {
      return;
    }
    this.cameraChangeDispatcher.removeOnCameraMoveStartedListener(listener);
  }

  /**
   * 添加相机移动中监听器
   * 在相机移动过程中频繁触发
   *
   * @param listener OnCameraMoveListener 实例
   */
  public addOnCameraMoveListener(listener: OnCameraMoveListener): void {
    if (this.destroyed) {
      return;
    }

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
    if (this.destroyed) {
      return;
    }
    this.cameraChangeDispatcher.removeOnCameraMoveListener(listener);
  }

  /**
   * 添加相机移动取消监听器
   * 当相机动画被中断或取消时触发
   *
   * @param listener OnCameraMoveCanceledListener 实例
   */
  public addOnCameraMoveCanceledListener(listener: OnCameraMoveCanceledListener): void {
    if (this.destroyed) {
      return;
    }

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
    if (this.destroyed) {
      return;
    }
    this.cameraChangeDispatcher.removeOnCameraMoveCanceledListener(listener);
  }

  /**
   * 内部方法：通知相机开始移动（手势触发）
   * 供手势处理器调用
   * @internal
   */
  public _notifyCameraMoveStartedByGesture(): void {
    if (this.destroyed) {
      return;
    }
    this.cameraChangeDispatcher.notifyCameraMoveStarted(CameraMoveReason.GESTURE);
  }

  /**
   * 内部方法：通知相机正在移动
   * 供手势处理器调用
   * @internal
   */
  public _notifyCameraMove(): void {
    if (this.destroyed) {
      return;
    }
    this.cameraChangeDispatcher.notifyCameraMove();
  }

  /**
   * 内部方法：通知相机停止移动
   * 供手势处理器调用
   * @internal
   */
  public _notifyCameraIdle(): void {
    if (this.destroyed) {
      return;
    }
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
    if (this.destroyed) {
      return;
    }
    if (!this.mapClickListeners.includes(listener)) {
      this.mapClickListeners.push(listener);
    }
  }

  /**
   * 移除地图点击监听器
   *
   * @param listener 要移除的监听器
   */
  public removeOnMapClickListener(listener: OnMapClickListener): void {
    if (this.destroyed) {
      return;
    }
    const index = this.mapClickListeners.indexOf(listener);
    if (index > -1) {
      this.mapClickListeners.splice(index, 1);
    }
  }

  /**
   * 添加地图长按监听器
   * 当用户长按地图时触发（参考 Android addOnMapLongClickListener）
   *
   * @param listener OnMapLongClickListener 实例
   */
  public addOnMapLongClickListener(listener: OnMapLongClickListener): void {
    if (this.destroyed) {
      return;
    }
    if (!this.mapLongClickListeners.includes(listener)) {
      this.mapLongClickListeners.push(listener);
    }
  }

  /**
   * 移除地图长按监听器
   *
   * @param listener 要移除的监听器
   */
  public removeOnMapLongClickListener(listener: OnMapLongClickListener): void {
    if (this.destroyed) {
      return;
    }
    const index = this.mapLongClickListeners.indexOf(listener);
    if (index > -1) {
      this.mapLongClickListeners.splice(index, 1);
    }
  }

  // 触摸事件监听器列表（用于 Marker 拖拽等功能）
  private touchMoveListeners: OnTouchMoveListener[] = [];
  private touchUpListeners: OnTouchUpListener[] = [];

  /**
   * 添加触摸移动监听器
   * 用于实现 Marker 拖拽等需要连续跟踪触摸位置的功能
   * 参考 Android AndroidGesturesManager.setMoveGestureListener
   *
   * 注意：触摸事件通过 NativeMapView 的手势系统分发，这里只是注册回调
   *
   * @param listener OnTouchMoveListener 实例
   */
  public addOnTouchMoveListener(listener: OnTouchMoveListener): void {
    if (this.destroyed) {
      return;
    }
    if (!this.touchMoveListeners.includes(listener)) {
      this.touchMoveListeners.push(listener);
    }
  }

  /**
   * 移除触摸移动监听器
   *
   * @param listener 要移除的监听器
   */
  public removeOnTouchMoveListener(listener: OnTouchMoveListener): void {
    if (this.destroyed) {
      return;
    }
    const index = this.touchMoveListeners.indexOf(listener);
    if (index > -1) {
      this.touchMoveListeners.splice(index, 1);
    }
  }

  /**
   * 添加触摸释放监听器
   * 用于检测触摸结束，实现 Marker 拖拽结束等功能
   * 参考 iOS UIPanGestureRecognizer UIGestureRecognizerStateEnded
   *
   * @param listener OnTouchUpListener 实例
   */
  public addOnTouchUpListener(listener: OnTouchUpListener): void {
    if (this.destroyed) {
      return;
    }
    if (!this.touchUpListeners.includes(listener)) {
      this.touchUpListeners.push(listener);
    }
  }

  /**
   * 移除触摸释放监听器
   *
   * @param listener 要移除的监听器
   */
  public removeOnTouchUpListener(listener: OnTouchUpListener): void {
    if (this.destroyed) {
      return;
    }
    const index = this.touchUpListeners.indexOf(listener);
    if (index > -1) {
      this.touchUpListeners.splice(index, 1);
    }
  }

  /**
   * 移除所有监听器
   * 
   * 批量移除地图上的所有事件监听器，包括：
   * - 样式加载监听器
   * - 相机移动监听器
   * - 地图点击/长按监听器
   * - 触摸事件监听器
   * - Marker 相关监听器
   * 
   * 通常在页面销毁时调用，防止内存泄漏
   * 
   * @example
   * aboutToDisappear() {
   *   if (this.mapController) {
   *     this.mapController.removeAllListeners();
   *     this.mapController.destroy();
   *   }
   * }
   */
  public removeAllListeners(): void {
    if (this.destroyed) {
      return;
    }
    
    // 清除样式监听器
    this.styleLoadedListeners = [];
    this.styleLoadErrorListeners = [];
    
    // 清除相机移动监听器（通过 dispatcher）
    this.cameraChangeDispatcher.clearAllListeners();
    
    // 清除地图交互监听器
    this.mapClickListeners = [];
    this.mapLongClickListeners = [];
    this.touchMoveListeners = [];
    this.touchUpListeners = [];
    
    // 清除 Marker 相关监听器
    this.markerManager.clearAllListeners();
    
    console.info('[MapLibreMap] All listeners removed');
  }

  /**
   * 内部方法：触发触摸移动事件
   * 由 NativeMapView 或手势系统调用
   *
   * @param x 触摸位置 X 坐标
   * @param y 触摸位置 Y 坐标
   * @returns true 如果事件被消费
   */
  public fireTouchMoveEvent(x: number, y: number): boolean {
    if (this.destroyed) {
      return false;
    }

    for (const listener of this.touchMoveListeners) {
      try {
        if (listener.onTouchMove(x, y)) {
          return true; // 事件被消费
        }
      } catch (error) {
        console.error(`MapLibreMap: Error in touch move listener: ${error}`);
      }
    }
    return false;
  }

  /**
   * 内部方法：触发触摸释放事件
   * 由 NativeMapView 或手势系统调用
   *
   * @param x 触摸位置 X 坐标
   * @param y 触摸位置 Y 坐标
   * @returns true 如果事件被消费
   */
  public fireTouchUpEvent(x: number, y: number): boolean {
    if (this.destroyed) {
      return false;
    }

    for (const listener of this.touchUpListeners) {
      try {
        if (listener.onTouchUp(x, y)) {
          return true; // 事件被消费
        }
      } catch (error) {
        console.error(`MapLibreMap: Error in touch up listener: ${error}`);
      }
    }
    return false;
  }

  /**
   * 内部方法：触发地图点击事件
   * @param x 点击位置 X 坐标
   * @param y 点击位置 Y 坐标
   * @returns 是否有监听器消费了该事件
   * @internal
   */
  public _notifyMapClick(x: number, y: number): boolean {
    if (this.destroyed) {
      return false;
    }
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
    if (this.destroyed) {
      return false;
    }
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

  /**
   * 尝试开始拖拽 Marker（在 Pan 手势开始时调用）
   *
   * @param x 触摸位置 X 坐标（逻辑像素）
   * @param y 触摸位置 Y 坐标（逻辑像素）
   * @returns true 如果开始拖拽 Marker
   * @internal
   */
  public tryStartMarkerDrag(x: number, y: number): boolean {
    if (this.destroyed) {
      return false;
    }

    // 尝试通过 MarkerManager 开始拖拽
    if (this.markerManager) {
      return this.markerManager.tryStartDrag(x, y);
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
    if (this.destroyed) {
      return;
    }
    this.annotationViewDelegate = delegate;

    // 设置到管理器的 adapter（如果需要）
    // 注：AnnotationViewDelegate 和 AnnotationViewAdapter 可以统一
  }

  /**
   * 获取 AnnotationViewDelegate
   * @returns AnnotationViewDelegate 实例或 null
   */
  public getAnnotationViewDelegate(): AnnotationViewDelegate | null {
    if (this.destroyed) {
      return null;
    }
    return this.annotationViewDelegate;
  }

  /**
   * 为 Marker 注册 AnnotationView
   *
   * @param marker Marker 实例
   * @param config AnnotationViewConfig 配置
   */
  public registerAnnotationView(marker: Marker, config: AnnotationViewConfig): void {
    if (this.destroyed) {
      return;
    }

    // 使用 AnnotationViewManager 创建视图
    this.annotationViewManager.createOrUpdateView(marker);

  }

  /**
   * 取消注册 AnnotationView
   *
   * @param marker Marker 实例
   */
  public unregisterAnnotationView(marker: Marker): void {
    if (this.destroyed) {
      return;
    }

    this.annotationViewManager.removeView(marker);

  }

  /**
   * 选中 Annotation
   *
   * @param marker Marker 实例
   * @param animated 是否播放动画
   */
  public selectAnnotation(marker: Marker, animated: boolean = true): void {
    if (this.destroyed) {
      return;
    }

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
    if (this.destroyed) {
      return;
    }

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
    if (this.destroyed) {
      return;
    }

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
    if (this.destroyed) {
      return [];
    }
    return this.annotationViewManager.getSelectedAnnotations();
  }

  /**
   * 从复用池获取 AnnotationView
   *
   * @param identifier 复用标识符
   * @returns AnnotationViewData 实例或 null
   */
  public dequeueReusableAnnotationView(identifier: string): AnnotationViewData | null {
    if (this.destroyed) {
      return null;
    }
    return this.annotationViewManager.dequeueReusableView(identifier);
  }

  /**
   * 检查 Annotation 是否被选中
   *
   * @param marker Marker 实例
   * @returns true 表示已选中
   */
  public isAnnotationSelected(marker: Marker): boolean {
    if (this.destroyed) {
      return false;
    }
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
    if (this.destroyed) {
      return [];
    }

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
    if (this.destroyed) {
      return;
    }
    this.annotationViewManager.batchUpdatePositions(cameraChanged);
  }

  // ==================== 特性查询 (Feature Query) ====================

  /**
   * 查询指定点的渲染要素
   *
   * @param x X 坐标（逻辑像素，会自动转换为物理像素）
   * @param y Y 坐标（逻辑像素，会自动转换为物理像素）
   * @param layerIds 可选的图层 ID 数组，如果提供则只查询这些图层
   * @param filter 可选的过滤器表达式
   * @returns Feature 数组
   *
   * @note 坐标系统说明：
   * - 输入坐标为逻辑像素（与触摸事件坐标一致）
   * - 内部会自动乘以 pixelRatio 转换为物理像素传递给底层渲染引擎
   * - 这确保了在不同 DPI 设备上的查询准确性
   *
   * @example
  * ```typescript
   * // 查询屏幕坐标 (100, 200) 处的所有要素（使用逻辑像素）
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
    filter?: NapiExpressionLiteral
  ): IFeature[] {
    if (this.destroyed) {
      console.warn('MapLibreMap', 'queryRenderedFeaturesForPoint: Map is destroyed');
      return [];
    }

    try {
      // DPI 转换：逻辑像素 -> 物理像素
      const pixelRatio = this.nativeMapView.getPixelRatio();
      const screenX = x * pixelRatio;
      const screenY = y * pixelRatio;

      const features = this.nativeMapView.queryRenderedFeaturesForPoint(screenX, screenY, layerIds, filter);
      return features as ESObject as IFeature[];
    } catch (error) {
      console.error('MapLibreMap', `queryRenderedFeaturesForPoint failed: ${error.message}`);
      return [];
    }
  }

  /**
   * 查询矩形区域内的渲染要素
   *
   * @param left 左边界（逻辑像素，会自动转换为物理像素）
   * @param top 上边界（逻辑像素，会自动转换为物理像素）
   * @param right 右边界（逻辑像素，会自动转换为物理像素）
   * @param bottom 下边界（逻辑像素，会自动转换为物理像素）
   * @param layerIds 可选的图层 ID 数组，如果提供则只查询这些图层
   * @param filter 可选的过滤器表达式
   * @returns IFeature 数组
   *
   * @note 坐标系统说明：
   * - 输入坐标为逻辑像素（与触摸事件坐标一致）
   * - 内部会自动乘以 pixelRatio 转换为物理像素传递给底层渲染引擎
   * - 这确保了在不同 DPI 设备上的查询准确性
   * - 保持与 handleMapClick 等方法的坐标处理一致性
   *
   * @example
  * ```typescript
   * // 查询矩形区域内的所有要素（逻辑像素坐标）
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
    filter?: NapiExpressionLiteral
  ): IFeature[] {
    if (this.destroyed) {
      console.warn('MapLibreMap', 'queryRenderedFeaturesForBox: Map is destroyed');
      return [];
    }

    try {
      // DPI 转换：逻辑像素 -> 物理像素
      const pixelRatio = this.nativeMapView.getPixelRatio();
      const physicalLeft = left * pixelRatio;
      const physicalTop = top * pixelRatio;
      const physicalRight = right * pixelRatio;
      const physicalBottom = bottom * pixelRatio;

      const features = this.nativeMapView.queryRenderedFeaturesForBox(
        physicalLeft, physicalTop, physicalRight, physicalBottom, layerIds, filter
      );
      return features as ESObject as IFeature[];
    } catch (error) {
      console.error('MapLibreMap', `queryRenderedFeaturesForBox failed: ${error.message}`);
      return [];
    }
  }

  /**
   * 查询数据源中的所有要素
   * 
   * 此方法查询指定数据源中的所有要素，不考虑这些要素是否已渲染。
   * 这对于 GeoJSON 数据源特别有用，可以获取所有添加到数据源的要素。
   * 
   * @param sourceId 数据源 ID
   * @param sourceLayerIds 可选的源图层 ID 数组（用于 vector tile 数据源）
   * @param filter 可选的过滤器表达式
   * @returns 查询到的要素数组
   * 
   * @example
  * ```typescript
   * // 查询 GeoJSON 数据源中的所有要素
   * const features = map.querySourceFeatures('my-source');
   *
   * // 查询 vector tile 数据源中特定图层的要素
   * const features = map.querySourceFeatures('composite', ['poi-label']);
   *
   * // 使用过滤器查询
   * const features = map.querySourceFeatures(
   *   'my-source',
   *   undefined,
   *   ['==', ['get', 'type'], 'restaurant']
   * );
   * ```
   */
  public querySourceFeatures(
    sourceId: string,
    sourceLayerIds?: string[],
    filter?: NapiExpressionLiteral
  ): IFeature[] {
    if (this.destroyed) {
      console.warn('MapLibreMap', 'querySourceFeatures: Map is destroyed');
      return [];
    }

    try {
      const features = this.nativeMapView.querySourceFeatures(
        sourceId,
        sourceLayerIds || undefined,
        filter || undefined
      );
      return features as Object as IFeature[];
    } catch (error) {
      console.error('MapLibreMap', `querySourceFeatures failed: ${error}`);
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

  // ========== 性能测量方法 (参考 Android) ==========

  /**
   * 设置 FPS 变化监听器（参考 Android MapLibreMap.setOnFpsChangedListener）
   * 用于实时监控渲染帧率
   * @param listener FPS 变化监听器，传入 null 则移除监听器
   */
  public setOnFpsChangedListener(listener: OnFpsChangedListener | null): void {
    if (this.destroyed) {
      console.warn('MapLibreMap', 'setOnFpsChangedListener: Map is destroyed');
      return;
    }

    try {
      if (listener === null) {
        this.nativeMapView.setOnFpsChangedListener(null);
      } else {
        this.nativeMapView.setOnFpsChangedListener((fps: number) => {
          listener.onFpsChanged(fps);
        });
      }
    } catch (error) {
      console.error('MapLibreMap', `setOnFpsChangedListener failed: ${error.message}`);
    }
  }

  // ========== 观察者事件监听器 (Shader, Glyph, Sprite, Tile) ==========
  
  /**
   * 添加着色器编译前监听器
   * @param listener 监听器对象或回调函数
   */
  public addOnPreCompileShaderListener(listener: OnPreCompileShaderListener | ((shaderId: number, backendType: number, defines: string) => void)): void {
    if (this.destroyed) return;
    
    // 如果是接口实现，转换为回调函数
    const callback = typeof listener === 'function' 
      ? listener 
      : (shaderId: number, backendType: number, defines: string) => (listener as OnPreCompileShaderListener).onPreCompileShader(shaderId, backendType, defines);
    
    this.nativeMapView.addOnPreCompileShaderListener(callback);
  }
  
  /**
   * 移除着色器编译前监听器
   */
  public removeOnPreCompileShaderListener(listener: OnPreCompileShaderListener | ((shaderId: number, backendType: number, defines: string) => void)): void {
    if (this.destroyed) return;
    
    // 如果是接口实现，转换为回调函数
    const callback = typeof listener === 'function' 
      ? listener 
      : (shaderId: number, backendType: number, defines: string) => (listener as OnPreCompileShaderListener).onPreCompileShader(shaderId, backendType, defines);
    
    this.nativeMapView.removeOnPreCompileShaderListener(callback);
  }
  
  /**
   * 添加着色器编译后监听器
   * @param listener 监听器对象或回调函数
   */
  public addOnPostCompileShaderListener(listener: OnPostCompileShaderListener | ((shaderId: number, backendType: number, defines: string) => void)): void {
    if (this.destroyed) return;
    
    const callback = typeof listener === 'function' 
      ? listener 
      : (shaderId: number, backendType: number, defines: string) => (listener as OnPostCompileShaderListener).onPostCompileShader(shaderId, backendType, defines);
    
    this.nativeMapView.addOnPostCompileShaderListener(callback);
  }
  
  /**
   * 移除着色器编译后监听器
   */
  public removeOnPostCompileShaderListener(listener: OnPostCompileShaderListener | ((shaderId: number, backendType: number, defines: string) => void)): void {
    if (this.destroyed) return;
    
    const callback = typeof listener === 'function' 
      ? listener 
      : (shaderId: number, backendType: number, defines: string) => (listener as OnPostCompileShaderListener).onPostCompileShader(shaderId, backendType, defines);
    
    this.nativeMapView.removeOnPostCompileShaderListener(callback);
  }
  
  /**
   * 添加着色器编译失败监听器
   * @param listener 监听器对象或回调函数
   */
  public addOnShaderCompileFailedListener(listener: OnShaderCompileFailedListener | ((shaderId: number, backendType: number, defines: string) => void)): void {
    if (this.destroyed) return;
    
    const callback = typeof listener === 'function' 
      ? listener 
      : (shaderId: number, backendType: number, defines: string) => (listener as OnShaderCompileFailedListener).onShaderCompileFailed(shaderId, backendType, defines);
    
    this.nativeMapView.addOnShaderCompileFailedListener(callback);
  }
  
  /**
   * 移除着色器编译失败监听器
   */
  public removeOnShaderCompileFailedListener(listener: OnShaderCompileFailedListener | ((shaderId: number, backendType: number, defines: string) => void)): void {
    if (this.destroyed) return;
    
    const callback = typeof listener === 'function' 
      ? listener 
      : (shaderId: number, backendType: number, defines: string) => (listener as OnShaderCompileFailedListener).onShaderCompileFailed(shaderId, backendType, defines);
    
    this.nativeMapView.removeOnShaderCompileFailedListener(callback);
  }
  
  /**
   * 添加字形请求监听器
   * @param listener 监听器对象或回调函数
   */
  public addOnGlyphsRequestedListener(listener: OnGlyphsRequestedListener | ((fontStack: string[], rangeStart: number, rangeEnd: number) => void)): void {
    if (this.destroyed) return;
    
    const callback = typeof listener === 'function' 
      ? listener 
      : (fontStack: string[], rangeStart: number, rangeEnd: number) => (listener as OnGlyphsRequestedListener).onGlyphsRequested(fontStack, rangeStart, rangeEnd);
    
    this.nativeMapView.addOnGlyphsRequestedListener(callback);
  }
  
  /**
   * 移除字形请求监听器
   */
  public removeOnGlyphsRequestedListener(listener: OnGlyphsRequestedListener | ((fontStack: string[], rangeStart: number, rangeEnd: number) => void)): void {
    if (this.destroyed) return;
    
    const callback = typeof listener === 'function' 
      ? listener 
      : (fontStack: string[], rangeStart: number, rangeEnd: number) => (listener as OnGlyphsRequestedListener).onGlyphsRequested(fontStack, rangeStart, rangeEnd);
    
    this.nativeMapView.removeOnGlyphsRequestedListener(callback);
  }
  
  /**
   * 添加字形加载完成监听器
   * @param listener 监听器对象或回调函数
   */
  public addOnGlyphsLoadedListener(listener: OnGlyphsLoadedListener | ((fontStack: string[], rangeStart: number, rangeEnd: number) => void)): void {
    if (this.destroyed) return;
    
    const callback = typeof listener === 'function' 
      ? listener 
      : (fontStack: string[], rangeStart: number, rangeEnd: number) => (listener as OnGlyphsLoadedListener).onGlyphsLoaded(fontStack, rangeStart, rangeEnd);
    
    this.nativeMapView.addOnGlyphsLoadedListener(callback);
  }
  
  /**
   * 移除字形加载完成监听器
   */
  public removeOnGlyphsLoadedListener(listener: OnGlyphsLoadedListener | ((fontStack: string[], rangeStart: number, rangeEnd: number) => void)): void {
    if (this.destroyed) return;
    
    const callback = typeof listener === 'function' 
      ? listener 
      : (fontStack: string[], rangeStart: number, rangeEnd: number) => (listener as OnGlyphsLoadedListener).onGlyphsLoaded(fontStack, rangeStart, rangeEnd);
    
    this.nativeMapView.removeOnGlyphsLoadedListener(callback);
  }
  
  /**
   * 添加字形加载错误监听器
   * @param listener 监听器对象或回调函数
   */
  public addOnGlyphsErrorListener(listener: OnGlyphsErrorListener | ((fontStack: string[], rangeStart: number, rangeEnd: number) => void)): void {
    if (this.destroyed) return;
    
    const callback = typeof listener === 'function' 
      ? listener 
      : (fontStack: string[], rangeStart: number, rangeEnd: number) => (listener as OnGlyphsErrorListener).onGlyphsError(fontStack, rangeStart, rangeEnd);
    
    this.nativeMapView.addOnGlyphsErrorListener(callback);
  }
  
  /**
   * 移除字形加载错误监听器
   */
  public removeOnGlyphsErrorListener(listener: OnGlyphsErrorListener | ((fontStack: string[], rangeStart: number, rangeEnd: number) => void)): void {
    if (this.destroyed) return;
    
    const callback = typeof listener === 'function' 
      ? listener 
      : (fontStack: string[], rangeStart: number, rangeEnd: number) => (listener as OnGlyphsErrorListener).onGlyphsError(fontStack, rangeStart, rangeEnd);
    
    this.nativeMapView.removeOnGlyphsErrorListener(callback);
  }
  
  /**
   * 添加 Sprite 请求监听器
   * @param listener 监听器对象或回调函数
   */
  public addOnSpriteRequestedListener(listener: OnSpriteRequestedListener | ((spriteId: string, url: string) => void)): void {
    if (this.destroyed) return;
    
    const callback = typeof listener === 'function' 
      ? listener 
      : (spriteId: string, url: string) => (listener as OnSpriteRequestedListener).onSpriteRequested(spriteId, url);
    
    this.nativeMapView.addOnSpriteRequestedListener(callback);
  }
  
  /**
   * 移除 Sprite 请求监听器
   */
  public removeOnSpriteRequestedListener(listener: OnSpriteRequestedListener | ((spriteId: string, url: string) => void)): void {
    if (this.destroyed) return;
    
    const callback = typeof listener === 'function' 
      ? listener 
      : (spriteId: string, url: string) => (listener as OnSpriteRequestedListener).onSpriteRequested(spriteId, url);
    
    this.nativeMapView.removeOnSpriteRequestedListener(callback);
  }
  
  /**
   * 添加 Sprite 加载完成监听器
   * @param listener 监听器对象或回调函数
   */
  public addOnSpriteLoadedListener(listener: OnSpriteLoadedListener | ((spriteId: string, url: string) => void)): void {
    if (this.destroyed) return;
    
    const callback = typeof listener === 'function' 
      ? listener 
      : (spriteId: string, url: string) => (listener as OnSpriteLoadedListener).onSpriteLoaded(spriteId, url);
    
    this.nativeMapView.addOnSpriteLoadedListener(callback);
  }
  
  /**
   * 移除 Sprite 加载完成监听器
   */
  public removeOnSpriteLoadedListener(listener: OnSpriteLoadedListener | ((spriteId: string, url: string) => void)): void {
    if (this.destroyed) return;
    
    const callback = typeof listener === 'function' 
      ? listener 
      : (spriteId: string, url: string) => (listener as OnSpriteLoadedListener).onSpriteLoaded(spriteId, url);
    
    this.nativeMapView.removeOnSpriteLoadedListener(callback);
  }
  
  /**
   * 添加 Sprite 加载错误监听器
   * @param listener 监听器对象或回调函数
   */
  public addOnSpriteErrorListener(listener: OnSpriteErrorListener | ((spriteId: string, url: string) => void)): void {
    if (this.destroyed) return;
    
    const callback = typeof listener === 'function' 
      ? listener 
      : (spriteId: string, url: string) => (listener as OnSpriteErrorListener).onSpriteError(spriteId, url);
    
    this.nativeMapView.addOnSpriteErrorListener(callback);
  }
  
  /**
   * 移除 Sprite 加载错误监听器
   */
  public removeOnSpriteErrorListener(listener: OnSpriteErrorListener | ((spriteId: string, url: string) => void)): void {
    if (this.destroyed) return;
    
    const callback = typeof listener === 'function' 
      ? listener 
      : (spriteId: string, url: string) => (listener as OnSpriteErrorListener).onSpriteError(spriteId, url);
    
    this.nativeMapView.removeOnSpriteErrorListener(callback);
  }
  
  /**
   * 添加瓦片操作监听器
   * @param listener 监听器对象或回调函数
   */
  public addOnTileActionListener(listener: OnTileActionListener | ((operation: number, x: number, y: number, z: number, wrap: number, overscaledZ: number, sourceId: string) => void)): void {
    if (this.destroyed) return;
    
    const callback = typeof listener === 'function' 
      ? listener 
      : (operation: number, x: number, y: number, z: number, wrap: number, overscaledZ: number, sourceId: string) => (listener as OnTileActionListener).onTileAction(operation, x, y, z, wrap, overscaledZ, sourceId);
    
    this.nativeMapView.addOnTileActionListener(callback);
  }
  
  /**
   * 移除瓦片操作监听器
   */
  public removeOnTileActionListener(listener: OnTileActionListener | ((operation: number, x: number, y: number, z: number, wrap: number, overscaledZ: number, sourceId: string) => void)): void {
    if (this.destroyed) return;
    
    const callback = typeof listener === 'function' 
      ? listener 
      : (operation: number, x: number, y: number, z: number, wrap: number, overscaledZ: number, sourceId: string) => (listener as OnTileActionListener).onTileAction(operation, x, y, z, wrap, overscaledZ, sourceId);
    
    this.nativeMapView.removeOnTileActionListener(callback);
  }

  /**
   * 设置最大帧率（参考 Android MapView.setMaximumFps）
   * @param maximumFps 最大帧率，例如 30、60
   */
  public setMaximumFps(maximumFps: number): void {
    if (this.destroyed) {
      console.warn('MapLibreMap', 'setMaximumFps: Map is destroyed');
      return;
    }

    try {
      this.nativeMapView.setMaximumFps(maximumFps);
    } catch (error) {
      console.error('MapLibreMap', `setMaximumFps failed: ${error.message}`);
    }
  }

  /**
   * 设置渲染刷新模式（参考 Android MapView.setRenderingRefreshMode）
   * @param mode 渲染模式：CONTINUOUS（持续渲染）或 WHEN_DIRTY（按需渲染）
   */
  public setRenderingRefreshMode(mode: RenderingRefreshMode): void {
    if (this.destroyed) {
      console.warn('MapLibreMap', 'setRenderingRefreshMode: Map is destroyed');
      return;
    }

    try {
      this.nativeMapView.setRenderingRefreshMode(mode);
    } catch (error) {
      console.error('MapLibreMap', `setRenderingRefreshMode failed: ${error.message}`);
    }
  }

  /**
   * 获取渲染刷新模式（参考 Android MapView.getRenderingRefreshMode）
   * @returns 当前渲染模式
   */
  public getRenderingRefreshMode(): RenderingRefreshMode {
    if (this.destroyed) {
      console.warn('MapLibreMap', 'getRenderingRefreshMode: Map is destroyed');
      return RenderingRefreshMode.WHEN_DIRTY;
    }

    try {
      return this.nativeMapView.getRenderingRefreshMode();
    } catch (error) {
      console.error('MapLibreMap', `getRenderingRefreshMode failed: ${error.message}`);
      return RenderingRefreshMode.WHEN_DIRTY;
    }
  }

  // ========== 兼容性方法 (从 NativeMapView 迁移) ==========

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
    if (this.destroyed) {
      return;
    }
    // 调用 native 层的 setContentPadding 方法
    // 注意：native 层的顺序是 [top, left, bottom, right]
    this.nativeMapView.setContentPadding([top, left, bottom, right]);
  }

  /**
   * 获取内容边距
   * @returns 边距数组 [top, left, bottom, right]
   */
  public getContentPadding(): number[] {
    if (this.destroyed) {
      return [0, 0, 0, 0];
    }
    try {
      // 从 native 层获取边距
      const padding: number[] = this.nativeMapView.getContentPadding();
      if (padding && Array.isArray(padding) && padding.length === 4) {
        // native 返回 [top, left, bottom, right]
        return padding;
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

  /**
   * 转换 Native LatLng 数组为 ETS LatLng 数组
   * @private
   */
  private convertNativeLatLngArray(nativeArray: import('libmaplibre.so').LatLng[]): LatLng[] {
    return nativeArray.map(native => LatLng.fromNative(native));
  }

  // ========== 调试功能（Debug Mode）==========

  /**
   * 设置调试选项
   * 使用 MapDebugOptions 枚举值的位掩码来启用多个调试功能
   *
   * 调试选项包括：
   * - TileBoundaries: 显示瓦片边界（红线）
   * - TileInfo: 显示瓦片坐标（x/y/z）
   * - Timestamps: 显示瓦片加载时间戳
   * - CollisionBoxes: 显示碰撞检测框（绿线）
   * - OverdrawVisualization: 过度绘制可视化
   *
   * @param debugOptions 调试选项的位掩码
   * @example
  * ```typescript
   * import { MapDebugOptions } from '@ohos/maplibre';
   *
   * // 启用多个调试选项
   * map.setDebugOptions(MapDebugOptions.TileBoundaries | MapDebugOptions.CollisionBoxes);
   *
   * // 禁用所有调试选项
   * map.setDebugOptions(MapDebugOptions.NoDebug);
   * ```
   */
  public setDebugOptions(debugOptions: number): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setDebug(debugOptions);
  }

  /**
   * 获取当前调试选项
   *
   * @returns 当前启用的调试选项位掩码
   * @example
  * ```typescript
   * const currentOptions = map.getDebugOptions();
   * console.log('Current debug options:', currentOptions);
   * ```
   */
  public getDebugOptions(): number {
    if (this.destroyed) {
      return 0;
    }
    return this.nativeMapView.getDebug();
  }

  /**
   * 快速开关调试模式（使用默认调试选项组合）
   *
   * 当启用调试模式时，会自动开启以下调试选项：
   * - 瓦片边界（TileBoundaries）
   * - 瓦片信息（TileInfo）  
   * - 碰撞框（CollisionBoxes）
   *
   * 这是最常用的调试选项组合，可以帮助诊断大多数渲染问题。
   *
   * @param active 是否启用调试模式
   * @example
  * ```typescript
   * // 快速启用调试模式
   * map.setDebugActive(true);
   *
   * // 检查状态
   * if (map.isDebugActive()) {
   *   console.log('Debug mode is active');
   * }
   *
   * // 关闭调试模式
   * map.setDebugActive(false);
   * ```
   */
  public setDebugActive(active: boolean): void {
    if (this.destroyed) {
      return;
    }
    this.nativeMapView.setDebugActive(active);
  }

  /**
   * 检查是否处于调试模式
   *
   * @returns 是否有任何调试选项被启用
   * @example
  * ```typescript
   * if (map.isDebugActive()) {
   *   console.log('Debug visualizations are currently enabled');
   * }
   * ```
   */
  public isDebugActive(): boolean {
    if (this.destroyed) {
      return false;
    }
    return this.nativeMapView.isDebugActive();
  }
}

