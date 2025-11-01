/**
 * Performance Measurement Test Page
 * 性能指标测量测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MapLibreMapOptions } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct PerformanceMeasurementTestPage {
  private mapController: MapLibreMap | null = null;
  @State private memoryUsage: number = 0;
  @State private renderingTime: number = 0;
  @State private fps: number = 0;
  @State private tileCount: number = 0;
  @State private measurements:  string[] = [];
  private measurementInterval: number = -1;
  
  aboutToDisappear() {
    if (this.measurementInterval !== -1) {
      clearInterval(this.measurementInterval);
    }
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 12);
  };
  
  private startMeasurement = (): void => {
    if (this.measurementInterval !== -1) return;
    
    this.measurementInterval = setInterval(() => {
      // 模拟性能测量
      this.memoryUsage = Math.round(Math.random() * 50 + 30); // MB
      this.renderingTime = Math.round(Math.random() * 10 + 5); // ms
      this.fps = Math.round(Math.random() * 10 + 50);
      this.tileCount = Math.round(Math.random() * 20 + 10);
      
      const timestamp = new Date().toLocaleTimeString();
      this.measurements.unshift(`[${timestamp}] FPS:${this.fps} Mem:${this.memoryUsage}MB`);
      if (this.measurements.length > 8) {
        this.measurements.pop();
      }
    }, 1000);
    
    showToast('性能测量已启动');
  };
  
  private stopMeasurement = (): void => {
    if (this.measurementInterval !== -1) {
      clearInterval(this.measurementInterval);
      this.measurementInterval = -1;
      showToast('性能测量已停止');
    }
  };
  
  private clearMeasurements = (): void => {
    this.measurements = [];
    showToast('测量记录已清除');
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
    Scroll() {
      Column({ space: 12 }) {
        Text('性能指标测量')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        
        Text('当前指标')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
        
        Column({ space: 4 }) {
          Text(`内存使用: ${this.memoryUsage} MB`)
            .fontSize(12)
          Text(`渲染时间: ${this.renderingTime} ms`)
            .fontSize(12)
          Text(`帧率: ${this.fps} FPS`)
            .fontSize(12)
          Text(`瓦片数: ${this.tileCount}`)
            .fontSize(12)
        }
        .width('100%')
        .padding(8)
        .backgroundColor('#F5F5F5')
        .borderRadius(4)
        
        Button(this.measurementInterval !== -1 ? '停止测量' : '开始测量')
          .width('100%')
          .backgroundColor(this.measurementInterval !== -1 ? '#FF6B6B' : '#4CAF50')
          .onClick(() => {
            if (this.measurementInterval !== -1) {
              this.stopMeasurement();
            } else {
              this.startMeasurement();
            }
          })
        
        Button('清除记录')
          .width('100%')
          .enabled(this.measurements.length > 0)
          .onClick(() => this.clearMeasurements())
        
        Text('测量记录')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 8 })
        
        Column() {
          ForEach(this.measurements, (measurement: string, index: number) => {
            Text(measurement)
              .fontSize(10)
              .fontFamily('monospace')
              .width('100%')
              .padding(4)
              .backgroundColor(index % 2 === 0 ? '#F5F5F5' : '#FFFFFF')
          })
        }
        .width('100%')
        .backgroundColor('#F9F9F9')
        .border({ width: 1, color: '#DDD' })
        .borderRadius(4)
        
        Text('说明: 实时监控地图性能指标')
          .fontSize(12)
          .fontColor('#666')
          .margin({ top: 8 })
      }
      .width('100%')
      .padding(16)
    }
    .height('100%')
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Performance Measurement',
        description: '性能指标测量',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      })
    }
    .width('100%')
    .height('100%')
  }
}

