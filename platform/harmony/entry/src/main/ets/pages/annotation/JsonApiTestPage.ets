/**
 * JSON API Test Page
 * JSON API测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { NativeMapView, MapLibreMap, MapLibreMapOptions, GeoJsonSource, CircleLayer } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS } from '../common/TestUtils';

@Entry
@Component
struct JsonApiTestPage {
  private mapController: MapLibreMap | null = null;
  @State private featureCount: number = 0;
  
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
  
  private addGeoJsonFromString = (): void => {
    if (!this.mapController) return;
    
    const geoJsonString = `{
      "type": "FeatureCollection",
      "features": [
        {"type": "Feature", "geometry": {"type": "Point", "coordinates": [116.4074, 39.9042]}},
        {"type": "Feature", "geometry": {"type": "Point", "coordinates": [121.4737, 31.2304]}},
        {"type": "Feature", "geometry": {"type": "Point", "coordinates": [113.2644, 23.1291]}}
      ]
    }`;
    
    const source = new GeoJsonSource('json-source', geoJsonString);
    this.mapController.getStyle()?.addSource(source);
    
    const layer = new CircleLayer('json-layer', 'json-source');
    layer.setProperties({
      'circle-radius': 8,
      'circle-color': '#E74C3C'
    });
    this.mapController.getStyle()?.addLayer(layer);
    
    this.featureCount = 3;
    showToast('GeoJSON已添加（3个点）');
  };
  
  private updateGeoJson = (): void => {
    if (!this.mapController) return;
    
    const features = [];
    for (let i = 0; i < 10; i++) {
      features.push({
        type: 'Feature',
        geometry: {
          type: 'Point',
          coordinates: [115 + Math.random() * 10, 30 + Math.random() * 15]
        }
      });
    }
    
    const geoJsonString = JSON.stringify({
      type: 'FeatureCollection',
      features: features
    });
    
    const source = this.mapController.getStyle()?.getSourceAs('json-source') as GeoJsonSource;
    if (source) {
      source.setGeoJson(geoJsonString);
      this.featureCount = 10;
      showToast('GeoJSON已更新（10个随机点）');
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
      Text('JSON API')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Text(`特征数: ${this.featureCount}`)
        .fontSize(14)
        .fontColor('#666')
      
      Button('添加GeoJSON')
        .width('100%')
        .onClick(() => this.addGeoJsonFromString())
      
      Button('更新GeoJSON')
        .width('100%')
        .enabled(this.featureCount > 0)
        .onClick(() => this.updateGeoJson())
      
      Text('说明: 通过JSON字符串操作GeoJSON数据')
        .fontSize(12)
        .fontColor('#666')
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'JSON API',
        description: 'JSON API测试',
        showActionBar: true,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%')
  }
}


