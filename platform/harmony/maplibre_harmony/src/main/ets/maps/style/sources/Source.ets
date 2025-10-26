/**
 * SourceData - 数据源数据类型
 */
export type SourceData = Object | string | null;

/**
 * SourceMetadata - 数据源元数据类型
 */
export type SourceMetadata = Record<string, Object> | null;

/**
 * ClusterProperties - 聚合属性类型
 */
export type ClusterProperties = Record<string, Object> | null;

/**
 * SourceOptions - 数据源选项接口
 */
export interface SourceOptions {
  id: string;
  type: string;
  data?: SourceData;
  minZoom?: number;
  maxZoom?: number;
  attribution?: string;
  bounds?: number[];
  cluster?: boolean;
  clusterMaxZoom?: number;
  clusterRadius?: number;
  clusterMinPoints?: number;
  clusterProperties?: ClusterProperties;
  generateId?: boolean;
  promoteId?: string;
  tolerance?: number;
  buffer?: number;
  lineMetrics?: boolean;
  maxzoom?: number;
  tileSize?: number;
  url?: string;
  tiles?: string[];
  scheme?: string;
  metadata?: SourceMetadata;
}

/**
 * Source - 数据源基类
 */
export abstract class Source {
  public id: string;
  public type: string;
  public data: SourceData;
  public minZoom: number | null;
  public maxZoom: number | null;
  public attribution: string | null;
  public bounds: number[] | null;
  public cluster: boolean;
  public clusterMaxZoom: number | null;
  public clusterRadius: number | null;
  public clusterMinPoints: number | null;
  public clusterProperties: ClusterProperties;
  public generateId: boolean;
  public promoteId: string | null;
  public tolerance: number | null;
  public buffer: number | null;
  public lineMetrics: boolean;
  public maxzoom: number | null;
  public tileSize: number | null;
  public url: string | null;
  public tiles: string[] | null;
  public scheme: string | null;
  public metadata: SourceMetadata;

  constructor(options: SourceOptions) {
    this.id = options.id;
    this.type = options.type;
    this.data = options.data || null;
    this.minZoom = options.minZoom || null;
    this.maxZoom = options.maxZoom || null;
    this.attribution = options.attribution || null;
    this.bounds = options.bounds || null;
    this.cluster = options.cluster || false;
    this.clusterMaxZoom = options.clusterMaxZoom || null;
    this.clusterRadius = options.clusterRadius || null;
    this.clusterMinPoints = options.clusterMinPoints || null;
    this.clusterProperties = options.clusterProperties || null;
    this.generateId = options.generateId || false;
    this.promoteId = options.promoteId || null;
    this.tolerance = options.tolerance || null;
    this.buffer = options.buffer || null;
    this.lineMetrics = options.lineMetrics || false;
    this.maxzoom = options.maxzoom || null;
    this.tileSize = options.tileSize || null;
    this.url = options.url || null;
    this.tiles = options.tiles || null;
    this.scheme = options.scheme || null;
    this.metadata = options.metadata || null;
  }

  /**
   * 获取数据源ID
   */
  public getId(): string {
    return this.id;
  }

  /**
   * 获取数据源类型
   */
  public getType(): string {
    return this.type;
  }

  /**
   * 获取数据
   */
  public getData(): SourceData {
    return this.data;
  }

  /**
   * 设置数据
   */
  public setData(data: SourceData): void {
    this.data = data;
  }

  /**
   * 获取最小缩放级别
   */
  public getMinZoom(): number | null {
    return this.minZoom;
  }

  /**
   * 设置最小缩放级别
   */
  public setMinZoom(minZoom: number | null): void {
    this.minZoom = minZoom;
  }

  /**
   * 获取最大缩放级别
   */
  public getMaxZoom(): number | null {
    return this.maxZoom;
  }

  /**
   * 设置最大缩放级别
   */
  public setMaxZoom(maxZoom: number | null): void {
    this.maxZoom = maxZoom;
  }

  /**
   * 获取属性
   */
  public getAttribution(): string | null {
    return this.attribution;
  }

  /**
   * 设置属性
   */
  public setAttribution(attribution: string | null): void {
    this.attribution = attribution;
  }

  /**
   * 获取边界
   */
  public getBounds(): number[] | null {
    return this.bounds;
  }

  /**
   * 设置边界
   */
  public setBounds(bounds: number[] | null): void {
    this.bounds = bounds;
  }

  /**
   * 是否启用聚类
   */
  public isCluster(): boolean {
    return this.cluster;
  }

  /**
   * 设置聚类
   */
  public setCluster(cluster: boolean): void {
    this.cluster = cluster;
  }

  /**
   * 获取聚类最大缩放级别
   */
  public getClusterMaxZoom(): number | null {
    return this.clusterMaxZoom;
  }

  /**
   * 设置聚类最大缩放级别
   */
  public setClusterMaxZoom(clusterMaxZoom: number | null): void {
    this.clusterMaxZoom = clusterMaxZoom;
  }

  /**
   * 获取聚类半径
   */
  public getClusterRadius(): number | null {
    return this.clusterRadius;
  }

  /**
   * 设置聚类半径
   */
  public setClusterRadius(clusterRadius: number | null): void {
    this.clusterRadius = clusterRadius;
  }

  /**
   * 获取聚类最小点数
   */
  public getClusterMinPoints(): number | null {
    return this.clusterMinPoints;
  }

  /**
   * 设置聚类最小点数
   */
  public setClusterMinPoints(clusterMinPoints: number | null): void {
    this.clusterMinPoints = clusterMinPoints;
  }

  /**
   * 获取聚类属性
   */
  public getClusterProperties(): ClusterProperties {
    return this.clusterProperties;
  }

  /**
   * 设置聚类属性
   */
  public setClusterProperties(clusterProperties: ClusterProperties): void {
    this.clusterProperties = clusterProperties;
  }

  /**
   * 是否生成ID
   */
  public isGenerateId(): boolean {
    return this.generateId;
  }

  /**
   * 设置生成ID
   */
  public setGenerateId(generateId: boolean): void {
    this.generateId = generateId;
  }

  /**
   * 获取提升ID
   */
  public getPromoteId(): string | null {
    return this.promoteId;
  }

  /**
   * 设置提升ID
   */
  public setPromoteId(promoteId: string | null): void {
    this.promoteId = promoteId;
  }

  /**
   * 获取容差
   */
  public getTolerance(): number | null {
    return this.tolerance;
  }

  /**
   * 设置容差
   */
  public setTolerance(tolerance: number | null): void {
    this.tolerance = tolerance;
  }

  /**
   * 获取缓冲区
   */
  public getBuffer(): number | null {
    return this.buffer;
  }

  /**
   * 设置缓冲区
   */
  public setBuffer(buffer: number | null): void {
    this.buffer = buffer;
  }

  /**
   * 是否启用线度量
   */
  public isLineMetrics(): boolean {
    return this.lineMetrics;
  }

  /**
   * 设置线度量
   */
  public setLineMetrics(lineMetrics: boolean): void {
    this.lineMetrics = lineMetrics;
  }

  /**
   * 获取最大缩放级别
   */
  public getMaxzoom(): number | null {
    return this.maxzoom;
  }

  /**
   * 设置最大缩放级别
   */
  public setMaxzoom(maxzoom: number | null): void {
    this.maxzoom = maxzoom;
  }

  /**
   * 获取瓦片大小
   */
  public getTileSize(): number | null {
    return this.tileSize;
  }

  /**
   * 设置瓦片大小
   */
  public setTileSize(tileSize: number | null): void {
    this.tileSize = tileSize;
  }

  /**
   * 获取URL
   */
  public getUrl(): string | null {
    return this.url;
  }

  /**
   * 设置URL
   */
  public setUrl(url: string | null): void {
    this.url = url;
  }

  /**
   * 获取瓦片列表
   */
  public getTiles(): string[] | null {
    return this.tiles;
  }

  /**
   * 设置瓦片列表
   */
  public setTiles(tiles: string[] | null): void {
    this.tiles = tiles;
  }

  /**
   * 获取方案
   */
  public getScheme(): string | null {
    return this.scheme;
  }

  /**
   * 设置方案
   */
  public setScheme(scheme: string | null): void {
    this.scheme = scheme;
  }

  /**
   * 获取元数据
   */
  public getMetadata(): SourceMetadata {
    return this.metadata;
  }

  /**
   * 设置元数据
   */
  public setMetadata(metadata: SourceMetadata): void {
    this.metadata = metadata;
  }


  /**
   * 转换为JSON
   */
  public toJSON(): ESObject {
    return {
      id: this.id,
      type: this.type,
      data: this.data,
      minZoom: this.minZoom,
      maxZoom: this.maxZoom,
      attribution: this.attribution,
      bounds: this.bounds,
      cluster: this.cluster,
      clusterMaxZoom: this.clusterMaxZoom,
      clusterRadius: this.clusterRadius,
      clusterMinPoints: this.clusterMinPoints,
      clusterProperties: this.clusterProperties,
      generateId: this.generateId,
      promoteId: this.promoteId,
      tolerance: this.tolerance,
      buffer: this.buffer,
      lineMetrics: this.lineMetrics,
      maxzoom: this.maxzoom,
      tileSize: this.tileSize,
      url: this.url,
      tiles: this.tiles,
      scheme: this.scheme,
      metadata: this.metadata
    };
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return `Source(id=${this.id}, type=${this.type})`;
  }
}
