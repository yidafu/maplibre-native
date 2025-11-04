# MapLibre Native for HarmonyOS

OpenGL-based vector map rendering library for HarmonyOS.

## Features

- 🗺️ Vector map rendering using OpenGL ES
- 📍 Marker and annotation support
- 🎨 Customizable map styles
- 📊 Multiple data source types (GeoJSON, Vector, Raster)
- 🎯 Rich gesture support
- 📷 Camera animations and controls
- 🧮 Expression system for dynamic styling
- 💾 Offline map support
- 📸 Map snapshot generation

## Feature Comparison: HarmonyOS vs Android vs iOS

| Feature Category          | Feature                           | HarmonyOS | Android | iOS |
| ------------------------- | --------------------------------- | --------- | ------- | --- |
| **Core Map**              | Vector Tile Rendering             | ✅         | ✅       | ✅   |
|                           | Style Loading (JSON/URL)          | ✅         | ✅       | ✅   |
|                           | Map Initialization                | ✅         | ✅       | ✅   |
|                           | Map Destruction                   | ✅         | ✅       | ✅   |
| **Camera Control**        | Move Camera                       | ✅         | ✅       | ✅   |
|                           | Animate Camera                    | ✅         | ✅       | ✅   |
|                           | Ease Camera                       | ✅         | ✅       | ✅   |
|                           | Fly To                            | ✅         | ✅       | ✅   |
|                           | Get Camera Position               | ✅         | ✅       | ✅   |
|                           | Set Bounds                        | ✅         | ✅       | ✅   |
|                           | Min/Max Zoom                      | ✅         | ✅       | ✅   |
|                           | Min/Max Pitch                     | ✅         | ✅       | ✅   |
| **Gestures**              | Pan (Scroll)                      | ✅         | ✅       | ✅   |
|                           | Pinch Zoom                        | ✅         | ✅       | ✅   |
|                           | Rotate                            | ✅         | ✅       | ✅   |
|                           | Tilt (Pitch)                      | ✅         | ✅       | ✅   |
|                           | Double Tap Zoom                   | ✅         | ✅       | ✅   |
|                           | Quick Zoom                        | ✅         | ✅       | ✅   |
|                           | Gesture Enable/Disable            | ✅         | ✅       | ✅   |
| **Markers & Annotations** | Add/Remove Marker                 | ✅         | ✅       | ✅   |
|                           | Marker Click Events               | ✅         | ✅       | ✅   |
|                           | Custom Marker Icons               | ✅         | ✅       | ✅   |
|                           | Polylines                         | ✅         | ✅       | ✅   |
|                           | Polygons                          | ✅         | ✅       | ✅   |
|                           | Info Windows                      | ⚠️         | ✅       | ✅   |
| **Style Control**         | Runtime Styling                   | ✅         | ✅       | ✅   |
|                           | Add/Remove Layers                 | ✅         | ✅       | ✅   |
|                           | Layer Properties                  | ✅         | ✅       | ✅   |
|                           | Filter Expressions                | ✅         | ✅       | ✅   |
|                           | Data-Driven Styling               | ✅         | ✅       | ✅   |
|                           | Add/Remove Images                 | ✅         | ✅       | ✅   |
|                           | Light Settings                    | ❌         | ✅       | ✅   |
| **Data Sources**          | GeoJSON Source                    | ✅         | ✅       | ✅   |
|                           | Vector Source                     | ✅         | ✅       | ✅   |
|                           | Raster Source                     | ✅         | ✅       | ✅   |
|                           | Raster DEM Source                 | ✅         | ✅       | ✅   |
|                           | Image Source                      | ✅         | ✅       | ✅   |
|                           | Video Source                      | ❌         | ✅       | ✅   |
| **Event Listeners**       | Map Click                         | ✅         | ✅       | ✅   |
|                           | Map Long Click                    | ✅         | ✅       | ✅   |
|                           | Camera Change                     | ✅         | ✅       | ✅   |
|                           | Camera Idle                       | ✅         | ✅       | ✅   |
|                           | Map Load                          | ✅         | ✅       | ✅   |
|                           | Style Load                        | ✅         | ✅       | ✅   |
|                           | Source Changed                    | ✅         | ✅       | ✅   |
|                           | 26 Event Listeners                | ✅         | ✅       | ✅   |
| **Performance**           | FPS Control                       | ✅         | ✅       | ✅   |
|                           | Render Mode (Continuous/OnDemand) | ✅         | ✅       | ✅   |
|                           | Prefetch Tiles                    | ❌         | ✅       | ✅   |
|                           | LOD Configuration                 | ❌         | ❌       | ✅   |
|                           | Debug Info                        | ❌         | ✅       | ✅   |
| **UI Settings**           | Compass                           | 🚧         | ✅       | ✅   |
|                           | Logo                              | 🚧         | ✅       | ✅   |
|                           | Attribution                       | 🚧         | ✅       | ✅   |
|                           | Scale Bar                         | 🚧         | ✅       | ✅   |
| **Offline Maps**          | Download Regions                  | ⚠️         | ✅       | ✅   |
|                           | Offline Manager                   | ⚠️         | ✅       | ✅   |
|                           | Region Status                     | ⚠️         | ✅       | ✅   |
|                           | Pack Database                     | ⚠️         | ✅       | ✅   |
| **Snapshots**             | Take Snapshot                     | ✅         | ✅       | ✅   |
|                           | Snapshot Options                  | ✅         | ✅       | ✅   |
|                           | Async Snapshot                    | 🚧         | ✅       | ✅   |
| **Query Features**        | Query Rendered Features           | ✅         | ✅       | ✅   |
|                           | Query Source Features             | ✅         | ✅       | ✅   |
|                           | Get Cluster Children              | 🚧         | ✅       | ✅   |
|                           | Get Cluster Leaves                | 🚧         | ✅       | ✅   |
| **Coordinate Conversion** | LatLng to Screen                  | ✅         | ✅       | ✅   |
|                           | Screen to LatLng                  | ✅         | ✅       | ✅   |
|                           | Meters to LatLng                  | ✅         | ✅       | ✅   |

### Legend
- ✅ **Fully Supported** - Feature is implemented and tested
- ⚠️ **Partial Support** - Feature is available with limitations
- ❌ **Not Supported** - Feature is not yet implemented
- 🚧 **In Progress** - Feature is under development

### Notes

1. **HarmonyOS** implementation follows MapLibre GL JS API design with Android/iOS conventions
2. All core features are **API-compatible** with Android and iOS versions
3. **OpenGL ES 3.0** backend provides hardware-accelerated rendering
4. **Thread-safe** callbacks enable seamless cross-thread communication
5. **DPI-aware** coordinate transformations ensure proper scaling on high-resolution displays

## Architecture

### Thread Model

MapLibre Native for HarmonyOS uses a multi-threaded architecture to ensure smooth performance:

```text
┌─────────────────────────────────────────────────────────────────────┐
│                          Thread Architecture                        │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────────────────┐      ┌──────────────────────────────┐
│     UI/Main Thread       │      │    Render Thread             │
│   (ArkTS/NAPI Layer)     │      │  (Map + OpenGL Rendering)    │
├──────────────────────────┤      ├──────────────────────────────┤
│                          │      │                              │
│  • User Interactions     │      │  • Map Core Instance         │
│  • Event Callbacks       │      │  • Renderer Instance         │
│  • UI Updates            │◀────▶│  • EGL Context               │
│  • API Calls             │ ①②  │  • OpenGL Drawing            │
│  • NativeMapView         │      │  • RunLoop (libuv)           │
│                          │      │  • VSync Management          │
└────────────┬─────────────┘      └────────────┬─────────────────┘
             │                                 │
             │ ③ ThreadSafeCallback           │ ④ Async Tasks
             │                                 │
             ▼                                 ▼
┌──────────────────────────────────────────────────────────────────┐
│                       Resource Thread Pool                       │
│                   (Network & File Operations)                    │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  • HTTP Requests (libcurl)          • Tile Downloads             │
│  • File I/O Operations              • Image Decoding             │
│  • Style Loading                    • GeoJSON Parsing            │
│  • Database Access (SQLite)         • Asset Loading              │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### Communication Mechanisms

**① API Calls (UI → Render Thread)**

<!-- ```text
User calls mapInstance.moveCamera()
  ↓
ArkTS → NAPI Bridge
  ↓
RunLoop::invoke() schedules task on Render Thread
  ↓
Map updates camera position
  ↓
Triggers rendering via VSync
``` -->

**② Event Callbacks (Render Thread → UI Thread)**

<!-- ```text
Map event occurs (e.g., onClick, onLoad)
  ↓
Map notifies observers
  ↓
ThreadSafeCallback queues callback
  ↓
NAPI converts to napi_value
  ↓
ArkTS listener invoked on UI thread
``` -->

**③ ThreadSafeCallback System**

<!-- ```text
┌─────────────────────────────────────────────┐
│       ThreadSafeCallback Manager            │
├─────────────────────────────────────────────┤
│  • Thread-safe callback queue               │
│  • Automatic thread switching               │
│  • Reference counting for JS objects        │
│  • Safe cleanup on destruction              │
└─────────────────────────────────────────────┘
``` -->

**④ Resource Loading (Async)**

<!-- ```text
Map requests tile/style/image
  ↓
FileSource schedules network request
  ↓
Resource Thread Pool executes
  ↓
Downloads via libcurl
  ↓
Decodes/Parses data
  ↓
Callback to Render Thread via RunLoop
  ↓
Map updates and triggers render
``` -->

### Key Features

- **Single Render Thread**: Map and Renderer share one thread (iOS-style architecture)
- **Thread-Safe**: All cross-thread communication uses RunLoop and ThreadSafeCallback
- **Non-Blocking UI**: Resource loading never blocks user interaction
- **VSync-Driven**: Rendering synchronized with display refresh rate
- **Efficient**: Minimizes context switching and lock contention

## Installation

### Prerequisites

- **HarmonyOS SDK**: 5.0.0 (API 12) or higher
- **DevEco Studio**: 5.0.5 or higher
- **Node.js**: 18.0.0 or higher

### From npm registry

> ohpm registry not support.

```bash
npm install maplibre-harmony
```

Add to your module's `oh-package.json5`:

```json5
{
  "dependencies": {
    "maplibre_harmony": "file:./node_modules/maplibre-harmony/maplibre_harmony.har"
  }
}
```

## Usage

### Basic Map

```typescript
import { NativeMapView, MapLibreMap, CameraPosition } from 'maplibre-harmony';

@Entry
@Component
struct MapPage {
  private mapInstance?: MapLibreMap;

  build() {
    Column() {
      NativeMapView({
        styleUrl: 'https://demotiles.maplibre.org/style.json',
        cameraPosition: new CameraPosition(
          116.397128, // longitude
          39.916527,  // latitude
          12,         // zoom
          0,          // bearing
          0           // tilt
        ),
        onMapReady: (map: MapLibreMap) => {
          this.mapInstance = map;
          console.log('Map is ready!');
        }
      })
        .width('100%')
        .height('100%')
    }
  }
}
```

### Adding Markers

```typescript
import { MarkerOptions, LatLng } from 'maplibre-harmony';

// Add a marker with custom options
const marker = this.mapInstance?.addMarker(
  new MarkerOptions()
    .position(new LatLng(39.916527, 116.397128))
    .title('Beijing')
    .snippet('Capital of China')
);

// Add marker click listener
marker?.setOnMarkerClickListener({
  onMarkerClick: (clickedMarker) => {
    console.log('Marker clicked:', clickedMarker.getTitle());
    return true; // consume the event
  }
});
```

### Camera Animations

```typescript
import { CameraUpdateFactory } from 'maplibre-harmony';

// Animate to a new position
this.mapInstance?.animateCamera(
  CameraUpdateFactory.newLatLngZoom(
    new LatLng(31.230416, 121.473701),
    14
  ),
  1000, // duration in milliseconds
  {
    onFinish: () => console.log('Animation finished'),
    onCancel: () => console.log('Animation cancelled')
  }
);

// Fly to with easing
this.mapInstance?.flyTo(
  CameraUpdateFactory.newCameraPosition(
    new CameraPosition(121.473701, 31.230416, 15, 45, 60)
  )
);
```

### Event Listeners

```typescript
// Map click listener
this.mapInstance?.addOnMapClickListener({
  onMapClick: (latLng: LatLng) => {
    console.log('Map clicked at:', latLng.latitude, latLng.longitude);
    return false;
  }
});

// Camera change listener
this.mapInstance?.addOnCameraMoveListener({
  onCameraMove: () => {
    const position = this.mapInstance?.getCameraPosition();
    console.log('Camera moved to:', position);
  }
});

// Style load listener
this.mapInstance?.addOnStyleLoadedListener({
  onStyleLoaded: () => {
    console.log('Style loaded, ready to add layers');
  }
});
```

### Runtime Styling

```typescript
// Add a GeoJSON source
this.mapInstance?.getStyle()?.addSource('my-source', {
  type: 'geojson',
  data: {
    type: 'Feature',
    geometry: {
      type: 'Point',
      coordinates: [116.397128, 39.916527]
    }
  }
});

// Add a circle layer
this.mapInstance?.getStyle()?.addLayer({
  id: 'my-layer',
  type: 'circle',
  source: 'my-source',
  paint: {
    'circle-radius': 10,
    'circle-color': '#FF0000'
  }
});
```

## API Quick Reference

### Core Classes

- **`MapLibreMap`** - Main map instance
- **`NativeMapView`** - ArkTS map component
- **`CameraPosition`** - Camera position and orientation
- **`LatLng`** - Geographic coordinates
- **`LatLngBounds`** - Geographic bounds

### Key Methods

| Method                    | Description                        |
| ------------------------- | ---------------------------------- |
| `moveCamera()`            | Move camera instantly              |
| `animateCamera()`         | Animate camera smoothly            |
| `flyTo()`                 | Fly to location with easing        |
| `addMarker()`             | Add a marker to the map            |
| `addPolyline()`           | Add a polyline                     |
| `addPolygon()`            | Add a polygon                      |
| `getStyle()`              | Get style for runtime manipulation |
| `queryRenderedFeatures()` | Query features at point            |
| `snapshot()`              | Take a map snapshot                |

### Event Listeners (26 total)

- Map Events: `onClick`, `onLongClick`, `onFling`
- Camera Events: `onMove`, `onMoveStart`, `onMoveEnd`, `onIdle`
- Style Events: `onStyleLoaded`, `onStyleImageMissing`
- Source Events: `onSourceChanged`, `onSourceDataLoaded`
- And 15 more...

For complete API documentation, see the [`/docs`](./docs/) directory.

## Building from Source

### Build Commands

```bash
cd platform/harmony/maplibre_harmony

./pre-release.sh
```

### Build Output

The compiled HAR will be at:
```
build/default/outputs/default/maplibre-harmony.har
```

## Troubleshooting

### Map not rendering
1. Verify OpenGL ES 3.0 support
2. Check style URL accessibility
3. Inspect HiLog: `hdc hilog | grep MapLibre`

### Build errors
1. Clean build cache: `npm run clean`
2. Verify environment variables are set
3. Check HarmonyOS SDK version (≥5.0.0)

### Gesture issues
1. Ensure proper DPI configuration
2. Check XComponent touch event handling
3. Verify gesture settings are enabled

## Documentation

### API Documentation
- **[API Documentation Index](./docs/api/INDEX.md)** 📚 - Complete API documentation hub
- **[API Reference](./docs/api/README.md)** - Core API overview and quick start
- **[Usage Guide](./docs/api/USAGE_GUIDE.md)** - Detailed usage examples and patterns
- **[Implementation Progress](./docs/api/ALIGNMENT_PROGRESS.md)** - API alignment status

## Examples

See the [`entry`](../entry/) module for complete working examples:
- Basic map display
- Marker management
- Camera animations
- Runtime styling
- Gesture handling
- Offline maps
- Custom layers

## Contributing

We welcome contributions! Please see the main repository's [CONTRIBUTING.md](../../../CONTRIBUTING.md) for guidelines.

### Development Setup

1. Clone the repository
2. Set up environment variables
3. Build the project: `npm run build:debug`
4. Run tests in DevEco Studio

## License

BSD-2-Clause License - See [LICENSE.md](../../../LICENSE.md)

## Links

- **MapLibre Website**: https://maplibre.org
- **GitHub Repository**: https://github.com/yidafu/maplibre-native/tree/hmos/harmony
- **Issue Tracker**: https://github.com/yidafu/maplibre-native/issues
- **HarmonyOS Documentation**: https://developer.huawei.com/consumer/en/harmonyos/
- **OpenHarmony**: https://www.openharmony.cn/

## Support

- **Documentation**: See `/docs` directory
- **Issues**: Report bugs on GitHub Issues
- **Discussions**: Join MapLibre community discussions
- **Commercial Support**: Contact MapLibre team

---

Made with ❤️ by the MapLibre community
