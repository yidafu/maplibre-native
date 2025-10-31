import { BackgroundLayer, MapLibreMap, NativeMapView } from 'maplibre_harmony';
/**
 * Background Layer Test Page
 * 背景图层测试
 * 参考 Android BackgroundLayer 测试
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, showToast } from '../common/TestUtils';

@Entry
@Component
struct BackgroundLayerTestPage {
  private mapController: MapLibreMap | null = null;
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Background Layer',
        description: '背景图层颜色',
        showActionBar: true,
        mapContent: this.buildMapContent,
        actionButtons: this.buildActionButtons
      })
    }
    .width('100%')

    .height('100%')
  }

  @Builder
  buildMapContent() {
    NativeMapView({
      styleUrl: DEFAULT_STYLE_URLS.streets,
      onMapReady: (map: MapLibreMap) => {
        this.mapController = map;
        map.jumpTo(0, 0, 0, 0, 2);
      }
    })
    .width('100%')
    .height('100%')
  }

  @Builder
  buildActionButtons() {
    Button('蓝色背景')
      .onClick(() => {
        this.changeBackgroundColor('#1E88E5');
      })
    
    Button('绿色背景')
      .onClick(() => {
        this.changeBackgroundColor('#43A047');
      })
    
    Button('深色背景')
      .onClick(() => {
        this.changeBackgroundColor('#212121');
      })
  }
  
  private changeBackgroundColor(color: string): void {
    if (!this.mapController) return;
    
    try {
      const layers = this.mapController.getLayers();
      for (const layer of layers) {
        const layerObj = layer as ESObject;
        const type = layerObj['type'] as string;
        if (type === 'background') {
          (layer as BackgroundLayer).setBackgroundColor(color);
          showToast(`背景颜色已更改`);
          return;
        }
      }
      showToast('未找到背景图层');
    } catch (error) {
      showToast(`更改失败: ${error}`);
    }
  }
}

