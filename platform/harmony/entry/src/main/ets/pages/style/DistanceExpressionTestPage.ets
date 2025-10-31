/**
 * Distance Expression Test Page
 * 距离表达式测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { NativeMapView, MapLibreMap, MapLibreMapOptions, CircleLayer, GeoJsonSource, LatLng } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS } from '../common/TestUtils';

@Entry
@Component
struct DistanceExpressionTestPage {
  private mapController: MapLibreMap | null = null;
  @State private centerPoint: LatLng = LatLng.create(39.9042, 116.4074);
  @State private distance: number = 5000; // 米
  
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
    
    setTimeout(() => this.addLayers(), 1000);
  };
  
  private addLayers = (): void => {
    if (!this.mapController) return;
    
    // 生成圆形区域的点
    const points = [];
    for (let angle = 0; angle < 360; angle += 10) {
      const rad = angle * Math.PI / 180;
      const offsetLat = (this.distance / 111320) * Math.sin(rad);
      const offsetLng = (this.distance / 111320) * Math.cos(rad) / Math.cos(this.centerPoint.latitude * Math.PI / 180);
      
      points.push({
        type: 'Feature',
        geometry: {
          type: 'Point',
          coordinates: [this.centerPoint.longitude + offsetLng, this.centerPoint.latitude + offsetLat]
        }
      });
    }
    
    const geojson = {
      type: 'FeatureCollection',
      features: points
    };
    
    const source = new GeoJsonSource('distance-points', JSON.stringify(geojson));
    this.mapController.getStyle()?.addSource(source);
    
    const layer = new CircleLayer('distance-layer', 'distance-points');
    layer.setProperties({
      'circle-radius': 6,
      'circle-color': '#4A90E2'
    });
    this.mapController.getStyle()?.addLayer(layer);
    
    showToast('距离表达式图层已添加');
  };
  
  private updateDistance = (): void => {
    if (!this.mapController) return;
    
    const source = this.mapController.getStyle()?.getSourceAs('distance-points') as GeoJsonSource;
    if (source) {
      const points = [];
      for (let angle = 0; angle < 360; angle += 10) {
        const rad = angle * Math.PI / 180;
        const offsetLat = (this.distance / 111320) * Math.sin(rad);
        const offsetLng = (this.distance / 111320) * Math.cos(rad) / Math.cos(this.centerPoint.latitude * Math.PI / 180);
        
        points.push({
          type: 'Feature',
          geometry: {
            type: 'Point',
            coordinates: [this.centerPoint.longitude + offsetLng, this.centerPoint.latitude + offsetLat]
          }
        });
      }
      
      source.setGeoJson(JSON.stringify({
        type: 'FeatureCollection',
        features: points
      }));
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
      Text('距离表达式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Row() {
        Text('距离(米):')
          .fontSize(14)
          .width(80)
        Slider({
          value: this.distance,
          min: 1000,
          max: 20000,
          step: 1000
        })
        .layoutWeight(1)
        .onChange((value: number) => {
          this.distance = value;
          this.updateDistance();
        })
        Text(`${this.distance}`)
          .fontSize(14)
          .width(60)
      }
    }
    .width('100%')
    .padding(16)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Distance Expression',
        description: '距离表达式',
        showActionBar: true,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%')
  }
}


