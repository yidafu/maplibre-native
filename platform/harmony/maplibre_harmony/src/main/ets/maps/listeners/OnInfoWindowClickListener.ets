import maplibre from 'libmaplibre_native.so';

// 使用 NAPI Marker 类型
type Marker = maplibre.Marker;

/**
 * OnInfoWindowClickListener - InfoWindow 点击事件监听器
 * 
 * 当用户点击 Marker 的 InfoWindow 时触发
 * 
 * 参考:
 * - Android: MapLibreMap.OnInfoWindowClickListener
 */
export interface OnInfoWindowClickListener {
  /**
   * InfoWindow 被点击时调用
   * 
   * @param marker InfoWindow 所属的 Marker
   */
  onInfoWindowClick(marker: Marker): void;
}


