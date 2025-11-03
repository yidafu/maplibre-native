/**
 * ImageOptions - 图片选项接口
 */
export interface ImageOptions {
  /** 图片名称（必需） */
  name: string;

  /** 图片宽度（必需，像素） */
  width: number;

  /** 图片高度（必需，像素） */
  height: number;

  /** RGBA 图片数据（必需，预乘 alpha） */
  data: Uint8Array;

  /** 像素比率（可选，默认 1.0） */
  pixelRatio?: number;

  /** 是否为 SDF（Signed Distance Field）图片（可选，默认 false） */
  sdf?: boolean;

  /**
   * 水平拉伸区域（可选）
   * 格式：[start1, end1, start2, end2, ...]
   * 每对值定义一个可拉伸区域
   */
  stretchX?: number[];

  /**
   * 垂直拉伸区域（可选）
   * 格式：[start1, end1, start2, end2, ...]
   * 每对值定义一个可拉伸区域
   */
  stretchY?: number[];

  /**
   * 内容区域（可选）
   * 格式：[left, top, right, bottom]
   * 定义文本或图标可以放置的区域
   */
  content?: number[];
}

/**
 * Image - 地图样式图片类
 *
 * 用于在地图样式中添加自定义图片，支持：
 * - 基本图片显示
 * - SDF（Signed Distance Field）图片用于动态着色
 * - 可拉伸图片（类似 9-patch）
 * - 内容区域定义
 */
export class Image {
  /**
   * 构造函数
   * @param options - 图片选项
   * @throws 如果参数无效
   */
  constructor(options: ImageOptions);

  /**
   * 获取图片名称
   * @returns 图片名称
   */
  getName(): string;

  /**
   * 获取图片宽度
   * @returns 宽度（像素）
   */
  getWidth(): number;

  /**
   * 获取图片高度
   * @returns 高度（像素）
   */
  getHeight(): number;

  /**
   * 获取像素比率
   * @returns 像素比率
   */
  getPixelRatio(): number;

  /**
   * 检查是否为 SDF 图片
   * @returns true 如果是 SDF 图片
   */
  getSdf(): boolean;

  /**
   * 获取图片数据
   * @returns RGBA 图片数据的副本，如果不可用则返回 null
   */
  getData(): Uint8Array | null;

  /**
   * 获取水平拉伸区域
   * @returns 拉伸区域数组 [start1, end1, start2, end2, ...]，如果未设置则返回 null
   */
  getStretchX(): number[] | null;

  /**
   * 获取垂直拉伸区域
   * @returns 拉伸区域数组 [start1, end1, start2, end2, ...]，如果未设置则返回 null
   */
  getStretchY(): number[] | null;

  /**
   * 获取内容区域
   * @returns 内容区域 [left, top, right, bottom]，如果未设置则返回 null
   */
  getContent(): number[] | null;
}

