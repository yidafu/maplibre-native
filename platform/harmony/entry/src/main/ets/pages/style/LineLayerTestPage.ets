/**
 * Line Layer Test Page
 * 线条图层测试
 * 参考 Android Line Layer 相关测试
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { GeoJson, GeoJsonSource, LineLayer, MapLibreMap, MapView } from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import type { JsonObject } from '../../types/EntryTypes';

@Entry
@Component
struct LineLayerTestPage {
  private scroller: Scroller = new Scroller();
  private mapController: MapLibreMap | null = null;
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Line Layer',
        description: '线条图层样式',
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
        map.jumpTo(0, 35, 105, 0, 5);
        this.addLineLayer(map);
      }
    })
  }

  private addLineLayer(map: MapLibreMap): void {
    try {
      const geojson = GeoJson.featureCollection([
        GeoJson.lineStringFeature([
            [116.4, 39.9],
            [115, 38],
            [113, 36],
            [121.5, 31.2]
          ])
      ]);
      
      const source = new GeoJsonSource('line-source');
      source.setGeoJson(geojson);
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
    Scroll(this.scroller) {
      Column({ space: 8 }) {
        Button('改变宽度')
          .width('100%')
          .onClick(() => {
            if (this.mapController) {
              const layer = this.mapController.getLayer('line-layer');
              if (layer) {
                const lineWidth: number = 2 + Math.random() * 8;
                (layer as LineLayer).setLineWidth(lineWidth);
                showToast(`宽度: ${lineWidth.toFixed(1)}`);
              }
            }
          })
      }
      .width('100%')
      .padding(8)
    }
    .scrollBar(BarState.Auto)
    .scrollable(ScrollDirection.Vertical)
  }
}

