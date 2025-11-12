/**
 * Listener for camera tracking state changes.
 */
export interface OnCameraTrackingChangedListener {
  /**
   * Invoked when the camera tracking mode changes.
   * @param currentMode Current camera mode.
   */
  onCameraTrackingChanged(currentMode: number): void;

  /**
   * Invoked when user gestures dismiss camera tracking.
   */
  onCameraTrackingDismissed?(): void;
}

