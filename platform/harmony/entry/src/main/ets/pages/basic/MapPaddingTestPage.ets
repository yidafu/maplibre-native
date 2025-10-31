/**
 * Map Padding Test Page
 * 地图内边距测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/maplayout/MapPaddingActivity.kt
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { NativeMapView, MapLibreMap, CameraPosition, LatLng } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS } from '../common/TestUtils';

@Entry
@Component
struct MapPaddingTestPage {
  private mapController: MapLibreMap | null = null;
  @State private paddingTop: number = 0;
  @State private paddingBottom: number = 0;
  @State private paddingLeft: number = 0;
  @State private paddingRight: number = 0;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[MapPaddingTestPage] onMapReady');
    this.mapController = map;
    map.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    
    // TODO: Use jumpTo instead of CameraPosition
    // TODO: map.setCameraPosition(initialPosition);
  };
  
  /**
   * 设置地图内边距
   */
  private applyPadding = (top: number, bottom: number, left: number, right: number): void => {
    this.paddingTop = top;
    this.paddingBottom = bottom;
    this.paddingLeft = left;
    this.paddingRight = right;
    
    if (this.mapController) {
      // TODO: 实现 setPadding 方法
      // this.mapController.setPadding(left, top, right, bottom);
      console.warn('TODO: Implement setPadding');
      showToast(`边距: ${top}, ${right}, ${bottom}, ${left}`);
    }
  };
  
  @Builder
  actionButtonsBuilder() {
    Button('无边距')
      .fontSize(14)
      .onClick(() => this.applyPadding(0, 0, 0, 0));
    
    Button('上边距')
      .fontSize(14)
      .onClick(() => this.applyPadding(200, 0, 0, 0));
    
    Button('下边距')
      .fontSize(14)
      .onClick(() => this.applyPadding(0, 200, 0, 0));
    
    Button('左右边距')
      .fontSize(14)
      .onClick(() => this.applyPadding(0, 0, 100, 100));
    
    Button('全边距')
      .fontSize(14)
      .onClick(() => this.applyPadding(100, 100, 100, 100));
  }
  
  @Builder
  controlPanelBuilder() {
    Column() {
      Text('地图内边距')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 });
      
      Text(`上: ${this.paddingTop}px`)
        .fontSize(14)
        .margin({ bottom: 4 });
      Text(`下: ${this.paddingBottom}px`)
        .fontSize(14)
        .margin({ bottom: 4 });
      Text(`左: ${this.paddingLeft}px`)
        .fontSize(14)
        .margin({ bottom: 4 });
      Text(`右: ${this.paddingRight}px`)
        .fontSize(14);
    }
    .alignItems(HorizontalAlign.Start);
  }
  
  build() {
    Column() {
      TestPageLayout({
      title: 'Map Padding',
      description: '地图内边距',
      showActionBar: true,
      actionButtons: this.actionButtonsBuilder,
      controlPanel: this.controlPanelBuilder,
      mapContent: () => {
        NativeMapView({
          onMapReady: this.onMapReady
        })
          .width('100%')
          .height('100%');
      }
    });
    }
    .width('100%')
    .height('100%');
  }
}