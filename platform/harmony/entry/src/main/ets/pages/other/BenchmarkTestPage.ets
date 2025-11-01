/**
 * Benchmark Test Page
 * 性能基准测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MapLibreMapOptions, Marker, MarkerOptions, LatLng } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct BenchmarkTestPage {
  private mapController: MapLibreMap | null = null;
  @State private renderTime: number = 0;
  @State private markerAddTime: number = 0;
  @State private cameraAnimTime: number = 0;
  @State private fps: number = 0;
  private frameCount: number = 0;
  private lastFpsTime: number = 0;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    const startTime = Date.now();
    
    this.mapController = map;
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 12);
    
    this.renderTime = Date.now() - startTime;
    this.startFpsMonitoring();
  };
  
  private startFpsMonitoring = (): void => {
    this.lastFpsTime = Date.now();
    setInterval(() => {
      const now = Date.now();
      const elapsed = now - this.lastFpsTime;
      if (elapsed >= 1000) {
        this.fps = Math.round(this.frameCount * 1000 / elapsed);
        this.frameCount = 0;
        this.lastFpsTime = now;
      }
      this.frameCount++;
    }, 16); // ~60fps
  };
  
  private benchmarkAddMarkers = async (): Promise<void> => {
    if (!this.mapController) return;
    
    const startTime = Date.now();
    const markerCount = 100;
    
    for (let i = 0; i < markerCount; i++) {
      const lat = 39.85 + Math.random() * 0.1;
      const lng = 116.35 + Math.random() * 0.1;
      const markerOptions = new MarkerOptions().position(LatLng.create(lat, lng));
      await this.mapController.addMarker(markerOptions);
    }
    
    this.markerAddTime = Date.now() - startTime;
    showToast(`${markerCount}个标记耗时: ${this.markerAddTime}ms`);
  };
  
  private benchmarkCameraAnimation = (): void => {
    if (!this.mapController) return;
    
    const startTime = Date.now();
    
    this.mapController.easeTo({
      center: TEST_LOCATIONS.shanghai,
      zoom: 15
    }, 2000);
    
    setTimeout(() => {
      this.cameraAnimTime = Date.now() - startTime;
      showToast(`相机动画耗时: ${this.cameraAnimTime}ms`);
    }, 2000);
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
        Text('性能基准测试')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        
        Text('测试结果')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
        
        Column({ space: 4 }) {
          Text(`地图初始化: ${this.renderTime}ms`)
            .fontSize(12)
          Text(`FPS: ${this.fps}`)
            .fontSize(12)
          Text(`添加100个标记: ${this.markerAddTime}ms`)
            .fontSize(12)
          Text(`相机动画: ${this.cameraAnimTime}ms`)
            .fontSize(12)
        }
        .width('100%')
        .padding(8)
        .backgroundColor('#F5F5F5')
        .borderRadius(4)
        
        Button('测试添加标记')
          .width('100%')
          .onClick(() => this.benchmarkAddMarkers())
        
        Button('测试相机动画')
          .width('100%')
          .onClick(() => this.benchmarkCameraAnimation())
        
        Text('说明: 性能基准测试工具')
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
        title: 'Benchmark',
        description: '性能基准测试',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      })
    }
    .width('100%')
    .height('100%')
  }
}


