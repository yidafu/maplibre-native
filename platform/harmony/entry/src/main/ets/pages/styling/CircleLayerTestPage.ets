/**
 * CircleLayerTestPage - Render circle layers on the map.
 *
 * Demonstrates adding a GeoJSON source with point data,
 * then styling it with a CircleLayer with configurable
 * radius, color, opacity, and blur.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import {
  MapView, MapLibreMap, GeoJsonSource, CircleLayer,
  LatLng, Expression, GeoJson
} from 'maplibre_harmony';
import type { IFeature } from 'maplibre_harmony';
import type { JSONValue } from 'libmaplibre.so';
import { DEFAULT_STYLE_URLS, showToast } from '../common/TestUtils';

@Entry
@Component
struct CircleLayerTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private layerAdded: boolean = false;

  private readonly SOURCE_ID: string = 'circle-points-source';
  private readonly LAYER_ID: string = 'circle-layer-test';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready - add a circle layer';
    console.info('[CircleLayerTestPage] Map ready');
  };

  private addCircleLayer(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) {
      this.statusMessage = 'Style not ready yet, retrying...';
      setTimeout(() => this.addCircleLayer(), 500);
      return;
    }

    try {
      // Generate random points around the current center
      const center = this.mapController.getLatLng();
      const features = this.generatePointFeatures(center, 50);

      // Create GeoJSON source
      const source = new GeoJsonSource(this.SOURCE_ID);
      source.setGeoJson(GeoJson.featureCollection(features));
      style.addSource(source);

      // Create circle layer
      const layer = new CircleLayer(this.LAYER_ID, this.SOURCE_ID);
      layer.setCircleColor('#FF5722');
      layer.setCircleRadius(12);
      layer.setCircleOpacity(0.8);
      layer.setCircleBlur(2);
      style.addLayer(layer);

      this.layerAdded = true;
      this.statusMessage = 'Circle layer added with 50 points';
      showToast('Circle layer created');
    } catch (err) {
      this.statusMessage = `Error: ${err}`;
      console.error('[CircleLayerTestPage] Error:', err);
    }
  }

  private updateCircleProperties(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    const layer = style.getLayer(this.LAYER_ID) as CircleLayer;
    if (!layer) {
      showToast('Layer not found, add it first');
      return;
    }

    const colors = ['#FF5722', '#2196F3', '#4CAF50', '#9C27B0', '#FF9800'];
    const randomColor = colors[Math.floor(Math.random() * colors.length)];
    const radius = 6 + Math.random() * 20;

    layer.setCircleColor(randomColor);
    layer.setCircleRadius(radius);
    layer.setCircleOpacity(0.5 + Math.random() * 0.5);
    this.statusMessage = `Updated: color=${randomColor}, radius=${radius.toFixed(1)}`;
    showToast('Circle properties updated');
  }

  private removeCircleLayer(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    style.removeLayer(this.LAYER_ID);
    style.removeSource(this.SOURCE_ID);
    this.layerAdded = false;
    this.statusMessage = 'Circle layer removed';
    showToast('Circle layer removed');
  }

  private generatePointFeatures(center: LatLng, count: number): IFeature[] {
    const features: IFeature[] = [];
    for (let i = 0; i < count; i++) {
      const lat = center.latitude + (Math.random() - 0.5) * 0.5;
      const lng = center.longitude + (Math.random() - 0.5) * 0.5;
      const props: Record<string, JSONValue> = { "id": i, "value": Math.random() * 100 };
      features.push(GeoJson.pointFeature([lng, lat], props));
    }
    return features;
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

      Text('Circle Layer Controls')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Button('Add Circle Layer')
        .width('100%')
        .margin({ top: 6 })
        .backgroundColor('#4CAF50')
        .fontColor(Color.White)
        .onClick(() => this.addCircleLayer())
        .enabled(this.isMapReady)

      Button('Randomize Properties')
        .width('100%')
        .margin({ top: 6 })
        .onClick(() => this.updateCircleProperties())
        .enabled(this.isMapReady && this.layerAdded)

      Button('Remove Layer')
        .width('100%')
        .margin({ top: 6 })
        .backgroundColor('#F44336')
        .fontColor(Color.White)
        .onClick(() => this.removeCircleLayer())
        .enabled(this.isMapReady && this.layerAdded)
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Circle Layer',
      subtitle: 'Render point data as circles',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
