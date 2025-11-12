import { Image } from '../images/Image';

/**
 * ImageSource option interface.
 */
export interface ImageSourceOptions {
  /** Image URL. */
  url?: string;

  /** Coordinates for the four image corners [[lon, lat], ...]. */
  coordinates?: number[][];
}

/**
 * ImageSource - displays a single image over a geographic extent.
 */
export class ImageSource {
  /**
   * Type token used for ETS-side type checks.
   */
  _TYPE_?: string;

  /**
   * Construct an image source.
   * @param id Source identifier.
   * @param options Optional configuration (url and/or coordinates).
   */
  constructor(id: string, options?: ImageSourceOptions);

  /**
   * Get the source identifier.
   */
  getId(): string;

  /**
   * Reserved for internal native pointer access.
   */
  /**
   * Set the image URL.
   * @param url Image URL.
   * @returns this (chainable).
   */
  setUrl(url: string): this;

  /**
   * Set the image object.
   * @param image Image instance.
   * @returns this (chainable).
   */
  setImage(image: Image): this;

  /**
   * Set the four corner coordinates.
   * @param coordinates Array of corner coordinates [[lon, lat], ...].
   * @returns this (chainable).
   */
  setCoordinates(coordinates: number[][]): this;
}
