/**
 * OnStyleLoadErrorListener - style load failure listener.
 *
 * Triggered when the map style fails to load.
 */
export interface OnStyleLoadErrorListener {
  /**
   * Callback invoked upon style load failure.
   *
   * @param error Error description.
   */
  onStyleLoadError(error: string): void;
}

