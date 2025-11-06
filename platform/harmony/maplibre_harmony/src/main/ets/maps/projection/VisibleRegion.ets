/**
 * VisibleRegion - 地图可见区域
 *
 * 表示地图当前视口的可见区域，包含屏幕四个角对应的地理坐标和边界。
 * 
 * **平台对照**：
 * - Android: `VisibleRegion` 类
 * - iOS: `visibleCoordinateBounds` 属性
 * 
 * **坐标系统**：
 * - topLeft: 屏幕左上角（远左角）
 * - topRight: 屏幕右上角（远右角）
 * - bottomLeft: 屏幕左下角（近左角）
 * - bottomRight: 屏幕右下角（近右角）
 * 
 * @example
 * ```typescript
 * const projection = map.getProjection();
 * const visibleRegion = projection.getVisibleRegion();
 * console.log('可见区域左上角:', visibleRegion.topLeft);
 * console.log('可见边界:', visibleRegion.latLngBounds);
 * ```
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
   * 屏幕左上角的地理坐标（远左角）
   * 对应 Android: topLeft
   */
  public readonly topLeft: LatLng;
  
  /**
   * 屏幕右上角的地理坐标（远右角）
   * 对应 Android: topRight
   */
  public readonly topRight: LatLng;
  
  /**
   * 屏幕左下角的地理坐标（近左角）
   * 对应 Android: bottomLeft
   */
  public readonly bottomLeft: LatLng;
  
  /**
   * 屏幕右下角的地理坐标（近右角）
   * 对应 Android: bottomRight
   */
  public readonly bottomRight: LatLng;
  
  /**
   * 包含整个可见区域的最小边界
   * 对应 Android: latLngBounds
   */
  public readonly latLngBounds: LatLngBounds;

  // 兼容旧命名（向后兼容）
  /**
   * @deprecated 使用 bottomLeft 替代
   */
  public get nearLeft(): LatLng { return this.bottomLeft; }
  
  /**
   * @deprecated 使用 bottomRight 替代
   */
  public get nearRight(): LatLng { return this.bottomRight; }
  
  /**
   * @deprecated 使用 topLeft 替代
   */
  public get farLeft(): LatLng { return this.topLeft; }
  
  /**
   * @deprecated 使用 topRight 替代
   */
  public get farRight(): LatLng { return this.topRight; }

  /**
   * 构造函数（Android 风格命名）
   *
   * @param topLeft 屏幕左上角坐标
   * @param topRight 屏幕右上角坐标
   * @param bottomLeft 屏幕左下角坐标
   * @param bottomRight 屏幕右下角坐标
   * @param latLngBounds 边界对象
   */
  constructor(
    topLeft: LatLng,
    topRight: LatLng,
    bottomLeft: LatLng,
    bottomRight: LatLng,
    latLngBounds: LatLngBounds
  ) {
    this.topLeft = topLeft;
    this.topRight = topRight;
    this.bottomLeft = bottomLeft;
    this.bottomRight = bottomRight;
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
   * 获取可见区域的四个角点坐标数组
   * 对应 Android API
   * 
   * @returns 按 [topLeft, topRight, bottomRight, bottomLeft] 顺序排列的角点数组
   */
  public getCorners(): LatLng[] {
    return [this.topLeft, this.topRight, this.bottomRight, this.bottomLeft];
  }

  /**
   * 获取可见区域的中心点坐标
   * 
   * @returns 可见区域的中心点地理坐标
   */
  public getCenter(): LatLng {
    return this.latLngBounds.getCenter();
  }

  /**
   * 转换为字符串表示
   */
  public toString(): string {
    return `VisibleRegion{` +
      `topLeft=${this.topLeft.latitude},${this.topLeft.longitude}, ` +
      `topRight=${this.topRight.latitude},${this.topRight.longitude}, ` +
      `bottomLeft=${this.bottomLeft.latitude},${this.bottomLeft.longitude}, ` +
      `bottomRight=${this.bottomRight.latitude},${this.bottomRight.longitude}, ` +
      `bounds=${this.latLngBounds.toString()}}`;
  }

  /**
   * 判断两个可见区域是否相等
   */
  public equals(other: VisibleRegion): boolean {
    if (!other) {
      return false;
    }

    return this.topLeft.latitude === other.topLeft.latitude &&
      this.topLeft.longitude === other.topLeft.longitude &&
      this.topRight.latitude === other.topRight.latitude &&
      this.topRight.longitude === other.topRight.longitude &&
      this.bottomLeft.latitude === other.bottomLeft.latitude &&
      this.bottomLeft.longitude === other.bottomLeft.longitude &&
      this.bottomRight.latitude === other.bottomRight.latitude &&
      this.bottomRight.longitude === other.bottomRight.longitude;
  }
}

