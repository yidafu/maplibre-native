/**
 * ImageSource - Wrapper for image sources
 */
import maplibre from 'libmaplibre.so';
import { Image } from '../images/Image';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

export class ImageSource {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'ImageSource';
  private nativeInstance: maplibre.ImageSource;

  constructor(
    idOrMarker: string | InternalMarker,
    coordsOrNative?: maplibre.ImageSource
  ) {
    if (idOrMarker === InternalMarker.INSTANCE && coordsOrNative instanceof Object) {
      this.nativeInstance = coordsOrNative;
    } else if (typeof idOrMarker === 'string') {
      // ImageSource only requires an id; coordinates are supplied via setCoordinates
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
    // Pass the native Image instance through to the ImageSource
    this.nativeInstance.setImage(image.getNative());
    return this;
  }
}
