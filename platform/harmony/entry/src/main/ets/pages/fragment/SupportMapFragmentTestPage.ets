/**
 * Support Map Fragment Test Page
 * 支持地图Fragment测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { NativeMapView, MapLibreMap, MapLibreMapOptions } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS } from '../common/TestUtils';

@Entry
@Component
struct SupportMapFragmentTestPage {
  private mapController: MapLibreMap | null = null;
  @State private fragmentLoaded: boolean = false;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (mapView: NativeMapView): void => {
    const options = new MapLibreMapOptions();
    this.mapController = new MapLibreMap(mapView, options);
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 12);
    this.fragmentLoaded = true;
    showToast('地图Fragment已加载');
  };
  
  @Builder
  buildMapContent() {
    NativeMapView({
      onMapReady: this.onMapReady
    })
    .width('100%')
    .height('100%')
  }
  
  @Builder
  buildControlPanel() {
    Column({ space: 12 }) {
      Text('地图Fragment支持')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Text(`状态: ${this.fragmentLoaded ? '已加载' : '未加载'}`)
        .fontSize(14)
        .fontColor(this.fragmentLoaded ? '#4CAF50' : '#666')
      
      Text('说明: Harmony使用@Component实现')
        .fontSize(12)
        .fontColor('#666')
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Support Map Fragment',
        description: '支持地图Fragment',
        showActionBar: true,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%')
  }
}


