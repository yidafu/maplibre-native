/**
 * Change Resources Cache Path Test Page
 * 修改资源缓存路径测试页面
 * 
 * 测试功能:
 * - 查看当前缓存路径
 * - 测试不同缓存路径配置
 * 
 * 注意: Harmony使用沙箱路径，缓存路径在创建MapView时设定
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { NativeMapView, MapLibreMap, MapLibreMapOptions } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS } from '../common/TestUtils';
import common from '@ohos.app.ability.common';

@Entry
@Component
struct ChangeResourcesCachePathTestPage {
  private mapController: MapLibreMap | null = null;
  @State private currentPath: string = '';
  @State private cacheSize: number = 0;
  @State private pathInfo: string[] = [];
  
  aboutToAppear() {
    this.initPathInfo();
  }
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  /**
   * 初始化路径信息
   */
  private initPathInfo = (): void => {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      this.currentPath = context.cacheDir + '/maplibre';
      
      this.pathInfo = [
        `缓存目录: ${context.cacheDir}`,
        `文件目录: ${context.filesDir}`,
        `临时目录: ${context.tempDir}`,
        `数据库目录: ${context.databaseDir}`
      ];
      
      showToast('路径信息已加载');
    } catch (error) {
      showToast(`获取路径失败: ${error}`);
    }
  };
  
  private onMapReady = (mapView: NativeMapView): void => {
    const options = new MapLibreMapOptions();
    this.mapController = new MapLibreMap(mapView, options);
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 10);
  };
  
  /**
   * 查询缓存大小
   */
  private queryCacheSize = (): void => {
    // 模拟查询缓存大小
    this.cacheSize = Math.floor(Math.random() * 100);
    showToast(`缓存大小: ${this.cacheSize}MB（模拟）`);
  };
  
  /**
   * 清除缓存
   */
  private clearCache = (): void => {
    this.cacheSize = 0;
    showToast('缓存已清除（模拟）');
  };
  
  @Builder
  buildMapContent() {
    NativeMapView({
      onMapReady: this.onMapReady
    })
    .width('100%')
    .height('100%')
  }
  
  @Builder
  buildControlPanel() {
    Scroll() {
      Column({ space: 12 }) {
        Text('资源缓存路径')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        
        Text('当前路径')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
        
        Text(this.currentPath)
          .fontSize(11)
          .fontFamily('monospace')
          .fontColor('#666')
          .padding(8)
          .backgroundColor('#F5F5F5')
          .borderRadius(4)
          .width('100%')
        
        Divider()
        
        Text('Harmony沙箱路径')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
        
        Column() {
          ForEach(this.pathInfo, (info: string, index: number) => {
            Text(info)
              .fontSize(10)
              .fontFamily('monospace')
              .width('100%')
              .padding(6)
              .backgroundColor(index % 2 === 0 ? '#F5F5F5' : '#FFFFFF')
          })
        }
        .width('100%')
        .backgroundColor('#F9F9F9')
        .border({ width: 1, color: '#DDD' })
        .borderRadius(4)
        
        Divider()
        
        Text('缓存管理')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
        
        Text(`缓存大小: ${this.cacheSize} MB`)
          .fontSize(14)
          .fontColor('#666')
        
        Button('查询缓存大小')
          .width('100%')
          .onClick(() => this.queryCacheSize())
        
        Button('清除缓存')
          .width('100%')
          .backgroundColor('#FF6B6B')
          .onClick(() => this.clearCache())
        
        Text('说明: Harmony沙箱路径在NativeMapView创建时设定')
          .fontSize(12)
          .fontColor('#666')
          .margin({ top: 8 })
      }
      .width('100%')
      .padding(16)
    }
    .height('100%')
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Change Resources Cache Path',
        description: '修改资源缓存路径',
        showActionBar: true,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%')
  }
}
