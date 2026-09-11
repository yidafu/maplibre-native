/**
 * StyleFileTestPage - Load map styles from local JSON.
 *
 * Demonstrates loading a style from a raw JSON string,
 * simulating loading from a local file.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { StyleLoadedListener } from '../../utils/ListenerFactories';
import { showToast } from '../common/TestUtils';

/** Local interface for tile source config. */
interface _SourceConfig {
  type: string;
  tiles: string[];
  tileSize: number;
  attribution?: string;
}

/** Local interface for layer config. */
interface _LayerConfig {
  id: string;
  type: string;
  source?: string;
  minzoom?: number;
  maxzoom?: number;
}

/** Local interface for a map style config object. */
interface _StyleConfig {
  version: number;
  name: string;
  center: number[];
  zoom: number;
  bearing?: number;
  pitch?: number;
  sprite?: string;
  glyphs?: string;
  sources: Record<string, _SourceConfig>;
  layers: _LayerConfig[];
  id?: string;
}

@Entry
@Component
struct StyleFileTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private isCustomStyleLoaded: boolean = false;

  // A minimal style JSON for testing
  private readonly minimalStyleJson: string = StyleFileTestPage.buildMinimalStyleJson();

  // A colorful custom style
  private readonly colorfulStyleJson: string = StyleFileTestPage.buildColorfulStyleJson();

  private static buildMinimalStyleJson(): string {
    const osmSource: _SourceConfig = {
      type: 'raster',
      tiles: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
      tileSize: 256,
      attribution: '© OpenStreetMap contributors'
    };
    const osmLayer: _LayerConfig = {
      id: 'osm-raster-layer',
      type: 'raster',
      source: 'osm-tiles',
      minzoom: 0,
      maxzoom: 19
    };
    const sourceMap: Record<string, _SourceConfig> = { 'osm-tiles': osmSource };
    const styleData: _StyleConfig = {
      version: 8,
      name: 'Minimal Custom Style',
      center: [120.1551, 30.2741],
      zoom: 8,
      bearing: 0,
      pitch: 0,
      sprite: '',
      glyphs: 'https://demotiles.maplibre.org/font/{fontstack}/{range}.pbf',
      sources: sourceMap,
      layers: [osmLayer],
      id: 'minimal-style'
    };
    return JSON.stringify(styleData);
  }

  private static buildColorfulStyleJson(): string {
    const bgSource: _SourceConfig = {
      type: 'raster',
      tiles: ['https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}.png'],
      tileSize: 256,
      attribution: '© Stadia Maps'
    };
    const bgLayer: _LayerConfig = {
      id: 'background-layer',
      type: 'raster',
      source: 'background-source'
    };
    const sourceMap2: Record<string, _SourceConfig> = { 'background-source': bgSource };
    const styleData: _StyleConfig = {
      version: 8,
      name: 'Colorful Custom Style',
      center: [120.1551, 30.2741],
      zoom: 8,
      sources: sourceMap2,
      layers: [bgLayer]
    };
    return JSON.stringify(styleData);
  }

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready';
    console.info('[StyleFileTestPage] Map ready');
  };

  private loadStyleJson(json: string, name: string): void {
    if (!this.mapController) return;
    this.statusMessage = `Loading ${name}...`;
    try {
      this.mapController.setStyleJson(json);
      this.mapController.addOnStyleLoadedListener(new StyleLoadedListener(
        () => {
          this.isCustomStyleLoaded = true;
          this.statusMessage = `Loaded: ${name}`;
          showToast(`Style loaded: ${name}`);
        }
      ));
    } catch (err) {
      this.statusMessage = `Error: ${err}`;
      showToast(`Failed: ${err}`);
    }
  }

  private getCurrentStyleInfo(): void {
    if (!this.mapController) return;
    const url = this.mapController.getStyleUrl();
    const json = this.mapController.getStyleJson();
    this.statusMessage = `URL: ${url || 'none'} | JSON length: ${json.length}`;
    showToast(`Style JSON length: ${json.length} chars`);
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
      Text(this.statusMessage)
        .fontSize(14)
        .fontColor(this.isMapReady ? '#4CAF50' : '#FF9800')
        .width('100%')
        .padding(8)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      Text('Local Style JSON')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Button('Load Minimal Style')
        .width('100%')
        .margin({ top: 6 })
        .onClick(() => this.loadStyleJson(this.minimalStyleJson, 'Minimal (OSM)'))
        .enabled(this.isMapReady)

      Button('Load Colorful Style')
        .width('100%')
        .margin({ top: 6 })
        .onClick(() => this.loadStyleJson(this.colorfulStyleJson, 'Colorful (Stadia)'))
        .enabled(this.isMapReady)

      Button('Get Style Info')
        .width('100%')
        .margin({ top: 6 })
        .backgroundColor('#FF9800')
        .onClick(() => this.getCurrentStyleInfo())
        .enabled(this.isMapReady)

      if (this.isCustomStyleLoaded) {
        Text('Custom style loaded from JSON')
          .fontSize(12)
          .fontColor('#4CAF50')
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 8 })
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Style File',
      subtitle: 'Load local style JSON',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
