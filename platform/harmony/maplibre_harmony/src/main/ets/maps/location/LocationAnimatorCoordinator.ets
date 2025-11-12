import { createLatLng, LatLng } from '../geometry/LatLng';

/**
 * Location animation coordinator.
 * Orchestrates smooth animation for position, bearing, accuracy, and related properties.
 */
export class LocationAnimatorCoordinator {
  private static readonly TAG: string = 'LocationAnimatorCoordinator';
  // Current animated values
  private currentLatitude: number = 0;
  private currentLongitude: number = 0;
  private currentBearing: number = 0;
  private currentAccuracy: number = 0;
  // Target values
  private targetLatitude: number = 0;
  private targetLongitude: number = 0;
  private targetBearing: number = 0;
  private targetAccuracy: number = 0;
  // Animation parameters
  private animationDuration: number = 750; // Milliseconds
  private trackingAnimationDurationMultiplier: number = 1.1;
  // Animation timer
  private animationTimer?: number;
  private isAnimating: boolean = false;
  // Callback
  private onLocationUpdate?: (location: LatLng, bearing: number, accuracy: number) => void;

  constructor(onLocationUpdate?: (location: LatLng, bearing: number, accuracy: number) => void) {
    this.onLocationUpdate = onLocationUpdate;
  }

  /**
   * Configure the tracking animation duration multiplier.
   */
  setTrackingAnimationDurationMultiplier(multiplier: number): void {
    this.trackingAnimationDurationMultiplier = multiplier;
  }

  /**
   * Animate a location update.
   */
  animateLocationUpdate(location: LatLng, bearing: number, accuracy: number, animate: boolean = true): void {
    // Apply target values
    this.targetLatitude = location.latitude;
    this.targetLongitude = location.longitude;
    this.targetBearing = bearing;
    this.targetAccuracy = accuracy;

    // Bypass animation if requested
    if (!animate) {
      this.currentLatitude = location.latitude;
      this.currentLongitude = location.longitude;
      this.currentBearing = bearing;
      this.currentAccuracy = accuracy;

      this.notifyUpdate();
      return;
    }

    // If current state is uninitialized, apply directly
    if (this.currentLatitude === 0 && this.currentLongitude === 0) {
      this.currentLatitude = location.latitude;
      this.currentLongitude = location.longitude;
      this.currentBearing = bearing;
      this.currentAccuracy = accuracy;

      this.notifyUpdate();
      return;
    }

    // Begin animation
    this.startAnimation();
  }

  /**
   * Start animation.
   */
  private startAnimation(): void {
    if (this.isAnimating) {
      return;
    }

    this.isAnimating = true;
    const startTime = Date.now();
    const duration = this.animationDuration * this.trackingAnimationDurationMultiplier;

    // Capture starting values
    const startLat = this.currentLatitude;
    const startLng = this.currentLongitude;
    const startBearing = this.currentBearing;
    const startAccuracy = this.currentAccuracy;

    const animate = () => {
      const now = Date.now();
      const elapsed = now - startTime;
      const progress = Math.min(elapsed / duration, 1.0);

      // Apply easing
      const eased = this.easeInOutQuad(progress);

      // Interpolate current values
      this.currentLatitude = this.lerp(startLat, this.targetLatitude, eased);
      this.currentLongitude = this.lerp(startLng, this.targetLongitude, eased);
      this.currentAccuracy = this.lerp(startAccuracy, this.targetAccuracy, eased);

      // Angle interpolation requires special handling for wrap-around
      this.currentBearing = this.lerpAngle(startBearing, this.targetBearing, eased);

      // Notify observers
      this.notifyUpdate();

      // Continue animation or finish
      if (progress < 1.0) {
        this.animationTimer = setTimeout(animate, 16); // ~60 FPS
      } else {
        this.isAnimating = false;
        this.animationTimer = undefined;
      }
    };

    animate();
  }

  /**
   * Stop the animation.
   */
  stopAnimation(): void {
    if (this.animationTimer) {
      clearTimeout(this.animationTimer);
      this.animationTimer = undefined;
    }
    this.isAnimating = false;
  }

  /**
   * Linear interpolation.
   */
  private lerp(start: number, end: number, t: number): number {
    return start + (end - start) * t;
  }

  /**
   * Angle interpolation (handles wrap-around across 0/360).
   */
  private lerpAngle(start: number, end: number, t: number): number {
    let diff = end - start;

    // Handle wrap-around
    if (diff > 180) {
      diff -= 360;
    } else if (diff < -180) {
      diff += 360;
    }

    let result = start + diff * t;

    // Normalize to 0-360
    if (result < 0) {
      result += 360;
    } else if (result >= 360) {
      result -= 360;
    }

    return result;
  }

  /**
   * Ease-in-out-quad easing function.
   */
  private easeInOutQuad(t: number): number {
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }

  /**
   * Notify observers with the current values.
   */
  private notifyUpdate(): void {
    if (this.onLocationUpdate) {
      const location: LatLng = createLatLng(this.currentLatitude, this.currentLongitude);
      this.onLocationUpdate(location, this.currentBearing, this.currentAccuracy);
    }
  }

  /**
   * Get the current location.
   */
  getCurrentLocation(): LatLng {
    return createLatLng(this.currentLatitude, this.currentLongitude);
  }

  /**
   * Get the current bearing.
   */
  getCurrentBearing(): number {
    return this.currentBearing;
  }

  /**
   * Get the current accuracy.
   */
  getCurrentAccuracy(): number {
    return this.currentAccuracy;
  }

  /**
   * Clean up resources.
   */
  dispose(): void {
    this.stopAnimation();
    this.onLocationUpdate = undefined;
  }
}

