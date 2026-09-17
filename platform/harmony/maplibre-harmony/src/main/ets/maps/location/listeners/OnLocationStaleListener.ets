/**
 * Listener for stale location state changes.
 */
export interface OnLocationStaleListener {
  /**
   * Invoked when the location becomes stale.
   * @param isStale Whether the location is stale.
   */
  onStaleStateChange(isStale: boolean): void;
}

