import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';
import { TestPageLayout } from '../common/TestPageLayout';

import { BackgroundLayer, CircleLayer, FillExtrusionLayer, FillLayer, GeoJson, GeoJsonSource, HeatmapLayer, LatLng, LatLngBounds, LineLayer, MapLibreMap, MapView, Point,
  RasterLayer, RasterSource, SymbolLayer,
  NativeMapView,
  IFeature} from 'maplibre_harmony';
import type { CameraOptions } from 'maplibre_harmony';
import type { JsonObject, LayerPropertyOptions, PropertiesMap } from '../../types/EntryTypes';
import type { JSONValue } from 'libmaplibre.so';
// 从 ETS 层导入 Layer 和 Source 封装类

const TAG = 'LayerTestPage';

/**
 * 随机位置接口
 */
interface RandomLocation {
  longitude: number;
  latitude: number;
}

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
  coordinates: number[] | number[][] | number[][][] | number[][][][]
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
  addLayer(layer: FillLayer) {
    throw new Error('Method not implemented.');
  }

  mapView: MapLibreMap | undefined;
  @State message: string = 'Layer 图层测试';
  private nativeMapView: NativeMapView | undefined = undefined;
  private mapLibreMap: MapLibreMap | undefined = undefined;
  @State currentLayer: string = '无';
  @State mapReady: boolean = false;
  @State isInitializing: boolean = false;

  @Builder
  buildMapContent() {
    Stack() {
      MapView({
        styleUrl: 'https://demotiles.maplibre.org/style.json',
        initialLatitude: 39.9,
        initialLongitude: 116.4,
        initialZoom: 5,
        initialBearing: 0,
        initialPitch: 0,
        onMapReady: (map: MapLibreMap) => {
          this.initializeMap(map);
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
    .width('100%')
    .height('100%')
  }

  @Builder
  buildActionButtons() {
    Column({ space: 8 }) {
      // 当前图层显示
      Text(`当前图层: ${this.currentLayer}`)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .padding(8)
        .backgroundColor('#F8F8F8')
        .borderRadius(4)
      
      Text('基础图层类型')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 4 })
      
      Row({ space: 8 }) {
        Button('FillLayer - 填充图层')
          .onClick(() => this.handleTestFillLayer())
          .layoutWeight(1)
          .fontSize(13)
          .backgroundColor('#E91E63')

        Button('LineLayer - 线条图层')
          .onClick(() => this.handleTestLineLayer())
          .layoutWeight(1)
          .fontSize(13)
          .backgroundColor('#9C27B0')
      }
      .width('100%')
      
      Row({ space: 8 }) {
        Button('CircleLayer - 圆形图层')
          .onClick(() => this.handleTestCircleLayer())
          .layoutWeight(1)
          .fontSize(13)
          .backgroundColor('#3F51B5')

        Button('SymbolLayer - 符号图层')
          .onClick(() => this.handleTestSymbolLayer())
          .layoutWeight(1)
          .fontSize(13)
          .backgroundColor('#2196F3')
      }
      .width('100%')
      
      Divider().strokeWidth(2).margin({ top: 4, bottom: 4 })

      Text('高级图层类型')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
      
      Row({ space: 8 }) {
        Button('HeatmapLayer - 热力图')
          .onClick(() => this.handleTestHeatmapLayer())
          .layoutWeight(1)
          .fontSize(13)
          .backgroundColor('#FF5722')

        Button('FillExtrusionLayer - 3D 拉伸')
          .onClick(() => this.handleTestFillExtrusionLayer())
          .layoutWeight(1)
          .fontSize(12)
          .backgroundColor('#FF9800')
      }
      .width('100%')
      
      Row({ space: 8 }) {
        Button('RasterLayer - 栅格图层')
          .onClick(() => this.handleTestRasterLayer())
          .layoutWeight(1)
          .fontSize(12)
          .backgroundColor('#FFC107')

        Button('BackgroundLayer - 背景图层')
          .onClick(() => this.handleTestBackgroundLayer())
          .layoutWeight(1)
          .fontSize(11)
          .backgroundColor('#FFEB3B')
      }
      .width('100%')
      
      Divider().strokeWidth(2).margin({ top: 4, bottom: 4 })

      Button('清除所有图层')
        .onClick(() => this.handleClearAllLayers())
        .width('100%')
        .fontSize(14)
        .backgroundColor(Color.Red)
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
        showActionBar: true,
        title: this.message,
        mapContent: (): void => this.buildMapContent(),
        actionButtons: (): void => this.buildActionButtons()
      })
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 生成随机位置（中国区域）
   */
  private generateRandomLocation(): RandomLocation {
    // 中国区域：经度 70-135，纬度 15-55
    const longitude: number = 70 + Math.random() * 65;
    const latitude: number = 15 + Math.random() * 40;
    return { longitude, latitude };
  }

  /**
   * FlyTo 到指定边界范围
   */
  private flyToBounds(points: LatLng[]) {
    if (!this.mapLibreMap || points.length === 0) return;

    try {
      // 计算边界范围
      const bounds = LatLngBounds.fromLatLngArray(points);
      
      // 使用 getCameraForLatLngBounds 获取合适的相机位置
      const padding = 80; // 四周留 80 像素边距
      const camera = this.mapLibreMap.getCameraForLatLngBounds(
        bounds,
        padding, padding, padding, padding
      );

      if (camera) {
        // FlyTo 到计算出的相机位置
        const options: CameraOptions = {
          center: camera.target,
          zoom: camera.zoom,
          bearing: camera.bearing,
          pitch: camera.tilt
        };
        this.mapLibreMap.flyTo(options, 2000);
        
        hilog.info(DOMAIN, TAG, `Flying to bounds: center=${camera.target.latitude},${camera.target.longitude}, zoom=${camera.zoom}`);
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to fly to bounds: ${error}`);
    }
  }

  /**
   * 初始化地图
   */
  private initializeMap(map?: MapLibreMap) {
    if (this.isInitializing) {
      hilog.warn(DOMAIN, TAG, 'Map is already initializing');
      return;
    }
    
    if (!this.mapLibreMap) {
      hilog.error(DOMAIN, TAG, 'onMapReady: this.mapView is null');
      this.message = '❌ 地图初始化失败';
      return;
    }
    
    this.isInitializing = true;
    
    try {
      this.mapLibreMap = map;
      this.nativeMapView = map?.getNativeMapView();

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
   * 确保测试数据源已添加（使用随机位置）
   * @returns 所有坐标点的数组，用于计算边界
   */
  private ensureDataSource(): LatLng[] {
    if (!this.mapLibreMap) return []
    
    const style = this.mapLibreMap.getStyle();
    if (!style) return []

    try {
      // 移除旧的数据源（如果存在）
      try {
        style.removeSource('test-data');
      } catch (e) {
        // 忽略不存在的情况
      }

      // 生成随机中心位置
      const center = this.generateRandomLocation();
      const centerLng = center.longitude;
      const centerLat = center.latitude;

      // 在中心位置周围生成随机数据
      const offset = 1.5; // 经纬度偏移范围（适合 zoom=5）
      
      // 添加通用测试数据源
      const props1: Record<string, JSONValue> = { 'name': "中心点", 'type': "center", 'value': 100 };
      const props2: Record<string, JSONValue> = { 'name': "点2", 'type': "point", 'value': 80 };
      const props3: Record<string, JSONValue> = { 'name': "路径1" };
      const props4: Record<string, JSONValue> = { 'name': "区域1", 'height': 50 };
      const geojsonData = GeoJson.featureCollection([
        // 点要素
        GeoJson.pointFeature([centerLng, centerLat], props1),
        GeoJson.pointFeature([centerLng + offset * 0.5, centerLat + offset * 0.3], props2),
        // 线要素
        GeoJson.lineStringFeature([
            [centerLng - offset, centerLat],
            [centerLng - offset * 0.5, centerLat + offset * 0.5],
            [centerLng, centerLat + offset]
          ], props3),
        // 面要素
        GeoJson.polygonFeature([[
            [centerLng - offset, centerLat - offset],
            [centerLng + offset, centerLat - offset],
            [centerLng + offset, centerLat + offset],
            [centerLng - offset, centerLat + offset],
            [centerLng - offset, centerLat - offset]
          ]], props4)
      ]);

      const source: GeoJsonSource = new GeoJsonSource('test-data');
      source.setGeoJson(geojsonData);
      style.addSource(source);

      // 提取所有坐标点用于计算边界
      const allPoints: LatLng[] = [];;
      allPoints.push(LatLng.create(centerLat, centerLng));
      allPoints.push(LatLng.create(centerLat + offset * 0.3, centerLng + offset * 0.5));
      allPoints.push(LatLng.create(centerLat, centerLng - offset));
      allPoints.push(LatLng.create(centerLat + offset * 0.5, centerLng - offset * 0.5));
      allPoints.push(LatLng.create(centerLat + offset, centerLng));
      allPoints.push(LatLng.create(centerLat - offset, centerLng - offset));
      allPoints.push(LatLng.create(centerLat - offset, centerLng + offset));
      allPoints.push(LatLng.create(centerLat + offset, centerLng + offset));
      allPoints.push(LatLng.create(centerLat + offset, centerLng - offset));

      hilog.info(DOMAIN, TAG, `Test data source added at ${centerLat}, ${centerLng}`);
      return allPoints;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to add test data: ${error}`);
      return []
    }
  }

  /**
   * 测试 FillLayer
   */
  private testFillLayer: () => void = () : void => {
    if (!this.mapLibreMap) return;
    const style = this
    if (!style) return;

    const allPoints = this.ensureDataSource();
    this.currentLayer = 'FillLayer';

    try {
      const layer: FillLayer = new FillLayer('fill-test-layer', 'test-data')
          .setFillColor('#ff0000')
        .setFillOpacity(0.6)
        .setFillOutlineColor('#000000');
      
      style.addLayer(layer);

      // FlyTo 到图层边界
      this.flyToBounds(allPoints);

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

    const allPoints = this.ensureDataSource();
    this.currentLayer = 'LineLayer';

    try {
      const layer: LineLayer = new LineLayer('line-test-layer', 'test-data')
          .setLineColor('#0000ff')
        .setLineWidth(4)
        .setLineDasharray([2, 2]);
      
      style.addLayer(layer);

      // FlyTo 到图层边界
      this.flyToBounds(allPoints);

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

    const allPoints = this.ensureDataSource();
    this.currentLayer = 'CircleLayer';

    try {
      const layer: CircleLayer = new CircleLayer('circle-test-layer', 'test-data')
          .setCircleRadius(15)
        .setCircleColor('#00ff00')
        .setCircleOpacity(0.8)
        .setCircleStrokeWidth(2)
        .setCircleStrokeColor('#ffffff');
      
      style.addLayer(layer);

      // FlyTo 到图层边界
      this.flyToBounds(allPoints);

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

    const allPoints = this.ensureDataSource();
    this.currentLayer = 'SymbolLayer';

    try {
      const layer: SymbolLayer = new SymbolLayer('symbol-test-layer', 'test-data');
      layer.setTextField('{name}');
      layer.setTextSize(16);
      layer.setTextColor('#000000');
      
      style.addLayer(layer);

      // FlyTo 到图层边界
      this.flyToBounds(allPoints);

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
      // 移除旧的数据源（如果存在）
      try {
        style.removeSource('heatmap-source');
      } catch (e) {
        // 忽略不存在的情况
      }

      // 生成随机中心位置
      const center = this.generateRandomLocation();
      const centerLng = center.longitude;
      const centerLat = center.latitude;
      const offset = 1.0; // 热力图点分布范围（适合 zoom=5）

      // 创建密集点数据用于热力图
      const features: Array<IFeature> = [];
      const allPoints: LatLng[] = [];;
      
      for (let i = 0; i < 200; i++) {
        const lng: number = centerLng + (Math.random() - 0.5) * offset * 2;
        const lat: number = centerLat + (Math.random() - 0.5) * offset * 2;
        
        const props: Record<string, JSONValue> = { 'intensity': Math.random() * 100 };
        features.push(GeoJson.pointFeature([lng, lat], props));
        
        if (i % 20 === 0) {
          allPoints.push(LatLng.create(lat, lng));
        }
      }

      const geojsonData = GeoJson.featureCollection(features);

      const source: GeoJsonSource = new GeoJsonSource('heatmap-source');
      source.setGeoJson(geojsonData);
      style.addSource(source);

      const layer: HeatmapLayer = new HeatmapLayer('heatmap-test-layer', 'heatmap-source')
          .setHeatmapRadius(30)
        .setHeatmapIntensity(1.5)
        .setHeatmapOpacity(0.8);
      
      style.addLayer(layer);

      // FlyTo 到图层边界
      this.flyToBounds(allPoints);

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
      // 移除旧的数据源（如果存在）
      try {
        style.removeSource('extrusion-source');
      } catch (e) {
        // 忽略不存在的情况
      }

      // 生成随机中心位置
      const center = this.generateRandomLocation();
      const centerLng = center.longitude;
      const centerLat = center.latitude;
      const offset = 0.5; // 建筑物间距（适合 zoom=5）

      const props1: Record<string, JSONValue> = { 'height': 80, 'base_height': 0 };
      const props2: Record<string, JSONValue> = { 'height': 120, 'base_height': 0 };
      const geojsonData = GeoJson.featureCollection([
        GeoJson.polygonFeature([[
            [centerLng - offset, centerLat - offset],
            [centerLng, centerLat - offset],
            [centerLng, centerLat],
            [centerLng - offset, centerLat],
            [centerLng - offset, centerLat - offset]
          ]], props1),
        GeoJson.polygonFeature([[
            [centerLng + offset * 0.5, centerLat],
            [centerLng + offset * 2, centerLat],
            [centerLng + offset * 2, centerLat + offset * 1.5],
            [centerLng + offset * 0.5, centerLat + offset * 1.5],
            [centerLng + offset * 0.5, centerLat]
          ]], props2)
      ]);

      const source: GeoJsonSource = new GeoJsonSource('extrusion-source');
      source.setGeoJson(geojsonData);
      style.addSource(source);

      const layer = new FillExtrusionLayer('extrusion-test-layer', 'extrusion-source')
          .setFillExtrusionHeight(100)
          .setFillExtrusionBase(0)
        .setFillExtrusionColor('#0080ff')
        .setFillExtrusionOpacity(0.9);
      
      style.addLayer(layer);

      // 提取边界点
      const allPoints: LatLng[] = [
        LatLng.create(centerLat - offset, centerLng - offset),
        LatLng.create(centerLat, centerLng),
        LatLng.create(centerLat + offset * 1.5, centerLng + offset * 2)
      ]

      // 调整视角以查看 3D 效果
      if (this.mapLibreMap) {
        this.mapLibreMap.setPitch(60);
      }

      // FlyTo 到图层边界
      this.flyToBounds(allPoints);

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
      // 移除旧的数据源（如果存在）
      try {
        style.removeSource('raster-test-source');
      } catch (e) {
        // 忽略不存在的情况
      }

      const source: RasterSource = new RasterSource('raster-test-source');
      source.setUrl('https://tile.openstreetmap.org/{z}/{x}/{y}.png');
      style.addSource(source);

      const layer: RasterLayer = new RasterLayer('raster-test-layer', 'raster-test-source')
          .setRasterOpacity(0.5);
      
      style.addLayer(layer);

      // 生成随机位置并 flyTo（栅格图层是全球的，选择一个随机位置查看）
      const center = this.generateRandomLocation();
      const options: CameraOptions = {
        center: LatLng.create(center.latitude, center.longitude),
        zoom: 8
      };
      this.mapLibreMap.flyTo(options, 2000);

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
      const layer: BackgroundLayer = new BackgroundLayer('background-test-layer')
          .setBackgroundColor('#ffcccc')
        .setBackgroundOpacity(0.8);
      
      // 背景图层应该添加到最底层
      style.addLayer(layer);

      // 生成随机位置并 flyTo（背景图层是全局的，选择一个随机位置查看）
      const center = this.generateRandomLocation();
      const options: CameraOptions = {
        center: LatLng.create(center.latitude, center.longitude),
        zoom: 8
      };
      this.mapLibreMap.flyTo(options, 2000);

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
      ]

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
      ]

      sourceIds.forEach(sourceId => {
        try {
          style.removeSource(sourceId);
        } catch (e) {
          // 忽略不存在的数据源
        }
      });

      hilog.info(DOMAIN, TAG, 'All layers cleared');
      this.message = '✅ 已清除所有图层';
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed to clear layers: ${errorMsg}`);
      this.message = `❌ 清除失败: ${errorMsg}`;
    }
  }
  
  // ========== 包装方法（用于 @Builder 中的 this 上下文绑定） ==========
  
  private handleTestFillLayer = (): void => {
    this.testFillLayer();
  }
  
  private handleTestLineLayer = (): void => {
    this.testLineLayer();
  }
  
  private handleTestCircleLayer = (): void => {
    this.testCircleLayer();
  }
  
  private handleTestSymbolLayer = (): void => {
    this.testSymbolLayer();
  }
  
  private handleTestHeatmapLayer = (): void => {
    this.testHeatmapLayer();
  }
  
  private handleTestFillExtrusionLayer = (): void => {
    this.testFillExtrusionLayer();
  }
  
  private handleTestRasterLayer = (): void => {
    this.testRasterLayer();
  }
  
  private handleTestBackgroundLayer = (): void => {
    this.testBackgroundLayer();
  }
  
  private handleClearAllLayers = (): void => {
    this.clearAllLayers();
  }
}

