/**
 * Custom Layer
 * 自定义渲染图层
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/activity/customlayer/CustomLayerActivity.kt
 * 
 * 功能测试：
 * 1. 添加/移除自定义图层
 * 2. 切换图层颜色（红/绿/蓝）
 * 3. 触发重绘
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, CustomLayer } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct CustomLayerTestPage {
  private mapController: MapLibreMap | null = null;
  private customLayer: CustomLayer | null = null;
  @State private layerAdded: boolean = false;
  @State private currentColor: string = '红色';
  
  aboutToDisappear() {
    // CustomLayer 在移除时自动销毁，无需手动调用 destroy
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[CustomLayerTestPage] onMapReady');
    this.mapController = map;
    map.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    
    // 设置初始位置（对应Android测试：39.91448, -243.60947）
    map.jumpTo(0, 39.91448, -243.60947, 0, 10);
    
    showToast('CustomLayer API - 待实现底层NAPI绑定');
  };
  
  /**
   * 添加/移除自定义图层
   * 
   * TODO: 需要实现以下功能：
   * 1. NAPI层的CustomLayer实现
   * 2. OpenGL渲染上下文创建
   * 3. 图层添加/移除到Style
   */
  private toggleCustomLayer = (): void => {
    if (!this.mapController) {
      showToast('地图未初始化');
      return;
    }
    
    const style = this.mapController.getStyle();
    if (!style) {
      showToast('样式未加载');
      return;
    }
    
    if (this.layerAdded && this.customLayer) {
      // 移除图层
      try {
        // TODO: 当NAPI层实现后，这里应该能正常工作
        const removed = style.removeLayer(this.customLayer.getId());
        if (removed) {
          this.layerAdded = false;
          showToast('已移除CustomLayer');
          console.info('[CustomLayerTestPage] Custom layer removed');
        } else {
          showToast('移除失败：图层不存在');
        }
      } catch (error) {
        showToast(`移除失败: ${error}`);
        console.error('[CustomLayerTestPage] Failed to remove layer:', error);
      }
    } else {
      // 添加图层
      try {
        // 创建简化的自定义图层
        // 注意：完整的 CustomLayer 实现需要 Native 层支持
        this.customLayer = new CustomLayer('custom-layer');
        
        // 添加图层
        style.addLayer(this.customLayer!);
        this.layerAdded = true;
        showToast('已添加CustomLayer (简化版)');
        console.info('[CustomLayerTestPage] Custom layer added');
      } catch (error) {
        showToast(`添加失败: ${error}`);
        console.error('[CustomLayerTestPage] Failed to add layer:', error);
      }
    }
  };
  
  /**
   * 设置图层颜色
   * 
   * TODO: 需要实现Native层的setColor方法
   */
  private setLayerColor = (red: number, green: number, blue: number, colorName: string): void => {
    if (!this.layerAdded) {
      showToast('请先添加自定义图层');
      return;
    }
    
    try {
      // TODO: 当 CustomLayer API 完善后，可以实现颜色变更
      this.currentColor = colorName;
      
      // 触发重绘
      if (this.mapController) {
        this.mapController.triggerRepaint();
      }
      
      showToast(`颜色设置为${colorName} (TODO: 需要API实现)`);
      console.info(`[CustomLayerTestPage] Color set to ${colorName}: (${red}, ${green}, ${blue})`);
    } catch (error) {
      showToast(`设置颜色失败: ${error}`);
      console.error('[CustomLayerTestPage] Failed to set color:', error);
    }
  };
  
  /**
   * 触发地图重绘
   */
  private updateLayer = (): void => {
    if (!this.mapController) {
      showToast('地图未初始化');
      return;
    }
    
    try {
      this.mapController.triggerRepaint();
      showToast('已触发重绘');
      console.info('[CustomLayerTestPage] Layer update triggered');
    } catch (error) {
      showToast(`重绘失败: ${error}`);
      console.error('[CustomLayerTestPage] Failed to trigger repaint:', error);
    }
  };
  
  @Builder
  actionButtonsBuilder() {
    Column({ space: 8 }) {
      // 添加/移除图层按钮
      Button(this.layerAdded ? '移除CustomLayer' : '添加CustomLayer')
        .fontSize(14)
        .width('100%')
        .type(ButtonType.Normal)
        .backgroundColor(this.layerAdded ? '#FF6B6B' : '#4ECDC4')
        .onClick(() => {
          this.toggleCustomLayer();
        });
      
      // 颜色控制按钮组
      Text('图层颜色控制')
        .fontSize(12)
        .fontColor('#666666')
        .margin({ top: 8 });
      
      Row({ space: 8 }) {
        Button('红色')
          .fontSize(12)
          .layoutWeight(1)
          .type(ButtonType.Normal)
          .backgroundColor(this.currentColor === '红色' ? '#FF0000' : '#FFB3B3')
          .onClick(() => {
            this.setLayerColor(1.0, 0.0, 0.0, '红色');
          })
          .enabled(this.layerAdded);
        
        Button('绿色')
          .fontSize(12)
          .layoutWeight(1)
          .type(ButtonType.Normal)
          .backgroundColor(this.currentColor === '绿色' ? '#00FF00' : '#B3FFB3')
          .onClick(() => {
            this.setLayerColor(0.0, 1.0, 0.0, '绿色');
          })
          .enabled(this.layerAdded);
        
        Button('蓝色')
          .fontSize(12)
          .layoutWeight(1)
          .type(ButtonType.Normal)
          .backgroundColor(this.currentColor === '蓝色' ? '#0000FF' : '#B3B3FF')
          .onClick(() => {
            this.setLayerColor(0.0, 0.0, 1.0, '蓝色');
          })
          .enabled(this.layerAdded);
      }
      .width('100%');
      
      // 重绘按钮
      Button('触发重绘')
        .fontSize(14)
        .width('100%')
        .type(ButtonType.Normal)
        .backgroundColor('#95A5A6')
        .onClick(() => {
          this.updateLayer();
        })
        .enabled(this.layerAdded);
      
      // 说明文字
      Text('注意：CustomLayer需要底层NAPI实现支持')
        .fontSize(11)
        .fontColor('#999999')
        .margin({ top: 8 })
        .textAlign(TextAlign.Center);
    }
    .width('100%')
    .padding(8);
  }
  
  @Builder
  mapContentBuilder() {
    MapView({
      onMapReady: this.onMapReady,
      styleUrl: DEFAULT_STYLE_URLS.bright,
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
        title: 'Custom Layer',
        description: '自定义渲染图层',
        showActionBar: true,
        actionButtons: (): void => this.actionButtonsBuilder(),
        mapContent: (): void => this.mapContentBuilder()
      });
    }
    .width('100%')
    .height('100%');
  }
}
