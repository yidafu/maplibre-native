/**
 * MapLibre Native for HarmonyOS - 主导出文件
 *
 * 提供所有公共 API 的统一导出
 */
import maplibre from 'libmaplibre.so'

// ========== 核心组件 ==========
export { MapView } from './NativeMapView';

export type NativeMapView = maplibre.NativeMapView

export { MapLibreMap } from './MapLibreMap';

export { MapLibreMapOptions } from './MapLibreMapOptions';

// ========== 类型定义 ==========
export {
  OrnamentPosition,
  RenderingRefreshMode,
  TileOperation,
  UserTrackingMode,
  CameraMoveReason
} from './types/NativeTypes';

export type { Margins } from './types/NativeTypes';

// ========== 渲染统计 ==========
export { RenderingStats } from './renderer/RenderingStats';

// ========== UI 设置 ==========
export { UiSettings, FocalPoint, CompassMargins } from './UiSettings';

// ========== 监听器接口 ==========
export {
  // 相机事件
  OnCameraWillChangeListener,
  OnCameraIsChangingListener,
  OnCameraDidChangeListener,

  // 地图加载事件
  OnWillStartLoadingMapListener,
  OnDidFinishLoadingMapListener,
  OnDidFailLoadingMapListener,

  // 渲染事件
  OnWillStartRenderingFrameListener,
  OnDidFinishRenderingFrameListener,
  OnDidFinishRenderingFrameWithStatsListener,
  OnWillStartRenderingMapListener,
  OnDidFinishRenderingMapListener,

  // 样式事件
  OnDidFinishLoadingStyleListener,
  OnStyleImageMissingListener,
  OnCanRemoveUnusedStyleImageListener,

  // 其他事件
  OnDidBecomeIdleListener,
  OnSourceChangedListener,
  OnPreCompileShaderListener,
  OnPostCompileShaderListener,
  OnShaderCompileFailedListener,
  OnGlyphsLoadedListener,
  OnGlyphsErrorListener,
  OnGlyphsRequestedListener,
  OnTileActionListener,
  OnSpriteLoadedListener,
  OnSpriteErrorListener,
  OnSpriteRequestedListener,

  // 地图就绪回调
  OnMapReadyCallback,

  // 原有监听器
  OnMarkerClickListener,
  OnMarkerDragListener,
  OnInfoWindowClickListener,
  OnInfoWindowCloseListener,
  OnMarkerSelectListener,
  OnStyleLoadedListener,
  OnStyleLoadErrorListener
} from './listeners';

// ========== 手势监听器 ==========
export {
  OnMoveListener,
  OnScaleListener,
  OnRotateListener,
  OnMapClickListener,
  OnMapLongClickListener,
  OnDoubleTapListener,
  OnTiltListener,
  OnQuickZoomListener
} from './gestures/GestureListeners';

// ========== 几何类型 ==========
export { LatLng } from './geometry/LatLng';

export { LatLngBounds } from './geometry/LatLngBounds';

export { Point, PixelCoordinate, IPixelCoordinate } from './geometry/Point';

export { Point as ScreenPoint } from './geometry/Point'; // 屏幕像素坐标（别名）

export type { ScreenCoordinate } from './geometry/Point'; // 屏幕坐标类型别名

export { ProjectedMeters, IProjectedMeters } from './geometry/ProjectedMeters';

export { Rect, IRect } from './geometry/Rect';

// ========== 投影工具 ==========
export { Projection } from './projection/Projection';

export { VisibleRegion } from './projection/VisibleRegion';

// ========== 离线地图 ==========
export {
  OfflineManager,
  OfflineRegion,
  DownloadState as OfflineRegionDownloadState,
  OfflineRegionDefinition,
  OfflineTilePyramidRegionDefinition,
  OfflineRegionStatus,
  OfflineRegionErrorReason
} from './offline';

export type {
  OfflineRegionObserver, OfflineRegionError
} from './offline';

// ========== 相机 ==========
export {
  CameraPosition,
  ICameraPosition,
  EdgeInsets,
  IEdgeInsets,
  CameraOptions
} from './camera/CameraPosition';

export { CameraAnimationCallback, OnFinishCallback, AnimationOptions } from './camera/CameraAnimationCallback';

export {
  OnCameraIdleListener,
  OnCameraMoveStartedListener,
  OnCameraMoveListener,
  OnCameraMoveCanceledListener,
  OnAnimationFinishedListener,
  CameraChangeListener
} from './camera/CameraListener';

// ========== UI 组件 ==========
export { CompassView } from './widgets/CompassView';

export { LogoView } from './widgets/LogoView';

export { CompassPosition } from './widgets/CompassPosition';

export { CompassVisibility } from './widgets/CompassVisibility';

export { ScaleBarView, ScaleBarUnit } from './widgets/ScaleBarView';

export { AttributionButton, DEFAULT_ATTRIBUTIONS } from './widgets/AttributionButton';

export type { AttributionInfo } from './widgets/AttributionButton';

// ========== 标注 ==========
export { Marker } from './annotations/Marker';

export { Icon } from './annotations/Icon';

export { IconFactory } from './annotations/IconFactory';

export { MarkerOptions } from './annotations/MarkerOptions';

export { Annotation } from './annotations/Annotation';

export { Polyline } from './annotations/Polyline';

export { Polygon } from './annotations/Polygon';

export { InfoWindow, InfoWindowComponent } from './annotations/InfoWindow';

export { InfoWindowAdapter } from './annotations/InfoWindowAdapter';

export { AnnotationView } from './annotations/AnnotationView';

export { AnnotationViewAdapter } from './annotations/AnnotationViewAdapter';

export { AnnotationViewManager, AnnotationViewData } from './annotations/AnnotationViewManager';

// ========== GeoJSON 类型（通过命名空间导出）==========
export * from './geojson';

// ========== 样式 ==========
export { Style, StyleBuilder } from './style/Style';

export { Light } from './style/light/Light';

export type { LightOptions } from './style/light/Light';

export { DEFAULT_STYLE_URLS } from './constants/DefaultStyles';

export type { DefaultStyleUrls } from './constants/DefaultStyles';

// ========== 图层 ==========
export {
  FillLayer,
  LineLayer,
  CircleLayer,
  SymbolLayer,
  RasterLayer,
  BackgroundLayer,
  HeatmapLayer,
  HillshadeLayer,
  FillExtrusionLayer,
  CustomLayer,
  ExampleCustomLayer,
  PropertyFactory
} from './style/layers';

export type {
  Layer,
  LayerOptions,
  LayerFilter,
  LayerLayout,
  LayerPaint,
  LayerMetadata,
  CustomLayerOptions,
  ColorValue,
  NumberValue,
  BooleanValue,
  StringValue
} from './style/layers';

// ========== 表达式 ==========
export {
  Expression,
  ExpressionBuilder, // deprecated: use Expression instead
  ExpressionLiteral,
  ExpressionLiteralArray,
  ExpressionMap,
  CollatorExpression
} from './style/expressions';

export {
  Interpolator
} from './style/expressions/Interpolator';

export {
  Stop
} from './style/expressions/Stop';

export type {
  ValueExpression, ExpressionValue
} from './style/expressions';

// ========== 数据源 ==========
export {
  GeoJsonSource, VectorSource, RasterSource, RasterDemSource, ImageSource
} from './style/sources';

export type {
  Source, SourceOptions, GeoJsonData
} from './style/sources';

// ========== 地图快照 ==========
export {
  MapSnapshotter, MapSnapshot, SnapshotOptions, SnapshotOptionsBuilder, Size
} from './snapshot';

export type {
  SnapshotReadyCallback, SnapshotErrorHandler
} from './snapshot';

// ========== 位置组件 ==========
export {
  LocationComponent,
  LocationComponentOptions,
  LocationComponentOptionsBuilder,
  RenderMode,
  CameraMode,
  LocationEngine,
  LocationEngineCallback,
  LocationEngineRequest,
  LocationEngineRequestBuilder,
  HarmonyLocationEngine,
  CompassEngine,
  OnLocationClickListener,
  OnCameraTrackingChangedListener,
  OnRenderModeChangedListener,
  OnLocationStaleListener,
  LocationComponentConstants,
  PermissionManager
} from './location';

export type {
  CompassListener, PermissionRequestResult
} from './location';

// ========== 地图组件 ==========
export * from './widgets'