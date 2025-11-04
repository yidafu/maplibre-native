import { MapLibreMap, MapView } from 'maplibre_harmony';
/**
 * Query Rendered Features Box Symbol Count Test Page
 * 框选查询符号数量
 * 参考 Android: QueryRenderedFeaturesBoxSymbolCountActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, showToast } from '../common/TestUtils';

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
        mapContent: (): void => this.buildMapContent(),
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
        map.jumpTo(0, 39.9, 116.4, 0, 6);
      }
    })
      .width('100%')
      .height('100%')
  }

  @Builder
  buildActionButtons() {
    Column({ space: 8 }) {
      // 符号数量统计展示
      Column({ space: 4 }) {
        Text('符号要素统计')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .width('100%')

        Text(`符号数量: ${this.symbolCount}`)
          .fontSize(20)
          .fontColor('#2196F3')
          .fontWeight(FontWeight.Bold)
          .width('100%')
      }
      .width('100%')
      .padding(8)
      .backgroundColor('#f5f5f5')
      .borderRadius(4)
      .margin({ bottom: 8 })

      // 查询按钮
      Button('查询屏幕中心')
        .width('100%')
        .onClick(() => {
          this.countSymbols(300, 400, 780, 1200);
        })

      Button('查询左上角')
        .width('100%')
        .onClick(() => {
          this.countSymbols(0, 0, 540, 1200);
        })

      Button('查询全屏')
        .width('100%')
        .onClick(() => {
          this.countSymbols(0, 0, 1080, 2400);
        })
    }
    .width('100%')
  }

  private countSymbols(left: number, top: number, right: number, bottom: number): void {
    if (!this.mapController) {
      return;
    }

    try {
      // 查询所有 symbol 图层的要素
      const features = this.mapController.queryRenderedFeaturesForBox(left, top, right, bottom);

      // 过滤出符号要素
      const symbols = features.filter(f => {
        const layerId = f.layer;
        // f.geometry.type === "Point"
        return layerId && f.geometry.type === "Point";
      });

      this.symbolCount = symbols.length;
      showToast(`查询到 ${symbols.length} 个符号`);
    } catch (error) {
      showToast(`查询失败: ${error}`);
    }
  }
}
