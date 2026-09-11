
// Use the NAPI Marker type
import { Marker } from '../annotations/Marker';

/**
 * OnMarkerClickListener - marker tap listener.
 *
 * Triggered when the user taps a marker on the map.
 *
 * Reference:
 * - Android: MapLibreMap.OnMarkerClickListener.
 * - iOS: `MLNMapViewDelegate didSelectAnnotation`.
 */
export interface OnMarkerClickListener {
  /**
   * Called when a marker is tapped.
   *
   * @param marker The tapped marker.
   * @returns true to consume the event; false to propagate.
   */
  onMarkerClick(marker: Marker): boolean;
}

