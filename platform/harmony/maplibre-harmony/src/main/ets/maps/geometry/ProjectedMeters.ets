/**
 * ProjectedMeters - projected meter coordinates.
 * ETS class implementation.
 */

/**
 * IProjectedMeters - interface for projected meter coordinates.
 * Suitable for object literals.
 */
export interface IProjectedMeters {
  northing: number;
  easting: number;
}

/**
 * ProjectedMeters - projected meter coordinate class.
 * Represents coordinates in a projected coordinate system (unit: meters).
 */
export class ProjectedMeters implements IProjectedMeters {
  northing: number;
  easting: number;

  constructor(northing: number = 0, easting: number = 0) {
    this.northing = northing;
    this.easting = easting;
  }

  /**
   * Create a ProjectedMeters instance from an object literal.
   */
  static fromObject(obj: IProjectedMeters): ProjectedMeters {
    return new ProjectedMeters(obj.northing, obj.easting);
  }

  /**
   * Convert to an object literal.
   */
  toObject(): IProjectedMeters {
    return {
      northing: this.northing,
      easting: this.easting
    };
  }

  /**
   * Create projected meter coordinates (static factory method).
   */
  static create(northing: number, easting: number): ProjectedMeters {
    return new ProjectedMeters(northing, easting);
  }

  /**
   * Compute the distance to another point.
   */
  distanceTo(other: ProjectedMeters): number {
    const dx = this.easting - other.easting;
    const dy = this.northing - other.northing;
    return Math.sqrt(dx * dx + dy * dy);
  }
}

