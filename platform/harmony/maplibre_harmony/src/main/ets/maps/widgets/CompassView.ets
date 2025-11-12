/**
 * CompassView - compass component.
 *
 * Inspired by Android CompassView and iOS MLNCompassButton implementations.
 * Displays map orientation and recenters to north when tapped.
 */

import { CompassVisibility } from './CompassVisibility';
// Constants (aligned with Android CompassView).
const TIME_WAIT_IDLE = 500; // Delay before fade-out (ms).
const TIME_FADE_ANIMATION = 500; // Fade-out animation duration (ms).
const ROTATION_THRESHOLD = 1.0; // Threshold for north alignment (degrees).

@Component
export struct CompassView {
  // Original bearing value (used to detect facing north).
  private bearing: number = 0;
  // Current rotation angle (view rotation using negative bearing).
  @State private rotation: number = 0;
  // Opacity.
  @State private compassOpacity: number = 0;
  // Enabled flag.
  @Prop compassEnabled: boolean = true;
  // Visibility mode.
  @Prop compassVisibility: CompassVisibility = CompassVisibility.Adaptive;
  // Whether to fade when facing north.
  @Prop fadeWhenFacingNorth: boolean = true;
  // Compass image resource.
  @Prop compassImage: Resource = $r('app.media.compass_icon');
  // External bearing input (map orientation).
  @Prop @Watch('onBearingChanged') externalBearing: number = 0;
  // Tap callback.
  onCompassClick?: () => void;
  // Fade-out timer.
  private fadeTimer: number = -1;

  /**
   * Bearing change listener.
   */
  onBearingChanged(): void {
    this.update(this.externalBearing);
  }

  /**
   * Component initialization.
   */
  aboutToAppear(): void {
    this.update(this.externalBearing);
  }

  /**
   * Update the compass orientation.
   * @param bearing Map bearing in degrees (clockwise, 0 is north).
   */
  update(bearing: number): void {
    // Store the original bearing (for north detection, see Android/iOS).
    this.bearing = bearing;

    // Negate to derive the rotation angle (mirrors the iOS approach).
    this.rotation = -bearing;

    if (!this.compassEnabled) {
      return;
    }

    // Determine visibility based on mode and bearing.
    switch (this.compassVisibility) {
      case CompassVisibility.Adaptive:
        // Refer to iOS: show when direction > 0, otherwise hide.
        // Refer to Android: if not hidden, show; otherwise schedule fade-out.
        if (this.isFacingNorth() && this.fadeWhenFacingNorth) {
          // Delay fade-out when aligned with north.
          this.scheduleFadeOut();
        } else {
          // Show immediately when not facing north.
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
   * Determine whether the compass is facing true north.
   * Android reference: Math.abs(rotation) >= 359.0 || Math.abs(rotation) <= 1.0.
   * iOS reference: direction == 0 (with tolerance).
   */
  private isFacingNorth(): boolean {
    // Use the original bearing value (consistent with Android/iOS).
    const absBearing = Math.abs(this.bearing);
    return absBearing <= ROTATION_THRESHOLD || absBearing >= (360 - ROTATION_THRESHOLD);
  }

  /**
   * Show the compass.
   * @param animated Whether to animate.
   */
  private show(animated: boolean): void {
    // The animation property automatically applies to compassOpacity changes.
    this.compassOpacity = 1.0;
  }

  /**
   * Hide the compass.
   * @param animated Whether to animate.
   */
  private hide(animated: boolean): void {
    // The animation property automatically applies to compassOpacity changes.
    this.compassOpacity = 0;
  }

  /**
   * Schedule the fade-out animation.
   */
  private scheduleFadeOut(): void {
    // Cancel the previous timer.
    this.cancelFadeOut();

    // Fade out after a delay.
    this.fadeTimer = setTimeout(() => {
      this.hide(true);
      this.fadeTimer = -1;
    }, TIME_WAIT_IDLE);
  }

  /**
   * Cancel the fade-out animation.
   */
  private cancelFadeOut(): void {
    if (this.fadeTimer !== -1) {
      clearTimeout(this.fadeTimer);
      this.fadeTimer = -1;
    }
  }

  /**
   * Handle compass tap events.
   */
  private handleClick(): void {

    if (this.onCompassClick) {
      this.onCompassClick();
    }
  }

  /**
   * Set the enabled state.
   */
  setEnabled(enabled: boolean): void {
    this.compassEnabled = enabled;

    if (enabled) {
      // Re-evaluate visibility (using the original bearing).
      this.update(this.bearing);
    } else {
      this.hide(false);
    }
  }

  build() {
    if (this.compassEnabled) {
      Image(this.compassImage)
        .width(48)
        .height(48)
        .opacity(this.compassOpacity)
        .rotate({
          angle: this.rotation,
          centerX: '50%',
          centerY: '50%'
        })
        .animation({ duration: TIME_FADE_ANIMATION, curve: Curve.EaseInOut })
        .onClick(() => {
          this.handleClick();
        })
        .transition({
          type: TransitionType.All,
          opacity: 1
        })
    }
  }
}

