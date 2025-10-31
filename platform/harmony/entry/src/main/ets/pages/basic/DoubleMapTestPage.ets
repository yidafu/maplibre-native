/**
 * Double Map Test Page
 * 双地图实例测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/maplayout/DoubleMapActivity.kt
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { NativeMapView, MapLibreMap, CameraPosition, LatLng } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS } from '../common/TestUtils';

@Entry
@Component
struct DoubleMapTestPage {
  private map1Controller: MapLibreMap | null = null;
  private map2Controller: MapLibreMap | null = null;
  
  aboutToDisappear() {
    if (this.map1Controller) {
      this.map1Controller.destroy();
      this.map1Controller = null;
    }
    if (this.map2Controller) {
      this.map2Controller.destroy();
      this.map2Controller = null;
    }
  }
  
  private onMap1Ready = (map: MapLibreMap): void => {
    console.info('[DoubleMapTestPage] onMap1Ready');
    this.map1Controller = map;
    map.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    
    // 设置为北京
    map.jumpTo(0, TEST_LOCATIONS.beijing.latitude, TEST_LOCATIONS.beijing.longitude, 0, 10);
  };
  
  private onMap2Ready = (map: MapLibreMap): void => {
    console.info('[DoubleMapTestPage] onMap2Ready');
    this.map2Controller = map;
    map.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    
    // 设置为上海
    map.jumpTo(0, TEST_LOCATIONS.shanghai.latitude, TEST_LOCATIONS.shanghai.longitude, 0, 10);
  };
  
  /**
   * 同步两个地图的相机位置
   */
  private syncMaps = (): void => {
    if (this.map1Controller && this.map2Controller) {
      const latLng1 = this.map1Controller.getLatLng();
      const zoom1 = this.map1Controller.getZoom();
      const bearing1 = this.map1Controller.getBearing();
      const pitch1 = this.map1Controller.getPitch();
      
      this.map2Controller.jumpTo(bearing1, latLng1.latitude, latLng1.longitude, pitch1, zoom1);
      showToast('地图位置已同步');
    }
  };
  
  @Builder
  actionButtonsBuilder() {
    Button('同步位置')
      .fontSize(14)
      .onClick(this.syncMaps);
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
          // 返回上一页
          // TODO: 实现返回逻辑
        });
        
        Column() {
          Text('Double Map')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White);
          Text('双地图实例')
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
      
      // 两个地图（上下分屏）
      Column() {
        // 地图1
        Column() {
          Text('地图 1 - 北京')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .padding(8)
            .backgroundColor('#F5F5F5');
          
          NativeMapView({
            onMapReady: this.onMap1Ready
          })
            .width('100%')
            .layoutWeight(1);
        }
        .width('100%')
        .layoutWeight(1);
        
        // 分隔线
        Divider()
          .strokeWidth(2)
          .color('#E0E0E0');
        
        // 地图2
        Column() {
          Text('地图 2 - 上海')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .padding(8)
            .backgroundColor('#F5F5F5');
          
          NativeMapView({
            onMapReady: this.onMap2Ready
          })
            .width('100%')
            .layoutWeight(1);
        }
        .width('100%')
        .layoutWeight(1);
      }
      .layoutWeight(1);
      
      // 操作按钮区
      Row() {
        this.actionButtonsBuilder();
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#F5F5F5')
      .justifyContent(FlexAlign.Center);
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF');
  }
}
