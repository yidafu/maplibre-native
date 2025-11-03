import maplibre from 'libmaplibre.so';
import { MapLibreMap } from '../MapLibreMap';
import { LocationComponentOptions } from './LocationComponentOptions';
import { CameraMode } from './modes/CameraMode';
import { OnCameraTrackingChangedListener } from './listeners/OnCameraTrackingChangedListener';
import { LatLng } from '../geometry/LatLng';
import { CameraPosition, CameraOptions } from '../camera/CameraPosition';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';

type ESObject = object;

/**
 * 位置相机控制器
 * 负责管理相机跟踪用户位置的行为
 */
export class LocationCameraController {
  private static readonly TAG: string = 'LocationCameraController';

  private maplibreMap: MapLibreMap;
  private options: LocationComponentOptions;
  private cameraMode: number = CameraMode.NONE;
  private cameraTrackingChangedListener?: OnCameraTrackingChangedListener;
  
  // 当前跟踪的位置和方向
  private lastLocation?: LatLng;
  private lastBearing: number = 0;
  
  // 手势打断跟踪的检测
  private isTransitioning: boolean = false;
  private userInteracting: boolean = false;

  constructor(
    maplibreMap: MapLibreMap,
    options: LocationComponentOptions,
    cameraTrackingChangedListener?: OnCameraTrackingChangedListener
  ) {
    this.maplibreMap = maplibreMap;
    this.options = options;
    this.cameraTrackingChangedListener = cameraTrackingChangedListener;
    
    // 监听相机移动事件，检测用户手势
    this.setupGestureDetection();
  }

  /**
   * 设置相机模式
   */
  setCameraMode(mode: number): void {
    if (!CameraMode.isValid(mode)) {
      hilog.error(DOMAIN, LocationCameraController.TAG, `Invalid camera mode: ${mode}`);
      return;
    }

    if (this.cameraMode === mode) {
      return;
    }

    const oldMode = this.cameraMode;
    this.cameraMode = mode;

    // 通知监听器
    if (this.cameraTrackingChangedListener) {
      this.cameraTrackingChangedListener.onCameraTrackingChanged(mode);
    }

    // 如果切换到跟踪模式，立即更新相机
    if (CameraMode.isTracking(mode) && this.lastLocation) {
      this.updateCamera(this.lastLocation, this.lastBearing, true);
    }
  }

  /**
   * 更新位置并可能更新相机
   */
  updateLocation(location: LatLng, bearing: number): void {
    this.lastLocation = location;
    this.lastBearing = bearing;

    // 如果在跟踪模式，更新相机
    if (CameraMode.isTracking(this.cameraMode) && !this.userInteracting) {
      this.updateCamera(location, bearing, false);
    }
  }

  /**
   * 更新相机位置
   */
  private updateCamera(location: LatLng, bearing: number, immediate: boolean): void {
    if (this.isTransitioning) {
      return;
    }

    try {
      this.isTransitioning = true;

      // 根据相机模式决定相机参数
      let cameraBearing: number = 0;
      const currentCamera: Object | null = this.maplibreMap.getCameraPosition();

      switch (this.cameraMode) {
        case CameraMode.TRACKING:
        case CameraMode.TRACKING_GPS_NORTH:
          // 只跟踪位置，不改变方向
          cameraBearing = (currentCamera as CameraPosition)?.bearing ?? 0;
          break;
        
        case CameraMode.TRACKING_COMPASS:
        case CameraMode.TRACKING_GPS:
          // 跟踪位置和方向
          cameraBearing = bearing;
          break;
        
        default:
          this.isTransitioning = false;
          return;
      }

      // 创建相机选项
      const cameraOptions: CameraOptions = {
        center: location,
        zoom: (currentCamera as CameraPosition)?.zoom ?? 15,
        bearing: cameraBearing,
        pitch: (currentCamera as CameraPosition)?.tilt ?? 0
      };

      // 动画时长
      const duration = immediate ? 0 : 
        (this.options.trackingAnimationDurationMultiplier * 750);

      // 移动相机
      this.maplibreMap.easeTo(cameraOptions, duration);
      this.isTransitioning = false;

    } catch (err) {
      hilog.error(DOMAIN, LocationCameraController.TAG, `Failed to update camera: ${err}`);
      this.isTransitioning = false;
    }
  }

  /**
   * 设置手势检测
   */
  private setupGestureDetection(): void {
    // 监听用户手势，当用户拖动地图时取消跟踪
    // 注意：这里需要 MapLibreMap 提供手势事件监听
    // 简化实现，实际需要更复杂的手势检测逻辑
  }

  /**
   * 用户开始交互
   */
  onUserInteractionStart(): void {
    this.userInteracting = true;
    
    // 如果在跟踪模式，取消跟踪
    if (CameraMode.isTracking(this.cameraMode)) {
      
      // 通知监听器
      if (this.cameraTrackingChangedListener && this.cameraTrackingChangedListener.onCameraTrackingDismissed) {
        this.cameraTrackingChangedListener.onCameraTrackingDismissed();
      }
      
      // 切换到非跟踪模式
      this.setCameraMode(CameraMode.NONE);
    }
  }

  /**
   * 用户结束交互
   */
  onUserInteractionEnd(): void {
    this.userInteracting = false;
  }

  /**
   * 获取当前相机模式
   */
  getCameraMode(): number {
    return this.cameraMode;
  }

  /**
   * 应用配置
   */
  applyOptions(options: LocationComponentOptions): void {
    this.options = options;
  }

  /**
   * 判断是否在跟踪模式
   */
  isTracking(): boolean {
    return CameraMode.isTracking(this.cameraMode);
  }
}

