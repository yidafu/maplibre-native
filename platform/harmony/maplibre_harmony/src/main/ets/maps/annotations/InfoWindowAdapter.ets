import maplibre from 'libmaplibre.so';
// import { ComponentContent } from '@kit.ArkUI';

// Use the NAPI marker type
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
 *   getInfoWindow: (marker: Marker) => {
 *     // Return a custom view
 *     return new ComponentContent(uiContext, wrapBuilder(CustomInfoWindowBuilder), marker);
 *   }
 * });
 * ```
 */
export interface InfoWindowAdapter {
  /**
   * Create a custom InfoWindow view for the provided marker.
   *
   * @param marker Marker instance.
   * @returns Custom view component; return null to use the default InfoWindow.
   */
  getInfoWindow(marker: Marker): object | null;
}


