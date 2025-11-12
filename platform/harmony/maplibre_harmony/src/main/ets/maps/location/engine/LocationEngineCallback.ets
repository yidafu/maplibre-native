import geoLocationManager from '@ohos.geoLocationManager';

/**
 * Location engine callback interface.
 */
export interface LocationEngineCallback {
  /**
   * Invoked when a location is retrieved successfully.
   * @param location Location information.
   */
  onSuccess(location: geoLocationManager.Location): void;

  /**
   * Invoked when retrieving the location fails.
   * @param error Error information.
   */
  onFailure(error: Error): void;
}

