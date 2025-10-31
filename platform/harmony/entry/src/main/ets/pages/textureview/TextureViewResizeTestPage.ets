/**
 * TextureView Resize Test Page
 * TextureView调整大小测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { NativeMapView, MapLibreMap, MapLibreMapOptions } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS } from '../common/TestUtils';

@Entry
@Component
struct TextureViewResizeTestPage {
  private mapController: MapLibreMap | null = null;
  @State private mapHeight: number = 400;
  
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
    Column() {
      NativeMapView({
        onMapReady: this.onMapReady
      })
      .width('100%')
      .height(this.mapHeight)
    }
    .width('100%')
    .height('100%')
  }
  
  @Builder
  buildControlPanel() {
    Column({ space: 12 }) {
      Text('地图高度调整')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Text(`当前高度: ${this.mapHeight}px`)
        .fontSize(14)
        .fontColor('#666')
      
      Row() {
        Text('高度:')
          .fontSize(14)
          .width(60)
        Slider({
          value: this.mapHeight,
          min: 200,
          max: 600,
          step: 50
        })
        .layoutWeight(1)
        .onChange((value: number) => {
          this.mapHeight = value;
          showToast(`高度: ${value}px`);
        })
      }
      .width('100%')
      
      Button('重置 (400px)')
        .width('100%')
        .onClick(() => {
          this.mapHeight = 400;
        })
    }
    .width('100%')
    .padding(16)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'TextureView Resize',
        description: 'XComponent调整大小',
        showActionBar: true,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%')
  }
}


