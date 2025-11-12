/**
 * Defines how the user's location is rendered on the map.
 * Contains the variety of ways the user location can be rendered on the map.
 */
export class RenderMode {
  /**
   * Basic tracking that shows the user position point and ignores bearing.
   * Basic tracking is enabled, bearing ignored.
   */
  static readonly NORMAL: number = 0x00000012;
  /**
   * Track the user location with bearing supplied by the compass.
   * Tracking the user location with bearing considered from a CompassEngine.
   */
  static readonly COMPASS: number = 0x00000004;
  /**
   * Track the user location with bearing supplied by GPS.
   * Tracking the user location with bearing considered from Location.
   */
  static readonly GPS: number = 0x00000008;

  /**
   * Validate whether the render mode is supported.
   */
  static isValid(mode: number): boolean {
    return mode === RenderMode.NORMAL ||
      mode === RenderMode.COMPASS ||
      mode === RenderMode.GPS;
  }

  /**
   * Get the render mode name.
   */
  static getName(mode: number): string {
    switch (mode) {
      case RenderMode.NORMAL:
        return 'NORMAL';
      case RenderMode.COMPASS:
        return 'COMPASS';
      case RenderMode.GPS:
        return 'GPS';
      default:
        return 'UNKNOWN';
    }
  }
}

