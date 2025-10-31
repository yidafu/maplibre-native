/**
 * Runtime Style Timing Test Page
 * 运行时样式计时测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { NativeMapView, MapLibreMap, MapLibreMapOptions, CircleLayer, GeoJsonSource } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS } from '../common/TestUtils';

@Entry
@Component
struct RuntimeStyleTimingTestPage {
  private mapController: MapLibreMap | null = null;
  @State private addLayerTime: number = 0;
  @State private removeLayerTime: number = 0;
  @State private updateSourceTime: number = 0;
  @State private layerCount: number = 0;
  
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
  };
  
  private testAddLayer = (): void => {
    if (!this.mapController) return;
    
    const startTime = Date.now();
    
    const geojson = {
      type: 'FeatureCollection',
      features: [{
        type: 'Feature',
        geometry: {
          type: 'Point',
          coordinates: [116.4074, 39.9042]
        }
      }]
    };
    
    const source = new GeoJsonSource(`test-source-${this.layerCount}`, JSON.stringify(geojson));
    this.mapController.getStyle()?.addSource(source);
    
    const layer = new CircleLayer(`test-layer-${this.layerCount}`, `test-source-${this.layerCount}`);
    layer.setProperties({
      'circle-radius': 8,
      'circle-color': '#E74C3C'
    });
    this.mapController.getStyle()?.addLayer(layer);
    
    this.addLayerTime = Date.now() - startTime;
    this.layerCount++;
    showToast(`添加图层耗时: ${this.addLayerTime}ms`);
  };
  
  private testRemoveLayer = (): void => {
    if (!this.mapController || this.layerCount === 0) return;
    
    const startTime = Date.now();
    
    const layerId = `test-layer-${this.layerCount - 1}`;
    this.mapController.getStyle()?.removeLayer(layerId);
    
    this.removeLayerTime = Date.now() - startTime;
    this.layerCount--;
    showToast(`删除图层耗时: ${this.removeLayerTime}ms`);
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
      Text('样式性能测试')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Text(`当前图层数: ${this.layerCount}`)
        .fontSize(14)
        .fontColor('#666')
      
      Button('添加图层')
        .width('100%')
        .onClick(() => this.testAddLayer())
      
      Text(`添加耗时: ${this.addLayerTime}ms`)
        .fontSize(12)
        .fontColor('#666')
      
      Button('删除图层')
        .width('100%')
        .enabled(this.layerCount > 0)
        .onClick(() => this.testRemoveLayer())
      
      Text(`删除耗时: ${this.removeLayerTime}ms`)
        .fontSize(12)
        .fontColor('#666')
    }
    .width('100%')
    .padding(16)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Runtime Style Timing',
        description: '样式计时测试',
        showActionBar: true,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%')
  }
}


