import { BackgroundLayer, MapLibreMap, MapView } from 'maplibre_harmony';
/**
 * Background Layer Test Page
 * 背景图层测试
 * 参考 Android BackgroundLayer 测试
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct BackgroundLayerTestPage {
  private mapController: MapLibreMap | null = null;
  @State private currentStyleIndex: number = 0;
  private readonly STYLES = [DEFAULT_STYLE_URLS.streets, DEFAULT_STYLE_URLS.bright];
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Background Layer',
        description: '背景图层颜色',
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
        map.jumpTo(0, 0, 0, 0, 2);
      }
    })
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
        Button('重置图层')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.resetLayer())
        
        Button('切换样式')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeMapStyle())
      }
      
      Text('背景样式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('背景颜色')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeBackgroundColor())
        
        Button('背景透明度')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeBackgroundOpacity())
      }
      
      Text('显示模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Button('重置视图')
        .fontSize(14)
        .width('100%')
        .onClick(() => this.resetView())
    }
    .width('100%')
  }

  // 重置图层
  private resetLayer(): void {
    if (!this.mapController) return;
    
    try {
      const layers = this.mapController.getLayers();
      for (const layer of layers) {
        if (layer instanceof BackgroundLayer) {
          layer.setBackgroundColor('#F2F2F2');
          layer.setBackgroundOpacity(1.0);
          showToast('背景图层已重置');
          return;
        }
      }
      showToast('未找到背景图层');
    } catch (error) {
      showToast(`重置失败: ${error}`);
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
    } catch (error) {
      showToast(`切换样式失败: ${error}`);
    }
  }

  // 改变背景颜色
  private changeBackgroundColor(): void {
    if (!this.mapController) return;
    
    try {
      const layers = this.mapController.getLayers();
      for (const layer of layers) {
        if (layer instanceof BackgroundLayer) {
          const colors: string[] = ['#2196F3', '#FF9800', '#4CAF50', '#F44336', '#9C27B0', '#212121'];
          const randomColor: string = colors[Math.floor(Math.random() * colors.length)];
          
          layer.setBackgroundColor(randomColor);
          showToast(`背景颜色: ${randomColor}`);
          return;
        }
      }
      showToast('未找到背景图层');
    } catch (error) {
      showToast(`更改颜色失败: ${error}`);
    }
  }

  // 改变背景透明度
  private changeBackgroundOpacity(): void {
    if (!this.mapController) return;
    
    try {
      const layers = this.mapController.getLayers();
      for (const layer of layers) {
        if (layer instanceof BackgroundLayer) {
          const opacity = 0.3 + Math.random() * 0.7; // 0.3-1.0
          
          layer.setBackgroundOpacity(opacity);
          showToast(`背景透明度: ${opacity.toFixed(2)}`);
          return;
        }
      }
      showToast('未找到背景图层');
    } catch (error) {
      showToast(`更改透明度失败: ${error}`);
    }
  }

  // 重置视图
  private resetView(): void {
    if (!this.mapController) return;
    
    this.mapController.jumpTo(0, 0, 0, 0, 2);
    showToast('视图已重置');
  }
}

