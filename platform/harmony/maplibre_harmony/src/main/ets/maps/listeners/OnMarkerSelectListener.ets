import maplibre from 'libmaplibre.so';

// 使用 NAPI Marker 类型
import { Marker } from '../annotations/Marker';

/**
 * OnMarkerSelectListener - Marker 选中状态变化监听器
 *
 * 当 Marker 被选中或取消选中时触发
 *
 * 参考:
 * - Android: 类似功能通过 OnMarkerClickListener 实现
 * - iOS: mapView:didSelectAnnotation: 和 mapView:didDeselectAnnotation:
 */
export interface OnMarkerSelectListener {
  /**
   * Marker 被选中时调用
   *
   * @param marker 被选中的 Marker
   */
  onMarkerSelect(marker: Marker): void;

  /**
   * Marker 被取消选中时调用
   *
   * @param marker 被取消选中的 Marker
   */
  onMarkerDeselect(marker: Marker): void;
}

