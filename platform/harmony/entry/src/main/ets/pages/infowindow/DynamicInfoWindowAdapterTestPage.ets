import { InfoWindowAdapter, LatLng, MapLibreMap, MarkerOptions, NativeMapView, OnInfoWindowClickListener } from 'maplibre_harmony';
/**
 * Dynamic Info Window Adapter Activity
 * 动态自定义信息窗口测试
 * 参考 Android: DynamicInfoWindowAdapterActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, TEST_LOCATIONS, showToast } from '../common/TestUtils';

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
    NativeMapView({
      styleUrl: DEFAULT_STYLE_URLS.streets,
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
    .width('100%')
    .height('100%')
  }

  private setupAdapter(map: MapLibreMap): void {
    const dynamicAdapter: InfoWindowAdapter = {
      getInfoWindowView: (marker: Marker): ESObject => {
        const colors = ['#FF6200EE', '#FF03DAC5', '#FFBB86FC', '#FF018786'];
        const randomColor = colors[this.updateCount % colors.length];
        
        return {
          title: `${marker.getTitle()} [${this.updateCount}]`,
          snippet: `更新次数: ${this.updateCount}`,
          backgroundColor: randomColor,
          titleColor: '#FFFFFF',
          snippetColor: '#E0E0E0'
        };
      }
    };
    
    map.setInfoWindowAdapter(dynamicAdapter);
      .width('100%')

      .height('100%')
  }

  private setupListeners(map: MapLibreMap): void {
    const infoWindowClickListener: OnInfoWindowClickListener = {
      onInfoWindowClick: (marker: Marker): boolean => {
        this.updateCount++;
        // 重新显示 InfoWindow 以刷新内容
        map.hideInfoWindow(marker);
        setTimeout(() => {
          map.showInfoWindow(marker);
        }, 100);
        showToast(`InfoWindow 已更新 ${this.updateCount} 次`);
        return true;
      }
    };
    
    map.setOnInfoWindowClickListener(infoWindowClickListener);
      .width('100%')

      .height('100%')
  }

  @Builder
  buildActionButtons() {
    Button('重置计数')
      .onClick(() => {
        this.updateCount = 0;
        showToast('计数已重置');
      })
    .width('100%')
    .height('100%')
}
