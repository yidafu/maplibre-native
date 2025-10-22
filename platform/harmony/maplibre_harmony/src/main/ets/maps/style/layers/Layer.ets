/**
 * LayerFilter - 图层过滤器类型
 */
export type LayerFilter = Object | null;

/**
 * LayerLayout - 图层布局属性类型
 */
export type LayerLayout = Record<string, Object>;

/**
 * LayerPaint - 图层绘制属性类型
 */
export type LayerPaint = Record<string, Object>;

/**
 * LayerMetadata - 图层元数据类型
 */
export type LayerMetadata = Record<string, Object> | null;

/**
 * LayerOptions - 图层选项接口
 */
export interface LayerOptions {
  id: string;
  type: string;
  source: string;
  sourceLayer?: string;
  minZoom?: number;
  maxZoom?: number;
  filter?: LayerFilter;
  layout?: LayerLayout;
  paint?: LayerPaint;
  metadata?: LayerMetadata;
}

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
  public filter: LayerFilter;
  public layout: LayerLayout;
  public paint: LayerPaint;
  public metadata: LayerMetadata;

  constructor(options: LayerOptions) {
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
  public getFilter(): LayerFilter {
    return this.filter;
  }

  /**
   * 设置过滤器
   */
  public setFilter(filter: LayerFilter): void {
    this.filter = filter;
  }

  /**
   * 获取布局属性
   */
  public getLayout(): LayerLayout {
    return this.layout;
  }

  /**
   * 设置布局属性
   */
  public setLayout(layout: LayerLayout): void {
    this.layout = layout;
  }

  /**
   * 获取绘制属性
   */
  public getPaint(): LayerPaint {
    return this.paint;
  }

  /**
   * 设置绘制属性
   */
  public setPaint(paint: LayerPaint): void {
    this.paint = paint;
  }

  /**
   * 获取元数据
   */
  public getMetadata(): LayerMetadata {
    return this.metadata;
  }

  /**
   * 设置元数据
   */
  public setMetadata(metadata: LayerMetadata): void {
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
  public toJSON(): ESObject {
    const obj: ESObject = {};
    obj['id'] = this.id;
    obj['type'] = this.type;
    obj['source'] = this.source;
    obj['sourceLayer'] = this.sourceLayer;
    obj['minZoom'] = this.minZoom;
    obj['maxZoom'] = this.maxZoom;
    obj['filter'] = this.filter;
    obj['layout'] = this.layout;
    obj['paint'] = this.paint;
    obj['metadata'] = this.metadata;
    return obj;
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return `Layer(id=${this.id}, type=${this.type}, source=${this.source})`;
  }
}
