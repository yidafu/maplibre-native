import { Style } from '../style/Style';

/**
 * OnStyleLoadedListener - style load completion listener.
 *
 * Triggered when the map style has finished loading; safe to manipulate style resources afterwards.
 */
export interface OnStyleLoadedListener {
  /**
   * Callback invoked once the style is loaded.
   *
   * @param style Loaded style object (may be null if working directly with NativeMapView).
   */
  onStyleLoaded(style: Style | null): void;
}


