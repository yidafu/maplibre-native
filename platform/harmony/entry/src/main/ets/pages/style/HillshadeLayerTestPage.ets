import { HillshadeLayer, MapLibreMap, MapView, RasterDemSource } from 'maplibre_harmony';
/**
 * Hillshade Layer Test Page
 * 山体阴影图层测试
 * 参考 Android: HillshadeLayerActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct HillshadeLayerTestPage {
  private mapController: MapLibreMap | null = null;
  @State private currentStyleIndex: number = 0;
  @State private layerVisible: boolean = true;
  private readonly STYLES = [DEFAULT_STYLE_URLS.streets, DEFAULT_STYLE_URLS.bright];

  build() {
    Column() {
      TestPageLayout({
        title: 'Hillshade Layer',
        description: '山体阴影效果',
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
        map.jumpTo(0, 30, 105, 0, 8);
        this.addHillshadeLayer(map);
      }
    })
  }

  private addHillshadeLayer(map: MapLibreMap): void {
    try {
      const source = new RasterDemSource('hillshade-source');
      source.setUrl('https://demotiles.maplibre.org/terrain-tiles/{z}/{x}/{y}.png');
      source.setTileSize(256);
      map.addSource(source);

      const layer = new HillshadeLayer('hillshade-layer', 'hillshade-source');
      layer.setHillshadeExaggeration(0.5);
      layer.setHillshadeIlluminationDirection(45);
      map.addLayer(layer);

      showToast('山体阴影已添加');
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
      
      Text('阴影效果')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('光照方向')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeIlluminationDirection())
        
        Button('夸张系数')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeExaggeration())
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
      this.mapController.removeLayer('hillshade-layer');
      this.mapController.removeSource('hillshade-source');
      this.addHillshadeLayer(this.mapController);
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
          this.addHillshadeLayer(this.mapController);
        }
      }, 1000);
    } catch (error) {
      showToast(`切换样式失败: ${error}`);
    }
  }

  // 改变光照方向
  private changeIlluminationDirection(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('hillshade-layer');
      
      if (!layer || !(layer instanceof HillshadeLayer)) {
        showToast('未找到山体阴影图层');
        return;
      }
      
      const direction = Math.random() * 360; // 0-360 degrees
      layer.setHillshadeIlluminationDirection(direction);
      showToast(`光照方向: ${direction.toFixed(0)}°`);
    } catch (error) {
      showToast(`更改光照方向失败: ${error}`);
    }
  }

  // 改变夸张系数
  private changeExaggeration(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('hillshade-layer');
      
      if (!layer || !(layer instanceof HillshadeLayer)) {
        showToast('未找到山体阴影图层');
        return;
      }
      
      const exaggeration = 0.2 + Math.random() * 0.8; // 0.2-1.0
      layer.setHillshadeExaggeration(exaggeration);
      showToast(`夸张系数: ${exaggeration.toFixed(2)}`);
    } catch (error) {
      showToast(`更改夸张系数失败: ${error}`);
    }
  }

  // 切换显示/隐藏
  private toggleVisibility(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('hillshade-layer');
      
      if (!layer || !(layer instanceof HillshadeLayer)) {
        showToast('未找到山体阴影图层');
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
    
    this.mapController.jumpTo(0, 30, 105, 0, 8);
    showToast('视图已重置');
  }
}