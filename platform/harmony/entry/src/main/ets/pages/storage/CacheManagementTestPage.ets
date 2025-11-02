/**
 * Cache Management
 * 缓存管理
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/storage/CacheManagementActivity.kt
 * 
 * 功能：
 * - 重置数据库（Reset Database）
 * - 使环境缓存失效（Invalidate Ambient Cache）
 * - 清除环境缓存（Clear Ambient Cache）
 * - 设置最大环境缓存大小（Set Maximum Ambient Cache Size）
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, OfflineManager } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS } from '../common/TestUtils';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct CacheManagementTestPage {
  private mapController: MapLibreMap | null = null;
  private offlineManager: OfflineManager | null = null;
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State private operationStatus: string = '等待操作...';
  @State private isProcessing: boolean = false;
  
  aboutToAppear() {
    try {
      // 获取 OfflineManager 实例
      this.offlineManager = OfflineManager.getInstance(this.context);
      this.operationStatus = 'OfflineManager 已就绪';
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      this.operationStatus = `初始化失败: ${errorMsg}`;
      console.error('[CacheManagementTestPage] Failed to get OfflineManager:', errorMsg);
    }
  }
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[CacheManagementTestPage] onMapReady');
    this.mapController = map;
    map.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    map.jumpTo(0, TEST_LOCATIONS.beijing.latitude, TEST_LOCATIONS.beijing.longitude, 0, 10);
  };
  
  /**
   * 重置数据库
   */
  private resetDatabase = async (): Promise<void> => {
    if (!this.offlineManager || this.isProcessing) return;
    
    this.isProcessing = true;
    this.operationStatus = '正在重置数据库...';
    
    try {
      await this.offlineManager.resetDatabase();
      this.operationStatus = '✅ 数据库重置成功';
      showToast('数据库重置成功');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      this.operationStatus = `❌ 重置失败: ${errorMsg}`;
      showToast(`重置失败: ${errorMsg}`);
      console.error('[CacheManagementTestPage] resetDatabase failed:', errorMsg);
    } finally {
      this.isProcessing = false;
    }
  };
  
  /**
   * 使环境缓存失效
   */
  private invalidateAmbientCache = async (): Promise<void> => {
    if (!this.offlineManager || this.isProcessing) return;
    
    this.isProcessing = true;
    this.operationStatus = '正在使缓存失效...';
    
    try {
      await this.offlineManager.invalidateAmbientCache();
      this.operationStatus = '✅ 缓存失效成功';
      showToast('缓存失效成功');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      this.operationStatus = `❌ 操作失败: ${errorMsg}`;
      showToast(`操作失败: ${errorMsg}`);
      console.error('[CacheManagementTestPage] invalidateAmbientCache failed:', errorMsg);
    } finally {
      this.isProcessing = false;
    }
  };
  
  /**
   * 清除环境缓存
   */
  private clearAmbientCache = async (): Promise<void> => {
    if (!this.offlineManager || this.isProcessing) return;
    
    this.isProcessing = true;
    this.operationStatus = '正在清除缓存...';
    
    try {
      await this.offlineManager.clearAmbientCache();
      this.operationStatus = '✅ 缓存清除成功';
      showToast('缓存清除成功');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      this.operationStatus = `❌ 清除失败: ${errorMsg}`;
      showToast(`清除失败: ${errorMsg}`);
      console.error('[CacheManagementTestPage] clearAmbientCache failed:', errorMsg);
    } finally {
      this.isProcessing = false;
    }
  };
  
  /**
   * 设置最大环境缓存大小（5MB）
   */
  private setMaximumAmbientCacheSize = (): void => {
    if (!this.offlineManager || this.isProcessing) return;
    
    this.isProcessing = true;
    this.operationStatus = '正在设置缓存大小...';
    
    try {
      const maxSize = 5000000; // 5MB
      this.offlineManager.setMaximumAmbientCacheSize(maxSize);
      this.operationStatus = `✅ 最大缓存设置为: ${(maxSize / 1024 / 1024).toFixed(2)}MB`;
      showToast(`最大缓存设置为: ${(maxSize / 1024 / 1024).toFixed(2)}MB`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      this.operationStatus = `❌ 设置失败: ${errorMsg}`;
      showToast(`设置失败: ${errorMsg}`);
      console.error('[CacheManagementTestPage] setMaximumAmbientCacheSize failed:', errorMsg);
    } finally {
      this.isProcessing = false;
    }
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
      // 状态显示
      Text('操作状态')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
      
      Text(this.operationStatus)
        .fontSize(14)
        .fontColor('#666')
        .width('100%')
        .padding(8)
        .backgroundColor('#F5F5F5')
        .borderRadius(4)
      
      Divider().margin({ top: 4, bottom: 4 })
      
      // 操作按钮组
      Text('缓存操作')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .width('100%')
      
      Button('重置数据库')
        .width('100%')
        .backgroundColor('#FF6B6B')
        .onClick(() => this.resetDatabase())
        .enabled(!this.isProcessing)
      
      Button('使缓存失效')
        .width('100%')
        .backgroundColor('#FFA500')
        .onClick(() => this.invalidateAmbientCache())
        .enabled(!this.isProcessing)
      
      Button('清除环境缓存')
        .width('100%')
        .backgroundColor('#4CAF50')
        .onClick(() => this.clearAmbientCache())
        .enabled(!this.isProcessing)
      
      Button('设置最大缓存(5MB)')
        .width('100%')
        .backgroundColor('#2196F3')
        .onClick(() => this.setMaximumAmbientCacheSize())
        .enabled(!this.isProcessing)
      
      // 说明文字
      Text('⚠️ 重置数据库会删除所有离线数据')
        .fontSize(12)
        .fontColor('#FF6B6B')
        .width('100%')
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Cache Management',
        description: '缓存管理',
        showActionBar: false,
        mapContent: (): void => this.mapContentBuilder(),
        controlPanel: (): void => this.controlPanelBuilder()
      });
    }
    .width('100%')
    .height('100%');
  }
}
