import geoLocationManager from '@ohos.geoLocationManager';
import { MapLibreMap } from '../MapLibreMap';
import { LocationComponentOptions } from './LocationComponentOptions';
import { LocationLayerController } from './LocationLayerController';
import { LocationCameraController } from './LocationCameraController';
import { LocationAnimatorCoordinator } from './LocationAnimatorCoordinator';
import { CompassEngine, CompassListener } from './CompassEngine';
import { LocationEngine } from './engine/LocationEngine';
import { LocationEngineCallback } from './engine/LocationEngineCallback';
import { LocationEngineRequest } from './engine/LocationEngineRequest';
import { HarmonyLocationEngine } from './engine/HarmonyLocationEngine';
import { RenderMode } from './modes/RenderMode';
import { CameraMode } from './modes/CameraMode';
import { createLatLng, LatLng } from '../geometry/LatLng';
import { OnLocationClickListener } from './listeners/OnLocationClickListener';
import { OnCameraTrackingChangedListener } from './listeners/OnCameraTrackingChangedListener';
import { OnRenderModeChangedListener } from './listeners/OnRenderModeChangedListener';
import { OnLocationStaleListener } from './listeners/OnLocationStaleListener';
import { LocationComponentConstants } from './LocationComponentConstants';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';
import { Style } from '../style/Style';

/**
 * LocationComponent - 用户定位组件
 *
 * 提供用户位置的可视化、相机跟踪和交互功能
 *
 * 使用方法：
 * 1. 从 MapLibreMap 获取组件：map.getLocationComponent()
 * 2. 激活组件：component.activateLocationComponent(options)
 * 3. 启用组件：component.setLocationComponentEnabled(true)
 * 4. 设置模式：component.setCameraMode() / component.setRenderMode()
 */
export class LocationComponent implements OnRenderModeChangedListener, OnCameraTrackingChangedListener, LocationEngineCallback, CompassListener {
  private static readonly TAG: string = 'LocationComponent';
  // 核心依赖
  private maplibreMap: MapLibreMap;
  private style: Style | null = null;
  private options: LocationComponentOptions;
  // 子控制器
  private locationLayerController?: LocationLayerController;
  private locationCameraController?: LocationCameraController;
  private locationAnimatorCoordinator?: LocationAnimatorCoordinator;
  private compassEngine?: CompassEngine;
  // 位置引擎
  private locationEngine?: LocationEngine;
  private locationEngineRequest: LocationEngineRequest;
  private useDefaultLocationEngine: boolean = true;
  // 状态管理
  private isComponentInitialized: boolean = false;
  private isComponentStarted: boolean = false;
  private isEnabled: boolean = false;
  private lastLocation?: geoLocationManager.Location;
  // 过期状态管理
  private staleStateTimer?: number;
  // 监听器列表
  private locationClickListeners: Set<OnLocationClickListener> = new Set();
  private cameraTrackingChangedListeners: Set<OnCameraTrackingChangedListener> = new Set();
  private renderModeChangedListeners: Set<OnRenderModeChangedListener> = new Set();
  private locationStaleListeners: Set<OnLocationStaleListener> = new Set();

  constructor(maplibreMap: MapLibreMap) {
    this.maplibreMap = maplibreMap;
    this.options = new LocationComponentOptions();

    // 创建默认的位置请求
    this.locationEngineRequest = LocationEngineRequest.builder()
      .setInterval(LocationComponentConstants.DEFAULT_INTERVAL_MILLIS)
      .setFastestInterval(LocationComponentConstants.DEFAULT_FASTEST_INTERVAL_MILLIS)
      .build();
  }

  /**
   * 激活位置组件
   * @param options 配置选项
   * @throws Error 如果地图样式未加载或组件初始化失败
   */
  activateLocationComponent(options?: LocationComponentOptions): void {
    if (this.isComponentInitialized) {
      hilog.warn(DOMAIN, LocationComponent.TAG, 'LocationComponent already initialized');
      return;
    }

    if (options) {
      this.options = options;
    }

    // 获取地图样式
    this.style = this.maplibreMap.getStyle();
    if (!this.style) {
      const error = 'Map style is not loaded yet. Wait for style to load before activating LocationComponent.';
      hilog.error(DOMAIN, LocationComponent.TAG, error);
      throw new Error(error);
    }

    try {
      // 初始化子组件
      this.initializeComponents();
      this.isComponentInitialized = true;
    } catch (err) {
      const errorMsg = `Failed to initialize LocationComponent: ${err}`;
      hilog.error(DOMAIN, LocationComponent.TAG, errorMsg);

      // 清理已初始化的资源
      this.cleanup();
      throw new Error(errorMsg);
    }
  }

  /**
   * 初始化子组件
   */
  private initializeComponents(): void {
    if (!this.style) {
      return;
    }

    // 创建动画协调器
    this.locationAnimatorCoordinator = new LocationAnimatorCoordinator(
      (location: LatLng, bearing: number, accuracy: number): void => {
        // 更新图层
        this.locationLayerController?.updateLocation(location, bearing, accuracy);
      }
    );
    this.locationAnimatorCoordinator.setTrackingAnimationDurationMultiplier(
      this.options.trackingAnimationDurationMultiplier
    );

    // 创建图层控制器
    this.locationLayerController = new LocationLayerController(
      this.options,
      this
    );
    this.locationLayerController.initializeComponents(this.style);

    // 创建相机控制器
    this.locationCameraController = new LocationCameraController(
      this.maplibreMap,
      this.options,
      this
    );

    // 创建指南针引擎
    if (this.options.compassAnimationEnabled) {
      this.compassEngine = new CompassEngine();
    }

    // 使用默认位置引擎
    if (this.useDefaultLocationEngine) {
      this.locationEngine = HarmonyLocationEngine.getInstance();
    }
  }

  /**
   * 启用或禁用位置组件
   * @param enabled true 启用，false 禁用
   * @throws Error 如果组件未激活
   */
  setLocationComponentEnabled(enabled: boolean): void {
    if (!this.isComponentInitialized) {
      const error = 'LocationComponent must be activated first. Call activateLocationComponent() before enabling.';
      hilog.error(DOMAIN, LocationComponent.TAG, error);
      throw new Error(error);
    }

    if (this.isEnabled === enabled) {
      return;
    }

    try {
      this.isEnabled = enabled;

      if (enabled) {
        this.enable();
      } else {
        this.disable();
      }
    } catch (err) {
      hilog.error(DOMAIN, LocationComponent.TAG, `Failed to ${enabled ? 'enable' : 'disable'} component: ${err}`);
      // 恢复状态
      this.isEnabled = !enabled;
      throw new Error(String(err));
    }
  }

  /**
   * 启用组件
   */
  private enable(): void {
    // 显示图层
    this.locationLayerController?.show();

    // 开始位置更新
    if (this.locationEngine) {
      this.locationEngine.requestLocationUpdates(
        this.locationEngineRequest,
        this
      );
    }

    // 开始指南针更新
    if (this.compassEngine && this.getRenderMode() === RenderMode.COMPASS) {
      this.compassEngine.addCompassListener(this);
    }
  }

  /**
   * 禁用组件
   */
  private disable(): void {
    // 隐藏图层
    this.locationLayerController?.hide();

    // 停止位置更新
    if (this.locationEngine) {
      this.locationEngine.removeLocationUpdates(this);
    }

    // 停止指南针更新
    if (this.compassEngine) {
      this.compassEngine.removeCompassListener(this);
    }

    // 停止动画
    this.locationAnimatorCoordinator?.stopAnimation();

    // 清除过期状态定时器
    this.clearStaleStateTimer();
  }

  // 实现 LocationEngineCallback
  onSuccess(location: geoLocationManager.Location): void {

    this.updateLocation(location, true);
  }

  onFailure(error: Error): void {
    hilog.error(DOMAIN, LocationComponent.TAG, `Location error: ${error.message}`);
  }

  // 实现 CompassListener
  onCompassChanged(heading: number): void {
    // 更新方向（仅在 COMPASS 模式下）
    if (this.getRenderMode() === RenderMode.COMPASS && this.lastLocation) {
      const latLng: LatLng = createLatLng(this.lastLocation.latitude, this.lastLocation.longitude);
      this.locationAnimatorCoordinator?.animateLocationUpdate(
        latLng,
        heading,
        this.lastLocation.accuracy ?? 0,
        this.options.compassAnimationEnabled
      );

      // 更新相机
      this.locationCameraController?.updateLocation(latLng, heading);
    }
  }

  /**
   * 更新位置
   */
  private updateLocation(location: geoLocationManager.Location, animate: boolean): void {
    this.lastLocation = location;

    const latLng: LatLng = createLatLng(location.latitude, location.longitude);
    const bearing = location.direction ?? 0;
    const accuracy = location.accuracy ?? 0;

    // 通过动画协调器更新位置
    this.locationAnimatorCoordinator?.animateLocationUpdate(latLng, bearing, accuracy, animate);

    // 更新相机
    this.locationCameraController?.updateLocation(latLng, bearing);

    // 重置过期状态定时器
    this.resetStaleStateTimer();
  }

  /**
   * 强制更新位置（不通过位置引擎）
   */
  forceLocationUpdate(latitude: number, longitude: number, bearing?: number, accuracy?: number): void {
    if (!this.isComponentInitialized) {
      throw new Error('LocationComponent must be activated first');
    }

    const location: geoLocationManager.Location = {
      latitude: latitude,
      longitude: longitude,
      altitude: 0,
      accuracy: accuracy ?? 0,
      speed: 0,
      direction: bearing ?? 0,
      timeStamp: Date.now(),
      timeSinceBoot: Date.now(),
      additions: []
    };

    this.updateLocation(location, true);
  }

  /**
   * 设置相机模式
   */
  setCameraMode(mode: number): void {
    if (!this.isComponentInitialized) {
      throw new Error('LocationComponent must be activated first');
    }

    this.locationCameraController?.setCameraMode(mode);
  }

  /**
   * 设置渲染模式
   */
  setRenderMode(mode: number): void {
    if (!this.isComponentInitialized) {
      throw new Error('LocationComponent must be activated first');
    }

    this.locationLayerController?.setRenderMode(mode);

    // 如果切换到 COMPASS 模式，启动指南针
    if (mode === RenderMode.COMPASS && this.compassEngine && this.isEnabled) {
      this.compassEngine.addCompassListener(this);
    } else if (this.compassEngine) {
      this.compassEngine.removeCompassListener(this);
    }
  }

  /**
   * 获取当前相机模式
   */
  getCameraMode(): number {
    return this.locationCameraController?.getCameraMode() ?? CameraMode.NONE;
  }

  /**
   * 获取当前渲染模式
   */
  getRenderMode(): number {
    return this.locationLayerController?.getRenderMode() ?? RenderMode.NORMAL;
  }

  /**
   * 获取最后已知位置
   */
  getLastKnownLocation(): LatLng | undefined {
    if (this.lastLocation) {
      return createLatLng(this.lastLocation.latitude, this.lastLocation.longitude);
    }
    return undefined;
  }

  /**
   * 应用新的样式配置
   */
  applyStyle(options: LocationComponentOptions): void {
    this.options = options;
    this.locationLayerController?.applyStyle(options);
    this.locationCameraController?.applyOptions(options);
    this.locationAnimatorCoordinator?.setTrackingAnimationDurationMultiplier(
      options.trackingAnimationDurationMultiplier
    );
  }

  /**
   * 获取当前配置
   */
  getLocationComponentOptions(): LocationComponentOptions {
    return this.options;
  }

  /**
   * 添加位置点击监听器
   */
  addOnLocationClickListener(listener: OnLocationClickListener): void {
    this.locationClickListeners.add(listener);
  }

  /**
   * 移除位置点击监听器
   */
  removeOnLocationClickListener(listener: OnLocationClickListener): void {
    this.locationClickListeners.delete(listener);
  }

  /**
   * 添加相机跟踪变更监听器
   */
  addOnCameraTrackingChangedListener(listener: OnCameraTrackingChangedListener): void {
    this.cameraTrackingChangedListeners.add(listener);
  }

  /**
   * 移除相机跟踪变更监听器
   */
  removeOnCameraTrackingChangedListener(listener: OnCameraTrackingChangedListener): void {
    this.cameraTrackingChangedListeners.delete(listener);
  }

  /**
   * 添加渲染模式变更监听器
   */
  addOnRenderModeChangedListener(listener: OnRenderModeChangedListener): void {
    this.renderModeChangedListeners.add(listener);
  }

  /**
   * 移除渲染模式变更监听器
   */
  removeOnRenderModeChangedListener(listener: OnRenderModeChangedListener): void {
    this.renderModeChangedListeners.delete(listener);
  }

  /**
   * 添加位置过期监听器
   */
  addOnLocationStaleListener(listener: OnLocationStaleListener): void {
    this.locationStaleListeners.add(listener);
  }

  /**
   * 移除位置过期监听器
   */
  removeOnLocationStaleListener(listener: OnLocationStaleListener): void {
    this.locationStaleListeners.delete(listener);
  }

  /**
   * 通知相机跟踪变更
   */
  // 实现 OnCameraTrackingChangedListener
  onCameraTrackingChanged(mode: number): void {
    this.notifyCameraTrackingChanged(mode);
  }

  onCameraTrackingDismissed(): void {
    this.notifyCameraTrackingDismissed();
  }

  private notifyCameraTrackingChanged(mode: number): void {
    this.cameraTrackingChangedListeners.forEach(listener => {
      listener.onCameraTrackingChanged(mode);
    });
  }

  /**
   * 通知相机跟踪被取消
   */
  private notifyCameraTrackingDismissed(): void {
    this.cameraTrackingChangedListeners.forEach(listener => {
      if (listener.onCameraTrackingDismissed) {
        listener.onCameraTrackingDismissed();
      }
    });
  }

  /**
   * 通知渲染模式变更
   */
  // 实现 OnRenderModeChangedListener  
  onRenderModeChanged(mode: number): void {
    this.notifyRenderModeChanged(mode);
  }

  private notifyRenderModeChanged(mode: number): void {
    this.renderModeChangedListeners.forEach(listener => {
      listener.onRenderModeChanged(mode);
    });
  }

  /**
   * 通知位置过期状态变更
   */
  private notifyStaleStateChanged(isStale: boolean): void {
    this.locationStaleListeners.forEach(listener => {
      listener.onStaleStateChange(isStale);
    });
    this.locationLayerController?.setStale(isStale);
  }

  /**
   * 重置过期状态定时器
   */
  private resetStaleStateTimer(): void {
    this.clearStaleStateTimer();

    if (!this.options.enableStaleState) {
      return;
    }

    this.staleStateTimer = setTimeout(() => {
      this.notifyStaleStateChanged(true);
    }, this.options.staleStateTimeout);
  }

  /**
   * 清除过期状态定时器
   */
  private clearStaleStateTimer(): void {
    if (this.staleStateTimer) {
      clearTimeout(this.staleStateTimer);
      this.staleStateTimer = undefined;
    }
    this.notifyStaleStateChanged(false);
  }

  /**
   * 组件生命周期：onStart
   */
  onStart(): void {
    if (!this.isComponentInitialized) {
      return;
    }

    this.isComponentStarted = true;

    if (this.isEnabled) {
      this.enable();
    }
  }

  /**
   * 组件生命周期：onStop
   */
  onStop(): void {
    if (!this.isComponentInitialized) {
      return;
    }

    this.isComponentStarted = false;
    this.disable();
  }

  /**
   * 组件生命周期：onDestroy
   */
  onDestroy(): void {

    try {
      this.disable();
      this.cleanup();
    } catch (err) {
      hilog.error(DOMAIN, LocationComponent.TAG, `Error during destroy: ${err}`);
    }
  }

  /**
   * 清理资源
   * @private
   */
  private cleanup(): void {
    try {
      // 清理动画
      this.locationAnimatorCoordinator?.dispose();
      this.locationAnimatorCoordinator = undefined;

      // 清理指南针
      this.compassEngine?.stopAllListeners();
      this.compassEngine = undefined;

      // 清理图层
      this.locationLayerController?.removeLayers();
      this.locationLayerController = undefined;

      // 清理相机控制器
      this.locationCameraController = undefined;

      // 清理监听器
      this.locationClickListeners.clear();
      this.cameraTrackingChangedListeners.clear();
      this.renderModeChangedListeners.clear();
      this.locationStaleListeners.clear();

      // 清理定时器
      this.clearStaleStateTimer();

      this.isComponentInitialized = false;
      this.isEnabled = false;

    } catch (err) {
      hilog.error(DOMAIN, LocationComponent.TAG, `Error during cleanup: ${err}`);
    }
  }
}

