import maplibre from 'libmaplibre.so';
// import { ComponentContent } from '@kit.ArkUI';

import { Marker } from './Marker';

/**
 * AnnotationViewAdapter - 自定义 Annotation 视图适配器
 * 
 * 允许为不同的 Marker 提供自定义视图
 * 
 * 参考:
 * - iOS: mapView:viewForAnnotation:
 * - Android: 自定义布局 inflation
 * 
 * 使用示例:
 * ```typescript
 * class MyAnnotationViewAdapter implements AnnotationViewAdapter {
 *   getAnnotationView(marker: Marker): ComponentContent<Object> | null {
 *     if (marker.getTitle() === 'Custom') {
 *       return new ComponentContent(
 *         getContext(),
 *         wrapBuilder(CustomMarkerBuilder),
 *         { marker: marker }
 *       );
 *     }
 *     return null;  // 使用默认图标
 *   }
 *   
 *   getReuseIdentifier(marker: Marker): string {
 *     return marker.getIcon() || 'default';
 *   }
 * }
 * 
 * mapLibreMap.setAnnotationViewAdapter(new MyAnnotationViewAdapter());
 * ```
 */
export interface AnnotationViewAdapter {
  /**
   * 为 Marker 创建自定义视图
   * 
   * @param marker 要显示的 Marker
   * @returns 自定义视图组件内容，返回 null 使用默认图标
   */
  getAnnotationView(marker: Marker): object | null;
  
  /**
   * 获取视图复用标识符（可选，用于性能优化）
   * 
   * 具有相同标识符的视图可以被复用，减少视图创建开销
   * 
   * @param marker 要显示的 Marker
   * @returns 复用标识符，默认使用 marker.getIcon()
   */
  getReuseIdentifier?(marker: Marker): string;
}

