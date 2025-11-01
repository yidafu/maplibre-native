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
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 10);
    
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
    if (!this.offlineManager) return;
    
    try {
      this.regions = await this.offlineManager.listOfflineRegions();
      this.regionCount = this.regions.length;
      showToast(`找到${this.regionCount}个离线区域`);
    } catch (error) {
      showToast(`列出区域失败: ${error}`);
    }
  };
  
  /**
   * 删除所有区域
   */
  private deleteAllRegions = async (): Promise<void> => {
    if (!this.offlineManager || this.regions.length === 0) return;
    
    try {
      for (let region of this.regions) {
        await region.delete(() => {});
      }
      this.regions = [];
      this.regionCount = 0;
      showToast('所有离线区域已删除');
    } catch (error) {
      showToast(`删除失败: ${error}`);
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
    Column({ space: 12 }) {
      Text('离线区域管理')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Text(`区域数量: ${this.regionCount}`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.regionCount > 0 ? '#4CAF50' : '#666')
      
      Button('刷新列表')
        .width('100%')
        .onClick(() => this.listRegions())
      
      Button('删除所有区域')
        .width('100%')
        .backgroundColor('#FF6B6B')
        .enabled(this.regionCount > 0)
        .onClick(() => this.deleteAllRegions())
      
      Divider()
      
      Text('区域列表')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
      
      if (this.regions.length > 0) {
        Column() {
          ForEach(this.regions, (region: OfflineRegion, index: number) => {
            Text(`区域 ${index + 1}`)
              .fontSize(12)
              .width('100%')
              .padding(8)
              .backgroundColor(index % 2 === 0 ? '#F5F5F5' : '#FFFFFF')
          })
        }
        .width('100%')
        .backgroundColor('#F9F9F9')
        .border({ width: 1, color: '#DDD' })
        .borderRadius(4)
      } else {
        Text('暂无离线区域')
          .fontSize(12)
          .fontColor('#999')
          .padding(12)
      }
      
      Text('说明: 使用OfflineManager管理离线地图')
        .fontSize(12)
        .fontColor('#666')
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
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
