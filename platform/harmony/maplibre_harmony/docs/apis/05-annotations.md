# Annotations Module

## Overview

The Annotations module provides classes for adding markers, lines, polygons, and custom annotations to the map. It includes support for info windows, custom icons, and interactive overlays.

## Classes

- [Marker](#marker) - Point markers with icons and info windows
- [MarkerOptions](#markeroptions) - Marker configuration
- [Icon & IconFactory](#icon--iconfactory) - Custom marker icons
- [Polyline](#polyline) - Line annotations
- [Polygon](#polygon) - Polygon annotations
- [InfoWindow](#infowindow) - Information popups for markers
- [AnnotationView](#annotationview) - Custom annotation views

---

## Marker

### Description

`Marker` represents a point annotation on the map with an optional icon, title, and snippet. Markers can be interactive and display info windows when clicked.

### Constructor

```typescript
constructor(options: ESObject)
```

**Parameters:**
- `options: ESObject` - Marker configuration object

### Key Methods

#### getPosition() / setPosition()

Get or set marker position.

```typescript
getPosition(): LatLng
setPosition(position: LatLng): Marker
```

**Example:**
```typescript
const marker = new Marker({ position: new LatLng(39.9042, 116.4074) });
map.addMarker(marker);

// Update position
marker.setPosition(new LatLng(31.2304, 121.4737));
```

#### getIcon() / setIcon()

Get or set marker icon.

```typescript
getIcon(): string
setIcon(iconId: string): Marker
```

**Example:**
```typescript
marker.setIcon('custom-marker-icon');
```

#### getTitle() / setTitle()

Get or set marker title (displayed in info window).

```typescript
getTitle(): string
setTitle(title: string): Marker
```

**Example:**
```typescript
marker.setTitle('Beijing');
```

#### getSnippet() / setSnippet()

Get or set marker snippet (subtitle in info window).

```typescript
getSnippet(): string
setSnippet(snippet: string): Marker
```

**Example:**
```typescript
marker.setSnippet('Capital of China');
```

#### getAnchor() / setAnchor()

Get or set icon anchor point (0-1 normalized coordinates).

```typescript
getAnchor(): MarkerAnchor
setAnchor(u: number, v: number): Marker
```

**Parameters:**
- `u: number` - Horizontal anchor (0 = left, 0.5 = center, 1 = right)
- `v: number` - Vertical anchor (0 = top, 0.5 = center, 1 = bottom)

**Example:**
```typescript
// Center anchor (default for most icons)
marker.setAnchor(0.5, 0.5);

// Bottom center (typical for pin icons)
marker.setAnchor(0.5, 1.0);
```

#### getDraggable() / setDraggable()

Get or set marker draggability.

```typescript
getDraggable(): boolean
setDraggable(draggable: boolean): Marker
```

**Example:**
```typescript
marker.setDraggable(true);

// Listen for drag events
map.addOnMarkerDragListener({
  onMarkerDragStart: (marker) => {
    console.info('Drag started');
  },
  onMarkerDrag: (marker) => {
    const pos = marker.getPosition();
    console.info(`Dragging: ${pos.latitude}, ${pos.longitude}`);
  },
  onMarkerDragEnd: (marker) => {
    console.info('Drag ended');
  }
});
```

#### isVisible() / setVisible()

Get or set marker visibility.

```typescript
isVisible(): boolean
setVisible(visible: boolean): Marker
```

**Example:**
```typescript
marker.setVisible(false);  // Hide marker
marker.setVisible(true);   // Show marker
```

#### remove()

Remove marker from map.

```typescript
remove(): void
```

**Example:**
```typescript
marker.remove();
```

### Complete Marker Example

```typescript
import { Marker, LatLng, MarkerOptions } from '@ohos/maplibre';

// Create marker with options
const marker = new Marker({
  position: new LatLng(39.9042, 116.4074),
  title: 'Beijing',
  snippet: 'Capital of China',
  draggable: true,
  icon: 'custom-pin'
});

// Add to map
map.addMarker(marker);

// Listen for clicks
map.addOnMarkerClickListener({
  onMarkerClick: (clickedMarker) => {
    if (clickedMarker === marker) {
      console.info(`Clicked: ${clickedMarker.getTitle()}`);
      // Show info window
      map.selectMarker(clickedMarker);
    }
    return true;  // Consume event
  }
});

// Update marker
marker
  .setPosition(new LatLng(39.91, 116.41))
  .setTitle('Updated Title')
  .setDraggable(false);

// Remove marker
marker.remove();
```

---

## MarkerOptions

### Description

`MarkerOptions` defines configuration for creating markers.

### Properties

```typescript
interface MarkerOptions {
  position: LatLng;         // Marker position (required)
  icon?: string;            // Icon ID
  title?: string;           // Title text
  snippet?: string;         // Subtitle text
  draggable?: boolean;      // Enable dragging
  visible?: boolean;        // Initial visibility
  anchor?: {                // Icon anchor point
    u: number;              // Horizontal (0-1)
    v: number;              // Vertical (0-1)
  };
  zIndex?: number;          // Z-order (higher = on top)
}
```

### Usage Example

```typescript
const options: MarkerOptions = {
  position: new LatLng(39.9042, 116.4074),
  title: 'Beijing',
  snippet: 'Capital of China',
  icon: 'custom-marker',
  draggable: true,
  visible: true,
  anchor: { u: 0.5, v: 1.0 },
  zIndex: 100
};

const marker = new Marker(options);
map.addMarker(marker);
```

---

## Icon & IconFactory

### Description

`Icon` and `IconFactory` manage custom marker icons. Icons can be created from images, resources, or bitmaps.

### IconFactory

Factory class for creating icons.

```typescript
class IconFactory {
  // Create icon from resource
  static fromResource(resourceId: string): Icon;
  
  // Create icon from bitmap
  static fromBitmap(bitmap: PixelMap): Icon;
  
  // Create icon from asset
  static fromAsset(assetPath: string): Icon;
}
```

### Icon

Represents a marker icon.

```typescript
class Icon {
  getId(): string;              // Get icon ID
  getBitmap(): PixelMap;        // Get icon bitmap
}
```

### Usage Example

```typescript
import { IconFactory, Icon } from '@ohos/maplibre';

// Create icon from resource
const icon = IconFactory.fromResource('custom_marker_icon');

// Add icon to map
map.addImage('my-custom-icon', icon.getBitmap());

// Use icon with marker
const marker = new Marker({
  position: new LatLng(39.9042, 116.4074),
  icon: 'my-custom-icon'
});
map.addMarker(marker);
```

---

## Polyline

### Description

`Polyline` represents a line annotation connecting multiple points on the map.

### Constructor

```typescript
constructor(options: PolylineOptions)
```

### PolylineOptions

```typescript
interface PolylineOptions {
  points: LatLng[];          // Line vertices
  color?: string;            // Line color (CSS color)
  width?: number;            // Line width in pixels
  opacity?: number;          // Line opacity (0-1)
  pattern?: number[];        // Dash pattern
  lineCap?: string;          // Line cap style ('butt', 'round', 'square')
  lineJoin?: string;         // Line join style ('bevel', 'round', 'miter')
}
```

### Key Methods

```typescript
getPoints(): LatLng[]                    // Get all points
setPoints(points: LatLng[]): Polyline    // Set all points
addPoint(point: LatLng): Polyline        // Add point
getColor(): string                       // Get color
setColor(color: string): Polyline        // Set color
getWidth(): number                       // Get width
setWidth(width: number): Polyline        // Set width
remove(): void                           // Remove from map
```

### Usage Example

```typescript
import { Polyline, LatLng } from '@ohos/maplibre';

// Create route line
const route = new Polyline({
  points: [
    new LatLng(39.9042, 116.4074),
    new LatLng(39.9142, 116.4174),
    new LatLng(39.9242, 116.4274)
  ],
  color: '#FF0000',
  width: 5,
  opacity: 0.8
});

// Add to map
map.addPolyline(route);

// Update route
route.addPoint(new LatLng(39.9342, 116.4374));
route.setColor('#00FF00');

// Remove route
route.remove();
```

---

## Polygon

### Description

`Polygon` represents a filled polygon area on the map.

### Constructor

```typescript
constructor(options: PolygonOptions)
```

### PolygonOptions

```typescript
interface PolygonOptions {
  points: LatLng[];          // Polygon vertices (outer ring)
  holes?: LatLng[][];        // Holes (inner rings)
  fillColor?: string;        // Fill color
  strokeColor?: string;      // Stroke color
  strokeWidth?: number;      // Stroke width
  fillOpacity?: number;      // Fill opacity (0-1)
  strokeOpacity?: number;    // Stroke opacity (0-1)
}
```

### Key Methods

```typescript
getPoints(): LatLng[]                  // Get outer ring
setPoints(points: LatLng[]): Polygon   // Set outer ring
getFillColor(): string                 // Get fill color
setFillColor(color: string): Polygon   // Set fill color
getStrokeColor(): string               // Get stroke color
setStrokeColor(color: string): Polygon // Set stroke color
remove(): void                         // Remove from map
```

### Usage Example

```typescript
import { Polygon, LatLng } from '@ohos/maplibre';

// Create area polygon
const area = new Polygon({
  points: [
    new LatLng(39.90, 116.40),
    new LatLng(39.91, 116.40),
    new LatLng(39.91, 116.41),
    new LatLng(39.90, 116.41),
    new LatLng(39.90, 116.40)  // Close the ring
  ],
  fillColor: '#FF0000',
  fillOpacity: 0.3,
  strokeColor: '#AA0000',
  strokeWidth: 2
});

// Add to map
map.addPolygon(area);

// Update appearance
area.setFillColor('#00FF00');
area.setFillOpacity(0.5);

// Remove polygon
area.remove();
```

---

## InfoWindow

### Description

`InfoWindow` displays information popups above markers when they are selected.

### InfoWindowAdapter

Custom info window content adapter.

```typescript
interface InfoWindowAdapter {
  getInfoWindow(marker: Marker): InfoWindowComponent | null;
}
```

### InfoWindowComponent

Custom info window component.

```typescript
@Component
struct CustomInfoWindow {
  @Prop marker: Marker;
  
  build() {
    Column() {
      Text(this.marker.getTitle())
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      Text(this.marker.getSnippet())
        .fontSize(14)
        .fontColor('#666666')
    }
    .backgroundColor(Color.White)
    .padding(10)
    .borderRadius(8)
  }
}
```

### Setting Custom Info Windows

```typescript
map.setInfoWindowAdapter({
  getInfoWindow: (marker: Marker) => {
    return new CustomInfoWindow({ marker: marker });
  }
});
```

### InfoWindow Listeners

```typescript
// Info window click
map.addOnInfoWindowClickListener({
  onInfoWindowClick: (marker) => {
    console.info(`Info window clicked for: ${marker.getTitle()}`);
  }
});

// Info window close
map.addOnInfoWindowCloseListener({
  onInfoWindowClose: (marker) => {
    console.info(`Info window closed for: ${marker.getTitle()}`);
  }
});

// Info window long click
map.addOnInfoWindowLongClickListener({
  onInfoWindowLongClick: (marker) => {
    console.info(`Info window long clicked for: ${marker.getTitle()}`);
  }
});
```

---

## AnnotationView

### Description

`AnnotationView` allows completely custom ArkTS components to be used as map annotations with full interactivity.

### AnnotationViewAdapter

```typescript
interface AnnotationViewAdapter {
  getView(annotation: Annotation): AnnotationViewComponent;
}
```

### Usage Example

```typescript
import { AnnotationView, Annotation } from '@ohos/maplibre';

@Component
struct CustomAnnotation {
  @Prop data: AnnotationViewData;
  
  build() {
    Column() {
      Image($r('app.media.custom_icon'))
        .width(40)
        .height(40)
      Text(this.data.title)
        .fontSize(12)
    }
    .onClick(() => {
      console.info(`Clicked: ${this.data.title}`);
    })
  }
}

// Register adapter
map.setAnnotationViewAdapter({
  getView: (annotation) => {
    return new CustomAnnotation({ data: annotation.data });
  }
});
```

---

## Complete Annotations Example

```typescript
import {
  NativeMapView,
  MapLibreMap,
  Marker,
  Polyline,
  Polygon,
  LatLng,
  OnMarkerClickListener,
  OnMarkerDragListener
} from '@ohos/maplibre';

@Entry
@Component
struct AnnotationsExample {
  private map: MapLibreMap | null = null;
  private markers: Marker[] = [];

  build() {
    NativeMapView({
      styleUrl: "https://demotiles.maplibre.org/style.json",
      onMapViewCreated: (mapLibreMap) => {
        this.map = mapLibreMap;
        this.setupAnnotations();
      }
    })
      .width('100%')
      .height('100%')
  }

  private setupAnnotations() {
    if (!this.map) return;

    // Add markers
    const beijing = new Marker({
      position: new LatLng(39.9042, 116.4074),
      title: 'Beijing',
      snippet: 'Capital of China',
      draggable: true
    });
    this.markers.push(beijing);
    this.map.addMarker(beijing);

    const shanghai = new Marker({
      position: new LatLng(31.2304, 121.4737),
      title: 'Shanghai',
      snippet: 'Financial center'
    });
    this.markers.push(shanghai);
    this.map.addMarker(shanghai);

    // Add route line
    const route = new Polyline({
      points: [
        new LatLng(39.9042, 116.4074),
        new LatLng(31.2304, 121.4737)
      ],
      color: '#FF0000',
      width: 3
    });
    this.map.addPolyline(route);

    // Add area polygon
    const area = new Polygon({
      points: [
        new LatLng(39.85, 116.35),
        new LatLng(39.95, 116.35),
        new LatLng(39.95, 116.45),
        new LatLng(39.85, 116.45),
        new LatLng(39.85, 116.35)
      ],
      fillColor: '#00FF00',
      fillOpacity: 0.2,
      strokeColor: '#00AA00',
      strokeWidth: 2
    });
    this.map.addPolygon(area);

    // Add marker click listener
    this.map.addOnMarkerClickListener({
      onMarkerClick: (marker) => {
        console.info(`Clicked: ${marker.getTitle()}`);
        this.map?.selectMarker(marker);
        return true;
      }
    });

    // Add marker drag listener
    this.map.addOnMarkerDragListener({
      onMarkerDragStart: (marker) => {
        console.info('Drag started');
      },
      onMarkerDrag: (marker) => {
        const pos = marker.getPosition();
        console.info(`Dragging: ${pos.latitude}, ${pos.longitude}`);
      },
      onMarkerDragEnd: (marker) => {
        const pos = marker.getPosition();
        console.info(`Drag ended at: ${pos.latitude}, ${pos.longitude}`);
      }
    });
  }
}
```

---

**Last Updated:** 2025-11-04  
**Version:** 1.0.0

