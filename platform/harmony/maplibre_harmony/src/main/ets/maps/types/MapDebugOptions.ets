/**
 * Debug options for MapLibre map rendering.
 * 
 * These options enable various debugging visualizations to help diagnose
 * rendering issues, tile loading problems, and performance bottlenecks.
 * 
 * Debug options should be disabled in production builds as they impact
 * performance and are intended for development use only.
 * 
 * @example
 * ```typescript
 * // Enable tile boundaries and collision boxes
 * map.setDebugOptions(MapDebugOptions.TileBoundaries | MapDebugOptions.CollisionBoxes);
 * 
 * // Quick toggle with default debug options
 * map.setDebugActive(true);
 * ```
 */
export enum MapDebugOptions {
  /**
   * No debug options enabled.
   */
  NoDebug = 0,

  /**
   * Show tile boundaries as thick red lines.
   * Helps diagnose tile clipping and loading issues.
   */
  TileBoundaries = 1 << 1,

  /**
   * Show tile coordinates (x/y/z) in the upper-left corner of each tile.
   * Helps identify which tiles are being loaded.
   */
  TileInfo = 1 << 2,

  /**
   * Show timestamp indicating when each tile was loaded.
   * Helps diagnose tile caching and refresh issues.
   */
  Timestamps = 1 << 3,

  /**
   * Show collision boxes as faint green lines around glyphs and symbols.
   * Helps diagnose label placement and collision detection issues.
   */
  CollisionBoxes = 1 << 4,

  /**
   * Show overdraw visualization with translucent fills.
   * Overlapping drawing operations appear more prominent.
   * Helps diagnose rendering performance issues.
   * 
   * Note: This option may have limited effect in release builds.
   */
  OverdrawVisualization = 1 << 5,

  /**
   * Show stencil buffer instead of color buffer.
   * For advanced rendering diagnostics.
   * 
   * Note: This option may have limited effect in release builds.
   */
  StencilClip = 1 << 6,

  /**
   * Show depth buffer instead of color buffer.
   * For advanced rendering diagnostics.
   * 
   * Note: This option may have limited effect in release builds.
   */
  DepthBuffer = 1 << 7
}

