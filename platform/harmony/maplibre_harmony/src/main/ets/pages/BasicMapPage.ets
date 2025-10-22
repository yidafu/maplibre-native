/**
 * 基础地图测试页面
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { NativeMapView } from '../maps/NativeMapView'
import { router } from '@kit.ArkUI';

const DOMAIN = 0x0000;

@Entry
@Component
struct BasicMapPage {
  @State mapReady: boolean = false;

  build() {
    Column() {
      // 标题栏
      Row() {
        Button('返回')
          .fontSize(16)
          .backgroundColor(Color.Transparent)
          .fontColor('#2196F3')
          .onClick(() => {
            router.back();
          })
          .margin({ left: 5 })

        Text('基础地图测试')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 60 })
      }
      .width('100%')
      .height(50)
      .backgroundColor('#F0F0F0')

      // 地图容器
      Stack() {
        NativeMapView({
          styleUrl: "https://demotiles.maplibre.org/style.json",
          initialLatitude: 39.9042,
          initialLongitude: 116.4074,
          initialZoom: 10,
          onMapReady: () => {
            this.mapReady = true;
            hilog.info(DOMAIN, 'BasicMapPage', 'Map ready');
          }
        })
          .width('100%')
          .height('100%')

        // 加载指示器
        if (!this.mapReady) {
          Column() {
            LoadingProgress()
              .width(50)
              .height(50)
              .color('#2196F3')

            Text('地图加载中...')
              .fontSize(16)
              .margin({ top: 10 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor('rgba(255, 255, 255, 0.8)')
        }
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}

