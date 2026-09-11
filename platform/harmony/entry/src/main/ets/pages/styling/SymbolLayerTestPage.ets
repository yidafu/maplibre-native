/**
 * SymbolLayerTestPage - Render icon and text symbols on the map.
 *
 * Demonstrates adding a GeoJSON point source with a SymbolLayer,
 * showing custom icons and text labels with configurable properties.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import {
  MapView, MapLibreMap, GeoJsonSource, SymbolLayer,
  LatLng, IconFactory
} from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, showToast } from '../common/TestUtils';
import { Feature } from 'maplibre_harmony/src/main/cpp/types/libmaplibre/geojson/Feature';

interface SymbolPointInfo {
  lng: number;
  lat: number;
  label: string;
}

@Entry
@Component
struct SymbolLayerTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private layerAdded: boolean = false;

  private readonly SOURCE_ID: string = 'symbol-source';
  private readonly LAYER_ID: string = 'symbol-layer-test';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready - add a symbol layer';
    console.info('[SymbolLayerTestPage] Map ready');
  };

  private addSymbolLayer(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) {
      setTimeout(() => this.addSymbolLayer(), 500);
      return;
    }

    try {
      const center = this.mapController.getLatLng();
      const points: SymbolPointInfo[] = [
        { lng: center.longitude, lat: center.latitude, label: 'Center' },
        { lng: center.longitude + 0.2, lat: center.latitude + 0.1, label: 'NE Point' },
        { lng: center.longitude - 0.2, lat: center.latitude - 0.1, label: 'SW Point' },
        { lng: center.longitude + 0.15, lat: center.latitude - 0.15, label: 'SE Point' },
        { lng: center.longitude - 0.15, lat: center.latitude + 0.15, label: 'NW Point' },
      ];

      const features: object[] = points.map((p: SymbolPointInfo, i: number): object => ({
        type: 'Feature',
        geometry: {
          type: 'Point',
          coordinates: [p.lng, p.lat]
        },
        properties: {
          label: p.label,
          index: i,
          size: 12 + i * 4
        }
      } as Feature));

      const source = new GeoJsonSource(this.SOURCE_ID);
      source.setGeoJson({
        type: 'FeatureCollection',
        features: features
      });
      style.addSource(source);

      // Create symbol layer with text labels
      const layer = new SymbolLayer(this.LAYER_ID, this.SOURCE_ID);
      layer.setTextField('{label}');
      layer.setTextSize(14);
      layer.setTextColor('#FFFFFF');
      layer.setTextHaloColor('#000000');
      layer.setTextHaloWidth(1);
      layer.setTextAnchor('center');
      layer.setTextOffset([0, 1.5]);
      style.addLayer(layer);

      this.layerAdded = true;
      this.statusMessage = `Symbol layer added: ${points.length} labels`;
      showToast('Symbol layer created');
    } catch (err) {
      this.statusMessage = `Error: ${err}`;
      console.error('[SymbolLayerTestPage] Error:', err);
    }
  }

  private updateSymbolProperties(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    const layer = style.getLayer(this.LAYER_ID) as SymbolLayer;
    if (!layer) {
      showToast('Layer not found');
      return;
    }

    const colors = ['#FFFFFF', '#FFEB3B', '#4CAF50', '#FF5722', '#2196F3'];
    const color = colors[Math.floor(Math.random() * colors.length)];
    const size = 10 + Math.random() * 20;

    layer.setTextColor(color);
    layer.setTextSize(size);
    this.statusMessage = `Text color=${color}, size=${size.toFixed(1)}`;
    showToast('Symbol properties updated');
  }

  private removeSymbolLayer(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    style.removeLayer(this.LAYER_ID);
    style.removeSource(this.SOURCE_ID);
    this.layerAdded = false;
    this.statusMessage = 'Symbol layer removed';
    showToast('Symbol layer removed');
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

      Text('Symbol Layer Controls')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Button('Add Symbol Layer')
        .width('100%')
        .margin({ top: 6 })
        .backgroundColor('#4CAF50')
        .fontColor(Color.White)
        .onClick(() => this.addSymbolLayer())
        .enabled(this.isMapReady)

      Button('Randomize Text')
        .width('100%')
        .margin({ top: 6 })
        .onClick(() => this.updateSymbolProperties())
        .enabled(this.isMapReady && this.layerAdded)

      Button('Remove Layer')
        .width('100%')
        .margin({ top: 6 })
        .backgroundColor('#F44336')
        .fontColor(Color.White)
        .onClick(() => this.removeSymbolLayer())
        .enabled(this.isMapReady && this.layerAdded)
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Symbol Layer',
      subtitle: 'Render icon and text symbols',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
