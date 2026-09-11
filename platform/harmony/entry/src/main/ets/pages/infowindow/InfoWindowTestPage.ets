/**
 * InfoWindowTestPage - Test default InfoWindow display.
 *
 * Demonstrates adding markers with titles/snippets, showing InfoWindows
 * on tap and programmatically, and customizing InfoWindow style.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { MarkerOptions, LatLng, Marker } from 'maplibre_harmony';
import { TEST_LOCATIONS, showToast, DEFAULT_MAP_CONFIG, formatLatLng } from '../common/TestUtils';

@Entry
@Component
struct InfoWindowTestPage {
  private mapController: MapLibreMap | null = null;
  private markers: Marker[] = [];
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private markerCount: number = 0;
  @State private selectedMarkerInfo: string = '--';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready';
  };

  private async addMarkers(): Promise<void> {
    if (!this.mapController) {
      return;
    }

    this.statusMessage = 'Adding markers...';

    const markerOptions = [
      new MarkerOptions()
        .position(TEST_LOCATIONS.beijing)
        .title('Beijing')
        .snippet('Capital of China, Population: 21M'),
      new MarkerOptions()
        .position(TEST_LOCATIONS.shanghai)
        .title('Shanghai')
        .snippet('Largest city, Population: 24M'),
      new MarkerOptions()
        .position(TEST_LOCATIONS.guangzhou)
        .title('Guangzhou')
        .snippet('Southern hub, Population: 15M'),
      new MarkerOptions()
        .position(TEST_LOCATIONS.hangzhou)
        .title('Hangzhou')
        .snippet('West Lake, Population: 10M'),
      new MarkerOptions()
        .position(TEST_LOCATIONS.chengdu)
        .title('Chengdu')
        .snippet('Panda base, Population: 16M'),
    ];

    try {
      const addedMarkers = await this.mapController.addMarkersBatch(markerOptions);
      this.markers = this.markers.concat(addedMarkers);
      this.markerCount = this.markers.length;
      this.statusMessage = 'Added ' + addedMarkers.length + ' markers';
      showToast(addedMarkers.length + ' markers added');

      // Fit the camera to show all markers
      const lats = markerOptions.map(m => m.getPosition()!.latitude);
      const lngs = markerOptions.map(m => m.getPosition()!.longitude);
      const minLat = Math.min(...lats);
      const maxLat = Math.max(...lats);
      const minLng = Math.min(...lngs);
      const maxLng = Math.max(...lngs);
      const centerLat = (minLat + maxLat) / 2;
      const centerLng = (minLng + maxLng) / 2;
      this.mapController.easeTo(centerLat, centerLng, 0, 5, 1000);
    } catch (err) {
      this.statusMessage = 'Add markers failed: ' + err;
      showToast('Error: ' + err);
    }
  }

  private showInfoWindow(index: number): void {
    if (!this.mapController || index >= this.markers.length) {
      showToast('Invalid marker index');
      return;
    }
    this.mapController.showInfoWindow(this.markers[index]);
    this.selectedMarkerInfo = this.markers[index].getTitle() || 'Marker ' + index;
    this.statusMessage = 'Showing InfoWindow for: ' + this.selectedMarkerInfo;
  }

  private hideInfoWindow(index: number): void {
    if (!this.mapController || index >= this.markers.length) {
      return;
    }
    this.mapController.hideInfoWindow(this.markers[index]);
    this.statusMessage = 'Hidden InfoWindow for marker ' + index;
  }

  private hideAllInfoWindows(): void {
    if (!this.mapController) {
      return;
    }
    this.mapController.hideAllInfoWindows();
    this.statusMessage = 'All InfoWindows hidden';
  }

  private applyCustomStyle(): void {
    if (!this.mapController) {
      return;
    }
    this.statusMessage = 'Markers already have default style. Tap a marker to see InfoWindow.';
    showToast('Tap any marker to see InfoWindow');
  }

  private selectMarker(index: number): void {
    if (!this.mapController || index >= this.markers.length) {
      return;
    }
    this.mapController.selectMarker(this.markers[index], true);
    this.selectedMarkerInfo = this.markers[index].getTitle() || 'Marker ' + index;
    this.statusMessage = 'Selected marker: ' + this.selectedMarkerInfo;

    // Move camera to the marker
    const pos = this.markers[index].getPosition();
    if (pos) {
      this.mapController.easeTo(pos.latitude, pos.longitude, 0, 10, 500);
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
        .fontSize(14)
        .fontColor(this.isMapReady ? '#4CAF50' : '#FF9800')
        .width('100%')
        .padding(12)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)
        .margin({ bottom: 8 })

      Row() {
        Text('Markers: ')
          .fontSize(13)
        Text(String(this.markerCount))
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2196F3')
      }
      .width('100%')
      .margin({ bottom: 8 })

      if (this.markerCount === 0) {
        Button('Add Test Markers')
          .width('100%')
          .enabled(this.isMapReady)
          .onClick(() => this.addMarkers())
      } else {
        // Show InfoWindow for each marker
        Text('Show InfoWindow:').fontSize(14).fontWeight(FontWeight.Bold).width('100%')

        ForEach(this.markers, (marker: Marker, index: number) => {
          Row() {
            Text(marker.getTitle() || 'Marker ' + index)
              .fontSize(13)
              .layoutWeight(1)

            Button('Show')
              .fontSize(11)
              .height(28)
              .margin({ left: 4 })
              .onClick(() => this.showInfoWindow(index))

            Button('Hide')
              .fontSize(11)
              .height(28)
              .margin({ left: 4 })
              .backgroundColor('#FF9800')
              .onClick(() => this.hideInfoWindow(index))
          }
          .width('100%')
          .padding(4)
        }, (marker: Marker) => String(marker.getId()))

        Divider().height(1).margin({ top: 8, bottom: 8 })

        Row() {
          Button('Hide All InfoWindows')
            .width('48%')
            .backgroundColor('#FF9800')
            .onClick(() => this.hideAllInfoWindows())

          Button('Deselect All')
            .width('48%')
            .margin({ left: '4%' })
            .onClick(() => {
              if (this.mapController) {
                this.mapController.deselectMarkers();
                this.statusMessage = 'All markers deselected';
              }
            })
        }
        .width('100%')

        Text('Quick Select:').fontSize(14).fontWeight(FontWeight.Bold).width('100%').margin({ top: 8 })

        Row() {
          Button('Beijing')
            .width('30%')
            .fontSize(12)
            .onClick(() => this.selectMarker(0))
          Button('Shanghai')
            .width('30%')
            .fontSize(12)
            .margin({ left: '5%' })
            .onClick(() => this.selectMarker(1))
          Button('Guangzhou')
            .width('30%')
            .fontSize(12)
            .margin({ left: '5%' })
            .onClick(() => this.selectMarker(2))
        }
        .width('100%')
        .margin({ top: 4 })

        Text('Selected: ' + this.selectedMarkerInfo)
          .fontSize(12)
          .fontColor('#666')
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 8 })
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Info Window',
      subtitle: 'Default info window',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
