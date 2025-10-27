/**
 * 定义用户位置在地图上的渲染方式
 * Contains the variety of ways the user location can be rendered on the map.
 */
export class RenderMode {
  /**
   * 基础跟踪模式，显示用户位置点，忽略方向
   * Basic tracking is enabled, bearing ignored.
   */
  static readonly NORMAL: number = 0x00000012;

  /**
   * 跟踪用户位置，方向由指南针提供
   * Tracking the user location with bearing considered from a CompassEngine.
   */
  static readonly COMPASS: number = 0x00000004;

  /**
   * 跟踪用户位置，方向由 GPS 提供
   * Tracking the user location with bearing considered from Location.
   */
  static readonly GPS: number = 0x00000008;

  /**
   * 验证渲染模式是否有效
   */
  static isValid(mode: number): boolean {
    return mode === RenderMode.NORMAL ||
           mode === RenderMode.COMPASS ||
           mode === RenderMode.GPS;
  }

  /**
   * 获取渲染模式的名称
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

