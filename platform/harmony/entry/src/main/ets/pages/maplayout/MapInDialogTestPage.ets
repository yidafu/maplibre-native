/**
 * MapInDialogTestPage - Embed a map inside a dialog.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { showToast } from '../common/TestUtils';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct MapInDialogTestPage {
  private mapController: MapLibreMap | null = null;
  private dialogMapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private dialogOpen: boolean = false;
  @State private statusMessage: string = 'Ready';

  aboutToDisappear() {
    this.cleanupDialogMap();
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready';
  };

  private onDialogMapReady = (map: MapLibreMap): void => {
    this.dialogMapController = map;
    this.statusMessage = 'Dialog map ready';
    showToast('Map inside dialog is ready');
  };

  private cleanupDialogMap(): void {
    this.dialogMapController?.destroy();
    this.dialogMapController = null;
  }

  private showDialogWithMap(): void {
    if (this.dialogOpen) return;
    this.dialogOpen = true;
    this.statusMessage = 'Dialog opened with embedded map';
    showToast('Dialog with map opened');
  }

  private closeDialog(): void {
    this.cleanupDialogMap();
    this.dialogOpen = false;
    this.statusMessage = 'Dialog closed. Map inside dialog cleaned up.';
  }

  private zoomDialogMap(zoomIn: boolean): void {
    if (!this.dialogMapController) return;
    const z = this.dialogMapController.getZoom();
    this.dialogMapController.setZoom(zoomIn ? z + 1 : z - 1);
  }

  @Builder
  mapContent() {
    MapView({
      onMapReady: this.onMapReady,
    })
      .width('100%')
      .height('100%')
  }

  @Builder
  controlPanel() {
    Column() {
      Text(this.statusMessage)
        .fontSize(13)
        .fontColor('#333')
        .width('100%')
        .padding(10)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      Text('Dialog Map Controls')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Button('Open Map Dialog')
        .width('100%')
        .height(44)
        .enabled(this.isMapReady && !this.dialogOpen)
        .onClick(() => this.showDialogWithMap())

      if (this.dialogOpen) {
        Button('Close Dialog')
          .width('100%')
          .margin({ top: 8 })
          .height(44)
          .backgroundColor('#F44336')
          .onClick(() => this.closeDialog())

        Row() {
          Button('Zoom In').layoutWeight(1).height(36).margin({ top: 8 })
            .onClick(() => this.zoomDialogMap(true))
          Button('Zoom Out').layoutWeight(1).height(36).margin({ top: 8, left: 8 })
            .onClick(() => this.zoomDialogMap(false))
        }
        .width('100%')
      }

      Button('Show Info Dialog')
        .width('100%')
        .margin({ top: 12 })
        .height(36)
        .onClick(() => {
          promptAction.showDialog({
            title: 'Map Demo',
            message: 'This is a standard promptAction dialog (not embedding a map).',
            buttons: [{ text: 'OK', color: '#2196F3' }]
          });
        })
    }
    .width('100%')
  }

  @Builder
  dialogContent() {
    Column() {
      Row() {
        Text('Map Dialog')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        Blank()
        Button({ type: ButtonType.Normal }) {
          Text('X').fontSize(18).fontColor('#666')
        }
        .backgroundColor(Color.Transparent)
        .width(36)
        .height(36)
        .onClick(() => this.closeDialog())
      }
      .width('100%')
      .padding({ left: 16, right: 8, top: 8 })

      Text('This map is embedded inside a dialog overlay.')
        .fontSize(11)
        .fontColor('#999')
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 8 })

      MapView({
        onMapReady: this.onDialogMapReady,
        initialLatitude: 48.8566,
        initialLongitude: 2.3522,
        initialZoom: 10,
      })
        .width('100%')
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }

  build() {
    Stack() {
      TestPageLayout({
        title: 'Map In Dialog',
        subtitle: 'Embed a map inside a dialog',
        mapContent: (): void => this.mapContent(),
        controlPanel: (): void => this.controlPanel(),
      })

      // Dialog overlay
      if (this.dialogOpen) {
        Column() {
          Column() {
            this.dialogContent()
          }
          .width('80%')
          .height('60%')
          .backgroundColor(Color.White)
          .borderRadius(12)
          .shadow({ radius: 20, color: 'rgba(0,0,0,0.3)' })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => this.closeDialog())
        .hitTestBehavior(HitTestMode.Block)
      }
    }
    .width('100%')
    .height('100%')
  }
}
