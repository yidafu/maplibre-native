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
import { 
  MapView, 
  MapLibreMap, 
  MapLibreMapOptions,
  OfflineManager
} from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import common from '@ohos.app.ability.common';

@Entry
@Component
struct ChangeResourcesCachePathTestPage {
  private mapController: MapLibreMap | null = null;
  private offlineManager: OfflineManager | null = null;
  
  @State private currentPath: string = '';
  @State private cacheSize: number = 0;
  @State private pathInfo:  string[] = [];
  
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
      ]
      
      showToast('路径信息已加载');
    } catch (error) {
      showToast(`获取路径失败: ${error}`);
    }
  };
  
  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 10);
    
    // 初始化离线管理器
    this.initOfflineManager();
  };
  
  /**
   * 初始化离线管理器
   */
  private initOfflineManager = (): void => {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      this.offlineManager = OfflineManager.getInstance(context);
      console.info('[ChangeResourcesCachePathTestPage] OfflineManager initialized');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[ChangeResourcesCachePathTestPage] Failed to initialize OfflineManager:', errorMsg);
      showToast(`初始化失败: ${errorMsg}`);
    }
  };
  
  /**
   * 查询缓存大小
   */
  private queryCacheSize = async (): Promise<void> => {
    if (!this.offlineManager) {
      showToast('离线管理器未就绪');
      return;
    }
    
    try {
      // 通过列出所有离线区域并获取其状态来估算缓存大小
      const regions = await this.offlineManager.listOfflineRegions();
      let totalBytes = 0;
      let completedCount = 0;
      
      if (regions.length === 0) {
        this.cacheSize = 0;
        showToast('暂无离线数据');
        return;
      }
      
      // 遍历所有区域获取大小
      const promises = regions.map(region => {
        return new Promise<number>((resolve) => {
          region.getStatus((result: string | Record<string, number>) => {
            if (typeof result !== 'string') {
              resolve(result.completedResourceSize);
            } else {
              resolve(0);
            }
          });
        });
      });
      
      const sizes = await Promise.all(promises);
      totalBytes = sizes.reduce((sum, size) => sum + size, 0);
      
      this.cacheSize = Math.round(totalBytes / (1024 * 1024)); // 转换为 MB
      showToast(`缓存大小: ${this.cacheSize}MB`);
      console.info('[ChangeResourcesCachePathTestPage] Cache size:', this.cacheSize, 'MB');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[ChangeResourcesCachePathTestPage] Failed to query cache size:', errorMsg);
      showToast(`查询失败: ${errorMsg}`);
    }
  };
  
  /**
   * 清除缓存
   */
  private clearCache = async (): Promise<void> => {
    if (!this.offlineManager) {
      showToast('离线管理器未就绪');
      return;
    }
    
    try {
      await this.offlineManager.clearAmbientCache();
      this.cacheSize = 0;
      showToast('缓存已清除');
      console.info('[ChangeResourcesCachePathTestPage] Cache cleared');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[ChangeResourcesCachePathTestPage] Failed to clear cache:', errorMsg);
      showToast(`清除失败: ${errorMsg}`);
    }
  };
  
  @Builder
  buildMapContent() {
    MapView({
      onMapReady: this.onMapReady,
            styleUrl: DEFAULT_STYLE_URLS.bright,
            initialLatitude: 39.9,
            initialLongitude: 116.4,
            initialZoom: 10
    })
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
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      })
    }
    .width('100%')
    .height('100%')
  }
}
