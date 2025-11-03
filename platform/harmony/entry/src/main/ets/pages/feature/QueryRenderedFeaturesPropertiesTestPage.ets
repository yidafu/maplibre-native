import { MapLibreMap, MapView, OnMapClickListener, ScreenPoint } from 'maplibre_harmony';
/**
 * Query Rendered Features Properties Test Page
 * 查询要素属性
 * 参考 Android: QueryRenderedFeaturesPropertiesActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct QueryRenderedFeaturesPropertiesTestPage {
  private mapController: MapLibreMap | null = null;
  @State private featureInfo: string = '点击地图查询要素';
  
  build() {
    Column() {
    TestPageLayout({
      title: 'Query Feature Properties',
      description: '查询要素属性',
      showActionBar: true,
      mapContent: (): void => this.buildMapContent(),
      controlPanel: (): void => this.buildControlPanel()
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
      initialZoom: 5,
      onMapReady: (map: MapLibreMap) => {
        this.mapController = map;
        map.jumpTo(0, 39.9, 116.4, 0, 6);
        this.setupClickListener(map);
      }
    })
  }

  @Builder
  buildControlPanel() {
    Column({ space: 8 }) {
      Text('要素信息')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
      
      Text(this.featureInfo)
        .fontSize(11)
        .fontColor('#666666')
        .maxLines(5)
    }
    .width(280)
    .padding(12)
    .width('100%')
    .height('100%')
  }

  private setupClickListener(map: MapLibreMap): void {
    class MapClickListener implements OnMapClickListener {
      page: QueryRenderedFeaturesPropertiesTestPage;
      
      constructor(page: QueryRenderedFeaturesPropertiesTestPage) {
        this.page = page;
      }
      
      onMapClick(x: number, y: number): boolean {
        this.page.queryFeatureAtPoint(x, y);
        return true;
      }
    }
    
    map.addOnMapClickListener(new MapClickListener(this));
  }

  private queryFeatureAtPoint(x: number, y: number): void {
    if (!this.mapController) return;

    try {
      const features = this.mapController.queryRenderedFeaturesForPoint(x, y);

      if (features.length > 0) {
        const feature = features[0];
        const props: Record<string, Object> = feature.properties || {};
        const propStr = JSON.stringify(props, null, 2);
        const layerName: string = feature.layer || '未知';
        this.featureInfo = `类型: ${feature.type}\n图层: ${layerName}\n属性:\n${propStr}`;
        showToast(`查询到 ${features.length} 个要素`);
      } else {
        this.featureInfo = '未查询到要素';
        showToast('未查询到要素');
      }
    } catch (error) {
      this.featureInfo = `查询失败: ${error}`;
    }
  }
}
