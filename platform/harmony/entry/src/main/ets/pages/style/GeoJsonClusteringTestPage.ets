/**
 * GeoJSON Clustering Test Page
 * GeoJSON 聚类测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/style/GeoJsonClusteringActivity.kt
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, CameraPosition, LatLng, GeoJsonSource, CircleLayer, SymbolLayer, Expression, GeoJson,
  IFeature } from 'maplibre_harmony';
import type { IFeatureCollection } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import type { JsonObject } from '../../types/EntryTypes';
import { GeoJsonOptions } from 'maplibre_harmony/src/main/ets/maps/style';

import type { JSONValue } from 'libmaplibre.so';
@Entry
@Component
struct GeoJsonClusteringTestPage {
  private scroller: Scroller = new Scroller();
  private mapController: MapLibreMap | null = null;
  @State private pointCount: number = 0;
  @State private clusterRadius: number = 50;
  @State private clusterMaxZoom: number = 14;
  
  // 示例 GeoJSON 数据
  private sampleGeoJson: Object = this.createInitialGeoJson();
  
  private createInitialGeoJson(): Object {
    const props1: Record<string, JSONValue> = { 'name': '北京', 'type': 'city' };
    const props2: Record<string, JSONValue> = { 'name': '上海', 'type': 'city' };
    const props3: Record<string, JSONValue> = { 'name': '广州', 'type': 'city' };
    const props4: Record<string, JSONValue> = { 'name': '深圳', 'type': 'city' };
    const props5: Record<string, JSONValue> = { 'name': '杭州', 'type': 'city' };
    return GeoJson.featureCollection([
      GeoJson.pointFeature([116.4074, 39.9042], props1),
      GeoJson.pointFeature([121.4737, 31.2304], props2),
      GeoJson.pointFeature([113.2644, 23.1291], props3),
      GeoJson.pointFeature([114.0579, 22.5431], props4),
      GeoJson.pointFeature([120.1551, 30.2741], props5)
    ]);
  }
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[GeoJsonClusteringTestPage] onMapReady');
    this.mapController = map;
    map.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    
    // 设置初始位置
    map.jumpTo(0, 31, 115, 0, 5);
    
    // 等待样式加载后添加聚类层
    setTimeout(() => {
      this.addClusteringLayers();
    }, 1000);
  };
  
  /**
   * 添加聚类图层
   */
  private addClusteringLayers(): void {
    if (!this.mapController) return;
    
    try {
      // 创建聚类数据源
      const options: GeoJsonOptions = {
        cluster: true,
        clusterRadius: this.clusterRadius,
        clusterMaxZoom: this.clusterMaxZoom
      };
      const source = new GeoJsonSource('earthquake-source', options);
      source.setGeoJson(this.sampleGeoJson);
      this.mapController.getStyle()?.addSource(source);
      
      // 添加聚类圆圈图层 - 大聚类（>= 100）
      const largeCluster = new CircleLayer('cluster-large', 'earthquake-source');
      largeCluster.setCircleColor('#f1f075')
        .setCircleRadius(30)
        .setCircleOpacity(0.7);
      this.mapController.getStyle()?.addLayer(largeCluster);
      
      // 添加聚类数量标签
      const countLayer = new SymbolLayer('cluster-count', 'earthquake-source');
      countLayer.setTextField(Expression.get('point_count_abbreviated'))
        .setTextSize(12)
        .setTextColor('#000000');
      this.mapController.getStyle()?.addLayer(countLayer);
      
      // 添加未聚类的点
      const unclusteredLayer = new CircleLayer('unclustered-point', 'earthquake-source');
      unclusteredLayer.setCircleColor('#11b4da')
        .setCircleRadius(8)
        .setCircleStrokeWidth(1)
        .setCircleStrokeColor('#ffffff');
      this.mapController.getStyle()?.addLayer(unclusteredLayer);
      
      showToast('聚类图层已添加');
      
    } catch (error) {
      console.error('Error adding clustering layers:', error);
      showToast('添加聚类图层失败');
    }
  };
  
  /**
   * 更新聚类配置
   * 
   * 注意：MapLibre Core不支持动态更新聚类配置
   * 必须重新创建数据源和图层
   */
  private updateClusterConfig = (): void => {
    if (!this.mapController) return;
    
    try {
      // 移除现有图层和数据源
      this.mapController.getStyle()?.removeLayer('cluster-large');
      this.mapController.getStyle()?.removeLayer('cluster-count');
      this.mapController.getStyle()?.removeLayer('unclustered-point');
      this.mapController.getStyle()?.removeSource('earthquake-source');
      
      // 重新添加（使用新配置）
      this.addClusteringLayers();
      
      showToast(`聚类配置已更新: 半径${this.clusterRadius}, 最大缩放${this.clusterMaxZoom}`);
    } catch (error) {
      console.error('[GeoJsonClusteringTestPage] Update cluster config failed:', error);
      showToast('更新聚类配置失败');
    }
  };
  
  /**
   * 生成随机点数据
   */
  private generateRandomPoints = (count: number): void => {
    const features: IFeature[] = [];;
    
    for (let i = 0; i < count; i++) {
      const lat = 20 + Math.random() * 30;
      const lng = 100 + Math.random() * 30;
      
      const props: Record<string, JSONValue> = {
        'name': `Point ${i + 1}`,
        'value': Math.floor(Math.random() * 100)
      };
      const feature = GeoJson.pointFeature([lng, lat], props);
      features.push(feature);
    }
    
    const featureCollection = GeoJson.featureCollection(features);
    this.sampleGeoJson = featureCollection as Object;
    this.pointCount = count;
    
    // 重新添加图层
    this.addClusteringLayers();
    
    showToast(`已生成 ${count} 个随机点`);
  };
  
  @Builder
  buildActionButtons() {
    Scroll(this.scroller) {
      Column({ space: 8 }) {
        Text('生成测试数据')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ top: 8, bottom: 4 })
        
        Row({ space: 8 }) {
          Button('10个点')
            .fontSize(14)
            .layoutWeight(1)
            .onClick(() => this.generateRandomPoints(10))
          
          Button('50个点')
            .fontSize(14)
            .layoutWeight(1)
            .onClick(() => this.generateRandomPoints(50))
        }
        
        Row({ space: 8 }) {
          Button('100个点')
            .fontSize(14)
            .layoutWeight(1)
            .onClick(() => this.generateRandomPoints(100))
          
          Button('更新配置')
            .fontSize(14)
            .layoutWeight(1)
            .backgroundColor('#4CAF50')
            .onClick(this.updateClusterConfig)
        }
        
        Text('聚类配置')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ top: 8, bottom: 4 })
        
        Text(`点数量: ${this.pointCount}`)
          .fontSize(14)
          .width('100%')
        
        Row() {
          Text('聚类半径:')
            .fontSize(14)
            .width(80)
          Slider({
            value: this.clusterRadius,
            min: 10,
            max: 100,
            step: 10
          })
            .layoutWeight(1)
            .onChange((value: number) => {
              this.clusterRadius = value;
            })
          Text(`${this.clusterRadius}`)
            .fontSize(14)
            .width(50)
        }
        .width('100%')
        
        Row() {
          Text('最大级别:')
            .fontSize(14)
            .width(80)
          Slider({
            value: this.clusterMaxZoom,
            min: 8,
            max: 18,
            step: 1
          })
            .layoutWeight(1)
            .onChange((value: number) => {
              this.clusterMaxZoom = value;
            })
          Text(`${this.clusterMaxZoom}`)
            .fontSize(14)
            .width(50)
        }
        .width('100%')
        
        Text('说明: 点击聚类可以放大查看详情')
          .fontSize(12)
          .fontColor('#666')
          .width('100%')
      }
      .width('100%')
      .padding(8)
    }
    .scrollBar(BarState.Auto)
    .scrollable(ScrollDirection.Vertical)
  }
  
  @Builder
  buildMapContent() {
    MapView({
      onMapReady: this.onMapReady,
      styleUrl: DEFAULT_STYLE_URLS.bright,
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 10
    })
      .width('100%')
      .height('100%')
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'GeoJSON Clustering',
        description: 'GeoJSON 聚类',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        actionButtons: (): void => this.buildActionButtons()
      })
    }
    .width('100%')
    .height('100%')
  }
}