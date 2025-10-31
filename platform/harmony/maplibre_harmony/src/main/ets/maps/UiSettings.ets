import { CompassVisibility } from './widgets/CompassVisibility';
import { CompassPosition } from './widgets/CompassPosition';
import { ScaleBarUnit } from './widgets/ScaleBarView';

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
 * 指南针边距配置
 */
export class CompassMargins {
  left: number = 0;
  top: number = 0;
  right: number = 0;
  bottom: number = 0;

  constructor(left: number = 10, top: number = 10, right: number = 10, bottom: number = 10) {
    this.left = left;
    this.top = top;
    this.right = right;
    this.bottom = bottom;
  }
}

/**
 * UI 设置类
 * 
 * 管理地图的手势启用/禁用配置和 UI 组件配置
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

  // Zoom 相关配置
  private zoomRate: number = 1.0;  // 缩放速率倍率（参考 Android UiSettings）

  // Rotation 相关配置
  private rotationRate: number = 1.0;  // 旋转速率倍率（控制旋转灵敏度）

  // ==================== 指南针配置 ====================
  
  // 指南针启用状态
  private compassEnabled: boolean = true;
  
  // 指南针可见性模式
  private compassVisibility: CompassVisibility = CompassVisibility.Adaptive;
  
  // 正北时是否淡出
  private compassFadeWhenFacingNorth: boolean = true;
  
  // 指南针边距
  private compassMargins: CompassMargins = new CompassMargins(10, 10, 10, 10);
  
  // 指南针位置
  private compassPosition: CompassPosition = CompassPosition.TopRight;
  
  // 指南针更新回调（由 MapLibreMap 注入）
  public onCompassConfigChanged?: () => void;

  // ==================== Logo 配置 ====================
  
  // Logo 启用状态
  private logoEnabled: boolean = true;
  
  // Logo 边距
  private logoMargins: CompassMargins = new CompassMargins(10, 10, 10, 10);
  
  // Logo 位置
  private logoPosition: CompassPosition = CompassPosition.BottomLeft;
  
  // Logo 更新回调
  public onLogoConfigChanged?: () => void;

  // ==================== ScaleBar 配置 ====================
  
  // ScaleBar 启用状态
  private scaleBarEnabled: boolean = true;  // 默认启用
  
  // ScaleBar 单位系统
  private scaleBarUnit: ScaleBarUnit = ScaleBarUnit.Metric;
  
  // ScaleBar 是否使用深色样式
  private scaleBarUseDarkStyles: boolean = false;
  
  // ScaleBar 边距
  private scaleBarMargins: CompassMargins = new CompassMargins(10, 10, 10, 10);
  
  // ScaleBar 位置
  private scaleBarPosition: CompassPosition = CompassPosition.TopLeft;
  
  // ScaleBar 更新回调
  public onScaleBarConfigChanged?: () => void;

  // ==================== 手势配置 ====================

  /**
   * 设置是否启用滚动手势（平移）
   */
  setScrollGesturesEnabled(enabled: boolean): UiSettings {
    this.scrollGesturesEnabled = enabled;
    return this;
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
  setZoomGesturesEnabled(enabled: boolean): UiSettings {
    this.zoomGesturesEnabled = enabled;
    return this;
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
  setRotateGesturesEnabled(enabled: boolean): UiSettings {
    this.rotateGesturesEnabled = enabled;
    return this;
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
  setTiltGesturesEnabled(enabled: boolean): UiSettings {
    this.tiltGesturesEnabled = enabled;
    return this;
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
  setDoubleTapGesturesEnabled(enabled: boolean): UiSettings {
    this.doubleTapGesturesEnabled = enabled;
    return this;
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
  setQuickZoomGesturesEnabled(enabled: boolean): UiSettings {
    this.quickZoomGesturesEnabled = enabled;
    return this;
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
  setHorizontalScrollGesturesEnabled(enabled: boolean): UiSettings {
    this.horizontalScrollGesturesEnabled = enabled;
    return this;
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
  setFocalPoint(point: FocalPoint | null): UiSettings {
    this.focalPoint = point;
    return this;
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
  setAllGesturesEnabled(enabled: boolean): UiSettings {
    this.scrollGesturesEnabled = enabled;
    this.zoomGesturesEnabled = enabled;
    this.rotateGesturesEnabled = enabled;
    this.tiltGesturesEnabled = enabled;
    this.doubleTapGesturesEnabled = enabled;
    this.quickZoomGesturesEnabled = enabled;
    return this;
  }

  // ==================== 惯性动画配置 ====================

  /**
   * 设置是否启用 Fling 速度动画
   * @param enabled 是否启用
   */
  setFlingVelocityAnimationEnabled(enabled: boolean): UiSettings {
    this.flingVelocityAnimationEnabled = enabled;
    return this;
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
  setScaleVelocityAnimationEnabled(enabled: boolean): UiSettings {
    this.scaleVelocityAnimationEnabled = enabled;
    return this;
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
  setRotateVelocityAnimationEnabled(enabled: boolean): UiSettings {
    this.rotateVelocityAnimationEnabled = enabled;
    return this;
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
  setAllVelocityAnimationsEnabled(enabled: boolean): UiSettings {
    this.flingVelocityAnimationEnabled = enabled;
    this.scaleVelocityAnimationEnabled = enabled;
    this.rotateVelocityAnimationEnabled = enabled;
    return this;
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

  // ==================== Zoom Rate 配置 ====================

  /**
   * 设置缩放速率倍率
   * 参考 Android UiSettings.setZoomRate()
   * @param rate 缩放速率倍率（默认 1.0）
   */
  setZoomRate(rate: number): void {
    this.zoomRate = Math.max(0.1, Math.min(10.0, rate));
  }

  /**
   * 获取缩放速率倍率
   */
  getZoomRate(): number {
    return this.zoomRate;
  }

  // ==================== Rotation Rate 配置 ====================

  /**
   * 设置旋转速率倍率
   * @param rate 旋转速率倍率（默认 1.0，越小旋转越慢）
   */
  setRotationRate(rate: number): void {
    this.rotationRate = Math.max(0.1, Math.min(10.0, rate));
  }

  /**
   * 获取旋转速率倍率
   */
  getRotationRate(): number {
    return this.rotationRate;
  }

  // ==================== 指南针配置方法 ====================

  /**
   * 设置指南针启用状态
   * @param enabled 是否启用指南针
   */
  setCompassEnabled(enabled: boolean): void {
    if (this.compassEnabled !== enabled) {
      this.compassEnabled = enabled;
      this.notifyCompassConfigChanged();
    }
  }

  /**
   * 获取指南针启用状态
   */
  isCompassEnabled(): boolean {
    return this.compassEnabled;
  }

  /**
   * 设置指南针可见性模式
   * @param visibility 可见性模式
   */
  setCompassVisibility(visibility: CompassVisibility): void {
    if (this.compassVisibility !== visibility) {
      this.compassVisibility = visibility;
      this.notifyCompassConfigChanged();
    }
  }

  /**
   * 获取指南针可见性模式
   */
  getCompassVisibility(): CompassVisibility {
    return this.compassVisibility;
  }

  /**
   * 设置指南针在正北时是否淡出
   * @param fade 是否淡出
   */
  setCompassFadeFacingNorth(fade: boolean): void {
    if (this.compassFadeWhenFacingNorth !== fade) {
      this.compassFadeWhenFacingNorth = fade;
      this.notifyCompassConfigChanged();
    }
  }

  /**
   * 获取指南针在正北时是否淡出
   */
  isCompassFadeWhenFacingNorth(): boolean {
    return this.compassFadeWhenFacingNorth;
  }

  /**
   * 设置指南针边距
   * @param left 左边距
   * @param top 上边距
   * @param right 右边距
   * @param bottom 下边距
   */
  setCompassMargins(left: number, top: number, right: number, bottom: number): void {
    this.compassMargins.left = left;
    this.compassMargins.top = top;
    this.compassMargins.right = right;
    this.compassMargins.bottom = bottom;
    this.notifyCompassConfigChanged();
  }

  /**
   * 获取指南针边距
   */
  getCompassMargins(): CompassMargins {
    return this.compassMargins;
  }

  /**
   * 设置指南针位置
   * @param position 位置枚举
   */
  setCompassPosition(position: CompassPosition): void {
    if (this.compassPosition !== position) {
      this.compassPosition = position;
      this.notifyCompassConfigChanged();
    }
  }

  /**
   * 获取指南针位置
   */
  getCompassPosition(): CompassPosition {
    return this.compassPosition;
  }

  /**
   * 通知指南针配置变更
   */
  private notifyCompassConfigChanged(): void {
    if (this.onCompassConfigChanged) {
      this.onCompassConfigChanged();
    }
  }

  // ==================== Logo 配置方法 ====================

  /**
   * 设置 Logo 启用状态
   * @param enabled 是否启用 Logo
   */
  setLogoEnabled(enabled: boolean): void {
    if (this.logoEnabled !== enabled) {
      this.logoEnabled = enabled;
      this.notifyLogoConfigChanged();
    }
  }

  /**
   * 获取 Logo 启用状态
   */
  isLogoEnabled(): boolean {
    return this.logoEnabled;
  }

  /**
   * 设置 Logo 位置
   * @param position 位置枚举
   */
  setLogoPosition(position: CompassPosition): void {
    if (this.logoPosition !== position) {
      this.logoPosition = position;
      this.notifyLogoConfigChanged();
    }
  }

  /**
   * 获取 Logo 位置
   */
  getLogoPosition(): CompassPosition {
    return this.logoPosition;
  }

  /**
   * 设置 Logo 边距
   * @param left 左边距
   * @param top 上边距
   * @param right 右边距
   * @param bottom 下边距
   */
  setLogoMargins(left: number, top: number, right: number, bottom: number): void {
    this.logoMargins.left = left;
    this.logoMargins.top = top;
    this.logoMargins.right = right;
    this.logoMargins.bottom = bottom;
    this.notifyLogoConfigChanged();
  }

  /**
   * 获取 Logo 边距
   */
  getLogoMargins(): CompassMargins {
    return this.logoMargins;
  }

  /**
   * 通知 Logo 配置变更
   */
  private notifyLogoConfigChanged(): void {
    if (this.onLogoConfigChanged) {
      this.onLogoConfigChanged();
    }
  }

  // ==================== ScaleBar 配置方法 ====================

  /**
   * 设置 ScaleBar 启用状态
   * @param enabled 是否启用 ScaleBar
   */
  setScaleBarEnabled(enabled: boolean): void {
    if (this.scaleBarEnabled !== enabled) {
      this.scaleBarEnabled = enabled;
      this.notifyScaleBarConfigChanged();
    }
  }

  /**
   * 获取 ScaleBar 启用状态
   */
  isScaleBarEnabled(): boolean {
    return this.scaleBarEnabled;
  }

  /**
   * 设置 ScaleBar 单位系统
   * @param unit 单位系统（公制/英制）
   */
  setScaleBarUnit(unit: ScaleBarUnit): void {
    if (this.scaleBarUnit !== unit) {
      this.scaleBarUnit = unit;
      this.notifyScaleBarConfigChanged();
    }
  }

  /**
   * 获取 ScaleBar 单位系统
   */
  getScaleBarUnit(): ScaleBarUnit {
    return this.scaleBarUnit;
  }

  /**
   * 设置 ScaleBar 是否使用深色样式
   * @param useDarkStyles 是否使用深色样式
   */
  setScaleBarUseDarkStyles(useDarkStyles: boolean): void {
    if (this.scaleBarUseDarkStyles !== useDarkStyles) {
      this.scaleBarUseDarkStyles = useDarkStyles;
      this.notifyScaleBarConfigChanged();
    }
  }

  /**
   * 获取 ScaleBar 是否使用深色样式
   */
  isScaleBarUseDarkStyles(): boolean {
    return this.scaleBarUseDarkStyles;
  }

  /**
   * 设置 ScaleBar 位置
   * @param position 位置枚举
   */
  setScaleBarPosition(position: CompassPosition): void {
    if (this.scaleBarPosition !== position) {
      this.scaleBarPosition = position;
      this.notifyScaleBarConfigChanged();
    }
  }

  /**
   * 获取 ScaleBar 位置
   */
  getScaleBarPosition(): CompassPosition {
    return this.scaleBarPosition;
  }

  /**
   * 设置 ScaleBar 边距
   * @param left 左边距
   * @param top 上边距
   * @param right 右边距
   * @param bottom 下边距
   */
  setScaleBarMargins(left: number, top: number, right: number, bottom: number): void {
    this.scaleBarMargins.left = left;
    this.scaleBarMargins.top = top;
    this.scaleBarMargins.right = right;
    this.scaleBarMargins.bottom = bottom;
    this.notifyScaleBarConfigChanged();
  }

  /**
   * 获取 ScaleBar 边距
   */
  getScaleBarMargins(): CompassMargins {
    return this.scaleBarMargins;
  }

  /**
   * 通知 ScaleBar 配置变更
   */
  private notifyScaleBarConfigChanged(): void {
    if (this.onScaleBarConfigChanged) {
      this.onScaleBarConfigChanged();
    }
  }
}


