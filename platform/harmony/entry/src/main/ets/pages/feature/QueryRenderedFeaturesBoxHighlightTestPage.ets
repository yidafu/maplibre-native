import { MapLibreMap, NativeMapView } from 'maplibre_harmony';
/**
 * Query Rendered Features Box Highlight Test Page  
 * 框选高亮要素
 * 参考 Android: QueryRenderedFeaturesBoxHighlightActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, showToast } from '../common/TestUtils';

@Entry
@Component
struct QueryRenderedFeaturesBoxHighlightTestPage {
  private mapController: MapLibreMap | null = null;
  @State private highlightedCount: number = 0;
  
  build() {
    Column() {
    TestPageLayout({
      title: 'Box Highlight Features',
      description: '框选高亮显示要素',
      showActionBar: true,
      mapContent: this.buildMapContent,
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
        map.jumpTo(0, 39.9, 116.4, 0, 14);
      }
    })
    .width('100%')
    .height('100%')
  }

  @Builder
  buildActionButtons() {
    Button('查询并高亮')
      .onClick(() => {
        this.queryAndHighlight();
      })
    
    Button('清除高亮')
      .onClick(() => {
        this.clearHighlight();
      })
  }

  private queryAndHighlight(): void {
    if (!this.mapController) return;
    
    try {
      // 查询屏幕中心区域
      const features = this.mapController.queryRenderedFeaturesForBox(300, 400, 780, 1200, ['building']);
      
      this.highlightedCount = features.length;
      showToast(`查询到 ${features.length} 个建筑物`);
      
      // TODO: 实现高亮显示逻辑（需要修改图层样式）
      console.warn('Highlight feature: stub implementation');
    } catch (error) {
      showToast(`查询失败: ${error}`);
    }
      .width('100%')
      .height('100%')
  }

  private clearHighlight(): void {
    this.highlightedCount = 0;
    showToast('高亮已清除');
    // TODO: 实现清除高亮逻辑
      .width('100%')
      .height('100%')
}

