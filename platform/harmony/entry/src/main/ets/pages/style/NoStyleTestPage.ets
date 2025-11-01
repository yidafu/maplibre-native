/**
 * No Style Test Page
 * 无样式地图测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MapLibreMapOptions } from 'maplibre_harmony';
import { showToast, DEFAULT_MAP_CONFIG, DEFAULT_STYLE_URLS } from '../common/TestUtils';

@Entry
@Component
struct NoStyleTestPage {
  private mapController: MapLibreMap | null = null;
  @State private hasStyle: boolean = false;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    // 不设置样式
    showToast('地图已初始化（无样式）');
  };
  
  private loadStyle = (): void => {
    if (!this.mapController) return;
    
    this.mapController.setStyleUrl('https://demotiles.maplibre.org/style.json');
    this.hasStyle = true;
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 12);
    showToast('样式已加载');
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
      Text('无样式地图')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Text(`状态: ${this.hasStyle ? '已加载样式' : '无样式'}`)
        .fontSize(14)
        .fontColor(this.hasStyle ? '#4CAF50' : '#FF6B6B')
      
      Button('加载样式')
        .width('100%')
        .enabled(!this.hasStyle)
        .onClick(() => this.loadStyle())
      
      Text('说明: 测试地图在无样式状态下的行为')
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
        title: 'No Style',
        description: '无样式地图',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      })
    }
    .width('100%')
    .height('100%')
  }
}


