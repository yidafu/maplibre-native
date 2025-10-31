import { CircleLayer, Expression, GeoJsonSource, MapLibreMap, NativeMapView, ScreenPoint } from 'maplibre_harmony';
/**
 * Data Driven Style Test Page
 * 数据驱动样式测试
 * 参考 Android: DataDrivenStyleActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, showToast } from '../common/TestUtils';

@Entry
@Component
struct DataDrivenStyleTestPage {
  private mapController: MapLibreMap | null = null;
  
  build() {
    Column() {
    TestPageLayout({
      title: 'Data Driven Style',
      description: '使用表达式驱动样式',
      showActionBar: true,
      mapContent: this.buildMapContent,
      actionButtons: this.buildActionButtons
    })
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  buildMapContent() {
    NativeMapView({
      styleUrl: DEFAULT_STYLE_URLS.streets,
      onMapReady: (map: MapLibreMap) => {
        this.mapController = map;
        map.jumpTo(0, 35, 105, 0, 4);
        this.addDataDrivenLayer(map);
      }
    })
    .width('100%')
    .height('100%')
  }

  private addDataDrivenLayer(map: MapLibreMap): void {
    try {
      // 添加带数据的 GeoJSON 源
      const geojson = {
        type: 'FeatureCollection',
        features: [
          {
            type: 'Feature',
            geometry: { type: 'Point', coordinates: [116.4, 39.9] },
            properties: { population: 2154, type: 'capital' }
          },
          {
            type: 'Feature',
            geometry: { type: 'Point', coordinates: [121.5, 31.2] },
            properties: { population: 2424, type: 'major' }
          },
          {
            type: 'Feature',
            geometry: { type: 'Point', coordinates: [113.3, 23.1] },
            properties: { population: 1501, type: 'major' }
          }
        ]
      };
      
      const source = new GeoJsonSource('cities-source');
      source.setGeoJson(JSON.stringify(geojson));
      map.addSource(source);
      
      // 添加使用数据驱动样式的圆形图层
      const layer = new CircleLayer('cities-layer', 'cities-source');
      
      // 根据人口数据设置圆形大小
      const sizeExpression = Expression.interpolate(
        Expression.linear(),
        Expression.get('population'),
        Expression.literal(1000), Expression.literal(10),
        Expression.literal(2500), Expression.literal(25)
      );
      layer.setCircleRadius(sizeExpression);
      
      // 根据类型设置颜色
      const colorExpression = Expression.match(
        Expression.get('type'),
        Expression.literal('#FF0000'), // 默认红色
        Expression.literal('capital'), Expression.literal('#2196F3'),
        Expression.literal('major'), Expression.literal('#FF9800')
      );
      layer.setCircleColor(colorExpression);
      
      layer.setCircleOpacity(0.8);
      map.addLayer(layer);
      
      showToast('数据驱动样式已添加');
    } catch (error) {
      showToast(`添加失败: ${error}`);
    }
      .width('100%')

      .height('100%')
  }

  @Builder
  buildActionButtons() {
    Button('更新数据')
      .onClick(() => {
        showToast('更新数据功能待实现');
      })
    .width('100%')
    .height('100%')
}
