/**
 * Stretchable Image Example
 * 可拉伸图片示例 - 9-patch 风格图片
 * 参考 Android: StretchableImageActivity
 * 
 * 演示如何使用 stretchX, stretchY 和 content 参数创建可拉伸的图片
 * 类似于 Android 的 9-patch 图片，常用于创建聊天气泡、弹窗背景等
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
struct StretchableImageExample {
  private scroller: Scroller = new Scroller();
  private mapController: MapLibreMap | null = null;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Stretchable Image',
        description: '9-patch 可拉伸图片示例',
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
        map.jumpTo(0, 39.9042, 116.4074, 0, 12);
        showToast('地图已加载');
      }
    })
  }

  @Builder
  buildActionButtons() {
    Scroll(this.scroller) {
      Column({ space: 12 }) {
        Text('可拉伸图片测试')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        
        Text('9-patch 风格的可拉伸图片，可用于创建聊天气泡、弹窗背景等UI元素')
          .fontSize(12)
          .fontColor('#666')
          .width('100%')
          .margin({ bottom: 8 })
        
        Button('添加可拉伸图片')
          .onClick(() => this.addStretchableImage())
          .width('100%')
        
        Button('显示拉伸效果')
          .onClick(() => this.showStretchedPopups())
          .width('100%')
        
        Button('添加不拉伸图片对比')
          .onClick(() => this.addNonStretchableImage())
          .width('100%')
        
        Text('实现说明')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ top: 12 })
        
        Text('• stretchX: 水平可拉伸区域\n• stretchY: 垂直可拉伸区域\n• content: 文本显示区域')
          .fontSize(12)
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
   * 创建一个简单的弹窗样式图片（模拟）
   * 实际应用中应该从资源加载或动态生成
   */
  private createPopupImageData(width: number, height: number): Uint8Array {
    const data = new Uint8Array(width * height * 4);
    
    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        const idx = (y * width + x) * 4;
        
        // 创建一个简单的渐变色弹窗背景
        // 边缘 10px 为边框区域（深蓝色）
        // 中间为可拉伸区域（浅蓝色）
        const isEdge = x < 10 || x >= width - 10 || y < 10 || y >= height - 10;
        
        if (isEdge) {
          // 边框：深蓝色
          data[idx] = 41;      // R
          data[idx + 1] = 98;  // G
          data[idx + 2] = 255; // B
          data[idx + 3] = 255; // A
        } else {
          // 内容区域：浅蓝色半透明
          data[idx] = 173;     // R
          data[idx + 1] = 216; // G
          data[idx + 2] = 230; // B
          data[idx + 3] = 230; // A (90% 不透明)
        }
      }
    }
    
    return data;
  }
  
  private addStretchableImage(): void {
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
      
      // 创建一个 140x125 的弹窗背景图片
      const width = 140;
      const height = 125;
      const imageData = this.createPopupImageData(width, height);
      
      // 定义可拉伸区域
      // stretchX: 两个水平可拉伸区域（蓝色列）
      const stretchX = [25, 55, 85, 115]; // [start1, end1, start2, end2]
      
      // stretchY: 一个垂直可拉伸区域（红色行）
      const stretchY = [25, 100]; // [start, end]
      
      // content: 文本可以放置的区域
      const content = [25, 25, 115, 100]; // [left, top, right, bottom]
      
      // 使用 Image 类创建可拉伸图片
      const stretchableImage = new Image({
        name: 'popup-stretchable',
        width: width,
        height: height,
        pixelRatio: 1.0,
        sdf: false,
        data: imageData,
        stretchX: stretchX,
        stretchY: stretchY,
        content: content
      });
      
      // 同步添加图片
      style.addImage('popup-stretchable', imageData, width, height, false);
      
      showToast('可拉伸图片已添加 (popup-stretchable)');
      
    } catch (error) {
      showToast(`添加失败: ${error}`);
      console.error('Error adding stretchable image:', error);
    }
  }
  
  private showStretchedPopups(): void {
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
      
      // 创建多个点，每个点有不同长度的文本来展示拉伸效果
      const features = [
        GeoJson.pointFeature([116.3, 39.95], { 
          'text': 'Short',
          'icon': 'popup-stretchable'
        } as Record<string, JSONValue>),
        GeoJson.pointFeature([116.4, 39.95], { 
          'text': 'Medium Text',
          'icon': 'popup-stretchable'
        } as Record<string, JSONValue>),
        GeoJson.pointFeature([116.5, 39.95], { 
          'text': 'Very Long Text Message',
          'icon': 'popup-stretchable'
        } as Record<string, JSONValue>),
      ];
      
      const geojson = GeoJson.featureCollection(features);
      const source = new GeoJsonSource('popup-source');
      source.setGeoJson(geojson);
      
      // 移除旧的图层和数据源
      if (style.getLayer('popup-layer')) {
        style.removeLayer('popup-layer');
      }
      if (style.getSource('popup-source')) {
        style.removeSource('popup-source');
      }
      
      style.addSource(source);
      
      // 创建 Symbol 图层
      const layer = new SymbolLayer('popup-layer', 'popup-source');
      layer.setIconImage(Expression.get('icon'));
      layer.setIconAllowOverlap(true);
      layer.setTextField(Expression.get('text'));
      layer.setTextColor('#FFFFFF');
      layer.setTextSize(14);
      layer.setTextAllowOverlap(true);
      
      style.addLayer(layer);
      
      showToast('已添加拉伸弹窗（观察不同文本长度的效果）');
      
    } catch (error) {
      showToast(`显示失败: ${error}`);
      console.error('Error showing popups:', error);
    }
  }
  
  private addNonStretchableImage(): void {
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
      
      // 创建相同尺寸的非拉伸图片作为对比
      const width = 140;
      const height = 125;
      const imageData = this.createPopupImageData(width, height);
      
      // 不设置 stretch 参数
      style.addImage('popup-fixed', imageData, width, height, false);
      
      showToast('非拉伸图片已添加 (popup-fixed)\n可以修改代码对比效果');
      
    } catch (error) {
      showToast(`添加失败: ${error}`);
      console.error('Error adding non-stretchable image:', error);
    }
  }
}

