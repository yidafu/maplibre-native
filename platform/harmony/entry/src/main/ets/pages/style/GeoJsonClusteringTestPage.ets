/**
 * GeoJSON Clustering Test Page
 * GeoJSON 聚类测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/style/GeoJsonClusteringActivity.kt
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { NativeMapView, MapLibreMap, CameraPosition, LatLng, GeoJsonSource, CircleLayer, SymbolLayer, Expression } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS } from '../common/TestUtils';

@Entry
@Component
struct GeoJsonClusteringTestPage {
  private mapController: MapLibreMap | null = null;
  @State private pointCount: number = 0;
  @State private clusterRadius: number = 50;
  @State private clusterMaxZoom: number = 14;
  
  // 示例 GeoJSON 数据
  private sampleGeoJson = {
    "type": "FeatureCollection",
    "features": [
      {
        "type": "Feature",
        "geometry": { "type": "Point", "coordinates": [116.4074, 39.9042] },
        "properties": { "name": "北京", "type": "city" }
      },
      {
        "type": "Feature",
        "geometry": { "type": "Point", "coordinates": [121.4737, 31.2304] },
        "properties": { "name": "上海", "type": "city" }
      },
      {
        "type": "Feature",
        "geometry": { "type": "Point", "coordinates": [113.2644, 23.1291] },
        "properties": { "name": "广州", "type": "city" }
      },
      {
        "type": "Feature",
        "geometry": { "type": "Point", "coordinates": [114.0579, 22.5431] },
        "properties": { "name": "深圳", "type": "city" }
      },
      {
        "type": "Feature",
        "geometry": { "type": "Point", "coordinates": [120.1551, 30.2741] },
        "properties": { "name": "杭州", "type": "city" }
      }
    ]
  };
  
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
    
    const initialPosition = // new CameraPosition(
      new LatLng(31, 115),
      5,
      0,
      0
    );
    // TODO: map.setCameraPosition(initialPosition);
    
    // 等待样式加载后添加聚类层
    setTimeout(() => {
      this.addClusteringLayers();
    }, 1000);
  };
  
  /**
   * 添加聚类图层
   */
  private addClusteringLayers(): void => {
    if (!this.mapController) return;
    
    try {
      // TODO: 实现聚类数据源
      // const source = new GeoJsonSource('earthquake-source', {
      //   data: this.sampleGeoJson,
      //   cluster: true,
      //   clusterRadius: this.clusterRadius,
      //   clusterMaxZoom: this.clusterMaxZoom
      // });
      // this.mapController.addSource(source);
      
      // TODO: 添加聚类圆圈图层
      // 大聚类（>= 100）
      // const largeCluster = new CircleLayer('cluster-large', 'earthquake-source');
      // largeCluster.setProperties({
      //   circleColor: '#f1f075',
      //   circleRadius: 30,
      //   circleOpacity: 0.7
      // });
      // largeCluster.setFilter(Expression.gte(Expression.get('point_count'), 100));
      // this.mapController.addLayer(largeCluster);
      
      // TODO: 添加聚类数量标签
      // const countLayer = new SymbolLayer('cluster-count', 'earthquake-source');
      // countLayer.setProperties({
      //   textField: Expression.get('point_count_abbreviated'),
      //   textSize: 12,
      //   textColor: '#000000'
      // });
      // this.mapController.addLayer(countLayer);
      
      // TODO: 添加未聚类的点
      // const unclusteredLayer = new CircleLayer('unclustered-point', 'earthquake-source');
      // unclusteredLayer.setProperties({
      //   circleColor: '#11b4da',
      //   circleRadius: 8,
      //   circleStrokeWidth: 1,
      //   circleStrokeColor: '#ffffff'
      // });
      // unclusteredLayer.setFilter(Expression.not(Expression.has('point_count')));
      // this.mapController.addLayer(unclusteredLayer);
      
      showToast('聚类图层已添加 (TODO: 完整实现)');
      
    } catch (error) {
      console.error('Error adding clustering layers:', error);
      showToast('添加聚类图层失败');
    }
  };
  
  /**
   * 更新聚类配置
   */
  private updateClusterConfig = (): void => {
    if (!this.mapController) return;
    
    // TODO: 实现动态更新聚类配置
    // this.mapController.removeLayer('cluster-large');
    // this.mapController.removeLayer('cluster-count');
    // this.mapController.removeLayer('unclustered-point');
    // this.mapController.removeSource('earthquake-source');
    
    // this.addClusteringLayers();
    
    showToast(`聚类配置已更新 (TODO: 实现)`);
  };
  
  /**
   * 生成随机点数据
   */
  private generateRandomPoints = (count: number): void => {
    const features: any[] = [];
    
    for (let i = 0; i < count; i++) {
      const lat = 20 + Math.random() * 30;
      const lng = 100 + Math.random() * 30;
      
      features.push({
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [lng, lat]
        },
        "properties": {
          "name": `Point ${i + 1}`,
          "value": Math.floor(Math.random() * 100)
        }
      });
    }
    
    this.sampleGeoJson.features = features;
    this.pointCount = count;
    
    // 重新添加图层
    this.addClusteringLayers();
    
    showToast(`已生成 ${count} 个随机点`);
  };
  
  @Builder
  actionButtonsBuilder() {
    Button('10个点')
      .fontSize(14)
      .onClick(() => this.generateRandomPoints(10));
    
    Button('50个点')
      .fontSize(14)
      .onClick(() => this.generateRandomPoints(50));
    
    Button('100个点')
      .fontSize(14)
      .onClick(() => this.generateRandomPoints(100));
    
    Button('更新配置')
      .fontSize(14)
      .backgroundColor('#4CAF50')
      .onClick(this.updateClusterConfig);
  }
  
  @Builder
  controlPanelBuilder() {
    Column() {
      Text('聚类配置')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 });
      
      Text(`点数量: ${this.pointCount}`)
        .fontSize(14)
        .margin({ bottom: 8 });
      
      // 聚类半径
      Row() {
        Text('聚类半径:')
          .fontSize(14)
          .width(80);
        Slider({
          value: this.clusterRadius,
          min: 10,
          max: 100,
          step: 10
        })
          .layoutWeight(1)
          .onChange((value: number) => {
            this.clusterRadius = value;
          });
        Text(`${this.clusterRadius}`)
          .fontSize(14)
          .width(50);
      }
      .width('100%')
      .margin({ bottom: 8 });
      
      // 最大聚类缩放级别
      Row() {
        Text('最大级别:')
          .fontSize(14)
          .width(80);
        Slider({
          value: this.clusterMaxZoom,
          min: 8,
          max: 18,
          step: 1
        })
          .layoutWeight(1)
          .onChange((value: number) => {
            this.clusterMaxZoom = value;
          });
        Text(`${this.clusterMaxZoom}`)
          .fontSize(14)
          .width(50);
      }
      .width('100%')
      .margin({ bottom: 8 });
      
      Text('说明: 点击聚类可以放大查看详情')
        .fontSize(12)
        .fontColor('#666666')
        .margin({ top: 8 });
    }
    .alignItems(HorizontalAlign.Start)
    .width(280);
  }
  
  build() {
    Column() {
      TestPageLayout({
      title: 'GeoJSON Clustering',
      description: 'GeoJSON 聚类',
      showActionBar: true,
      actionButtons: this.actionButtonsBuilder,
      controlPanel: this.controlPanelBuilder,
      mapContent: () => {
        NativeMapView({
          onMapReady: this.onMapReady
        })
          .width('100%')
          .height('100%');
      }
    });
    }
    .width('100%')
    .height('100%');
  }
}