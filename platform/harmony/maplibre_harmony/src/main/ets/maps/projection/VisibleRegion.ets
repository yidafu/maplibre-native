/**
 * VisibleRegion - map visible region.
 *
 * Represents the visible region of the current viewport, including coordinates for the four screen corners and the encompassing bounds.
 *
 * **Platform references**:
 * - Android: `VisibleRegion`
 * - iOS: `visibleCoordinateBounds`
 *
 * **Coordinate system**:
 * - topLeft: upper-left (far left)
 * - topRight: upper-right (far right)
 * - bottomLeft: lower-left (near left)
 * - bottomRight: lower-right (near right)
 *
 * @example
 * ```typescript
 * const projection = map.getProjection();
 * const visibleRegion = projection.getVisibleRegion();
 * console.log('Visible top left:', visibleRegion.topLeft);
 * console.log('Visible bounds:', visibleRegion.latLngBounds);
 * ```
 */
import { LatLng } from '../geometry/LatLng';
import { LatLngBounds } from '../geometry/LatLngBounds';

/**
 * VisibleRegion class.
 *
 * Mirrors Android `VisibleRegion` and iOS coordinate bounds.
 */
export class VisibleRegion {
  /**
   * Geographic coordinate at the upper-left corner (far left).
   * Matches Android `topLeft`.
   */
  public readonly topLeft: LatLng;
  
  /**
   * Geographic coordinate at the upper-right corner (far right).
   * Matches Android `topRight`.
   */
  public readonly topRight: LatLng;
  
  /**
   * Geographic coordinate at the lower-left corner (near left).
   * Matches Android `bottomLeft`.
   */
  public readonly bottomLeft: LatLng;
  
  /**
   * Geographic coordinate at the lower-right corner (near right).
   * Matches Android `bottomRight`.
   */
  public readonly bottomRight: LatLng;
  
  /**
   * Bounds enclosing the entire visible region.
   * Matches Android `latLngBounds`.
   */
  public readonly latLngBounds: LatLngBounds;

  // Backwards-compatible accessors.
  /**
   * @deprecated Use `bottomLeft` instead.
   */
  public get nearLeft(): LatLng { return this.bottomLeft; }
  
  /**
   * @deprecated Use `bottomRight` instead.
   */
  public get nearRight(): LatLng { return this.bottomRight; }
  
  /**
   * @deprecated Use `topLeft` instead.
   */
  public get farLeft(): LatLng { return this.topLeft; }
  
  /**
   * @deprecated Use `topRight` instead.
   */
  public get farRight(): LatLng { return this.topRight; }

  /**
   * Constructor (Android-style naming).
   *
   * @param topLeft Upper-left coordinate.
   * @param topRight Upper-right coordinate.
   * @param bottomLeft Lower-left coordinate.
   * @param bottomRight Lower-right coordinate.
   * @param latLngBounds Bounding region.
   */
  constructor(
    topLeft: LatLng,
    topRight: LatLng,
    bottomLeft: LatLng,
    bottomRight: LatLng,
    latLngBounds: LatLngBounds
  ) {
    this.topLeft = topLeft;
    this.topRight = topRight;
    this.bottomLeft = bottomLeft;
    this.bottomRight = bottomRight;
    this.latLngBounds = latLngBounds;
  }

  /**
   * Check whether a coordinate lies within the visible region.
   *
   * @param latLng Coordinate to check.
   * @returns True if the coordinate is inside the region.
   */
  public contains(latLng: LatLng): boolean {
    return this.latLngBounds.contains(latLng);
  }

  /**
   * Retrieve all four corner coordinates (Android API parity).
   *
   * @returns Array ordered as [topLeft, topRight, bottomRight, bottomLeft].
   */
  public getCorners(): LatLng[] {
    return [this.topLeft, this.topRight, this.bottomRight, this.bottomLeft];
  }

  /**
   * Get the geographic center of the visible region.
   *
   * @returns Center coordinate.
   */
  public getCenter(): LatLng {
    return this.latLngBounds.getCenter();
  }

  /**
   * Convert to a string representation.
   */
  public toString(): string {
    return `VisibleRegion{` +
      `topLeft=${this.topLeft.latitude},${this.topLeft.longitude}, ` +
      `topRight=${this.topRight.latitude},${this.topRight.longitude}, ` +
      `bottomLeft=${this.bottomLeft.latitude},${this.bottomLeft.longitude}, ` +
      `bottomRight=${this.bottomRight.latitude},${this.bottomRight.longitude}, ` +
      `bounds=${this.latLngBounds.toString()}}`;
  }

  /**
   * Compare two visible regions.
   */
  public equals(other: VisibleRegion): boolean {
    if (!other) {
      return false;
    }

    return this.topLeft.latitude === other.topLeft.latitude &&
      this.topLeft.longitude === other.topLeft.longitude &&
      this.topRight.latitude === other.topRight.latitude &&
      this.topRight.longitude === other.topRight.longitude &&
      this.bottomLeft.latitude === other.bottomLeft.latitude &&
      this.bottomLeft.longitude === other.bottomLeft.longitude &&
      this.bottomRight.latitude === other.bottomRight.latitude &&
      this.bottomRight.longitude === other.bottomRight.longitude;
  }
}

