import { createLatLng, LatLng } from '../geometry/LatLng';

/**
 * 位置动画协调器
 * 负责协调位置、方向、精度等属性的平滑动画
 */
export class LocationAnimatorCoordinator {
  private static readonly TAG: string = 'LocationAnimatorCoordinator';
  // 当前动画值
  private currentLatitude: number = 0;
  private currentLongitude: number = 0;
  private currentBearing: number = 0;
  private currentAccuracy: number = 0;
  // 目标值
  private targetLatitude: number = 0;
  private targetLongitude: number = 0;
  private targetBearing: number = 0;
  private targetAccuracy: number = 0;
  // 动画参数
  private animationDuration: number = 750; // 毫秒
  private trackingAnimationDurationMultiplier: number = 1.1;
  // 动画定时器
  private animationTimer?: number;
  private isAnimating: boolean = false;
  // 回调
  private onLocationUpdate?: (location: LatLng, bearing: number, accuracy: number) => void;

  constructor(onLocationUpdate?: (location: LatLng, bearing: number, accuracy: number) => void) {
    this.onLocationUpdate = onLocationUpdate;
  }

  /**
   * 设置跟踪动画时长倍数
   */
  setTrackingAnimationDurationMultiplier(multiplier: number): void {
    this.trackingAnimationDurationMultiplier = multiplier;
  }

  /**
   * 动画更新位置
   */
  animateLocationUpdate(location: LatLng, bearing: number, accuracy: number, animate: boolean = true): void {
    // 设置目标值
    this.targetLatitude = location.latitude;
    this.targetLongitude = location.longitude;
    this.targetBearing = bearing;
    this.targetAccuracy = accuracy;

    // 如果不需要动画，直接设置
    if (!animate) {
      this.currentLatitude = location.latitude;
      this.currentLongitude = location.longitude;
      this.currentBearing = bearing;
      this.currentAccuracy = accuracy;

      this.notifyUpdate();
      return;
    }

    // 如果当前位置未初始化，直接设置
    if (this.currentLatitude === 0 && this.currentLongitude === 0) {
      this.currentLatitude = location.latitude;
      this.currentLongitude = location.longitude;
      this.currentBearing = bearing;
      this.currentAccuracy = accuracy;

      this.notifyUpdate();
      return;
    }

    // 开始动画
    this.startAnimation();
  }

  /**
   * 开始动画
   */
  private startAnimation(): void {
    if (this.isAnimating) {
      return;
    }

    this.isAnimating = true;
    const startTime = Date.now();
    const duration = this.animationDuration * this.trackingAnimationDurationMultiplier;

    // 记录起始值
    const startLat = this.currentLatitude;
    const startLng = this.currentLongitude;
    const startBearing = this.currentBearing;
    const startAccuracy = this.currentAccuracy;

    const animate = () => {
      const now = Date.now();
      const elapsed = now - startTime;
      const progress = Math.min(elapsed / duration, 1.0);

      // 使用缓动函数
      const eased = this.easeInOutQuad(progress);

      // 插值计算当前值
      this.currentLatitude = this.lerp(startLat, this.targetLatitude, eased);
      this.currentLongitude = this.lerp(startLng, this.targetLongitude, eased);
      this.currentAccuracy = this.lerp(startAccuracy, this.targetAccuracy, eased);

      // 角度插值需要特殊处理（处理跨越 0/360 边界的情况）
      this.currentBearing = this.lerpAngle(startBearing, this.targetBearing, eased);

      // 通知更新
      this.notifyUpdate();

      // 继续动画或结束
      if (progress < 1.0) {
        this.animationTimer = setTimeout(animate, 16); // 约 60 FPS
      } else {
        this.isAnimating = false;
        this.animationTimer = undefined;
      }
    };

    animate();
  }

  /**
   * 停止动画
   */
  stopAnimation(): void {
    if (this.animationTimer) {
      clearTimeout(this.animationTimer);
      this.animationTimer = undefined;
    }
    this.isAnimating = false;
  }

  /**
   * 线性插值
   */
  private lerp(start: number, end: number, t: number): number {
    return start + (end - start) * t;
  }

  /**
   * 角度插值（处理跨越 0/360 边界）
   */
  private lerpAngle(start: number, end: number, t: number): number {
    let diff = end - start;

    // 处理跨越边界
    if (diff > 180) {
      diff -= 360;
    } else if (diff < -180) {
      diff += 360;
    }

    let result = start + diff * t;

    // 归一化到 0-360
    if (result < 0) {
      result += 360;
    } else if (result >= 360) {
      result -= 360;
    }

    return result;
  }

  /**
   * 缓动函数：ease-in-out-quad
   */
  private easeInOutQuad(t: number): number {
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }

  /**
   * 通知更新
   */
  private notifyUpdate(): void {
    if (this.onLocationUpdate) {
      const location: LatLng = createLatLng(this.currentLatitude, this.currentLongitude);
      this.onLocationUpdate(location, this.currentBearing, this.currentAccuracy);
    }
  }

  /**
   * 获取当前位置
   */
  getCurrentLocation(): LatLng {
    return createLatLng(this.currentLatitude, this.currentLongitude);
  }

  /**
   * 获取当前方向
   */
  getCurrentBearing(): number {
    return this.currentBearing;
  }

  /**
   * 获取当前精度
   */
  getCurrentAccuracy(): number {
    return this.currentAccuracy;
  }

  /**
   * 清理资源
   */
  dispose(): void {
    this.stopAnimation();
    this.onLocationUpdate = undefined;
  }
}

