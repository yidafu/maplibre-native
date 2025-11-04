/**
 * Fill Extrusion Test Page
 * 3D 拉伸图层测试
 * 参考 Android: FillExtrusionActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { FillExtrusionLayer, GeoJson, GeoJsonSource, MapLibreMap, MapView } from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import type { JsonObject } from '../../types/EntryTypes';

@Entry
@Component
struct FillExtrusionTestPage {
  private mapController: MapLibreMap | null = null;
  @State private currentStyleIndex: number = 0;
  @State private layerVisible: boolean = true;
  @State private translateAnchor: string = 'map'; // 'map' or 'viewport'
  private readonly STYLES = [DEFAULT_STYLE_URLS.streets, DEFAULT_STYLE_URLS.bright];

  build() {
    Column() {
      TestPageLayout({
        title: 'Fill Extrusion',
        description: '3D 建筑拉伸效果',
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
        map.jumpTo(0, 39.9, 116.4, 45, 16);
        this.addExtrusionLayer(map);
      }
    })
  }

  private addExtrusionLayer(map: MapLibreMap): void {
    try {
      const props1: Record<string, Object> = { 'height': 100 };
      const props2: Record<string, Object> = { 'height': 150 };
      const geojson = GeoJson.featureCollection([
        GeoJson.polygonFeature([[
          [116.39, 39.89],
          [116.40, 39.89],
          [116.40, 39.90],
          [116.39, 39.90],
          [116.39, 39.89]
        ]], props1),
        GeoJson.polygonFeature([[
          [116.40, 39.90],
          [116.41, 39.90],
          [116.41, 39.91],
          [116.40, 39.91],
          [116.40, 39.90]
        ]], props2)
      ]);

      const source = new GeoJsonSource('extrusion-source');
      source.setGeoJson(geojson);
      map.addSource(source);

      const layer = new FillExtrusionLayer('extrusion-layer', 'extrusion-source');
      layer.setFillExtrusionColor('#2196F3');
      layer.setFillExtrusionOpacity(0.8);
      layer.setFillExtrusionHeight(['get', 'height']);
      layer.setFillExtrusionBase(0);
      map.addLayer(layer);

      showToast('3D 拉伸图层已添加');
    } catch (error) {
      showToast(`添加失败: ${error}`);
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
      
      Text('拉伸基础样式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('拉伸颜色')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeExtrusionColor())
        
        Button('拉伸透明度')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeExtrusionOpacity())
      }
      
      Text('高度控制')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('拉伸高度')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeExtrusionHeight())
        
        Button('基础高度')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeExtrusionBase())
      }
      
      Text('偏移控制')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('位置偏移')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeExtrusionTranslate())
        
        Button('切换偏移锚点')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.toggleTranslateAnchor())
      }
      
      Text('视图控制')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('调整俯仰角')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.togglePitch())
        
        Button('显示/隐藏')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.toggleVisibility())
      }
      
      Button('重置视图')
        .fontSize(14)
        .width('100%')
        .onClick(() => this.resetView())
    }
    .width('100%')
  }

  // 重新加载图层
  private reloadLayer(): void {
    if (!this.mapController) return;
    
    try {
      this.mapController.removeLayer('extrusion-layer');
      this.mapController.removeSource('extrusion-source');
      this.addExtrusionLayer(this.mapController);
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
          this.addExtrusionLayer(this.mapController);
        }
      }, 1000);
    } catch (error) {
      showToast(`切换样式失败: ${error}`);
    }
  }

  // 改变拉伸颜色
  private changeExtrusionColor(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('extrusion-layer');
      
      if (!layer || !(layer instanceof FillExtrusionLayer)) {
        showToast('未找到拉伸图层');
        return;
      }
      
      const colors: string[] = ['#2196F3', '#FF9800', '#4CAF50', '#F44336', '#9C27B0', '#00BCD4'];
      const randomColor: string = colors[Math.floor(Math.random() * colors.length)];
      
      layer.setFillExtrusionColor(randomColor);
      showToast(`拉伸颜色: ${randomColor}`);
    } catch (error) {
      showToast(`更改颜色失败: ${error}`);
    }
  }

  // 改变拉伸透明度
  private changeExtrusionOpacity(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('extrusion-layer');
      
      if (!layer || !(layer instanceof FillExtrusionLayer)) {
        showToast('未找到拉伸图层');
        return;
      }
      
      const opacity = 0.3 + Math.random() * 0.7; // 0.3-1.0
      layer.setFillExtrusionOpacity(opacity);
      showToast(`拉伸透明度: ${opacity.toFixed(2)}`);
    } catch (error) {
      showToast(`更改透明度失败: ${error}`);
    }
  }

  // 改变拉伸高度
  private changeExtrusionHeight(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('extrusion-layer');
      
      if (!layer || !(layer instanceof FillExtrusionLayer)) {
        showToast('未找到拉伸图层');
        return;
      }
      
      const height = 50 + Math.random() * 200; // 50-250
      layer.setFillExtrusionHeight(height);
      showToast(`拉伸高度: ${height.toFixed(0)}`);
    } catch (error) {
      showToast(`更改高度失败: ${error}`);
    }
  }

  // 改变基础高度
  private changeExtrusionBase(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('extrusion-layer');
      
      if (!layer || !(layer instanceof FillExtrusionLayer)) {
        showToast('未找到拉伸图层');
        return;
      }
      
      const base = Math.random() * 50; // 0-50
      layer.setFillExtrusionBase(base);
      showToast(`基础高度: ${base.toFixed(0)}`);
    } catch (error) {
      showToast(`更改基础高度失败: ${error}`);
    }
  }

  // 改变拉伸偏移
  private changeExtrusionTranslate(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('extrusion-layer');
      
      if (!layer || !(layer instanceof FillExtrusionLayer)) {
        showToast('未找到拉伸图层');
        return;
      }
      
      const x = Math.random() * 100 - 50; // -50 到 50
      const y = Math.random() * 100 - 50;
      layer.setFillExtrusionTranslate([x, y]);
      showToast(`位置偏移: [${x.toFixed(1)}, ${y.toFixed(1)}]`);
    } catch (error) {
      showToast(`更改偏移失败: ${error}`);
    }
  }

  // 切换偏移锚点
  private toggleTranslateAnchor(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('extrusion-layer');
      
      if (!layer || !(layer instanceof FillExtrusionLayer)) {
        showToast('未找到拉伸图层');
        return;
      }
      
      this.translateAnchor = this.translateAnchor === 'map' ? 'viewport' : 'map';
      layer.setFillExtrusionTranslateAnchor(this.translateAnchor);
      showToast(`偏移锚点: ${this.translateAnchor === 'map' ? '地图' : '视口'}`);
    } catch (error) {
      showToast(`切换偏移锚点失败: ${error}`);
    }
  }

  // 调整俯仰角
  private togglePitch(): void {
    if (!this.mapController) return;
    
    const pitch = this.mapController.getPitch();
    this.mapController.setPitch(pitch < 45 ? 60 : 30, 500);
    showToast(`俯仰角: ${pitch < 45 ? '60°' : '30°'}`);
  }

  // 切换显示/隐藏
  private toggleVisibility(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('extrusion-layer');
      
      if (!layer || !(layer instanceof FillExtrusionLayer)) {
        showToast('未找到拉伸图层');
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
    
    this.mapController.jumpTo(0, 39.9, 116.4, 45, 16);
    showToast('视图已重置');
  }
}