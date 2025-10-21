import { LatLng } from './geometry/LatLng';
import { LatLngBounds } from './geometry/LatLngBounds';
import { CameraPosition } from './camera/CameraPosition';

/**
 * MapLibreMapOptions - 地图选项配置类
 */
export class MapLibreMapOptions {
  // 基础配置
  public pixelRatio: number = 1.0;
  public contextMode: string = 'unique';
  public crossSourceCollisions: boolean = true;
  public size: { width: number; height: number } = { width: 256, height: 256 };
  
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
  public tileLodPitchThreshold: number = 0;
  public tileLodZoomShift: number = 0;
  
  // 光照配置
  public light: any = null;
  
  // 过渡动画配置
  public transitionDuration: number = 300;
  public transitionDelay: number = 0;
  
  constructor(options?: Partial<MapLibreMapOptions>) {
    if (options) {
      Object.assign(this, options);
    }
  }
  
}
