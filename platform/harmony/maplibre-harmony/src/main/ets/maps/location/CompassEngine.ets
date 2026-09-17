import sensor from '@ohos.sensor';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';

/**
 * Compass listener interface.
 */
export interface CompassListener {
  /**
   * Called when the compass heading changes.
   * @param heading Heading in degrees (0-360, north = 0).
   */
  onCompassChanged(heading: number): void;

  /**
   * Called when compass accuracy changes.
   * @param accuracy Accuracy value.
   */
  onCompassAccuracyChange?(accuracy: number): void;
}

/**
 * Compass engine built on the HarmonyOS sensor API.
 */
export class CompassEngine {
  private static readonly TAG: string = 'CompassEngine';
  private listeners: Set<CompassListener> = new Set();
  private isListening: boolean = false;
  private lastHeading: number = 0;
  private updateInterval: number = 500; // Update interval (milliseconds)
  private lastUpdateTime: number = 0;
  // Smoothing parameters
  private static readonly SMOOTHING_FACTOR: number = 0.1;
  // Low-pass filter history values
  private headingHistory: number[] = [];
  private static readonly HISTORY_SIZE: number = 5;
  // Change threshold (degrees)
  private changeThreshold: number = 0.5;

  /**
   * Add a compass listener.
   */
  addCompassListener(listener: CompassListener): void {
    this.listeners.add(listener);

    if (!this.isListening) {
      this.startListening();
    }
  }

  /**
   * Remove a compass listener.
   */
  removeCompassListener(listener: CompassListener): void {
    this.listeners.delete(listener);

    if (this.listeners.size === 0 && this.isListening) {
      this.stopListening();
    }
  }

  /**
   * Set the update interval.
   */
  setUpdateInterval(interval: number): void {
    this.updateInterval = interval;
  }

  /**
   * Start listening to compass updates.
   */
  private startListening(): void {
    try {

      // Subscribe to the orientation sensor
      sensor.on(sensor.SensorId.ORIENTATION, (data: sensor.OrientationResponse) => {
        const now = Date.now();

        // Rate limit updates
        if (now - this.lastUpdateTime < this.updateInterval) {
          return;
        }
        this.lastUpdateTime = now;

        // Obtain azimuth
        // data.alpha is rotation around the Z axis, range 0-360
        let heading = data.alpha;

        // Apply smoothing filter
        heading = this.smoothHeading(heading);

        // Notify listeners (respect the configurable change threshold)
        const headingDiff = Math.abs(heading - this.lastHeading);
        const normalizedDiff = headingDiff > 180 ? 360 - headingDiff : headingDiff;

        if (normalizedDiff > this.changeThreshold) {
          this.lastHeading = heading;

          this.listeners.forEach(listener => {
            try {
              listener.onCompassChanged(heading);
            } catch (err) {
              hilog.error(DOMAIN, CompassEngine.TAG, `Listener error: ${err}`);
            }
          });
        }
      }, {
        interval: this.updateInterval * 1000000 // Convert to nanoseconds
      });

      this.isListening = true;

    } catch (err) {
      hilog.error(DOMAIN, CompassEngine.TAG, `Failed to start compass sensor: ${err}`);
    }
  }

  /**
   * Stop listening to compass updates.
   */
  private stopListening(): void {
    try {
      if (this.isListening) {
        sensor.off(sensor.SensorId.ORIENTATION);
        this.isListening = false;
      }
    } catch (err) {
      hilog.error(DOMAIN, CompassEngine.TAG, `Failed to stop compass sensor: ${err}`);
    }
  }

  /**
   * Smooth heading changes (enhanced low-pass filter + moving average).
   */
  private smoothHeading(newHeading: number): number {
    if (this.lastHeading === 0 && this.headingHistory.length === 0) {
      this.headingHistory.push(newHeading);
      return newHeading;
    }

    // Add to history
    this.headingHistory.push(newHeading);
    if (this.headingHistory.length > CompassEngine.HISTORY_SIZE) {
      this.headingHistory.shift();
    }

    // Compute moving average (handles wrap-around across 0/360)
    let sum = 0;
    let count = this.headingHistory.length;

    for (let i = 0; i < count; i++) {
      let angle = this.headingHistory[i];

      // Adjust angles to remain continuous relative to the first value
      if (i > 0) {
        let diff = angle - this.headingHistory[0];
        if (diff > 180) {
          angle -= 360;
        } else if (diff < -180) {
          angle += 360;
        }
      }

      sum += angle;
    }

    let average = sum / count;

    // Normalize to the 0-360 range
    while (average < 0) {
      average += 360;
    }
    while (average >= 360) {
      average -= 360;
    }

    return average;
  }

  /**
   * Get the latest heading.
   */
  getLastHeading(): number {
    return this.lastHeading;
  }

  /**
   * Check whether the compass sensor is available.
   */
  static isCompassAvailable(): boolean {
    try {
      // Check whether the orientation sensor exists
      // Note: a production implementation may need a more detailed check
      return true;
    } catch (err) {
      hilog.error(DOMAIN, CompassEngine.TAG, `Failed to check compass availability: ${err}`);
      return false;
    }
  }

  /**
   * Stop all listeners.
   */
  stopAllListeners(): void {
    this.listeners.clear();
    this.stopListening();
    this.resetState();
  }

  /**
   * Reset internal state.
   */
  private resetState(): void {
    this.lastHeading = 0;
    this.headingHistory = [];
    this.lastUpdateTime = 0;
  }

  /**
   * Set the change threshold.
   */
  setChangeThreshold(threshold: number): void {
    this.changeThreshold = Math.max(0.1, threshold);
  }

  /**
   * Calibrate the compass (clear history).
   */
  calibrate(): void {
    this.headingHistory = [];
    this.lastHeading = 0;
  }
}

