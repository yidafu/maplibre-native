/**
 * ImageOptions - image option interface.
 */
export interface ImageOptions {
  /** Image name (required). */
  name: string;

  /** Image width in pixels (required). */
  width: number;

  /** Image height in pixels (required). */
  height: number;

  /** RGBA image data (required, premultiplied alpha). */
  data: Uint8Array;

  /** Pixel ratio (optional, defaults to 1.0). */
  pixelRatio?: number;

  /** Whether the image is an SDF (Signed Distance Field) asset (optional, defaults to false). */
  sdf?: boolean;

  /**
   * Optional horizontal stretch regions.
   * Format: [start1, end1, start2, end2, ...]; each pair defines a stretchable segment.
   */
  stretchX?: number[];

  /**
   * Optional vertical stretch regions.
   * Format: [start1, end1, start2, end2, ...]; each pair defines a stretchable segment.
   */
  stretchY?: number[];

  /**
   * Optional content inset.
   * Format: [left, top, right, bottom]; defines where text or icons can be placed.
   */
  content?: number[];
}

/**
 * Image - map style image class.
 *
 * Adds custom images to map styles, supporting:
 * - Basic image rendering.
 * - SDF images for runtime recoloring.
 * - Stretchable images (similar to nine-patch).
 * - Content area definitions.
 */
export class Image {
  /**
   * Constructor.
   * @param options Image options.
   * @throws Throws when arguments are invalid.
   */
  constructor(options: ImageOptions);

  /**
   * Get the image name.
   * @returns Image name.
   */
  getName(): string;

  /**
   * Get the image width.
   * @returns Width in pixels.
   */
  getWidth(): number;

  /**
   * Get the image height.
   * @returns Height in pixels.
   */
  getHeight(): number;

  /**
   * Get the pixel ratio.
   * @returns Pixel ratio.
   */
  getPixelRatio(): number;

  /**
   * Check whether the image is SDF.
   * @returns True if this is an SDF image.
   */
  getSdf(): boolean;

  /**
   * Get the image data.
   * @returns Copy of the RGBA buffer, or null when unavailable.
   */
  getData(): Uint8Array | null;

  /**
   * Get horizontal stretch regions.
   * @returns Array [start1, end1, start2, end2, ...], or null if unset.
   */
  getStretchX(): number[] | null;

  /**
   * Get vertical stretch regions.
   * @returns Array [start1, end1, start2, end2, ...], or null if unset.
   */
  getStretchY(): number[] | null;

  /**
   * Get the content inset.
   * @returns Array [left, top, right, bottom], or null if unset.
   */
  getContent(): number[] | null;
}

