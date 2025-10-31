/**
 * Stretchable Image Test Page
 * 可拉伸图片测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { NativeMapView, MapLibreMap, MapLibreMapOptions } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS } from '../common/TestUtils';

@Entry
@Component
struct StretchableImageTestPage {
  private mapController: MapLibreMap | null = null;
  
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
      Text('可拉伸图片')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Text('说明: 9-patch类似的可拉伸图片功能')
        .fontSize(12)
        .fontColor('#666')
      
      Text('TODO: 实现可拉伸图片API')
        .fontSize(12)
        .fontColor('#FF9800')
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .padding(16)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Stretchable Image',
        description: '可拉伸图片',
        showActionBar: true,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%')
  }
}


