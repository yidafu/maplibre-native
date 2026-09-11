/**
 * DoubleMapTestPage - Two map instances side by side.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { showToast } from '../common/TestUtils';

@Entry
@Component
struct DoubleMapTestPage {
  private mapLeft: MapLibreMap | null = null;
  private mapRight: MapLibreMap | null = null;
  @State private isMapLeftReady: boolean = false;
  @State private isMapRightReady: boolean = false;
  @State private syncEnabled: boolean = false;
  @State private statusMessage: string = 'Initializing...';

  aboutToDisappear() {
    this.mapLeft?.destroy();
    this.mapLeft = null;
    this.mapRight?.destroy();
    this.mapRight = null;
  }

  private onLeftMapReady = (map: MapLibreMap): void => {
    this.mapLeft = map;
    this.isMapLeftReady = true;
    this.updateStatus();
    console.info('[DoubleMapTestPage] Left map ready');
  };

  private onRightMapReady = (map: MapLibreMap): void => {
    this.mapRight = map;
    this.isMapRightReady = true;
    this.updateStatus();
    console.info('[DoubleMapTestPage] Right map ready');
  };

  private updateStatus(): void {
    const left = this.isMapLeftReady ? 'ready' : 'loading';
    const right = this.isMapRightReady ? 'ready' : 'loading';
    this.statusMessage = `Left: ${left} | Right: ${right}`;
    if (this.isMapLeftReady && this.isMapRightReady) {
      showToast('Both maps ready');
    }
  }

  private applyToBoth(action: (map: MapLibreMap) => void): void {
    if (this.mapLeft) action(this.mapLeft);
    if (this.mapRight) action(this.mapRight);
  }

  private jumpBothTo(lat: number, lng: number, zoom: number): void {
    this.applyToBoth((map) => {
      map.jumpTo(0, lat, lng, 0, zoom);
    });
    this.statusMessage = `Jumped to (${lat.toFixed(2)}, ${lng.toFixed(2)})`;
  }

  @Builder
  leftMapContent() {
    Column() {
      Text('Map A')
        .fontSize(12)
        .fontColor('#666')
        .padding(4)
      MapView({
        onMapReady: this.onLeftMapReady,
        initialLatitude: 39.9042,
        initialLongitude: 116.4074,
        initialZoom: 6,
      })
        .width('100%')
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  rightMapContent() {
    Column() {
      Text('Map B')
        .fontSize(12)
        .fontColor('#666')
        .padding(4)
      MapView({
        onMapReady: this.onRightMapReady,
        initialLatitude: 30.2741,
        initialLongitude: 120.1551,
        initialZoom: 6,
      })
        .width('100%')
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  mapContent() {
    Row() {
      this.leftMapContent()
      Divider().width(2).height('100%').color('#2196F3')
      this.rightMapContent()
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  controlPanel() {
    Column() {
      Text(this.statusMessage)
        .fontSize(12)
        .fontColor('#333')
        .width('100%')
        .padding(10)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      Text('Sync Control')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Row() {
        Button('Sync Both To Beijing').height(36)
          .enabled(this.isMapLeftReady && this.isMapRightReady)
          .layoutWeight(1)
          .onClick(() => this.jumpBothTo(39.9042, 116.4074, 10))
        Button('Sync Both To NYC').height(36)
          .enabled(this.isMapLeftReady && this.isMapRightReady)
          .layoutWeight(1)
          .margin({ left: 6 })
          .onClick(() => this.jumpBothTo(40.7128, -74.006, 10))
      }
      .width('100%')

      Row() {
        Button('Sync To Shanghai').height(36).margin({ top: 6 })
          .enabled(this.isMapLeftReady && this.isMapRightReady)
          .layoutWeight(1)
          .onClick(() => this.jumpBothTo(31.2304, 121.4737, 11))
        Button('Sync To London').height(36).margin({ top: 6, left: 6 })
          .enabled(this.isMapLeftReady && this.isMapRightReady)
          .layoutWeight(1)
          .onClick(() => this.jumpBothTo(51.5074, -0.1278, 8))
      }
      .width('100%')

      Text('Individual Control')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Row() {
        Button('Zoom Left +1').height(32)
          .enabled(this.isMapLeftReady)
          .layoutWeight(1)
          .onClick(() => {
            if (!this.mapLeft) return;
            this.mapLeft.setZoom(this.mapLeft.getZoom() + 1);
          })
        Button('Zoom Right +1').height(32)
          .enabled(this.isMapRightReady)
          .layoutWeight(1)
          .margin({ left: 6 })
          .onClick(() => {
            if (!this.mapRight) return;
            this.mapRight.setZoom(this.mapRight.getZoom() + 1);
          })
      }
      .width('100%')

      Row() {
        Button('Reset Left').height(32).margin({ top: 6 })
          .enabled(this.isMapLeftReady)
          .layoutWeight(1)
          .onClick(() => this.mapLeft?.jumpTo(0, 39.9042, 116.4074, 0, 6))
        Button('Reset Right').height(32).margin({ top: 6, left: 6 })
          .enabled(this.isMapRightReady)
          .layoutWeight(1)
          .onClick(() => this.mapRight?.jumpTo(0, 30.2741, 120.1551, 0, 6))
      }
      .width('100%')
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Double Map',
      subtitle: 'Two map instances side by side',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
