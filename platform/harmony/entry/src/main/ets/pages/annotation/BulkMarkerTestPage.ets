/**
 * Bulk Marker Test Page
 * 批量标注测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/annotation/BulkMarkerActivity.kt
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, CameraPosition, LatLng, Marker, MarkerOptions } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS, randomLatLng , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct BulkMarkerTestPage {
  private mapController: MapLibreMap | null = null;
  @State private markerCount: number = 0;
  private markers: Marker[] = [];;
  
  aboutToDisappear() {
    this.clearMarkers();
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[BulkMarkerTestPage] onMapReady');
    this.mapController = map;
    map.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    
    // 设置初始位置
    map.jumpTo(0, TEST_LOCATIONS.beijing.latitude, TEST_LOCATIONS.beijing.longitude, 0, 5);
  };
  
  /**
   * 添加批量标注
   */
  private addMarkers = (count: number): void => {
    if (!this.mapController) {
      showToast('地图未就绪');
      return;
    }
    
    // 清除现有标注
    this.clearMarkers();
    
    const startTime = Date.now();
    
    // 批量添加标注
    for (let i = 0; i < count; i++) {
      const position = randomLatLng(20, 50, 100, 130); // 中国范围
      
      const markerOptions = new MarkerOptions()
        .position(position)
        .title(`Marker ${i + 1}`);
      
      // addMarker 返回 Promise<Marker>
      this.mapController.addMarker(markerOptions).then((marker: Marker) => {
        this.markers.push(marker);
      });
    }
    
    const endTime = Date.now();
    this.markerCount = this.markers.length;
    
    showToast(`添加 ${count} 个标注，耗时 ${endTime - startTime}ms`);
  };
  
  /**
   * 清除所有标注
   */
  private clearMarkers = (): void => {
    if (this.mapController) {
      // TODO: 实现 removeMarkers 批量删除
      for (const marker of this.markers) {
        this.mapController.removeMarker(marker);
      }
      this.markers = [];
      this.markerCount = 0;
      showToast('已清除所有标注');
    }
  };
  
  @Builder
  actionButtonsBuilder() {
    Button('10个')
      .fontSize(14)
      .onClick(() => this.addMarkers(10));
    
    Button('100个')
      .fontSize(14)
      .onClick(() => this.addMarkers(100));
    
    Button('500个')
      .fontSize(14)
      .onClick(() => this.addMarkers(500));
    
    Button('1000个')
      .fontSize(14)
      .onClick(() => this.addMarkers(1000));
    
    Button('清除')
      .fontSize(14)
      .backgroundColor('#F44336')
      .onClick(this.clearMarkers);
  }
  
  @Builder
  controlPanelBuilder() {
    Column() {
      Text('批量标注性能测试')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 });
      
      Text(`当前标注数: ${this.markerCount}`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2196F3');
    }
    .alignItems(HorizontalAlign.Start);
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
        title: 'Bulk Marker',
        description: '批量标注 (1000+)',
        showActionBar: true,
        actionButtons: (): void => this.actionButtonsBuilder(),
        controlPanel: (): void => this.controlPanelBuilder(),
        mapContent: (): void => this.mapContentBuilder()
      });
    }
    .width('100%')
    .height('100%');
  }
}