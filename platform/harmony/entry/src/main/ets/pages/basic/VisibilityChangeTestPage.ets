/**
 * Visibility Change Test Page
 * 可见性变化测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/maplayout/VisibilityChangeActivity.kt
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, CameraPosition, LatLng } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct VisibilityChangeTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapVisible: boolean = true;
  @State private visibilityCount: number = 0;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[VisibilityChangeTestPage] onMapReady');
    this.mapController = map;
    map.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    map.jumpTo(0, 39.9, 116.4, 0, 10);
  };
  
  /**
   * 切换地图可见性
   */
  private toggleVisibility = (): void => {
    this.isMapVisible = !this.isMapVisible;
    this.visibilityCount++;
    
    if (this.mapController) {
      // TODO: 实现 onPause/onResume 调用
      if (this.isMapVisible) {
        // this.mapController.onResume();
        console.info('Map resumed');
      } else {
        // this.mapController.onPause();
        console.info('Map paused');
      }
    }
    
    showToast(`地图${this.isMapVisible ? '显示' : '隐藏'}`);
  };
  
  @Builder
  actionButtonsBuilder() {
    Button(this.isMapVisible ? '隐藏地图' : '显示地图')
      .fontSize(14)
      .onClick(this.toggleVisibility);
    
    Text(`切换次数: ${this.visibilityCount}`)
      .fontSize(14)
      .padding(12);
  }
  
  build() {
    Column() {
      // 标题栏
      Row() {
        Button({ type: ButtonType.Normal }) {
          Text('←')
            .fontSize(24)
            .fontColor(Color.White)
        }
        .backgroundColor(Color.Transparent)
        .width(48)
        .height(48)
        .onClick(() => {
          // router.back();
        });
        
        Column() {
          Text('Visibility Change')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White);
          Text('可见性变化')
            .fontSize(12)
            .fontColor('#E0E0E0')
            .margin({ top: 2 });
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 8 });
      }
      .width('100%')
      .height(60)
      .backgroundColor('#2196F3')
      .padding({ left: 8, right: 8, top: 10 });
      
      // 内容区
      Column() {
        if (this.isMapVisible) {
          MapView({
            onMapReady: this.onMapReady,
            styleUrl: DEFAULT_STYLE_URLS.bright,
            initialLatitude: 39.9,
            initialLongitude: 116.4,
            initialZoom: 10
          })
            .width('100%')
            .layoutWeight(1);
        } else {
          Column() {
            Text('地图已隐藏')
              .fontSize(24)
              .fontColor('#999999');
            Text('点击下方按钮显示地图')
              .fontSize(14)
              .fontColor('#CCCCCC')
              .margin({ top: 12 });
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#F5F5F5');
        }
      }
      .layoutWeight(1);
      
      // 操作按钮区
      Row() {
        this.actionButtonsBuilder();
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#F5F5F5')
      .justifyContent(FlexAlign.SpaceEvenly);
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF');
  }
}
