/**
 * 矢量瓦片数据源选项
 */
export interface VectorSourceOptions {
  /** 瓦片 URL */
  url?: string;

  /** 瓦片 URL 列表 */
  tiles?: string[];

  /** 最小缩放级别 */
  minzoom?: number;

  /** 最大缩放级别 */
  maxzoom?: number;

  /** 瓦片坐标系统 */
  scheme?: 'xyz' | 'tms';

  /** 边界 [west, south, east, north] */
  bounds?: [number, number, number, number];
}

/**
 * VectorSource - 矢量瓦片数据源
 *
 * 用于加载 Mapbox Vector Tiles (MVT) 格式的数据
 */
export class VectorSource {
  /**
   * 类型标识，用于 ETS 层的类型判断
   */
  _TYPE_?: string;

  /**
   * 构造矢量瓦片数据源
   * @param id 数据源 ID
   * @param options 可选配置
   */
  constructor(id: string, options?: VectorSourceOptions);

  /**
   * 获取数据源 ID
   */
  getId(): string;

  /**
   * 获取原生指针（内部使用）
   */

  /**
   * 获取瓦片 URL
   */
  getUrl(): string;

  /**
   * 设置瓦片 URL
   * @param url 瓦片 URL
   * @returns this（支持链式调用）
   */
  setUrl(url: string): this;

  /**
   * 设置瓦片 URL 列表
   * @param tiles 瓦片 URL 数组
   * @returns this（支持链式调用）
   */
  setTiles(tiles: string[]): this;
}
