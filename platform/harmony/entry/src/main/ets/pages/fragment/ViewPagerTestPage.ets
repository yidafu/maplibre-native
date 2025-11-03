/**
 * ViewPager Test Page
 * ViewPager测试页面
 * 
 * 注意: Harmony使用Swiper组件
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MapLibreMapOptions , NativeMapView} from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct ViewPagerTestPage {
  private mapController1: MapLibreMap | null = null;
  private mapController2: MapLibreMap | null = null;
  @State private currentIndex: number = 0;
  private mapView: NativeMapView | null = null;
  
  aboutToDisappear() {
    if (this.mapController1) {
      this.mapController1.destroy();
      this.mapController1 = null;
    }
    if (this.mapController2) {
      this.mapController2.destroy();
      this.mapController2 = null;
    }
  }
  
  private onMap1Ready = (map: MapLibreMap): void => {
    this.mapController1 = map;
    this.mapController1.jumpTo(0, 39.9042, 116.4074, 0, 12);
  };
  
  private onMap2Ready = (map: MapLibreMap): void => {
    this.mapController2 = map;
    this.mapController2.jumpTo(0, 31.2304, 121.4737, 0, 12);
  };
  
  @Builder
  buildMapContent() {
    Swiper() {
      // 地图1
      Column() {
        Text('地图1 - 北京')
          .fontSize(18)
          .margin(8)
        MapView({
            styleUrl: DEFAULT_STYLE_URLS.bright,
            onMapReady: this.onMap1Ready,
            initialLatitude: 39.9,
            initialLongitude: 116.4,
            initialZoom: 10
          })
        .width('100%')
        .layoutWeight(1)
      }
      
      // 地图2
      Column() {
        Text('地图2 - 上海')
          .fontSize(18)
          .margin(8)
        MapView({
            styleUrl: DEFAULT_STYLE_URLS.bright,
            onMapReady: this.onMap2Ready,
            initialLatitude: 39.9,
            initialLongitude: 116.4,
            initialZoom: 10
          })
        .width('100%')
        .layoutWeight(1)
      }
    }
    .index(this.currentIndex)
    .onChange((index: number) => {
      this.currentIndex = index;
      showToast(`地图 ${index + 1}`);
    })
  }
  
  @Builder
  buildControlPanel() {
    Column({ space: 12 }) {
      Text('ViewPager地图切换')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Text(`当前: 地图${this.currentIndex + 1}`)
        .fontSize(14)
        .fontColor('#666')
      
      Button('切换到地图1')
        .width('100%')
        .onClick(() => {
          this.currentIndex = 0;
        })
      
      Button('切换到地图2')
        .width('100%')
        .onClick(() => {
          this.currentIndex = 1;
        })
    }
    .width('100%')
    .padding(16)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'ViewPager',
        description: 'ViewPager测试',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      })
    }
    .width('100%')
    .height('100%')
  }
}

