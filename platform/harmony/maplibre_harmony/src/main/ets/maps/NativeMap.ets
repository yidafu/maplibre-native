import { Feature, Polygon, } from 'geojson';
import maplibre from 'libmaplibre_native.so';
// Marker 现在由 NAPI 提供
type Marker = maplibre.Marker;
import { CameraPosition } from './camera/CameraPosition';
import { LatLng } from './geometry/LatLng';
import { LatLngBounds } from './geometry/LatLngBounds';
import { OnFpsChangedListener } from './OnFpsChangedListener';
import { SnapshotReadyCallback } from './SnapshotReadyCallback';
import { Layer } from './style/layers/Layer';
import { Source } from './style/sources/Source';

/**
 * NativeMap接口定义
 */
export interface NativeMap {
  // 基础方法
  destroy(): void;
  resizeView(width: number, height: number): void;
  setStyleUri(url: string): void;
  getStyleUri(): string;
  setStyleJson(json: string): void;
  getStyleJson(): string;
  setLatLngBounds(bounds: LatLngBounds): void;
  cancelTransitions(): void;
  setGestureInProgress(inProgress: boolean): void;
  getPixelRatio(): number;
  
  // 相机控制
  moveBy(dx: number, dy: number, duration: number): void;
  setLatLng(latitude: number, longitude: number, padding?: number[], duration?: number): void;
  getLatLng(): LatLng;
  getCameraForLatLngBounds(
    bounds: LatLngBounds,
    top: number,
    left: number,
    bottom: number,
    right: number,
    bearing?: number,
    tilt?: number
  ): CameraPosition;
  getCameraForGeometry(
    geometry: Geometry,
    top: number,
    left: number,
    bottom: number,
    right: number,
    bearing?: number,
    tilt?: number
  ): CameraPosition;
  resetPosition(): void;
  getPitch(): number;
  setPitch(pitch: number, duration?: number): void;
  setZoom(zoom: number, cx?: number, cy?: number, duration?: number): void;
  getZoom(): number;
  resetZoom(): void;
  setMinZoom(zoom: number): void;
  getMinZoom(): number;
  setMaxZoom(zoom: number): void;
  getMaxZoom(): number;
  setMinPitch(pitch: number): void;
  getMinPitch(): number;
  setMaxPitch(pitch: number): void;
  getMaxPitch(): number;
  rotateBy(sx: number, sy: number, ex: number, ey: number, duration?: number): void;
  setBearing(degrees: number, duration?: number): void;
  setBearingXY(degrees: number, fx: number, fy: number, duration?: number): void;
  getBearing(): number;
  resetNorth(): void;
  
  // 地图交互
  setContentPadding(left: number, top: number, right: number, bottom: number): void;
  getContentPadding(): EdgeInsets;
  
  // 动画方法
  jumpTo(angle: number, latitude: number, longitude: number, pitch: number, zoom: number, padding?: number[]): void;
  easeTo(
    angle: number,
    latitude: number,
    longitude: number,
    duration: number,
    pitch: number,
    zoom: number,
    padding?: number[],
    easingInterpolator?: boolean
  ): void;
  flyTo(
    angle: number,
    latitude: number,
    longitude: number,
    duration: number,
    pitch: number,
    zoom: number,
    padding?: number[]
  ): void;
  getCameraPosition(): CameraPosition;
  
  // 过渡动画
  setTransitionOptions(options: TransitionOptions): void;
  getTransitionOptions(): TransitionOptions;
  getTransitionDuration(): number;
  setTransitionDuration(duration: number): void;
  getTransitionDelay(): number;
  setTransitionDelay(delay: number): void;
  
  // 样式API
  getLayers(): Layer[];
  getLayer(layerId: string): Layer | null;
  addLayer(layer: Layer): void;
  addLayerBelow(layer: Layer, belowLayerId: string): void;
  addLayerAbove(layer: Layer, aboveLayerId: string): void;
  addLayerAt(layer: Layer, index: number): void;
  removeLayer(layerId: string): boolean;
  removeLayer(layer: Layer): boolean;
  removeLayerAt(index: number): boolean;
  
  // 数据源API
  getSources(): Source[];
  getSource(sourceId: string): Source | null;
  addSource(source: Source): void;
  removeSource(sourceId: string): boolean;
  removeSource(source: Source): boolean;
  
  // 图片API
  addImages(images: Image[]): void;
  removeImage(name: string): void;
  getImage(name: string): ImageBitmap | null;
  
  // 特性查询
  queryRenderedFeatures(coordinates: Point, layerIds?: string[], filter?: Expression): Feature[];
  queryRenderedFeatures(coordinates: Rect, layerIds?: string[], filter?: Expression): Feature[];
  
  // 缓存和预加载
  setPrefetchTiles(enable: boolean): void;
  getPrefetchTiles(): boolean;
  setPrefetchZoomDelta(delta: number): void;
  getPrefetchZoomDelta(): number;
  setTileCacheEnabled(enabled: boolean): void;
  getTileCacheEnabled(): boolean;
  
  // 图层细节级别
  setTileLodMinRadius(radius: number): void;
  getTileLodMinRadius(): number;
  setTileLodScale(scale: number): void;
  getTileLodScale(): number;
  setTileLodPitchThreshold(threshold: number): void;
  getTileLodPitchThreshold(): number;
  setTileLodZoomShift(shift: number): void;
  getTileLodZoomShift(): number;
  
  // 光照
  getLight(): Light;
  
  // 渲染控制
  triggerRepaint(): void;
  isRenderingStatsViewEnabled(): boolean;
  enableRenderingStatsView(enabled: boolean): void;
  
  // 快照
  addSnapshotCallback(callback: SnapshotReadyCallback): void;
  
  // 调试
  getDebug(): boolean;
  setDebug(debug: boolean): void;
  
  // 工具方法
  getMetersPerPixelAtLatitude(latitude: number, zoom: number): number;
  projectedMetersForLatLng(latitude: number, longitude: number): ProjectedMeters;
  latLngForProjectedMeters(northing: number, easting: number): LatLng;
  pixelForLatLng(latitude: number, longitude: number): Point;
  latLngForPixel(x: number, y: number): LatLng;
  getVisibleCoordinateBounds(): LatLng[];
  setVisibleCoordinateBounds(coordinates: LatLng[], padding: Rect, direction: number, duration: number): void;
  
  // 注解
  addMarkers(markers: Marker[]): number[];
  addPolylines(polylines: Polyline[]): number[];
  addPolygons(polygons: Polygon[]): number[];
  removeAnnotations(ids: number[]): void;
  updateMarker(markerId: number, lat: number, lon: number, iconId: string): void;
  updatePolygon(polygonId: number, polygon: Polygon): void;
  updatePolyline(polylineId: number, polyline: Polyline): void;
  queryPointAnnotations(rect: Rect): number[];
  queryShapeAnnotations(rect: Rect): number[];
  addAnnotationIcon(symbol: string, width: number, height: number, scale: number, pixels: Uint8Array): void;
  removeAnnotationIcon(symbol: string): void;
  getTopOffsetPixelsForAnnotationSymbol(symbolName: string): number;
  
  // 其他
  isDestroyed(): boolean;
  setApiBaseUrl(baseUrl: string): void;
  setReachability(status: boolean): void;
  onLowMemory(): void;
  setSwapBehaviorFlush(flush: boolean): void;
  getDensityDependantRectangle(rectangle: Rect): Rect;
  setOnFpsChangedListener(listener: OnFpsChangedListener | null): void;
  isFullyLoaded(): boolean;
}
