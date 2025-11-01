/**
 * Fragment BackStack Test Page
 * Fragment回退栈测试页面
 * 
 * 注意: Harmony使用Navigation组件实现
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MapLibreMapOptions } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct FragmentBackStackTestPage {
  private mapController: MapLibreMap | null = null;
  @State private stackDepth: number = 0;
  @State private navigationLog:  string[] = [];
  
  aboutToAppear() {
    this.addNavigationLog('页面启动');
  }
  
  aboutToDisappear() {
    this.addNavigationLog('页面销毁');
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 12);
    this.addNavigationLog('地图已就绪');
  };
  
  private addNavigationLog = (event: string): void => {
    const timestamp = new Date().toLocaleTimeString();
    this.navigationLog.unshift(`[${timestamp}] ${event}`);
    if (this.navigationLog.length > 8) {
      this.navigationLog.pop();
    }
  };
  
  private pushStack = (): void => {
    this.stackDepth++;
    this.addNavigationLog(`压入栈 (深度: ${this.stackDepth})`);
    showToast(`栈深度: ${this.stackDepth}`);
  };
  
  private popStack = (): void => {
    if (this.stackDepth > 0) {
      this.stackDepth--;
      this.addNavigationLog(`弹出栈 (深度: ${this.stackDepth})`);
      showToast(`栈深度: ${this.stackDepth}`);
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
      Text('Fragment回退栈')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Text(`栈深度: ${this.stackDepth}`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.stackDepth > 0 ? '#4CAF50' : '#666')
      
      Button('压入栈')
        .width('100%')
        .onClick(() => this.pushStack())
      
      Button('弹出栈')
        .width('100%')
        .backgroundColor('#FF6B6B')
        .enabled(this.stackDepth > 0)
        .onClick(() => this.popStack())
      
      Text('导航日志')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 8 })
      
      Column() {
        ForEach(this.navigationLog, (log: string, index: number) => {
          Text(log)
            .fontSize(11)
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
      
      Text('说明: Harmony使用Navigation组件')
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
        title: 'Fragment BackStack',
        description: 'Fragment回退栈',
        showActionBar: true,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%')
  }
}


