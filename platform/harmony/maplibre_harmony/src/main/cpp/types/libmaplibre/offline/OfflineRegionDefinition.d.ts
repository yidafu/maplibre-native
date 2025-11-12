/**
 * OfflineRegionDefinition - offline region definition types.
 *
 * Describes the structures used to declare offline map coverage and parameters.
 */

/**
 * Geographic bounds describing a rectangular lat/lng area.
 */
export interface LatLngBounds {
  /** Northern latitude (maximum, -90 to 90). */
  north: number;

  /** Southern latitude (minimum, -90 to 90). */
  south: number;

  /** Eastern longitude (maximum, -180 to 180). */
  east: number;

  /** Western longitude (minimum, -180 to 180). */
  west: number;
}

/**
 * GeoJSON geometry type supporting Point, LineString, Polygon, MultiPoint, MultiLineString, MultiPolygon.
 */
export interface GeoJSONGeometry {
  /** Geometry type name. */
  type: 'Point' | 'LineString' | 'Polygon' | 'MultiPoint' | 'MultiLineString' | 'MultiPolygon' | 'GeometryCollection';

  /** Coordinates array (structure depends on the geometry type). */
  coordinates?: number[] | number[][] | number[][][];

  /** Geometry collection contents (GeometryCollection only). */
  geometries?: GeoJSONGeometry[];
}

/**
 * Offline region definition based on a tile pyramid.
 *
 * Uses rectangular bounds and downloads all tiles across the specified zoom range.
 */
export interface OfflineTilePyramidRegionDefinition {
  /** Definition type discriminator. */
  type: 'tilePyramid';

  /**
   * Map style URL (e.g. "https://demotiles.maplibre.org/style.json").
   */
  styleURL: string;

  /**
   * Geographic bounds specifying the download area.
   */
  bounds: LatLngBounds;

  /**
   * Minimum zoom level (inclusive). Range: 0-22, commonly 0-16.
   */
  minZoom: number;

  /**
   * Maximum zoom level (inclusive). Range: 0-22 (higher zooms yield more tiles).
   */
  maxZoom: number;

  /**
   * Device pixel ratio (commonly 1.0, 2.0, 3.0). Higher ratios fetch higher-resolution tiles.
   */
  pixelRatio: number;

  /**
   * Include CJK ideographs in glyph downloads.
   * true downloads CJK glyphs (more data); false skips them.
   */
  includeIdeographs: boolean;
}

/**
 * Offline region definition using arbitrary geometry.
 *
 * Leverages GeoJSON geometry for complex shapes, ideal for fine-grained coverage control.
 */
export interface OfflineGeometryRegionDefinition {
  /** Definition type discriminator. */
  type: 'geometry';

  /**
   * Map style URL (e.g. "https://demotiles.maplibre.org/style.json").
   */
  styleURL: string;

  /**
   * GeoJSON geometry. Supports Polygon, MultiPolygon, etc.
   * Only tiles intersecting the geometry are downloaded.
   * Accepts GeoJSONGeometry or compatible objects.
   */
  geometry: GeoJSONGeometry | object;

  /**
   * Minimum zoom level (inclusive). Range: 0-22.
   */
  minZoom: number;

  /**
   * Maximum zoom level (inclusive). Range: 0-22.
   */
  maxZoom: number;

  /**
   * Device pixel ratio (commonly 1.0, 2.0, 3.0).
   */
  pixelRatio: number;

  /**
   * Include CJK ideographs in glyph downloads (true) or skip them (false).
   */
  includeIdeographs: boolean;
}

/**
 * Offline region definition union (tile pyramid or geometry-based).
 */
export type OfflineRegionDefinition =
  | OfflineTilePyramidRegionDefinition
    | OfflineGeometryRegionDefinition;

