/**
 * Image In Label Test Page
 * 标签中嵌入图片测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { NativeMapView, MapLibreMap, MapLibreMapOptions, SymbolLayer, GeoJsonSource } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS } from '../common/TestUtils';

@Entry
@Component
struct ImageInLabelTestPage {
  private mapController: MapLibreMap | null = null;
  
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
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 12);
    
    setTimeout(() => this.addSymbolLayer(), 1000);
  };
  
  private addSymbolLayer = (): void => {
    if (!this.mapController) return;
    
    const geojson = {
      type: 'FeatureCollection',
      features: [{
        type: 'Feature',
        geometry: {
          type: 'Point',
          coordinates: [116.4074, 39.9042]
        },
        properties: {
          title: '📍 北京'
        }
      }]
    };
    
    const source = new GeoJsonSource('label-source', JSON.stringify(geojson));
    this.mapController.getStyle()?.addSource(source);
    
    const layer = new SymbolLayer('label-layer', 'label-source');
    layer.setProperties({
      'text-field': ['get', 'title'],
      'text-size': 16,
      'text-anchor': 'top',
      'text-offset': [0, 1]
    });
    this.mapController.getStyle()?.addLayer(layer);
    
    showToast('图文标签已添加');
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
      Text('标签中嵌入图片')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Text('说明: 使用Emoji实现图文混排')
        .fontSize(12)
        .fontColor('#666')
      
      Text('TODO: 实现自定义图片嵌入')
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
        title: 'Image In Label',
        description: '标签中嵌入图片',
        showActionBar: true,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%')
  }
}


