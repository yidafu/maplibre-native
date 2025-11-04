/**
 * Simple Map Test Page
 * 简单地图显示测试
 *
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/maplayout/SimpleMapActivity.kt
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, CameraPosition, LatLng } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct SimpleMapTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;

  aboutToAppear() {
    console.info('[SimpleMapTestPage] aboutToAppear');
  }

  aboutToDisappear() {
    console.info('[SimpleMapTestPage] aboutToDisappear');
    // 清理地图资源
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }

  /**
   * 地图就绪回调
   */
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[SimpleMapTestPage] onMapReady');
    this.mapController = map;
    this.isMapReady = true;

    // 设置默认样式
    // map.setStyleUrl(DEFAULT_STYLE_URLS.streets);

    // 设置初始相机位置（使用 jumpTo）
    map.jumpTo(0, 39.9042, 116.4074, 0, 5);

    showToast('地图加载成功');
  };

  /**
   * 地图内容构建器
   */
  @Builder
  mapContentBuilder() {
    MapView({
      onMapReady: this.onMapReady,
      styleUrl: DEFAULT_STYLE_URLS.streets,
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
        title: 'Simple Map',
        description: '简单地图显示',
        showActionBar: false,
        mapContent: (): void => this.mapContentBuilder()
      });
    }
    .width('100%')
    .height('100%');
  }
}
