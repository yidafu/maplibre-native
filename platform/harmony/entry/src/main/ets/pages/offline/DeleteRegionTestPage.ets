/**
 * Delete Region Test Page
 * 删除离线区域测试页面
 * 
 * 功能:
 * - 列出所有离线区域
 * - 显示区域详细信息
 * - 选择并删除单个区域
 * - 删除确认对话框
 * - 删除所有区域
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

interface RegionInfo {
  region: OfflineRegion;
  name: string;
  date: string;
  id: number;
}

@Entry
@Component
struct DeleteRegionTestPage {
  private mapController: MapLibreMap | null = null;
  private offlineManager: OfflineManager | null = null;
  
  @State private regionInfos: Array<RegionInfo> = [];
  @State private selectedIndex: number = -1;
  @State private isLoading: boolean = false;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[DeleteRegionTestPage] onMapReady');
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
      console.info('[DeleteRegionTestPage] OfflineManager initialized');
      
      // 加载离线区域列表
      this.loadRegions();
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[DeleteRegionTestPage] Failed to initialize OfflineManager:', errorMsg);
      showToast(`初始化失败: ${errorMsg}`);
    }
  };
  
  /**
   * 加载离线区域列表
   */
  private loadRegions = async (): Promise<void> => {
    if (!this.offlineManager) {
      console.warn('[DeleteRegionTestPage] OfflineManager not initialized');
      return;
    }
    
    this.isLoading = true;
    this.selectedIndex = -1;
    
    try {
      const regions = await this.offlineManager.listOfflineRegions();
      console.info(`[DeleteRegionTestPage] Found ${regions.length} offline regions`);
      
      // 解析区域元数据
      this.regionInfos = [];
      const decoder = new util.TextDecoder('utf-8');
      
      for (const region of regions) {
        try {
          const metadataStr = decoder.decodeWithStream(new Uint8Array(region.metadata));
          const metadata = JSON.parse(metadataStr) as Record<string, string>;
          this.regionInfos.push({
            region: region,
            name: metadata['name'] || `区域 ${region.id}`,
            date: metadata['date'] || '未知',
            id: region.id
          });
        } catch (e) {
          // 如果元数据解析失败，使用默认名称
          this.regionInfos.push({
            region: region,
            name: `区域 ${region.id}`,
            date: '未知',
            id: region.id
          });
        }
      }
      
      showToast(regions.length > 0 ? `已加载 ${regions.length} 个离线区域` : '暂无离线区域');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[DeleteRegionTestPage] Failed to load regions:', errorMsg);
      showToast(`加载失败: ${errorMsg}`);
    } finally {
      this.isLoading = false;
    }
  };
  
  /**
   * 选择区域
   */
  private selectRegion = (index: number): void => {
    this.selectedIndex = index;
    const regionInfo = this.regionInfos[index];
    console.info('[DeleteRegionTestPage] Selected region:', regionInfo.name);
  };
  
  /**
   * 删除选中的区域
   */
  private deleteSelectedRegion = (): void => {
    if (this.selectedIndex < 0 || this.selectedIndex >= this.regionInfos.length) {
      showToast('请先选择要删除的区域');
      return;
    }
    
    if (!this.offlineManager) {
      showToast('离线管理器未就绪');
      return;
    }
    
    const regionInfo = this.regionInfos[this.selectedIndex];
    
    // 显示确认对话框
    promptAction.showDialog({
      title: '确认删除',
      message: `确定要删除 "${regionInfo.name}" 吗？`,
      buttons: [
        { text: '取消', color: '#999999' },
        { text: '删除', color: '#F44336' }
      ]
    }).then(async (result) => {
      if (result.index === 1) {
        try {
          await this.offlineManager!.deleteOfflineRegion(regionInfo.region);
          showToast(`已删除: ${regionInfo.name}`);
          console.info('[DeleteRegionTestPage] Region deleted:', regionInfo.name);
          
          // 重新加载区域列表
          this.loadRegions();
        } catch (error) {
          const errorMsg = error instanceof Error ? error.message : String(error);
          console.error('[DeleteRegionTestPage] Failed to delete region:', errorMsg);
          showToast(`删除失败: ${errorMsg}`);
        }
      }
    }).catch((error: Error) => {
      console.error('[DeleteRegionTestPage] Dialog error:', error);
    });
  };
  
  /**
   * 删除所有区域
   */
  private deleteAllRegions = (): void => {
    if (this.regionInfos.length === 0) {
      showToast('暂无离线区域');
      return;
    }
    
    if (!this.offlineManager) {
      showToast('离线管理器未就绪');
      return;
    }
    
    // 显示确认对话框
    promptAction.showDialog({
      title: '确认删除所有',
      message: `确定要删除所有 ${this.regionInfos.length} 个离线区域吗？此操作不可恢复！`,
      buttons: [
        { text: '取消', color: '#999999' },
        { text: '全部删除', color: '#F44336' }
      ]
    }).then(async (result) => {
      if (result.index === 1) {
        try {
          let successCount = 0;
          let failCount = 0;
          
          for (const regionInfo of this.regionInfos) {
            try {
              await this.offlineManager!.deleteOfflineRegion(regionInfo.region);
              successCount++;
            } catch (e) {
              failCount++;
              console.error('[DeleteRegionTestPage] Failed to delete region:', regionInfo.name, e);
            }
          }
          
          if (failCount === 0) {
            showToast(`成功删除所有 ${successCount} 个离线区域`);
          } else {
            showToast(`删除完成: 成功 ${successCount} 个，失败 ${failCount} 个`);
          }
          
          console.info('[DeleteRegionTestPage] All regions deleted:', { successCount, failCount });
          
          // 重新加载区域列表
          this.loadRegions();
        } catch (error) {
          const errorMsg = error instanceof Error ? error.message : String(error);
          console.error('[DeleteRegionTestPage] Failed to delete all regions:', errorMsg);
          showToast(`删除失败: ${errorMsg}`);
        }
      }
    }).catch((error: Error) => {
      console.error('[DeleteRegionTestPage] Dialog error:', error);
    });
  };
  
  @Builder
  actionButtonsBuilder() {
    Button('刷新列表')
      .fontSize(14)
      .backgroundColor('#2196F3')
      .onClick(() => this.loadRegions());
    
    Button('删除选中')
      .fontSize(14)
      .backgroundColor('#FF9800')
      .enabled(this.selectedIndex >= 0)
      .onClick(this.deleteSelectedRegion);
    
    Button('删除所有')
      .fontSize(14)
      .backgroundColor('#F44336')
      .enabled(this.regionInfos.length > 0)
      .onClick(this.deleteAllRegions);
  }
  
  @Builder
  controlPanelBuilder() {
    Scroll() {
      Column({ space: 12 }) {
        Text('离线区域列表')
          .fontSize(16)
          .fontWeight(FontWeight.Bold);
        
        Text(`共 ${this.regionInfos.length} 个区域`)
          .fontSize(12)
          .fontColor(this.regionInfos.length > 0 ? '#4CAF50' : '#999');
        
        if (this.selectedIndex >= 0) {
          Text(`已选择: ${this.regionInfos[this.selectedIndex].name}`)
            .fontSize(12)
            .fontColor('#2196F3')
            .fontWeight(FontWeight.Bold);
        }
        
        Divider();
        
        if (this.isLoading) {
          Text('加载中...')
            .fontSize(14)
            .fontColor('#666');
        } else if (this.regionInfos.length === 0) {
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
          .alignItems(HorizontalAlign.Center);
        } else {
          // 区域列表
          Column({ space: 8 }) {
            ForEach(this.regionInfos, (regionInfo: RegionInfo, index: number) => {
              Column({ space: 4 }) {
                Row() {
                  Text(`${index + 1}. ${regionInfo.name}`)
                    .fontSize(13)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.selectedIndex === index ? '#2196F3' : '#333')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1);
                  
                  if (this.selectedIndex === index) {
                    Text('✓')
                      .fontSize(16)
                      .fontColor('#2196F3')
                      .fontWeight(FontWeight.Bold);
                  }
                }
                .width('100%');
                
                Text(`创建时间: ${regionInfo.date}`)
                  .fontSize(10)
                  .fontColor('#999');
                
                Text(`ID: ${regionInfo.id}`)
                  .fontSize(10)
                  .fontColor('#999');
              }
              .width('100%')
              .padding(12)
              .backgroundColor(this.selectedIndex === index ? '#E3F2FD' : '#F5F5F5')
              .borderRadius(4)
              .border({ 
                width: this.selectedIndex === index ? 2 : 1, 
                color: this.selectedIndex === index ? '#2196F3' : '#DDD' 
              })
              .onClick(() => this.selectRegion(index));
            }, (regionInfo: RegionInfo) => `region_${regionInfo.id}`);
          }
          .width('100%');
        }
        
        Divider().margin({ top: 8 });
        
        Text('说明')
          .fontSize(14)
          .fontWeight(FontWeight.Bold);
        
        Text('• 点击区域可选中')
          .fontSize(11)
          .fontColor('#666');
        
        Text('• 点击"删除选中"删除单个区域')
          .fontSize(11)
          .fontColor('#666');
        
        Text('• 点击"删除所有"删除全部区域')
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
        title: 'Delete Region',
        description: '删除离线区域',
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
