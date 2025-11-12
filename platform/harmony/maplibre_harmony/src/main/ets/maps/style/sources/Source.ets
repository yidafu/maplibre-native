/**
 * Source - Source type definitions
 *
 * Sources come from the NAPI layer; this module provides helper aliases and unions
 */

import type { GeoJsonSource } from './GeoJsonSource';
import type { VectorSource } from './VectorSource';
import type { RasterSource } from './RasterSource';
import type { RasterDemSource } from './RasterDemSource';
import type { ImageSource } from './ImageSource';
/**
 * Source - Union of all supported source types
 *
 * Enables type-safe operations across every source variant
 */
export type Source =
  | GeoJsonSource
    | VectorSource
    | RasterSource
    | RasterDemSource
    | ImageSource;

/**
 * SourceData - Source payload type
 */
export type SourceData = Object | string | null;

/**
 * SourceMetadata - Source metadata structure
 */
export type SourceMetadata = Record<string, Object> | null;

/**
 * ClusterProperties - Aggregation property map
 */
export type ClusterProperties = Record<string, Object> | null;

/**
 * SourceOptions - Source configuration interface
 *
 * Provides the options available when constructing a source
 */
export interface SourceOptions {
  /** Source identifier */
  id: string;

  /** Source type: 'vector', 'raster', 'raster-dem', 'geojson', 'image', 'video' */
  type: string;

  /** Data payload (GeoJSON source) */
  data?: SourceData;

  /** Minimum zoom level */
  minZoom?: number;

  /** Maximum zoom level */
  maxZoom?: number;

  /** Attribution string */
  attribution?: string;

  /** Bounds [west, south, east, north] */
  bounds?: number[];

  /** Enable clustering (GeoJSON) */
  cluster?: boolean;

  /** Maximum cluster zoom */
  clusterMaxZoom?: number;

  /** Cluster radius in pixels */
  clusterRadius?: number;

  /** Minimum points per cluster */
  clusterMinPoints?: number;

  /** Cluster property definitions */
  clusterProperties?: ClusterProperties;

  /** Auto-generate feature IDs */
  generateId?: boolean;

  /** Property name to promote as ID */
  promoteId?: string;

  /** Geometry simplification tolerance */
  tolerance?: number;

  /** Tile buffer size */
  buffer?: number;

  /** Enable line metrics */
  lineMetrics?: boolean;

  /** Maximum zoom (tile sources) */
  maxzoom?: number;

  /** Tile size */
  tileSize?: number;

  /** TileJSON URL */
  url?: string;

  /** Tile URL templates */
  tiles?: string[];

  /** Tile scheme: 'xyz' or 'tms' */
  scheme?: string;

  /** Metadata */
  metadata?: SourceMetadata;
}
