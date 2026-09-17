/**
 * MapLibre Native for HarmonyOS - Main module export
 *
 * Provides a unified export surface for all public APIs
 */
import maplibre from 'libmaplibre.so';
// Do not export maplibre directly; keep the encapsulation intact
// namespace export would expose the NAPI layer for advanced use

// ========== Core components ==========
export { MapView } from './mapview/NativeMapView';
export { TextureMapView } from './mapview/TextureMapView';

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

export { MapLibreMap, CameraState } from './MapLibreMap';

export { MapLibreMapOptions } from './MapLibreMapOptions';

// ========== Network configuration ==========
export { NetworkConfiguration } from './network/NetworkConfiguration';
export type { HttpHeaders } from './network/NetworkConfiguration';

// ========== Storage and resources ==========
export { FileSource } from './storage/FileSource';
export { ResourceTransform, ResourceKind } from './storage/ResourceTransform';
export type { ResourceTransformCallback } from './storage/ResourceTransform';

// ========== Type definitions ==========
export {
  OrnamentPosition,
  RenderingRefreshMode,
  TileOperation,
  UserTrackingMode
} from './types/NativeTypes';

export type { Margins, Size } from './types/NativeTypes';

// ========== Render surface types ==========
export type { MapSurfaceType } from './types/NativeTypes';

// ========== Debug options ==========
export { MapDebugOptions } from './types/MapDebugOptions';

// ========== Rendering statistics ==========
export { RenderingStats } from './renderer/RenderingStats';

// ========== UI settings ==========
export { UiSettings, FocalPoint } from './UiSettings';

// ========== Listener interfaces ==========
export {
  // Camera events
  OnCameraWillChangeListener,
  OnCameraIsChangingListener,
  OnCameraDidChangeListener,

  // Map loading events
  OnWillStartLoadingMapListener,
  OnDidFinishLoadingMapListener,
  OnDidFailLoadingMapListener,

  // Rendering events
  OnWillStartRenderingFrameListener,
  OnDidFinishRenderingFrameListener,
  OnDidFinishRenderingFrameWithStatsListener,
  OnWillStartRenderingMapListener,
  OnDidFinishRenderingMapListener,

  // Style events
  OnDidFinishLoadingStyleListener,
  OnStyleImageMissingListener,
  OnCanRemoveUnusedStyleImageListener,

  // Other events
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

  // Map ready callback
  OnMapReadyCallback,

  // Legacy listeners
  OnMarkerClickListener,
  OnMarkerLongClickListener,
  OnMarkerDragListener,
  OnInfoWindowClickListener,
  OnInfoWindowCloseListener,
  OnMarkerSelectListener,
  OnStyleLoadedListener,
  OnStyleLoadErrorListener,
  OnFpsChangedListener
} from './listeners';

// ========== Gesture listeners ==========
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

// ========== Geometry types ==========
export { LatLng } from './geometry/LatLng';

export type { ILatLng } from './types/NativeTypes';

export { LatLngBounds } from './geometry/LatLngBounds';

export { Point, PixelCoordinate, IPixelCoordinate } from './geometry/Point';

export { Point as ScreenPoint } from './geometry/Point'; // Screen-pixel coordinate alias

export type { ScreenCoordinate } from './geometry/Point'; // Screen coordinate alias

export { ProjectedMeters, IProjectedMeters } from './geometry/ProjectedMeters';

export { Rect, IRect } from './geometry/Rect';

// ========== Projection utilities ==========
export { Projection } from './projection/Projection';

export { VisibleRegion } from './projection/VisibleRegion';

// ========== Offline maps ==========
export {
  OfflineManager,
  OfflineRegion,
  DownloadState,
  DownloadState as OfflineRegionDownloadState,
  OfflineRegionDefinition,
  OfflineTilePyramidRegionDefinition,
  createTilePyramidRegionDefinition,
  OfflineRegionStatus,
  OfflineRegionErrorReason
} from './offline';

export type {
  OfflineRegionObserver, OfflineRegionError
} from './offline';

// ========== Camera ==========
export {
  CameraPosition,
  createCameraPosition,
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

export { CameraMoveReason, getCameraMoveReasonText } from './camera/CameraMoveReason';

// ========== UI components ==========
export { CompassView } from './widgets/CompassView';

export { LogoView } from './widgets/LogoView';

export { CompassVisibility } from './widgets/CompassVisibility';

export { ScaleBarView, ScaleBarUnit } from './widgets/ScaleBarView';

export { AttributionButton, DEFAULT_ATTRIBUTIONS } from './widgets/AttributionButton';

export type { AttributionInfo } from './widgets/AttributionButton';

// ========== Annotations ==========
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

export type { InfoWindowStyle } from './annotations/InfoWindow';

export { InfoWindowAdapter, createInfoWindowAdapter } from './annotations/InfoWindowAdapter';

export type { CenterOffset } from './annotations/ViewAnnotationUtils';

export type { AnnotationViewDelegate, AnnotationViewConfig, AnnotationViewBuilder, AnnotationViewSize } from './annotations/AnnotationViewDelegate';

export { ViewAnnotationHandle } from './annotations/ViewAnnotationHandle';

export {
  ViewAnnotationManager,
  ViewAnnotationAddOptions,
  ViewAnnotationUpdateOptions
} from './annotations/ViewAnnotationManager';

// ========== GeoJSON types (namespace export) ==========
export * from './geojson';

// ========== Styling ==========
export { Style, StyleBuilder } from './style/Style';

export { Light } from './style/light/Light';

export { TransitionOptions } from './style/layers/TransitionOptions';

export type { ITransitionOptions } from './style/layers/TransitionOptions';

export { DEFAULT_STYLE_URLS } from './constants/DefaultStyles';

export type { DefaultStyleUrls } from './constants/DefaultStyles';

// Custom layers
export {
  CustomLayer, createCustomLayerWithColor
} from './style/layers';

export type { RGBAColor } from './style/layers';

// ========== Layers ==========
export {
  FillLayer,
  LineLayer,
  CircleLayer,
  SymbolLayer,
  RasterLayer,
  BackgroundLayer,
  HeatmapLayer,
  HillshadeLayer,
  ColorReliefLayer,
  FillExtrusionLayer,
  LocationIndicatorLayer,
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

// ========== Expressions ==========
export {
  Expression,
  ExpressionLiteral,
  ExpressionLiteralArray,
  ExpressionMap
} from './style/expressions';

export { ExpressionValue } from './style/expressions';

// ========== Data sources ==========
export {
  GeoJsonSource, VectorSource, RasterSource, RasterDemSource, ImageSource,
  VideoSource, CustomGeometrySource
} from './style/sources';

export type {
  Source, SourceOptions, GeoJsonData
} from './style/sources';

export { TileSet, VectorLayer } from './style/sources/TileSet';

export { GeoJsonOptions, GeoJsonOptionsBuilder } from './style/sources/GeoJsonOptions';

// ========== Map snapshots ==========
export {
  MapSnapshotter,
  MapSnapshot,
  SnapshotOptions,
  SnapshotOptionsBuilder,
  SnapshotReadyCallback,
  SnapshotErrorHandler,
  MapSnapshotterObserver
} from './snapshot';

// ========== Location component ==========
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

// ========== Map widgets ==========
export * from './widgets'