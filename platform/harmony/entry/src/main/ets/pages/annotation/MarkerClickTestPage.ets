import { LatLng, MapLibreMap, Marker, MarkerOptions, MapView, OnMarkerClickListener } from 'maplibre_harmony';
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, TEST_LOCATIONS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

/**
 * Marker Click Activity
 * 标记点击事件测试
 * 参考 Android OnMarkerClickListener
 */

class MarkerClickListener implements OnMarkerClickListener {
  private page: MarkerClickTestPage;
  
  constructor(page: MarkerClickTestPage) {
    this.page = page;
  }
  
  onMarkerClick(marker: Marker): boolean {
    this.page.clickCount++;
    this.page.lastClickedMarker = marker.getTitle() || `ID ${marker.getId()}`;
    showToast(`点击了: ${this.page.lastClickedMarker}`);
    return false; // false 表示继续显示 InfoWindow
  }
}

@Entry
@Component
struct MarkerClickTestPage {
  private mapController: MapLibreMap | null = null;
  @State clickCount: number = 0;
  @State lastClickedMarker: string = '';
  
  build() {
    Column() {
    TestPageLayout({
      title: 'Marker Click',
      description: '标记点击事件',
      showActionBar: true,
      mapContent: this.buildMapContent,
      controlPanel: this.buildControlPanel,
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
        map.jumpTo(0, 35, 105, 0, 4);
        
        // 添加多个标记
        await this.addMultipleMarkers(map);
        this.setupClickListener(map);
      }
    })
  }

  @Builder
  buildControlPanel() {
    Column({ space: 8 }) {
      Text(`点击次数: ${this.clickCount}`)
        .fontSize(14)
      
      Text(`上次点击: ${this.lastClickedMarker}`)
        .fontSize(12)
        .fontColor('#666666')
    }
    .width(220)
      .height('100%')
  }
  
  private async addMultipleMarkers(map: MapLibreMap): Promise<void> {
    const cities = [
      TEST_LOCATIONS.beijing,
      TEST_LOCATIONS.shanghai,
      TEST_LOCATIONS.guangzhou,
      TEST_LOCATIONS.shenzhen,
      TEST_LOCATIONS.hangzhou
    ]
    
    const options: MarkerOptions[] = cities.map((latLng, index) => 
      new MarkerOptions()
        .position(latLng)
        .title(`城市 ${index + 1}`)
    );
    
    await map.addMarkersBatch(options);
  }
  
  private setupClickListener(map: MapLibreMap): void {
    const clickListener = new MarkerClickListener(this);
    map.setOnMarkerClickListener(clickListener);
  }
  
  @Builder
  buildActionButtons() {
    Button('重置计数')
      .onClick(() => {
        this.clickCount = 0;
        this.lastClickedMarker = '';
        showToast('计数已重置');
      })
  }
}