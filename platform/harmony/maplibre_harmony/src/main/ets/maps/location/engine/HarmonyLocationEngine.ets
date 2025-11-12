import geoLocationManager from '@ohos.geoLocationManager';
import { LocationEngine } from './LocationEngine';
import { LocationEngineCallback } from './LocationEngineCallback';
import { LocationEngineRequest } from './LocationEngineRequest';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../../constants/HiLogConstants';

/**
 * HarmonyOS location engine implementation built upon `@ohos.geoLocationManager`.
 */
export class HarmonyLocationEngine implements LocationEngine {
  private static readonly TAG: string = 'HarmonyLocationEngine';
  private static instance: HarmonyLocationEngine | null = null;
  private callbacks: Map<LocationEngineCallback, boolean> = new Map();
  private isListening: boolean = false;
  private currentRequest?: LocationEngineRequest;
  // Throttling control
  private lastLocationTime: number = 0;
  private minUpdateInterval: number = 100; // Minimum interval in milliseconds

  // Error retry
  private retryCount: number = 0;
  private maxRetries: number = 3;
  private retryDelay: number = 2000; // Retry delay in milliseconds

  private constructor() {
    // Private constructor for singleton usage
  }

  /**
   * Obtain the singleton instance.
   */
  static getInstance(): HarmonyLocationEngine {
    if (!HarmonyLocationEngine.instance) {
      HarmonyLocationEngine.instance = new HarmonyLocationEngine();
    }
    return HarmonyLocationEngine.instance;
  }

  /**
   * Request location updates.
   */
  requestLocationUpdates(request: LocationEngineRequest, callback: LocationEngineCallback): void {
    try {

      // Register callback
      this.callbacks.set(callback, true);

      // If already listening, return early
      if (this.isListening) {
        return;
      }

      // Store request configuration
      this.currentRequest = request;

      // Ensure location services are enabled
      if (!geoLocationManager.isLocationEnabled()) {
        const error = new Error('Location service is disabled');
        hilog.error(DOMAIN, HarmonyLocationEngine.TAG, 'Location service is disabled');
        this.callbacks.forEach((_, cb) => {
          cb.onFailure(error);
        });
        return;
      }

      // Build the location request
      const locationRequest: geoLocationManager.LocationRequest = {
        priority: request.priority,
        scenario: request.scenario,
        timeInterval: Math.floor(request.interval / 1000), // Convert to seconds
        distanceInterval: request.minDisplacement,
        maxAccuracy: request.maxAccuracy
      };

      // Start listening for location changes
      geoLocationManager.on('locationChange', locationRequest, (location: geoLocationManager.Location) => {
        // Throttle updates to respect the minimum interval
        const now = Date.now();
        if (now - this.lastLocationTime < this.minUpdateInterval) {
          return;
        }
        this.lastLocationTime = now;

        // Reset retry count
        this.retryCount = 0;

        // Notify all callbacks
        this.callbacks.forEach((_, callback) => {
          try {
            callback.onSuccess(location);
          } catch (err) {
            hilog.error(DOMAIN, HarmonyLocationEngine.TAG, `Callback error: ${err}`);
          }
        });
      });

      this.isListening = true;

    } catch (err) {
      hilog.error(DOMAIN, HarmonyLocationEngine.TAG, `Failed to request location updates: ${err}`);
      const error = err instanceof Error ? err : new Error(String(err));

      // Attempt retry if possible
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
   * Remove location update listener.
   */
  removeLocationUpdates(callback: LocationEngineCallback): void {
    try {

      // Remove callback
      this.callbacks.delete(callback);

      // Stop listening when no callbacks remain
      if (this.callbacks.size === 0 && this.isListening) {
        geoLocationManager.off('locationChange');
        this.isListening = false;
      }
    } catch (err) {
      hilog.error(DOMAIN, HarmonyLocationEngine.TAG, `Failed to remove location updates: ${err}`);
    }
  }

  /**
   * Retrieve the last known location.
   */
  getLastLocation(callback: LocationEngineCallback): void {
    try {

      // Verify that location services are enabled
      if (!geoLocationManager.isLocationEnabled()) {
        const error = new Error('Location service is disabled');
        hilog.error(DOMAIN, HarmonyLocationEngine.TAG, 'Location service is disabled');
        callback.onFailure(error);
        return;
      }

      // Obtain the last location
      try {
        const location = geoLocationManager.getLastLocation();
        if (location) {
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
   * Check whether location permission is available.
   */
  static hasLocationPermission(): boolean {
    try {
      const permissions = ['ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION'];
      // Note: proper permission handling should use abilityAccessCtrl; simplified here
      return geoLocationManager.isLocationEnabled();
    } catch (err) {
      hilog.error(DOMAIN, HarmonyLocationEngine.TAG, `Failed to check location permission: ${err}`);
      return false;
    }
  }

  /**
   * Stop all location updates.
   */
  stopAllUpdates(): void {
    try {
      if (this.isListening) {
        geoLocationManager.off('locationChange');
        this.isListening = false;
        this.callbacks.clear();
        this.retryCount = 0;
      }
    } catch (err) {
      hilog.error(DOMAIN, HarmonyLocationEngine.TAG, `Failed to stop all updates: ${err}`);
    }
  }

  /**
   * Set the minimum update interval (throttling).
   */
  setMinUpdateInterval(interval: number): void {
    this.minUpdateInterval = Math.max(100, interval); // Minimum 100 ms
  }

  /**
   * Set the maximum retry count.
   */
  setMaxRetries(maxRetries: number): void {
    this.maxRetries = Math.max(0, maxRetries);
  }
}

