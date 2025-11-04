# UI Settings Module

## Overview

The UI Settings module provides comprehensive control over map interaction gestures, UI components (compass, logo, scale bar, attribution), and inertial animations. It follows the Android UiSettings and iOS MLNMapView design patterns.

## Classes

- [UiSettings](#uisettings) - Main UI configuration class
- [FocalPoint](#focalpoint) - Gesture focal point
- [CompassMargins](#compassmargins) - Margins configuration

---

## UiSettings

### Description

`UiSettings` manages all UI-related settings for the map, including gesture enablement, UI component visibility and positioning, animation parameters, and interaction sensitivity.

### Obtaining Instance

```typescript
const uiSettings = map.getUiSettings();
```

### Gesture Control

#### Scroll Gestures (Pan)

Enable or disable map panning gestures.

```typescript
setScrollGesturesEnabled(enabled: boolean): UiSettings
isScrollGesturesEnabled(): boolean
```

**Example:**
```typescript
const uiSettings = map.getUiSettings();
uiSettings.setScrollGesturesEnabled(true);  // Enable panning
const isEnabled = uiSettings.isScrollGesturesEnabled();
```

#### Zoom Gestures

Enable or disable zoom gestures (pinch-to-zoom, double-tap zoom).

```typescript
setZoomGesturesEnabled(enabled: boolean): UiSettings
isZoomGesturesEnabled(): boolean
```

**Example:**
```typescript
uiSettings.setZoomGesturesEnabled(true);
```

#### Rotate Gestures

Enable or disable rotation gestures (two-finger rotate).

```typescript
setRotateGesturesEnabled(enabled: boolean): UiSettings
isRotateGesturesEnabled(): boolean
```

**Example:**
```typescript
uiSettings.setRotateGesturesEnabled(true);
```

#### Tilt Gestures

Enable or disable tilt/pitch gestures (two-finger vertical drag).

```typescript
setTiltGesturesEnabled(enabled: boolean): UiSettings
isTiltGesturesEnabled(): boolean
```

**Example:**
```typescript
uiSettings.setTiltGesturesEnabled(true);
```

#### Double-Tap Gestures

Enable or disable double-tap to zoom in.

```typescript
setDoubleTapGesturesEnabled(enabled: boolean): UiSettings
isDoubleTapGesturesEnabled(): boolean
```

**Example:**
```typescript
uiSettings.setDoubleTapGesturesEnabled(true);
```

#### Quick Zoom Gestures

Enable or disable quick zoom (double-tap and drag to zoom).

```typescript
setQuickZoomGesturesEnabled(enabled: boolean): UiSettings
isQuickZoomGesturesEnabled(): boolean
```

**Example:**
```typescript
uiSettings.setQuickZoomGesturesEnabled(true);
```

#### Enable All Gestures

Enable or disable all gesture types at once.

```typescript
setAllGesturesEnabled(enabled: boolean): UiSettings
```

**Example:**
```typescript
// Disable all gestures
uiSettings.setAllGesturesEnabled(false);

// Enable all gestures
uiSettings.setAllGesturesEnabled(true);
```

### Focal Point

#### setFocalPoint()

Set a custom focal point for gestures. When set, zoom and rotation gestures will pivot around this point.

```typescript
setFocalPoint(point: FocalPoint | null): UiSettings
getFocalPoint(): FocalPoint | null
```

**Parameters:**
- `point: FocalPoint | null` - Focal point in screen coordinates, or `null` for default behavior

**Example:**
```typescript
import { FocalPoint } from '@ohos/maplibre';

// Set focal point to center of screen
const centerPoint = new FocalPoint(screenWidth / 2, screenHeight / 2);
uiSettings.setFocalPoint(centerPoint);

// Reset to default
uiSettings.setFocalPoint(null);
```

### Compass Configuration

#### setCompassEnabled()

Enable or disable the compass widget.

```typescript
setCompassEnabled(enabled: boolean): UiSettings
isCompassEnabled(): boolean
```

**Example:**
```typescript
uiSettings.setCompassEnabled(true);
```

#### setCompassPosition()

Set the compass position on screen.

```typescript
setCompassPosition(position: OrnamentPosition): UiSettings
getCompassPosition(): OrnamentPosition
```

**Parameters:**
- `position: OrnamentPosition` - Position enum value

**Example:**
```typescript
import { OrnamentPosition } from '@ohos/maplibre';

uiSettings.setCompassPosition(OrnamentPosition.TopRight);
uiSettings.setCompassPosition(OrnamentPosition.TopLeft);
uiSettings.setCompassPosition(OrnamentPosition.BottomRight);
uiSettings.setCompassPosition(OrnamentPosition.BottomLeft);
```

#### setCompassVisibility()

Set compass visibility mode.

```typescript
setCompassVisibility(visibility: CompassVisibility): UiSettings
getCompassVisibility(): CompassVisibility
```

**Parameters:**
- `visibility: CompassVisibility` - Visibility mode

**Example:**
```typescript
import { CompassVisibility } from '@ohos/maplibre';

// Always visible
uiSettings.setCompassVisibility(CompassVisibility.Visible);

// Adaptive (show when map is rotated)
uiSettings.setCompassVisibility(CompassVisibility.Adaptive);

// Always hidden
uiSettings.setCompassVisibility(CompassVisibility.Hidden);
```

#### setCompassFadeWhenFacingNorth()

Configure whether compass fades out when pointing north.

```typescript
setCompassFadeWhenFacingNorth(fade: boolean): UiSettings
isCompassFadeWhenFacingNorth(): boolean
```

**Example:**
```typescript
uiSettings.setCompassFadeWhenFacingNorth(true);
```

#### setCompassMargins()

Set compass margins from screen edges.

```typescript
setCompassMargins(left: number, top: number, right: number, bottom: number): UiSettings
getCompassMargins(): CompassMargins
```

**Parameters:**
- `left: number` - Left margin in dp
- `top: number` - Top margin in dp
- `right: number` - Right margin in dp
- `bottom: number` - Bottom margin in dp

**Example:**
```typescript
// Set 20dp margin on all sides
uiSettings.setCompassMargins(20, 20, 20, 20);
```

### Logo Configuration

#### setLogoEnabled()

Enable or disable the MapLibre logo.

```typescript
setLogoEnabled(enabled: boolean): UiSettings
isLogoEnabled(): boolean
```

**Example:**
```typescript
uiSettings.setLogoEnabled(true);
```

#### setLogoPosition()

Set the logo position on screen.

```typescript
setLogoPosition(position: OrnamentPosition): UiSettings
getLogoPosition(): OrnamentPosition
```

**Example:**
```typescript
import { OrnamentPosition } from '@ohos/maplibre';

uiSettings.setLogoPosition(OrnamentPosition.BottomLeft);
```

#### setLogoMargins()

Set logo margins from screen edges.

```typescript
setLogoMargins(left: number, top: number, right: number, bottom: number): UiSettings
getLogoMargins(): CompassMargins
```

**Example:**
```typescript
uiSettings.setLogoMargins(10, 10, 10, 10);
```

### Scale Bar Configuration

#### setScaleBarEnabled()

Enable or disable the scale bar.

```typescript
setScaleBarEnabled(enabled: boolean): UiSettings
isScaleBarEnabled(): boolean
```

**Example:**
```typescript
uiSettings.setScaleBarEnabled(true);
```

#### setScaleBarPosition()

Set the scale bar position on screen.

```typescript
setScaleBarPosition(position: OrnamentPosition): UiSettings
getScaleBarPosition(): OrnamentPosition
```

**Example:**
```typescript
import { OrnamentPosition } from '@ohos/maplibre';

uiSettings.setScaleBarPosition(OrnamentPosition.TopLeft);
```

#### setScaleBarUnit()

Set the scale bar measurement unit.

```typescript
setScaleBarUnit(unit: ScaleBarUnit): UiSettings
getScaleBarUnit(): ScaleBarUnit
```

**Parameters:**
- `unit: ScaleBarUnit` - Either `ScaleBarUnit.Metric` or `ScaleBarUnit.Imperial`

**Example:**
```typescript
import { ScaleBarUnit } from '@ohos/maplibre';

// Use metric units (meters/kilometers)
uiSettings.setScaleBarUnit(ScaleBarUnit.Metric);

// Use imperial units (feet/miles)
uiSettings.setScaleBarUnit(ScaleBarUnit.Imperial);
```

#### setScaleBarUseDarkStyles()

Set whether scale bar uses dark styling.

```typescript
setScaleBarUseDarkStyles(useDark: boolean): UiSettings
isScaleBarUseDarkStyles(): boolean
```

**Example:**
```typescript
uiSettings.setScaleBarUseDarkStyles(false);  // Light style
```

#### setScaleBarMargins()

Set scale bar margins from screen edges.

```typescript
setScaleBarMargins(left: number, top: number, right: number, bottom: number): UiSettings
getScaleBarMargins(): CompassMargins
```

**Example:**
```typescript
uiSettings.setScaleBarMargins(10, 10, 10, 10);
```

### Attribution Configuration

#### setAttributionEnabled()

Enable or disable the attribution button.

```typescript
setAttributionEnabled(enabled: boolean): UiSettings
isAttributionEnabled(): boolean
```

**Example:**
```typescript
uiSettings.setAttributionEnabled(true);
```

#### setAttributionPosition()

Set the attribution button position.

```typescript
setAttributionPosition(position: OrnamentPosition): UiSettings
getAttributionPosition(): OrnamentPosition
```

**Example:**
```typescript
import { OrnamentPosition } from '@ohos/maplibre';

uiSettings.setAttributionPosition(OrnamentPosition.BottomRight);
```

#### setAttributionMargins()

Set attribution button margins from screen edges.

```typescript
setAttributionMargins(left: number, top: number, right: number, bottom: number): UiSettings
getAttributionMargins(): CompassMargins
```

**Example:**
```typescript
uiSettings.setAttributionMargins(10, 10, 10, 10);
```

### Inertial Animation Configuration

#### Fling Velocity Animation

Configure inertial scrolling animation after pan gestures.

```typescript
setFlingVelocityAnimationEnabled(enabled: boolean): UiSettings
isFlingVelocityAnimationEnabled(): boolean
```

**Example:**
```typescript
// Enable smooth deceleration after panning
uiSettings.setFlingVelocityAnimationEnabled(true);
```

#### Scale Velocity Animation

Configure inertial zoom animation after pinch gestures.

```typescript
setScaleVelocityAnimationEnabled(enabled: boolean): UiSettings
isScaleVelocityAnimationEnabled(): boolean
```

**Example:**
```typescript
uiSettings.setScaleVelocityAnimationEnabled(true);
```

#### Rotate Velocity Animation

Configure inertial rotation animation after rotate gestures.

```typescript
setRotateVelocityAnimationEnabled(enabled: boolean): UiSettings
isRotateVelocityAnimationEnabled(): boolean
```

**Example:**
```typescript
uiSettings.setRotateVelocityAnimationEnabled(true);
```

### Animation Parameters

#### setDecelerationRate()

Set the deceleration rate for inertial animations (iOS-style, 0-1).

```typescript
setDecelerationRate(rate: number): UiSettings
getDecelerationRate(): number
```

**Parameters:**
- `rate: number` - Deceleration rate (0-1). Higher values = longer animation.

**Example:**
```typescript
uiSettings.setDecelerationRate(0.35);  // Default value
```

#### setFlingAnimationBaseTime()

Set the base duration for fling animations.

```typescript
setFlingAnimationBaseTime(timeMs: number): UiSettings
getFlingAnimationBaseTime(): number
```

**Parameters:**
- `timeMs: number` - Base animation duration in milliseconds

**Example:**
```typescript
uiSettings.setFlingAnimationBaseTime(300);
```

### Velocity Thresholds

#### setMinFlingVelocity()

Set minimum velocity threshold for fling animation.

```typescript
setMinFlingVelocity(velocity: number): UiSettings
getMinFlingVelocity(): number
```

**Parameters:**
- `velocity: number` - Minimum velocity in pixels/second

**Example:**
```typescript
uiSettings.setMinFlingVelocity(100);
```

#### setMinScaleVelocity()

Set minimum velocity threshold for scale animation.

```typescript
setMinScaleVelocity(velocity: number): UiSettings
getMinScaleVelocity(): number
```

**Example:**
```typescript
uiSettings.setMinScaleVelocity(0.5);
```

#### setMinRotateVelocity()

Set minimum velocity threshold for rotation animation.

```typescript
setMinRotateVelocity(velocity: number): UiSettings
getMinRotateVelocity(): number
```

**Parameters:**
- `velocity: number` - Minimum velocity in degrees/second

**Example:**
```typescript
uiSettings.setMinRotateVelocity(5);
```

### Tilt Configuration

#### setMinPitch() / setMaxPitch()

Set minimum and maximum pitch angles.

```typescript
setMinPitch(pitch: number): UiSettings
getMinPitch(): number
setMaxPitch(pitch: number): UiSettings
getMaxPitch(): number
```

**Parameters:**
- `pitch: number` - Pitch angle in degrees (0-60)

**Example:**
```typescript
uiSettings.setMinPitch(0);
uiSettings.setMaxPitch(60);
```

#### setTiltSensitivity()

Set tilt gesture sensitivity.

```typescript
setTiltSensitivity(sensitivity: number): UiSettings
getTiltSensitivity(): number
```

**Parameters:**
- `sensitivity: number` - Sensitivity factor (slowdown multiplier)

**Example:**
```typescript
uiSettings.setTiltSensitivity(0.5);  // Less sensitive
```

### Zoom Configuration

#### setZoomRate()

Set zoom gesture sensitivity.

```typescript
setZoomRate(rate: number): UiSettings
getZoomRate(): number
```

**Parameters:**
- `rate: number` - Zoom rate multiplier (1.0 = default)

**Example:**
```typescript
uiSettings.setZoomRate(1.5);  // 50% more sensitive
```

#### setQuickZoomMaxChange()

Set maximum zoom change for quick zoom gesture.

```typescript
setQuickZoomMaxChange(maxChange: number): UiSettings
getQuickZoomMaxChange(): number
```

**Parameters:**
- `maxChange: number` - Maximum zoom level change

**Example:**
```typescript
uiSettings.setQuickZoomMaxChange(4);
```

### Rotation Configuration

#### setRotationRate()

Set rotation gesture sensitivity.

```typescript
setRotationRate(rate: number): UiSettings
getRotationRate(): number
```

**Parameters:**
- `rate: number` - Rotation rate multiplier (1.0 = default)

**Example:**
```typescript
uiSettings.setRotationRate(1.2);  // 20% more sensitive
```

### Complete Usage Example

```typescript
import {
  NativeMapView,
  MapLibreMap,
  OrnamentPosition,
  CompassVisibility,
  ScaleBarUnit,
  FocalPoint
} from '@ohos/maplibre';

@Entry
@Component
struct UISettingsExample {
  private map: MapLibreMap | null = null;

  build() {
    NativeMapView({
      styleUrl: "https://demotiles.maplibre.org/style.json",
      onMapViewCreated: (mapLibreMap) => {
        this.map = mapLibreMap;
        this.configureUI();
      }
    })
      .width('100%')
      .height('100%')
  }

  private configureUI() {
    if (!this.map) return;

    const uiSettings = this.map.getUiSettings();

    // Configure gestures
    uiSettings
      .setScrollGesturesEnabled(true)
      .setZoomGesturesEnabled(true)
      .setRotateGesturesEnabled(true)
      .setTiltGesturesEnabled(true)
      .setDoubleTapGesturesEnabled(true)
      .setQuickZoomGesturesEnabled(true);

    // Configure compass
    uiSettings
      .setCompassEnabled(true)
      .setCompassPosition(OrnamentPosition.TopRight)
      .setCompassVisibility(CompassVisibility.Adaptive)
      .setCompassFadeWhenFacingNorth(true)
      .setCompassMargins(20, 20, 20, 20);

    // Configure logo
    uiSettings
      .setLogoEnabled(true)
      .setLogoPosition(OrnamentPosition.BottomLeft)
      .setLogoMargins(10, 10, 10, 10);

    // Configure scale bar
    uiSettings
      .setScaleBarEnabled(true)
      .setScaleBarPosition(OrnamentPosition.TopLeft)
      .setScaleBarUnit(ScaleBarUnit.Metric)
      .setScaleBarUseDarkStyles(false)
      .setScaleBarMargins(10, 60, 10, 10);

    // Configure attribution
    uiSettings
      .setAttributionEnabled(true)
      .setAttributionPosition(OrnamentPosition.BottomRight)
      .setAttributionMargins(10, 10, 10, 10);

    // Configure inertial animations
    uiSettings
      .setFlingVelocityAnimationEnabled(true)
      .setScaleVelocityAnimationEnabled(true)
      .setRotateVelocityAnimationEnabled(true)
      .setDecelerationRate(0.35)
      .setFlingAnimationBaseTime(300);

    // Configure sensitivity
    uiSettings
      .setZoomRate(1.0)
      .setRotationRate(1.0)
      .setTiltSensitivity(0.5);

    // Configure limits
    uiSettings
      .setMinPitch(0)
      .setMaxPitch(60);

    console.info('UI settings configured successfully');
  }
}
```

---

## FocalPoint

### Description

`FocalPoint` represents a point on the screen in pixels, used as the pivot for zoom and rotation gestures.

### Constructor

```typescript
constructor(x: number, y: number)
```

**Parameters:**
- `x: number` - X coordinate in pixels
- `y: number` - Y coordinate in pixels

### Properties

```typescript
x: number  // X coordinate
y: number  // Y coordinate
```

### Usage Example

```typescript
import { FocalPoint } from '@ohos/maplibre';

const screenCenter = new FocalPoint(375, 667);
uiSettings.setFocalPoint(screenCenter);
```

---

## CompassMargins

### Description

`CompassMargins` defines margins from screen edges for UI components.

### Constructor

```typescript
constructor(left: number = 10, top: number = 10, right: number = 10, bottom: number = 10)
```

**Parameters:**
- `left: number` - Left margin in dp (default: 10)
- `top: number` - Top margin in dp (default: 10)
- `right: number` - Right margin in dp (default: 10)
- `bottom: number` - Bottom margin in dp (default: 10)

### Properties

```typescript
left: number    // Left margin
top: number     // Top margin
right: number   // Right margin
bottom: number  // Bottom margin
```

### Usage Example

```typescript
import { CompassMargins } from '@ohos/maplibre';

const margins = new CompassMargins(20, 20, 20, 20);
// Use with setCompassMargins(), setLogoMargins(), etc.
```

---

**Last Updated:** 2025-11-04  
**Version:** 1.0.0

