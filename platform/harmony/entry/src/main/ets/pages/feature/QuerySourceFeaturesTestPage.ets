import { GeoJsonSource, LatLng, MapLibreMap, NativeMapView, ScreenPoint } from 'maplibre_harmony';
/**
 * Query Source Features Test Page
 * 查询数据源要素
 * 参考 Android: QuerySourceFeaturesActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, showToast } from '../common/TestUtils';

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
    NativeMapView({
      styleUrl: DEFAULT_STYLE_URLS.streets,
      onMapReady: (map: MapLibreMap) => {
        this.mapController = map;
        map.jumpTo(0, 39.9, 116.4, 0, 12);
        this.addTestSource(map);
      }
    })
    .width('100%')
    .height('100%')
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
    const geojsonData = {
      type: 'FeatureCollection',
      features: [
        {
          type: 'Feature',
          geometry: {
            type: 'Point',
            coordinates: [116.4, 39.9]
          },
          properties: {
            name: '测试点 1'
          }
        },
        {
          type: 'Feature',
          geometry: {
            type: 'Point',
            coordinates: [116.5, 40.0]
          },
          properties: {
            name: '测试点 2'
          }
        }
      ]
    };
    
    try {
      const source = new GeoJsonSource('test-source');
      source.setGeoJson(JSON.stringify(geojsonData));
      map.addSource(source);
      this.sourceFeatureCount = geojsonData.features.length;
    } catch (error) {
      console.error(`添加数据源失败: ${error}`);
    }
      .width('100%')
      .height('100%')
  }

  @Builder
  buildActionButtons() {
    Button('查询数据源')
      .onClick(() => {
        showToast('querySourceFeatures API 待实现');
        // TODO: 实现 querySourceFeatures API
      })
    .width('100%')
    .height('100%')
}
