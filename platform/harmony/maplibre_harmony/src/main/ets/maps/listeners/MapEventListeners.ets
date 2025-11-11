/**
 * 地图事件监听器接口定义
 * 对齐 Android MapView 的所有监听器接口
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

// ========== 相机事件监听器 ==========

/** 相机即将改变的监听器 */
export type OnCameraWillChangeListener = OnCameraWillChangeListenerNAPI;

/** 相机正在改变的监听器 */
export type OnCameraIsChangingListener = OnCameraIsChangingListenerNAPI;

/** 相机已改变的监听器 */
export type OnCameraDidChangeListener = OnCameraDidChangeListenerNAPI;

// ========== 地图加载事件监听器 ==========

/** 地图即将开始加载的监听器 */
export type OnWillStartLoadingMapListener = OnWillStartLoadingMapListenerNAPI;

/** 地图加载完成的监听器 */
export type OnDidFinishLoadingMapListener = OnDidFinishLoadingMapListenerNAPI;

/** 地图加载失败的监听器 */
export type OnDidFailLoadingMapListener = OnDidFailLoadingMapListenerNAPI;

// ========== 渲染事件监听器 ==========

/** 帧即将开始渲染的监听器 */
export type OnWillStartRenderingFrameListener = OnWillStartRenderingFrameListenerNAPI;

/** 帧渲染完成的监听器（简单版本） */
export type OnDidFinishRenderingFrameListener = OnDidFinishRenderingFrameListenerNAPI;

/** 帧渲染完成的监听器（带统计信息） */
export type OnDidFinishRenderingFrameWithStatsListener = OnDidFinishRenderingFrameWithStatsListenerNAPI;
export type RenderingStats = RenderingStatsNAPI;

/** 地图即将开始渲染的监听器 */
export type OnWillStartRenderingMapListener = OnWillStartRenderingMapListenerNAPI;

/** 地图渲染完成的监听器 */
export type OnDidFinishRenderingMapListener = OnDidFinishRenderingMapListenerNAPI;

// ========== 样式事件监听器 ==========

/** 样式加载完成的监听器 */
export type OnDidFinishLoadingStyleListener = OnDidFinishLoadingStyleListenerNAPI;

/** 样式图片缺失的监听器（NAPI 中内联定义，手动声明） */
export type OnStyleImageMissingListener = (id: string) => void;

/** 可移除未使用样式图片的监听器 */
export type OnCanRemoveUnusedStyleImageListener = OnCanRemoveUnusedStyleImageListenerNAPI;

// ========== 其他事件监听器 ==========

/** 地图进入空闲状态的监听器 */
export type OnDidBecomeIdleListener = OnDidBecomeIdleListenerNAPI;

/** 数据源改变的监听器 */
export type OnSourceChangedListener = OnSourceChangedListenerNAPI;

/** 着色器编译前的监听器（NAPI 中内联定义，手动声明） */
export type OnPreCompileShaderListener = (id: number, type: number, additionalDefines: string) => void;

/** 着色器编译后的监听器（NAPI 中内联定义，手动声明） */
export type OnPostCompileShaderListener = (id: number, type: number, additionalDefines: string) => void;

/** 着色器编译失败的监听器（NAPI 中内联定义，手动声明） */
export type OnShaderCompileFailedListener = (id: number, type: number, additionalDefines: string) => void;

/** 字形加载完成的监听器（NAPI 中内联定义，手动声明） */
export type OnGlyphsLoadedListener = (stack: string[], rangeStart: number, rangeEnd: number) => void;

/** 字形加载错误的监听器（NAPI 中内联定义，手动声明） */
export type OnGlyphsErrorListener = (stack: string[], rangeStart: number, rangeEnd: number) => void;

/** 字形请求的监听器（NAPI 中内联定义，手动声明） */
export type OnGlyphsRequestedListener = (stack: string[], rangeStart: number, rangeEnd: number) => void;

/** 瓦片操作的监听器（NAPI 中内联定义，手动声明） */
export type OnTileActionListener = (op: TileOperation, x: number, y: number, z: number, wrap: number, overscaledZ: number, sourceID: string) => void;

/** 精灵图加载完成的监听器（NAPI 中内联定义，手动声明） */
export type OnSpriteLoadedListener = (id: string, url: string) => void;

/** 精灵图加载错误的监听器（NAPI 中内联定义，手动声明） */
export type OnSpriteErrorListener = (id: string, url: string) => void;

/** 精灵图请求的监听器（NAPI 中内联定义，手动声明） */
export type OnSpriteRequestedListener = (id: string, url: string) => void;

// ========== Map ready 回调 ==========

/** 地图就绪回调接口（使用 ETS MapLibreMap 类型） */
export type OnMapReadyCallback = (mapView: MapLibreMap | null) => void;

