/**
 * ScrollByTestPage - Pan the map by pixel offset.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { showToast } from '../common/TestUtils';

@Entry
@Component
struct ScrollByTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Ready';
  @State private scrollAmount: number = 100;

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready';
  };

  private scrollBy(dx: number, dy: number): void {
    if (!this.mapController) return;
    this.mapController.moveBy(dx, dy, 300);
    this.statusMessage = `Scrolled by (${dx}, ${dy})px`;
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
      Text('Scroll By (Pan)')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 8 })

      Text(this.statusMessage)
        .fontSize(13)
        .fontColor('#333')
        .width('100%')
        .padding(10)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      Text('Direction')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Row() {
        Button('Up').height(44).enabled(this.isMapReady)
          .onClick((): void => this.scrollBy(0, -this.scrollAmount))
        Button('Down').height(44).margin({ left: 12 }).enabled(this.isMapReady)
          .onClick((): void => this.scrollBy(0, this.scrollAmount))
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)

      Row() {
        Button('Left').height(44).margin({ top: 8 }).enabled(this.isMapReady)
          .onClick((): void => this.scrollBy(-this.scrollAmount, 0))
        Button('Right').height(44).margin({ top: 8, left: 12 }).enabled(this.isMapReady)
          .onClick((): void => this.scrollBy(this.scrollAmount, 0))
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)

      Text('Diagonal')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Row() {
        Button('Up-Left').height(36).enabled(this.isMapReady)
          .onClick((): void => this.scrollBy(-this.scrollAmount, -this.scrollAmount))
        Button('Up-Right').height(36).margin({ left: 6 }).enabled(this.isMapReady)
          .onClick((): void => this.scrollBy(this.scrollAmount, -this.scrollAmount))
        Button('Down-Left').height(36).margin({ left: 6 }).enabled(this.isMapReady)
          .onClick((): void => this.scrollBy(-this.scrollAmount, this.scrollAmount))
        Button('Down-Right').height(36).margin({ left: 6 }).enabled(this.isMapReady)
          .onClick((): void => this.scrollBy(this.scrollAmount, this.scrollAmount))
      }
      .width('100%')

      Text('Scroll Distance')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Row() {
        Button('50px').height(36).enabled(this.isMapReady)
          .onClick((): void => { this.scrollAmount = 50; showToast('Scroll distance: 50px'); })
        Button('100px').height(36).margin({ left: 6 }).enabled(this.isMapReady)
          .onClick((): void => { this.scrollAmount = 100; showToast('Scroll distance: 100px'); })
        Button('200px').height(36).margin({ left: 6 }).enabled(this.isMapReady)
          .onClick((): void => { this.scrollAmount = 200; showToast('Scroll distance: 200px'); })
        Button('500px').height(36).margin({ left: 6 }).enabled(this.isMapReady)
          .onClick((): void => { this.scrollAmount = 500; showToast('Scroll distance: 500px'); })
      }
      .width('100%')
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Scroll By',
      subtitle: 'Pan the map by pixel offset',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
