import { NativeMapView } from '../maps/NativeMapView';
import { MapLibreMap } from '../maps/MapLibreMap';
import { MapLibreMapOptions } from '../maps/MapLibreMapOptions';
import { LatLng } from '../maps/geometry/LatLng';
import { CameraPosition } from '../maps/camera/CameraPosition';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import maplibre from 'libmaplibre_native.so';
import { DOMAIN } from '../constants/HiLogConstants';
// 暂时从 ETS 层导入 Layer（待 Layer NAPI 重构）
import { 
  FillLayer, 
  LineLayer, 
  CircleLayer,
  SymbolLayer,
  HeatmapLayer,
  FillExtrusionLayer,
  RasterLayer
} from '../maps/style/index';

// 使用 NAPI 对象
type Style = maplibre.Style;
type GeoJsonSource = maplibre.GeoJsonSource;
type VectorSource = maplibre.VectorSource;
type RasterSource = maplibre.RasterSource;

const TAG = 'StyleTestPage';

/**
 * Style API 测试页面
 * 
 * 【重要】本页面已更新使用新的 NAPI API：
 * 
 * 1. Style - 使用 maplibre.Style NAPI 对象
 *    - 旧: maplibre.Style.addSource(mapPtr, id, json, ptr)
 *    - 新: style.addSource(source)
 * 
 * 2. Source - 使用 NAPI 构造函数
 *    - 旧: GeoJsonSource.withData(id, data)
 *    - 新: new maplibre.GeoJsonSource(id); source.setGeoJson(data)
 * 
 * 3. 生命周期管理
 *    - Source 对象由 NAPI 自动管理
 *    - 调用 style.addSource() 后所有权转移到 Style
 * 
 * 待完善功能：
 * - GeoJsonOptions 参数解析（cluster, clusterRadius 等）
 * - RasterSource.setTileSize()
 * - Layer NAPI 重构（当前仍使用 ETS Layer）
 */

// 样式URL配置接口
interface StyleUrlItem {
  name: string;
  url: string;
}

// GeoJSON类型定义
interface GeoJSONGeometry {
  type: string;
  coordinates: number[] | number[][] | number[][][] | number[][][][];
}

interface GeoJSONFeature {
  type: string;
  geometry: GeoJSONGeometry;
  properties: ESObject;
}

interface GeoJSONFeatureCollection {
  type: string;
  features: Array<GeoJSONFeature>;
}

@Entry
@Component
struct StyleTestPage {
  @State message: string = 'Style API 测试';
  private nativeMapView: maplibre.NativeMapView | null = null;
  private mapLibreMap: MapLibreMap | null = null;
  @State currentExample: string = '无';
  @State currentStyleName: string = 'MapLibre Demo';
  @State mapReady: boolean = false;
  @State isInitializing: boolean = false;
  
  // 免费样式列表
  private styleUrls: StyleUrlItem[] = [
    {
      name: 'MapLibre Demo',
      url: 'https://demotiles.maplibre.org/style.json'
    },
    {
      name: 'Americana',
      url: 'https://americanamap.org/style.json'
    },
    {
      name: 'VersaTiles Colorful',
      url: 'https://tiles.versatiles.org/assets/styles/colorful.json'
    }
  ];

  build() {
    Column() {
      // 标题栏
      Row() {
        Button('返回')
          .fontSize(16)
          .backgroundColor(Color.Transparent)
          .fontColor('#2196F3')
          .onClick(() => {
            router.back();
          })
          .margin({ left: 5 })

        Text(this.message)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 60 })
      }
      .width('100%')
      .height(50)
      .backgroundColor('#f5f5f5')

      // 地图容器
      Stack() {
        NativeMapView({
          styleUrl: this.styleUrls[0].url,
          initialLatitude: 39.9042,
          initialLongitude: 116.4074,
          initialZoom: 3,
          initialBearing: 0,
          initialPitch: 0,
          onMapReady: (mapView?: maplibre.NativeMapView) => {
            this.initializeMap(mapView);
          }
        })
          .width('100%')
          .height('100%')
        
        // 加载指示器
        if (!this.mapReady) {
          Column() {
            LoadingProgress()
              .width(50)
              .height(50)
              .color('#2196F3')
            
            Text('地图加载中...')
              .fontSize(16)
              .margin({ top: 10 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor('rgba(255, 255, 255, 0.8)')
        }
      }
      .layoutWeight(1)

      // 当前状态显示
      Row() {
        Text(`当前样式: ${this.currentStyleName} | 示例: ${this.currentExample}`)
          .fontSize(14)
          .padding(8)
      }
      .width('100%')
      .backgroundColor('#e0e0e0')

      // 控制面板
      Scroll() {
        Column({ space: 8 }) {
          // 地图样式切换区域
          Text('地图样式切换')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .padding({ left: 16, top: 8 })

          ForEach(this.styleUrls, (item: StyleUrlItem) => {
            Button(item.name)
              .onClick(() => this.switchStyle(item.url, item.name))
              .width('90%')
              .backgroundColor(this.currentStyleName === item.name ? '#4CAF50' : '#2196F3')
          })

          Divider().strokeWidth(2).margin({ top: 8, bottom: 8 })

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

  /**
   * 初始化地图
   */
  private initializeMap(mapView?: maplibre.NativeMapView) {
    if (this.isInitializing) {
      hilog.warn(DOMAIN, TAG, 'Map is already initializing, skipping duplicate initialization');
      return;
    }
    
    if (!mapView) {
      hilog.error(DOMAIN, TAG, 'onMapReady: mapView is null');
      this.message = '❌ 地图初始化失败';
      return;
    }
    
    this.isInitializing = true;
    
    try {
      this.nativeMapView = mapView;
      
      // 创建 MapLibreMap 实例
      const options = new MapLibreMapOptions();
      this.mapLibreMap = new MapLibreMap(mapView, options);
      
      this.mapReady = true;
      this.message = '✅ 地图已就绪 - 可以开始测试 Style API';
      
      hilog.info(DOMAIN, TAG, 'Map is ready for Style API testing');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed to initialize map: ${errorMsg}`);
      this.message = `❌ 初始化失败: ${errorMsg}`;
      this.mapReady = false;
    } finally {
      this.isInitializing = false;
    }
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
      const geometry: GeoJSONGeometry = {
        type: "Polygon",
        coordinates: [[
          [116.3, 39.8],
          [116.5, 39.8],
          [116.5, 40.0],
          [116.3, 40.0],
          [116.3, 39.8]
        ]]
      };
      
      const properties: ESObject = {
        name: "测试区域"
      };
      
      const feature: GeoJSONFeature = {
        type: "Feature",
        geometry: geometry,
        properties: properties
      };

      const geojsonData: GeoJSONFeatureCollection = {
        type: "FeatureCollection",
        features: [feature]
      };

      // 使用新的 NAPI GeoJsonSource
      const source = new maplibre.GeoJsonSource('fill-source');
      source.setGeoJson(JSON.stringify(geojsonData));
      style.addSource(source);

      // 创建填充图层
      const layer = new maplibre.FillLayer('fill-layer', 'fill-source')
          .setFillColor('#ff0000')
        .setFillOpacity(0.5)
        .setFillOutlineColor('#000000');
      
      style.addLayer(layer as object);

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
      const geometry: GeoJSONGeometry = {
        type: "LineString",
        coordinates: [
          [116.3, 39.9],
          [116.4, 39.95],
          [116.5, 39.9],
          [116.6, 39.95]
        ]
      };
      
      const properties: ESObject = {
        name: "测试路径"
      };
      
      const feature: GeoJSONFeature = {
        type: "Feature",
        geometry: geometry,
        properties: properties
      };

      const geojsonData: GeoJSONFeatureCollection = {
        type: "FeatureCollection",
        features: [feature]
      };

      // 使用新的 NAPI GeoJsonSource
      const source = new maplibre.GeoJsonSource('line-source');
      source.setGeoJson(JSON.stringify(geojsonData));
      style.addSource(source);

      // 创建线条图层
      const layer = new maplibre.LineLayer('line-layer', 'line-source')
          .setLineColor('#0000ff')
        .setLineWidth(4)
        .setLineDasharray([2, 2]);
      
      style.addLayer(layer as object);

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
      const features: Array<GeoJSONFeature> = [];
      
      const geom1: GeoJSONGeometry = { type: "Point", coordinates: [116.4, 39.9] };
      const props1: ESObject = { value: 100 };
      features.push({ type: "Feature", geometry: geom1, properties: props1 });
      
      const geom2: GeoJSONGeometry = { type: "Point", coordinates: [116.45, 39.95] };
      const props2: ESObject = { value: 80 };
      features.push({ type: "Feature", geometry: geom2, properties: props2 });
      
      const geom3: GeoJSONGeometry = { type: "Point", coordinates: [116.35, 39.85] };
      const props3: ESObject = { value: 120 };
      features.push({ type: "Feature", geometry: geom3, properties: props3 });

      const geojsonData: GeoJSONFeatureCollection = {
        type: "FeatureCollection",
        features: features
      };

      // 使用新的 NAPI GeoJsonSource
      const source = new maplibre.GeoJsonSource('circle-source');
      source.setGeoJson(JSON.stringify(geojsonData));
      style.addSource(source);

      // 创建圆形图层
      const layer = new maplibre.CircleLayer('circle-layer', 'circle-source')
          .setCircleRadius(15)
        .setCircleColor('#00ff00')
        .setCircleOpacity(0.8)
        .setCircleStrokeWidth(2)
        .setCircleStrokeColor('#ffffff');
      
      style.addLayer(layer as object);

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
      const geometry: GeoJSONGeometry = { type: "Point", coordinates: [116.4074, 39.9042] };
      const properties: ESObject = { title: "北京" };
      
      const feature: GeoJSONFeature = {
        type: "Feature",
        geometry: geometry,
        properties: properties
      };

      const geojsonData: GeoJSONFeatureCollection = {
        type: "FeatureCollection",
        features: [feature]
      };

      // 使用新的 NAPI GeoJsonSource
      const source = new maplibre.GeoJsonSource('symbol-source');
      source.setGeoJson(JSON.stringify(geojsonData));
      style.addSource(source);

      // 创建符号图层
      const layer = new maplibre.SymbolLayer('symbol-layer', 'symbol-source');
      layer.setTextField('{title}');
      layer.setTextSize(16);
      layer.setTextColor('#000000');
      
      style.addLayer(layer as object);

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
      const features: Array<GeoJSONFeature> = [];
      for (let i = 0; i < 50; i++) {
        const geometry: GeoJSONGeometry = {
          type: "Point",
          coordinates: [
            116.3 + Math.random() * 0.3,
            39.8 + Math.random() * 0.3
          ]
        };
        const properties: ESObject = { id: i };
        const feature: GeoJSONFeature = {
          type: "Feature",
          geometry: geometry,
          properties: properties
        };
        features.push(feature);
      }

      const geojsonData: GeoJSONFeatureCollection = {
        type: "FeatureCollection",
        features: features
      };

      // 使用新的 NAPI GeoJsonSource（聚类功能）
      // TODO: 完善 GeoJsonOptions 解析后可以传递聚类选项
      const source = new maplibre.GeoJsonSource('cluster-source');
      source.setGeoJson(JSON.stringify(geojsonData));
      style.addSource(source);
      
      hilog.info(DOMAIN, TAG, 'Note: Cluster options parsing not yet implemented, using defaults');

      // 聚类圆形图层
      const clusterLayer = new maplibre.CircleLayer('cluster-layer', 'cluster-source')
          .setCircleRadius(20)
        .setCircleColor('#ff6600')
        .setCircleOpacity(0.8);
      
      style.addLayer(clusterLayer as object);

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
      const features: Array<GeoJSONFeature> = [];
      for (let i = 0; i < 100; i++) {
        const geometry: GeoJSONGeometry = {
          type: "Point",
          coordinates: [
            116.4 + (Math.random() - 0.5) * 0.2,
            39.9 + (Math.random() - 0.5) * 0.2
          ]
        };
        const properties: ESObject = { intensity: Math.random() };
        const feature: GeoJSONFeature = {
          type: "Feature",
          geometry: geometry,
          properties: properties
        };
        features.push(feature);
      }

      const geojsonData: GeoJSONFeatureCollection = {
        type: "FeatureCollection",
        features: features
      };

      // 使用新的 NAPI GeoJsonSource
      const source = new maplibre.GeoJsonSource('heatmap-source');
      source.setGeoJson(JSON.stringify(geojsonData));
      style.addSource(source);

      // 热力图图层
      const layer = new maplibre.HeatmapLayer('heatmap-layer', 'heatmap-source')
          .setHeatmapRadius(30)
        .setHeatmapIntensity(1.5)
        .setHeatmapOpacity(0.8);
      
      style.addLayer(layer as object);

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
      const geometry: GeoJSONGeometry = {
        type: "Polygon",
        coordinates: [[
          [116.4, 39.9],
          [116.42, 39.9],
          [116.42, 39.92],
          [116.4, 39.92],
          [116.4, 39.9]
        ]]
      };
      
      const properties: ESObject = {
        height: 100,
        base_height: 0
      };
      
      const feature: GeoJSONFeature = {
        type: "Feature",
        geometry: geometry,
        properties: properties
      };

      const geojsonData: GeoJSONFeatureCollection = {
        type: "FeatureCollection",
        features: [feature]
      };

      // 使用新的 NAPI GeoJsonSource
      const source = new maplibre.GeoJsonSource('extrusion-source');
      source.setGeoJson(JSON.stringify(geojsonData));
      style.addSource(source);

      // 3D拉伸图层
      const layer = new maplibre.FillExtrusionLayer('extrusion-layer', 'extrusion-source')
          .setFillExtrusionHeight(100)
          .setFillExtrusionBase(0)
        .setFillExtrusionColor('#0080ff')
        .setFillExtrusionOpacity(0.9);
      
      style.addLayer(layer as object);

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
      // 使用新的 NAPI RasterSource
      const source = new maplibre.RasterSource('raster-source');
      source.setUrl('https://tile.openstreetmap.org/{z}/{x}/{y}.png');
      // TODO: source.setTileSize(256) 待实现
      style.addSource(source);

      // 栅格图层
      const layer = new maplibre.RasterLayer('raster-layer', 'raster-source')
          .setRasterOpacity(0.5);
      
      style.addLayer(layer as object);

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

  /**
   * 切换地图样式
   */
  private switchStyle(styleUrl: string, styleName: string) {
    if (!this.mapLibreMap) {
      console.error('Map not initialized');
      return;
    }

    try {
      // 清除所有自定义图层（避免样式冲突）
      this.clearAllLayers();
      
      // 切换样式
      this.mapLibreMap.setStyleUrl(styleUrl);
      
      // 更新状态
      this.currentStyleName = styleName;
      this.currentExample = '无';
      this.message = `已切换到: ${styleName}`;
      
      console.info(`Switched to style: ${styleName} (${styleUrl})`);
    } catch (error) {
      console.error(`Failed to switch style: ${error}`);
      this.message = `切换样式失败: ${error}`;
    }
  }
}

