import type { ExpressionLiteral } from '../expressions/ExpressionTypes';

/**
 * Cluster property configuration
 * Format: { "propertyName": [operatorExpression, mapExpression] }
 */
export type ClusterProperties = Record<string, [ExpressionLiteral | string, ExpressionLiteral]>;

/**
 * GeoJsonOptions - Configuration for GeoJSON sources
 */
export interface GeoJsonOptions {
  // Minimum zoom level
  minzoom?: number;

  // Maximum zoom level
  maxzoom?: number;

  // Simplification tolerance (Douglas-Peucker)
  tolerance?: number;

  // Tile buffer size
  buffer?: number;

  // Enable clustering
  cluster?: boolean;

  // Cluster radius in pixels
  clusterRadius?: number;

  // Maximum zoom level for clustering
  clusterMaxZoom?: number;

  // Minimum number of points required for clustering
  clusterMinPoints?: number;

  // Cluster property aggregation definitions
  clusterProperties?: ClusterProperties;

  // Automatically generate feature IDs
  generateId?: boolean;

  // Enable line distance metrics
  lineMetrics?: boolean;

  // Promote ID property
  promoteId?: string;
}

/**
 * Builder for GeoJsonOptions
 */
export class GeoJsonOptionsBuilder {
  private options: GeoJsonOptions = {};

  public withMinZoom(minzoom: number): GeoJsonOptionsBuilder {
    this.options.minzoom = minzoom;
    return this;
  }

  public withMaxZoom(maxzoom: number): GeoJsonOptionsBuilder {
    this.options.maxzoom = maxzoom;
    return this;
  }

  public withTolerance(tolerance: number): GeoJsonOptionsBuilder {
    this.options.tolerance = tolerance;
    return this;
  }

  public withBuffer(buffer: number): GeoJsonOptionsBuilder {
    this.options.buffer = buffer;
    return this;
  }

  public withCluster(cluster: boolean): GeoJsonOptionsBuilder {
    this.options.cluster = cluster;
    return this;
  }

  public withClusterRadius(clusterRadius: number): GeoJsonOptionsBuilder {
    this.options.clusterRadius = clusterRadius;
    return this;
  }

  public withClusterMaxZoom(clusterMaxZoom: number): GeoJsonOptionsBuilder {
    this.options.clusterMaxZoom = clusterMaxZoom;
    return this;
  }

  public withClusterMinPoints(clusterMinPoints: number): GeoJsonOptionsBuilder {
    this.options.clusterMinPoints = clusterMinPoints;
    return this;
  }

  public withClusterProperties(clusterProperties: ClusterProperties): GeoJsonOptionsBuilder {
    this.options.clusterProperties = clusterProperties;
    return this;
  }

  public withGenerateId(generateId: boolean): GeoJsonOptionsBuilder {
    this.options.generateId = generateId;
    return this;
  }

  public withLineMetrics(lineMetrics: boolean): GeoJsonOptionsBuilder {
    this.options.lineMetrics = lineMetrics;
    return this;
  }

  public withPromoteId(promoteId: string): GeoJsonOptionsBuilder {
    this.options.promoteId = promoteId;
    return this;
  }

  public build(): GeoJsonOptions {
    return this.options;
  }
}

