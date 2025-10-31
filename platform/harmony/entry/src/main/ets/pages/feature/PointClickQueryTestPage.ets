import { MapLibreMap, NativeMapView, OnMapClickListener, ScreenPoint } from 'maplibre_harmony';
/**
 * ScreenPoint Click Query Test Page
 * 点击查询要素
 * 补充 Feature 测试
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, showToast } from '../common/TestUtils';

@Entry
@Component
struct PointClickQueryTestPage {
  private mapController: MapLibreMap | null = null;
  @State private queryResult: string = '点击地图查询';
  @State private queryCount: number = 0;
  
  build() {
    Column() {
    TestPageLayout({
      title: 'Point Click Query',
      description: '点击查询要素信息',
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
        map.jumpTo(0, 39.9, 116.4, 0, 14);
        this.setupClickListener(map);
      }
    })
    .width('100%')
    .height('100%')
  }

  @Builder
  buildControlPanel() {
    Column({ space: 8 }) {
      Text(`查询次数: ${this.queryCount}`)
        .fontSize(12)
      
      Text(this.queryResult)
        .fontSize(11)
        .fontColor('#333333')
        .maxLines(8)
    }
    .width(280)
      .height('100%')
  }
  
  private setupClickListener(map: MapLibreMap): void {
    const clickListener: OnMapClickListener = {
      onMapClick: (x: number, y: number): boolean => {
        this.queryPoint(x, y);
        return true;
      }
    };
    
    map.addOnMapClickListener(clickListener);
      .width('100%')
      .height('100%')
  }

  private queryPoint(x: number, y: number): void {
    if (!this.mapController) return;
    
    try {
      const features = this.mapController.queryRenderedFeaturesForPoint(x, y);
      this.queryCount++;
      
      if (features.length > 0) {
        const feature = features[0];
        const layerId = (feature as ESObject)['layer'] as string || '未知';
        const type = feature.type || '未知';
        this.queryResult = `查询点: (${x.toFixed(0)}, ${y.toFixed(0)})\n要素数: ${features.length}\n图层: ${layerId}\n类型: ${type}`;
      } else {
        this.queryResult = `查询点: (${x.toFixed(0)}, ${y.toFixed(0)})\n未查询到要素`;
      }
    } catch (error) {
      this.queryResult = `查询失败: ${error}`;
    }
      .width('100%')
      .height('100%')
}

