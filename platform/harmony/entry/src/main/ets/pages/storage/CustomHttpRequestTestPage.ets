/**
 * Custom HTTP Request Test Page
 * 自定义HTTP请求测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MapLibreMapOptions } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import { http } from '@kit.NetworkKit';

@Entry
@Component
struct CustomHttpRequestTestPage {
  private mapController: MapLibreMap | null = null;
  @State private requestCount: number = 0;
  @State private useCustom: boolean = false;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 12);
  };
  
  private testCustomRequest = async (): Promise<void> => {
    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request('https://demotiles.maplibre.org/style.json');
      
      if (response.responseCode === 200) {
        this.requestCount++;
        showToast(`自定义请求成功 (${this.requestCount})`);
      } else {
        showToast(`请求失败: ${response.responseCode}`);
      }
      
      httpRequest.destroy();
    } catch (error) {
      showToast(`请求错误: ${error}`);
    }
  };
  
  @Builder
  buildMapContent() {
    MapView({
      onMapReady: this.onMapReady,
            styleUrl: DEFAULT_STYLE_URLS.bright,
            initialLatitude: 39.9,
            initialLongitude: 116.4,
            initialZoom: 10
    })
  }
  
  @Builder
  buildControlPanel() {
    Column({ space: 12 }) {
      Text('自定义HTTP请求')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Text(`请求次数: ${this.requestCount}`)
        .fontSize(14)
        .fontColor('#666')
      
      Button('测试自定义请求')
        .width('100%')
        .onClick(() => this.testCustomRequest())
      
      Button(this.useCustom ? '使用默认' : '使用自定义')
        .width('100%')
        .backgroundColor(this.useCustom ? '#FF6B6B' : '#4CAF50')
        .onClick(() => {
          this.useCustom = !this.useCustom;
          showToast(`HTTP实现: ${this.useCustom ? '自定义' : '默认'}`);
        })
      
      Text('说明: 使用Harmony @kit.NetworkKit')
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
        title: 'Custom HTTP Request',
        description: '自定义HTTP请求',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      })
    }
    .width('100%')
    .height('100%')
  }
}


