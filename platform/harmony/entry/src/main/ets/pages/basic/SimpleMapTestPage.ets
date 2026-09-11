/**
 * SimpleMapTestPage - Display a basic interactive map.
 *
 * Reference: Android SimpleMapActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct SimpleMapTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready';
    console.info('[SimpleMapTestPage] Map ready');
  };

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

      Text('Map Controls')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Row() {
        Button('Zoom In')
          .width('48%')
          .onClick((): void => {
            if (this.mapController) {
              const z = this.mapController.getZoom();
              this.mapController.setZoom(z + 1, 300);
              this.statusMessage = `Zoom: ${(z + 1).toFixed(1)}`;
            }
          })
          .enabled(this.isMapReady)

        Button('Zoom Out')
          .width('48%')
          .margin({ left: 8 })
          .onClick((): void => {
            if (this.mapController) {
              const z = this.mapController.getZoom();
              this.mapController.setZoom(z - 1, 300);
              this.statusMessage = `Zoom: ${(z - 1).toFixed(1)}`;
            }
          })
          .enabled(this.isMapReady)
      }
      .width('100%')

      Row() {
        Button('Jump to Default')
          .width('100%')
          .margin({ top: 8 })
          .onClick((): void => {
            if (this.mapController) {
              this.mapController.jumpTo(0, DEFAULT_MAP_CONFIG.latitude,
                DEFAULT_MAP_CONFIG.longitude, 0, DEFAULT_MAP_CONFIG.zoom);
              this.statusMessage = 'Jumped to default position';
            }
          })
          .enabled(this.isMapReady)
      }
      .width('100%')
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Simple Map',
      subtitle: 'Basic map display',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
