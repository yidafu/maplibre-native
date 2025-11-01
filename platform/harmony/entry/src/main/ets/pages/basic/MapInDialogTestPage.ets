/**
 * Map In Dialog Test Page
 * 对话框中的地图测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/maplayout/MapInDialogActivity.kt
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, CameraPosition, LatLng } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct MapInDialogTestPage {
  private mapController: MapLibreMap | null = null;
  private dialogMapController: MapLibreMap | null = null;
  @State private showDialog: boolean = false;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
    if (this.dialogMapController) {
      this.dialogMapController.destroy();
      this.dialogMapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[MapInDialogTestPage] onMapReady');
    this.mapController = map;
    map.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    
    // TODO: Use jumpTo instead of CameraPosition
    // TODO: map.setCameraPosition(initialPosition);
  };
  
  private onDialogMapReady = (map: MapLibreMap): void => {
    console.info('[MapInDialogTestPage] onDialogMapReady');
    this.dialogMapController = map;
    map.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    
    // TODO: Use jumpTo instead of CameraPosition
    // TODO: map.setCameraPosition(initialPosition);
  };
  
  @Builder
  actionButtonsBuilder() {
    Button('显示对话框')
      .fontSize(14)
      .onClick(() => {
        this.showDialog = true;
      });
  }
  
  @Builder
  dialogBuilder() {
    Column() {
      Text('对话框中的地图')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 });
      
      MapView({
        onMapReady: this.onDialogMapReady
      })
        .width('100%')
        .height(400);
      
      Button('关闭')
        .margin({ top: 12 })
        .onClick(() => {
          this.showDialog = false;
          if (this.dialogMapController) {
            this.dialogMapController.destroy();
            this.dialogMapController = null;
          }
        });
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(12);
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
        title: 'Map In Dialog',
        description: '对话框中的地图',
        showActionBar: true,
        actionButtons: (): void => this.actionButtonsBuilder(),
        mapContent: (): void => this.mapContentBuilder()
      });
      
      // 自定义对话框
      if (this.showDialog) {
        Column() {
          Column() {
            this.dialogBuilder();
          }
          .width('90%');
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          // 点击背景关闭
          this.showDialog = false;
        });
      }
    }
    .width('100%')
    .height('100%');
  }
}
