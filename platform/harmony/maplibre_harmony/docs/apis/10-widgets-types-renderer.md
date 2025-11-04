# Widgets, Types & Renderer Modules

## Overview

This document covers UI widgets (compass, logo, scale bar), type definitions/enums, and rendering statistics.

---

## Widgets Module

### CompassView

Displays a compass indicating map rotation.

```typescript
@Component
struct CompassView {
  @Prop bearing: number;                      // Current map bearing
  @Prop visibility: CompassVisibility;        // Visibility mode
  @Prop position: OrnamentPosition;           // Screen position
  @Prop fadeWhenNorth: boolean;               // Fade when pointing north
  @Prop onClick?: () => void;                 // Click callback
}
```

**Usage:**
```typescript
CompassView({
  bearing: map.getBearing(),
  visibility: CompassVisibility.Adaptive,
  position: OrnamentPosition.TopRight,
  fadeWhenNorth: true,
  onClick: () => {
    // Reset bearing to north
    map.setBearing(0, { duration: 300 });
  }
})
```

### LogoView

Displays MapLibre logo (required by license).

```typescript
@Component
struct LogoView {
  @Prop position: OrnamentPosition;           // Screen position
  @Prop enabled: boolean;                     // Visibility
}
```

**Usage:**
```typescript
LogoView({
  position: OrnamentPosition.BottomLeft,
  enabled: true
})
```

### ScaleBarView

Displays map scale.

```typescript
@Component
struct ScaleBarView {
  @Prop metersPerPixel: number;               // Current scale
  @Prop unit: ScaleBarUnit;                   // Measurement unit
  @Prop position: OrnamentPosition;           // Screen position
  @Prop useDarkStyles: boolean;               // Dark/light theme
  @Prop enabled: boolean;                     // Visibility
}

enum ScaleBarUnit {
  Metric,    // Meters/Kilometers
  Imperial   // Feet/Miles
}
```

**Usage:**
```typescript
ScaleBarView({
  metersPerPixel: map.getMetersPerPixelAtLatitude(latLng.latitude),
  unit: ScaleBarUnit.Metric,
  position: OrnamentPosition.TopLeft,
  useDarkStyles: false,
  enabled: true
})
```

### AttributionButton

Displays attribution information.

```typescript
@Component
struct AttributionButton {
  @Prop attributions: AttributionInfo[];
  @Prop position: OrnamentPosition;
  @Prop enabled: boolean;
  @Prop onClick?: () => void;
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

**Usage:**
```typescript
AttributionButton({
  attributions: DEFAULT_ATTRIBUTIONS,
  position: OrnamentPosition.BottomRight,
  enabled: true,
  onClick: () => {
    // Show attribution dialog
  }
})
```

---

## Types Module

### OrnamentPosition

Enum for widget positioning.

```typescript
enum OrnamentPosition {
  TopLeft,
  TopRight,
  BottomLeft,
  BottomRight
}
```

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

Enum for camera movement reasons.

```typescript
enum CameraMoveReason {
  GESTURE,              // User gesture
  API_ANIMATION,        // Programmatic animation
  DEVELOPER_ANIMATION   // Developer-initiated animation
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
  Visible,    // Always visible
  Hidden,     // Always hidden
  Adaptive    // Show only when map is rotated
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

Provides rendering performance statistics.

```typescript
class RenderingStats {
  getEstimatedFps(): number;              // Estimated frames per second
  getFrameTime(): number;                 // Frame time in milliseconds
  getFrameCount(): number;                // Total frames rendered
  isFullyRendered(): boolean;             // Whether frame is fully rendered
}
```

**Usage:**
```typescript
map.addOnDidFinishRenderingFrameWithStatsListener({
  onDidFinishRenderingFrame: (fully: boolean, stats: RenderingStats) => {
    const fps = stats.getEstimatedFps();
    const frameTime = stats.getFrameTime();
    const frameCount = stats.getFrameCount();
    
    console.info(`FPS: ${fps.toFixed(1)}`);
    console.info(`Frame time: ${frameTime.toFixed(2)}ms`);
    console.info(`Total frames: ${frameCount}`);
    console.info(`Fully rendered: ${fully}`);
    
    // Alert if performance is poor
    if (fps < 30) {
      console.warn('Low frame rate detected');
    }
  }
});
```

### Performance Monitoring Example

```typescript
import {
  NativeMapView,
  MapLibreMap,
  RenderingStats,
  OnDidFinishRenderingFrameWithStatsListener
} from '@ohos/maplibre';

@Entry
@Component
struct PerformanceMonitor {
  private map: MapLibreMap | null = null;
  @State private fps: number = 0;
  @State private frameTime: number = 0;

  private fpsListener: OnDidFinishRenderingFrameWithStatsListener = {
    onDidFinishRenderingFrame: (fully: boolean, stats: RenderingStats) => {
      this.fps = stats.getEstimatedFps();
      this.frameTime = stats.getFrameTime();
    }
  };

  build() {
    Column() {
      // Performance overlay
      Row() {
        Text(`FPS: ${this.fps.toFixed(1)}`)
          .fontSize(14)
          .fontColor(this.fps < 30 ? Color.Red : Color.Green)
          .padding(5)
          .backgroundColor(Color.Black)
          .opacity(0.7)
        
        Text(`Frame: ${this.frameTime.toFixed(1)}ms`)
          .fontSize(14)
          .fontColor(Color.White)
          .padding(5)
          .backgroundColor(Color.Black)
          .opacity(0.7)
      }
      .position({ x: 10, y: 10 })
      .zIndex(1000)

      // Map
      NativeMapView({
        styleUrl: "https://demotiles.maplibre.org/style.json",
        onMapViewCreated: (mapLibreMap) => {
          this.map = mapLibreMap;
          this.map.addOnDidFinishRenderingFrameWithStatsListener(this.fpsListener);
        }
      })
        .width('100%')
        .height('100%')
    }
  }

  aboutToDisappear() {
    if (this.map) {
      this.map.removeOnDidFinishRenderingFrameWithStatsListener(this.fpsListener);
    }
  }
}
```

---

## Complete Widget Integration Example

```typescript
import {
  NativeMapView,
  MapLibreMap,
  CompassView,
  LogoView,
  ScaleBarView,
  AttributionButton,
  OrnamentPosition,
  CompassVisibility,
  ScaleBarUnit,
  DEFAULT_ATTRIBUTIONS
} from '@ohos/maplibre';

@Entry
@Component
struct CustomMapWithWidgets {
  private map: MapLibreMap | null = null;
  @State private bearing: number = 0;
  @State private metersPerPixel: number = 0;
  @State private showAttribution: boolean = false;

  build() {
    Stack() {
      // Map view
      NativeMapView({
        styleUrl: "https://demotiles.maplibre.org/style.json",
        onMapViewCreated: (mapLibreMap) => {
          this.map = mapLibreMap;
          this.setupWidgetUpdates();
        }
      })
        .width('100%')
        .height('100%')

      // Compass (top-right)
      CompassView({
        bearing: this.bearing,
        visibility: CompassVisibility.Adaptive,
        position: OrnamentPosition.TopRight,
        fadeWhenNorth: true,
        onClick: () => {
          this.map?.setBearing(0, { duration: 300 });
        }
      })
        .position({ right: 20, top: 20 })

      // Logo (bottom-left)
      LogoView({
        position: OrnamentPosition.BottomLeft,
        enabled: true
      })
        .position({ left: 10, bottom: 10 })

      // Scale bar (top-left)
      ScaleBarView({
        metersPerPixel: this.metersPerPixel,
        unit: ScaleBarUnit.Metric,
        position: OrnamentPosition.TopLeft,
        useDarkStyles: false,
        enabled: true
      })
        .position({ left: 10, top: 20 })

      // Attribution (bottom-right)
      AttributionButton({
        attributions: DEFAULT_ATTRIBUTIONS,
        position: OrnamentPosition.BottomRight,
        enabled: true,
        onClick: () => {
          this.showAttribution = true;
        }
      })
        .position({ right: 10, bottom: 10 })

      // Attribution dialog
      if (this.showAttribution) {
        Dialog({
          title: 'Attribution',
          message: DEFAULT_ATTRIBUTIONS.map(a => a.title).join('\n'),
          confirm: {
            value: 'Close',
            action: () => {
              this.showAttribution = false;
            }
          }
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  private setupWidgetUpdates() {
    // Update widgets on camera change
    this.map?.addOnCameraDidChangeListener({
      onCameraDidChange: () => {
        this.bearing = this.map?.getBearing() ?? 0;
        
        const latLng = this.map?.getLatLng();
        if (latLng) {
          this.metersPerPixel = this.map?.getMetersPerPixelAtLatitude(latLng.latitude) ?? 0;
        }
      }
    });
  }
}
```

---

**Last Updated:** 2025-11-04  
**Version:** 1.0.0

