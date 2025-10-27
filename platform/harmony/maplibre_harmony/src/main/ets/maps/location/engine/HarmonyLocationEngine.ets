import geoLocationManager from '@ohos.geoLocationManager';
import { LocationEngine } from './LocationEngine';
import { LocationEngineCallback } from './LocationEngineCallback';
import { LocationEngineRequest } from './LocationEngineRequest';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../../constants/HiLogConstants';

/**
 * 鸿蒙位置引擎实现
 * 基于 @ohos.geoLocationManager
 */
export class HarmonyLocationEngine implements LocationEngine {
  private static readonly TAG: string = 'HarmonyLocationEngine';
  private static instance: HarmonyLocationEngine | null = null;
  
  private callbacks: Map<LocationEngineCallback, boolean> = new Map();
  private isListening: boolean = false;
  private currentRequest?: LocationEngineRequest;
  
  // 节流控制
  private lastLocationTime: number = 0;
  private minUpdateInterval: number = 100; // 最小更新间隔（毫秒）
  
  // 错误重试
  private retryCount: number = 0;
  private maxRetries: number = 3;
  private retryDelay: number = 2000; // 重试延迟（毫秒）

  private constructor() {
    // 私有构造函数，使用单例模式
  }

  /**
   * 获取单例实例
   */
  static getInstance(): HarmonyLocationEngine {
    if (!HarmonyLocationEngine.instance) {
      HarmonyLocationEngine.instance = new HarmonyLocationEngine();
    }
    return HarmonyLocationEngine.instance;
  }

  /**
   * 请求位置更新
   */
  requestLocationUpdates(request: LocationEngineRequest, callback: LocationEngineCallback): void {
    try {
      hilog.info(DOMAIN, HarmonyLocationEngine.TAG, 'Requesting location updates');
      
      // 保存回调
      this.callbacks.set(callback, true);
      
      // 如果已经在监听，直接返回
      if (this.isListening) {
        hilog.info(DOMAIN, HarmonyLocationEngine.TAG, 'Already listening to location updates');
        return;
      }

      // 保存请求配置
      this.currentRequest = request;

      // 检查位置服务是否开启
      if (!geoLocationManager.isLocationEnabled()) {
        const error = new Error('Location service is disabled');
        hilog.error(DOMAIN, HarmonyLocationEngine.TAG, 'Location service is disabled');
        this.callbacks.forEach((_, cb) => {
          cb.onFailure(error);
        });
        return;
      }

      // 创建位置请求配置
      const locationRequest: geoLocationManager.LocationRequest = {
        priority: request.priority,
        scenario: request.scenario,
        timeInterval: Math.floor(request.interval / 1000), // 转换为秒
        distanceInterval: request.minDisplacement,
        maxAccuracy: request.maxAccuracy
      };

      // 开始监听位置变化
      geoLocationManager.on('locationChange', locationRequest, (location: geoLocationManager.Location) => {
        // 节流处理：限制更新频率
        const now = Date.now();
        if (now - this.lastLocationTime < this.minUpdateInterval) {
          hilog.debug(DOMAIN, HarmonyLocationEngine.TAG, 'Location update throttled');
          return;
        }
        this.lastLocationTime = now;
        
        hilog.debug(DOMAIN, HarmonyLocationEngine.TAG, 
          `Location update: lat=${location.latitude}, lng=${location.longitude}, accuracy=${location.accuracy}`);
        
        // 重置重试计数
        this.retryCount = 0;
        
        // 通知所有回调
        this.callbacks.forEach((_, callback) => {
          try {
            callback.onSuccess(location);
          } catch (err) {
            hilog.error(DOMAIN, HarmonyLocationEngine.TAG, `Callback error: ${err}`);
          }
        });
      });

      this.isListening = true;
      hilog.info(DOMAIN, HarmonyLocationEngine.TAG, 'Started listening to location updates');

    } catch (err) {
      hilog.error(DOMAIN, HarmonyLocationEngine.TAG, `Failed to request location updates: ${err}`);
      const error = err instanceof Error ? err : new Error(String(err));
      
      // 尝试重试
      if (this.retryCount < this.maxRetries) {
        this.retryCount++;
        hilog.warn(DOMAIN, HarmonyLocationEngine.TAG, 
          `Retrying location updates (${this.retryCount}/${this.maxRetries})`);
        
        setTimeout(() => {
          this.requestLocationUpdates(request, callback);
        }, this.retryDelay);
      } else {
        callback.onFailure(error);
      }
    }
  }

  /**
   * 移除位置更新监听
   */
  removeLocationUpdates(callback: LocationEngineCallback): void {
    try {
      hilog.info(DOMAIN, HarmonyLocationEngine.TAG, 'Removing location updates callback');
      
      // 移除回调
      this.callbacks.delete(callback);

      // 如果没有回调了，停止监听
      if (this.callbacks.size === 0 && this.isListening) {
        geoLocationManager.off('locationChange');
        this.isListening = false;
        hilog.info(DOMAIN, HarmonyLocationEngine.TAG, 'Stopped listening to location updates');
      }
    } catch (err) {
      hilog.error(DOMAIN, HarmonyLocationEngine.TAG, `Failed to remove location updates: ${err}`);
    }
  }

  /**
   * 获取最后已知位置
   */
  getLastLocation(callback: LocationEngineCallback): void {
    try {
      hilog.info(DOMAIN, HarmonyLocationEngine.TAG, 'Getting last known location');

      // 检查位置服务是否开启
      if (!geoLocationManager.isLocationEnabled()) {
        const error = new Error('Location service is disabled');
        hilog.error(DOMAIN, HarmonyLocationEngine.TAG, 'Location service is disabled');
        callback.onFailure(error);
        return;
      }

      // 获取最后位置
      try {
        const location = geoLocationManager.getLastLocation();
        if (location) {
          hilog.debug(DOMAIN, HarmonyLocationEngine.TAG, 
            `Got last location: lat=${location.latitude}, lng=${location.longitude}`);
          callback.onSuccess(location);
        } else {
          callback.onFailure(new Error('No last location available'));
        }
      } catch (err) {
        const error = err instanceof Error ? err : new Error(String(err));
        hilog.error(DOMAIN, HarmonyLocationEngine.TAG, `Failed to get last location: ${error.message}`);
        callback.onFailure(error);
      }

    } catch (err) {
      hilog.error(DOMAIN, HarmonyLocationEngine.TAG, `Exception in getLastLocation: ${err}`);
      const error = err instanceof Error ? err : new Error(String(err));
      callback.onFailure(error);
    }
  }

  /**
   * 检查是否有位置权限
   */
  static hasLocationPermission(): boolean {
    try {
      const permissions = ['ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION'];
      // 注意：实际权限检查需要使用 abilityAccessCtrl，这里简化处理
      return geoLocationManager.isLocationEnabled();
    } catch (err) {
      hilog.error(DOMAIN, HarmonyLocationEngine.TAG, `Failed to check location permission: ${err}`);
      return false;
    }
  }

  /**
   * 停止所有位置更新
   */
  stopAllUpdates(): void {
    try {
      if (this.isListening) {
        geoLocationManager.off('locationChange');
        this.isListening = false;
        this.callbacks.clear();
        this.retryCount = 0;
        hilog.info(DOMAIN, HarmonyLocationEngine.TAG, 'Stopped all location updates');
      }
    } catch (err) {
      hilog.error(DOMAIN, HarmonyLocationEngine.TAG, `Failed to stop all updates: ${err}`);
    }
  }

  /**
   * 设置最小更新间隔（节流）
   */
  setMinUpdateInterval(interval: number): void {
    this.minUpdateInterval = Math.max(100, interval); // 最小 100ms
    hilog.info(DOMAIN, HarmonyLocationEngine.TAG, `Min update interval set to ${this.minUpdateInterval}ms`);
  }

  /**
   * 设置最大重试次数
   */
  setMaxRetries(maxRetries: number): void {
    this.maxRetries = Math.max(0, maxRetries);
    hilog.info(DOMAIN, HarmonyLocationEngine.TAG, `Max retries set to ${this.maxRetries}`);
  }
}

