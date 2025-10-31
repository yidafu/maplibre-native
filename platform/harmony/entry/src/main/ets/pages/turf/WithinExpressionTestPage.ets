/**
 * Within Expression Test Page
 * Within表达式测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { NativeMapView, MapLibreMap, MapLibreMapOptions, FillLayer, CircleLayer, GeoJsonSource, Expression } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS } from '../common/TestUtils';

@Entry
@Component
struct WithinExpressionTestPage {
  private mapController: MapLibreMap | null = null;
  @State private pointsInside: number = 0;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (mapView: NativeMapView): void => {
    const options = new MapLibreMapOptions();
    this.mapController = new MapLibreMap(mapView, options);
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 11);
    
    setTimeout(() => this.addLayers(), 1000);
  };
  
  private addLayers = (): void => {
    if (!this.mapController) return;
    
    // 添加多边形
    const polygon = {
      type: 'FeatureCollection',
      features: [{
        type: 'Feature',
        geometry: {
          type: 'Polygon',
          coordinates: [[
            [116.38, 39.88],
            [116.43, 39.88],
            [116.43, 39.92],
            [116.38, 39.92],
            [116.38, 39.88]
          ]]
        }
      }]
    };
    
    // 添加随机点
    const points = {
      type: 'FeatureCollection',
      features: Array.from({ length: 50 }, () => ({
        type: 'Feature',
        geometry: {
          type: 'Point',
          coordinates: [
            116.35 + Math.random() * 0.1,
            39.85 + Math.random() * 0.1
          ]
        },
        properties: { id: Math.random() }
      }))
    };
    
    const polygonSource = new GeoJsonSource('polygon-source', JSON.stringify(polygon));
    const pointsSource = new GeoJsonSource('points-source', JSON.stringify(points));
    
    this.mapController.getStyle()?.addSource(polygonSource);
    this.mapController.getStyle()?.addSource(pointsSource);
    
    const polygonLayer = new FillLayer('polygon-layer', 'polygon-source');
    polygonLayer.setProperties({
      'fill-color': '#4A90E2',
      'fill-opacity': 0.3,
      'fill-outline-color': '#2196F3'
    });
    this.mapController.getStyle()?.addLayer(polygonLayer);
    
    const pointsLayer = new CircleLayer('points-layer', 'points-source');
    pointsLayer.setProperties({
      'circle-radius': 6,
      'circle-color': '#E74C3C'
    });
    this.mapController.getStyle()?.addLayer(pointsLayer);
    
    showToast('Within表达式测试已设置');
  };
  
  @Builder
  buildMapContent() {
    NativeMapView({
      onMapReady: this.onMapReady
    })
    .width('100%')
    .height('100%')
  }
  
  @Builder
  buildControlPanel() {
    Column({ space: 12 }) {
      Text('Within Expression')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Text(`多边形内的点数: ${this.pointsInside}`)
        .fontSize(14)
        .fontColor('#666')
      
      Text('说明: 蓝色区域为多边形，红点为测试点')
        .fontSize(12)
        .fontColor('#666')
        .margin({ top: 8 })
      
      Text('TODO: 实现 within 表达式过滤')
        .fontSize(12)
        .fontColor('#FF9800')
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .padding(16)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Within Expression',
        description: 'Within表达式',
        showActionBar: true,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%')
  }
}


