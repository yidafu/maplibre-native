/**
 * CameraPositionTestPage - Set camera position and zoom.
 *
 * Reference: Android CameraPositionActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, CameraState } from 'maplibre_harmony';
import { TEST_LOCATIONS, showToast } from '../common/TestUtils';

@Entry
@Component
struct CameraPositionTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Ready';
  @State private lat: number = 30.2741;
  @State private lng: number = 120.1551;
  @State private zoom: number = 8;
  @State private bearing: number = 0;
  @State private pitch: number = 0;

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.refreshCameraState();
  };

  private refreshCameraState(): void {
    if (!this.mapController) return;
    const state: CameraState = this.mapController.getCameraState();
    this.lat = state.latitude;
    this.lng = state.longitude;
    this.zoom = state.zoom;
    this.bearing = state.bearing;
    this.pitch = state.pitch;
    this.statusMessage = `Lat: ${state.latitude.toFixed(4)}, Lng: ${state.longitude.toFixed(4)}`;
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
      Text('Camera State')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 8 })

      Column() {
        this.buildInfoRow('Latitude', this.lat.toFixed(4))
        this.buildInfoRow('Longitude', this.lng.toFixed(4))
        this.buildInfoRow('Zoom', this.zoom.toFixed(2))
        this.buildInfoRow('Bearing', `${this.bearing.toFixed(1)} deg`)
        this.buildInfoRow('Pitch', `${this.pitch.toFixed(1)} deg`)
      }
      .width('100%')
      .padding(8)
      .backgroundColor('#F5F5F5')
      .borderRadius(6)

      Text('Jump to Location')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Row() {
        Button('Beijing').height(36)
          .onClick((): void => {
            this.mapController?.jumpTo(0, 39.9042, 116.4074, 0, 10);
            setTimeout((): void => this.refreshCameraState(), 200);
          })
        Button('Shanghai').height(36).margin({ left: 6 })
          .onClick((): void => {
            this.mapController?.jumpTo(0, 31.2304, 121.4737, 0, 12);
            setTimeout((): void => this.refreshCameraState(), 200);
          })
        Button('London').height(36).margin({ left: 6 })
          .onClick((): void => {
            this.mapController?.jumpTo(0, 51.5074, -0.1278, 0, 10);
            setTimeout((): void => this.refreshCameraState(), 200);
          })
      }
      .width('100%')

      Row() {
        Button('Tokyo').height(36).margin({ top: 6 })
          .onClick((): void => {
            this.mapController?.jumpTo(0, 35.6762, 139.6503, 0, 11);
            setTimeout((): void => this.refreshCameraState(), 200);
          })
        Button('NYC').height(36).margin({ top: 6, left: 6 })
          .onClick((): void => {
            this.mapController?.jumpTo(0, 40.7128, -74.006, 0, 11);
            setTimeout((): void => this.refreshCameraState(), 200);
          })
        Button('SF').height(36).margin({ top: 6, left: 6 })
          .onClick((): void => {
            this.mapController?.jumpTo(0, 37.7749, -122.4194, 0, 10);
            setTimeout((): void => this.refreshCameraState(), 200);
          })
      }
      .width('100%')

      Text('Zoom Level')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Row() {
        Button('Zoom 4').height(36)
          .onClick((): void => { this.mapController?.setZoom(4); setTimeout((): void => this.refreshCameraState(), 200); })
        Button('Zoom 8').height(36).margin({ left: 6 })
          .onClick((): void => { this.mapController?.setZoom(8); setTimeout((): void => this.refreshCameraState(), 200); })
        Button('Zoom 12').height(36).margin({ left: 6 })
          .onClick((): void => { this.mapController?.setZoom(12); setTimeout((): void => this.refreshCameraState(), 200); })
        Button('Zoom 16').height(36).margin({ left: 6 })
          .onClick((): void => { this.mapController?.setZoom(16); setTimeout((): void => this.refreshCameraState(), 200); })
      }
      .width('100%')

      Button('Refresh State')
        .width('100%')
        .margin({ top: 10 })
        .onClick((): void => {
          this.refreshCameraState();
          showToast('Camera state refreshed');
        })
        .enabled(this.isMapReady)
    }
    .width('100%')
  }

  @Builder
  buildInfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(12)
        .fontColor('#666')
        .width(80)
      Text(value)
        .fontSize(12)
        .fontFamily('monospace')
        .fontColor('#333')
        .layoutWeight(1)
    }
    .width('100%')
    .height(24)
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Camera Position',
      subtitle: 'Set camera position and zoom',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
