# Style, Expressions & Sources Modules

## Overview

This document covers three interconnected modules: Style (map appearance), Expressions (data-driven styling), and Sources (data providers for layers).

---

## Style Module

### Style

Main style management class.

```typescript
class Style {
  // Layer management
  addLayer(layer: Layer, beforeId?: string): void;
  removeLayer(layerId: string): void;
  getLayer(layerId: string): Layer | null;
  
  // Source management
  addSource(sourceId: string, source: Source): void;
  removeSource(sourceId: string): void;
  getSource(sourceId: string): Source | null;
  
  // Image management
  addImage(imageId: string, image: PixelMap): void;
  removeImage(imageId: string): void;
  hasImage(imageId: string): boolean;
  
  // Light
  setLight(light: Light): void;
  getLight(): Light | null;
  
  // Transition
  setTransition(duration: number, delay: number): void;
}
```

### Layer Types

All layer classes follow similar patterns:

```typescript
// Fill Layer
class FillLayer {
  constructor(id: string, sourceId: string);
  setVisibility(visibility: 'visible' | 'none'): FillLayer;
  setMinZoom(zoom: number): FillLayer;
  setMaxZoom(zoom: number): FillLayer;
  setFilter(filter: Expression<boolean>): FillLayer;
  setFillColor(color: PropertyValue<string>): FillLayer;
  setFillOpacity(opacity: PropertyValue<number>): FillLayer;
  setFillPattern(pattern: PropertyValue<string>): FillLayer;
}

// Line Layer
class LineLayer {
  setLineColor(color: PropertyValue<string>): LineLayer;
  setLineWidth(width: PropertyValue<number>): LineLayer;
  setLineOpacity(opacity: PropertyValue<number>): LineLayer;
  setLineDasharray(dasharray: PropertyValue<number[]>): LineLayer;
}

// Circle Layer
class CircleLayer {
  setCircleRadius(radius: PropertyValue<number>): CircleLayer;
  setCircleColor(color: PropertyValue<string>): CircleLayer;
  setCircleOpacity(opacity: PropertyValue<number>): CircleLayer;
}

// Symbol Layer
class SymbolLayer {
  setTextField(text: PropertyValue<string>): SymbolLayer;
  setTextSize(size: PropertyValue<number>): SymbolLayer;
  setTextColor(color: PropertyValue<string>): SymbolLayer;
  setIconImage(image: PropertyValue<string>): SymbolLayer;
  setIconSize(size: PropertyValue<number>): SymbolLayer;
}

// Raster Layer
class RasterLayer {
  setRasterOpacity(opacity: PropertyValue<number>): RasterLayer;
  setRasterBrightnessMin(brightness: PropertyValue<number>): RasterLayer;
  setRasterBrightnessMax(brightness: PropertyValue<number>): RasterLayer;
}

// Background Layer
class BackgroundLayer {
  setBackgroundColor(color: PropertyValue<string>): BackgroundLayer;
  setBackgroundOpacity(opacity: PropertyValue<number>): BackgroundLayer;
}

// Heatmap Layer
class HeatmapLayer {
  setHeatmapRadius(radius: PropertyValue<number>): HeatmapLayer;
  setHeatmapWeight(weight: PropertyValue<number>): HeatmapLayer;
  setHeatmapIntensity(intensity: PropertyValue<number>): HeatmapLayer;
  setHeatmapColor(color: Expression<string>): HeatmapLayer;
}

// Fill Extrusion Layer (3D buildings)
class FillExtrusionLayer {
  setFillExtrusionHeight(height: PropertyValue<number>): FillExtrusionLayer;
  setFillExtrusionBase(base: PropertyValue<number>): FillExtrusionLayer;
  setFillExtrusionColor(color: PropertyValue<string>): FillExtrusionLayer;
  setFillExtrusionOpacity(opacity: PropertyValue<number>): FillExtrusionLayer;
}

// Hillshade Layer
class HillshadeLayer {
  setHillshadeIlluminationDirection(direction: PropertyValue<number>): HillshadeLayer;
  setHillshadeExaggeration(exaggeration: PropertyValue<number>): HillshadeLayer;
}
```

### Example: Creating Layers

```typescript
import { FillLayer, LineLayer, SymbolLayer } from '@ohos/maplibre';

// Fill layer
const fillLayer = new FillLayer('buildings-fill', 'buildings-source');
fillLayer
  .setFillColor('#CCCCCC')
  .setFillOpacity(0.8)
  .setMinZoom(12);
map.addLayer(fillLayer);

// Line layer
const lineLayer = new LineLayer('roads', 'roads-source');
lineLayer
  .setLineColor('#FF0000')
  .setLineWidth(3)
  .setLineDasharray([2, 1]);
map.addLayer(lineLayer);

// Symbol layer
const symbolLayer = new SymbolLayer('pois', 'poi-source');
symbolLayer
  .setTextField(['get', 'name'])
  .setTextSize(12)
  .setIconImage('poi-icon');
map.addLayer(symbolLayer);
```

---

## Expressions Module

### Expression

Data-driven styling using expressions.

```typescript
class Expression<T> {
  // Literals
  static literal(value: any): Expression<any>;
  
  // Lookups
  static get(property: string): Expression<any>;
  static at(index: number, array: Expression<any[]>): Expression<any>;
  static has(property: string): Expression<boolean>;
  static hasNot(property: string): Expression<boolean>;
  
  // Math
  static add(...values: Expression<number>[]): Expression<number>;
  static subtract(a: Expression<number>, b: Expression<number>): Expression<number>;
  static multiply(...values: Expression<number>[]): Expression<number>;
  static divide(a: Expression<number>, b: Expression<number>): Expression<number>;
  static mod(a: Expression<number>, b: Expression<number>): Expression<number>;
  static pow(base: Expression<number>, exponent: Expression<number>): Expression<number>;
  static sqrt(value: Expression<number>): Expression<number>;
  static abs(value: Expression<number>): Expression<number>;
  static min(...values: Expression<number>[]): Expression<number>;
  static max(...values: Expression<number>[]): Expression<number>;
  
  // Comparison
  static eq(a: Expression<any>, b: Expression<any>): Expression<boolean>;
  static neq(a: Expression<any>, b: Expression<any>): Expression<boolean>;
  static lt(a: Expression<any>, b: Expression<any>): Expression<boolean>;
  static lte(a: Expression<any>, b: Expression<any>): Expression<boolean>;
  static gt(a: Expression<any>, b: Expression<any>): Expression<boolean>;
  static gte(a: Expression<any>, b: Expression<any>): Expression<boolean>;
  
  // Logic
  static all(...conditions: Expression<boolean>[]): Expression<boolean>;
  static any(...conditions: Expression<boolean>[]): Expression<boolean>;
  static not(condition: Expression<boolean>): Expression<boolean>;
  
  // Conditional
  static match<T>(
    input: Expression<any>,
    cases: Record<string, T>,
    defaultValue: T
  ): Expression<T>;
  
  static case(...conditions: any[]): Expression<any>;
  
  static coalesce(...values: Expression<any>[]): Expression<any>;
  
  // Interpolation
  static interpolate(
    interpolationType: 'linear' | ['exponential', number] | ['cubic-bezier', number, number, number, number],
    input: Expression<number>,
    ...stops: [number, any][]
  ): Expression<any>;
  
  static step(
    input: Expression<number>,
    defaultValue: any,
    ...stops: [number, any][]
  ): Expression<any>;
  
  // String
  static concat(...values: Expression<string>[]): Expression<string>;
  static downcase(value: Expression<string>): Expression<string>;
  static upcase(value: Expression<string>): Expression<string>;
  
  // Array
  static length(array: Expression<any[]>): Expression<number>;
  
  // Type conversion
  static toString(value: Expression<any>): Expression<string>;
  static toNumber(value: Expression<any>): Expression<number>;
  static toBoolean(value: Expression<any>): Expression<boolean>;
  static toColor(value: Expression<any>): Expression<string>;
}
```

### Expression Examples

```typescript
import { Expression } from '@ohos/maplibre';

// Property lookup
const name = Expression.get('name');
const population = Expression.get('population');

// Conditional styling
const color = Expression.case(
  Expression.gt(population, Expression.literal(1000000)),
  Expression.literal('#FF0000'),  // Red for large cities
  Expression.gt(population, Expression.literal(100000)),
  Expression.literal('#FFAA00'),  // Orange for medium cities
  Expression.literal('#00FF00')   // Green for small cities
);

// Match expression
const categoryColor = Expression.match(
  Expression.get('category'),
  {
    'restaurant': '#FF0000',
    'hotel': '#00FF00',
    'shop': '#0000FF'
  },
  '#CCCCCC'  // Default color
);

// Interpolation
const radiusByZoom = Expression.interpolate(
  'linear',
  Expression.zoom(),
  [10, 5],   // At zoom 10, radius = 5
  [15, 20],  // At zoom 15, radius = 20
  [20, 50]   // At zoom 20, radius = 50
);

// Use in layer
fillLayer.setFillColor(color);
circleLayer.setCircleRadius(radiusByZoom);
```

---

## Sources Module

### Source Types

#### GeoJsonSource

GeoJSON data source.

```typescript
class GeoJsonSource {
  constructor(id: string, options: GeoJsonSourceOptions);
  setGeoJSON(data: GeoJsonData): void;
  getClusterExpansionZoom(clusterId: number): Promise<number>;
  getClusterChildren(clusterId: number): Promise<IFeature[]>;
  getClusterLeaves(clusterId: number, limit: number, offset: number): Promise<IFeature[]>;
}

interface GeoJsonSourceOptions {
  data?: GeoJsonData;
  maxzoom?: number;
  buffer?: number;
  tolerance?: number;
  cluster?: boolean;
  clusterRadius?: number;
  clusterMaxZoom?: number;
  lineMetrics?: boolean;
}
```

#### VectorSource

Vector tile source.

```typescript
class VectorSource {
  constructor(id: string, options: VectorSourceOptions);
}

interface VectorSourceOptions {
  url?: string;
  tiles?: string[];
  minzoom?: number;
  maxzoom?: number;
  bounds?: [number, number, number, number];
}
```

#### RasterSource

Raster tile source.

```typescript
class RasterSource {
  constructor(id: string, options: RasterSourceOptions);
}

interface RasterSourceOptions {
  url?: string;
  tiles?: string[];
  tileSize?: number;
  minzoom?: number;
  maxzoom?: number;
}
```

#### RasterDemSource

Raster DEM (elevation) source.

```typescript
class RasterDemSource {
  constructor(id: string, options: RasterDemSourceOptions);
}

interface RasterDemSourceOptions {
  url?: string;
  tiles?: string[];
  encoding?: 'terrarium' | 'mapbox';
}
```

#### ImageSource

Single image source.

```typescript
class ImageSource {
  constructor(id: string, options: ImageSourceOptions);
  setCoordinates(coordinates: [LatLng, LatLng, LatLng, LatLng]): void;
  setUrl(url: string): void;
}

interface ImageSourceOptions {
  url: string;
  coordinates: [LatLng, LatLng, LatLng, LatLng];  // [top-left, top-right, bottom-right, bottom-left]
}
```

### Source Examples

```typescript
import {
  GeoJsonSource,
  VectorSource,
  RasterSource,
  ImageSource
} from '@ohos/maplibre';

// GeoJSON source
const geojsonSource = new GeoJsonSource('my-geojson', {
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
          name: 'Beijing'
        }
      }
    ]
  },
  cluster: true,
  clusterRadius: 50
});
map.addSource('my-geojson', geojsonSource);

// Vector source
const vectorSource = new VectorSource('maplibre', {
  url: 'https://demotiles.maplibre.org/tiles/tiles.json'
});
map.addSource('maplibre', vectorSource);

// Raster source
const satelliteSource = new RasterSource('satellite', {
  tiles: ['https://tile.server/{z}/{x}/{y}.png'],
  tileSize: 256,
  maxzoom: 18
});
map.addSource('satellite', satelliteSource);

// Image source
const imageSource = new ImageSource('overlay', {
  url: 'https://example.com/image.png',
  coordinates: [
    new LatLng(40.0, 116.0),  // top-left
    new LatLng(40.0, 117.0),  // top-right
    new LatLng(39.0, 117.0),  // bottom-right
    new LatLng(39.0, 116.0)   // bottom-left
  ]
});
map.addSource('overlay', imageSource);
```

---

**Last Updated:** 2025-11-04  
**Version:** 1.0.0

