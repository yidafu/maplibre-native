# Camera Module

## Overview

The Camera module provides comprehensive control over the map's camera position, orientation, and animation. It includes classes for defining camera states, animation callbacks, and event listeners for camera movement.

## Classes

- [CameraPosition](#cameraposition) - Camera state definition
- [EdgeInsets](#edgeinsets) - Padding/insets for camera bounds
- [CameraAnimationCallback](#cameraanimationcallback) - Animation lifecycle callbacks
- [CameraListener Interfaces](#camera-listeners) - Camera movement event listeners

---

## CameraPosition

### Description

`CameraPosition` defines the complete state of the map camera, including target location, zoom level, bearing (rotation), and pitch (tilt).

### Constructor

```typescript
constructor(target: LatLng, zoom: number, bearing: number = 0, tilt: number = 0)
```

**Parameters:**
- `target: LatLng` - Target geographic coordinate
- `zoom: number` - Zoom level (typically 0-22)
- `bearing: number` - Bearing/rotation in degrees (0-360, default: 0)
- `tilt: number` - Pitch/tilt in degrees (0-60, default: 0)

### Properties

```typescript
target: LatLng    // Camera target coordinates
zoom: number      // Zoom level
bearing: number   // Rotation angle (degrees)
tilt: number      // Pitch angle (degrees)
```

### Static Methods

#### fromObject()

Create from a plain object.

```typescript
static fromObject(obj: ICameraPosition): CameraPosition
```

### Instance Methods

#### toObject()

Convert to plain object.

```typescript
toObject(): ICameraPosition
```

**Returns:** `{ target: LatLng, zoom: number, bearing: number, tilt: number }`

### Usage Example

```typescript
import { CameraPosition, LatLng } from '@ohos/maplibre';

// Create camera position
const position = new CameraPosition(
  new LatLng(39.9042, 116.4074),  // Beijing
  14,   // Zoom level
  90,   // Bearing (facing east)
  45    // Tilt (45 degrees)
);

// Apply to map
map.setCameraPosition(position);

// Animate to position
map.animateCamera(position, 2000, {
  onFinish: () => {
    console.info('Camera animation completed');
  }
});

// Fly to position
map.flyTo(position, 3000);
```

---

## EdgeInsets

### Description

`EdgeInsets` defines padding from screen edges, used for constraining the camera to ensure important content isn't obscured by UI elements.

### Constructor

```typescript
constructor(top: number = 0, left: number = 0, bottom: number = 0, right: number = 0)
```

**Parameters:**
- `top: number` - Top padding in pixels (default: 0)
- `left: number` - Left padding in pixels (default: 0)
- `bottom: number` - Bottom padding in pixels (default: 0)
- `right: number` - Right padding in pixels (default: 0)

### Properties

```typescript
top: number       // Top padding
left: number      // Left padding
bottom: number    // Bottom padding
right: number     // Right padding
```

### Static Methods

#### fromObject()

Create from a plain object.

```typescript
static fromObject(obj: IEdgeInsets): EdgeInsets
```

### Instance Methods

#### toObject()

Convert to plain object.

```typescript
toObject(): IEdgeInsets
```

### Usage Example

```typescript
import { EdgeInsets } from '@ohos/maplibre';

// Create insets with 100px padding on all sides
const insets = new EdgeInsets(100, 100, 100, 100);

// Use with camera operations
const cameraOptions = {
  center: new LatLng(39.9042, 116.4074),
  zoom: 12,
  padding: insets
};

// Apply padding when fitting bounds
map.fitBounds(bounds, insets, 1000);
```

---

## CameraAnimationCallback

### Description

`CameraAnimationCallback` provides lifecycle callbacks for camera animations, allowing you to execute code when animations complete or are cancelled.

### Interface

```typescript
interface CameraAnimationCallback {
  onFinish?: () => void;    // Called when animation completes normally
  onCancel?: () => void;    // Called when animation is cancelled
}
```

### AnimationOptions

Extended options for camera animations:

```typescript
interface AnimationOptions {
  duration?: number;                       // Animation duration in milliseconds
  callback?: CameraAnimationCallback;      // Animation callbacks
}
```

### Usage Example

```typescript
import { CameraPosition, CameraAnimationCallback } from '@ohos/maplibre';

const callback: CameraAnimationCallback = {
  onFinish: () => {
    console.info('Animation completed successfully');
    // Perform post-animation actions
  },
  onCancel: () => {
    console.info('Animation was cancelled');
    // Handle cancellation
  }
};

// Use with animateCamera
const newPosition = new CameraPosition(
  new LatLng(31.2304, 121.4737),
  12,
  0,
  0
);

map.animateCamera(newPosition, 2000, callback);

// Or with options
map.animateCamera(newPosition, 2000, {
  onFinish: () => console.info('Done'),
  onCancel: () => console.info('Cancelled')
});
```

---

## Camera Listeners

### Overview

Camera listeners provide real-time notifications about camera movement and state changes. They follow the Android/iOS camera listener pattern.

### OnCameraIdleListener

Notifies when the camera becomes idle (stops moving).

```typescript
interface OnCameraIdleListener {
  onCameraIdle(): void;
}
```

**Example:**
```typescript
map.addOnCameraIdleListener({
  onCameraIdle: () => {
    console.info('Camera is now idle');
    const position = map.getCameraPosition();
    console.info(`Final position: ${position.target.latitude}, ${position.target.longitude}`);
  }
});
```

### OnCameraMoveStartedListener

Notifies when the camera starts moving, including the reason for movement.

```typescript
interface OnCameraMoveStartedListener {
  onCameraMoveStarted(reason: CameraMoveReason): void;
}
```

**CameraMoveReason Enum:**
- `GESTURE` - User gesture initiated
- `API_ANIMATION` - Programmatic animation
- `DEVELOPER_ANIMATION` - Developer-initiated animation

**Example:**
```typescript
import { CameraMoveReason } from '@ohos/maplibre';

map.addOnCameraMoveStartedListener({
  onCameraMoveStarted: (reason: CameraMoveReason) => {
    switch (reason) {
      case CameraMoveReason.GESTURE:
        console.info('User is panning/zooming the map');
        break;
      case CameraMoveReason.API_ANIMATION:
        console.info('Map is animating programmatically');
        break;
      case CameraMoveReason.DEVELOPER_ANIMATION:
        console.info('Developer animation started');
        break;
    }
  }
});
```

### OnCameraMoveListener

Notifies continuously while the camera is moving.

```typescript
interface OnCameraMoveListener {
  onCameraMove(): void;
}
```

**Example:**
```typescript
map.addOnCameraMoveListener({
  onCameraMove: () => {
    // Called frequently during movement
    const zoom = map.getZoom();
    console.info(`Current zoom: ${zoom.toFixed(2)}`);
  }
});
```

### OnCameraMoveCanceledListener

Notifies when a camera animation is cancelled.

```typescript
interface OnCameraMoveCanceledListener {
  onCameraMoveCanceled(): void;
}
```

**Example:**
```typescript
map.addOnCameraMoveCanceledListener({
  onCameraMoveCanceled: () => {
    console.info('Camera animation was cancelled');
  }
});
```

### Adding and Removing Listeners

```typescript
// Add listeners
map.addOnCameraIdleListener(idleListener);
map.addOnCameraMoveStartedListener(moveStartedListener);
map.addOnCameraMoveListener(moveListener);
map.addOnCameraMoveCanceledListener(canceledListener);

// Remove listeners
map.removeOnCameraIdleListener(idleListener);
map.removeOnCameraMoveStartedListener(moveStartedListener);
map.removeOnCameraMoveListener(moveListener);
map.removeOnCameraMoveCanceledListener(canceledListener);
```

### Complete Camera Control Example

```typescript
import {
  NativeMapView,
  MapLibreMap,
  CameraPosition,
  LatLng,
  EdgeInsets,
  CameraAnimationCallback,
  OnCameraIdleListener,
  OnCameraMoveStartedListener,
  OnCameraMoveListener,
  CameraMoveReason
} from '@ohos/maplibre';

@Entry
@Component
struct CameraExample {
  private map: MapLibreMap | null = null;
  private isAnimating: boolean = false;

  // Define listeners
  private idleListener: OnCameraIdleListener = {
    onCameraIdle: () => {
      this.isAnimating = false;
      const pos = this.map?.getCameraPosition();
      console.info(`Camera idle at: ${pos?.target.latitude}, ${pos?.target.longitude}`);
    }
  };

  private moveStartedListener: OnCameraMoveStartedListener = {
    onCameraMoveStarted: (reason: CameraMoveReason) => {
      this.isAnimating = true;
      console.info(`Camera move started: ${reason}`);
    }
  };

  private moveListener: OnCameraMoveListener = {
    onCameraMove: () => {
      // Update UI during camera movement
      const zoom = this.map?.getZoom();
      const bearing = this.map?.getBearing();
      console.info(`Moving: zoom=${zoom?.toFixed(2)}, bearing=${bearing?.toFixed(1)}°`);
    }
  };

  build() {
    Column() {
      // Map view
      NativeMapView({
        styleUrl: "https://demotiles.maplibre.org/style.json",
        onMapViewCreated: (mapLibreMap) => {
          this.map = mapLibreMap;
          this.setupCamera();
        }
      })
        .width('100%')
        .height('80%')

      // Control buttons
      Row() {
        Button('Beijing')
          .onClick(() => this.flyToBeijing())
        Button('Shanghai')
          .onClick(() => this.flyToShanghai())
        Button('Reset')
          .onClick(() => this.resetCamera())
      }
      .width('100%')
      .height('20%')
      .justifyContent(FlexAlign.SpaceAround)
    }
  }

  private setupCamera() {
    if (!this.map) return;

    // Register camera listeners
    this.map.addOnCameraIdleListener(this.idleListener);
    this.map.addOnCameraMoveStartedListener(this.moveStartedListener);
    this.map.addOnCameraMoveListener(this.moveListener);

    // Set initial position
    const initialPosition = new CameraPosition(
      new LatLng(35.0, 105.0),  // Center of China
      4,
      0,
      0
    );
    this.map.setCameraPosition(initialPosition);
  }

  private flyToBeijing() {
    const beijing = new CameraPosition(
      new LatLng(39.9042, 116.4074),
      12,
      0,
      45  // 45° tilt
    );

    this.map?.flyTo(beijing, 3000);
  }

  private flyToShanghai() {
    const shanghai = new CameraPosition(
      new LatLng(31.2304, 121.4737),
      12,
      90,  // Facing east
      45
    );

    const callback: CameraAnimationCallback = {
      onFinish: () => {
        console.info('Arrived in Shanghai');
      },
      onCancel: () => {
        console.info('Flight cancelled');
      }
    };

    this.map?.animateCamera(shanghai, 2500, callback);
  }

  private resetCamera() {
    const reset = new CameraPosition(
      new LatLng(35.0, 105.0),
      4,
      0,
      0
    );

    this.map?.moveCamera(reset);  // Instant, no animation
  }

  aboutToDisappear() {
    // Clean up listeners
    if (this.map) {
      this.map.removeOnCameraIdleListener(this.idleListener);
      this.map.removeOnCameraMoveStartedListener(this.moveStartedListener);
      this.map.removeOnCameraMoveListener(this.moveListener);
    }
  }
}
```

---

## CameraOptions

### Description

Advanced camera configuration options for precise control.

```typescript
interface CameraOptions {
  center?: LatLng;         // Camera center point
  zoom?: number;           // Zoom level
  bearing?: number;        // Bearing/rotation in degrees
  pitch?: number;          // Pitch/tilt in degrees
  padding?: EdgeInsets;    // Padding from edges
  anchor?: Point;          // Anchor point for rotation/zoom
}
```

### Usage with Map Methods

```typescript
import { CameraOptions, LatLng, EdgeInsets, Point } from '@ohos/maplibre';

// Simple center change
const options1: CameraOptions = {
  center: new LatLng(39.9042, 116.4074)
};
map.easeTo(options1, 1000);

// Complex camera configuration
const options2: CameraOptions = {
  center: new LatLng(31.2304, 121.4737),
  zoom: 14,
  bearing: 45,
  pitch: 60,
  padding: new EdgeInsets(100, 100, 100, 100),
  anchor: new Point(screenWidth / 2, screenHeight / 2)
};
map.easeTo(options2, 2000);
```

---

**Last Updated:** 2025-11-04  
**Version:** 1.0.0

