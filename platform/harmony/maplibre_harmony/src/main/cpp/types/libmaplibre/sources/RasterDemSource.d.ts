/**
 * RasterDemSourceOptions - 栅格 DEM 数据源选项
 */
export interface RasterDemSourceOptions {
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

  /** DEM 编码方式 */
  encoding?: 'mapbox' | 'terrarium';
}

/**
 * RasterDemSource - 栅格 DEM 数据源
 *
 * 用于加载数字高程模型数据
 */
export class RasterDemSource {
  /**
   * 类型标识，用于 ETS 层的类型判断
   */
  _TYPE_?: string;

  /**
   * 构造栅格 DEM 数据源
   * @param id 数据源 ID
   * @param options 可选配置
   */
  constructor(id: string, options?: RasterDemSourceOptions);

  /**
   * 获取数据源 ID
   */
  getId(): string;

  /**
   * 获取原生指针（内部使用）
   */

  /**
   * 获取数据 URL
   */
  getUrl(): string;

  /**
   * 设置数据 URL
   * @param url 数据 URL
   * @returns this（支持链式调用）
   */
  setUrl(url: string): this;
}
