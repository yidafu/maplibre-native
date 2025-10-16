import { hilog } from '@kit.PerformanceAnalysisKit';
import maplibre from 'libmaplibre_native.so'
import { NativeMapView } from '../maps/NativeMapView'

const DOMAIN = 0x0000;

@Entry
@Component
struct Index {
  @State mapReady: boolean= true;
  @State message: string = 'Hello World';
  @State currentStatus: string = "index";

  build() {
    Row() {
      Column() {
        // 标题栏
        Row() {
          Text('MapLibre Native 测试')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width('100%')
        .height(60)
        .backgroundColor('#2196F3')
        .justifyContent(FlexAlign.Center)

        // 控制按钮
        Row() {
          Button('添加标记')
            .onClick(() => {
              // this.addTestMarker();
            })
            .enabled(this.mapReady)

          Button('清除标记')
            .onClick(() => {
              // this.clearMarkers();
            })
            .enabled(this.mapReady)

          Button('跳转北京')
            .onClick(() => {
              // this.jumpToBeijing();
            })
            .enabled(this.mapReady)

          Button('跳转上海')
            .onClick(() => {
              // this.jumpToShanghai();
            })
            .enabled(this.mapReady)
        }
        .width('100%')
        .height(50)
        .padding({ left: 10, right: 10 })
        .justifyContent(FlexAlign.SpaceEvenly)

        // 地图容器
        Stack() {
          NativeMapView({
            styleUrl: "https://demotiles.maplibre.org/style.json",
            initialLatitude: 39.9042,
            initialLongitude: 116.4074,
            initialZoom: 10,
            debugMode: true,
            onMapReady: () => {
              console.info('Map is ready!');
              this.mapReady = true;
            },
            onMapLoaded: () => {
              console.info('Map loaded!');
            },
            onMapError: (error: string) => {
              console.error('Map error:', error);
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
                .fontColor('#666666')
                .margin({ top: 10 })
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .backgroundColor('rgba(255, 255, 255, 0.8)')
          }
        }
        .width('100%')
        .layoutWeight(1)

        // 状态栏
        Row() {
          Text(`状态: ${this.mapReady ? '已就绪' : '加载中'}`)
            .fontSize(14)
            .fontColor('#666666')

          Text(`标记数量: ${0}`)
            .fontSize(14)
            .fontColor('#666666')
            .margin({ left: 20 })
        }
        .width('100%')
        .height(40)
        .padding({ left: 10, right: 10 })
        .justifyContent(FlexAlign.SpaceBetween)
        .backgroundColor('#F5F5F5')
      }
      .width('100%')
      .height('100%')

    }
    .height('100%')
  }
}
