import { Marker } from '../annotations/Marker';

/**
 * OnMarkerLongClickListener - Marker 长按事件监听器
 * 
 * 当用户长按地图上的 Marker 时触发
 * 
 * 参考:
 * - Android: 类似 View.OnLongClickListener 的模式
 * - iOS: UILongPressGestureRecognizer
 */
export interface OnMarkerLongClickListener {
  /**
   * Marker 被长按时调用
   * 
   * @param marker 被长按的 Marker
   * @returns true 表示事件已被消费，不再传播；false 表示事件继续传播
   */
  onMarkerLongClick(marker: Marker): boolean;
}

