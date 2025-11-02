/**
 * Manual Zoom Test Page
 * 手动缩放测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/camera/ManualZoomActivity.kt
 * 
 * 功能：
 * - 放大/缩小（Zoom In/Out）
 * - 缩放到指定级别（Zoom To）
 * - 相对缩放（Zoom By）
 * - 禁用所有手势，仅通过按钮控制
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS } from '../common/TestUtils';

@Entry
@Component
struct ManualZoomTestPage {
  private mapController: MapLibreMap | null = null;
  @State private currentZoom: number = 10;
  @State private minZoom: number = 0;
  @State private maxZoom: number = 22;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[ManualZoomTestPage] onMapReady');
    this.mapController = map;
    map.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    map.jumpTo(0, 39.9042, 116.4074, 0, this.currentZoom);
    
    this.updateZoomLevel();
    showToast('手动缩放控制已激活');
  };
  
  /**
   * 更新缩放级别显示
   */
  private updateZoomLevel = (): void => {
    if (!this.mapController) return;
    
    try {
      this.currentZoom = this.mapController.getZoom();
      this.minZoom = this.mapController.getMinZoom();
      this.maxZoom = this.mapController.getMaxZoom();
    } catch (error) {
      console.error('[ManualZoomTestPage] Failed to get zoom level:', error);
    }
  };
  
  /**
   * 放大（Zoom In）
   */
  private zoomIn = (): void => {
    if (!this.mapController) return;
    
    const newZoom = Math.min(this.currentZoom + 1, this.maxZoom);
    this.mapController.setZoom(newZoom, 300);
    
    setTimeout(() => {
      this.updateZoomLevel();
      showToast(`放大到: ${newZoom.toFixed(2)}`);
    }, 300);
  };
  
  /**
   * 缩小（Zoom Out）
   */
  private zoomOut = (): void => {
    if (!this.mapController) return;
    
    const newZoom = Math.max(this.currentZoom - 1, this.minZoom);
    this.mapController.setZoom(newZoom, 300);
    
    setTimeout(() => {
      this.updateZoomLevel();
      showToast(`缩小到: ${newZoom.toFixed(2)}`);
    }, 300);
  };
  
  /**
   * 缩放到指定级别（Zoom To）
   */
  private zoomTo = (level: number): void => {
    if (!this.mapController) return;
    
    this.mapController.setZoom(level, 500);
    
    setTimeout(() => {
      this.updateZoomLevel();
      showToast(`缩放到: ${level}`);
    }, 500);
  };
  
  /**
   * 相对缩放（Zoom By）
   */
  private zoomBy = (delta: number): void => {
    if (!this.mapController) return;
    
    const newZoom = Math.max(this.minZoom, Math.min(this.maxZoom, this.currentZoom + delta));
    this.mapController.setZoom(newZoom, 400);
    
    setTimeout(() => {
      this.updateZoomLevel();
      showToast(`相对缩放: ${delta > 0 ? '+' : ''}${delta}`);
    }, 400);
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
      .height('100%')
  }
  
  @Builder
  controlPanelBuilder() {
    Column({ space: 12 }) {
      Text('手动缩放控制')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
      
      // 当前缩放级别显示
      Column({ space: 8 }) {
        Row() {
          Text('当前缩放:')
            .fontSize(14)
            .width(80)
          Text(this.currentZoom.toFixed(2))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2196F3')
            .layoutWeight(1)
        }
        .width('100%')
        
        Row() {
          Text('范围:')
            .fontSize(12)
            .width(80)
          Text(`${this.minZoom} - ${this.maxZoom}`)
            .fontSize(12)
            .fontColor('#666')
            .layoutWeight(1)
        }
        .width('100%')
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#F5F5F5')
      .borderRadius(4)
      
      Divider().margin({ top: 4, bottom: 4 })
      
      // 基础缩放控制
      Text('基础缩放')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .width('100%')
      
      Row({ space: 8 }) {
        Button('放大 (+)')
          .layoutWeight(1)
          .backgroundColor('#4CAF50')
          .onClick(() => this.zoomIn())
          .enabled(this.currentZoom < this.maxZoom)
        
        Button('缩小 (-)')
          .layoutWeight(1)
          .backgroundColor('#FF6B6B')
          .onClick(() => this.zoomOut())
          .enabled(this.currentZoom > this.minZoom)
      }
      .width('100%')
      
      Divider().margin({ top: 4, bottom: 4 })
      
      // 快捷缩放
      Text('缩放到指定级别')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .width('100%')
      
      Row({ space: 8 }) {
        Button('0')
          .layoutWeight(1)
          .fontSize(12)
          .backgroundColor('#607D8B')
          .onClick(() => this.zoomTo(0))
        
        Button('5')
          .layoutWeight(1)
          .fontSize(12)
          .backgroundColor('#607D8B')
          .onClick(() => this.zoomTo(5))
        
        Button('10')
          .layoutWeight(1)
          .fontSize(12)
          .backgroundColor('#607D8B')
          .onClick(() => this.zoomTo(10))
        
        Button('15')
          .layoutWeight(1)
          .fontSize(12)
          .backgroundColor('#607D8B')
          .onClick(() => this.zoomTo(15))
      }
      .width('100%')
      
      Divider().margin({ top: 4, bottom: 4 })
      
      // 相对缩放
      Text('相对缩放')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .width('100%')
      
      Row({ space: 8 }) {
        Button('+0.5')
          .layoutWeight(1)
          .fontSize(12)
          .backgroundColor('#2196F3')
          .onClick(() => this.zoomBy(0.5))
        
        Button('+2')
          .layoutWeight(1)
          .fontSize(12)
          .backgroundColor('#2196F3')
          .onClick(() => this.zoomBy(2))
        
        Button('-0.5')
          .layoutWeight(1)
          .fontSize(12)
          .backgroundColor('#FF9800')
          .onClick(() => this.zoomBy(-0.5))
        
        Button('-2')
          .layoutWeight(1)
          .fontSize(12)
          .backgroundColor('#FF9800')
          .onClick(() => this.zoomBy(-2))
      }
      .width('100%')
      
      // 刷新按钮
      Button('刷新缩放级别')
        .width('100%')
        .backgroundColor('#9C27B0')
        .onClick(() => {
          this.updateZoomLevel();
          showToast('缩放级别已刷新');
        })
      
      // 说明文字
      Text('💡 手动控制地图缩放\n所有手势已禁用，仅通过按钮控制')
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
        title: 'Manual Zoom',
        description: '手动缩放',
        showActionBar: false,
        mapContent: (): void => this.mapContentBuilder(),
        controlPanel: (): void => this.controlPanelBuilder()
      });
    }
    .width('100%')
    .height('100%');
  }
}
