import maplibre from 'libmaplibre_native.so';

// 使用 NAPI Marker 类型
type Marker = maplibre.Marker;

/**
 * OnInfoWindowLongClickListener - InfoWindow 长按事件监听器
 * 
 * 当用户长按 Marker 的 InfoWindow 时触发
 * 
 * 参考:
 * - Android: MapLibreMap.OnInfoWindowLongClickListener
 */
export interface OnInfoWindowLongClickListener {
  /**
   * InfoWindow 被长按时调用
   * 
   * @param marker InfoWindow 所属的 Marker
   */
  onInfoWindowLongClick(marker: Marker): void;
}


