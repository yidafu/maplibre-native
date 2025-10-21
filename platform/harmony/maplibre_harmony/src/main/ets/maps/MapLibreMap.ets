import { NativeMapView } from './NativeMapView';
import { MapLibreMapOptions } from './MapLibreMapOptions';
import { CameraPosition } from './camera/CameraPosition';
import { LatLng } from './geometry/LatLng';
import { LatLngBounds } from './geometry/LatLngBounds';
import { Point } from './geometry/Point';
import { Rect } from './geometry/Rect';
import { Layer } from './style/layers/Layer';
import { Source } from './style/sources/Source';
import { Image } from './style/images/Image';
import { Feature } from './geojson/Feature';
import { TransitionOptions } from './style/layers/TransitionOptions';
import { Light } from './style/light/Light';
import { Marker } from './annotations/Marker';
import { Polyline } from './annotations/Polyline';
import { Polygon } from './annotations/Polygon';

/**
 * MapLibreMap - 主要的地图API类
 */
export class MapLibreMap {
  private nativeMapView: NativeMapView;
  private options: MapLibreMapOptions;
  private destroyed: boolean = false;

  constructor(nativeMapView: NativeMapView, options: MapLibreMapOptions) {
    this.nativeMapView = nativeMapView;
    this.options = options;
  }

  /**
   * 销毁地图
   */
  public destroy(): void {
    if (this.destroyed) {
      return;
    }
    this.destroyed = true;
    this.nativeMapView.destroy();
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
  public setStyleUri(url: string): void {
    if (this.destroyed) return;
    this.nativeMapView.setStyleUri(url);
  }

  public getStyleUri(): string {
    if (this.destroyed) return '';
    return this.nativeMapView.getStyleUri();
  }

  public setStyleJson(json: string): void {
    if (this.destroyed) return;
    this.nativeMapView.setStyleJson(json);
  }

  public getStyleJson(): string {
    if (this.destroyed) return '';
    return this.nativeMapView.getStyleJson();
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

  public easeTo(angle: number, latitude: number, longitude: number, duration: number, pitch: number, zoom: number, padding?: number[], easingInterpolator?: boolean): void {
    if (this.destroyed) return;
    this.nativeMapView.easeTo(angle, latitude, longitude, duration, pitch, zoom, padding, easingInterpolator);
  }

  public flyTo(angle: number, latitude: number, longitude: number, duration: number, pitch: number, zoom: number, padding?: number[]): void {
    if (this.destroyed) return;
    this.nativeMapView.flyTo(angle, latitude, longitude, duration, pitch, zoom, padding);
  }

  // 位置和相机
  public getLatLng(): LatLng {
    if (this.destroyed) return new LatLng(0, 0)
    return this.nativeMapView.getLatLng();
  }

  public setLatLng(latitude: number, longitude: number, padding?: number[], duration?: number): void {
    if (this.destroyed) return;
    this.nativeMapView.setLatLng(latitude, longitude, padding, duration);
  }

  public getCameraForLatLngBounds(bounds: LatLngBounds, top: number, left: number, bottom: number, right: number, bearing?: number, tilt?: number): CameraPosition {
    if (this.destroyed) return null;
    return this.nativeMapView.getCameraForLatLngBounds(bounds, top, left, bottom, right, bearing, tilt);
  }

  public getCameraForGeometry(geometry: any, top: number, left: number, bottom: number, right: number, bearing?: number, tilt?: number): CameraPosition {
    if (this.destroyed) return null;
    return this.nativeMapView.getCameraForGeometry(geometry, top, left, bottom, right, bearing, tilt);
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
  public getCameraPosition(): CameraPosition {
    if (this.destroyed) return null;
    return this.nativeMapView.getCameraPosition();
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

  public projectedMetersForLatLng(latitude: number, longitude: number): any {
    if (this.destroyed) return null;
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
  public queryPointAnnotations(rect: Rect): number[] {
    if (this.destroyed) return [];
    return this.nativeMapView.queryPointAnnotations(rect);
  }

  public queryShapeAnnotations(rect: Rect): number[] {
    if (this.destroyed) return [];
    return this.nativeMapView.queryShapeAnnotations(rect);
  }

  public queryRenderedFeaturesForPoint(x: number, y: number, layerIds?: string[], filter?: any): Feature[] {
    if (this.destroyed) return [];
    return this.nativeMapView.queryRenderedFeaturesForPoint(x, y, layerIds, filter);
  }

  public queryRenderedFeaturesForBox(left: number, top: number, right: number, bottom: number, layerIds?: string[], filter?: any): Feature[] {
    if (this.destroyed) return [];
    return this.nativeMapView.queryRenderedFeaturesForBox(left, top, right, bottom, layerIds, filter);
  }

  // 光照
  public getLight(): Light {
    if (this.destroyed) return null;
    return this.nativeMapView.getLight();
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
  public addImage(name: string, bitmap: any, pixelRatio: number, sdf: boolean): void {
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

  public getImage(name: string): any {
    if (this.destroyed) return null;
    return this.nativeMapView.getImage(name);
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
}
