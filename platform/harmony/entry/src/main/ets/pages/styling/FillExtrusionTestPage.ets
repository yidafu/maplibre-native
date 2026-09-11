/**
 * FillExtrusionTestPage - Render 3D extruded polygon layers.
 *
 * Demonstrates adding a GeoJSON source with polygon features
 * that have height properties, styled with FillExtrusionLayer
 * to create 3D buildings.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import {
  MapView, MapLibreMap, GeoJsonSource, FillExtrusionLayer,
  LatLng
} from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, showToast, randomColor } from '../common/TestUtils';

/** GeoJSON geometry for a Polygon. */
interface GeoJsonPolygonGeometry {
  type: string;
  coordinates: number[][][];
}

/** GeoJSON Feature with Polygon geometry and building properties. */
interface GeoJsonBuildingFeatureProperty {
  height: number;
  base: number;
  name: string;
}

interface GeoJsonBuildingFeature {
  type: string;
  geometry: GeoJsonPolygonGeometry;
  properties: GeoJsonBuildingFeatureProperty;
}

/** GeoJSON FeatureCollection wrapping an array of building features. */
interface GeoJsonBuildingCollection {
  type: string;
  features: GeoJsonBuildingFeature[];
}

@Entry
@Component
struct FillExtrusionTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private layerAdded: boolean = false;

  private readonly SOURCE_ID: string = 'extrusion-source';
  private readonly LAYER_ID: string = 'extrusion-layer-test';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready - add 3D extrusion';
    console.info('[FillExtrusionTestPage] Map ready');
  };

  private addExtrusionLayer(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) {
      setTimeout(() => this.addExtrusionLayer(), 500);
      return;
    }

    try {
      const center = this.mapController.getLatLng();
      const polygons = this.generateBuildingPolygons(center);

      const source = new GeoJsonSource(this.SOURCE_ID);
      const collection: GeoJsonBuildingCollection = {
        type: 'FeatureCollection',
        features: polygons
      };
      source.setGeoJson(collection);
      style.addSource(source);

      const layer = new FillExtrusionLayer(this.LAYER_ID, this.SOURCE_ID);
      layer.setFillExtrusionColor('#FF5722');
      layer.setFillExtrusionOpacity(0.8);
      layer.setFillExtrusionHeight(['get', 'height']);
      layer.setFillExtrusionBase(['get', 'base']);
      style.addLayer(layer);

      // Tilt the map to show 3D effect
      this.mapController.setPitch(45, 1000);

      this.layerAdded = true;
      this.statusMessage = `Extrusion layer added: ${polygons.length} buildings`;
      showToast('3D extrusion layer created');
    } catch (err) {
      this.statusMessage = `Error: ${err}`;
      console.error('[FillExtrusionTestPage] Error:', err);
    }
  }

  private updateExtrusionColors(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    const layer = style.getLayer(this.LAYER_ID) as FillExtrusionLayer;
    if (!layer) return;

    layer.setFillExtrusionColor(randomColor());
    layer.setFillExtrusionOpacity(0.5 + Math.random() * 0.5);
    this.statusMessage = 'Colors randomized';
    showToast('Extrusion colors updated');
  }

  private removeExtrusionLayer(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    style.removeLayer(this.LAYER_ID);
    style.removeSource(this.SOURCE_ID);
    this.layerAdded = false;
    this.statusMessage = 'Extrusion layer removed';
    this.mapController.setPitch(0, 500);
    showToast('Extrusion layer removed');
  }

  private generateBuildingPolygons(center: LatLng): GeoJsonBuildingFeature[] {
    const features: GeoJsonBuildingFeature[] = [];
    const rows = 5;
    const cols = 5;
    const spacing = 0.02;

    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        const baseLat = center.latitude + (r - rows / 2) * spacing;
        const baseLng = center.longitude + (c - cols / 2) * spacing;
        const width = 0.008 + Math.random() * 0.012;
        const height = 10 + Math.random() * 60;
        const baseHeight = 0;

        features.push({
          type: 'Feature',
          geometry: {
            type: 'Polygon',
            coordinates: [[
              [baseLng - width / 2, baseLat - width / 2],
              [baseLng + width / 2, baseLat - width / 2],
              [baseLng + width / 2, baseLat + width / 2],
              [baseLng - width / 2, baseLat + width / 2],
              [baseLng - width / 2, baseLat - width / 2]
            ]]
          },
          properties: {
            height: height,
            base: baseHeight,
            name: `Building ${r * cols + c + 1}`
          }
        });
      }
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

      Text('3D Extrusion Controls')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Button('Add 3D Buildings')
        .width('100%')
        .margin({ top: 6 })
        .backgroundColor('#4CAF50')
        .fontColor(Color.White)
        .onClick(() => this.addExtrusionLayer())
        .enabled(this.isMapReady)

      Button('Randomize Colors')
        .width('100%')
        .margin({ top: 6 })
        .onClick(() => this.updateExtrusionColors())
        .enabled(this.isMapReady && this.layerAdded)

      Row() {
        Button('Pitch 30')
          .layoutWeight(1)
          .margin({ right: 4 })
          .fontSize(13)
          .onClick(() => this.mapController?.setPitch(30, 500))
          .enabled(this.isMapReady)

        Button('Pitch 60')
          .layoutWeight(1)
          .margin({ left: 4 })
          .fontSize(13)
          .onClick(() => this.mapController?.setPitch(60, 500))
          .enabled(this.isMapReady)
      }
      .width('100%')
      .margin({ top: 6 })

      Button('Remove Layer')
        .width('100%')
        .margin({ top: 6 })
        .backgroundColor('#F44336')
        .fontColor(Color.White)
        .onClick(() => this.removeExtrusionLayer())
        .enabled(this.isMapReady && this.layerAdded)
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Fill Extrusion',
      subtitle: '3D extruded polygon layers',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
