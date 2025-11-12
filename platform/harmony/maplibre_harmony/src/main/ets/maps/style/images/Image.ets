import maplibre from 'libmaplibre.so';

/**
 * ImageOptions - image configuration interface.
 */
export interface ImageOptions {
  /** Image name used in style references. */
  name: string;
  /** Image width in pixels. */
  width: number;
  /** Image height in pixels. */
  height: number;
  /** Pixel ratio, defaults to 1.0. */
  pixelRatio?: number;
  /** 
   * Whether the image is SDF (Signed Distance Field).
   * SDF assets allow style-driven color changes, common for icons.
   * Default false.
   */
  sdf?: boolean;
  /** Image data (RGBA, premultiplied alpha). */
  data: Uint8Array;
  /**
   * Stretchable regions (horizontal) - 9-patch style.
   * Array format: [start1, end1, start2, end2, ...] in pixels.
   * Example: [25, 55, 85, 115] marks two stretchable ranges.
   */
  stretchX?: number[];
  /**
   * Stretchable regions (vertical) - 9-patch style.
   * Array format: [start1, end1, start2, end2, ...] in pixels.
   * Example: [25, 100] marks a stretchable band from 25-100.
   */
  stretchY?: number[];
  /**
   * Content region (for text placement).
   * Array format: [left, top, right, bottom] in pixels.
   * Defines the text area after stretching.
   */
  content?: number[];
}

/**
 * ImageSize - image dimensions interface.
 */
export interface ImageSize {
  width: number;
  height: number;
}

/**
 * InternalMarker - sentinel class controlling instantiation.
 */
class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

/**
 * Image - wrapper around the NAPI Image object.
 *
 * Provides a type-safe façade and keeps the native object encapsulated.
 */
export class Image {
  private nativeInstance: maplibre.Image;

  /**
   * Constructor.
   * @param options Image creation options.
   */
  constructor(options: ImageOptions) {
    // Validate required fields.
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

    // Validate data size (RGBA = 4 bytes per pixel).
    const expectedSize = options.width * options.height * 4;
    if (options.data.byteLength !== expectedSize) {
      throw new Error(
        `Image data size mismatch: expected ${expectedSize} bytes, got ${options.data.byteLength} bytes`
      );
    }

    // Validate stretchX (if provided).
    if (options.stretchX && options.stretchX.length % 2 !== 0) {
      throw new Error('stretchX must contain pairs of values [start, end, ...]');
    }

    // Validate stretchY (if provided).
    if (options.stretchY && options.stretchY.length % 2 !== 0) {
      throw new Error('stretchY must contain pairs of values [start, end, ...]');
    }

    // Validate content (if provided).
    if (options.content && options.content.length !== 4) {
      throw new Error('content must contain exactly 4 values [left, top, right, bottom]');
    }

    // Create native Image instance.
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
   * Access the native instance (internal use, e.g., `Style.addImage`).
   * @internal
   */
  getNative(): maplibre.Image {
    return this.nativeInstance;
  }

  /**
   * Get the image name.
   */
  getName(): string {
    return this.nativeInstance.getName();
  }

  /**
   * Get the width.
   */
  getWidth(): number {
    return this.nativeInstance.getWidth();
  }

  /**
   * Get the height.
   */
  getHeight(): number {
    return this.nativeInstance.getHeight();
  }

  /**
   * Get the pixel ratio.
   */
  getPixelRatio(): number {
    return this.nativeInstance.getPixelRatio();
  }

  /**
   * Determine whether the image uses SDF.
   */
  isSdf(): boolean {
    return this.nativeInstance.getSdf();
  }

  /**
   * Get the raw image data.
   */
  getData(): Uint8Array | null {
    return this.nativeInstance.getData();
  }

  /**
   * Get horizontal stretch regions.
   * @returns Array [start1, end1, ...] or null.
   */
  getStretchX(): number[] | null {
    return this.nativeInstance.getStretchX();
  }

  /**
   * Get vertical stretch regions.
   * @returns Array [start1, end1, ...] or null.
   */
  getStretchY(): number[] | null {
    return this.nativeInstance.getStretchY();
  }

  /**
   * Get the content region used for text placement.
   * @returns `[left, top, right, bottom]` or null.
   */
  getContent(): number[] | null {
    return this.nativeInstance.getContent();
  }

  /**
   * Get the image dimensions.
   */
  getSize(): ImageSize {
    return {
      width: this.getWidth(),
      height: this.getHeight()
    };
  }

  /**
   * Compare two images by metadata.
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
   * Convert to string.
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
