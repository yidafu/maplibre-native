/**
 * TextureView Debug Mode Test Page
 * TextureView调试模式测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MapLibreMapOptions } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct TextureViewDebugModeTestPage {
  private mapController: MapLibreMap | null = null;
  @State private debugMode: boolean = false;
  
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
  
  private toggleDebugMode = (): void => {
    if (!this.mapController) return;
    
    this.debugMode = !this.debugMode;
    this.mapController.setDebugActive(this.debugMode);
    showToast(`调试模式: ${this.debugMode ? '开启' : '关闭'}`);
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
      Button(this.debugMode ? '关闭调试模式' : '开启调试模式')
        .width('100%')
        .backgroundColor(this.debugMode ? '#FF6B6B' : '#4CAF50')
        .onClick(() => this.toggleDebugMode())
      
      Text(`当前状态: ${this.debugMode ? '调试中' : '正常'}`)
        .fontSize(14)
        .fontColor('#666')
    }
    .width('100%')
    .padding(16)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'TextureView Debug Mode',
        description: 'XComponent调试模式',
        showActionBar: true,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%')
  }
}


