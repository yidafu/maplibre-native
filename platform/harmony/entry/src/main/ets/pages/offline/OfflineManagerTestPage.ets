/**
 * Offline Manager Test Page
 * 离线管理器测试页面
 * 
 * 功能:
 * - 显示离线区域统计信息
 * - 测试数据库重置功能
 * - 测试缓存清理功能
 * - 设置缓存限制
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { 
  MapView, 
  MapLibreMap,
  OfflineManager,
  OfflineRegion
} from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS, DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import { promptAction } from '@kit.ArkUI';
import common from '@ohos.app.ability.common';
import { util } from '@kit.ArkTS';

@Entry
@Component
struct OfflineManagerTestPage {
  private mapController: MapLibreMap | null = null;
  private offlineManager: OfflineManager | null = null;
  
  @State private regionCount: number = 0;
  @State private totalSize: number = 0;
  @State private cacheSize: number = 50; // MB
  @State private tileLimit: number = 6000;
  @State private isProcessing: boolean = false;
  @State private lastOperation: string = '';
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[OfflineManagerTestPage] onMapReady');
    this.mapController = map;
    map.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    
    // 设置初始位置
    map.jumpTo(0, TEST_LOCATIONS.beijing.latitude, TEST_LOCATIONS.beijing.longitude, 0, 10);
    
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
      console.info('[OfflineManagerTestPage] OfflineManager initialized');
      
      // 加载统计信息
      this.loadStatistics();
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[OfflineManagerTestPage] Failed to initialize OfflineManager:', errorMsg);
      showToast(`初始化失败: ${errorMsg}`);
    }
  };
  
  /**
   * 加载统计信息
   */
  private loadStatistics = async (): Promise<void> => {
    if (!this.offlineManager) {
      return;
    }
    
    try {
      const regions = await this.offlineManager.listOfflineRegions();
      this.regionCount = regions.length;
      
      // 计算总大小（估算）
      let totalBytes = 0;
      for (const region of regions) {
      // 获取区域状态来获取大小信息
      region.getStatus((result: string | Record<string, number>) => {
        if (typeof result !== 'string') {
          totalBytes += result.completedResourceSize;
        }
      });
      }
      
      // 延迟更新总大小以确保所有状态查询完成
      setTimeout(() => {
        this.totalSize = totalBytes;
      }, 500);
      
      console.info('[OfflineManagerTestPage] Statistics loaded:', {
        regionCount: this.regionCount,
        totalBytes
      });
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[OfflineManagerTestPage] Failed to load statistics:', errorMsg);
    }
  };
  
  /**
   * 清理环境缓存
   */
  private clearAmbientCache = async (): Promise<void> => {
    if (!this.offlineManager || this.isProcessing) {
      return;
    }
    
    promptAction.showDialog({
      title: '清理缓存',
      message: '确定要清理环境缓存吗？',
      buttons: [
        { text: '取消', color: '#999999' },
        { text: '清理', color: '#2196F3' }
      ]
    }).then(async (result) => {
      if (result.index === 1) {
        this.isProcessing = true;
        try {
          await this.offlineManager!.clearAmbientCache();
          this.lastOperation = '清理缓存成功';
          showToast('缓存已清理');
          console.info('[OfflineManagerTestPage] Ambient cache cleared');
        } catch (error) {
          const errorMsg = error instanceof Error ? error.message : String(error);
          console.error('[OfflineManagerTestPage] Failed to clear cache:', errorMsg);
          this.lastOperation = `清理缓存失败: ${errorMsg}`;
          showToast(`清理失败: ${errorMsg}`);
        } finally {
          this.isProcessing = false;
        }
      }
    }).catch((error: Error) => {
      console.error('[OfflineManagerTestPage] Dialog error:', error);
    });
  };
  
  /**
   * 使缓存失效
   */
  private invalidateAmbientCache = async (): Promise<void> => {
    if (!this.offlineManager || this.isProcessing) {
      return;
    }
    
    this.isProcessing = true;
    try {
      await this.offlineManager.invalidateAmbientCache();
      this.lastOperation = '缓存已失效';
      showToast('缓存已失效');
      console.info('[OfflineManagerTestPage] Ambient cache invalidated');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[OfflineManagerTestPage] Failed to invalidate cache:', errorMsg);
      this.lastOperation = `失效缓存失败: ${errorMsg}`;
      showToast(`操作失败: ${errorMsg}`);
    } finally {
      this.isProcessing = false;
    }
  };
  
  /**
   * 重置数据库
   */
  private resetDatabase = (): void => {
    if (!this.offlineManager || this.isProcessing) {
      return;
    }
    
    promptAction.showDialog({
      title: '重置数据库',
      message: '⚠️ 警告：此操作将删除所有离线区域和缓存数据，不可恢复！\n\n确定要继续吗？',
      buttons: [
        { text: '取消', color: '#999999' },
        { text: '重置', color: '#F44336' }
      ]
    }).then(async (result) => {
      if (result.index === 1) {
        this.isProcessing = true;
        try {
          await this.offlineManager!.resetDatabase();
          this.lastOperation = '数据库已重置';
          this.regionCount = 0;
          this.totalSize = 0;
          showToast('数据库已重置');
          console.warn('[OfflineManagerTestPage] Database reset');
          
          // 重新加载统计信息
          this.loadStatistics();
        } catch (error) {
          const errorMsg = error instanceof Error ? error.message : String(error);
          console.error('[OfflineManagerTestPage] Failed to reset database:', errorMsg);
          this.lastOperation = `重置数据库失败: ${errorMsg}`;
          showToast(`重置失败: ${errorMsg}`);
        } finally {
          this.isProcessing = false;
        }
      }
    }).catch((error: Error) => {
      console.error('[OfflineManagerTestPage] Dialog error:', error);
    });
  };
  
  /**
   * 设置最大缓存大小
   */
  private setMaxCacheSize = (): void => {
    if (!this.offlineManager || this.isProcessing) {
      return;
    }
    
    try {
      const sizeInBytes = this.cacheSize * 1024 * 1024; // 转换为字节
      this.offlineManager.setMaximumAmbientCacheSize(sizeInBytes);
      this.lastOperation = `缓存大小限制已设置为 ${this.cacheSize}MB`;
      showToast(`缓存限制: ${this.cacheSize}MB`);
      console.info('[OfflineManagerTestPage] Max cache size set:', sizeInBytes);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[OfflineManagerTestPage] Failed to set max cache size:', errorMsg);
      this.lastOperation = `设置缓存大小失败: ${errorMsg}`;
      showToast(`设置失败: ${errorMsg}`);
    }
  };
  
  /**
   * 设置瓦片数量限制
   */
  private setTileCountLimit = (): void => {
    if (!this.offlineManager || this.isProcessing) {
      return;
    }
    
    try {
      this.offlineManager.setOfflineMapboxTileCountLimit(this.tileLimit);
      this.lastOperation = `瓦片数量限制已设置为 ${this.tileLimit}`;
      showToast(`瓦片限制: ${this.tileLimit}`);
      console.info('[OfflineManagerTestPage] Tile count limit set:', this.tileLimit);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[OfflineManagerTestPage] Failed to set tile count limit:', errorMsg);
      this.lastOperation = `设置瓦片限制失败: ${errorMsg}`;
      showToast(`设置失败: ${errorMsg}`);
    }
  };
  
  @Builder
  actionButtonsBuilder() {
    Button('刷新统计')
      .fontSize(14)
      .backgroundColor('#2196F3')
      .onClick(() => this.loadStatistics());
    
    Button('清理缓存')
      .fontSize(14)
      .backgroundColor('#FF9800')
      .enabled(!this.isProcessing)
      .onClick(this.clearAmbientCache);
    
    Button('重置数据库')
      .fontSize(14)
      .backgroundColor('#F44336')
      .enabled(!this.isProcessing)
      .onClick(this.resetDatabase);
  }
  
  @Builder
  controlPanelBuilder() {
    Scroll() {
      Column({ space: 12 }) {
        Text('离线管理器')
          .fontSize(16)
          .fontWeight(FontWeight.Bold);
        
        // 统计信息
        Column({ space: 8 }) {
          Text('统计信息')
            .fontSize(14)
            .fontWeight(FontWeight.Bold);
          
          Row() {
            Text('离线区域数量:')
              .fontSize(12)
              .fontColor('#666')
              .layoutWeight(1);
            Text(`${this.regionCount}`)
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4CAF50');
          }
          .width('100%');
          
          Row() {
            Text('总大小:')
              .fontSize(12)
              .fontColor('#666')
              .layoutWeight(1);
            Text(`${(this.totalSize / (1024 * 1024)).toFixed(2)} MB`)
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4CAF50');
          }
          .width('100%');
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#F5F5F5')
        .borderRadius(4);
        
        Divider();
        
        // 缓存设置
        Column({ space: 8 }) {
          Text('缓存设置')
            .fontSize(14)
            .fontWeight(FontWeight.Bold);
          
          Row({ space: 8 }) {
            Text(`最大缓存: ${this.cacheSize} MB`)
              .fontSize(12)
              .fontColor('#666')
              .layoutWeight(1);
            
            Button('-')
              .fontSize(14)
              .width(40)
              .height(30)
              .onClick(() => {
                if (this.cacheSize > 10) {
                  this.cacheSize -= 10;
                }
              });
            
            Button('+')
              .fontSize(14)
              .width(40)
              .height(30)
              .onClick(() => {
                if (this.cacheSize < 500) {
                  this.cacheSize += 10;
                }
              });
          }
          .width('100%');
          
          Button('设置缓存大小')
            .fontSize(12)
            .width('100%')
            .height(30)
            .backgroundColor('#4CAF50')
            .onClick(this.setMaxCacheSize);
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#F5F5F5')
        .borderRadius(4);
        
        // 瓦片限制设置
        Column({ space: 8 }) {
          Text('瓦片限制')
            .fontSize(14)
            .fontWeight(FontWeight.Bold);
          
          Row({ space: 8 }) {
            Text(`瓦片数量限制: ${this.tileLimit}`)
              .fontSize(12)
              .fontColor('#666')
              .layoutWeight(1);
            
            Button('-')
              .fontSize(14)
              .width(40)
              .height(30)
              .onClick(() => {
                if (this.tileLimit > 1000) {
                  this.tileLimit -= 1000;
                }
              });
            
            Button('+')
              .fontSize(14)
              .width(40)
              .height(30)
              .onClick(() => {
                if (this.tileLimit < 50000) {
                  this.tileLimit += 1000;
                }
              });
          }
          .width('100%');
          
          Button('设置瓦片限制')
            .fontSize(12)
            .width('100%')
            .height(30)
            .backgroundColor('#4CAF50')
            .onClick(this.setTileCountLimit);
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#F5F5F5')
        .borderRadius(4);
        
        Divider();
        
        // 高级操作
        Column({ space: 8 }) {
          Text('高级操作')
            .fontSize(14)
            .fontWeight(FontWeight.Bold);
          
          Button('使缓存失效')
            .fontSize(12)
            .width('100%')
            .height(30)
            .backgroundColor('#FF9800')
            .enabled(!this.isProcessing)
            .onClick(this.invalidateAmbientCache);
          
          Text('⚠️ 使缓存失效将强制重新验证所有缓存数据')
            .fontSize(10)
            .fontColor('#999');
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FFF3E0')
        .borderRadius(4);
        
        if (this.lastOperation) {
          Divider();
          
          Text('最后操作')
            .fontSize(12)
            .fontWeight(FontWeight.Bold);
          
          Text(this.lastOperation)
            .fontSize(11)
            .fontColor('#666')
            .padding(8)
            .backgroundColor('#F5F5F5')
            .borderRadius(4)
            .width('100%');
        }
        
        Divider().margin({ top: 8 });
        
        Text('说明')
          .fontSize(14)
          .fontWeight(FontWeight.Bold);
        
        Text('• 清理缓存：删除不属于任何离线区域的缓存')
          .fontSize(11)
          .fontColor('#666');
        
        Text('• 重置数据库：删除所有离线数据（不可恢复）')
          .fontSize(11)
          .fontColor('#666');
        
        Text('• 缓存限制：设置最大缓存大小')
          .fontSize(11)
          .fontColor('#666');
        
        Text('• 瓦片限制：限制下载的最大瓦片数量')
          .fontSize(11)
          .fontColor('#666');
      }
      .width('100%')
      .padding(16)
      .alignItems(HorizontalAlign.Start);
    }
    .height('100%');
  }
  
  @Builder
  mapContentBuilder() {
    MapView({
      onMapReady: this.onMapReady,
      styleUrl: DEFAULT_STYLE_URLS.streets,
      initialLatitude: TEST_LOCATIONS.beijing.latitude,
      initialLongitude: TEST_LOCATIONS.beijing.longitude,
      initialZoom: 10
    })
      .width('100%')
      .height('100%');
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Offline Manager',
        description: '离线管理器',
        showActionBar: true,
        actionButtons: (): void => this.actionButtonsBuilder(),
        controlPanel: (): void => this.controlPanelBuilder(),
        mapContent: (): void => this.mapContentBuilder()
      });
    }
    .width('100%')
    .height('100%');
  }
}
