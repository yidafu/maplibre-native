import { GeoJsonSource, MapLibreMap, NativeMapView, Point, SymbolLayer } from 'maplibre_harmony';
/**
 * Symbol Layer Test Page
 * 符号图层测试
 * 参考 Android: SymbolLayerActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, TEST_LOCATIONS, showToast } from '../common/TestUtils';

@Entry
@Component
struct SymbolLayerTestPage {
  private mapController: MapLibreMap | null = null;
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Symbol Layer',
        description: '符号图层功能测试',
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
        map.jumpTo(0, 35, 105, 0, 4);
      }
    })
    .width('100%')
    .height('100%')
  }

  @Builder
  buildActionButtons() {
    Button('添加符号图层')
      .onClick(() => {
        this.addSymbolLayer();
      })
    
    Button('移除符号图层')
      .onClick(() => {
        if (this.mapController) {
          try {
            this.mapController.removeLayer('symbol-layer');
            this.mapController.removeSource('symbol-source');
            showToast('符号图层已移除');
          } catch (error) {
            showToast(`移除失败: ${error}`);
          }
        }
      })
  }
  
  private addSymbolLayer(): void {
    if (!this.mapController) return;
    
    try {
      const geojson = {
        type: 'FeatureCollection',
        features: [
          {
            type: 'Feature',
            geometry: { type: 'Point', coordinates: [116.4, 39.9] },
            properties: { title: '北京', icon: 'marker' }
          },
          {
            type: 'Feature',
            geometry: { type: 'Point', coordinates: [121.5, 31.2] },
            properties: { title: '上海', icon: 'marker' }
          }
        ]
      };
      
      const source = new GeoJsonSource('symbol-source');
      source.setGeoJson(JSON.stringify(geojson));
      this.mapController.addSource(source);
      
      const layer = new SymbolLayer('symbol-layer', 'symbol-source');
      layer.setTextField(['get', 'title']);
      layer.setTextSize(14);
      layer.setTextColor('#2196F3');
      this.mapController.addLayer(layer);
      
      showToast('符号图层已添加');
    } catch (error) {
      showToast(`添加失败: ${error}`);
    }
  }
}

