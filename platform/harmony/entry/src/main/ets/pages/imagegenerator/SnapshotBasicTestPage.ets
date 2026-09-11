/**
 * SnapshotBasicTestPage - Take a static map snapshot and display it.
 *
 * Uses the MapLibreMap.snapshot() method to capture the current map view
 * and display the result in an Image component. Includes capture button,
 * snapshot preview, and status indicators.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { showToast } from '../common/TestUtils';
import image from '@ohos.multimedia.image';

@Entry
@Component
struct SnapshotBasicTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private snapshotPixelMap: image.PixelMap | undefined = undefined;
  @State private snapshotWidth: number = 0;
  @State private snapshotHeight: number = 0;
  @State private isCapturing: boolean = false;
  @State private hasSnapshot: boolean = false;
  @State private statusMessage: string = 'Loading...';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready — tap Capture to snapshot';
    console.info('[SnapshotBasicTestPage] Map ready');
  };

  private async captureSnapshot(): Promise<void> {
    if (!this.mapController || this.isCapturing) return;

    this.isCapturing = true;
    this.snapshotPixelMap = undefined;
    this.hasSnapshot = false;
    this.statusMessage = 'Capturing snapshot...';
    showToast('Capturing snapshot...');

    try {
      // snapshot() returns a Promise<PixelMap> of the current map view
      const pixelMap: image.PixelMap = await this.mapController.snapshot();
      this.snapshotPixelMap = pixelMap;

      const info = await pixelMap.getImageInfo();
      this.snapshotWidth = info.size.width;
      this.snapshotHeight = info.size.height;

      this.hasSnapshot = true;
      this.statusMessage = `Snapshot: ${this.snapshotWidth}x${this.snapshotHeight}`;
      showToast(`Snapshot captured: ${this.snapshotWidth}x${this.snapshotHeight}`);
      console.info(`[SnapshotBasicTestPage] Snapshot size: ${this.snapshotWidth}x${this.snapshotHeight}`);
    } catch (error) {
      console.error(`[SnapshotBasicTestPage] Snapshot failed: ${error}`);
      this.statusMessage = `Error: ${error}`;
      showToast(`Snapshot failed: ${error}`);
    } finally {
      this.isCapturing = false;
    }
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
      // Status message
      Text(this.statusMessage)
        .fontSize(14)
        .fontColor(this.hasSnapshot ? '#4CAF50' : this.isMapReady ? '#FF9800' : '#FF9800')
        .width('100%')
        .padding(8)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      // Capture button
      Button(this.isCapturing ? 'Capturing...' : 'Capture Snapshot')
        .width('100%')
        .margin({ top: 12 })
        .onClick(() => this.captureSnapshot())
        .enabled(this.isMapReady && !this.isCapturing)
        .backgroundColor(this.isCapturing ? '#FF9800' : '#2196F3')

      // Snapshot preview
      if (this.hasSnapshot && this.snapshotPixelMap) {
        Text('Snapshot Preview')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ top: 16, bottom: 8 })

        Image(this.snapshotPixelMap)
          .width('100%')
          .height(200)
          .objectFit(ImageFit.Contain)
          .borderRadius(6)
          .border({ width: 1, color: '#E0E0E0' })

        Text(`Size: ${this.snapshotWidth} x ${this.snapshotHeight}`)
          .fontSize(12)
          .fontColor('#666')
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 4 })

        // Retake button
        Button('Retake Snapshot')
          .width('100%')
          .margin({ top: 8 })
          .onClick(() => this.captureSnapshot())
          .enabled(!this.isCapturing)
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Snapshot Basic',
      subtitle: 'Static map snapshot capture',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
