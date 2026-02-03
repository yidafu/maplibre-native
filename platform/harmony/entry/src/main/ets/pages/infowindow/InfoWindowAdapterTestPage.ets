import { InfoWindowAdapter, LatLng, MapLibreMap, Marker, MarkerOptions, MapView } from 'maplibre_harmony';
/**
 * Info Window Adapter Activity
 * 自定义信息窗口适配器测试
 * 参考 Android: InfoWindowAdapterActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, TEST_LOCATIONS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct InfoWindowAdapterTestPage {
  private mapController: MapLibreMap | null = null;
  @State private useCustomAdapter: boolean = false;
  private readonly INFO_WINDOW_COLORS: string[] = ['#6200EE', '#03DAC5', '#BB86FC', '#018786'];
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Custom InfoWindow Adapter',
        description: '自定义信息窗口样式',
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
    ];
    
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
      page: InfoWindowAdapterTestPage;

      constructor(page: InfoWindowAdapterTestPage) {
        this.page = page;
      }

      getInfoWindow(marker: Marker): (() => void) | null {
        const colorIndex = marker.getTitle() ? marker.getTitle().length % this.page.INFO_WINDOW_COLORS.length : 0;
        const backgroundColor = this.page.INFO_WINDOW_COLORS[colorIndex];
        return () => {
          this.page.renderInfoWindow(marker, backgroundColor);
        };
      }
    }
    
    if (this.useCustomAdapter) {
      map.setInfoWindowAdapter(new CustomAdapter(this));
    }
  }

  @Builder
  private renderInfoWindow(marker: Marker, backgroundColor: string) {
    Column() {
      Row({ space: 8 }) {
        Text('🗺️')
          .fontSize(20)

        Column({ space: 4 }) {
          Text(`🏙️ ${marker.getTitle()}`)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(`📍 ${marker.getSnippet()}`)
            .fontSize(14)
            .fontColor('#E0E0E0')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(VerticalAlign.Center)
    }
    .padding(12)
    .backgroundColor(backgroundColor)
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: 'rgba(0, 0, 0, 0.25)',
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  buildActionButtons() {
    Button(this.useCustomAdapter ? '使用默认样式' : '使用自定义样式')
      .onClick(() => {
        if (this.mapController) {
          this.useCustomAdapter = !this.useCustomAdapter;
          if (this.useCustomAdapter) {
            this.setupCustomAdapter(this.mapController);
            showToast('已启用自定义 InfoWindow');
          } else {
            this.mapController.setInfoWindowAdapter(null);
            showToast('已恢复默认 InfoWindow');
          }
        }
      })
  }
}
