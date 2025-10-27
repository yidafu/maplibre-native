import { LocationEngineCallback } from './LocationEngineCallback';
import { LocationEngineRequest } from './LocationEngineRequest';

/**
 * 位置引擎接口
 * 用于获取设备位置信息
 */
export interface LocationEngine {
  /**
   * 请求位置更新
   * @param request 位置请求配置
   * @param callback 位置更新回调
   */
  requestLocationUpdates(request: LocationEngineRequest, callback: LocationEngineCallback): void;

  /**
   * 移除位置更新监听
   * @param callback 要移除的回调
   */
  removeLocationUpdates(callback: LocationEngineCallback): void;

  /**
   * 获取最后已知位置
   * @param callback 位置回调
   */
  getLastLocation(callback: LocationEngineCallback): void;
}

