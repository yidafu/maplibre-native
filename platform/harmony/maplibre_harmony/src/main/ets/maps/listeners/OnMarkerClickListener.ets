
// 使用 NAPI Marker 类型
import { Marker } from '../annotations/Marker';

/**
 * OnMarkerClickListener - Marker 点击事件监听器
 *
 * 当用户点击地图上的 Marker 时触发
 *
 * 参考:
 * - Android: MapLibreMap.OnMarkerClickListener
 * - iOS: MLNMapViewDelegate didSelectAnnotation
 */
export interface OnMarkerClickListener {
  /**
   * Marker 被点击时调用
   *
   * @param marker 被点击的 Marker
   * @returns true 表示事件已被消费，不再传播；false 表示事件继续传播
   */
  onMarkerClick(marker: Marker): boolean;
}


