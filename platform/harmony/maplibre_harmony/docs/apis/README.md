# MapLibre Harmony API Documentation

Welcome to the MapLibre Native for HarmonyOS API documentation. This documentation provides comprehensive coverage of all public APIs, organized by functional modules.

## Quick Links

- **Getting Started**: See [01-core.md](./01-core.md#usage-example) for basic usage
- **Full Documentation**: Browse modules below by category
- **Examples**: Each module includes complete code examples
- **Main Docs**: See `../api/` directory for additional guides

## API Modules

### Core Modules

#### [01. Core Module](./01-core.md)
**Primary map components and controllers**

- `NativeMapView` - Map view component
- `MapLibreMap` - Map controller and API interface
- `MapLibreMapOptions` - Map configuration options

**Key Features**: Map initialization, camera control, layer management, source management, marker operations

#### [02. UI Settings Module](./02-ui-settings.md)
**UI configuration and gesture control**

- `UiSettings` - Main UI configuration class
- `FocalPoint` - Gesture focal point
- `CompassMargins` - Margins configuration

**Key Features**: Gesture enablement, compass/logo/scale bar configuration, inertial animations, UI widget positioning

#### [03. Geometry Module](./03-geometry.md)
**Geographic and screen coordinate types**

- `LatLng` - Geographic coordinates (latitude/longitude)
- `LatLngBounds` - Geographic bounding box
- `Point` - Screen pixel coordinates
- `Rect` - Screen rectangle
- `ProjectedMeters` - Projected coordinate system

**Key Features**: Coordinate creation, distance calculations, bounds operations, spatial queries

---

### Interaction Modules

#### [04. Camera Module](./04-camera.md)
**Camera position and animation control**

- `CameraPosition` - Camera state definition
- `EdgeInsets` - Padding/insets for camera bounds
- `CameraAnimationCallback` - Animation lifecycle callbacks
- Camera Listeners - Movement event notifications

**Key Features**: Camera positioning, smooth animations, flyTo transitions, camera tracking

#### [05. Annotations Module](./05-annotations.md)
**Markers, lines, polygons, and custom overlays**

- `Marker` - Point markers with icons
- `MarkerOptions` - Marker configuration
- `Icon` & `IconFactory` - Custom marker icons
- `Polyline` - Line annotations
- `Polygon` - Polygon annotations
- `InfoWindow` - Information popups
- `AnnotationView` - Custom annotation views

**Key Features**: Marker management, draggable markers, info windows, custom icons, lines and polygons

#### [06. Listeners Module](./06-listeners.md)
**Event notification interfaces**

Categories:
- Camera Events - Camera movement notifications
- Map Loading Events - Map lifecycle events
- Rendering Events - Frame rendering notifications
- Style Events - Style loading and image management
- Gesture Events - User input handling
- Marker Events - Marker interaction events
- Other Events - Shader, glyph, tile, sprite events

**Key Features**: Event-driven programming, reactive map interactions, performance monitoring

---

### Styling Modules

#### [07. Style, Expressions & Sources Module](./07-style-expressions-sources.md)
**Map appearance and data-driven styling**

**Style System**:
- `Style` - Style management
- Layer types: `FillLayer`, `LineLayer`, `CircleLayer`, `SymbolLayer`, `RasterLayer`, etc.
- `Light` - Map lighting

**Expressions**:
- `Expression` - Data-driven styling expressions
- Math, comparison, logic, conditional, interpolation functions

**Sources**:
- `GeoJsonSource` - GeoJSON data source
- `VectorSource` - Vector tile source
- `RasterSource` - Raster tile source
- `RasterDemSource` - DEM source
- `ImageSource` - Single image source

**Key Features**: Dynamic styling, data-driven properties, multiple layer types, various data sources

---

### Data Modules

#### [08. GeoJSON & Projection Module](./08-geojson-projection.md)
**Geographic data and coordinate conversion**

**GeoJSON**:
- Complete GeoJSON type definitions (RFC 7946)
- Geometry types: Point, LineString, Polygon, etc.
- Feature and FeatureCollection
- GeoJSON clustering

**Projection**:
- `Projection` - Coordinate conversion utilities
- `VisibleRegion` - Visible map region
- Screen ↔ Geographic conversion
- Geographic ↔ Projected meters conversion

**Key Features**: GeoJSON support, coordinate transformations, visible region queries

---

### Advanced Features

#### [09. Offline, Snapshot & Location Module](./09-offline-snapshot-location.md)
**Offline maps, snapshots, and location services**

**Offline Maps**:
- `OfflineManager` - Offline region management
- `OfflineRegion` - Offline map regions
- `OfflineRegionDefinition` - Region definitions
- Download progress tracking

**Snapshots**:
- `MapSnapshotter` - Static map image generation
- `MapSnapshot` - Generated snapshot
- `SnapshotOptions` - Snapshot configuration

**Location**:
- `LocationComponent` - User location display
- `LocationEngine` - Location services integration
- `HarmonyLocationEngine` - HarmonyOS location provider
- `RenderMode` & `CameraMode` - Location display modes

**Key Features**: Offline map downloads, static map generation, real-time location tracking

---

### UI Components

#### [10. Widgets, Types & Renderer Module](./10-widgets-types-renderer.md)
**UI widgets, enums, and performance monitoring**

**Widgets**:
- `CompassView` - Compass widget
- `LogoView` - MapLibre logo
- `ScaleBarView` - Scale bar
- `AttributionButton` - Attribution display

**Types & Enums**:
- `OrnamentPosition` - Widget positioning
- `RenderingRefreshMode` - Rendering modes
- `TileOperation` - Tile events
- `CameraMoveReason` - Camera movement reasons
- `CompassVisibility` - Compass visibility modes
- `MapDebugOptions` - Debug visualization flags

**Renderer**:
- `RenderingStats` - Performance statistics
- FPS monitoring
- Frame time tracking

**Key Features**: Customizable UI widgets, comprehensive type definitions, performance monitoring

---

## Getting Started

### Basic Example

```typescript
import { NativeMapView, MapLibreMap } from '@ohos/maplibre';

@Entry
@Component
struct BasicMap {
  private map: MapLibreMap | null = null;

  build() {
    NativeMapView({
      styleUrl: "https://demotiles.maplibre.org/style.json",
      initialLatitude: 39.9042,
      initialLongitude: 116.4074,
      initialZoom: 12,
      onMapViewCreated: (mapLibreMap) => {
        this.map = mapLibreMap;
        console.info('Map ready!');
      }
    })
      .width('100%')
      .height('100%')
  }
}
```

### Common Tasks

#### Adding a Marker

```typescript
import { Marker, LatLng } from '@ohos/maplibre';

const marker = new Marker({
  position: new LatLng(39.9042, 116.4074),
  title: 'Beijing',
  snippet: 'Capital of China'
});
map.addMarker(marker);
```

#### Animating Camera

```typescript
import { CameraPosition, LatLng } from '@ohos/maplibre';

const position = new CameraPosition(
  new LatLng(31.2304, 121.4737),
  14,
  0,
  45
);
map.flyTo(position, 2000);
```

#### Adding a Layer

```typescript
import { GeoJsonSource, CircleLayer } from '@ohos/maplibre';

// Add source
const source = new GeoJsonSource('my-data', {
  data: { type: 'FeatureCollection', features: [] }
});
map.addSource('my-data', source);

// Add layer
const layer = new CircleLayer('my-points', 'my-data');
layer.setCircleRadius(8).setCircleColor('#FF0000');
map.addLayer(layer);
```

#### Listening to Events

```typescript
map.addOnMapClickListener({
  onMapClick: (latLng) => {
    console.info(`Clicked: ${latLng.latitude}, ${latLng.longitude}`);
    return true;
  }
});

map.addOnCameraIdleListener({
  onCameraIdle: () => {
    console.info('Camera stopped moving');
  }
});
```

## API Design Principles

### Android/iOS Compatibility

MapLibre Harmony follows Android and iOS API patterns:

- **Android-style**: Method names, listener interfaces, manager classes
- **iOS-style**: Delegate patterns adapted to TypeScript interfaces
- **HarmonyOS-native**: Lifecycle methods (`onPageShow`, `onPageHide`)

### Type Safety

- Full TypeScript type definitions
- Strong typing for all APIs
- Interface-based listener patterns
- Enum types for constants

### Fluent API

Many methods return `this` for method chaining:

```typescript
layer
  .setFillColor('#FF0000')
  .setFillOpacity(0.5)
  .setMinZoom(10)
  .setMaxZoom(18);
```

## Performance Tips

1. **Use `WHEN_DIRTY` rendering mode** for power savings:
   ```typescript
   mapView.setRenderingRefreshMode(RenderingRefreshMode.WHEN_DIRTY);
   ```

2. **Enable tile prefetching** for smoother experience:
   ```typescript
   mapView.setPrefetchesTiles(true);
   ```

3. **Monitor performance** with rendering stats:
   ```typescript
   map.addOnDidFinishRenderingFrameWithStatsListener({
     onDidFinishRenderingFrame: (fully, stats) => {
       console.info(`FPS: ${stats.getEstimatedFps()}`);
     }
   });
   ```

4. **Clean up listeners** to prevent memory leaks:
   ```typescript
   aboutToDisappear() {
     map.removeOnMapClickListener(this.clickListener);
   }
   ```

## Additional Resources

- **API Reference (Chinese)**: `../api/README_zh.md`
- **Usage Guide**: `../api/USAGE_GUIDE.md`
- **Implementation Guide**: `../api/CPP_NAPI_BINDING_GUIDE.md`
- **Migration Guide**: `../guides/CAMERA_API_MIGRATION_GUIDE.md`
- **Quick Start**: `../guides/QUICK_START.md`

## Version Information

- **API Version**: 1.0.0
- **Last Updated**: 2025-11-04
- **HarmonyOS Compatibility**: API 10+
- **MapLibre GL Native Version**: Based on MapLibre Native v2.x

## Support

For issues, questions, or contributions:
- Check existing documentation in `docs/` directory
- Review troubleshooting guides in `docs/troubleshooting/`
- Consult implementation notes in `docs/implementation/`

---

**Note**: This is a comprehensive API reference. For tutorial-style documentation, see the guides in `../guides/` directory.

