/**
 * Simple Map Test Page
 * 简单地图显示测试
 *
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/maplayout/SimpleMapActivity.kt
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, LatLng } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct SimpleMapTestPage {
  private mapController: MapLibreMap | null = null;
  private mapViewRef: ESObject = null; // Reference to MapView component
  @State private isMapReady: boolean = false;

  aboutToAppear() {
    console.info('[SimpleMapTestPage] aboutToAppear');
  }

  onPageShow(): void {
    console.info('[SimpleMapTestPage] onPageShow');
  }

  onPageHide(): void {
    console.info('[SimpleMapTestPage] onPageHide');
    // When page hides, cancel pending network requests to prevent crashes
    // This is critical for preventing SIGSEGV when navigating away
    if (this.mapController) {
      try {
        const nativeMapView = this.mapController.getNativeMapView();
        if (nativeMapView) {
          nativeMapView.cancelAllRequests();
          console.info('[SimpleMapTestPage] onPageHide: Cancelled all pending requests');
        }
      } catch (error) {
        console.warn('[SimpleMapTestPage] onPageHide: Failed to cancel requests', error);
      }
    }
  }

  aboutToDisappear(): void {
    console.info('[SimpleMapTestPage] aboutToDisappear');

    // CRITICAL: Cancel pending requests BEFORE destroying the map
    // This prevents HTTPFileSource callbacks from accessing destroyed objects
    if (this.mapController) {
      try {
        const nativeMapView = this.mapController.getNativeMapView();
        if (nativeMapView) {
          nativeMapView.cancelAllRequests();
          console.info('[SimpleMapTestPage] aboutToDisappear: Cancelled all pending requests');
        }
      } catch (error) {
        console.warn('[SimpleMapTestPage] aboutToDisappear: Failed to cancel requests', error);
      }
    }

    // Then destroy the map controller
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }

    console.info('[SimpleMapTestPage] aboutToDisappear: Cleanup complete');
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
    // map.jumpTo(0, 39.9042, 116.4074, 0, 5);

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
