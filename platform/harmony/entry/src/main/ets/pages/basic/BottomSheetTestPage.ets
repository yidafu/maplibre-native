/**
 * Bottom Sheet Test Page
 * 底部抽屉测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/maplayout/BottomSheetActivity.kt
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, CameraPosition, LatLng } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct BottomSheetTestPage {
  private mapController: MapLibreMap | null = null;
  @State private sheetHeight: number = 200;
  @State private isExpanded: boolean = false;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[BottomSheetTestPage] onMapReady');
    this.mapController = map;
    map.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    
    // TODO: Use jumpTo instead of CameraPosition
    // TODO: map.setCameraPosition(initialPosition);
  };
  
  /**
   * 切换抽屉展开状态
   */
  private toggleSheet = (): void => {
    this.isExpanded = !this.isExpanded;
    this.sheetHeight = this.isExpanded ? 500 : 200;
  };
  
  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 地图层
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
            // router.back();
          });
          
          Column() {
            Text('Bottom Sheet')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White);
            Text('底部抽屉')
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
        
        // 地图
        MapView({
          onMapReady: this.onMapReady,
            styleUrl: DEFAULT_STYLE_URLS.bright,
            initialLatitude: 39.9,
            initialLongitude: 116.4,
            initialZoom: 10
        })
          .layoutWeight(1)
          .width('100%');
      }
      .width('100%')
      .height('100%');
      
      // 底部抽屉
      Column() {
        // 拖动指示器
        Column()
          .width(40)
          .height(4)
          .backgroundColor('#CCCCCC')
          .borderRadius(2)
          .margin({ top: 8, bottom: 8 });
        
        // 抽屉内容
        Column() {
          Row() {
            Text('底部抽屉内容')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1);
            
            Button(this.isExpanded ? '收起' : '展开')
              .fontSize(14)
              .onClick(this.toggleSheet);
          }
          .width('100%')
          .margin({ bottom: 16 });
          
          Text('这是一个底部抽屉组件，可以在地图底部显示内容。')
            .fontSize(14)
            .margin({ bottom: 12 });
          
          if (this.isExpanded) {
            Column() {
              Text('展开后的内容')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 8 });
              
              Text('可以显示更多信息和操作按钮')
                .fontSize(14)
                .margin({ bottom: 8 });
              
              Button('测试按钮')
                .width('100%')
                .onClick(() => showToast('按钮被点击'));
            }
            .alignItems(HorizontalAlign.Start);
          }
        }
        .alignItems(HorizontalAlign.Start)
        .padding(16);
      }
      .width('100%')
      .height(this.sheetHeight)
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 16, topRight: 16 })
      .shadow({
        radius: 16,
        color: 'rgba(0, 0, 0, 0.2)',
        offsetX: 0,
        offsetY: -4
      })
      .animation({
        duration: 300,
        curve: Curve.EaseInOut
      });
    }
    .width('100%')
    .height('100%');
  }
}
