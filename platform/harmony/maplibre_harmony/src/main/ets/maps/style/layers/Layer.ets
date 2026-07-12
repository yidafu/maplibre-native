/**
 * Layer - Layer type definitions
 *
 * Layers are provided by the NAPI layer; this file offers helper type aliases
 */

import { FillLayer } from './FillLayer';
import { LineLayer } from './LineLayer';
import { SymbolLayer } from './SymbolLayer';
import { CircleLayer } from './CircleLayer';
import { HeatmapLayer } from './HeatmapLayer';
import { FillExtrusionLayer } from './FillExtrusionLayer';
import { RasterLayer } from './RasterLayer';
import { HillshadeLayer } from './HillshadeLayer';
import { ColorReliefLayer } from './ColorReliefLayer';
import { BackgroundLayer } from './BackgroundLayer';
import type { FilterExpression } from './Expression';
import type {
  BackgroundLayout,
  CircleLayout,
  FillExtrusionLayout,
  FillLayout,
  HeatmapLayout,
  HillshadeLayout,
  LineLayout,
  RasterLayout,
  SymbolLayout
} from './LayerLayout';
import type {
  BackgroundPaint,
  CirclePaint,
  FillExtrusionPaint,
  FillPaint,
  HeatmapPaint,
  HillshadePaint,
  ColorReliefPaint,
  LinePaint,
  RasterPaint,
  SymbolPaint
} from './LayerPaint';
import { CustomLayer } from '..';

// Layer type represents the union of all concrete layer types
export type Layer =
  | FillLayer
    | LineLayer
    | SymbolLayer
    | CircleLayer
    | HeatmapLayer
    | FillExtrusionLayer
    | RasterLayer
    | HillshadeLayer
    | ColorReliefLayer
    | BackgroundLayer
    | CustomLayer;

/**
 * LayerFilter - Layer filter type
 *
 * MapLibre expression arrays used to filter features
 *
 * @see https://maplibre.org/maplibre-style-spec/layers/#filter
 * @example
* ["==", ["get", "type"], "restaurant"]
 * ["all", [">=", ["get", "price"], 10], ["<", ["get", "price"], 100]]
 * ["in", "class", ["literal", ["motorway", "trunk"]]]
 */
export type LayerFilter = FilterExpression | null;

/**
 * LayerLayout - Layer layout property type
 *
 * Layout properties control geometry placement and visibility
 * Each layer type has its own layout property set
 *
 * @see https://maplibre.org/maplibre-style-spec/layers/#layout
 */
export type LayerLayout =
  | BackgroundLayout
    | FillLayout
    | LineLayout
    | SymbolLayout
    | CircleLayout
    | HeatmapLayout
    | FillExtrusionLayout
    | RasterLayout
    | HillshadeLayout;

/**
 * LayerPaint - Layer paint property type
 *
 * Paint properties control the visual appearance of layers
 * Each layer type has its own paint property set
 *
 * @see https://maplibre.org/maplibre-style-spec/layers/#paint
 */
export type LayerPaint =
  | BackgroundPaint
    | FillPaint
    | LinePaint
    | SymbolPaint
    | CirclePaint
    | HeatmapPaint
    | FillExtrusionPaint
    | RasterPaint
    | HillshadePaint
    | ColorReliefPaint;

/**
 * LayerMetadata - Layer metadata type
 *
 * Stores custom metadata for layers
 * Users can supply arbitrary data that is not constrained by the MapLibre spec
 *
 * @see https://maplibre.org/maplibre-style-spec/layers/#metadata
 */
export type LayerMetadata = Record<string, Object> | null;

/**
 * LayerOptions - Layer configuration interface
 *
 * Configuration options used to construct a layer
 */
export interface LayerOptions {
  /** Layer ID */
  id: string;

  /** Layer type: 'fill', 'line', 'symbol', 'circle', 'heatmap', 'fill-extrusion', 'raster', 'hillshade', 'background' */
  type: string;

  /** Source ID */
  source: string;

  /** Source layer name (vector tiles) */
  sourceLayer?: string;

  /** Minimum zoom level */
  minZoom?: number;

  /** Maximum zoom level */
  maxZoom?: number;

  /** Filter expression */
  filter?: LayerFilter;

  /** Layout properties */
  layout?: LayerLayout;

  /** Paint properties */
  paint?: LayerPaint;

  /** Metadata */
  metadata?: LayerMetadata;
}
