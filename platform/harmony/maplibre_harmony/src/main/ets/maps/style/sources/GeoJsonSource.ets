/**
 * GeoJsonSource - Wrapper around the GeoJSON data source
 *
 * Provides comprehensive GeoJSON source capabilities, including:
 * - Multiple data formats (string, Feature, FeatureCollection, Geometry)
 * - Asynchronous and synchronous updates
 * - Source queries
 * - Clustering utilities
 */
import maplibre from 'libmaplibre.so';
import type { ExpressionLiteral } from 'libmaplibre.so';
import { Geometry, IFeature, IFeatureCollection } from '../../geojson';
import { GeoJsonOptions } from './GeoJsonOptions';
import type { Expression } from '../../style/expressions/Expression';
/**
 * Internal marker used to identify the fromNative factory
 */
class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

/**
 * GeoJSON data shape
 * Accepts strings, GeoJSON objects, or native NAPI counterparts
 */
export type GeoJsonData = string | IFeature | IFeatureCollection | Geometry | Object;

/**
 * GeoJsonSource implementation
 */
export class GeoJsonSource {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'GeoJsonSource';
  private nativeInstance: maplibre.GeoJsonSource;

  /**
   * Constructor (prefer using the static factory helpers)
   * @param idOrMarker Source identifier or internal marker
   * @param optionsOrNative Options object or native instance
   */
  constructor(idOrMarker: string | InternalMarker, optionsOrNative?: GeoJsonOptions | maplibre.GeoJsonSource) {
    if (idOrMarker === InternalMarker.INSTANCE && optionsOrNative instanceof Object) {
      // Construct from a native instance
      this.nativeInstance = optionsOrNative as maplibre.GeoJsonSource;
    } else if (typeof idOrMarker === 'string') {
      // Construct with ETS options
      this.nativeInstance = new maplibre.GeoJsonSource(idOrMarker, optionsOrNative as GeoJsonOptions);
    } else {
      throw new Error('Invalid GeoJsonSource constructor arguments');
    }
  }

  // ==================== Static factory helpers ====================

  /**
   * Create an empty GeoJsonSource
   * @param id Source identifier
   * @param options Optional configuration
   * @returns GeoJsonSource instance
   */
  static create(id: string, options?: GeoJsonOptions): GeoJsonSource {
    return new GeoJsonSource(id, options);
  }

  /**
   * Create a source from a GeoJSON string
   * @param id Source identifier
   * @param geojson GeoJSON string
   * @param options Optional configuration
   * @returns GeoJsonSource instance
   */
  static fromGeoJson(id: string, geojson: string, options?: GeoJsonOptions): GeoJsonSource {
    const source = new GeoJsonSource(id, options);
    source.setGeoJson(geojson);
    return source;
  }

  /**
   * Create from a Feature
   * @param id Source identifier
   * @param feature Feature object
   * @param options Optional configuration
   * @returns GeoJsonSource instance
   */
  static fromFeature(id: string, feature: IFeature, options?: GeoJsonOptions): GeoJsonSource {
    const source = new GeoJsonSource(id, options);
    source.setGeoJson(feature);
    return source;
  }

  /**
   * Create from a FeatureCollection
   * @param id Source identifier
   * @param featureCollection FeatureCollection object
   * @param options Optional configuration
   * @returns GeoJsonSource instance
   */
  static fromFeatureCollection(id: string, featureCollection: IFeatureCollection,
    options?: GeoJsonOptions): GeoJsonSource {
    const source = new GeoJsonSource(id, options);
    source.setGeoJson(featureCollection);
    return source;
  }

  /**
   * Create from a Geometry
   * @param id Source identifier
   * @param geometry Geometry object
   * @param options Optional configuration
   * @returns GeoJsonSource instance
   */
  static fromGeometry(id: string, geometry: Geometry, options?: GeoJsonOptions): GeoJsonSource {
    const source = new GeoJsonSource(id, options);
    source.setGeoJson(geometry);
    return source;
  }

  /**
   * Create from a URL
   * @param id Source identifier
   * @param url GeoJSON URL
   * @param options Optional configuration
   * @returns GeoJsonSource instance
   */
  static fromUrl(id: string, url: string, options?: GeoJsonOptions): GeoJsonSource {
    const source = new GeoJsonSource(id, options);
    source.setUrl(url);
    return source;
  }

  /**
   * Create from a native instance (internal use)
   * @param nativeInstance Native GeoJsonSource instance
   * @returns GeoJsonSource instance
   */
  static fromNative(nativeInstance: maplibre.GeoJsonSource): GeoJsonSource {
    return new GeoJsonSource(InternalMarker.INSTANCE, nativeInstance);
  }

  // ==================== Basic accessors ====================

  /**
   * Get the underlying native instance
   * @returns Native GeoJsonSource
   */
  getNative(): maplibre.GeoJsonSource {
    return this.nativeInstance;
  }

  /**
   * Get the source identifier
   * @returns Source ID
   */
  getId(): string {
    return this.nativeInstance.getId();
  }

  // ==================== Data update APIs ====================

  /**
   * Set GeoJSON data asynchronously
   *
   * Supported formats:
   * - GeoJSON string
   * - Feature object
   * - FeatureCollection object
   * - Geometry object (Point, LineString, Polygon, etc.)
   *
   * @param data GeoJSON payload
   *
   * @example
  * ```typescript
   * // Load from a string
   * source.setGeoJson('{"type":"FeatureCollection","features":[...]}');
   *
   * // Load from a Feature
   * const feature = new Feature({
   *   geometry: new Point(116.4, 39.9),
   *   properties: { name: 'Beijing' }
   * });
   * source.setGeoJson(feature);
   *
   * // Load from a FeatureCollection
   * const collection = new FeatureCollection({ features: [feature1, feature2] });
   * source.setGeoJson(collection);
   * ```
   */
  setGeoJson(data: GeoJsonData): GeoJsonSource {
    if (typeof data === 'string') {
      // Strings use the async path
      this.nativeInstance.setGeoJson(data);
    } else {
      // Objects can be passed directly; NAPI performs conversion
      this.nativeInstance.setGeoJsonSync(data);
    }
    return this;
  }

  /**
   * Set GeoJSON data synchronously
   *
   * Updates the dataset immediately so queries reflect the new content.
   * Accepts the same formats as `setGeoJson`.
   *
   * @param data GeoJSON payload
   *
   * @example
  * ```typescript
   * // Synchronous update—takes effect immediately
   * source.setGeoJsonSync(featureCollection);
   * // The data becomes queryable instantly
   * const features = source.querySourceFeatures();
   * ```
   */
  setGeoJsonSync(data: GeoJsonData): GeoJsonSource {
    if (typeof data === 'string') {
      // Strings can also use the synchronous path
      this.nativeInstance.setGeoJsonSync(data);
    } else {
      // Objects pass through directly
      this.nativeInstance.setGeoJsonSync(data);
    }
    return this;
  }

  /**
   * Load GeoJSON from a URL
   *
   * Supported protocols:
   * - http:// / https:// for remote resources
   * - file:// for local files
   * - resource:// for application assets
   *
   * @param url GeoJSON URL
   *
   * @example
  * ```typescript
   * source.setUrl('https://example.com/data.geojson');
   * source.setUrl('resource://rawfile/data.geojson');
   * ```
   */
  setUrl(url: string): GeoJsonSource {
    this.nativeInstance.setUrl(url);
    return this;
  }

  /**
   * Configure maximum zoom level for tile generation
   * @param maxZoom maximum zoom level
   */
  setMaxZoom(maxZoom: number): GeoJsonSource {
    this.nativeInstance.setMaxZoom(maxZoom);
    return this;
  }

  /**
   * Configure tile buffer size in pixels
   * @param buffer tile buffer size
   */
  setBuffer(buffer: number): GeoJsonSource {
    this.nativeInstance.setBuffer(buffer);
    return this;
  }

  /**
   * Configure geometry simplification tolerance
   * @param tolerance simplification tolerance
   */
  setTolerance(tolerance: number): GeoJsonSource {
    this.nativeInstance.setTolerance(tolerance);
    return this;
  }

  /**
   * Enable or disable line metrics generation
   * @param lineMetrics whether line metrics should be generated
   */
  setLineMetrics(lineMetrics: boolean): GeoJsonSource {
    this.nativeInstance.setLineMetrics(lineMetrics);
    return this;
  }

  /**
   * Enable or disable clustering for the source
   * @param cluster whether clustering should be enabled
   */
  setCluster(cluster: boolean): GeoJsonSource {
    this.nativeInstance.setCluster(cluster);
    return this;
  }

  /**
   * Configure cluster radius in pixels
   * @param clusterRadius cluster radius size
   */
  setClusterRadius(clusterRadius: number): GeoJsonSource {
    this.nativeInstance.setClusterRadius(clusterRadius);
    return this;
  }

  /**
   * Configure maximum zoom level for clustering
   * @param clusterMaxZoom maximum cluster zoom level
   */
  setClusterMaxZoom(clusterMaxZoom: number): GeoJsonSource {
    this.nativeInstance.setClusterMaxZoom(clusterMaxZoom);
    return this;
  }

  /**
   * Configure minimum number of points to form a cluster
   * @param clusterMinPoints minimum points required for clustering
   */
  setClusterMinPoints(clusterMinPoints: number): GeoJsonSource {
    this.nativeInstance.setClusterMinPoints(clusterMinPoints);
    return this;
  }

  /**
   * Get the source URL
   * @returns Source URL or an empty string if unset
   */
  getUrl(): string {
    return this.nativeInstance.getUrl();
  }

  // ==================== Query helpers ====================

  /**
   * Query features from the source
   *
   * @param filter Optional expression filter
   * @returns Array of IFeature instances
   *
   * @example
  * ```typescript
   * // Query all features
   * const allFeatures = source.querySourceFeatures();
   *
   * // Query with a filter
   * const filtered = source.querySourceFeatures(
   *   Expression.eq(Expression.get('type'), 'restaurant')
   * );
   * ```
   */
  querySourceFeatures(filter?: Expression): IFeature[] {
    // Native returns an array of raw Feature objects; perform double casting
    const filterArray = filter ? filter.toArray() : undefined;
    return this.nativeInstance.querySourceFeatures(filterArray as Object as ExpressionLiteral) as Object as IFeature[];
  }

  // ==================== Clustering utilities ====================

  /**
   * Retrieve direct children of a cluster
   *
   * Returns the immediate child features that form the specified cluster (points or sub-clusters).
   *
   * @param clusterId Cluster identifier (from the `cluster_id` property)
   * @returns Array of child features
   *
   * @example
  * ```typescript
   * // Obtain cluster_id from a cluster Feature
   * const clusterId = clusterFeature.getProperties()['cluster_id'];
   * const children = source.getClusterChildren(clusterId);
   * ```
   */
  getClusterChildren(clusterId: number): IFeature[] {
    // Native returns raw Feature objects; perform double casting
    return this.nativeInstance.getClusterChildren(clusterId) as Object as IFeature[];
  }

  /**
   * Retrieve all leaves for a cluster
   *
   * Returns the original point features composing the cluster (non-cluster leaves).
   * Supports pagination to handle large clusters.
   *
   * @param clusterId Cluster identifier
   * @param limit Maximum number of features to return (default 10)
   * @param offset Offset for pagination (default 0)
   * @returns Array of leaf features
   *
   * @example
  * ```typescript
   * // Fetch the first 10 leaves
   * const leaves = source.getClusterLeaves(clusterId);
   *
   * // Paginate through leaves
   * const page1 = source.getClusterLeaves(clusterId, 20, 0);
   * const page2 = source.getClusterLeaves(clusterId, 20, 20);
   * ```
   */
  getClusterLeaves(clusterId: number, limit: number = 10, offset: number = 0): IFeature[] {
    // Native returns raw Feature objects; perform double casting
    return this.nativeInstance.getClusterLeaves(clusterId, limit, offset) as Object as IFeature[];
  }

  /**
   * Get the expansion zoom level for a cluster
   *
   * Returns the minimum zoom level required to expand the specified cluster.
   * Useful for implementing "zoom to cluster" interactions.
   *
   * @param clusterId Cluster identifier
   * @returns Target zoom level
   *
   * @example
  * ```typescript
   * // Zoom to the expansion level when a cluster is tapped
   * const clusterId = feature.getProperties()['cluster_id'];
   * const zoomLevel = source.getClusterExpansionZoom(clusterId);
   * map.easeTo({ zoom: zoomLevel, center: feature.getGeometry().getCoordinates() });
   * ```
   */
  getClusterExpansionZoom(clusterId: number): number {
    return this.nativeInstance.getClusterExpansionZoom(clusterId);
  }
}
