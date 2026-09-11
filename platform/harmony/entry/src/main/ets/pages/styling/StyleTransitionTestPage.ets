/**
 * StyleTransitionTestPage - Test animated style transitions.
 *
 * Demonstrates style transitions using different easing curves
 * and durations. Tests smooth camera movements and layer animations.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, LatLng } from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, TEST_LOCATIONS, showToast, delay } from '../common/TestUtils';

interface CityInfo {
  lat: number;
  lng: number;
  zoom: number;
  name: string;
}

@Entry
@Component
struct StyleTransitionTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private currentTransition: string = 'None';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready - try style transitions';
    console.info('[StyleTransitionTestPage] Map ready');
  };

  private flyToCity(lat: number, lng: number, zoom: number, name: string, duration: number): void {
    if (!this.mapController) return;
    this.currentTransition = `Flying to ${name}`;
    this.statusMessage = `Animating to ${name} (${duration}ms)...`;
    this.mapController.flyTo({
      center: new LatLng(lat, lng),
      zoom: zoom,
      bearing: 0,
      pitch: 0
    }, duration);
    setTimeout(() => {
      this.statusMessage = `Arrived at ${name}`;
      this.currentTransition = 'Idle';
    }, duration + 200);
  }

  private easeToCity(lat: number, lng: number, zoom: number, name: string, duration: number): void {
    if (!this.mapController) return;
    this.currentTransition = `Easing to ${name}`;
    this.statusMessage = `Easing to ${name} (${duration}ms)...`;
    this.mapController.easeTo(lat, lng, 0, zoom, duration);
    setTimeout(() => {
      this.statusMessage = `Arrived at ${name}`;
      this.currentTransition = 'Idle';
    }, duration + 200);
  }

  private jumpToCity(lat: number, lng: number, zoom: number, name: string): void {
    if (!this.mapController) return;
    this.currentTransition = `Jumping to ${name}`;
    this.mapController.jumpTo(0, lat, lng, 0, zoom);
    this.statusMessage = `Jumped to ${name}`;
    setTimeout(() => {
      this.currentTransition = 'Idle';
    }, 500);
  }

  private cycleThroughCities(): void {
    if (!this.mapController) return;
    showToast('Starting city fly-through');
    const cities: CityInfo[] = [
      { lat: TEST_LOCATIONS.beijing.latitude, lng: TEST_LOCATIONS.beijing.longitude, zoom: 10, name: 'Beijing' },
      { lat: TEST_LOCATIONS.shanghai.latitude, lng: TEST_LOCATIONS.shanghai.longitude, zoom: 11, name: 'Shanghai' },
      { lat: TEST_LOCATIONS.tokyo.latitude, lng: TEST_LOCATIONS.tokyo.longitude, zoom: 10, name: 'Tokyo' },
      { lat: TEST_LOCATIONS.london.latitude, lng: TEST_LOCATIONS.london.longitude, zoom: 10, name: 'London' },
      { lat: TEST_LOCATIONS.sf.latitude, lng: TEST_LOCATIONS.sf.longitude, zoom: 10, name: 'San Francisco' },
    ];
    this.runCityCycle(cities, 0);
  }

  private async runCityCycle(cities: CityInfo[], index: number): Promise<void> {
    if (!this.mapController || index >= cities.length) {
      this.statusMessage = 'City cycle complete';
      showToast('Cycle complete');
      return;
    }
    const city = cities[index];
    this.flyToCity(city.lat, city.lng, city.zoom, city.name, 1500);
    await delay(2000);
    this.runCityCycle(cities, index + 1);
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
        .padding(8)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      Text('Style Transitions')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Row() {
        Button('Jump To')
          .width('48%')
          .fontSize(13)
          .onClick(() => this.jumpToCity(TEST_LOCATIONS.beijing.latitude, TEST_LOCATIONS.beijing.longitude, 12, 'Beijing'))
          .enabled(this.isMapReady)

        Button('Ease (500ms)')
          .width('48%')
          .margin({ left: 8 })
          .fontSize(13)
          .onClick(() => this.easeToCity(TEST_LOCATIONS.beijing.latitude, TEST_LOCATIONS.beijing.longitude, 12, 'Beijing', 500))
          .enabled(this.isMapReady)
      }
      .width('100%')
      .margin({ top: 6 })

      Row() {
        Button('Fly (1s)')
          .width('48%')
          .fontSize(13)
          .onClick(() => this.flyToCity(TEST_LOCATIONS.shanghai.latitude, TEST_LOCATIONS.shanghai.longitude, 13, 'Shanghai', 1000))
          .enabled(this.isMapReady)

        Button('Fly (3s)')
          .width('48%')
          .margin({ left: 8 })
          .fontSize(13)
          .onClick(() => this.flyToCity(TEST_LOCATIONS.london.latitude, TEST_LOCATIONS.london.longitude, 10, 'London', 3000))
          .enabled(this.isMapReady)
      }
      .width('100%')
      .margin({ top: 6 })

      Button('City Fly-Through Cycle')
        .width('100%')
        .margin({ top: 8 })
        .backgroundColor('#4CAF50')
        .onClick(() => this.cycleThroughCities())
        .enabled(this.isMapReady)

      Text('Current: ' + this.currentTransition)
        .fontSize(12)
        .fontColor('#666')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 8 })
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Style Transition',
      subtitle: 'Animated style transitions',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
