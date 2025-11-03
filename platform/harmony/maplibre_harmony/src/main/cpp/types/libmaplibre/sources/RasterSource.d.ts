/**
 * 栅格瓦片数据源选项
 */
export interface RasterSourceOptions {
  /** 瓦片 URL */
  url?: string;

  /** 瓦片 URL 列表 */
  tiles?: string[];

  /** 最小缩放级别 */
  minzoom?: number;

  /** 最大缩放级别 */
  maxzoom?: number;

  /** 瓦片大小 */
  tileSize?: number;

  /** 瓦片坐标系统 */
  scheme?: 'xyz' | 'tms';
}

/**
 * RasterSource - 栅格瓦片数据源
 *
 * 用于加载栅格瓦片图像
 */
export class RasterSource {
  /**
   * 类型标识，用于 ETS 层的类型判断
   */
  _TYPE_?: string;

  /**
   * 构造栅格瓦片数据源
   * @param id 数据源 ID
   * @param options 可选配置
   */
  constructor(id: string, options?: RasterSourceOptions);

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
   * 设置瓦片大小
   * @param tileSize 瓦片大小（像素）
   * @returns this（支持链式调用）
   */
  setTileSize(tileSize: number): this;
}
