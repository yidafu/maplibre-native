/**
 * Listener for render mode changes.
 */
export interface OnRenderModeChangedListener {
  /**
   * Invoked when the render mode changes.
   * @param currentMode Current render mode.
   */
  onRenderModeChanged(currentMode: number): void;
}

