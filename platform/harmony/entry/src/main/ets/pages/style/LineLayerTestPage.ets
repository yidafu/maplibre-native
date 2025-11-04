/**
 * Line Layer Test Page
 * 线条图层测试
 * 参考 Android Line Layer 相关测试
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { GeoJson, GeoJsonSource, LineLayer, MapLibreMap, MapView } from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import type { JsonObject } from '../../types/EntryTypes';

@Entry
@Component
struct LineLayerTestPage {
  private mapController: MapLibreMap | null = null;
  @State private currentStyleIndex: number = 0;
  @State private layerVisible: boolean = true;
  @State private translateAnchor: string = 'map'; // 'map' or 'viewport'
  @State private lineCap: string = 'butt'; // 'butt', 'round', 'square'
  @State private lineJoin: string = 'miter'; // 'bevel', 'round', 'miter'
  private readonly STYLES = [DEFAULT_STYLE_URLS.streets, DEFAULT_STYLE_URLS.bright];
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Line Layer',
        description: '线条图层样式',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        actionButtons: (): void => this.buildActionButtons()
      })
    }
    .width('100%')

    .height('100%')
  }

  @Builder
  buildMapContent() {
    MapView({
      styleUrl: DEFAULT_STYLE_URLS.streets,
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 5,
      onMapReady: (map: MapLibreMap) => {
        this.mapController = map;
        map.jumpTo(0, 35, 105, 0, 5);
        this.addLineLayer(map);
      }
    })
  }

  private addLineLayer(map: MapLibreMap): void {
    try {
      const geojson = GeoJson.featureCollection([
        GeoJson.lineStringFeature([
            [116.4, 39.9],
            [115, 38],
            [113, 36],
            [121.5, 31.2]
          ])
      ]);
      
      const source = new GeoJsonSource('line-source');
      source.setGeoJson(geojson);
      map.addSource(source);
      
      const layer = new LineLayer('line-layer', 'line-source');
      layer.setLineColor('#2196F3');
      layer.setLineWidth(5);
      layer.setLineOpacity(0.8);
      map.addLayer(layer);
    } catch (error) {
      console.error(`添加线条图层失败: ${error}`);
    }
  }
  
  @Builder
  buildActionButtons() {
    // 移除内层 Scroll，TestPageLayout 已经提供了外层 Scroll
    Column({ space: 8 }) {
      Text('基础操作')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('重新加载图层')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.reloadLayer())
        
        Button('切换样式')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeMapStyle())
      }
      
      Text('线条基础样式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('线条颜色')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeLineColor())
        
        Button('线条宽度')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeLineWidth())
      }
      
      Row({ space: 8 }) {
        Button('线条透明度')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeLineOpacity())
        
        Button('线条模糊度')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeLineBlur())
      }
      
      Text('虚线样式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('虚线模式')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeLineDasharray())
        
        Button('间隙宽度')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeLineGapWidth())
      }
      
      Text('端点和连接')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('端点样式')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeLineCap())
        
        Button('连接样式')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeLineJoin())
      }
      
      Row({ space: 8 }) {
        Button('斜接限制')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeLineMiterLimit())
        
        Button('圆角限制')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeLineRoundLimit())
      }
      
      Text('位置和偏移')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('线条偏移')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeLineOffset())
        
        Button('位置偏移')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeLineTranslate())
      }
      
      Row({ space: 8 }) {
        Button('切换偏移锚点')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.toggleTranslateAnchor())
        
        Button('排序键')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeLineSortKey())
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

  // 重新加载图层
  private reloadLayer(): void {
    if (!this.mapController) return;
    
    try {
      this.mapController.removeLayer('line-layer');
      this.mapController.removeSource('line-source');
      this.addLineLayer(this.mapController);
      showToast('图层已重新加载');
    } catch (error) {
      showToast(`重新加载失败: ${error}`);
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
      
      setTimeout(() => {
        if (this.mapController) {
          this.addLineLayer(this.mapController);
        }
      }, 1000);
    } catch (error) {
      showToast(`切换样式失败: ${error}`);
    }
  }

  // 改变线条颜色
  private changeLineColor(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('line-layer');
      
      if (!layer || !(layer instanceof LineLayer)) {
        showToast('未找到线条图层');
        return;
      }
      
      const colors: string[] = ['#2196F3', '#FF9800', '#4CAF50', '#F44336', '#9C27B0', '#00BCD4'];
      const randomColor: string = colors[Math.floor(Math.random() * colors.length)];
      
      layer.setLineColor(randomColor);
      showToast(`颜色: ${randomColor}`);
    } catch (error) {
      showToast(`更改颜色失败: ${error}`);
    }
  }

  // 改变线条宽度
  private changeLineWidth(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('line-layer');
      
      if (!layer || !(layer instanceof LineLayer)) {
        showToast('未找到线条图层');
        return;
      }
      
      const width = 2 + Math.random() * 10; // 2-12
      layer.setLineWidth(width);
      showToast(`宽度: ${width.toFixed(1)}`);
    } catch (error) {
      showToast(`更改宽度失败: ${error}`);
    }
  }

  // 改变线条透明度
  private changeLineOpacity(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('line-layer');
      
      if (!layer || !(layer instanceof LineLayer)) {
        showToast('未找到线条图层');
        return;
      }
      
      const opacity = 0.3 + Math.random() * 0.7; // 0.3-1.0
      layer.setLineOpacity(opacity);
      showToast(`透明度: ${opacity.toFixed(2)}`);
    } catch (error) {
      showToast(`更改透明度失败: ${error}`);
    }
  }

  // 改变线条模糊度
  private changeLineBlur(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('line-layer');
      
      if (!layer || !(layer instanceof LineLayer)) {
        showToast('未找到线条图层');
        return;
      }
      
      const blur = Math.random() * 3; // 0-3
      layer.setLineBlur(blur);
      showToast(`模糊度: ${blur.toFixed(2)}`);
    } catch (error) {
      showToast(`更改模糊度失败: ${error}`);
    }
  }

  // 改变虚线模式
  private changeLineDasharray(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('line-layer');
      
      if (!layer || !(layer instanceof LineLayer)) {
        showToast('未找到线条图层');
        return;
      }
      
      const patterns: number[][] = [
        [],              // 实线
        [2, 2],          // 短虚线
        [5, 5],          // 中虚线
        [10, 5],         // 长虚线
        [1, 3],          // 点线
        [5, 5, 1, 5],    // 点划线
        [10, 5, 2, 5]    // 长划线
      ];
      const pattern = patterns[Math.floor(Math.random() * patterns.length)];
      
      layer.setLineDasharray(pattern);
      const desc = pattern.length === 0 ? '实线' : `[${pattern.join(', ')}]`;
      showToast(`虚线: ${desc}`);
    } catch (error) {
      showToast(`更改虚线失败: ${error}`);
    }
  }

  // 改变间隙宽度
  private changeLineGapWidth(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('line-layer');
      
      if (!layer || !(layer instanceof LineLayer)) {
        showToast('未找到线条图层');
        return;
      }
      
      const gapWidth = Math.random() * 5; // 0-5
      layer.setLineGapWidth(gapWidth);
      showToast(`间隙宽度: ${gapWidth.toFixed(1)}`);
    } catch (error) {
      showToast(`更改间隙宽度失败: ${error}`);
    }
  }

  // 改变端点样式
  private changeLineCap(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('line-layer');
      
      if (!layer || !(layer instanceof LineLayer)) {
        showToast('未找到线条图层');
        return;
      }
      
      const caps: string[] = ['butt', 'round', 'square'];
      const currentIndex = caps.indexOf(this.lineCap);
      this.lineCap = caps[(currentIndex + 1) % caps.length];
      
      layer.setLineCap(this.lineCap);
      const capNames: Record<string, string> = { 'butt': '平头', 'round': '圆头', 'square': '方头' };
      showToast(`端点: ${capNames[this.lineCap]}`);
    } catch (error) {
      showToast(`更改端点失败: ${error}`);
    }
  }

  // 改变连接样式
  private changeLineJoin(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('line-layer');
      
      if (!layer || !(layer instanceof LineLayer)) {
        showToast('未找到线条图层');
        return;
      }
      
      const joins: string[] = ['bevel', 'round', 'miter'];
      const currentIndex = joins.indexOf(this.lineJoin);
      this.lineJoin = joins[(currentIndex + 1) % joins.length];
      
      layer.setLineJoin(this.lineJoin);
      const joinNames: Record<string, string> = { 'bevel': '斜角', 'round': '圆角', 'miter': '尖角' };
      showToast(`连接: ${joinNames[this.lineJoin]}`);
    } catch (error) {
      showToast(`更改连接失败: ${error}`);
    }
  }

  // 改变斜接限制
  private changeLineMiterLimit(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('line-layer');
      
      if (!layer || !(layer instanceof LineLayer)) {
        showToast('未找到线条图层');
        return;
      }
      
      const limit = 1 + Math.random() * 3; // 1-4
      layer.setLineMiterLimit(limit);
      showToast(`斜接限制: ${limit.toFixed(2)}`);
    } catch (error) {
      showToast(`更改斜接限制失败: ${error}`);
    }
  }

  // 改变圆角限制
  private changeLineRoundLimit(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('line-layer');
      
      if (!layer || !(layer instanceof LineLayer)) {
        showToast('未找到线条图层');
        return;
      }
      
      const limit = 0.5 + Math.random() * 2; // 0.5-2.5
      layer.setLineRoundLimit(limit);
      showToast(`圆角限制: ${limit.toFixed(2)}`);
    } catch (error) {
      showToast(`更改圆角限制失败: ${error}`);
    }
  }

  // 改变线条偏移
  private changeLineOffset(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('line-layer');
      
      if (!layer || !(layer instanceof LineLayer)) {
        showToast('未找到线条图层');
        return;
      }
      
      const offset = Math.random() * 10 - 5; // -5 到 5
      layer.setLineOffset(offset);
      showToast(`线条偏移: ${offset.toFixed(1)}`);
    } catch (error) {
      showToast(`更改线条偏移失败: ${error}`);
    }
  }

  // 改变位置偏移
  private changeLineTranslate(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('line-layer');
      
      if (!layer || !(layer instanceof LineLayer)) {
        showToast('未找到线条图层');
        return;
      }
      
      const x = Math.random() * 100 - 50; // -50 到 50
      const y = Math.random() * 100 - 50;
      layer.setLineTranslate([x, y]);
      showToast(`位置偏移: [${x.toFixed(1)}, ${y.toFixed(1)}]`);
    } catch (error) {
      showToast(`更改位置偏移失败: ${error}`);
    }
  }

  // 切换偏移锚点
  private toggleTranslateAnchor(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('line-layer');
      
      if (!layer || !(layer instanceof LineLayer)) {
        showToast('未找到线条图层');
        return;
      }
      
      this.translateAnchor = this.translateAnchor === 'map' ? 'viewport' : 'map';
      layer.setLineTranslateAnchor(this.translateAnchor);
      showToast(`偏移锚点: ${this.translateAnchor === 'map' ? '地图' : '视口'}`);
    } catch (error) {
      showToast(`切换偏移锚点失败: ${error}`);
    }
  }

  // 改变排序键
  private changeLineSortKey(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('line-layer');
      
      if (!layer || !(layer instanceof LineLayer)) {
        showToast('未找到线条图层');
        return;
      }
      
      const sortKey = Math.floor(Math.random() * 100);
      layer.setLineSortKey(sortKey);
      showToast(`排序键: ${sortKey}`);
    } catch (error) {
      showToast(`更改排序键失败: ${error}`);
    }
  }

  // 切换显示/隐藏
  private toggleVisibility(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('line-layer');
      
      if (!layer || !(layer instanceof LineLayer)) {
        showToast('未找到线条图层');
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
    
    this.mapController.jumpTo(0, 35, 105, 0, 5);
    showToast('视图已重置');
  }
}

