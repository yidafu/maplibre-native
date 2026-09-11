/**
 * ZoomControlsTestPage - Manual zoom and zoom limits.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, CameraState } from 'maplibre_harmony';
import { showToast } from '../common/TestUtils';

@Entry
@Component
struct ZoomControlsTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private currentZoom: number = 8;
  @State private minZoom: number = 0;
  @State private maxZoom: number = 22;
  @State private statusMessage: string = 'Ready';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.refreshZoomState();
    this.statusMessage = 'Map ready';
  };

  private refreshZoomState(): void {
    if (!this.mapController) return;
    this.currentZoom = this.mapController.getZoom();
    this.minZoom = this.mapController.getMinZoom();
    this.maxZoom = this.mapController.getMaxZoom();
  }

  private setZoom(zoom: number): void {
    if (!this.mapController) return;
    this.mapController.setZoom(zoom, undefined, undefined, 200);
    setTimeout((): void => this.refreshZoomState(), 300);
    this.statusMessage = `Zoom set to ${zoom.toFixed(1)}`;
  }

  private zoomIn(): void {
    if (!this.mapController) return;
    const z: number = this.mapController.getZoom();
    this.setZoom(z + 1);
  }

  private zoomOut(): void {
    if (!this.mapController) return;
    const z: number = this.mapController.getZoom();
    this.setZoom(z - 1);
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
      Text('Zoom Controls')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 8 })

      Row() {
        Text(`Current Zoom: ${this.currentZoom.toFixed(2)}`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding(12)
      .backgroundColor('#F5F5F5')
      .borderRadius(6)

      Text('Adjust Zoom')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Row() {
        Button('Zoom In').height(44).enabled(this.isMapReady)
          .onClick((): void => this.zoomIn())
        Button('Zoom Out').height(44).margin({ left: 12 }).enabled(this.isMapReady)
          .onClick((): void => this.zoomOut())
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)

      Row() {
        Button('Set Zoom 1').height(36).margin({ top: 8 }).enabled(this.isMapReady)
          .onClick((): void => this.setZoom(1))
        Button('Set Zoom 5').height(36).margin({ top: 8, left: 6 }).enabled(this.isMapReady)
          .onClick((): void => this.setZoom(5))
        Button('Set Zoom 10').height(36).margin({ top: 8, left: 6 }).enabled(this.isMapReady)
          .onClick((): void => this.setZoom(10))
        Button('Set Zoom 15').height(36).margin({ top: 8, left: 6 }).enabled(this.isMapReady)
          .onClick((): void => this.setZoom(15))
      }
      .width('100%')

      Button('Reset Zoom')
        .width('100%')
        .margin({ top: 8 })
        .enabled(this.isMapReady)
        .onClick((): void => {
          this.mapController?.resetZoom();
          setTimeout((): void => this.refreshZoomState(), 300);
          this.statusMessage = 'Zoom reset';
        })

      Text('Zoom Limits')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Text(`Min Zoom: ${this.minZoom.toFixed(1)}  |  Max Zoom: ${this.maxZoom.toFixed(1)}`)
        .fontSize(12)
        .fontColor('#666')
        .width('100%')

      Row() {
        Button('Set Min=5').height(36).margin({ top: 6 }).enabled(this.isMapReady)
          .onClick((): void => {
            this.mapController?.setMinZoom(5);
            setTimeout((): void => this.refreshZoomState(), 100);
            this.statusMessage = 'Min zoom set to 5';
          })
        Button('Set Min=10').height(36).margin({ top: 6, left: 6 }).enabled(this.isMapReady)
          .onClick((): void => {
            this.mapController?.setMinZoom(10);
            setTimeout((): void => this.refreshZoomState(), 100);
            this.statusMessage = 'Min zoom set to 10';
          })
        Button('Set Max=15').height(36).margin({ top: 6, left: 6 }).enabled(this.isMapReady)
          .onClick((): void => {
            this.mapController?.setMaxZoom(15);
            setTimeout((): void => this.refreshZoomState(), 100);
            this.statusMessage = 'Max zoom set to 15';
          })
        Button('Reset Limits').height(36).margin({ top: 6, left: 6 }).enabled(this.isMapReady)
          .onClick((): void => {
            this.mapController?.setMinZoom(0);
            this.mapController?.setMaxZoom(22);
            setTimeout((): void => this.refreshZoomState(), 100);
            this.statusMessage = 'Zoom limits reset';
          })
      }
      .width('100%')
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Zoom Controls',
      subtitle: 'Manual zoom and zoom limits',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
