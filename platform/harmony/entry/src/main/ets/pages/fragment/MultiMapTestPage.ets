/**
 * Multi Map
 * 多地图实例
 * 
 * 参考: platform/android/MapLibreAndroidTestApp
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { NativeMapView, MapLibreMap } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS } from '../common/TestUtils';

@Entry
@Component
struct MultiMapTestPage {
  private mapController: MapLibreMap | null = null;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[MultiMapTestPage] onMapReady');
    this.mapController = map;
    map.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    
    // 设置初始位置
    map.jumpTo(0, TEST_LOCATIONS.beijing.latitude, TEST_LOCATIONS.beijing.longitude, 0, 10);
    
    // TODO: 实现具体测试功能
    showToast('多地图实例 - 待实现');
  };
  
  @Builder
  actionButtonsBuilder() {
    Button('测试功能')
      .fontSize(14)
      .onClick(() => {
        showToast('TODO: 实现测试功能');
      });
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Multi Map',
        description: '多地图实例',
        showActionBar: true,
        actionButtons: this.actionButtonsBuilder,
        mapContent: () => {
          NativeMapView({
            onMapReady: this.onMapReady
          })
            .width('100%')
            .height('100%');
        }
      });
    }
    .width('100%')
    .height('100%');
  }
}
