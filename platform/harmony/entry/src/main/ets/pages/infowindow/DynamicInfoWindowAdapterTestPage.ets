import { InfoWindowAdapter, LatLng, MapLibreMap, MarkerOptions, MapView, OnInfoWindowClickListener, Marker } from 'maplibre_harmony';
/**
 * Dynamic Info Window Adapter Activity
 * 动态自定义信息窗口测试
 * 参考 Android: DynamicInfoWindowAdapterActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, TEST_LOCATIONS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct DynamicInfoWindowAdapterTestPage {
  private mapController: MapLibreMap | null = null;
  @State private updateCount: number = 0;
  
  build() {
    Column() {
    TestPageLayout({
      title: 'Dynamic InfoWindow',
      description: '动态更新信息窗口内容',
      showActionBar: true,
      mapContent: this.buildMapContent,
      actionButtons: this.buildActionButtons
    })
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  buildMapContent() {
    MapView({
      styleUrl: DEFAULT_STYLE_URLS.streets,
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 10,
      onMapReady: async (map: MapLibreMap) => {
        this.mapController = map;
        map.jumpTo(0, TEST_LOCATIONS.beijing.latitude, TEST_LOCATIONS.beijing.longitude, 0, 12);
        
        // 添加标记
        await map.addMarker(new MarkerOptions()
          .position(TEST_LOCATIONS.beijing)
          .title('动态窗口')
          .snippet('点击窗口更新内容')
        );
        
        this.setupAdapter(map);
        this.setupListeners(map);
      }
    })
  }

  private setupAdapter(map: MapLibreMap): void {
    class DynamicAdapter implements InfoWindowAdapter {
      page: DynamicInfoWindowAdapterTestPage;
      
      constructor(page: DynamicInfoWindowAdapterTestPage) {
        this.page = page;
      }
      
      getInfoWindow(marker: Marker): ESObject {
        const colors = ['#FF6200EE', '#FF03DAC5', '#FFBB86FC', '#FF018786']
        const randomColor = colors[this.page.updateCount % colors.length]
        
        const viewData: Record<string, Object> = {
          'title': `${marker.getTitle()} [${this.page.updateCount}]`,
          'snippet': `更新次数: ${this.page.updateCount}`,
          'backgroundColor': randomColor,
          'titleColor': '#FFFFFF',
          'snippetColor': '#E0E0E0'
        };
        return viewData as ESObject;
      }
    }
    
    map.setInfoWindowAdapter(new DynamicAdapter(this));
  }

  private setupListeners(map: MapLibreMap): void {
    class InfoWindowClickListener implements OnInfoWindowClickListener {
      page: DynamicInfoWindowAdapterTestPage;
      map: MapLibreMap;
      
      constructor(page: DynamicInfoWindowAdapterTestPage, map: MapLibreMap) {
        this.page = page;
        this.map = map;
      }
      
      onInfoWindowClick(marker: Marker): boolean {
        this.page.updateCount++;
        // 重新显示 InfoWindow 以刷新内容
        this.map.hideInfoWindow(marker);
        setTimeout(() => {
          this.map.showInfoWindow(marker);
        }, 100);
        showToast(`InfoWindow 已更新 ${this.page.updateCount} 次`);
        return true;
      }
    }
    
    map.setOnInfoWindowClickListener(new InfoWindowClickListener(this, map));
  }

  @Builder
  buildActionButtons() {
    Button('重置计数')
      .onClick(() => {
        this.updateCount = 0;
        showToast('计数已重置');
      })
  }
}
