/**
 * MarkerDragState - marker drag state enumeration.
 *
 * Represents the current drag state of a marker.
 *
 * Reference:
 * - iOS: MLNAnnotationViewDragState
 */
export enum MarkerDragState {
  /**
   * Not participating in a drag operation.
   */
  None = 0,

  /**
   * Drag starting.
   * Triggered after a long-press when dragging is about to begin.
   */
  Starting = 1,

  /**
   * Drag in progress.
   * The marker is moving with the user gesture.
   */
  Dragging = 2,

  /**
   * Drag canceled.
   * The drag operation was aborted.
   */
  Canceling = 3,

  /**
   * Drag ended.
   * The user lifted their finger and completed the drag.
   */
  Ending = 4
}


