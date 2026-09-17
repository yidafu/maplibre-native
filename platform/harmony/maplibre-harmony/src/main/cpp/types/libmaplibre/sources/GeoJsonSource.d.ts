import type { ExpressionLiteral } from '../ExpressionTypes';
import type { JSONValue } from '../CommonTypes';
import type { IFeature, IFeatureCollection } from '../geojson';

/**
 * Cluster property configuration for custom aggregate attributes.
 *
 * Format: `{ "propertyName": [operatorExpression, mapExpression] }`
 * - operatorExpression: aggregate operator (e.g. "+", "max", "min") or a full aggregate expression.
 * - mapExpression: expression extracting a value from an individual point.
 *
 * @example
* ```typescript
 * {
 *   // Compute the maximum value.
 *   "max": [["max", ["accumulated"], ["get", "sum"]], ["get", "mag"]],
 *
 *   // Simple sum.
 *   "sum": ["+", ["get", "value"]],
 *
 *   // Check whether any point satisfies a condition.
 *   "hasSpecial": ["any", ["==", ["get", "type"], "special"]]
 * }
 * ```
 */
export type ClusterProperties = Record<string, [ExpressionLiteral | string, ExpressionLiteral]>;

/**
 * GeoJSON source options.
 */
export interface GeoJsonOptions {
  /** Minimum zoom level. */
  minzoom?: number;

  /** Maximum zoom level. */
  maxzoom?: number;

  /** Tile buffer size. */
  buffer?: number;

  /** Simplification tolerance. */
  tolerance?: number;

  /** Enable clustering. */
  cluster?: boolean;

  /** Cluster radius (default 50). */
  clusterRadius?: number;

  /** Cluster maximum zoom. */
  clusterMaxZoom?: number;

  /** Cluster minimum point count (default 2). */
  clusterMinPoints?: number;

  /**
   * Cluster properties computed via expressions.
   *
   * Enables custom aggregations such as min/max, sums/averages, or conditional checks.
   * Each entry follows `[operatorExpr, mapExpr]`.
   * - operatorExpr: aggregate operator or expression array.
   * - mapExpr: expression extracting a value from a feature.
   *
   * @example
  * ```typescript
   * clusterProperties: {
   *   "max_magnitude": [
   *     ["max", ["accumulated"], ["get", "max"]],
   *     ["get", "magnitude"]
   *   ],
   *   "sum_value": ["+", ["get", "value"]]
   * }
   * ```
   */
  clusterProperties?: ClusterProperties;

  /** Enable line metrics. */
  lineMetrics?: boolean;

  /** Generate feature IDs. */
  generateId?: boolean;

  /** Promote ID attribute. */
  promoteId?: string;
}

/**
 * GeoJSON coordinate position type (compatible with all geometries).
 */
export type Position = number[]; // [lng, lat] or [lng, lat, altitude]

/**
 * GeoJSON coordinate union covering all geometries.
 */
export type Coordinates = Position | Position[] | Position[][] | Position[][][];

/**
 * Simplified GeoJSON geometry interface for data interchange.
 * For full geometry types use the geojson module's NAPI classes.
 */
export interface Geometry {
  type: 'Point' | 'LineString' | 'Polygon' | 'MultiPoint' | 'MultiLineString' | 'MultiPolygon' | 'GeometryCollection';
  coordinates: Coordinates;
}

/**
 * Simplified GeoJSON Feature interface for data interchange.
 * For full Feature types use the geojson module's NAPI classes.
 */
export interface Feature {
  type: 'Feature';
  id?: string | number;
  geometry: Geometry | null;
  properties: Record<string, JSONValue>;
}

/**
 * GeoJSON data input types (multiple formats supported).
 */
export type GeoJsonData = string | Geometry | IFeature | IFeatureCollection | object;

/**
 * GeoJsonSource - GeoJSON data source supporting vector features and clustering.
 */
export class GeoJsonSource {
  /**
   * Type token used for ETS-side type checks.
   */
  _TYPE_?: string;

  /**
   * Construct a GeoJSON source.
   * @param id Source identifier.
   * @param options Optional configuration.
   */
  constructor(id: string, options?: GeoJsonOptions);

  /**
   * Get the source identifier.
   */
  getId(): string;

  /**
   * Set GeoJSON data asynchronously.
   * Accepts GeoJSON strings, Geometry objects, Feature objects, or FeatureCollections.
   * @param data GeoJSON payload.
   * @returns this (chainable).
   */
  setGeoJson(data: GeoJsonData): this;

  /**
   * Set GeoJSON data synchronously.
   * Accepts GeoJSON strings, Geometry objects, Feature objects, or FeatureCollections.
   * @param data GeoJSON payload.
   * @returns this (chainable).
   */
  setGeoJsonSync(data: GeoJsonData): this;

  /**
   * Load GeoJSON data from a URL.
   * @param url GeoJSON data URL.
   * @returns this (chainable).
   */
  setUrl(url: string): this;

  /** Set the maximum zoom level for tile generation. */
  setMaxZoom(maxZoom: number): this;

  /** Set the tile buffer size in pixels. */
  setBuffer(buffer: number): this;

  /** Set geometry simplification tolerance. */
  setTolerance(tolerance: number): this;

  /** Enable or disable line metrics. */
  setLineMetrics(lineMetrics: boolean): this;

  /** Enable or disable clustering. */
  setCluster(cluster: boolean): this;

  /** Set cluster radius in pixels. */
  setClusterRadius(clusterRadius: number): this;

  /** Set the maximum zoom used during clustering. */
  setClusterMaxZoom(clusterMaxZoom: number): this;

  /** Set the minimum number of points required to form a cluster. */
  setClusterMinPoints(clusterMinPoints: number): this;

  /**
   * Get the data URL.
   */
  getUrl(): string;

  /**
   * Query source features.
   * @param filter Optional filter expression.
   * @returns Array of IFeature.
   */
  querySourceFeatures(filter?: ExpressionLiteral): IFeature[];

  /**
   * Retrieve children of a cluster.
   * @param clusterId Cluster ID or an IFeature containing cluster_id.
   * @returns Array of child IFeature.
   */
  getClusterChildren(clusterId: number | IFeature): IFeature[];

  /**
   * Retrieve cluster leaves.
   * @param clusterId Cluster ID or IFeature containing cluster_id.
   * @param limit Maximum leaf count (default 10).
   * @param offset Offset into the leaf set (default 0).
   * @returns Array of leaf IFeature.
   */
  getClusterLeaves(clusterId: number | IFeature, limit?: number, offset?: number): IFeature[];

  /**
   * Get the expansion zoom for a cluster.
   * @param clusterId Cluster ID or IFeature containing cluster_id.
   * @returns Target zoom level.
   */
  getClusterExpansionZoom(clusterId: number | IFeature): number;
}
