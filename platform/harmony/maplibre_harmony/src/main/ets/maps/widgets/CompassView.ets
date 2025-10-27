/**
 * CompassView - 指南针组件
 * 
 * 参考 Android CompassView 和 iOS MLNCompassButton 实现
 * 用于显示地图方位，点击后归正北
 */

import { CompassVisibility } from './CompassVisibility';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';

// 常量定义（参考 Android CompassView）
const TIME_WAIT_IDLE = 500; // 延迟淡出时间（ms）
const TIME_FADE_ANIMATION = 500; // 淡出动画时长（ms）
const ROTATION_THRESHOLD = 1.0; // 正北判断阈值（度）

@Component
export struct CompassView {
  // 当前旋转角度
  @State private rotation: number = 0;
  
  // 透明度
  @State private opacity: number = 0;
  
  // 是否启用
  @Prop enabled: boolean = true;
  
  // 可见性模式
  @Prop compassVisibility: CompassVisibility = CompassVisibility.Adaptive;
  
  // 是否在正北时淡出
  @Prop fadeWhenFacingNorth: boolean = true;
  
  // 指南针图像资源
  @Prop compassImage: Resource = $r('app.media.compass_icon');
  
  // 点击回调
  onCompassClick?: () => void;
  
  // 淡出定时器
  private fadeTimer: number = -1;

  /**
   * 更新指南针方向
   * @param bearing 地图方位角（顺时针，0为正北）
   */
  update(bearing: number): void {
    // 取反作为旋转角度（参考 iOS 实现）
    this.rotation = -bearing;
    
    if (!this.enabled) {
      return;
    }
    
    // 根据可见性模式和方位角决定显示/隐藏
    switch (this.compassVisibility) {
      case CompassVisibility.Adaptive:
        if (this.isFacingNorth() && this.fadeWhenFacingNorth) {
          // 延迟淡出
          this.scheduleFadeOut();
        } else {
          // 立即显示
          this.cancelFadeOut();
          this.show(true);
        }
        break;
      
      case CompassVisibility.Visible:
        this.show(true);
        break;
      
      case CompassVisibility.Hidden:
        this.hide(true);
        break;
    }
  }
  
  /**
   * 判断是否面向正北
   */
  private isFacingNorth(): boolean {
    // 容差范围：±1度
    const absBearing = Math.abs(this.rotation);
    return absBearing <= ROTATION_THRESHOLD || absBearing >= (360 - ROTATION_THRESHOLD);
  }
  
  /**
   * 显示指南针
   * @param animated 是否使用动画
   */
  private show(animated: boolean): void {
    if (animated) {
      animateTo({
        duration: TIME_FADE_ANIMATION,
        curve: Curve.EaseInOut
      }, () => {
        this.opacity = 1.0;
      });
    } else {
      this.opacity = 1.0;
    }
  }
  
  /**
   * 隐藏指南针
   * @param animated 是否使用动画
   */
  private hide(animated: boolean): void {
    if (animated) {
      animateTo({
        duration: TIME_FADE_ANIMATION,
        curve: Curve.EaseInOut
      }, () => {
        this.opacity = 0;
      });
    } else {
      this.opacity = 0;
    }
  }
  
  /**
   * 计划淡出动画
   */
  private scheduleFadeOut(): void {
    // 取消之前的定时器
    this.cancelFadeOut();
    
    // 延迟后淡出
    this.fadeTimer = setTimeout(() => {
      this.hide(true);
      this.fadeTimer = -1;
    }, TIME_WAIT_IDLE);
  }
  
  /**
   * 取消淡出动画
   */
  private cancelFadeOut(): void {
    if (this.fadeTimer !== -1) {
      clearTimeout(this.fadeTimer);
      this.fadeTimer = -1;
    }
  }
  
  /**
   * 处理点击事件
   */
  private handleClick(): void {
    hilog.info(DOMAIN, 'CompassView', 'Compass clicked, resetting north');
    
    if (this.onCompassClick) {
      this.onCompassClick();
    }
  }
  
  /**
   * 设置启用状态
   */
  setEnabled(enabled: boolean): void {
    this.enabled = enabled;
    
    if (enabled) {
      // 重新计算可见性
      this.update(this.rotation);
    } else {
      this.hide(false);
    }
  }
  
  build() {
    if (!this.enabled) {
      // 禁用时不渲染
      return;
    }
    
    Image(this.compassImage)
      .width(48)
      .height(48)
      .opacity(this.opacity)
      .rotate({
        angle: this.rotation,
        centerX: '50%',
        centerY: '50%'
      })
      .onClick(() => {
        this.handleClick();
      })
      .transition({
        type: TransitionType.All,
        opacity: 1
      })
  }
}

