/**
 * LineLayerTestPage - Render line string layers on the map.
 *
 * Demonstrates adding a GeoJSON LineString source with a LineLayer,
 * with configurable line color, width, opacity, and dash pattern.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import {
  MapView, MapLibreMap, GeoJsonSource, LineLayer,
  LatLng
} from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, TEST_LOCATIONS, showToast, randomColor } from '../common/TestUtils';
import { Feature } from 'maplibre_harmony/src/main/cpp/types/libmaplibre/geojson/Feature';

@Entry
@Component
struct LineLayerTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private layerAdded: boolean = false;
  @State private isDashOn: boolean = false;

  private readonly SOURCE_ID: string = 'line-source';
  private readonly LAYER_ID: string = 'line-layer-test';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready - add a line layer';
    console.info('[LineLayerTestPage] Map ready');
  };

  private addLineLayer(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) {
      setTimeout(() => this.addLineLayer(), 500);
      return;
    }

    try {
      const cities: LatLng[] = [
        TEST_LOCATIONS.beijing,
        TEST_LOCATIONS.shanghai,
        TEST_LOCATIONS.guangzhou,
        TEST_LOCATIONS.shenzhen,
        TEST_LOCATIONS.hangzhou,
        TEST_LOCATIONS.chengdu,
        TEST_LOCATIONS.wuhan,
        TEST_LOCATIONS.xian,
        TEST_LOCATIONS.beijing,
      ];

      // Create line features connecting the cities
      const lineCoords: number[][] = cities.map((c: LatLng): number[] => [c.longitude, c.latitude]);
      const feature: Feature = {
        type: 'Feature',
        geometry: {
          type: 'LineString',
          coordinates: lineCoords
        },
        properties: { name: 'City Route' }
      };

      const source = new GeoJsonSource(this.SOURCE_ID);
      source.setGeoJson({
        type: 'FeatureCollection',
        features: [feature]
      });
      style.addSource(source);

      const layer = new LineLayer(this.LAYER_ID, this.SOURCE_ID);
      layer.setLineColor('#E91E63');
      layer.setLineWidth(4);
      layer.setLineOpacity(0.9);
      style.addLayer(layer);

      this.layerAdded = true;
      this.statusMessage = 'Line layer added: city route';
      showToast('Line layer created');
    } catch (err) {
      this.statusMessage = `Error: ${err}`;
      console.error('[LineLayerTestPage] Error:', err);
    }
  }

  private updateLineProperties(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    const layer = style.getLayer(this.LAYER_ID) as LineLayer;
    if (!layer) {
      showToast('Layer not found');
      return;
    }

    layer.setLineColor(randomColor());
    layer.setLineWidth(2 + Math.random() * 8);
    layer.setLineOpacity(0.5 + Math.random() * 0.5);
    this.statusMessage = 'Line properties randomized';
    showToast('Line updated');
  }

  private toggleDashPattern(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    const layer = style.getLayer(this.LAYER_ID) as LineLayer;
    if (!layer) return;

    // Toggle dash pattern
    if (this.isDashOn) {
      layer.setLineDasharray([] as number[]);
      this.statusMessage = 'Dash pattern: off';
      showToast('Solid line');
    } else {
      layer.setLineDasharray([2, 3]);
      this.statusMessage = 'Dash pattern: on';
      showToast('Dashed line');
    }
    this.isDashOn = !this.isDashOn;
  }

  private removeLineLayer(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    style.removeLayer(this.LAYER_ID);
    style.removeSource(this.SOURCE_ID);
    this.layerAdded = false;
    this.statusMessage = 'Line layer removed';
    showToast('Line layer removed');
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

      Text('Line Layer Controls')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Button('Add Line Layer')
        .width('100%')
        .margin({ top: 6 })
        .backgroundColor('#4CAF50')
        .fontColor(Color.White)
        .onClick(() => this.addLineLayer())
        .enabled(this.isMapReady)

      Button('Randomize Line')
        .width('100%')
        .margin({ top: 6 })
        .onClick(() => this.updateLineProperties())
        .enabled(this.isMapReady && this.layerAdded)

      Button('Toggle Dash Pattern')
        .width('100%')
        .margin({ top: 6 })
        .onClick(() => this.toggleDashPattern())
        .enabled(this.isMapReady && this.layerAdded)

      Button('Remove Layer')
        .width('100%')
        .margin({ top: 6 })
        .backgroundColor('#F44336')
        .fontColor(Color.White)
        .onClick(() => this.removeLineLayer())
        .enabled(this.isMapReady && this.layerAdded)
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Line Layer',
      subtitle: 'Render line string layers',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
