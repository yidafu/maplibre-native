/**
 * MarkerClickTestPage - Test marker click events and removal.
 *
 * Demonstrates handling marker click events, tracking click counts,
 * and dynamically adding/removing markers.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import {
  MapView, MapLibreMap, Marker, MarkerOptions, LatLng,
  OnMarkerClickListener
} from 'maplibre_harmony';
import { TEST_LOCATIONS, showToast } from '../common/TestUtils';

interface CityLocation {
  loc: LatLng;
  name: string;
}

class ClickCounterListener implements OnMarkerClickListener {
  private page: MarkerClickTestPage;

  constructor(page: MarkerClickTestPage) {
    this.page = page;
  }

  onMarkerClick(marker: Marker): boolean {
    const title = marker.getTitle() || `Marker #${marker.getId()}`;
    this.page.clickCount++;
    this.page.lastClickedTitle = title;
    showToast(`Clicked: ${title}`);
    return false;
  }
}

@Entry
@Component
struct MarkerClickTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State clickCount: number = 0;
  @State lastClickedTitle: string = '';
  @State private markerCount: number = 0;

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = async (map: MapLibreMap): Promise<void> => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Adding markers...';

    // Set up click listener
    map.setOnMarkerClickListener(new ClickCounterListener(this));

    // Add initial markers at city locations
    const cities: CityLocation[] = [
      { loc: TEST_LOCATIONS.beijing, name: 'Beijing' },
      { loc: TEST_LOCATIONS.shanghai, name: 'Shanghai' },
      { loc: TEST_LOCATIONS.guangzhou, name: 'Guangzhou' },
      { loc: TEST_LOCATIONS.shenzhen, name: 'Shenzhen' },
      { loc: TEST_LOCATIONS.hangzhou, name: 'Hangzhou' },
    ];

    const optionsList: MarkerOptions[] = cities.map((c): MarkerOptions =>
      new MarkerOptions()
        .position(c.loc)
        .title(c.name)
        .snippet('Click me!')
    );
    const markers: Marker[] = await map.addMarkersBatch(optionsList);
    this.markerCount = markers.length;
    this.statusMessage = `${this.markerCount} markers ready - click one`;
    console.info('[MarkerClickTestPage] Map ready');
  };

  private async addRandomMarker(): Promise<void> {
    if (!this.mapController) return;
    const lat = 20 + Math.random() * 30;
    const lng = 80 + Math.random() * 50;
    await this.mapController.addMarker(new MarkerOptions()
      .position(new LatLng(lat, lng))
      .title(`Random #${Date.now() % 10000}`)
    );
    this.markerCount++;
    this.statusMessage = `Added marker (total: ${this.markerCount})`;
    showToast('Random marker added');
  }

  private removeLastMarker(): void {
    if (!this.mapController) return;
    const markers = this.mapController.getMarkers();
    if (markers.length > 0) {
      const lastMarker = markers[markers.length - 1];
      this.mapController.removeMarker(lastMarker);
      this.markerCount = markers.length - 1;
      this.statusMessage = `Removed last marker (total: ${this.markerCount})`;
      showToast('Marker removed');
    } else {
      showToast('No markers to remove');
    }
  }

  private clearAll(): void {
    if (!this.mapController) return;
    this.mapController.clearMarkers();
    this.markerCount = 0;
    this.statusMessage = 'All markers cleared';
    showToast('Cleared all markers');
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

      Text('Click Statistics')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Text(`Markers: ${this.markerCount}`)
        .fontSize(14)
        .fontColor('#2196F3')
        .width('100%')

      Text(`Clicks: ${this.clickCount}`)
        .fontSize(14)
        .fontColor('#4CAF50')
        .width('100%')

      if (this.lastClickedTitle) {
        Text(`Last clicked: ${this.lastClickedTitle}`)
          .fontSize(12)
          .fontColor('#666')
          .width('100%')
      }

      Divider().margin({ top: 8, bottom: 8 })

      Row() {
        Button('Add Marker')
          .width('48%')
          .onClick((): void => { this.addRandomMarker(); })
          .enabled(this.isMapReady)

        Button('Remove Last')
          .width('48%')
          .margin({ left: 8 })
          .backgroundColor('#FF9800')
          .onClick((): void => this.removeLastMarker())
          .enabled(this.isMapReady && this.markerCount > 0)
      }
      .width('100%')

      Button('Clear All')
        .width('100%')
        .margin({ top: 6 })
        .backgroundColor('#F44336')
        .fontColor(Color.White)
        .onClick((): void => this.clearAll())
        .enabled(this.isMapReady && this.markerCount > 0)

      Button('Reset Counter')
        .width('100%')
        .margin({ top: 6 })
        .onClick((): void => {
          this.clickCount = 0;
          this.lastClickedTitle = '';
          this.statusMessage = 'Counter reset';
        })
        .enabled(this.isMapReady)
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Marker Click',
      subtitle: 'Click and remove markers',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
