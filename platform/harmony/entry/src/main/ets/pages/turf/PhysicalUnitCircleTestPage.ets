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
import { MapView, MapLibreMap, MapLibreMapOptions, FillLayer, GeoJson, GeoJsonSource } from 'maplibre_harmony';
import type { Position } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import type { JsonObject } from '../../types/EntryTypes';

@Entry
@Component
struct PhysicalUnitCircleTestPage {
  private mapController: MapLibreMap | null = null;
  @State private radius: number = 5000; // 米
  @State private steps: number = 64;
  private center: number[] = [116.4074, 39.9042]
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 5);
    
    setTimeout(() => this.addCircle(), 1000);
  };
  
  /**
   * 生成物理单位圆的GeoJSON
   */
  private generateCircle = () => {
    const coordinates: number[][] = [];
    const radiusInDegrees = this.radius / 111320; // 近似转换为度
    
    for (let i = 0; i <= this.steps; i++) {
      const angle = (i * 360 / this.steps) * Math.PI / 180;
      const lat = this.center[1] + radiusInDegrees * Math.sin(angle);
      const lng = this.center[0] + radiusInDegrees * Math.cos(angle) / Math.cos(this.center[1] * Math.PI / 180);
      coordinates.push([lng, lat, 0]);
    }
    
    const coords3d: Position[] = coordinates.map((coord: number[]): Position => [coord[0], coord[1], coord[2] || 0] as Position);
    return GeoJson.featureCollection([
      GeoJson.polygonFeature([coords3d])
    ]);
  };
  
  private addCircle = (): void => {
    if (!this.mapController) return;
    
    const circleGeoJson = this.generateCircle();
    const source = new GeoJsonSource('circle-source');
    source.setGeoJson(circleGeoJson);
    this.mapController.getStyle()?.addSource(source);
    
    const circleLayer = new FillLayer('circle-layer', 'circle-source');
    circleLayer.setFillColor('#4A90E2')
      .setFillOpacity(0.4)
      .setFillOutlineColor('#2196F3');
    this.mapController.getStyle()?.addLayer(circleLayer);
    
    showToast('物理单位圆已添加');
  };
  
  private updateCircle = (): void => {
    if (!this.mapController) return;
    
    const circleGeoJson = this.generateCircle();
    const source = this.mapController.getStyle()?.getSource('circle-source');
    if (source && source instanceof GeoJsonSource) {
      source.setGeoJson(circleGeoJson);
      showToast(`半径已更新: ${this.radius}米`);
    }
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
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      })
    }
    .width('100%')
    .height('100%')
  }
}


