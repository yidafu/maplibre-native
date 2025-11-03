/**
 * Fill Layer Test Page
 * 填充图层测试
 * 参考 Android Fill Layer 相关测试
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { FillLayer, GeoJson, GeoJsonSource, MapLibreMap, MapView } from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import type { JsonObject } from '../../types/EntryTypes';

@Entry
@Component
struct FillLayerTestPage {
  private scroller: Scroller = new Scroller();
  private mapController: MapLibreMap | null = null;
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Fill Layer',
        description: '填充图层样式',
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
      styleUrl: DEFAULT_STYLE_URLS.bright,
      onMapReady: (map: MapLibreMap) => {
        this.mapController = map;
        map.jumpTo(0, 39.9, 116.4, 0, 10);
        this.addFillLayer(map);
      },
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 10
    })
  }

  private addFillLayer(map: MapLibreMap): void {
    try {
      const geojson = GeoJson.featureCollection([
        GeoJson.polygonFeature([[
            [116.3, 39.8],
            [116.5, 39.8],
            [116.5, 40.0],
            [116.3, 40.0],
            [116.3, 39.8]
          ]])
      ]);
      
      const source = new GeoJsonSource('fill-source');
      source.setGeoJson(geojson);
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
    Scroll(this.scroller) {
      Column({ space: 8 }) {
        Button('改变颜色')
          .width('100%')
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
      .width('100%')
      .padding(8)
    }
    .scrollBar(BarState.Auto)
    .scrollable(ScrollDirection.Vertical)
  }
}

