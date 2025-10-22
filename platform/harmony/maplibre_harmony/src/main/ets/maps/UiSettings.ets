/**
 * 焦点位置类型
 */
export class FocalPoint {
  x: number = 0;
  y: number = 0;

  constructor(x: number, y: number) {
    this.x = x;
    this.y = y;
  }
}

/**
 * UI 设置类
 * 
 * 管理地图的手势启用/禁用配置
 * 参考 Android UiSettings 和 iOS MLNMapView 属性
 */

export class UiSettings {
  // 手势启用状态
  private scrollGesturesEnabled: boolean = true;
  private zoomGesturesEnabled: boolean = true;
  private rotateGesturesEnabled: boolean = true;
  private tiltGesturesEnabled: boolean = true;
  private doubleTapGesturesEnabled: boolean = true;
  private quickZoomGesturesEnabled: boolean = true;
  
  // 滚动配置
  private horizontalScrollGesturesEnabled: boolean = true;
  
  // 手势灵敏度配置
  private focalPoint: FocalPoint | null = null;

  // 惯性动画开关
  private flingVelocityAnimationEnabled: boolean = true;
  private scaleVelocityAnimationEnabled: boolean = true;
  private rotateVelocityAnimationEnabled: boolean = true;

  // 动画参数
  private decelerationRate: number = 0.35;  // iOS 风格（0-1），越大动画越长
  private flingAnimationBaseTime: number = 300;  // 基础动画时长（ms）
  private flingThreshold: number = 100;  // 速度阈值（像素/秒）

  // 速度阈值
  private minFlingVelocity: number = 100;  // 平移最小速度（像素/秒）
  private minScaleVelocity: number = 0.5;  // 缩放最小速度
  private minRotateVelocity: number = 5;   // 旋转最小速度（度/秒）

  // Tilt 相关配置
  private minPitch: number = 0;           // 最小俯仰角（度）
  private maxPitch: number = 60;          // 最大俯仰角（度）
  private tiltSensitivity: number = 0.5;  // 倾斜灵敏度（slowdown factor）

  // Quick Zoom 相关配置
  private quickZoomMaxChange: number = 4;  // Quick Zoom 最大缩放变化

  /**
   * 设置是否启用滚动手势（平移）
   */
  setScrollGesturesEnabled(enabled: boolean): void {
    this.scrollGesturesEnabled = enabled;
  }

  /**
   * 获取滚动手势是否启用
   */
  isScrollGesturesEnabled(): boolean {
    return this.scrollGesturesEnabled;
  }

  /**
   * 设置是否启用缩放手势
   */
  setZoomGesturesEnabled(enabled: boolean): void {
    this.zoomGesturesEnabled = enabled;
  }

  /**
   * 获取缩放手势是否启用
   */
  isZoomGesturesEnabled(): boolean {
    return this.zoomGesturesEnabled;
  }

  /**
   * 设置是否启用旋转手势
   */
  setRotateGesturesEnabled(enabled: boolean): void {
    this.rotateGesturesEnabled = enabled;
  }

  /**
   * 获取旋转手势是否启用
   */
  isRotateGesturesEnabled(): boolean {
    return this.rotateGesturesEnabled;
  }

  /**
   * 设置是否启用倾斜手势（双指拖动调整 pitch）
   */
  setTiltGesturesEnabled(enabled: boolean): void {
    this.tiltGesturesEnabled = enabled;
  }

  /**
   * 获取倾斜手势是否启用
   */
  isTiltGesturesEnabled(): boolean {
    return this.tiltGesturesEnabled;
  }

  /**
   * 设置是否启用双击缩放手势
   */
  setDoubleTapGesturesEnabled(enabled: boolean): void {
    this.doubleTapGesturesEnabled = enabled;
  }

  /**
   * 获取双击缩放手势是否启用
   */
  isDoubleTapGesturesEnabled(): boolean {
    return this.doubleTapGesturesEnabled;
  }

  /**
   * 设置是否启用快速缩放手势（双击并拖动）
   */
  setQuickZoomGesturesEnabled(enabled: boolean): void {
    this.quickZoomGesturesEnabled = enabled;
  }

  /**
   * 获取快速缩放手势是否启用
   */
  isQuickZoomGesturesEnabled(): boolean {
    return this.quickZoomGesturesEnabled;
  }

  /**
   * 设置是否启用水平滚动
   */
  setHorizontalScrollGesturesEnabled(enabled: boolean): void {
    this.horizontalScrollGesturesEnabled = enabled;
  }

  /**
   * 获取水平滚动是否启用
   */
  isHorizontalScrollGesturesEnabled(): boolean {
    return this.horizontalScrollGesturesEnabled;
  }

  /**
   * 设置手势焦点
   * @param point 焦点坐标，null 表示使用默认焦点
   */
  setFocalPoint(point: FocalPoint | null): void {
    this.focalPoint = point;
  }

  /**
   * 获取手势焦点
   */
  getFocalPoint(): FocalPoint | null {
    return this.focalPoint;
  }

  /**
   * 启用所有手势
   */
  setAllGesturesEnabled(enabled: boolean): void {
    this.scrollGesturesEnabled = enabled;
    this.zoomGesturesEnabled = enabled;
    this.rotateGesturesEnabled = enabled;
    this.tiltGesturesEnabled = enabled;
    this.doubleTapGesturesEnabled = enabled;
    this.quickZoomGesturesEnabled = enabled;
  }

  // ==================== 惯性动画配置 ====================

  /**
   * 设置是否启用 Fling 速度动画
   * @param enabled 是否启用
   */
  setFlingVelocityAnimationEnabled(enabled: boolean): void {
    this.flingVelocityAnimationEnabled = enabled;
  }

  /**
   * 获取 Fling 速度动画是否启用
   */
  isFlingVelocityAnimationEnabled(): boolean {
    return this.flingVelocityAnimationEnabled;
  }

  /**
   * 设置是否启用缩放速度动画
   * @param enabled 是否启用
   */
  setScaleVelocityAnimationEnabled(enabled: boolean): void {
    this.scaleVelocityAnimationEnabled = enabled;
  }

  /**
   * 获取缩放速度动画是否启用
   */
  isScaleVelocityAnimationEnabled(): boolean {
    return this.scaleVelocityAnimationEnabled;
  }

  /**
   * 设置是否启用旋转速度动画
   * @param enabled 是否启用
   */
  setRotateVelocityAnimationEnabled(enabled: boolean): void {
    this.rotateVelocityAnimationEnabled = enabled;
  }

  /**
   * 获取旋转速度动画是否启用
   */
  isRotateVelocityAnimationEnabled(): boolean {
    return this.rotateVelocityAnimationEnabled;
  }

  /**
   * 批量设置所有速度动画开关
   * @param enabled 是否启用
   */
  setAllVelocityAnimationsEnabled(enabled: boolean): void {
    this.flingVelocityAnimationEnabled = enabled;
    this.scaleVelocityAnimationEnabled = enabled;
    this.rotateVelocityAnimationEnabled = enabled;
  }

  /**
   * 设置减速率（0-1）
   * 越大动画时间越长，减速越慢
   * @param rate 减速率
   */
  setDecelerationRate(rate: number): void {
    this.decelerationRate = Math.max(0, Math.min(1, rate));  // 限制在 0-1
  }

  /**
   * 获取减速率
   */
  getDecelerationRate(): number {
    return this.decelerationRate;
  }

  /**
   * 设置 Fling 速度阈值
   * @param threshold 阈值（像素/秒）
   */
  setFlingThreshold(threshold: number): void {
    this.flingThreshold = Math.max(0, threshold);
  }

  /**
   * 获取 Fling 速度阈值
   */
  getFlingThreshold(): number {
    return this.flingThreshold;
  }

  /**
   * 设置 Fling 动画基础时长
   * @param time 时长（毫秒）
   */
  setFlingAnimationBaseTime(time: number): void {
    this.flingAnimationBaseTime = Math.max(0, time);
  }

  /**
   * 获取 Fling 动画基础时长
   */
  getFlingAnimationBaseTime(): number {
    return this.flingAnimationBaseTime;
  }

  /**
   * 设置平移最小速度阈值
   * @param velocity 速度（像素/秒）
   */
  setMinFlingVelocity(velocity: number): void {
    this.minFlingVelocity = Math.max(0, velocity);
  }

  /**
   * 获取平移最小速度阈值
   */
  getMinFlingVelocity(): number {
    return this.minFlingVelocity;
  }

  /**
   * 设置缩放最小速度阈值
   * @param velocity 速度
   */
  setMinScaleVelocity(velocity: number): void {
    this.minScaleVelocity = Math.max(0, velocity);
  }

  /**
   * 获取缩放最小速度阈值
   */
  getMinScaleVelocity(): number {
    return this.minScaleVelocity;
  }

  /**
   * 设置旋转最小速度阈值
   * @param velocity 速度（度/秒）
   */
  setMinRotateVelocity(velocity: number): void {
    this.minRotateVelocity = Math.max(0, velocity);
  }

  /**
   * 获取旋转最小速度阈值
   */
  getMinRotateVelocity(): number {
    return this.minRotateVelocity;
  }

  // ==================== Tilt 配置 ====================

  /**
   * 设置最小俯仰角
   */
  setMinPitch(pitch: number): void {
    this.minPitch = Math.max(0, Math.min(60, pitch));
  }

  /**
   * 获取最小俯仰角
   */
  getMinPitch(): number {
    return this.minPitch;
  }

  /**
   * 设置最大俯仰角
   */
  setMaxPitch(pitch: number): void {
    this.maxPitch = Math.max(0, Math.min(60, pitch));
  }

  /**
   * 获取最大俯仰角
   */
  getMaxPitch(): number {
    return this.maxPitch;
  }

  /**
   * 设置倾斜灵敏度
   * 值越大，倾斜越慢（slowdown factor）
   */
  setTiltSensitivity(sensitivity: number): void {
    this.tiltSensitivity = Math.max(0.1, Math.min(5.0, sensitivity));
  }

  /**
   * 获取倾斜灵敏度
   */
  getTiltSensitivity(): number {
    return this.tiltSensitivity;
  }

  // ==================== Quick Zoom 配置 ====================

  /**
   * 设置 Quick Zoom 最大缩放变化
   */
  setQuickZoomMaxChange(maxChange: number): void {
    this.quickZoomMaxChange = Math.max(1, Math.min(10, maxChange));
  }

  /**
   * 获取 Quick Zoom 最大缩放变化
   */
  getQuickZoomMaxChange(): number {
    return this.quickZoomMaxChange;
  }
}


