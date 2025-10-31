/**
 * Icon - 图标封装类
 * 
 * 符合 ArkTS 规范的封装实现
 */
import maplibre from 'libmaplibre.so';
import image from '@ohos.multimedia.image';

/**
 * 内部创建标记
 */
class InternalMarker {
  static readonly INSTANCE = new InternalMarker();
  private constructor() {}
}

/**
 * Icon 封装类
 */
export class Icon {
  private nativeInstance: maplibre.Icon;

  /**
   * 构造函数
   * 支持两种模式：
   * 1. 从图标数据创建: new Icon(id, pixelMap, scale)
   * 2. 从 NAPI 实例创建（内部使用）: new Icon(marker, nativeInstance)
   */
  constructor(
    idOrMarker: string | InternalMarker,
    pixelMapOrNative?: image.PixelMap | maplibre.Icon,
    scale?: number
  ) {
    if (idOrMarker === InternalMarker.INSTANCE && pixelMapOrNative instanceof Object) {
      // 内部模式：从 NAPI 实例创建
      this.nativeInstance = pixelMapOrNative as maplibre.Icon;
    } else if (typeof idOrMarker === 'string' && pixelMapOrNative) {
      // 正常模式：从图标数据创建
      this.nativeInstance = new maplibre.Icon(idOrMarker, pixelMapOrNative as image.PixelMap, scale);
    } else {
      throw new Error('Invalid Icon constructor arguments');
    }
  }

  /**
   * 从 NAPI 实例创建（内部使用）
   */
  static fromNative(nativeInstance: maplibre.Icon): Icon {
    return new Icon(InternalMarker.INSTANCE, nativeInstance);
  }

  /**
   * 内部创建方法（供 IconFactory 使用）
   */
  static createInternal(id: string, pixelMap: image.PixelMap, scale?: number): Icon {
    return new Icon(id, pixelMap, scale);
  }

  /**
   * 获取 NAPI 实例（内部使用）
   */
  getNative(): maplibre.Icon {
    return this.nativeInstance;
  }

  /**
   * 获取图标 ID
   */
  getId(): string {
    return this.nativeInstance.getId();
  }

  /**
   * 获取图标缩放比例
   */
  getScale(): number {
    return this.nativeInstance.getScale();
  }

  /**
   * 获取图标宽度
   */
  getWidth(): number {
    return this.nativeInstance.getWidth();
  }

  /**
   * 获取图标高度
   */
  getHeight(): number {
    return this.nativeInstance.getHeight();
  }

  /**
   * 检查图标是否已释放（内部使用）
   */
  isReleased(): boolean {
    // IconManager 需要的方法
    return false;
  }

  /**
   * 释放图标资源（内部使用）
   */
  release(): void {
    // IconManager 需要的方法
  }
}
