/**
 * TestPageRegistry - Centralized metadata registry for all test pages.
 *
 * Inspired by Android's FeatureOverviewActivity which reads activity metadata
 * from AndroidManifest.xml. This file replaces the inline data that was
 * previously hardcoded in Index.ets.
 */

export interface TestPageItem {
  title: string;
  description: string;
  route: string;
}

export interface TestPageCategory {
  name: string;
  key: string;
  pages: TestPageItem[];
}

export const TEST_PAGE_CATEGORIES: TestPageCategory[] = [
  {
    name: 'Basic',
    key: '01_basic',
    pages: [
      { title: 'Simple Map', description: 'Display a basic interactive map', route: 'pages/basic/SimpleMapTestPage' },
      { title: 'Debug Mode', description: 'Toggle debug visualizations (tile boundaries, FPS)', route: 'pages/basic/DebugModeTestPage' },
      { title: 'Map State', description: 'Monitor map lifecycle and state changes', route: 'pages/basic/MapStateTestPage' },
      { title: 'Renderer Backend Info', description: 'Show active graphics backend (OpenGL ES / Vulkan) and GPU', route: 'pages/basic/BackendInfoTestPage' },
    ],
  },
  {
    name: 'Map Layout',
    key: '02_maplayout',
    pages: [
      { title: 'Map Padding', description: 'Set content insets for the map', route: 'pages/maplayout/MapPaddingTestPage' },
      { title: 'Double Map', description: 'Display two map instances side by side', route: 'pages/maplayout/DoubleMapTestPage' },
      { title: 'Map In Dialog', description: 'Embed a map inside a modal dialog', route: 'pages/maplayout/MapInDialogTestPage' },
      { title: 'Map Change', description: 'Observe map move and resize events', route: 'pages/maplayout/MapChangeTestPage' },
      { title: 'Overlay Map', description: 'Overlay views on top of the map', route: 'pages/maplayout/OverlayMapTestPage' },
      { title: 'Bottom Sheet', description: 'Bottom sheet panel with a map', route: 'pages/maplayout/BottomSheetTestPage' },
      { title: 'Visibility Change', description: 'Test map visibility lifecycle', route: 'pages/maplayout/VisibilityChangeTestPage' },
      { title: 'Local Glyph', description: 'Use local glyph font rendering', route: 'pages/maplayout/LocalGlyphTestPage' },
    ],
  },
  {
    name: 'Annotation',
    key: '03_annotation',
    pages: [
      { title: 'Bulk Marker', description: 'Add 1000+ markers to test performance', route: 'pages/annotation/BulkMarkerTestPage' },
      { title: 'Draggable Marker', description: 'Drag markers to new positions', route: 'pages/annotation/DraggableMarkerTestPage' },
      { title: 'Dynamic Marker', description: 'Dynamically change marker properties', route: 'pages/annotation/DynamicMarkerChangeTestPage' },
      { title: 'Marker Click', description: 'Handle marker click and remove events', route: 'pages/annotation/MarkerClickTestPage' },
      { title: 'Annotation View', description: 'Custom annotation views with reuse', route: 'pages/annotation/AnnotationViewTestPage' },
      { title: 'Icon Test', description: 'Custom icons for markers', route: 'pages/annotation/IconTestPage' },
      { title: 'Polygon', description: 'Draw and interact with polygons', route: 'pages/annotation/PolygonTestPage' },
      { title: 'Polyline', description: 'Draw and interact with polylines', route: 'pages/annotation/PolylineTestPage' },
      { title: 'Press for Marker', description: 'Long-press to add a marker', route: 'pages/annotation/PressForMarkerTestPage' },
    ],
  },
  {
    name: 'Camera',
    key: '04_camera',
    pages: [
      { title: 'Camera Position', description: 'Set camera position, zoom, bearing, pitch', route: 'pages/camera/CameraPositionTestPage' },
      { title: 'Camera Update', description: 'Animate camera with easeTo, flyTo, jumpTo', route: 'pages/camera/CameraUpdateTestPage' },
      { title: 'Camera Animator', description: 'Configure animation duration and easing', route: 'pages/camera/CameraAnimatorTestPage' },
      { title: 'Animation Type', description: 'Compare different animation curve types', route: 'pages/camera/CameraAnimationTypeTestPage' },
      { title: 'LatLng Bounds', description: 'Constrain camera to a bounding box', route: 'pages/camera/LatLngBoundsTestPage' },
      { title: 'Zoom Controls', description: 'Manual zoom, min/max zoom limits', route: 'pages/camera/ZoomControlsTestPage' },
      { title: 'Pitch and Rotate', description: 'Control tilt and rotation', route: 'pages/camera/PitchRotateTestPage' },
      { title: 'Scroll By', description: 'Pan the map by pixel offset', route: 'pages/camera/ScrollByTestPage' },
      { title: 'Gesture Detector', description: 'Test gesture recognizers', route: 'pages/camera/GestureDetectorTestPage' },
    ],
  },
  {
    name: 'Styling',
    key: '05_styling',
    pages: [
      { title: 'Runtime Style', description: 'Change map style at runtime', route: 'pages/styling/RuntimeStyleTestPage' },
      { title: 'Style URL', description: 'Load map styles from URLs', route: 'pages/styling/StyleUrlTestPage' },
      { title: 'Style File', description: 'Load local style JSON files', route: 'pages/styling/StyleFileTestPage' },
      { title: 'No Style', description: 'Display map with no style loaded', route: 'pages/styling/NoStyleTestPage' },
      { title: 'Style Transition', description: 'Animated style transitions', route: 'pages/styling/StyleTransitionTestPage' },
      { title: 'Circle Layer', description: 'Render circle layers', route: 'pages/styling/CircleLayerTestPage' },
      { title: 'Fill Layer', description: 'Render filled polygon layers', route: 'pages/styling/FillLayerTestPage' },
      { title: 'Line Layer', description: 'Render line string layers', route: 'pages/styling/LineLayerTestPage' },
      { title: 'Symbol Layer', description: 'Render icon and text symbols', route: 'pages/styling/SymbolLayerTestPage' },
      { title: 'Background Layer', description: 'Set background color/pattern', route: 'pages/styling/BackgroundLayerTestPage' },
      { title: 'Fill Extrusion', description: 'Extruded polygon (3D) layers', route: 'pages/styling/FillExtrusionTestPage' },
      { title: 'Heatmap Layer', description: 'Heatmap density visualization', route: 'pages/styling/HeatmapLayerTestPage' },
      { title: 'Hillshade Layer', description: 'Terrain hillshading', route: 'pages/styling/HillshadeLayerTestPage' },
      { title: 'Expression', description: 'Data-driven expressions', route: 'pages/styling/ExpressionTestPage' },
      { title: 'Light', description: 'Scene lighting configuration', route: 'pages/styling/LightTestPage' },
    ],
  },
  {
    name: 'Custom Layer',
    key: '06_customlayer',
    pages: [
      { title: 'Custom Layer', description: 'Custom rendering with OpenGL', route: 'pages/customlayer/CustomLayerTestPage' },
    ],
  },
  {
    name: 'Data Sources',
    key: '07_datasources',
    pages: [
      { title: 'Vector Tile', description: 'Display vector tile source', route: 'pages/datasources/VectorTileTestPage' },
      { title: 'Raster Source', description: 'Display raster tile source', route: 'pages/datasources/RasterSourceTestPage' },
      { title: 'GeoJSON Source', description: 'Real-time and clustered GeoJSON sources', route: 'pages/datasources/GeoJsonSourceTestPage' },
    ],
  },
  {
    name: 'Features',
    key: '08_features',
    pages: [
      { title: 'Point Query', description: 'Query features at a screen point', route: 'pages/features/PointQueryTestPage' },
      { title: 'Box Query', description: 'Query features within a bounding box', route: 'pages/features/BoxQueryTestPage' },
      { title: 'Box Highlight', description: 'Highlight features within a box selection', route: 'pages/features/BoxHighlightTestPage' },
      { title: 'Source Features', description: 'Query features from a specific source', route: 'pages/features/SourceFeaturesTestPage' },
    ],
  },
  {
    name: 'Storage',
    key: '09_storage',
    pages: [
      { title: 'Cache Management', description: 'Manage tile cache', route: 'pages/storage/CacheManagementTestPage' },
      { title: 'URL Transform', description: 'Transform tile URLs', route: 'pages/storage/UrlTransformTestPage' },
      { title: 'Custom HTTP', description: 'Custom HTTP request implementation', route: 'pages/storage/CustomHttpTestPage' },
    ],
  },
  {
    name: 'Events',
    key: '10_events',
    pages: [
      { title: 'Observer', description: 'Observe map and resource events', route: 'pages/events/ObserverTestPage' },
    ],
  },
  {
    name: 'Location',
    key: '11_location',
    pages: [
      { title: 'Location Map Change', description: 'Location updates on map move', route: 'pages/location/LocationMapChangeTestPage' },
      { title: 'Location Modes', description: 'Toggle location tracking modes', route: 'pages/location/LocationModesTestPage' },
      { title: 'Location Activation', description: 'Location component lifecycle', route: 'pages/location/LocationActivationTestPage' },
      { title: 'Pulsing Circle', description: 'Custom pulsing circle UI', route: 'pages/location/PulsingCircleTestPage' },
      { title: 'Manual Location', description: 'Update location programmatically', route: 'pages/location/ManualLocationTestPage' },
    ],
  },
  {
    name: 'Offline',
    key: '12_offline',
    pages: [
      { title: 'Download Region', description: 'Download a map region', route: 'pages/offline/DownloadRegionTestPage' },
      { title: 'Delete Region', description: 'Delete an offline region', route: 'pages/offline/DeleteRegionTestPage' },
      { title: 'List Regions', description: 'List all offline regions', route: 'pages/offline/ListRegionsTestPage' },
      { title: 'Offline Manager', description: 'Manage offline storage', route: 'pages/offline/OfflineManagerTestPage' },
    ],
  },
  {
    name: 'Info Window',
    key: '13_infowindow',
    pages: [
      { title: 'Info Window', description: 'Default info window on marker tap', route: 'pages/infowindow/InfoWindowTestPage' },
      { title: 'Info Window Adapter', description: 'Custom info window layout', route: 'pages/infowindow/InfoWindowAdapterTestPage' },
      { title: 'Dynamic Adapter', description: 'Dynamic custom info window', route: 'pages/infowindow/DynamicAdapterTestPage' },
    ],
  },
  {
    name: 'Fragment',
    key: '14_fragment',
    pages: [
      { title: 'Multi Map', description: 'Multiple map instances on screen', route: 'pages/fragment/MultiMapTestPage' },
      { title: 'Map Fragment', description: 'Map inside a fragment container', route: 'pages/fragment/MapFragmentTestPage' },
      { title: 'BackStack', description: 'Fragment back stack navigation', route: 'pages/fragment/BackStackTestPage' },
    ],
  },
  {
    name: 'Texture View',
    key: '15_textureview',
    pages: [
      { title: 'TextureView Debug', description: 'Debug overlay on TextureView', route: 'pages/textureview/TextureViewDebugTestPage' },
      { title: 'TextureView Resize', description: 'Resize TextureView container', route: 'pages/textureview/TextureViewResizeTestPage' },
      { title: 'TextureView Animation', description: 'Animate TextureView', route: 'pages/textureview/TextureViewAnimationTestPage' },
    ],
  },
  {
    name: 'Image Generator',
    key: '16_imagegenerator',
    pages: [
      { title: 'Snapshot Basic', description: 'Take a static map snapshot', route: 'pages/imagegenerator/SnapshotBasicTestPage' },
      { title: 'Map Snapshotter', description: 'Snapshotter with custom config', route: 'pages/imagegenerator/MapSnapshotterTestPage' },
      { title: 'Snapshotter Reuse', description: 'Reuse snapshotter instance', route: 'pages/imagegenerator/SnapshotterReuseTestPage' },
      { title: 'Bitmap Overlay', description: 'Overlay bitmap on snapshot', route: 'pages/imagegenerator/BitmapOverlayTestPage' },
    ],
  },
  {
    name: 'Turf',
    key: '17_turf',
    pages: [
      { title: 'Physical Circle', description: 'Draw turf physical circle', route: 'pages/turf/PhysicalCircleTestPage' },
      { title: 'Within Expression', description: 'Turf within expression', route: 'pages/turf/WithinExpressionTestPage' },
    ],
  },
  {
    name: 'Map Options',
    key: '18_mapoptions',
    pages: [
      { title: 'Options Runtime', description: 'Set map options at runtime', route: 'pages/mapoptions/OptionsRuntimeTestPage' },
      { title: 'Options XML', description: 'Configure map via XML', route: 'pages/mapoptions/OptionsXmlTestPage' },
    ],
  },
  {
    name: 'Benchmark',
    key: '19_benchmark',
    pages: [
      { title: 'Benchmark', description: 'Performance benchmark suite', route: 'pages/benchmark/BenchmarkTestPage' },
      { title: 'Performance', description: 'Frame rate and memory measurement', route: 'pages/benchmark/PerformanceTestPage' },
    ],
  },
  {
    name: 'Integration',
    key: '20_integration',
    pages: [
      { title: 'Auto Test', description: 'Bridge for ohosTest suites', route: 'pages/integration/AutomationTestPage' },
      { title: 'Declarative API', description: 'Declarative map API demo', route: 'pages/integration/DeclarativeAPITestPage' },
    ],
  },
  {
    name: 'Texture Mode',
    key: '21_texturemode',
    pages: [
      { title: 'Texture XComponent', description: 'Map on XComponentType.TEXTURE with transforms', route: 'pages/texturemode/TextureModeTestPage' },
    ],
  },
];
