/**
 * RenderingStatsView - rendering statistics overlay.
 *
 * Built-in debug ornament mirroring Android's FpsChangedListener-based debug
 * overlays and the iOS MLNMapView debugging masks: shows the measured frame
 * rate plus the per-frame encoding/rendering times reported through
 * OnDidFinishRenderingFrameWithStatsListener.
 *
 * The widget registers its own listeners on the supplied MapLibreMap and
 * removes them when it disappears. Place it on top of the map (e.g. inside a
 * Stack) and position it with .position() / .align().
 *
 * Example:
 *   Stack() {
 *     MapLibreMap(...)
 *     RenderingStatsView({ map: this.map })
 *       .position({ x: 12, y: 12 })
 *   }
 */

import { MapLibreMap } from '../MapLibreMap';
import { RenderingStats } from '../renderer/RenderingStats';
import { OnFpsChangedListener } from '../listeners/OnFpsChangedListener';
import { OnDidFinishRenderingFrameWithStatsListener } from '../listeners/MapEventListeners';

// Default window over which frames are averaged before the text updates.
const DEFAULT_UPDATE_INTERVAL_MS = 250;

/**
 * Adapter turning OnFpsChangedListener into a plain callback. ArkTS strict
 * mode rejects untyped object literals, so the interface is implemented with
 * a class instead of a literal.
 */
class FpsListenerAdapter implements OnFpsChangedListener {
  private readonly handler: (fps: number) => void;

  constructor(handler: (fps: number) => void) {
    this.handler = handler;
  }

  onFpsChanged(fps: number): void {
    this.handler(fps);
  }
}

@Component
export struct RenderingStatsView {
  // Map instance to observe. Set once by the caller before the component
  // appears; a plain member is enough (listeners are wired in aboutToAppear).
  map: MapLibreMap | null = null;
  // Whether to show per-frame encoding/rendering times in addition to FPS.
  @Prop showFrameTimes: boolean = true;
  // Interval in milliseconds at which the displayed values are refreshed.
  @Prop updateIntervalMs: number = DEFAULT_UPDATE_INTERVAL_MS;

  // Displayed values.
  @State private fpsText: string = '-- FPS';
  @State private encodingText: string = '-- ms';
  @State private renderingText: string = '-- ms';

  // Listener wrappers kept so they can be removed on teardown.
  private fpsListener?: OnFpsChangedListener;
  private statsListener?: OnDidFinishRenderingFrameWithStatsListener;

  // FPS accumulation window.
  private sampleStartMs: number = 0;
  private frameCount: number = 0;
  // Latest frame times reported by the stats listener (ms).
  private lastEncodingMs: number = 0;
  private lastRenderingMs: number = 0;

  aboutToAppear(): void {
    if (!this.map) {
      return;
    }

    this.sampleStartMs = Date.now();
    this.frameCount = 0;

    this.fpsListener = new FpsListenerAdapter((fps: number): void => {
      this.onFpsSample(fps);
    });
    this.map.setOnFpsChangedListener(this.fpsListener);

    const statsListener: OnDidFinishRenderingFrameWithStatsListener =
      (stats: RenderingStats): void => {
        this.lastEncodingMs = stats.frameEncodingTime;
        this.lastRenderingMs = stats.frameRenderingTime;
      };
    this.statsListener = statsListener;
    this.map.addOnDidFinishRenderingFrameWithStatsListener(statsListener);
  }

  aboutToDisappear(): void {
    if (!this.map) {
      return;
    }
    this.map.setOnFpsChangedListener(null);
    if (this.statsListener) {
      this.map.removeOnDidFinishRenderingFrameWithStatsListener(this.statsListener);
      this.statsListener = undefined;
    }
    this.fpsListener = undefined;
  }

  /**
   * Accumulate per-frame FPS values and refresh the text once per window.
   */
  private onFpsSample(fps: number): void {
    this.frameCount++;
    const now = Date.now();
    const elapsedMs = now - this.sampleStartMs;
    if (elapsedMs < this.updateIntervalMs) {
      return;
    }

    const measuredFps = this.frameCount * 1000.0 / elapsedMs;
    this.fpsText = `${measuredFps.toFixed(1)} FPS`;
    this.encodingText = `${this.lastEncodingMs.toFixed(1)} ms`;
    this.renderingText = `${this.lastRenderingMs.toFixed(1)} ms`;
    this.frameCount = 0;
    this.sampleStartMs = now;
  }

  build() {
    Column({ space: 2 }) {
      Text(this.fpsText)
        .fontSize(12)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Medium)
      if (this.showFrameTimes) {
        Text(`enc ${this.encodingText}`)
          .fontSize(10)
          .fontColor('#CCFFFFFF')
        Text(`render ${this.renderingText}`)
          .fontSize(10)
          .fontColor('#CCFFFFFF')
      }
    }
    .alignItems(HorizontalAlign.Start)
    .padding(6)
    .borderRadius(6)
    .backgroundColor('#99000000')
  }
}
