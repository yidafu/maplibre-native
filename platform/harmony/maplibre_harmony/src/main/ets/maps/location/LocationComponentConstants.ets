/**
 * LocationComponent 常量定义
 */
export class LocationComponentConstants {
  // 图层和源名称
  static readonly LOCATION_SOURCE: string = 'maplibre-location-source';
  static readonly ACCURACY_LAYER: string = 'maplibre-location-accuracy-layer';
  static readonly BACKGROUND_LAYER: string = 'maplibre-location-background-layer';
  static readonly FOREGROUND_LAYER: string = 'maplibre-location-foreground-layer';
  static readonly BEARING_LAYER: string = 'maplibre-location-bearing-layer';

  // 图标名称
  static readonly FOREGROUND_ICON: string = 'maplibre-location-foreground-icon';
  static readonly BACKGROUND_ICON: string = 'maplibre-location-background-icon';
  static readonly FOREGROUND_STALE_ICON: string = 'maplibre-location-foreground-stale-icon';
  static readonly BACKGROUND_STALE_ICON: string = 'maplibre-location-background-stale-icon';
  static readonly BEARING_ICON: string = 'maplibre-location-bearing-icon';
  static readonly GPS_ICON: string = 'maplibre-location-gps-icon';

  // 属性名称
  static readonly PROPERTY_LOCATION_STALE: string = 'maplibre-property-location-stale';
  static readonly PROPERTY_GPS_BEARING: string = 'maplibre-property-gps-bearing';
  static readonly PROPERTY_COMPASS_BEARING: string = 'maplibre-property-compass-bearing';
  static readonly PROPERTY_ACCURACY_RADIUS: string = 'maplibre-property-accuracy-radius';
  static readonly PROPERTY_ACCURACY_COLOR: string = 'maplibre-property-accuracy-color';
  static readonly PROPERTY_ACCURACY_ALPHA: string = 'maplibre-property-accuracy-alpha';
  static readonly PROPERTY_FOREGROUND_ICON_OFFSET: string = 'maplibre-property-foreground-icon-offset';
  static readonly PROPERTY_SHADOW_ICON_OFFSET: string = 'maplibre-property-shadow-icon-offset';

  // 默认值
  static readonly DEFAULT_INTERVAL_MILLIS: number = 1000;
  static readonly DEFAULT_FASTEST_INTERVAL_MILLIS: number = 1000;
  static readonly TRANSITION_ANIMATION_DURATION_MS: number = 750;
  static readonly DEFAULT_TRACKING_TILT_ANIM_DURATION: number = 1250;
  static readonly DEFAULT_TRACKING_ZOOM_ANIM_DURATION: number = 1250;
  static readonly DEFAULT_TRACKING_PADDING_ANIM_DURATION: number = 1000;
  static readonly ACCURACY_ALPHA_DEFAULT: number = 0.15;
  static readonly MIN_ZOOM_ICON_SCALE_DEFAULT: number = 0.6;
  static readonly MAX_ZOOM_ICON_SCALE_DEFAULT: number = 1.0;
  static readonly STALE_STATE_DELAY_MS: number = 30000;

  // 动画
  static readonly COMPASS_UPDATE_RATE_MS: number = 500;
  static readonly LOCATION_UPDATE_DELAY_MS: number = 250;
}

