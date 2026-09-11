/**
 * LocationMapChangeTestPage - Test location tracking when the map moves.
 *
 * Demonstrates how the location component responds to camera changes
 * and map movements in TRACKING mode.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { LocationComponent, LocationComponentOptions, CameraMode, RenderMode } from 'maplibre_harmony';
import { CameraTrackingChangedListener } from '../../utils/ListenerFactories';
import { LatLng, CameraPosition } from 'maplibre_harmony';
import { TEST_LOCATIONS, showToast, DEFAULT_MAP_CONFIG } from '../common/TestUtils';

interface CameraModeInfo {
  mode: number;
  name: string;
}

@Entry
@Component
struct LocationMapChangeTestPage {
  private mapController: MapLibreMap | null = null;
  private locationComponent: LocationComponent | null = null;
  @State private isMapReady: boolean = false;
  @State private isLocationEnabled: boolean = false;
  @State private isComponentActivated: boolean = false;
  @State private currentCameraMode: string = 'NONE';
  @State private statusMessage: string = 'Loading...';
  @State private currentLatLng: string = '--';
  @State private trackingState: string = 'Inactive';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready. Tap Activate to start.';
  };

  private activateLocationComponent(): void {
    if (!this.mapController || !this.isMapReady) {
      showToast('Map not ready yet');
      return;
    }

    const locationComponent = this.mapController.getLocationComponent();
    if (!locationComponent) {
      showToast('Failed to get LocationComponent');
      return;
    }

    this.locationComponent = locationComponent;

    // Use default options
    const options = new LocationComponentOptions();

    locationComponent.activateLocationComponent(options).then(() => {
      this.isComponentActivated = true;
      this.statusMessage = 'Location component activated';
      showToast('Location component activated');

      // Listen for camera tracking changes
      locationComponent.addOnCameraTrackingChangedListener(new CameraTrackingChangedListener(
        (mode: number): void => {
          this.currentCameraMode = CameraMode.getName(mode);
          this.trackingState = CameraMode.isTracking(mode) ? 'Tracking' : 'Not tracking';
        },
        (): void => {
          this.currentCameraMode = CameraMode.getName(CameraMode.NONE);
          this.trackingState = 'Dismissed';
        }
      ));
    }).catch((err: Error) => {
      this.statusMessage = 'Activation failed: ' + err.message;
      showToast('Activation failed: ' + err.message);
    });
  }

  private toggleLocationEnabled(): void {
    if (!this.locationComponent || !this.isComponentActivated) {
      showToast('Activate location component first');
      return;
    }

    try {
      const newState = !this.isLocationEnabled;
      this.locationComponent.setLocationComponentEnabled(newState);
      this.isLocationEnabled = newState;
      this.statusMessage = newState ? 'Location enabled' : 'Location disabled';

      if (newState) {
        // Set to TRACKING mode by default when enabling
        this.locationComponent.setCameraMode(CameraMode.TRACKING);
      }
    } catch (err) {
      this.statusMessage = 'Error: ' + err;
    }
  }

  private cycleCameraMode(): void {
    if (!this.locationComponent || !this.isLocationEnabled) {
      showToast('Enable location first');
      return;
    }

    const modes: CameraModeInfo[] = [
      { mode: CameraMode.TRACKING, name: 'TRACKING' },
      { mode: CameraMode.TRACKING_COMPASS, name: 'TRACKING_COMPASS' },
      { mode: CameraMode.TRACKING_GPS, name: 'TRACKING_GPS' },
      { mode: CameraMode.NONE, name: 'NONE' },
    ];

    // Find the next mode in the cycle
    const currentMode = this.locationComponent.getCameraMode();
    let nextIndex = 0;
    for (let i = 0; i < modes.length; i++) {
      if (modes[i].mode === currentMode) {
        nextIndex = (i + 1) % modes.length;
        break;
      }
    }

    this.locationComponent.setCameraMode(modes[nextIndex].mode);
    this.currentCameraMode = modes[nextIndex].name;
    this.statusMessage = 'Camera mode: ' + modes[nextIndex].name;
    showToast('Camera mode: ' + modes[nextIndex].name);
  }

  private forceUpdateLocation(): void {
    if (!this.locationComponent || !this.isComponentActivated) {
      showToast('Activate location component first');
      return;
    }

    // Force location update to Shanghai
    const lat = TEST_LOCATIONS.shanghai.latitude;
    const lng = TEST_LOCATIONS.shanghai.longitude;
    this.locationComponent.forceLocationUpdate(lat, lng, 0, 100);
    this.currentLatLng = lat.toFixed(4) + ', ' + lng.toFixed(4);
    this.statusMessage = 'Forced location to Shanghai';
    showToast('Location updated to Shanghai');
  }

  private moveMapAndTrack(): void {
    if (!this.mapController) {
      return;
    }

    // Move to Beijing to see if tracking follows
    this.mapController.easeTo(TEST_LOCATIONS.beijing.latitude, TEST_LOCATIONS.beijing.longitude, 0, 12, 2000);
    this.statusMessage = 'Moving map to Beijing (tracking should follow)';
  }

  @Builder
  mapContent() {
    MapView({
      onMapReady: this.onMapReady,
    })
      .width('100%')
      .height('100%')
  }

  @Builder
  controlPanel() {
    Column() {
      Text(this.statusMessage)
        .fontSize(14)
        .fontColor(this.isMapReady ? '#4CAF50' : '#FF9800')
        .width('100%')
        .padding(12)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)
        .margin({ bottom: 8 })

      Row() {
        Text('Camera Mode: ')
          .fontSize(13)
          .fontColor('#333')
        Text(this.currentCameraMode)
          .fontSize(13)
          .fontColor('#2196F3')
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .margin({ bottom: 4 })

      Row() {
        Text('Tracking: ')
          .fontSize(13)
          .fontColor('#333')
        Text(this.trackingState)
          .fontSize(13)
          .fontColor(this.isLocationEnabled ? '#4CAF50' : '#999')
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .margin({ bottom: 12 })

      Button(this.isComponentActivated ? 'Activated' : 'Activate Location')
        .width('100%')
        .enabled(!this.isComponentActivated && this.isMapReady)
        .backgroundColor(this.isComponentActivated ? '#4CAF50' : '#2196F3')
        .onClick(() => this.activateLocationComponent())

      Button(this.isLocationEnabled ? 'Disable Location' : 'Enable Location')
        .width('100%')
        .margin({ top: 8 })
        .enabled(this.isComponentActivated)
        .backgroundColor(this.isLocationEnabled ? '#FF5722' : '#4CAF50')
        .onClick(() => this.toggleLocationEnabled())

      Button('Cycle Camera Mode')
        .width('100%')
        .margin({ top: 8 })
        .enabled(this.isLocationEnabled)
        .onClick(() => this.cycleCameraMode())

      Button('Force Location to Shanghai')
        .width('100%')
        .margin({ top: 8 })
        .enabled(this.isComponentActivated)
        .onClick(() => this.forceUpdateLocation())

      Button('Move Map to Beijing')
        .width('100%')
        .margin({ top: 8 })
        .enabled(this.isMapReady)
        .onClick(() => this.moveMapAndTrack())
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Location Map Change',
      subtitle: 'Tracking during map movement',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
