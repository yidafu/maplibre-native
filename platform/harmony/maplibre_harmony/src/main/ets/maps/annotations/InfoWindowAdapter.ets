import { Marker } from './Marker';

/**
 * InfoWindowAdapter - InfoWindow adapter interface.
 *
 * Allows developers to provide custom InfoWindow content.
 *
 * References:
 * - Android: MapLibreMap.InfoWindowAdapter
 *
 * @example
 * ```typescript
 * mapLibreMap.setInfoWindowAdapter({
 *   getInfoWindow: (marker: Marker) => () => {
 *     Column() {
 *       Text(marker.getTitle())
 *         .fontSize(16)
 *         .fontColor(Color.White)
 *     }
 *     .padding(12)
 *     .backgroundColor('#6200EE')
 *     .borderRadius(8)
 *   }
 * });
 * ```
 * ```
 */
export interface InfoWindowAdapter {
  /**
   * Create a custom InfoWindow builder for the provided marker.
   *
   * @param marker Marker instance.
   * @returns ArkUI builder; return null to use the default InfoWindow.
   */
  getInfoWindow(marker: Marker): (() => void) | null;
}
