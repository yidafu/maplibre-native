/**
 * MapSnapshotterTestPage - Use MapSnapshotter API with custom camera configuration.
 *
 * Creates a standalone MapSnapshotter with custom camera position (center, zoom, size),
 * retrieves the snapshot, and displays it in an Image component.
 * Allows retaking with different settings via location and zoom controls.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapSnapshotter, MapSnapshot, SnapshotOptions, LatLng, CameraPosition } from 'maplibre_harmony';
import { SnapshotReadyCallbackImpl, SnapshotErrorHandlerImpl } from '../../utils/ListenerFactories';
import { DEFAULT_STYLE_URLS, TEST_LOCATIONS, showToast } from '../common/TestUtils';
import image from '@ohos.multimedia.image';

interface LocationItem {
  name: string;
  latLng: LatLng;
}

@Entry
@Component
struct MapSnapshotterTestPage {
  @State private snapshotPixelMap: image.PixelMap | undefined = undefined;
  @State private isCapturing: boolean = false;
  @State private hasSnapshot: boolean = false;
  @State private zoomLevel: number = 10;
  @Watch('onLocationChanged') @State private selectedLocation: string = 'Beijing';
  @State private targetLatLng: LatLng = TEST_LOCATIONS.beijing;
  @State private statusMessage: string = 'Configure settings and take a snapshot';
  @State private snapshotWidth: number = 0;
  @State private snapshotHeight: number = 0;

  private snapshotter: MapSnapshotter | null = null;
  private readonly locations: LocationItem[] = [
    { name: 'Beijing', latLng: TEST_LOCATIONS.beijing },
    { name: 'Shanghai', latLng: TEST_LOCATIONS.shanghai },
    { name: 'London', latLng: TEST_LOCATIONS.london },
    { name: 'NYC', latLng: TEST_LOCATIONS.nyc },
    { name: 'Tokyo', latLng: TEST_LOCATIONS.tokyo },
  ];

  aboutToDisappear() {
    this.snapshotter?.cancel();
    this.snapshotter = null;
  }

  private onLocationChanged(): void {
    const found: LocationItem | undefined = this.locations.find((l: LocationItem): boolean => l.name === this.selectedLocation);
    this.targetLatLng = found ? found.latLng : TEST_LOCATIONS.beijing;
  }

  private getSelectedLatLng(): LatLng {
    const found: LocationItem | undefined = this.locations.find((l: LocationItem): boolean => l.name === this.selectedLocation);
    return found ? found.latLng : TEST_LOCATIONS.beijing;
  }

  private async takeSnapshot(): Promise<void> {
    if (this.isCapturing) return;

    // Cancel any previous snapshotter session
    this.snapshotter?.cancel();
    this.snapshotter = null;

    this.isCapturing = true;
    this.hasSnapshot = false;
    this.snapshotPixelMap = undefined;
    this.statusMessage = 'Generating snapshot...';
    showToast('Starting snapshotter...');

    try {
      const target: LatLng = this.getSelectedLatLng();

      const cameraPosition: CameraPosition = {
        target: target,
        zoom: this.zoomLevel,
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

      // Create a new MapSnapshotter instance for each capture
      this.snapshotter = new MapSnapshotter(options);

      await new Promise<void>((resolve, reject) => {
        this.snapshotter!.start(
          new SnapshotReadyCallbackImpl((snapshot: MapSnapshot) => {
            this.snapshotPixelMap = snapshot.getImage();
            this.snapshotWidth = snapshot.width;
            this.snapshotHeight = snapshot.height;
            this.hasSnapshot = true;
            this.statusMessage = `Snapshot ready: ${snapshot.width}x${snapshot.height}`;
            showToast(`Snapshot: ${this.selectedLocation} @ zoom ${this.zoomLevel}`);
            resolve();
          }),
          new SnapshotErrorHandlerImpl((error: string) => {
            this.statusMessage = `Error: ${error}`;
            showToast(`Snapshot failed: ${error}`);
            reject(new Error(error));
          })
        );
      });
    } catch (error) {
      console.error(`[MapSnapshotterTestPage] Failed: ${error}`);
      this.statusMessage = `Error: ${error}`;
    } finally {
      this.isCapturing = false;
    }
  }

  @Builder
  mapContent() {
    // MapSnapshotter works standalone — no live MapView needed
    Column() {
      if (this.hasSnapshot && this.snapshotPixelMap) {
        // Show the snapshot result
        Image(this.snapshotPixelMap)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Contain)
      } else {
        // Placeholder while no snapshot is available
        Column() {
          Text('MapSnapshotter Demo')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')
            .margin({ bottom: 12 })

          Text('Generates map images off-thread')
            .fontSize(14)
            .fontColor('#666')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 8 })

          Text('Configure camera settings below')
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

      // Location selector
      Text('Location')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 6 })

      Row() {
        ForEach(this.locations, (loc: LocationItem) => {
          Button(loc.name)
            .layoutWeight(1)
            .margin({ left: 2, right: 2 })
            .fontSize(12)
            .backgroundColor(this.selectedLocation === loc.name ? '#2196F3' : '#9E9E9E')
            .onClick(() => {
              this.selectedLocation = loc.name;
            })
        })
      }
      .width('100%')

      // Custom camera: target coords and zoom
      Text(`Target: ${this.targetLatLng.latitude.toFixed(4)}, ${this.targetLatLng.longitude.toFixed(4)}`)
        .fontSize(12)
        .fontColor('#666')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 8 })

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

      Text(`Camera config: center=(${this.targetLatLng.latitude.toFixed(2)}, ${this.targetLatLng.longitude.toFixed(2)}), zoom=${this.zoomLevel}, size=720x480`)
        .fontSize(11)
        .fontColor('#999')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 8 })

      // Capture button
      Button(this.isCapturing ? 'Generating...' : 'Take Snapshot')
        .width('100%')
        .margin({ top: 12 })
        .onClick(() => this.takeSnapshot())
        .enabled(!this.isCapturing)
        .backgroundColor(this.isCapturing ? '#FF9800' : '#2196F3')

      if (this.hasSnapshot) {
        Text(`Snapshot: ${this.snapshotWidth} x ${this.snapshotHeight} @ ${this.zoomLevel.toFixed(0)} zoom`)
          .fontSize(12)
          .fontColor('#666')
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 4 })
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Map Snapshotter',
      subtitle: 'Off-thread snapshot with custom camera',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
