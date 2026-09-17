/**
 * Listener module exports.
 *
 * Provides map event listener interfaces.
 */

// Core listeners
export { OnMarkerClickListener } from './OnMarkerClickListener';

export { OnMarkerLongClickListener } from './OnMarkerLongClickListener';

export { OnMarkerDragListener } from './OnMarkerDragListener';

export { OnInfoWindowClickListener } from './OnInfoWindowClickListener';

export { OnInfoWindowCloseListener } from './OnInfoWindowCloseListener';

export { OnMarkerSelectListener } from './OnMarkerSelectListener';

export { OnStyleLoadedListener } from './OnStyleLoadedListener';

export { OnStyleLoadErrorListener } from './OnStyleLoadErrorListener';

// Map event listeners (aligned with Android/iOS APIs)
export {
  // Camera events
  OnCameraWillChangeListener,
  OnCameraIsChangingListener,
  OnCameraDidChangeListener,

  // Map loading events
  OnWillStartLoadingMapListener,
  OnDidFinishLoadingMapListener,
  OnDidFailLoadingMapListener,

  // Rendering events
  OnWillStartRenderingFrameListener,
  OnDidFinishRenderingFrameListener,
  OnDidFinishRenderingFrameWithStatsListener,
  OnWillStartRenderingMapListener,
  OnDidFinishRenderingMapListener,

  // Style events
  OnDidFinishLoadingStyleListener,
  OnStyleImageMissingListener,
  OnCanRemoveUnusedStyleImageListener,

  // Misc events
  OnDidBecomeIdleListener,
  OnSourceChangedListener,
  OnPreCompileShaderListener,
  OnPostCompileShaderListener,
  OnShaderCompileFailedListener,
  OnGlyphsLoadedListener,
  OnGlyphsErrorListener,
  OnGlyphsRequestedListener,
  OnTileActionListener,
  OnSpriteLoadedListener,
  OnSpriteErrorListener,
  OnSpriteRequestedListener,

  // Map ready callback
  OnMapReadyCallback
} from './MapEventListeners';

// Additional callbacks
export { OnFpsChangedListener } from './OnFpsChangedListener';

export { StateCallback } from './StateCallback';

export { ViewCallback } from './ViewCallback';

