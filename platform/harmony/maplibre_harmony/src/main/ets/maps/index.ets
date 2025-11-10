/**
 * MapLibre Native for HarmonyOS - 主导出文件
 *
 * 提供所有公共 API 的统一导出
 */
import maplibre from 'libmaplibre.so';
// 不能导出 maplibre，会破坏封装性
// 导出 maplibre namespace（供需要访问底层 NAPI 的用户使用）
// export { maplibre };

// ========== 核心组件 ==========
export { MapView } from './mapview/NativeMapView';

export type NativeMapView = maplibre.NativeMapView;

export type {
  NativeViewAnnotationAnchor,
  NativeViewAnnotationCenterOffset,
  NativeViewAnnotationFrame,
  NativeViewAnnotationOptions
} from './annotations/NativeViewAnnotationTypes';

export {
  NativeViewAnnotationAnchorImpl,
  NativeViewAnnotationCenterOffsetImpl,
  NativeViewAnnotationOptionsImpl
} from './annotations/NativeViewAnnotationTypes';

export { MapLibreMap } from './MapLibreMap';

export { MapLibreMapOptions } from './MapLibreMapOptions';

// ========== 网络配置 ==========
export { NetworkConfiguration } from './network/NetworkConfiguration';
export type { HttpHeaders } from './network/NetworkConfiguration';

// ========== 存储和资源 ==========
export { FileSource } from './storage/FileSource';
export { ResourceTransform, ResourceKind } from './storage/ResourceTransform';
export type { ResourceTransformCallback } from './storage/ResourceTransform';

// ========== 类型定义 ==========
export {
  OrnamentPosition,
  RenderingRefreshMode,
  TileOperation,
  UserTrackingMode,
  CameraMoveReason
} from './types/NativeTypes';

export type { Margins, Size } from './types/NativeTypes';

// ========== 调试选项 ==========
export { MapDebugOptions } from './types/MapDebugOptions';

// ========== 渲染统计 ==========
export { RenderingStats } from './renderer/RenderingStats';

// ========== UI 设置 ==========
export { UiSettings, FocalPoint } from './UiSettings';

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
  OnMarkerLongClickListener,
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

export type { ILatLng } from './types/NativeTypes';

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
  EdgeInsets
} from './camera/CameraPosition';

export type CameraOptions = maplibre.CameraOptions;
export type { ExpressionLiteral as FilterExpression } from 'libmaplibre.so';
export type { ExpressionLiteral as NapiExpressionLiteral } from 'libmaplibre.so';

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

export type { PolylineOptions } from './annotations/Polyline';

export { Polygon } from './annotations/Polygon';

export type { PolygonOptions } from './annotations/Polygon';

export { PolylineManager } from './annotations/PolylineManager';

export { PolygonManager } from './annotations/PolygonManager';

export { InfoWindow, InfoWindowComponent } from './annotations/InfoWindow';

export { InfoWindowAdapter } from './annotations/InfoWindowAdapter';

export { AnnotationView, DragState } from './annotations/AnnotationView';

export type { CenterOffset } from './annotations/AnnotationView';

export { AnnotationViewAdapter, createDelegateFromAdapter } from './annotations/AnnotationViewAdapter';

export type { AnnotationViewDelegate, AnnotationViewConfig, AnnotationViewBuilder, AnnotationViewSize } from './annotations/AnnotationViewDelegate';

export { AnnotationViewManager } from './annotations/AnnotationViewManager';

export type { AnnotationViewData } from './annotations/AnnotationViewManager';

export { NativeViewAnnotationOverlay, ViewAnnotationRenderState } from './annotations/NativeViewAnnotationOverlay';

export type { ViewAnnotationRenderStateParams } from './annotations/NativeViewAnnotationOverlay';

export {
  ViewAnnotationManager,
  ViewAnnotationAddOptions,
  ViewAnnotationUpdateOptions
} from './annotations/ViewAnnotationManager';

// ========== GeoJSON 类型（通过命名空间导出）==========
export * from './geojson';

// ========== 样式 (Styling) ==========
export { Style, StyleBuilder } from './style/Style';

export { Light } from './style/light/Light';

export type { LightOptions } from './style/light/Light';

export { DEFAULT_STYLE_URLS } from './constants/DefaultStyles';

export type { DefaultStyleUrls } from './constants/DefaultStyles';

// 自定义图层 (CustomLayer)
export {
  CustomLayer, createCustomLayerWithColor
} from './style/layers';

export type { RGBAColor } from './style/layers';

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
  Layer,
  LayerOptions,
  LayerFilter,
  LayerLayout,
  LayerPaint,
  LayerMetadata,
  ColorValue,
  NumberValue,
  BooleanValue,
  StringValue
} from './style/layers';

// ========== 表达式 ==========
export {
  Expression,
  ExpressionLiteral,
  ExpressionLiteralArray,
  ExpressionMap
} from './style/expressions';

export { ExpressionValue } from './style/expressions';

// ========== 数据源 ==========
export {
  GeoJsonSource, VectorSource, RasterSource, RasterDemSource, ImageSource
} from './style/sources';

export type {
  Source, SourceOptions, GeoJsonData
} from './style/sources';

export { GeoJsonOptions, GeoJsonOptionsBuilder } from './style/sources/GeoJsonOptions';

// ========== 地图快照 ==========
export {
  MapSnapshotter,
  MapSnapshot,
  SnapshotOptions,
  SnapshotOptionsBuilder,
  SnapshotReadyCallback,
  SnapshotErrorHandler,
  MapSnapshotterObserver
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