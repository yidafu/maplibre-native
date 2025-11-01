/**
 * Symbol Generator Test Page
 * 符号生成器测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MapLibreMapOptions, SymbolLayer, GeoJson, GeoJsonSource } from 'maplibre_harmony';
import type { JsonObject } from '../../types/EntryTypes';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

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
  
  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 10);
  };
  
  private addRandomSymbol = (): void => {
    if (!this.mapController) return;
    
    const lat = 39.85 + Math.random() * 0.1;
    const lng = 116.35 + Math.random() * 0.1;
    const emoji = ['📍', '⭐', '❤️', '🎯', '🏠'][Math.floor(Math.random() * 5)];
    
    const props: Record<string, Object> = { 'symbol': emoji };
    const geojson = GeoJson.featureCollection([
      GeoJson.pointFeature([lng, lat], props)
    ]);
    
    const sourceId = `symbol-source-${this.symbolCount}`;
    const layerId = `symbol-layer-${this.symbolCount}`;
    
    const source = new GeoJsonSource(sourceId);
    source.setGeoJson(geojson);
    this.mapController.getStyle()?.addSource(source);
    
    const layer = new SymbolLayer(layerId, sourceId);
    // TODO: setProperties() not available - layer.setProperties({
    //   'text-size': 24
    // });
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
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      })
    }
    .width('100%')
    .height('100%')
  }
}


