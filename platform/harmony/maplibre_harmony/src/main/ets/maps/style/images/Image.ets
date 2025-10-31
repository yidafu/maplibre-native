import maplibre from 'libmaplibre.so';

/**
 * ImageOptions - 图片选项接口
 */
export interface ImageOptions {
  name: string;
  width: number;
  height: number;
  pixelRatio?: number;
  sdf?: boolean;
  data: Uint8Array;
  stretchX?: number[];
  stretchY?: number[];
  content?: number[];
}

/**
 * ImageSize - 图片尺寸接口
 */
export interface ImageSize {
  width: number;
  height: number;
}

/**
 * InternalMarker - 内部标记类，用于控制实例化
 */
class InternalMarker {
  static readonly INSTANCE = new InternalMarker();
  private constructor() {}
}

/**
 * Image - 图片包装类
 * 
 * 这是一个封装类，包装了 NAPI Image 对象，提供类型安全的接口。
 * 遵循封装原则，不直接暴露 NAPI 对象给最终用户。
 */
export class Image {
  private nativeInstance: maplibre.Image;

  /**
   * 构造函数
   * @param options - 图片选项
   */
  constructor(options: ImageOptions) {
    // 验证必需参数
    if (!options.name || options.name.trim() === '') {
      throw new Error('Image name is required');
    }
    
    if (!options.width || options.width <= 0) {
      throw new Error('Image width must be greater than 0');
    }
    
    if (!options.height || options.height <= 0) {
      throw new Error('Image height must be greater than 0');
    }
    
    if (!options.data) {
      throw new Error('Image data is required');
    }
    
    // 验证数据大小 (RGBA = 4 bytes per pixel)
    const expectedSize = options.width * options.height * 4;
    if (options.data.byteLength !== expectedSize) {
      throw new Error(
        `Image data size mismatch: expected ${expectedSize} bytes, got ${options.data.byteLength} bytes`
      );
    }
    
    // 验证 stretchX（如果提供）
    if (options.stretchX && options.stretchX.length % 2 !== 0) {
      throw new Error('stretchX must contain pairs of values [start, end, ...]');
    }
    
    // 验证 stretchY（如果提供）
    if (options.stretchY && options.stretchY.length % 2 !== 0) {
      throw new Error('stretchY must contain pairs of values [start, end, ...]');
    }
    
    // 验证 content（如果提供）
    if (options.content && options.content.length !== 4) {
      throw new Error('content must contain exactly 4 values [left, top, right, bottom]');
    }
    
    // 创建 native Image 实例
    try {
      this.nativeInstance = new maplibre.Image({
        name: options.name,
        width: options.width,
        height: options.height,
        pixelRatio: options.pixelRatio ?? 1.0,
        sdf: options.sdf ?? false,
        data: options.data,
        stretchX: options.stretchX,
        stretchY: options.stretchY,
        content: options.content
      });
    } catch (error) {
      throw new Error(`Failed to create Image: ${error}`);
    }
  }

  /**
   * 获取 native 实例（供内部使用，如 Style.addImage）
   * @internal
   */
  getNative(): maplibre.Image {
    return this.nativeInstance;
  }

  /**
   * 获取图片名称
   */
  getName(): string {
    return this.nativeInstance.getName();
  }

  /**
   * 获取宽度
   */
  getWidth(): number {
    return this.nativeInstance.getWidth();
  }

  /**
   * 获取高度
   */
  getHeight(): number {
    return this.nativeInstance.getHeight();
  }

  /**
   * 获取像素比
   */
  getPixelRatio(): number {
    return this.nativeInstance.getPixelRatio();
  }

  /**
   * 是否为SDF图片
   */
  isSdf(): boolean {
    return this.nativeInstance.getSdf();
  }

  /**
   * 获取图片数据
   */
  getData(): Uint8Array | null {
    return this.nativeInstance.getData();
  }

  /**
   * 获取水平拉伸区域
   * @returns 拉伸区域数组 [start1, end1, start2, end2, ...] 或 null
   */
  getStretchX(): number[] | null {
    return this.nativeInstance.getStretchX();
  }

  /**
   * 获取垂直拉伸区域
   * @returns 拉伸区域数组 [start1, end1, start2, end2, ...] 或 null
   */
  getStretchY(): number[] | null {
    return this.nativeInstance.getStretchY();
  }

  /**
   * 获取内容区域（用于文本放置）
   * @returns 内容区域 [left, top, right, bottom] 或 null
   */
  getContent(): number[] | null {
    return this.nativeInstance.getContent();
  }

  /**
   * 获取图片尺寸
   */
  getSize(): ImageSize {
    return { 
      width: this.getWidth(), 
      height: this.getHeight() 
    };
  }

  /**
   * 比较两个图片是否相等（基于元数据）
   */
  equals(other: Image): boolean {
    if (!other) {
      return false;
    }
    
    return this.getName() === other.getName() &&
           this.getWidth() === other.getWidth() &&
           this.getHeight() === other.getHeight() &&
           this.getPixelRatio() === other.getPixelRatio() &&
           this.isSdf() === other.isSdf();
  }

  /**
   * 转换为字符串
   */
  toString(): string {
    const sdfStr = this.isSdf() ? ', sdf' : '';
    const stretchXStr = this.getStretchX() ? ', stretchable-x' : '';
    const stretchYStr = this.getStretchY() ? ', stretchable-y' : '';
    const contentStr = this.getContent() ? ', has-content' : '';
    
    return `Image(name=${this.getName()}, ` +
           `size=${this.getWidth()}x${this.getHeight()}, ` +
           `pixelRatio=${this.getPixelRatio()}${sdfStr}${stretchXStr}${stretchYStr}${contentStr})`;
  }
}
