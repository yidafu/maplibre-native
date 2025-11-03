/**
 * 地图事件监听器接口定义
 * 对齐 Android MapView 的所有监听器接口
 */

import { RenderingStats } from '../renderer/RenderingStats';
import { TileOperation } from '../types/NativeTypes';

// ========== 相机事件监听器 ==========

/**
 * 相机即将改变的监听器
 * 对齐 Android MapView.OnCameraWillChangeListener
 */
export interface OnCameraWillChangeListener {
  /**
   * 当相机区域即将改变时调用
   * @param animated 是否使用动画
   */
  onCameraWillChange(animated: boolean): void;
}

/**
 * 相机正在改变的监听器
 * 对齐 Android MapView.OnCameraIsChangingListener
 */
export interface OnCameraIsChangingListener {
  /**
   * 当相机正在改变时调用（可能被多次调用）
   */
  onCameraIsChanging(): void;
}

/**
 * 相机已改变的监听器
 * 对齐 Android MapView.OnCameraDidChangeListener
 */
export interface OnCameraDidChangeListener {
  /**
   * 当相机已改变时调用
   * @param animated 是否使用了动画
   */
  onCameraDidChange(animated: boolean): void;
}

// ========== 地图加载事件监听器 ==========

/**
 * 地图即将开始加载的监听器
 * 对齐 Android MapView.OnWillStartLoadingMapListener
 */
export interface OnWillStartLoadingMapListener {
  /**
   * 当地图即将开始加载时调用
   */
  onWillStartLoadingMap(): void;
}

/**
 * 地图加载完成的监听器
 * 对齐 Android MapView.OnDidFinishLoadingMapListener
 */
export interface OnDidFinishLoadingMapListener {
  /**
   * 当地图加载完成时调用
   */
  onDidFinishLoadingMap(): void;
}

/**
 * 地图加载失败的监听器
 * 对齐 Android MapView.OnDidFailLoadingMapListener
 */
export interface OnDidFailLoadingMapListener {
  /**
   * 当地图加载失败时调用
   * @param errorMessage 错误信息
   */
  onDidFailLoadingMap(errorMessage: string): void;
}

// ========== 渲染事件监听器 ==========

/**
 * 帧即将开始渲染的监听器
 * 对齐 Android MapView.OnWillStartRenderingFrameListener
 */
export interface OnWillStartRenderingFrameListener {
  /**
   * 当帧即将开始渲染时调用
   */
  onWillStartRenderingFrame(): void;
}

/**
 * 帧渲染完成的监听器（简单版本）
 * 对齐 Android MapView.OnDidFinishRenderingFrameListener
 */
export interface OnDidFinishRenderingFrameListener {
  /**
   * 当帧渲染完成时调用
   * @param fully true 表示所有帧都已渲染完成，false 表示部分渲染
   * @param frameEncodingTime CPU 编码时间（毫秒）
   * @param frameRenderingTime CPU 渲染时间（毫秒）
   */
  onDidFinishRenderingFrame(fully: boolean, frameEncodingTime: number, frameRenderingTime: number): void;
}

/**
 * 帧渲染完成的监听器（带统计信息）
 * 对齐 Android MapView.OnDidFinishRenderingFrameWithStatsListener
 */
export interface OnDidFinishRenderingFrameWithStatsListener {
  /**
   * 当帧渲染完成时调用
   * @param fully true 表示所有帧都已渲染完成，false 表示部分渲染
   * @param stats 渲染统计信息
   */
  onDidFinishRenderingFrame(fully: boolean, stats: RenderingStats): void;
}

/**
 * 地图即将开始渲染的监听器
 * 对齐 Android MapView.OnWillStartRenderingMapListener
 */
export interface OnWillStartRenderingMapListener {
  /**
   * 当地图即将开始渲染时调用
   */
  onWillStartRenderingMap(): void;
}

/**
 * 地图渲染完成的监听器
 * 对齐 Android MapView.OnDidFinishRenderingMapListener
 */
export interface OnDidFinishRenderingMapListener {
  /**
   * 当地图渲染完成时调用
   * @param fully true 表示地图完全渲染，false 表示未完全渲染
   */
  onDidFinishRenderingMap(fully: boolean): void;
}

// ========== 样式事件监听器 ==========

/**
 * 样式加载完成的监听器
 * 对齐 Android MapView.OnDidFinishLoadingStyleListener
 */
export interface OnDidFinishLoadingStyleListener {
  /**
   * 当样式加载完成时调用
   */
  onDidFinishLoadingStyle(): void;
}

/**
 * 样式图片缺失的监听器
 * 对齐 Android MapView.OnStyleImageMissingListener
 */
export interface OnStyleImageMissingListener {
  /**
   * 当样式中缺少图片时调用
   * 应该同步添加图片以在当前缩放级别渲染
   * @param id 缺失的图片 ID
   */
  onStyleImageMissing(id: string): void;
}

/**
 * 可移除未使用样式图片的监听器
 * 对齐 Android MapView.OnCanRemoveUnusedStyleImageListener
 */
export interface OnCanRemoveUnusedStyleImageListener {
  /**
   * 当地图需要释放未使用的图片资源时调用
   * @param id 未使用的图片 ID
   * @returns true 表示可以移除，false 表示不能移除
   */
  onCanRemoveUnusedStyleImage(id: string): boolean;
}

// ========== 其他事件监听器 ==========

/**
 * 地图进入空闲状态的监听器
 * 对齐 Android MapView.OnDidBecomeIdleListener
 */
export interface OnDidBecomeIdleListener {
  /**
   * 当地图进入空闲状态时调用
   */
  onDidBecomeIdle(): void;
}

/**
 * 数据源改变的监听器
 * 对齐 Android MapView.OnSourceChangedListener
 */
export interface OnSourceChangedListener {
  /**
   * 当数据源改变时调用
   * @param id 改变的数据源 ID
   */
  onSourceChangedListener(id: string): void;
}

/**
 * 着色器编译前的监听器
 * 对齐 Android MapView.OnPreCompileShaderListener
 */
export interface OnPreCompileShaderListener {
  /**
   * 在着色器编译前调用
   * @param id 着色器类型枚举 ID
   * @param type 图形后端类型
   * @param additionalDefines 着色器的排列定义
   */
  onPreCompileShader(id: number, type: number, additionalDefines: string): void;
}

/**
 * 着色器编译后的监听器
 * 对齐 Android MapView.OnPostCompileShaderListener
 */
export interface OnPostCompileShaderListener {
  /**
   * 在着色器编译后调用
   * @param id 着色器类型枚举 ID
   * @param type 图形后端类型
   * @param additionalDefines 着色器的排列定义
   */
  onPostCompileShader(id: number, type: number, additionalDefines: string): void;
}

/**
 * 着色器编译失败的监听器
 * 对齐 Android MapView.OnShaderCompileFailedListener
 */
export interface OnShaderCompileFailedListener {
  /**
   * 当着色器编译失败时调用
   * @param id 着色器类型枚举 ID
   * @param type 图形后端类型
   * @param additionalDefines 着色器的排列定义
   */
  onShaderCompileFailed(id: number, type: number, additionalDefines: string): void;
}

/**
 * 字形加载完成的监听器
 * 对齐 Android MapView.OnGlyphsLoadedListener
 */
export interface OnGlyphsLoadedListener {
  /**
   * 当字体的字形范围加载完成时调用
   * @param stack 字体名称数组
   * @param rangeStart 字形索引范围起始
   * @param rangeEnd 字形索引范围结束
   */
  onGlyphsLoaded(stack: string[], rangeStart: number, rangeEnd: number): void;
}

/**
 * 字形加载错误的监听器
 * 对齐 Android MapView.OnGlyphsErrorListener
 */
export interface OnGlyphsErrorListener {
  /**
   * 当字体的字形范围加载失败时调用
   * @param stack 字体名称数组
   * @param rangeStart 字形索引范围起始
   * @param rangeEnd 字形索引范围结束
   */
  onGlyphsError(stack: string[], rangeStart: number, rangeEnd: number): void;
}

/**
 * 字形请求的监听器
 * 对齐 Android MapView.OnGlyphsRequestedListener
 */
export interface OnGlyphsRequestedListener {
  /**
   * 当字体的字形范围被请求时调用
   * @param stack 字体名称数组
   * @param rangeStart 字形索引范围起始
   * @param rangeEnd 字形索引范围结束
   */
  onGlyphsRequested(stack: string[], rangeStart: number, rangeEnd: number): void;
}

/**
 * 瓦片操作的监听器
 * 对齐 Android MapView.OnTileActionListener
 */
export interface OnTileActionListener {
  /**
   * 当瓦片操作发生时调用
   * @param op 瓦片操作类型
   * @param x 瓦片 x 坐标
   * @param y 瓦片 y 坐标
   * @param z 瓦片 z 坐标
   * @param wrap 瓦片 wrap 坐标
   * @param overscaledZ 瓦片 overscaledZ 坐标
   * @param sourceID 数据源 ID
   */
  onTileAction(op: TileOperation, x: number, y: number, z: number, wrap: number, overscaledZ: number,
    sourceID: string): void;
}

/**
 * 精灵图加载完成的监听器
 * 对齐 Android MapView.OnSpriteLoadedListener
 */
export interface OnSpriteLoadedListener {
  /**
   * 当精灵图加载完成时调用
   * @param id 精灵图 ID
   * @param url 精灵图 URL
   */
  onSpriteLoaded(id: string, url: string): void;
}

/**
 * 精灵图加载错误的监听器
 * 对齐 Android MapView.OnSpriteErrorListener
 */
export interface OnSpriteErrorListener {
  /**
   * 当精灵图加载失败时调用
   * @param id 精灵图 ID
   * @param url 精灵图 URL
   */
  onSpriteError(id: string, url: string): void;
}

/**
 * 精灵图请求的监听器
 * 对齐 Android MapView.OnSpriteRequestedListener
 */
export interface OnSpriteRequestedListener {
  /**
   * 当精灵图被请求时调用
   * @param id 精灵图 ID
   * @param url 精灵图 URL
   */
  onSpriteRequested(id: string, url: string): void;
}

/**
 * 地图就绪回调接口
 * 对齐 Android OnMapReadyCallback
 */
export interface OnMapReadyCallback {
  /**
   * 当地图准备就绪时调用
   * @param mapView 地图视图实例（这里使用 Object 避免循环依赖，实际使用时为 NativeMapView）
   */
  onMapReady(mapView: Object | null): void;
}

