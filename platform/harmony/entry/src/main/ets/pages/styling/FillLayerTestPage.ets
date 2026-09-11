/**
 * FillLayerTestPage - Render fill polygon layers on the map.
 *
 * Demonstrates adding a GeoJSON polygon source with a FillLayer,
 * with configurable fill color, opacity, and outline.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import {
  MapView, MapLibreMap, GeoJsonSource, FillLayer,
  LatLng, GeoJson
} from 'maplibre_harmony';
import type { JSONValue } from 'libmaplibre.so';
import { DEFAULT_STYLE_URLS, showToast, randomColor } from '../common/TestUtils';

@Entry
@Component
struct FillLayerTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private layerAdded: boolean = false;

  private readonly SOURCE_ID: string = 'fill-polygon-source';
  private readonly LAYER_ID: string = 'fill-layer-test';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready - add a fill layer';
    console.info('[FillLayerTestPage] Map ready');
  };

  private addFillLayer(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) {
      setTimeout(() => this.addFillLayer(), 500);
      return;
    }

    try {
      const center = this.mapController.getLatLng();

      // Create a polygon feature (a hexagon around the center)
      const hexagonCoords = this.generateHexagon(center, 0.15);
      const prop1: Record<string, JSONValue> = { "name": 'Test Polygon' };
      const feature = GeoJson.polygonFeature(
        [hexagonCoords],
        prop1
      );

      // Additionally, create a smaller polygon with a hole
      const innerHexagon = this.generateHexagon(center, 0.06);
      const prop2: Record<string, JSONValue> = { "name": 'Polygon with Hole' };
      const polygonWithHole = GeoJson.feature(
        GeoJson.polygon([
          this.generateHexagon(center, 0.3),
          innerHexagon
        ]),
        prop2
      );

      const source = new GeoJsonSource(this.SOURCE_ID);
      source.setGeoJson(GeoJson.featureCollection([feature, polygonWithHole]));
      style.addSource(source);

      const layer = new FillLayer(this.LAYER_ID, this.SOURCE_ID);
      layer.setFillColor('#2196F3');
      layer.setFillOpacity(0.6);
      layer.setFillOutlineColor('#1565C0');
      style.addLayer(layer);

      this.layerAdded = true;
      this.statusMessage = 'Fill layer added with polygons';
      showToast('Fill layer created');
    } catch (err) {
      this.statusMessage = `Error: ${err}`;
      console.error('[FillLayerTestPage] Error:', err);
    }
  }

  private updateFillProperties(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    const layer = style.getLayer(this.LAYER_ID) as FillLayer;
    if (!layer) {
      showToast('Layer not found');
      return;
    }

    const color = randomColor();
    const outlineColor = randomColor();
    layer.setFillColor(color);
    layer.setFillOutlineColor(outlineColor);
    layer.setFillOpacity(0.3 + Math.random() * 0.7);
    this.statusMessage = `Fill color: ${color}`;
    showToast('Fill properties updated');
  }

  private removeFillLayer(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    style.removeLayer(this.LAYER_ID);
    style.removeSource(this.SOURCE_ID);
    this.layerAdded = false;
    this.statusMessage = 'Fill layer removed';
    showToast('Fill layer removed');
  }

  private generateHexagon(center: LatLng, radius: number): number[][] {
    const coords: number[][] = [];
    for (let i = 0; i <= 6; i++) {
      const angle = (i / 6) * Math.PI * 2 - Math.PI / 2;
      const lng = center.longitude + radius * Math.cos(angle);
      const lat = center.latitude + radius * Math.sin(angle);
      coords.push([lng, lat] as number[]);
    }
    return coords;
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

      Text('Fill Layer Controls')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Button('Add Fill Layer')
        .width('100%')
        .margin({ top: 6 })
        .backgroundColor('#4CAF50')
        .fontColor(Color.White)
        .onClick(() => this.addFillLayer())
        .enabled(this.isMapReady)

      Button('Randomize Fill')
        .width('100%')
        .margin({ top: 6 })
        .onClick(() => this.updateFillProperties())
        .enabled(this.isMapReady && this.layerAdded)

      Button('Remove Layer')
        .width('100%')
        .margin({ top: 6 })
        .backgroundColor('#F44336')
        .fontColor(Color.White)
        .onClick(() => this.removeFillLayer())
        .enabled(this.isMapReady && this.layerAdded)
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Fill Layer',
      subtitle: 'Render polygon fill layers',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
