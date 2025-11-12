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

/**
 * Concrete implementation of CameraAnimationCallback.
 * Helps avoid type mismatches when using object literals.
 */
export class CameraAnimationCallbackImpl implements CameraAnimationCallback {
  private finishFn: () => void;
  private cancelFn?: () => void;

  constructor(onFinish: () => void, onCancel?: () => void) {
    this.finishFn = onFinish;
    this.cancelFn = onCancel;
  }

  onFinish(): void {
    this.finishFn();
  }

  onCancel(): void {
    if (this.cancelFn) {
      this.cancelFn();
    }
  }
}

/**
 * Factory helper to create CameraAnimationCallback instances.
 */
export function createAnimationCallback(
  onFinish: () => void,
  onCancel?: () => void
): CameraAnimationCallback {
  return new CameraAnimationCallbackImpl(onFinish, onCancel);
}

