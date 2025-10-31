import { LatLng, Marker, MapLibreMap, MarkerOptions, NativeMapView, OnMarkerDragListener } from 'maplibre_harmony';
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, TEST_LOCATIONS, showToast, formatLatLng } from '../common/TestUtils';

/**
 * Draggable Marker Activity
 * 可拖拽标记测试
 * 参考 Android: DraggableMarkerActivity
 */

@Entry
@Component
struct DraggableMarkerTestPage {
  private mapController: MapLibreMap | null = null;
  @State private dragStatus: string = '长按标记开始拖拽';
  
  build() {
    Column() {
    TestPageLayout({
      title: 'Draggable Marker',
      description: '可拖拽标记',
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
    .width('100%')
    .height('100%')
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
    const dragListener: OnMarkerDragListener = {
      onMarkerDragStart: (marker: Marker) => {
        this.dragStatus = '开始拖拽...';
      },
      onMarkerDrag: (marker: Marker) => {
        const pos = marker.getPosition();
        this.dragStatus = `拖拽中: ${formatLatLng(pos.latitude, pos.longitude, 4)}`;
      },
      onMarkerDragEnd: (marker: Marker) => {
        const pos = marker.getPosition();
        this.dragStatus = `拖拽结束: ${formatLatLng(pos.latitude, pos.longitude, 4)}`;
        showToast('标记已移动');
      }
    };
    
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
    .width('100%')
    .height('100%')
}
