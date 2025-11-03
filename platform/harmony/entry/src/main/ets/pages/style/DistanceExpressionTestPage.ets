/**
 * Distance Expression Test Page
 * 距离表达式测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MapLibreMapOptions, CircleLayer, GeoJsonSource, LatLng, GeoJson, IFeature } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct DistanceExpressionTestPage {
  private scroller: Scroller = new Scroller();
  private mapController: MapLibreMap | null = null;
  @State private centerPoint: LatLng = LatLng.create(39.9042, 116.4074);
  @State private distance: number = 5000; // 米
  
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
    
    setTimeout(() => this.addLayers(), 1000);
  };
  
  private addLayers = (): void => {
    if (!this.mapController) return;
    
    // 生成圆形区域的点
    const points: IFeature[] = [];
    for (let angle = 0; angle < 360; angle += 10) {
      const rad = angle * Math.PI / 180;
      const offsetLat = (this.distance / 111320) * Math.sin(rad);
      const offsetLng = (this.distance / 111320) * Math.cos(rad) / Math.cos(this.centerPoint.latitude * Math.PI / 180);
      
      points.push(GeoJson.pointFeature([this.centerPoint.longitude + offsetLng, this.centerPoint.latitude + offsetLat]));
    }
    
    const geojson = GeoJson.featureCollection(points);
    
    const source = new GeoJsonSource('distance-points');
    source.setGeoJson(geojson);
    this.mapController.getStyle()?.addSource(source);
    
    const layer = new CircleLayer('distance-layer', 'distance-points');
    // TODO: setProperties() not available - layer.setProperties({
    //   'circle-color': '#4A90E2'
    // });
    this.mapController.getStyle()?.addLayer(layer);
    
    showToast('距离表达式图层已添加');
  };
  
  private updateDistance = (): void => {
    if (!this.mapController) return;
    
    const source = this.mapController.getStyle()?.getSourceAs('distance-points') as GeoJsonSource;
    if (source) {
      const points: IFeature[] = [];
      for (let angle = 0; angle < 360; angle += 10) {
        const rad = angle * Math.PI / 180;
        const offsetLat = (this.distance / 111320) * Math.sin(rad);
        const offsetLng = (this.distance / 111320) * Math.cos(rad) / Math.cos(this.centerPoint.latitude * Math.PI / 180);
        
        points.push(GeoJson.pointFeature([this.centerPoint.longitude + offsetLng, this.centerPoint.latitude + offsetLat]));
      }
      
      source.setGeoJson(GeoJson.featureCollection(points));
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
        Text('距离表达式')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        
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
        title: 'Distance Expression',
        description: '距离表达式',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        actionButtons: (): void => this.buildActionButtons()
      })
    }
    .width('100%')
    .height('100%')
  }
}


