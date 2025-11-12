/**
 * Defines how the camera tracks the user location.
 * Contains the variety of camera modes which determine how the camera will track the user location.
 */
export class CameraMode {
  /**
   * Do not track location.
   * No camera tracking.
   */
  static readonly NONE: number = 0x00000008;
  /**
   * Camera does not track location but tracks compass bearing.
   * Camera does not track location, but does track compass bearing.
   */
  static readonly NONE_COMPASS: number = 0x00000010;
  /**
   * Camera does not track location but tracks GPS bearing.
   * Camera does not track location, but does track GPS bearing.
   */
  static readonly NONE_GPS: number = 0x00000016;
  /**
   * Camera tracks the user location.
   * Camera tracks the user location.
   */
  static readonly TRACKING: number = 0x00000018;
  /**
  * Camera tracks the user location with bearing from the compass.
   * Camera tracks the user location, with bearing provided by a compass.
   */
  static readonly TRACKING_COMPASS: number = 0x00000020;
  /**
   * Camera tracks the user location with bearing from GPS.
   * Camera tracks the user location, with bearing provided by GPS.
   */
  static readonly TRACKING_GPS: number = 0x00000022;
  /**
   * Camera tracks the user location with a fixed north-facing bearing (0 degrees).
   * Camera tracks the user location, with bearing always set to north (0).
   */
  static readonly TRACKING_GPS_NORTH: number = 0x00000024;

  /**
   * Validate whether the camera mode is supported.
   */
  static isValid(mode: number): boolean {
    return mode === CameraMode.NONE ||
      mode === CameraMode.NONE_COMPASS ||
      mode === CameraMode.NONE_GPS ||
      mode === CameraMode.TRACKING ||
      mode === CameraMode.TRACKING_COMPASS ||
      mode === CameraMode.TRACKING_GPS ||
      mode === CameraMode.TRACKING_GPS_NORTH;
  }

  /**
   * Determine whether the mode tracks the user.
   */
  static isTracking(mode: number): boolean {
    return mode === CameraMode.TRACKING ||
      mode === CameraMode.TRACKING_COMPASS ||
      mode === CameraMode.TRACKING_GPS ||
      mode === CameraMode.TRACKING_GPS_NORTH;
  }

  /**
   * Get the camera mode name.
   */
  static getName(mode: number): string {
    switch (mode) {
      case CameraMode.NONE:
        return 'NONE';
      case CameraMode.NONE_COMPASS:
        return 'NONE_COMPASS';
      case CameraMode.NONE_GPS:
        return 'NONE_GPS';
      case CameraMode.TRACKING:
        return 'TRACKING';
      case CameraMode.TRACKING_COMPASS:
        return 'TRACKING_COMPASS';
      case CameraMode.TRACKING_GPS:
        return 'TRACKING_GPS';
      case CameraMode.TRACKING_GPS_NORTH:
        return 'TRACKING_GPS_NORTH';
      default:
        return 'UNKNOWN';
    }
  }
}

