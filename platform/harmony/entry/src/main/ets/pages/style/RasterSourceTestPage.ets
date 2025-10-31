import { MapLibreMap, NativeMapView, RasterLayer, RasterSource } from 'maplibre_harmony';
/**
 * Raster Source Test Page
 * 栅格数据源测试
 * 参考 Android RasterSource 测试
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, showToast } from '../common/TestUtils';

@Entry
@Component
struct RasterSourceTestPage {
  private mapController: MapLibreMap | null = null;
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Raster Source',
        description: '栅格瓦片数据源',
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
        map.jumpTo(0, 39.9, 116.4, 0, 10);
      }
    })
    .width('100%')
    .height('100%')
  }

  @Builder
  buildActionButtons() {
    Button('添加栅格图层')
      .onClick(() => {
        this.addRasterLayer();
      })
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

