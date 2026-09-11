/**
 * MultiMapTestPage - Display multiple map instances on screen.
 *
 * Tests the ability to create and manage several map instances simultaneously.
 * Each map can be controlled independently with its own camera and location.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, LatLng } from 'maplibre_harmony';
import { DEFAULT_MAP_CONFIG, TEST_LOCATIONS, showToast } from '../common/TestUtils';

@Entry
@Component
struct MultiMapTestPage {
  private mapA: MapLibreMap | null = null;
  private mapB: MapLibreMap | null = null;
  private mapC: MapLibreMap | null = null;
  @State private isMapAReady: boolean = false;
  @State private isMapBReady: boolean = false;
  @State private isMapCReady: boolean = false;
  @State private activeMapLabel: string = 'None';
  @State private zoomA: number = DEFAULT_MAP_CONFIG.zoom;
  @State private zoomB: number = DEFAULT_MAP_CONFIG.zoom;
  @State private zoomC: number = DEFAULT_MAP_CONFIG.zoom;

  aboutToDisappear() {
    this.mapA?.destroy();
    this.mapA = null;
    this.mapB?.destroy();
    this.mapB = null;
    this.mapC?.destroy();
    this.mapC = null;
  }

  private onMapAReady = (map: MapLibreMap): void => {
    this.mapA = map;
    this.isMapAReady = true;
    map.jumpTo(0, TEST_LOCATIONS.beijing.latitude, TEST_LOCATIONS.beijing.longitude, 0, 12);
    this.zoomA = 12;
    showToast('Map A (Beijing) ready');
  };

  private onMapBReady = (map: MapLibreMap): void => {
    this.mapB = map;
    this.isMapBReady = true;
    map.jumpTo(0, TEST_LOCATIONS.shanghai.latitude, TEST_LOCATIONS.shanghai.longitude, 0, 12);
    this.zoomB = 12;
    showToast('Map B (Shanghai) ready');
  };

  private onMapCReady = (map: MapLibreMap): void => {
    this.mapC = map;
    this.isMapCReady = true;
    map.jumpTo(0, TEST_LOCATIONS.guangzhou.latitude, TEST_LOCATIONS.guangzhou.longitude, 0, 12);
    this.zoomC = 12;
    showToast('Map C (Guangzhou) ready');
  };

  private zoomMap(label: string, delta: number): void {
    if (label === 'A' && this.mapA) {
      const z = this.mapA.getZoom();
      this.mapA.setZoom(z + delta, 300);
      this.zoomA = z + delta;
      this.activeMapLabel = 'A';
    } else if (label === 'B' && this.mapB) {
      const z = this.mapB.getZoom();
      this.mapB.setZoom(z + delta, 300);
      this.zoomB = z + delta;
      this.activeMapLabel = 'B';
    } else if (label === 'C' && this.mapC) {
      const z = this.mapC.getZoom();
      this.mapC.setZoom(z + delta, 300);
      this.zoomC = z + delta;
      this.activeMapLabel = 'C';
    }
  }

  private resetAll(): void {
    if (this.mapA) {
      this.mapA.jumpTo(0, TEST_LOCATIONS.beijing.latitude, TEST_LOCATIONS.beijing.longitude, 0, 12);
      this.zoomA = 12;
    }
    if (this.mapB) {
      this.mapB.jumpTo(0, TEST_LOCATIONS.shanghai.latitude, TEST_LOCATIONS.shanghai.longitude, 0, 12);
      this.zoomB = 12;
    }
    if (this.mapC) {
      this.mapC.jumpTo(0, TEST_LOCATIONS.guangzhou.latitude, TEST_LOCATIONS.guangzhou.longitude, 0, 12);
      this.zoomC = 12;
    }
    this.activeMapLabel = 'All reset';
    showToast('All maps reset to initial positions');
  }

  @Builder
  mapContent() {
    Column() {
      // Map A
      Column() {
        Text('Map A: Beijing')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .padding({ left: 8, top: 4 })
          .width('100%')
          .height(20)
          .backgroundColor('rgba(0,0,0,0.4)')
          .position({ top: 0 })
          .zIndex(1)

        MapView({
          onMapReady: this.onMapAReady,
        })
          .width('100%')
          .height('100%')
      }
      .height('33%')
      .width('100%')

      // Map B
      Column() {
        Text('Map B: Shanghai')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .padding({ left: 8, top: 4 })
          .width('100%')
          .height(20)
          .backgroundColor('rgba(0,0,0,0.4)')
          .position({ top: 0 })
          .zIndex(1)

        MapView({
          onMapReady: this.onMapBReady,
        })
          .width('100%')
          .height('100%')
      }
      .height('33%')
      .width('100%')
      .margin({ top: 2 })

      // Map C
      Column() {
        Text('Map C: Guangzhou')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .padding({ left: 8, top: 4 })
          .width('100%')
          .height(20)
          .backgroundColor('rgba(0,0,0,0.4)')
          .position({ top: 0 })
          .zIndex(1)

        MapView({
          onMapReady: this.onMapCReady,
        })
          .width('100%')
          .height('100%')
      }
      .height('33%')
      .width('100%')
      .margin({ top: 2 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  controlPanel() {
    Column() {
      Text('Active Map: ' + this.activeMapLabel)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 8 })

      Text('Zoom A=' + this.zoomA.toFixed(1) + ' B=' + this.zoomB.toFixed(1) + ' C=' + this.zoomC.toFixed(1))
        .fontSize(12)
        .fontColor('#666')
        .width('100%')
        .margin({ bottom: 12 })

      Text('Map A Controls').fontSize(13).fontWeight(FontWeight.Bold).width('100%').margin({ bottom: 4 })
      Row() {
        Button('A Zoom In').fontSize(12).width('48%')
          .onClick(() => this.zoomMap('A', 1)).enabled(this.isMapAReady)
        Button('A Zoom Out').fontSize(12).width('48%').margin({ left: 8 })
          .onClick(() => this.zoomMap('A', -1)).enabled(this.isMapAReady)
      }
      .width('100%')
      .margin({ bottom: 8 })

      Text('Map B Controls').fontSize(13).fontWeight(FontWeight.Bold).width('100%').margin({ bottom: 4 })
      Row() {
        Button('B Zoom In').fontSize(12).width('48%')
          .onClick(() => this.zoomMap('B', 1)).enabled(this.isMapBReady)
        Button('B Zoom Out').fontSize(12).width('48%').margin({ left: 8 })
          .onClick(() => this.zoomMap('B', -1)).enabled(this.isMapBReady)
      }
      .width('100%')
      .margin({ bottom: 8 })

      Text('Map C Controls').fontSize(13).fontWeight(FontWeight.Bold).width('100%').margin({ bottom: 4 })
      Row() {
        Button('C Zoom In').fontSize(12).width('48%')
          .onClick(() => this.zoomMap('C', 1)).enabled(this.isMapCReady)
        Button('C Zoom Out').fontSize(12).width('48%').margin({ left: 8 })
          .onClick(() => this.zoomMap('C', -1)).enabled(this.isMapCReady)
      }
      .width('100%')
      .margin({ bottom: 8 })

      Button('Reset All Maps').width('100%')
        .onClick(() => this.resetAll())
        .enabled(this.isMapAReady || this.isMapBReady || this.isMapCReady)
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Multi Map',
      subtitle: '3 map instances: Beijing, Shanghai, Guangzhou',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
