/**
 * SourceFeaturesTestPage - Query features from a specific source.
 *
 * Uses querySourceFeatures to retrieve all features from a
 * specified source without requiring them to be rendered.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, GeoJsonSource, CircleLayer } from 'maplibre_harmony';
import { DEFAULT_MAP_CONFIG, showToast } from '../common/TestUtils';
import type { IFeature } from 'maplibre_harmony';
import { FeatureCollection } from 'maplibre_harmony/src/main/cpp/types/libmaplibre/geojson/FeatureCollection';

@Entry
@Component
struct SourceFeaturesTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private queryResult: string = '(no query yet)';
  @State private featureCount: number = 0;
  @State private sourceReady: boolean = false;
  private sourceId: string = 'query-source';

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready. Add a GeoJSON source to query.';

    // Add a GeoJSON source programmatically for querying
    setTimeout(() => {
      this.addQuerySource();
    }, 500);

    console.info('[SourceFeaturesTestPage] Map ready');
  };

  /**
   * Add a GeoJSON source with sample city data.
   */
  private addQuerySource(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    try {
      const geojson = JSON.stringify({
        type: 'FeatureCollection',
        features: [
          { type: 'Feature', geometry: { type: 'Point', coordinates: [116.4074, 39.9042] }, properties: { name: 'Beijing', country: 'China', population: 21540000 } },
          { type: 'Feature', geometry: { type: 'Point', coordinates: [121.4737, 31.2304] }, properties: { name: 'Shanghai', country: 'China', population: 24870000 } },
          { type: 'Feature', geometry: { type: 'Point', coordinates: [113.2644, 23.1291] }, properties: { name: 'Guangzhou', country: 'China', population: 18680000 } },
          { type: 'Feature', geometry: { type: 'Point', coordinates: [114.0579, 22.5431] }, properties: { name: 'Shenzhen', country: 'China', population: 17560000 } },
          { type: 'Feature', geometry: { type: 'Point', coordinates: [120.1551, 30.2741] }, properties: { name: 'Hangzhou', country: 'China', population: 11940000 } },
          { type: 'Feature', geometry: { type: 'Point', coordinates: [104.0668, 30.5728] }, properties: { name: 'Chengdu', country: 'China', population: 16330000 } }
        ]
      } as FeatureCollection);

      const source = GeoJsonSource.fromGeoJson(this.sourceId, geojson);
      style.addSource(source);

      const circleLayer = new CircleLayer('query-circle-layer', this.sourceId);
      style.addLayer(circleLayer);

      this.sourceReady = true;
      this.statusMessage = 'Source added with 6 cities. Click "Query Source" to inspect.';
      showToast('Source ready for querying');
    } catch (error) {
      this.statusMessage = `Error adding source: ${error instanceof Error ? error.message : String(error)}`;
    }
  }

  /**
   * Query all features from the source.
   */
  private queryAllSourceFeatures(): void {
    if (!this.mapController) {
      showToast('Map not ready');
      return;
    }

    try {
      const features: IFeature[] = this.mapController.querySourceFeatures(this.sourceId);
      this.featureCount = features.length;
      this.statusMessage = `Queried source: ${features.length} features`;

      if (features.length === 0) {
        this.queryResult = 'No features found in the source.';
        return;
      }

      let result = `Source "${this.sourceId}" contains ${features.length} features:\n\n`;
      for (let i = 0; i < Math.min(features.length, 10); i++) {
        const props = (features[i] as Object as Record<string, Object>).properties as Object as Record<string, Object> || {};
        const name = props['name'] || 'unknown';
        const pop = props['population'] || 'N/A';
        const country = props['country'] || 'N/A';
        result += `${i + 1}. ${name} (${country}, pop: ${pop})\n`;
      }

      this.queryResult = result;
      showToast(`Found ${features.length} features in source`);
    } catch (error) {
      this.statusMessage = `Query error: ${error instanceof Error ? error.message : String(error)}`;
    }
  }

  /**
   * Query features filtered by a property condition (population > 15 million).
   */
  private queryFilteredFeatures(): void {
    if (!this.mapController) return;

    try {
      // Query without source layer filter, using a filter expression
      const features: IFeature[] = this.mapController.querySourceFeatures(
        this.sourceId,
        undefined,
        // Note: filter expressions may vary in supported format
        undefined
      );

      // Apply client-side filtering for display
      const filtered = features.filter(f => {
        const props = (f as Object as Record<string, Object>).properties as Object as Record<string, Object> || {};
        const pop = Number(props['population'] || 0);
        return pop > 15000000;
      });

      this.featureCount = filtered.length;
      this.statusMessage = `Filtered query (pop > 15M): ${filtered.length} features`;

      if (filtered.length === 0) {
        this.queryResult = 'No features matched the filter.';
        return;
      }

      let result = 'Cities with population > 15,000,000:\n\n';
      for (let i = 0; i < filtered.length; i++) {
        const props = (filtered[i] as Object as Record<string, Object>).properties as Object as Record<string, Object> || {};
        result += `${i + 1}. ${props['name']} - ${Number(props['population']).toLocaleString()}\n`;
      }

      this.queryResult = result;
      showToast(`Filtered: ${filtered.length} cities > 15M population`);
    } catch (error) {
      this.statusMessage = `Filter query error: ${error instanceof Error ? error.message : String(error)}`;
    }
  }

  /**
   * Get the list of all sources in the current style.
   */
  private listSources(): void {
    if (!this.mapController) return;
    const style = this.mapController.getStyle();
    if (!style) return;

    const sources = style.getSources();
    const names = sources.map(s => {
      const srcInfo = `${s.getId()} (${(s as Object as Record<string, Object>)._TYPE_ || 'unknown'})`;
      return srcInfo;
    }).join('\n');

    this.statusMessage = `Style has ${sources.length} sources`;
    this.queryResult = `All sources:\n${names || '(none)'}`;
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

      Text('Source Features')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 12, bottom: 8 })

      Text('Query features directly from a data source, bypassing the renderer.')
        .fontSize(12)
        .fontColor('#666')
        .width('100%')
        .lineHeight(18)
        .margin({ bottom: 12 })

      Button('Query All Source Features')
        .width('100%')
        .backgroundColor('#2196F3')
        .margin({ bottom: 6 })
        .onClick(() => this.queryAllSourceFeatures())
        .enabled(this.isMapReady && this.sourceReady)

      Button('Filtered Query (pop > 15M)')
        .width('100%')
        .backgroundColor('#4CAF50')
        .margin({ bottom: 6 })
        .onClick(() => this.queryFilteredFeatures())
        .enabled(this.isMapReady && this.sourceReady)

      Button('List All Sources in Style')
        .width('100%')
        .backgroundColor('#FF9800')
        .onClick(() => this.listSources())
        .enabled(this.isMapReady)

      Divider()
        .margin({ top: 12, bottom: 8 })

      Text('Results')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 4 })

      Text(`Features: ${this.featureCount}`)
        .fontSize(12)
        .fontColor('#2196F3')
        .width('100%')
        .margin({ bottom: 4 })

      Scroll() {
        Text(this.queryResult)
          .fontSize(12)
          .fontColor('#333')
          .width('100%')
          .lineHeight(18)
      }
      .width('100%')
      .constraintSize({ maxHeight: 150 })
      .backgroundColor('#FAFAFA')
      .borderRadius(4)
      .padding(8)
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Source Features',
      subtitle: 'Query features from a data source',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
