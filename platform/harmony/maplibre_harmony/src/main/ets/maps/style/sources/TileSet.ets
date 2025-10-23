/**
 * TileSet - 瓦片集配置类
 * 
 * 用于配置矢量瓦片和栅格瓦片数据源
 */
export interface TileSetOptions {
  // 瓦片URL数组，支持{z}/{x}/{y}占位符
  tiles: string[];
  
  // 最小缩放级别
  minzoom?: number;
  
  // 最大缩放级别
  maxzoom?: number;
  
  // 边界范围 [west, south, east, north]
  bounds?: number[];
  
  // 瓦片方案："xyz" 或 "tms"
  scheme?: string;
  
  // 归属信息
  attribution?: string;
  
  // 瓦片大小（像素）
  tileSize?: number;
  
  // TileJSON规范版本
  version?: string;
  
  // 名称
  name?: string;
  
  // 描述
  description?: string;
  
  // 矢量图层信息
  vector_layers?: VectorLayer[];
}

/**
 * VectorLayer - 矢量图层信息
 */
export interface VectorLayer {
  id: string;
  fields?: Record<string, string>;
  description?: string;
  minzoom?: number;
  maxzoom?: number;
}

/**
 * TileSet 类
 */
export class TileSet {
  private options: TileSetOptions;

  constructor(tiles: string[], minzoom?: number, maxzoom?: number) {
    this.options = {
      tiles: tiles,
      minzoom: minzoom,
      maxzoom: maxzoom
    };
  }

  /**
   * 从选项创建TileSet
   */
  public static fromOptions(options: TileSetOptions): TileSet {
    const tileSet = new TileSet(options.tiles, options.minzoom, options.maxzoom);
    tileSet.options = options;
    return tileSet;
  }

  /**
   * 获取瓦片URLs
   */
  public getTiles(): string[] {
    return this.options.tiles;
  }

  /**
   * 设置边界
   */
  public setBounds(bounds: number[]): void {
    this.options.bounds = bounds;
  }

  /**
   * 获取边界
   */
  public getBounds(): number[] | undefined {
    return this.options.bounds;
  }

  /**
   * 设置瓦片方案
   */
  public setScheme(scheme: string): void {
    this.options.scheme = scheme;
  }

  /**
   * 获取瓦片方案
   */
  public getScheme(): string | undefined {
    return this.options.scheme;
  }

  /**
   * 设置归属信息
   */
  public setAttribution(attribution: string): void {
    this.options.attribution = attribution;
  }

  /**
   * 获取归属信息
   */
  public getAttribution(): string | undefined {
    return this.options.attribution;
  }

  /**
   * 设置瓦片大小
   */
  public setTileSize(tileSize: number): void {
    this.options.tileSize = tileSize;
  }

  /**
   * 获取瓦片大小
   */
  public getTileSize(): number | undefined {
    return this.options.tileSize;
  }

  /**
   * 转换为JSON对象
   */
  public toJSON(): TileSetOptions {
    return this.options;
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return `TileSet(tiles=${this.options.tiles.length}, minzoom=${this.options.minzoom}, maxzoom=${this.options.maxzoom})`;
  }
}

