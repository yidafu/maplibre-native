/**
 * OnMapReady Test Page
 * 测试 onMapReady 回调行为
 * 
 * 测试目标：
 * 1. onMapReady 应该只在地图首次初始化时触发一次
 * 2. setStyleUrl 切换样式时不应重复触发 onMapReady
 * 3. OnDidFinishLoadingStyleListener 应该在每次样式加载完成时触发
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS } from '../common/TestUtils';

@Entry
@Component
struct OnMapReadyTestPage {
  private mapController: MapLibreMap | null = null;
  @State private onMapReadyCount: number = 0;
  @State private onStyleLoadedCount: number = 0;
  @State private statusMessage: string = '等待地图初始化...';
  @State private currentStyle: string = 'bright';
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    this.onMapReadyCount++;
    console.info(`[OnMapReadyTestPage] ✅ onMapReady triggered - Count: ${this.onMapReadyCount}`);
    this.mapController = map;
    
    // 添加样式加载监听器
    this.mapController.addOnStyleLoadedListener(() => {
      this.onStyleLoadedCount++;
      console.info(`[OnMapReadyTestPage] 🎨 onStyleLoaded triggered - Count: ${this.onStyleLoadedCount}`);
      this.statusMessage = `样式加载完成 (${this.onStyleLoadedCount}次)`;
    });
    
    this.statusMessage = '地图已就绪';
    showToast('地图初始化完成');
  };
  
  private switchToBright = (): void => {
    if (!this.mapController) {
      showToast('地图未就绪');
      return;
    }
    
    console.info('[OnMapReadyTestPage] 🔄 Switching to Bright style');
    this.currentStyle = 'bright';
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.bright);
    this.statusMessage = '切换到 Bright 样式...';
  };
  
  private switchToStreets = (): void => {
    if (!this.mapController) {
      showToast('地图未就绪');
      return;
    }
    
    console.info('[OnMapReadyTestPage] 🔄 Switching to Streets style');
    this.currentStyle = 'streets';
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.statusMessage = '切换到 Streets 样式...';
  };
  
  private switchToDark = (): void => {
    if (!this.mapController) {
      showToast('地图未就绪');
      return;
    }
    
    console.info('[OnMapReadyTestPage] 🔄 Switching to Dark style');
    this.currentStyle = 'dark';
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.dark);
    this.statusMessage = '切换到 Dark 样式...';
  };
  
  private resetCounters = (): void => {
    // 注意：这只是重置显示的计数器，不会重置实际的回调触发次数
    console.info('[OnMapReadyTestPage] 🔄 Resetting displayed counters');
    showToast('计数器已重置（仅显示）');
  };
  
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
  
  @Builder
  controlPanelBuilder() {
    Column({ space: 12 }) {
      Text('onMapReady 行为测试')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
      
      // 状态显示
      Column({ space: 8 }) {
        Text(this.statusMessage)
          .fontSize(14)
          .fontColor('#666')
          .width('100%')
        
        Text(`onMapReady 触发次数: ${this.onMapReadyCount}`)
          .fontSize(14)
          .fontColor(this.onMapReadyCount === 1 ? '#4CAF50' : '#F44336')
          .fontWeight(FontWeight.Bold)
          .width('100%')
        
        Text(`onStyleLoaded 触发次数: ${this.onStyleLoadedCount}`)
          .fontSize(14)
          .fontColor('#2196F3')
          .width('100%')
        
        Text(`当前样式: ${this.currentStyle}`)
          .fontSize(14)
          .fontColor('#666')
          .width('100%')
      }
      .padding(12)
      .width('100%')
      .backgroundColor('#F5F5F5')
      .borderRadius(8)
      
      // 测试说明
      Column({ space: 4 }) {
        Text('✅ 预期行为：')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#4CAF50')
          .width('100%')
        
        Text('• onMapReady 应该始终为 1')
          .fontSize(12)
          .fontColor('#666')
          .width('100%')
        
        Text('• onStyleLoaded 应该随切换递增')
          .fontSize(12)
          .fontColor('#666')
          .width('100%')
      }
      .padding(12)
      .width('100%')
      .backgroundColor('#E8F5E9')
      .borderRadius(8)
      
      Divider()
      
      // 样式切换按钮
      Text('切换样式（测试）')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('100%')
      
      Button('切换到 Bright')
        .width('100%')
        .onClick(() => this.switchToBright())
        .enabled(this.currentStyle !== 'bright')
      
      Button('切换到 Streets')
        .width('100%')
        .onClick(() => this.switchToStreets())
        .enabled(this.currentStyle !== 'streets')
      
      Button('切换到 Dark')
        .width('100%')
        .onClick(() => this.switchToDark())
        .enabled(this.currentStyle !== 'dark')
    }
    .padding(16)
    .width('100%')
  }
  
  build() {
    TestPageLayout({
      title: 'onMapReady 测试',
      mapContentBuilder: this.mapContentBuilder,
      controlPanelBuilder: this.controlPanelBuilder
    });
  }
}

