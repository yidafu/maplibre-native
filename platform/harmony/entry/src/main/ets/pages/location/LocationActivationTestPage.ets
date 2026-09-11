/**
 * LocationActivationTestPage - Test location component lifecycle.
 *
 * Demonstrates activateLocationComponent, setLocationComponentEnabled,
 * and the lifecycle methods (onStart, onStop, onDestroy).
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { LocationComponent, LocationComponentOptions, CameraMode, RenderMode } from 'maplibre_harmony';
import { showToast } from '../common/TestUtils';

@Entry
@Component
struct LocationActivationTestPage {
  private mapController: MapLibreMap | null = null;
  private locationComponent: LocationComponent | null = null;
  @State private isMapReady: boolean = false;
  @State private activationState: string = 'Not activated';
  @State private enabledState: string = 'N/A';
  @State private statusMessage: string = 'Loading...';
  @State private lastLatLng: string = '--';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready';
  };

  private activate(): void {
    if (!this.mapController || !this.isMapReady) {
      showToast('Map not ready');
      return;
    }
    this.mapController.addOnDidFinishLoadingStyleListener(() => {
      this.doActivate();
    });
  }

  private doActivate(): void {
    if (this.locationComponent && this.activationState !== 'Not activated') {
      showToast('Already activated');
      return;
    }

    const lc = this.mapController!.getLocationComponent();
    if (!lc) {
      showToast('No LocationComponent available');
      return;
    }
    this.locationComponent = lc;

    const options = new LocationComponentOptions();
    lc.activateLocationComponent(options).then(() => {
      this.activationState = 'Activated';
      this.enabledState = 'Disabled';
      this.statusMessage = 'Component activated. Tap Enable to start.';
      showToast('Location component activated');
    }).catch((err: Error) => {
      this.activationState = 'Error: ' + err.message;
      this.statusMessage = 'Activation failed';
      showToast('Activation error: ' + err.message);
    });
  }

  private toggleEnabled(): void {
    if (!this.locationComponent || this.activationState !== 'Activated') {
      showToast('Activate first');
      return;
    }
    try {
      const currentEnabled = this.enabledState === 'Enabled';
      this.locationComponent.setLocationComponentEnabled(!currentEnabled);
      this.enabledState = currentEnabled ? 'Disabled' : 'Enabled';
      this.statusMessage = 'Location ' + (currentEnabled ? 'disabled' : 'enabled');

      if (!currentEnabled) {
        this.locationComponent.setCameraMode(CameraMode.TRACKING);
      }
    } catch (err) {
      this.statusMessage = 'Toggle error: ' + err;
    }
  }

  private forceLocation(): void {
    if (!this.locationComponent || this.activationState !== 'Activated') {
      showToast('Activate first');
      return;
    }
    // Force location near Tokyo
    this.locationComponent.forceLocationUpdate(35.6762, 139.6503, 45, 100);
    this.lastLatLng = '35.6762, 139.6503';
    this.statusMessage = 'Forced location to Tokyo';
    showToast('Location set to Tokyo');
  }

  private callOnStop(): void {
    if (!this.locationComponent || this.activationState !== 'Activated') {
      showToast('Activate first');
      return;
    }
    this.locationComponent.onStop();
    this.enabledState = 'Stopped';
    this.statusMessage = 'Called onStop() - location updates paused';
    showToast('onStop() called');
  }

  private callOnStart(): void {
    if (!this.locationComponent || this.activationState !== 'Activated') {
      showToast('Activate first');
      return;
    }
    this.locationComponent.onStart();
    this.enabledState = 'Started';
    this.statusMessage = 'Called onStart() - location updates resumed';
    showToast('onStart() called');
  }

  private deactivateAndCleanup(): void {
    if (!this.locationComponent) {
      showToast('Nothing to deactivate');
      return;
    }
    this.locationComponent.onDestroy();
    this.activationState = 'Deactivated';
    this.enabledState = 'N/A';
    this.locationComponent = null;
    this.statusMessage = 'Component destroyed and cleaned up';
    showToast('Location component destroyed');
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

      Column() {
        Row() {
          Text('Activation: ')
            .fontSize(13)
          Text(this.activationState)
            .fontSize(13)
            .fontColor('#2196F3')
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .margin({ top: 8 })

        Row() {
          Text('Enabled: ')
            .fontSize(13)
          Text(this.enabledState)
            .fontSize(13)
            .fontColor(this.enabledState === 'Enabled' ? '#4CAF50' : '#999')
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .margin({ top: 4 })
      }
      .padding(12)
      .backgroundColor('#F5F5F5')
      .borderRadius(6)
      .margin({ top: 8, bottom: 8 })

      // Activate
      Button('Activate Location Component')
        .width('100%')
        .enabled(this.isMapReady && this.activationState === 'Not activated')
        .onClick(() => this.activate())

      // Toggle enable
      Button(this.enabledState === 'Enabled' ? 'Disable Location' : 'Enable Location')
        .width('100%')
        .margin({ top: 8 })
        .enabled(this.activationState === 'Activated' && this.enabledState !== 'Stopped')
        .onClick(() => this.toggleEnabled())

      Divider().height(1).margin({ top: 12, bottom: 8 })

      Text('Lifecycle Methods').fontSize(15).fontWeight(FontWeight.Bold).width('100%')

      Row() {
        Button('onStart()')
          .width('48%')
          .enabled(this.activationState === 'Activated')
          .onClick(() => this.callOnStart())

        Button('onStop()')
          .width('48%')
          .margin({ left: '4%' })
          .enabled(this.activationState === 'Activated')
          .onClick(() => this.callOnStop())
      }
      .width('100%')
      .margin({ top: 8 })

      Button('Force Location (Tokyo)')
        .width('100%')
        .margin({ top: 8 })
        .enabled(this.activationState === 'Activated')
        .onClick(() => this.forceLocation())

      Button('Deactivate / Destroy')
        .width('100%')
        .margin({ top: 8 })
        .backgroundColor('#FF5722')
        .enabled(this.activationState === 'Activated')
        .onClick(() => this.deactivateAndCleanup())
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Location Activation',
      subtitle: 'Component lifecycle',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
