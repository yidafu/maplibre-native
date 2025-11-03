/**
 * Animated Symbol Layer Test Page
 * 动画符号图层测试页面
 * 
 * 参考: platform/android/.../style/AnimatedSymbolLayerActivity.kt
 * 注意: 使用Harmony animateTo替代Android ValueAnimator
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MapLibreMapOptions, SymbolLayer, GeoJsonSource, LatLng, GeoJson, IFeature } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct AnimatedSymbolLayerTestPage {
  private scroller: Scroller = new Scroller();
  private mapController: MapLibreMap | null = null;
  @State private markerPosition: LatLng = LatLng.create(39.9042, 116.4074);
  @State private isAnimating: boolean = false;
  private animationIntervalId: number = -1;
  
  aboutToDisappear() {
    if (this.animationIntervalId !== -1) {
      clearInterval(this.animationIntervalId);
    }
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
    
    const geojson = GeoJson.featureCollection([
      GeoJson.pointFeature([this.markerPosition.longitude, this.markerPosition.latitude])
    ]);
    
    const source = new GeoJsonSource('marker-source');
    source.setGeoJson(geojson);
    this.mapController.getStyle()?.addSource(source);
    
    const symbolLayer = new SymbolLayer('marker-layer', 'marker-source');
    // TODO: setProperties() not available - symbolLayer.setProperties({
    //   'icon-size': 1.5,
    //   'icon-allow-overlap': true
    // });
    this.mapController.getStyle()?.addLayer(symbolLayer);
  };
  
  private startAnimation = (): void => {
    if (this.isAnimating) return;
    
    this.isAnimating = true;
    let currentLat = 39.9042;
    let currentLng = 116.4074;
    const targetLat = 39.9142;
    const targetLng = 116.4174;
    
    this.animationIntervalId = setInterval(() => {
      const progress = 0.02;
      currentLat += (targetLat - currentLat) * progress;
      currentLng += (targetLng - currentLng) * progress;
      
      this.markerPosition = LatLng.create(currentLat, currentLng);
      this.updateMarkerPosition();
      
      if (Math.abs(currentLat - targetLat) < 0.0001) {
        this.stopAnimation();
      }
    }, 50);
  };
  
  private stopAnimation = (): void => {
    if (this.animationIntervalId !== -1) {
      clearInterval(this.animationIntervalId);
      this.animationIntervalId = -1;
    }
    this.isAnimating = false;
  };
  
  private updateMarkerPosition = (): void => {
    if (!this.mapController) return;
    
    const geojson = GeoJson.featureCollection([
      GeoJson.pointFeature([this.markerPosition.longitude, this.markerPosition.latitude])
    ]);
    
    const source = this.mapController.getStyle()?.getSourceAs('marker-source') as GeoJsonSource;
    if (source) {
      source.setGeoJson(geojson);
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
        Button(this.isAnimating ? '停止动画' : '开始动画')
          .width('100%')
          .backgroundColor(this.isAnimating ? '#FF6B6B' : '#4CAF50')
          .onClick(() => {
            if (this.isAnimating) {
              this.stopAnimation();
            } else {
              this.startAnimation();
            }
          })
        
        Button('重置位置')
          .width('100%')
          .onClick(() => {
            this.stopAnimation();
            this.markerPosition = LatLng.create(39.9042, 116.4074);
            this.updateMarkerPosition();
          })
        
        Text(`位置: ${this.markerPosition.latitude.toFixed(4)}, ${this.markerPosition.longitude.toFixed(4)}`)
          .fontSize(12)
          .fontColor('#666')
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
        title: 'Animated Symbol Layer',
        description: '动画符号图层',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        actionButtons: (): void => this.buildActionButtons()
      })
    }
    .width('100%')
    .height('100%')
  }
}


