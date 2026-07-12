import { LatLngBounds } from './geometry/LatLngBounds';
import { CameraPosition } from './camera/CameraPosition';
import type { LightSpecification } from 'libmaplibre.so';
import type { Size } from './types/NativeTypes';

/**
 * MapLibreMapOptions - map configuration options
 */
export class MapLibreMapOptions {
  // Basic configuration
  public pixelRatio: number = 1.0;
  public contextMode: string = 'unique';
  public crossSourceCollisions: boolean = true;
  public size: Size = { width: 256, height: 256 };
  // Camera configuration
  public cameraPosition: CameraPosition | null = null;
  public bounds: LatLngBounds | null = null;
  public minZoom: number = 0;
  public maxZoom: number = 22;
  public minPitch: number = 0;
  public maxPitch: number = 60;
  // Style configuration
  public styleUrl: string = '';
  public styleJson: string = '';
  // Rendering configuration
  public renderWorldCopies: boolean = true;
  public renderMode: string = 'normal';
  public constrainMode: string = 'heightOnly';
  public viewportMode: string = 'default';
  // Debug configuration
  public debug: boolean = false;
  public attributionEnabled: boolean = true;
  public logoEnabled: boolean = true;
  public compassEnabled: boolean = true;
  public scaleBarEnabled: boolean = true;
  // Interaction configuration
  public scrollEnabled: boolean = true;
  public zoomEnabled: boolean = true;
  public rotateEnabled: boolean = true;
  public tiltEnabled: boolean = true;
  public doubleTapToZoomInEnabled: boolean = true;
  public quickZoomEnabled: boolean = true;
  public twoFingerTouchRotationEnabled: boolean = true;
  public twoFingerTouchPitchEnabled: boolean = true;
  // Performance configuration
  public prefetchTiles: boolean = true;
  public prefetchZoomDelta: number = 4;
  public tileCacheEnabled: boolean = true;
  // Tile LOD configuration
  /** Minimum radius around the view point in tile units where fine-grained zoom level tiles are always used.
   *  0 = disabled (always use highest LOD). Must be >= 1 when enabled. */
  public tileLodMinRadius: number = 0;
  /** Factor for the distance to the camera view point.
   *  A value larger than 1 increases the distance, reducing LOD effect. 1.0 = no scaling (default). */
  public tileLodScale: number = 1.0;
  // Local glyph configuration
  // HarmonyOS font families (priority order):
  // 1. HarmonyOS Sans series (official font, variable font covers all weights)
  //    - HarmonyOS_Sans.ttf (default, multilingual support)
  //    - HarmonyOS_Sans_SC.ttf (Simplified Chinese optimized)
  //    - HarmonyOS_Sans_TC.ttf (Traditional Chinese)
  //    - HarmonyOS_Sans_Digit.ttf (numeric glyphs)
  //    - HarmonyOS_Sans_Condensed.ttf (condensed variant)
  // 2. Noto Sans series (Google open-source fallback)
  //    - NotoSansCJK-Regular.ttc (CJK unified font)
  //    - NotoSans-Regular.ttf (base font)
  //    - NotoSans[wdth,wght].ttf (variable font)
  // 3. DroidSansFallback.ttf (final fallback)
  public localIdeographFontFamily: string | null = 'HarmonyOS_Sans';
  public localIdeographEnabled: boolean = true;
  /** Pitch angle in radians above which LOD calculation is performed. 0 = always perform LOD. */
  public tileLodPitchThreshold: number = 0;
  /** Shift applied to the zoom level during LOD calculation.
   *  A negative value shifts to coarser levels (reducing quality, improving performance).
   *  0 = no shift (default). */
  public tileLodZoomShift: number = 0;
  // Lighting
  public light: LightSpecification | null = null;
  // Transition animation
  public transitionDuration: number = 300;
  public transitionDelay: number = 0;

  constructor(options?: Partial<MapLibreMapOptions>) {
    if (options) {
      // Manually copy properties, avoiding Object.assign
      if (options.pixelRatio !== undefined) {
        this.pixelRatio = options.pixelRatio;
      }
      if (options.contextMode !== undefined) {
        this.contextMode = options.contextMode;
      }
      if (options.crossSourceCollisions !== undefined) {
        this.crossSourceCollisions = options.crossSourceCollisions;
      }
      if (options.size !== undefined) {
        this.size = options.size;
      }
      if (options.cameraPosition !== undefined) {
        this.cameraPosition = options.cameraPosition;
      }
      if (options.bounds !== undefined) {
        this.bounds = options.bounds;
      }
      if (options.minZoom !== undefined) {
        this.minZoom = options.minZoom;
      }
      if (options.maxZoom !== undefined) {
        this.maxZoom = options.maxZoom;
      }
      if (options.minPitch !== undefined) {
        this.minPitch = options.minPitch;
      }
      if (options.maxPitch !== undefined) {
        this.maxPitch = options.maxPitch;
      }
      if (options.styleUrl !== undefined) {
        this.styleUrl = options.styleUrl;
      }
      if (options.styleJson !== undefined) {
        this.styleJson = options.styleJson;
      }
      if (options.renderWorldCopies !== undefined) {
        this.renderWorldCopies = options.renderWorldCopies;
      }
      if (options.renderMode !== undefined) {
        this.renderMode = options.renderMode;
      }
      if (options.constrainMode !== undefined) {
        this.constrainMode = options.constrainMode;
      }
      if (options.viewportMode !== undefined) {
        this.viewportMode = options.viewportMode;
      }
      if (options.debug !== undefined) {
        this.debug = options.debug;
      }
      if (options.attributionEnabled !== undefined) {
        this.attributionEnabled = options.attributionEnabled;
      }
      if (options.logoEnabled !== undefined) {
        this.logoEnabled = options.logoEnabled;
      }
      if (options.compassEnabled !== undefined) {
        this.compassEnabled = options.compassEnabled;
      }
      if (options.scaleBarEnabled !== undefined) {
        this.scaleBarEnabled = options.scaleBarEnabled;
      }
      if (options.scrollEnabled !== undefined) {
        this.scrollEnabled = options.scrollEnabled;
      }
      if (options.zoomEnabled !== undefined) {
        this.zoomEnabled = options.zoomEnabled;
      }
      if (options.rotateEnabled !== undefined) {
        this.rotateEnabled = options.rotateEnabled;
      }
      if (options.tiltEnabled !== undefined) {
        this.tiltEnabled = options.tiltEnabled;
      }
      if (options.doubleTapToZoomInEnabled !== undefined) {
        this.doubleTapToZoomInEnabled =
          options.doubleTapToZoomInEnabled;
      }
      if (options.quickZoomEnabled !== undefined) {
        this.quickZoomEnabled = options.quickZoomEnabled;
      }
      if (options.twoFingerTouchRotationEnabled !== undefined) {
        this.twoFingerTouchRotationEnabled =
          options.twoFingerTouchRotationEnabled;
      }
      if (options.twoFingerTouchPitchEnabled !== undefined) {
        this.twoFingerTouchPitchEnabled =
          options.twoFingerTouchPitchEnabled;
      }
      if (options.prefetchTiles !== undefined) {
        this.prefetchTiles = options.prefetchTiles;
      }
      if (options.prefetchZoomDelta !== undefined) {
        this.prefetchZoomDelta = options.prefetchZoomDelta;
      }
      if (options.tileCacheEnabled !== undefined) {
        this.tileCacheEnabled = options.tileCacheEnabled;
      }
      if (options.tileLodMinRadius !== undefined) {
        this.tileLodMinRadius = options.tileLodMinRadius;
      }
      if (options.tileLodScale !== undefined) {
        this.tileLodScale = options.tileLodScale;
      }
      if (options.tileLodPitchThreshold !== undefined) {
        this.tileLodPitchThreshold = options.tileLodPitchThreshold;
      }
      if (options.tileLodZoomShift !== undefined) {
        this.tileLodZoomShift = options.tileLodZoomShift;
      }
      if (options.light !== undefined) {
        this.light = options.light;
      }
      if (options.transitionDuration !== undefined) {
        this.transitionDuration = options.transitionDuration;
      }
      if (options.transitionDelay !== undefined) {
        this.transitionDelay = options.transitionDelay;
      }
    }
  }
}
