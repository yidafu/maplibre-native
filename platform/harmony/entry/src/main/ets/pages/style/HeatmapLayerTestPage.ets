/**
 * Heatmap Layer Test Page
 * 热力图图层测试
 * 参考 Android: HeatmapLayerActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { GeoJsonSource, HeatmapLayer, LatLng, MapLibreMap, MapView, ScreenPoint, GeoJson, IFeature } from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, showToast, randomLatLng , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct HeatmapLayerTestPage {
  private mapController: MapLibreMap | null = null;
  @State private currentStyleIndex: number = 0;
  @State private layerVisible: boolean = true;
  private readonly STYLES = [DEFAULT_STYLE_URLS.streets, DEFAULT_STYLE_URLS.bright];
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Heatmap Layer',
        description: '热力图可视化',
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
        map.jumpTo(0, 35, 105, 0, 4);
        this.addHeatmapLayer(map);
      }
    })
  }

  private addHeatmapLayer(map: MapLibreMap): void {
    try {
      // 生成密集点数据（模拟地震数据）
      const features: IFeature[] = [];
      for (let i = 0; i < 500; i++) {
        const latLng = randomLatLng(18, 54, 73, 135);
        const props: Record<string, Object> = {
          'magnitude': Math.random() * 10
        };
        features.push(GeoJson.pointFeature(
          [latLng.longitude, latLng.latitude],
          props
        ));
      }
      
      const source = new GeoJsonSource('heatmap-source');
      source.setGeoJson(GeoJson.featureCollection(features));
      map.addSource(source);
      
      const layer = new HeatmapLayer('heatmap-layer', 'heatmap-source');
      layer.setHeatmapRadius(20);
      layer.setHeatmapOpacity(0.8);
      map.addLayer(layer);
      
      showToast('热力图已添加');
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
      
      Text('热力参数')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('热力半径')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeHeatmapRadius())
        
        Button('热力权重')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeHeatmapWeight())
      }
      
      Row({ space: 8 }) {
        Button('热力强度')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeHeatmapIntensity())
        
        Button('热力透明度')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeHeatmapOpacity())
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
      this.mapController.removeLayer('heatmap-layer');
      this.mapController.removeSource('heatmap-source');
      this.addHeatmapLayer(this.mapController);
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
          this.addHeatmapLayer(this.mapController);
        }
      }, 1000);
    } catch (error) {
      showToast(`切换样式失败: ${error}`);
    }
  }

  // 改变热力半径
  private changeHeatmapRadius(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('heatmap-layer');
      
      if (!layer || !(layer instanceof HeatmapLayer)) {
        showToast('未找到热力图图层');
        return;
      }
      
      const radius = 10 + Math.random() * 40; // 10-50
      layer.setHeatmapRadius(radius);
      showToast(`热力半径: ${radius.toFixed(1)}`);
    } catch (error) {
      showToast(`更改半径失败: ${error}`);
    }
  }

  // 改变热力权重
  private changeHeatmapWeight(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('heatmap-layer');
      
      if (!layer || !(layer instanceof HeatmapLayer)) {
        showToast('未找到热力图图层');
        return;
      }
      
      const weight = 0.5 + Math.random() * 1.5; // 0.5-2.0
      layer.setHeatmapWeight(weight);
      showToast(`热力权重: ${weight.toFixed(2)}`);
    } catch (error) {
      showToast(`更改权重失败: ${error}`);
    }
  }

  // 改变热力强度
  private changeHeatmapIntensity(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('heatmap-layer');
      
      if (!layer || !(layer instanceof HeatmapLayer)) {
        showToast('未找到热力图图层');
        return;
      }
      
      const intensity = 0.5 + Math.random() * 1.5; // 0.5-2.0
      layer.setHeatmapIntensity(intensity);
      showToast(`热力强度: ${intensity.toFixed(2)}`);
    } catch (error) {
      showToast(`更改强度失败: ${error}`);
    }
  }

  // 改变热力透明度
  private changeHeatmapOpacity(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('heatmap-layer');
      
      if (!layer || !(layer instanceof HeatmapLayer)) {
        showToast('未找到热力图图层');
        return;
      }
      
      const opacity = 0.3 + Math.random() * 0.7; // 0.3-1.0
      layer.setHeatmapOpacity(opacity);
      showToast(`热力透明度: ${opacity.toFixed(2)}`);
    } catch (error) {
      showToast(`更改透明度失败: ${error}`);
    }
  }

  // 切换显示/隐藏
  private toggleVisibility(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('heatmap-layer');
      
      if (!layer || !(layer instanceof HeatmapLayer)) {
        showToast('未找到热力图图层');
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
    
    this.mapController.jumpTo(0, 35, 105, 0, 4);
    showToast('视图已重置');
  }
}

