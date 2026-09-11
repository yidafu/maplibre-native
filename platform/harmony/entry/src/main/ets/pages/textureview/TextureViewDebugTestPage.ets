/**
 * TextureViewDebugTestPage - Debug information overlay on the map.
 *
 * Displays real-time map debug info such as camera state, FPS, tile info,
 * and rendering statistics overlaid on the map view.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MapDebugOptions, RenderingStats, CameraState } from 'maplibre_harmony';
import { DEFAULT_MAP_CONFIG, showToast } from '../common/TestUtils';

@Entry
@Component
struct TextureViewDebugTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private isDebugActive: boolean = false;
  @State private showInfoOverlay: boolean = false;
  @State private cameraInfo: string = '';
  @State private fps: number = 0;
  @State private frameTime: string = '';
  @State private tileInfo: string = '';
  @State private updateCounter: number = 0;

  private frameStatsListener: ((stats: RenderingStats) => void) | null = null;

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.startDebugOverlay();
    showToast('Debug overlay ready');
  };

  private startDebugOverlay(): void {
    if (!this.mapController) return;

    // Register a rendering frame stats listener
    this.frameStatsListener = (stats: RenderingStats): void => {
      // Calculate FPS from frame rendering time
      const renderTime = stats.frameRenderingTime || 0;
      this.fps = renderTime > 0 ? Math.min(Math.round(1000 / renderTime), 120) : 0;
      this.frameTime = 'E: ' + (stats.frameEncodingTime?.toFixed(1) || '0') +
        'ms R: ' + (stats.frameRenderingTime?.toFixed(1) || '0') + 'ms';
      this.updateCounter++;

      // Periodically update camera info (every 10 frames to reduce overhead)
      if (this.updateCounter % 10 === 0 && this.mapController) {
        const state = this.mapController.getCameraState();
        this.cameraInfo = 'Lat: ' + state.latitude.toFixed(4) +
          '\nLng: ' + state.longitude.toFixed(4) +
          '\nZoom: ' + state.zoom.toFixed(2) +
          '\nBearing: ' + state.bearing.toFixed(1) +
          '\nPitch: ' + state.pitch.toFixed(1);
      }
    };
    this.mapController.addOnDidFinishRenderingFrameWithStatsListener(this.frameStatsListener);
  }

  private toggleDebugVisuals(): void {
    if (!this.mapController) return;
    this.isDebugActive = !this.isDebugActive;
    this.mapController.setDebugActive(this.isDebugActive);
    showToast('Debug visuals: ' + (this.isDebugActive ? 'ON' : 'OFF'));
  }

  private toggleInfoOverlay(): void {
    this.showInfoOverlay = !this.showInfoOverlay;
    showToast('Info overlay: ' + (this.showInfoOverlay ? 'shown' : 'hidden'));
  }

  private enableStatsView(): void {
    if (!this.mapController) return;
    this.mapController.enableRenderingStatsView(true);
    showToast('Rendering stats view enabled');
  }

  private disableStatsView(): void {
    if (!this.mapController) return;
    this.mapController.enableRenderingStatsView(false);
    showToast('Rendering stats view disabled');
  }

  @Builder
  mapContent() {
    Stack() {
      MapView({
        onMapReady: this.onMapReady,
      })
        .width('100%')
        .height('100%')

      // Debug info overlay
      if (this.showInfoOverlay && this.cameraInfo) {
        Column() {
          Text('Camera State')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4CAF50')
            .margin({ bottom: 2 })
          Text(this.cameraInfo)
            .fontSize(10)
            .fontColor(Color.White)
            .lineHeight(14)
          Text('FPS: ' + this.fps.toFixed(1))
            .fontSize(11)
            .fontColor('#FF9800')
            .margin({ top: 4 })
          Text(this.frameTime)
            .fontSize(10)
            .fontColor('#FF9800')
          Text('Frame: #' + this.updateCounter)
            .fontSize(10)
            .fontColor('#999')
            .margin({ top: 2 })
        }
        .padding(8)
        .backgroundColor('rgba(0,0,0,0.7)')
        .borderRadius(6)
        .margin(8)
        .alignSelf(ItemAlign.Start)
        .constraintSize({ maxWidth: '60%' })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  controlPanel() {
    Column() {
      Text('TextureView Debug')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 8 })

      Text('Toggle debug overlays and view real-time map information.')
        .fontSize(12)
        .fontColor('#666')
        .width('100%')
        .margin({ bottom: 12 })

      Row() {
        Button(this.isDebugActive ? 'Debug: ON' : 'Debug: OFF')
          .fontSize(12)
          .backgroundColor(this.isDebugActive ? '#4CAF50' : '#9E9E9E')
          .layoutWeight(1)
          .margin({ right: 4 })
          .onClick(() => this.toggleDebugVisuals())
          .enabled(this.isMapReady)

        Button(this.showInfoOverlay ? 'Overlay: ON' : 'Overlay: OFF')
          .fontSize(12)
          .backgroundColor(this.showInfoOverlay ? '#2196F3' : '#9E9E9E')
          .layoutWeight(1)
          .margin({ left: 4 })
          .onClick(() => this.toggleInfoOverlay())
          .enabled(this.isMapReady)
      }
      .width('100%')
      .margin({ bottom: 8 })

      Row() {
        Button('Stats View ON')
          .fontSize(12)
          .layoutWeight(1)
          .margin({ right: 4 })
          .onClick(() => this.enableStatsView())
          .enabled(this.isMapReady)
        Button('Stats View OFF')
          .fontSize(12)
          .layoutWeight(1)
          .margin({ left: 4 })
          .onClick(() => this.disableStatsView())
          .enabled(this.isMapReady)
      }
      .width('100%')

      Text('FPS: ' + this.fps.toFixed(1) + '  Frame: #' + this.updateCounter)
        .fontSize(12)
        .fontColor('#666')
        .width('100%')
        .margin({ top: 12 })
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'TextureView Debug',
      subtitle: 'Debug overlay with camera, FPS, and frame stats',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
