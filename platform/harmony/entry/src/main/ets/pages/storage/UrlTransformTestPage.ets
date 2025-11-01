/**
 * URL Transform Test Page
 * URL转换测试页面
 * 
 * 参考: platform/android/.../storage/UrlTransformActivity.kt
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MapLibreMapOptions } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct UrlTransformTestPage {
  private mapController: MapLibreMap | null = null;
  @State private transformEnabled: boolean = false;
  @State private requestLog:  string[] = [];
  
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
  
  private logRequest = (url: string): void => {
    const timestamp = new Date().toLocaleTimeString();
    this.requestLog.unshift(`[${timestamp}] ${url.substring(0, 60)}...`);
    if (this.requestLog.length > 10) {
      this.requestLog.pop();
    }
  };
  
  private toggleTransform = (): void => {
    this.transformEnabled = !this.transformEnabled;
    showToast(`URL转换: ${this.transformEnabled ? '启用' : '禁用'}`);
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
      Text('URL转换')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Button(this.transformEnabled ? '禁用转换' : '启用转换')
        .width('100%')
        .backgroundColor(this.transformEnabled ? '#FF6B6B' : '#4CAF50')
        .onClick(() => this.toggleTransform())
      
      Text('请求日志')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 8 })
      
      Column() {
        ForEach(this.requestLog, (log: string, index: number) => {
          Text(log)
            .fontSize(10)
            .fontFamily('monospace')
            .width('100%')
            .padding(4)
            .backgroundColor(index % 2 === 0 ? '#F5F5F5' : '#FFFFFF')
        })
      }
      .width('100%')
      .backgroundColor('#F9F9F9')
      .border({ width: 1, color: '#DDD' })
      .borderRadius(4)
      .height(200)
      
      Text('TODO: 实现ResourceTransform API')
        .fontSize(12)
        .fontColor('#FF9800')
        .fontWeight(FontWeight.Bold)
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'URL Transform',
        description: 'URL转换',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      })
    }
    .width('100%')
    .height('100%')
  }
}


