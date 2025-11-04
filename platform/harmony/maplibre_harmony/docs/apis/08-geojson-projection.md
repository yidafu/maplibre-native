# GeoJSON & Projection Modules

## Overview

This document covers GeoJSON types for geographic data and Projection utilities for coordinate conversion.

---

## GeoJSON Module

### Description

The GeoJSON module provides TypeScript types and utilities for working with GeoJSON data format, following the RFC 7946 specification.

### GeoJSON Types

```typescript
// Base types
type GeoJsonGeometryType =
  | 'Point'
  | 'MultiPoint'
  | 'LineString'
  | 'MultiLineString'
  | 'Polygon'
  | 'MultiPolygon'
  | 'GeometryCollection';

// Position (longitude, latitude, [elevation])
type Position = [number, number] | [number, number, number];

// Geometries
interface Point {
  type: 'Point';
  coordinates: Position;
}

interface MultiPoint {
  type: 'MultiPoint';
  coordinates: Position[];
}

interface LineString {
  type: 'LineString';
  coordinates: Position[];
}

interface MultiLineString {
  type: 'MultiLineString';
  coordinates: Position[][];
}

interface Polygon {
  type: 'Polygon';
  coordinates: Position[][];  // First ring is outer, others are holes
}

interface MultiPolygon {
  type: 'MultiPolygon';
  coordinates: Position[][][];
}

interface GeometryCollection {
  type: 'GeometryCollection';
  geometries: Geometry[];
}

type Geometry =
  | Point
  | MultiPoint
  | LineString
  | MultiLineString
  | Polygon
  | MultiPolygon
  | GeometryCollection;

// Feature
interface Feature<G extends Geometry = Geometry, P = Record<string, any>> {
  type: 'Feature';
  geometry: G;
  properties: P;
  id?: string | number;
}

// FeatureCollection
interface FeatureCollection<G extends Geometry = Geometry, P = Record<string, any>> {
  type: 'FeatureCollection';
  features: Feature<G, P>[];
}

// Union type
type GeoJson = Geometry | Feature | FeatureCollection;
```

### Usage Examples

#### Creating GeoJSON Objects

```typescript
import type { Point, LineString, Polygon, Feature, FeatureCollection } from '@ohos/maplibre';

// Point geometry
const point: Point = {
  type: 'Point',
  coordinates: [116.4074, 39.9042]  // Beijing
};

// LineString geometry
const line: LineString = {
  type: 'LineString',
  coordinates: [
    [116.4074, 39.9042],
    [121.4737, 31.2304]
  ]
};

// Polygon geometry
const polygon: Polygon = {
  type: 'Polygon',
  coordinates: [
    [
      [116.0, 39.0],
      [117.0, 39.0],
      [117.0, 40.0],
      [116.0, 40.0],
      [116.0, 39.0]
    ]
  ]
};

// Feature with properties
const feature: Feature = {
  type: 'Feature',
  geometry: point,
  properties: {
    name: 'Beijing',
    population: 21540000,
    capital: true
  }
};

// FeatureCollection
const collection: FeatureCollection = {
  type: 'FeatureCollection',
  features: [
    {
      type: 'Feature',
      geometry: { type: 'Point', coordinates: [116.4074, 39.9042] },
      properties: { name: 'Beijing' }
    },
    {
      type: 'Feature',
      geometry: { type: 'Point', coordinates: [121.4737, 31.2304] },
      properties: { name: 'Shanghai' }
    }
  ]
};
```

#### Using with Map

```typescript
import { GeoJsonSource } from '@ohos/maplibre';

// Add GeoJSON source
const source = new GeoJsonSource('my-data', {
  data: {
    type: 'FeatureCollection',
    features: [
      {
        type: 'Feature',
        geometry: {
          type: 'Point',
          coordinates: [116.4074, 39.9042]
        },
        properties: {
          name: 'Beijing',
          category: 'capital'
        }
      }
    ]
  }
});
map.addSource('my-data', source);

// Add layer to visualize
const layer = new CircleLayer('my-points', 'my-data');
layer
  .setCircleRadius(8)
  .setCircleColor('#FF0000');
map.addLayer(layer);
```

#### Dynamic GeoJSON Updates

```typescript
import { GeoJsonSource, FeatureCollection } from '@ohos/maplibre';

// Create source
const source = new GeoJsonSource('live-data', {
  data: {
    type: 'FeatureCollection',
    features: []
  }
});
map.addSource('live-data', source);

// Update data dynamically
function updateData(newFeatures: Feature[]) {
  const collection: FeatureCollection = {
    type: 'FeatureCollection',
    features: newFeatures
  };
  source.setGeoJSON(collection);
}

// Example: Add new point
const newFeature: Feature = {
  type: 'Feature',
  geometry: {
    type: 'Point',
    coordinates: [116.5, 39.9]
  },
  properties: {
    timestamp: Date.now()
  }
};

updateData([newFeature]);
```

#### GeoJSON Clustering

```typescript
// Create clustered source
const clusteredSource = new GeoJsonSource('clusters', {
  data: featureCollection,
  cluster: true,
  clusterRadius: 50,
  clusterMaxZoom: 14
});
map.addSource('clusters', clusteredSource);

// Cluster layer
const clusterLayer = new CircleLayer('clusters-layer', 'clusters');
clusterLayer
  .setFilter(['has', 'point_count'])
  .setCircleColor('#51bbd6')
  .setCircleRadius([
    'step',
    ['get', 'point_count'],
    20,   // radius for count < 100
    100, 30,   // radius for count >= 100
    750, 40    // radius for count >= 750
  ]);
map.addLayer(clusterLayer);

// Cluster count layer
const countLayer = new SymbolLayer('cluster-count', 'clusters');
countLayer
  .setFilter(['has', 'point_count'])
  .setTextField(['get', 'point_count_abbreviated'])
  .setTextSize(12);
map.addLayer(countLayer);

// Unclustered points layer
const unclusteredLayer = new CircleLayer('unclustered-point', 'clusters');
unclusteredLayer
  .setFilter(['!', ['has', 'point_count']])
  .setCircleColor('#11b4da')
  .setCircleRadius(5);
map.addLayer(unclusteredLayer);
```

---

## Projection Module

### Projection

Coordinate conversion utilities.

```typescript
class Projection {
  constructor(nativeMapView: NativeMapView, width: number, height: number);
  
  // Convert between geographic and screen coordinates
  pixelForLatLng(latLng: LatLng): Point;
  latLngForPixel(point: Point): LatLng;
  
  // Convert between geographic and projected meters
  projectedMetersForLatLng(latLng: LatLng): ProjectedMeters;
  latLngForProjectedMeters(meters: ProjectedMeters): LatLng;
  
  // Get visible region
  getVisibleRegion(): VisibleRegion;
  
  // Meters per pixel at latitude
  getMetersPerPixelAtLatitude(latitude: number, zoom: number): number;
}
```

### VisibleRegion

Represents the visible map region.

```typescript
class VisibleRegion {
  nearLeft: LatLng;       // Near-left corner
  nearRight: LatLng;      // Near-right corner
  farLeft: LatLng;        // Far-left corner
  farRight: LatLng;       // Far-right corner
  latLngBounds: LatLngBounds;  // Bounding box
  
  constructor(
    nearLeft: LatLng,
    nearRight: LatLng,
    farLeft: LatLng,
    farRight: LatLng,
    bounds: LatLngBounds
  );
  
  contains(latLng: LatLng): boolean;
}
```

### Usage Examples

#### Screen to Geographic Conversion

```typescript
import { Projection } from '@ohos/maplibre';

const projection = map.getProjection();

// Convert touch point to geographic coordinate
const touchPoint = new Point(375, 667);
const latLng = projection.latLngForPixel(touchPoint);
console.info(`Touched at: ${latLng.latitude}, ${latLng.longitude}`);

// Convert geographic coordinate to screen position
const beijing = new LatLng(39.9042, 116.4074);
const screenPoint = projection.pixelForLatLng(beijing);
console.info(`Beijing is at screen position: ${screenPoint.x}, ${screenPoint.y}`);
```

#### Projected Meters Conversion

```typescript
// Convert to projected meters
const latLng = new LatLng(39.9042, 116.4074);
const meters = projection.projectedMetersForLatLng(latLng);
console.info(`Projected: ${meters.northing}, ${meters.easting}`);

// Convert back to LatLng
const backToLatLng = projection.latLngForProjectedMeters(meters);
```

#### Visible Region

```typescript
// Get currently visible region
const visibleRegion = projection.getVisibleRegion();

// Check if point is visible
const point = new LatLng(39.9, 116.4);
if (visibleRegion.contains(point)) {
  console.info('Point is visible on screen');
}

// Get bounds
const bounds = visibleRegion.latLngBounds;
console.info(`Visible area: ${bounds.toString()}`);
```

#### Distance Calculations

```typescript
// Calculate meters per pixel at given latitude
const zoom = map.getZoom();
const metersPerPixel = projection.getMetersPerPixelAtLatitude(39.9042, zoom);
console.info(`At current zoom, 1 pixel = ${metersPerPixel.toFixed(2)} meters`);

// Calculate screen distance from geographic distance
const point1 = new LatLng(39.9042, 116.4074);
const point2 = new LatLng(39.9142, 116.4174);

const geoDistance = point1.distanceTo(point2);  // meters
const screenPoint1 = projection.pixelForLatLng(point1);
const screenPoint2 = projection.pixelForLatLng(point2);
const screenDistance = screenPoint1.distanceTo(screenPoint2);  // pixels

console.info(`Geographic distance: ${geoDistance.toFixed(0)}m`);
console.info(`Screen distance: ${screenDistance.toFixed(0)}px`);
```

#### Interactive Conversion Example

```typescript
import {
  NativeMapView,
  MapLibreMap,
  Projection,
  LatLng,
  Point
} from '@ohos/maplibre';

@Entry
@Component
struct ProjectionExample {
  private map: MapLibreMap | null = null;
  private projection: Projection | null = null;

  build() {
    Column() {
      NativeMapView({
        styleUrl: "https://demotiles.maplibre.org/style.json",
        onMapViewCreated: (mapLibreMap) => {
          this.map = mapLibreMap;
          this.projection = mapLibreMap.getProjection();
          this.setupInteraction();
        }
      })
        .width('100%')
        .height('100%')
        .onClick((event: ClickEvent) => {
          this.handleMapClick(event.x, event.y);
        })
    }
  }

  private setupInteraction() {
    this.map?.addOnMapClickListener({
      onMapClick: (latLng: LatLng) => {
        // Convert back to screen coordinates
        const screenPoint = this.projection?.pixelForLatLng(latLng);
        console.info(`Clicked at screen: ${screenPoint?.x}, ${screenPoint?.y}`);
        console.info(`Geographic: ${latLng.latitude}, ${latLng.longitude}`);
        
        // Add marker at clicked location
        const marker = new Marker({
          position: latLng,
          title: `${latLng.latitude.toFixed(4)}, ${latLng.longitude.toFixed(4)}`
        });
        this.map?.addMarker(marker);
        
        return true;
      }
    });
  }

  private handleMapClick(x: number, y: number) {
    if (!this.projection) return;
    
    // Convert screen coordinates to geographic
    const point = new Point(x, y);
    const latLng = this.projection.latLngForPixel(point);
    
    console.info(`Screen click: ${x}, ${y}`);
    console.info(`Maps to: ${latLng.latitude}, ${latLng.longitude}`);
  }
}
```

---

**Last Updated:** 2025-11-04  
**Version:** 1.0.0

