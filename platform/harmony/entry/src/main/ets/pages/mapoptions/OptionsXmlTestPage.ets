/**
 * OptionsXmlTestPage - Test declarative map options via MapLibreMapOptions.
 *
 * Demonstrates configuring the map entirely through the MapLibreMapOptions
 * object passed as the `mapOptions` prop to MapView, including camera,
 * style, zoom limits, gesture settings, and debug mode.
 *
 * Also shows how to recreate the map with a different configuration.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import {
  MapView, MapLibreMap, MapLibreMapOptions, createCameraPosition, LatLng
} from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS } from '../common/TestUtils';

@Entry
@Component
struct OptionsXmlTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';

  // Current configuration state (reflects the active MapLibreMapOptions)
  @State private currentConfig: string = '';
  @State private configIndex: number = 0;

  // Predefined config profiles
  private readonly configs: MapLibreMapOptions[] = [];

  aboutToAppear(): void {
    // Build config profiles
    // Profile 0: Default view - Hangzhou
    const cfg0 = new MapLibreMapOptions();
    cfg0.styleUrl = 'https://demotiles.maplibre.org/style.json';
    cfg0.cameraPosition = createCameraPosition(
      new LatLng(TEST_LOCATIONS.hangzhou.latitude, TEST_LOCATIONS.hangzhou.longitude),
      8,
      0,
      0
    );
    cfg0.minZoom = 2;
    cfg0.maxZoom = 18;
    cfg0.scrollEnabled = true;
    cfg0.zoomEnabled = true;
    cfg0.rotateEnabled = true;
    cfg0.tiltEnabled = true;
    cfg0.prefetchTiles = true;
    this.configs.push(cfg0);

    // Profile 1: Beijing close-up, restricted zoom
    const cfg1 = new MapLibreMapOptions();
    cfg1.styleUrl = 'https://demotiles.maplibre.org/style.json';
    cfg1.cameraPosition = createCameraPosition(
      new LatLng(TEST_LOCATIONS.beijing.latitude, TEST_LOCATIONS.beijing.longitude),
      12,
      0,
      45
    );
    cfg1.minZoom = 10;
    cfg1.maxZoom = 16;
    cfg1.scrollEnabled = true;
    cfg1.zoomEnabled = true;
    cfg1.rotateEnabled = false;
    cfg1.tiltEnabled = false;
    cfg1.prefetchTiles = false;
    this.configs.push(cfg1);

    // Profile 2: World view with debug enabled
    const cfg2 = new MapLibreMapOptions();
    cfg2.styleUrl = DEFAULT_STYLE_URLS.bright || 'https://demotiles.maplibre.org/style.json';
    cfg2.cameraPosition = createCameraPosition(
      new LatLng(20, 0),
      2,
      0,
      0
    );
    cfg2.minZoom = 1;
    cfg2.maxZoom = 10;
    cfg2.scrollEnabled = true;
    cfg2.zoomEnabled = true;
    cfg2.rotateEnabled = true;
    cfg2.tiltEnabled = true;
    cfg2.debug = true;
    cfg2.prefetchTiles = false;
    this.configs.push(cfg2);

    // Profile 3: London with high max zoom and pitch
    const cfg3 = new MapLibreMapOptions();
    cfg3.styleUrl = 'https://demotiles.maplibre.org/style.json';
    cfg3.cameraPosition = createCameraPosition(
      new LatLng(TEST_LOCATIONS.london.latitude, TEST_LOCATIONS.london.longitude),
      14,
      45,
      60
    );
    cfg3.minZoom = 5;
    cfg3.maxZoom = 20;
    cfg3.scrollEnabled = true;
    cfg3.zoomEnabled = true;
    cfg3.rotateEnabled = true;
    cfg3.tiltEnabled = true;
    cfg3.prefetchTiles = true;
    this.configs.push(cfg3);
  }

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.currentConfig = this.describeConfig(this.configs[this.configIndex]);
    this.statusMessage = `Profile ${this.configIndex + 1}/${this.configs.length} active`;
    console.info('[OptionsXmlTestPage] Map ready');
  };

  private describeConfig(opts: MapLibreMapOptions): string {
    const lines: string[] = [];
    if (opts.cameraPosition) {
      const lat = opts.cameraPosition.target?.latitude?.toFixed(2) ?? '?';
      const lng = opts.cameraPosition.target?.longitude?.toFixed(2) ?? '?';
      const z = opts.cameraPosition.zoom?.toFixed(1) ?? '?';
      lines.push(`Camera: ${lat}, ${lng} zoom=${z}`);
    }
    lines.push(`Zoom: ${opts.minZoom}-${opts.maxZoom}`);
    lines.push(`Rotate: ${opts.rotateEnabled}, Tilt: ${opts.tiltEnabled}`);
    if (opts.debug) {
      lines.push('Debug: ON');
    }
    return lines.join(' | ');
  }

  private applyConfig(index: number): void {
    if (!this.mapController || index < 0 || index >= this.configs.length) return;
    this.configIndex = index;
    const opts = this.configs[index];

    // Apply each option individually (simulating XML-based config)
    if (opts.cameraPosition) {
      this.mapController.setCameraPosition(opts.cameraPosition);
    }
    this.mapController.setMinZoom(opts.minZoom ?? 0);
    this.mapController.setMaxZoom(opts.maxZoom ?? 22);
    this.mapController.setPrefetchTiles(opts.prefetchTiles ?? true);

    const ui = this.mapController.getUiSettings();
    if (ui) {
      ui.setScrollGesturesEnabled(opts.scrollEnabled ?? true);
      ui.setRotateGesturesEnabled(opts.rotateEnabled ?? true);
      ui.setTiltGesturesEnabled(opts.tiltEnabled ?? true);
    }

    this.mapController.setDebugActive(opts.debug ?? false);

    this.currentConfig = this.describeConfig(opts);
    this.statusMessage = `Profile ${index + 1}/${this.configs.length} applied`;
    showToast(`Config ${index + 1} applied`);
  }

  private loadNextConfig(): void {
    const next = (this.configIndex + 1) % this.configs.length;
    this.applyConfig(next);
  }

  private loadPreviousConfig(): void {
    const prev = (this.configIndex - 1 + this.configs.length) % this.configs.length;
    this.applyConfig(prev);
  }

  @Builder
  mapContent() {
    MapView({
      onMapReady: this.onMapReady,
      mapOptions: this.configs[0],
    })
      .width('100%')
      .height('100%')
  }

  @Builder
  controlPanel() {
    Column() {
      Text(this.statusMessage)
        .fontSize(14)
        .fontColor(this.isMapReady ? '#4CAF50' : '#FF9800')
        .width('100%')
        .padding(12)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      Text('Map Options via Config')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Text(this.currentConfig)
        .fontSize(12)
        .fontColor('#555')
        .width('100%')
        .lineHeight(18)
        .margin({ bottom: 8 })

      // Config profile buttons
      ForEach(this.configs, (config: MapLibreMapOptions, index: number) => {
        Button(`Profile ${index + 1}`)
          .width('100%')
          .margin({ top: 4 })
          .backgroundColor(index === this.configIndex ? '#2196F3' : '#9E9E9E')
          .onClick(() => this.applyConfig(index))
          .enabled(this.isMapReady)
      })

      Row() {
        Button('Previous')
          .width('48%')
          .onClick(() => this.loadPreviousConfig())
          .enabled(this.isMapReady)
        Button('Next')
          .width('48%')
          .margin({ left: 8 })
          .onClick(() => this.loadNextConfig())
          .enabled(this.isMapReady)
      }
      .width('100%')
      .margin({ top: 8 })

      Text('Each profile sets camera, zoom limits, gesture settings, and debug via MapLibreMapOptions.')
        .fontSize(12)
        .fontColor('#888')
        .width('100%')
        .margin({ top: 8 })
        .lineHeight(16)
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Options XML',
      subtitle: 'Declarative map configuration',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
