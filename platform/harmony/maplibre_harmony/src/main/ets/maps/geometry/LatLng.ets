/**
 * LatLng - Latitude/longitude value object
 *
 * Pure ETS implementation with no NAPI dependency
 */
import type { ILatLng } from '../types/NativeTypes';

/**
 * Represents a geographic coordinate (latitude and longitude)
 */
export class LatLng implements ILatLng {
  latitude: number;
  longitude: number;

  /**
   * Constructor
   * @param latitude Latitude (-90 to 90)
   * @param longitude Longitude (-180 to 180)
   */
  constructor(latitude: number, longitude: number) {
    this.latitude = latitude;
    this.longitude = longitude;
  }

  /**
   * Static factory method
   * @param latitude Latitude value
   * @param longitude Longitude value
   * @returns LatLng instance
   */
  static create(latitude: number, longitude: number): LatLng {
    return new LatLng(latitude, longitude);
  }

  /**
   * Create from a native LatLng (for NAPI interop)
   * @param native Native LatLng object
   * @returns LatLng instance
   */
  static fromNative(native: ILatLng): LatLng {
    return new LatLng(native.latitude, native.longitude);
  }


  /**
   * Convert to a plain object
   * @returns Object literal { latitude, longitude }
   */
  toObject(): ILatLng {
    return {
      latitude: this.latitude,
      longitude: this.longitude
    };
  }

  /**
   * Check whether the coordinate is within valid bounds
   * @returns True if the coordinate is within range
   */
  isValid(): boolean {
    return this.latitude >= -90 && this.latitude <= 90 &&
      this.longitude >= -180 && this.longitude <= 180;
  }

  /**
   * Compute the distance to another coordinate in meters
   * Uses the Haversine formula
   * @param other Target coordinate
   * @returns Distance in meters
   */
  distanceTo(other: LatLng): number {
    const R = 6371000; // Earth radius in meters
    const dLat = toRadians(other.latitude - this.latitude);
    const dLon = toRadians(other.longitude - this.longitude);
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(toRadians(this.latitude)) * Math.cos(toRadians(other.latitude)) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  /**
   * Compare for equality
   * @param other Coordinate to compare
   * @returns True if both coordinates are equal
   */
  equals(other: LatLng): boolean {
    return Math.abs(this.latitude - other.latitude) < 1e-10 &&
      Math.abs(this.longitude - other.longitude) < 1e-10;
  }

  /**
   * Convert to a string representation
   * @returns String form
   */
  toString(): string {
    return `LatLng(${this.latitude}, ${this.longitude})`;
  }
}

/**
 * Convert degrees to radians
 * @param degrees Degrees
 * @returns Radians
 */
function toRadians(degrees: number): number {
  return degrees * (Math.PI / 180);
}

/**
 * Factory helper to create a LatLng
 * @param latitude Latitude
 * @param longitude Longitude
 * @returns LatLng instance
 */
export function createLatLng(latitude: number, longitude: number): LatLng {
  return LatLng.create(latitude, longitude);
}

/**
 * Check whether a coordinate is valid
 * @param latLng Coordinate object
 * @returns True if valid
 */
export function isValidLatLng(latLng: LatLng): boolean {
  return latLng.isValid();
}

/**
 * Calculate the distance between two coordinates (meters)
 * @param from Starting coordinate
 * @param to Destination coordinate
 * @returns Distance in meters
 */
export function distanceBetween(from: LatLng, to: LatLng): number {
  return from.distanceTo(to);
}

/**
 * Compare whether two coordinates are equal
 * @param a Coordinate A
 * @param b Coordinate B
 * @returns True if they are equal
 */
export function latLngEquals(a: LatLng, b: LatLng): boolean {
  return a.equals(b);
}
