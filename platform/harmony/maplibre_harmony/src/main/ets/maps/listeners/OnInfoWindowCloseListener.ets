import maplibre from 'libmaplibre.so';

// 使用 NAPI Marker 类型
import { Marker } from '../annotations/Marker';

/**
 * OnInfoWindowCloseListener - InfoWindow 关闭事件监听器
 * 
 * 当 Marker 的 InfoWindow 关闭时触发
 * 
 * 参考:
 * - Android: MapLibreMap.OnInfoWindowCloseListener
 */
export interface OnInfoWindowCloseListener {
  /**
   * InfoWindow 关闭时调用
   * 
   * @param marker InfoWindow 所属的 Marker
   */
  onInfoWindowClose(marker: Marker): void;
}

