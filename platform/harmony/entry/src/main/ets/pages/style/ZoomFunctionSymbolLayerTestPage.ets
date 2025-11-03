/**
 * Zoom Function Symbol Layer Test Page
 * 缩放函数符号图层测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MapLibreMapOptions, SymbolLayer, GeoJsonSource, GeoJson, IFeature } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct ZoomFunctionSymbolLayerTestPage {
  private scroller: Scroller = new Scroller();
  private mapController: MapLibreMap | null = null;
  @State private currentZoom: number = 10;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, this.currentZoom);
    
    setTimeout(() => this.addSymbolLayer(), 1000);
  };
  
  private addSymbolLayer = (): void => {
    if (!this.mapController) return;
    
    const props: Record<string, Object> = { 'title': '缩放测试' };
    const geojson = GeoJson.featureCollection([
      GeoJson.pointFeature([116.4074, 39.9042], props)
    ]);
    
    const source = new GeoJsonSource('zoom-source');
    source.setGeoJson(geojson);
    this.mapController.getStyle()?.addSource(source);
    
    const layer = new SymbolLayer('zoom-layer', 'zoom-source');
    // TODO: setProperties() not available - layer.setProperties({
    //   'text-size': 14
    // });
    this.mapController.getStyle()?.addLayer(layer);
    
    showToast('缩放函数图层已添加');
  };
  
  private changeZoom = (zoom: number): void => {
    if (!this.mapController) return;
    
    this.currentZoom = zoom;
    this.mapController.easeTo({ zoom: zoom }, 500);
    showToast(`缩放级别: ${zoom}`);
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
        Text('缩放函数')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        
        Text(`当前缩放: ${this.currentZoom.toFixed(1)}`)
          .fontSize(14)
          .fontColor('#666')
          .width('100%')
        
        Row() {
          Text('缩放:')
            .fontSize(14)
            .width(60)
          Slider({
            value: this.currentZoom,
            min: 1,
            max: 20,
            step: 1
          })
          .layoutWeight(1)
          .onChange((value: number) => {
            this.changeZoom(value);
          })
        }
        .width('100%')
        
        Text('说明: 符号大小随缩放级别变化')
          .fontSize(12)
          .fontColor('#666')
          .width('100%')
          .margin({ top: 8 })
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
        title: 'Zoom Function Symbol Layer',
        description: '缩放函数符号图层',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        actionButtons: (): void => this.buildActionButtons()
      })
    }
    .width('100%')
    .height('100%')
  }
}


