import { Image } from '../images/Image';

/**
 * ImageSource 选项接口
 */
export interface ImageSourceOptions {
  /** 图像 URL */
  url?: string;

  /** 图像四个角的坐标 [[lon, lat], [lon, lat], [lon, lat], [lon, lat]] */
  coordinates?: number[][];
}

/**
 * ImageSource - 图像数据源
 *
 * 用于在指定的地理坐标范围内显示单张图像
 */
export class ImageSource {
  /**
   * 类型标识，用于 ETS 层的类型判断
   */
  _TYPE_?: string;

  /**
   * 构造图像数据源
   * @param id 数据源 ID
   * @param options 可选配置（包含 url 和/或 coordinates）
   */
  constructor(id: string, options?: ImageSourceOptions);

  /**
   * 获取数据源 ID
   */
  getId(): string;

  /**
   * 获取原生指针（内部使用）
   */

  /**
   * 设置图像 URL
   * @param url 图像 URL
   * @returns this（支持链式调用）
   */
  setUrl(url: string): this;

  /**
   * 设置图像对象
   * @param image 图像对象
   * @returns this（支持链式调用）
   */
  setImage(image: Image): this;

  /**
   * 设置图像四个角的坐标
   * @param coordinates 四个角的坐标数组 [[lon, lat], [lon, lat], [lon, lat], [lon, lat]]
   * @returns this（支持链式调用）
   */
  setCoordinates(coordinates: number[][]): this;
}
