import maplibre from 'libmaplibre.so';

// Use the NAPI Marker type
import { Marker } from '../annotations/Marker';

/**
 * OnMarkerSelectListener - marker selection listener.
 *
 * Triggered when a marker is selected or deselected.
 *
 * Reference:
 * - Android: similar behavior via OnMarkerClickListener.
 * - iOS: `mapView:didSelectAnnotation:` and `mapView:didDeselectAnnotation:`.
 */
export interface OnMarkerSelectListener {
  /**
   * Called when a marker is selected.
   *
   * @param marker Selected marker.
   */
  onMarkerSelect(marker: Marker): void;

  /**
   * Called when a marker is deselected.
   *
   * @param marker Deselected marker.
   */
  onMarkerDeselect(marker: Marker): void;
}

