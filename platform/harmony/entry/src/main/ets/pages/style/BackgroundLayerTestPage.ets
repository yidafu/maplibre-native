import { BackgroundLayer, MapLibreMap, MapView } from 'maplibre_harmony';
/**
 * Background Layer Test Page
 * 背景图层测试
 * 参考 Android BackgroundLayer 测试
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct BackgroundLayerTestPage {
  private scroller: Scroller = new Scroller();
  private mapController: MapLibreMap | null = null;
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Background Layer',
        description: '背景图层颜色',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        actionButtons: (): void => this.buildActionButtons()
      })
    }
    .width('100%')

    .height('100%')
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
        map.jumpTo(0, 0, 0, 0, 2);
      }
    })
  }

  @Builder
  buildActionButtons() {
    Scroll(this.scroller) {
      Column({ space: 8 }) {
        Button('蓝色背景')
          .width('100%')
          .onClick(() => {
            this.changeBackgroundColor('#1E88E5');
          })
        
        Button('绿色背景')
          .width('100%')
          .onClick(() => {
            this.changeBackgroundColor('#43A047');
          })
        
        Button('深色背景')
          .width('100%')
          .onClick(() => {
            this.changeBackgroundColor('#212121');
          })
      }
      .width('100%')
      .padding(8)
    }
    .scrollBar(BarState.Auto)
    .scrollable(ScrollDirection.Vertical)
  }
  
  private changeBackgroundColor(color: string): void {
    if (!this.mapController) return;
    
    try {
      const layers = this.mapController.getLayers();
      for (const layer of layers) {
        if (layer instanceof BackgroundLayer) {
          layer.setBackgroundColor(color)
        }
      }
      showToast('未找到背景图层');
    } catch (error) {
      showToast(`更改失败: ${error}`);
    }
  }
}

