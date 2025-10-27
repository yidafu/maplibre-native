import geoLocationManager from '@ohos.geoLocationManager';

/**
 * 位置引擎回调接口
 */
export interface LocationEngineCallback {
  /**
   * 成功获取位置时调用
   * @param location 位置信息
   */
  onSuccess(location: geoLocationManager.Location): void;

  /**
   * 获取位置失败时调用
   * @param error 错误信息
   */
  onFailure(error: Error): void;
}

