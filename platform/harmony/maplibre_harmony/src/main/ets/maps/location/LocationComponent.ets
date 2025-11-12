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
 * LocationComponent - user location component.
 *
 * Provides visualization, camera tracking, and interaction for the user's location.
 *
 * Usage:
 * 1. Obtain the component from MapLibreMap: `map.getLocationComponent()`
 * 2. Activate the component: `component.activateLocationComponent(options)`
 * 3. Enable the component: `component.setLocationComponentEnabled(true)`
 * 4. Configure modes: `component.setCameraMode()` / `component.setRenderMode()`
 */
export class LocationComponent implements OnRenderModeChangedListener, OnCameraTrackingChangedListener, LocationEngineCallback, CompassListener {
  private static readonly TAG: string = 'LocationComponent';
  // Core dependencies
  private maplibreMap: MapLibreMap;
  private style: Style | null = null;
  private options: LocationComponentOptions;
  // Sub-controllers
  private locationLayerController?: LocationLayerController;
  private locationCameraController?: LocationCameraController;
  private locationAnimatorCoordinator?: LocationAnimatorCoordinator;
  private compassEngine?: CompassEngine;
  // Location engine
  private locationEngine?: LocationEngine;
  private locationEngineRequest: LocationEngineRequest;
  private useDefaultLocationEngine: boolean = true;
  // State management
  private isComponentInitialized: boolean = false;
  private isComponentStarted: boolean = false;
  private isEnabled: boolean = false;
  private lastLocation?: geoLocationManager.Location;
  // Stale state management
  private staleStateTimer?: number;
  // Listener collections
  private locationClickListeners: Set<OnLocationClickListener> = new Set();
  private cameraTrackingChangedListeners: Set<OnCameraTrackingChangedListener> = new Set();
  private renderModeChangedListeners: Set<OnRenderModeChangedListener> = new Set();
  private locationStaleListeners: Set<OnLocationStaleListener> = new Set();

  constructor(maplibreMap: MapLibreMap) {
    this.maplibreMap = maplibreMap;
    this.options = new LocationComponentOptions();

    // Create the default location request
    this.locationEngineRequest = LocationEngineRequest.builder()
      .setInterval(LocationComponentConstants.DEFAULT_INTERVAL_MILLIS)
      .setFastestInterval(LocationComponentConstants.DEFAULT_FASTEST_INTERVAL_MILLIS)
      .build();
  }

  /**
   * Activate the location component.
   * @param options Optional configuration.
   * @throws Error When the map style is not loaded or initialization fails.
   */
  async activateLocationComponent(options?: LocationComponentOptions): Promise<void> {
    if (this.isComponentInitialized) {
      hilog.warn(DOMAIN, LocationComponent.TAG, 'LocationComponent already initialized');
      return;
    }

    if (options) {
      this.options = options;
    }

    // Retrieve the map style
    this.style = this.maplibreMap.getStyle();
    if (!this.style) {
      const error = 'Map style is not loaded yet. Wait for style to load before activating LocationComponent.';
      hilog.error(DOMAIN, LocationComponent.TAG, error);
      throw new Error(error);
    }

    try {
      // Initialize subcomponents (asynchronously loads icon assets)
      await this.initializeComponents();
      this.isComponentInitialized = true;
    } catch (err) {
      const errorMsg = `Failed to initialize LocationComponent: ${err}`;
      hilog.error(DOMAIN, LocationComponent.TAG, errorMsg);

      // Clean up any partially initialized resources
      this.cleanup();
      throw new Error(errorMsg);
    }
  }

  /**
   * Initialize child components.
   */
  private async initializeComponents(): Promise<void> {
    if (!this.style) {
      return;
    }

    // Create the animation coordinator
    this.locationAnimatorCoordinator = new LocationAnimatorCoordinator(
      (location: LatLng, bearing: number, accuracy: number): void => {
        // Update the layer
        this.locationLayerController?.updateLocation(location, bearing, accuracy);
      }
    );
    this.locationAnimatorCoordinator.setTrackingAnimationDurationMultiplier(
      this.options.trackingAnimationDurationMultiplier
    );

    // Create the layer controller
    this.locationLayerController = new LocationLayerController(
      this.options,
      this
    );
    // Initialize layers asynchronously (loads icon assets)
    await this.locationLayerController.initializeComponents(this.style);

    // Create the camera controller
    this.locationCameraController = new LocationCameraController(
      this.maplibreMap,
      this.options,
      this
    );

    // Create the compass engine
    if (this.options.compassAnimationEnabled) {
      this.compassEngine = new CompassEngine();
    }

    // Use the default location engine
    if (this.useDefaultLocationEngine) {
      this.locationEngine = HarmonyLocationEngine.getInstance();
    }
  }

  /**
   * Enable or disable the location component.
   * @param enabled `true` to enable, `false` to disable.
   * @throws Error When the component has not been activated.
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
      // Restore the previous state
      this.isEnabled = !enabled;
      throw new Error(String(err));
    }
  }

  /**
   * Enable the component.
   */
  private enable(): void {
    // Show layers
    this.locationLayerController?.show();

    // Start location updates
    if (this.locationEngine) {
      this.locationEngine.requestLocationUpdates(
        this.locationEngineRequest,
        this
      );
    }

    // Start compass updates if required
    if (this.compassEngine && this.getRenderMode() === RenderMode.COMPASS) {
      this.compassEngine.addCompassListener(this);
    }
  }

  /**
   * Disable the component.
   */
  private disable(): void {
    // Hide layers
    this.locationLayerController?.hide();

    // Stop location updates
    if (this.locationEngine) {
      this.locationEngine.removeLocationUpdates(this);
    }

    // Stop compass updates
    if (this.compassEngine) {
      this.compassEngine.removeCompassListener(this);
    }

    // Stop animations
    this.locationAnimatorCoordinator?.stopAnimation();

    // Clear stale-state timer
    this.clearStaleStateTimer();
  }

  // LocationEngineCallback implementation
  onSuccess(location: geoLocationManager.Location): void {

    this.updateLocation(location, true);
  }

  onFailure(error: Error): void {
    hilog.error(DOMAIN, LocationComponent.TAG, `Location error: ${error.message}`);
  }

  // CompassListener implementation
  onCompassChanged(heading: number): void {
    // Update bearing (COMPASS mode only)
    if (this.getRenderMode() === RenderMode.COMPASS && this.lastLocation) {
      const latLng: LatLng = createLatLng(this.lastLocation.latitude, this.lastLocation.longitude);
      this.locationAnimatorCoordinator?.animateLocationUpdate(
        latLng,
        heading,
        this.lastLocation.accuracy ?? 0,
        this.options.compassAnimationEnabled
      );

      // Update camera
      this.locationCameraController?.updateLocation(latLng, heading);
    }
  }

  /**
   * Update location.
   */
  private updateLocation(location: geoLocationManager.Location, animate: boolean): void {
    this.lastLocation = location;

    const latLng: LatLng = createLatLng(location.latitude, location.longitude);
    const bearing = location.direction ?? 0;
    const accuracy = location.accuracy ?? 0;

    // Feed the animation coordinator
    this.locationAnimatorCoordinator?.animateLocationUpdate(latLng, bearing, accuracy, animate);

    // Update the camera
    this.locationCameraController?.updateLocation(latLng, bearing);

    // Reset stale-state timer
    this.resetStaleStateTimer();
  }

  /**
   * Force-update location (bypassing the location engine).
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
   * Configure camera mode.
   */
  setCameraMode(mode: number): void {
    if (!this.isComponentInitialized) {
      throw new Error('LocationComponent must be activated first');
    }

    this.locationCameraController?.setCameraMode(mode);
  }

  /**
   * Configure render mode.
   */
  setRenderMode(mode: number): void {
    if (!this.isComponentInitialized) {
      throw new Error('LocationComponent must be activated first');
    }

    this.locationLayerController?.setRenderMode(mode);

    // When switching to COMPASS mode, enable compass updates
    if (mode === RenderMode.COMPASS && this.compassEngine && this.isEnabled) {
      this.compassEngine.addCompassListener(this);
    } else if (this.compassEngine) {
      this.compassEngine.removeCompassListener(this);
    }
  }

  /**
   * Get the current camera mode.
   */
  getCameraMode(): number {
    return this.locationCameraController?.getCameraMode() ?? CameraMode.NONE;
  }

  /**
   * Get the current render mode.
   */
  getRenderMode(): number {
    return this.locationLayerController?.getRenderMode() ?? RenderMode.NORMAL;
  }

  /**
   * Get the last known location.
   */
  getLastKnownLocation(): LatLng | undefined {
    if (this.lastLocation) {
      return createLatLng(this.lastLocation.latitude, this.lastLocation.longitude);
    }
    return undefined;
  }

  /**
   * Apply new styling options.
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
   * Get the current configuration.
   */
  getLocationComponentOptions(): LocationComponentOptions {
    return this.options;
  }

  /**
   * Add a location click listener.
   */
  addOnLocationClickListener(listener: OnLocationClickListener): void {
    this.locationClickListeners.add(listener);
  }

  /**
   * Remove a location click listener.
   */
  removeOnLocationClickListener(listener: OnLocationClickListener): void {
    this.locationClickListeners.delete(listener);
  }

  /**
   * Add a camera tracking change listener.
   */
  addOnCameraTrackingChangedListener(listener: OnCameraTrackingChangedListener): void {
    this.cameraTrackingChangedListeners.add(listener);
  }

  /**
   * Remove a camera tracking change listener.
   */
  removeOnCameraTrackingChangedListener(listener: OnCameraTrackingChangedListener): void {
    this.cameraTrackingChangedListeners.delete(listener);
  }

  /**
   * Add a render mode change listener.
   */
  addOnRenderModeChangedListener(listener: OnRenderModeChangedListener): void {
    this.renderModeChangedListeners.add(listener);
  }

  /**
   * Remove a render mode change listener.
   */
  removeOnRenderModeChangedListener(listener: OnRenderModeChangedListener): void {
    this.renderModeChangedListeners.delete(listener);
  }

  /**
   * Add a location stale-state listener.
   */
  addOnLocationStaleListener(listener: OnLocationStaleListener): void {
    this.locationStaleListeners.add(listener);
  }

  /**
   * Remove a location stale-state listener.
   */
  removeOnLocationStaleListener(listener: OnLocationStaleListener): void {
    this.locationStaleListeners.delete(listener);
  }

  /**
   * Notify camera tracking changes.
   */
  // OnCameraTrackingChangedListener implementation
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
   * Notify that camera tracking has been dismissed.
   */
  private notifyCameraTrackingDismissed(): void {
    this.cameraTrackingChangedListeners.forEach(listener => {
      if (listener.onCameraTrackingDismissed) {
        listener.onCameraTrackingDismissed();
      }
    });
  }

  /**
   * Notify render mode changes.
   */
  // OnRenderModeChangedListener implementation  
  onRenderModeChanged(mode: number): void {
    this.notifyRenderModeChanged(mode);
  }

  private notifyRenderModeChanged(mode: number): void {
    this.renderModeChangedListeners.forEach(listener => {
      listener.onRenderModeChanged(mode);
    });
  }

  /**
   * Notify stale-state changes.
   */
  private notifyStaleStateChanged(isStale: boolean): void {
    this.locationStaleListeners.forEach(listener => {
      listener.onStaleStateChange(isStale);
    });
    this.locationLayerController?.setStale(isStale);
  }

  /**
   * Reset the stale-state timer.
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
   * Clear the stale-state timer.
   */
  private clearStaleStateTimer(): void {
    if (this.staleStateTimer) {
      clearTimeout(this.staleStateTimer);
      this.staleStateTimer = undefined;
    }
    this.notifyStaleStateChanged(false);
  }

  /**
   * Component lifecycle: onStart.
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
   * Component lifecycle: onStop.
   */
  onStop(): void {
    if (!this.isComponentInitialized) {
      return;
    }

    this.isComponentStarted = false;
    this.disable();
  }

  /**
   * Component lifecycle: onDestroy.
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
   * Release resources.
   */
  private cleanup(): void {
    try {
      // Dispose animations
      this.locationAnimatorCoordinator?.dispose();
      this.locationAnimatorCoordinator = undefined;

      // Dispose compass engine
      this.compassEngine?.stopAllListeners();
      this.compassEngine = undefined;

      // Remove layers
      this.locationLayerController?.removeLayers();
      this.locationLayerController = undefined;

      // Release camera controller
      this.locationCameraController = undefined;

      // Clear listener sets
      this.locationClickListeners.clear();
      this.cameraTrackingChangedListeners.clear();
      this.renderModeChangedListeners.clear();
      this.locationStaleListeners.clear();

      // Clear timers
      this.clearStaleStateTimer();

      this.isComponentInitialized = false;
      this.isEnabled = false;

    } catch (err) {
      hilog.error(DOMAIN, LocationComponent.TAG, `Error during cleanup: ${err}`);
    }
  }
}

