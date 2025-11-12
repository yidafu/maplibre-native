/**
 * Map event listener interface definitions
 * Mirrors the listener interfaces provided by Android MapView
 */

import type {
  OnCameraWillChangeListener as OnCameraWillChangeListenerNAPI,
  OnCameraIsChangingListener as OnCameraIsChangingListenerNAPI,
  OnCameraDidChangeListener as OnCameraDidChangeListenerNAPI,
  OnWillStartLoadingMapListener as OnWillStartLoadingMapListenerNAPI,
  OnDidFinishLoadingMapListener as OnDidFinishLoadingMapListenerNAPI,
  OnDidFailLoadingMapListener as OnDidFailLoadingMapListenerNAPI,
  OnWillStartRenderingFrameListener as OnWillStartRenderingFrameListenerNAPI,
  OnDidFinishRenderingFrameListener as OnDidFinishRenderingFrameListenerNAPI,
  OnDidFinishRenderingFrameWithStatsListener as OnDidFinishRenderingFrameWithStatsListenerNAPI,
  OnWillStartRenderingMapListener as OnWillStartRenderingMapListenerNAPI,
  OnDidFinishRenderingMapListener as OnDidFinishRenderingMapListenerNAPI,
  OnDidFinishLoadingStyleListener as OnDidFinishLoadingStyleListenerNAPI,
  OnCanRemoveUnusedStyleImageListener as OnCanRemoveUnusedStyleImageListenerNAPI,
  OnDidBecomeIdleListener as OnDidBecomeIdleListenerNAPI,
  OnSourceChangedListener as OnSourceChangedListenerNAPI,
  RenderingStats as RenderingStatsNAPI
} from 'libmaplibre.so';
import type { MapLibreMap } from '../MapLibreMap';
import type { TileOperation } from '../types/NativeTypes';

// ========== Camera event listeners ==========

/** Camera-will-change listener */
export type OnCameraWillChangeListener = OnCameraWillChangeListenerNAPI;

/** Camera-is-changing listener */
export type OnCameraIsChangingListener = OnCameraIsChangingListenerNAPI;

/** Camera-did-change listener */
export type OnCameraDidChangeListener = OnCameraDidChangeListenerNAPI;

// ========== Map loading listeners ==========

/** Map-will-start-loading listener */
export type OnWillStartLoadingMapListener = OnWillStartLoadingMapListenerNAPI;

/** Map-did-finish-loading listener */
export type OnDidFinishLoadingMapListener = OnDidFinishLoadingMapListenerNAPI;

/** Map-did-fail-loading listener */
export type OnDidFailLoadingMapListener = OnDidFailLoadingMapListenerNAPI;

// ========== Rendering listeners ==========

/** Frame-will-start-rendering listener */
export type OnWillStartRenderingFrameListener = OnWillStartRenderingFrameListenerNAPI;

/** Frame-did-finish-rendering listener (basic version) */
export type OnDidFinishRenderingFrameListener = OnDidFinishRenderingFrameListenerNAPI;

/** Frame-did-finish-rendering listener (with stats) */
export type OnDidFinishRenderingFrameWithStatsListener = OnDidFinishRenderingFrameWithStatsListenerNAPI;
export type RenderingStats = RenderingStatsNAPI;

/** Map-will-start-rendering listener */
export type OnWillStartRenderingMapListener = OnWillStartRenderingMapListenerNAPI;

/** Map-did-finish-rendering listener */
export type OnDidFinishRenderingMapListener = OnDidFinishRenderingMapListenerNAPI;

// ========== Style listeners ==========

/** Style-did-finish-loading listener */
export type OnDidFinishLoadingStyleListener = OnDidFinishLoadingStyleListenerNAPI;

/** Style-image-missing listener (declared manually, inline in NAPI) */
export type OnStyleImageMissingListener = (id: string) => void;

/** Listener that decides whether unused style images can be removed */
export type OnCanRemoveUnusedStyleImageListener = OnCanRemoveUnusedStyleImageListenerNAPI;

// ========== Other event listeners ==========

/** Map-did-become-idle listener */
export type OnDidBecomeIdleListener = OnDidBecomeIdleListenerNAPI;

/** Source-changed listener */
export type OnSourceChangedListener = OnSourceChangedListenerNAPI;

/** Pre-compile-shader listener (declared manually, inline in NAPI) */
export type OnPreCompileShaderListener = (id: number, type: number, additionalDefines: string) => void;

/** Post-compile-shader listener (declared manually, inline in NAPI) */
export type OnPostCompileShaderListener = (id: number, type: number, additionalDefines: string) => void;

/** Shader-compile-failed listener (declared manually, inline in NAPI) */
export type OnShaderCompileFailedListener = (id: number, type: number, additionalDefines: string) => void;

/** Glyphs-loaded listener (declared manually, inline in NAPI) */
export type OnGlyphsLoadedListener = (stack: string[], rangeStart: number, rangeEnd: number) => void;

/** Glyphs-error listener (declared manually, inline in NAPI) */
export type OnGlyphsErrorListener = (stack: string[], rangeStart: number, rangeEnd: number) => void;

/** Glyphs-requested listener (declared manually, inline in NAPI) */
export type OnGlyphsRequestedListener = (stack: string[], rangeStart: number, rangeEnd: number) => void;

/** Tile-operation listener (declared manually, inline in NAPI) */
export type OnTileActionListener = (op: TileOperation, x: number, y: number, z: number, wrap: number, overscaledZ: number, sourceID: string) => void;

/** Sprite-loaded listener (declared manually, inline in NAPI) */
export type OnSpriteLoadedListener = (id: string, url: string) => void;

/** Sprite-error listener (declared manually, inline in NAPI) */
export type OnSpriteErrorListener = (id: string, url: string) => void;

/** Sprite-requested listener (declared manually, inline in NAPI) */
export type OnSpriteRequestedListener = (id: string, url: string) => void;

// ========== Map ready callback ==========

/** Map-ready callback (uses the ETS MapLibreMap type) */
export type OnMapReadyCallback = (mapView: MapLibreMap | null) => void;

