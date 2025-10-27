/**
 * 定义相机如何跟踪用户位置的方式
 * Contains the variety of camera modes which determine how the camera will track the user location.
 */
export class CameraMode {
  /**
   * 不跟踪位置
   * No camera tracking.
   */
  static readonly NONE: number = 0x00000008;

  /**
   * 相机不跟踪位置，但跟踪指南针方向
   * Camera does not track location, but does track compass bearing.
   */
  static readonly NONE_COMPASS: number = 0x00000010;

  /**
   * 相机不跟踪位置，但跟踪 GPS 方向
   * Camera does not track location, but does track GPS bearing.
   */
  static readonly NONE_GPS: number = 0x00000016;

  /**
   * 相机跟踪用户位置
   * Camera tracks the user location.
   */
  static readonly TRACKING: number = 0x00000018;

  /**
   * 相机跟踪用户位置和指南针方向
   * Camera tracks the user location, with bearing provided by a compass.
   */
  static readonly TRACKING_COMPASS: number = 0x00000020;

  /**
   * 相机跟踪用户位置和 GPS 方向
   * Camera tracks the user location, with bearing provided by GPS.
   */
  static readonly TRACKING_GPS: number = 0x00000022;

  /**
   * 相机跟踪用户位置，方向始终为北（0度）
   * Camera tracks the user location, with bearing always set to north (0).
   */
  static readonly TRACKING_GPS_NORTH: number = 0x00000024;

  /**
   * 验证相机模式是否有效
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
   * 判断是否是跟踪模式
   */
  static isTracking(mode: number): boolean {
    return mode === CameraMode.TRACKING ||
           mode === CameraMode.TRACKING_COMPASS ||
           mode === CameraMode.TRACKING_GPS ||
           mode === CameraMode.TRACKING_GPS_NORTH;
  }

  /**
   * 获取相机模式的名称
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

