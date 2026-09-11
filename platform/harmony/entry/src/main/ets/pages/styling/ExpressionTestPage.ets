/**
 * ExpressionTestPage - Data-driven styling expressions.
 *
 * Demonstrates using expressions to style map layers based on
 * feature properties, including color stops, zoom-based sizing,
 * and conditional logic.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import {
  MapView, MapLibreMap, GeoJsonSource, CircleLayer,
  SymbolLayer, LatLng, Expression
} from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, showToast } from '../common/TestUtils';
import { Feature } from 'maplibre_harmony/src/main/cpp/types/libmaplibre/geojson/Feature';

/** GeoJSON Point geometry shape. */
interface GeoJsonPointGeometry {
  type: string;
  coordinates: number[];
}

/** GeoJSON Feature for expression demo data points. */
interface GeoJsonPointFeatureFeature {
  label: string;
  category: string;
  value: number;
}

interface GeoJsonPointFeature {
  type: string;
  geometry: GeoJsonPointGeometry;
  properties: GeoJsonPointFeatureFeature;
}

/** GeoJSON FeatureCollection wrapper. */
interface GeoJsonFeatureCollection {
  type: string;
  features: GeoJsonPointFeature[];
}

@Entry
@Component
struct ExpressionTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private layerAdded: boolean = false;
  @State private expressionMode: string = 'color-by-value';

  private readonly SOURCE_ID: string = 'expression-source';
  private readonly CIRCLE_LAYER_ID: string = 'expression-circle-layer';
  private readonly LABEL_LAYER_ID: string = 'expression-label-layer';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready - add expression layer';
    console.info('[ExpressionTestPage] Map ready');
  };

  private addExpressionLayer(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) {
      setTimeout(() => this.addExpressionLayer(), 500);
      return;
    }

    try {
      const center = this.mapController.getLatLng();
      const features = this.generateDataPoints(center, 60);

      const source = new GeoJsonSource(this.SOURCE_ID);
      const collection: GeoJsonFeatureCollection = {
        type: 'FeatureCollection',
        features: features
      };
      source.setGeoJson(collection);
      style.addSource(source);

      // Add a circle layer with data-driven color
      const circleLayer = new CircleLayer(this.CIRCLE_LAYER_ID, this.SOURCE_ID);
      circleLayer.setCircleRadius(
        Expression.interpolate(
          Expression.linear(),
          Expression.zoom(),
          Expression.literal(8), Expression.literal(5),
          Expression.literal(12), Expression.literal(10),
          Expression.literal(16), Expression.literal(20)
        )
      );
      circleLayer.setCircleColor(
        Expression.match(
          Expression.get('category'),
          Expression.literal('A'), Expression.literal('#F44336'),
          Expression.literal('B'), Expression.literal('#2196F3'),
          Expression.literal('C'), Expression.literal('#4CAF50'),
          Expression.literal('D'), Expression.literal('#FF9800'),
          Expression.literal('#9E9E9E')
        )
      );
      circleLayer.setCircleOpacity(0.8);
      circleLayer.setCircleStrokeColor('#FFFFFF');
      circleLayer.setCircleStrokeWidth(2);
      style.addLayer(circleLayer);

      // Add label layer
      const labelLayer = new SymbolLayer(this.LABEL_LAYER_ID, this.SOURCE_ID);
      labelLayer.setTextField(Expression.get<string>('label'));
      labelLayer.setTextSize(12);
      labelLayer.setTextColor('#FFFFFF');
      labelLayer.setTextHaloColor('#000000');
      labelLayer.setTextHaloWidth(1);
      labelLayer.setTextOffset([0, 1.5]);
      style.addLayer(labelLayer);

      this.layerAdded = true;
      this.statusMessage = 'Expression layer added: 60 points with data-driven styling';
      showToast('Expression layer created');
    } catch (err) {
      this.statusMessage = `Error: ${err}`;
      console.error('[ExpressionTestPage] Error:', err);
    }
  }

  private switchExpressionMode(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    const layer = style.getLayer(this.CIRCLE_LAYER_ID) as CircleLayer;
    if (!layer) return;

    if (this.expressionMode === 'color-by-value') {
      // Switch to size-by-value
      layer.setCircleColor('#2196F3');
      layer.setCircleRadius(
        Expression.multiply(
          Expression.get<number>('value'),
          Expression.literal(0.3)
        )
      );
      this.expressionMode = 'size-by-value';
      this.statusMessage = 'Mode: circle size driven by value property';
    } else {
      // Switch back to color-by-value
      layer.setCircleRadius(10);
      layer.setCircleColor(
        Expression.match(
          Expression.get('category'),
          Expression.literal('A'), Expression.literal('#F44336'),
          Expression.literal('B'), Expression.literal('#2196F3'),
          Expression.literal('C'), Expression.literal('#4CAF50'),
          Expression.literal('D'), Expression.literal('#FF9800'),
          Expression.literal('#9E9E9E')
        )
      );
      this.expressionMode = 'color-by-value';
      this.statusMessage = 'Mode: circle color driven by category property';
    }
    showToast(`Switched to ${this.expressionMode}`);
  }

  private removeExpressionLayer(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    style.removeLayer(this.LABEL_LAYER_ID);
    style.removeLayer(this.CIRCLE_LAYER_ID);
    style.removeSource(this.SOURCE_ID);
    this.layerAdded = false;
    this.statusMessage = 'Expression layers removed';
    showToast('Expression layers removed');
  }

  private generateDataPoints(center: LatLng, count: number): GeoJsonPointFeature[] {
    const categories = ['A', 'B', 'C', 'D'];
    const features: GeoJsonPointFeature[] = [];
    for (let i = 0; i < count; i++) {
      const lat = center.latitude + (Math.random() - 0.5) * 0.4;
      const lng = center.longitude + (Math.random() - 0.5) * 0.4;
      const category = categories[Math.floor(Math.random() * categories.length)];
      const value = Math.random() * 100;
      features.push({
        type: 'Feature',
        geometry: {
          type: 'Point',
          coordinates: [lng, lat]
        },
        properties: {
          label: `${category}-${i}`,
          category: category,
          value: value
        }
      } as GeoJsonPointFeature);
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

      Text('Expression Controls')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Button('Add Expression Layer')
        .width('100%')
        .margin({ top: 6 })
        .backgroundColor('#4CAF50')
        .fontColor(Color.White)
        .onClick(() => this.addExpressionLayer())
        .enabled(this.isMapReady)

      if (this.layerAdded) {
        Text(`Mode: ${this.expressionMode}`)
          .fontSize(12)
          .fontColor('#666')
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 6 })

        Button('Switch Expression Mode')
          .width('100%')
          .margin({ top: 6 })
          .onClick(() => this.switchExpressionMode())
          .enabled(this.isMapReady && this.layerAdded)

        Button('Remove Layer')
          .width('100%')
          .margin({ top: 6 })
          .backgroundColor('#F44336')
          .fontColor(Color.White)
          .onClick(() => this.removeExpressionLayer())
          .enabled(this.isMapReady && this.layerAdded)
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Expression',
      subtitle: 'Data-driven expressions',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
