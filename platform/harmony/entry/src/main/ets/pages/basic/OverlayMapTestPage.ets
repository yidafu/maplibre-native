/**
 * Overlay Map Test Page
 * 叠加层地图测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/maplayout/OverlayMapActivity.kt
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, CameraPosition, LatLng } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct OverlayMapTestPage {
  private mapController: MapLibreMap | null = null;
  @State private showOverlay: boolean = false;
  @State private overlayOpacity: number = 0.5;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[OverlayMapTestPage] onMapReady');
    this.mapController = map;
    map.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    map.jumpTo(0, 39.9, 116.4, 0, 10);
  };
  
  /**
   * 切换叠加层
   */
  private toggleOverlay = (): void => {
    this.showOverlay = !this.showOverlay;
    showToast(`叠加层: ${this.showOverlay ? '显示' : '隐藏'}`);
  };
  
  /**
   * 调整叠加层透明度
   */
  private adjustOpacity = (value: number): void => {
    this.overlayOpacity = value;
  };
  
  @Builder
  actionButtonsBuilder() {
    Button(this.showOverlay ? '隐藏叠加层' : '显示叠加层')
      .fontSize(14)
      .onClick(this.toggleOverlay);
    
    if (this.showOverlay) {
      Slider({
        value: this.overlayOpacity * 100,
        min: 0,
        max: 100,
        step: 10
      })
        .width(150)
        .onChange((value: number) => {
          this.adjustOpacity(value / 100);
        });
      
      Text(`透明度: ${(this.overlayOpacity * 100).toFixed(0)}%`)
        .fontSize(14);
    }
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
    Stack() {
      TestPageLayout({
        title: 'Overlay Map',
        description: '叠加层地图',
        showActionBar: true,
        actionButtons: (): void => this.actionButtonsBuilder(),
        mapContent: (): void => this.mapContentBuilder()
      });
      
      // 叠加层
      if (this.showOverlay) {
        Column() {
          Text('这是一个叠加层')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White);
          
          Text('可以在地图上显示任意内容')
            .fontSize(16)
            .fontColor('#E0E0E0')
            .margin({ top: 12 });
        }
        .width('100%')
        .height('100%')
        .backgroundColor(`rgba(33, 150, 243, ${this.overlayOpacity})`)
        .justifyContent(FlexAlign.Center);
      }
    }
    .width('100%')
    .height('100%');
  }
}
