/**
 * Zoom Function Symbol Layer Test Page
 * 缩放函数符号图层测试页面
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, MapLibreMapOptions, SymbolLayer, GeoJsonSource, GeoJson, IFeature } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

import type { JSONValue } from 'libmaplibre.so';
@Entry
@Component
struct ZoomFunctionSymbolLayerTestPage {
  private mapController: MapLibreMap | null = null;
  @State private currentZoom: number = 10;
  @State private currentStyleIndex: number = 0;
  @State private layerVisible: boolean = true;
  private readonly STYLES = [DEFAULT_STYLE_URLS.streets, DEFAULT_STYLE_URLS.bright];
  
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
    
    const props: Record<string, JSONValue> = { 'title': '缩放测试' };
    const geojson = GeoJson.featureCollection([
      GeoJson.pointFeature([116.4074, 39.9042], props)
    ]);
    
    const source = new GeoJsonSource('zoom-source');
    source.setGeoJson(geojson);
    this.mapController.getStyle()?.addSource(source);
    
    const layer = new SymbolLayer('zoom-layer', 'zoom-source');
    layer.setTextField(['get', 'title']);
    layer.setTextSize(14);
    layer.setTextColor('#2196F3');
    layer.setTextHaloColor('#FFFFFF');
    layer.setTextHaloWidth(2);
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
    // 移除内层 Scroll，TestPageLayout 已经提供了外层 Scroll
    Column({ space: 8 }) {
      Text('缩放控制')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
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
      const layer = this.mapController.getLayer('zoom-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      const colors: string[] = ['#2196F3', '#FF9800', '#4CAF50', '#F44336', '#9C27B0', '#000000'];
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
      const layer = this.mapController.getLayer('zoom-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      const size = 10 + Math.random() * 20; // 10-30
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
      const layer = this.mapController.getLayer('zoom-layer');
      
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
      const layer = this.mapController.getLayer('zoom-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      const width = Math.random() * 5; // 0-5
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
      const layer = this.mapController.getLayer('zoom-layer');
      
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
    
    this.currentZoom = 10;
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 5);
    showToast('视图已重置');
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


