import maplibre from 'libmaplibre_native.so';
import { MapLibreMapOptions } from './MapLibreMapOptions';
import { CameraPosition } from './camera/CameraPosition';
import { LatLng } from './geometry/LatLng';
import { LatLngBounds } from './geometry/LatLngBounds';
import { Point } from './geometry/Point';
// Rect 类型已在 maplibre NAPI 中定义
import { Layer } from './style/layers/Layer';
import { Source } from './style/sources/Source';
import { Image } from './style/images/Image';
import { Feature } from './geojson/Feature';
import { TransitionOptions } from './style/layers/TransitionOptions';
import { Light } from './style/light/Light';
import { Marker } from './annotations/Marker';
import { Polyline } from './annotations/Polyline';
import { Polygon } from './annotations/Polygon';
import { MarkerManager } from './annotations/MarkerManager';
import { MarkerOptions } from './annotations/MarkerOptions';
import { Annotation } from './annotations/Annotation';
import { OnMarkerClickListener } from './listeners/OnMarkerClickListener';
import { OnMarkerDragListener } from './listeners/OnMarkerDragListener';
import { OnInfoWindowClickListener } from './listeners/OnInfoWindowClickListener';
import { InfoWindowAdapter } from './annotations/InfoWindowAdapter';
import { Style } from './style/Style';

/**
 * MapLibreMap - 主要的地图API类
 */
export class MapLibreMap {
  private nativeMapView: maplibre.NativeMapView;
  private options: MapLibreMapOptions;
  private destroyed: boolean = false;
  private markerManager: MarkerManager;
  private style: Style | null = null;
  private styleLoaded: boolean = false;

  constructor(nativeMapView: maplibre.NativeMapView, options: MapLibreMapOptions) {
    this.nativeMapView = nativeMapView;
    this.options = options;
    this.markerManager = new MarkerManager(this);
    
    // 初始化Style对象（需要等待样式加载完成）
    this.initializeStyle();
  }

  /**
   * 初始化样式对象
   */
  private initializeStyle(): void {
    try {
      // 获取native map指针
      const nativePtr = this.nativeMapView.getNativePtr ? this.nativeMapView.getNativePtr() : 0;
      this.style = new Style(nativePtr);
    } catch (error) {
      console.error(`Failed to initialize style: ${error}`);
    }
  }

  /**
   * 标记样式已加载（由外部调用，通常在样式加载完成回调中）
   */
  public onStyleLoaded(): void {
    this.styleLoaded = true;
    if (this.style) {
      this.style.setFullyLoaded(true);
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
    if (this.style) {
      this.style.setFullyLoaded(false);
    }
  }

  public getStyleUrl(): string {
    if (this.destroyed) return '';
    return this.nativeMapView.getStyleUrl();
  }

  public setStyleJson(json: string): void {
    if (this.destroyed) return;
    this.nativeMapView.setStyleJson(json);
    this.styleLoaded = false;
    if (this.style) {
      this.style.setFullyLoaded(false);
    }
  }

  public getStyleJson(): string {
    if (this.destroyed) return '';
    return this.nativeMapView.getStyleJson();
  }

  /**
   * 获取样式对象
   * 
   * @returns Style对象，如果样式未加载则返回null
   */
  public getStyle(): Style | null {
    if (this.destroyed) return null;
    if (!this.styleLoaded) {
      console.warn('Style is not fully loaded yet');
    }
    return this.style;
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
  public updateMarker(markerId: number, lat: number, lon: number, iconId: string): void {
    if (this.destroyed) return;
    this.nativeMapView.updateMarker(markerId, lat, lon, iconId);
  }

  public addMarkers(markers: Marker[]): number[] {
    if (this.destroyed) return [];
    return this.nativeMapView.addMarkers(markers);
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
  public removeAnnotation(annotation: Annotation): void {
    if (this.destroyed) return;
    
    if (annotation instanceof Marker) {
      this.markerManager.removeMarker(annotation as Marker);
    } else {
      // 对于其他类型的 Annotation（Polyline, Polygon），调用原有方法
      const id = annotation.getId();
      if (id !== -1) {
        this.removeAnnotations([id]);
      }
    }
  }
  
  /**
   * 批量移除 Annotation
   * 
   * @param annotations Annotation 数组
   */
  public removeAnnotationsBatch(annotations: Annotation[]): void {
    if (this.destroyed) return;
    
    const markers: Marker[] = [];
    const otherIds: number[] = [];
    
    for (const annotation of annotations) {
      if (annotation instanceof Marker) {
        markers.push(annotation as Marker);
      } else {
        const id = annotation.getId();
        if (id !== -1) {
          otherIds.push(id);
        }
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
   * 设置 InfoWindow 点击监听器
   * 
   * @param listener 监听器实例
   */
  public setOnInfoWindowClickListener(listener: OnInfoWindowClickListener | null): void {
    if (this.destroyed) return;
    this.markerManager.setOnInfoWindowClickListener(listener);
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
}
