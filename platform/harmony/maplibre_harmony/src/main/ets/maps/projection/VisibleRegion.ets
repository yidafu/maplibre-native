/**
 * VisibleRegion - 地图可见区域
 *
 * 表示地图当前视口的可见区域，包含屏幕四个角对应的地理坐标和边界
 */
import { LatLng } from '../geometry/LatLng';
import { LatLngBounds } from '../geometry/LatLngBounds';
/**
 * VisibleRegion 类
 *
 * 对应 Android 的 VisibleRegion 和 iOS 的 coordinate bounds
 */
export class VisibleRegion {
  /**
   * 近左角（屏幕左下角）的地理坐标
   */
  public readonly nearLeft: LatLng;
  /**
   * 近右角（屏幕右下角）的地理坐标
   */
  public readonly nearRight: LatLng;
  /**
   * 远左角（屏幕左上角）的地理坐标
   */
  public readonly farLeft: LatLng;
  /**
   * 远右角（屏幕右上角）的地理坐标
   */
  public readonly farRight: LatLng;
  /**
   * 包含整个可见区域的最小边界
   */
  public readonly latLngBounds: LatLngBounds;

  /**
   * 构造函数
   *
   * @param nearLeft 近左角坐标（屏幕左下角）
   * @param nearRight 近右角坐标（屏幕右下角）
   * @param farLeft 远左角坐标（屏幕左上角）
   * @param farRight 远右角坐标（屏幕右上角）
   * @param latLngBounds 边界对象
   */
  constructor(
    nearLeft: LatLng,
    nearRight: LatLng,
    farLeft: LatLng,
    farRight: LatLng,
    latLngBounds: LatLngBounds
  ) {
    this.nearLeft = nearLeft;
    this.nearRight = nearRight;
    this.farLeft = farLeft;
    this.farRight = farRight;
    this.latLngBounds = latLngBounds;
  }

  /**
   * 判断指定坐标是否在可见区域内
   *
   * @param latLng 要检查的坐标
   * @returns 是否在可见区域内
   */
  public contains(latLng: LatLng): boolean {
    return this.latLngBounds.contains(latLng);
  }

  /**
   * 转换为字符串表示
   */
  public toString(): string {
    return `VisibleRegion{` +
      `nearLeft=${this.nearLeft.latitude},${this.nearLeft.longitude}, ` +
      `nearRight=${this.nearRight.latitude},${this.nearRight.longitude}, ` +
      `farLeft=${this.farLeft.latitude},${this.farLeft.longitude}, ` +
      `farRight=${this.farRight.latitude},${this.farRight.longitude}, ` +
      `bounds=${this.latLngBounds.toString()}}`;
  }

  /**
   * 判断两个可见区域是否相等
   */
  public equals(other: VisibleRegion): boolean {
    if (!other) {
      return false;
    }

    return this.nearLeft.latitude === other.nearLeft.latitude &&
      this.nearLeft.longitude === other.nearLeft.longitude &&
      this.nearRight.latitude === other.nearRight.latitude &&
      this.nearRight.longitude === other.nearRight.longitude &&
      this.farLeft.latitude === other.farLeft.latitude &&
      this.farLeft.longitude === other.farLeft.longitude &&
      this.farRight.latitude === other.farRight.latitude &&
      this.farRight.longitude === other.farRight.longitude;
  }
}

