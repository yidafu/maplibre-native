import type { ExpressionLiteral } from '../expressions/ExpressionTypes';

/**
 * 聚类属性类型
 * 格式：{ "propertyName": [operatorExpression, mapExpression] }
 */
export type ClusterProperties = Record<string, [ExpressionLiteral | string, ExpressionLiteral]>;

/**
 * GeoJsonOptions - GeoJSON数据源选项配置
 */
export interface GeoJsonOptions {
  // 最大缩放级别
  maxzoom?: number;

  // 简化容差（Douglas-Peucker算法）
  tolerance?: number;

  // 瓦片缓冲区大小
  buffer?: number;

  // 是否启用聚类
  cluster?: boolean;

  // 聚类半径（像素）
  clusterRadius?: number;

  // 聚类的最大缩放级别
  clusterMaxZoom?: number;

  // 聚类最小点数
  clusterMinPoints?: number;

  // 聚类属性
  clusterProperties?: ClusterProperties;

  // 是否为每个要素生成ID
  generateId?: boolean;

  // 是否启用线条距离度量
  lineMetrics?: boolean;

  // 提升ID属性
  promoteId?: string;
}

/**
 * GeoJsonOptions 构建器类
 */
export class GeoJsonOptionsBuilder {
  private options: GeoJsonOptions = {};

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

