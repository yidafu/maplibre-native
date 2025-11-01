/**
 * Within Expression Test Page
 * Within表达式测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MapLibreMapOptions, FillLayer, CircleLayer, GeoJson, GeoJsonSource, Expression,
  IFeature } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import type { JsonObject } from '../../types/EntryTypes';

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
  
  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 11);
    
    setTimeout(() => this.addLayers(), 1000);
  };
  
  private addLayers (): void  {
    if (!this.mapController) return;
    
    // 添加多边形
    const polygon = GeoJson.featureCollection([
      GeoJson.polygonFeature([[
        [116.38, 39.88],
        [116.43, 39.88],
        [116.43, 39.92],
        [116.38, 39.92],
        [116.38, 39.88]
      ]])
    ]);
    
    // 添加随机点
    const randomProps: Record<string, Object> = {};
    const points = GeoJson.featureCollection(
      Array.from<number>({ length: 50 }).fill(1).map((): IFeature => {
        return GeoJson.pointFeature([
            116.35 + Math.random() * 0.1,
            39.85 + Math.random() * 0.1,
            0
          ], randomProps)
      }));


    const polygonSource = new GeoJsonSource('polygon-source');
    polygonSource.setGeoJson(polygon);
    const pointsSource = new GeoJsonSource('points-source');
    pointsSource.setGeoJson(points);
    
    this.mapController.getStyle()?.addSource(polygonSource);
    this.mapController.getStyle()?.addSource(pointsSource);
    
    const polygonLayer = new FillLayer('polygon-layer', 'polygon-source');
    // TODO: setProperties() not available - polygonLayer.setProperties({
    //   'fill-opacity': 0.3,
    //   'fill-outline-color': '#2196F3'
    // });
    this.mapController.getStyle()?.addLayer(polygonLayer);
    
    const pointsLayer = new CircleLayer('points-layer', 'points-source');
    // TODO: setProperties() not available - pointsLayer.setProperties({
    //   'circle-color': '#E74C3C'
    // });
    this.mapController.getStyle()?.addLayer(pointsLayer);
    
    showToast('Within表达式测试已设置');
  };
  
  @Builder
  buildMapContent() {
    MapView({
      onMapReady: this.onMapReady,
            styleUrl: DEFAULT_STYLE_URLS.bright,
            initialLatitude: 39.9,
            initialLongitude: 116.4,
            initialZoom: 10
    })
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
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      })
    }
    .width('100%')
    .height('100%')
  }
}


