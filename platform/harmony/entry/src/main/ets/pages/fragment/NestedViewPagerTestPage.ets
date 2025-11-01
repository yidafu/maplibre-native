/**
 * Nested ViewPager Test Page
 * 嵌套ViewPager测试页面
 * 
 * 注意: Harmony使用Swiper组件
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MapLibreMapOptions } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct NestedViewPagerTestPage {
  private mapController: MapLibreMap | null = null;
  @State private currentPage: number = 0;
  
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
  
  @Builder
  buildMapContent() {
    Swiper() {
      // 页面1: 地图
      MapView({
        onMapReady: this.onMapReady,
            styleUrl: DEFAULT_STYLE_URLS.bright,
            initialLatitude: 39.9,
            initialLongitude: 116.4,
            initialZoom: 10
      })
      .width('100%')
      .height('100%')
      
      // 页面2: 信息
      Column() {
        Text('信息页面')
          .fontSize(24)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#F5F5F5')
      
      // 页面3: 设置
      Column() {
        Text('设置页面')
          .fontSize(24)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#E8F5E9')
    }
    .index(this.currentPage)
    .onChange((index: number) => {
      this.currentPage = index;
      showToast(`页面 ${index + 1}`);
    })
  }
  
  @Builder
  buildControlPanel() {
    Column({ space: 12 }) {
      Text('嵌套ViewPager')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Text(`当前页面: ${this.currentPage + 1}/3`)
        .fontSize(14)
        .fontColor('#666')
      
      Row({ space: 8 }) {
        Button('地图')
          .layoutWeight(1)
          .backgroundColor(this.currentPage === 0 ? '#2196F3' : '#9E9E9E')
          .onClick(() => {
            this.currentPage = 0;
          })
        
        Button('信息')
          .layoutWeight(1)
          .backgroundColor(this.currentPage === 1 ? '#2196F3' : '#9E9E9E')
          .onClick(() => {
            this.currentPage = 1;
          })
        
        Button('设置')
          .layoutWeight(1)
          .backgroundColor(this.currentPage === 2 ? '#2196F3' : '#9E9E9E')
          .onClick(() => {
            this.currentPage = 2;
          })
      }
      
      Text('说明: 使用Swiper实现页面切换')
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
        title: 'Nested ViewPager',
        description: '嵌套ViewPager',
        showActionBar: true,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%')
  }
}


