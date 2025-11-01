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
 * 
 * 注意: 离线功能需要 C++ 层的 OfflineManager 支持
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapLibreMap, MapView, LatLng } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG  } from '../common/TestUtils';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct OfflineManagementTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isDownloading: boolean = false;
  @State private downloadProgress: number = 0;
  @State private offlineRegions: Array<string> = [];
  @State private regionName: string = '';
  
  aboutToDisappear() {
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
    
    // 加载离线区域列表
    this.loadOfflineRegions();
  };
  
  /**
   * 加载离线区域列表
   * 注意: 需要 OfflineManager API 支持
   */
  private loadOfflineRegions = (): void => {
    // TODO: 实现真实的离线区域加载
    // const offlineManager = OfflineManager.getInstance();
    // const regions = offlineManager.listOfflineRegions();
    
    // 模拟数据（用于演示）
    this.offlineRegions = [
      '纽约地区 (2024-10-31)',
      '上海地区 (2024-10-30)',
      '伦敦地区 (2024-10-29)'
    ]
    
    console.info(`[OfflineManagementTestPage] 已加载 ${this.offlineRegions.length} 个离线区域`);
  };
  
  /**
   * 显示下载对话框
   */
  private showDownloadDialog = (): void => {
    promptAction.showDialog({
      title: '下载离线地图',
      message: '请输入区域名称',
      buttons: [
        { text: '取消', color: '#999999' },
        { text: '确定', color: '#2196F3' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        // 用户点击了确定
        this.startDownload('当前区域');
      }
    });
  };
  
  /**
   * 开始下载离线地图
   */
  private startDownload = (regionName: string): void => {
    if (!this.mapController || this.isDownloading) {
      showToast('地图未就绪或正在下载');
      return;
    }
    
    if (!regionName || regionName.trim() === '') {
      showToast('区域名称不能为空');
      return;
    }
    
    this.regionName = regionName;
    this.isDownloading = true;
    this.downloadProgress = 0;
    
    showToast(`开始下载: ${regionName}`);
    
    // TODO: 实现真实的离线地图下载
    // const offlineManager = OfflineManager.getInstance();
    // const bounds = this.mapController.getVisibleBounds();
    // const minZoom = this.mapController.getZoom();
    // const maxZoom = this.mapController.getMaxZoom();
    // const pixelRatio = display.getDefaultDisplay().densityDPI / 160;
    //
    // const definition = new OfflineTilePyramidRegionDefinition(
    //   DEFAULT_STYLE_URLS.bright,
    //   bounds,
    //   minZoom,
    //   maxZoom,
    //   pixelRatio
    // );
    //
    // offlineManager.createOfflineRegion(definition, regionName, (region) => {
    //   region.setObserver((status) => {
    //     this.downloadProgress = status.completedResourceCount / status.requiredResourceCount * 100;
    //     if (status.isComplete) {
    //       this.onDownloadComplete();
    //     }
    //   });
    //   region.setDownloadState(OfflineRegion.STATE_ACTIVE);
    // });
    
    // 模拟下载进度
    this.simulateDownload();
  };
  
  /**
   * 模拟下载进度（用于演示）
   */
  private simulateDownload = (): void => {
    const interval = setInterval(() => {
      if (this.downloadProgress >= 100) {
        clearInterval(interval);
        this.onDownloadComplete();
        return;
      }
      
      this.downloadProgress += Math.random() * 10;
      if (this.downloadProgress > 100) {
        this.downloadProgress = 100;
      }
    }, 300);
  };
  
  /**
   * 下载完成回调
   */
  private onDownloadComplete = (): void => {
    this.isDownloading = false;
    this.downloadProgress = 100;
    showToast('下载完成！');
    
    // 添加到离线区域列表
    const date = new Date();
    const dateStr = `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`;
    this.offlineRegions.push(`${this.regionName} (${dateStr})`);
  };
  
  /**
   * 显示离线区域列表
   */
  private showRegionsList = (): void => {
    if (this.offlineRegions.length === 0) {
      showToast('暂无离线区域');
      return;
    }
    
    // 显示区域列表对话框
    promptAction.showDialog({
      title: '离线区域列表',
      message: `共 ${this.offlineRegions.length} 个区域:\n${this.offlineRegions.join('\n')}`,
      buttons: [
        { text: '确定', color: '#2196F3' }
      ]
    });
  };
  
  /**
   * 删除所有离线区域
   */
  private deleteAllRegions = (): void => {
    if (this.offlineRegions.length === 0) {
      showToast('暂无离线区域');
      return;
    }
    
    promptAction.showDialog({
      title: '删除确认',
      message: `确定要删除所有 ${this.offlineRegions.length} 个离线区域吗？`,
      buttons: [
        { text: '取消', color: '#999999' },
        { text: '删除', color: '#F44336' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        // TODO: 实现真实的删除操作
        // const offlineManager = OfflineManager.getInstance();
        // offlineManager.deleteAllOfflineRegions();
        
        this.offlineRegions = [];
        showToast('已删除所有离线区域');
      }
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
      .enabled(this.offlineRegions.length > 0 && !this.isDownloading)
      .onClick(this.deleteAllRegions);
  }
  
  @Builder
  controlPanelBuilder() {
    Column() {
      Text('离线地图管理')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 });
      
      Text(`区域数量: ${this.offlineRegions.length}`)
        .fontSize(12)
        .fontColor('#666');
      
      if (this.isDownloading) {
        Divider().margin({ top: 8, bottom: 8 });
        
        Text('下载中...')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF9800')
          .margin({ bottom: 4 });
        
        Text(`${this.regionName}`)
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
        
        Text('• 查看下载进度')
          .fontSize(11)
          .fontColor('#666');
      }
      
      if (this.offlineRegions.length > 0) {
        Divider().margin({ top: 8, bottom: 8 });
        
        Text('最近区域')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 4 });
        
        ForEach(this.offlineRegions.slice(-3), (region: string) => {
          Text(`• ${region}`)
            .fontSize(11)
            .fontColor('#666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
        }, (region: string) => region);
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
        actionButtons: this.actionButtonsBuilder,
        controlPanel: (): void => this.controlPanelBuilder(),
        mapContent: (): void => this.mapContentBuilder()
      });
    }
    .width('100%')
    .height('100%');
  }
}

