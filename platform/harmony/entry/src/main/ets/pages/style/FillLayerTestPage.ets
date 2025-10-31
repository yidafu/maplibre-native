import { FillLayer, GeoJsonSource, MapLibreMap, NativeMapView, Polygon } from 'maplibre_harmony';
/**
 * Fill Layer Test Page
 * 填充图层测试
 * 参考 Android Fill Layer 相关测试
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, showToast } from '../common/TestUtils';

@Entry
@Component
struct FillLayerTestPage {
  private mapController: MapLibreMap | null = null;
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Fill Layer',
        description: '填充图层样式',
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
        this.addFillLayer(map);
      }
    })
    .width('100%')
    .height('100%')
  }

  private addFillLayer(map: MapLibreMap): void {
    try {
      const geojson = {
        type: 'FeatureCollection',
        features: [{
          type: 'Feature',
          geometry: {
            type: 'Polygon',
            coordinates: [[
              [116.3, 39.8],
              [116.5, 39.8],
              [116.5, 40.0],
              [116.3, 40.0],
              [116.3, 39.8]
            ]]
          }
        }]
      };
      
      const source = new GeoJsonSource('fill-source');
      source.setGeoJson(JSON.stringify(geojson));
      map.addSource(source);
      
      const layer = new FillLayer('fill-layer', 'fill-source');
      layer.setFillColor('#8033B5E5');
      layer.setFillOpacity(0.6);
      layer.setFillOutlineColor('#FF2196F3');
      map.addLayer(layer);
    } catch (error) {
      console.error(`添加填充图层失败: ${error}`);
    }
  }
  
  @Builder
  buildActionButtons() {
    Button('改变颜色')
      .onClick(() => {
        if (this.mapController) {
          const layer = this.mapController.getLayer('fill-layer');
          if (layer) {
            (layer as FillLayer).setFillColor('#80FF9800');
            showToast('颜色已更改');
          }
        }
      })
  }
}

