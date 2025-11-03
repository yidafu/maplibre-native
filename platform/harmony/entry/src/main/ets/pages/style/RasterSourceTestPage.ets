import { MapLibreMap, MapView, RasterLayer, RasterSource } from 'maplibre_harmony';
/**
 * Raster Source Test Page
 * 栅格数据源测试
 * 参考 Android RasterSource 测试
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct RasterSourceTestPage {
  private scroller: Scroller = new Scroller();
  private mapController: MapLibreMap | null = null;
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Raster Source',
        description: '栅格瓦片数据源',
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
        map.jumpTo(0, 39.9, 116.4, 0, 10);
      }
    })
  }

  @Builder
  buildActionButtons() {
    Scroll(this.scroller) {
      Column({ space: 8 }) {
      Button('添加栅格图层')
            .onClick(() => {
              this.addRasterLayer();
            })
      }
      .width('100%')
      .padding(8)
    }
    .scrollBar(BarState.Auto)
    .scrollable(ScrollDirection.Vertical)
  
  }
  
  private addRasterLayer(): void {
    if (!this.mapController) return;
    
    try {
      const source = new RasterSource('raster-source');
      source.setUrl('https://tile.openstreetmap.org/{z}/{x}/{y}.png');
      source.setTileSize(256);
      this.mapController.addSource(source);
      
      const layer = new RasterLayer('raster-layer', 'raster-source');
      layer.setRasterOpacity(0.5);
      this.mapController.addLayer(layer);
      
      showToast('栅格图层已添加');
    } catch (error) {
      showToast(`添加失败: ${error}`);
    }
  }
}

