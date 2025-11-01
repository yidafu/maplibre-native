import { HillshadeLayer, MapLibreMap, MapView, RasterDemSource } from 'maplibre_harmony';
/**
 * Hillshade Layer Test Page
 * 山体阴影图层测试
 * 参考 Android: HillshadeLayerActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct HillshadeLayerTestPage {
  private mapController: MapLibreMap | null = null;
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Hillshade Layer',
        description: '山体阴影效果',
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
    MapView({
      styleUrl: DEFAULT_STYLE_URLS.streets,
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 10,
      onMapReady: (map: MapLibreMap) => {
        this.mapController = map;
        map.jumpTo(0, 30, 105, 0, 8);
        this.addHillshadeLayer(map);
      }
    })
  }

  private addHillshadeLayer(map: MapLibreMap): void {
    try {
      const source = new RasterDemSource('hillshade-source');
      source.setUrl('https://demotiles.maplibre.org/terrain-tiles/{z}/{x}/{y}.png');
      source.setTileSize(256);
      map.addSource(source);
      
      const layer = new HillshadeLayer('hillshade-layer', 'hillshade-source');
      layer.setHillshadeExaggeration(0.5);
      layer.setHillshadeIlluminationDirection(45);
      map.addLayer(layer);
      
      showToast('山体阴影已添加');
    } catch (error) {
      showToast(`添加失败: ${error}`);
    }
  }
  
  @Builder
  buildActionButtons() {
    Button('调整光照方向')
      .onClick(() => {
        if (this.mapController) {
          const layer = this.mapController.getLayer('hillshade-layer');
          if (layer) {
            const direction = Math.random() * 360;
            (layer as HillshadeLayer).setHillshadeIlluminationDirection(direction);
            showToast(`光照方向: ${direction.toFixed(0)}°`);
          }
        }
      })
    
    Button('调整夸张度')
      .onClick(() => {
        if (this.mapController) {
          const layer = this.mapController.getLayer('hillshade-layer');
          if (layer) {
            const exaggeration = Math.random();
            (layer as HillshadeLayer).setHillshadeExaggeration(exaggeration);
            showToast(`夸张度: ${exaggeration.toFixed(2)}`);
          }
        }
      })
  }
}

