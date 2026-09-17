import { LocationEngineCallback } from './LocationEngineCallback';
import { LocationEngineRequest } from './LocationEngineRequest';

/**
 * Location engine interface.
 * Used to retrieve device location information.
 */
export interface LocationEngine {
  /**
   * Request location updates.
   * @param request Location request configuration.
   * @param callback Location update callback.
   */
  requestLocationUpdates(request: LocationEngineRequest, callback: LocationEngineCallback): void;

  /**
   * Remove location updates.
   * @param callback Callback to remove.
   */
  removeLocationUpdates(callback: LocationEngineCallback): void;

  /**
   * Get the last known location.
   * @param callback Location callback.
   */
  getLastLocation(callback: LocationEngineCallback): void;
}

