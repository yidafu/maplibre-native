/**
 * Fill Layer Test Page
 * 填充图层测试
 * 参考 Android Fill Layer 相关测试
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { FillLayer, GeoJson, GeoJsonSource, MapLibreMap, MapView } from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import type { JsonObject } from '../../types/EntryTypes';

@Entry
@Component
struct FillLayerTestPage {
  private mapController: MapLibreMap | null = null;
  @State private currentStyleIndex: number = 0;
  @State private antialiasEnabled: boolean = true;
  @State private layerVisible: boolean = true;
  @State private translateAnchor: string = 'map'; // 'map' or 'viewport'
  private readonly STYLES = [DEFAULT_STYLE_URLS.streets, DEFAULT_STYLE_URLS.bright];
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Fill Layer',
        description: '填充图层样式',
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
      styleUrl: DEFAULT_STYLE_URLS.bright,
      onMapReady: (map: MapLibreMap) => {
        this.mapController = map;
        map.jumpTo(0, 39.9, 116.4, 0, 10);
        this.addFillLayer(map);
      },
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 10
    })
  }

  private addFillLayer(map: MapLibreMap): void {
    try {
      const geojson = GeoJson.featureCollection([
        GeoJson.polygonFeature([[
            [116.3, 39.8],
            [116.5, 39.8],
            [116.5, 40.0],
            [116.3, 40.0],
            [116.3, 39.8]
          ]])
      ]);
      
      const source = new GeoJsonSource('fill-source');
      source.setGeoJson(geojson);
      map.addSource(source);
      
      const layer = new FillLayer('fill-layer', 'fill-source');
      layer.setFillColor('#33B5E5');
      layer.setFillOpacity(0.6);
      layer.setFillOutlineColor('#2196F3');
      map.addLayer(layer);
    } catch (error) {
      console.error(`添加填充图层失败: ${error}`);
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
      
      Text('填充样式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('填充颜色')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeFillColor())
        
        Button('填充透明度')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeFillOpacity())
      }
      
      Text('轮廓样式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('轮廓颜色')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeOutlineColor())
        
        Button('切换抗锯齿')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.toggleAntialias())
      }
      
      Text('高级样式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('偏移位置')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeFillTranslate())
        
        Button('切换偏移锚点')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.toggleTranslateAnchor())
      }
      
      Button('改变排序键')
        .fontSize(14)
        .width('100%')
        .onClick(() => this.changeSortKey())
      
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
      // 移除旧图层和数据源
      this.mapController.removeLayer('fill-layer');
      this.mapController.removeSource('fill-source');
      
      // 重新添加
      this.addFillLayer(this.mapController);
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
      
      // 样式加载完成后重新加载图层
      setTimeout(() => {
        if (this.mapController) {
          this.addFillLayer(this.mapController);
        }
      }, 1000);
    } catch (error) {
      showToast(`切换样式失败: ${error}`);
    }
  }

  // 改变填充颜色
  private changeFillColor(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('fill-layer');
      
      if (!layer) {
        showToast('未找到填充图层');
        return;
      }
      
      if (!(layer instanceof FillLayer)) {
        showToast('图层不是填充图层类型');
        return;
      }
      
      const fillLayer = layer;
      const colors: string[] = ['#2196F3', '#FF9800', '#4CAF50', '#F44336', '#9C27B0', '#33B5E5'];
      const randomColor: string = colors[Math.floor(Math.random() * colors.length)];
      
      fillLayer.setFillColor(randomColor);
      showToast(`填充颜色: ${randomColor}`);
    } catch (error) {
      showToast(`更改颜色失败: ${error}`);
    }
  }

  // 改变填充透明度
  private changeFillOpacity(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('fill-layer');
      
      if (!layer) {
        showToast('未找到填充图层');
        return;
      }
      
      if (!(layer instanceof FillLayer)) {
        showToast('图层不是填充图层类型');
        return;
      }
      
      const fillLayer = layer;
      const opacity = 0.2 + Math.random() * 0.8; // 0.2 - 1.0
      
      fillLayer.setFillOpacity(opacity);
      showToast(`填充透明度: ${opacity.toFixed(2)}`);
    } catch (error) {
      showToast(`更改透明度失败: ${error}`);
    }
  }

  // 改变轮廓颜色
  private changeOutlineColor(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('fill-layer');
      
      if (!layer) {
        showToast('未找到填充图层');
        return;
      }
      
      if (!(layer instanceof FillLayer)) {
        showToast('图层不是填充图层类型');
        return;
      }
      
      const fillLayer = layer;
      // 使用高对比度颜色，更容易看到变化
      const colors: string[] = ['#FF0000', '#00FF00', '#0000FF', '#FFFF00', '#FF00FF', '#00FFFF', '#FFFFFF', '#000000'];
      const randomColor: string = colors[Math.floor(Math.random() * colors.length)];
      
      console.info(`[FillLayerTestPage] 设置轮廓颜色: ${randomColor}`);
      
      // 关闭抗锯齿以确保轮廓可见
      fillLayer.setFillAntialias(false);
      this.antialiasEnabled = false;
      
      // 设置轮廓颜色
      fillLayer.setFillOutlineColor(randomColor);
      
      // 降低填充透明度，让轮廓更明显
      fillLayer.setFillOpacity(0.5);
      
      showToast(`轮廓: ${randomColor} (抗锯齿已关闭)`);
    } catch (error) {
      console.error(`[FillLayerTestPage] 更改轮廓颜色失败: ${error}`);
      showToast(`更改轮廓颜色失败: ${error}`);
    }
  }

  // 切换抗锯齿
  private toggleAntialias(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('fill-layer');
      
      if (!layer) {
        showToast('未找到填充图层');
        return;
      }
      
      if (!(layer instanceof FillLayer)) {
        showToast('图层不是填充图层类型');
        return;
      }
      
      const fillLayer = layer;
      this.antialiasEnabled = !this.antialiasEnabled;
      
      fillLayer.setFillAntialias(this.antialiasEnabled);
      showToast(`抗锯齿: ${this.antialiasEnabled ? '开启' : '关闭'}`);
    } catch (error) {
      showToast(`切换抗锯齿失败: ${error}`);
    }
  }

  // 切换显示/隐藏
  private toggleVisibility(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('fill-layer');
      
      if (!layer) {
        showToast('未找到填充图层');
        return;
      }
      
      if (!(layer instanceof FillLayer)) {
        showToast('图层不是填充图层类型');
        return;
      }
      
      const fillLayer = layer;
      this.layerVisible = !this.layerVisible;
      
      fillLayer.setVisibility(this.layerVisible ? 'visible' : 'none');
      showToast(`图层: ${this.layerVisible ? '显示' : '隐藏'}`);
    } catch (error) {
      showToast(`切换显示失败: ${error}`);
    }
  }

  // 重置视图
  private resetView(): void {
    if (!this.mapController) return;
    
    this.mapController.jumpTo(0, 39.9, 116.4, 0, 10);
    showToast('视图已重置');
  }

  // 改变填充偏移
  private changeFillTranslate(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('fill-layer');
      
      if (!layer) {
        showToast('未找到填充图层');
        return;
      }
      
      if (!(layer instanceof FillLayer)) {
        showToast('图层不是填充图层类型');
        return;
      }
      
      const fillLayer = layer;
      // 生成随机偏移量 (-50 到 50 像素)
      const x = Math.random() * 100 - 50;
      const y = Math.random() * 100 - 50;
      
      console.info(`[FillLayerTestPage] 设置偏移: [${x.toFixed(1)}, ${y.toFixed(1)}]`);
      fillLayer.setFillTranslate([x, y]);
      
      showToast(`偏移: [${x.toFixed(1)}, ${y.toFixed(1)}]`);
    } catch (error) {
      console.error(`[FillLayerTestPage] 更改偏移失败: ${error}`);
      showToast(`更改偏移失败: ${error}`);
    }
  }

  // 切换偏移锚点
  private toggleTranslateAnchor(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('fill-layer');
      
      if (!layer) {
        showToast('未找到填充图层');
        return;
      }
      
      if (!(layer instanceof FillLayer)) {
        showToast('图层不是填充图层类型');
        return;
      }
      
      const fillLayer = layer;
      // 切换锚点类型
      this.translateAnchor = this.translateAnchor === 'map' ? 'viewport' : 'map';
      
      console.info(`[FillLayerTestPage] 设置偏移锚点: ${this.translateAnchor}`);
      fillLayer.setFillTranslateAnchor(this.translateAnchor);
      
      showToast(`偏移锚点: ${this.translateAnchor === 'map' ? '地图' : '视口'}`);
    } catch (error) {
      console.error(`[FillLayerTestPage] 切换偏移锚点失败: ${error}`);
      showToast(`切换偏移锚点失败: ${error}`);
    }
  }

  // 改变排序键
  private changeSortKey(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('fill-layer');
      
      if (!layer) {
        showToast('未找到填充图层');
        return;
      }
      
      if (!(layer instanceof FillLayer)) {
        showToast('图层不是填充图层类型');
        return;
      }
      
      const fillLayer = layer;
      // 生成随机排序键 (0-100)
      const sortKey = Math.floor(Math.random() * 100);
      
      console.info(`[FillLayerTestPage] 设置排序键: ${sortKey}`);
      fillLayer.setFillSortKey(sortKey);
      
      showToast(`排序键: ${sortKey}`);
    } catch (error) {
      console.error(`[FillLayerTestPage] 更改排序键失败: ${error}`);
      showToast(`更改排序键失败: ${error}`);
    }
  }
}

