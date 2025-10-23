import { Marker } from './Marker';
import { ComponentContent } from '@kit.ArkUI';

/**
 * InfoWindowAdapter - InfoWindow 适配器接口
 * 
 * 允许开发者自定义 InfoWindow 的显示内容
 * 
 * 参考:
 * - Android: MapLibreMap.InfoWindowAdapter
 * 
 * @example
 * ```typescript
 * mapLibreMap.setInfoWindowAdapter({
 *   getInfoWindow: (marker: Marker) => {
 *     // 返回自定义视图
 *     return new ComponentContent(uiContext, wrapBuilder(CustomInfoWindowBuilder), marker);
 *   }
 * });
 * ```
 */
export interface InfoWindowAdapter {
  /**
   * 为指定的 Marker 创建自定义 InfoWindow 视图
   * 
   * @param marker Marker 实例
   * @returns 自定义视图组件，如果返回 null 则使用默认 InfoWindow
   */
  getInfoWindow(marker: Marker): ComponentContent<Object> | null;
}


