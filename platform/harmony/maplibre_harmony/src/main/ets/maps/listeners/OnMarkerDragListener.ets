import maplibre from 'libmaplibre_native.so';

// 使用 NAPI Marker 类型
type Marker = maplibre.Marker;

/**
 * OnMarkerDragListener - Marker 拖拽事件监听器
 * 
 * 当用户拖拽 Marker 时触发
 * 
 * 参考:
 * - iOS: MLNAnnotationView drag state changes
 * - Android: DraggableSymbolsManager
 */
export interface OnMarkerDragListener {
  /**
   * Marker 开始拖拽时调用
   * 
   * @param marker 正在被拖拽的 Marker
   */
  onMarkerDragStart(marker: Marker): void;
  
  /**
   * Marker 拖拽过程中持续调用
   * 
   * @param marker 正在被拖拽的 Marker
   */
  onMarkerDrag(marker: Marker): void;
  
  /**
   * Marker 拖拽结束时调用
   * 
   * @param marker 完成拖拽的 Marker
   */
  onMarkerDragEnd(marker: Marker): void;
}


