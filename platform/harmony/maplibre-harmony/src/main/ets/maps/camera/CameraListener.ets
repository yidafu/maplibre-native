/**
 * CameraListener - camera listener interfaces.
 *
 * Observe various map camera state changes.
 */

import { CameraMoveReason } from './CameraMoveReason';

/**
 * Listener for when the camera becomes idle.
 * Triggered after all animations and gestures complete.
 */
export interface OnCameraIdleListener {
  /**
   * Called when the camera stops moving.
   */
  onCameraIdle(): void;
}

/**
 * Listener for when the camera starts moving.
 * Triggered as soon as movement begins.
 */
export interface OnCameraMoveStartedListener {
  /**
   * Called when the movement begins.
   * @param reason Reason for camera movement.
   */
  onCameraMoveStarted(reason: CameraMoveReason): void;
}

/**
 * Listener for intermediate camera movement.
 * Invoked repeatedly while the camera is moving.
 */
export interface OnCameraMoveListener {
  /**
   * Called while the camera is in motion.
   */
  onCameraMove(): void;
}

/**
 * Listener for when camera movement is cancelled.
 * Triggered when animations are interrupted or cancelled.
 */
export interface OnCameraMoveCanceledListener {
  /**
   * Called when camera movement is cancelled.
   */
  onCameraMoveCanceled(): void;
}

/**
 * Listener for animation completion.
 * Triggered when `flyTo` or `easeTo` completes.
 */
export interface OnAnimationFinishedListener {
  /**
   * Called when the animation finishes.
   */
  onAnimationFinished(): void;
}

/**
 * Composite camera listener.
 * Includes callbacks for all camera events.
 */
export interface CameraChangeListener {
  /**
   * Called when the camera starts moving.
   */
  onCameraMoveStarted?(reason: CameraMoveReason): void;

  /**
   * Called while the camera is moving.
   */
  onCameraMove?(): void;

  /**
   * Called when the camera stops moving.
   */
  onCameraIdle?(): void;

  /**
   * Called when camera movement is cancelled.
   */
  onCameraMoveCanceled?(): void;
}

