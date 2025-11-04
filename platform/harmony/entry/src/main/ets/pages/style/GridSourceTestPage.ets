/**
 * Grid Source Test Page
 * 网格数据源测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MapLibreMapOptions, LineLayer, GeoJsonSource, GeoJson, IFeature, IFeatureCollection } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct GridSourceTestPage {
  private scroller: Scroller = new Scroller();
  private mapController: MapLibreMap | null = null;
  @State private gridSize: number = 10;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 5);
    
    setTimeout(() => this.addGrid(), 1000);
  };
  
  private generateGrid = (): IFeatureCollection => {
    const features: IFeature[] = [];
    const minLat = 39.85, maxLat = 39.95;
    const minLng = 116.35, maxLng = 116.45;
    const latStep = (maxLat - minLat) / this.gridSize;
    const lngStep = (maxLng - minLng) / this.gridSize;
    
    // 水平线
    for (let i = 0; i <= this.gridSize; i++) {
      const lat = minLat + i * latStep;
      features.push(GeoJson.lineStringFeature([[minLng, lat], [maxLng, lat]]));
    }
    
    // 垂直线
    for (let i = 0; i <= this.gridSize; i++) {
      const lng = minLng + i * lngStep;
      features.push(GeoJson.lineStringFeature([[lng, minLat], [lng, maxLat]]));
    }
    
    return GeoJson.featureCollection(features);
  };
  
  private addGrid = (): void => {
    if (!this.mapController) return;
    
    const gridGeoJson = this.generateGrid();
    const source = new GeoJsonSource('grid-source');
    source.setGeoJson(gridGeoJson);
    this.mapController.getStyle()?.addSource(source);
    
    const layer = new LineLayer('grid-layer', 'grid-source');
    layer.setLineWidth(1)
      .setLineOpacity(0.6);
    this.mapController.getStyle()?.addLayer(layer);
    
    showToast('网格已添加');
  };
  
  private updateGrid = (): void => {
    if (!this.mapController) return;
    
    const source = this.mapController.getStyle()?.getSourceAs('grid-source') as GeoJsonSource;
    if (source) {
      source.setGeoJson(this.generateGrid());
      showToast(`网格大小: ${this.gridSize}x${this.gridSize}`);
    }
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
        Text('网格数据源')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        
        Row() {
          Text('网格大小:')
            .fontSize(14)
            .width(80)
          Slider({
            value: this.gridSize,
            min: 5,
            max: 30,
            step: 5
          })
          .layoutWeight(1)
          .onChange((value: number) => {
            this.gridSize = value;
            this.updateGrid();
          })
          Text(`${this.gridSize}`)
            .fontSize(14)
            .width(60)
        }
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
        title: 'Grid Source',
        description: '网格数据源',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        actionButtons: (): void => this.buildActionButtons()
      })
    }
    .width('100%')
    .height('100%')
  }
}


