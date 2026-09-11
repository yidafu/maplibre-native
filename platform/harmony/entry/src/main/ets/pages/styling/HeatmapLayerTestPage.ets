/**
 * HeatmapLayerTestPage - Render heatmap density visualizations.
 *
 * Demonstrates adding a GeoJSON source with many point features
 * and styling as a heatmap with configurable radius, intensity,
 * weight, and color ramp.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import {
  MapView, MapLibreMap, GeoJsonSource, HeatmapLayer,
  LatLng, GeoJson
} from 'maplibre_harmony';
import type { IFeature } from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, showToast } from '../common/TestUtils';
import { JSONValue } from 'maplibre_harmony/src/main/cpp/types/libmaplibre/CommonTypes';

/** A single point within a cluster for heatmap generation. */
interface ClusterPoint {
  lat: number;
  lng: number;
  weight: number;
}


@Entry
@Component
struct HeatmapLayerTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private layerAdded: boolean = false;

  private readonly SOURCE_ID: string = 'heatmap-source';
  private readonly LAYER_ID: string = 'heatmap-layer-test';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready - add a heatmap layer';
    console.info('[HeatmapLayerTestPage] Map ready');
  };

  private addHeatmapLayer(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) {
      setTimeout(() => this.addHeatmapLayer(), 500);
      return;
    }

    try {
      const center = this.mapController.getLatLng();
      const points = this.generateRandomPoints(center, 200);

      const source = new GeoJsonSource(this.SOURCE_ID);
      source.setGeoJson(GeoJson.featureCollection(points));
      style.addSource(source);

      const layer = new HeatmapLayer(this.LAYER_ID, this.SOURCE_ID);
      layer.setHeatmapRadius(20);
      layer.setHeatmapWeight(['get', 'weight']);
      layer.setHeatmapIntensity(1.0);
      layer.setHeatmapOpacity(0.8);
      // Use the default color ramp
      style.addLayer(layer);

      this.layerAdded = true;
      this.statusMessage = `Heatmap added: ${points.length} data points`;
      showToast('Heatmap layer created');
    } catch (err) {
      this.statusMessage = `Error: ${err}`;
      console.error('[HeatmapLayerTestPage] Error:', err);
    }
  }

  private updateHeatmapIntensity(intensity: number): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    const layer = style.getLayer(this.LAYER_ID) as HeatmapLayer;
    if (!layer) return;

    layer.setHeatmapIntensity(intensity);
    this.statusMessage = `Intensity: ${intensity.toFixed(1)}`;
  }

  private updateHeatmapRadius(radius: number): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    const layer = style.getLayer(this.LAYER_ID) as HeatmapLayer;
    if (!layer) return;

    layer.setHeatmapRadius(radius);
    this.statusMessage = `Radius: ${radius}`;
  }

  private removeHeatmapLayer(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    style.removeLayer(this.LAYER_ID);
    style.removeSource(this.SOURCE_ID);
    this.layerAdded = false;
    this.statusMessage = 'Heatmap layer removed';
    showToast('Heatmap removed');
  }

  private generateRandomPoints(center: LatLng, count: number): IFeature[] {
    const features: IFeature[] = [];
    // Create clusters of points for better heatmap visualization
    const clusters: ClusterPoint[] = [
      { lat: center.latitude, lng: center.longitude, weight: 1.0 },
      { lat: center.latitude + 0.1, lng: center.longitude + 0.1, weight: 0.8 },
      { lat: center.latitude - 0.08, lng: center.longitude + 0.05, weight: 0.6 },
      { lat: center.latitude + 0.05, lng: center.longitude - 0.1, weight: 0.7 },
      { lat: center.latitude - 0.12, lng: center.longitude - 0.08, weight: 0.9 },
    ];

    for (let i = 0; i < count; i++) {
      const cluster = clusters[Math.floor(Math.random() * clusters.length)];
      const lat = cluster.lat + (Math.random() - 0.5) * 0.04;
      const lng = cluster.lng + (Math.random() - 0.5) * 0.04;
      const props:  Record<string, JSONValue> = { "weight": Math.random() * cluster.weight };
      features.push(GeoJson.pointFeature([lng, lat, 0], props));
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

      Text('Heatmap Controls')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Button('Add Heatmap')
        .width('100%')
        .margin({ top: 6 })
        .backgroundColor('#4CAF50')
        .fontColor(Color.White)
        .onClick(() => this.addHeatmapLayer())
        .enabled(this.isMapReady)

      if (this.layerAdded) {
        Text('Radius').fontSize(13).fontWeight(FontWeight.Bold).width('100%').margin({ top: 6 })

        Row() {
          Button('10').layoutWeight(1).margin({ right: 4 }).fontSize(12)
            .onClick(() => this.updateHeatmapRadius(10))
          Button('20').layoutWeight(1).margin({ right: 4 }).fontSize(12)
            .onClick(() => this.updateHeatmapRadius(20))
          Button('40').layoutWeight(1).fontSize(12)
            .onClick(() => this.updateHeatmapRadius(40))
        }
        .width('100%')
        .margin({ top: 4 })

        Text('Intensity').fontSize(13).fontWeight(FontWeight.Bold).width('100%').margin({ top: 6 })

        Row() {
          Button('0.5').layoutWeight(1).margin({ right: 4 }).fontSize(12)
            .onClick(() => this.updateHeatmapIntensity(0.5))
          Button('1.0').layoutWeight(1).margin({ right: 4 }).fontSize(12)
            .onClick(() => this.updateHeatmapIntensity(1.0))
          Button('2.0').layoutWeight(1).fontSize(12)
            .onClick(() => this.updateHeatmapIntensity(2.0))
        }
        .width('100%')
        .margin({ top: 4 })

        Button('Remove Layer')
          .width('100%')
          .margin({ top: 8 })
          .backgroundColor('#F44336')
          .fontColor(Color.White)
          .onClick(() => this.removeHeatmapLayer())
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Heatmap Layer',
      subtitle: 'Heatmap density visualization',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
