/**
 * CompassVisibility - compass visibility modes.
 *
 * Mirrors iOS MLNOrnamentVisibility.
 */
export enum CompassVisibility {
  /**
   * Adaptive mode: show when the map is not facing north, hide when it is.
   */
  Adaptive = 0,

  /**
   * Always visible.
   */
  Visible = 1,

  /**
   * Always hidden.
   */
  Hidden = 2
}

