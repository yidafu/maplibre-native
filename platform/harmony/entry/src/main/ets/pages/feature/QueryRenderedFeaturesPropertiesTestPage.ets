import { MapLibreMap, NativeMapView, OnMapClickListener, ScreenPoint } from 'maplibre_harmony';
/**
 * Query Rendered Features Properties Test Page
 * 查询要素属性
 * 参考 Android: QueryRenderedFeaturesPropertiesActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, showToast } from '../common/TestUtils';

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
      mapContent: this.buildMapContent,
      controlPanel: this.buildControlPanel
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
        this.setupClickListener(map);
      }
    })
    .width('100%')
    .height('100%')
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
    const clickListener: OnMapClickListener = {
      onMapClick: (x: number, y: number): boolean => {
        this.queryFeatureAtPoint(x, y);
        return true;
      }
    };
    
    map.addOnMapClickListener(clickListener);
      .width('100%')

      .height('100%')
  }

  private queryFeatureAtPoint(x: number, y: number): void {
    if (!this.mapController) return;
    
    try {
      const features = this.mapController.queryRenderedFeaturesForPoint(x, y);
      
      if (features.length > 0) {
        const feature = features[0];
        const props = feature.properties || {};
        const propStr = JSON.stringify(props, null, 2);
        this.featureInfo = `类型: ${feature.type}\n图层: ${feature.layer || '未知'}\n属性:\n${propStr}`;
        showToast(`查询到 ${features.length} 个要素`);
      } else {
        this.featureInfo = '未查询到要素';
        showToast('未查询到要素');
      }
    } catch (error) {
      this.featureInfo = `查询失败: ${error}`;
    }
      .width('100%')

      .height('100%')
}

