import { MapLibreMap, MapView } from 'maplibre_harmony';
/**
 * Query Rendered Features Box Symbol Count Test Page
 * 框选查询符号数量
 * 参考 Android: QueryRenderedFeaturesBoxSymbolCountActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct QueryRenderedFeaturesBoxSymbolCountTestPage {
  private mapController: MapLibreMap | null = null;
  @State private symbolCount: number = 0;
  
  build() {
    Column() {
    TestPageLayout({
      title: 'Box Symbol Count',
      description: '框选查询符号数量',
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
      }
    })
    .width('100%')
    .height('100%')
  }

  @Builder
  buildControlPanel() {
    Column({ space: 8 }) {
      Text('符号要素统计')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
      
      Text(`符号数量: ${this.symbolCount}`)
        .fontSize(20)
        .fontColor('#2196F3')
        .fontWeight(FontWeight.Bold)
    }
      .width('100%')
      .height('100%')
  }

  @Builder
  buildActionButtons() {
    Button('查询屏幕中心')
      .onClick(() => {
        this.countSymbols(300, 400, 780, 1200);
      })
    
    Button('查询左上角')
      .onClick(() => {
        this.countSymbols(0, 0, 540, 1200);
      })
    
    Button('查询全屏')
      .onClick(() => {
        this.countSymbols(0, 0, 1080, 2400);
      })
  }

  private countSymbols(left: number, top: number, right: number, bottom: number): void {
    if (!this.mapController) return;
    
    try {
      // 查询所有 symbol 图层的要素
      const features = this.mapController.queryRenderedFeaturesForBox(left, top, right, bottom);
      
      // 过滤出符号要素
      const symbols = features.filter(f => {
        const layerId = (f as ESObject)['layer'] as string;
        return layerId && layerId.includes('symbol');
      });
      
      this.symbolCount = symbols.length;
      showToast(`查询到 ${symbols.length} 个符号`);
    } catch (error) {
      showToast(`查询失败: ${error}`);
    }
  }
}
