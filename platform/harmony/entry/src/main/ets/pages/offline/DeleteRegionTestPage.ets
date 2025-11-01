/**
 * Delete Region
 * 删除区域
 * 
 * 参考: platform/android/MapLibreAndroidTestApp
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct DeleteRegionTestPage {
  private mapController: MapLibreMap | null = null;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[DeleteRegionTestPage] onMapReady');
    this.mapController = map;
    map.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    
    // 设置初始位置
    map.jumpTo(0, TEST_LOCATIONS.beijing.latitude, TEST_LOCATIONS.beijing.longitude, 0, 10);
    
    // TODO: 实现具体测试功能
    showToast('删除区域 - 待实现');
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
      onMapReady: this.onMapReady,
      styleUrl: DEFAULT_STYLE_URLS.bright,
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 10
    })
      .width('100%')
      .height('100%');
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Delete Region',
        description: '删除区域',
        showActionBar: true,
        actionButtons: this.actionButtonsBuilder,
        mapContent: (): void => this.mapContentBuilder()
      });
    }
    .width('100%')
    .height('100%');
  }
}
