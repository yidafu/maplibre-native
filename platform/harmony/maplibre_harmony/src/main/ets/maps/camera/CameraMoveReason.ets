/**
 * CameraMoveReason - enumerates reasons the camera moves.
 */

/**
 * Reasons for camera movement.
 */
export enum CameraMoveReason {
  /**
   * Unknown reason.
   */
  UNKNOWN = 0,

  /**
   * User gesture (pan, zoom, rotate, etc.).
   */
  GESTURE = 1,

  /**
   * API invocation (e.g. `jumpTo`, `setCenter`).
   */
  API_ANIMATION = 2,

  /**
   * Developer-provided animation (`easeTo`, `flyTo`).
   */
  DEVELOPER_ANIMATION = 3,

  /**
   * Animation cancelled.
   */
  ANIMATION_CANCELLED = 4
}

/**
 * Get a human-readable description of the camera move reason.
 */
export function getCameraMoveReasonText(reason: CameraMoveReason): string {
  switch (reason) {
    case CameraMoveReason.GESTURE:
      return 'Gesture';
    case CameraMoveReason.API_ANIMATION:
      return 'API animation';
    case CameraMoveReason.DEVELOPER_ANIMATION:
      return 'Developer animation';
    case CameraMoveReason.ANIMATION_CANCELLED:
      return 'Animation cancelled';
    default:
      return 'Unknown';
  }
}

