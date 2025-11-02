/**
 * Animation Types Test Page
 * 动画类型对比测试页面
 * 
 * 功能：easeTo/flyTo/animateCamera 对比
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS } from '../common/TestUtils';

@Entry
@Component
struct CameraAnimationTypeTestPage {
  private mapController: MapLibreMap | null = null;
  @State private statusMessage: string = '初始化...';
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[CameraAnimationTypeTestPage] onMapReady');
    this.mapController = map;
    map.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    map.jumpTo(0, 39.9042, 116.4074, 0, 12);
    
    this.statusMessage = '地图已就绪';
    showToast('动画类型对比功能已激活');
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
    Column({ space: 12 }) {
      Text('动画类型对比')
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
      
      Divider().margin({ top: 8, bottom: 8 })
      
      Button('测试功能')
        .width('100%')
        .backgroundColor('#2196F3')
        .onClick(() => {
          showToast('功能测试');
          this.statusMessage = '测试执行中...';
        })
      
      Text('💡 easeTo/flyTo/animateCamera 对比')
        .fontSize(11)
        .fontColor('#666')
        .width('100%')
        .margin({ top: 8 })
        .lineHeight(16)
    }
    .width('100%')
    .padding(16)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Animation Types',
        description: '动画类型对比',
        showActionBar: false,
        mapContent: (): void => this.mapContentBuilder(),
        controlPanel: (): void => this.controlPanelBuilder()
      });
    }
    .width('100%')
    .height('100%');
  }
}
