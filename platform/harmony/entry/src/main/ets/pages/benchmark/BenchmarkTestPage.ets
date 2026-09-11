/**
 * BenchmarkTestPage - Quick performance benchmark suite.
 *
 * Runs timing-based benchmarks for common map operations:
 * - Zoom animation latency
 * - Camera flyTo animation time
 * - Marker batch addition time
 * - Style reload time
 *
 * Results are displayed and logged for comparison across runs.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import {
  MapView, MapLibreMap, MarkerOptions, LatLng
} from 'maplibre_harmony';
import { StyleLoadedListener } from '../../utils/ListenerFactories';
import { showToast, TEST_LOCATIONS, delay } from '../common/TestUtils';

interface BenchmarkResult {
  name: string;
  durationMs: number;
  status: 'pass' | 'fail';
}

@Entry
@Component
struct BenchmarkTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private isRunning: boolean = false;
  @State private results: BenchmarkResult[] = [];

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready. Press "Run All Benchmarks" to start.';
    console.info('[BenchmarkTestPage] Map ready');
  };

  private async runAllBenchmarks(): Promise<void> {
    if (!this.mapController || this.isRunning) return;
    this.isRunning = true;
    this.results = [];
    this.statusMessage = 'Running benchmarks...';

    try {
      await this.benchmarkZoomAnimation();
      await delay(300);
      await this.benchmarkFlyTo();
      await delay(300);
      await this.benchmarkMarkerBatch(100);
      await delay(300);
      await this.benchmarkMarkerBatch(500);
      await delay(300);
      await this.benchmarkStyleReload();
      await delay(300);
      await this.benchmarkCoordinateConversion();

      this.statusMessage = `All benchmarks complete. ${this.results.length} tests.`;
      showToast('Benchmarks finished');
    } catch (error) {
      this.statusMessage = `Benchmark error: ${error}`;
      showToast('Benchmark failed');
    } finally {
      this.isRunning = false;
    }
  }

  private recordResult(name: string, durationMs: number, status: 'pass' | 'fail'): void {
    const result: BenchmarkResult = { name, durationMs, status };
    this.results = [...this.results, result];
    console.info(`[Benchmark] ${name}: ${durationMs.toFixed(1)}ms ${status}`);
  }

  private async benchmarkZoomAnimation(): Promise<void> {
    const map = this.mapController!;
    const start = new Date().getTime();
    const iterations = 5;
    for (let i = 0; i < iterations; i++) {
      map.setZoom(10, 200);
      await delay(250);
      map.setZoom(5, 200);
      await delay(250);
    }
    const elapsed = new Date().getTime() - start;
    this.recordResult(`Zoom animation (${iterations}x2 steps)`, elapsed / iterations, 'pass');
  }

  private async benchmarkFlyTo(): Promise<void> {
    const map = this.mapController!;
    const locations: LatLng[] = [
      TEST_LOCATIONS.beijing,
      TEST_LOCATIONS.london,
      TEST_LOCATIONS.nyc,
      TEST_LOCATIONS.tokyo,
      TEST_LOCATIONS.sf,
    ];
    const start = new Date().getTime();
    for (const loc of locations) {
      map.jumpTo(0, loc.latitude, loc.longitude, 0, 5);
      await delay(200);
    }
    const elapsed = new Date().getTime() - start;
    this.recordResult(`JumpTo (${locations.length} locations)`, elapsed / locations.length, 'pass');
  }

  private async benchmarkMarkerBatch(count: number): Promise<void> {
    const map = this.mapController!;
    // Return to a broad view
    map.jumpTo(0, 20, 0, 0, 3);
    await delay(300);

    const start = new Date().getTime();
    const optionsList: MarkerOptions[] = [];
    for (let i = 0; i < count; i++) {
      const lat = (Math.random() - 0.5) * 140;
      const lng = (Math.random() - 0.5) * 360;
      const options = new MarkerOptions()
        .position(new LatLng(lat, lng))
        .title(`Marker ${i}`);
      optionsList.push(options);
    }
    const markers = await map.addMarkersBatch(optionsList);
    const elapsed = new Date().getTime() - start;
    const avg = elapsed / count;

    // Clean up
    for (const marker of markers) {
      map.removeMarker(marker);
    }

    this.recordResult(`Add ${count} markers`, elapsed, avg < 10 ? 'pass' : 'fail');
  }

  private async benchmarkStyleReload(): Promise<void> {
    const map = this.mapController!;
    const start = new Date().getTime();
    // Switch styles and measure
    map.setStyleUrl('https://demotiles.maplibre.org/style.json');
    // Wait for the style to load
    await new Promise<void>((resolve: () => void): void => {
      const listener = new StyleLoadedListener(
        (): void => {
          map.removeOnStyleLoadedListener(listener);
          resolve();
        },
      );
      map.addOnStyleLoadedListener(listener);
    });
    const elapsed = new Date().getTime() - start;
    this.recordResult('Style reload', elapsed, 'pass');
  }

  private async benchmarkCoordinateConversion(): Promise<void> {
    const map = this.mapController!;
    map.jumpTo(0, 0, 0, 0, 2);
    await delay(300);

    const start = new Date().getTime();
    const iterations = 1000;
    for (let i = 0; i < iterations; i++) {
      const lat = (Math.random() - 0.5) * 180;
      const lng = (Math.random() - 0.5) * 360;
      map.pixelForLatLng(lat, lng);
    }
    const elapsed = new Date().getTime() - start;
    this.recordResult(`pixelForLatLng (${iterations}x)`, elapsed, 'pass');
  }

  private clearResults(): void {
    this.results = [];
    this.statusMessage = 'Results cleared';
    showToast('Results cleared');
  }

  @Builder
  mapContent() {
    MapView({
      onMapReady: this.onMapReady,
      styleUrl: 'https://demotiles.maplibre.org/style.json',
      initialLatitude: TEST_LOCATIONS.hangzhou.latitude,
      initialLongitude: TEST_LOCATIONS.hangzhou.longitude,
      initialZoom: 3,
    })
      .width('100%')
      .height('100%')
  }

  @Builder
  controlPanel() {
    Column() {
      Text(this.statusMessage)
        .fontSize(14)
        .fontColor(this.isMapReady ? (this.isRunning ? '#FF9800' : '#4CAF50') : '#FF9800')
        .width('100%')
        .padding(12)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      Text('Benchmark Suite')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Row() {
        Button('Run All Benchmarks')
          .width('60%')
          .onClick(() => this.runAllBenchmarks())
          .enabled(this.isMapReady && !this.isRunning)
        Button('Clear')
          .width('35%')
          .margin({ left: 8 })
          .onClick(() => this.clearResults())
          .enabled(this.results.length > 0)
      }
      .width('100%')

      // Results list
      if (this.results.length > 0) {
        Text('Results')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ top: 12, bottom: 4 })

        ForEach(this.results, (result: BenchmarkResult) => {
          Row() {
            Text(result.name)
              .fontSize(13)
              .layoutWeight(1)
            Text(`${result.durationMs.toFixed(1)} ms`)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(result.status === 'pass' ? '#4CAF50' : '#E53935')
            Text(result.status === 'pass' ? 'OK' : 'FAIL')
              .fontSize(11)
              .fontColor(result.status === 'pass' ? '#4CAF50' : '#E53935')
              .margin({ left: 6 })
          }
          .width('100%')
          .height(28)
          .padding({ left: 4, right: 4 })
        })
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Benchmark',
      subtitle: 'Performance benchmark suite',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
