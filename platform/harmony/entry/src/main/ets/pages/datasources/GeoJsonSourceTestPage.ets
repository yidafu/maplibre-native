/**
 * GeoJsonSourceTestPage - Real-time and clustered GeoJSON sources.
 *
 * Demonstrates adding GeoJSON data directly, updating it in real-time,
 * and using GeoJSON clustering to group nearby points.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, GeoJsonSource, CircleLayer, FillLayer, GeoJsonOptionsBuilder } from 'maplibre_harmony';
import { DEFAULT_MAP_CONFIG, TEST_LOCATIONS, showToast } from '../common/TestUtils';
import { LatLng } from 'maplibre_harmony';
import type { IFeature, IFeatureCollection } from 'maplibre_harmony';

@Entry
@Component
struct GeoJsonSourceTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private currentMode: string = 'none';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready';
    console.info('[GeoJsonSourceTestPage] Map ready');
  };

  /**
   * Add a GeoJSON source with a few point features rendered as circles.
   */
  private addSimpleGeoJson(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) {
      this.statusMessage = 'Style not yet loaded';
      return;
    }

    try {
      this.removeCurrentSource();
      this.currentMode = 'simple';

      const plainFeatures: IFeature[] = [
        {
          type: 'Feature',
          geometry: { type: 'Point', coordinates: [116.4074, 39.9042] },
          properties: { name: 'Beijing', population: 21540000 }
        },
        {
          type: 'Feature',
          geometry: { type: 'Point', coordinates: [121.4737, 31.2304] },
          properties: { name: 'Shanghai', population: 24870000 }
        },
        {
          type: 'Feature',
          geometry: { type: 'Point', coordinates: [113.2644, 23.1291] },
          properties: { name: 'Guangzhou', population: 18680000 }
        },
        {
          type: 'Feature',
          geometry: { type: 'Point', coordinates: [114.0579, 22.5431] },
          properties: { name: 'Shenzhen', population: 17560000 }
        }
      ];
      const collection: IFeatureCollection = { type: 'FeatureCollection', features: plainFeatures };
      const geojson = JSON.stringify(collection);

      const source = GeoJsonSource.fromGeoJson('test-geojson-source', geojson);
      style.addSource(source);

      const circleLayer = new CircleLayer('test-circle-layer', 'test-geojson-source');
      style.addLayer(circleLayer);

      this.statusMessage = 'Simple GeoJSON source added with 4 cities';
      showToast('GeoJSON source added');
    } catch (error) {
      this.statusMessage = `Error: ${error instanceof Error ? error.message : String(error)}`;
    }
  }

  /**
   * Add a clustered GeoJSON source with many random points.
   */
  private addClusteredGeoJson(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) {
      this.statusMessage = 'Style not yet loaded';
      return;
    }

    try {
      this.removeCurrentSource();
      this.currentMode = 'cluster';

      // Generate random features around Beijing
      const features: string[] = [];
      for (let i = 0; i < 50; i++) {
        const lat = 39.9 + (Math.random() - 0.5) * 2;
        const lng = 116.4 + (Math.random() - 0.5) * 2;
        const clusterFeature: IFeature = {
          type: 'Feature',
          geometry: { type: 'Point', coordinates: [lng, lat] },
          properties: { id: i, value: Math.floor(Math.random() * 100) }
        };
        features.push(JSON.stringify(clusterFeature));
      }

      const geojson = `{"type":"FeatureCollection","features":[${features.join(',')}]}`;

      const options = new GeoJsonOptionsBuilder()
        .withCluster(true)
        .withClusterRadius(50)
        .withClusterMaxZoom(14)
        .build();

      const source = GeoJsonSource.fromGeoJson('cluster-geojson-source', geojson, options);
      style.addSource(source);

      // Add circle layer for clustered points
      const circleLayer = new CircleLayer('cluster-circle-layer', 'cluster-geojson-source');
      style.addLayer(circleLayer);

      // Move to Beijing area
      this.mapController.jumpTo(0, 39.9, 116.4, 0, 9);

      this.statusMessage = 'Clustered GeoJSON source added with 50 random points near Beijing';
      showToast('Clustered source added');
    } catch (error) {
      this.statusMessage = `Error: ${error instanceof Error ? error.message : String(error)}`;
    }
  }

  /**
   * Update GeoJSON data in real-time by adding a new random point.
   */
  private updateGeoJson(): void {
    if (!this.mapController || this.currentMode === 'none') return;
    const style = this.mapController.getStyle();
    if (!style) return;

    try {
      const source = style.getSource('test-geojson-source') as GeoJsonSource;
      if (!source || !source.setGeoJson) {
        this.statusMessage = 'No GeoJSON source to update or setGeoJson not available';
        return;
      }

      const randLat = 30 + Math.random() * 10;
      const randLng = 110 + Math.random() * 15;
      const updatedFeature: IFeature = {
        type: 'Feature',
        geometry: { type: 'Point', coordinates: [randLng, randLat] },
        properties: { name: `Random ${Math.floor(Math.random() * 1000)}`, population: Math.floor(Math.random() * 10000000) }
      };
      const updateCollection: IFeatureCollection = { type: 'FeatureCollection', features: [updatedFeature] };
      const geojson = JSON.stringify(updateCollection);

      source.setGeoJson(geojson);
      this.statusMessage = `Updated GeoJSON with random point at ${randLat.toFixed(2)}, ${randLng.toFixed(2)}`;
      showToast('GeoJSON data updated');
    } catch (error) {
      this.statusMessage = `Error: ${error instanceof Error ? error.message : String(error)}`;
    }
  }

  /**
   * List all sources currently in the style.
   */
  private listSources(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    const sources = style.getSources();
    const names = sources.map((s): string => s.getId()).join(', ') || '(none)';
    this.statusMessage = `Sources: ${names}`;
    showToast(`Found ${sources.length} sources`);
  }

  private removeCurrentSource(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    try {
      if (this.currentMode === 'simple') {
        style.removeLayer('test-circle-layer');
        style.removeSource('test-geojson-source');
      } else if (this.currentMode === 'cluster') {
        style.removeLayer('cluster-circle-layer');
        style.removeSource('cluster-geojson-source');
      }
      this.currentMode = 'none';
    } catch (error) {
      console.error('[GeoJsonSourceTestPage] Remove error:', error);
    }
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
        .padding(10)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)

      Text('GeoJSON Source Controls')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Button('Add Simple GeoJSON (4 cities)')
        .width('100%')
        .backgroundColor('#2196F3')
        .margin({ bottom: 6 })
        .onClick((): void => this.addSimpleGeoJson())
        .enabled(this.isMapReady)

      Button('Add Clustered GeoJSON (50 points)')
        .width('100%')
        .backgroundColor('#4CAF50')
        .margin({ bottom: 6 })
        .onClick((): void => this.addClusteredGeoJson())
        .enabled(this.isMapReady)

      Button('Update GeoJSON Data')
        .width('100%')
        .backgroundColor('#FF9800')
        .margin({ bottom: 6 })
        .onClick((): void => this.updateGeoJson())
        .enabled(this.isMapReady && this.currentMode !== 'none')

      Button('List Sources')
        .width('100%')
        .backgroundColor('#607D8B')
        .margin({ bottom: 6 })
        .onClick((): void => this.listSources())
        .enabled(this.isMapReady)

      Button('Remove Source')
        .width('100%')
        .backgroundColor('#E91E63')
        .onClick((): void => {
          this.removeCurrentSource();
          this.statusMessage = 'Source and layers removed';
          showToast('Source removed');
        })
        .enabled(this.isMapReady && this.currentMode !== 'none')
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'GeoJSON Source',
      subtitle: 'Real-time and clustered GeoJSON',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
