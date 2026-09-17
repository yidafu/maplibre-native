import maplibre from 'libmaplibre.so';

// Use the NAPI Marker type
import { Marker } from '../annotations/Marker';

/**
 * OnInfoWindowCloseListener - InfoWindow close listener.
 *
 * Triggered when a marker's InfoWindow closes.
 *
 * Reference:
 * - Android: MapLibreMap.OnInfoWindowCloseListener
 */
export interface OnInfoWindowCloseListener {
  /**
   * Called when the InfoWindow closes.
   *
   * @param marker Marker owning the InfoWindow.
   */
  onInfoWindowClose(marker: Marker): void;
}

