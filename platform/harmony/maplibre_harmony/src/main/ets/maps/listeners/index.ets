/**
 * Listeners 模块导出
 *
 * 提供地图事件监听器接口
 */

// 原有的监听器
export { OnMarkerClickListener } from './OnMarkerClickListener';

export { OnMarkerLongClickListener } from './OnMarkerLongClickListener';

export { OnMarkerDragListener } from './OnMarkerDragListener';

export { OnInfoWindowClickListener } from './OnInfoWindowClickListener';

export { OnInfoWindowCloseListener } from './OnInfoWindowCloseListener';

export { OnMarkerSelectListener } from './OnMarkerSelectListener';

export { OnStyleLoadedListener } from './OnStyleLoadedListener';

export { OnStyleLoadErrorListener } from './OnStyleLoadErrorListener';

// 地图事件监听器（对齐 Android/iOS API）
export {
  // 相机事件
  OnCameraWillChangeListener,
  OnCameraIsChangingListener,
  OnCameraDidChangeListener,

  // 地图加载事件
  OnWillStartLoadingMapListener,
  OnDidFinishLoadingMapListener,
  OnDidFailLoadingMapListener,

  // 渲染事件
  OnWillStartRenderingFrameListener,
  OnDidFinishRenderingFrameListener,
  OnDidFinishRenderingFrameWithStatsListener,
  OnWillStartRenderingMapListener,
  OnDidFinishRenderingMapListener,

  // 样式事件
  OnDidFinishLoadingStyleListener,
  OnStyleImageMissingListener,
  OnCanRemoveUnusedStyleImageListener,

  // 其他事件
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

  // 地图就绪回调
  OnMapReadyCallback
} from './MapEventListeners';

// 回调接口
export { OnFpsChangedListener } from './OnFpsChangedListener';

export { StateCallback } from './StateCallback';

export { ViewCallback } from './ViewCallback';

