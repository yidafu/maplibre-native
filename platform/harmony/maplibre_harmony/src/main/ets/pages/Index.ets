import { hilog } from '@kit.PerformanceAnalysisKit';
import maplibre from 'libmaplibre_harmony.so'

const DOMAIN = 0x0000;

class MyXComponentController extends XComponentController{
  onSurfaceCreated(surfaceId: string): void {
    console.info(`onSurfaceCreated surfaceId: ${surfaceId}`);
    maplibre.SetSurfaceId(BigInt(surfaceId));
  }
  onSurfaceChanged(surfaceId: string, rect: SurfaceRect): void {
    console.info(`onSurfaceChanged surfaceId: ${surfaceId}, rect: ${JSON.stringify(rect)}}`);
    maplibre.ChangeSurface(BigInt(surfaceId), rect.surfaceWidth, rect.surfaceHeight);
  }
  onSurfaceDestroyed(surfaceId: string): void {
    console.info(`onSurfaceDestroyed surfaceId: ${surfaceId}`);
    maplibre.DestroySurface(BigInt(surfaceId));
  }
}

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';
  @State currentStatus: string = "index";

  xComponentController: XComponentController = new MyXComponentController();

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize($r('app.float.page_text_font_size'))
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            this.message = 'Welcome';
            hilog.info(DOMAIN, 'testTag', 'Test NAPI 2 + 3 = %{public}d', maplibre.add(2, 3));
          })
        Row() {
          Button('Draw Star')
            .fontSize('16fp')
            .fontWeight(500)
            .margin({ bottom: 24 })
            .onClick(() => {
              let surfaceId = this.xComponentController.getXComponentSurfaceId()
              maplibre.DrawPattern(BigInt(surfaceId))
              let hasDraw: boolean = false;
              if (maplibre.GetXComponentStatus(BigInt(surfaceId))) {
                hasDraw = maplibre.GetXComponentStatus(BigInt(surfaceId)).hasDraw;
              }
              if (hasDraw) {
                this.currentStatus = "draw star"
              }
            })
            .width('53.6%')
            .height(40)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Bottom)
        .layoutWeight(1)

        XComponent({
          type: XComponentType.SURFACE,
          controller: this.xComponentController
        })
      }
      .width('100%')
    }
    .height('100%')
  }
}
