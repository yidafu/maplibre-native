/**
 * Style File Test Page
 * 样式文件加载测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/style/StyleFileActivity.kt
 * 
 * 功能:
 * - 加载本地样式文件
 * - 样式切换
 * - 样式加载状态监听
 * 
 * 注意: 需要将样式文件放在 rawfile 目录中
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapLibreMap, MapView } from 'maplibre_harmony';
import { showToast, DEFAULT_MAP_CONFIG, DEFAULT_STYLE_URLS } from '../common/TestUtils';
import { resourceManager } from '@kit.LocalizationKit';

@Entry
@Component
struct StyleFileTestPage {
  private scroller: Scroller = new Scroller();
  private mapController: MapLibreMap | null = null;
  @State private currentStyle: string = '远程样式';
  @State private isLoading: boolean = false;
  @State private styleLoadError: string = '';
  
  // 预定义的样式 URL
  private styles: Record<string, string> = {
    '远程样式': 'https://demotiles.maplibre.org/style.json',
    'OSM Bright': 'https://tiles.openfreemap.org/styles/bright',
    'OSM Liberty': 'https://tiles.openfreemap.org/styles/liberty',
    'Positron': 'https://tiles.openfreemap.org/styles/positron',
    // 本地样式需要先从 rawfile 读取
    // '本地样式': 'asset://rawfile/style.json'
  };
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[StyleFileTestPage] onMapReady');
    this.mapController = map;
    
    // 加载初始样式
    this.loadStyle('远程样式');
    
    // 设置初始位置
    map.jumpTo(0, 39.9, 116.4, 0, 10);
  };
  
  /**
   * 加载样式
   */
  private loadStyle = (styleName: string): void => {
    if (!this.mapController) {
      showToast('地图未就绪');
      return;
    }
    
    const styleUrl = this.styles[styleName]
    if (!styleUrl) {
      showToast(`未找到样式: ${styleName}`);
      return;
    }
    
    this.isLoading = true;
    this.styleLoadError = '';
    this.currentStyle = styleName;
    
    try {
      showToast(`加载样式: ${styleName}`);
      
      // 加载样式
      this.mapController.setStyleUrl(styleUrl);
      
      // 模拟加载完成（实际应该监听样式加载事件）
      setTimeout(() => {
        this.isLoading = false;
        showToast(`样式加载完成: ${styleName}`);
      }, 1000);
      
    } catch (error) {
      console.error(`加载样式失败: ${error}`);
      this.isLoading = false;
      this.styleLoadError = `${error}`;
      showToast(`加载失败: ${error}`);
    }
  };
  
  /**
   * 加载本地样式文件
   * 注意: 需要先将样式 JSON 文件放在 rawfile 目录
   */
  private loadLocalStyle = async (): Promise<void> => {
    if (!this.mapController) {
      showToast('地图未就绪');
      return;
    }
    
    try {
      showToast('加载本地样式...');
      this.isLoading = true;
      this.styleLoadError = '';
      
      // 从 rawfile 读取样式文件
      // const context = getContext(this);
      // const resourceMgr = context.resourceManager;
      // const styleContent = await resourceMgr.getRawFileContent('style.json');
      // const styleJson = new util.TextDecoder().decode(styleContent);
      
      // TODO: 实现本地样式加载
      // this.mapController.setStyleJson(styleJson);
      
      showToast('本地样式功能待实现');
      this.isLoading = false;
      
    } catch (error) {
      console.error(`加载本地样式失败: ${error}`);
      this.isLoading = false;
      this.styleLoadError = `${error}`;
      showToast(`加载失败: ${error}`);
    }
  };
  
  /**
   * 重新加载当前样式
   */
  private reloadCurrentStyle = (): void => {
    this.loadStyle(this.currentStyle);
  };
  
  @Builder
  actionButtonsBuilder() {
    Column({ space: 8 }) {
      // 样式加载信息显示
      Column({ space: 4 }) {
        Text('样式加载')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        
        Text(`当前样式: ${this.currentStyle}`)
          .fontSize(12)
          .fontColor('#666')
          .width('100%')
        
        Text(`状态: ${this.isLoading ? '加载中...' : '就绪'}`)
          .fontSize(12)
          .fontColor(this.isLoading ? '#FF9800' : '#4CAF50')
          .width('100%')
        
        if (this.styleLoadError) {
          Divider().margin({ top: 4, bottom: 4 })
          
          Text('错误信息')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#F44336')
            .width('100%')
          
          Text(this.styleLoadError)
            .fontSize(11)
            .fontColor('#F44336')
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
        
        Divider().margin({ top: 4, bottom: 4 })
        
        Text('可用样式')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        
        ForEach(Object.keys(this.styles), (styleName: string) => {
          Text(`• ${styleName}`)
            .fontSize(11)
            .fontColor(styleName === this.currentStyle ? '#2196F3' : '#666')
            .fontWeight(styleName === this.currentStyle ? FontWeight.Bold : FontWeight.Normal)
            .width('100%')
        }, (styleName: string) => styleName)
        
        Divider().margin({ top: 4, bottom: 4 })
        
        Text('功能说明')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        
        Text('• 加载远程样式文件')
          .fontSize(10)
          .fontColor('#666')
          .width('100%')
        
        Text('• 加载本地样式文件（待实现）')
          .fontSize(10)
          .fontColor('#666')
          .width('100%')
        
        Text('• 样式快速切换')
          .fontSize(10)
          .fontColor('#666')
          .width('100%')
      }
      .width('100%')
      .padding(8)
      .backgroundColor('#F8F8F8')
      .borderRadius(4)
      .alignItems(HorizontalAlign.Start)
      
      Button('远程样式')
        .fontSize(14)
        .width('100%')
        .enabled(!this.isLoading)
        .onClick(() => this.loadStyle('远程样式'))
      
      Button('OSM Bright')
        .fontSize(14)
        .width('100%')
        .enabled(!this.isLoading)
        .onClick(() => this.loadStyle('OSM Bright'))
      
      Button('OSM Liberty')
        .fontSize(14)
        .width('100%')
        .enabled(!this.isLoading)
        .onClick(() => this.loadStyle('OSM Liberty'))
      
      Button('Positron')
        .fontSize(14)
        .width('100%')
        .enabled(!this.isLoading)
        .onClick(() => this.loadStyle('Positron'))
      
      Button('本地样式')
        .fontSize(14)
        .width('100%')
        .enabled(!this.isLoading)
        .onClick(this.loadLocalStyle)
      
      Button('重新加载')
        .fontSize(14)
        .width('100%')
        .backgroundColor('#FF9800')
        .enabled(!this.isLoading)
        .onClick(this.reloadCurrentStyle)
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
        title: 'Style File',
        description: '样式文件加载',
        showActionBar: true,
        actionButtons: (): void => this.actionButtonsBuilder(),
        mapContent: (): void => this.mapContentBuilder()
      });
    }
    .width('100%')
    .height('100%');
  }
}

