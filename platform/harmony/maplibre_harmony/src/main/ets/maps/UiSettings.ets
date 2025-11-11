import { CompassVisibility } from './widgets/CompassVisibility';
import { OrnamentPosition, Margins } from './types/NativeTypes';
import { ScaleBarUnit } from './widgets/ScaleBarView';
import { WidgetLayoutHelper, Offset2D } from './widgets/WidgetLayoutTypes';

/**
 * Focal point data type
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
 * UiSettings
 *
 * Manages gesture enablement and UI component configuration for the map.
 * Mirrors Android UiSettings and iOS MLNMapView properties.
 */

export class UiSettings {
  // Gesture enablement flags
  private scrollGesturesEnabled: boolean = true;
  private zoomGesturesEnabled: boolean = true;
  private rotateGesturesEnabled: boolean = true;
  private tiltGesturesEnabled: boolean = true;
  private doubleTapGesturesEnabled: boolean = true;
  private quickZoomGesturesEnabled: boolean = true;
  // Scroll configuration
  private horizontalScrollGesturesEnabled: boolean = true;
  // Gesture sensitivity configuration
  private focalPoint: FocalPoint | null = null;
  // Inertial animation toggles
  private flingVelocityAnimationEnabled: boolean = true;
  private scaleVelocityAnimationEnabled: boolean = true;
  private rotateVelocityAnimationEnabled: boolean = true;
  // Animation parameters
  private decelerationRate: number = 0.35; // iOS style (0-1), higher = longer animation
  private flingAnimationBaseTime: number = 300; // Base animation duration (ms)
  private flingThreshold: number = 100; // Velocity threshold (px/s)

  // Velocity thresholds
  private minFlingVelocity: number = 100; // Minimum pan velocity (px/s)
  private minScaleVelocity: number = 0.5; // Minimum scale velocity
  private minRotateVelocity: number = 5; // Minimum rotation velocity (deg/s)

  // Tilt configuration
  private minPitch: number = 0; // Minimum pitch (deg)
  private maxPitch: number = 60; // Maximum pitch (deg)
  private tiltSensitivity: number = 0.5; // Tilt sensitivity (slowdown factor)

  // Quick zoom configuration
  private quickZoomMaxChange: number = 4; // Maximum quick zoom delta

  // Zoom configuration
  private zoomRate: number = 1.0; // Zoom rate multiplier (mirrors Android UiSettings)

  // Rotation configuration
  private rotationRate: number = 1.0; // Rotation sensitivity multiplier

  // ==================== Compass configuration ====================

  // Compass enablement
  private compassEnabled: boolean = false;
  // Compass visibility mode
  private compassVisibility: CompassVisibility = CompassVisibility.Adaptive;
  // Fade when facing north
  private compassFadeWhenFacingNorth: boolean = true;
  // Compass alignment (ArkUI Alignment)
  private compassAlignment: Alignment = Alignment.TopEnd;
  // Compass margins
  private compassMargins: Margins = { left: 10, top: 10, right: 10, bottom: 10 };
  // Optional compass offset
  private compassOffset?: Offset2D;
  // Compass configuration change callback (injected by MapLibreMap)
  public onCompassConfigChanged?: () => void;
  // ==================== Logo configuration ====================

  // Logo enablement
  private logoEnabled: boolean = false;
  // Logo alignment (ArkUI Alignment)
  private logoAlignment: Alignment = Alignment.BottomStart;
  // Logo margins
  private logoMargins: Margins = { left: 10, top: 10, right: 10, bottom: 10 };
  // Optional logo offset
  private logoOffset?: Offset2D;
  // Logo configuration callback
  public onLogoConfigChanged?: () => void;
  // ==================== ScaleBar configuration ====================

  // ScaleBar enablement
  private scaleBarEnabled: boolean = true; // Enabled by default

  // ScaleBar units
  private scaleBarUnit: ScaleBarUnit = ScaleBarUnit.Metric;
  // Dark theme toggle for ScaleBar
  private scaleBarUseDarkStyles: boolean = false;
  // ScaleBar alignment (ArkUI Alignment)
  private scaleBarAlignment: Alignment = Alignment.TopStart;
  // ScaleBar margins
  private scaleBarMargins: Margins = { left: 10, top: 10, right: 10, bottom: 10 };
  // Optional ScaleBar offset
  private scaleBarOffset?: Offset2D;
  // ScaleBar configuration callback
  public onScaleBarConfigChanged?: () => void;
  // ==================== Attribution configuration ====================

  // Attribution enablement
  private attributionEnabled: boolean = true;
  // Attribution alignment (ArkUI Alignment)
  private attributionAlignment: Alignment = Alignment.BottomEnd;
  // Attribution margins
  private attributionMargins: Margins = { left: 10, top: 10, right: 10, bottom: 10 };
  // Optional attribution offset
  private attributionOffset?: Offset2D;
  // Attribution configuration callback
  public onAttributionConfigChanged?: () => void;

  // ==================== Gesture configuration ====================

  /**
   * Enable or disable scroll gestures (panning)
   */
  setScrollGesturesEnabled(enabled: boolean): UiSettings {
    this.scrollGesturesEnabled = enabled;
    return this;
  }

  /**
   * Check whether scroll gestures are enabled
   */
  isScrollGesturesEnabled(): boolean {
    return this.scrollGesturesEnabled;
  }

  /**
   * Enable or disable zoom gestures
   */
  setZoomGesturesEnabled(enabled: boolean): UiSettings {
    this.zoomGesturesEnabled = enabled;
    return this;
  }

  /**
   * Check whether zoom gestures are enabled
   */
  isZoomGesturesEnabled(): boolean {
    return this.zoomGesturesEnabled;
  }

  /**
   * Enable or disable rotate gestures
   */
  setRotateGesturesEnabled(enabled: boolean): UiSettings {
    this.rotateGesturesEnabled = enabled;
    return this;
  }

  /**
   * Check whether rotate gestures are enabled
   */
  isRotateGesturesEnabled(): boolean {
    return this.rotateGesturesEnabled;
  }

  /**
   * Enable or disable tilt gestures (two-finger drag adjusts pitch)
   */
  setTiltGesturesEnabled(enabled: boolean): UiSettings {
    this.tiltGesturesEnabled = enabled;
    return this;
  }

  /**
   * Check whether tilt gestures are enabled
   */
  isTiltGesturesEnabled(): boolean {
    return this.tiltGesturesEnabled;
  }

  /**
   * Enable or disable double-tap zoom gestures
   */
  setDoubleTapGesturesEnabled(enabled: boolean): UiSettings {
    this.doubleTapGesturesEnabled = enabled;
    return this;
  }

  /**
   * Check whether double-tap zoom gestures are enabled
   */
  isDoubleTapGesturesEnabled(): boolean {
    return this.doubleTapGesturesEnabled;
  }

  /**
   * Enable or disable quick zoom gestures (double-tap and drag)
   */
  setQuickZoomGesturesEnabled(enabled: boolean): UiSettings {
    this.quickZoomGesturesEnabled = enabled;
    return this;
  }

  /**
   * Check whether quick zoom gestures are enabled
   */
  isQuickZoomGesturesEnabled(): boolean {
    return this.quickZoomGesturesEnabled;
  }

  /**
   * Enable or disable horizontal scroll gestures
   */
  setHorizontalScrollGesturesEnabled(enabled: boolean): UiSettings {
    this.horizontalScrollGesturesEnabled = enabled;
    return this;
  }

  /**
   * Check whether horizontal scrolling is enabled
   */
  isHorizontalScrollGesturesEnabled(): boolean {
    return this.horizontalScrollGesturesEnabled;
  }

  /**
   * Set the gesture focal point
   * @param point Focal coordinates; null uses the default focal point
   */
  setFocalPoint(point: FocalPoint | null): UiSettings {
    this.focalPoint = point;
    return this;
  }

  /**
   * Get the gesture focal point
   */
  getFocalPoint(): FocalPoint | null {
    return this.focalPoint;
  }

  /**
   * Enable or disable all gestures
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

  // ==================== Inertial animation configuration ====================

  /**
   * Enable or disable fling velocity animation
   * @param enabled Whether the animation is enabled
   */
  setFlingVelocityAnimationEnabled(enabled: boolean): UiSettings {
    this.flingVelocityAnimationEnabled = enabled;
    return this;
  }

  /**
   * Check whether fling velocity animation is enabled
   */
  isFlingVelocityAnimationEnabled(): boolean {
    return this.flingVelocityAnimationEnabled;
  }

  /**
   * Enable or disable scale velocity animation
   * @param enabled Whether the animation is enabled
   */
  setScaleVelocityAnimationEnabled(enabled: boolean): UiSettings {
    this.scaleVelocityAnimationEnabled = enabled;
    return this;
  }

  /**
   * Check whether scale velocity animation is enabled
   */
  isScaleVelocityAnimationEnabled(): boolean {
    return this.scaleVelocityAnimationEnabled;
  }

  /**
   * Enable or disable rotate velocity animation
   * @param enabled Whether the animation is enabled
   */
  setRotateVelocityAnimationEnabled(enabled: boolean): UiSettings {
    this.rotateVelocityAnimationEnabled = enabled;
    return this;
  }

  /**
   * Check whether rotate velocity animation is enabled
   */
  isRotateVelocityAnimationEnabled(): boolean {
    return this.rotateVelocityAnimationEnabled;
  }

  /**
   * Toggle all velocity-driven animations at once
   * @param enabled Whether the animations are enabled
   */
  setAllVelocityAnimationsEnabled(enabled: boolean): UiSettings {
    this.flingVelocityAnimationEnabled = enabled;
    this.scaleVelocityAnimationEnabled = enabled;
    this.rotateVelocityAnimationEnabled = enabled;
    return this;
  }

  /**
   * Set the deceleration rate (0-1)
   * Higher values mean longer animations and slower deceleration
   * @param rate Deceleration rate
   */
  setDecelerationRate(rate: number): void {
    this.decelerationRate = Math.max(0, Math.min(1, rate)); // Clamp to 0-1
  }

  /**
   * Get the deceleration rate
   */
  getDecelerationRate(): number {
    return this.decelerationRate;
  }

  /**
   * Set fling velocity threshold
   * @param threshold Threshold in pixels per second
   */
  setFlingThreshold(threshold: number): void {
    this.flingThreshold = Math.max(0, threshold);
  }

  /**
   * Get fling velocity threshold
   */
  getFlingThreshold(): number {
    return this.flingThreshold;
  }

  /**
   * Set base fling animation duration
   * @param time Duration in milliseconds
   */
  setFlingAnimationBaseTime(time: number): void {
    this.flingAnimationBaseTime = Math.max(0, time);
  }

  /**
   * Get base fling animation duration
   */
  getFlingAnimationBaseTime(): number {
    return this.flingAnimationBaseTime;
  }

  /**
   * Set minimum pan velocity threshold
   * @param velocity Velocity in pixels per second
   */
  setMinFlingVelocity(velocity: number): void {
    this.minFlingVelocity = Math.max(0, velocity);
  }

  /**
   * Get minimum pan velocity threshold
   */
  getMinFlingVelocity(): number {
    return this.minFlingVelocity;
  }

  /**
   * Set minimum scale velocity threshold
   * @param velocity Velocity
   */
  setMinScaleVelocity(velocity: number): void {
    this.minScaleVelocity = Math.max(0, velocity);
  }

  /**
   * Get minimum scale velocity threshold
   */
  getMinScaleVelocity(): number {
    return this.minScaleVelocity;
  }

  /**
   * Set minimum rotation velocity threshold
   * @param velocity Velocity in degrees per second
   */
  setMinRotateVelocity(velocity: number): void {
    this.minRotateVelocity = Math.max(0, velocity);
  }

  /**
   * Get minimum rotation velocity threshold
   */
  getMinRotateVelocity(): number {
    return this.minRotateVelocity;
  }

  // ==================== Tilt configuration ====================

  /**
   * Set minimum pitch
   */
  setMinPitch(pitch: number): void {
    this.minPitch = Math.max(0, Math.min(60, pitch));
  }

  /**
   * Get minimum pitch
   */
  getMinPitch(): number {
    return this.minPitch;
  }

  /**
   * Set maximum pitch
   */
  setMaxPitch(pitch: number): void {
    this.maxPitch = Math.max(0, Math.min(60, pitch));
  }

  /**
   * Get maximum pitch
   */
  getMaxPitch(): number {
    return this.maxPitch;
  }

  /**
   * Set tilt sensitivity
   * Larger values slow the tilt down (slowdown factor)
   */
  setTiltSensitivity(sensitivity: number): void {
    this.tiltSensitivity = Math.max(0.1, Math.min(5.0, sensitivity));
  }

  /**
   * Get tilt sensitivity
   */
  getTiltSensitivity(): number {
    return this.tiltSensitivity;
  }

  // ==================== Quick zoom configuration ====================

  /**
   * Set maximum quick zoom delta
   */
  setQuickZoomMaxChange(maxChange: number): void {
    this.quickZoomMaxChange = Math.max(1, Math.min(10, maxChange));
  }

  /**
   * Get maximum quick zoom delta
   */
  getQuickZoomMaxChange(): number {
    return this.quickZoomMaxChange;
  }

  // ==================== Zoom rate configuration ====================

  /**
   * Set zoom rate multiplier
   * Mirrors Android UiSettings.setZoomRate()
   * @param rate Zoom rate multiplier (default 1.0)
   */
  setZoomRate(rate: number): void {
    this.zoomRate = Math.max(0.1, Math.min(10.0, rate));
  }

  /**
   * Get zoom rate multiplier
   */
  getZoomRate(): number {
    return this.zoomRate;
  }

  // ==================== Rotation rate configuration ====================

  /**
   * Set rotation rate multiplier
   * @param rate Rotation rate multiplier (default 1.0; smaller slows rotation)
   */
  setRotationRate(rate: number): void {
    this.rotationRate = Math.max(0.1, Math.min(10.0, rate));
  }

  /**
   * Get rotation rate multiplier
   */
  getRotationRate(): number {
    return this.rotationRate;
  }

  // ==================== Compass configuration methods ====================

  /**
   * Enable or disable the compass
   * @param enabled Whether the compass is enabled
   */
  setCompassEnabled(enabled: boolean): void {
    if (this.compassEnabled !== enabled) {
      this.compassEnabled = enabled;
      this.notifyCompassConfigChanged();
    }
  }

  /**
   * Check whether the compass is enabled
   */
  isCompassEnabled(): boolean {
    return this.compassEnabled;
  }

  /**
   * Set compass visibility mode
   * @param visibility Visibility mode
   */
  setCompassVisibility(visibility: CompassVisibility): void {
    if (this.compassVisibility !== visibility) {
      this.compassVisibility = visibility;
      this.notifyCompassConfigChanged();
    }
  }

  /**
   * Get compass visibility mode
   */
  getCompassVisibility(): CompassVisibility {
    return this.compassVisibility;
  }

  /**
   * Control whether the compass fades when facing north
   * @param fade Whether to fade
   */
  setCompassFadeFacingNorth(fade: boolean): void {
    if (this.compassFadeWhenFacingNorth !== fade) {
      this.compassFadeWhenFacingNorth = fade;
      this.notifyCompassConfigChanged();
    }
  }

  /**
   * Check whether the compass fades when facing north
   */
  isCompassFadeWhenFacingNorth(): boolean {
    return this.compassFadeWhenFacingNorth;
  }

  /**
   * Set compass margins
   * @param left Left margin
   * @param top Top margin
   * @param right Right margin
   * @param bottom Bottom margin
   */
  setCompassMargins(left: number, top: number, right: number, bottom: number): void {
    this.compassMargins.left = left;
    this.compassMargins.top = top;
    this.compassMargins.right = right;
    this.compassMargins.bottom = bottom;
    this.notifyCompassConfigChanged();
  }

  /**
   * Get compass margins
   */
  getCompassMargins(): Margins {
    return this.compassMargins;
  }
  
  /**
   * Get compass left margin
   */
  getCompassMarginLeft(): number {
    return this.compassMargins.left;
  }
  
  /**
   * Get compass top margin
   */
  getCompassMarginTop(): number {
    return this.compassMargins.top;
  }
  
  /**
   * Get compass right margin
   */
  getCompassMarginRight(): number {
    return this.compassMargins.right;
  }
  
  /**
   * Get compass bottom margin
   */
  getCompassMarginBottom(): number {
    return this.compassMargins.bottom;
  }

  /**
   * Set compass alignment (ArkUI style)
   * @param alignment ArkUI Alignment
   */
  setCompassAlignment(alignment: Alignment): void {
    if (this.compassAlignment !== alignment) {
      this.compassAlignment = alignment;
      this.notifyCompassConfigChanged();
    }
  }

  /**
   * Get compass alignment
   */
  getCompassAlignment(): Alignment {
    return this.compassAlignment;
  }
  
  /**
   * Set additional compass offset
   * @param offset Offset { x, y } in vp
   */
  setCompassOffset(offset: Offset2D | undefined): void {
    this.compassOffset = offset;
    this.notifyCompassConfigChanged();
  }

  /**
   * Get additional compass offset
   */
  getCompassOffset(): Offset2D | undefined {
    return this.compassOffset;
  }

  /**
   * Set compass position (backward compatibility)
   * @param position Ornament position enum
   * @deprecated Use setCompassAlignment() instead
   */
  setCompassPosition(position: OrnamentPosition): void {
    const alignment = WidgetLayoutHelper.ornamentPositionToAlignment(position);
    this.setCompassAlignment(alignment);
  }

  /**
   * Get compass position (backward compatibility)
   * @deprecated Use getCompassAlignment() instead
   */
  getCompassPosition(): OrnamentPosition {
    const position = WidgetLayoutHelper.alignmentToOrnamentPosition(this.compassAlignment);
    return position !== null ? position : OrnamentPosition.TopRight;
  }

  /**
   * Notify compass configuration change
   */
  private notifyCompassConfigChanged(): void {
    if (this.onCompassConfigChanged) {
      this.onCompassConfigChanged();
    }
  }

  // ==================== Logo configuration methods ====================

  /**
   * Enable or disable the logo
   * @param enabled Whether the logo is enabled
   */
  setLogoEnabled(enabled: boolean): void {
    if (this.logoEnabled !== enabled) {
      this.logoEnabled = enabled;
      this.notifyLogoConfigChanged();
    }
  }

  /**
   * Check whether the logo is enabled
   */
  isLogoEnabled(): boolean {
    return this.logoEnabled;
  }

  /**
   * Set logo alignment (ArkUI style)
   * @param alignment ArkUI Alignment
   */
  setLogoAlignment(alignment: Alignment): void {
    if (this.logoAlignment !== alignment) {
      this.logoAlignment = alignment;
      this.notifyLogoConfigChanged();
    }
  }

  /**
   * Get logo alignment
   */
  getLogoAlignment(): Alignment {
    return this.logoAlignment;
  }

  /**
   * Set logo position (backward compatibility)
   * @param position Ornament position enum
   * @deprecated Use setLogoAlignment() instead
   */
  setLogoPosition(position: OrnamentPosition): void {
    const alignment = WidgetLayoutHelper.ornamentPositionToAlignment(position);
    this.setLogoAlignment(alignment);
  }

  /**
   * Get logo position (backward compatibility)
   * @deprecated Use getLogoAlignment() instead
   */
  getLogoPosition(): OrnamentPosition {
    const position = WidgetLayoutHelper.alignmentToOrnamentPosition(this.logoAlignment);
    return position !== null ? position : OrnamentPosition.BottomLeft;
  }

  /**
   * Set logo margins
   * @param left Left margin
   * @param top Top margin
   * @param right Right margin
   * @param bottom Bottom margin
   */
  setLogoMargins(left: number, top: number, right: number, bottom: number): void {
    this.logoMargins.left = left;
    this.logoMargins.top = top;
    this.logoMargins.right = right;
    this.logoMargins.bottom = bottom;
    this.notifyLogoConfigChanged();
  }

  /**
   * Get logo margins
   */
  getLogoMargins(): Margins {
    return this.logoMargins;
  }
  
  /**
   * Get logo left margin
   */
  getLogoMarginLeft(): number {
    return this.logoMargins.left;
  }
  
  /**
   * Get logo top margin
   */
  getLogoMarginTop(): number {
    return this.logoMargins.top;
  }
  
  /**
   * Get logo right margin
   */
  getLogoMarginRight(): number {
    return this.logoMargins.right;
  }
  
  /**
   * Get logo bottom margin
   */
  getLogoMarginBottom(): number {
    return this.logoMargins.bottom;
  }
  
  /**
   * Set additional logo offset
   * @param offset Offset { x, y } in vp
   */
  setLogoOffset(offset: Offset2D | undefined): void {
    this.logoOffset = offset;
    this.notifyLogoConfigChanged();
  }

  /**
   * Get additional logo offset
   */
  getLogoOffset(): Offset2D | undefined {
    return this.logoOffset;
  }

  /**
   * Notify logo configuration change
   */
  private notifyLogoConfigChanged(): void {
    if (this.onLogoConfigChanged) {
      this.onLogoConfigChanged();
    }
  }

  // ==================== ScaleBar configuration methods ====================

  /**
   * Enable or disable the ScaleBar
   * @param enabled Whether the ScaleBar is enabled
   */
  setScaleBarEnabled(enabled: boolean): void {
    if (this.scaleBarEnabled !== enabled) {
      this.scaleBarEnabled = enabled;
      this.notifyScaleBarConfigChanged();
    }
  }

  /**
   * Check whether the ScaleBar is enabled
   */
  isScaleBarEnabled(): boolean {
    return this.scaleBarEnabled;
  }

  /**
   * Set ScaleBar unit system
   * @param unit Unit system (metric/imperial)
   */
  setScaleBarUnit(unit: ScaleBarUnit): void {
    if (this.scaleBarUnit !== unit) {
      this.scaleBarUnit = unit;
      this.notifyScaleBarConfigChanged();
    }
  }

  /**
   * Get ScaleBar unit system
   */
  getScaleBarUnit(): ScaleBarUnit {
    return this.scaleBarUnit;
  }

  /**
   * Toggle dark style for ScaleBar
   * @param useDarkStyles Whether to use dark styles
   */
  setScaleBarUseDarkStyles(useDarkStyles: boolean): void {
    if (this.scaleBarUseDarkStyles !== useDarkStyles) {
      this.scaleBarUseDarkStyles = useDarkStyles;
      this.notifyScaleBarConfigChanged();
    }
  }

  /**
   * Check whether ScaleBar uses dark styles
   */
  isScaleBarUseDarkStyles(): boolean {
    return this.scaleBarUseDarkStyles;
  }

  /**
   * Set ScaleBar alignment (ArkUI style)
   * @param alignment ArkUI Alignment
   */
  setScaleBarAlignment(alignment: Alignment): void {
    if (this.scaleBarAlignment !== alignment) {
      this.scaleBarAlignment = alignment;
      this.notifyScaleBarConfigChanged();
    }
  }

  /**
   * Get ScaleBar alignment
   */
  getScaleBarAlignment(): Alignment {
    return this.scaleBarAlignment;
  }

  /**
   * Set ScaleBar position (backward compatibility)
   * @param position Ornament position enum
   * @deprecated Use setScaleBarAlignment() instead
   */
  setScaleBarPosition(position: OrnamentPosition): void {
    const alignment = WidgetLayoutHelper.ornamentPositionToAlignment(position);
    this.setScaleBarAlignment(alignment);
  }

  /**
   * Get ScaleBar position (backward compatibility)
   * @deprecated Use getScaleBarAlignment() instead
   */
  getScaleBarPosition(): OrnamentPosition {
    const position = WidgetLayoutHelper.alignmentToOrnamentPosition(this.scaleBarAlignment);
    return position !== null ? position : OrnamentPosition.TopLeft;
  }

  /**
   * Set ScaleBar margins
   * @param left Left margin
   * @param top Top margin
   * @param right Right margin
   * @param bottom Bottom margin
   */
  setScaleBarMargins(left: number, top: number, right: number, bottom: number): void {
    this.scaleBarMargins.left = left;
    this.scaleBarMargins.top = top;
    this.scaleBarMargins.right = right;
    this.scaleBarMargins.bottom = bottom;
    this.notifyScaleBarConfigChanged();
  }

  /**
   * Get ScaleBar margins
   */
  getScaleBarMargins(): Margins {
    return this.scaleBarMargins;
  }
  
  /**
   * Get ScaleBar left margin
   */
  getScaleBarMarginLeft(): number {
    return this.scaleBarMargins.left;
  }
  
  /**
   * Get ScaleBar top margin
   */
  getScaleBarMarginTop(): number {
    return this.scaleBarMargins.top;
  }
  
  /**
   * Get ScaleBar right margin
   */
  getScaleBarMarginRight(): number {
    return this.scaleBarMargins.right;
  }
  
  /**
   * Get ScaleBar bottom margin
   */
  getScaleBarMarginBottom(): number {
    return this.scaleBarMargins.bottom;
  }
  
  /**
   * Set additional ScaleBar offset
   * @param offset Offset { x, y } in vp
   */
  setScaleBarOffset(offset: Offset2D | undefined): void {
    this.scaleBarOffset = offset;
    this.notifyScaleBarConfigChanged();
  }

  /**
   * Get additional ScaleBar offset
   */
  getScaleBarOffset(): Offset2D | undefined {
    return this.scaleBarOffset;
  }

  /**
   * Notify ScaleBar configuration change
   */
  private notifyScaleBarConfigChanged(): void {
    if (this.onScaleBarConfigChanged) {
      this.onScaleBarConfigChanged();
    }
  }

  // ==================== Attribution configuration methods ====================

  /**
   * Enable or disable attribution control
   * @param enabled Whether attribution is enabled
   */
  setAttributionEnabled(enabled: boolean): void {
    if (this.attributionEnabled !== enabled) {
      this.attributionEnabled = enabled;
      this.notifyAttributionConfigChanged();
    }
  }

  /**
   * Check whether attribution is enabled
   */
  isAttributionEnabled(): boolean {
    return this.attributionEnabled;
  }

  /**
   * Set attribution alignment (ArkUI style)
   * @param alignment ArkUI Alignment
   */
  setAttributionAlignment(alignment: Alignment): void {
    if (this.attributionAlignment !== alignment) {
      this.attributionAlignment = alignment;
      this.notifyAttributionConfigChanged();
    }
  }

  /**
   * Get attribution alignment
   */
  getAttributionAlignment(): Alignment {
    return this.attributionAlignment;
  }

  /**
   * Set attribution position (backward compatibility)
   * @param position Ornament position enum
   * @deprecated Use setAttributionAlignment() instead
   */
  setAttributionPosition(position: OrnamentPosition): void {
    const alignment = WidgetLayoutHelper.ornamentPositionToAlignment(position);
    this.setAttributionAlignment(alignment);
  }

  /**
   * Get attribution position (backward compatibility)
   * @deprecated Use getAttributionAlignment() instead
   */
  getAttributionPosition(): OrnamentPosition {
    const position = WidgetLayoutHelper.alignmentToOrnamentPosition(this.attributionAlignment);
    return position !== null ? position : OrnamentPosition.BottomRight;
  }

  /**
   * Set attribution margins
   * @param left Left margin
   * @param top Top margin
   * @param right Right margin
   * @param bottom Bottom margin
   */
  setAttributionMargins(left: number, top: number, right: number, bottom: number): void {
    this.attributionMargins.left = left;
    this.attributionMargins.top = top;
    this.attributionMargins.right = right;
    this.attributionMargins.bottom = bottom;
    this.notifyAttributionConfigChanged();
  }

  /**
   * Get attribution margins
   */
  getAttributionMargins(): Margins {
    return this.attributionMargins;
  }
  
  /**
   * Get attribution left margin
   */
  getAttributionMarginLeft(): number {
    return this.attributionMargins.left;
  }
  
  /**
   * Get attribution top margin
   */
  getAttributionMarginTop(): number {
    return this.attributionMargins.top;
  }
  
  /**
   * Get attribution right margin
   */
  getAttributionMarginRight(): number {
    return this.attributionMargins.right;
  }
  
  /**
   * Get attribution bottom margin
   */
  getAttributionMarginBottom(): number {
    return this.attributionMargins.bottom;
  }
  
  /**
   * Set additional attribution offset
   * @param offset Offset { x, y } in vp
   */
  setAttributionOffset(offset: Offset2D | undefined): void {
    this.attributionOffset = offset;
    this.notifyAttributionConfigChanged();
  }

  /**
   * Get additional attribution offset
   */
  getAttributionOffset(): Offset2D | undefined {
    return this.attributionOffset;
  }

  /**
   * Notify attribution configuration change
   */
  private notifyAttributionConfigChanged(): void {
    if (this.onAttributionConfigChanged) {
      this.onAttributionConfigChanged();
    }
  }
}


