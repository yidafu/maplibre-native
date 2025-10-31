import { InfoWindowAdapter, LatLng, MapLibreMap, Marker, MarkerOptions, NativeMapView } from 'maplibre_harmony';
/**
 * Info Window Adapter Activity
 * 自定义信息窗口适配器测试
 * 参考 Android: InfoWindowAdapterActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, TEST_LOCATIONS, showToast } from '../common/TestUtils';

@Entry
@Component
struct InfoWindowAdapterTestPage {
  private mapController: MapLibreMap | null = null;
  @State private useCustomAdapter: boolean = false;
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Custom InfoWindow Adapter',
        description: '自定义信息窗口样式',
        showActionBar: true,
        mapContent: this.buildMapContent,
        actionButtons: this.buildActionButtons
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildMapContent() {
    NativeMapView({
      styleUrl: DEFAULT_STYLE_URLS.streets,
      onMapReady: async (map: MapLibreMap) => {
        this.mapController = map;
        map.jumpTo(0, 35, 105, 0, 4);
        
        await this.addMarkersWithInfoWindow(map);
        this.setupCustomAdapter(map);
      }
    })
    .width('100%')
    .height('100%')
  }

  private async addMarkersWithInfoWindow(map: MapLibreMap): Promise<void> {
    const cities = [
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
    const customAdapter: InfoWindowAdapter = {
      getInfoWindowView: (marker: Marker): ESObject => {
        // 返回自定义视图数据
        return {
          title: `🏙️ ${marker.getTitle()}`,
          snippet: marker.getSnippet(),
          backgroundColor: '#FF6200EE',
          titleColor: '#FFFFFF',
          snippetColor: '#E0E0E0'
        };
      }
    };
    
    if (this.useCustomAdapter) {
      map.setInfoWindowAdapter(customAdapter);
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
            showToast('已启用自定义 InfoWindow');
          } else {
            this.mapController.setInfoWindowAdapter(null);
            showToast('已恢复默认 InfoWindow');
          }
        }
      })
  }
}
