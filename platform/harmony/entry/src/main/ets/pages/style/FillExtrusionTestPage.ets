import { FillExtrusionLayer, GeoJsonSource, MapLibreMap, NativeMapView, Polygon } from 'maplibre_harmony';
/**
 * Fill Extrusion Test Page
 * 3D 拉伸图层测试
 * 参考 Android: FillExtrusionActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, showToast } from '../common/TestUtils';

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
        map.jumpTo(0, 39.9, 116.4, 45, 16);
        this.addExtrusionLayer(map);
      }
    })
    .width('100%')
    .height('100%')
  }

  private addExtrusionLayer(map: MapLibreMap): void {
    try {
      const geojson = {
        type: 'FeatureCollection',
        features: [
          {
            type: 'Feature',
            geometry: {
              type: 'Polygon',
              coordinates: [[
                [116.39, 39.89],
                [116.40, 39.89],
                [116.40, 39.90],
                [116.39, 39.90],
                [116.39, 39.89]
              ]]
            },
            properties: { height: 100 }
          },
          {
            type: 'Feature',
            geometry: {
              type: 'Polygon',
              coordinates: [[
                [116.40, 39.90],
                [116.41, 39.90],
                [116.41, 39.91],
                [116.40, 39.91],
                [116.40, 39.90]
              ]]
            },
            properties: { height: 150 }
          }
        ]
      };
      
      const source = new GeoJsonSource('extrusion-source');
      source.setGeoJson(JSON.stringify(geojson));
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

