/**
 * NativeMapOptions - 原生地图选项类
 */
interface NativeMapSize {
  width: number;
  height: number;
}

export class NativeMapOptions {
  public pixelRatio: number;
  public contextMode: string;
  public crossSourceCollisions: boolean;
  public size: NativeMapSize;
  public debug: boolean;
  public attributionEnabled: boolean;
  public logoEnabled: boolean;
  public compassEnabled: boolean;
  public scrollEnabled: boolean;
  public zoomEnabled: boolean;
  public rotateEnabled: boolean;
  public tiltEnabled: boolean;
  public doubleTapToZoomInEnabled: boolean;
  public quickZoomEnabled: boolean;
  public twoFingerTouchRotationEnabled: boolean;
  public twoFingerTouchPitchEnabled: boolean;
  public prefetchTiles: boolean;
  public prefetchZoomDelta: number;
  public tileCacheEnabled: boolean;
  public tileLodMinRadius: number;
  public tileLodScale: number;
  public tileLodPitchThreshold: number;
  public tileLodZoomShift: number;
  public transitionDuration: number;
  public transitionDelay: number;

  constructor(options: {
    pixelRatio?: number;
    contextMode?: string;
    crossSourceCollisions?: boolean;
    size?: NativeMapSize;
    debug?: boolean;
    attributionEnabled?: boolean;
    logoEnabled?: boolean;
    compassEnabled?: boolean;
    scrollEnabled?: boolean;
    zoomEnabled?: boolean;
    rotateEnabled?: boolean;
    tiltEnabled?: boolean;
    doubleTapToZoomInEnabled?: boolean;
    quickZoomEnabled?: boolean;
    twoFingerTouchRotationEnabled?: boolean;
    twoFingerTouchPitchEnabled?: boolean;
    prefetchTiles?: boolean;
    prefetchZoomDelta?: number;
    tileCacheEnabled?: boolean;
    tileLodMinRadius?: number;
    tileLodScale?: number;
    tileLodPitchThreshold?: number;
    tileLodZoomShift?: number;
    transitionDuration?: number;
    transitionDelay?: number;
  }) {
    this.pixelRatio = options.pixelRatio || 1.0;
    this.contextMode = options.contextMode || 'unique';
    this.crossSourceCollisions = options.crossSourceCollisions !== undefined ? options.crossSourceCollisions : true;
    this.size = options.size || { width: 256, height: 256 };
    this.debug = options.debug || false;
    this.attributionEnabled = options.attributionEnabled !== undefined ? options.attributionEnabled : true;
    this.logoEnabled = options.logoEnabled !== undefined ? options.logoEnabled : true;
    this.compassEnabled = options.compassEnabled !== undefined ? options.compassEnabled : true;
    this.scrollEnabled = options.scrollEnabled !== undefined ? options.scrollEnabled : true;
    this.zoomEnabled = options.zoomEnabled !== undefined ? options.zoomEnabled : true;
    this.rotateEnabled = options.rotateEnabled !== undefined ? options.rotateEnabled : true;
    this.tiltEnabled = options.tiltEnabled !== undefined ? options.tiltEnabled : true;
    this.doubleTapToZoomInEnabled = options.doubleTapToZoomInEnabled !== undefined ? options.doubleTapToZoomInEnabled : true;
    this.quickZoomEnabled = options.quickZoomEnabled !== undefined ? options.quickZoomEnabled : true;
    this.twoFingerTouchRotationEnabled = options.twoFingerTouchRotationEnabled !== undefined ? options.twoFingerTouchRotationEnabled : true;
    this.twoFingerTouchPitchEnabled = options.twoFingerTouchPitchEnabled !== undefined ? options.twoFingerTouchPitchEnabled : true;
    this.prefetchTiles = options.prefetchTiles !== undefined ? options.prefetchTiles : true;
    this.prefetchZoomDelta = options.prefetchZoomDelta || 4;
    this.tileCacheEnabled = options.tileCacheEnabled !== undefined ? options.tileCacheEnabled : true;
    this.tileLodMinRadius = options.tileLodMinRadius || 0;
    this.tileLodScale = options.tileLodScale || 1.0;
    this.tileLodPitchThreshold = options.tileLodPitchThreshold || 0;
    this.tileLodZoomShift = options.tileLodZoomShift || 0;
    this.transitionDuration = options.transitionDuration || 300;
    this.transitionDelay = options.transitionDelay || 0;
  }

  /**
   * 转换为JSON
   */
  public toJSON(): any {
    return {
      pixelRatio: this.pixelRatio,
      contextMode: this.contextMode,
      crossSourceCollisions: this.crossSourceCollisions,
      size: this.size,
      debug: this.debug,
      attributionEnabled: this.attributionEnabled,
      logoEnabled: this.logoEnabled,
      compassEnabled: this.compassEnabled,
      scrollEnabled: this.scrollEnabled,
      zoomEnabled: this.zoomEnabled,
      rotateEnabled: this.rotateEnabled,
      tiltEnabled: this.tiltEnabled,
      doubleTapToZoomInEnabled: this.doubleTapToZoomInEnabled,
      quickZoomEnabled: this.quickZoomEnabled,
      twoFingerTouchRotationEnabled: this.twoFingerTouchRotationEnabled,
      twoFingerTouchPitchEnabled: this.twoFingerTouchPitchEnabled,
      prefetchTiles: this.prefetchTiles,
      prefetchZoomDelta: this.prefetchZoomDelta,
      tileCacheEnabled: this.tileCacheEnabled,
      tileLodMinRadius: this.tileLodMinRadius,
      tileLodScale: this.tileLodScale,
      tileLodPitchThreshold: this.tileLodPitchThreshold,
      tileLodZoomShift: this.tileLodZoomShift,
      transitionDuration: this.transitionDuration,
      transitionDelay: this.transitionDelay
    };
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return `NativeMapOptions(pixelRatio=${this.pixelRatio}, size=${this.size.width}x${this.size.height})`;
  }
}
