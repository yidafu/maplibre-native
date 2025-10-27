import { NativeMapView } from '../maps/NativeMapView';
import { MapLibreMap } from '../maps/MapLibreMap';
import { MapLibreMapOptions } from '../maps/MapLibreMapOptions';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import maplibre from 'libmaplibre_native.so';
import { DOMAIN } from '../constants/HiLogConstants';

// 暂时从 ETS 层导入 Layer（待 Layer NAPI 重构）
import { 
  FillLayer, 
  LineLayer, 
  CircleLayer
} from '../maps/style/index';
const TAG = 'SourceTestPage';

/**
 * Source 数据源测试页面
 * 
 * 测试功能：
 * 1. GeoJsonSource - 各种几何类型（点、线、面）
 * 2. VectorSource - 矢量瓦片数据源
 * 3. RasterSource - 栅格瓦片数据源
 * 4. RasterDemSource - DEM 数据源
 * 5. ImageSource - 图像数据源
 * 
 * 使用新的 NAPI API：
 * - new maplibre.GeoJsonSource(id)
 * - new maplibre.VectorSource(id)
 * - new maplibre.RasterSource(id)
 * - source.setGeoJson(data)
 * - source.setUrl(url)
 * - style.addSource(source)
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
struct SourceTestPage {
  @State message: string = 'Source 数据源测试';
  private nativeMapView: maplibre.NativeMapView | null = null;
  private mapLibreMap: MapLibreMap | null = null;
  @State currentSource: string = '无';
  @State mapReady: boolean = false;
  @State isInitializing: boolean = false;

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

      // 当前数据源显示
      Row() {
        Text(`当前数据源: ${this.currentSource}`)
          .fontSize(14)
          .padding(8)
      }
      .width('100%')
      .backgroundColor('#e0e0e0')

      // 控制面板
      Scroll() {
        Column({ space: 8 }) {
          Text('GeoJsonSource 测试')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .padding({ left: 16, top: 8 })

          Button('点数据 (Point)')
            .onClick(() => this.testGeoJsonPoint())
            .width('90%')
            .backgroundColor('#2196F3')

          Button('线数据 (LineString)')
            .onClick(() => this.testGeoJsonLine())
            .width('90%')
            .backgroundColor('#2196F3')

          Button('面数据 (Polygon)')
            .onClick(() => this.testGeoJsonPolygon())
            .width('90%')
            .backgroundColor('#2196F3')

          Button('多点聚类')
            .onClick(() => this.testGeoJsonCluster())
            .width('90%')
            .backgroundColor('#2196F3')

          Button('从 URL 加载')
            .onClick(() => this.testGeoJsonFromUrl())
            .width('90%')
            .backgroundColor('#2196F3')

          Divider().strokeWidth(2).margin({ top: 8, bottom: 8 })

          Text('VectorSource 测试')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .padding({ left: 16, top: 8 })

          Button('矢量瓦片数据源')
            .onClick(() => this.testVectorSource())
            .width('90%')
            .backgroundColor('#4CAF50')

          Divider().strokeWidth(2).margin({ top: 8, bottom: 8 })

          Text('RasterSource 测试')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .padding({ left: 16, top: 8 })

          Button('OSM 栅格瓦片')
            .onClick(() => this.testRasterSource())
            .width('90%')
            .backgroundColor('#FF9800')

          Button('卫星影像')
            .onClick(() => this.testRasterSourceSatellite())
            .width('90%')
            .backgroundColor('#FF9800')

          Divider().strokeWidth(2).margin({ top: 8, bottom: 8 })

          Button('清除所有数据源')
            .onClick(() => this.clearAllSources())
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
      this.message = '✅ 地图已就绪 - 可以开始测试 Source';
      
      hilog.info(DOMAIN, TAG, 'Map is ready for Source testing');
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
   * 测试 GeoJsonSource - 点数据
   */
  private testGeoJsonPoint() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.currentSource = 'GeoJsonSource - Point';

    try {
      const geojsonData: GeoJSONFeatureCollection = {
        type: "FeatureCollection",
        features: [
          {
            type: "Feature",
            geometry: { type: "Point", coordinates: [116.4074, 39.9042] },
            properties: { name: "北京", value: 100 }
          }
        ]
      };

      const source = new maplibre.GeoJsonSource('point-source');
      source.setGeoJson(JSON.stringify(geojsonData));
      style.addSource(source);

      const layer: CircleLayer = new maplibre.CircleLayer('point-layer', 'point-source')
          .setCircleRadius(15)
        .setCircleColor('#ff0000')
        .setCircleOpacity(0.8);
      
      style.addLayer(layer as object);

      hilog.info(DOMAIN, TAG, 'GeoJsonSource Point added');
      this.message = '✅ 已添加 GeoJSON 点数据源';
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed: ${errorMsg}`);
      this.message = `❌ 失败: ${errorMsg}`;
    }
  }

  /**
   * 测试 GeoJsonSource - 线数据
   */
  private testGeoJsonLine() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.currentSource = 'GeoJsonSource - LineString';

    try {
      const geojsonData: GeoJSONFeatureCollection = {
        type: "FeatureCollection",
        features: [
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
            properties: { name: "测试路径" }
          }
        ]
      };

      const source = new maplibre.GeoJsonSource('line-source');
      source.setGeoJson(JSON.stringify(geojsonData));
      style.addSource(source);

      const layer: LineLayer = new maplibre.LineLayer('line-layer', 'line-source')
          .setLineColor('#0000ff')
        .setLineWidth(4);
      
      style.addLayer(layer as object);

      hilog.info(DOMAIN, TAG, 'GeoJsonSource Line added');
      this.message = '✅ 已添加 GeoJSON 线数据源';
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed: ${errorMsg}`);
      this.message = `❌ 失败: ${errorMsg}`;
    }
  }

  /**
   * 测试 GeoJsonSource - 面数据
   */
  private testGeoJsonPolygon() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.currentSource = 'GeoJsonSource - Polygon';

    try {
      const geojsonData: GeoJSONFeatureCollection = {
        type: "FeatureCollection",
        features: [
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
            properties: { name: "测试区域" }
          }
        ]
      };

      const source = new maplibre.GeoJsonSource('polygon-source');
      source.setGeoJson(JSON.stringify(geojsonData));
      style.addSource(source);

      const layer: FillLayer = new maplibre.FillLayer('polygon-layer', 'polygon-source')
          .setFillColor('#00ff00')
        .setFillOpacity(0.5)
        .setFillOutlineColor('#000000');
      
      style.addLayer(layer as object);

      hilog.info(DOMAIN, TAG, 'GeoJsonSource Polygon added');
      this.message = '✅ 已添加 GeoJSON 面数据源';
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed: ${errorMsg}`);
      this.message = `❌ 失败: ${errorMsg}`;
    }
  }

  /**
   * 测试 GeoJsonSource - 聚类
   */
  private testGeoJsonCluster() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.currentSource = 'GeoJsonSource - Cluster';

    try {
      // 生成随机点数据
      const features: Array<GeoJSONFeature> = [];
      for (let i = 0; i < 100; i++) {
        features.push({
          type: "Feature",
          geometry: {
            type: "Point",
            coordinates: [
              116.3 + Math.random() * 0.3,
              39.8 + Math.random() * 0.3
            ]
          },
          properties: { id: i }
        });
      }

      const geojsonData: GeoJSONFeatureCollection = {
        type: "FeatureCollection",
        features: features
      };

      // TODO: 聚类选项待完善
      const source = new maplibre.GeoJsonSource('cluster-source');
      source.setGeoJson(JSON.stringify(geojsonData));
      style.addSource(source);

      const layer: CircleLayer = new maplibre.CircleLayer('cluster-layer', 'cluster-source')
          .setCircleRadius(10)
        .setCircleColor('#ff6600')
        .setCircleOpacity(0.8);
      
      style.addLayer(layer as object);

      hilog.info(DOMAIN, TAG, 'GeoJsonSource Cluster added (options not yet supported)');
      this.message = '✅ 已添加聚类数据源 (默认选项)';
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed: ${errorMsg}`);
      this.message = `❌ 失败: ${errorMsg}`;
    }
  }

  /**
   * 测试 GeoJsonSource - 从 URL 加载
   */
  private testGeoJsonFromUrl() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.currentSource = 'GeoJsonSource - URL';

    try {
      const source = new maplibre.GeoJsonSource('url-source');
      // 使用公开的 GeoJSON 数据源
      source.setUrl('https://raw.githubusercontent.com/maplibre/maplibre-gl-js/main/test/integration/data/countries.geojson');
      style.addSource(source);

      const layer: FillLayer = new maplibre.FillLayer('url-layer', 'url-source')
          .setFillColor('#0080ff')
        .setFillOpacity(0.3)
        .setFillOutlineColor('#000000');
      
      style.addLayer(layer as object);

      hilog.info(DOMAIN, TAG, 'GeoJsonSource from URL added');
      this.message = '✅ 已添加从 URL 加载的 GeoJSON 数据源';
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed: ${errorMsg}`);
      this.message = `❌ 失败: ${errorMsg}`;
    }
  }

  /**
   * 测试 VectorSource
   */
  private testVectorSource() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.currentSource = 'VectorSource';

    try {
      const source = new maplibre.VectorSource('vector-source');
      source.setUrl('https://demotiles.maplibre.org/tiles/tiles.json');
      style.addSource(source);

      hilog.info(DOMAIN, TAG, 'VectorSource added');
      hilog.info(DOMAIN, TAG, `  Source ID: ${source.getId()}`);
      hilog.info(DOMAIN, TAG, `  Source URL: ${source.getUrl()}`);
      
      this.message = '✅ 已添加 VectorSource 数据源';
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed: ${errorMsg}`);
      this.message = `❌ 失败: ${errorMsg}`;
    }
  }

  /**
   * 测试 RasterSource - OSM
   */
  private testRasterSource() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.currentSource = 'RasterSource - OSM';

    try {
      const source = new maplibre.RasterSource('osm-raster');
      source.setUrl('https://tile.openstreetmap.org/{z}/{x}/{y}.png');
      style.addSource(source);

      hilog.info(DOMAIN, TAG, 'RasterSource (OSM) added');
      hilog.info(DOMAIN, TAG, `  Source ID: ${source.getId()}`);
      hilog.info(DOMAIN, TAG, `  Source URL: ${source.getUrl()}`);
      
      this.message = '✅ 已添加 RasterSource (OSM) 数据源';
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed: ${errorMsg}`);
      this.message = `❌ 失败: ${errorMsg}`;
    }
  }

  /**
   * 测试 RasterSource - 卫星影像
   */
  private testRasterSourceSatellite() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.currentSource = 'RasterSource - Satellite';

    try {
      const source = new maplibre.RasterSource('satellite-raster');
      // 使用示例卫星影像服务
      source.setUrl('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}');
      style.addSource(source);

      hilog.info(DOMAIN, TAG, 'RasterSource (Satellite) added');
      this.message = '✅ 已添加卫星影像数据源';
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed: ${errorMsg}`);
      this.message = `❌ 失败: ${errorMsg}`;
    }
  }

  /**
   * 清除所有自定义数据源
   */
  private clearAllSources() {
    if (!this.mapLibreMap) return;
    const style = this.mapLibreMap.getStyle();
    if (!style) return;

    this.currentSource = '无';

    try {
      // 移除所有测试图层
      const layerIds = [
        'point-layer', 'line-layer', 'polygon-layer', 'cluster-layer',
        'url-layer'
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
        'point-source', 'line-source', 'polygon-source', 'cluster-source',
        'url-source', 'vector-source', 'osm-raster', 'satellite-raster'
      ];

      sourceIds.forEach(sourceId => {
        try {
          style.removeSource(sourceId);
        } catch (e) {
          // 忽略不存在的数据源
        }
      });

      hilog.info(DOMAIN, TAG, 'All sources cleared');
      this.message = '✅ 已清除所有数据源';
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed to clear sources: ${errorMsg}`);
      this.message = `❌ 清除失败: ${errorMsg}`;
    }
  }
}

