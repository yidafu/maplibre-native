import { GeoJsonSource, LineLayer, MapLibreMap, NativeMapView } from 'maplibre_harmony';
/**
 * Line Layer Test Page
 * 线条图层测试
 * 参考 Android Line Layer 相关测试
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, showToast } from '../common/TestUtils';

@Entry
@Component
struct LineLayerTestPage {
  private mapController: MapLibreMap | null = null;
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Line Layer',
        description: '线条图层样式',
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
        map.jumpTo(0, 35, 105, 0, 5);
        this.addLineLayer(map);
      }
    })
    .width('100%')
    .height('100%')
  }

  private addLineLayer(map: MapLibreMap): void {
    try {
      const geojson = {
        type: 'FeatureCollection',
        features: [{
          type: 'Feature',
          geometry: {
            type: 'LineString',
            coordinates: [
              [116.4, 39.9],
              [115, 38],
              [113, 36],
              [121.5, 31.2]
            ]
          }
        }]
      };
      
      const source = new GeoJsonSource('line-source');
      source.setGeoJson(JSON.stringify(geojson));
      map.addSource(source);
      
      const layer = new LineLayer('line-layer', 'line-source');
      layer.setLineColor('#FF2196F3');
      layer.setLineWidth(5);
      layer.setLineOpacity(0.8);
      map.addLayer(layer);
    } catch (error) {
      console.error(`添加线条图层失败: ${error}`);
    }
  }
  
  @Builder
  buildActionButtons() {
    Button('改变宽度')
      .onClick(() => {
        if (this.mapController) {
          const layer = this.mapController.getLayer('line-layer');
          if (layer) {
            const width = 2 + Math.random() * 8;
            (layer as LineLayer).setLineWidth(width);
            showToast(`宽度: ${width.toFixed(1)}`);
          }
        }
      })
  }
}

