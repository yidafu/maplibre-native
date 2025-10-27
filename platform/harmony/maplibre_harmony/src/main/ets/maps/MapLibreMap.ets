import maplibre from 'libmaplibre_native.so';
import { MapLibreMapOptions } from './MapLibreMapOptions';
import { CameraPosition } from './camera/CameraPosition';
import { LatLng } from './geometry/LatLng';
import { LatLngBounds } from './geometry/LatLngBounds';
import { Point } from './geometry/Point';
// Layer 和 Source 现在通过 maplibre.XXXLayer / maplibre.XXXSource 访问
// import { Layer } from './style/layers/Layer';
// import { Source } from './style/sources/Source';
import { Image } from './style/images/Image';
import { Feature } from './geojson';
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
import { LocationComponent } from './location/LocationComponent';

// Marker 和 Style 现在由 NAPI 提供
type Marker = maplibre.Marker;
type Style = maplibre.Style;

/**
 * 操作队列项类型
 */
type PendingOperation = () => void;

/**
 * MapLibreMap - 主要的地图API类
 */
export class MapLibreMap {
  private nativeMapView: maplibre.NativeMapView;
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

  constructor(nativeMapView: maplibre.NativeMapView, options: MapLibreMapOptions) {
    this.nativeMapView = nativeMapView;
    this.options = options;
    this.markerManager = new MarkerManager(this);
    this.infoWindowManager = new InfoWindowManager();
    this.annotationViewManager = new AnnotationViewManager();
    this.locationComponent = new LocationComponent(this);
    
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
   * 设置 AnnotationView 相机移动监听器
   * 当地图相机移动时，自动更新所有 AnnotationView 的位置
   * @private
   */
  private setupAnnotationViewCameraListener(): void {
    class AnnotationViewMoveListenerImpl implements OnCameraMoveListener {
      parent: MapLibreMap;
      
      constructor(parent: MapLibreMap) {
        this.parent = parent;
      }
      
      onCameraMove(): void {
        // 地图相机移动时，更新所有 AnnotationView 的位置
        this.parent.annotationViewManager.updateAllPositions();
      }
    }
    const annotationViewMoveListener = new AnnotationViewMoveListenerImpl(this);
    this.cameraChangeDispatcher.addOnCameraMoveListener(annotationViewMoveListener);
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
      }
    }
    this.cameraChangeDispatcher.addOnCameraMoveListener(new ScaleBarMoveListenerImpl(this));
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
   * 销毁地图
   */
  public destroy(): void {
    if (this.destroyed) {
      return;
    }
    this.destroyed = true;
    
    // 销毁位置组件
    this.locationComponent.onDestroy();
    
    // NativeMapView 没有 destroy 方法，资源由系统管理
    // this.nativeMapView.destroy();
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
   * 调整视图大小
   */
  public resizeView(width: number, height: number): void {
    if (this.destroyed) return;
    // 保存尺寸
    this.viewWidth = width;
    this.viewHeight = height;
    this.nativeMapView.resizeView(width, height);
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
   * @returns Style 对象，如果地图未初始化或样式未加载则返回 null
   */
  public getStyle(): Style | null {
    if (this.destroyed) return null;
    if (!this.nativeMapView) return null;
    
    try {
      return this.nativeMapView.getStyle();
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

  public easeTo(options: maplibre.CameraOptions, duration: number): void {
    if (this.destroyed) return;
    this.nativeMapView.easeTo(options, duration);
  }

  public flyTo(options: maplibre.CameraOptions, duration: number): void {
    if (this.destroyed) return;
    this.nativeMapView.flyTo(options, duration);
  }

  // 位置和相机
  public getLatLng(): LatLng {
    if (this.destroyed) return new maplibre.LatLng(0, 0);
    return this.nativeMapView.getLatLng();
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
  public setVisibleCoordinateBounds(coordinates: LatLng[], padding: maplibre.Rect, direction: number, duration: number): void {
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
  public getCameraPosition(): ESObject | null {
    if (this.destroyed) return null;
    const result: ESObject = this.nativeMapView.getCameraPosition() as ESObject;
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
    
    // 直接传递 NAPI Marker 对象数组
    const ids = this.nativeMapView.addMarkers(markers);
    
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
  public projectedMetersForLatLng(latitude: number, longitude: number): maplibre.ProjectedMeters {
    if (this.destroyed) return { northing: 0, easting: 0 };
    return this.nativeMapView.projectedMetersForLatLng(latitude, longitude);
  }

  public pixelForLatLng(latitude: number, longitude: number): Point {
    if (this.destroyed) return { x: 0, y: 0 };
    return this.nativeMapView.pixelForLatLng(latitude, longitude);
  }

  public pixelsForLatLngs(input: number[], output: number[]): void {
    if (this.destroyed) return;
    this.nativeMapView.pixelsForLatLngs(input, output);
  }

  public latLngForProjectedMeters(northing: number, easting: number): LatLng {
    if (this.destroyed) return new maplibre.LatLng(0, 0);
    return this.nativeMapView.latLngForProjectedMeters(northing, easting);
  }

  public latLngForPixel(x: number, y: number): LatLng {
    if (this.destroyed) return new maplibre.LatLng(0, 0);
    return this.nativeMapView.latLngForPixel(x, y);
  }

  public latLngsForPixels(input: number[], output: number[]): void {
    if (this.destroyed) return;
    this.nativeMapView.latLngsForPixels(input, output);
  }

  // 过渡
  public getTransitionOptions(): TransitionOptions {
    if (this.destroyed) return { duration: 0, delay: 0 };
    return this.nativeMapView.getTransitionOptions();
  }

  public setTransitionOptions(options: TransitionOptions): void {
    if (this.destroyed) return;
    this.nativeMapView.setTransitionOptions(options);
  }

  // 查询
  public queryPointAnnotations(rect: maplibre.Rect): number[] {
    if (this.destroyed) return [];
    return this.nativeMapView.queryPointAnnotations(rect);
  }

  public queryShapeAnnotations(rect: maplibre.Rect): number[] {
    if (this.destroyed) return [];
    return this.nativeMapView.queryShapeAnnotations(rect);
  }

  public queryRenderedFeaturesForPoint(x: number, y: number, layerIds?: string[], filter?: ESObject): Feature[] {
    if (this.destroyed) return [];
    const results: ESObject[] = this.nativeMapView.queryRenderedFeaturesForPoint(x, y, layerIds, filter) as ESObject[];
    return results as Feature[];
  }

  public queryRenderedFeaturesForBox(left: number, top: number, right: number, bottom: number, layerIds?: string[], filter?: ESObject): Feature[] {
    if (this.destroyed) return [];
    const results: ESObject[] = this.nativeMapView.queryRenderedFeaturesForBox(left, top, right, bottom, layerIds, filter) as ESObject[];
    return results as Feature[];
  }

  // 光照
  public getLight(): Light | null {
    if (this.destroyed) return null;
    const result: ESObject = this.nativeMapView.getLight() as ESObject;
    return result as Light;
  }

  // 图层（使用 any 类型因为 Layer 类型未导出）
  public getLayers(): object[] {
    if (this.destroyed) return [];
    return this.nativeMapView.getLayers();
  }

  public getLayer(layerId: string): object | null {
    if (this.destroyed) return null;
    return this.nativeMapView.getLayer(layerId);
  }

  public addLayer(layer: object): void {
    if (this.destroyed) return;
    this.nativeMapView.addLayer(layer);
  }

  public addLayerAbove(layer: object, aboveLayerId: string): void {
    if (this.destroyed) return;
    this.nativeMapView.addLayerAbove(layer, aboveLayerId);
  }

  public addLayerAt(layer: object, index: number): void {
    if (this.destroyed) return;
    this.nativeMapView.addLayerAt(layer, index);
  }

  public removeLayerAt(index: number): boolean {
    if (this.destroyed) return false;
    return this.nativeMapView.removeLayerAt(index);
  }

  public removeLayer(layer: object): boolean {
    if (this.destroyed) return false;
    return this.nativeMapView.removeLayer(layer);
  }

  // 数据源（使用 object 类型因为 Source 类型未导出）
  public getSources(): object[] {
    if (this.destroyed) return [];
    return this.nativeMapView.getSources();
  }

  public getSource(sourceId: string): object | null {
    if (this.destroyed) return null;
    return this.nativeMapView.getSource(sourceId);
  }

  public addSource(source: object): void {
    if (this.destroyed) return;
    this.nativeMapView.addSource(source);
  }

  public removeSource(source: object): boolean {
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

  public getImage(name: string): ESObject | null {
    if (this.destroyed) return null;
    const result: ESObject = this.nativeMapView.getImage(name) as ESObject;
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
  public getNativeMapView(): maplibre.NativeMapView {
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
}

