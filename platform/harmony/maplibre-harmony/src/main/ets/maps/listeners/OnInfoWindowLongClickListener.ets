import maplibre from 'libmaplibre.so';

// Use the NAPI Marker type
import { Marker } from '../annotations/Marker';

/**
 * OnInfoWindowLongClickListener - InfoWindow long-press listener.
 *
 * Triggered when the user long-presses a marker's InfoWindow.
 *
 * Reference:
 * - Android: MapLibreMap.OnInfoWindowLongClickListener
 */
export interface OnInfoWindowLongClickListener {
  /**
   * Called when the InfoWindow is long-pressed.
   *
   * @param marker Marker that owns the InfoWindow.
   */
  onInfoWindowLongClick(marker: Marker): void;
}


