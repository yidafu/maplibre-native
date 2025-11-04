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
  @State private currentStyleIndex: number = 0;
  @State private currentTextSize: number = 24;
  @State private currentTextColor: string = '#F44336';
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
    // this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 5);
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
    layer.setTextField(['get', 'symbol']);
    layer.setTextSize(this.currentTextSize);
    layer.setTextColor(this.currentTextColor);
    layer.setTextAllowOverlap(true);
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

  // 改变符号文本颜色（用于下次生成）
  private changeSymbolTextColor(): void {
    const colors: string[] = ['#F44336', '#4CAF50', '#2196F3', '#FF9800', '#9C27B0', '#000000'];
    this.currentTextColor = colors[Math.floor(Math.random() * colors.length)];
    showToast(`下次符号颜色: ${this.currentTextColor}`);
  }

  // 改变符号文本大小（用于下次生成）
  private changeSymbolTextSize(): void {
    this.currentTextSize = 16 + Math.random() * 24; // 16-40
    showToast(`下次符号大小: ${this.currentTextSize.toFixed(1)}`);
  }

  // 应用样式到所有现有符号
  private applyStyleToAll(): void {
    if (!this.mapController || this.symbolCount === 0) {
      showToast('没有符号可应用样式');
      return;
    }
    
    try {
      for (let i = 0; i < this.symbolCount; i++) {
        const layer = this.mapController.getLayer(`symbol-layer-${i}`);
        if (layer && layer instanceof SymbolLayer) {
          layer.setTextSize(this.currentTextSize);
          layer.setTextColor(this.currentTextColor);
        }
      }
      showToast(`已应用样式到 ${this.symbolCount} 个符号`);
    } catch (error) {
      showToast(`应用样式失败: ${error}`);
    }
  }

  // 切换地图样式
  private changeMapStyle(): void {
    if (!this.mapController) return;
    
    try {
      this.currentStyleIndex = (this.currentStyleIndex + 1) % this.STYLES.length;
      const newStyleUrl = this.STYLES[this.currentStyleIndex];
      
      this.mapController.setStyleUrl(newStyleUrl);
      showToast(`正在切换到样式 ${this.currentStyleIndex + 1}`);
      
      // 样式切换会清除所有图层
      this.symbolCount = 0;
    } catch (error) {
      showToast(`切换样式失败: ${error}`);
    }
  }

  // 重置视图
  private resetView(): void {
    if (!this.mapController) return;
    
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 5);
    showToast('视图已重置');
  }
  
  @Builder
  buildMapContent() {
    MapView({
      onMapReady: this.onMapReady,
            styleUrl: DEFAULT_STYLE_URLS.bright,
            initialLatitude: 39.9,
            initialLongitude: 116.4,
            initialZoom: 5
    })
  }
  
  @Builder
  buildActionButtons() {
    // 移除内层 Scroll，TestPageLayout 已经提供了外层 Scroll
    Column({ space: 8 }) {
      Text('符号生成器')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Text(`符号数量: ${this.symbolCount}`)
        .fontSize(14)
        .fontColor('#666')
        .width('100%')
      
      Row({ space: 8 }) {
        Button('添加随机符号')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.addRandomSymbol())
        
        Button('清除所有符号')
          .fontSize(14)
          .layoutWeight(1)
          .backgroundColor('#F44336')
          .enabled(this.symbolCount > 0)
          .onClick(() => this.clearSymbols())
      }
      
      Text('符号样式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('文本颜色')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeSymbolTextColor())
        
        Button('文本大小')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeSymbolTextSize())
      }
      
      Button('应用样式到所有符号')
        .fontSize(14)
        .width('100%')
        .onClick(() => this.applyStyleToAll())
      
      Text('基础操作')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('切换样式')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeMapStyle())
        
        Button('重置视图')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.resetView())
      }
    }
    .width('100%')
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Symbol Generator',
        description: '符号生成器',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        actionButtons: (): void => this.buildActionButtons()
      })
    }
    .width('100%')
    .height('100%')
  }
}


