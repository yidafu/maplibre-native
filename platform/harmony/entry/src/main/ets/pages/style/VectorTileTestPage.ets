/**
 * Vector Tile Test Page
 * 矢量瓦片源测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/sources/VectorTileActivity.kt
 * 
 * 功能:
 * - 添加矢量瓦片数据源（Vector Source）
 * - 添加图层显示矢量数据
 * - 设置图层属性（颜色、宽度）
 * - 指定源图层（sourceLayer）
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapLibreMap, MapView, VectorSource, LineLayer } from 'maplibre_harmony';
import { showToast, DEFAULT_MAP_CONFIG, DEFAULT_STYLE_URLS } from '../common/TestUtils';

@Entry
@Component
struct VectorTileTestPage {
  private scroller: Scroller = new Scroller();
  private mapController: MapLibreMap | null = null;
  @State private layerAdded: boolean = false;
  @State private currentColor: string = '#FF0000';
  @State private currentWidth: number = 2.0;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[VectorTileTestPage] onMapReady');
    this.mapController = map;
    
    // 使用 Protomaps Grayscale 样式（从 Android 示例）
    map.setStyleUrl('https://api.maptiler.com/maps/bright/style.json?key=get_your_own_key');
    
    // 设置初始位置到演示瓦片区域
    // z: 12, x: 2177, y: 1436 是一个可用的瓦片
    // 对应的经纬度范围
    map.jumpTo(0, 40.7, -74.0, 0, 12);
    
    // 延迟添加矢量瓦片图层，等待样式加载完成
    setTimeout(() => {
      this.addVectorTileLayer();
    }, 1000);
  };
  
  /**
   * 添加矢量瓦片图层
   */
  private addVectorTileLayer = (): void => {
    if (!this.mapController) {
      showToast('地图未就绪');
      return;
    }
    
    try {
      // 检查数据源是否已存在
      const existingSource = this.mapController.getSource('openmaptiles');
      if (existingSource) {
        console.info('[VectorTileTestPage] Source already exists');
        // 如果数据源已存在，只添加图层
        this.addRoadLayer();
        return;
      }
      
      // 创建矢量瓦片数据源
      // 使用 OpenMapTiles 演示服务
      const vectorSource = new VectorSource('openmaptiles');
      vectorSource.setUrl('https://demotiles.maplibre.org/tiles-omt/{z}/{x}/{y}.pbf');
      
      // 可选：设置瓦片范围
      vectorSource.setMinZoom(0);
      vectorSource.setMaxZoom(14);
      
      // 添加数据源
      this.mapController.addSource(vectorSource);
      
      // 添加道路图层
      this.addRoadLayer();
      
      this.layerAdded = true;
      showToast('矢量瓦片图层已添加');
    } catch (error) {
      console.error(`添加矢量瓦片失败: ${error}`);
      showToast(`添加失败: ${error}`);
    }
  };
  
  /**
   * 添加道路图层
   */
  private addRoadLayer = (): void => {
    if (!this.mapController) return;
    
    try {
      // 移除旧图层（如果存在）
      const existingLayer = this.mapController.getLayer('road');
      if (existingLayer) {
        this.mapController.removeLayer('road');
      }
      
      // 创建线条图层显示道路
      const roadLayer = new LineLayer('road', 'openmaptiles');
      
      // 设置源图层（从矢量瓦片中选择 transportation 图层）
      roadLayer.setSourceLayer('transportation');
      
      // 设置样式
      roadLayer.setLineColor(this.currentColor);
      roadLayer.setLineWidth(this.currentWidth);
      
      // 可选：添加过滤器，只显示特定类型的道路
      // roadLayer.setFilter(['==', ['get', 'class'], 'primary']);
      
      // 添加图层
      this.mapController.addLayer(roadLayer);
      
      this.layerAdded = true;
    } catch (error) {
      console.error(`添加道路图层失败: ${error}`);
    }
  };
  
  /**
   * 移除矢量瓦片图层
   */
  private removeVectorTileLayer = (): void => {
    if (!this.mapController) return;
    
    try {
      // 移除图层
      const layer = this.mapController.getLayer('road');
      if (layer) {
        this.mapController.removeLayer('road');
      }
      
      // 移除数据源
      const source = this.mapController.getSource('openmaptiles');
      if (source) {
        this.mapController.removeSource('openmaptiles');
      }
      
      this.layerAdded = false;
      showToast('已移除矢量瓦片图层');
    } catch (error) {
      console.error(`移除图层失败: ${error}`);
      showToast(`移除失败: ${error}`);
    }
  };
  
  /**
   * 切换颜色
   */
  private toggleColor = (): void => {
    if (!this.mapController || !this.layerAdded) return;
    
    const colors = ['#FF0000', '#00FF00', '#0000FF', '#FFFF00', '#FF00FF']
    const currentIndex = colors.indexOf(this.currentColor);
    this.currentColor = colors[(currentIndex + 1) % colors.length]
    
    try {
      const layer = this.mapController.getLayer('road');
      if (layer) {
        (layer as LineLayer).setLineColor(this.currentColor);
        showToast(`颜色: ${this.currentColor}`);
      }
    } catch (error) {
      console.error(`切换颜色失败: ${error}`);
    }
  };
  
  /**
   * 切换宽度
   */
  private toggleWidth = (): void => {
    if (!this.mapController || !this.layerAdded) return;
    
    const widths = [1.0, 2.0, 3.0, 4.0, 5.0]
    const currentIndex = widths.indexOf(this.currentWidth);
    this.currentWidth = widths[(currentIndex + 1) % widths.length]
    
    try {
      const layer = this.mapController.getLayer('road');
      if (layer) {
        (layer as LineLayer).setLineWidth(this.currentWidth);
        showToast(`宽度: ${this.currentWidth}px`);
      }
    } catch (error) {
      console.error(`切换宽度失败: ${error}`);
    }
  };
  
  @Builder
  actionButtonsBuilder() {
    Column({ space: 8 }) {
      // 矢量瓦片信息显示
      Column({ space: 4 }) {
        Text('矢量瓦片信息')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        
        Text(`数据源: OpenMapTiles`)
          .fontSize(12)
          .fontColor('#666')
          .width('100%')
        
        Text(`源图层: transportation`)
          .fontSize(12)
          .fontColor('#666')
          .width('100%')
        
        Text(`状态: ${this.layerAdded ? '已添加' : '未添加'}`)
          .fontSize(12)
          .fontColor(this.layerAdded ? '#4CAF50' : '#999')
          .width('100%')
        
        if (this.layerAdded) {
          Divider().margin({ top: 4, bottom: 4 })
          
          Text('图层样式')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .width('100%')
          
          Text(`颜色: ${this.currentColor}`)
            .fontSize(12)
            .fontColor('#666')
            .width('100%')
          
          Text(`宽度: ${this.currentWidth}px`)
            .fontSize(12)
            .fontColor('#666')
            .width('100%')
        }
      }
      .width('100%')
      .padding(8)
      .backgroundColor('#F8F8F8')
      .borderRadius(4)
      .alignItems(HorizontalAlign.Start)
      
      Button('添加图层')
        .fontSize(14)
        .width('100%')
        .enabled(!this.layerAdded)
        .onClick(this.addVectorTileLayer)
      
      Button('移除图层')
        .fontSize(14)
        .width('100%')
        .backgroundColor('#F44336')
        .enabled(this.layerAdded)
        .onClick(this.removeVectorTileLayer)
      
      Button('切换颜色')
        .fontSize(14)
        .width('100%')
        .enabled(this.layerAdded)
        .onClick(this.toggleColor)
      
      Button('切换宽度')
        .fontSize(14)
        .width('100%')
        .enabled(this.layerAdded)
        .onClick(this.toggleWidth)
    }
    .width('100%')
  }
  
  
  @Builder
  mapContentBuilder() {
    MapView({
      styleUrl: DEFAULT_STYLE_URLS.bright,
      onMapReady: this.onMapReady,
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 10
    })
      .width('100%')
      .height('100%');
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Vector Tile',
        description: '矢量瓦片源',
        showActionBar: true,
        actionButtons: (): void => this.actionButtonsBuilder(),
        mapContent: (): void => this.mapContentBuilder()
      });
    }
    .width('100%')
    .height('100%');
  }
}

