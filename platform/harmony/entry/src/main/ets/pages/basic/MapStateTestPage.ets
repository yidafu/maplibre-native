/**
 * MapStateTestPage - Monitor map lifecycle and state changes.
 *
 * Registers lifecycle listeners: willStartLoadingMap, didFinishLoadingMap,
 * didFailLoadingMap, didFinishRenderingMap, didBecomeIdle.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, CameraState } from 'maplibre_harmony';
import { showToast } from '../common/TestUtils';

@Entry
@Component
struct MapStateTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private isFullyLoaded: boolean = false;
  @State private stateLog: string[] = [];
  @State private zoom: number = 0;
  @State private pitch: number = 0;
  @State private bearing: number = 0;

  private readonly MAX_LOG_LINES: number = 20;

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.addLog('MapLibreMap ready callback');
    this.refreshState();

    map.addOnWillStartLoadingMapListener((): void => {
      this.addLog('Event: willStartLoadingMap');
    });

    map.addOnDidFinishLoadingMapListener((): void => {
      this.addLog('Event: didFinishLoadingMap');
      this.isFullyLoaded = true;
      this.statusMessage = 'Map fully loaded';
    });

    map.addOnDidFailLoadingMapListener((): void => {
      this.addLog('Event: didFailLoadingMap');
      this.statusMessage = 'Map failed to load';
    });

    map.addOnDidFinishRenderingMapListener((): void => {
      this.addLog('Event: didFinishRenderingMap');
    });

    map.addOnDidBecomeIdleListener((): void => {
      this.addLog('Event: didBecomeIdle');
    });

    this.addLog('All lifecycle listeners registered');
  };

  private addLog(message: string): void {
    const time: string = new Date().toLocaleTimeString();
    this.stateLog = [`[${time}] ${message}`, ...this.stateLog].slice(0, this.MAX_LOG_LINES);
  }

  private refreshState(): void {
    if (!this.mapController) return;
    const state: CameraState = this.mapController.getCameraState();
    this.zoom = state.zoom;
    this.pitch = state.pitch;
    this.bearing = state.bearing;
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
      Text('Live Log')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 8 })

      Column() {
        ForEach(this.stateLog, (log: string): void => {
          Text(log)
            .fontSize(10)
            .fontFamily('monospace')
            .fontColor('#333')
            .lineHeight(16)
            .width('100%')
        }, (log: string): string => log)
      }
      .width('100%')
      .height(180)
      .padding(8)
      .backgroundColor('#F5F5F5')
      .borderRadius(6)

      Row() {
        Button('Check Full Load')
          .height(36)
          .layoutWeight(1)
          .enabled(this.isMapReady)
          .onClick((): void => {
            if (!this.mapController) return;
            const loaded: boolean = this.mapController.isFullyLoaded();
            this.statusMessage = loaded ? 'Fully loaded' : 'Not fully loaded';
            this.addLog(`isFullyLoaded() = ${loaded}`);
            this.isFullyLoaded = loaded;
          })
        Button('Check Style Loaded')
          .height(36)
          .margin({ left: 6 })
          .layoutWeight(1)
          .enabled(this.isMapReady)
          .onClick((): void => {
            if (!this.mapController) return;
            const loaded: boolean = this.mapController.isStyleLoaded();
            this.addLog(`isStyleLoaded() = ${loaded}`);
          })
      }
      .width('100%')
      .margin({ top: 8 })

      Row() {
        Button('Get Camera State')
          .height(36)
          .layoutWeight(1)
          .enabled(this.isMapReady)
          .onClick((): void => {
            this.refreshState();
            this.addLog(`getCameraState: z=${this.zoom.toFixed(2)} p=${this.pitch.toFixed(1)} b=${this.bearing.toFixed(1)}`);
          })
        Button('Clear Log')
          .height(36)
          .margin({ left: 6 })
          .layoutWeight(1)
          .onClick((): void => {
            this.stateLog = [];
            this.statusMessage = 'Log cleared';
          })
      }
      .width('100%')
      .margin({ top: 6 })

      Button('Trigger Repaint')
        .width('100%')
        .margin({ top: 6 })
        .enabled(this.isMapReady)
        .onClick((): void => {
          this.mapController?.triggerRepaint();
          this.addLog('triggerRepaint() called');
          showToast('Repaint triggered');
        })

      Text(`Zoom: ${this.zoom.toFixed(2)}  |  Pitch: ${this.pitch.toFixed(1)}  |  Bearing: ${this.bearing.toFixed(1)}`)
        .fontSize(11)
        .fontColor('#999')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 8 })
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Map State',
      subtitle: 'Monitor map lifecycle and state',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
