/**
 * Map Options Xml Test Page
 * 声明式地图选项测试页面
 * 
 * 注意: Harmony使用@Builder声明式配置
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { NativeMapView, MapLibreMap, MapLibreMapOptions } from 'maplibre_harmony';
import { showToast } from '../common/TestUtils';

@Entry
@Component
struct MapOptionsXmlTestPage {
  private mapController: MapLibreMap | null = null;
  @State private currentConfig: string = '默认配置';
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (mapView: NativeMapView): void => {
    const options = new MapLibreMapOptions();
    this.mapController = new MapLibreMap(mapView, options);
    this.mapController.setStyleUrl('https://demotiles.maplibre.org/style.json');
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 12);
  };
  
  @Builder
  buildMapWithConfig1() {
    // 配置1: 高缩放级别
    NativeMapView({
      styleUrl: 'https://demotiles.maplibre.org/style.json',
      initialLatitude: 39.9042,
      initialLongitude: 116.4074,
      initialZoom: 15,
      initialBearing: 0,
      initialPitch: 0,
      onMapReady: this.onMapReady
    })
    .width('100%')
    .height('100%')
  }
  
  @Builder
  buildMapWithConfig2() {
    // 配置2: 低缩放+倾斜
    NativeMapView({
      styleUrl: 'https://demotiles.maplibre.org/style.json',
      initialLatitude: 39.9042,
      initialLongitude: 116.4074,
      initialZoom: 8,
      initialBearing: 45,
      initialPitch: 60,
      onMapReady: this.onMapReady
    })
    .width('100%')
    .height('100%')
  }
  
  @Builder
  buildMapContent() {
    if (this.currentConfig === '配置1') {
      this.buildMapWithConfig1()
    } else if (this.currentConfig === '配置2') {
      this.buildMapWithConfig2()
    } else {
      NativeMapView({
        onMapReady: this.onMapReady
      })
      .width('100%')
      .height('100%')
    }
  }
  
  @Builder
  buildControlPanel() {
    Column({ space: 12 }) {
      Text('声明式配置')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Text(`当前: ${this.currentConfig}`)
        .fontSize(14)
        .fontColor('#666')
      
      Button('默认配置')
        .width('100%')
        .backgroundColor(this.currentConfig === '默认配置' ? '#2196F3' : '#9E9E9E')
        .onClick(() => {
          this.currentConfig = '默认配置';
          showToast('已切换到默认配置');
        })
      
      Button('配置1 (高缩放)')
        .width('100%')
        .backgroundColor(this.currentConfig === '配置1' ? '#2196F3' : '#9E9E9E')
        .onClick(() => {
          this.currentConfig = '配置1';
          showToast('已切换到配置1');
        })
      
      Button('配置2 (低缩放+倾斜)')
        .width('100%')
        .backgroundColor(this.currentConfig === '配置2' ? '#2196F3' : '#9E9E9E')
        .onClick(() => {
          this.currentConfig = '配置2';
          showToast('已切换到配置2');
        })
      
      Text('说明: 使用@Builder进行声明式配置')
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
        title: 'Map Options Xml',
        description: '声明式地图选项',
        showActionBar: true,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%')
  }
}


