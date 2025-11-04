# MapLibre Harmony Test Application

This directory contains the test application for MapLibre Native on HarmonyOS platform. The application provides comprehensive test coverage for all MapLibre features and APIs.

## Overview

The test application is organized into multiple categories, each containing test pages that demonstrate and validate specific MapLibre functionality. All test pages are built using ArkTS and follow HarmonyOS development best practices.

**Total Test Pages**: 150+  
**Categories**: 15  
**Status**: ✅ All pages pass ArkTS linter validation

## Test Categories

### 1. Basic Map Features (`basic/`)

Core map functionality and basic operations.

- **SimpleMapTestPage** - Basic map initialization and rendering
- **CoreAPITestPage** - Core MapLibre API methods testing
- **MapStateTestPage** - Map lifecycle state management
- **MapChangeTestPage** - Map style switching and transitions
- **DoubleMapTestPage** - Multiple map instances in single page
- **MapInDialogTestPage** - Map rendering in dialog components
- **MapPaddingTestPage** - Map padding and content insets
- **OverlayMapTestPage** - Map overlay and z-index management
- **BottomSheetTestPage** - Map with bottom sheet interactions
- **VisibilityChangeTestPage** - Map visibility state handling
- **DebugModeTestPage** - Debug mode and performance monitoring
- **LocalGlyphTestPage** - Local font glyph rendering
- **OSMRasterMapPage** - OpenStreetMap raster tile rendering
- **SatelliteMapPage** - Satellite imagery map style

**Key Features Tested:**
- Map initialization and lifecycle
- Style loading and switching
- Multiple map instances
- UI component integration
- Debug and performance tools

### 2. Camera Controls (`camera/`)

Camera positioning, animation, and viewport manipulation.

- **CameraPositionTestPage** - Camera position and target setting
- **CameraUpdateTestPage** - Camera update and transition methods
- **CameraAnimationTypeTestPage** - Different animation curve types
- **CameraAnimatorTestPage** - Custom camera animation sequences
- **ManualZoomTestPage** - Programmatic zoom control
- **MaxMinZoomTestPage** - Zoom level constraints
- **PitchTestPage** - Camera pitch/tilt angle control
- **RotateByTestPage** - Map rotation operations
- **ScrollByTestPage** - Programmatic map panning
- **LatLngBoundsTestPage** - Geographic bounds calculations
- **LatLngBoundsForCameraTestPage** - Fitting bounds to camera
- **GestureTestPage** - Touch gesture recognition
- **GestureDetectorTestPage** - Custom gesture handlers

**Key Features Tested:**
- Camera positioning (target, zoom, bearing, tilt)
- Animation types and easing functions
- Zoom constraints and levels
- Rotation and orientation
- Geographic bounds fitting
- Touch gesture handling

### 3. Annotations (`annotation/`)

Markers, polygons, polylines, and other map annotations.

- **MarkerClickTestPage** - Marker tap event handling
- **DraggableMarkerTestPage** - Interactive draggable markers
- **RemoveMarkerTestPage** - Dynamic marker removal
- **BulkMarkerTestPage** - Performance testing with many markers
- **DynamicMarkerChangeTestPage** - Runtime marker property updates
- **PressForMarkerTestPage** - Long press marker creation
- **IconTestPage** - Custom marker icon management
- **AnnotationViewTestPage** - Custom annotation view components
- **PolylineTestPage** - Polyline drawing and styling
- **PolygonTestPage** - Polygon rendering and interactions
- **PolylinePolygonTestPage** - Combined polyline and polygon
- **JsonApiTestPage** - GeoJSON string API operations

**Key Features Tested:**
- Marker creation and management
- Custom icons and views
- Drag and drop interactions
- Event handling (click, long press)
- Polyline and polygon rendering
- GeoJSON data integration
- Performance with large datasets

### 4. Location Services (`location/`)

Location component integration and GPS functionality.

- **LocationModesTestPage** - RenderMode and CameraMode switching
  - RenderMode: NORMAL, COMPASS, GPS
  - CameraMode: TRACKING, TRACKING_COMPASS, TRACKING_GPS, TRACKING_GPS_NORTH
- **LocationComponentActivationTestPage** - Location component lifecycle
  - Permission management
  - Component activation flow
  - Step-by-step activation guide
- **BasicLocationPulsingCircleTestPage** - Basic pulsing circle effect
- **CustomizedLocationPulsingCircleTestPage** - Custom pulse styling
  - Color customization
  - Radius configuration
- **LocationFragmentTestPage** - Location component in fragments
- **LocationMapChangeTestPage** - Location state across style changes
- **ManualLocationUpdatesTestPage** - Simulated location updates
  - forceLocationUpdate API
  - Mock location data

**Key Features Tested:**
- LocationComponent API integration
- HarmonyOS location permissions
- Render modes (normal, compass, GPS)
- Camera tracking modes
- Pulsing circle effects
- Location state persistence
- Manual location injection

### 5. Style and Layers (`style/`)

Map styling, layers, expressions, and visual customization.

#### Layer Types
- **BackgroundLayerTestPage** - Background layer properties
- **FillLayerTestPage** - Fill layer rendering
- **LineLayerTestPage** - Line layer styling
- **CircleLayerTestPage** - Circle layer markers
- **SymbolLayerTestPage** - Symbol and icon layers
- **HeatmapLayerTestPage** - Heatmap visualization
- **HillshadeLayerTestPage** - Terrain hillshade rendering
- **FillExtrusionTestPage** - 3D extrusion layers
- **BuildingFillExtrusionTestPage** - 3D building visualization

#### Layer Management
- **LayerTestPage** - Layer add/remove/reorder operations
- **RuntimeStyleTestPage** - Dynamic style modifications
- **RuntimeStyleTimingTestPage** - Style operation performance testing
- **StyleTestPage** - Complete style object manipulation
- **StyleFileTestPage** - Local style file loading
- **StyleUrlTestPage** - Remote style URL loading
- **StyleTransitionTestPage** - Style transition animations
- **NoStyleTestPage** - Error handling for missing styles
- **CollectionUpdateOnStyleChangeTestPage** - Annotation persistence across style changes

#### Data Sources
- **SourceTestPage** - Data source management
- **GeoJsonClusteringTestPage** - GeoJSON point clustering
- **RasterSourceTestPage** - Raster tile sources
- **VectorTileTestPage** - Vector tile rendering
- **GridSourceTestPage** - Dynamic grid generation
- **AnimatedImageSourceTestPage** - Animated image overlays
- **RealTimeGeoJsonTestPage** - Real-time GeoJSON updates
- **CustomSpriteTestPage** - Custom sprite sheet loading

#### Advanced Styling
- **DataDrivenStyleTestPage** - Data-driven styling
- **ExpressionTestPage** - MapLibre expressions API
- **DistanceExpressionTestPage** - Distance calculations
- **ZoomFunctionSymbolLayerTestPage** - Zoom-based styling
- **GradientLineTestPage** - Gradient line rendering
- **AnimatedSymbolLayerTestPage** - Animated symbol positions
- **SymbolGeneratorTestPage** - Dynamic symbol generation
- **ImageInLabelTestPage** - Images embedded in text labels
- **StretchableImageTestPage** - 9-patch stretchable images
- **LightTestPage** - 3D lighting effects

#### Expression Examples
- **NewExpressionPropertiesTest** - New expression property testing
- **ClusterExpressionExample** - Clustering expressions
- **DataDrivenStyleExample** - Data-driven expression examples
- **SymbolLayerExpressionExample** - Symbol layer expressions
- **ExpressionPerformanceTest** - Expression performance benchmarks
- **ExpressionRealWorldExamples** - Practical expression use cases
- **NewPropertyFactoryTest** - PropertyFactory API testing

**Key Features Tested:**
- All MapLibre layer types
- Dynamic style manipulation
- GeoJSON and vector tile sources
- Data-driven styling
- MapLibre expressions
- Performance optimization
- 3D rendering and lighting
- Animation and transitions

### 6. Feature Querying (`feature/`)

Spatial queries and feature inspection.

- **PointClickQueryTestPage** - Query features at click point
- **QueryRenderedFeaturesBoxHighlightTestPage** - Box selection with highlighting
- **QueryRenderedFeaturesBoxCountTestPage** - Feature counting in box
- **QueryRenderedFeaturesBoxSymbolCountTestPage** - Symbol-specific queries
- **QueryRenderedFeaturesPropertiesTestPage** - Feature property inspection
- **QuerySourceFeaturesTestPage** - Source-level feature queries

**Key Features Tested:**
- Point-based feature queries
- Box selection queries
- Feature filtering by layer
- Property extraction
- Source vs rendered feature queries
- Interactive feature highlighting

### 7. Snapshots (`snapshot/`)

Map snapshot generation and image export.

- **MapSnapshotterTestPage** - Basic snapshot generation
  - Background rendering
  - Parallel snapshot creation
  - SnapshotOptions configuration
- **SnapshotBasicTestPage** - Simple snapshot operations
- **MapSnapshotterLocalStyleTestPage** - Snapshot with local styles
- **MapSnapshotterHeatMapTestPage** - Heatmap layer snapshots
- **MapSnapshotterReuseTestPage** - Snapshot performance testing
  - Parallel generation with Promise.all
  - Performance metrics
- **MapSnapshotterBitmapOverlayTestPage** - Overlay drawing on snapshots

**Key Features Tested:**
- MapSnapshotter API
- Asynchronous snapshot generation
- Custom styles in snapshots
- Performance benchmarking
- Bitmap manipulation
- Parallel snapshot processing

### 8. Offline Maps (`offline/`)

Offline map download and management.

- **OfflineManagerTestPage** - OfflineManager basic operations
- **OfflineManagementTestPage** - Offline region management UI
- **DownloadRegionTestPage** - Region download with progress
- **DeleteRegionTestPage** - Region deletion
- **MergeOfflineRegionsTestPage** - Region listing and merging
- **UpdateMetadataTestPage** - Region metadata operations
  - Metadata encoding/decoding
  - JSON metadata storage
- **ChangeResourcesCachePathTestPage** - Cache path configuration
  - HarmonyOS sandbox paths
  - Storage management

**Key Features Tested:**
- OfflineManager API
- Region definition and download
- Download progress tracking
- Region metadata management
- Cache path configuration
- Offline region lifecycle

### 9. Info Windows (`infowindow/`)

Marker info windows and popups.

- **InfoWindowTestPage** - Basic info window display
- **InfoWindowAdapterTestPage** - Custom info window adapters
- **DynamicInfoWindowAdapterTestPage** - Dynamic content updates

**Key Features Tested:**
- Info window creation and display
- Custom view adapters
- Dynamic content updates
- Positioning and anchoring

### 10. Fragment Management (`fragment/`)

HarmonyOS navigation and multi-page scenarios.

- **SupportMapFragmentTestPage** - Map in component fragments
- **ViewPagerTestPage** - Map in Swiper component
- **NestedViewPagerTestPage** - Nested swiper navigation
- **FragmentBackStackTestPage** - Navigation backstack handling
- **MultiMapTestPage** - Multiple map instances management

**Key Features Tested:**
- Map lifecycle in fragments
- Swiper integration
- Navigation component usage
- State preservation
- Multiple map coordination

### 11. Storage and Network (`storage/`)

HTTP requests and caching.

- **CacheManagementTestPage** - Cache operations and management
- **CustomHttpRequestTestPage** - Custom HTTP interceptors
  - HarmonyOS @kit.NetworkKit integration
  - http.createHttp API usage
- **UrlTransformTestPage** - URL transformation monitoring
  - ResourceTransform implementation

**Key Features Tested:**
- Cache management APIs
- Custom HTTP client integration
- Request/response interception
- URL transformation
- Network monitoring

### 12. Custom Layers (`customlayer/`)

Custom rendering layers.

- **CustomLayerTestPage** - Custom OpenGL/WebGL layer rendering

**Key Features Tested:**
- Custom layer lifecycle
- OpenGL context access
- Custom rendering integration

### 13. Events and Listeners (`events/`, `listeners/`)

Map event handling and observation.

- **EventListenersTestPage** - Map event listener registration
  - Click, long click events
  - Camera change events
  - Map load events
- **ObserverTestPage** - Observer pattern implementation

**Key Features Tested:**
- Event listener registration
- Event callback handling
- Observer pattern
- Event lifecycle management

### 14. Turf.js Integration (`turf/`)

Geospatial calculations and analysis.

- **PhysicalUnitCircleTestPage** - Physical unit circles (meters)
  - Dynamic radius adjustment
  - FillLayer with GeoJSON
- **WithinExpressionTestPage** - Polygon containment queries
- **MapSnapshotterWithinExpressionTestPage** - Snapshot with spatial queries

**Key Features Tested:**
- Turf.js integration
- Distance calculations
- Spatial queries
- Polygon containment
- Physical unit conversions

### 15. Texture View (`textureview/`)

XComponent rendering and view properties.

- **TextureViewAnimationTestPage** - View animation effects
  - Size and opacity animations
  - animateTo API usage
- **TextureViewResizeTestPage** - Dynamic view resizing
- **TextureViewDebugModeTestPage** - Debug mode in texture view
- **TextureViewTransparentBackgroundTestPage** - Transparency and background

**Key Features Tested:**
- XComponent integration
- View animations
- Dynamic resizing
- Transparency handling
- Debug visualization

### 16. Performance Testing (`other/`)

Performance benchmarking and monitoring.

- **BenchmarkTestPage** - Performance benchmark suite
  - FPS monitoring
  - Marker addition performance
  - Camera animation timing
- **PerformanceMeasurementTestPage** - Real-time performance monitoring
  - Memory usage
  - Render time statistics
  - Performance logging

**Key Features Tested:**
- Frame rate monitoring
- Memory profiling
- Operation timing
- Performance metrics collection
- Benchmark comparison

## Technical Highlights

### API Integration
- ✅ **LocationComponent** - Complete location API (RenderMode, CameraMode, PermissionManager)
- ✅ **MapSnapshotter** - Background rendering and snapshot generation
- ✅ **OfflineManager** - Offline region management and metadata
- ✅ **UiSettings** - Gesture and UI control APIs
- ✅ **Expression** - Data-driven styling expressions
- ✅ **Query** - Feature querying and inspection

### HarmonyOS Platform Adaptation
- ✅ **Location** - `@ohos.geoLocationManager` + LocationComponent
- ✅ **Permissions** - PermissionManager + `@kit.AbilityKit`
- ✅ **Snapshots** - MapSnapshotter NAPI implementation
- ✅ **Fragments** - Swiper + Navigation components
- ✅ **Network** - `@kit.NetworkKit` http API
- ✅ **XComponent** - Native rendering surface

### Code Quality
- ✅ Zero syntax errors - All files pass ArkTS linter
- ✅ Lifecycle management - Proper aboutToAppear/aboutToDisappear
- ✅ Error handling - Try-catch blocks and user notifications
- ✅ Unified architecture - TestPageLayout component pattern
- ✅ Type safety - Strong typing throughout

### Interactive Features
- ✅ Rich UI controls - Slider, Button, Toggle components
- ✅ Real-time status - Live state updates and logging
- ✅ Performance metrics - Timing and statistics
- ✅ Batch operations - Parallel snapshots, bulk markers

## Directory Structure

```
entry/
├── src/main/ets/
│   ├── pages/                    # Test pages organized by category
│   │   ├── annotation/          # Marker, polygon, polyline tests
│   │   ├── basic/               # Core map functionality
│   │   ├── camera/              # Camera and viewport controls
│   │   ├── customlayer/         # Custom layer rendering
│   │   ├── events/              # Event handling
│   │   ├── feature/             # Feature queries
│   │   ├── fragment/            # Fragment management
│   │   ├── infowindow/          # Info window tests
│   │   ├── listeners/           # Event listeners
│   │   ├── location/            # Location services
│   │   ├── offline/             # Offline maps
│   │   ├── options/             # Map options
│   │   ├── other/               # Performance tests
│   │   ├── snapshot/            # Map snapshots
│   │   ├── storage/             # Storage and network
│   │   ├── style/               # Styles and layers
│   │   ├── textureview/         # XComponent tests
│   │   ├── turf/                # Turf.js integration
│   │   └── Index.ets            # Main test index page
│   ├── components/              # Reusable test components
│   │   ├── MapDebugOverlay.ets
│   │   └── TestPageLayout.ets
│   ├── entryability/            # Application ability
│   ├── model/                   # Data models
│   └── utils/                   # Utility functions
├── resources/                    # Resources and assets
│   ├── base/                    # Basic resources
│   └── rawfile/                 # Raw files (GeoJSON, styles)
└── oh_modules/                   # Dependencies
    └── maplibre_harmony          # MapLibre Harmony SDK
```

## Usage

### Running the Test Application

1. **Prerequisites**
   ```bash
   export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
   export NODE_HOME=/Applications/DevEco-Studio.app/Contents/tools/node
   ```

2. **Build and Run**
   ```bash
   cd platform/harmony
   
   # Build the entry module
   $NODE_HOME/bin/node \
     $DEVECO_SDK_HOME/../tools/hvigor/bin/hvigorw.js \
     --mode module \
     -p product=default \
     -p module=entry@default \
     -p buildMode=debug assembleHap \
     --analyze=normal \
     --parallel \
     --incremental \
     --no-daemon
   ```

3. **Install on Device**
   - Open DevEco Studio
   - Connect HarmonyOS device or emulator
   - Click "Run" to install and launch

### Navigating Test Pages

The application provides a categorized list of all test pages on the main screen. Simply tap on any test page to open it and interact with the test functionality.

Each test page includes:
- **Description** - Brief explanation of what is being tested
- **Controls** - Interactive UI elements (buttons, sliders, toggles)
- **Status Display** - Real-time feedback and logs
- **Test Actions** - Buttons to trigger specific test scenarios

## API Usage Examples

### LocationComponent

```typescript
const locationComponent = mapController.getLocationComponent();
const options = new LocationComponentOptions();
options.pulsingEnabled = true;
options.pulsingColor = '#0000FF';
options.pulsingMaxRadius = 100;

locationComponent.activateLocationComponent(options);
locationComponent.setLocationComponentEnabled(true);
locationComponent.setRenderMode(RenderMode.COMPASS);
locationComponent.setCameraMode(CameraMode.TRACKING);
```

### MapSnapshotter

```typescript
const options: SnapshotOptions = {
  size: { width: 800, height: 600 },
  pixelRatio: 2.0,
  styleUrl: 'https://demotiles.maplibre.org/style.json',
  cameraPosition: new CameraPosition(latLng, 14, 0, 0)
};

const snapshotter = new MapSnapshotter(options);
snapshotter.start(
  { onSnapshotReady: (snapshot) => {
    // Use the snapshot image
    console.log('Snapshot generated:', snapshot);
  }},
  { onError: (error) => {
    console.error('Snapshot error:', error);
  }}
);
```

### OfflineManager

```typescript
const offlineManager = OfflineManager.getInstance(context);

// List offline regions
const regions = await offlineManager.listOfflineRegions();

// Update region metadata
const metadata = { name: 'My Region', timestamp: Date.now() };
const buffer = JSON.stringify(metadata);
await region.updateMetadata(buffer);

// Download a region
const definition = new OfflineTilePyramidRegionDefinition(
  styleUrl, bounds, minZoom, maxZoom, pixelRatio
);
const region = await offlineManager.createOfflineRegion(definition, metadata);
```

### UiSettings

```typescript
const uiSettings = mapController.getUiSettings();

// Gesture controls
uiSettings.setScrollGesturesEnabled(true);
uiSettings.setZoomGesturesEnabled(true);
uiSettings.setRotateGesturesEnabled(true);
uiSettings.setTiltGesturesEnabled(true);

// UI component controls
uiSettings.setCompassEnabled(true);
uiSettings.setLogoEnabled(true);
uiSettings.setAttributionEnabled(true);
```

### Feature Querying

```typescript
// Query features at a point
const screenPoint = { x: 100, y: 200 };
const features = await mapController.queryRenderedFeatures(screenPoint);

// Query features in a box
const box = { left: 0, top: 0, right: 100, bottom: 100 };
const layerIds = ['poi-layer', 'building-layer'];
const features = await mapController.queryRenderedFeatures(box, layerIds);
```

## Known Limitations

### Core Library Issues
Some core MapLibre Harmony library files have type system issues that need to be resolved separately:
- `Expression.ets` - 298 ArkTS type errors
- `PropertyFactory.ets` - Type conversion issues
- `SymbolLayer.ets` - Object type casting problems

These are library-level issues and do not affect the test page implementations.

### Pending Features
Some test pages contain TODO markers for features that are placeholders:
- **BuildingFillExtrusionTestPage** - Complete FillExtrusionLayer implementation
- **ImageInLabelTestPage** - Custom image embedding in labels
- **StretchableImageTestPage** - 9-patch stretchable image support
- **MapSnapshotterBitmapOverlayTestPage** - Canvas drawing on snapshots

## Contributing

When adding new test pages:

1. Place them in the appropriate category directory
2. Use the `TestPageLayout` component for consistent UI
3. Follow ArkTS coding standards
4. Include proper error handling and user feedback
5. Add lifecycle management (aboutToAppear/aboutToDisappear)
6. Update this README with the new test page description

## Resources

- **MapLibre Native**: https://github.com/maplibre/maplibre-native
- **HarmonyOS Documentation**: https://developer.harmonyos.com/
- **Test Style Files**: `src/main/resources/rawfile/`
  - `styles.json` - Default style
  - `styles-demo.json` - Demo style with all layers
  - `amsterdam.geojson` - Sample GeoJSON data

## Version

- **MapLibre Harmony SDK**: See `oh_modules/maplibre_harmony/package.json`
- **HarmonyOS API Version**: API 12+
- **DevEco Studio**: 5.0.0+

## License

BSD-2-Clause License - See main project LICENSE file.

---

**Created**: 2025-10-31  
**Last Updated**: 2025-11-04  
**Maintained by**: MapLibre Harmony Team

