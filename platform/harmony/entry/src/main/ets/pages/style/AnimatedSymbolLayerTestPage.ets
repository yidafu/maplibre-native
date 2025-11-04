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
  private mapController: MapLibreMap | null = null;
  @State private markerPosition: LatLng = LatLng.create(39.9042, 116.4074);
  @State private isAnimating: boolean = false;
  @State private currentStyleIndex: number = 0;
  @State private layerVisible: boolean = true;
  private animationIntervalId: number = -1;
  private readonly STYLES = [DEFAULT_STYLE_URLS.streets, DEFAULT_STYLE_URLS.bright];
  
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
    symbolLayer.setTextField('📍');
    symbolLayer.setTextSize(24);
    symbolLayer.setTextColor('#F44336');
    symbolLayer.setTextAllowOverlap(true);
    symbolLayer.setTextHaloColor('#FFFFFF');
    symbolLayer.setTextHaloWidth(2);
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
    // 移除内层 Scroll，TestPageLayout 已经提供了外层 Scroll
    Column({ space: 8 }) {
      Text('动画控制')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Button(this.isAnimating ? '停止动画' : '开始动画')
        .fontSize(14)
        .width('100%')
        .backgroundColor(this.isAnimating ? '#F44336' : '#4CAF50')
        .onClick(() => {
          if (this.isAnimating) {
            this.stopAnimation();
          } else {
            this.startAnimation();
          }
        })
      
      Button('重置位置')
        .fontSize(14)
        .width('100%')
        .onClick(() => {
          this.stopAnimation();
          this.markerPosition = LatLng.create(39.9042, 116.4074);
          this.updateMarkerPosition();
          showToast('位置已重置');
        })
      
      Text(`位置: ${this.markerPosition.latitude.toFixed(4)}, ${this.markerPosition.longitude.toFixed(4)}`)
        .fontSize(12)
        .fontColor('#666')
        .width('100%')
        .margin({ bottom: 8 })
      
      Text('文本样式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('文本颜色')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeTextColor())
        
        Button('文本大小')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeTextSize())
      }
      
      Row({ space: 8 }) {
        Button('光晕颜色')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeTextHaloColor())
        
        Button('光晕宽度')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeTextHaloWidth())
      }
      
      Text('显示模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('显示/隐藏')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.toggleVisibility())
        
        Button('重置视图')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.resetView())
      }
    }
    .width('100%')
  }

  // 改变文本颜色
  private changeTextColor(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('marker-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      const colors: string[] = ['#F44336', '#4CAF50', '#2196F3', '#FF9800', '#9C27B0', '#000000'];
      const randomColor: string = colors[Math.floor(Math.random() * colors.length)];
      
      layer.setTextColor(randomColor);
      showToast(`文本颜色: ${randomColor}`);
    } catch (error) {
      showToast(`更改文本颜色失败: ${error}`);
    }
  }

  // 改变文本大小
  private changeTextSize(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('marker-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      const size = 16 + Math.random() * 24; // 16-40
      layer.setTextSize(size);
      showToast(`文本大小: ${size.toFixed(1)}`);
    } catch (error) {
      showToast(`更改文本大小失败: ${error}`);
    }
  }

  // 改变文本光晕颜色
  private changeTextHaloColor(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('marker-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      const colors: string[] = ['#FFFFFF', '#000000', '#FFFF00', '#00FFFF'];
      const randomColor: string = colors[Math.floor(Math.random() * colors.length)];
      
      layer.setTextHaloColor(randomColor);
      showToast(`文本光晕: ${randomColor}`);
    } catch (error) {
      showToast(`更改文本光晕颜色失败: ${error}`);
    }
  }

  // 改变文本光晕宽度
  private changeTextHaloWidth(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('marker-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      const width = 1 + Math.random() * 4; // 1-5
      layer.setTextHaloWidth(width);
      showToast(`文本光晕宽度: ${width.toFixed(1)}`);
    } catch (error) {
      showToast(`更改文本光晕宽度失败: ${error}`);
    }
  }

  // 切换显示/隐藏
  private toggleVisibility(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('marker-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      this.layerVisible = !this.layerVisible;
      layer.setVisibility(this.layerVisible ? 'visible' : 'none');
      showToast(`图层: ${this.layerVisible ? '显示' : '隐藏'}`);
    } catch (error) {
      showToast(`切换显示失败: ${error}`);
    }
  }

  // 重置视图
  private resetView(): void {
    if (!this.mapController) return;
    
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 12);
    showToast('视图已重置');
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


