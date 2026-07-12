import type { Marker } from './Marker';
import type { ComponentContent } from '@kit.ArkUI';

/**
 * InfoWindowAdapter - InfoWindow adapter interface.
 *
 * Allows developers to provide custom InfoWindow content via ComponentContent.
 * Each call to getInfoWindow() receives the marker and a UIContext,
 * and may return a ComponentContent containing any ArkUI component tree.
 *
 * Return null to use the default InfoWindow style.
 *
 * References:
 * - Android: MapLibreMap.InfoWindowAdapter
 *
 * @example
 * ```typescript
 * // Fully dynamic InfoWindow via ComponentContent
 * mapLibreMap.setInfoWindowAdapter({
 *   getInfoWindow: (marker: Marker, uiContext: UIContext): ComponentContent | null => {
 *     const content = new ComponentContent(uiContext);
 *     content.update(() => {
 *       Column() {
 *         Text(marker.getTitle()).fontSize(16).fontWeight(Bold)
 *         Text(marker.getSnippet()).fontSize(14).fontColor('#666')
 *         Button('详情').onClick(() => navigateToDetail(marker))
 *       }
 *       .padding(12).backgroundColor(Color.White).borderRadius(8)
 *     });
 *     return content;
 *   }
 * });
 *
 * // Using pre-defined @Builder via ComponentContent wrapper
 * const HOTEL_BUILDER = wrapBuilder(hotelInfoWindowBuilder);
 *
 * mapLibreMap.setInfoWindowAdapter({
 *   getInfoWindow: (marker: Marker, uiContext: UIContext): ComponentContent | null => {
 *     const ctx = new InfoWindowBuilderContext(/* ... *​/);
 *     const content = new ComponentContent(uiContext);
 *     content.update(() => {
 *       HOTEL_BUILDER.builder(ctx);
 *     });
 *     return content;
 *   }
 * });
 * ```
 */
export interface InfoWindowAdapter {
  /**
   * Create a custom InfoWindow ComponentContent for the provided marker.
   *
   * Use the provided UIContext to create a new ComponentContent instance
   * and populate it with any ArkUI component tree via content.update().
   *
   * @param marker   Marker instance.
   * @param uiContext UIContext required to create ComponentContent instances.
   * @returns A ComponentContent with the desired InfoWindow UI, or null to use the default.
   */
  getInfoWindow(marker: Marker, uiContext: UIContext): ComponentContent<Object> | null;
}
