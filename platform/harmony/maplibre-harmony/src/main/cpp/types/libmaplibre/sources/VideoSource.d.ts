/**
 * VideoSource - displays video content over a geographic extent.
 *
 * Platform-level composition over an ImageSource: the ArkTS side samples
 * video frames and pushes them with updateImage().
 */
export class VideoSource {
  /**
   * Type token used for ETS-side type checks.
   */
  _TYPE_?: string;

  /**
   * Construct a video source.
   * @param id Source identifier.
   * @param coordinates Optional four corner coordinates [[lon, lat] x 4].
   */
  constructor(id: string, coordinates?: number[][]);

  /**
   * Get the source identifier.
   */
  getId(): string;

  /**
   * Set the four corner coordinates [[lon, lat] x 4].
   * @param coordinates Corner coordinates.
   * @returns this (chainable).
   */
  setCoordinates(coordinates: number[][]): this;

  /**
   * Get the four corner coordinates.
   */
  getCoordinates(): number[][];

  /**
   * Set a static image URL (poster frame).
   * @param url Image URL.
   * @returns this (chainable).
   */
  setUrl(url: string): this;

  /**
   * Push a decoded frame into the map.
   * @param image Image instance.
   * @returns this (chainable).
   */
  updateImage(image: Object): this;

  /**
   * Alias of updateImage.
   * @param image Image instance.
   * @returns this (chainable).
   */
  setImage(image: Object): this;
}
