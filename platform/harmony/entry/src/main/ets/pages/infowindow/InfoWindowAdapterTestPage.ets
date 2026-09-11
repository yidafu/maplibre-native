/**
 * InfoWindowAdapterTestPage - Test custom InfoWindow adapter.
 *
 * Demonstrates using setInfoWindowAdapter to provide custom InfoWindow
 * content via ComponentContent.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { MarkerOptions, LatLng, Marker, InfoWindowAdapter, createInfoWindowAdapter } from 'maplibre_harmony';
import { TEST_LOCATIONS, showToast } from '../common/TestUtils';
import { UIContext, ComponentContent } from '@kit.ArkUI';

// Data passed to the custom InfoWindow @Builder via ComponentContent.
interface InfoWindowData {
  title: string;
  snippet: string;
}

// Builder wrapper for custom InfoWindow content
@Builder
function customInfoWindowBuilder(data: InfoWindowData) {
  Column() {
    Row() {
      Column() {
        Circle()
          .width(40)
          .height(40)
          .fill('#2196F3')
          .strokeWidth(2)
          .stroke(Color.White)
      }
      .width(44)
      .height(44)
      .margin({ right: 8 })

      Column() {
        Text(data.title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1565C0')

        Text(data.snippet)
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 2 })
      }
      .layoutWeight(1)
    }
    .alignItems(VerticalAlign.Top)

    Row() {
      Button('Navigate')
        .fontSize(12)
        .height(28)
        .backgroundColor('#4CAF50')
        .onClick(() => {
          showToast('Navigate to: ' + data.title);
        })

      Button('Share')
        .fontSize(12)
        .height(28)
        .margin({ left: 8 })
        .backgroundColor('#FF9800')
        .onClick(() => {
          showToast('Share: ' + data.title);
        })
    }
    .width('100%')
    .margin({ top: 8 })
  }
  .width(220)
  .padding(12)
  .backgroundColor('#FFFFFF')
  .borderRadius(10)
  .shadow({
    radius: 8,
    color: 'rgba(0,0,0,0.2)',
    offsetX: 0,
    offsetY: 2
  })
}

@Entry
@Component
struct InfoWindowAdapterTestPage {
  private mapController: MapLibreMap | null = null;
  private markers: Marker[] = [];
  private customAdapter: InfoWindowAdapter | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private isAdapterSet: boolean = false;
  @State private markerCount: number = 0;

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

    const markerOptions: MarkerOptions[] = [
      new MarkerOptions()
        .position(TEST_LOCATIONS.beijing)
        .title('Beijing')
        .snippet('Capital, 21M people'),
      new MarkerOptions()
        .position(TEST_LOCATIONS.shanghai)
        .title('Shanghai')
        .snippet('Financial hub, 24M'),
      new MarkerOptions()
        .position(TEST_LOCATIONS.hangzhou)
        .title('Hangzhou')
        .snippet('West Lake, 10M'),
      new MarkerOptions()
        .position(TEST_LOCATIONS.shenzhen)
        .title('Shenzhen')
        .snippet('Tech hub, 12M'),
    ];

    try {
      const added = await this.mapController.addMarkersBatch(markerOptions);
      this.markers = this.markers.concat(added);
      this.markerCount = this.markers.length;
      this.statusMessage = added.length + ' markers added';
      showToast('Markers added');

      // Set adapter if not set
      if (!this.isAdapterSet) {
        this.setCustomAdapter();
      }

      // Fit view
      this.mapController.easeTo(32, 118, 0, 4.5, 1000);
    } catch (err) {
      this.statusMessage = 'Error: ' + err;
    }
  }

  private setCustomAdapter(): void {
    if (!this.mapController) {
      return;
    }

    const adapter = createInfoWindowAdapter(
      (marker: Marker, uiContext: UIContext): ComponentContent<Object> | null => {
        const data: InfoWindowData = {
          title: marker.getTitle() || 'Unknown',
          snippet: marker.getSnippet() || 'No description'
        };

        const componentContent = new ComponentContent(
          uiContext,
          wrapBuilder<[InfoWindowData]>(customInfoWindowBuilder),
          data
        );
        return componentContent;
      }
    );

    this.mapController.setInfoWindowAdapter(adapter);
    this.customAdapter = adapter;
    this.isAdapterSet = true;
    this.statusMessage = 'Custom InfoWindow adapter set';
    showToast('Custom adapter set');
  }

  private removeAdapter(): void {
    if (!this.mapController) {
      return;
    }
    this.mapController.setInfoWindowAdapter(null);
    this.isAdapterSet = false;
    this.statusMessage = 'InfoWindow adapter removed (uses default)';
    showToast('Adapter removed');
  }

  private toggleAdapter(): void {
    if (this.isAdapterSet) {
      this.removeAdapter();
    } else {
      this.setCustomAdapter();
    }
  }

  private showAllInfoWindows(): void {
    if (!this.mapController) {
      return;
    }
    for (const marker of this.markers) {
      this.mapController.showInfoWindow(marker);
    }
    this.statusMessage = 'Showing all InfoWindows';
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
        Button('Add Test Markers')
          .width('100%')
          .enabled(this.isMapReady)
          .onClick(() => this.addMarkers())
      } else {
        Button(this.isAdapterSet ? 'Adapter: ON (Custom)' : 'Adapter: OFF (Default)')
          .width('100%')
          .backgroundColor(this.isAdapterSet ? '#4CAF50' : '#9E9E9E')
          .onClick(() => this.toggleAdapter())

        Button('Show All InfoWindows')
          .width('100%')
          .margin({ top: 8 })
          .onClick(() => this.showAllInfoWindows())

        Button('Hide All InfoWindows')
          .width('100%')
          .margin({ top: 8 })
          .backgroundColor('#FF9800')
          .onClick(() => {
            if (this.mapController) {
              this.mapController.hideAllInfoWindows();
              this.statusMessage = 'All InfoWindows hidden';
            }
          })

        Divider().height(1).margin({ top: 12, bottom: 8 })

        Text('Markers:').fontSize(14).fontWeight(FontWeight.Bold).width('100%')

        ForEach(this.markers, (marker: Marker, index: number) => {
          Row() {
            Text(marker.getTitle() || 'Marker')
              .fontSize(13)
              .layoutWeight(1)

            Button('Show')
              .fontSize(11)
              .height(28)
              .onClick(() => {
                if (this.mapController) {
                  this.mapController.showInfoWindow(marker);
                  this.statusMessage = 'Showing InfoWindow for ' + marker.getTitle();
                }
              })
          }
          .width('100%')
          .padding(4)
        }, (marker: Marker) => String(marker.getId()))

        Text('Tap a marker on the map to see the custom InfoWindow')
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
      title: 'Info Window Adapter',
      subtitle: 'Custom info window via adapter',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
