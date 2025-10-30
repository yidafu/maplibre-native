/**
 * MapLibre Native for HarmonyOS - 主导出文件
 * 
 * 提供所有公共 API 的统一导出
 */

// ========== 核心组件 ==========
export { NativeMapView } from './NativeMapView';
export { MapLibreMap } from './MapLibreMap';
export { MapLibreMapOptions } from './MapLibreMapOptions';

// ========== 类型定义 ==========
export { 
  OrnamentPosition,
  RenderingRefreshMode,
  TileOperation,
  UserTrackingMode,
  CameraMoveReason
} from './types';
export type { Margins } from './types';

// ========== 渲染统计 ==========
export { RenderingStats } from './RenderingStats';

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
export { Point } from './geometry/Point';
export { ProjectedMeters } from './geometry/ProjectedMeters';
export { Rect } from './geometry/Rect';

// ========== 投影工具 ==========
export { Projection } from './projection/Projection';
export { VisibleRegion } from './projection/VisibleRegion';

// ========== 离线地图 ==========
export {
  OfflineManager,
  OfflineRegion,
  OfflineRegionDefinition,
  OfflineTilePyramidRegionDefinition,
  OfflineRegionStatus,
  DownloadState as OfflineRegionDownloadState,
  OfflineRegionError,
  OfflineRegionErrorReason
} from './offline';
export type {
  OfflineRegionObserver
} from './offline';

// ========== 相机 ==========
export { CameraPosition } from './camera/CameraPosition';
export { CameraAnimationCallback, OnFinishCallback, AnimationOptions } from './camera/CameraAnimationCallback';

// ========== UI 组件 ==========
export { CompassView } from './widgets/CompassView';
export { LogoView } from './widgets/LogoView';
export { CompassPosition } from './widgets/CompassPosition';
export { CompassVisibility } from './widgets/CompassVisibility';
export { ScaleBarView, ScaleBarUnit } from './widgets/ScaleBarView';
export { AttributionButton, DEFAULT_ATTRIBUTIONS } from './widgets/AttributionButton';
export type { AttributionInfo } from './widgets/AttributionButton';

// ========== 标注 ==========
export { MarkerOptions } from './annotations/MarkerOptions';
export { Annotation } from './annotations/Annotation';

// ========== 样式 ==========
export { Style, StyleBuilder } from './style/Style';

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
  PropertyFactory
} from './style/layers';
export type {
  LayerOptions,
  LayerFilter,
  LayerLayout,
  LayerPaint,
  LayerMetadata
} from './style/layers';

// ========== 表达式 ==========
export {
  Expression,
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
  ValueExpression,
  ExpressionValue
} from './style/expressions';

// ========== 数据源 ==========
export {
  GeoJsonSource,
  VectorSource,
  RasterSource,
  RasterDemSource,
  ImageSource
} from './style/sources';
export type {
  SourceOptions,
  GeoJsonData
} from './style/sources';

// ========== 地图快照 ==========
export {
  MapSnapshotter,
  MapSnapshot,
  SnapshotOptions,
  SnapshotOptionsBuilder,
  Size
} from './snapshot';
export type {
  SnapshotReadyCallback,
  SnapshotErrorHandler
} from './snapshot';

