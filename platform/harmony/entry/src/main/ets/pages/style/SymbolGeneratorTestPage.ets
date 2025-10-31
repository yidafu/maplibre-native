/**
 * Symbol Generator Test Page
 * 符号生成器测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { NativeMapView, MapLibreMap, MapLibreMapOptions, SymbolLayer, GeoJsonSource } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS } from '../common/TestUtils';

@Entry
@Component
struct SymbolGeneratorTestPage {
  private mapController: MapLibreMap | null = null;
  @State private symbolCount: number = 0;
  
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
  
  private addRandomSymbol = (): void => {
    if (!this.mapController) return;
    
    const lat = 39.85 + Math.random() * 0.1;
    const lng = 116.35 + Math.random() * 0.1;
    const emoji = ['📍', '⭐', '❤️', '🎯', '🏠'][Math.floor(Math.random() * 5)];
    
    const geojson = {
      type: 'FeatureCollection',
      features: [{
        type: 'Feature',
        geometry: {
          type: 'Point',
          coordinates: [lng, lat]
        },
        properties: {
          symbol: emoji
        }
      }]
    };
    
    const sourceId = `symbol-source-${this.symbolCount}`;
    const layerId = `symbol-layer-${this.symbolCount}`;
    
    const source = new GeoJsonSource(sourceId, JSON.stringify(geojson));
    this.mapController.getStyle()?.addSource(source);
    
    const layer = new SymbolLayer(layerId, sourceId);
    layer.setProperties({
      'text-field': ['get', 'symbol'],
      'text-size': 24
    });
    this.mapController.getStyle()?.addLayer(layer);
    
    this.symbolCount++;
    showToast(`符号已添加: ${emoji}`);
  };
  
  private clearSymbols = (): void => {
    if (!this.mapController) return;
    
    for (let i = 0; i < this.symbolCount; i++) {
      this.mapController.getStyle()?.removeLayer(`symbol-layer-${i}`);
      this.mapController.getStyle()?.removeSource(`symbol-source-${i}`);
    }
    
    this.symbolCount = 0;
    showToast('符号已清除');
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
      Text('符号生成器')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Text(`符号数量: ${this.symbolCount}`)
        .fontSize(14)
        .fontColor('#666')
      
      Button('添加随机符号')
        .width('100%')
        .onClick(() => this.addRandomSymbol())
      
      Button('清除所有符号')
        .width('100%')
        .backgroundColor('#FF6B6B')
        .enabled(this.symbolCount > 0)
        .onClick(() => this.clearSymbols())
    }
    .width('100%')
    .padding(16)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Symbol Generator',
        description: '符号生成器',
        showActionBar: true,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%')
  }
}


