/**
 * Merge Offline Regions Test Page
 * 合并离线区域测试页面
 * 
 * 测试功能:
 * - 使用OfflineManager管理离线区域
 * - 列出和删除离线区域
 */

import { TestPageLayout } from '../common/TestPageLayout';
import {
  NativeMapView,
  MapLibreMap,
  MapLibreMapOptions,
  OfflineManager,
  OfflineRegion,
  MapView
} from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import common from '@ohos.app.ability.common';

@Entry
@Component
struct MergeOfflineRegionsTestPage {
  private mapController: MapLibreMap | null = null;
  private offlineManager: OfflineManager | null = null;
  @State private regionCount: number = 0;
  @State private regions: OfflineRegion[] = [];;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 5);
    
    this.initOfflineManager();
  };
  
  /**
   * 初始化离线管理器
   */
  private initOfflineManager = (): void => {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      this.offlineManager = OfflineManager.getInstance(context);
      this.listRegions();
      showToast('OfflineManager已初始化');
    } catch (error) {
      showToast(`初始化失败: ${error}`);
    }
  };
  
  /**
   * 列出所有离线区域
   */
  private listRegions = async (): Promise<void> => {
    if (!this.offlineManager) {
      showToast('离线管理器未就绪');
      return;
    }
    
    try {
      this.regions = await this.offlineManager.listOfflineRegions();
      this.regionCount = this.regions.length;
      
      if (this.regionCount > 0) {
        showToast(`找到 ${this.regionCount} 个离线区域`);
        console.info('[MergeOfflineRegionsTestPage] Listed regions:', this.regionCount);
      } else {
        showToast('暂无离线区域');
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[MergeOfflineRegionsTestPage] Failed to list regions:', errorMsg);
      showToast(`列出区域失败: ${errorMsg}`);
    }
  };
  
  /**
   * 删除所有区域
   */
  private deleteAllRegions = async (): Promise<void> => {
    if (!this.offlineManager) {
      showToast('离线管理器未就绪');
      return;
    }
    
    if (this.regions.length === 0) {
      showToast('暂无离线区域');
      return;
    }
    
    try {
      let successCount = 0;
      let failCount = 0;
      
      for (const region of this.regions) {
        try {
          await new Promise<void>((resolve, reject) => {
            region.delete((error?: string) => {
              if (error) {
                reject(new Error(error));
              } else {
                resolve();
              }
            });
          });
          successCount++;
        } catch (e) {
          failCount++;
          const errorMsg = e instanceof Error ? e.message : String(e);
          console.error('[MergeOfflineRegionsTestPage] Failed to delete region:', region.id, errorMsg);
        }
      }
      
      this.regions = [];
      this.regionCount = 0;
      
      if (failCount === 0) {
        showToast(`成功删除所有 ${successCount} 个离线区域`);
        console.info('[MergeOfflineRegionsTestPage] All regions deleted successfully');
      } else {
        showToast(`删除完成: 成功 ${successCount} 个，失败 ${failCount} 个`);
        console.warn('[MergeOfflineRegionsTestPage] Some regions failed to delete:', { successCount, failCount });
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[MergeOfflineRegionsTestPage] Failed to delete all regions:', errorMsg);
      showToast(`删除失败: ${errorMsg}`);
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
        Text('离线区域管理')
          .fontSize(16)
          .fontWeight(FontWeight.Bold);
        
        Row() {
          Text('区域数量:')
            .fontSize(12)
            .fontColor('#666')
            .layoutWeight(1);
          Text(`${this.regionCount}`)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.regionCount > 0 ? '#4CAF50' : '#999');
        }
        .width('100%');
        
        Button('刷新列表')
          .width('100%')
          .backgroundColor('#2196F3')
          .onClick(() => this.listRegions());
        
        Button('删除所有区域')
          .width('100%')
          .backgroundColor('#F44336')
          .enabled(this.regionCount > 0)
          .onClick(() => this.deleteAllRegions());
        
        Divider();
        
        Text('区域列表')
          .fontSize(14)
          .fontWeight(FontWeight.Bold);
        
        if (this.regions.length > 0) {
          Column({ space: 8 }) {
            ForEach(this.regions, (region: OfflineRegion, index: number) => {
              Column({ space: 4 }) {
                Row() {
                  Text(`区域 ${index + 1}`)
                    .fontSize(13)
                    .fontWeight(FontWeight.Medium)
                    .layoutWeight(1);
                  
                  Text(`ID: ${region.id}`)
                    .fontSize(10)
                    .fontColor('#999');
                }
                .width('100%');
                
                // 显示元数据（如果有）
                Text(`定义类型: ${region.definition.type || '未知'}`)
                  .fontSize(10)
                  .fontColor('#666');
              }
              .width('100%')
              .padding(10)
              .backgroundColor(index % 2 === 0 ? '#F5F5F5' : '#FAFAFA')
              .borderRadius(4)
              .border({ width: 1, color: '#E0E0E0' });
            }, (region: OfflineRegion, index: number) => `region_${region.id}_${index}`);
          }
          .width('100%');
        } else {
          Column({ space: 8 }) {
            Text('暂无离线区域')
              .fontSize(14)
              .fontColor('#999');
            
            Text('请先在其他页面下载离线地图')
              .fontSize(11)
              .fontColor('#999');
          }
          .width('100%')
          .padding(20)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('#F5F5F5')
          .borderRadius(4);
        }
        
        Divider().margin({ top: 8 });
        
        Text('说明')
          .fontSize(14)
          .fontWeight(FontWeight.Bold);
        
        Text('• 使用 OfflineManager 管理离线地图')
          .fontSize(11)
          .fontColor('#666');
        
        Text('• 支持列出和删除离线区域')
          .fontSize(11)
          .fontColor('#666');
        
        Text('• 可查看每个区域的基本信息')
          .fontSize(11)
          .fontColor('#666');
      }
      .width('100%')
      .padding(16)
      .alignItems(HorizontalAlign.Start);
    }
    .height('100%');
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Merge Offline Regions',
        description: '合并离线区域',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      })
    }
    .width('100%')
    .height('100%')
  }
}
