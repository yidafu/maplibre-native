/**
 * ImageSource - 图片数据源封装类
 */
import maplibre from 'libmaplibre.so';
import { Image } from '../images/Image';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();
  private constructor() {}
}

export class ImageSource {
  private nativeInstance: maplibre.ImageSource;

  constructor(
    idOrMarker: string | InternalMarker,
    coordsOrNative?: maplibre.ImageSource
  ) {
    if (idOrMarker === InternalMarker.INSTANCE && coordsOrNative instanceof Object) {
      this.nativeInstance = coordsOrNative;
    } else if (typeof idOrMarker === 'string') {
      // ImageSource 只需要 id，coordinates 通过 setCoordinates 设置
      this.nativeInstance = new maplibre.ImageSource(idOrMarker);
    } else {
      throw new Error('Invalid ImageSource constructor arguments');
    }
  }

  static create(id: string): ImageSource {
    return new ImageSource(id);
  }

  static fromNative(nativeInstance: maplibre.ImageSource): ImageSource {
    return new ImageSource(InternalMarker.INSTANCE, nativeInstance);
  }

  getNative(): maplibre.ImageSource {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  setCoordinates(coordinates: number[][]): ImageSource {
    this.nativeInstance.setCoordinates(coordinates);
    return this;
  }

  setUrl(url: string): ImageSource {
    this.nativeInstance.setUrl(url);
    return this;
  }

  setImage(image: Image): ImageSource {
    // 获取 Image 的 native 实例并传递给 ImageSource
    this.nativeInstance.setImage(image.getNative());
    return this;
  }
}
