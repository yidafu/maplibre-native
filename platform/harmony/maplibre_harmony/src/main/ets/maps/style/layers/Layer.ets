/**
 * Layer - 图层基类
 */
export abstract class Layer {
  public id: string;
  public type: string;
  public source: string;
  public sourceLayer: string | null;
  public minZoom: number | null;
  public maxZoom: number | null;
  public filter: any;
  public layout: any;
  public paint: any;
  public metadata: any;

  constructor(options: {
    id: string;
    type: string;
    source: string;
    sourceLayer?: string;
    minZoom?: number;
    maxZoom?: number;
    filter?: any;
    layout?: any;
    paint?: any;
    metadata?: any;
  }) {
    this.id = options.id;
    this.type = options.type;
    this.source = options.source;
    this.sourceLayer = options.sourceLayer || null;
    this.minZoom = options.minZoom || null;
    this.maxZoom = options.maxZoom || null;
    this.filter = options.filter || null;
    this.layout = options.layout || {};
    this.paint = options.paint || {};
    this.metadata = options.metadata || null;
  }

  /**
   * 获取图层ID
   */
  public getId(): string {
    return this.id;
  }

  /**
   * 获取图层类型
   */
  public getType(): string {
    return this.type;
  }

  /**
   * 获取数据源ID
   */
  public getSource(): string {
    return this.source;
  }

  /**
   * 设置数据源ID
   */
  public setSource(source: string): void {
    this.source = source;
  }

  /**
   * 获取源图层
   */
  public getSourceLayer(): string | null {
    return this.sourceLayer;
  }

  /**
   * 设置源图层
   */
  public setSourceLayer(sourceLayer: string | null): void {
    this.sourceLayer = sourceLayer;
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
   * 获取过滤器
   */
  public getFilter(): any {
    return this.filter;
  }

  /**
   * 设置过滤器
   */
  public setFilter(filter: any): void {
    this.filter = filter;
  }

  /**
   * 获取布局属性
   */
  public getLayout(): any {
    return this.layout;
  }

  /**
   * 设置布局属性
   */
  public setLayout(layout: any): void {
    this.layout = layout;
  }

  /**
   * 获取绘制属性
   */
  public getPaint(): any {
    return this.paint;
  }

  /**
   * 设置绘制属性
   */
  public setPaint(paint: any): void {
    this.paint = paint;
  }

  /**
   * 获取元数据
   */
  public getMetadata(): any {
    return this.metadata;
  }

  /**
   * 设置元数据
   */
  public setMetadata(metadata: any): void {
    this.metadata = metadata;
  }

  /**
   * 获取原生指针（用于NAPI调用）
   */
  public getNativePtr(): number {
    // 这里应该返回实际的C++对象指针
    // 在实际实现中，这应该是一个有效的指针值
    return 0;
  }

  /**
   * 转换为JSON
   */
  public toJSON(): any {
    return {
      id: this.id,
      type: this.type,
      source: this.source,
      sourceLayer: this.sourceLayer,
      minZoom: this.minZoom,
      maxZoom: this.maxZoom,
      filter: this.filter,
      layout: this.layout,
      paint: this.paint,
      metadata: this.metadata
    };
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return `Layer(id=${this.id}, type=${this.type}, source=${this.source})`;
  }
}
