/**
 * Rotate By
 * 旋转控制
 * 
 * 参考: platform/android/MapLibreAndroidTestApp
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct RotateByTestPage {
  private mapController: MapLibreMap | null = null;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[RotateByTestPage] onMapReady');
    this.mapController = map;
    map.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    
    // 设置初始位置
    map.jumpTo(0, TEST_LOCATIONS.beijing.latitude, TEST_LOCATIONS.beijing.longitude, 0, 10);
    
    // TODO: 实现具体测试功能
    showToast('旋转控制 - 待实现');
  };
  
  @Builder
  actionButtonsBuilder() {
    Button('测试功能')
      .fontSize(14)
      .onClick(() => {
        showToast('TODO: 实现测试功能');
      });
  }
  
  @Builder
  mapContentBuilder() {
    MapView({
      onMapReady: this.onMapReady
    })
      .width('100%')
      .height('100%');
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Rotate By',
        description: '旋转控制',
        showActionBar: true,
        actionButtons: this.actionButtonsBuilder,
        mapContent: (): void => this.mapContentBuilder()
      });
    }
    .width('100%')
    .height('100%');
  }
}
