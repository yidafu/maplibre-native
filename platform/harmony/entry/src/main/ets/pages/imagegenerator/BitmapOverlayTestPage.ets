/**
 * BitmapOverlayTestPage - Take a map snapshot and overlay a custom bitmap.
 *
 * Demonstrates how to take a map snapshot and apply a visual overlay
 * (watermark, border, or logo) on top of the snapshot result.
 * The overlay is composited using ArkTS Stack layout for visual
 * demonstration of the overlay concept.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapSnapshotter, MapSnapshot, SnapshotOptions, LatLng, CameraPosition } from 'maplibre_harmony';
import { SnapshotReadyCallbackImpl, SnapshotErrorHandlerImpl } from '../../utils/ListenerFactories';
import { DEFAULT_STYLE_URLS, TEST_LOCATIONS, showToast } from '../common/TestUtils';
import image from '@ohos.multimedia.image';

@Entry
@Component
struct BitmapOverlayTestPage {
  @State private snapshotPixelMap: image.PixelMap | undefined = undefined;
  @State private isCapturing: boolean = false;
  @State private hasSnapshot: boolean = false;
  @State private showOverlay: boolean = true;
  @State private overlayType: string = 'Watermark';
  @State private statusMessage: string = 'Ready';

  private snapshotter: MapSnapshotter | null = null;

  private readonly overlayTypes: string[] = ['Watermark', 'Border', 'Logo'];

  aboutToDisappear() {
    this.snapshotter?.cancel();
    this.snapshotter = null;
  }

  private async captureWithOverlay(): Promise<void> {
    if (this.isCapturing) return;

    this.snapshotter?.cancel();
    this.snapshotter = null;

    this.isCapturing = true;
    this.hasSnapshot = false;
    this.snapshotPixelMap = undefined;
    this.statusMessage = 'Capturing...';
    showToast('Capturing snapshot for overlay...');

    try {
      const cameraPosition: CameraPosition = {
        target: TEST_LOCATIONS.beijing,
        zoom: 10,
        bearing: 0,
        tilt: 0
      };

      const options: SnapshotOptions = {
        size: { width: 720, height: 480 },
        pixelRatio: 2.0,
        styleUrl: DEFAULT_STYLE_URLS.streets,
        cameraPosition: cameraPosition,
        showLogo: true
      };

      this.snapshotter = new MapSnapshotter(options);

      await new Promise<void>((resolve: () => void, reject: (reason: Error) => void): void => {
        this.snapshotter!.start(
          new SnapshotReadyCallbackImpl((snapshot: MapSnapshot): void => {
            this.snapshotPixelMap = snapshot.getImage();
            this.hasSnapshot = true;
            this.statusMessage = `Snapshot ready: ${snapshot.width}x${snapshot.height}`;
            showToast('Snapshot captured for overlay');
            resolve();
          }),
          new SnapshotErrorHandlerImpl((error: string): void => {
            this.statusMessage = `Error: ${error}`;
            showToast(`Snapshot failed: ${error}`);
            reject(new Error(error));
          })
        );
      });
    } catch (error) {
      console.error(`[BitmapOverlayTestPage] Failed: ${error}`);
      this.statusMessage = `Error: ${error}`;
    } finally {
      this.isCapturing = false;
    }
  }

  @Builder
  mapContent() {
    Column() {
      if (this.hasSnapshot && this.snapshotPixelMap) {
        // Stack the snapshot with the custom overlay on top
        Stack({ alignContent: Alignment.TopStart }) {
          // Base snapshot image
          Image(this.snapshotPixelMap)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)

          // Custom overlay (conditionally shown)
          if (this.showOverlay) {
            if (this.overlayType === 'Watermark') {
              this.WatermarkOverlay()
            } else if (this.overlayType === 'Border') {
              this.BorderOverlay()
            } else if (this.overlayType === 'Logo') {
              this.LogoOverlay()
            }
          }
        }
        .width('100%')
        .height('100%')
      } else {
        // Placeholder
        Column() {
          Text('Bitmap Overlay Demo')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')
            .margin({ bottom: 12 })

          Text('Capture a snapshot, then overlay a watermark, border, or logo')
            .fontSize(14)
            .fontColor('#666')
            .textAlign(TextAlign.Center)
            .padding({ left: 20, right: 20 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#F0F0F0')
      }
    }
    .width('100%')
    .height('100%')
  }

  /**
   * Watermark overlay — semi-transparent text at the bottom-right corner.
   */
  @Builder
  WatermarkOverlay() {
    Row() {
      Text(' Sample Watermark ')
        .fontSize(16)
        .fontColor('rgba(255, 255, 255, 0.7)')
        .backgroundColor('rgba(0, 0, 0, 0.4)')
        .borderRadius(4)
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
    }
    .width('100%')
    .height('100%')
    .alignItems(VerticalAlign.Bottom)
    .justifyContent(FlexAlign.End)
    .padding(16)
  }

  /**
   * Border overlay — colored border frame around the snapshot.
   */
  @Builder
  BorderOverlay() {
    Column() {
      // Top border
      Row()
        .width('100%')
        .height(4)
        .backgroundColor('#2196F3')
    }
    .width('100%')
    .height('100%')
    .border({ width: { left: 4, right: 4, bottom: 4 }, color: '#2196F3' })
  }

  /**
   * Logo overlay — a styled badge in the top-left corner.
   */
  @Builder
  LogoOverlay() {
    Row() {
      Row() {
        Text('ML')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .width(40)
      .height(40)
      .backgroundColor('#2196F3')
      .borderRadius(20)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .alignItems(VerticalAlign.Top)
    .justifyContent(FlexAlign.Start)
    .padding(16)
  }

  @Builder
  controlPanel() {
    Column() {
      // Status
      Text(this.statusMessage)
        .fontSize(14)
        .fontColor(this.hasSnapshot ? '#4CAF50' : '#FF9800')
        .width('100%')
        .padding(8)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      // Capture button
      Button(this.isCapturing ? 'Capturing...' : '1. Capture Snapshot')
        .width('100%')
        .margin({ top: 12 })
        .onClick(() => this.captureWithOverlay())
        .enabled(!this.isCapturing)

      // Overlay type selector
      if (this.hasSnapshot) {
        Text('2. Choose Overlay Type')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ top: 12, bottom: 8 })

        Row() {
          ForEach(this.overlayTypes, (type: string) => {
            Button(type)
              .layoutWeight(1)
              .margin({ left: 2, right: 2 })
              .backgroundColor(this.overlayType === type ? '#2196F3' : '#9E9E9E')
              .fontSize(13)
              .onClick(() => {
                this.overlayType = type;
                this.showOverlay = true;
                showToast(`Overlay: ${type}`);
              })
          })
        }
        .width('100%')

        // Toggle overlay visibility
        Row() {
          Button(`Overlay: ${this.showOverlay ? 'ON' : 'OFF'}`)
            .width('100%')
            .margin({ top: 8 })
            .backgroundColor(this.showOverlay ? '#4CAF50' : '#F44336')
            .fontColor(Color.White)
            .onClick(() => {
              this.showOverlay = !this.showOverlay;
              showToast(`Overlay ${this.showOverlay ? 'shown' : 'hidden'}`);
            })
        }
        .width('100%')

        // Capture again
        Button('3. Retake with Overlay')
          .width('100%')
          .margin({ top: 8 })
          .onClick(() => this.captureWithOverlay())
          .enabled(!this.isCapturing)

        Divider()
          .margin({ top: 12 })

        Text('Notes:')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .width('100%')

        Text('Overlays are composited via ArkTS Stack layout on top of the snapshot Image component.')
          .fontSize(12)
          .fontColor('#666')
          .width('100%')
          .margin({ top: 4 })

        Text('In production, use SnapshotOverlay or image drawing API to permanently render overlays into the pixel buffer.')
          .fontSize(12)
          .fontColor('#666')
          .width('100%')
          .margin({ top: 4 })
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Bitmap Overlay',
      subtitle: 'Overlay watermark and border on snapshot',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
