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
  private mapView: MapLibreMap | null = null;
  @State private markerCount: number = 0;
  private markers: Marker[] = [];;
  
  aboutToDisappear() {
    this.clearMarkersAll();
    if (this.mapView) {
      this.mapView.destroy();
      this.mapView = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[BulkMarkerTestPage] onMapReady');
    this.mapView = map;
    
    // 设置初始位置
    map.jumpTo(0, TEST_LOCATIONS.beijing.latitude, TEST_LOCATIONS.beijing.longitude, 0, 5);
  };
  
  /**
   * 添加批量标注
   */
  private addMarkers = async (count: number): Promise<void> => {
    if (!this.mapView) {
      showToast('地图未就绪');
      return;
    }
    
    // 清除现有标注
    this.clearMarkersAll();
    
    const startTime = Date.now();
    
    // 🚀 批量添加标注 - 使用 addMarkers API (性能优化)
    const markerOptionsList: MarkerOptions[] = [];
    for (let i = 0; i < count; i++) {
      const position = randomLatLng(20, 50, 100, 130); // 中国范围
      
      const markerOptions = new MarkerOptions()
        .position(position)
        .title(`Marker ${i + 1}`);
      
      markerOptionsList.push(markerOptions);
    }
    
    try {
      // 一次性批量添加,只更新一次GeoJSON (避免ANR)
      const addedMarkers = await this.mapView.addMarkersBatch(markerOptionsList);
      this.markers = addedMarkers;
      this.markerCount = this.markers.length;
      
      const endTime = Date.now();
      showToast(`添加 ${count} 个标注，耗时 ${endTime - startTime}ms`);
    } catch (error) {
      console.error(`Failed to add bulk markers: ${error}`);
      showToast(`添加标注失败: ${error}`);
    }
  };
  
  /**
   * 清除所有标注 (批量清除API)
   */
  private clearMarkersAll = (): void => {
    if (this.mapView) {
      const startTime = Date.now();
      
      // 使用批量清除API (性能优化, 只更新一次GeoJSON)
      this.mapView.clearMarkers();
      
      const endTime = Date.now();
      const count = this.markers.length;
      this.markers = [];
      this.markerCount = 0;
      
      showToast(`批量清除 ${count} 个标注，耗时 ${endTime - startTime}ms`);
    }
  };
  
  /**
   * 逐个清除标注 (测试单个删除性能 - 每次删除50个)
   */
  private clearMarkersOneByOne = (): void => {
    if (this.mapView && this.markers.length > 0) {
      const startTime = Date.now();
      
      // 每次删除最多50个 (测试防抖性能)
      const batchSize = Math.min(50, this.markers.length);
      const markersToRemove = this.markers.slice(0, batchSize);
      
      console.info(`[BulkMarkerTest] 逐个删除 ${batchSize} 个 markers (防抖测试)`);
      
      // 逐个删除 (每次触发updateSource, 会被防抖优化)
      for (const marker of markersToRemove) {
        this.mapView.removeMarker(marker);
      }
      
      // 更新剩余 markers
      this.markers = this.markers.slice(batchSize);
      this.markerCount = this.markers.length;
      
      const endTime = Date.now();
      showToast(`逐个删除 ${batchSize} 个标注，耗时 ${endTime - startTime}ms，剩余 ${this.markerCount} 个`);
    } else if (this.mapView) {
      showToast('没有标注可删除');
    }
  };
  
  @Builder
  actionButtonsBuilder() {
    // 使用 Flex 自动换行布局,支持多行显示
    Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap, alignItems: ItemAlign.Start }) {
      Button('10个')
        .fontSize(14)
        .margin(4)
        .onClick(() => this.addMarkers(10));
      
      Button('100个')
        .fontSize(14)
        .margin(4)
        .onClick(() => this.addMarkers(100));
      
      Button('500个')
        .fontSize(14)
        .margin(4)
        .onClick(() => this.addMarkers(500));
      
      Button('1000个')
        .fontSize(14)
        .margin(4)
        .onClick(() => this.addMarkers(1000));
      
      Button('批量清除')
        .fontSize(14)
        .margin(4)
        .backgroundColor('#F44336')
        .onClick(this.clearMarkersAll);
      
      Button('逐个清除')
        .fontSize(14)
        .margin(4)
        .backgroundColor('#FF5722')
        .onClick(this.clearMarkersOneByOne);
    }
    .width('100%')
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