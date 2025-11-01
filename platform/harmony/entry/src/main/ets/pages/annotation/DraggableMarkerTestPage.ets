import { LatLng, Marker, MapLibreMap, MarkerOptions, MapView, OnMarkerDragListener } from 'maplibre_harmony';
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, TEST_LOCATIONS, showToast, formatLatLng , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

/**
 * Draggable Marker Activity
 * 可拖拽标记测试
 * 参考 Android: DraggableMarkerActivity
 */

class DraggableMarkerDragListener implements OnMarkerDragListener {
  private page: DraggableMarkerTestPage;
  
  constructor(page: DraggableMarkerTestPage) {
    this.page = page;
  }
  
  onMarkerDragStart(marker: Marker): void {
    this.page.dragStatus = '开始拖拽...';
  }
  
  onMarkerDrag(marker: Marker): void {
    const pos = marker.getPosition();
    this.page.dragStatus = `拖拽中: ${formatLatLng(pos.latitude, pos.longitude, 4)}`;
  }
  
  onMarkerDragEnd(marker: Marker): void {
    const pos = marker.getPosition();
    this.page.dragStatus = `拖拽结束: ${formatLatLng(pos.latitude, pos.longitude, 4)}`;
    showToast('标记已移动');
  }
}

@Entry
@Component
struct DraggableMarkerTestPage {
  private mapController: MapLibreMap | null = null;
  @State dragStatus: string = '长按标记开始拖拽';
  
  build() {
    Column() {
    TestPageLayout({
      title: 'Draggable Marker',
      description: '可拖拽标记',
      showActionBar: true,
      mapContent: (): void => this.buildMapContent(),
      controlPanel: (): void => this.buildControlPanel(),
      actionButtons: (): void => this.buildActionButtons()
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
        
        // 添加可拖拽标记
        await map.addMarker(new MarkerOptions()
          .position(TEST_LOCATIONS.beijing)
          .title('拖动我')
          .draggable(true)
        );
        
        this.setupDragListener(map);
      }
    })
  }

  @Builder
  buildControlPanel() {
    Column({ space: 8 }) {
      Text('拖拽状态')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
      
      Text(this.dragStatus)
        .fontSize(12)
        .fontColor('#666666')
    }
    .width(250)
    .height('100%')
  }
  
  private setupDragListener(map: MapLibreMap): void {
    const dragListener = new DraggableMarkerDragListener(this);
    map.setOnMarkerDragListener(dragListener);
  }
  
  @Builder
  buildActionButtons() {
    Button('添加可拖拽标记')
      .onClick(async () => {
        if (this.mapController) {
          const center = this.mapController.getLatLng();
          await this.mapController.addMarker(new MarkerOptions()
            .position(center)
            .title(`标记 ${Date.now()}`)
            .draggable(true)
          );
          showToast('已添加可拖拽标记');
        }
      })
    
    Button('清除全部')
      .onClick(() => {
        if (this.mapController) {
          this.mapController.clear();
          this.dragStatus = '已清除';
          showToast('已清除所有标记');
        }
      })
  }
}
