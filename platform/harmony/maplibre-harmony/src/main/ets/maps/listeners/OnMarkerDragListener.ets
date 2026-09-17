
// Use the NAPI Marker type
import { Marker } from '../annotations/Marker';

/**
 * OnMarkerDragListener - marker drag listener.
 *
 * Triggered when the user drags a marker.
 *
 * Reference:
 * - iOS: `MLNAnnotationView` drag state changes.
 * - Android: `DraggableSymbolsManager`.
 */
export interface OnMarkerDragListener {
  /**
   * Called when marker dragging begins.
   *
   * @param marker Marker currently being dragged.
   */
  onMarkerDragStart(marker: Marker): void;

  /**
   * Called repeatedly while the marker is being dragged.
   *
   * @param marker Marker currently being dragged.
   */
  onMarkerDrag(marker: Marker): void;

  /**
   * Called when marker dragging ends.
   *
   * @param marker Marker that finished dragging.
   */
  onMarkerDragEnd(marker: Marker): void;
}


