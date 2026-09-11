/**
 * CameraAnimationCallback - camera animation callback interface.
 *
 * Listens for camera animation completion or cancellation events.
 * Mirrors Android's `CancelableCallback` and the iOS completion handler.
 */

/**
 * Camera animation callback interface.
 */
export interface CameraAnimationCallback {
  /**
   * Invoked when the animation finishes.
   */
  onFinish(): void;

  /**
   * Invoked when the animation is cancelled (optional).
   */
  onCancel?(): void;
}

/**
 * Simplified completion callback type.
 */
export type OnFinishCallback = () => void;

/**
 * Animation options interface (for future extensions).
 */
export interface AnimationOptions {
  /**
   * Animation duration (milliseconds).
   */
  duration: number;

  /**
   * Completion callback (optional).
   */
  callback?: CameraAnimationCallback;
}

