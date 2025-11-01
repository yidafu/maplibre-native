/**
 * Map Options Runtime Test Page
 * 运行时地图选项测试页面
 * 
 * 参考: platform/android/.../options/MapOptionsRuntimeActivity.kt
 * 
 * 测试功能:
 * - 运行时修改地图手势选项
 * - 使用UiSettings API控制手势
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MapLibreMapOptions, UiSettings } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct MapOptionsRuntimeTestPage {
  private mapController: MapLibreMap | null = null;
  private uiSettings: UiSettings | null = null;
  @State private rotateEnabled: boolean = true;
  @State private scrollEnabled: boolean = true;
  @State private zoomEnabled: boolean = true;
  @State private tiltEnabled: boolean = true;
  @State private compassEnabled: boolean = true;
  @State private logoEnabled: boolean = true;
  @State private attributionEnabled: boolean = true;
  
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
    
    // 获取UiSettings
    this.uiSettings = this.mapController.getUiSettings();
    
    // 读取当前设置
    this.rotateEnabled = this.uiSettings.isRotateGesturesEnabled();
    this.scrollEnabled = this.uiSettings.isScrollGesturesEnabled();
    this.zoomEnabled = this.uiSettings.isZoomGesturesEnabled();
    this.tiltEnabled = this.uiSettings.isTiltGesturesEnabled();
    this.compassEnabled = this.uiSettings.isCompassEnabled();
    this.logoEnabled = this.uiSettings.isLogoEnabled();
    this.attributionEnabled = this.uiSettings.isAttributionEnabled();
  };
  
  /**
   * 切换旋转手势
   */
  private toggleRotate = (): void => {
    if (!this.uiSettings) return;
    
    this.rotateEnabled = !this.rotateEnabled;
    this.uiSettings.setRotateGesturesEnabled(this.rotateEnabled);
    showToast(`旋转手势: ${this.rotateEnabled ? '启用' : '禁用'}`);
  };
  
  /**
   * 切换平移手势
   */
  private toggleScroll = (): void => {
    if (!this.uiSettings) return;
    
    this.scrollEnabled = !this.scrollEnabled;
    this.uiSettings.setScrollGesturesEnabled(this.scrollEnabled);
    showToast(`平移手势: ${this.scrollEnabled ? '启用' : '禁用'}`);
  };
  
  /**
   * 切换缩放手势
   */
  private toggleZoom = (): void => {
    if (!this.uiSettings) return;
    
    this.zoomEnabled = !this.zoomEnabled;
    this.uiSettings.setZoomGesturesEnabled(this.zoomEnabled);
    showToast(`缩放手势: ${this.zoomEnabled ? '启用' : '禁用'}`);
  };
  
  /**
   * 切换倾斜手势
   */
  private toggleTilt = (): void => {
    if (!this.uiSettings) return;
    
    this.tiltEnabled = !this.tiltEnabled;
    this.uiSettings.setTiltGesturesEnabled(this.tiltEnabled);
    showToast(`倾斜手势: ${this.tiltEnabled ? '启用' : '禁用'}`);
  };
  
  /**
   * 切换指南针
   */
  private toggleCompass = (): void => {
    if (!this.uiSettings) return;
    
    this.compassEnabled = !this.compassEnabled;
    this.uiSettings.setCompassEnabled(this.compassEnabled);
    showToast(`指南针: ${this.compassEnabled ? '显示' : '隐藏'}`);
  };
  
  /**
   * 切换Logo
   */
  private toggleLogo = (): void => {
    if (!this.uiSettings) return;
    
    this.logoEnabled = !this.logoEnabled;
    this.uiSettings.setLogoEnabled(this.logoEnabled);
    showToast(`Logo: ${this.logoEnabled ? '显示' : '隐藏'}`);
  };
  
  /**
   * 切换Attribution
   */
  private toggleAttribution = (): void => {
    if (!this.uiSettings) return;
    
    this.attributionEnabled = !this.attributionEnabled;
    this.uiSettings.setAttributionEnabled(this.attributionEnabled);
    showToast(`Attribution: ${this.attributionEnabled ? '显示' : '隐藏'}`);
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
    Scroll() {
      Column({ space: 12 }) {
        Text('运行时选项控制')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        
        Text('手势控制')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
        
        Button(`旋转手势 ${this.rotateEnabled ? '✓' : '✗'}`)
          .width('100%')
          .backgroundColor(this.rotateEnabled ? '#4CAF50' : '#9E9E9E')
          .onClick(() => this.toggleRotate())
        
        Button(`平移手势 ${this.scrollEnabled ? '✓' : '✗'}`)
          .width('100%')
          .backgroundColor(this.scrollEnabled ? '#4CAF50' : '#9E9E9E')
          .onClick(() => this.toggleScroll())
        
        Button(`缩放手势 ${this.zoomEnabled ? '✓' : '✗'}`)
          .width('100%')
          .backgroundColor(this.zoomEnabled ? '#4CAF50' : '#9E9E9E')
          .onClick(() => this.toggleZoom())
        
        Button(`倾斜手势 ${this.tiltEnabled ? '✓' : '✗'}`)
          .width('100%')
          .backgroundColor(this.tiltEnabled ? '#4CAF50' : '#9E9E9E')
          .onClick(() => this.toggleTilt())
        
        Divider()
        
        Text('UI组件控制')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
        
        Button(`指南针 ${this.compassEnabled ? '✓' : '✗'}`)
          .width('100%')
          .backgroundColor(this.compassEnabled ? '#4CAF50' : '#9E9E9E')
          .onClick(() => this.toggleCompass())
        
        Button(`Logo ${this.logoEnabled ? '✓' : '✗'}`)
          .width('100%')
          .backgroundColor(this.logoEnabled ? '#4CAF50' : '#9E9E9E')
          .onClick(() => this.toggleLogo())
        
        Button(`Attribution ${this.attributionEnabled ? '✓' : '✗'}`)
          .width('100%')
          .backgroundColor(this.attributionEnabled ? '#4CAF50' : '#9E9E9E')
          .onClick(() => this.toggleAttribution())
        
        Text('说明: 使用UiSettings运行时修改地图选项')
          .fontSize(12)
          .fontColor('#666')
          .margin({ top: 8 })
      }
      .width('100%')
      .padding(16)
    }
    .height('100%')
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Map Options Runtime',
        description: '运行时地图选项',
        showActionBar: true,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%')
  }
}
