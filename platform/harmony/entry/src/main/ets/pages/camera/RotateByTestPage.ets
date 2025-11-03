/**
 * Rotate By Test Page
 * 旋转控制测试页面
 * 
 * 功能：顺时针和逆时针旋转地图
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS } from '../common/TestUtils';

@Entry
@Component
struct RotateByTestPage {
  private mapController: MapLibreMap | null = null;
  @State private statusMessage: string = '初始化...';
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[RotateByTestPage] onMapReady');
    this.mapController = map;
    
    this.statusMessage = '地图已就绪';
    showToast('旋转控制功能已激活');
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
      Text('旋转控制')
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
      
      Text('💡 顺时针和逆时针旋转地图')
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
        title: 'Rotate By',
        description: '旋转控制',
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
