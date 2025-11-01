import { LatLng, MapLibreMap, Marker, MarkerOptions, MapView, OnInfoWindowClickListener, OnMarkerClickListener } from 'maplibre_harmony';
/**
 * Info Window Activity
 * 标准信息窗口测试
 * 参考 Android: InfoWindowActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, TEST_LOCATIONS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct InfoWindowTestPage {
  private mapController: MapLibreMap | null = null;
  @State private infoWindowCount: number = 0;
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Standard InfoWindow',
        description: '标准信息窗口测试',
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
      initialZoom: 10,
      onMapReady: async (map: MapLibreMap) => {
        this.mapController = map;
        map.jumpTo(0, 35, 105, 0, 4);
        
        await this.addMarkersWithInfoWindow(map);
        this.setupListeners(map);
      }
    })
  }

  private async addMarkersWithInfoWindow(map: MapLibreMap): Promise<void> {
    interface CityInfo {
      name: string;
      latLng: LatLng;
      desc: string;
    }
    
    const cities: CityInfo[] = [
      { name: '北京', latLng: TEST_LOCATIONS.beijing, desc: '中国首都' },
      { name: '上海', latLng: TEST_LOCATIONS.shanghai, desc: '经济中心' },
      { name: '广州', latLng: TEST_LOCATIONS.guangzhou, desc: '南方门户' },
      { name: '深圳', latLng: TEST_LOCATIONS.shenzhen, desc: '科技之都' }
    ]
    
    const options: MarkerOptions[] = cities.map(city => 
      new MarkerOptions()
        .position(city.latLng)
        .title(city.name)
        .snippet(city.desc)
    );
    
    await map.addMarkersBatch(options);
  }

  private setupListeners(map: MapLibreMap): void {
    // 标记点击监听（显示 InfoWindow）
    class MarkerClickListenerImpl implements OnMarkerClickListener {
      mapController: MapLibreMap;
      
      constructor(mapController: MapLibreMap) {
        this.mapController = mapController;
      }
      
      onMarkerClick(marker: Marker): boolean {
        this.mapController.selectMarker(marker, true);
        showToast(`显示 InfoWindow: ${marker.getTitle()}`);
        return false; // false 会自动显示 InfoWindow
      }
    }
    
    // InfoWindow 点击监听
    class InfoWindowClickListenerImpl implements OnInfoWindowClickListener {
      component: InfoWindowTestPage;
      
      constructor(component: InfoWindowTestPage) {
        this.component = component;
      }
      
      onInfoWindowClick(marker: Marker): boolean {
        this.component.infoWindowCount++;
        showToast(`InfoWindow 被点击 ${this.component.infoWindowCount} 次`);
        return true;
      }
    }
    
    const markerClickListener = new MarkerClickListenerImpl(map);
    const infoWindowClickListener = new InfoWindowClickListenerImpl(this);
    
    map.setOnMarkerClickListener(markerClickListener);
    map.setOnInfoWindowClickListener(infoWindowClickListener);
  }

  @Builder
  buildActionButtons() {
    Button('关闭所有窗口')
      .onClick(() => {
        if (this.mapController) {
          this.mapController.deselectMarkers();
          showToast('已关闭所有 InfoWindow');
        }
      })
    
    Button('重置计数')
      .onClick(() => {
        this.infoWindowCount = 0;
        showToast('计数已重置');
      })
  }
}
