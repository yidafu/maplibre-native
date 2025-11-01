/**
 * Query Source Features Test Page
 * 查询数据源要素
 * 参考 Android: QuerySourceFeaturesActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { GeoJson, GeoJsonSource, LatLng, MapLibreMap, MapView, ScreenPoint } from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import type { JsonObject } from '../../types/EntryTypes';

@Entry
@Component
struct QuerySourceFeaturesTestPage {
  private mapController: MapLibreMap | null = null;
  @State private sourceFeatureCount: number = 0;
  
  build() {
    Column() {
    TestPageLayout({
      title: 'Query Source Features',
      description: '查询数据源中的要素',
      showActionBar: true,
      mapContent: this.buildMapContent,
      controlPanel: this.buildControlPanel,
      actionButtons: this.buildActionButtons
    })
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  buildMapContent() {
    MapView({
      styleUrl: DEFAULT_STYLE_URLS.streets,
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 10,
      onMapReady: (map: MapLibreMap) => {
        this.mapController = map;
        map.jumpTo(0, 39.9, 116.4, 0, 12);
        this.addTestSource(map);
      }
    })
  }

  @Builder
  buildControlPanel() {
    Column({ space: 8 }) {
      Text('数据源要素')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
      
      Text(`要素数量: ${this.sourceFeatureCount}`)
        .fontSize(16)
        .fontColor('#2196F3')
    }
      .width('100%')
      .height('100%')
  }

  private addTestSource(map: MapLibreMap): void {
    // 添加测试 GeoJSON 数据源
    const props1: Record<string, Object> = { 'name': '测试点 1' };
    const props2: Record<string, Object> = { 'name': '测试点 2' };
    const geojsonData = GeoJson.featureCollection([
      GeoJson.pointFeature([116.4, 39.9], props1),
      GeoJson.pointFeature([116.5, 40.0], props2)
    ]);
    
    try {
      const source = new GeoJsonSource('test-source');
      source.setGeoJson(geojsonData);
      map.addSource(source);
      this.sourceFeatureCount = 2;
    } catch (error) {
      console.error(`添加数据源失败: ${error}`);
    }
  }

  @Builder
  buildActionButtons() {
    Button('查询数据源')
      .onClick(() => {
        showToast('querySourceFeatures API 待实现');
        // TODO: 实现 querySourceFeatures API
      })
  }
}
