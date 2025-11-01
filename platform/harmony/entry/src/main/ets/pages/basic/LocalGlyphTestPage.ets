/**
 * Local Glyph Test Page
 * 本地字体测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/maplayout/LocalGlyphActivity.kt
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, CameraPosition, LatLng } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct LocalGlyphTestPage {
  private mapController: MapLibreMap | null = null;
  @State private useLocalGlyphs: boolean = false;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[LocalGlyphTestPage] onMapReady');
    this.mapController = map;
    map.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    
    // 设置为中国区域，显示中文标签
    // TODO: Use jumpTo instead of CameraPosition
    // TODO: map.setCameraPosition(initialPosition);
    
    // 默认启用本地字体
    this.enableLocalGlyphs();
  };
  
  /**
   * 启用本地字体
   */
  private enableLocalGlyphs = (): void => {
    this.useLocalGlyphs = true;
    
    if (this.mapController) {
      // TODO: 实现本地字体配置
      // this.mapController.setLocalIdeographFontFamily("sans-serif");
      console.warn('TODO: Implement setLocalIdeographFontFamily');
      showToast('本地字体已启用');
    }
  };
  
  /**
   * 禁用本地字体
   */
  private disableLocalGlyphs = (): void => {
    this.useLocalGlyphs = false;
    
    if (this.mapController) {
      // TODO: 实现禁用本地字体
      // this.mapController.setLocalIdeographFontFamily(null);
      console.warn('TODO: Implement disable local glyphs');
      showToast('本地字体已禁用，将从服务器加载');
    }
  };
  
  /**
   * 切换到不同城市查看字体
   */
  private showCity = (city: LatLng, name: string): void => {
    if (this.mapController) {
      this.mapController.jumpTo(0, city.latitude, city.longitude, 0, 12);
      showToast(`显示: ${name}`);
    }
  };
  
  @Builder
  actionButtonsBuilder() {
    Button(this.useLocalGlyphs ? '禁用本地字体' : '启用本地字体')
      .fontSize(14)
      .backgroundColor(this.useLocalGlyphs ? '#4CAF50' : '#9E9E9E')
      .onClick(() => {
        if (this.useLocalGlyphs) {
          this.disableLocalGlyphs();
        } else {
          this.enableLocalGlyphs();
        }
      });
    
    Button('北京')
      .fontSize(14)
      .onClick(() => this.showCity(TEST_LOCATIONS.beijing, '北京'));
    
    Button('上海')
      .fontSize(14)
      .onClick(() => this.showCity(TEST_LOCATIONS.shanghai, '上海'));
    
    Button('西安')
      .fontSize(14)
      .onClick(() => this.showCity(TEST_LOCATIONS.xian, '西安'));
  }
  
  @Builder
  controlPanelBuilder() {
    Column() {
      Text('本地字体设置')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 });
      
      Text(this.useLocalGlyphs ? '✓ 使用本地字体渲染' : '✗ 从服务器加载字体')
        .fontSize(14)
        .fontColor(this.useLocalGlyphs ? '#4CAF50' : '#F44336')
        .margin({ bottom: 8 });
      
      Text('说明：')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 4 });
      
      Text('本地字体可以提高中文、日文等表意文字的渲染性能，避免从网络加载大量字形数据。')
        .fontSize(12)
        .fontColor('#666666');
    }
    .alignItems(HorizontalAlign.Start)
    .width(280);
  }
  
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
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Local Glyph',
        description: '本地字体',
        showActionBar: true,
        actionButtons: this.actionButtonsBuilder,
        controlPanel: (): void => this.controlPanelBuilder(),
        mapContent: (): void => this.mapContentBuilder()
      });
    }
    .width('100%')
    .height('100%');
  }
}