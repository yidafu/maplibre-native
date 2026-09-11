/**
 * LatLngBoundsTestPage - Constrain camera to bounds.
 *
 * Reference: Android LatLngBoundsActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, LatLng, LatLngBounds, CameraPosition, CameraState } from 'maplibre_harmony';
import { TEST_LOCATIONS, showToast } from '../common/TestUtils';

@Entry
@Component
struct LatLngBoundsTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Ready';
  @State private boundsActive: boolean = false;

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready';
  };

  private fitBounds(bounds: LatLngBounds, animated: boolean): void {
    if (!this.mapController) return;
    this.mapController.setCameraForBounds(bounds, animated, 500);
    const center = bounds.getCenter();
    this.statusMessage = `Bounds: N${bounds.north.toFixed(2)} S${bounds.south.toFixed(2)} E${bounds.east.toFixed(2)} W${bounds.west.toFixed(2)}`;
    this.boundsActive = true;
  }

  private constrainBounds(bounds: LatLngBounds): void {
    if (!this.mapController) return;
    this.mapController.setLatLngBounds(bounds);
    this.statusMessage = `Bounds constrained. Pan/zoom limited.`;
    this.boundsActive = true;
  }

  private clearBounds(): void {
    if (!this.mapController) return;
    this.mapController.setLatLngBounds(null);
    this.boundsActive = false;
    this.statusMessage = 'Bounds cleared';
    showToast('Map bounds unrestricted');
  }

  private getCameraForBounds(bounds: LatLngBounds): void {
    if (!this.mapController) return;
    const camera = this.mapController.getCameraForBounds(bounds);
    if (camera) {
      this.statusMessage = `Camera: zoom=${camera.zoom.toFixed(2)}, bearing=${camera.bearing.toFixed(1)}`;
      this.mapController.animateCamera(camera, 800);
      showToast('Camera fit to bounds');
    }
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
        .fontSize(13)
        .fontColor(this.boundsActive ? '#FF9800' : '#4CAF50')
        .width('100%')
        .padding(10)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      Text('Fit to Bounds')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Row() {
        Button('Beijing Area').height(36).enabled(this.isMapReady)
          .onClick(() => this.fitBounds(new LatLngBounds(40.1, 116.6, 39.7, 116.2), true))
        Button('China').height(36).margin({ left: 6 }).enabled(this.isMapReady)
          .onClick(() => this.fitBounds(new LatLngBounds(53.5, 135.0, 18.0, 73.5), true))
      }
      .width('100%')

      Row() {
        Button('USA').height(36).margin({ top: 6 }).enabled(this.isMapReady)
          .onClick(() => this.fitBounds(new LatLngBounds(49.0, -66.0, 24.0, -125.0), true))
        Button('Europe').height(36).margin({ top: 6, left: 6 }).enabled(this.isMapReady)
          .onClick(() => this.fitBounds(new LatLngBounds(60.0, 40.0, 35.0, -10.0), true))
      }
      .width('100%')

      Row() {
        Button('World').height(36).margin({ top: 6 }).enabled(this.isMapReady)
          .onClick(() => this.fitBounds(new LatLngBounds(85.0, 180.0, -85.0, -180.0), true))
        Button('Fit No Anim').height(36).margin({ top: 6, left: 6 }).enabled(this.isMapReady)
          .onClick(() => this.fitBounds(new LatLngBounds(40.1, 116.6, 39.7, 116.2), false))
      }
      .width('100%')

      Text('Constrain / Limit')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Row() {
        Button('Constrain Beijing').height(36).enabled(this.isMapReady)
          .onClick(() => this.constrainBounds(new LatLngBounds(40.5, 117.0, 39.4, 115.5)))
        Button('Clear Bounds').height(36).margin({ left: 6 }).enabled(this.isMapReady && this.boundsActive)
          .onClick(() => this.clearBounds())
      }
      .width('100%')

      Text('Get Camera for Bounds')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Row() {
        Button('Camera for Shanghai').height(36).enabled(this.isMapReady)
          .onClick(() => this.getCameraForBounds(new LatLngBounds(31.5, 121.7, 30.9, 121.2)))
        Button('Camera for Hangzhou').height(36).margin({ left: 6 }).enabled(this.isMapReady)
          .onClick(() => this.getCameraForBounds(new LatLngBounds(30.5, 120.4, 30.0, 119.9)))
      }
      .width('100%')
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'LatLng Bounds',
      subtitle: 'Constrain camera to bounds',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
