import maplibre from 'libmaplibre_native.so';
import { MapLibreMapOptions } from './MapLibreMapOptions';
import { CameraPosition } from './camera/CameraPosition';
import { LatLng } from './geometry/LatLng';
import { LatLngBounds } from './geometry/LatLngBounds';
import { Point } from './geometry/Point';
import { Layer } from './style/layers/Layer';
import { Source } from './style/sources/Source';
import { Image } from './style/images/Image';
import { Feature } from './geojson/Feature';
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
  
  // Style 监听器
  private styleLoadedListeners: OnStyleLoadedListener[] = [];
  private styleLoadErrorListeners: OnStyleLoadErrorListener[] = [];
  
  // 操作队列 - 在样式加载前缓存操作
  private pendingOperations: PendingOperation[] = [];

  constructor(nativeMapView: maplibre.NativeMapView, options: MapLibreMapOptions) {
    this.nativeMapView = nativeMapView;
    this.options = options;
    this.markerManager = new MarkerManager(this);
    this.infoWindowManager = new InfoWindowManager();
    this.annotationViewManager = new AnnotationViewManager();
    
    // 设置 AnnotationViewManager 的 NativeMapView
    this.annotationViewManager.setNativeMapView(nativeMapView);
    
    // 设置 Native 层的样式监听器
    this.setupNativeStyleListeners();
    
    // 设置相机移动监听器，自动更新 InfoWindow 位置
    this.setupInfoWindowCameraListener();
    
    // 设置相机移动监听器，自动更新 AnnotationView 位置
    this.setupAnnotationViewCameraListener();
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
    this.cameraChangeDispatcher.addOnCameraMoveListener({
      onCameraMove: () => {
        // 地图相机移动时，更新所有 InfoWindow 的位置
        const screenWidth = this.nativeMapView.getWidth();
        const screenHeight = this.nativeMapView.getHeight();
        
        this.infoWindowManager.updatePositions(
          screenWidth,
          screenHeight,
          (marker: Marker) => {
            const pos = marker.getPosition();
            return this.pixelForLatLng(pos.latitude, pos.longitude);
          }
        );
      }
    });
  }
  
  /**
   * 设置 AnnotationView 相机移动监听器
   * 当地图相机移动时，自动更新所有 AnnotationView 的位置
   * @private
   */
  private setupAnnotationViewCameraListener(): void {
    this.cameraChangeDispatcher.addOnCameraMoveListener({
      onCameraMove: () => {
        // 地图相机移动时，更新所有 AnnotationView 的位置
        this.annotationViewManager.updateAllPositions();
      }
    });
  }

  /**
   * 标记样式已加载（由外部调用，通常在样式加载完成回调中）
   */
  public onStyleLoaded(): void {
    this.styleLoaded = true;
    
    // 获取样式对象
    const style = this.getStyle();
    
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
    if (style && this.styleLoadedListeners.length > 0) {
      console.info(`MapLibreMap: Notifying ${this.styleLoadedListeners.length} style loaded listeners`);
      this.styleLoadedListeners.forEach(listener => {
        try {
          listener.onStyleLoaded(style);
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
   * 调整视图大小
   */
  public resizeView(width: number, height: number): void {
    if (this.destroyed) return;
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
   * @returns Style对象（NAPI 对象），如果样式未加载则返回null
   */
  public getStyle(): Style | null {
    if (this.destroyed) return null;
    try {
      // 从 NativeMapView 获取 Style NAPI 对象
      const style = this.nativeMapView.getStyle() as Style;
      if (!this.styleLoaded) {
        console.warn('Style is not fully loaded yet');
      }
      return style;
    } catch (error) {
      console.error(`Failed to get style: ${error}`);
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
    if (this.destroyed) return { latitude: 0, longitude: 0 };
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

  public resetNorth(): void {
    if (this.destroyed) return;
    this.nativeMapView.resetNorth();
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
  public updateMarker(marker: Marker): void {
    if (this.destroyed) return;
    this.nativeMapView.updateMarker(marker);
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
  public getMetersPerPixelAtLatitude(latitude: number, zoom: number): number {
    if (this.destroyed) return 0;
    return this.nativeMapView.getMetersPerPixelAtLatitude(latitude, zoom);
  }

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
    if (this.destroyed) return { latitude: 0, longitude: 0 };
    return this.nativeMapView.latLngForProjectedMeters(northing, easting);
  }

  public latLngForPixel(x: number, y: number): LatLng {
    if (this.destroyed) return { latitude: 0, longitude: 0 };
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

  // 图层
  public getLayers(): Layer[] {
    if (this.destroyed) return [];
    return this.nativeMapView.getLayers();
  }

  public getLayer(layerId: string): Layer | null {
    if (this.destroyed) return null;
    return this.nativeMapView.getLayer(layerId);
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

  public removeLayer(layer: Layer): boolean {
    if (this.destroyed) return false;
    return this.nativeMapView.removeLayer(layer);
  }

  // 数据源
  public getSources(): Source[] {
    if (this.destroyed) return [];
    return this.nativeMapView.getSources();
  }

  public getSource(sourceId: string): Source | null {
    if (this.destroyed) return null;
    return this.nativeMapView.getSource(sourceId);
  }

  public addSource(source: Source): void {
    if (this.destroyed) return;
    this.nativeMapView.addSource(source);
  }

  public removeSource(source: Source): boolean {
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
   * @returns 创建的 Marker
   */
  public addMarker(options: MarkerOptions): Marker {
    if (this.destroyed) {
      throw new Error('Map has been destroyed');
    }
    return this.markerManager.addMarker(options);
  }
  
  /**
   * 批量添加 Marker
   * 
   * @param optionsList MarkerOptions 数组
   * @returns 创建的 Marker 数组
   */
  public addMarkersBatch(optionsList: MarkerOptions[]): Marker[] {
    if (this.destroyed) return [];
    return this.markerManager.addMarkers(optionsList);
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
        const style = this.getStyle();
        if (style) {
          try {
            listener.onStyleLoaded(style);
          } catch (error) {
            console.error(`MapLibreMap: Error in onStyleLoaded listener: ${error}`);
          }
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
  
  // ========== InfoWindow 管理方法 ==========
  
  /**
   * 获取 InfoWindowManager 实例
   * @returns InfoWindowManager 实例
   */
  public getInfoWindowManager(): InfoWindowManager {
    return this.infoWindowManager;
  }
  
  /**
   * 设置 InfoWindowAdapter
   * 用于自定义 InfoWindow 的显示内容
   * 
   * @param adapter InfoWindowAdapter 实例，传 null 则使用默认样式
   */
  public setInfoWindowAdapter(adapter: InfoWindowAdapter | null): void {
    if (this.destroyed) return;
    this.infoWindowManager.setAdapter(adapter);
  }
  
  /**
   * 获取 InfoWindowAdapter
   * @returns InfoWindowAdapter 实例或 null
   */
  public getInfoWindowAdapter(): InfoWindowAdapter | null {
    if (this.destroyed) return null;
    return this.infoWindowManager.getAdapter();
  }
  
  /**
   * 设置 InfoWindow 点击监听器
   * 
   * @param listener OnInfoWindowClickListener 实例
   */
  public setOnInfoWindowClickListener(listener: OnInfoWindowClickListener | null): void {
    if (this.destroyed) return;
    this.infoWindowManager.setOnClickListener(listener);
  }
  
  /**
   * 获取 InfoWindow 点击监听器
   * @returns OnInfoWindowClickListener 实例或 null
   */
  public getOnInfoWindowClickListener(): OnInfoWindowClickListener | null {
    if (this.destroyed) return null;
    return this.infoWindowManager.getOnClickListener();
  }
  
  /**
   * 设置 InfoWindow 长按监听器
   * 
   * @param listener OnInfoWindowLongClickListener 实例
   */
  public setOnInfoWindowLongClickListener(listener: OnInfoWindowLongClickListener | null): void {
    if (this.destroyed) return;
    this.infoWindowManager.setOnLongClickListener(listener);
  }
  
  /**
   * 获取 InfoWindow 长按监听器
   * @returns OnInfoWindowLongClickListener 实例或 null
   */
  public getOnInfoWindowLongClickListener(): OnInfoWindowLongClickListener | null {
    if (this.destroyed) return null;
    return this.infoWindowManager.getOnLongClickListener();
  }
  
  /**
   * 设置 InfoWindow 关闭监听器
   * 
   * @param listener OnInfoWindowCloseListener 实例
   */
  public setOnInfoWindowCloseListener(listener: OnInfoWindowCloseListener | null): void {
    if (this.destroyed) return;
    this.infoWindowManager.setOnCloseListener(listener);
  }
  
  /**
   * 获取 InfoWindow 关闭监听器
   * @returns OnInfoWindowCloseListener 实例或 null
   */
  public getOnInfoWindowCloseListener(): OnInfoWindowCloseListener | null {
    if (this.destroyed) return null;
    return this.infoWindowManager.getOnCloseListener();
  }
  
  /**
   * 设置是否允许多个 InfoWindow 同时显示
   * 
   * @param allow true 表示允许多个同时显示，false 表示同时只能显示一个
   */
  public setAllowConcurrentMultipleInfoWindows(allow: boolean): void {
    if (this.destroyed) return;
    this.infoWindowManager.setAllowConcurrentMultiple(allow);
  }
  
  /**
   * 是否允许多个 InfoWindow 同时显示
   * @returns true 表示允许多个同时显示
   */
  public isAllowConcurrentMultipleInfoWindows(): boolean {
    if (this.destroyed) return false;
    return this.infoWindowManager.isAllowConcurrentMultiple();
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
