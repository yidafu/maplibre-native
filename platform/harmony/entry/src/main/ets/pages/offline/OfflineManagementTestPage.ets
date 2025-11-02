/**
 * Offline Management Test Page
 * 离线地图综合管理页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/offline/OfflineActivity.kt
 * 
 * 功能:
 * - 创建离线区域
 * - 列出已有离线区域
 * - 下载进度显示
 * - 区域元数据管理
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { 
  MapLibreMap, 
  MapView, 
  LatLng,
  OfflineManager,
  OfflineRegion,
  OfflineRegionObserver,
  OfflineRegionStatus,
  OfflineRegionError,
  OfflineRegionDownloadState,
  LatLngBounds
} from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import { promptAction } from '@kit.ArkUI';
import common from '@ohos.app.ability.common';
import { util } from '@kit.ArkTS';
import maplibre from 'libmaplibre.so';

interface RegionInfo {
  region: OfflineRegion;
  name: string;
  date: string;
}

@Entry
@Component
struct OfflineManagementTestPage {
  private mapController: MapLibreMap | null = null;
  private offlineManager: OfflineManager | null = null;
  private currentDownloadRegion: OfflineRegion | null = null;
  
  @State private isDownloading: boolean = false;
  @State private downloadProgress: number = 0;
  @State private downloadedResources: number = 0;
  @State private totalResources: number = 0;
  @State private downloadedBytes: number = 0;
  @State private regionInfos: Array<RegionInfo> = [];
  @State private currentRegionName: string = '';
  
  aboutToDisappear() {
    // 停止下载
    if (this.currentDownloadRegion && this.isDownloading) {
      this.currentDownloadRegion.setDownloadState(OfflineRegionDownloadState.INACTIVE);
    }
    
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[OfflineManagementTestPage] onMapReady');
    this.mapController = map;
    map.setStyleUrl(DEFAULT_STYLE_URLS.bright);
    
    // 设置初始位置（纽约 UNHQ）
    map.jumpTo(0, 40.749851, -73.967966, 0, 14);
    
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
      console.info('[OfflineManagementTestPage] OfflineManager initialized');
      
      // 加载离线区域列表
      this.loadOfflineRegions();
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[OfflineManagementTestPage] Failed to initialize OfflineManager:', errorMsg);
      showToast(`初始化失败: ${errorMsg}`);
    }
  };
  
  /**
   * 加载离线区域列表
   */
  private loadOfflineRegions = async (): Promise<void> => {
    if (!this.offlineManager) {
      console.warn('[OfflineManagementTestPage] OfflineManager not initialized');
      return;
    }
    
    try {
      const regions = await this.offlineManager.listOfflineRegions();
      console.info(`[OfflineManagementTestPage] Found ${regions.length} offline regions`);
      
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
            date: metadata['date'] || '未知'
          });
        } catch (e) {
          // 如果元数据解析失败，使用默认名称
          this.regionInfos.push({
            region: region,
            name: `区域 ${region.id}`,
            date: '未知'
          });
        }
      }
      
      if (regions.length > 0) {
        showToast(`已加载 ${regions.length} 个离线区域`);
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[OfflineManagementTestPage] Failed to load regions:', errorMsg);
      showToast(`加载失败: ${errorMsg}`);
    }
  };
  
  /**
   * 显示下载对话框
   */
  private showDownloadDialog = (): void => {
    if (!this.mapController || !this.offlineManager) {
      showToast('地图或离线管理器未就绪');
      return;
    }
    
    if (this.isDownloading) {
      showToast('正在下载中，请稍候');
      return;
    }
    
    // 使用 TextInput 对话框获取区域名称
    promptAction.showDialog({
      title: '下载离线地图',
      message: '请输入区域名称:',
      buttons: [
        { text: '取消', color: '#999999' },
        { text: '开始下载', color: '#2196F3' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        // 获取用户输入（由于 Harmony promptAction 限制，这里使用默认名称）
        const regionName = `离线区域_${Date.now()}`;
        this.startDownload(regionName);
      }
    }).catch((error: Error) => {
      console.error('[OfflineManagementTestPage] Dialog error:', error);
    });
  };
  
  /**
   * 开始下载离线地图
   */
  private startDownload = async (regionName: string): Promise<void> => {
    if (!this.mapController || !this.offlineManager || this.isDownloading) {
      showToast('无法开始下载');
      return;
    }
    
    if (!regionName || regionName.trim() === '') {
      showToast('区域名称不能为空');
      return;
    }
    
    try {
      this.currentRegionName = regionName;
      this.isDownloading = true;
      this.downloadProgress = 0;
      this.downloadedResources = 0;
      this.totalResources = 0;
      this.downloadedBytes = 0;
      
      // 获取当前地图视图的边界
      const projection = this.mapController.getProjection();
      const visibleRegion = projection.getVisibleRegion();
      const bounds = visibleRegion.latLngBounds;
      
      // 获取缩放级别
      const zoom = this.mapController.getZoom();
      const minZoom = zoom;
      const maxZoom = Math.min(minZoom + 2, 16); // 限制最大缩放级别
      
      console.info('[OfflineManagementTestPage] Creating offline region:', {
        name: regionName,
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
      interface OfflineDefinition {
        type: string;
        styleURL: string;
        bounds: BoundsObject;
        minZoom: number;
        maxZoom: number;
        pixelRatio: number;
      }
      
      const definition: OfflineDefinition = {
        type: 'tilePyramid',
        styleURL: DEFAULT_STYLE_URLS.bright,
        bounds: boundsObj,
        minZoom: minZoom,
        maxZoom: maxZoom,
        pixelRatio: 2.0
      };
      
      // 创建元数据
      const encoder = new util.TextEncoder();
      const metadata = encoder.encodeInto(JSON.stringify({
        name: regionName,
        date: new Date().toISOString(),
        bounds: bounds.toString()
      }));
      
      // 创建离线区域
      const region = await this.offlineManager.createOfflineRegion(definition, metadata.buffer as ArrayBuffer);
      this.currentDownloadRegion = region;
      
      showToast(`开始下载: ${regionName}`);
      
      // 设置下载观察者
      const observer: OfflineRegionObserver = {
        onStatusChanged: (status: OfflineRegionStatus) => {
          this.downloadedResources = status.completedResourceCount;
          this.totalResources = status.requiredResourceCount;
          this.downloadedBytes = status.completedResourceSize;
          
          if (this.totalResources > 0) {
            this.downloadProgress = (this.downloadedResources / this.totalResources) * 100;
          }
          
          console.info('[OfflineManagementTestPage] Download progress:', {
            completed: this.downloadedResources,
            total: this.totalResources,
            percentage: this.downloadProgress.toFixed(2),
            bytes: this.downloadedBytes
          });
          
          if (status.isComplete) {
            this.onDownloadComplete();
          }
        },
        onError: (error: OfflineRegionError) => {
          console.error('[OfflineManagementTestPage] Download error:', error);
          showToast(`下载错误: ${error.message}`);
          this.isDownloading = false;
          if (this.currentDownloadRegion) {
            this.currentDownloadRegion.setDownloadState(OfflineRegionDownloadState.INACTIVE);
          }
        },
        mapboxTileCountLimitExceeded: (limit: number) => {
          console.warn('[OfflineManagementTestPage] Tile count limit exceeded:', limit);
          showToast(`瓦片数量超限: ${limit}`);
          this.isDownloading = false;
          if (this.currentDownloadRegion) {
            this.currentDownloadRegion.setDownloadState(OfflineRegionDownloadState.INACTIVE);
          }
        }
      };
      
      region.setObserver(observer);
      
      // 开始下载
      region.setDownloadState(OfflineRegionDownloadState.ACTIVE);
      
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[OfflineManagementTestPage] Failed to start download:', errorMsg);
      showToast(`下载失败: ${errorMsg}`);
      this.isDownloading = false;
    }
  };
  
  /**
   * 下载完成回调
   */
  private onDownloadComplete = (): void => {
    console.info('[OfflineManagementTestPage] Download complete');
    this.isDownloading = false;
    this.downloadProgress = 100;
    
    const bytesInMB = (this.downloadedBytes / (1024 * 1024)).toFixed(2);
    showToast(`下载完成！资源数: ${this.downloadedResources}, 大小: ${bytesInMB}MB`);
    
    // 停止下载
    if (this.currentDownloadRegion) {
      this.currentDownloadRegion.setDownloadState(OfflineRegionDownloadState.INACTIVE);
      this.currentDownloadRegion = null;
    }
    
    // 重新加载区域列表
    this.loadOfflineRegions();
  };
  
  /**
   * 显示离线区域列表
   */
  private showRegionsList = (): void => {
    if (this.regionInfos.length === 0) {
      showToast('暂无离线区域');
      return;
    }
    
    const regionNames = this.regionInfos.map((info, index) => 
      `${index + 1}. ${info.name} (${info.date})`
    ).join('\n');
    
    // 显示区域列表对话框
    promptAction.showDialog({
      title: '离线区域列表',
      message: `共 ${this.regionInfos.length} 个区域:\n\n${regionNames}`,
      buttons: [
        { text: '确定', color: '#2196F3' }
      ]
    });
  };
  
  /**
   * 删除所有离线区域
   */
  private deleteAllRegions = async (): Promise<void> => {
    if (this.regionInfos.length === 0) {
      showToast('暂无离线区域');
      return;
    }
    
    if (!this.offlineManager) {
      showToast('离线管理器未就绪');
      return;
    }
    
    promptAction.showDialog({
      title: '删除确认',
      message: `确定要删除所有 ${this.regionInfos.length} 个离线区域吗？`,
      buttons: [
        { text: '取消', color: '#999999' },
        { text: '删除', color: '#F44336' }
      ]
    }).then(async (result) => {
      if (result.index === 1) {
        try {
          // 删除所有离线区域
          for (const regionInfo of this.regionInfos) {
            await this.offlineManager!.deleteOfflineRegion(regionInfo.region);
          }
          
          this.regionInfos = [];
          showToast('已删除所有离线区域');
          console.info('[OfflineManagementTestPage] All regions deleted');
        } catch (error) {
          const errorMsg = error instanceof Error ? error.message : String(error);
          console.error('[OfflineManagementTestPage] Failed to delete regions:', errorMsg);
          showToast(`删除失败: ${errorMsg}`);
        }
      }
    }).catch((error: Error) => {
      console.error('[OfflineManagementTestPage] Dialog error:', error);
    });
  };
  
  @Builder
  actionButtonsBuilder() {
    Button('下载区域')
      .fontSize(14)
      .enabled(!this.isDownloading)
      .onClick(this.showDownloadDialog);
    
    Button('区域列表')
      .fontSize(14)
      .onClick(this.showRegionsList);
    
    Button('删除所有')
      .fontSize(14)
      .backgroundColor('#F44336')
      .enabled(this.regionInfos.length > 0 && !this.isDownloading)
      .onClick(this.deleteAllRegions);
  }
  
  @Builder
  controlPanelBuilder() {
    Column() {
      Text('离线地图管理')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 });
      
      Text(`区域数量: ${this.regionInfos.length}`)
        .fontSize(12)
        .fontColor(this.regionInfos.length > 0 ? '#4CAF50' : '#666');
      
      if (this.isDownloading) {
        Divider().margin({ top: 8, bottom: 8 });
        
        Text('下载中...')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF9800')
          .margin({ bottom: 4 });
        
        Text(`${this.currentRegionName}`)
          .fontSize(12)
          .fontColor('#666')
          .margin({ bottom: 4 });
        
        Progress({
          value: this.downloadProgress,
          total: 100,
          type: ProgressType.Linear
        })
          .width('100%')
          .height(20)
          .color('#2196F3');
        
        Text(`${this.downloadProgress.toFixed(1)}%`)
          .fontSize(12)
          .fontColor('#666')
          .margin({ top: 4 });
        
        // 下载资源信息
        if (this.totalResources > 0) {
          Column() {
            Text(`${this.downloadedResources} / ${this.totalResources} 资源`)
              .fontSize(11)
              .fontColor('#666')
              .margin({ top: 2 });
            
            Text(`大小: ${(this.downloadedBytes / (1024 * 1024)).toFixed(2)} MB`)
              .fontSize(11)
              .fontColor('#666')
              .margin({ top: 2 });
          }
          .width('100%')
        }
      } else {
        Divider().margin({ top: 8, bottom: 8 });
        
        Text('功能说明')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 4 });
        
        Text('• 下载当前视图区域')
          .fontSize(11)
          .fontColor('#666');
        
        Text('• 管理离线区域')
          .fontSize(11)
          .fontColor('#666');
        
        Text('• 实时查看下载进度')
          .fontSize(11)
          .fontColor('#666');
      }
      
      if (this.regionInfos.length > 0) {
        Column() {
          Divider().margin({ top: 8, bottom: 8 });
          
          Text('已下载区域')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 4 });
          
          ForEach(this.regionInfos.slice(-3), (regionInfo: RegionInfo, index: number) => {
            Text(`• ${regionInfo.name}`)
              .fontSize(11)
              .fontColor('#666')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
          }, (regionInfo: RegionInfo, index: number) => `region_${index}`);
          
          if (this.regionInfos.length > 3) {
            Text(`... 还有 ${this.regionInfos.length - 3} 个区域`)
              .fontSize(10)
              .fontColor('#999')
              .margin({ top: 2 });
          }
        }
        .width('100%')
      }
    }
    .alignItems(HorizontalAlign.Start);
  }
  
  @Builder
  mapContentBuilder() {
    MapView({
      styleUrl: DEFAULT_STYLE_URLS.bright,
      onMapReady: this.onMapReady,
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 10
    })
      .width('100%')
      .height('100%');
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Offline Management',
        description: '离线地图管理',
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

