/**
 * Image In Label Test Page
 * 标签中嵌入图片测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MapLibreMapOptions, SymbolLayer, GeoJson, GeoJsonSource } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import type { JsonObject } from '../../types/EntryTypes';

@Entry
@Component
struct ImageInLabelTestPage {
  private scroller: Scroller = new Scroller();
  private mapController: MapLibreMap | null = null;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 12);
    
    setTimeout(() => this.addSymbolLayer(), 1000);
  };
  
  private addSymbolLayer = (): void => {
    if (!this.mapController) return;
    
    const props: Record<string, Object> = { 'title': '📍 北京' };
    const geojson = GeoJson.featureCollection([
      GeoJson.pointFeature([116.4074, 39.9042], props)
    ]);
    
    const source = new GeoJsonSource('label-source');
    source.setGeoJson(geojson);
    this.mapController.getStyle()?.addSource(source);
    
    const layer = new SymbolLayer('label-layer', 'label-source');
    // TODO: setProperties() not available - layer.setProperties({
    //   'text-size': 16,
    //   'text-anchor': 'top',
    //   'text-offset': [0, 1]
    // });
    this.mapController.getStyle()?.addLayer(layer);
    
    showToast('图文标签已添加');
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
  buildActionButtons() {
    Scroll(this.scroller) {
      Column({ space: 8 }) {
        Text('标签中嵌入图片')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        
        Text('说明: 使用Emoji实现图文混排')
          .fontSize(12)
          .fontColor('#666')
          .width('100%')
        
        Text('TODO: 实现自定义图片嵌入')
          .fontSize(12)
          .fontColor('#FF9800')
          .fontWeight(FontWeight.Bold)
          .width('100%')
      }
      .width('100%')
      .padding(8)
    }
    .scrollBar(BarState.Auto)
    .scrollable(ScrollDirection.Vertical)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Image In Label',
        description: '标签中嵌入图片',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        actionButtons: (): void => this.buildActionButtons()
      })
    }
    .width('100%')
    .height('100%')
  }
}


