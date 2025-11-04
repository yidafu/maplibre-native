/**
 * Update Metadata Test Page
 * 更新元数据测试页面
 * 
 * 测试功能:
 * - 使用OfflineRegion更新元数据
 * - 获取和设置离线区域的元数据
 */

import { TestPageLayout } from '../common/TestPageLayout';
import {
  NativeMapView,
  MapLibreMap,
  MapLibreMapOptions,
  OfflineManager,
  OfflineRegion
} from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import common from '@ohos.app.ability.common';
import { util } from '@kit.ArkTS';
import { MapView } from 'maplibre_harmony';

@Entry
@Component
struct UpdateMetadataTestPage {
  private mapController: MapLibreMap | null = null;
  private offlineManager: OfflineManager | null = null;
  @State private regionName: string = '北京区域';
  @State private regionDescription: string = '北京市离线地图';
  @State private lastUpdate: string = '';
  @State private currentRegion: OfflineRegion | null = null;
  
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
  
  private initOfflineManager = (): void => {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      this.offlineManager = OfflineManager.getInstance(context);
      this.loadFirstRegion();
    } catch (error) {
      showToast(`初始化失败: ${error}`);
    }
  };
  
  /**
   * 加载第一个离线区域
   */
  private loadFirstRegion = async (): Promise<void> => {
    if (!this.offlineManager) return;
    
    try {
      const regions = await this.offlineManager.listOfflineRegions();
      if (regions.length > 0) {
        this.currentRegion = regions[0]
        await this.loadMetadata();
        showToast('已加载第一个离线区域');
      } else {
        showToast('暂无离线区域');
      }
    } catch (error) {
      showToast(`加载区域失败: ${error}`);
    }
  };
  
  /**
   * 加载元数据
   */
  private loadMetadata = async (): Promise<void> => {
    if (!this.currentRegion) return;
    
    try {
      const metadata: ArrayBuffer = this.currentRegion.metadata;
      const decoder = new util.TextDecoder('utf-8');
      const metadataStr = decoder.decodeWithStream(new Uint8Array(metadata));
      
      // 尝试解析JSON元数据
      try {
        const metadataObj: Record<string, Object> = JSON.parse(metadataStr);
        this.regionName = (metadataObj['name'] as string) || this.regionName;
        this.regionDescription = (metadataObj['description'] as string) || this.regionDescription;
      } catch {
        // 如果不是JSON，直接使用字符串
        this.regionName = metadataStr;
      }
      
      showToast('元数据已加载');
    } catch (error) {
      showToast(`加载元数据失败: ${error}`);
    }
  };
  
  /**
   * 更新元数据
   */
  private updateMetadata = async (): Promise<void> => {
    if (!this.currentRegion) {
      showToast('未选择离线区域');
      return;
    }
    
    try {
      const metadataObj: Record<string, Object> = {
        'name': this.regionName,
        'description': this.regionDescription,
        'lastUpdate': new Date().toLocaleString('zh-CN')
      };
      
      const encoder = new util.TextEncoder();
      const metadataStr = JSON.stringify(metadataObj);
      const metadataBuffer = encoder.encodeInto(metadataStr);
      
      // 使用 Promise 包装回调方式的更新操作
      await new Promise<void>((resolve, reject) => {
        this.currentRegion!.updateMetadata(metadataBuffer.buffer as ArrayBuffer, (result) => {
          if (typeof result === 'string') {
            // 错误情况
            reject(new Error(result));
          } else {
            // 成功情况
            resolve();
          }
        });
      });
      
      this.lastUpdate = metadataObj['lastUpdate'] as string;
      showToast('元数据已更新');
      console.info('[UpdateMetadataTestPage] Metadata updated successfully');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[UpdateMetadataTestPage] Failed to update metadata:', errorMsg);
      showToast(`更新元数据失败: ${errorMsg}`);
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
      Text('离线区域元数据')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Text(`当前区域: ${this.currentRegion ? '已选择' : '未选择'}`)
        .fontSize(12)
        .fontColor(this.currentRegion ? '#4CAF50' : '#666')
      
      TextInput({ text: this.regionName, placeholder: '区域名称' })
        .width('100%')
        .onChange((value: string) => {
          this.regionName = value;
        })
      
      TextInput({ text: this.regionDescription, placeholder: '区域描述' })
        .width('100%')
        .onChange((value: string) => {
          this.regionDescription = value;
        })
      
      Button('更新元数据')
        .width('100%')
        .backgroundColor('#4CAF50')
        .enabled(this.currentRegion !== null)
        .onClick(() => this.updateMetadata())
      
      Button('重新加载元数据')
        .width('100%')
        .enabled(this.currentRegion !== null)
        .onClick(() => this.loadMetadata())
      
      if (this.lastUpdate) {
        Text(`最后更新: ${this.lastUpdate}`)
          .fontSize(12)
          .fontColor('#666')
          .padding(8)
          .backgroundColor('#F5F5F5')
          .borderRadius(4)
          .width('100%')
      }
      
      Text('说明: 使用OfflineRegion.updateMetadata更新')
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
        title: 'Update Metadata',
        description: '更新元数据',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      })
    }
    .width('100%')
    .height('100%')
  }
}
