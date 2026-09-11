/**
 * LocationModesTestPage - Test location tracking modes.
 *
 * Demonstrates switching between NORMAL, COMPASS, and GPS render modes,
 * and various camera tracking modes.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { LocationComponent, LocationComponentOptions, CameraMode, RenderMode } from 'maplibre_harmony';
import { showToast } from '../common/TestUtils';

@Entry
@Component
struct LocationModesTestPage {
  private mapController: MapLibreMap | null = null;
  private locationComponent: LocationComponent | null = null;
  @State private isMapReady: boolean = false;
  @State private isActivated: boolean = false;
  @State private isEnabled: boolean = false;
  @State private currentRenderMode: string = 'NORMAL';
  @State private currentCameraMode: string = 'NONE';
  @State private statusMessage: string = 'Loading...';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready';
  };

  private activateAndEnable(): void {
    if (!this.mapController) {
      return;
    }

    const locationComponent = this.mapController.getLocationComponent();
    if (!locationComponent) {
      showToast('Failed to get LocationComponent');
      return;
    }

    this.locationComponent = locationComponent;

    // Wait for style to load, then activate
    this.mapController.addOnDidFinishLoadingStyleListener(() => {
      const options = new LocationComponentOptions();
      locationComponent.activateLocationComponent(options).then(() => {
        this.isActivated = true;
        locationComponent.setLocationComponentEnabled(true);
        this.isEnabled = true;
        locationComponent.setCameraMode(CameraMode.TRACKING);
        locationComponent.setRenderMode(RenderMode.NORMAL);
        this.currentRenderMode = RenderMode.getName(RenderMode.NORMAL);
        this.currentCameraMode = CameraMode.getName(CameraMode.TRACKING);
        this.statusMessage = 'Location active, mode: NORMAL / TRACKING';
        showToast('Location activated');
      }).catch((err: Error) => {
        this.statusMessage = 'Activation failed: ' + err.message;
      });
    });
  }

  private setRenderMode(mode: number, name: string): void {
    if (!this.locationComponent || !this.isActivated) {
      showToast('Activate location first');
      return;
    }
    try {
      this.locationComponent.setRenderMode(mode);
      this.currentRenderMode = name;
      this.statusMessage = 'Render mode: ' + name;
      showToast('Render mode: ' + name);
    } catch (err) {
      this.statusMessage = 'Error: ' + err;
    }
  }

  private setCameraMode(mode: number, name: string): void {
    if (!this.locationComponent || !this.isEnabled) {
      showToast('Enable location first');
      return;
    }
    try {
      this.locationComponent.setCameraMode(mode);
      this.currentCameraMode = name;
      this.statusMessage = 'Camera mode: ' + name;
      showToast('Camera mode: ' + name);
    } catch (err) {
      this.statusMessage = 'Error: ' + err;
    }
  }

  private toggleEnabled(): void {
    if (!this.locationComponent || !this.isActivated) {
      showToast('Activate first');
      return;
    }
    const newState = !this.isEnabled;
    this.locationComponent.setLocationComponentEnabled(newState);
    this.isEnabled = newState;
    this.statusMessage = newState ? 'Location enabled' : 'Location disabled';
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

      if (!this.isActivated) {
        Button('Activate & Enable Location')
          .width('100%')
          .enabled(this.isMapReady)
          .onClick(() => this.activateAndEnable())
      } else {
        Button(this.isEnabled ? 'Disable' : 'Enable')
          .width('100%')
          .backgroundColor(this.isEnabled ? '#FF5722' : '#4CAF50')
          .onClick(() => this.toggleEnabled())
      }

      Divider().margin({ top: 12, bottom: 8 })

      Text('Render Modes').fontSize(15).fontWeight(FontWeight.Bold).width('100%')

      Row() {
        Button('NORMAL')
          .width('31%')
          .backgroundColor(this.currentRenderMode === 'NORMAL' ? '#2196F3' : '#9E9E9E')
          .onClick(() => this.setRenderMode(RenderMode.NORMAL, 'NORMAL'))

        Button('COMPASS')
          .width('31%')
          .margin({ left: '3%' })
          .backgroundColor(this.currentRenderMode === 'COMPASS' ? '#2196F3' : '#9E9E9E')
          .onClick(() => this.setRenderMode(RenderMode.COMPASS, 'COMPASS'))

        Button('GPS')
          .width('31%')
          .margin({ left: '3%' })
          .backgroundColor(this.currentRenderMode === 'GPS' ? '#2196F3' : '#9E9E9E')
          .onClick(() => this.setRenderMode(RenderMode.GPS, 'GPS'))
      }
      .width('100%')
      .margin({ top: 4 })

      Divider().margin({ top: 12, bottom: 8 })

      Text('Camera Modes').fontSize(15).fontWeight(FontWeight.Bold).width('100%')

      Button('TRACKING')
        .width('100%')
        .margin({ top: 4 })
        .backgroundColor(this.currentCameraMode === 'TRACKING' ? '#2196F3' : '#9E9E9E')
        .enabled(this.isEnabled)
        .onClick(() => this.setCameraMode(CameraMode.TRACKING, 'TRACKING'))

      Button('TRACKING_COMPASS')
        .width('100%')
        .margin({ top: 4 })
        .backgroundColor(this.currentCameraMode === 'TRACKING_COMPASS' ? '#2196F3' : '#9E9E9E')
        .enabled(this.isEnabled)
        .onClick(() => this.setCameraMode(CameraMode.TRACKING_COMPASS, 'TRACKING_COMPASS'))

      Button('TRACKING_GPS')
        .width('100%')
        .margin({ top: 4 })
        .backgroundColor(this.currentCameraMode === 'TRACKING_GPS' ? '#2196F3' : '#9E9E9E')
        .enabled(this.isEnabled)
        .onClick(() => this.setCameraMode(CameraMode.TRACKING_GPS, 'TRACKING_GPS'))

      Button('NONE (No Tracking)')
        .width('100%')
        .margin({ top: 4 })
        .backgroundColor(this.currentCameraMode === 'NONE' ? '#FF5722' : '#9E9E9E')
        .enabled(this.isEnabled)
        .onClick(() => this.setCameraMode(CameraMode.NONE, 'NONE'))

      // Status display
      Text('Render: ' + this.currentRenderMode + ' | Camera: ' + this.currentCameraMode)
        .fontSize(12)
        .fontColor('#666')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 12 })
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Location Modes',
      subtitle: 'Render and camera tracking modes',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
