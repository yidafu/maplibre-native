/**
 * GeoJsonSource - GeoJSON 数据源封装类
 *
 * 提供完整的 GeoJSON 数据源功能，包括：
 * - 多种数据格式支持（字符串、Feature、FeatureCollection、Geometry）
 * - 异步和同步数据更新
 * - 数据源查询
 * - 聚类功能
 */
import maplibre from 'libmaplibre.so';
import { Geometry, IFeature, IFeatureCollection } from '../../geojson';
import { GeoJsonOptions } from './GeoJsonOptions';
import type { Expression } from '../../style/expressions/Expression';
/**
 * 内部标记类，用于识别 fromNative 工厂方法
 */
class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

/**
 * GeoJSON 数据类型
 * 支持字符串、GeoJSON 对象和原生 NAPI 对象
 */
export type GeoJsonData = string | IFeature | IFeatureCollection | Geometry | Object;

/**
 * GeoJsonSource 类
 */
export class GeoJsonSource {
  // 类型标识，用于类型判断（因为 instanceof 在 NAPI 返回的对象上不工作）
  static readonly _TYPE_ = 'GeoJsonSource';
  private nativeInstance: maplibre.GeoJsonSource;

  /**
   * 构造函数（私有，使用静态工厂方法创建实例）
   * @param idOrMarker 数据源 ID 或内部标记
   * @param optionsOrNative 选项对象或原生实例
   */
  constructor(idOrMarker: string | InternalMarker, optionsOrNative?: GeoJsonOptions | maplibre.GeoJsonSource) {
    if (idOrMarker === InternalMarker.INSTANCE && optionsOrNative instanceof Object) {
      // 从原生实例创建
      this.nativeInstance = optionsOrNative as maplibre.GeoJsonSource;
    } else if (typeof idOrMarker === 'string') {
      // 正常构造
      this.nativeInstance = new maplibre.GeoJsonSource(idOrMarker, optionsOrNative as GeoJsonOptions);
    } else {
      throw new Error('Invalid GeoJsonSource constructor arguments');
    }
  }

  // ==================== 静态工厂方法 ====================

  /**
   * 创建空的 GeoJsonSource
   * @param id 数据源 ID
   * @param options 可选配置
   * @returns GeoJsonSource 实例
   */
  static create(id: string, options?: GeoJsonOptions): GeoJsonSource {
    return new GeoJsonSource(id, options);
  }

  /**
   * 从 GeoJSON 字符串创建
   * @param id 数据源 ID
   * @param geojson GeoJSON 字符串
   * @param options 可选配置
   * @returns GeoJsonSource 实例
   */
  static fromGeoJson(id: string, geojson: string, options?: GeoJsonOptions): GeoJsonSource {
    const source = new GeoJsonSource(id, options);
    source.setGeoJson(geojson);
    return source;
  }

  /**
   * 从 Feature 创建
   * @param id 数据源 ID
   * @param feature Feature 对象
   * @param options 可选配置
   * @returns GeoJsonSource 实例
   */
  static fromFeature(id: string, feature: IFeature, options?: GeoJsonOptions): GeoJsonSource {
    const source = new GeoJsonSource(id, options);
    source.setGeoJson(feature);
    return source;
  }

  /**
   * 从 FeatureCollection 创建
   * @param id 数据源 ID
   * @param featureCollection FeatureCollection 对象
   * @param options 可选配置
   * @returns GeoJsonSource 实例
   */
  static fromFeatureCollection(id: string, featureCollection: IFeatureCollection,
    options?: GeoJsonOptions): GeoJsonSource {
    const source = new GeoJsonSource(id, options);
    source.setGeoJson(featureCollection);
    return source;
  }

  /**
   * 从 Geometry 创建
   * @param id 数据源 ID
   * @param geometry Geometry 对象
   * @param options 可选配置
   * @returns GeoJsonSource 实例
   */
  static fromGeometry(id: string, geometry: Geometry, options?: GeoJsonOptions): GeoJsonSource {
    const source = new GeoJsonSource(id, options);
    source.setGeoJson(geometry);
    return source;
  }

  /**
   * 从 URL 创建
   * @param id 数据源 ID
   * @param url GeoJSON 数据 URL
   * @param options 可选配置
   * @returns GeoJsonSource 实例
   */
  static fromUrl(id: string, url: string, options?: GeoJsonOptions): GeoJsonSource {
    const source = new GeoJsonSource(id, options);
    source.setUrl(url);
    return source;
  }

  /**
   * 从原生实例创建（内部使用）
   * @param nativeInstance 原生 GeoJsonSource 实例
   * @returns GeoJsonSource 实例
   */
  static fromNative(nativeInstance: maplibre.GeoJsonSource): GeoJsonSource {
    return new GeoJsonSource(InternalMarker.INSTANCE, nativeInstance);
  }

  // ==================== 基础方法 ====================

  /**
   * 获取原生实例
   * @returns 原生 GeoJsonSource 实例
   */
  getNative(): maplibre.GeoJsonSource {
    return this.nativeInstance;
  }

  /**
   * 获取数据源 ID
   * @returns 数据源 ID
   */
  getId(): string {
    return this.nativeInstance.getId();
  }

  // ==================== 数据更新方法 ====================

  /**
   * 设置 GeoJSON 数据（异步）
   *
   * 支持多种数据格式：
   * - GeoJSON 字符串
   * - Feature 对象
   * - FeatureCollection 对象
   * - Geometry 对象（Point, LineString, Polygon 等）
   *
   * @param data GeoJSON 数据
   *
   * @example
  * ```typescript
   * // 从字符串加载
   * source.setGeoJson('{"type":"FeatureCollection","features":[...]}');
   *
   * // 从 Feature 对象加载
   * const feature = new Feature({
   *   geometry: new Point(116.4, 39.9),
   *   properties: { name: 'Beijing' }
   * });
   * source.setGeoJson(feature);
   *
   * // 从 FeatureCollection 加载
   * const collection = new FeatureCollection({ features: [feature1, feature2] });
   * source.setGeoJson(collection);
   * ```
   */
  setGeoJson(data: GeoJsonData): GeoJsonSource {
    if (typeof data === 'string') {
      // 字符串类型，使用异步方法
      this.nativeInstance.setGeoJson(data);
    } else {
      // 对象类型，使用同步方法（NAPI 层会处理类型转换）
      this.nativeInstance.setGeoJsonSync(data);
    }
    return this;
  }

  /**
   * 设置 GeoJSON 数据（同步）
   *
   * 同步更新数据，数据会立即可见和可查询。
   * 支持与 setGeoJson 相同的数据格式。
   *
   * @param data GeoJSON 数据
   *
   * @example
  * ```typescript
   * // 同步更新，立即生效
   * source.setGeoJsonSync(featureCollection);
   * // 数据立即可查询
   * const features = source.querySourceFeatures();
   * ```
   */
  setGeoJsonSync(data: GeoJsonData): GeoJsonSource {
    if (typeof data === 'string') {
      // 字符串类型也使用同步方法
      this.nativeInstance.setGeoJsonSync(data);
    } else {
      // 对象类型
      this.nativeInstance.setGeoJsonSync(data);
    }
    return this;
  }

  /**
   * 从 URL 加载 GeoJSON 数据
   *
   * 支持的 URL 协议：
   * - http:// / https:// - 网络资源
   * - file:// - 本地文件
   * - resource:// - 应用资源
   *
   * @param url GeoJSON 数据 URL
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
   * 获取数据源 URL
   * @returns 数据源 URL，如果没有设置则返回空字符串
   */
  getUrl(): string {
    return this.nativeInstance.getUrl();
  }

  // ==================== 查询功能 ====================

  /**
   * 查询数据源中的要素
   *
   * @param filter 可选的过滤表达式
   * @returns IFeature 数组
   *
   * @example
  * ```typescript
   * // 查询所有要素
   * const allFeatures = source.querySourceFeatures();
   *
   * // 使用过滤器查询
   * const filtered = source.querySourceFeatures(
   *   Expression.eq(Expression.get('type'), 'restaurant')
   * );
   * ```
   */
  querySourceFeatures(filter?: Expression): IFeature[] {
    // NAPI 返回的是原生 Feature 对象数组，需要双重类型转换
    return this.nativeInstance.querySourceFeatures(filter) as Object as IFeature[];
  }

  // ==================== 聚类功能 ====================

  /**
   * 获取聚类的直接子项
   *
   * 返回组成指定聚类的直接子要素（可能是点或子聚类）。
   *
   * @param clusterId 聚类 ID（从 cluster_id 属性获取）
   * @returns 子要素数组
   *
   * @example
  * ```typescript
   * // 从聚类 Feature 获取 cluster_id
   * const clusterId = clusterFeature.getProperties()['cluster_id'];
   * const children = source.getClusterChildren(clusterId);
   * ```
   */
  getClusterChildren(clusterId: number): IFeature[] {
    // NAPI 返回的是原生 Feature 对象数组，需要双重类型转换
    return this.nativeInstance.getClusterChildren(clusterId) as Object as IFeature[];
  }

  /**
   * 获取聚类的所有叶子节点
   *
   * 返回组成指定聚类的所有原始点要素（非聚类的叶子节点）。
   * 支持分页，可以获取大型聚类的部分数据。
   *
   * @param clusterId 聚类 ID
   * @param limit 限制返回的要素数量（默认 10）
   * @param offset 偏移量，用于分页（默认 0）
   * @returns 叶子要素数组
   *
   * @example
  * ```typescript
   * // 获取前 10 个叶子节点
   * const leaves = source.getClusterLeaves(clusterId);
   *
   * // 分页获取
   * const page1 = source.getClusterLeaves(clusterId, 20, 0);
   * const page2 = source.getClusterLeaves(clusterId, 20, 20);
   * ```
   */
  getClusterLeaves(clusterId: number, limit: number = 10, offset: number = 0): IFeature[] {
    // NAPI 返回的是原生 Feature 对象数组，需要双重类型转换
    return this.nativeInstance.getClusterLeaves(clusterId, limit, offset) as Object as IFeature[];
  }

  /**
   * 获取聚类展开的缩放级别
   *
   * 返回能够完全展开指定聚类的最小缩放级别。
   * 可用于实现"缩放到聚类"功能。
   *
   * @param clusterId 聚类 ID
   * @returns 目标缩放级别
   *
   * @example
  * ```typescript
   * // 点击聚类时缩放到展开级别
   * const clusterId = feature.getProperties()['cluster_id'];
   * const zoomLevel = source.getClusterExpansionZoom(clusterId);
   * map.easeTo({ zoom: zoomLevel, center: feature.getGeometry().getCoordinates() });
   * ```
   */
  getClusterExpansionZoom(clusterId: number): number {
    return this.nativeInstance.getClusterExpansionZoom(clusterId);
  }
}
