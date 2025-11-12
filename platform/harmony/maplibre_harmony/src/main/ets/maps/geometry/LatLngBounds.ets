import { LatLng } from './LatLng';

/**
 * LatLngBounds - latitude/longitude bounds helper.
 */
export class LatLngBounds {
  public north: number;
  public east: number;
  public south: number;
  public west: number;

  /**
   * Constructor supporting two modes:
   * 1. Provide four numeric arguments: `new LatLngBounds(north, east, south, west)`
   * 2. Provide two `LatLng` objects: `new LatLngBounds(southwest, northeast)`
   */
  constructor(northOrSouthwest: number | LatLng, eastOrNortheast: number | LatLng, south?: number, west?: number) {
    if (typeof northOrSouthwest === 'number' && typeof eastOrNortheast === 'number' &&
      typeof south === 'number' && typeof west === 'number') {
      // Mode 1: four numeric arguments
      this.north = northOrSouthwest;
      this.east = eastOrNortheast;
      this.south = south;
      this.west = west;
    } else if (northOrSouthwest instanceof LatLng && eastOrNortheast instanceof LatLng) {
      // Mode 2: two LatLng objects (southwest, northeast)
      const southwest = northOrSouthwest;
      const northeast = eastOrNortheast;
      this.south = southwest.latitude;
      this.west = southwest.longitude;
      this.north = northeast.latitude;
      this.east = northeast.longitude;
    } else {
      throw new Error('Invalid LatLngBounds constructor arguments');
    }
  }

  /**
   * Create bounds from two points.
   *
   * @param northeast Northeast point (greater latitude and longitude).
   * @param southwest Southwest point (smaller latitude and longitude).
   * @returns LatLngBounds instance.
   *
   * @example
  * ```typescript
   * const southwest = createLatLng(30.23, 120.12);
   * const northeast = createLatLng(30.31, 120.20);
   * const bounds = LatLngBounds.fromLatLngs(northeast, southwest);
   * ```
   */
  public static fromLatLngs(northeast: LatLng, southwest: LatLng): LatLngBounds {
    // Validate arguments
    if (northeast.latitude < southwest.latitude) {
      throw new Error(`Invalid bounds: northeast latitude (${northeast.latitude}) must be >= southwest latitude (${southwest.latitude})`);
    }
    if (northeast.longitude < southwest.longitude) {
      throw new Error(`Invalid bounds: northeast longitude (${northeast.longitude}) must be >= southwest longitude (${southwest.longitude})`);
    }

    return new LatLngBounds(northeast.latitude, northeast.longitude, southwest.latitude, southwest.longitude);
  }

  /**
   * Create bounds from an array of points.
   */
  public static fromLatLngArray(latLngs: LatLng[]): LatLngBounds {
    if (latLngs.length === 0) {
      throw new Error('Cannot create bounds from empty array');
    }

    let north = latLngs[0].latitude;
    let east = latLngs[0].longitude;
    let south = latLngs[0].latitude;
    let west = latLngs[0].longitude;

    for (const latLng of latLngs) {
      north = Math.max(north, latLng.latitude);
      east = Math.max(east, latLng.longitude);
      south = Math.min(south, latLng.latitude);
      west = Math.min(west, latLng.longitude);
    }

    return new LatLngBounds(north, east, south, west);
  }

  /**
   * Get the northeast corner.
   */
  public getNortheast(): LatLng {
    return LatLng.create(this.north, this.east);
  }

  /**
   * Get the southwest corner.
   */
  public getSouthwest(): LatLng {
    return LatLng.create(this.south, this.west);
  }

  /**
   * Get the center point.
   */
  public getCenter(): LatLng {
    return LatLng.create(
      (this.north + this.south) / 2,
      (this.east + this.west) / 2
    );
  }

  /**
   * Check whether a point is inside the bounds.
   */
  public contains(latLng: LatLng): boolean {
    return latLng.latitude >= this.south && latLng.latitude <= this.north &&
      latLng.longitude >= this.west && latLng.longitude <= this.east;
  }

  /**
   * Check whether the bounds contains another bounds.
   */
  public containsBounds(other: LatLngBounds): boolean {
    return this.north >= other.north && this.south <= other.south &&
      this.east >= other.east && this.west <= other.west;
  }

  /**
   * Check whether the bounds intersects another bounds.
   */
  public intersects(other: LatLngBounds): boolean {
    return !(this.south > other.north || this.north < other.south ||
      this.west > other.east || this.east < other.west);
  }

  /**
   * Extend the bounds to include a point.
   */
  public extend(latLng: LatLng): LatLngBounds {
    return new LatLngBounds(
      Math.max(this.north, latLng.latitude),
      Math.max(this.east, latLng.longitude),
      Math.min(this.south, latLng.latitude),
      Math.min(this.west, latLng.longitude)
    );
  }

  /**
   * Extend the bounds to include another bounds.
   */
  public extendBounds(other: LatLngBounds): LatLngBounds {
    return new LatLngBounds(
      Math.max(this.north, other.north),
      Math.max(this.east, other.east),
      Math.min(this.south, other.south),
      Math.min(this.west, other.west)
    );
  }

  /**
   * Check whether the bounds is valid.
   */
  public isValid(): boolean {
    return this.north >= this.south && this.east >= this.west &&
      this.north >= -90 && this.north <= 90 &&
      this.south >= -90 && this.south <= 90 &&
      this.east >= -180 && this.east <= 180 &&
      this.west >= -180 && this.west <= 180;
  }

  /**
   * Convert to string.
   */
  public toString(): string {
    return `LatLngBounds(${this.north}, ${this.east}, ${this.south}, ${this.west})`;
  }
}
