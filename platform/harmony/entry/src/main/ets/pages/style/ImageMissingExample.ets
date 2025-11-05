/**
 * Image Missing Listener Example
 * 图片缺失监听器示例 - 懒加载图片
 * 参考 Android: SymbolLayerActivity 的 OnStyleImageMissing 功能
 * 
 * 演示如何使用 OnStyleImageMissingListener 实现图片懒加载：
 * 1. Symbol layer 引用不存在的图片
 * 2. 监听器检测到图片缺失
 * 3. 动态加载并添加图片
 * 4. 地图自动重新渲染显示图片
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { 
  GeoJson, 
  GeoJsonSource, 
  Image,
  MapLibreMap, 
  MapView,
  SymbolLayer,
  Expression
} from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, showToast } from '../common/TestUtils';
import type { JSONValue } from 'libmaplibre.so';

@Entry
@Component
struct ImageMissingExample {
  private scroller: Scroller = new Scroller();
  private mapController: MapLibreMap | null = null;
  @State private missingImageLog: string[] = [];
  @State private loadedImages: Set<string> = new Set();
  
  aboutToDisappear() {
    if (this.mapController) {
      // 移除监听器
      this.mapController.removeOnStyleImageMissingListener();
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Image Missing Listener',
        description: '图片懒加载示例',
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
      initialLatitude: 39.9042,
      initialLongitude: 116.4074,
      initialZoom: 12,
      onMapReady: (map: MapLibreMap) => {
        this.mapController = map;
        this.setupImageMissingListener();
        map.jumpTo(0, 39.9042, 116.4074, 0, 12);
        showToast('地图已加载，监听器已设置');
      }
    })
  }

  @Builder
  buildActionButtons() {
    Scroll(this.scroller) {
      Column({ space: 12 }) {
        Text('懒加载测试')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        
        Text('当 Symbol Layer 引用不存在的图片时，监听器会自动加载')
          .fontSize(12)
          .fontColor('#666')
          .width('100%')
          .margin({ bottom: 8 })
        
        Button('添加引用缺失图片的 Layer')
          .onClick(() => this.addLayerWithMissingIcon())
          .width('100%')
        
        Button('测试异步批量加载')
          .onClick(() => this.testAsyncBatchLoading())
          .width('100%')
        
        Button('清空日志')
          .onClick(() => {
            this.missingImageLog = [];
          })
          .width('100%')
        
        Divider().margin({ top: 8, bottom: 8 })
        
        Text('监听器日志')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        
        if (this.missingImageLog.length === 0) {
          Text('暂无缺失图片')
            .fontSize(12)
            .fontColor('#999')
            .width('100%')
        } else {
          ForEach(this.missingImageLog, (log: string, index: number) => {
            Text(`${index + 1}. ${log}`)
              .fontSize(11)
              .fontColor('#333')
              .width('100%')
              .padding({ left: 8, top: 4, bottom: 4 })
          })
        }
      }
      .width('100%')
      .padding(16)
    }
    .scrollBar(BarState.Auto)
    .scrollable(ScrollDirection.Vertical)
  }
  
  /**
   * 设置图片缺失监听器
   */
  private setupImageMissingListener(): void {
    if (!this.mapController) return;
    
    this.mapController.setOnStyleImageMissingListener((imageId: string) => {
      console.info(`[ImageMissing] 检测到缺失图片: ${imageId}`);
      
      // 添加到日志
      const log = `缺失图片: ${imageId}`;
      this.missingImageLog = [...this.missingImageLog, log];
      
      // 检查是否已经加载过（避免重复加载）
      if (this.loadedImages.has(imageId)) {
        console.warn(`[ImageMissing] 图片 ${imageId} 已加载，跳过`);
        return;
      }
      
      // 懒加载图片
      this.loadImageOnDemand(imageId);
    });
  }
  
  /**
   * 按需加载图片
   */
  private loadImageOnDemand(imageId: string): void {
    if (!this.mapController) return;
    
    try {
      const style = this.mapController.getStyle();
      if (!style) return;
      
      // 根据图片 ID 生成对应的图片
      // 实际应用中应该从网络、本地文件或资源加载
      const imageData = this.generateImageForId(imageId);
      
      if (imageData) {
        style.addImage(imageId, imageData.data, imageData.width, imageData.height, false);
        this.loadedImages.add(imageId);
        
        const successLog = `✓ 已加载: ${imageId}`;
        this.missingImageLog = [...this.missingImageLog, successLog];
        
        console.info(`[ImageMissing] 成功加载图片: ${imageId}`);
      }
    } catch (error) {
      console.error(`[ImageMissing] 加载图片失败: ${error}`);
      const errorLog = `✗ 加载失败: ${imageId}`;
      this.missingImageLog = [...this.missingImageLog, errorLog];
    }
  }
  
  /**
   * 根据 ID 生成图片数据（模拟）
   */
  private generateImageForId(imageId: string): { data: Uint8Array, width: number, height: number } | null {
    // 为不同的 icon 生成不同颜色的图标
    const size = 64;
    const data = new Uint8Array(size * size * 4);
    
    // 根据 imageId 选择颜色
    let r = 255, g = 0, b = 0; // 默认红色
    
    if (imageId.includes('icon-1')) {
      r = 255; g = 0; b = 0; // 红色
    } else if (imageId.includes('icon-2')) {
      r = 0; g = 255; b = 0; // 绿色
    } else if (imageId.includes('icon-3')) {
      r = 0; g = 0; b = 255; // 蓝色
    } else if (imageId.includes('icon-4')) {
      r = 255; g = 255; b = 0; // 黄色
    } else {
      r = 255; g = 128; b = 0; // 橙色（默认）
    }
    
    // 创建一个圆形图标
    const centerX = size / 2;
    const centerY = size / 2;
    const radius = size / 2 - 4;
    
    for (let y = 0; y < size; y++) {
      for (let x = 0; x < size; x++) {
        const idx = (y * size + x) * 4;
        const dx = x - centerX;
        const dy = y - centerY;
        const distance = Math.sqrt(dx * dx + dy * dy);
        
        if (distance <= radius) {
          // 圆形内部
          data[idx] = r;
          data[idx + 1] = g;
          data[idx + 2] = b;
          data[idx + 3] = 255; // 不透明
        } else {
          // 圆形外部 - 透明
          data[idx] = 0;
          data[idx + 1] = 0;
          data[idx + 2] = 0;
          data[idx + 3] = 0;
        }
      }
    }
    
    return { data, width: size, height: size };
  }
  
  /**
   * 添加引用缺失图片的图层
   */
  private addLayerWithMissingIcon(): void {
    if (!this.mapController) {
      showToast('地图未初始化');
      return;
    }
    
    try {
      const style = this.mapController.getStyle();
      if (!style) {
        showToast('样式未加载');
        return;
      }
      
      // 创建多个点，引用不同的（当前不存在的）图标
      const features = [
        GeoJson.pointFeature([116.3, 39.9], { 
          'title': '点 1',
          'icon': 'missing-icon-1'
        } as Record<string, JSONValue>),
        GeoJson.pointFeature([116.4, 39.9], { 
          'title': '点 2',
          'icon': 'missing-icon-2'
        } as Record<string, JSONValue>),
        GeoJson.pointFeature([116.5, 39.9], { 
          'title': '点 3',
          'icon': 'missing-icon-3'
        } as Record<string, JSONValue>),
      ];
      
      const geojson = GeoJson.featureCollection(features);
      const source = new GeoJsonSource('missing-icon-source');
      source.setGeoJson(geojson);
      
      // 移除旧的
      if (style.getLayer('missing-icon-layer')) {
        style.removeLayer('missing-icon-layer');
      }
      if (style.getSource('missing-icon-source')) {
        style.removeSource('missing-icon-source');
      }
      
      style.addSource(source);
      
      // 创建图层引用缺失的图片
      const layer = new SymbolLayer('missing-icon-layer', 'missing-icon-source');
      layer.setIconImage(Expression.get('icon'));
      layer.setIconAllowOverlap(true);
      layer.setIconSize(0.8);
      layer.setTextField(Expression.get('title'));
      layer.setTextOffset([0, 2]);
      layer.setTextAnchor('top');
      
      style.addLayer(layer);
      
      showToast('已添加图层，监听器将自动加载缺失的图片');
      
    } catch (error) {
      showToast(`添加失败: ${error}`);
      console.error('Error adding layer:', error);
    }
  }
  
  /**
   * 测试异步批量加载图片
   */
  private async testAsyncBatchLoading(): Promise<void> {
    if (!this.mapController) {
      showToast('地图未初始化');
      return;
    }
    
    try {
      const style = this.mapController.getStyle();
      if (!style) {
        showToast('样式未加载');
        return;
      }
      
      showToast('开始异步批量加载 5 张图片...');
      
      // 创建多个图片
      const images: Image[] = [];
      for (let i = 1; i <= 5; i++) {
        const imageData = this.generateImageForId(`async-icon-${i}`);
        if (imageData) {
          images.push(new Image({
            name: `async-icon-${i}`,
            width: imageData.width,
            height: imageData.height,
            data: imageData.data,
            sdf: false
          }));
        }
      }
      
      // 使用异步方法批量添加
      const startTime = Date.now();
      await this.mapController.addImagesAsync(images);
      const elapsed = Date.now() - startTime;
      
      showToast(`✓ 异步加载完成！\n耗时: ${elapsed}ms\n已加载 ${images.length} 张图片`);
      
      // 添加使用这些图片的图层
      this.showAsyncLoadedIcons();
      
    } catch (error) {
      showToast(`异步加载失败: ${error}`);
      console.error('Error in async batch loading:', error);
    }
  }
  
  /**
   * 显示异步加载的图标
   */
  private showAsyncLoadedIcons(): void {
    if (!this.mapController) return;
    
    try {
      const style = this.mapController.getStyle();
      if (!style) return;
      
      // 创建点
      const features = [];
      for (let i = 1; i <= 5; i++) {
        features.push(GeoJson.pointFeature(
          [116.2 + i * 0.1, 39.85], 
          { 
            'title': `异步 ${i}`,
            'icon': `async-icon-${i}`
          } as Record<string, JSONValue>
        ));
      }
      
      const geojson = GeoJson.featureCollection(features);
      const source = new GeoJsonSource('async-icon-source');
      source.setGeoJson(geojson);
      
      // 移除旧的
      if (style.getLayer('async-icon-layer')) {
        style.removeLayer('async-icon-layer');
      }
      if (style.getSource('async-icon-source')) {
        style.removeSource('async-icon-source');
      }
      
      style.addSource(source);
      
      const layer = new SymbolLayer('async-icon-layer', 'async-icon-source');
      layer.setIconImage(Expression.get('icon'));
      layer.setIconAllowOverlap(true);
      layer.setIconSize(0.6);
      layer.setTextField(Expression.get('title'));
      layer.setTextOffset([0, 1.5]);
      layer.setTextAnchor('top');
      layer.setTextSize(10);
      
      style.addLayer(layer);
      
    } catch (error) {
      console.error('Error showing async icons:', error);
    }
  }

  @Builder
  buildActionButtons() {
    Scroll(this.scroller) {
      Column({ space: 12 }) {
        Text('懒加载功能演示')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        
        Text('OnStyleImageMissingListener 会在地图需要但找不到图片时触发')
          .fontSize(12)
          .fontColor('#666')
          .width('100%')
          .margin({ bottom: 8 })
        
        Button('添加缺失图标的图层')
          .onClick(() => this.addLayerWithMissingIcon())
          .width('100%')
        
        Button('测试异步批量加载')
          .onClick(() => this.testAsyncBatchLoading())
          .width('100%')
        
        Button('清空日志')
          .onClick(() => {
            this.missingImageLog = [];
            this.loadedImages.clear();
          })
          .width('100%')
        
        Divider().margin({ top: 8, bottom: 8 })
        
        Text('监听器日志')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        
        if (this.missingImageLog.length === 0) {
          Text('等待触发监听器...')
            .fontSize(12)
            .fontColor('#999')
            .width('100%')
        } else {
          Column({ space: 4 }) {
            ForEach(this.missingImageLog, (log: string, index: number) => {
              Text(`${index + 1}. ${log}`)
                .fontSize(11)
                .fontColor(log.startsWith('✓') ? '#4CAF50' : log.startsWith('✗') ? '#F44336' : '#FF9800')
                .width('100%')
                .fontFamily('monospace')
            })
          }
          .width('100%')
        }
        
        Divider().margin({ top: 8, bottom: 8 })
        
        Text('使用说明')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        
        Text('1. 点击"添加缺失图标的图层"\n2. 监听器会检测到 missing-icon-1/2/3\n3. 自动生成并添加这些图片\n4. 地图自动显示图标')
          .fontSize(11)
          .fontColor('#666')
          .width('100%')
      }
      .width('100%')
      .padding(16)
    }
    .scrollBar(BarState.Auto)
    .scrollable(ScrollDirection.Vertical)
  }
  
  /**
   * 添加引用缺失图片的图层
   */
  private addLayerWithMissingIcon(): void {
    if (!this.mapController) {
      showToast('地图未初始化');
      return;
    }
    
    try {
      const style = this.mapController.getStyle();
      if (!style) {
        showToast('样式未加载');
        return;
      }
      
      // 创建多个点，引用不同的（当前不存在的）图标
      const features = [
        GeoJson.pointFeature([116.35, 39.92], { 
          'title': '图标 1',
          'icon': 'missing-icon-1'
        } as Record<string, JSONValue>),
        GeoJson.pointFeature([116.4, 39.92], { 
          'title': '图标 2',
          'icon': 'missing-icon-2'
        } as Record<string, JSONValue>),
        GeoJson.pointFeature([116.45, 39.92], { 
          'title': '图标 3',
          'icon': 'missing-icon-3'
        } as Record<string, JSONValue>),
      ];
      
      const geojson = GeoJson.featureCollection(features);
      const source = new GeoJsonSource('lazy-load-source');
      source.setGeoJson(geojson);
      
      // 移除旧的
      if (style.getLayer('lazy-load-layer')) {
        style.removeLayer('lazy-load-layer');
      }
      if (style.getSource('lazy-load-source')) {
        style.removeSource('lazy-load-source');
      }
      
      style.addSource(source);
      
      // 创建图层 - 引用还不存在的图片
      const layer = new SymbolLayer('lazy-load-layer', 'lazy-load-source');
      layer.setIconImage(Expression.get('icon'));
      layer.setIconAllowOverlap(true);
      layer.setIconSize(0.8);
      layer.setTextField(Expression.get('title'));
      layer.setTextOffset([0, 2]);
      layer.setTextAnchor('top');
      layer.setTextSize(12);
      
      style.addLayer(layer);
      
      showToast('已添加图层，监听器将触发');
      
    } catch (error) {
      showToast(`添加失败: ${error}`);
      console.error('Error adding layer:', error);
    }
  }
}

