import { MapViewComponentController } from '../maps/MapViewComponentController';
import { MapLibreMap } from '../maps/MapLibreMap';
import { LatLng } from '../maps/geometry/LatLng';
import { CameraPosition } from '../maps/camera/CameraPosition';
import { 
  Style, 
  GeoJsonSource, 
  VectorSource,
  RasterSource,
  FillLayer, 
  LineLayer, 
  CircleLayer,
  SymbolLayer,
  HeatmapLayer,
  FillExtrusionLayer,
  PropertyFactory
} from '../maps/style/index';

@Entry
@Component
struct StyleTestPage {
  @State message: string = 'Style API 测试';
  private mapController: MapViewComponentController = new MapViewComponentController();
  private mapLibreMap: MapLibreMap | null = null;
  @State currentExample: string = '无';

  build() {
    Column() {
      // 标题栏
      Row() {
        Text(this.message)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .padding(16)
      }
      .width('100%')
      .backgroundColor('#f5f5f5')

      // 地图容器
      Stack() {
        XComponent({
          id: 'mapview',
          type: 'surface',
          controller: this.mapController.getXComponentController()
        })
          .onLoad(() => {
            console.info('XComponent onLoad');
            this.mapController.onCreate();
          })
          .width('100%')
          .height('100%')
      }
      .width('100%')
      .layoutWeight(1)

      // 当前示例显示
      Row() {
        Text(`当前示例: ${this.currentExample}`)
          .fontSize(14)
          .padding(8)
      }
      .width('100%')
      .backgroundColor('#e0e0e0')

      // 控制面板
      Scroll() {
        Column({ space: 8 }) {
          Text('数据源示例')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .padding({ left: 16, top: 8 })

          Button('GeoJSON - 填充区域')
            .onClick(() => this.showGeoJsonFillExample())
            .width('90%')

          Button('GeoJSON - 线条路径')
            .onClick(() => this.showGeoJsonLineExample())
            .width('90%')

          Button('GeoJSON - 圆形热点')
            .onClick(() => this.showGeoJsonCircleExample())
            .width('90%')

          Button('GeoJSON - 符号标注')
            .onClick(() => this.showGeoJsonSymbolExample())
            .width('90%')

          Button('GeoJSON - 聚类')
            .onClick(() => this.showGeoJsonClusterExample())
            .width('90%')

          Divider().strokeWidth(2).margin({ top: 8, bottom: 8 })

          Text('高级图层示例')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .padding({ left: 16 })

          Button('热力图')
            .onClick(() => this.showHeatmapExample())
            .width('90%')

          Button('3D 建筑拉伸')
            .onClick(() => this.showFillExtrusionExample())
            .width('90%')

          Button('栅格图层')
            .onClick(() => this.showRasterExample())
            .width('90%')

          Button('清除所有图层')
            .onClick(() => this.clearAllLayers())
            .width('90%')
            .backgroundColor(Color.Red)
        }
        .width('100%')
        .padding(16)
      }
      .height(200)
      .width('100%')
      .backgroundColor(Color.White)
    }
    .width('100%')
    .height('100%')
  }

  aboutToAppear() {
    // 地图初始化后的回调
    this.mapController.setOnMapReadyCallback((map: MapLibreMap) => {
      this.mapLibreMap = map;
      
      // 设置初始位置
      const position = new CameraPosition(
        new LatLng(39.9042, 116.4074), // 北京
        10,
        0,
        0
      );
      map.setCameraPosition(position);

      // 标记样式已加载
      map.onStyleLoaded();
      
      console.info('Map is ready');
    });
  }

  /**
   * 示例1: GeoJSON + FillLayer (填充区域)
   */
  private showGeoJsonFillExample() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.currentExample = 'GeoJSON 填充区域';

    try {
      // 创建GeoJSON数据源
      const geojsonData = {
        "type": "FeatureCollection",
        "features": [{
          "type": "Feature",
          "geometry": {
            "type": "Polygon",
            "coordinates": [[
              [116.3, 39.8],
              [116.5, 39.8],
              [116.5, 40.0],
              [116.3, 40.0],
              [116.3, 39.8]
            ]]
          },
          "properties": {
            "name": "测试区域"
          }
        }]
      };

      const source = GeoJsonSource.withData('fill-source', geojsonData);
      style.addSource(source);

      // 创建填充图层
      const layer = new FillLayer('fill-layer', 'fill-source')
        .withFillColor('#ff0000')
        .withFillOpacity(0.5)
        .withFillOutlineColor('#000000');
      
      style.addLayer(layer);

      console.info('GeoJSON Fill example added');
    } catch (error) {
      console.error(`Failed to add GeoJSON fill: ${error}`);
    }
  }

  /**
   * 示例2: GeoJSON + LineLayer (线条)
   */
  private showGeoJsonLineExample() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.currentExample = 'GeoJSON 线条路径';

    try {
      const geojsonData = {
        "type": "FeatureCollection",
        "features": [{
          "type": "Feature",
          "geometry": {
            "type": "LineString",
            "coordinates": [
              [116.3, 39.9],
              [116.4, 39.95],
              [116.5, 39.9],
              [116.6, 39.95]
            ]
          },
          "properties": {
            "name": "测试路径"
          }
        }]
      };

      const source = GeoJsonSource.withData('line-source', geojsonData);
      style.addSource(source);

      // 创建线条图层
      const layer = new LineLayer('line-layer', 'line-source')
        .withLineColor('#0000ff')
        .withLineWidth(4)
        .withLineDasharray([2, 2]);
      
      style.addLayer(layer);

      console.info('GeoJSON Line example added');
    } catch (error) {
      console.error(`Failed to add GeoJSON line: ${error}`);
    }
  }

  /**
   * 示例3: GeoJSON + CircleLayer (圆形热点)
   */
  private showGeoJsonCircleExample() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.currentExample = 'GeoJSON 圆形热点';

    try {
      const geojsonData = {
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "geometry": { "type": "Point", "coordinates": [116.4, 39.9] },
            "properties": { "value": 100 }
          },
          {
            "type": "Feature",
            "geometry": { "type": "Point", "coordinates": [116.45, 39.95] },
            "properties": { "value": 80 }
          },
          {
            "type": "Feature",
            "geometry": { "type": "Point", "coordinates": [116.35, 39.85] },
            "properties": { "value": 120 }
          }
        ]
      };

      const source = GeoJsonSource.withData('circle-source', geojsonData);
      style.addSource(source);

      // 创建圆形图层
      const layer = new CircleLayer('circle-layer', 'circle-source')
        .withCircleRadius(15)
        .withCircleColor('#00ff00')
        .withCircleOpacity(0.8)
        .withCircleStroke(2, '#ffffff');
      
      style.addLayer(layer);

      console.info('GeoJSON Circle example added');
    } catch (error) {
      console.error(`Failed to add GeoJSON circle: ${error}`);
    }
  }

  /**
   * 示例4: GeoJSON + SymbolLayer (符号标注)
   */
  private showGeoJsonSymbolExample() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.currentExample = 'GeoJSON 符号标注';

    try {
      const geojsonData = {
        "type": "FeatureCollection",
        "features": [{
          "type": "Feature",
          "geometry": { "type": "Point", "coordinates": [116.4074, 39.9042] },
          "properties": { "title": "北京" }
        }]
      };

      const source = GeoJsonSource.withData('symbol-source', geojsonData);
      style.addSource(source);

      // 创建符号图层
      const layer = new SymbolLayer('symbol-layer', 'symbol-source')
        .withText('{title}', 16, '#000000');
      
      style.addLayer(layer);

      console.info('GeoJSON Symbol example added');
    } catch (error) {
      console.error(`Failed to add GeoJSON symbol: ${error}`);
    }
  }

  /**
   * 示例5: GeoJSON 聚类
   */
  private showGeoJsonClusterExample() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.currentExample = 'GeoJSON 聚类';

    try {
      // 生成随机点数据
      const features = [];
      for (let i = 0; i < 50; i++) {
        features.push({
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [
              116.3 + Math.random() * 0.3,
              39.8 + Math.random() * 0.3
            ]
          },
          "properties": { "id": i }
        });
      }

      const geojsonData = {
        "type": "FeatureCollection",
        "features": features
      };

      // 使用聚类选项
      import { GeoJsonOptionsBuilder } from '../maps/style/sources/GeoJsonOptions';
      const options = new GeoJsonOptionsBuilder()
        .withCluster(true)
        .withClusterRadius(50)
        .withClusterMaxZoom(14)
        .build();

      const source = GeoJsonSource.withData('cluster-source', geojsonData, options);
      style.addSource(source);

      // 聚类圆形图层
      const clusterLayer = new CircleLayer('cluster-layer', 'cluster-source')
        .withCircleRadius(20)
        .withCircleColor('#ff6600')
        .withCircleOpacity(0.8);
      
      style.addLayer(clusterLayer);

      console.info('GeoJSON Cluster example added');
    } catch (error) {
      console.error(`Failed to add GeoJSON cluster: ${error}`);
    }
  }

  /**
   * 示例6: 热力图
   */
  private showHeatmapExample() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.currentExample = '热力图';

    try {
      // 生成随机热力点
      const features = [];
      for (let i = 0; i < 100; i++) {
        features.push({
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [
              116.4 + (Math.random() - 0.5) * 0.2,
              39.9 + (Math.random() - 0.5) * 0.2
            ]
          },
          "properties": { "intensity": Math.random() }
        });
      }

      const geojsonData = {
        "type": "FeatureCollection",
        "features": features
      };

      const source = GeoJsonSource.withData('heatmap-source', geojsonData);
      style.addSource(source);

      // 热力图图层
      const layer = new HeatmapLayer('heatmap-layer', 'heatmap-source')
        .withHeatmapRadius(30)
        .withHeatmapIntensity(1.5)
        .withHeatmapOpacity(0.8);
      
      style.addLayer(layer);

      console.info('Heatmap example added');
    } catch (error) {
      console.error(`Failed to add heatmap: ${error}`);
    }
  }

  /**
   * 示例7: 3D建筑拉伸
   */
  private showFillExtrusionExample() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.currentExample = '3D 建筑拉伸';

    try {
      const geojsonData = {
        "type": "FeatureCollection",
        "features": [{
          "type": "Feature",
          "geometry": {
            "type": "Polygon",
            "coordinates": [[
              [116.4, 39.9],
              [116.42, 39.9],
              [116.42, 39.92],
              [116.4, 39.92],
              [116.4, 39.9]
            ]]
          },
          "properties": {
            "height": 100,
            "base_height": 0
          }
        }]
      };

      const source = GeoJsonSource.withData('extrusion-source', geojsonData);
      style.addSource(source);

      // 3D拉伸图层
      const layer = new FillExtrusionLayer('extrusion-layer', 'extrusion-source')
        .withFillExtrusionHeight(100, 0)
        .withFillExtrusionColor('#0080ff')
        .withFillExtrusionOpacity(0.9);
      
      style.addLayer(layer);

      console.info('FillExtrusion example added');
    } catch (error) {
      console.error(`Failed to add fill extrusion: ${error}`);
    }
  }

  /**
   * 示例8: 栅格图层
   */
  private showRasterExample() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.currentExample = '栅格图层';

    try {
      // 使用示例栅格瓦片服务
      const source = new RasterSource(
        'raster-source',
        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        256
      );
      style.addSource(source);

      // 栅格图层
      import { RasterLayer } from '../maps/style/layers/RasterLayer';
      const layer = new RasterLayer('raster-layer', 'raster-source')
        .withRasterOpacity(0.5);
      
      style.addLayer(layer);

      console.info('Raster example added');
    } catch (error) {
      console.error(`Failed to add raster: ${error}`);
    }
  }

  /**
   * 清除所有自定义图层
   */
  private clearAllLayers() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.currentExample = '无';

    try {
      // 移除所有测试图层
      const layerIds = [
        'fill-layer', 'line-layer', 'circle-layer', 'symbol-layer',
        'cluster-layer', 'heatmap-layer', 'extrusion-layer', 'raster-layer'
      ];

      layerIds.forEach(layerId => {
        style.removeLayer(layerId);
      });

      // 移除所有测试数据源
      const sourceIds = [
        'fill-source', 'line-source', 'circle-source', 'symbol-source',
        'cluster-source', 'heatmap-source', 'extrusion-source', 'raster-source'
      ];

      sourceIds.forEach(sourceId => {
        style.removeSource(sourceId);
      });

      console.info('All layers cleared');
    } catch (error) {
      console.error(`Failed to clear layers: ${error}`);
    }
  }
}

