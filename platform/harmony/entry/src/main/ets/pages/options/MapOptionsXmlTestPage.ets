/**
 * Map Options Xml Test Page
 * 声明式地图选项测试页面
 * 
 * 注意: Harmony使用@Builder声明式配置
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MapLibreMapOptions } from 'maplibre_harmony';
import { showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

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
  
  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 12);
  };
  
  @Builder
  buildMapWithConfig1() {
    // 配置1: 高缩放级别
    MapView({
      styleUrl: 'https://demotiles.maplibre.org/style.json',
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 5,
      initialBearing: 0,
      initialPitch: 0,
      onMapReady: this.onMapReady
    })
  }
  
  @Builder
  buildMapWithConfig2() {
    // 配置2: 低缩放+倾斜
    MapView({
      styleUrl: 'https://demotiles.maplibre.org/style.json',
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 5,
      initialBearing: 0,
      initialPitch: 0,
      onMapReady: this.onMapReady
    })
  }
  
  @Builder
  buildMapContent() {
    if (this.currentConfig === '配置1') {
      this.buildMapWithConfig1()
    } else if (this.currentConfig === '配置2') {
      this.buildMapWithConfig2()
    } else {
      MapView({
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
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      })
    }
    .width('100%')
    .height('100%')
  }
}


