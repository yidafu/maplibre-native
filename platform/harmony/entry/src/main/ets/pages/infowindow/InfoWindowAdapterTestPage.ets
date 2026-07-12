import { InfoWindowAdapter, LatLng, MapLibreMap, Marker, MarkerOptions, MapView } from 'maplibre_harmony';
import { ComponentContent, UIContext } from '@kit.ArkUI';
/**
 * Info Window Adapter Activity
 * Custom InfoWindow adapter test using ComponentContent
 * References: Android - InfoWindowAdapterActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, TEST_LOCATIONS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

/**
 * Data passed to the custom InfoWindow @Builder via ComponentContent.
 */
interface CustomInfoWindowData {
  title: string;
  snippet: string;
}

/**
 * @Builder for the custom InfoWindow UI.
 * Receives CustomInfoWindowData via ComponentContent's WrappedBuilder parameter.
 */
@Builder
function customInfoWindowBuilder(params: CustomInfoWindowData) {
  Column() {
    Row({ space: 8 }) {
      Text('🗺️')
        .fontSize(20)

      Column({ space: 2 }) {
        Text(`🏙️ ${params.title}`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`📍 ${params.snippet}`)
          .fontSize(12)
          .fontColor('#E0E0E0')
      }
      .alignItems(HorizontalAlign.Start)
    }
  }
  .padding(12)
  .backgroundColor('#6200EE')
  .borderRadius(8)
  .shadow({
    radius: 6,
    color: 'rgba(98, 0, 238, 0.3)',
    offsetX: 0,
    offsetY: 2
  })
}

@Entry
@Component
struct InfoWindowAdapterTestPage {
  private mapController: MapLibreMap | null = null;
  @State private useCustomAdapter: boolean = false;

  build() {
    Column() {
      TestPageLayout({
        title: 'Custom InfoWindow Adapter',
        description: '自定义信息窗口样式 (ComponentContent)',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        actionButtons: (): void => this.buildActionButtons()
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildMapContent() {
    MapView({
      styleUrl: DEFAULT_STYLE_URLS.streets,
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 5,
      onMapReady: async (map: MapLibreMap) => {
        this.mapController = map;
        map.jumpTo(0, 35, 105, 0, 4);

        await this.addMarkersWithInfoWindow(map);
        this.setupCustomAdapter(map);
      }
    })
  }

  private async addMarkersWithInfoWindow(map: MapLibreMap): Promise<void> {
    interface CityInfo {
      name: string;
      latLng: LatLng;
    }

    const cities: CityInfo[] = [
      { name: '北京', latLng: TEST_LOCATIONS.beijing },
      { name: '上海', latLng: TEST_LOCATIONS.shanghai },
      { name: '广州', latLng: TEST_LOCATIONS.guangzhou }
    ]

    const options: MarkerOptions[] = cities.map((city, index) =>
      new MarkerOptions()
        .position(city.latLng)
        .title(city.name)
        .snippet(`自定义样式 ${index + 1}`)
    );

    await map.addMarkersBatch(options);
  }

  private setupCustomAdapter(map: MapLibreMap): void {
    class CustomAdapter implements InfoWindowAdapter {
      getInfoWindow(marker: Marker, uiContext: UIContext): ComponentContent<Object> | null {
        const data: CustomInfoWindowData = {
          title: marker.getTitle() || '',
          snippet: marker.getSnippet() || '',
        };

        const content = new ComponentContent<CustomInfoWindowData>(
          uiContext,
          wrapBuilder<[CustomInfoWindowData]>(customInfoWindowBuilder),
          data
        );
        return content;
      }
    }

    if (this.useCustomAdapter) {
      map.setInfoWindowAdapter(new CustomAdapter());
      showToast('已启用自定义 InfoWindow (ComponentContent)');
    }
  }

  @Builder
  buildActionButtons() {
    Button(this.useCustomAdapter ? '使用默认样式' : '使用自定义样式')
      .onClick(() => {
        if (this.mapController) {
          this.useCustomAdapter = !this.useCustomAdapter;
          if (this.useCustomAdapter) {
            this.setupCustomAdapter(this.mapController);
          } else {
            this.mapController.setInfoWindowAdapter(null);
            showToast('已恢复默认 InfoWindow');
          }
        }
      })
  }
}
