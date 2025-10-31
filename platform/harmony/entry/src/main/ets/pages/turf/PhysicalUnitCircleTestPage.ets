/**
 * Physical Unit Circle Test Page
 * 物理单位圆测试页面
 * 
 * 参考: platform/android/.../turf/PhysicalUnitCircleActivity.kt
 * 
 * 测试功能:
 * - 物理单位圆（以米为单位）
 * - 半径动态调整
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { NativeMapView, MapLibreMap, MapLibreMapOptions, FillLayer, GeoJsonSource } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS } from '../common/TestUtils';

@Entry
@Component
struct PhysicalUnitCircleTestPage {
  private mapController: MapLibreMap | null = null;
  @State private radius: number = 5000; // 米
  @State private steps: number = 64;
  private center: number[] = [116.4074, 39.9042];
  
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
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 10);
    
    setTimeout(() => this.addCircle(), 1000);
  };
  
  /**
   * 生成物理单位圆的GeoJSON
   */
  private generateCircle = (): string => {
    const coordinates: number[][] = [];
    const radiusInDegrees = this.radius / 111320; // 近似转换为度
    
    for (let i = 0; i <= this.steps; i++) {
      const angle = (i * 360 / this.steps) * Math.PI / 180;
      const lat = this.center[1] + radiusInDegrees * Math.sin(angle);
      const lng = this.center[0] + radiusInDegrees * Math.cos(angle) / Math.cos(this.center[1] * Math.PI / 180);
      coordinates.push([lng, lat]);
    }
    
    return JSON.stringify({
      type: 'FeatureCollection',
      features: [{
        type: 'Feature',
        geometry: {
          type: 'Polygon',
          coordinates: [coordinates]
        }
      }]
    });
  };
  
  private addCircle = (): void => {
    if (!this.mapController) return;
    
    const circleGeoJson = this.generateCircle();
    const source = new GeoJsonSource('circle-source', circleGeoJson);
    this.mapController.getStyle()?.addSource(source);
    
    const circleLayer = new FillLayer('circle-layer', 'circle-source');
    circleLayer.setProperties({
      'fill-color': '#4A90E2',
      'fill-opacity': 0.4,
      'fill-outline-color': '#2196F3'
    });
    this.mapController.getStyle()?.addLayer(circleLayer);
    
    showToast('物理单位圆已添加');
  };
  
  private updateCircle = (): void => {
    if (!this.mapController) return;
    
    const circleGeoJson = this.generateCircle();
    const source = this.mapController.getStyle()?.getSourceAs('circle-source') as GeoJsonSource;
    if (source) {
      source.setGeoJson(circleGeoJson);
      showToast(`半径已更新: ${this.radius}米`);
    }
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
      Text('物理单位圆')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Row() {
        Text('半径(米):')
          .fontSize(14)
          .width(80)
        Slider({
          value: this.radius,
          min: 1000,
          max: 50000,
          step: 1000
        })
        .layoutWeight(1)
        .onChange((value: number) => {
          this.radius = value;
          this.updateCircle();
        })
        Text(`${this.radius}`)
          .fontSize(14)
          .width(60)
      }
      .width('100%')
      
      Row() {
        Text('精度:')
          .fontSize(14)
          .width(80)
        Slider({
          value: this.steps,
          min: 16,
          max: 128,
          step: 16
        })
        .layoutWeight(1)
        .onChange((value: number) => {
          this.steps = value;
          this.updateCircle();
        })
        Text(`${this.steps}`)
          .fontSize(14)
          .width(60)
      }
      .width('100%')
      
      Text(`周长: ${(2 * Math.PI * this.radius / 1000).toFixed(2)} km`)
        .fontSize(12)
        .fontColor('#666')
      
      Text(`面积: ${(Math.PI * this.radius * this.radius / 1000000).toFixed(2)} km²`)
        .fontSize(12)
        .fontColor('#666')
    }
    .width('100%')
    .padding(16)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Physical Unit Circle',
        description: '物理单位圆',
        showActionBar: true,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%')
  }
}


