import { Component, Container, Window, Surface, Size, Point, Rect, EdgeInsets } from '@kit.ArkUI';
import { NativeMap } from "./NativeMap"
import { MapLibreMapOptions } from './MapLibreMapOptions';
import { MapRenderer } from './renderer/MapRenderer';
import { FileSource } from '../storage/FileSource';
import { LatLng } from './geometry/LatLng';
import { LatLngBounds } from './geometry/LatLngBounds';
import { ProjectedMeters } from './geometry/ProjectedMeters';
import { CameraPosition } from './camera/CameraPosition';
import { Marker } from './annotations/Marker';
import { Polyline } from './annotations/Polyline';
import { Polygon } from './annotations/Polygon';
import { Feature } from '../geojson/Feature';
import { Geometry } from '../geojson/Geometry';
import { Layer } from '../style/layers/Layer';
import { Source } from '../style/sources/Source';
import { Image } from '../style/images/Image';
import { TransitionOptions } from '../style/layers/TransitionOptions';
import { Light } from '../style/light/Light';
import { NativeMapOptions } from './NativeMapOptions';
import { ViewCallback } from './ViewCallback';
import { StateCallback } from './StateCallback';
import { SnapshotReadyCallback } from './SnapshotReadyCallback';
import { OnFpsChangedListener } from './OnFpsChangedListener';

/**
 * NativeMapView组件 - 实现NativeMap接口
 */
export class NativeMapView extends Container implements NativeMap {
  // 成员变量
  private nativePtr: number = 0;
  private destroyed: boolean = false;
  private pixelRatio: number = 1.0;
  private fileSource: FileSource;
  private mapRenderer: MapRenderer;
  private edgeInsets: number[] | null = null;
  private stateCallback: StateCallback | null = null;
  private snapshotReadyCallback: SnapshotReadyCallback | null = null;
  private viewCallback: ViewCallback | null = null;
  private thread: Thread | null = null;

  /**
   * 构造函数
   * @param context 上下文
   * @param viewCallback 视图回调
   * @param stateCallback 状态回调
   * @param mapRenderer 地图渲染器
   */
  constructor(
    context: any,
    viewCallback: ViewCallback,
    stateCallback: StateCallback,
    mapRenderer: MapRenderer
  ) {
    super();
    this.mapRenderer = mapRenderer;
    this.viewCallback = viewCallback;
    this.fileSource = FileSource.getInstance(context);
    this.pixelRatio = 1.0; // 默认像素比
    this.thread = Thread.currentThread();
    this.stateCallback = stateCallback;
    this.nativeInitialize(this, this.fileSource, this.mapRenderer, new NativeMapOptions());
  }

  /**
   * 检查状态是否有效
   * @param callingMethod 调用方法名
   * @returns 是否已销毁
   */
  private checkState(callingMethod: string): boolean {
    // 检查线程
    if (this.thread && this.thread !== Thread.currentThread()) {
      throw new Error(`Map interactions should happen on the UI thread. Method invoked from wrong thread is ${callingMethod}.`);
    }

    // 检查是否已销毁
    if (this.destroyed && callingMethod) {
      console.error(`You're calling \`${callingMethod}\` after the \`MapView\` was destroyed, were you invoking it after \`onDestroy()\`?`);
    }
    return this.destroyed;
  }

  // NativeMap接口方法实现
  destroy(): void {
    if (this.checkState("destroy")) {
      return;
    }
    this.destroyed = true;
    this.viewCallback = null;
    this.nativeDestroy();
  }

  resizeView(width: number, height: number): void {
    if (this.checkState("resizeView")) {
      return;
    }
    width = Math.ceil(width / this.pixelRatio);
    height = Math.ceil(height / this.pixelRatio);

    // 处理边界情况
    if (width < 0) {
      console.error(`Device returned a negative width size, setting value to 0 instead of ${width}`);
      width = 0;
    }
    if (height < 0) {
      console.error(`Device returned a negative height size, setting value to 0 instead of ${height}`);
      height = 0;
    }
    if (width > 65535) {
      console.error(`Device returned an out of range width size, capping value at 65535 instead of ${width}`);
      width = 65535;
    }
    if (height > 65535) {
      console.error(`Device returned an out of range height size, capping value at 65535 instead of ${height}`);
      height = 65535;
    }

    this.nativeResizeView(width, height);
  }

  setStyleUri(url: string): void {
    if (this.checkState("setStyleUri")) {
      return;
    }
    this.nativeSetStyleUrl(url);
  }

  getStyleUri(): string {
    if (this.checkState("getStyleUri")) {
      return '';
    }
    return this.nativeGetStyleUrl();
  }

  setStyleJson(json: string): void {
    if (this.checkState("setStyleJson")) {
      return;
    }
    this.nativeSetStyleJson(json);
  }

  getStyleJson(): string {
    if (this.checkState("getStyleJson")) {
      return '';
    }
    return this.nativeGetStyleJson();
  }

  setLatLngBounds(bounds: LatLngBounds): void {
    if (this.checkState("setLatLngBounds")) {
      return;
    }
    this.nativeSetLatLngBounds(bounds);
  }

  cancelTransitions(): void {
    if (this.checkState("cancelTransitions")) {
      return;
    }
    this.nativeCancelTransitions();
  }

  setGestureInProgress(inProgress: boolean): void {
    if (this.checkState("setGestureInProgress")) {
      return;
    }
    this.nativeSetGestureInProgress(inProgress);
  }

  setPixelRatio(pixelRatio: number): void {
    if (this.checkState("setPixelRatio")) {
      return;
    }
    this.pixelRatio = pixelRatio;
  }

  getPixelRatio(): number {
    if (this.checkState("getPixelRatio")) {
      return 0;
    }
    return this.pixelRatio;
  }

  moveBy(dx: number, dy: number, duration: number): void {
    if (this.checkState("moveBy")) {
      return;
    }

    try {
      this.nativeMoveBy(dx / this.pixelRatio, dy / this.pixelRatio, duration);
    } catch (error) {
      // workaround for latitude must not be NaN issue
      console.debug("Error when executing NativeMapView#moveBy", error);
    }
  }

  setLatLng(latitude: number, longitude: number, padding?: number[], duration?: number): void {
    if (this.checkState("setLatLng")) {
      return;
    }
    this.nativeSetLatLng(latitude, longitude, this.getAnimationPaddingAndClearCachedInsets(padding), duration || 0);
  }

  getLatLng(): LatLng {
    if (this.checkState("getLatLng")) {
      return { latitude: 0, longitude: 0 };
    }
    return this.nativeGetLatLng();
  }

  getCameraForLatLngBounds(
    bounds: LatLngBounds,
    top: number,
    left: number,
    bottom: number,
    right: number,
    bearing?: number,
    tilt?: number
  ): CameraPosition {
    if (this.checkState("getCameraForLatLngBounds")) {
      return null;
    }
    return this.nativeGetCameraForLatLngBounds(
      bounds,
      top / this.pixelRatio,
      left / this.pixelRatio,
      bottom / this.pixelRatio,
      right / this.pixelRatio,
      bearing || 0,
      tilt || 0
    );
  }

  getCameraForGeometry(
    geometry: Geometry,
    top: number,
    left: number,
    bottom: number,
    right: number,
    bearing?: number,
    tilt?: number
  ): CameraPosition {
    if (this.checkState("getCameraForGeometry")) {
      return null;
    }
    return this.nativeGetCameraForGeometry(
      geometry,
      top / this.pixelRatio,
      left / this.pixelRatio,
      bottom / this.pixelRatio,
      right / this.pixelRatio,
      bearing || 0,
      tilt || 0
    );
  }

  resetPosition(): void {
    if (this.checkState("resetPosition")) {
      return;
    }
    this.nativeResetPosition();
  }

  getPitch(): number {
    if (this.checkState("getPitch")) {
      return 0;
    }
    return this.nativeGetPitch();
  }

  setPitch(pitch: number, duration?: number): void {
    if (this.checkState("setPitch")) {
      return;
    }
    this.nativeSetPitch(pitch, duration || 0);
  }

  setZoom(zoom: number, cx?: number, cy?: number, duration?: number): void {
    if (this.checkState("setZoom")) {
      return;
    }
    this.nativeSetZoom(zoom, cx ? cx / this.pixelRatio : 0, cy ? cy / this.pixelRatio : 0, duration || 0);
  }

  getZoom(): number {
    if (this.checkState("getZoom")) {
      return 0;
    }
    return this.nativeGetZoom();
  }

  resetZoom(): void {
    if (this.checkState("resetZoom")) {
      return;
    }
    this.nativeResetZoom();
  }

  setMinZoom(zoom: number): void {
    if (this.checkState("setMinZoom")) {
      return;
    }
    this.nativeSetMinZoom(zoom);
  }

  getMinZoom(): number {
    if (this.checkState("getMinZoom")) {
      return 0;
    }
    return this.nativeGetMinZoom();
  }

  setMaxZoom(zoom: number): void {
    if (this.checkState("setMaxZoom")) {
      return;
    }
    this.nativeSetMaxZoom(zoom);
  }

  getMaxZoom(): number {
    if (this.checkState("getMaxZoom")) {
      return 0;
    }
    return this.nativeGetMaxZoom();
  }

  setMinPitch(pitch: number): void {
    if (this.checkState("setMinPitch")) {
      return;
    }
    this.nativeSetMinPitch(pitch);
  }

  getMinPitch(): number {
    if (this.checkState("getMinPitch")) {
      return 0;
    }
    return this.nativeGetMinPitch();
  }

  setMaxPitch(pitch: number): void {
    if (this.checkState("setMaxPitch")) {
      return;
    }
    this.nativeSetMaxPitch(pitch);
  }

  getMaxPitch(): number {
    if (this.checkState("getMaxPitch")) {
      return 0;
    }
    return this.nativeGetMaxPitch();
  }

  rotateBy(sx: number, sy: number, ex: number, ey: number, duration?: number): void {
    if (this.checkState("rotateBy")) {
      return;
    }
    this.nativeRotateBy(sx / this.pixelRatio, sy / this.pixelRatio, ex, ey, duration || 0);
  }

  setContentPadding(left: number, top: number, right: number, bottom: number): void {
    if (this.checkState("setContentPadding")) {
      return;
    }
    this.edgeInsets = [left, top, right, bottom];
  }

  getContentPadding(): EdgeInsets {
    if (this.checkState("getContentPadding")) {
      return { left: 0, top: 0, right: 0, bottom: 0 };
    }
    // if cached insets are not applied yet, return them, otherwise, get the padding from the camera
    if (this.edgeInsets !== null) {
      return { left: this.edgeInsets[0], top: this.edgeInsets[1], right: this.edgeInsets[2], bottom: this.edgeInsets[3] };
    }
    const cameraPosition = this.getCameraPosition();
    return cameraPosition ? cameraPosition.padding : { left: 0, top: 0, right: 0, bottom: 0 };
  }

  setBearing(degrees: number, duration?: number): void {
    if (this.checkState("setBearing")) {
      return;
    }
    this.nativeSetBearing(degrees, duration || 0);
  }

  setBearingXY(degrees: number, fx: number, fy: number, duration?: number): void {
    if (this.checkState("setBearingXY")) {
      return;
    }
    this.nativeSetBearingXY(degrees, fx / this.pixelRatio, fy / this.pixelRatio, duration || 0);
  }

  getBearing(): number {
    if (this.checkState("getBearing")) {
      return 0;
    }
    return this.nativeGetBearing();
  }

  resetNorth(): void {
    if (this.checkState("resetNorth")) {
      return;
    }
    this.nativeResetNorth();
  }

  // 注解相关方法
  addMarkers(markers: Marker[]): number[] {
    if (this.checkState("addMarkers")) {
      return [];
    }
    return this.nativeAddMarkers(markers);
  }

  addPolylines(polylines: Polyline[]): number[] {
    if (this.checkState("addPolylines")) {
      return [];
    }
    return this.nativeAddPolylines(polylines);
  }

  addPolygons(polygons: Polygon[]): number[] {
    if (this.checkState("addPolygons")) {
      return [];
    }
    return this.nativeAddPolygons(polygons);
  }

  removeAnnotations(ids: number[]): void {
    if (this.checkState("removeAnnotations")) {
      return;
    }
    this.nativeRemoveAnnotations(ids);
  }

  updateMarker(markerId: number, lat: number, lon: number, iconId: string): void {
    if (this.checkState("updateMarker")) {
      return;
    }
    this.nativeUpdateMarker(markerId, lat, lon, iconId);
  }

  updatePolygon(polygonId: number, polygon: Polygon): void {
    if (this.checkState("updatePolygon")) {
      return;
    }
    this.nativeUpdatePolygon(polygonId, polygon);
  }

  updatePolyline(polylineId: number, polyline: Polyline): void {
    if (this.checkState("updatePolyline")) {
      return;
    }
    this.nativeUpdatePolyline(polylineId, polyline);
  }

  queryPointAnnotations(rect: Rect): number[] {
    if (this.checkState("queryPointAnnotations")) {
      return [];
    }
    return this.nativeQueryPointAnnotations(rect);
  }

  queryShapeAnnotations(rect: Rect): number[] {
    if (this.checkState("queryShapeAnnotations")) {
      return [];
    }
    return this.nativeQueryShapeAnnotations(rect);
  }

  addAnnotationIcon(symbol: string, width: number, height: number, scale: number, pixels: Uint8Array): void {
    if (this.checkState("addAnnotationIcon")) {
      return;
    }
    this.nativeAddAnnotationIcon(symbol, width, height, scale, pixels);
  }

  removeAnnotationIcon(symbol: string): void {
    if (this.checkState("removeAnnotationIcon")) {
      return;
    }
    this.nativeRemoveAnnotationIcon(symbol);
  }

  // 地图视图控制
  setVisibleCoordinateBounds(coordinates: LatLng[], padding: Rect, direction: number, duration: number): void {
    if (this.checkState("setVisibleCoordinateBounds")) {
      return;
    }
    this.nativeSetVisibleCoordinateBounds(coordinates, padding, direction, duration);
  }

  onLowMemory(): void {
    if (this.checkState("onLowMemory")) {
      return;
    }
    this.nativeOnLowMemory();
  }

  setDebug(debug: boolean): void {
    if (this.checkState("setDebug")) {
      return;
    }
    this.nativeSetDebug(debug);
  }

  getDebug(): boolean {
    if (this.checkState("getDebug")) {
      return false;
    }
    return this.nativeGetDebug();
  }

  // 动作日志
  getActionJournalLogFiles(): string[] {
    if (this.checkState("getActionJournalLogFiles")) {
      return [];
    }
    return this.nativeGetActionJournalLogFiles();
  }

  getActionJournalLog(): string[] {
    if (this.checkState("getActionJournalLog")) {
      return [];
    }
    return this.nativeGetActionJournalLog();
  }

  clearActionJournalLog(): void {
    if (this.checkState("clearActionJournalLog")) {
      return;
    }
    this.nativeClearActionJournalLog();
  }

  // 加载状态
  isFullyLoaded(): boolean {
    if (this.checkState("isFullyLoaded")) {
      return false;
    }
    return this.nativeIsFullyLoaded();
  }

  setReachability(status: boolean): void {
    if (this.checkState("setReachability")) {
      return;
    }
    this.nativeSetReachability(status);
  }

  // 坐标转换
  getMetersPerPixelAtLatitude(latitude: number, zoom: number): number {
    if (this.checkState("getMetersPerPixelAtLatitude")) {
      return 0;
    }
    return this.nativeGetMetersPerPixelAtLatitude(latitude, zoom);
  }

  projectedMetersForLatLng(latitude: number, longitude: number): ProjectedMeters {
    if (this.checkState("projectedMetersForLatLng")) {
      return null;
    }
    return this.nativeProjectedMetersForLatLng(latitude, longitude);
  }

  latLngForProjectedMeters(northing: number, easting: number): LatLng {
    if (this.checkState("latLngForProjectedMeters")) {
      return { latitude: 0, longitude: 0 };
    }
    return this.nativeLatLngForProjectedMeters(northing, easting);
  }

  pixelForLatLng(latitude: number, longitude: number): Point {
    if (this.checkState("pixelForLatLng")) {
      return { x: 0, y: 0 };
    }
    const point = this.nativePixelForLatLng(latitude, longitude);
    return { x: point.x * this.pixelRatio, y: point.y * this.pixelRatio };
  }

  latLngForPixel(x: number, y: number): LatLng {
    if (this.checkState("latLngForPixel")) {
      return { latitude: 0, longitude: 0 };
    }
    return this.nativeLatLngForPixel(x / this.pixelRatio, y / this.pixelRatio);
  }

  getVisibleCoordinateBounds(): LatLng[] {
    if (this.checkState("getVisibleCoordinateBounds")) {
      return [];
    }
    const output: number[] = [];
    this.nativeGetVisibleCoordinateBounds(output);
    // 这里需要根据output数组重新构建LatLng数组
    const bounds: LatLng[] = [];
    // 实现略，需要根据具体的数据结构转换
    return bounds;
  }

  // 像素和坐标批量转换
  pixelsForLatLngs(input: number[], output: number[]): void {
    if (!this.checkState("pixelsForLatLngs")) {
      this.nativePixelsForLatLngs(input, output, this.pixelRatio);
    }
  }

  latLngsForPixels(input: number[], output: number[]): void {
    if (!this.checkState("latLngsForPixels")) {
      this.nativeLatLngsForPixels(input, output, this.pixelRatio);
    }
  }

  // 注解偏移
  getTopOffsetPixelsForAnnotationSymbol(symbolName: string): number {
    if (this.checkState("getTopOffsetPixelsForAnnotationSymbol")) {
      return 0;
    }
    return this.nativeGetTopOffsetPixelsForAnnotationSymbol(symbolName);
  }

  // 相机动画
  jumpTo(angle: number, latitude: number, longitude: number, pitch: number, zoom: number, padding?: number[]): void {
    if (this.checkState("jumpTo")) {
      return;
    }
    this.nativeJumpTo(angle, latitude, longitude, pitch, zoom, this.getAnimationPaddingAndClearCachedInsets(padding));
  }

  easeTo(
    angle: number,
    latitude: number,
    longitude: number,
    duration: number,
    pitch: number,
    zoom: number,
    padding?: number[],
    easingInterpolator?: boolean
  ): void {
    if (this.checkState("easeTo")) {
      return;
    }
    this.nativeEaseTo(angle, latitude, longitude, duration, pitch, zoom, 
      this.getAnimationPaddingAndClearCachedInsets(padding), easingInterpolator || false);
  }

  flyTo(
    angle: number,
    latitude: number,
    longitude: number,
    duration: number,
    pitch: number,
    zoom: number,
    padding?: number[]
  ): void {
    if (this.checkState("flyTo")) {
      return;
    }
    this.nativeFlyTo(angle, latitude, longitude, duration, pitch, zoom, 
      this.getAnimationPaddingAndClearCachedInsets(padding));
  }

  getCameraPosition(): CameraPosition {
    if (this.checkState("getCameraPosition")) {
      return null;
    }
    const position = this.nativeGetCameraPosition();
    // 如果有缓存的padding，应用到camera position
    if (this.edgeInsets !== null && position) {
      return { ...position, padding: { left: this.edgeInsets[0], top: this.edgeInsets[1], right: this.edgeInsets[2], bottom: this.edgeInsets[3] } };
    }
    return position;
  }

  // 过渡动画
  setTransitionOptions(options: TransitionOptions): void {
    if (this.checkState("setTransitionOptions")) {
      return;
    }
    this.nativeSetTransitionOptions(options);
  }

  getTransitionOptions(): TransitionOptions {
    if (this.checkState("getTransitionOptions")) {
      return { duration: 0, delay: 0 };
    }
    return this.nativeGetTransitionOptions();
  }

  getTransitionDuration(): number {
    if (this.checkState("getTransitionDuration")) {
      return 0;
    }
    return this.nativeGetTransitionDuration();
  }

  setTransitionDuration(duration: number): void {
    if (this.checkState("setTransitionDuration")) {
      return;
    }
    this.nativeSetTransitionDuration(duration);
  }

  getTransitionDelay(): number {
    if (this.checkState("getTransitionDelay")) {
      return 0;
    }
    return this.nativeGetTransitionDelay();
  }

  setTransitionDelay(delay: number): void {
    if (this.checkState("setTransitionDelay")) {
      return;
    }
    this.nativeSetTransitionDelay(delay);
  }

  // 样式图层
  getLayers(): Layer[] {
    if (this.checkState("getLayers")) {
      return [];
    }
    return this.nativeGetLayers();
  }

  getLayer(layerId: string): Layer | null {
    if (this.checkState("getLayer")) {
      return null;
    }
    return this.nativeGetLayer(layerId);
  }

  addLayer(layer: Layer): void {
    if (this.checkState("addLayer")) {
      return;
    }
    this.nativeAddLayer(layer.getNativePtr(), null);
  }

  addLayerBelow(layer: Layer, belowLayerId: string): void {
    if (this.checkState("addLayerBelow")) {
      return;
    }
    this.nativeAddLayer(layer.getNativePtr(), belowLayerId);
  }

  addLayerAbove(layer: Layer, aboveLayerId: string): void {
    if (this.checkState("addLayerAbove")) {
      return;
    }
    this.nativeAddLayerAbove(layer.getNativePtr(), aboveLayerId);
  }

  addLayerAt(layer: Layer, index: number): void {
    if (this.checkState("addLayerAt")) {
      return;
    }
    this.nativeAddLayerAt(layer.getNativePtr(), index);
  }

  removeLayer(layerId: string): boolean {
    if (this.checkState("removeLayer")) {
      return false;
    }
    // 这里可能需要根据具体实现调整
    return false;
  }

  removeLayer(layer: Layer): boolean {
    if (this.checkState("removeLayer")) {
      return false;
    }
    return this.nativeRemoveLayer(layer.getNativePtr());
  }

  removeLayerAt(index: number): boolean {
    if (this.checkState("removeLayerAt")) {
      return false;
    }
    return this.nativeRemoveLayerAt(index);
  }

  // 数据源
  getSources(): Source[] {
    if (this.checkState("getSources")) {
      return [];
    }
    return this.nativeGetSources();
  }

  getSource(sourceId: string): Source | null {
    if (this.checkState("getSource")) {
      return null;
    }
    return this.nativeGetSource(sourceId);
  }

  addSource(source: Source): void {
    if (this.checkState("addSource")) {
      return;
    }
    this.nativeAddSource(source, source.getNativePtr());
  }

  removeSource(sourceId: string): boolean {
    if (this.checkState("removeSource")) {
      return false;
    }
    // 这里可能需要根据具体实现调整
    return false;
  }

  removeSource(source: Source): boolean {
    if (this.checkState("removeSource")) {
      return false;
    }
    return this.nativeRemoveSource(source, source.getNativePtr());
  }

  // 图片
  addImages(images: Image[]): void {
    if (this.checkState("addImages")) {
      return;
    }
    this.nativeAddImages(images);
  }

  removeImage(name: string): void {
    if (this.checkState("removeImage")) {
      return;
    }
    this.nativeRemoveImage(name);
  }

  getImage(name: string): ImageBitmap | null {
    if (this.checkState("getImage")) {
      return null;
    }
    return this.nativeGetImage(name);
  }

  // 特性查询
  queryRenderedFeatures(coordinates: Point, layerIds?: string[], filter?: any): Feature[] {
    if (this.checkState("queryRenderedFeatures")) {
      return [];
    }
    return this.nativeQueryRenderedFeaturesForPoint(
      coordinates.x / this.pixelRatio,
      coordinates.y / this.pixelRatio,
      layerIds || [],
      filter
    );
  }

  queryRenderedFeatures(coordinates: Rect, layerIds?: string[], filter?: any): Feature[] {
    if (this.checkState("queryRenderedFeatures")) {
      return [];
    }
    return this.nativeQueryRenderedFeaturesForBox(
      coordinates.left / this.pixelRatio,
      coordinates.top / this.pixelRatio,
      coordinates.right / this.pixelRatio,
      coordinates.bottom / this.pixelRatio,
      layerIds || [],
      filter
    );
  }

  // 光照
  getLight(): Light {
    if (this.checkState("getLight")) {
      return null;
    }
    return this.nativeGetLight();
  }

  // 缓存和预加载
  setPrefetchTiles(enable: boolean): void {
    if (this.checkState("setPrefetchTiles")) {
      return;
    }
    this.nativeSetPrefetchTiles(enable);
  }

  getPrefetchTiles(): boolean {
    if (this.checkState("getPrefetchTiles")) {
      return false;
    }
    return this.nativeGetPrefetchTiles();
  }

  setPrefetchZoomDelta(delta: number): void {
    if (this.checkState("setPrefetchZoomDelta")) {
      return;
    }
    this.nativeSetPrefetchZoomDelta(delta);
  }

  getPrefetchZoomDelta(): number {
    if (this.checkState("getPrefetchZoomDelta")) {
      return 0;
    }
    return this.nativeGetPrefetchZoomDelta();
  }

  setTileCacheEnabled(enabled: boolean): void {
    if (this.checkState("setTileCacheEnabled")) {
      return;
    }
    this.nativeSetTileCacheEnabled(enabled);
  }

  getTileCacheEnabled(): boolean {
    if (this.checkState("getTileCacheEnabled")) {
      return false;
    }
    return this.nativeGetTileCacheEnabled();
  }

  // 图层细节级别
  setTileLodMinRadius(radius: number): void {
    if (this.checkState("setTileLodMinRadius")) {
      return;
    }
    this.nativeSetTileLodMinRadius(radius);
  }

  getTileLodMinRadius(): number {
    if (this.checkState("getTileLodMinRadius")) {
      return 0;
    }
    return this.nativeGetTileLodMinRadius();
  }

  setTileLodScale(scale: number): void {
    if (this.checkState("setTileLodScale")) {
      return;
    }
    this.nativeSetTileLodScale(scale);
  }

  getTileLodScale(): number {
    if (this.checkState("getTileLodScale")) {
      return 0;
    }
    return this.nativeGetTileLodScale();
  }

  setTileLodPitchThreshold(threshold: number): void {
    if (this.checkState("setTileLodPitchThreshold")) {
      return;
    }
    this.nativeSetTileLodPitchThreshold(threshold);
  }

  getTileLodPitchThreshold(): number {
    if (this.checkState("getTileLodPitchThreshold")) {
      return 0;
    }
    return this.nativeGetTileLodPitchThreshold();
  }

  setTileLodZoomShift(shift: number): void {
    if (this.checkState("setTileLodZoomShift")) {
      return;
    }
    this.nativeSetTileLodZoomShift(shift);
  }

  getTileLodZoomShift(): number {
    if (this.checkState("getTileLodZoomShift")) {
      return 0;
    }
    return this.nativeGetTileLodZoomShift();
  }

  // 渲染控制
  triggerRepaint(): void {
    if (this.checkState("triggerRepaint")) {
      return;
    }
    this.nativeTriggerRepaint();
  }

  isRenderingStatsViewEnabled(): boolean {
    if (this.checkState("isRenderingStatsViewEnabled")) {
      return false;
    }
    return this.nativeIsRenderingStatsViewEnabled();
  }

  enableRenderingStatsView(enabled: boolean): void {
    if (this.checkState("enableRenderingStatsView")) {
      return;
    }
    this.nativeEnableRenderingStatsView(enabled);
  }

  // 快照
  addSnapshotCallback(callback: SnapshotReadyCallback): void {
    if (this.checkState("addSnapshotCallback")) {
      return;
    }
    this.snapshotReadyCallback = callback;
    this.nativeTakeSnapshot();
  }

  // 帧率监听
  setOnFpsChangedListener(listener: OnFpsChangedListener | null): void {
    // 空实现
  }

  // API基础URL设置
  setApiBaseUrl(baseUrl: string): void {
    // 空实现
  }

  // 交换行为设置
  setSwapBehaviorFlush(flush: boolean): void {
    // 空实现
  }

  // 密度相关矩形
  getDensityDependantRectangle(rectangle: Rect): Rect {
    if (this.checkState("getDensityDependantRectangle")) {
      return rectangle;
    }
    // 简单实现，可能需要根据具体需求调整
    return {
      left: rectangle.left / this.pixelRatio,
      top: rectangle.top / this.pixelRatio,
      right: rectangle.right / this.pixelRatio,
      bottom: rectangle.bottom / this.pixelRatio
    };
  }

  // 获取原生指针
  getNativePtr(): number {
    return this.nativePtr;
  }

  // 检查是否已销毁
  isDestroyed(): boolean {
    return this.destroyed;
  }

  // 内部辅助方法
  private getAnimationPaddingAndClearCachedInsets(padding?: number[]): number[] {
    let resultPadding: number[] = [0, 0, 0, 0];
    
    if (padding) {
      resultPadding = padding;
    } else if (this.edgeInsets) {
      resultPadding = this.edgeInsets;
      this.edgeInsets = null;
    }
    
    return resultPadding;
  }

  // Native方法声明
  private nativeInitialize(nativeMap: NativeMapView, fileSource: FileSource, mapRenderer: MapRenderer, nativeOptions: NativeMapOptions): void;
  private nativeDestroy(): void;
  private nativeResizeView(width: number, height: number): void;
  private nativeSetStyleUrl(url: string): void;
  private nativeGetStyleUrl(): string;
  private nativeSetStyleJson(newStyleJson: string): void;
  private nativeGetStyleJson(): string;
  private nativeSetLatLngBounds(latLngBounds: LatLngBounds): void;
  private nativeCancelTransitions(): void;
  private nativeSetGestureInProgress(inProgress: boolean): void;
  private nativeMoveBy(dx: number, dy: number, duration: number): void;
  private nativeSetLatLng(latitude: number, longitude: number, padding: number[], duration: number): void;
  private nativeGetLatLng(): LatLng;
  private nativeGetCameraForLatLngBounds(bounds: LatLngBounds, top: number, left: number, bottom: number, right: number, bearing: number, tilt: number): CameraPosition;
  private nativeGetCameraForGeometry(geometry: Geometry, top: number, left: number, bottom: number, right: number, bearing: number, tilt: number): CameraPosition;
  private nativeResetPosition(): void;
  private nativeGetPitch(): number;
  private nativeSetPitch(pitch: number, duration: number): void;
  private nativeSetZoom(zoom: number, cx: number, cy: number, duration: number): void;
  private nativeGetZoom(): number;
  private nativeResetZoom(): void;
  private nativeSetMinZoom(zoom: number): void;
  private nativeGetMinZoom(): number;
  private nativeSetMaxZoom(zoom: number): void;
  private nativeGetMaxZoom(): number;
  private nativeSetMinPitch(pitch: number): void;
  private nativeGetMinPitch(): number;
  private nativeSetMaxPitch(pitch: number): void;
  private nativeGetMaxPitch(): number;
  private nativeRotateBy(sx: number, sy: number, ex: number, ey: number, duration: number): void;
  private nativeSetBearing(degrees: number, duration: number): void;
  private nativeSetBearingXY(degrees: number, fx: number, fy: number, duration: number): void;
  private nativeGetBearing(): number;
  private nativeResetNorth(): void;
  private nativeUpdateMarker(markerId: number, lat: number, lon: number, iconId: string): void;
  private nativeAddMarkers(markers: Marker[]): number[];
  private nativeAddPolylines(polylines: Polyline[]): number[];
  private nativeAddPolygons(polygons: Polygon[]): number[];
  private nativeRemoveAnnotations(id: number[]): void;
  private nativeQueryPointAnnotations(rect: Rect): number[];
  private nativeQueryShapeAnnotations(rect: Rect): number[];
  private nativeAddAnnotationIcon(symbol: string, width: number, height: number, scale: number, pixels: Uint8Array): void;
  private nativeRemoveAnnotationIcon(symbol: string): void;
  private nativeSetVisibleCoordinateBounds(coordinates: LatLng[], padding: Rect, direction: number, duration: number): void;
  private nativeOnLowMemory(): void;
  private nativeSetDebug(debug: boolean): void;
  private nativeGetDebug(): boolean;
  private nativeGetActionJournalLogFiles(): string[];
  private nativeGetActionJournalLog(): string[];
  private nativeClearActionJournalLog(): void;
  private nativeIsFullyLoaded(): boolean;
  private nativeSetReachability(status: boolean): void;
  private nativeGetMetersPerPixelAtLatitude(lat: number, zoom: number): number;
  private nativeProjectedMetersForLatLng(latitude: number, longitude: number): ProjectedMeters;
  private nativeLatLngForProjectedMeters(northing: number, easting: number): LatLng;
  private nativePixelForLatLng(lat: number, lon: number): Point;
  private nativePixelsForLatLngs(input: number[], output: number[], pixelRatio: number): void;
  private nativeGetVisibleCoordinateBounds(output: number[]): void;
  private nativeLatLngForPixel(x: number, y: number): LatLng;
  private nativeLatLngsForPixels(input: number[], output: number[], pixelRatio: number): void;
  private nativeGetTopOffsetPixelsForAnnotationSymbol(symbolName: string): number;
  private nativeJumpTo(angle: number, latitude: number, longitude: number, pitch: number, zoom: number, padding: number[]): void;
  private nativeEaseTo(angle: number, latitude: number, longitude: number, duration: number, pitch: number, zoom: number, padding: number[], easingInterpolator: boolean): void;
  private nativeFlyTo(angle: number, latitude: number, longitude: number, duration: number, pitch: number, zoom: number, padding: number[]): void;
  private nativeGetCameraPosition(): CameraPosition;
  private nativeSetTransitionOptions(transitionOptions: TransitionOptions): void;
  private nativeGetTransitionOptions(): TransitionOptions;
  private nativeGetTransitionDuration(): number;
  private nativeSetTransitionDuration(duration: number): void;
  private nativeGetTransitionDelay(): number;
  private nativeSetTransitionDelay(delay: number): void;
  private nativeGetLayers(): Layer[];
  private nativeGetLayer(layerId: string): Layer | null;
  private nativeAddLayer(layerPtr: number, before: string): void;
  private nativeAddLayerAbove(layerPtr: number, above: string): void;
  private nativeAddLayerAt(layerPtr: number, index: number): void;
  private nativeRemoveLayer(layerId: number): boolean;
  private nativeRemoveLayerAt(index: number): boolean;
  private nativeGetSources(): Source[];
  private nativeGetSource(sourceId: string): Source | null;
  private nativeAddSource(source: Source, sourcePtr: number): void;
  private nativeRemoveSource(source: Source, sourcePtr: number): boolean;
  private nativeAddImage(name: string, bitmap: any, pixelRatio: number, sdf: boolean): void;
  private nativeAddImages(images: Image[]): void;
  private nativeRemoveImage(name: string): void;
  private nativeGetImage(name: string): ImageBitmap | null;
  private nativeUpdatePolygon(polygonId: number, polygon: Polygon): void;
  private nativeUpdatePolyline(polylineId: number, polyline: Polyline): void;
  private nativeTakeSnapshot(): void;
  private nativeQueryRenderedFeaturesForPoint(x: number, y: number, layerIds: string[], filter: any): Feature[];
  private nativeQueryRenderedFeaturesForBox(left: number, top: number, right: number, bottom: number, layerIds: string[], filter: any): Feature[];
  private nativeGetLight(): Light;
  private nativeSetPrefetchTiles(enable: boolean): void;
  private nativeGetPrefetchTiles(): boolean;
  private nativeSetPrefetchZoomDelta(delta: number): void;
  private nativeSetTileCacheEnabled(enabled: boolean): void;
  private nativeGetTileCacheEnabled(): boolean;
  private nativeGetPrefetchZoomDelta(): number;
  private nativeSetTileLodMinRadius(radius: number): void;
  private nativeGetTileLodMinRadius(): number;
  private nativeSetTileLodScale(scale: number): void;
  private nativeGetTileLodScale(): number;
  private nativeSetTileLodPitchThreshold(threshold: number): void;
  private nativeGetTileLodPitchThreshold(): number;
  private nativeSetTileLodZoomShift(shift: number): void;
  private nativeGetTileLodZoomShift(): number;
  private nativeTriggerRepaint(): void;
  private nativeIsRenderingStatsViewEnabled(): boolean;
  private nativeEnableRenderingStatsView(enabled: boolean): void;
}