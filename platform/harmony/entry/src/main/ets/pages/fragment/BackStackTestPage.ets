/**
 * BackStackTestPage - Simulate fragment back stack navigation with map views.
 *
 * Demonstrates different map views that can be pushed/popped like fragment
 * transactions. Each "stack entry" shows a different geographic location.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, LatLng, CameraPosition } from 'maplibre_harmony';
import { DEFAULT_MAP_CONFIG, TEST_LOCATIONS, showToast } from '../common/TestUtils';

interface StackEntry {
  label: string;
  latitude: number;
  longitude: number;
  zoom: number;
}

@Entry
@Component
struct BackStackTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private stack: StackEntry[] = [];
  @State private currentIndex: number = -1;
  @State private currentLabel: string = 'Default';
  @State private stackDepth: number = 0;

  private readonly locations: StackEntry[] = [
    { label: 'Beijing', latitude: TEST_LOCATIONS.beijing.latitude, longitude: TEST_LOCATIONS.beijing.longitude, zoom: 12 },
    { label: 'Shanghai', latitude: TEST_LOCATIONS.shanghai.latitude, longitude: TEST_LOCATIONS.shanghai.longitude, zoom: 12 },
    { label: 'Guangzhou', latitude: TEST_LOCATIONS.guangzhou.latitude, longitude: TEST_LOCATIONS.guangzhou.longitude, zoom: 12 },
    { label: 'Shenzhen', latitude: TEST_LOCATIONS.shenzhen.latitude, longitude: TEST_LOCATIONS.shenzhen.longitude, zoom: 12 },
    { label: 'Chengdu', latitude: TEST_LOCATIONS.chengdu.latitude, longitude: TEST_LOCATIONS.chengdu.longitude, zoom: 12 },
    { label: 'Xi An', latitude: TEST_LOCATIONS.xian.latitude, longitude: TEST_LOCATIONS.xian.longitude, zoom: 12 },
    { label: 'Wuhan', latitude: TEST_LOCATIONS.wuhan.latitude, longitude: TEST_LOCATIONS.wuhan.longitude, zoom: 12 },
    { label: 'Tokyo', latitude: TEST_LOCATIONS.tokyo.latitude, longitude: TEST_LOCATIONS.tokyo.longitude, zoom: 10 },
    { label: 'London', latitude: TEST_LOCATIONS.london.latitude, longitude: TEST_LOCATIONS.london.longitude, zoom: 10 },
    { label: 'NYC', latitude: TEST_LOCATIONS.nyc.latitude, longitude: TEST_LOCATIONS.nyc.longitude, zoom: 10 },
  ];

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    // Start with default location pushed onto the stack
    this.pushLocation('Start', DEFAULT_MAP_CONFIG.latitude, DEFAULT_MAP_CONFIG.longitude, DEFAULT_MAP_CONFIG.zoom);
    showToast('Map ready, stack depth: ' + this.stack.length);
  };

  private pushLocation(label: string, lat: number, lng: number, zoom: number): void {
    const entry: StackEntry = { label, latitude: lat, longitude: lng, zoom };
    this.stack.push(entry);
    this.currentIndex = this.stack.length - 1;
    this.currentLabel = entry.label;
    this.stackDepth = this.stack.length;

    // Navigate map to the location
    if (this.mapController) {
      this.mapController.jumpTo(0, lat, lng, 0, zoom);
    }
    showToast('Pushed: ' + label + ' (depth: ' + this.stack.length + ')');
  }

  private pushRandomLocation(): void {
    const idx = Math.floor(Math.random() * this.locations.length);
    const loc = this.locations[idx];
    this.pushLocation(loc.label, loc.latitude, loc.longitude, loc.zoom);
  }

  private popLocation(): void {
    if (this.stack.length <= 1) {
      showToast('Cannot pop - only the root entry remains');
      return;
    }
    this.stack.pop();
    this.currentIndex = this.stack.length - 1;
    this.stackDepth = this.stack.length;

    // Navigate back to the previous location
    const entry = this.stack[this.currentIndex];
    this.currentLabel = entry.label;
    if (this.mapController) {
      this.mapController.jumpTo(0, entry.latitude, entry.longitude, 0, entry.zoom);
    }
    showToast('Popped back to: ' + entry.label + ' (depth: ' + this.stack.length + ')');
  }

  private clearStack(): void {
    this.stack = [];
    this.currentIndex = -1;
    this.stackDepth = 0;
    this.currentLabel = 'Default';
    // Reset to default location
    if (this.mapController) {
      this.mapController.jumpTo(0, DEFAULT_MAP_CONFIG.latitude, DEFAULT_MAP_CONFIG.longitude, 0, DEFAULT_MAP_CONFIG.zoom);
    }
    // Push the reset entry
    this.pushLocation('Start', DEFAULT_MAP_CONFIG.latitude, DEFAULT_MAP_CONFIG.longitude, DEFAULT_MAP_CONFIG.zoom);
    showToast('Stack cleared and reset');
  }

  private navigateToIndex(index: number): void {
    if (index < 0 || index >= this.stack.length) return;
    this.currentIndex = index;
    const entry = this.stack[index];
    this.currentLabel = entry.label;
    this.stackDepth = this.stack.length;
    if (this.mapController) {
      this.mapController.jumpTo(0, entry.latitude, entry.longitude, 0, entry.zoom);
    }
    showToast('Navigated to: ' + entry.label);
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
      Text('Back Stack: ' + this.currentLabel)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 4 })

      Text('Stack Depth: ' + this.stackDepth)
        .fontSize(12)
        .fontColor('#666')
        .width('100%')
        .margin({ bottom: 12 })

      Row() {
        Button('Push Location')
          .width('48%')
          .onClick((): void => this.pushRandomLocation())
          .enabled(this.isMapReady)

        Button('Pop')
          .width('48%')
          .margin({ left: 8 })
          .onClick((): void => this.popLocation())
          .enabled(this.isMapReady && this.stack.length > 1)
      }
      .width('100%')
      .margin({ bottom: 8 })

      Button('Clear Stack')
        .width('100%')
        .onClick((): void => this.clearStack())
        .enabled(this.isMapReady)

      // Stack visualization
      Text('Stack Contents:')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 4 })

      ForEach(this.stack, (entry: StackEntry, index: number): void => {
        Row() {
          Text((index === this.currentIndex ? '> ' : '  ') + (index + 1) + '. ' + entry.label)
            .fontSize(12)
            .fontColor(index === this.currentIndex ? '#2196F3' : '#333')
            .layoutWeight(1)
          if (index !== this.currentIndex) {
            Button('Go')
              .fontSize(10)
              .height(24)
              .onClick((): void => this.navigateToIndex(index))
          }
        }
        .width('100%')
        .height(28)
        .padding({ left: 8, right: 4 })
      }, (item: StackEntry, index: number): string => item.label + index)
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'BackStack',
      subtitle: 'Simulate fragment back stack navigation',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
