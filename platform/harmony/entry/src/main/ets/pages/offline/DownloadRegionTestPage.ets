/**
 * Download Region Test Page
 * 下载离线区域测试页面
 * 
 * 参考: platform/ios/app-swift/Sources/OfflinePackExample.swift
 * 
 * 功能:
 * - 输入区域名称
 * - 下载当前视图区域
 * - 实时显示下载进度
 * - 显示下载详细信息（瓦片数、字节数等）
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { 
  MapView, 
  MapLibreMap,
  OfflineManager,
  OfflineRegion,
  OfflineRegionObserver,
  OfflineRegionStatus,
  OfflineRegionError,
  OfflineRegionDownloadState
} from 'maplibre_harmony';
import type { OfflineTilePyramidRegionDefinition } from 'libmaplibre.so';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS, DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import common from '@ohos.app.ability.common';
import { util } from '@kit.ArkTS';
import maplibre from 'libmaplibre.so';

@Entry
@Component
struct DownloadRegionTestPage {
  private mapController: MapLibreMap | null = null;
  private offlineManager: OfflineManager | null = null;
  currentRegion: OfflineRegion | null = null;
  
  @State regionName: string = '';
  @State isDownloading: boolean = false;
  @State downloadProgress: number = 0;
  @State completedResources: number = 0;
  @State totalResources: number = 0;
  @State completedBytes: number = 0;
  @State private isComplete: boolean = false;
  @State downloadSpeed: string = '0 KB/s';
  
  lastBytes: number = 0;
  lastTime: number = Date.now();
  
  aboutToDisappear() {
    // 停止下载
    if (this.currentRegion && this.isDownloading) {
      this.currentRegion.setDownloadState(OfflineRegionDownloadState.INACTIVE);
    }
    
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[DownloadRegionTestPage] onMapReady');
    this.mapController = map;
    // 设置初始位置（北京）
    map.jumpTo(0, TEST_LOCATIONS.beijing.latitude, TEST_LOCATIONS.beijing.longitude, 0, 12);
    
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
      console.info('[DownloadRegionTestPage] OfflineManager initialized');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[DownloadRegionTestPage] Failed to initialize OfflineManager:', errorMsg);
      showToast(`初始化失败: ${errorMsg}`);
    }
  };
  
  /**
   * 开始下载
   */
  private startDownload = async (): Promise<void> => {
    if (!this.mapController || !this.offlineManager) {
      showToast('地图或离线管理器未就绪');
      return;
    }
    
    if (this.isDownloading) {
      showToast('正在下载中');
      return;
    }
    
    const name = this.regionName.trim() || `北京区域_${Date.now()}`;
    
    try {
      this.isDownloading = true;
      this.isComplete = false;
      this.downloadProgress = 0;
      this.completedResources = 0;
      this.totalResources = 0;
      this.completedBytes = 0;
      this.lastBytes = 0;
      this.lastTime = Date.now();
      
      // 获取当前地图视图的边界
      const projection = this.mapController.getProjection();
      const visibleRegion = projection.getVisibleRegion();
      const bounds = visibleRegion.latLngBounds;
      
      // 获取缩放级别
      const zoom = this.mapController.getZoom();
      const minZoom = zoom;
      const maxZoom = Math.min(minZoom + 2, 14); // 限制最大缩放级别
      
      console.info('[DownloadRegionTestPage] Creating offline region:', {
        name,
        bounds: bounds.toString(),
        minZoom,
        maxZoom
      });
      
      // 创建离线区域定义的边界对象
      interface BoundsObject {
        north: number;
        east: number;
        south: number;
        west: number;
      }
      
      const boundsObj: BoundsObject = {
        north: bounds.north,
        east: bounds.east,
        south: bounds.south,
        west: bounds.west
      };
      
      // 创建离线区域定义
      const definition: OfflineTilePyramidRegionDefinition = {
        type: 'tilePyramid',
        styleURL: DEFAULT_STYLE_URLS.streets,
        bounds: boundsObj,
        minZoom: minZoom,
        maxZoom: maxZoom,
        pixelRatio: 2.0,
        includeIdeographs: false
      };
      
      // 创建元数据
      const encoder = new util.TextEncoder();
      const metadata = encoder.encodeInto(JSON.stringify({
        name: name,
        date: new Date().toISOString(),
        minZoom: minZoom,
        maxZoom: maxZoom
      }));
      
      // 创建离线区域
      const region = await this.offlineManager.createOfflineRegion(definition, metadata.buffer as ArrayBuffer);
      this.currentRegion = region;
      
      showToast(`开始下载: ${name}`);
      
      // 设置下载观察者（直接使用对象字面量避免 ArkTS 结构类型问题）
      region.setObserver({
        onStatusChanged: (status: OfflineRegionStatus) => {
          this.completedResources = status.completedResourceCount;
          this.totalResources = status.requiredResourceCount;
          this.completedBytes = status.completedResourceSize;
          
          if (this.totalResources > 0) {
            this.downloadProgress = (this.completedResources / this.totalResources) * 100;
          }
          
          // 计算下载速度
          const now = Date.now();
          const timeDiff = now - this.lastTime;
          if (timeDiff >= 1000) { // 每秒更新一次速度
            const bytesDiff = this.completedBytes - this.lastBytes;
            const speedKBps = (bytesDiff / timeDiff); // KB/s
            this.downloadSpeed = speedKBps < 1024 
              ? `${speedKBps.toFixed(2)} KB/s`
              : `${(speedKBps / 1024).toFixed(2)} MB/s`;
            
            this.lastBytes = this.completedBytes;
            this.lastTime = now;
          }
          
          if (status.complete) {
            this.onDownloadComplete();
          }
        },
        onError: (error: OfflineRegionError) => {
          console.error('[DownloadRegionTestPage] Download error:', error);
          showToast(`下载错误: ${error.message}`);
          this.isDownloading = false;
          if (this.currentRegion) {
            this.currentRegion.setDownloadState(OfflineRegionDownloadState.INACTIVE);
          }
        },
        mapboxTileCountLimitExceeded: (limit: number) => {
          console.warn('[DownloadRegionTestPage] Tile count limit exceeded:', limit);
          showToast(`瓦片数量超限: ${limit}`);
          this.isDownloading = false;
          if (this.currentRegion) {
            this.currentRegion.setDownloadState(OfflineRegionDownloadState.INACTIVE);
          }
        }
      });
      
      // 开始下载
      region.setDownloadState(OfflineRegionDownloadState.ACTIVE);
      
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[DownloadRegionTestPage] Failed to start download:', errorMsg);
      showToast(`下载失败: ${errorMsg}`);
      this.isDownloading = false;
    }
  };
  
  /**
   * 暂停/继续下载
   */
  private toggleDownload = (): void => {
    if (!this.currentRegion) {
      showToast('没有正在下载的区域');
      return;
    }
    
    if (this.isDownloading) {
      this.currentRegion.setDownloadState(OfflineRegionDownloadState.INACTIVE);
      this.isDownloading = false;
      showToast('下载已暂停');
    } else {
      this.currentRegion.setDownloadState(OfflineRegionDownloadState.ACTIVE);
      this.isDownloading = true;
      this.lastBytes = this.completedBytes;
      this.lastTime = Date.now();
      showToast('下载已继续');
    }
  };
  
  /**
   * 下载完成回调
   */
  onDownloadComplete = (): void => {
    console.info('[DownloadRegionTestPage] Download complete');
    this.isDownloading = false;
    this.isComplete = true;
    this.downloadProgress = 100;
    
    const bytesInMB = (this.completedBytes / (1024 * 1024)).toFixed(2);
    showToast(`下载完成！资源数: ${this.completedResources}, 大小: ${bytesInMB}MB`);
    
    // 停止下载
    if (this.currentRegion) {
      this.currentRegion.setDownloadState(OfflineRegionDownloadState.INACTIVE);
    }
  };
  
  @Builder
  actionButtonsBuilder() {
    Button(this.isDownloading || this.isComplete ? '重新下载' : '开始下载')
      .fontSize(14)
      .backgroundColor('#4CAF50')
      .onClick(() => {
        if (this.isDownloading) {
          showToast('请先暂停当前下载');
        } else {
          this.startDownload();
        }
      });
    
    if (this.currentRegion && !this.isComplete) {
      Button(this.isDownloading ? '暂停' : '继续')
        .fontSize(14)
        .backgroundColor(this.isDownloading ? '#FF9800' : '#2196F3')
        .onClick(this.toggleDownload);
    }
  }
  
  @Builder
  controlPanelBuilder() {
    Column({ space: 12 }) {
      Text('下载离线区域')
        .fontSize(16)
        .fontWeight(FontWeight.Bold);
      
      // 区域名称输入
      Column({ space: 4 }) {
        Text('区域名称')
          .fontSize(12)
          .fontColor('#666')
          .alignSelf(ItemAlign.Start);
        
        TextInput({ placeholder: '输入区域名称（可选）', text: this.regionName })
          .width('100%')
          .onChange((value: string) => {
            this.regionName = value;
          })
          .enabled(!this.isDownloading);
      }
      
      Divider();
      
      // 下载进度
      if (this.isDownloading || this.isComplete) {
        Text(this.isComplete ? '下载完成' : '下载中...')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isComplete ? '#4CAF50' : '#FF9800');
        
        Progress({
          value: this.downloadProgress,
          total: 100,
          type: ProgressType.Linear
        })
          .width('100%')
          .height(20)
          .color(this.isComplete ? '#4CAF50' : '#2196F3');
        
        Text(`${this.downloadProgress.toFixed(1)}%`)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333');
        
        Column({ space: 4 }) {
          Text(`资源: ${this.completedResources} / ${this.totalResources}`)
            .fontSize(11)
            .fontColor('#666');
          
          Text(`大小: ${(this.completedBytes / (1024 * 1024)).toFixed(2)} MB`)
            .fontSize(11)
            .fontColor('#666');
          
          if (this.isDownloading) {
            Text(`速度: ${this.downloadSpeed}`)
              .fontSize(11)
              .fontColor('#666');
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start);
      } else {
        Text('说明')
          .fontSize(14)
          .fontWeight(FontWeight.Bold);
        
        Text('• 输入区域名称（可选）')
          .fontSize(11)
          .fontColor('#666');
        
        Text('• 点击"开始下载"下载当前视图区域')
          .fontSize(11)
          .fontColor('#666');
        
        Text('• 支持暂停和继续下载')
          .fontSize(11)
          .fontColor('#666');
      }
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start);
  }
  
  @Builder
  mapContentBuilder() {
    MapView({
      onMapReady: this.onMapReady,
      styleUrl: DEFAULT_STYLE_URLS.streets,
      initialLatitude: TEST_LOCATIONS.beijing.latitude,
      initialLongitude: TEST_LOCATIONS.beijing.longitude,
      initialZoom: 12
    })
      .width('100%')
      .height('100%');
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Download Region',
        description: '下载离线区域',
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
