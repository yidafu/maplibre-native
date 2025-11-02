/**
 * 手势监听器接口定义
 * 
 * 参考 Android MapGestureDetector 和 iOS MLNMapView 的手势监听器设计
 */

/**
 * 平移手势监听器
 * 当用户单指拖动地图时触发
 */
export interface OnMoveListener {
  /**
   * 平移手势开始
   */
  onMoveBegin(): void;

  /**
   * 平移手势进行中
   * @param distanceX X 轴移动距离（像素）
   * @param distanceY Y 轴移动距离（像素）
   */
  onMove(distanceX: number, distanceY: number): void;

  /**
   * 平移手势结束
   */
  onMoveEnd(): void;
}

/**
 * 缩放手势监听器
 * 当用户双指捏合或张开时触发
 */
export interface OnScaleListener {
  /**
   * 缩放手势开始
   * @param focalX 缩放中心点 X 坐标
   * @param focalY 缩放中心点 Y 坐标
   */
  onScaleBegin(focalX: number, focalY: number): void;

  /**
   * 缩放手势进行中
   * @param scaleFactor 缩放因子（>1 表示放大，<1 表示缩小）
   * @param focalX 缩放中心点 X 坐标
   * @param focalY 缩放中心点 Y 坐标
   */
  onScale(scaleFactor: number, focalX: number, focalY: number): void;

  /**
   * 缩放手势结束
   */
  onScaleEnd(): void;
}

/**
 * 旋转手势监听器
 * 当用户双指旋转时触发
 */
export interface OnRotateListener {
  /**
   * 旋转手势开始
   * @param focalX 旋转中心点 X 坐标
   * @param focalY 旋转中心点 Y 坐标
   */
  onRotateBegin(focalX: number, focalY: number): void;

  /**
   * 旋转手势进行中
   * @param rotationDelta 旋转角度增量（度）
   * @param focalX 旋转中心点 X 坐标
   * @param focalY 旋转中心点 Y 坐标
   */
  onRotate(rotationDelta: number, focalX: number, focalY: number): void;

  /**
   * 旋转手势结束
   */
  onRotateEnd(): void;
}

/**
 * 地图点击监听器
 */
export interface OnMapClickListener {
  /**
   * 地图单击事件
   * @param x 点击位置 X 坐标
   * @param y 点击位置 Y 坐标
   * @returns 是否消费该事件
   */
  onMapClick(x: number, y: number): boolean;
}

/**
 * 地图长按监听器
 */
export interface OnMapLongClickListener {
  /**
   * 地图长按事件
   * @param x 长按位置 X 坐标
   * @param y 长按位置 Y 坐标
   * @returns 是否消费该事件
   */
  onMapLongClick(x: number, y: number): boolean;
}

/**
 * 双击监听器（预留扩展）
 */
export interface OnDoubleTapListener {
  /**
   * 地图双击事件
   * @param x 双击位置 X 坐标
   * @param y 双击位置 Y 坐标
   * @returns 是否消费该事件
   */
  onDoubleTap(x: number, y: number): boolean;
}

/**
 * 快速滑动监听器（预留扩展）
 */
export interface OnFlingListener {
  /**
   * 快速滑动事件
   * @param velocityX X 轴速度
   * @param velocityY Y 轴速度
   */
  onFling(velocityX: number, velocityY: number): void;
}

/**
 * 双指点击监听器（预留扩展）
 */
export interface OnTwoFingerTapListener {
  /**
   * 双指点击事件
   * @param x 点击位置 X 坐标
   * @param y 点击位置 Y 坐标
   */
  onTwoFingerTap(x: number, y: number): void;
}

/**
 * 倾斜手势监听器
 * 当用户双指上下拖动改变地图俯仰角度时触发
 */
export interface OnTiltListener {
  /**
   * 倾斜手势开始
   */
  onTiltBegin(): void;

  /**
   * 倾斜手势进行中
   * @param pitch 当前俯仰角度（度，0-60）
   */
  onTilt(pitch: number): void;

  /**
   * 倾斜手势结束
   */
  onTiltEnd(): void;
}

/**
 * Shove 手势监听器（Android 命名）
 * 当用户双指上下拖动改变地图俯仰角度时触发
 * 等同于 OnTiltListener，提供 Android 风格的命名以保持兼容性
 * 
 * 参考 Android MapLibreMap.OnShoveListener
 */
export interface OnShoveListener {
  /**
   * Shove 手势开始
   */
  onShoveBegin(): void;

  /**
   * Shove 手势进行中
   * @param pitch 当前俯仰角度（度，0-60）
   */
  onShove(pitch: number): void;

  /**
   * Shove 手势结束
   */
  onShoveEnd(): void;
}

/**
 * Quick Zoom 监听器
 * 当用户双击并拖动进行快速缩放时触发
 */
export interface OnQuickZoomListener {
  /**
   * Quick Zoom 开始
   */
  onQuickZoomBegin(): void;

  /**
   * Quick Zoom 进行中
   * @param zoom 当前缩放级别
   */
  onQuickZoom(zoom: number): void;

  /**
   * Quick Zoom 结束
   */
  onQuickZoomEnd(): void;
}

