import { LatLng } from './geometry/LatLng';
import { LatLngBounds } from './geometry/LatLngBounds';
import { CameraPosition } from './camera/CameraPosition';

/**
 * MapSize - 地图尺寸接口
 */
export interface MapSize {
  width: number;
  height: number;
}

/**
 * MapLibreMapOptions - 地图选项配置类
 */
export class MapLibreMapOptions {
  // 基础配置
  public pixelRatio: number = 1.0;
  public contextMode: string = 'unique';
  public crossSourceCollisions: boolean = true;
  public size: MapSize = { width: 256, height: 256 };
  
  // 相机配置
  public cameraPosition: CameraPosition | null = null;
  public bounds: LatLngBounds | null = null;
  public minZoom: number = 0;
  public maxZoom: number = 22;
  public minPitch: number = 0;
  public maxPitch: number = 60;
  
  // 样式配置
  public styleUrl: string = '';
  public styleJson: string = '';
  
  // 渲染配置
  public renderWorldCopies: boolean = true;
  public renderMode: string = 'normal';
  public constrainMode: string = 'heightOnly';
  public viewportMode: string = 'default';
  
  // 调试配置
  public debug: boolean = false;
  public attributionEnabled: boolean = true;
  public logoEnabled: boolean = true;
  public compassEnabled: boolean = true;
  
  // 交互配置
  public scrollEnabled: boolean = true;
  public zoomEnabled: boolean = true;
  public rotateEnabled: boolean = true;
  public tiltEnabled: boolean = true;
  public doubleTapToZoomInEnabled: boolean = true;
  public quickZoomEnabled: boolean = true;
  public twoFingerTouchRotationEnabled: boolean = true;
  public twoFingerTouchPitchEnabled: boolean = true;
  
  // 性能配置
  public prefetchTiles: boolean = true;
  public prefetchZoomDelta: number = 4;
  public tileCacheEnabled: boolean = true;
  
  // 图层细节级别配置
  public tileLodMinRadius: number = 0;
  public tileLodScale: number = 1.0;
  
  // Local glyph 配置
  public localIdeographFontFamily: string | null = 'sans-serif';
  public localIdeographEnabled: boolean = true;
  public tileLodPitchThreshold: number = 0;
  public tileLodZoomShift: number = 0;
  
  // 光照配置
  public light: Object | null = null;
  
  // 过渡动画配置
  public transitionDuration: number = 300;
  public transitionDelay: number = 0;
  
  constructor(options?: Partial<MapLibreMapOptions>) {
    if (options) {
      // 手动复制属性，避免使用 Object.assign
      if (options.pixelRatio !== undefined) this.pixelRatio = options.pixelRatio;
      if (options.contextMode !== undefined) this.contextMode = options.contextMode;
      if (options.crossSourceCollisions !== undefined) this.crossSourceCollisions = options.crossSourceCollisions;
      if (options.size !== undefined) this.size = options.size;
      if (options.cameraPosition !== undefined) this.cameraPosition = options.cameraPosition;
      if (options.bounds !== undefined) this.bounds = options.bounds;
      if (options.minZoom !== undefined) this.minZoom = options.minZoom;
      if (options.maxZoom !== undefined) this.maxZoom = options.maxZoom;
      if (options.minPitch !== undefined) this.minPitch = options.minPitch;
      if (options.maxPitch !== undefined) this.maxPitch = options.maxPitch;
      if (options.styleUrl !== undefined) this.styleUrl = options.styleUrl;
      if (options.styleJson !== undefined) this.styleJson = options.styleJson;
      if (options.renderWorldCopies !== undefined) this.renderWorldCopies = options.renderWorldCopies;
      if (options.renderMode !== undefined) this.renderMode = options.renderMode;
      if (options.constrainMode !== undefined) this.constrainMode = options.constrainMode;
      if (options.viewportMode !== undefined) this.viewportMode = options.viewportMode;
      if (options.debug !== undefined) this.debug = options.debug;
      if (options.attributionEnabled !== undefined) this.attributionEnabled = options.attributionEnabled;
      if (options.logoEnabled !== undefined) this.logoEnabled = options.logoEnabled;
      if (options.compassEnabled !== undefined) this.compassEnabled = options.compassEnabled;
      if (options.scrollEnabled !== undefined) this.scrollEnabled = options.scrollEnabled;
      if (options.zoomEnabled !== undefined) this.zoomEnabled = options.zoomEnabled;
      if (options.rotateEnabled !== undefined) this.rotateEnabled = options.rotateEnabled;
      if (options.tiltEnabled !== undefined) this.tiltEnabled = options.tiltEnabled;
      if (options.doubleTapToZoomInEnabled !== undefined) this.doubleTapToZoomInEnabled = options.doubleTapToZoomInEnabled;
      if (options.quickZoomEnabled !== undefined) this.quickZoomEnabled = options.quickZoomEnabled;
      if (options.twoFingerTouchRotationEnabled !== undefined) this.twoFingerTouchRotationEnabled = options.twoFingerTouchRotationEnabled;
      if (options.twoFingerTouchPitchEnabled !== undefined) this.twoFingerTouchPitchEnabled = options.twoFingerTouchPitchEnabled;
      if (options.prefetchTiles !== undefined) this.prefetchTiles = options.prefetchTiles;
      if (options.prefetchZoomDelta !== undefined) this.prefetchZoomDelta = options.prefetchZoomDelta;
      if (options.tileCacheEnabled !== undefined) this.tileCacheEnabled = options.tileCacheEnabled;
      if (options.tileLodMinRadius !== undefined) this.tileLodMinRadius = options.tileLodMinRadius;
      if (options.tileLodScale !== undefined) this.tileLodScale = options.tileLodScale;
      if (options.tileLodPitchThreshold !== undefined) this.tileLodPitchThreshold = options.tileLodPitchThreshold;
      if (options.tileLodZoomShift !== undefined) this.tileLodZoomShift = options.tileLodZoomShift;
      if (options.light !== undefined) this.light = options.light;
      if (options.transitionDuration !== undefined) this.transitionDuration = options.transitionDuration;
      if (options.transitionDelay !== undefined) this.transitionDelay = options.transitionDelay;
    }
  }
  
}
