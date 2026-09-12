/**
 * Projection - Coordinate projection utility
 *
 * Converts between screen and geographic coordinates. Screen coordinates are expressed in
 * screen pixels (not physical display pixels) relative to the top-left corner of the map view
 * rather than the device screen.
 *
 * **Platform parity**:
 * - Android: `Projection` (`map.getProjection()`)
 * - iOS: Coordinate conversion methods on `MLNMapView` (for example `convertCoordinate:toPointToView:`)
 *
 * **Key capabilities**:
 * 1. Screen ↔ geographic coordinate conversion (single point and batch)
 * 2. Geographic coordinate ↔ projected meters conversion
 * 3. Visible region queries
 * 4. Distance and scale calculations
 *
 * @example
 * ```typescript
 * // Obtain the Projection instance
 * const projection = map.getProjection();
 *
 * // Convert a geographic coordinate to screen space
 * const latLng = new LatLng(39.9, 116.4);
 * const screenPoint = projection.toScreenLocation(latLng);
 *
 * // Convert a screen point back to a geographic coordinate
 * const location = projection.fromScreenLocation(new Point(100, 100));
 *
 * // Get the current visible region
 * const visibleRegion = projection.getVisibleRegion();
 * ```
 *
 * @see {@link https://docs.maplibre.org/android/api/ | MapLibre Android API}
 */
import { NativeMapView } from 'libmaplibre.so';
import { LatLng } from '../geometry/LatLng';
import { IPixelCoordinate, PixelCoordinate, Point } from '../geometry/Point';
import { IProjectedMeters, ProjectedMeters } from '../geometry/ProjectedMeters';
import { VisibleRegion } from './VisibleRegion';
import { LatLngBounds } from '../geometry/LatLngBounds';

/**
 * GeometryConstants - Geometry constants
 * Mirrors the Android implementation
 */
class GeometryConstants {
  static readonly MIN_LATITUDE: number = -90.0;
  static readonly MAX_LATITUDE: number = 90.0;
  static readonly MIN_LONGITUDE: number = -180.0;
  static readonly MAX_LONGITUDE: number = 180.0;
  static readonly LONGITUDE_SPAN: number = 360.0;
}

/**
 * Projection class
 *
 * Provides map projection helper methods aligned with the Android API
 */
export class Projection {
  private nativeMapView: NativeMapView;
  private viewWidth: number = 0;
  private viewHeight: number = 0;
  private contentPadding: number[] = [0, 0, 0, 0]; // [left, top, right, bottom]
  private static readonly DEFAULT_PIXEL_RATIO: number = 1;

  /**
   * Constructor
   *
   * @param nativeMapView NativeMapView instance
   * @param viewWidth View width in logical pixels
   * @param viewHeight View height in logical pixels
   */
  constructor(nativeMapView: NativeMapView, viewWidth: number, viewHeight: number) {
    this.nativeMapView = nativeMapView;
    this.viewWidth = viewWidth;
    this.viewHeight = viewHeight;
  }

  private getPixelRatio(): number {
    try {
      const ratioCandidate = this.nativeMapView.getPixelRatio?.();
      if (typeof ratioCandidate === 'number' && Number.isFinite(ratioCandidate) && ratioCandidate > 0) {
        return ratioCandidate;
      }
    } catch (error) {
      const reason = error instanceof Error ? error.message : `${error}`;
      console.warn(`[Projection] Failed to read pixel ratio, fallback to 1: ${reason}`);
    }
    return Projection.DEFAULT_PIXEL_RATIO;
  }

  /**
   * Update the view dimensions
   *
   * @param width New view width
   * @param height New view height
   */
  public updateViewSize(width: number, height: number): void {
    this.viewWidth = width;
    this.viewHeight = height;
  }

  // ========== Single-point coordinate conversion ==========

  /**
   * Convert a geographic coordinate to a screen coordinate
   *
   * Android: `toScreenLocation(LatLng)`
   * iOS: `convertCoordinate:toPointToView:`
   *
   * @param location Geographic coordinate
   * @returns Screen coordinate (pixels)
   */
  public toScreenLocation(location: LatLng): Point {
    const physical: IPixelCoordinate = this.nativeMapView.pixelForLatLng(location.latitude, location.longitude);
    const pixelRatio = this.getPixelRatio();
    return PixelCoordinate.create(physical.x / pixelRatio, physical.y / pixelRatio);
  }

  /**
   * Convert a screen coordinate to a geographic coordinate
   *
   * Android: `fromScreenLocation(PointF)`
   * iOS: `convertPoint:toCoordinateFromView:`
   *
   * @param point Screen coordinate (pixels)
   * @returns Geographic coordinate
   */
  public fromScreenLocation(point: Point): LatLng {
    const pixelRatio = this.getPixelRatio();
    const physicalX = point.x * pixelRatio;
    const physicalY = point.y * pixelRatio;
    return LatLng.fromNative(this.nativeMapView.latLngForPixel(physicalX, physicalY));
  }

  // ========== Batch coordinate conversion ==========

  /**
   * Batch convert geographic coordinates to screen coordinates (Android style)
   *
   * Android: `toScreenLocations(double[], double[])`
   *
   * @param input Input array formatted as [lat1, lng1, lat2, lng2, ...]
   * @param output Output array formatted as [x1, y1, x2, y2, ...]
   */
  public toScreenLocations(input: number[], output: number[]): void {
    if (input.length % 2 !== 0) {
      throw new Error('Input array length must be even (lat/lng pairs)');
    }
    
    if (output.length < input.length) {
      throw new Error('Output array must be at least as long as input array');
    }
    
    const pixelRatio = this.getPixelRatio();
    for (let i = 0; i < input.length; i += 2) {
      const lat = input[i];
      const lng = input[i + 1];
      const physical: IPixelCoordinate = this.nativeMapView.pixelForLatLng(lat, lng);
      output[i] = physical.x / pixelRatio;
      output[i + 1] = physical.y / pixelRatio;
    }
  }

  /**
   * Batch convert screen coordinates to geographic coordinates (Android style)
   *
   * Android: `fromScreenLocations(double[], double[])`
   *
   * @param input Input array formatted as [x1, y1, x2, y2, ...]
   * @param output Output array formatted as [lat1, lng1, lat2, lng2, ...]
   */
  public fromScreenLocations(input: number[], output: number[]): void {
    if (input.length % 2 !== 0) {
      throw new Error('Input array length must be even (x/y pairs)');
    }
    
    if (output.length < input.length) {
      throw new Error('Output array must be at least as long as input array');
    }
    
    const pixelRatio = this.getPixelRatio();
    for (let i = 0; i < input.length; i += 2) {
      const physicalX = input[i] * pixelRatio;
      const physicalY = input[i + 1] * pixelRatio;
      const latLng = this.nativeMapView.latLngForPixel(physicalX, physicalY);
      output[i] = latLng.latitude;
      output[i + 1] = latLng.longitude;
    }
  }

  // ========== Visible region ==========

  /**
   * Get the current visible region of the map
   *
   * Returns the geographic coordinates of the four screen corners and the bounding region.
   *
   * Android: `getVisibleRegion()` / `getVisibleRegion(boolean)`
   * iOS: `visibleCoordinateBounds`
   *
   * @param ignorePadding Whether to ignore content padding.
   *                      - true: Return the visible region for the full map view (default)
   *                      - false: Return the region after subtracting content padding
   * @returns Visible region details
   *
   * @example
   * ```typescript
   * // Fetch the full map region (ignoring padding)
   * const fullRegion = projection.getVisibleRegion();
   *
   * // Fetch the region constrained by content padding
   * const paddedRegion = projection.getVisibleRegion(false);
   * ```
   */
  public getVisibleRegion(ignorePadding: boolean = true): VisibleRegion {
    let left: number, right: number, top: number, bottom: number;
    
    if (ignorePadding) {
      // Ignore padding and use the full view size
      left = 0;
      right = this.viewWidth;
      top = 0;
      bottom = this.viewHeight;
    } else {
      // Respect content padding
      // contentPadding: [left, top, right, bottom]
      left = this.contentPadding[0];
      right = this.viewWidth - this.contentPadding[2];
      top = this.contentPadding[1];
      bottom = this.viewHeight - this.contentPadding[3];
    }
    
    // Calculate the center point
    const centerX = left + (right - left) / 2;
    const centerY = top + (bottom - top) / 2;
    const center = this.fromScreenLocation(PixelCoordinate.create(centerX, centerY));
    
    // Resolve geographic coordinates for the four corners
    // Screen coordinate origin is the top-left corner
    const topLeft = this.fromScreenLocation(PixelCoordinate.create(left, top));
    const topRight = this.fromScreenLocation(PixelCoordinate.create(right, top));
    const bottomRight = this.fromScreenLocation(PixelCoordinate.create(right, bottom));
    const bottomLeft = this.fromScreenLocation(PixelCoordinate.create(left, bottom));
    
    // Compute bounds that include all corner points (mirrors Android implementation)
    const latLngs = [topRight, bottomRight, bottomLeft, topLeft];
    
    let maxEastLonSpan = 0;
    let maxWestLonSpan = 0;
    
    let east = 0;
    let west = 0;
    let north = GeometryConstants.MIN_LATITUDE;
    let south = GeometryConstants.MAX_LATITUDE;
    
    for (const latLng of latLngs) {
      const bearingValue = Projection.bearing(center, latLng);
      
      if (bearingValue >= 0) {
        const span = Projection.getLongitudeSpan(latLng.longitude, center.longitude);
        if (span > maxEastLonSpan) {
          maxEastLonSpan = span;
          east = latLng.longitude;
        }
      } else {
        const span = Projection.getLongitudeSpan(center.longitude, latLng.longitude);
        if (span > maxWestLonSpan) {
          maxWestLonSpan = span;
          west = latLng.longitude;
        }
      }
      
      if (north < latLng.latitude) {
        north = latLng.latitude;
      }
      if (south > latLng.latitude) {
        south = latLng.latitude;
      }
    }
    
    let bounds: LatLngBounds;
    if (east < west) {
      // Bounds cross the prime meridian
      const ne = new LatLng(north, east + GeometryConstants.LONGITUDE_SPAN);
      const sw = new LatLng(south, west);
      bounds = LatLngBounds.fromLatLngs(ne, sw);
    } else {
      const ne = new LatLng(north, east);
      const sw = new LatLng(south, west);
      bounds = LatLngBounds.fromLatLngs(ne, sw);
    }
    
    return new VisibleRegion(topLeft, topRight, bottomLeft, bottomRight, bounds);
  }

  /**
   * Get the visible coordinate bounds of the map
   *
   * Android: `getVisibleCoordinateBounds(double[])`
   *
   * This method ignores content padding.
   *
   * @returns Visible coordinate bounds (LatLngBounds)
   */
  public getVisibleCoordinateBounds(): LatLngBounds {
    // Fetch directly from native
    const latLngs = this.nativeMapView.getVisibleCoordinateBounds();
    if (latLngs && latLngs.length >= 4) {
      // Return order: [topLeft, topRight, bottomRight, bottomLeft]
      // Construct a LatLngBounds from the native data
      const north = Math.max(latLngs[0].latitude, latLngs[1].latitude, 
                             latLngs[2].latitude, latLngs[3].latitude);
      const south = Math.min(latLngs[0].latitude, latLngs[1].latitude,
                             latLngs[2].latitude, latLngs[3].latitude);
      const east = Math.max(latLngs[0].longitude, latLngs[1].longitude,
                            latLngs[2].longitude, latLngs[3].longitude);
      const west = Math.min(latLngs[0].longitude, latLngs[1].longitude,
                            latLngs[2].longitude, latLngs[3].longitude);
      const ne = new LatLng(north, east);
      const sw = new LatLng(south, west);
      return LatLngBounds.fromLatLngs(ne, sw);
    }
    
    // Fallback to getVisibleRegion if the native method fails
    return this.getVisibleRegion(true).latLngBounds;
  }

  // ========== Utility methods ==========

  /**
   * Get the meters-per-pixel value at the specified latitude
   *
   * Uses the map's current zoom level
   *
   * @param latitude Latitude
   * @returns Meters per pixel
   */
  public getMetersPerPixelAtLatitude(latitude: number): number {
    // Use the NativeMapView API which derives the current zoom level
    const zoom: number = this.nativeMapView.getZoom();
    return this.nativeMapView.getMetersPerPixelAtLatitude(latitude, zoom);
  }

  /**
   * Get the meters-per-pixel value at the specified latitude and zoom level
   *
   * @param latitude Latitude
   * @param zoom Zoom level
   * @returns Meters per pixel
   */
  public getMetersPerPixelAtLatitudeAndZoom(latitude: number, zoom: number): number {
    return this.nativeMapView.getMetersPerPixelAtLatitude(latitude, zoom);
  }

  /**
   * Convert a geographic coordinate to projected meters (Spherical Mercator projection)
   *
   * Android: `getProjectedMetersForLatLng(LatLng)`
   *
   * @param latLng Geographic coordinate
   * @returns Projected meters
   */
  public getProjectedMetersForLatLng(latLng: LatLng): ProjectedMeters {
    const result: IProjectedMeters = this.nativeMapView.projectedMetersForLatLng(latLng.latitude, latLng.longitude);
    return ProjectedMeters.fromObject(result);
  }

  /**
   * Convert projected meters back to a geographic coordinate
   *
   * Android: `getLatLngForProjectedMeters(ProjectedMeters)`
   *
   * @param projectedMeters Projected meters
   * @returns Geographic coordinate
   */
  public getLatLngForProjectedMeters(projectedMeters: ProjectedMeters): LatLng {
    return LatLng.fromNative(this.nativeMapView.latLngForProjectedMeters(projectedMeters.northing,
      projectedMeters.easting));
  }

  /**
   * Get the view width
   */
  public getViewWidth(): number {
    return this.viewWidth;
  }

  /**
   * Get the view height
   */
  public getViewHeight(): number {
    return this.viewHeight;
  }

  // ========== Content padding ==========

  /**
   * Set the content padding
   * Adjusts how the map center is calculated so the logical center shifts
   *
   * Android reference: Projection.setContentPadding()
   *
   * @param left Left padding in pixels
   * @param top Top padding in pixels
   * @param right Right padding in pixels
   * @param bottom Bottom padding in pixels
   */
  public setContentPadding(left: number, top: number, right: number, bottom: number): void {
    // Store padding values
    this.contentPadding = [left, top, right, bottom];

    // Propagate to the native layer
    // Native expects: [left, top, right, bottom]
    this.nativeMapView.setContentPadding(this.contentPadding);
  }

  /**
   * Get the current content padding
   *
   * Android reference: Projection.getContentPadding()
   *
   * @returns Padding array [left, top, right, bottom]
   */
  public getContentPadding(): number[] {
    // Fetch the latest padding state from native
    try {
      const padding: number[] = this.nativeMapView.getContentPadding();
      if (padding && padding.length === 4) {
        this.contentPadding = padding;
      }
    } catch (error) {
      const reason = error instanceof Error ? error.message : `${error}`;
      console.error(`[Projection] Failed to get content padding from native: ${reason}`);
    }

    // Return a copy to avoid external mutation
    return [...this.contentPadding];
  }

  // ========== Static helper methods (aligned with Android) ==========

  /**
   * Calculate the bearing between two geographic coordinates
   *
   * Android: `Projection.bearing(LatLng, LatLng)`
   *
   * @param latLng1 Start coordinate
   * @param latLng2 Target coordinate
   * @returns Bearing in degrees
   */
  public static bearing(latLng1: LatLng, latLng2: LatLng): number {
    const lon1 = Projection.degreesToRadians(latLng1.longitude);
    const lon2 = Projection.degreesToRadians(latLng2.longitude);
    const lat1 = Projection.degreesToRadians(latLng1.latitude);
    const lat2 = Projection.degreesToRadians(latLng2.latitude);

    const value1 = Math.sin(lon2 - lon1) * Math.cos(lat2);
    const value2 = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1)
      * Math.cos(lat2) * Math.cos(lon2 - lon1);

    return Projection.radiansToDegrees(Math.atan2(value1, value2));
  }

  /**
   * Convert degrees to radians
   *
   * Android: `Projection.degreesToRadians(double)`
   *
   * @param degrees Degrees (0-360)
   * @returns Radians
   */
  public static degreesToRadians(degrees: number): number {
    const radians = degrees % 360;
    return radians * Math.PI / 180;
  }

  /**
   * Convert radians to degrees
   *
   * Android: `Projection.radiansToDegrees(double)`
   *
   * @param radians Radians
   * @returns Degrees (0-360)
   */
  public static radiansToDegrees(radians: number): number {
    const degrees = radians % (2 * Math.PI);
    return degrees * 180 / Math.PI;
  }

  /**
   * Calculate the longitudinal span between east and west boundaries (degrees)
   *
   * Android: `Projection.getLongitudeSpan(double, double)`
   *
   * @param east Eastern longitude
   * @param west Western longitude
   * @returns Longitudinal span in degrees
   */
  public static getLongitudeSpan(east: number, west: number): number {
    const longSpan = Math.abs(east - west);
    if (east > west) {
      return longSpan;
    }

    // Shortest span includes the prime meridian
    return GeometryConstants.LONGITUDE_SPAN - longSpan;
  }

  /**
   * Calculate the target zoom level based on the minimum scale and current zoom
   *
   * Android: `Projection.calculateZoom(float)`
   *
   * @param minScale Minimum scale factor
   * @returns Zoom level suitable for the MapView
   */
  public calculateZoom(minScale: number): number {
    return this.nativeMapView.getZoom() + Math.log(minScale) / Math.log(2);
  }
}