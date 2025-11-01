/**
 * Heatmap Layer Test Page
 * 热力图图层测试
 * 参考 Android: HeatmapLayerActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { GeoJsonSource, HeatmapLayer, LatLng, MapLibreMap, MapView, ScreenPoint, GeoJson, IFeature } from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, showToast, randomLatLng , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct HeatmapLayerTestPage {
  private mapController: MapLibreMap | null = null;
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Heatmap Layer',
        description: '热力图可视化',
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
        map.jumpTo(0, 35, 105, 0, 4);
        this.addHeatmapLayer(map);
      }
    })
  }

  private addHeatmapLayer(map: MapLibreMap): void {
    try {
      // 生成密集点数据（模拟地震数据）
      const features: IFeature[] = [];
      for (let i = 0; i < 500; i++) {
        const latLng = randomLatLng(18, 54, 73, 135);
        const props: Record<string, Object> = {
          'magnitude': Math.random() * 10
        };
        features.push(GeoJson.pointFeature(
          [latLng.longitude, latLng.latitude],
          props
        ));
      }
      
      const source = new GeoJsonSource('heatmap-source');
      source.setGeoJson(GeoJson.featureCollection(features));
      map.addSource(source);
      
      const layer = new HeatmapLayer('heatmap-layer', 'heatmap-source');
      layer.setHeatmapRadius(20);
      layer.setHeatmapOpacity(0.8);
      map.addLayer(layer);
      
      showToast('热力图已添加');
    } catch (error) {
      showToast(`添加失败: ${error}`);
    }
  }
  
  @Builder
  buildActionButtons() {
    Button('调整强度')
      .onClick(() => {
        if (this.mapController) {
          const layer = this.mapController.getLayer('heatmap-layer');
          if (layer) {
            const intensity = 0.5 + Math.random() * 0.5;
            (layer as HeatmapLayer).setHeatmapIntensity(intensity);
            showToast(`强度: ${intensity.toFixed(2)}`);
          }
        }
      })
  }
}

