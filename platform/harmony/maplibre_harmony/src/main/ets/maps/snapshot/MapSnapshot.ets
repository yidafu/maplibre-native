import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';
/**
 * MapSnapshot - snapshot result container.
 *
 * Holds the rendered snapshot image and accompanying metadata.
 *
 * **Platform equivalents**:
 * - Android: `MapSnapshot`
 * - iOS: `MLNMapSnapshot`
 *
 * **Coordinate conversion helpers**:
 * - `pixelForLatLng()` - locate geographic coordinates on the snapshot image.
 * - `latLngForPixel()` - convert pixel coordinates on the snapshot back to geographic coordinates.
 */

import image from '@ohos.multimedia.image';
import type {
  SnapshotResultNAPI,
  PixelCoordinateResult,
  LatLngResult
} from 'libmaplibre.so';
import { LatLng } from '../geometry/LatLng';
import { Point, PixelCoordinate } from '../geometry/Point';

/**
 * Wrapper for map snapshots.
 *
 * Mirrors Android `MapSnapshot` and the iOS snapshot result.
 */
export class MapSnapshot {
  /**
   * Snapshot image.
   */
  public readonly image: image.PixelMap;
  /**
   * Image width (pixels).
   */
  public readonly width: number;
  /**
   * Image height (pixels).
   */
  public readonly height: number;
  /**
   * Attribution strings.
   */
  public readonly attributions: string[];
  /**
   * Whether to draw the logo.
   */
  public readonly showLogo: boolean;
  
  /**
   * Native snapshot object (used for coordinate conversion).
   * @private
   */
  private nativeSnapshot: SnapshotResultNAPI | null = null;

  /**
   * Constructor.
   */
  constructor(
    image: image.PixelMap,
    width: number,
    height: number,
    attributions: string[] = [],
    showLogo: boolean = true,
    nativeSnapshot?: SnapshotResultNAPI
  ) {
    this.image = image;
    this.width = width;
    this.height = height;
    this.attributions = attributions;
    this.showLogo = showLogo;
    this.nativeSnapshot = nativeSnapshot || null;
  }

  /**
   * Retrieve the snapshot image.
   */
  public getImage(): image.PixelMap {
    return this.image;
  }

  /**
   * Retrieve attribution strings.
   */
  public getAttributions(): string[] {
    return this.attributions;
  }

  /**
   * Project a geographic location to pixel coordinates on the snapshot.
   *
   * Android equivalent: `MapSnapshot.pixelForLatLng(LatLng)`.
   * Useful when drawing overlays (markers, labels, etc.) on the snapshot.
   *
   * @param latLng Geographic coordinate.
   * @returns Pixel coordinate within the snapshot image.
   *
   * @example
   * ```typescript
   * const snapshot = await getSnapshot();
   * const markerPos = new LatLng(39.9, 116.4);
   * const pixelPos = snapshot.pixelForLatLng(markerPos);
   * // Draw marker at pixelPos
   * ```
   */
  public pixelForLatLng(latLng: LatLng): Point {
    if (!this.nativeSnapshot) {
      throw new Error('Native snapshot object not available for coordinate conversion');
    }

    try {
      // Invoke native conversion
      const result: PixelCoordinateResult = this.nativeSnapshot.pixelForLatLng(latLng.latitude, latLng.longitude);
      return new PixelCoordinate(result.x, result.y);
    } catch (err) {
      const error = err as Error;
      hilog.error(DOMAIN, 'MapSnapshot', '[MapSnapshot] pixelForLatLng failed: %{public}s', error.message);
      throw new Error(`Coordinate conversion failed: ${error.message}`);
    }
  }

  /**
   * Convert a pixel coordinate back to a geographic coordinate.
   *
   * Android equivalent: `MapSnapshot.latLngForPixel(PointF)`.
   * Useful when mapping user clicks on the snapshot to geographic coordinates.
   *
   * @param point Pixel coordinate on the snapshot image.
   * @returns Geographic coordinate.
   *
   * @example
   * ```typescript
   * const snapshot = await getSnapshot();
   * const clickPoint = new Point(100, 200);
   * const latLng = snapshot.latLngForPixel(clickPoint);
   * console.log('Clicked at:', latLng.latitude, latLng.longitude);
   * ```
   */
  public latLngForPixel(point: Point): LatLng {
    if (!this.nativeSnapshot) {
      throw new Error('Native snapshot object not available for coordinate conversion');
    }

    try {
      // Invoke native conversion
      const result: LatLngResult = this.nativeSnapshot.latLngForPixel(point.x, point.y);
      return new LatLng(result.latitude, result.longitude);
    } catch (err) {
      const error = err as Error;
      hilog.error(DOMAIN, 'MapSnapshot', '[MapSnapshot] latLngForPixel failed: %{public}s', error.message);
      throw new Error(`Coordinate conversion failed: ${error.message}`);
    }
  }

  /**
   * Convert to string.
   */
  public toString(): string {
    return `MapSnapshot{size=${this.width}x${this.height}, ` +
      `attributions=${this.attributions.length}, ` +
      `showLogo=${this.showLogo}}`;
  }
}

