# Core Module

## Overview

The Core module provides the fundamental components for integrating MapLibre maps into HarmonyOS applications. It includes the main map view component, map controller, and configuration options.

## Classes

- [NativeMapView](#nativemapview) - Map view component
- [MapLibreMap](#maplibremap) - Map controller and API interface
- [MapLibreMapOptions](#maplibremapoptions) - Map configuration options

---

## NativeMapView

### Description

`NativeMapView` is the primary map component for displaying interactive maps in HarmonyOS applications. It wraps the native MapLibre rendering engine and provides a declarative ArkTS component interface.

### Constructor Parameters

```typescript
interface NativeMapViewParams {
  styleUrl?: string;                    // Map style URL
  initialLatitude?: number;             // Initial latitude (default: 30.2741)
  initialLongitude?: number;            // Initial longitude (default: 120.1551)
  initialZoom?: number;                 // Initial zoom level (default: 6)
  initialBearing?: number;              // Initial bearing/rotation (default: 0)
  initialPitch?: number;                // Initial pitch/tilt (default: 0)
  onMapReady?: (mapView?: NativeMapView) => void;  // Callback when map is ready
  onMapViewCreated?: (mapLibreMap: MapLibreMap) => void;  // Callback when MapLibreMap is created
}
```

### Key Methods

#### getMapAsync()

Retrieve the map instance asynchronously (Android-style API).

```typescript
getMapAsync(callback: OnMapReadyCallback): void
```

**Parameters:**
- `callback: OnMapReadyCallback` - Callback interface with `onMapReady(map: MapLibreMap)` method

**Example:**
```typescript
mapView.getMapAsync({
  onMapReady: (map: MapLibreMap) => {
    console.info('Map is ready!');
    // Perform map operations
  }
});
```

#### Rendering Control

##### setMaximumFps()

Set the maximum frame rate for map rendering.

```typescript
setMaximumFps(fps: number): void
```

**Parameters:**
- `fps: number` - Maximum frames per second (e.g., 30, 60)

**Example:**
```typescript
mapView.setMaximumFps(60);  // Enable 60 FPS rendering
```

##### setRenderingRefreshMode()

Set the rendering refresh mode.

```typescript
setRenderingRefreshMode(mode: RenderingRefreshMode): void
```

**Parameters:**
- `mode: RenderingRefreshMode` - Either `CONTINUOUS` or `WHEN_DIRTY`

**Example:**
```typescript
import { RenderingRefreshMode } from '@ohos/maplibre';

// Continuous rendering (smooth animations, higher battery usage)
mapView.setRenderingRefreshMode(RenderingRefreshMode.CONTINUOUS);

// On-demand rendering (power saving)
mapView.setRenderingRefreshMode(RenderingRefreshMode.WHEN_DIRTY);
```

##### queueEvent()

Execute a callback on the render thread.

```typescript
queueEvent(callback: () => void): void
```

**Parameters:**
- `callback: () => void` - Function to execute on render thread

**Example:**
```typescript
mapView.queueEvent(() => {
  console.info('This runs on the render thread');
});
```

#### Performance Configuration

##### setPrefetchesTiles()

Enable or disable tile prefetching for improved performance.

```typescript
setPrefetchesTiles(enabled: boolean): void
```

**Parameters:**
- `enabled: boolean` - `true` to enable prefetching

**Example:**
```typescript
mapView.setPrefetchesTiles(true);
```

##### Tile LOD Configuration

Configure Level of Detail (LOD) parameters for tile rendering.

```typescript
setTileLodMinRadius(radius: number): void
setTileLodScale(scale: number): void
setTileLodPitchThreshold(threshold: number): void
setTileLodZoomShift(shift: number): void
```

**Example:**
```typescript
mapView.setTileLodMinRadius(1.5);
mapView.setTileLodScale(1.2);
mapView.setTileLodPitchThreshold(Math.PI / 4);
mapView.setTileLodZoomShift(0);
```

#### Lifecycle Methods

##### onPageShow() / onPageHide()

Handle HarmonyOS page lifecycle events.

```typescript
onPageShow(): void
onPageHide(): void
```

**Example:**
```typescript
@Entry
@Component
struct MapPage {
  private mapView: NativeMapView | null = null;

  onPageShow() {
    this.mapView?.onPageShow();
  }

  onPageHide() {
    this.mapView?.onPageHide();
  }
}
```

##### onBackPress()

Handle back button press.

```typescript
onBackPress(): boolean | undefined
```

**Returns:** `true` if event is consumed, `false` or `undefined` otherwise

### Usage Example

```typescript
import { NativeMapView, MapLibreMap, RenderingRefreshMode } from '@ohos/maplibre';

@Entry
@Component
struct MapPage {
  private mapView: NativeMapView | null = null;
  private map: MapLibreMap | null = null;

  onPageShow() {
    this.mapView?.onPageShow();
  }

  onPageHide() {
    this.mapView?.onPageHide();
  }

  build() {
    NativeMapView({
      styleUrl: "https://demotiles.maplibre.org/style.json",
      initialLatitude: 39.9042,
      initialLongitude: 116.4074,
      initialZoom: 12,
      onMapReady: (mapView) => {
        this.mapView = mapView;
        console.info('Map view is ready!');
        
        // Configure rendering
        mapView?.setMaximumFps(60);
        mapView?.setRenderingRefreshMode(RenderingRefreshMode.CONTINUOUS);
      },
      onMapViewCreated: (mapLibreMap) => {
        this.map = mapLibreMap;
        console.info('MapLibreMap instance created!');
        
        // Perform map operations
        const zoom = this.map.getZoom();
        console.info(`Current zoom: ${zoom}`);
      }
    })
      .width('100%')
      .height('100%')
  }
}
```

---

## MapLibreMap

### Description

`MapLibreMap` is the main API interface for controlling the map. It provides methods for camera control, layer management, marker operations, and event handling. This class follows the Android/iOS MapLibre API design pattern.

### Key Properties

- `nativeMapView: NativeMapView` - Reference to the native map view (read-only)
- `style: Style` - Map style object (read-only)
- `uiSettings: UiSettings` - UI configuration settings

### Camera Control

#### getZoom() / setZoom()

Get or set the current zoom level.

```typescript
getZoom(): number
setZoom(zoom: number, options?: AnimationOptions): void
```

**Example:**
```typescript
const currentZoom = map.getZoom();
map.setZoom(14, { duration: 1000 });
```

#### getBearing() / setBearing()

Get or set the map bearing (rotation).

```typescript
getBearing(): number
setBearing(bearing: number, options?: AnimationOptions): void
```

**Example:**
```typescript
const bearing = map.getBearing();
map.setBearing(90, { duration: 500 });  // Rotate to 90 degrees
```

#### getPitch() / setPitch()

Get or set the map pitch (tilt).

```typescript
getPitch(): number
setPitch(pitch: number, options?: AnimationOptions): void
```

**Example:**
```typescript
const pitch = map.getPitch();
map.setPitch(45, { duration: 800 });  // Tilt to 45 degrees
```

#### getCameraPosition() / setCameraPosition()

Get or set the complete camera position.

```typescript
getCameraPosition(): CameraPosition
setCameraPosition(position: CameraPosition, options?: AnimationOptions): void
```

**Example:**
```typescript
import { CameraPosition, LatLng } from '@ohos/maplibre';

const position = new CameraPosition(
  new LatLng(39.9042, 116.4074),  // target
  14,   // zoom
  90,   // bearing
  45    // pitch
);

map.setCameraPosition(position, { duration: 2000 });
```

#### moveCamera() / animateCamera()

Move or animate the camera to a new position.

```typescript
moveCamera(position: CameraPosition): void
animateCamera(
  position: CameraPosition, 
  duration?: number, 
  callback?: CameraAnimationCallback
): void
```

**Example:**
```typescript
// Instant move
map.moveCamera(newPosition);

// Animated move with callback
map.animateCamera(newPosition, 2000, {
  onFinish: () => {
    console.info('Animation completed');
  },
  onCancel: () => {
    console.info('Animation cancelled');
  }
});
```

#### flyTo()

Perform a smooth "fly-to" animation to a new location.

```typescript
flyTo(position: CameraPosition, duration?: number): void
```

**Example:**
```typescript
import { CameraPosition, LatLng } from '@ohos/maplibre';

const target = new CameraPosition(
  new LatLng(31.2304, 121.4737),  // Shanghai
  12,
  0,
  0
);

map.flyTo(target, 3000);
```

### Style Management

#### getStyle()

Get the current map style object.

```typescript
getStyle(): Style | null
```

**Example:**
```typescript
const style = map.getStyle();
if (style) {
  console.info('Style loaded');
}
```

#### setStyleUrl() / setStyleJson()

Load a new map style.

```typescript
setStyleUrl(url: string): void
setStyleJson(json: string): void
```

**Example:**
```typescript
// Load from URL
map.setStyleUrl('https://demotiles.maplibre.org/style.json');

// Load from JSON string
map.setStyleJson(JSON.stringify(styleObject));
```

### Layer Management

#### addLayer() / removeLayer()

Add or remove a map layer.

```typescript
addLayer(layer: Layer, beforeId?: string): void
removeLayer(layerId: string): void
```

**Example:**
```typescript
import { FillLayer } from '@ohos/maplibre';

const fillLayer = new FillLayer('my-fill-layer', 'my-source');
fillLayer.setFillColor('#FF0000');
fillLayer.setFillOpacity(0.5);

map.addLayer(fillLayer);

// Later, remove it
map.removeLayer('my-fill-layer');
```

#### getLayer()

Get a layer by ID.

```typescript
getLayer(layerId: string): Layer | null
```

**Example:**
```typescript
const layer = map.getLayer('road-layer');
if (layer) {
  console.info('Layer found');
}
```

### Source Management

#### addSource() / removeSource()

Add or remove a data source.

```typescript
addSource(sourceId: string, source: Source): void
removeSource(sourceId: string): void
```

**Example:**
```typescript
import { GeoJsonSource } from '@ohos/maplibre';

const source = new GeoJsonSource('my-source', {
  type: 'geojson',
  data: {
    type: 'FeatureCollection',
    features: []
  }
});

map.addSource('my-source', source);
```

#### getSource()

Get a source by ID.

```typescript
getSource(sourceId: string): Source | null
```

### Marker Management

#### addMarker() / removeMarker()

Add or remove a marker.

```typescript
addMarker(marker: Marker): Marker
removeMarker(marker: Marker): void
```

**Example:**
```typescript
import { Marker, LatLng } from '@ohos/maplibre';

const marker = new Marker({
  position: new LatLng(39.9042, 116.4074),
  title: 'Beijing',
  snippet: 'Capital of China'
});

map.addMarker(marker);

// Later, remove it
map.removeMarker(marker);
```

### Query Methods

#### queryRenderedFeatures()

Query rendered features at a point or in a rectangle.

```typescript
queryRenderedFeatures(
  geometry: Point | Rect,
  layerIds?: string[]
): IFeature[]
```

**Example:**
```typescript
import { Point } from '@ohos/maplibre';

const features = map.queryRenderedFeatures(
  new Point(100, 200),
  ['poi-layer', 'building-layer']
);

features.forEach(feature => {
  console.info(`Feature: ${feature.id}`);
});
```

#### pixelForLatLng() / latLngForPixel()

Convert between geographic coordinates and screen pixels.

```typescript
pixelForLatLng(latitude: number, longitude: number): Point
latLngForPixel(x: number, y: number): LatLng
```

**Example:**
```typescript
// Geographic to screen coordinates
const point = map.pixelForLatLng(39.9042, 116.4074);
console.info(`Screen position: ${point.x}, ${point.y}`);

// Screen to geographic coordinates
const latLng = map.latLngForPixel(100, 200);
console.info(`Lat/Lng: ${latLng.latitude}, ${latLng.longitude}`);
```

### Event Listeners

#### Camera Listeners

```typescript
addOnCameraIdleListener(listener: OnCameraIdleListener): void
addOnCameraMoveStartedListener(listener: OnCameraMoveStartedListener): void
addOnCameraMoveListener(listener: OnCameraMoveListener): void
addOnCameraMoveCanceledListener(listener: OnCameraMoveCanceledListener): void
```

**Example:**
```typescript
map.addOnCameraIdleListener({
  onCameraIdle: () => {
    console.info('Camera stopped moving');
  }
});

map.addOnCameraMoveStartedListener({
  onCameraMoveStarted: (reason: CameraMoveReason) => {
    console.info(`Camera move started: ${reason}`);
  }
});
```

#### Map Click Listeners

```typescript
addOnMapClickListener(listener: OnMapClickListener): void
addOnMapLongClickListener(listener: OnMapLongClickListener): void
```

**Example:**
```typescript
map.addOnMapClickListener({
  onMapClick: (latLng: LatLng) => {
    console.info(`Map clicked at: ${latLng.latitude}, ${latLng.longitude}`);
    return true;  // Consume event
  }
});
```

### UI Settings

#### getUiSettings()

Get the UI settings object for configuring map controls and gestures.

```typescript
getUiSettings(): UiSettings
```

**Example:**
```typescript
const uiSettings = map.getUiSettings();
uiSettings.setCompassEnabled(true);
uiSettings.setZoomGesturesEnabled(true);
```

### Complete Usage Example

```typescript
import {
  NativeMapView,
  MapLibreMap,
  CameraPosition,
  LatLng,
  Marker,
  FillLayer,
  GeoJsonSource
} from '@ohos/maplibre';

@Entry
@Component
struct CompleteMapExample {
  private map: MapLibreMap | null = null;

  build() {
    NativeMapView({
      styleUrl: "https://demotiles.maplibre.org/style.json",
      initialLatitude: 39.9042,
      initialLongitude: 116.4074,
      initialZoom: 12,
      onMapViewCreated: (mapLibreMap) => {
        this.map = mapLibreMap;
        this.setupMap();
      }
    })
      .width('100%')
      .height('100%')
  }

  private setupMap() {
    if (!this.map) return;

    // Configure UI
    const uiSettings = this.map.getUiSettings();
    uiSettings.setCompassEnabled(true);
    uiSettings.setZoomGesturesEnabled(true);

    // Add marker
    const marker = new Marker({
      position: new LatLng(39.9042, 116.4074),
      title: 'Beijing'
    });
    this.map.addMarker(marker);

    // Add click listener
    this.map.addOnMapClickListener({
      onMapClick: (latLng: LatLng) => {
        console.info(`Clicked: ${latLng.latitude}, ${latLng.longitude}`);
        return true;
      }
    });

    // Add camera listener
    this.map.addOnCameraIdleListener({
      onCameraIdle: () => {
        const zoom = this.map?.getZoom();
        console.info(`Zoom level: ${zoom}`);
      }
    });
  }
}
```

---

## MapLibreMapOptions

### Description

`MapLibreMapOptions` is a configuration class for customizing map behavior, appearance, and performance. It provides extensive options for controlling rendering, interaction, and display properties.

### Constructor

```typescript
constructor(options?: Partial<MapLibreMapOptions>)
```

**Parameters:**
- `options?: Partial<MapLibreMapOptions>` - Optional configuration object

### Properties

#### Basic Configuration

```typescript
pixelRatio: number = 1.0;              // Device pixel ratio
contextMode: string = 'unique';        // Rendering context mode
crossSourceCollisions: boolean = true; // Enable cross-source collision detection
size: MapSize = { width: 256, height: 256 };  // Map size
```

#### Camera Configuration

```typescript
cameraPosition: CameraPosition | null = null;  // Initial camera position
bounds: LatLngBounds | null = null;            // Visible bounds
minZoom: number = 0;                           // Minimum zoom level
maxZoom: number = 22;                          // Maximum zoom level
minPitch: number = 0;                          // Minimum pitch (degrees)
maxPitch: number = 60;                         // Maximum pitch (degrees)
```

#### Style Configuration

```typescript
styleUrl: string = '';        // Map style URL
styleJson: string = '';       // Map style JSON string
```

#### Rendering Configuration

```typescript
renderWorldCopies: boolean = true;       // Render world copies when zoomed out
renderMode: string = 'normal';           // Rendering mode
constrainMode: string = 'heightOnly';    // Constraint mode for map bounds
viewportMode: string = 'default';        // Viewport mode
```

#### Debug Configuration

```typescript
debug: boolean = false;                  // Enable debug mode
attributionEnabled: boolean = true;      // Show attribution
logoEnabled: boolean = true;             // Show MapLibre logo
compassEnabled: boolean = true;          // Show compass
```

#### Interaction Configuration

```typescript
scrollEnabled: boolean = true;                  // Enable pan gestures
zoomEnabled: boolean = true;                    // Enable zoom gestures
rotateEnabled: boolean = true;                  // Enable rotation gestures
tiltEnabled: boolean = true;                    // Enable tilt gestures
doubleTapToZoomInEnabled: boolean = true;       // Double-tap to zoom
quickZoomEnabled: boolean = true;               // Quick zoom (one-finger zoom)
twoFingerTouchRotationEnabled: boolean = true;  // Two-finger rotation
twoFingerTouchPitchEnabled: boolean = true;     // Two-finger pitch
```

#### Performance Configuration

```typescript
prefetchTiles: boolean = true;         // Enable tile prefetching
prefetchZoomDelta: number = 4;         // Zoom delta for prefetching
tileCacheEnabled: boolean = true;      // Enable tile caching
```

#### Tile LOD Configuration

```typescript
tileLodMinRadius: number = 0;          // Minimum LOD radius
tileLodScale: number = 1.0;            // LOD scale factor
tileLodPitchThreshold: number = 0;     // Pitch threshold for LOD
tileLodZoomShift: number = 0;          // Zoom shift for LOD
```

#### Font Configuration

```typescript
localIdeographFontFamily: string | null = 'HarmonyOS_Sans';  // Local CJK font
localIdeographEnabled: boolean = true;                        // Enable local fonts
```

#### Animation Configuration

```typescript
transitionDuration: number = 300;      // Style transition duration (ms)
transitionDelay: number = 0;           // Style transition delay (ms)
```

### Usage Example

```typescript
import { MapLibreMapOptions, CameraPosition, LatLng } from '@ohos/maplibre';

// Create options with custom configuration
const options = new MapLibreMapOptions({
  styleUrl: 'https://demotiles.maplibre.org/style.json',
  pixelRatio: 2.0,
  cameraPosition: new CameraPosition(
    new LatLng(39.9042, 116.4074),
    12,
    0,
    0
  ),
  minZoom: 4,
  maxZoom: 18,
  maxPitch: 60,
  
  // Performance
  prefetchTiles: true,
  prefetchZoomDelta: 5,
  tileCacheEnabled: true,
  
  // Interaction
  scrollEnabled: true,
  zoomEnabled: true,
  rotateEnabled: true,
  tiltEnabled: true,
  
  // UI
  compassEnabled: true,
  logoEnabled: true,
  attributionEnabled: true,
  
  // Rendering
  renderWorldCopies: true,
  
  // Font
  localIdeographFontFamily: 'HarmonyOS_Sans',
  localIdeographEnabled: true
});

// Use options when creating map
// (Note: Currently MapLibreMap is created internally by NativeMapView)
```

---

**Last Updated:** 2025-11-04  
**Version:** 1.0.0

