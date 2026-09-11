/**
 * BottomSheetTestPage - Bottom sheet with a map.
 *
 * Shows a draggable bottom panel over the map with location information.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, CameraState } from 'maplibre_harmony';
import { showToast } from '../common/TestUtils';

@Entry
@Component
struct BottomSheetTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Ready';
  @State private sheetExpanded: boolean = false;
  @State private sheetHeight: number = 120;
  @State private lat: number = 30.2741;
  @State private lng: number = 120.1551;
  @State private zoom: number = 8;
  @State private clickCount: number = 0;

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.refreshCameraData();
    this.statusMessage = 'Map ready';
  };

  private refreshCameraData(): void {
    if (!this.mapController) return;
    const state: CameraState = this.mapController.getCameraState();
    this.lat = state.latitude;
    this.lng = state.longitude;
    this.zoom = state.zoom;
  }

  private toggleSheet(): void {
    this.sheetExpanded = !this.sheetExpanded;
    this.sheetHeight = this.sheetExpanded ? 300 : 120;
  }

  private jumpToLocation(lat: number, lng: number, name: string): void {
    if (!this.mapController) return;
    this.mapController.jumpTo(0, lat, lng, 0, 12);
    this.refreshCameraData();
    this.statusMessage = `Jumped to ${name}`;
    showToast(name);
    this.clickCount++;
  }

  @Builder
  mapContent() {
    Stack() {
      MapView({
        onMapReady: this.onMapReady,
      })
        .width('100%')
        .height('100%')

      // Bottom sheet overlay
      Column() {
        Column() {
          // Handle bar
          Row() {
            Column()
              .width(40)
              .height(4)
              .backgroundColor('#CCC')
              .borderRadius(2)
          }
          .width('100%')
          .height(24)
          .justifyContent(FlexAlign.Center)
          .onClick(() => this.toggleSheet())

          // Sheet content
          Scroll() {
            Column() {
              Row() {
                Text('Location Info')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                Blank()
                Text(`${this.clickCount} moves`)
                  .fontSize(11)
                  .fontColor('#999')
              }
              .width('100%')

              Row() {
                Text('Lat:').fontSize(12).fontColor('#666').width(40)
                Text(this.lat.toFixed(6)).fontSize(12).fontFamily('monospace')
              }
              .width('100%')
              .margin({ top: 4 })
              Row() {
                Text('Lng:').fontSize(12).fontColor('#666').width(40)
                Text(this.lng.toFixed(6)).fontSize(12).fontFamily('monospace')
              }
              .width('100%')
              Row() {
                Text('Zoom:').fontSize(12).fontColor('#666').width(40)
                Text(this.zoom.toFixed(2)).fontSize(12).fontFamily('monospace')
              }
              .width('100%')

              Text('Quick Locations')
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .width('100%')
                .margin({ top: 8, bottom: 4 })

              Row() {
                Button('Beijing').height(30).layoutWeight(1)
                  .fontSize(11)
                  .onClick(() => this.jumpToLocation(39.9042, 116.4074, 'Beijing'))
                Button('Shanghai').height(30).layoutWeight(1).margin({ left: 4 })
                  .fontSize(11)
                  .onClick(() => this.jumpToLocation(31.2304, 121.4737, 'Shanghai'))
                Button('Hangzhou').height(30).layoutWeight(1).margin({ left: 4 })
                  .fontSize(11)
                  .onClick(() => this.jumpToLocation(30.2741, 120.1551, 'Hangzhou'))
              }
              .width('100%')

              Row() {
                Button('Zoom In').height(30).layoutWeight(1).margin({ top: 4 })
                  .fontSize(11)
                  .onClick(() => {
                    if (!this.mapController) return;
                    this.mapController.setZoom(this.mapController.getZoom() + 1);
                    this.refreshCameraData();
                    this.clickCount++;
                  })
                Button('Zoom Out').height(30).layoutWeight(1).margin({ top: 4, left: 4 })
                  .fontSize(11)
                  .onClick(() => {
                    if (!this.mapController) return;
                    this.mapController.setZoom(this.mapController.getZoom() - 1);
                    this.refreshCameraData();
                    this.clickCount++;
                  })
              }
              .width('100%')
            }
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 16 })
          }
          .layoutWeight(1)
        }
        .width('100%')
        .height(this.sheetHeight)
        .backgroundColor(Color.White)
        .borderRadius({ topLeft: 16, topRight: 16 })
        .shadow({ radius: 12, color: 'rgba(0,0,0,0.15)', offsetY: -4 })
        .transition(TransitionEffect.opacity(300))
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.End)
      .hitTestBehavior(HitTestMode.Transparent)

      // Status badge
      Column() {
        Text(this.statusMessage)
          .fontSize(10)
          .fontColor(Color.White)
      }
      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      .backgroundColor('rgba(0,0,0,0.5)')
      .borderRadius(12)
      .position({ x: 12, y: 50 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  controlPanel() {
    Column() {
      Text('Bottom Sheet')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 8 })

      Text('A bottom sheet is shown over the map. Tap the handle to expand/collapse.')
        .fontSize(12)
        .fontColor('#666')
        .lineHeight(17)
        .width('100%')

      Button(this.sheetExpanded ? 'Collapse Sheet' : 'Expand Sheet')
        .width('100%')
        .margin({ top: 12 })
        .onClick(() => this.toggleSheet())
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Bottom Sheet',
      subtitle: 'Bottom sheet with a map',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
