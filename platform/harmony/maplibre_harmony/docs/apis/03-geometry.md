# Geometry Module

## Overview

The Geometry module provides fundamental geographic and screen coordinate types for map operations. These classes are used throughout the MapLibre API for positioning, bounds calculation, coordinate conversion, and spatial queries.

## Classes

- [LatLng](#latlng) - Geographic coordinates (latitude/longitude)
- [LatLngBounds](#latlngbounds) - Geographic bounding box
- [Point](#point) - Screen pixel coordinates
- [Rect](#rect) - Screen rectangle
- [ProjectedMeters](#projectedmeters) - Projected coordinate system (meters)

---

## LatLng

### Description

`LatLng` represents a geographic coordinate with latitude and longitude values. It's used for positioning markers, defining camera targets, and performing geographic calculations.

### Constructor

```typescript
constructor(latitude: number, longitude: number)
```

**Parameters:**
- `latitude: number` - Latitude in degrees (-90 to 90)
- `longitude: number` - Longitude in degrees (-180 to 180)

### Properties

```typescript
latitude: number   // Latitude value
longitude: number  // Longitude value
```

### Static Methods

#### create()

Create a LatLng instance.

```typescript
static create(latitude: number, longitude: number): LatLng
```

**Example:**
```typescript
const beijing = LatLng.create(39.9042, 116.4074);
```

#### fromNative()

Create from a native LatLng object (for NAPI interoperability).

```typescript
static fromNative(native: ILatLng): LatLng
```

### Instance Methods

#### toObject()

Convert to a plain object literal.

```typescript
toObject(): ILatLng
```

**Returns:** `{ latitude: number, longitude: number }`

**Example:**
```typescript
const latLng = new LatLng(39.9042, 116.4074);
const obj = latLng.toObject();
// obj = { latitude: 39.9042, longitude: 116.4074 }
```

#### isValid()

Check if coordinates are within valid range.

```typescript
isValid(): boolean
```

**Returns:** `true` if latitude is in [-90, 90] and longitude is in [-180, 180]

**Example:**
```typescript
const valid = new LatLng(39.9042, 116.4074).isValid();  // true
const invalid = new LatLng(100, 200).isValid();  // false
```

#### distanceTo()

Calculate distance to another coordinate using Haversine formula.

```typescript
distanceTo(other: LatLng): number
```

**Parameters:**
- `other: LatLng` - Target coordinate

**Returns:** Distance in meters

**Example:**
```typescript
const beijing = new LatLng(39.9042, 116.4074);
const shanghai = new LatLng(31.2304, 121.4737);
const distance = beijing.distanceTo(shanghai);
console.info(`Distance: ${(distance / 1000).toFixed(2)} km`);
// Distance: ~1067.37 km
```

#### equals()

Check if coordinates are equal (with floating-point tolerance).

```typescript
equals(other: LatLng): boolean
```

**Example:**
```typescript
const a = new LatLng(39.9042, 116.4074);
const b = new LatLng(39.9042, 116.4074);
console.info(a.equals(b));  // true
```

#### toString()

Convert to string representation.

```typescript
toString(): string
```

**Returns:** String in format "LatLng(latitude, longitude)"

### Utility Functions

```typescript
// Factory function
createLatLng(latitude: number, longitude: number): LatLng

// Validation
isValidLatLng(latLng: LatLng): boolean

// Distance calculation
distanceBetween(from: LatLng, to: LatLng): number

// Equality check
latLngEquals(a: LatLng, b: LatLng): boolean
```

### Usage Example

```typescript
import { LatLng, createLatLng, distanceBetween } from '@ohos/maplibre';

// Create coordinates
const beijing = new LatLng(39.9042, 116.4074);
const shanghai = createLatLng(31.2304, 121.4737);

// Validate
if (beijing.isValid()) {
  console.info('Valid coordinates');
}

// Calculate distance
const distance = distanceBetween(beijing, shanghai);
console.info(`${(distance / 1000).toFixed(2)} km apart`);

// Use with map
map.flyTo(new CameraPosition(beijing, 12, 0, 0));
```

---

## LatLngBounds

### Description

`LatLngBounds` represents a rectangular geographic area defined by its southwest and northeast corners. It's used for viewport management, spatial queries, and map region definition.

### Constructor

```typescript
// Option 1: Four numbers
constructor(north: number, east: number, south: number, west: number)

// Option 2: Two LatLng objects
constructor(southwest: LatLng, northeast: LatLng)
```

**Parameters (Option 1):**
- `north: number` - Northern latitude
- `east: number` - Eastern longitude
- `south: number` - Southern latitude
- `west: number` - Western longitude

**Parameters (Option 2):**
- `southwest: LatLng` - Southwest corner
- `northeast: LatLng` - Northeast corner

### Properties

```typescript
north: number   // Northern boundary
east: number    // Eastern boundary
south: number   // Southern boundary
west: number    // Western boundary
```

### Static Methods

#### fromLatLngs()

Create bounds from two corner points.

```typescript
static fromLatLngs(northeast: LatLng, southwest: LatLng): LatLngBounds
```

**Example:**
```typescript
const southwest = new LatLng(30.23, 120.12);
const northeast = new LatLng(30.31, 120.20);
const bounds = LatLngBounds.fromLatLngs(northeast, southwest);
```

#### fromLatLngArray()

Create bounds that encompass all points in an array.

```typescript
static fromLatLngArray(latLngs: LatLng[]): LatLngBounds
```

**Example:**
```typescript
const points = [
  new LatLng(39.9042, 116.4074),
  new LatLng(31.2304, 121.4737),
  new LatLng(22.3964, 114.1095)
];
const bounds = LatLngBounds.fromLatLngArray(points);
```

### Instance Methods

#### getNortheast() / getSouthwest()

Get corner coordinates.

```typescript
getNortheast(): LatLng
getSouthwest(): LatLng
```

**Example:**
```typescript
const ne = bounds.getNortheast();
const sw = bounds.getSouthwest();
```

#### getCenter()

Get the center point of the bounds.

```typescript
getCenter(): LatLng
```

**Example:**
```typescript
const center = bounds.getCenter();
map.flyTo(new CameraPosition(center, 10, 0, 0));
```

#### contains()

Check if a point is within the bounds.

```typescript
contains(latLng: LatLng): boolean
```

**Example:**
```typescript
const point = new LatLng(39.9042, 116.4074);
if (bounds.contains(point)) {
  console.info('Point is within bounds');
}
```

#### containsBounds()

Check if bounds completely contain another bounds.

```typescript
containsBounds(other: LatLngBounds): boolean
```

**Example:**
```typescript
if (largeBounds.containsBounds(smallBounds)) {
  console.info('Small bounds is fully contained');
}
```

#### intersects()

Check if bounds intersect with another bounds.

```typescript
intersects(other: LatLngBounds): boolean
```

**Example:**
```typescript
if (bounds1.intersects(bounds2)) {
  console.info('Bounds overlap');
}
```

#### extend()

Extend bounds to include a point.

```typescript
extend(latLng: LatLng): LatLngBounds
```

**Returns:** New LatLngBounds instance (original is unchanged)

**Example:**
```typescript
let bounds = new LatLngBounds(30, 120, 29, 119);
bounds = bounds.extend(new LatLng(31, 121));
// Bounds now includes (31, 121)
```

#### extendBounds()

Extend bounds to include another bounds.

```typescript
extendBounds(other: LatLngBounds): LatLngBounds
```

**Example:**
```typescript
const combined = bounds1.extendBounds(bounds2);
```

#### isValid()

Check if bounds are valid.

```typescript
isValid(): boolean
```

**Returns:** `true` if bounds are valid (north >= south, east >= west, coordinates in range)

### Usage Example

```typescript
import { LatLng, LatLngBounds } from '@ohos/maplibre';

// Create bounds
const southwest = new LatLng(30.0, 120.0);
const northeast = new LatLng(31.0, 121.0);
const bounds = new LatLngBounds(southwest, northeast);

// Check if point is inside
const point = new LatLng(30.5, 120.5);
if (bounds.contains(point)) {
  console.info('Point is in bounds');
}

// Get center
const center = bounds.getCenter();
console.info(`Center: ${center.latitude}, ${center.longitude}`);

// Extend to include more points
let expandedBounds = bounds;
const newPoint = new LatLng(32.0, 122.0);
expandedBounds = expandedBounds.extend(newPoint);

// Use with camera
map.setLatLngBounds(bounds);
```

---

## Point

### Description

`Point` (alias for `PixelCoordinate`) represents a point on the screen in pixel coordinates. It's used for touch event handling, screen-to-geographic coordinate conversion, and UI positioning.

### Constructor

```typescript
constructor(x: number = 0, y: number = 0)
```

**Parameters:**
- `x: number` - X coordinate in pixels
- `y: number` - Y coordinate in pixels

### Properties

```typescript
x: number  // X coordinate
y: number  // Y coordinate
```

### Static Methods

#### create()

Create a Point instance.

```typescript
static create(x: number, y: number): PixelCoordinate
```

#### fromObject()

Create from a plain object.

```typescript
static fromObject(obj: IPixelCoordinate): PixelCoordinate
```

#### fromLogicalPixels()

Create from logical pixels, converting to physical pixels using device pixel ratio.

```typescript
static fromLogicalPixels(x: number, y: number, pixelRatio: number): PixelCoordinate
```

**Parameters:**
- `x: number` - Logical X coordinate
- `y: number` - Logical Y coordinate
- `pixelRatio: number` - Device pixel ratio (DPI)

**Example:**
```typescript
// Convert logical (375, 667) to physical pixels at 3x DPI
const physicalPoint = Point.fromLogicalPixels(375, 667, 3.0);
// Result: (1125, 2001)
```

### Instance Methods

#### toObject()

Convert to plain object.

```typescript
toObject(): IPixelCoordinate
```

**Returns:** `{ x: number, y: number }`

#### toPhysicalPixels()

Convert to physical pixels.

```typescript
toPhysicalPixels(pixelRatio: number): PixelCoordinate
```

**Example:**
```typescript
const logical = new Point(100, 200);
const physical = logical.toPhysicalPixels(2.0);
// physical = (200, 400)
```

#### distanceTo()

Calculate distance to another point.

```typescript
distanceTo(other: PixelCoordinate): number
```

**Returns:** Distance in pixels

**Example:**
```typescript
const p1 = new Point(0, 0);
const p2 = new Point(3, 4);
const distance = p1.distanceTo(p2);  // 5.0
```

#### midpoint()

Calculate midpoint between this point and another.

```typescript
midpoint(other: PixelCoordinate): PixelCoordinate
```

**Example:**
```typescript
const p1 = new Point(0, 0);
const p2 = new Point(100, 100);
const mid = p1.midpoint(p2);  // (50, 50)
```

### Type Aliases

```typescript
type Point = PixelCoordinate
type ScreenCoordinate = PixelCoordinate
```

### Usage Example

```typescript
import { Point } from '@ohos/maplibre';

// Create point
const touchPoint = new Point(375, 500);

// Convert to geographic coordinates
const latLng = map.latLngForPixel(touchPoint.x, touchPoint.y);

// Calculate distance between touch points
const point1 = new Point(100, 100);
const point2 = new Point(200, 200);
const distance = point1.distanceTo(point2);
console.info(`Distance: ${distance.toFixed(2)} pixels`);

// Use with queries
const features = map.queryRenderedFeatures(touchPoint);
```

---

## Rect

### Description

`Rect` represents a rectangular area on the screen, defined by left, top, right, and bottom coordinates. It's used for screen region queries and UI layout calculations.

### Constructor

```typescript
constructor(left: number = 0, top: number = 0, right: number = 0, bottom: number = 0)
```

**Parameters:**
- `left: number` - Left edge X coordinate
- `top: number` - Top edge Y coordinate
- `right: number` - Right edge X coordinate
- `bottom: number` - Bottom edge Y coordinate

### Properties

```typescript
left: number    // Left boundary
top: number     // Top boundary
right: number   // Right boundary
bottom: number  // Bottom boundary
```

### Static Methods

#### create()

Create a Rect instance.

```typescript
static create(left: number, top: number, right: number, bottom: number): Rect
```

#### fromPoints()

Create from two corner points.

```typescript
static fromPoints(topLeft: Point, bottomRight: Point): Rect
```

**Example:**
```typescript
const rect = Rect.fromPoints(
  new Point(10, 10),
  new Point(100, 100)
);
```

#### fromXYWH()

Create from position and dimensions.

```typescript
static fromXYWH(x: number, y: number, width: number, height: number): Rect
```

**Example:**
```typescript
const rect = Rect.fromXYWH(10, 10, 90, 90);
// Same as Rect(10, 10, 100, 100)
```

### Instance Methods

#### getWidth() / getHeight()

Get rectangle dimensions.

```typescript
getWidth(): number
getHeight(): number
```

**Example:**
```typescript
const width = rect.getWidth();
const height = rect.getHeight();
```

#### getCenter()

Get the center point of the rectangle.

```typescript
getCenter(): Point
```

**Example:**
```typescript
const center = rect.getCenter();
```

#### containsPoint()

Check if a point is within the rectangle.

```typescript
containsPoint(point: Point): boolean
```

**Example:**
```typescript
const point = new Point(50, 50);
if (rect.containsPoint(point)) {
  console.info('Point is inside rectangle');
}
```

#### intersects()

Check if rectangle intersects with another.

```typescript
intersects(other: Rect): boolean
```

**Example:**
```typescript
if (rect1.intersects(rect2)) {
  console.info('Rectangles overlap');
}
```

#### intersection()

Calculate the intersection of two rectangles.

```typescript
intersection(other: Rect): Rect | null
```

**Returns:** Intersection rectangle, or `null` if no intersection

**Example:**
```typescript
const overlap = rect1.intersection(rect2);
if (overlap) {
  console.info(`Overlap area: ${overlap.getArea()}`);
}
```

#### union()

Calculate the union of two rectangles.

```typescript
union(other: Rect): Rect
```

**Returns:** Smallest rectangle containing both rectangles

**Example:**
```typescript
const combined = rect1.union(rect2);
```

#### isEmpty()

Check if rectangle is empty (zero or negative area).

```typescript
isEmpty(): boolean
```

#### getArea()

Calculate rectangle area.

```typescript
getArea(): number
```

**Returns:** Area in square pixels, or 0 if empty

### Usage Example

```typescript
import { Rect, Point } from '@ohos/maplibre';

// Create selection rectangle
const selectionRect = Rect.fromXYWH(100, 100, 200, 150);

// Query features in rectangle
const features = map.queryRenderedFeatures(selectionRect, ['poi-layer']);

// Check if point is in rectangle
const touchPoint = new Point(150, 150);
if (selectionRect.containsPoint(touchPoint)) {
  console.info('Touch is within selection');
}

// Calculate area
const area = selectionRect.getArea();
console.info(`Selection area: ${area} square pixels`);
```

---

## ProjectedMeters

### Description

`ProjectedMeters` represents coordinates in a projected coordinate system where units are in meters. It's used for precise distance calculations and coordinate transformations.

### Constructor

```typescript
constructor(northing: number = 0, easting: number = 0)
```

**Parameters:**
- `northing: number` - North-south coordinate in meters
- `easting: number` - East-west coordinate in meters

### Properties

```typescript
northing: number  // North-south coordinate (Y)
easting: number   // East-west coordinate (X)
```

### Static Methods

#### create()

Create a ProjectedMeters instance.

```typescript
static create(northing: number, easting: number): ProjectedMeters
```

#### fromObject()

Create from a plain object.

```typescript
static fromObject(obj: IProjectedMeters): ProjectedMeters
```

### Instance Methods

#### toObject()

Convert to plain object.

```typescript
toObject(): IProjectedMeters
```

**Returns:** `{ northing: number, easting: number }`

#### distanceTo()

Calculate distance to another projected coordinate.

```typescript
distanceTo(other: ProjectedMeters): number
```

**Returns:** Distance in meters

**Example:**
```typescript
const p1 = new ProjectedMeters(0, 0);
const p2 = new ProjectedMeters(3000, 4000);
const distance = p1.distanceTo(p2);  // 5000 meters
```

### Usage Example

```typescript
import { ProjectedMeters } from '@ohos/maplibre';

// Convert from LatLng to projected meters
const latLng = new LatLng(39.9042, 116.4074);
const projected = map.projectedMetersForLatLng(latLng.latitude, latLng.longitude);

// Calculate distance
const point1 = new ProjectedMeters(1000000, 1000000);
const point2 = new ProjectedMeters(1003000, 1004000);
const distance = point1.distanceTo(point2);
console.info(`Distance: ${distance} meters`);

// Convert back to LatLng
const backToLatLng = map.latLngForProjectedMeters(projected.northing, projected.easting);
```

---

**Last Updated:** 2025-11-04  
**Version:** 1.0.0

