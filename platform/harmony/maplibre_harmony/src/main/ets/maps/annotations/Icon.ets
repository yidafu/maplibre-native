/**
 * Icon - icon wrapper class.
 *
 * ArkTS-compliant wrapper around the native icon implementation.
 */
import maplibre from 'libmaplibre.so';
import image from '@ohos.multimedia.image';
/**
 * Internal marker used to distinguish the native-construction path.
 */
class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

/**
 * Icon wrapper.
 */
export class Icon {
  private nativeInstance: maplibre.Icon;

  /**
   * Constructor supporting two modes:
   * 1. Create from icon data: `new Icon(id, pixelMap, scale)`
   * 2. Create from NAPI instance (internal use): `new Icon(marker, nativeInstance)`
   */
  constructor(
    idOrMarker: string | InternalMarker,
    pixelMapOrNative?: image.PixelMap | maplibre.Icon,
    scale?: number
  ) {
    if (idOrMarker === InternalMarker.INSTANCE && pixelMapOrNative instanceof Object) {
      // Internal mode: construct from NAPI instance
      this.nativeInstance = pixelMapOrNative as maplibre.Icon;
    } else if (typeof idOrMarker === 'string' && pixelMapOrNative) {
      // Standard mode: construct from icon data
      this.nativeInstance = new maplibre.Icon(idOrMarker, pixelMapOrNative as image.PixelMap, scale);
    } else {
      throw new Error('Invalid Icon constructor arguments');
    }
  }

  /**
   * Create from a NAPI instance (internal use).
   */
  static fromNative(nativeInstance: maplibre.Icon): Icon {
    return new Icon(InternalMarker.INSTANCE, nativeInstance);
  }

  /**
   * Internal creation helper (used by `IconFactory`).
   */
  static createInternal(id: string, pixelMap: image.PixelMap, scale?: number): Icon {
    return new Icon(id, pixelMap, scale);
  }

  /**
   * Retrieve the underlying NAPI instance (internal use).
   */
  getNative(): maplibre.Icon {
    return this.nativeInstance;
  }

  /**
   * Get the icon ID.
   */
  getId(): string {
    return this.nativeInstance.getId();
  }

  /**
   * Get the icon scale factor.
   */
  getScale(): number {
    return this.nativeInstance.getScale();
  }

  /**
   * Get the icon width.
   */
  getWidth(): number {
    return this.nativeInstance.getWidth();
  }

  /**
   * Get the icon height.
   */
  getHeight(): number {
    return this.nativeInstance.getHeight();
  }

  /**
   * Check whether the icon has been released (internal use).
   */
  isReleased(): boolean {
    // Required by IconManager
    return false;
  }

  /**
   * Release icon resources (internal use).
   */
  release(): void {
    // Required by IconManager
  }
}
