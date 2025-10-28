/**
 * OfflineMapTestPage - 离线地图功能测试页面
 * 
 * 演示如何使用离线地图功能
 */
import { MapLibreMap } from '../maps/MapLibreMap';
import {
  OfflineManager,
  OfflineRegion,
  getOfflineManager,
  DownloadState,
  createTilePyramidRegionDefinition,
  OfflineRegionObserver,
  OfflineRegionStatus,
  OfflineRegionError,
  OfflineTilePyramidRegionDefinition,
  CreateOfflineRegionCallback
} from '../maps/offline';
import { LatLngBounds } from '../maps/geometry/LatLngBounds';
import common from '@ohos.app.ability.common';
import { router } from '@kit.ArkUI';
import util from '@ohos.util';

// 创建离线区域回调实现
class CreateRegionCallbackImpl implements CreateOfflineRegionCallback {
  page: OfflineMapTestPage;
  
  constructor(page: OfflineMapTestPage) {
    this.page = page;
  }
  
  onCreate(region: OfflineRegion): void {
    this.page.currentRegion = region;
    this.page.statusMessage = '离线区域已创建，开始下载...';
    
    // 设置观察者监听下载进度
    this.page.setupRegionObserver(region);
    
    // 开始下载
    region.setDownloadState(DownloadState.ACTIVE);
    
    // 刷新列表
    this.page.loadOfflineRegions();
  }
  
  onError(error: string): void {
    this.page.statusMessage = `创建失败: ${error}`;
  }
}

@Entry
@Component
struct OfflineMapTestPage {
  @State title: string = '离线地图测试';
  @State offlineRegions: Array<OfflineRegion> = [];
  @State currentRegion: OfflineRegion | null = null;
  @State downloadProgress: string = '未开始';
  @State statusMessage: string = '准备就绪';
  
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private offlineManager: OfflineManager | null = null;
  private mapController: MapLibreMap | null = null;
  
  aboutToAppear() {
    // 初始化离线管理器
    this.offlineManager = getOfflineManager(this.context);
    
    // 加载现有离线区域列表
    this.loadOfflineRegions();
  }
  
  /**
   * 加载离线区域列表
   */
  public loadOfflineRegions() {
    if (!this.offlineManager) return;
    
    this.offlineManager.listOfflineRegions((result) => {
      if (typeof result === 'string') {
        this.statusMessage = `加载失败: ${result}`;
      } else {
        this.offlineRegions = result;
        this.statusMessage = `找到 ${result.length} 个离线区域`;
      }
    });
  }
  
  /**
   * 下载当前可见区域
   */
  private downloadCurrentRegion() {
    if (!this.offlineManager || !this.mapController) return;
    
    try {
      // 获取当前地图视图的参数
      const styleURL = 'https://demotiles.maplibre.org/style.json';
      const bounds = new LatLngBounds(
        40.0,  // north
        117.0, // east
        39.0,  // south
        116.0  // west
      );
      const minZoom = 10;
      const maxZoom = 14;
      const pixelRatio = 2.0;
      
      // 创建区域定义
      const definition: OfflineTilePyramidRegionDefinition = createTilePyramidRegionDefinition(
        styleURL,
        bounds,
        minZoom,
        maxZoom,
        pixelRatio,
        true
      );
      
      // 创建元数据（存储区域名称等信息）
      interface MetadataInfo {
        name: string;
        created: string;
      }
      
      const metadata: MetadataInfo = {
        name: '北京地区',
        created: new Date().toISOString()
      };
      const metadataStr = JSON.stringify(metadata);
      const encoder = new util.TextEncoder();
      const uint8Array = encoder.encodeInto(metadataStr);
      const metadataBuffer: ArrayBuffer = uint8Array.buffer as ArrayBuffer;
      
      this.statusMessage = '正在创建离线区域...';
      
      // 创建回调
      const page = this;
      const callback = new CreateRegionCallbackImpl(page);
      
      // 创建离线区域  
      this.offlineManager.createOfflineRegion(definition, metadataBuffer, callback);
    } catch (error) {
      this.statusMessage = `错误: ${error}`;
    }
  }
  
  /**
   * 设置区域观察者
   */
  public setupRegionObserver(region: OfflineRegion) {
    class ObserverImpl implements OfflineRegionObserver {
      private page: OfflineMapTestPage;
      private region: OfflineRegion;
      
      constructor(page: OfflineMapTestPage, region: OfflineRegion) {
        this.page = page;
        this.region = region;
      }
      
      onStatusChanged(status: OfflineRegionStatus): void {
        const percent = status.requiredResourceCount > 0
          ? Math.round((status.completedResourceCount / status.requiredResourceCount) * 100)
          : 0;
        
        this.page.downloadProgress = `${percent}% (${status.completedResourceCount}/${status.requiredResourceCount})`;
        
        if (status.complete) {
          this.page.statusMessage = '下载完成！';
          this.region.setDownloadState(DownloadState.INACTIVE);
        }
      }
      
      onError(error: OfflineRegionError): void {
        this.page.statusMessage = `下载错误: ${error.message}`;
      }
      
      mapboxTileCountLimitExceeded(limit: number): void {
        this.page.statusMessage = `警告: 已达到瓦片数量限制 (${limit})`;
      }
    }
    
    region.setObserver(new ObserverImpl(this, region));
  }
  
  /**
   * 删除指定区域
   */
  private deleteRegion(region: OfflineRegion) {
    const regionId = region.id;
    region.delete((error?: string) => {
      if (error) {
        this.statusMessage = `删除失败: ${error}`;
      } else {
        this.statusMessage = `区域 ${regionId} 已删除`;
        this.loadOfflineRegions();
      }
    });
  }
  
  /**
   * 暂停下载
   */
  private pauseDownload() {
    if (this.currentRegion) {
      this.currentRegion.setDownloadState(DownloadState.INACTIVE);
      this.statusMessage = '下载已暂停';
    }
  }
  
  /**
   * 恢复下载
   */
  private resumeDownload() {
    if (this.currentRegion) {
      this.currentRegion.setDownloadState(DownloadState.ACTIVE);
      this.statusMessage = '下载已恢复';
    }
  }
  
  build() {
    Column() {
      // 标题
      Text(this.title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 10 })
      
      // 状态信息
      Text(this.statusMessage)
        .fontSize(14)
        .fontColor('#666')
        .margin({ bottom: 10 })
      
      // 下载进度
      if (this.currentRegion) {
        Text(`下载进度: ${this.downloadProgress}`)
          .fontSize(14)
          .fontColor('#333')
          .margin({ bottom: 10 })
      }
      
      // 操作按钮
      Row() {
        Button('下载当前区域')
          .onClick(() => this.downloadCurrentRegion())
          .margin({ right: 10 })
        
        Button('暂停')
          .onClick(() => this.pauseDownload())
          .margin({ right: 10 })
          .enabled(this.currentRegion !== null)
        
        Button('恢复')
          .onClick(() => this.resumeDownload())
          .enabled(this.currentRegion !== null)
      }
      .margin({ bottom: 20 })
      
      // 离线区域列表
      Text(`离线区域列表 (${this.offlineRegions.length})`)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 10 })
      
      List() {
        ForEach(this.offlineRegions, (region: OfflineRegion) => {
          ListItem() {
            Row() {
              Column() {
                Text(`区域 ID: ${region.id}`)
                  .fontSize(14)
                
                Text(`样式: ${region.definition.styleURL}`)
                  .fontSize(12)
                  .fontColor('#666')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              
              Button('删除')
                .onClick(() => this.deleteRegion(region))
                .fontSize(12)
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#f5f5f5')
            .borderRadius(5)
          }
          .margin({ bottom: 10 })
        })
      }
      .height(300)
      .width('100%')
      
      // 底部操作按钮
      Row() {
        Button('刷新列表')
          .onClick(() => this.loadOfflineRegions())
          .margin({ right: 10 })
        
        Button('返回')
          .onClick(() => {
            router.back();
          })
      }
      .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }
}

