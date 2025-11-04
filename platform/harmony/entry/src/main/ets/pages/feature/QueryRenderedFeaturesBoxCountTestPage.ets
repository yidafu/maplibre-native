import { MapLibreMap, MapView, ScreenPoint } from 'maplibre_harmony';
/**
 * Query Rendered Features Box Count Test Page
 * 框选查询要素计数
 * 参考 Android: QueryRenderedFeaturesBoxCountActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct QueryRenderedFeaturesBoxCountTestPage {
  private mapController: MapLibreMap | null = null;
  @State private featureCount: number = 0;
  @State private queryBox: string = '';
  
  build() {
    Column() {
    TestPageLayout({
      title: 'Query Box Count',
      description: '框选查询要素数量',
      showActionBar: true,
      mapContent: (): void => this.buildMapContent(),
      controlPanel: (): void => this.buildControlPanel(),
      actionButtons: (): void => this.buildActionButtons()
    })
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  buildMapContent() {
    MapView({
      styleUrl: DEFAULT_STYLE_URLS.bright,
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 5,
      onMapReady: (map: MapLibreMap) => {
        this.mapController = map;
        // map.jumpTo(0, 39.9, 116.4, 0, 14);
      }
    })
  }

  @Builder
  buildControlPanel() {
    Column({ space: 8 }) {
      Text(`查询区域: ${this.queryBox}`)
        .fontSize(12)
      
      Text(`要素数量: ${this.featureCount}`)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2196F3')
    }
    .width(220)
      .height('100%')
  }
  
  @Builder
  buildActionButtons() {
    Button('查询中心区域')
      .onClick(() => {
        this.queryFeaturesInBox(200, 200, 600, 600);
      })
    
    Button('查询全屏')
      .onClick(() => {
        this.queryFeaturesInBox(0, 0, 1080, 2400);
      })
  }

  private queryFeaturesInBox(left: number, top: number, right: number, bottom: number): void {
    if (!this.mapController) return;
    
    try {
      const features = this.mapController.queryRenderedFeaturesForBox(left, top, right, bottom);
      this.featureCount = features.length;
      this.queryBox = `${left},${top}-${right},${bottom}`;
      showToast(`查询到 ${features.length} 个要素`);
    } catch (error) {
      showToast(`查询失败: ${error}`);
    }
  }
}
