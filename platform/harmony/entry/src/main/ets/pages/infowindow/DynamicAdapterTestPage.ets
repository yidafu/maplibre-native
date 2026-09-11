/**
 * DynamicAdapterTestPage - Test dynamic InfoWindow adapter.
 *
 * Demonstrates an InfoWindowAdapter that returns different custom
 * content based on marker properties (title, snippet, category).
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { MarkerOptions, LatLng, Marker, InfoWindowAdapter, createInfoWindowAdapter } from 'maplibre_harmony';
import { TEST_LOCATIONS, showToast } from '../common/TestUtils';
import { UIContext, ComponentContent } from '@kit.ArkUI';

// Red-themed builder for important cities
@Builder
function importantCityBuilder(context: Record<string, Object>) {
  Column() {
    Row() {
      Circle()
        .width(10)
        .height(10)
        .fill('#F44336')
      Blank()
      Text(context['markerType'] as string || '')
        .fontSize(10)
        .fontColor('#F44336')
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .margin({ bottom: 4 })

    Text(context['title'] as string || '')
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .fontColor('#D32F2F')

    Text(context['snippet'] as string || '')
      .fontSize(12)
      .fontColor('#666')
      .margin({ top: 4 })

    Row() {
      Text('Population: ')
        .fontSize(11)
        .fontColor('#999')
      Text(context['population'] as string || '')
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor('#F44336')
    }
    .width('100%')
    .margin({ top: 6 })
  }
  .width(200)
  .padding(14)
  .backgroundColor('#FFF5F5')
  .borderRadius(8)
  .border({ width: 1, color: '#FFCDD2' })
  .shadow({
    radius: 6,
    color: 'rgba(244, 67, 54, 0.2)',
    offsetX: 0,
    offsetY: 2
  })
}

// Green-themed builder for tech cities
@Builder
function techCityBuilder(context: Record<string, Object>) {
  Column() {
    Row() {
      Circle()
        .width(10)
        .height(10)
        .fill('#4CAF50')
      Blank()
      Text(context['markerType'] as string || '')
        .fontSize(10)
        .fontColor('#4CAF50')
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .margin({ bottom: 4 })

    Text(context['title'] as string || '')
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .fontColor('#2E7D32')

    Text(context['snippet'] as string || '')
      .fontSize(12)
      .fontColor('#666')
      .margin({ top: 4 })

    Row() {
      Text(context['extraInfo'] as string || '')
        .fontSize(11)
        .fontColor('#4CAF50')
    }
    .width('100%')
    .margin({ top: 6 })

    Button('Visit Website')
      .fontSize(12)
      .height(28)
      .width('100%')
      .margin({ top: 6 })
      .backgroundColor('#4CAF50')
      .onClick(() => {
        showToast('Opening ' + (context['title'] as string || '') + ' info');
      })
    .width('100%')
    .height('100%')
  }
  .width(200)
  .padding(14)
  .backgroundColor('#F1F8E9')
  .borderRadius(8)
  .border({ width: 1, color: '#C8E6C9' })
  .shadow({
    radius: 6,
    color: 'rgba(76, 175, 80, 0.2)',
    offsetX: 0,
    offsetY: 2
  })
}

// Blue-themed builder for scenic / cultural cities
@Builder
function scenicCityBuilder(context: Record<string, Object>) {
  Column() {
    Row() {
      Circle()
        .width(10)
        .height(10)
        .fill('#2196F3')
      Blank()
      Text(context['markerType'] as string || '')
        .fontSize(10)
        .fontColor('#2196F3')
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .margin({ bottom: 4 })

    Text(context['title'] as string || '')
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .fontColor('#1565C0')

    Text(context['extraInfo'] as string || '')
      .fontSize(12)
      .fontColor('#555')
      .margin({ top: 4 })

    Row() {
      Text('Rating: ')
        .fontSize(12)
        .fontColor('#999')
      Text(context['rating'] as string || '')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFB300')
    }
    .width('100%')
    .margin({ top: 6 })
  }
  .width(200)
  .padding(14)
  .backgroundColor('#E3F2FD')
  .borderRadius(8)
  .border({ width: 1, color: '#BBDEFB' })
  .shadow({
    radius: 6,
    color: 'rgba(33, 150, 243, 0.2)',
    offsetX: 0,
    offsetY: 2
  })
}


// Adapter that returns different builders based on marker data
function createDynamicAdapter(): InfoWindowAdapter {
  return createInfoWindowAdapter(
    (marker: Marker, uiContext: UIContext): ComponentContent<Object> | null => {
      const title = marker.getTitle() || '';
      const snippet = marker.getSnippet() || '';
      let markerType: string = 'general';
      let cleanSnippet: string = snippet;

      if (snippet.startsWith('CAPITAL:')) {
        markerType = 'capital';
        cleanSnippet = snippet.substring(8);
      } else if (snippet.startsWith('TECH:')) {
        markerType = 'tech';
        cleanSnippet = snippet.substring(5);
      } else if (snippet.startsWith('SCENIC:')) {
        markerType = 'scenic';
        cleanSnippet = snippet.substring(7);
      }

      if (markerType === 'capital') {
        const context: Record<string, Object> = {
          "title": title,
          "snippet": cleanSnippet,
          "markerType": markerType,
          "population": cleanSnippet.includes('21M') ? '21 Million' : '15M+'
        };
        return new ComponentContent(
          uiContext,
          wrapBuilder<[Record<string, Object>]>(importantCityBuilder),
          context
        );
      } else if (markerType === 'tech') {
        const context: Record<string, Object> = {
          "title": title,
          "snippet": cleanSnippet,
          "markerType": markerType,
          "extraInfo": 'Leading technology and innovation hub'
        };
        return new ComponentContent(
          uiContext,
          wrapBuilder<[Record<string, Object>]>(techCityBuilder),
          context
        );
      } else if (markerType === 'scenic') {
        const context: Record<string, Object> = {
          "title": title,
          "snippet": cleanSnippet,
          "markerType": markerType,
          "extraInfo": 'Famous tourist destination',
          "rating": '4.8 / 5.0'
        };
        return new ComponentContent(
          uiContext,
          wrapBuilder<[Record<string, Object>]>(scenicCityBuilder),
          context
        );
      }

      return null;
    }
  );
}

@Entry
@Component
struct DynamicAdapterTestPage {
  private mapController: MapLibreMap | null = null;
  private markers: Marker[] = [];
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private markerCount: number = 0;
  @State private adapterActive: boolean = false;

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready. Add markers to see dynamic InfoWindows.';
  };

  private async addMarkers(): Promise<void> {
    if (!this.mapController) {
      return;
    }

    this.statusMessage = 'Adding markers with category data...';

    // Each marker has its type encoded in the snippet prefix
    const markerOptions = [
      new MarkerOptions()
        .position(TEST_LOCATIONS.beijing)
        .title('Beijing')
        .snippet('CAPITAL:Capital of China, political & cultural center'),
      new MarkerOptions()
        .position(TEST_LOCATIONS.shanghai)
        .title('Shanghai')
        .snippet('TECH:Financial and tech powerhouse'),
      new MarkerOptions()
        .position(TEST_LOCATIONS.hangzhou)
        .title('Hangzhou')
        .snippet('SCENIC:West Lake, paradise on earth'),
      new MarkerOptions()
        .position(TEST_LOCATIONS.shenzhen)
        .title('Shenzhen')
        .snippet('TECH:Silicon Valley of hardware'),
      new MarkerOptions()
        .position(TEST_LOCATIONS.guangzhou)
        .title('Guangzhou')
        .snippet('CAPITAL:Southern gateway, 15M people'),
      new MarkerOptions()
        .position(TEST_LOCATIONS.chengdu)
        .title('Chengdu')
        .snippet('SCENIC:Giant panda base, Sichuan cuisine'),
    ];

    try {
      const added = await this.mapController.addMarkersBatch(markerOptions);
      this.markers = this.markers.concat(added);
      this.markerCount = this.markers.length;
      this.statusMessage = added.length + ' markers added with categories';
      showToast('Markers added: Capital / Tech / Scenic');

      // Set up dynamic adapter
      this.setDynamicAdapter();

      // Zoom to China view
      this.mapController.easeTo(32, 116, 0, 4.5, 1000);
    } catch (err) {
      this.statusMessage = 'Error: ' + err;
    }
  }

  private setDynamicAdapter(): void {
    if (!this.mapController) {
      return;
    }
    const adapter = createDynamicAdapter();
    this.mapController.setInfoWindowAdapter(adapter);
    this.adapterActive = true;
  }

  private toggleAdapter(): void {
    if (!this.mapController) {
      return;
    }
    if (this.adapterActive) {
      this.mapController.setInfoWindowAdapter(null);
      this.adapterActive = false;
      this.statusMessage = 'Dynamic adapter removed, using default';
      showToast('Using default InfoWindow');
    } else {
      this.setDynamicAdapter();
      this.statusMessage = 'Dynamic adapter restored';
      showToast('Dynamic adapter active');
    }
  }

  private showMarker(marker: Marker, title: string): void {
    if (!this.mapController) {
      return;
    }
    const pos = marker.getPosition();
    if (pos) {
      this.mapController.easeTo(pos.latitude, pos.longitude, 0, 11, 800);
    }
    this.mapController.showInfoWindow(marker);
    this.statusMessage = 'Showing: ' + title;
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

      if (this.markerCount === 0) {
        Button('Add Category Markers')
          .width('100%')
          .enabled(this.isMapReady)
          .onClick(() => this.addMarkers())
      } else {
        Row() {
          Text('Adapter: ')
            .fontSize(13)
          Text(this.adapterActive ? 'Dynamic (Custom)' : 'Default')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.adapterActive ? '#4CAF50' : '#9E9E9E')
        }
        .width('100%')
        .margin({ bottom: 8 })

        Button(this.adapterActive ? 'Switch to Default' : 'Switch to Dynamic')
          .width('100%')
          .backgroundColor(this.adapterActive ? '#FF9800' : '#2196F3')
          .onClick(() => this.toggleAdapter())

        Divider().height(1).margin({ top: 12, bottom: 8 })

        Text('Categories:').fontSize(15).fontWeight(FontWeight.Bold).width('100%')

        // Capital cities
        Text('Capital Cities (Red)').fontSize(13).fontColor('#F44336').fontWeight(FontWeight.Bold).margin({ top: 8 })
        Row() {
          Button('Beijing')
            .width('48%')
            .backgroundColor('#FFCDD2')
            .fontColor('#D32F2F')
            .onClick(() => this.showMarker(this.markers[0], 'Beijing'))
          Button('Guangzhou')
            .width('48%')
            .margin({ left: '4%' })
            .backgroundColor('#FFCDD2')
            .fontColor('#D32F2F')
            .onClick(() => this.showMarker(this.markers[4], 'Guangzhou'))
        }
        .width('100%')

        // Tech cities
        Text('Tech Cities (Green)').fontSize(13).fontColor('#4CAF50').fontWeight(FontWeight.Bold).margin({ top: 8 })
        Row() {
          Button('Shanghai')
            .width('48%')
            .backgroundColor('#C8E6C9')
            .fontColor('#2E7D32')
            .onClick(() => this.showMarker(this.markers[1], 'Shanghai'))
          Button('Shenzhen')
            .width('48%')
            .margin({ left: '4%' })
            .backgroundColor('#C8E6C9')
            .fontColor('#2E7D32')
            .onClick(() => this.showMarker(this.markers[3], 'Shenzhen'))
        }
        .width('100%')

        // Scenic cities
        Text('Scenic Cities (Blue)').fontSize(13).fontColor('#2196F3').fontWeight(FontWeight.Bold).margin({ top: 8 })
        Row() {
          Button('Hangzhou')
            .width('48%')
            .backgroundColor('#BBDEFB')
            .fontColor('#1565C0')
            .onClick(() => this.showMarker(this.markers[2], 'Hangzhou'))
          Button('Chengdu')
            .width('48%')
            .margin({ left: '4%' })
            .backgroundColor('#BBDEFB')
            .fontColor('#1565C0')
            .onClick(() => this.showMarker(this.markers[5], 'Chengdu'))
        }
        .width('100%')

        Text('Tap a marker on the map to see its dynamic InfoWindow')
          .fontSize(12)
          .fontColor('#999')
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 12 })
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Dynamic Adapter',
      subtitle: 'Adaptive info window per marker',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
