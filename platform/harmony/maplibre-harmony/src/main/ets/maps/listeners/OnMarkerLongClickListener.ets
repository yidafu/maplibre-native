import { Marker } from '../annotations/Marker';

/**
 * OnMarkerLongClickListener - marker long-press listener.
 *
 * Triggered when the user long-presses a marker on the map.
 *
 * Reference:
 * - Android: similar to `View.OnLongClickListener`.
 * - iOS: `UILongPressGestureRecognizer`.
 */
export interface OnMarkerLongClickListener {
  /**
   * Called when a marker is long-pressed.
   *
   * @param marker The pressed marker.
   * @returns true to consume the event; false to propagate.
   */
  onMarkerLongClick(marker: Marker): boolean;
}

