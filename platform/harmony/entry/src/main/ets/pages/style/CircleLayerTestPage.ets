import { CircleLayer, GeoJsonSource, MapLibreMap, NativeMapView, ScreenPoint } from 'maplibre_harmony';
/**
 * Circle Layer Test Page
 * 圆形图层测试
 * 参考 Android: CircleLayerActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, showToast } from '../common/TestUtils';

@Entry
@Component
struct CircleLayerTestPage {
  private mapController: MapLibreMap | null = null;
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Circle Layer',
        description: '圆形图层样式测试',
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
        this.addCircleLayer(map);
      }
    })
    .width('100%')
    .height('100%')
  }

  private addCircleLayer(map: MapLibreMap): void {
    try {
      const geojson = {
        type: 'FeatureCollection',
        features: [
          { type: 'Feature', geometry: { type: 'Point', coordinates: [116.4, 39.9] } },
          { type: 'Feature', geometry: { type: 'Point', coordinates: [121.5, 31.2] } },
          { type: 'Feature', geometry: { type: 'Point', coordinates: [113.3, 23.1] } },
          { type: 'Feature', geometry: { type: 'Point', coordinates: [114.1, 22.5] } }
        ]
      };
      
      const source = new GeoJsonSource('circle-source');
      source.setGeoJson(JSON.stringify(geojson));
      map.addSource(source);
      
      const layer = new CircleLayer('circle-layer', 'circle-source');
      layer.setCircleRadius(20);
      layer.setCircleColor('#FF2196F3');
      layer.setCircleOpacity(0.8);
      layer.setCircleStrokeWidth(2);
      layer.setCircleStrokeColor('#FFFFFF');
      map.addLayer(layer);
    } catch (error) {
      console.error(`添加圆形图层失败: ${error}`);
    }
  }
  
  @Builder
  buildActionButtons() {
    Button('改变颜色')
      .onClick(() => {
        if (this.mapController) {
          try {
            const layer = this.mapController.getLayer('circle-layer');
            if (layer) {
              const colors = ['#FF2196F3', '#FFFF9800', '#FF4CAF50', '#FFF44336'];
              const randomColor = colors[Math.floor(Math.random() * colors.length)];
              (layer as CircleLayer).setCircleColor(randomColor);
              showToast('颜色已更改');
            }
          } catch (error) {
            showToast(`更改失败: ${error}`);
          }
        }
      })
    
    Button('改变大小')
      .onClick(() => {
        if (this.mapController) {
          try {
            const layer = this.mapController.getLayer('circle-layer');
            if (layer) {
              const size = 10 + Math.random() * 30;
              (layer as CircleLayer).setCircleRadius(size);
              showToast(`大小: ${size.toFixed(0)}`);
            }
          } catch (error) {
            showToast(`更改失败: ${error}`);
          }
        }
      })
  }
}

