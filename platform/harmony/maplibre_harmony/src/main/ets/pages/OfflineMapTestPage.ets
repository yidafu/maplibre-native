/**
 * OfflineMapTestPage - 离线地图测试页面
 * 
 * 测试内容：
 * - 创建离线区域
 * - 下载离线地图
 * - 列出离线区域
 * - 删除离线区域
 * - 下载进度监控
 */

import { NativeMapView } from '../maps/NativeMapView';
import { OfflineManager } from '../maps/offline/OfflineManager';
import { OfflineRegion } from '../maps/offline/OfflineRegion';
import { createTilePyramidRegionDefinition } from '../maps/offline/OfflineRegionDefinition';
import type { OfflineTilePyramidRegionDefinition } from '../maps/offline/OfflineRegionDefinition';
import { DownloadState, OfflineRegionStatus } from '../maps/offline/OfflineRegionStatus';
import type { OfflineRegionObserver, OfflineRegionError } from '../maps/offline';
import { LatLngBounds } from '../maps/geometry/LatLngBounds';
import { createLatLng } from '../maps/geometry/LatLng';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../constants/HiLogConstants';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import maplibre from 'libmaplibre_native.so';
import util from '@ohos.util';
import { TestPageLayout } from '../components/TestPageLayout';

@Entry
@Component
struct OfflineMapTestPage {
  @State private mapReady: boolean = false;
  @State private offlineRegions: OfflineRegion[] = [];
  @State private downloadProgress: number = 0;
  @State private downloadStatus: string = '等待操作...';
  @State private currentRegion: OfflineRegion | null = null;
  
  private offlineManager: OfflineManager | null = null;
  
  aboutToAppear() {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      this.offlineManager = OfflineManager.getInstance(context);
      
      // 加载已有的离线区域
      this.loadOfflineRegions();
      
      hilog.info(DOMAIN, 'OfflineMapTest', 'OfflineManager initialized');
    } catch (error) {
      hilog.error(DOMAIN, 'OfflineMapTest', `Failed to initialize: ${error}`);
      promptAction.showToast({
        message: `初始化失败: ${error}`,
        duration: 2000
      });
    }
  }
  
  /**
   * 地图就绪回调
   */
  private onMapReady(mapView?: maplibre.NativeMapView): void {
    hilog.info(DOMAIN, 'OfflineMapTest', 'Map ready');
    this.mapReady = true;
  }
  
  /**
   * 加载离线区域列表
   */
  private async loadOfflineRegions(): Promise<void> {
    if (!this.offlineManager) {
      promptAction.showToast({ message: 'OfflineManager 未初始化', duration: 2000 });
      return;
    }
    
    try {
      hilog.info(DOMAIN, 'OfflineMapTest', 'Loading offline regions...');
      const regions = await this.offlineManager.listOfflineRegions();
      
      this.offlineRegions = regions;
      hilog.info(DOMAIN, 'OfflineMapTest', `Loaded ${regions.length} offline regions`);
      
      promptAction.showToast({
        message: `找到 ${regions.length} 个离线区域`,
        duration: 2000
      });
    } catch (error) {
      hilog.error(DOMAIN, 'OfflineMapTest', `Failed to load offline regions: ${error}`);
      promptAction.showToast({
        message: `加载失败: ${error}`,
        duration: 2000
      });
    }
  }
  
  /**
   * 创建杭州离线区域
   */
  private async createHangzhouOfflineRegion(): Promise<void> {
    if (!this.offlineManager) {
      promptAction.showToast({ message: 'OfflineManager 未初始化', duration: 2000 });
      return;
    }
    
    try {
      hilog.info(DOMAIN, 'OfflineMapTest', 'Creating Hangzhou offline region...');
      
      // 定义杭州区域（西湖附近）
      const southwest = createLatLng(30.23, 120.12);
      const northeast = createLatLng(30.31, 120.20);
      const bounds = LatLngBounds.fromLatLngs(southwest, northeast);
      
      const definition = createTilePyramidRegionDefinition(
        'https://demotiles.maplibre.org/style.json',
        bounds,
        10,  // minZoom
        14,  // maxZoom
        2.0, // pixelRatio
        true // includeIdeographs
      );
      
      // 创建元数据
      const metadataText = JSON.stringify({
        name: '杭州西湖',
        createdAt: Date.now()
      });
      // 使用 Uint8Array 直接创建 ArrayBuffer
      const utf8Bytes: Uint8Array = new Uint8Array(metadataText.length);
      for (let i = 0; i < metadataText.length; i++) {
        utf8Bytes[i] = metadataText.charCodeAt(i);
      }
      const metadata = utf8Bytes.buffer as ArrayBuffer;
      
      const region = await this.offlineManager.createOfflineRegion(definition, metadata);
      
      hilog.info(DOMAIN, 'OfflineMapTest', `Offline region created: ID=${region.id}`);
      
      // 设置观察者
      this.setupRegionObserver(region);
      
      // 添加到列表
      this.offlineRegions.push(region);
      this.currentRegion = region;
      
      promptAction.showToast({
        message: '离线区域创建成功！',
        duration: 2000
      });
      
    } catch (error) {
      hilog.error(DOMAIN, 'OfflineMapTest', `Failed to create offline region: ${error}`);
      promptAction.showToast({
        message: `创建失败: ${error}`,
        duration: 2000
      });
    }
  }
  
  /**
   * 选择区域
   */
  private selectRegion(region: OfflineRegion): void {
    this.currentRegion = region;
    this.setupRegionObserver(region);
    
    hilog.info(DOMAIN, 'OfflineMapTest', `Selected region: ${region.id}`);
    
      // 获取当前状态
      region.getStatus((result: OfflineRegionStatus | string) => {
        if (typeof result === 'string') {
          hilog.error(DOMAIN, 'OfflineMapTest', `Failed to get status: ${result}`);
        } else {
          this.downloadProgress = (result.completedResourceCount / result.requiredResourceCount) * 100;
          this.downloadStatus = `${result.completedResourceCount}/${result.requiredResourceCount}`;
        }
      });
  }
  
  /**
   * 设置区域观察者
   */
  private setupRegionObserver(region: OfflineRegion): void {
    const observer: OfflineRegionObserver = {
      onStatusChanged: (status: OfflineRegionStatus) => {
        const progress = (status.completedResourceCount / status.requiredResourceCount) * 100;
        this.downloadProgress = progress;
        this.downloadStatus = `${status.completedResourceCount}/${status.requiredResourceCount}`;
        
        hilog.info(DOMAIN, 'OfflineMapTest', 
          `Progress: ${progress.toFixed(1)}% ` +
          `(${status.completedResourceCount}/${status.requiredResourceCount})`);
        
        if (status.complete) {
          const toastOptions: promptAction.ShowToastOptions = {
            message: '下载完成！',
            duration: 2000
          };
          promptAction.showToast(toastOptions);
        }
      },
      
      onError: (error: OfflineRegionError) => {
        this.downloadStatus = `错误: ${error.message}`;
        
        hilog.error(DOMAIN, 'OfflineMapTest', `Download error: ${error.message}`);
        
        const toastOptions: promptAction.ShowToastOptions = {
          message: `下载错误: ${error.message}`,
          duration: 3000
        };
        promptAction.showToast(toastOptions);
      },
      
      mapboxTileCountLimitExceeded: (limit: number) => {
        this.downloadStatus = `超出瓦片数量限制: ${limit}`;
        
        hilog.warn(DOMAIN, 'OfflineMapTest', `Tile count limit exceeded: ${limit}`);
        
        const toastOptions: promptAction.ShowToastOptions = {
          message: `超出瓦片限制: ${limit}`,
          duration: 3000
        };
        promptAction.showToast(toastOptions);
      }
    };
    
    region.setObserver(observer);
  }
  
  /**
   * 开始下载
   */
  private startDownload(): void {
    if (!this.currentRegion) {
      promptAction.showToast({ message: '请先选择或创建离线区域', duration: 2000 });
      return;
    }
    
    try {
      this.currentRegion.setDownloadState(DownloadState.ACTIVE);
      this.downloadStatus = '开始下载...';
      
      hilog.info(DOMAIN, 'OfflineMapTest', 'Download started');
      
      const toastOptions: promptAction.ShowToastOptions = {
        message: '开始下载离线地图',
        duration: 2000
      };
      promptAction.showToast(toastOptions);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, 'OfflineMapTest', `Failed to start download: ${errorMsg}`);
      const toastOptions: promptAction.ShowToastOptions = {
        message: `启动下载失败: ${errorMsg}`,
        duration: 2000
      };
      promptAction.showToast(toastOptions);
    }
  }
  
  /**
   * 暂停下载
   */
  private pauseDownload(): void {
    if (!this.currentRegion) return;
    
    try {
      this.currentRegion.setDownloadState(DownloadState.INACTIVE);
      this.downloadStatus = '下载已暂停';
      
      hilog.info(DOMAIN, 'OfflineMapTest', 'Download paused');
      
      const toastOptions: promptAction.ShowToastOptions = {
        message: '下载已暂停',
        duration: 2000
      };
      promptAction.showToast(toastOptions);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, 'OfflineMapTest', `Failed to pause download: ${errorMsg}`);
    }
  }
  
  /**
   * 恢复下载
   */
  private resumeDownload(): void {
    if (!this.currentRegion) return;
    
    try {
      this.currentRegion.setDownloadState(DownloadState.ACTIVE);
      this.downloadStatus = '下载已恢复';
      
      hilog.info(DOMAIN, 'OfflineMapTest', 'Download resumed');
      
      const toastOptions: promptAction.ShowToastOptions = {
        message: '下载已恢复',
        duration: 2000
      };
      promptAction.showToast(toastOptions);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, 'OfflineMapTest', `Failed to resume download: ${errorMsg}`);
    }
  }
  
  /**
   * 删除当前区域
   */
  private async deleteCurrentRegion(): Promise<void> {
    if (!this.currentRegion) return;
    
    const regionId = this.currentRegion.id;
    
    hilog.info(DOMAIN, 'OfflineMapTest', `Deleting region: ${regionId}`);
    
    this.currentRegion.delete((error?: string) => {
      if (error) {
        hilog.error(DOMAIN, 'OfflineMapTest', `Failed to delete region: ${error}`);
        const toastOptions: promptAction.ShowToastOptions = {
          message: `删除失败: ${error}`,
          duration: 2000
        };
        promptAction.showToast(toastOptions);
      } else {
        // 从列表中移除
        this.offlineRegions = this.offlineRegions.filter(r => r.id !== regionId);
        this.currentRegion = null;
        this.downloadProgress = 0;
        this.downloadStatus = '区域已删除';
        
        hilog.info(DOMAIN, 'OfflineMapTest', 'Region deleted successfully');
        
        const toastOptions: promptAction.ShowToastOptions = {
          message: '离线区域已删除',
          duration: 2000
        };
        promptAction.showToast(toastOptions);
      }
    });
  }
  
  /**
   * 获取区域元数据文本
   */
  private getRegionMetadataText(region: OfflineRegion): string {
    try {
      const metadata = region.metadata;
      const uint8Array = new Uint8Array(metadata);
      // 简单的 UTF-8 解码
      let text = '';
      for (let i = 0; i < uint8Array.length; i++) {
        text += String.fromCharCode(uint8Array[i]);
      }
      interface MetadataJson {
        name?: string;
        createdAt?: number;
      }
      const json: MetadataJson = JSON.parse(text) as MetadataJson;
      return json.name || `区域 ${region.id}`;
    } catch {
      return `区域 ${region.id}`;
    }
  }

  @Builder
  MapAreaBuilder() {
    NativeMapView({
      styleUrl: 'https://demotiles.maplibre.org/style.json',
      initialLatitude: 30.2741,
      initialLongitude: 120.1551,
      initialZoom: 10,
      initialBearing: 0,
      initialPitch: 0,
      onMapReady: (mapView?: maplibre.NativeMapView) => {
        this.onMapReady(mapView);
      }
    })
    .width('100%')
    .height('100%')
  }

  @Builder
  ControlAreaBuilder() {
    Text('离线地图管理')
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .width('100%')
    
    Button('创建杭州离线区域')
      .width('100%')
      .onClick(() => {
        this.createHangzhouOfflineRegion();
      })
    
    Button('刷新离线区域列表')
      .width('100%')
      .onClick(() => {
        this.loadOfflineRegions();
      })
    
    Divider()
    
    Text('下载控制')
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .width('100%')
    
    Row() {
      Button('开始下载')
        .width('48%')
        .onClick(() => {
          this.startDownload();
        })
        .enabled(this.currentRegion !== null)
      
      Button('暂停')
        .width('48%')
        .margin({ left: 8 })
        .onClick(() => {
          this.pauseDownload();
        })
        .enabled(this.currentRegion !== null)
    }
    .width('100%')
    
    Row() {
      Button('恢复')
        .width('48%')
        .onClick(() => {
          this.resumeDownload();
        })
        .enabled(this.currentRegion !== null)
      
      Button('删除区域')
        .width('48%')
        .margin({ left: 8 })
        .backgroundColor('#FF6B6B')
        .onClick(() => {
          this.deleteCurrentRegion();
        })
        .enabled(this.currentRegion !== null)
    }
    .width('100%')
    
    Divider()
    
    Text('下载状态')
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .width('100%')
    
    Text(this.downloadStatus)
      .fontSize(14)
      .width('100%')
      .fontColor(Color.Gray)
    
    Progress({
      value: this.downloadProgress,
      total: 100,
      type: ProgressType.Linear
    })
    .width('100%')
    .color('#007AFF')
    
    Text(`${this.downloadProgress.toFixed(1)}%`)
      .fontSize(14)
      .width('100%')
    
    Divider()
    
    Text(`离线区域列表 (${this.offlineRegions.length})`)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .width('100%')
    
    ForEach(this.offlineRegions, (region: OfflineRegion, index: number) => {
      Row() {
        Column({ space: 4 }) {
          Text(`区域 ${region.id}`)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
          
          Text(this.getRegionMetadataText(region))
            .fontSize(12)
            .fontColor(Color.Gray)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        
        Button('选择')
          .fontSize(12)
          .onClick(() => {
            this.selectRegion(region);
          })
      }
      .width('100%')
      .padding(12)
      .backgroundColor(this.currentRegion === region ? '#E3F2FD' : '#F5F5F5')
      .borderRadius(8)
    }, (region: OfflineRegion) => region.id.toString())
  }

  build() {
    Navigation() {
      TestPageLayout({
        title: '离线地图测试',
        mapArea: (): void => this.MapAreaBuilder(),
        controlArea: (): void => this.ControlAreaBuilder()
      })
    }
    .hideTitleBar(true)
  }
}
