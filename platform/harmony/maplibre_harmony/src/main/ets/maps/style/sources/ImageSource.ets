/**
 * ImageSource - Wrapper for image sources
 */
import maplibre from 'libmaplibre.so';
import { Image } from '../images/Image';
import { BaseSource, SourceInternalTag, resolveSourceNative } from './BaseSource';

export class ImageSource extends BaseSource<maplibre.ImageSource> {
  // Type discriminator for instanceof-like checks (NAPI returns plain objects)
  static readonly _TYPE_ = 'ImageSource';

  constructor(idOrMarker: string | SourceInternalTag, coordsOrNative?: maplibre.ImageSource) {
    super(resolveSourceNative(idOrMarker, coordsOrNative, 
      (id) => new maplibre.ImageSource(id), "ImageSource"));
  }

  static create(id: string): ImageSource {
    return new ImageSource(id);
  }

  static fromNative(nativeInstance: maplibre.ImageSource): ImageSource {
    return new ImageSource(SourceInternalTag.INSTANCE, nativeInstance);
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
