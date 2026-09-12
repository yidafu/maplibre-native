# Widgets, Types & Renderer Modules

## Overview

This document covers UI widgets (compass, logo, scale bar, attribution), type definitions/enums, and rendering statistics.

> **Positioning note**: widget components are mounted automatically by
> `MapView`/`TextureMapView`. Their on-screen position is configured through
> `UiSettings` alignment setters (`setCompassAlignment`,
> `setLogoAlignment`, `setScaleBarAlignment`, `setAttributionAlignment`)
> with the ArkUI `Alignment` enum — see [02-ui-settings.md](./02-ui-settings.md).
> The legacy `*Position(OrnamentPosition)` setters were removed.

---

## Widgets Module

### CompassView

Displays a compass indicating map rotation; tapping it resets the camera to north. Mounted by MapView; configured via `UiSettings`.

```typescript
@Component
struct CompassView {
  @Prop compassEnabled: boolean = true;
  @Prop compassVisibility: CompassVisibility = CompassVisibility.Adaptive;
  @Prop fadeWhenFacingNorth: boolean = true;   // Fade when map faces north
  @Prop compassImage: Resource = $r('app.media.compass_icon');
  @Prop @Watch('onBearingChanged') externalBearing: number = 0;  // Fed by the map camera
}
```

**Configuration (recommended — via UiSettings):**
```typescript
const uiSettings = map.getUiSettings();
uiSettings.setCompassEnabled(true);
uiSettings.setCompassVisibility(CompassVisibility.Adaptive);
uiSettings.setCompassAlignment(Alignment.TopEnd); // positioning
```

### LogoView

Displays MapLibre logo (required by license). Mounted by MapView; configured via `UiSettings`.

```typescript
@Component
struct LogoView {
  @Prop logoImage: Resource = $r('app.media.maplibre_logo_helmet');
  @Prop logoEnabled: boolean = true;
  @Prop logoWidth: number | string = 'auto';
  @Prop logoHeight: number | string = 'auto';
}
```

**Configuration (recommended — via UiSettings):**
```typescript
uiSettings.setLogoEnabled(true);
uiSettings.setLogoAlignment(Alignment.BottomStart);
```

### ScaleBarView

Displays map scale. Mounted by MapView; configured via `UiSettings`.

```typescript
@Component
struct ScaleBarView {
  @Prop isEnabled: boolean = true;
  @Prop @Watch('onMetersPerPixelChanged') metersPerPixel: number = 0;
  @Prop unitSystem: ScaleBarUnit = ScaleBarUnit.Metric;
  @Prop useDarkStyles: boolean = false;
  @Prop primaryColor: string = '#122D11';
  @Prop secondaryColor: string = '#F7F7F7';
  @Prop maxWidth: number = 200;
}

enum ScaleBarUnit {
  Metric = 0,    // Meters/Kilometers
  Imperial = 1   // Feet/Miles
}
```

**Configuration (recommended — via UiSettings):**
```typescript
uiSettings.setScaleBarEnabled(true);
uiSettings.setScaleBarUnit(ScaleBarUnit.Metric);
uiSettings.setScaleBarAlignment(Alignment.TopStart);
```

### AttributionButton

Displays attribution information; tapping it opens the attribution dialog. Mounted by MapView; configured via `UiSettings`.

```typescript
@Component
struct AttributionButton {
  @Prop isEnabled: boolean = true;
  @Prop tintColor: string = '#000000';
  @Prop iconSize: number = 24;
  @Prop attributions: AttributionInfo[] = DEFAULT_ATTRIBUTIONS;
}

interface AttributionInfo {
  title: string;
  url?: string;
}

const DEFAULT_ATTRIBUTIONS: AttributionInfo[] = [
  { title: '© MapLibre', url: 'https://maplibre.org/' },
  { title: '© OpenStreetMap contributors', url: 'https://www.openstreetmap.org/copyright' }
];
```

**Configuration (recommended — via UiSettings):**
```typescript
uiSettings.setAttributionEnabled(true);
uiSettings.setAttributionAlignment(Alignment.BottomEnd);
```

---

## Types Module

### OrnamentPosition

Enum aligned with Android `MLNOrnamentPosition` and iOS `MLNOrnamentPosition`.

```typescript
enum OrnamentPosition {
  TopLeft = 0,
  TopRight = 1,
  BottomLeft = 2,
  BottomRight = 3
}
```

> The type remains exported for cross-platform API alignment, but current
> widget positioning uses the ArkUI `Alignment` enum through the
> `UiSettings.set*Alignment()` setters (see [02-ui-settings.md](./02-ui-settings.md)).

### RenderingRefreshMode

Enum for rendering modes.

```typescript
enum RenderingRefreshMode {
  CONTINUOUS,   // Render continuously (smooth animations, higher power)
  WHEN_DIRTY    // Render only when needed (power saving)
}
```

**Usage:**
```typescript
mapView.setRenderingRefreshMode(RenderingRefreshMode.WHEN_DIRTY);
```

### TileOperation

Enum for tile loading events.

```typescript
enum TileOperation {
  LOAD,    // Tile is being loaded
  REMOVE,  // Tile is being removed
  ERROR    // Tile loading error
}
```

### UserTrackingMode

Enum for location tracking modes.

```typescript
enum UserTrackingMode {
  NONE,               // No tracking
  FOLLOW,             // Follow user location
  FOLLOW_WITH_HEADING,  // Follow with heading
  FOLLOW_WITH_COURSE    // Follow with course
}
```

### CameraMoveReason

Enum for camera movement reasons (see `maps/camera/CameraMoveReason.ets`).

```typescript
enum CameraMoveReason {
  UNKNOWN = 0,             // Unknown reason
  GESTURE = 1,             // User gesture (pan, zoom, rotate, etc.)
  API_ANIMATION = 2,       // API invocation (e.g. jumpTo, setCenter)
  DEVELOPER_ANIMATION = 3, // Developer-provided animation (easeTo, flyTo)
  ANIMATION_CANCELLED = 4  // Animation cancelled
}
```

**Usage:**
```typescript
map.addOnCameraMoveStartedListener({
  onCameraMoveStarted: (reason: CameraMoveReason) => {
    if (reason === CameraMoveReason.GESTURE) {
      console.info('User is interacting with map');
    }
  }
});
```

### CompassVisibility

Enum for compass visibility modes.

```typescript
enum CompassVisibility {
  Adaptive = 0, // Show only when the map is not facing north
  Visible = 1,  // Always visible
  Hidden = 2    // Always hidden
}
```

### MapDebugOptions

Flags for debugging visualization.

```typescript
enum MapDebugOptions {
  None          = 0,
  TileBorders   = 1 << 0,  // Show tile boundaries
  ParseStatus   = 1 << 1,  // Show tile parse status
  Timestamps    = 1 << 2,  // Show tile timestamps
  Collision     = 1 << 3,  // Show collision boxes
  Overdraw      = 1 << 4,  // Show overdraw
  StencilClip   = 1 << 5,  // Show stencil clip
  DepthBuffer   = 1 << 6   // Show depth buffer
}
```

**Usage:**
```typescript
// Enable multiple debug options
const debugOptions = MapDebugOptions.TileBorders | MapDebugOptions.Collision;
map.setDebugOptions(debugOptions);

// Disable debug
map.setDebugOptions(MapDebugOptions.None);
```

### Margins

Type for padding/margins.

```typescript
interface Margins {
  left: number;
  top: number;
  right: number;
  bottom: number;
}
```

---

## Renderer Module

### RenderingStats

Frame statistics delivered by the rendering-frame listener.

```typescript
interface RenderingStats {
  fully: boolean;              // Whether the frame was fully rendered
  frameEncodingTime: number;   // Frame encoding time in milliseconds
  frameRenderingTime: number;  // Frame rendering time in milliseconds
}
```

**Usage:**
```typescript
map.addOnDidFinishRenderingFrameWithStatsListener({
  onDidFinishRenderingFrame: (stats: RenderingStats) => {
    console.info(`Fully rendered: ${stats.fully}`);
    console.info(`Encoding: ${stats.frameEncodingTime.toFixed(2)}ms`);
    console.info(`Rendering: ${stats.frameRenderingTime.toFixed(2)}ms`);

    if (stats.frameRenderingTime > 16) {
      console.warn('Frame time exceeds a 60fps budget');
    }
  }
});
```

### Performance Monitoring Example

```typescript
import {
  MapView,
  MapLibreMap,
  RenderingStats,
  OnDidFinishRenderingFrameWithStatsListener
} from 'maplibre_harmony';

@Entry
@Component
struct PerformanceMonitor {
  private map: MapLibreMap | null = null;
  @State private encodingTime: number = 0;
  @State private renderingTime: number = 0;

  private statsListener: OnDidFinishRenderingFrameWithStatsListener = {
    onDidFinishRenderingFrame: (stats: RenderingStats) => {
      this.encodingTime = stats.frameEncodingTime;
      this.renderingTime = stats.frameRenderingTime;
    }
  };

  build() {
    Column() {
      // Performance overlay
      Row() {
        Text(`Encode: ${this.encodingTime.toFixed(1)}ms`)
          .fontSize(14)
          .fontColor(this.encodingTime > 8 ? Color.Red : Color.Green)
          .padding(5)
          .backgroundColor(Color.Black)
          .opacity(0.7)

        Text(`Render: ${this.renderingTime.toFixed(1)}ms`)
          .fontSize(14)
          .fontColor(this.renderingTime > 8 ? Color.Red : Color.Green)
          .padding(5)
          .backgroundColor(Color.Black)
          .opacity(0.7)
      }
      .position({ x: 10, y: 10 })
      .zIndex(1000)

      // Map
      MapView({
        styleUrl: "https://demotiles.maplibre.org/style.json",
        onMapViewCreated: (mapLibreMap) => {
          this.map = mapLibreMap;
          this.map.addOnDidFinishRenderingFrameWithStatsListener(this.statsListener);
        }
      })
        .width('100%')
        .height('100%')
    }
  }

  aboutToDisappear() {
    if (this.map) {
      this.map.removeOnDidFinishRenderingFrameWithStatsListener(this.statsListener);
    }
  }
}
```

---

## Widget Configuration Example

Widgets are mounted by `MapView` automatically. Configure visibility and
placement through `UiSettings` — do not instantiate the widgets manually.

```typescript
import {
  MapView, MapLibreMap,
  ScaleBarUnit, CompassVisibility
} from 'maplibre_harmony';

@Entry
@Component
struct ConfiguredMapPage {
  private map: MapLibreMap | null = null;

  private onMapReady = (map: MapLibreMap): void => {
    this.map = map;

    const uiSettings = map.getUiSettings();
    uiSettings.setCompassEnabled(true);
    uiSettings.setCompassVisibility(CompassVisibility.Adaptive);
    uiSettings.setCompassAlignment(Alignment.TopEnd);

    uiSettings.setLogoEnabled(true);
    uiSettings.setLogoAlignment(Alignment.BottomStart);

    uiSettings.setScaleBarEnabled(true);
    uiSettings.setScaleBarUnit(ScaleBarUnit.Metric);
    uiSettings.setScaleBarAlignment(Alignment.TopStart);

    uiSettings.setAttributionEnabled(true);
    uiSettings.setAttributionAlignment(Alignment.BottomEnd);
  };

  build() {
    Column() {
      MapView({ onMapReady: this.onMapReady })
        .width('100%')
        .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}
```

---

**Last Updated:** 2026-09-12  
**Version:** 1.1.0

