/**
 * PerformanceTestPage - Monitor frame rate and rendering performance.
 *
 * Displays real-time FPS counter, frame timing statistics, and memory
 * pressure information. Provides controls to enable rendering stats,
 * toggle debug overlays, and simulate low-memory conditions.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import {
  MapView, MapLibreMap, MapDebugOptions, RenderingStats,
  OnDidFinishRenderingFrameWithStatsListener
} from 'maplibre_harmony';
import { showToast, TEST_LOCATIONS } from '../common/TestUtils';

@Entry
@Component
struct PerformanceTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';

  // FPS tracking
  @State private currentFps: number = 0;
  @State private avgFps: number = 0;
  @State private minFps: number = 999;
  @State private maxFps: number = 0;
  private fpsSamples: number[] = [];
  private fpsAccumulator: number = 0;
  private fpsSampleCount: number = 0;
  private lastFrameTime: number = 0;
  private fpsIntervalId: number | null = null;

  // Rendering stats
  @State private statsEnabled: boolean = false;
  @State private lastFrameEncodeTime: string = '--';
  @State private lastFrameRenderTime: string = '--';
  @State private lastFrameDrawableTime: string = '--';

  // Debug options
  @State private tileBoundaries: boolean = false;
  @State private overdraw: boolean = false;

  // Monitoring state
  @State private monitoringActive: boolean = false;
  @State private elapsedSeconds: number = 0;
  private monitorIntervalId: number | null = null;
  private startTime: number = 0;

  aboutToDisappear() {
    this.stopMonitoring();
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready. Start monitoring to track FPS.';
    console.info('[PerformanceTestPage] Map ready');
  };

  // ----- FPS Monitoring -----

  private startMonitoring(): void {
    if (!this.mapController || this.monitoringActive) return;
    this.monitoringActive = true;
    this.fpsSamples = [];
    this.fpsAccumulator = 0;
    this.fpsSampleCount = 0;
    this.minFps = 999;
    this.maxFps = 0;
    this.startTime = new Date().getTime();
    this.elapsedSeconds = 0;

    // Register a per-frame stats listener
    this.mapController.addOnDidFinishRenderingFrameWithStatsListener(this.frameStatsListener);

    // Poll FPS and elapsed time every 500ms
    this.fpsIntervalId = setInterval((): void => {
      if (!this.mapController || !this.monitoringActive) {
        this.stopMonitoring();
        return;
      }
      this.updateFpsDisplay();
    }, 500);

    // Update elapsed time every second
    this.monitorIntervalId = setInterval((): void => {
      if (!this.monitoringActive) return;
      this.elapsedSeconds = Math.floor((new Date().getTime() - this.startTime) / 1000);
    }, 1000);

    this.statusMessage = 'Monitoring active...';
    showToast('Performance monitoring started');
  }

  private stopMonitoring(): void {
    this.monitoringActive = false;

    if (this.fpsIntervalId !== null) {
      clearInterval(this.fpsIntervalId);
      this.fpsIntervalId = null;
    }
    if (this.monitorIntervalId !== null) {
      clearInterval(this.monitorIntervalId);
      this.monitorIntervalId = null;
    }

    // Remove stats listener
    if (this.mapController) {
      try {
        this.mapController.removeOnDidFinishRenderingFrameWithStatsListener(this.frameStatsListener);
      } catch (e) {
        console.warn('[PerformanceTestPage] Error removing stats listener:', e);
      }
    }

    this.statusMessage = 'Monitoring stopped';
    showToast('Monitoring stopped');
  }

  private frameStatsListener: OnDidFinishRenderingFrameWithStatsListener = (stats: RenderingStats): void => {
      const now = new Date().getTime();
      if (this.lastFrameTime > 0) {
        const deltaMs = now - this.lastFrameTime;
        if (deltaMs > 0) {
          const fps = 1000 / deltaMs;
          this.fpsAccumulator += fps;
          this.fpsSampleCount++;
          if (fps < this.minFps) this.minFps = fps;
          if (fps > this.maxFps) this.maxFps = fps;
        }
      }
      this.lastFrameTime = now;

      // Extract frame timing data
      this.lastFrameEncodeTime = stats.frameEncodingTime.toFixed(1);
      this.lastFrameRenderTime = stats.frameRenderingTime.toFixed(1);
  };

  private updateFpsDisplay(): void {
    if (this.fpsSampleCount > 0) {
      this.currentFps = Math.round(this.fpsAccumulator / this.fpsSampleCount);
      this.avgFps = this.currentFps;
      // Reset accumulator for next window
      this.fpsAccumulator = 0;
      this.fpsSampleCount = 0;
    }
  }

  // ----- Debug Toggles -----

  private toggleTileBoundaries(): void {
    if (!this.mapController) return;
    this.tileBoundaries = !this.tileBoundaries;
    let options: number = MapDebugOptions.NoDebug;
    if (this.tileBoundaries) {
      options |= MapDebugOptions.TileBoundaries;
    }
    if (this.overdraw) {
      options |= MapDebugOptions.OverdrawVisualization;
    }
    this.mapController.setDebugOptions(options);
    showToast(`Tile boundaries: ${this.tileBoundaries}`);
  }

  private toggleOverdraw(): void {
    if (!this.mapController) return;
    this.overdraw = !this.overdraw;
    let options: number = MapDebugOptions.NoDebug;
    if (this.tileBoundaries) {
      options |= MapDebugOptions.TileBoundaries;
    }
    if (this.overdraw) {
      options |= MapDebugOptions.OverdrawVisualization;
    }
    this.mapController.setDebugOptions(options);
    showToast(`Overdraw: ${this.overdraw}`);
  }

  private toggleStatsView(): void {
    if (!this.mapController) return;
    this.statsEnabled = !this.statsEnabled;
    this.mapController.enableRenderingStatsView(this.statsEnabled);
    showToast(`Rendering stats view: ${this.statsEnabled}`);
  }

  private simulateLowMemory(): void {
    if (!this.mapController) return;
    this.mapController.onLowMemory();
    showToast('Low memory signal sent');
  }

  private clearStats(): void {
    this.fpsSamples = [];
    this.currentFps = 0;
    this.avgFps = 0;
    this.minFps = 999;
    this.maxFps = 0;
    this.lastFrameEncodeTime = '--';
    this.lastFrameRenderTime = '--';
    this.lastFrameDrawableTime = '--';
    this.statusMessage = 'Stats cleared';
    showToast('Stats cleared');
  }

  @Builder
  mapContent() {
    MapView({
      onMapReady: this.onMapReady,
      styleUrl: 'https://demotiles.maplibre.org/style.json',
      initialLatitude: TEST_LOCATIONS.hangzhou.latitude,
      initialLongitude: TEST_LOCATIONS.hangzhou.longitude,
      initialZoom: 5,
    })
      .width('100%')
      .height('100%')
  }

  @Builder
  controlPanel() {
    Column() {
      Text(this.statusMessage)
        .fontSize(14)
        .fontColor(this.isMapReady ? (this.monitoringActive ? '#FF9800' : '#4CAF50') : '#FF9800')
        .width('100%')
        .padding(12)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      Text('Performance Monitor')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      // Monitoring controls
      Row() {
        Button(this.monitoringActive ? 'Stop Monitoring' : 'Start Monitoring')
          .width('60%')
          .backgroundColor(this.monitoringActive ? '#E53935' : '#4CAF50')
          .onClick((): void => {
            if (this.monitoringActive) {
              this.stopMonitoring();
            } else {
              this.startMonitoring();
            }
          })
          .enabled(this.isMapReady)
        Button('Clear')
          .width('35%')
          .margin({ left: 8 })
          .onClick((): void => this.clearStats())
          .enabled(this.isMapReady)
      }
      .width('100%')

      // FPS Display
      if (this.monitoringActive || this.currentFps > 0) {
        Row() {
          Text('FPS:')
            .fontSize(14)
          Text(`${this.currentFps}`)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(
              this.currentFps >= 50 ? '#4CAF50' :
              this.currentFps >= 30 ? '#FF9800' : '#E53935'
            )
            .margin({ left: 8 })
          Blank()
          Text(`Min: ${this.minFps < 999 ? this.minFps.toFixed(0) : '--'}  Max: ${this.maxFps.toFixed(0)}`)
            .fontSize(12)
            .fontColor('#666')
        }
        .width('100%')
        .margin({ top: 4 })
      }

      // Frame timing
      Text(`Frame encode: ${this.lastFrameEncodeTime} ms  |  Render: ${this.lastFrameRenderTime} ms`)
        .fontSize(12)
        .fontColor('#666')
        .width('100%')
        .margin({ top: 4 })

      if (this.monitoringActive) {
        Text(`Elapsed: ${this.elapsedSeconds}s`)
          .fontSize(12)
          .fontColor('#666')
          .width('100%')
          .margin({ top: 2 })
      }

      // Debug & Options
      Text('Debug Options')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 4 })

      Row() {
        Text('Tile Boundaries:')
          .fontSize(13)
        Toggle({ type: ToggleType.Switch, isOn: this.tileBoundaries })
          .onChange((): void => this.toggleTileBoundaries())
          .enabled(this.isMapReady)
        Text('Overdraw:')
          .fontSize(13)
          .margin({ left: 12 })
        Toggle({ type: ToggleType.Switch, isOn: this.overdraw })
          .onChange((): void => this.toggleOverdraw())
          .enabled(this.isMapReady)
      }
      .width('100%')
      .margin({ top: 4 })

      Row() {
        Text('Stats View:')
          .fontSize(13)
        Toggle({ type: ToggleType.Switch, isOn: this.statsEnabled })
          .onChange((): void => this.toggleStatsView())
          .enabled(this.isMapReady)
      }
      .width('100%')
      .margin({ top: 2 })

      Button('Simulate Low Memory')
        .width('100%')
        .margin({ top: 8 })
        .backgroundColor('#FF9800')
        .onClick((): void => this.simulateLowMemory())
        .enabled(this.isMapReady)
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Performance',
      subtitle: 'Frame rate and memory monitoring',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
