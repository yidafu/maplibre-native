/**
 * Fill Extrusion Test Page
 * 3D 拉伸图层测试
 * 参考 Android: FillExtrusionActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { FillExtrusionLayer, GeoJson, GeoJsonSource, MapLibreMap, MapView } from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import type { JsonObject } from '../../types/EntryTypes';

@Entry
@Component
struct FillExtrusionTestPage {
  private mapController: MapLibreMap | null = null;
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Fill Extrusion',
        description: '3D 建筑拉伸效果',
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
      initialZoom: 10,
      onMapReady: (map: MapLibreMap) => {
        this.mapController = map;
        map.jumpTo(0, 39.9, 116.4, 45, 16);
        this.addExtrusionLayer(map);
      }
    })
  }

  private addExtrusionLayer(map: MapLibreMap): void {
    try {
      const props1: Record<string, Object> = { 'height': 100 };
      const props2: Record<string, Object> = { 'height': 150 };
      const geojson = GeoJson.featureCollection([
        GeoJson.polygonFeature([[
            [116.39, 39.89],
            [116.40, 39.89],
            [116.40, 39.90],
            [116.39, 39.90],
            [116.39, 39.89]
          ]], props1),
        GeoJson.polygonFeature([[
            [116.40, 39.90],
            [116.41, 39.90],
            [116.41, 39.91],
            [116.40, 39.91],
            [116.40, 39.90]
          ]], props2)
      ]);
      
      const source = new GeoJsonSource('extrusion-source');
      source.setGeoJson(geojson);
      map.addSource(source);
      
      const layer = new FillExtrusionLayer('extrusion-layer', 'extrusion-source');
      layer.setFillExtrusionColor('#2196F3');
      layer.setFillExtrusionOpacity(0.8);
      layer.setFillExtrusionHeight(['get', 'height']);
      layer.setFillExtrusionBase(0);
      map.addLayer(layer);
      
      showToast('3D 拉伸图层已添加');
    } catch (error) {
      showToast(`添加失败: ${error}`);
    }
  }
  
  @Builder
  buildActionButtons() {
    Button('调整俯仰角')
      .onClick(() => {
        if (this.mapController) {
          const pitch = this.mapController.getPitch();
          this.mapController.setPitch(pitch < 45 ? 60 : 30, 500);
        }
      })
  }
}

