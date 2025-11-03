/**
 * Scroll By Test Page
 * 像素级滚动测试页面
 * 
 * 功能：按像素偏移地图（上下左右）
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS } from '../common/TestUtils';

@Entry
@Component
struct ScrollByTestPage {
  private mapController: MapLibreMap | null = null;
  @State private statusMessage: string = '初始化...';
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[ScrollByTestPage] onMapReady');
    this.mapController = map;
    
    this.statusMessage = '地图已就绪';
    showToast('像素级滚动功能已激活');
  };
  
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
  
  @Builder
  controlPanelBuilder() {
    Column({ space: 8 }) {
      Text('像素级滚动')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
      
      Text(this.statusMessage)
        .fontSize(14)
        .fontColor('#666')
        .width('100%')
        .padding(8)
        .backgroundColor('#F5F5F5')
        .borderRadius(4)
      
      Text('💡 按像素偏移地图（上下左右）')
        .fontSize(11)
        .fontColor('#666')
        .width('100%')
        .margin({ top: 4 })
        .lineHeight(16)
    }
    .width('100%')
    .padding(8)
  }
  
  @Builder
  actionButtonsBuilder() {
    Column({ space: 8 }) {
      Button('测试功能')
        .width('100%')
        .backgroundColor('#2196F3')
        .onClick(() => {
          showToast('功能测试');
          this.statusMessage = '测试执行中...';
        })
    }
    .width('100%')
    .padding(8)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Scroll By',
        description: '像素级滚动',
        showActionBar: true,
        mapContent: (): void => this.mapContentBuilder(),
        controlPanel: (): void => this.controlPanelBuilder(),
        actionButtons: (): void => this.actionButtonsBuilder()
      });
    }
    .width('100%')
    .height('100%');
  }
}
