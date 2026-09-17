/**
 * NativeTypes - native type exports and helper types.
 *
 * 1. Expose the NAPI-provided maplibre namespace.
 * 2. Provide helper type definitions (for test pages and app development).
 */

import maplibre from 'libmaplibre.so';

// Do not export maplibre directly; native methods must be proxied in ETS (or re-exported).

// ========== Helper type definitions ==========

/**
 * Latitude/longitude interface (coordinate type).
 *
 * Represents geographic coordinates and supports object literals and LatLng instances.
 *
 * @example
 * ```typescript
 * const position: ILatLng = { latitude: 39.9, longitude: 116.4 };
 * const latLng = new LatLng(position.latitude, position.longitude);
 * ```
 */
export type ILatLng = maplibre.LatLng;

/**
 * Rectangle literal interface.
 *
 * Represents a screen rectangle in screen pixel coordinates.
 */
export interface RectangleLiteral {
  left: number;
  top: number;
  right: number;
  bottom: number;
}

/**
 * Size interface.
 *
 * Represents width and height in pixels.
 *
 * @example
 * ```typescript
 * const mapSize: Size = { width: 800, height: 600 };
 * ```
 */
export interface Size {
  width: number;
  height: number;
}

/**
 * Padding interface.
 *
 * Represents inner spacing on four sides in pixels (vp) and configures UI component offsets relative to the container.
 *
 * @example
 * ```typescript
 * const padding: Padding = { top: 10, left: 10, bottom: 10, right: 10 };
 * ```
 */
export interface Padding {
  top: number;
  left: number;
  bottom: number;
  right: number;
}

/**
 * Margins interface (alias).
 *
 * Provides a more semantic name for the same structure as Padding.
 * Used to configure margins for UI components (Compass, Logo, ScaleBar, Attribution).
 */
export type Margins = Padding;

/**
 * Create a Margins object from an array.
 *
 * @param arr Margin array [left, top, right, bottom].
 * @returns Margins object.
 *
 * @example
 * ```typescript
 * const margins = createMargins([10, 20, 10, 20]);
 * // { left: 10, top: 20, right: 10, bottom: 20 }
 * ```
 */
export function createMargins(arr: number[]): Margins {
  return {
    left: arr[0] || 0,
    top: arr[1] || 0,
    right: arr[2] || 0,
    bottom: arr[3] || 0
  };
}

/**
 * Create a uniform Margins object from a single value.
 *
 * @param value Uniform margin value.
 * @returns Margins object.
 *
 * @example
 * ```typescript
 * const margins = createUniformMargins(10);
 * // { left: 10, top: 10, right: 10, bottom: 10 }
 * ```
 */
export function createUniformMargins(value: number): Margins {
  return {
    left: value,
    top: value,
    right: value,
    bottom: value
  };
}

/**
 * Merge two Margins objects (the second overrides the first).
 *
 * @param base Base Margins.
 * @param override Overriding Margins (only non-undefined values overwrite).
 * @returns Merged Margins object.
 */
export function mergeMargins(base: Margins, override: Partial<Margins>): Margins {
  return {
    left: override.left !== undefined ? override.left : base.left,
    top: override.top !== undefined ? override.top : base.top,
    right: override.right !== undefined ? override.right : base.right,
    bottom: override.bottom !== undefined ? override.bottom : base.bottom
  };
}

/**
 * Camera options literal interface (used for test pages).
 */
export interface CameraOptionsLiteral {
  center?: ILatLng;
  zoom?: number;
  bearing?: number;
  pitch?: number;
  padding?: Padding;
}

// ========== Merged type definitions from types.ets ==========

/**
 * Ornament position enum (aligned with Android MLNOrnamentPosition and iOS MLNOrnamentPosition).
 * Configures positions for UI components such as Compass, Logo, ScaleBar, and Attribution.
 */
export enum OrnamentPosition {
  /** Positioned at the top-left of the map. */
  TopLeft = 0,
  /** Positioned at the top-right of the map. */
  TopRight = 1,
  /** Positioned at the bottom-left of the map. */
  BottomLeft = 2,
  /** Positioned at the bottom-right of the map. */
  BottomRight = 3
}


/**
 * Rendering refresh mode (aligned with Android MapRenderer.RenderingRefreshMode).
 */
export enum RenderingRefreshMode {
  /** Continuous rendering mode - renders every frame, suited for animations. */
  CONTINUOUS = 0,
  /** On-demand rendering mode - renders only when needed to save performance. */
  WHEN_DIRTY = 1
}

/**
 * Tile operation enum (aligned with Android TileOperation).
 */
export enum TileOperation {
  /** Tile added. */
  Added = 0,
  /** Tile updated. */
  Updated = 1,
  /** Tile removed. */
  Removed = 2
}

/**
 * XComponent 渲染表面类型（对齐 Android MapLibreMapOptions.textureMode 的两种模式）。
 * - 'surface'：XComponentType.SURFACE，独占图层直接上屏，性能最优；
 * - 'texture'：XComponentType.TEXTURE，参与 ArkUI 合成树，支持 transform/特效叠加。
 * 模式在组件构造时确定，创建后不可切换，如需切换必须重建 MapView。
 */
export type MapSurfaceType = 'surface' | 'texture';

/**
 * User location tracking mode (aligned with iOS MLNUserTrackingMode).
 */
export enum UserTrackingMode {
  /** Do not track user location. */
  None = 0,
  /** Follow user location; exit when the user pans the map. */
  Follow = 1,
  /** Follow user location and heading (compass direction); revert to Follow when the user rotates the map. */
  FollowWithHeading = 2,
  /** Follow user location and course (movement direction); revert to Follow when the user rotates the map. */
  FollowWithCourse = 3
}


