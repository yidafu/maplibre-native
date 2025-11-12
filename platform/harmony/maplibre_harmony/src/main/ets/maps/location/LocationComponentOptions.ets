import { LocationComponentConstants } from './LocationComponentConstants';


/**
 * LocationComponent options.
 * Configures the appearance and behavior of the location component.
 */
export class LocationComponentOptions {
  // Accuracy circle configuration
  accuracyAlpha: number = LocationComponentConstants.ACCURACY_ALPHA_DEFAULT;
  accuracyColor: string = '#4264fb';
  // Icon resource configuration
  foregroundDrawable?: ResourceStr;
  backgroundDrawable?: ResourceStr;
  foregroundDrawableStale?: ResourceStr;
  backgroundDrawableStale?: ResourceStr;
  gpsDrawable?: ResourceStr;
  bearingDrawable?: ResourceStr;
  // Icon tint configuration
  foregroundTintColor?: string;
  backgroundTintColor?: string;
  foregroundStaleTintColor?: string;
  backgroundStaleTintColor?: string;
  bearingTintColor?: string;
  // Stale-state configuration
  enableStaleState: boolean = true;
  staleStateTimeout: number = LocationComponentConstants.STALE_STATE_DELAY_MS;
  // Zoom scaling configuration
  maxZoomIconScale: number = LocationComponentConstants.MAX_ZOOM_ICON_SCALE_DEFAULT;
  minZoomIconScale: number = LocationComponentConstants.MIN_ZOOM_ICON_SCALE_DEFAULT;
  // Layer placement configuration
  layerAbove?: string;
  layerBelow?: string;
  // Animation configuration
  trackingAnimationDurationMultiplier: number = 1.1;
  compassAnimationEnabled: boolean = true;
  accuracyAnimationEnabled: boolean = true;
  // Gesture management configuration
  trackingGesturesManagement: boolean = false;
  trackingInitialMoveThreshold: number = 50; // vp
  trackingMultiFingerMoveThreshold: number = 50; // vp

  // Pulse circle configuration
  pulseEnabled: boolean = false;
  pulseFadeEnabled: boolean = true;
  pulseColor?: string;
  pulseSingleDuration: number = 2300;
  pulseMaxRadius: number = 35;
  pulseAlpha: number = 1.0;
  // Shadow configuration
  elevation: number = 0;
  // Padding configuration (deprecated; use CameraPosition padding)
  padding?: number[]; // [left, top, right, bottom]

  constructor(builder?: LocationComponentOptionsBuilder) {
    if (builder) {
      this.accuracyAlpha = builder.accuracyAlpha ?? this.accuracyAlpha;
      this.accuracyColor = builder.accuracyColor ?? this.accuracyColor;
      this.foregroundDrawable = builder.foregroundDrawable;
      this.backgroundDrawable = builder.backgroundDrawable;
      this.foregroundDrawableStale = builder.foregroundDrawableStale;
      this.backgroundDrawableStale = builder.backgroundDrawableStale;
      this.gpsDrawable = builder.gpsDrawable;
      this.bearingDrawable = builder.bearingDrawable;
      this.foregroundTintColor = builder.foregroundTintColor;
      this.backgroundTintColor = builder.backgroundTintColor;
      this.foregroundStaleTintColor = builder.foregroundStaleTintColor;
      this.backgroundStaleTintColor = builder.backgroundStaleTintColor;
      this.bearingTintColor = builder.bearingTintColor;
      this.enableStaleState = builder.enableStaleState ?? this.enableStaleState;
      this.staleStateTimeout = builder.staleStateTimeout ?? this.staleStateTimeout;
      this.maxZoomIconScale = builder.maxZoomIconScale ?? this.maxZoomIconScale;
      this.minZoomIconScale = builder.minZoomIconScale ?? this.minZoomIconScale;
      this.layerAbove = builder.layerAbove;
      this.layerBelow = builder.layerBelow;
      this.trackingAnimationDurationMultiplier =
        builder.trackingAnimationDurationMultiplier ?? this.trackingAnimationDurationMultiplier;
      this.compassAnimationEnabled = builder.compassAnimationEnabled ?? this.compassAnimationEnabled;
      this.accuracyAnimationEnabled = builder.accuracyAnimationEnabled ?? this.accuracyAnimationEnabled;
      this.trackingGesturesManagement = builder.trackingGesturesManagement ?? this.trackingGesturesManagement;
      this.trackingInitialMoveThreshold = builder.trackingInitialMoveThreshold ?? this.trackingInitialMoveThreshold;
      this.trackingMultiFingerMoveThreshold =
        builder.trackingMultiFingerMoveThreshold ?? this.trackingMultiFingerMoveThreshold;
      this.pulseEnabled = builder.pulseEnabled ?? this.pulseEnabled;
      this.pulseFadeEnabled = builder.pulseFadeEnabled ?? this.pulseFadeEnabled;
      this.pulseColor = builder.pulseColor;
      this.pulseSingleDuration = builder.pulseSingleDuration ?? this.pulseSingleDuration;
      this.pulseMaxRadius = builder.pulseMaxRadius ?? this.pulseMaxRadius;
      this.pulseAlpha = builder.pulseAlpha ?? this.pulseAlpha;
      this.elevation = builder.elevation ?? this.elevation;
      this.padding = builder.padding;
    }
  }

  /**
   * Create a builder.
   */
  static builder(): LocationComponentOptionsBuilder {
    return new LocationComponentOptionsBuilder();
  }

  /**
   * Create a builder initialized from the current options.
   */
  toBuilder(): LocationComponentOptionsBuilder {
    const builder = new LocationComponentOptionsBuilder();
    builder.accuracyAlpha = this.accuracyAlpha;
    builder.accuracyColor = this.accuracyColor;
    builder.foregroundDrawable = this.foregroundDrawable;
    builder.backgroundDrawable = this.backgroundDrawable;
    builder.foregroundDrawableStale = this.foregroundDrawableStale;
    builder.backgroundDrawableStale = this.backgroundDrawableStale;
    builder.gpsDrawable = this.gpsDrawable;
    builder.bearingDrawable = this.bearingDrawable;
    builder.foregroundTintColor = this.foregroundTintColor;
    builder.backgroundTintColor = this.backgroundTintColor;
    builder.foregroundStaleTintColor = this.foregroundStaleTintColor;
    builder.backgroundStaleTintColor = this.backgroundStaleTintColor;
    builder.bearingTintColor = this.bearingTintColor;
    builder.enableStaleState = this.enableStaleState;
    builder.staleStateTimeout = this.staleStateTimeout;
    builder.maxZoomIconScale = this.maxZoomIconScale;
    builder.minZoomIconScale = this.minZoomIconScale;
    builder.layerAbove = this.layerAbove;
    builder.layerBelow = this.layerBelow;
    builder.trackingAnimationDurationMultiplier = this.trackingAnimationDurationMultiplier;
    builder.compassAnimationEnabled = this.compassAnimationEnabled;
    builder.accuracyAnimationEnabled = this.accuracyAnimationEnabled;
    builder.trackingGesturesManagement = this.trackingGesturesManagement;
    builder.trackingInitialMoveThreshold = this.trackingInitialMoveThreshold;
    builder.trackingMultiFingerMoveThreshold = this.trackingMultiFingerMoveThreshold;
    builder.pulseEnabled = this.pulseEnabled;
    builder.pulseFadeEnabled = this.pulseFadeEnabled;
    builder.pulseColor = this.pulseColor;
    builder.pulseSingleDuration = this.pulseSingleDuration;
    builder.pulseMaxRadius = this.pulseMaxRadius;
    builder.pulseAlpha = this.pulseAlpha;
    builder.elevation = this.elevation;
    builder.padding = this.padding;
    return builder;
  }
}

/**
 * Builder for `LocationComponentOptions`.
 */
export class LocationComponentOptionsBuilder {
  accuracyAlpha?: number;
  accuracyColor?: string;
  foregroundDrawable?: ResourceStr;
  backgroundDrawable?: ResourceStr;
  foregroundDrawableStale?: ResourceStr;
  backgroundDrawableStale?: ResourceStr;
  gpsDrawable?: ResourceStr;
  bearingDrawable?: ResourceStr;
  foregroundTintColor?: string;
  backgroundTintColor?: string;
  foregroundStaleTintColor?: string;
  backgroundStaleTintColor?: string;
  bearingTintColor?: string;
  enableStaleState?: boolean;
  staleStateTimeout?: number;
  maxZoomIconScale?: number;
  minZoomIconScale?: number;
  layerAbove?: string;
  layerBelow?: string;
  trackingAnimationDurationMultiplier?: number;
  compassAnimationEnabled?: boolean;
  accuracyAnimationEnabled?: boolean;
  trackingGesturesManagement?: boolean;
  trackingInitialMoveThreshold?: number;
  trackingMultiFingerMoveThreshold?: number;
  pulseEnabled?: boolean;
  pulseFadeEnabled?: boolean;
  pulseColor?: string;
  pulseSingleDuration?: number;
  pulseMaxRadius?: number;
  pulseAlpha?: number;
  elevation?: number;
  padding?: number[];

  setAccuracyAlpha(alpha: number): LocationComponentOptionsBuilder {
    if (alpha < 0 || alpha > 1) {
      throw new Error('Accuracy alpha value must be between 0.0 and 1.0.');
    }
    this.accuracyAlpha = alpha;
    return this;
  }

  setAccuracyColor(color: string): LocationComponentOptionsBuilder {
    this.accuracyColor = color;
    return this;
  }

  setForegroundDrawable(drawable: ResourceStr): LocationComponentOptionsBuilder {
    this.foregroundDrawable = drawable;
    return this;
  }

  setBackgroundDrawable(drawable: ResourceStr): LocationComponentOptionsBuilder {
    this.backgroundDrawable = drawable;
    return this;
  }

  setForegroundDrawableStale(drawable: ResourceStr): LocationComponentOptionsBuilder {
    this.foregroundDrawableStale = drawable;
    return this;
  }

  setBackgroundDrawableStale(drawable: ResourceStr): LocationComponentOptionsBuilder {
    this.backgroundDrawableStale = drawable;
    return this;
  }

  setGpsDrawable(drawable: ResourceStr): LocationComponentOptionsBuilder {
    this.gpsDrawable = drawable;
    return this;
  }

  setBearingDrawable(drawable: ResourceStr): LocationComponentOptionsBuilder {
    this.bearingDrawable = drawable;
    return this;
  }

  setForegroundTintColor(color: string): LocationComponentOptionsBuilder {
    this.foregroundTintColor = color;
    return this;
  }

  setBackgroundTintColor(color: string): LocationComponentOptionsBuilder {
    this.backgroundTintColor = color;
    return this;
  }

  setForegroundStaleTintColor(color: string): LocationComponentOptionsBuilder {
    this.foregroundStaleTintColor = color;
    return this;
  }

  setBackgroundStaleTintColor(color: string): LocationComponentOptionsBuilder {
    this.backgroundStaleTintColor = color;
    return this;
  }

  setBearingTintColor(color: string): LocationComponentOptionsBuilder {
    this.bearingTintColor = color;
    return this;
  }

  setEnableStaleState(enabled: boolean): LocationComponentOptionsBuilder {
    this.enableStaleState = enabled;
    return this;
  }

  setStaleStateTimeout(timeout: number): LocationComponentOptionsBuilder {
    this.staleStateTimeout = timeout;
    return this;
  }

  setMaxZoomIconScale(scale: number): LocationComponentOptionsBuilder {
    this.maxZoomIconScale = scale;
    return this;
  }

  setMinZoomIconScale(scale: number): LocationComponentOptionsBuilder {
    this.minZoomIconScale = scale;
    return this;
  }

  setLayerAbove(layerId: string): LocationComponentOptionsBuilder {
    this.layerAbove = layerId;
    return this;
  }

  setLayerBelow(layerId: string): LocationComponentOptionsBuilder {
    this.layerBelow = layerId;
    return this;
  }

  setTrackingAnimationDurationMultiplier(multiplier: number): LocationComponentOptionsBuilder {
    this.trackingAnimationDurationMultiplier = multiplier;
    return this;
  }

  setCompassAnimationEnabled(enabled: boolean): LocationComponentOptionsBuilder {
    this.compassAnimationEnabled = enabled;
    return this;
  }

  setAccuracyAnimationEnabled(enabled: boolean): LocationComponentOptionsBuilder {
    this.accuracyAnimationEnabled = enabled;
    return this;
  }

  setTrackingGesturesManagement(enabled: boolean): LocationComponentOptionsBuilder {
    this.trackingGesturesManagement = enabled;
    return this;
  }

  setTrackingInitialMoveThreshold(threshold: number): LocationComponentOptionsBuilder {
    this.trackingInitialMoveThreshold = threshold;
    return this;
  }

  setTrackingMultiFingerMoveThreshold(threshold: number): LocationComponentOptionsBuilder {
    this.trackingMultiFingerMoveThreshold = threshold;
    return this;
  }

  setPulseEnabled(enabled: boolean): LocationComponentOptionsBuilder {
    this.pulseEnabled = enabled;
    return this;
  }

  setPulseFadeEnabled(enabled: boolean): LocationComponentOptionsBuilder {
    this.pulseFadeEnabled = enabled;
    return this;
  }

  setPulseColor(color: string): LocationComponentOptionsBuilder {
    this.pulseColor = color;
    return this;
  }

  setPulseSingleDuration(duration: number): LocationComponentOptionsBuilder {
    this.pulseSingleDuration = duration;
    return this;
  }

  setPulseMaxRadius(radius: number): LocationComponentOptionsBuilder {
    this.pulseMaxRadius = radius;
    return this;
  }

  setPulseAlpha(alpha: number): LocationComponentOptionsBuilder {
    this.pulseAlpha = alpha;
    return this;
  }

  setElevation(elevation: number): LocationComponentOptionsBuilder {
    if (elevation < 0) {
      throw new Error('Invalid shadow size ' + elevation + '. Must be >= 0');
    }
    this.elevation = elevation;
    return this;
  }

  setPadding(padding: number[]): LocationComponentOptionsBuilder {
    if (padding.length !== 4) {
      throw new Error('Padding must have 4 elements: [left, top, right, bottom]');
    }
    this.padding = padding;
    return this;
  }

  build(): LocationComponentOptions {
    // Validate configuration
    if (this.layerAbove && this.layerBelow) {
      throw new Error('You cannot set both layerAbove and layerBelow options. Choose one or the other.');
    }

    return new LocationComponentOptions(this);
  }
}

