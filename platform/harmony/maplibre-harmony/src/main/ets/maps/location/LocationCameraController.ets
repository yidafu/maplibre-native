import { MapLibreMap } from '../MapLibreMap';
import { LocationComponentOptions } from './LocationComponentOptions';
import { CameraMode } from './modes/CameraMode';
import { OnCameraTrackingChangedListener } from './listeners/OnCameraTrackingChangedListener';
import { LatLng } from '../geometry/LatLng';
import { CameraPosition } from '../camera/CameraPosition';
import maplibre from 'libmaplibre.so';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';

/**
 * Location camera controller.
 * Manages camera behavior when tracking the user's location.
 */
export class LocationCameraController {
  private static readonly TAG: string = 'LocationCameraController';
  private maplibreMap: MapLibreMap;
  private options: LocationComponentOptions;
  private cameraMode: number = CameraMode.NONE;
  private cameraTrackingChangedListener?: OnCameraTrackingChangedListener;
  // Currently tracked position and bearing
  private lastLocation?: LatLng;
  private lastBearing: number = 0;
  // Gesture interruption detection
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

    // Listen for camera movements to detect user gestures
    this.setupGestureDetection();
  }

  /**
   * Set the camera mode.
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

    // Notify listeners
    if (this.cameraTrackingChangedListener) {
      this.cameraTrackingChangedListener.onCameraTrackingChanged(mode);
    }

    // If switching to a tracking mode, refresh the camera immediately
    if (CameraMode.isTracking(mode) && this.lastLocation) {
      this.updateCamera(this.lastLocation, this.lastBearing, true);
    }
  }

  /**
   * Update location and possibly adjust the camera.
   */
  updateLocation(location: LatLng, bearing: number): void {
    this.lastLocation = location;
    this.lastBearing = bearing;

    // Update the camera when tracking and not interrupted by gestures
    if (CameraMode.isTracking(this.cameraMode) && !this.userInteracting) {
      this.updateCamera(location, bearing, false);
    }
  }

  /**
   * Update the camera position.
   */
  private updateCamera(location: LatLng, bearing: number, immediate: boolean): void {
    if (this.isTransitioning) {
      return;
    }

    try {
      this.isTransitioning = true;

      // Pick camera parameters based on tracking mode
      let cameraBearing: number = 0;
      const currentCamera: Object | null = this.maplibreMap.getCameraPosition();

      switch (this.cameraMode) {
        case CameraMode.TRACKING:
        case CameraMode.TRACKING_GPS_NORTH:
          // Track position only, retain current bearing
          cameraBearing = (currentCamera as CameraPosition)?.bearing ?? 0;
          break;

        case CameraMode.TRACKING_COMPASS:
        case CameraMode.TRACKING_GPS:
          // Track position and bearing
          cameraBearing = bearing;
          break;

        default:
          this.isTransitioning = false;
          return;
      }

      // Build camera options
      const cameraOptions: maplibre.CameraOptions = {
        center: location,
        zoom: (currentCamera as CameraPosition)?.zoom ?? 15,
        bearing: cameraBearing,
        pitch: (currentCamera as CameraPosition)?.tilt ?? 0
      };

      // Animation duration
      const duration = immediate ? 0 :
        (this.options.trackingAnimationDurationMultiplier * 750);

      // Move the camera
      this.maplibreMap.easeTo(cameraOptions, duration);
      this.isTransitioning = false;

    } catch (err) {
      hilog.error(DOMAIN, LocationCameraController.TAG, `Failed to update camera: ${err}`);
      this.isTransitioning = false;
    }
  }

  /**
   * Configure gesture detection.
   */
  private setupGestureDetection(): void {
    // Observe user gestures; cancel tracking when the map is dragged
    // Note: requires gesture listener support from MapLibreMap
    // Simplified implementation—production code may need richer gesture handling
  }

  /**
   * Handle user interaction start.
   */
  onUserInteractionStart(): void {
    this.userInteracting = true;

    // Cancel tracking if currently active
    if (CameraMode.isTracking(this.cameraMode)) {

      // Notify listener
      if (this.cameraTrackingChangedListener && this.cameraTrackingChangedListener.onCameraTrackingDismissed) {
        this.cameraTrackingChangedListener.onCameraTrackingDismissed();
      }

      // Switch to non-tracking mode
      this.setCameraMode(CameraMode.NONE);
    }
  }

  /**
   * Handle user interaction end.
   */
  onUserInteractionEnd(): void {
    this.userInteracting = false;
  }

  /**
   * Get the current camera mode.
   */
  getCameraMode(): number {
    return this.cameraMode;
  }

  /**
   * Apply updated options.
   */
  applyOptions(options: LocationComponentOptions): void {
    this.options = options;
  }

  /**
   * Determine whether tracking mode is active.
   */
  isTracking(): boolean {
    return CameraMode.isTracking(this.cameraMode);
  }
}

