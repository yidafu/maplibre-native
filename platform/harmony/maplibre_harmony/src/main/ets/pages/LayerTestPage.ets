import { NativeMapView } from '../maps/NativeMapView';
import { MapLibreMap } from '../maps/MapLibreMap';
import { MapLibreMapOptions } from '../maps/MapLibreMapOptions';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import maplibre from 'libmaplibre_native.so';
import { DOMAIN } from '../constants/HiLogConstants';

// 从 ETS 层导入 Layer（待 Layer NAPI 重构）
import { 
  FillLayer, 
  LineLayer, 
  CircleLayer,
  SymbolLayer,
  HeatmapLayer,
  FillExtrusionLayer,
  RasterLayer,
  BackgroundLayer
} from '../maps/style/index';

const TAG = 'LayerTestPage';

/**
 * Layer 图层测试页面
 * 
 * 测试功能：
 * 1. FillLayer - 填充图层
 * 2. LineLayer - 线条图层
 * 3. CircleLayer - 圆形图层
 * 4. SymbolLayer - 符号图层
 * 5. HeatmapLayer - 热力图层
 * 6. FillExtrusionLayer - 3D 拉伸图层
 * 7. RasterLayer - 栅格图层
 * 8. BackgroundLayer - 背景图层
 * 
 * 使用新的 NAPI API：
 * - const style = mapLibreMap.getStyle()
 * - style.addLayer(layer)
 * - style.addLayerBelow(layer, belowLayerId)
 * - style.removeLayer(layerId)
 * 
 * 注意：Layer 当前仍使用 ETS 类，待后续重构为 NAPI 类
 */

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
struct LayerTestPage {
  @State message: string = 'Layer 图层测试';
  private nativeMapView: maplibre.NativeMapView | null = null;
  private mapLibreMap: MapLibreMap | null = null;
  @State currentLayer: string = '无';
  @State mapReady: boolean = false;
  @State isInitializing: boolean = false;
  
  // 数据源是否已添加标记
  private dataSourceAdded: boolean = false;

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
          styleUrl: 'https://demotiles.maplibre.org/style.json',
          initialLatitude: 39.9042,
          initialLongitude: 116.4074,
          initialZoom: 10,
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

      // 当前图层显示
      Row() {
        Text(`当前图层: ${this.currentLayer}`)
          .fontSize(14)
          .padding(8)
      }
      .width('100%')
      .backgroundColor('#e0e0e0')

      // 控制面板
      Scroll() {
        Column({ space: 8 }) {
          Text('基础图层类型')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .padding({ left: 16, top: 8 })

          Button('FillLayer - 填充图层')
            .onClick(() => this.testFillLayer())
            .width('90%')
            .backgroundColor('#E91E63')

          Button('LineLayer - 线条图层')
            .onClick(() => this.testLineLayer())
            .width('90%')
            .backgroundColor('#9C27B0')

          Button('CircleLayer - 圆形图层')
            .onClick(() => this.testCircleLayer())
            .width('90%')
            .backgroundColor('#3F51B5')

          Button('SymbolLayer - 符号图层')
            .onClick(() => this.testSymbolLayer())
            .width('90%')
            .backgroundColor('#2196F3')

          Divider().strokeWidth(2).margin({ top: 8, bottom: 8 })

          Text('高级图层类型')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .padding({ left: 16 })

          Button('HeatmapLayer - 热力图')
            .onClick(() => this.testHeatmapLayer())
            .width('90%')
            .backgroundColor('#FF5722')

          Button('FillExtrusionLayer - 3D 拉伸')
            .onClick(() => this.testFillExtrusionLayer())
            .width('90%')
            .backgroundColor('#FF9800')

          Button('RasterLayer - 栅格图层')
            .onClick(() => this.testRasterLayer())
            .width('90%')
            .backgroundColor('#FFC107')

          Button('BackgroundLayer - 背景图层')
            .onClick(() => this.testBackgroundLayer())
            .width('90%')
            .backgroundColor('#FFEB3B')

          Divider().strokeWidth(2).margin({ top: 8, bottom: 8 })

          Button('清除所有图层')
            .onClick(() => this.clearAllLayers())
            .width('90%')
            .backgroundColor(Color.Red)
        }
        .width('100%')
        .padding(16)
      }
      .height(300)
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
      hilog.warn(DOMAIN, TAG, 'Map is already initializing');
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
      const options = new MapLibreMapOptions();
      this.mapLibreMap = new MapLibreMap(mapView, options);
      
      this.mapReady = true;
      this.message = '✅ 地图已就绪 - 可以开始测试 Layer';
      
      hilog.info(DOMAIN, TAG, 'Map is ready for Layer testing');
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
   * 确保测试数据源已添加
   */
  private ensureDataSource() {
    if (this.dataSourceAdded || !this.mapLibreMap) return;
    
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    try {
      // 添加通用测试数据源
      const geojsonData: GeoJSONFeatureCollection = {
        type: "FeatureCollection",
        features: [
          // 点要素
          {
            type: "Feature",
            geometry: { type: "Point", coordinates: [116.4074, 39.9042] },
            properties: { name: "北京", type: "capital", value: 100 }
          },
          {
            type: "Feature",
            geometry: { type: "Point", coordinates: [121.4737, 31.2304] },
            properties: { name: "上海", type: "city", value: 80 }
          },
          // 线要素
          {
            type: "Feature",
            geometry: {
              type: "LineString",
              coordinates: [
                [116.3, 39.9],
                [116.4, 39.95],
                [116.5, 39.9]
              ]
            },
            properties: { name: "路径1" }
          },
          // 面要素
          {
            type: "Feature",
            geometry: {
              type: "Polygon",
              coordinates: [[
                [116.3, 39.8],
                [116.5, 39.8],
                [116.5, 40.0],
                [116.3, 40.0],
                [116.3, 39.8]
              ]]
            },
            properties: { name: "区域1", height: 50 }
          }
        ]
      };

      const source = new maplibre.GeoJsonSource('test-data');
      source.setGeoJson(JSON.stringify(geojsonData));
      style.addSource(source);

      this.dataSourceAdded = true;
      hilog.info(DOMAIN, TAG, 'Test data source added');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to add test data: ${error}`);
    }
  }

  /**
   * 测试 FillLayer
   */
  private testFillLayer() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.ensureDataSource();
    this.currentLayer = 'FillLayer';

    try {
      const layer: FillLayer = new maplibre.FillLayer('fill-test-layer', 'test-data')
          .setFillColor('#ff0000')
        .setFillOpacity(0.6)
        .setFillOutlineColor('#000000');
      
      style.addLayer(layer as object);

      hilog.info(DOMAIN, TAG, 'FillLayer added');
      this.message = '✅ 已添加 FillLayer (填充图层)';
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed: ${errorMsg}`);
      this.message = `❌ 失败: ${errorMsg}`;
    }
  }

  /**
   * 测试 LineLayer
   */
  private testLineLayer() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.ensureDataSource();
    this.currentLayer = 'LineLayer';

    try {
      const layer: LineLayer = new maplibre.LineLayer('line-test-layer', 'test-data')
          .setLineColor('#0000ff')
        .setLineWidth(4)
        .setLineDasharray([2, 2]);
      
      style.addLayer(layer as object);

      hilog.info(DOMAIN, TAG, 'LineLayer added');
      this.message = '✅ 已添加 LineLayer (线条图层)';
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed: ${errorMsg}`);
      this.message = `❌ 失败: ${errorMsg}`;
    }
  }

  /**
   * 测试 CircleLayer
   */
  private testCircleLayer() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.ensureDataSource();
    this.currentLayer = 'CircleLayer';

    try {
      const layer: CircleLayer = new maplibre.CircleLayer('circle-test-layer', 'test-data')
          .setCircleRadius(15)
        .setCircleColor('#00ff00')
        .setCircleOpacity(0.8)
        .setCircleStrokeWidth(2)
        .setCircleStrokeColor('#ffffff');
      
      style.addLayer(layer as object);

      hilog.info(DOMAIN, TAG, 'CircleLayer added');
      this.message = '✅ 已添加 CircleLayer (圆形图层)';
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed: ${errorMsg}`);
      this.message = `❌ 失败: ${errorMsg}`;
    }
  }

  /**
   * 测试 SymbolLayer
   */
  private testSymbolLayer() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.ensureDataSource();
    this.currentLayer = 'SymbolLayer';

    try {
      const layer: SymbolLayer = new maplibre.SymbolLayer('symbol-test-layer', 'test-data');
      layer.setTextField('{name}');
      layer.setTextSize(16);
      layer.setTextColor('#000000');
      
      style.addLayer(layer as object);

      hilog.info(DOMAIN, TAG, 'SymbolLayer added');
      this.message = '✅ 已添加 SymbolLayer (符号图层)';
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed: ${errorMsg}`);
      this.message = `❌ 失败: ${errorMsg}`;
    }
  }

  /**
   * 测试 HeatmapLayer
   */
  private testHeatmapLayer() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.currentLayer = 'HeatmapLayer';

    try {
      // 创建密集点数据用于热力图
      const features: Array<GeoJSONFeature> = [];
      for (let i = 0; i < 200; i++) {
        features.push({
          type: "Feature",
          geometry: {
            type: "Point",
            coordinates: [
              116.4 + (Math.random() - 0.5) * 0.2,
              39.9 + (Math.random() - 0.5) * 0.2
            ]
          },
          properties: { intensity: Math.random() * 100 }
        });
      }

      const geojsonData: GeoJSONFeatureCollection = {
        type: "FeatureCollection",
        features: features
      };

      const source = new maplibre.GeoJsonSource('heatmap-source');
      source.setGeoJson(JSON.stringify(geojsonData));
      style.addSource(source);

      const layer = new maplibre.HeatmapLayer('heatmap-test-layer', 'heatmap-source')
          .setHeatmapRadius(30)
        .setHeatmapIntensity(1.5)
        .setHeatmapOpacity(0.8);
      
      style.addLayer(layer as object);

      hilog.info(DOMAIN, TAG, 'HeatmapLayer added');
      this.message = '✅ 已添加 HeatmapLayer (热力图层)';
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed: ${errorMsg}`);
      this.message = `❌ 失败: ${errorMsg}`;
    }
  }

  /**
   * 测试 FillExtrusionLayer
   */
  private testFillExtrusionLayer() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.currentLayer = 'FillExtrusionLayer';

    try {
      const geojsonData: GeoJSONFeatureCollection = {
        type: "FeatureCollection",
        features: [
          {
            type: "Feature",
            geometry: {
              type: "Polygon",
              coordinates: [[
                [116.39, 39.89],
                [116.41, 39.89],
                [116.41, 39.91],
                [116.39, 39.91],
                [116.39, 39.89]
              ]]
            },
            properties: { height: 80, base_height: 0 }
          },
          {
            type: "Feature",
            geometry: {
              type: "Polygon",
              coordinates: [[
                [116.42, 39.90],
                [116.44, 39.90],
                [116.44, 39.92],
                [116.42, 39.92],
                [116.42, 39.90]
              ]]
            },
            properties: { height: 120, base_height: 0 }
          }
        ]
      };

      const source = new maplibre.GeoJsonSource('extrusion-source');
      source.setGeoJson(JSON.stringify(geojsonData));
      style.addSource(source);

      const layer = new maplibre.FillExtrusionLayer('extrusion-test-layer', 'extrusion-source')
          .setFillExtrusionHeight(100)
          .setFillExtrusionBase(0)
        .setFillExtrusionColor('#0080ff')
        .setFillExtrusionOpacity(0.9);
      
      style.addLayer(layer as object);

      // 调整视角以查看 3D 效果
      if (this.mapLibreMap) {
        this.mapLibreMap.setPitch(60);
      }

      hilog.info(DOMAIN, TAG, 'FillExtrusionLayer added');
      this.message = '✅ 已添加 FillExtrusionLayer (3D 拉伸)';
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed: ${errorMsg}`);
      this.message = `❌ 失败: ${errorMsg}`;
    }
  }

  /**
   * 测试 RasterLayer
   */
  private testRasterLayer() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.currentLayer = 'RasterLayer';

    try {
      const source = new maplibre.RasterSource('raster-test-source');
      source.setUrl('https://tile.openstreetmap.org/{z}/{x}/{y}.png');
      style.addSource(source);

      const layer: RasterLayer = new maplibre.RasterLayer('raster-test-layer', 'raster-test-source')
          .setRasterOpacity(0.5);
      
      style.addLayer(layer as object);

      hilog.info(DOMAIN, TAG, 'RasterLayer added');
      this.message = '✅ 已添加 RasterLayer (栅格图层)';
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed: ${errorMsg}`);
      this.message = `❌ 失败: ${errorMsg}`;
    }
  }

  /**
   * 测试 BackgroundLayer
   */
  private testBackgroundLayer() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.currentLayer = 'BackgroundLayer';

    try {
      const layer: object = new maplibre.BackgroundLayer('background-test-layer')
          .setBackgroundColor('#ffcccc')
        .setBackgroundOpacity(0.8);
      
      // 背景图层应该添加到最底层
      style.addLayer(layer as object);

      hilog.info(DOMAIN, TAG, 'BackgroundLayer added');
      this.message = '✅ 已添加 BackgroundLayer (背景图层)';
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed: ${errorMsg}`);
      this.message = `❌ 失败: ${errorMsg}`;
    }
  }

  /**
   * 清除所有测试图层
   */
  private clearAllLayers() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.currentLayer = '无';

    try {
      // 移除所有测试图层
      const layerIds = [
        'fill-test-layer', 'line-test-layer', 'circle-test-layer',
        'symbol-test-layer', 'heatmap-test-layer', 'extrusion-test-layer',
        'raster-test-layer', 'background-test-layer'
      ];

      layerIds.forEach(layerId => {
        try {
          style.removeLayer(layerId);
        } catch (e) {
          // 忽略不存在的图层
        }
      });

      // 移除所有测试数据源
      const sourceIds = [
        'test-data', 'heatmap-source', 'extrusion-source', 'raster-test-source'
      ];

      sourceIds.forEach(sourceId => {
        try {
          style.removeSource(sourceId);
        } catch (e) {
          // 忽略不存在的数据源
        }
      });

      this.dataSourceAdded = false;

      hilog.info(DOMAIN, TAG, 'All layers cleared');
      this.message = '✅ 已清除所有图层';
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed to clear layers: ${errorMsg}`);
      this.message = `❌ 清除失败: ${errorMsg}`;
    }
  }
}

