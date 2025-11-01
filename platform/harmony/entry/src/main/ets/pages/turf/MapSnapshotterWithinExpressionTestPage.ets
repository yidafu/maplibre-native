/**
 * Map Snapshotter Within Expression Test Page
 * 快照+Within表达式测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MapLibreMapOptions } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import { componentSnapshot } from '@kit.ArkUI';

@Entry
@Component
struct MapSnapshotterWithinExpressionTestPage {
  private mapController: MapLibreMap | null = null;
  @State private snapshotImage: PixelMap | null = null;
  private mapViewId: string = 'mapview_within';
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 11);
  };
  
  private captureSnapshot = async (): Promise<void> => {
    try {
      const pixelMap = await componentSnapshot.get(this.mapViewId);
      this.snapshotImage = pixelMap;
      showToast('快照已生成');
    } catch (error) {
      showToast(`快照失败: ${error}`);
    }
  };
  
  @Builder
  buildMapContent() {
    MapView({
      onMapReady: this.onMapReady,
            styleUrl: DEFAULT_STYLE_URLS.bright,
            initialLatitude: 39.9,
            initialLongitude: 116.4,
            initialZoom: 10
    })
    .id(this.mapViewId)
    .width('100%')
    .height('100%')
  }
  
  @Builder
  buildControlPanel() {
    Column({ space: 12 }) {
      Button('生成快照')
        .width('100%')
        .onClick(() => this.captureSnapshot())
      
      if (this.snapshotImage) {
        Image(this.snapshotImage)
          .width('100%')
          .height(200)
          .objectFit(ImageFit.Contain)
      }
      
      Text('TODO: 结合Within表达式功能')
        .fontSize(12)
        .fontColor('#FF9800')
    }
    .width('100%')
    .padding(16)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Snapshotter + Within',
        description: '快照+Within表达式',
        showActionBar: true,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%')
  }
}


