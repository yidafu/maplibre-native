import { LatLng, Marker, MapLibreMap, MarkerOptions, NativeMapView, OnMarkerClickListener } from 'maplibre_harmony';
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, TEST_LOCATIONS, showToast } from '../common/TestUtils';

/**
 * Remove Marker Activity
 * 移除标记测试
 * 补充 Android 功能测试
 */

@Entry
@Component
struct RemoveMarkerTestPage {
  private mapController: MapLibreMap | null = null;
  @State private markerCount: number = 0;
  
  build() {
    Column() {
    TestPageLayout({
      title: 'Remove Markers',
      description: '点击标记移除',
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
    NativeMapView({
      styleUrl: DEFAULT_STYLE_URLS.streets,
      onMapReady: async (map: MapLibreMap) => {
        this.mapController = map;
        map.jumpTo(0, 35, 105, 0, 4);
        
        // 添加初始标记
        await this.addMultipleMarkers(map);
        this.setupClickListener(map);
      }
    })
    .width('100%')
    .height('100%')
  }

  @Builder
  buildControlPanel() {
    Column({ space: 8 }) {
      Text(`当前标记数: ${this.markerCount}`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
      
      Text('点击标记将其移除')
        .fontSize(12)
        .fontColor('#666666')
    }
    .width(200)
      .height('100%')
  }
  
  private async addMultipleMarkers(map: MapLibreMap): Promise<void> {
    const cities = [
      TEST_LOCATIONS.beijing,
      TEST_LOCATIONS.shanghai,
      TEST_LOCATIONS.guangzhou,
      TEST_LOCATIONS.shenzhen,
      TEST_LOCATIONS.hangzhou,
      TEST_LOCATIONS.chengdu,
      TEST_LOCATIONS.xian,
      TEST_LOCATIONS.wuhan
    ];
    
    const options: MarkerOptions[] = cities.map((latLng, index) => 
      new MarkerOptions()
        .position(latLng)
        .title(`城市 ${index + 1}`)
    );
    
    await map.addMarkersBatch(options);
    this.markerCount = cities.length;
      .width('100%')
      .height('100%')
  }

  private setupClickListener(map: MapLibreMap): void {
    const clickListener: OnMarkerClickListener = {
      onMarkerClick: (marker: Marker): boolean => {
        // 点击时移除标记
        map.removeMarker(marker);
        this.markerCount--;
        showToast(`已移除标记，剩余 ${this.markerCount} 个`);
        return true; // true 表示消费事件
      }
    };
    
    map.setOnMarkerClickListener(clickListener);
      .width('100%')
      .height('100%')
  }

  @Builder
  buildActionButtons() {
    Button('重新添加')
      .onClick(async () => {
        if (this.mapController) {
          this.mapController.clear();
          await this.addMultipleMarkers(this.mapController);
          showToast('已重新添加标记');
        }
      })
    .width('100%')
    .height('100%')
