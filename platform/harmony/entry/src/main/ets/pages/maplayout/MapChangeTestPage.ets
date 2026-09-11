/**
 * MapChangeTestPage - Observe map move/resize events.
 *
 * Registers camera change listeners (willChange, isChanging, didChange, idle)
 * and displays real-time updates for map center, zoom, bearing, pitch.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, CameraState } from 'maplibre_harmony';
import { CameraIdleListener } from '../../utils/ListenerFactories';
import { showToast } from '../common/TestUtils';

@Entry
@Component
struct MapChangeTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Ready';
  @State private cameraState: CameraState = { bearing: 0, latitude: 30.27, longitude: 120.16, zoom: 8, pitch: 0 };
  @State private eventLog: string[] = [];
  @State private listenerActive: boolean = false;

  private readonly MAX_LOG: number = 15;

  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.removeAllListeners();
      this.mapController.destroy();
    }
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.addLog('MapLibreMap ready');
    this.toggleListener();
  };

  private toggleListener(): void {
    if (!this.mapController) return;
    if (this.listenerActive) {
      this.addLog('Listener disabled');
      this.listenerActive = false;
      this.statusMessage = 'Listeners off';
    } else {
      this.mapController.addOnCameraWillChangeListener((animated: boolean) => {
        this.addLog(`Camera will change (animated=${animated})`);
      });

      this.mapController.addOnCameraIsChangingListener(() => {
        if (this.mapController) {
          this.cameraState = this.mapController.getCameraState();
        }
      });

      this.mapController.addOnCameraDidChangeListener((animated: boolean) => {
        this.addLog(`Camera did change (animated=${animated})`);
        if (this.mapController) {
          this.cameraState = this.mapController.getCameraState();
        }
      });

      this.mapController.addOnCameraIdleListener(new CameraIdleListener(
        (): void => {
          this.addLog('Camera idle');
        }
      ));

      this.listenerActive = true;
      this.addLog('All camera change listeners registered');
      this.statusMessage = 'Listeners active';
      showToast('Camera change listeners enabled');
    }
  }

  private addLog(msg: string): void {
    const t = new Date().toLocaleTimeString();
    this.eventLog = [`[${t}] ${msg}`, ...this.eventLog].slice(0, this.MAX_LOG);
  }

  private refreshState(): void {
    if (!this.mapController) return;
    this.cameraState = this.mapController.getCameraState();
    this.addLog('Camera state refreshed');
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
      Text('Camera State')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 6 })

      Column() {
        this.buildRow('Lat', this.cameraState.latitude.toFixed(4))
        this.buildRow('Lng', this.cameraState.longitude.toFixed(4))
        this.buildRow('Zoom', this.cameraState.zoom.toFixed(2))
        this.buildRow('Bearing', `${this.cameraState.bearing.toFixed(1)} deg`)
        this.buildRow('Pitch', `${this.cameraState.pitch.toFixed(1)} deg`)
      }
      .width('100%')
      .padding(8)
      .backgroundColor('#E3F2FD')
      .borderRadius(6)

      Row() {
        Button(this.listenerActive ? 'Disable Listeners' : 'Enable Listeners')
          .height(36)
          .layoutWeight(1)
          .backgroundColor(this.listenerActive ? '#FF5722' : '#4CAF50')
          .onClick(() => this.toggleListener())
        Button('Refresh')
          .height(36)
          .layoutWeight(1)
          .margin({ left: 6 })
          .enabled(this.isMapReady)
          .onClick(() => this.refreshState())
      }
      .width('100%')
      .margin({ top: 8 })

      Text('Event Log')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })

      Column() {
        ForEach(this.eventLog, (line: string) => {
          Text(line)
            .fontSize(9)
            .fontFamily('monospace')
            .fontColor('#333')
            .lineHeight(15)
            .width('100%')
        }, (line: string) => line)
      }
      .width('100%')
      .height(160)
      .padding(6)
      .backgroundColor('#F5F5F5')
      .borderRadius(6)

      Text('Drag, zoom, or rotate the map to trigger change events.')
        .fontSize(10)
        .fontColor('#999')
        .width('100%')
        .margin({ top: 6 })
    }
    .width('100%')
  }

  @Builder
  buildRow(label: string, value: string) {
    Row() {
      Text(label).fontSize(12).fontColor('#1565C0').fontWeight(FontWeight.Bold).width(55)
      Text(value).fontSize(12).fontFamily('monospace').fontColor('#333').layoutWeight(1)
    }
    .width('100%')
    .height(22)
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Map Change',
      subtitle: 'Observe camera move/resize events',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
