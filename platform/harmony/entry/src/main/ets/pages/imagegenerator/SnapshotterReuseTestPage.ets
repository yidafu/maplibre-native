/**
 * SnapshotterReuseTestPage - Test snapshotter reuse across multiple captures.
 *
 * Creates a single MapSnapshotter instance and retakes snapshots with
 * different camera configurations, verifying snapshotter lifecycle works
 * across multiple capture invocations.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapSnapshotter, MapSnapshot, SnapshotOptions, LatLng, CameraPosition } from 'maplibre_harmony';
import { SnapshotReadyCallbackImpl, SnapshotErrorHandlerImpl } from '../../utils/ListenerFactories';
import { DEFAULT_STYLE_URLS, TEST_LOCATIONS, showToast } from '../common/TestUtils';
import image from '@ohos.multimedia.image';

@Entry
@Component
struct SnapshotterReuseTestPage {
  @State private snapshotPixelMap: image.PixelMap | undefined = undefined;
  @State private isCapturing: boolean = false;
  @State private hasSnapshot: boolean = false;
  @State private captureCount: number = 0;
  @State private zoomLevel: number = 10;
  @State private statusMessage: string = 'Ready';

  // Single snapshotter instance reused across captures
  private snapshotter: MapSnapshotter | null = null;
  private snapshotterInitialized: boolean = false;
  private readonly locations: LatLng[] = [
    TEST_LOCATIONS.beijing,
    TEST_LOCATIONS.shanghai,
    TEST_LOCATIONS.london,
    TEST_LOCATIONS.nyc,
  ];
  private locationIndex: number = 0;

  aboutToDisappear() {
    this.snapshotter?.cancel();
    this.snapshotter = null;
    this.snapshotterInitialized = false;
  }

  private getNextLatLng(): LatLng {
    const loc = this.locations[this.locationIndex % this.locations.length];
    this.locationIndex++;
    return loc;
  }

  private initializeSnapshotter(): void {
    if (this.snapshotterInitialized && this.snapshotter) return;

    // Initial options — will be reconfigured before each capture
    const options: SnapshotOptions = {
      size: { width: 640, height: 480 },
      pixelRatio: 1.5,
      styleUrl: DEFAULT_STYLE_URLS.bright,
      cameraPosition: {
        target: TEST_LOCATIONS.beijing,
        zoom: 8,
        bearing: 0,
        tilt: 0
      },
      showLogo: true
    };

    this.snapshotter = new MapSnapshotter(options);
    this.snapshotterInitialized = true;
    console.info('[SnapshotterReuseTestPage] Snapshotter created');
  }

  private async takeSnapshot(): Promise<void> {
    if (this.isCapturing) return;

    this.isCapturing = true;
    this.hasSnapshot = false;
    this.snapshotPixelMap = undefined;
    this.statusMessage = `Capture #${this.captureCount + 1}...`;
    showToast(`Capture #${this.captureCount + 1} starting`);

    try {
      // Initialize snapshotter only once — reuse for subsequent captures
      if (!this.snapshotterInitialized) {
        this.initializeSnapshotter();
      }

      // Reconfigure snapshotter for this capture
      const target: LatLng = this.getNextLatLng();
      const newZoom: number = this.zoomLevel;

      const newCameraPosition: CameraPosition = {
        target: target,
        zoom: newZoom,
        bearing: 0,
        tilt: 0
      };

      this.snapshotter!.setCameraPosition(newCameraPosition);

      console.info(`[SnapshotterReuseTestPage] Reconfigured: ${target.latitude}, ${target.longitude} @ zoom ${newZoom}`);

      // Start snapshot generation on the same snapshotter instance
      await new Promise<void>((resolve: () => void, reject: (reason: Error) => void): void => {
        this.snapshotter!.start(
          new SnapshotReadyCallbackImpl((snapshot: MapSnapshot): void => {
            this.snapshotPixelMap = snapshot.getImage();
            this.captureCount++;
            this.hasSnapshot = true;
            this.statusMessage = `Capture #${this.captureCount}: ${snapshot.width}x${snapshot.height}`;
            showToast(`Capture #${this.captureCount} ready`);
            console.info(`[SnapshotterReuseTestPage] Capture #${this.captureCount} completed`);
            resolve();
          }),
          new SnapshotErrorHandlerImpl((error: string): void => {
            this.statusMessage = `Error: ${error}`;
            showToast(`Capture ${this.captureCount + 1} failed: ${error}`);
            reject(new Error(error));
          })
        );
      });
    } catch (error) {
      console.error(`[SnapshotterReuseTestPage] Failed: ${error}`);
      this.statusMessage = `Error: ${error}`;
    } finally {
      this.isCapturing = false;
    }
  }

  private resetSnapshotter(): void {
    this.snapshotter?.cancel();
    this.snapshotter = null;
    this.snapshotterInitialized = false;
    this.captureCount = 0;
    this.hasSnapshot = false;
    this.snapshotPixelMap = undefined;
    this.locationIndex = 0;
    this.statusMessage = 'Snapshotter reset — tap to start fresh';
    showToast('Snapshotter reset');
  }

  @Builder
  mapContent() {
    Column() {
      if (this.hasSnapshot && this.snapshotPixelMap) {
        Image(this.snapshotPixelMap)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Contain)
      } else {
        Column() {
          Text('Snapshotter Reuse Demo')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')
            .margin({ bottom: 12 })

          Text('One snapshotter instance reused for multiple captures')
            .fontSize(14)
            .fontColor('#666')
            .textAlign(TextAlign.Center)
            .padding({ left: 20, right: 20 })
            .margin({ bottom: 8 })

          Text('Tap "Take Snapshot" multiple times to test reuse')
            .fontSize(14)
            .fontColor('#999')
            .textAlign(TextAlign.Center)
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

      // Lifecycle info
      Text(`Snapshotter state: ${this.snapshotterInitialized ? 'INITIALIZED' : 'NOT CREATED'}`)
        .fontSize(12)
        .fontColor(this.snapshotterInitialized ? '#4CAF50' : '#FF9800')
        .width('100%')
        .margin({ top: 8 })
        .textAlign(TextAlign.Center)

      Text(`Capture count: ${this.captureCount}`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 4 })
        .textAlign(TextAlign.Center)

      // Zoom slider
      Text(`Zoom: ${this.zoomLevel}`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12 })

      Slider({
        value: this.zoomLevel,
        min: 1,
        max: 18,
        step: 1
      })
        .width('100%')
        .onChange((value: number) => {
          this.zoomLevel = value;
        })

      // Capture buttons
      Row() {
        Button(this.isCapturing ? 'Busy...' : `Take Snapshot #${this.captureCount + 1}`)
          .layoutWeight(1)
          .height(40)
          .onClick(() => this.takeSnapshot())
          .enabled(!this.isCapturing)
          .backgroundColor(this.isCapturing ? '#FF9800' : '#2196F3')

        Button('Reset')
          .width(80)
          .height(40)
          .margin({ left: 8 })
          .backgroundColor('#F44336')
          .fontColor(Color.White)
          .onClick(() => this.resetSnapshotter())
          .enabled(!this.isCapturing)
      }
      .width('100%')
      .margin({ top: 12 })

      // Lifecycle notes
      Divider()
        .margin({ top: 12 })

      Text('Reuse lifecycle:')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      Text('1. Snapshotter created once on first capture')
        .fontSize(12)
        .fontColor('#666')
        .width('100%')

      Text('2. setCameraPosition() reconfigures for each capture')
        .fontSize(12)
        .fontColor('#666')
        .width('100%')

      Text('3. start() called multiple times on same instance')
        .fontSize(12)
        .fontColor('#666')
        .width('100%')

      Text('4. Reset destroys and recreates the snapshotter')
        .fontSize(12)
        .fontColor('#666')
        .width('100%')
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Snapshotter Reuse',
      subtitle: 'Reuse snapshotter across captures',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
