import maplibre from 'libmaplibre.so';

// Use the NAPI Marker type
import { Marker } from '../annotations/Marker';

/**
 * OnInfoWindowClickListener - InfoWindow click listener.
 *
 * Triggered when the user taps a marker's InfoWindow.
 *
 * Reference:
 * - Android: MapLibreMap.OnInfoWindowClickListener
 */
export interface OnInfoWindowClickListener {
  /**
   * Called when the InfoWindow is tapped.
   *
   * @param marker Marker owning the InfoWindow.
   */
  onInfoWindowClick(marker: Marker): void;
}


