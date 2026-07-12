/**
 * Debug Mode Test Page
 * 调试模式测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/maplayout/DebugModeActivity.kt
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, CameraPosition, LatLng, MapDebugOptions, RenderingStats } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct DebugModeTestPage {
  private mapView: MapLibreMap | null = null;
  @State private isDebugEnabled: boolean = false;
  @State private showTileBoundaries: boolean = false;
  @State private showCollisionBoxes: boolean = false;
  @State private showTileInfo: boolean = false;
  @State private showTimestamps: boolean = false;
  @State private showOverdraw: boolean = false;
  @State private renderingStatsEnabled: boolean = false;
  @State private actionJournalLogFiles: string = '';
  @State private actionJournalEntries: string = '';
  // Frame stats listener ID for cleanup
  private statsListenerId: number = 0;

  aboutToDisappear() {
    if (this.mapView) {
      this.mapView.destroy();
      this.mapView = null;
    }
  }

  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[DebugModeTestPage] onMapReady');
    this.mapView = map;
    // 设置初始相机位置
    map.jumpTo(0, 39.9042, 116.4074, 0, 6);
  };
  
  /**
   * 更新调试选项
   */
  private updateDebugOptions = (): void => {
    if (!this.mapView) return;
    
    let options = MapDebugOptions.NoDebug;
    
    if (this.showTileBoundaries) {
      options |= MapDebugOptions.TileBoundaries;
    }
    if (this.showCollisionBoxes) {
      options |= MapDebugOptions.CollisionBoxes;
    }
    if (this.showTileInfo) {
      options |= MapDebugOptions.TileInfo;
    }
    if (this.showTimestamps) {
      options |= MapDebugOptions.Timestamps;
    }
    if (this.showOverdraw) {
      options |= MapDebugOptions.OverdrawVisualization;
    }
    
    this.mapView.setDebugOptions(options);
    
    // 更新 isDebugEnabled 状态
    this.isDebugEnabled = this.mapView.isDebugActive();
  };
  
  /**
   * 快速切换调试模式（使用默认选项）
   */
  private toggleDebugMode = (): void => {
    if (!this.mapView) return;
    
    this.isDebugEnabled = !this.isDebugEnabled;
    this.mapView.setDebugActive(this.isDebugEnabled);
    
    // 同步各个选项的状态
    const currentOptions = this.mapView.getDebugOptions();
    this.showTileBoundaries = (currentOptions & MapDebugOptions.TileBoundaries) !== 0;
    this.showCollisionBoxes = (currentOptions & MapDebugOptions.CollisionBoxes) !== 0;
    this.showTileInfo = (currentOptions & MapDebugOptions.TileInfo) !== 0;
    this.showTimestamps = (currentOptions & MapDebugOptions.Timestamps) !== 0;
    this.showOverdraw = (currentOptions & MapDebugOptions.OverdrawVisualization) !== 0;
    
    showToast(`调试模式: ${this.isDebugEnabled ? '开启' : '关闭'}`);
  };
  
  /**
   * 切换瓦片边界显示
   */
  private toggleTileBoundaries = (): void => {
    this.showTileBoundaries = !this.showTileBoundaries;
    this.updateDebugOptions();
    showToast(`瓦片边界: ${this.showTileBoundaries ? '显示' : '隐藏'}`);
  };
  
  /**
   * 切换碰撞检测框显示
   */
  private toggleCollisionBoxes = (): void => {
    this.showCollisionBoxes = !this.showCollisionBoxes;
    this.updateDebugOptions();
    showToast(`碰撞检测框: ${this.showCollisionBoxes ? '显示' : '隐藏'}`);
  };
  
  /**
   * 切换瓦片信息显示
   */
  private toggleTileInfo = (): void => {
    this.showTileInfo = !this.showTileInfo;
    this.updateDebugOptions();
    showToast(`瓦片信息: ${this.showTileInfo ? '显示' : '隐藏'}`);
  };
  
  /**
   * 切换时间戳显示
   */
  private toggleTimestamps = (): void => {
    this.showTimestamps = !this.showTimestamps;
    this.updateDebugOptions();
    showToast(`时间戳: ${this.showTimestamps ? '显示' : '隐藏'}`);
  };
  
  /**
   * 切换过度绘制可视化
   */
  private toggleOverdraw = (): void => {
    this.showOverdraw = !this.showOverdraw;
    this.updateDebugOptions();
    showToast(`过度绘制: ${this.showOverdraw ? '显示' : '隐藏'}`);
  };

  // ========== Rendering Stats ==========

  /**
   * 切换 Rendering Stats View 显示
   */
  private toggleRenderingStats = (): void => {
    if (!this.mapView) return;
    this.renderingStatsEnabled = !this.renderingStatsEnabled;
    this.mapView.enableRenderingStatsView(this.renderingStatsEnabled);
    const actual = this.mapView.isRenderingStatsViewEnabled();
    showToast(`Rendering Stats: ${actual ? 'Enabled' : 'Disabled'}`);
  };

  /**
   * Register a frame stats listener to log rendering statistics
   */
  private registerStatsListener = (): void => {
    if (!this.mapView) return;
    this.mapView.addOnDidFinishRenderingFrameWithStatsListener((stats: RenderingStats) => {
      console.info(`[DebugMode] Frame stats - fully: ${stats.fully}, ` +
        `encoding: ${stats.frameEncodingTime?.toFixed(1)}ms, ` +
        `rendering: ${stats.frameRenderingTime?.toFixed(1)}ms`);
    });
    showToast('Stats listener registered');
  };

  // ========== Action Journal ==========

  /**
   * 加载 Action Journal 日志
   */
  private loadActionJournalLog = (): void => {
    if (!this.mapView) return;
    try {
      const files = this.mapView.getActionJournalLogFiles();
      this.actionJournalLogFiles = files.length > 0 ? files.join('\n') : '(no log files)';

      const entries = this.mapView.getActionJournalLog();
      this.actionJournalEntries = entries.length > 0
        ? entries.slice(0, 10).join('\n') + (entries.length > 10 ? `\n... (${entries.length - 10} more)` : '')
        : '(no entries)';
      showToast(`Journal: ${files.length} files, ${entries.length} entries`);
    } catch (error) {
      showToast('Journal not available (not configured)');
      this.actionJournalLogFiles = '(not configured)';
      this.actionJournalEntries = '(not configured)';
    }
  };

  /**
   * 清除 Action Journal 日志
   */
  private clearActionJournalLog = (): void => {
    if (!this.mapView) return;
    try {
      this.mapView.clearActionJournalLog();
      this.actionJournalLogFiles = '';
      this.actionJournalEntries = '';
      showToast('Journal cleared');
    } catch (error) {
      showToast('Failed to clear journal');
    }
  };

  @Builder
  actionButtonsBuilder() {
    Column() {
      // 第一行：快速调试开关
      Row() {
        Button('调试模式')
          .fontSize(14)
          .backgroundColor(this.isDebugEnabled ? '#4CAF50' : '#9E9E9E')
          .onClick(this.toggleDebugMode)
          .margin({ right: 8 });
      }
      .margin({ bottom: 8 });
      
      // 第二行：详细选项
      Row() {
        Button('瓦片边界')
          .fontSize(12)
          .backgroundColor(this.showTileBoundaries ? '#2196F3' : '#BDBDBD')
          .onClick(this.toggleTileBoundaries)
          .margin({ right: 4 });
        
        Button('碰撞框')
          .fontSize(12)
          .backgroundColor(this.showCollisionBoxes ? '#2196F3' : '#BDBDBD')
          .onClick(this.toggleCollisionBoxes)
          .margin({ right: 4 });
        
        Button('瓦片信息')
          .fontSize(12)
          .backgroundColor(this.showTileInfo ? '#2196F3' : '#BDBDBD')
          .onClick(this.toggleTileInfo)
          .margin({ right: 4 });
      }
      .margin({ bottom: 4 });
      
      // 第三行：更多选项
      Row() {
        Button('时间戳')
          .fontSize(12)
          .backgroundColor(this.showTimestamps ? '#2196F3' : '#BDBDBD')
          .onClick(this.toggleTimestamps)
          .margin({ right: 4 });
        
        Button('过度绘制')
          .fontSize(12)
          .backgroundColor(this.showOverdraw ? '#2196F3' : '#BDBDBD')
          .onClick(this.toggleOverdraw);
      }
      .margin({ bottom: 4 });

      // 第四行：Rendering Stats
      Row() {
        Button('Rendering Stats')
          .fontSize(12)
          .backgroundColor(this.renderingStatsEnabled ? '#FF9800' : '#BDBDBD')
          .onClick(this.toggleRenderingStats)
          .margin({ right: 4 });

        Button('Stats Listener')
          .fontSize(12)
          .backgroundColor('#9C27B0')
          .onClick(this.registerStatsListener)
          .margin({ right: 4 });
      }
      .margin({ bottom: 4 });

      // 第五行：Action Journal
      Row() {
        Button('Load Journal')
          .fontSize(12)
          .backgroundColor('#607D8B')
          .onClick(this.loadActionJournalLog)
          .margin({ right: 4 });

        Button('Clear Journal')
          .fontSize(12)
          .backgroundColor('#E91E63')
          .onClick(this.clearActionJournalLog)
          .margin({ right: 4 });
      }

      // Log display area
      if (this.actionJournalLogFiles.length > 0) {
        Text('Journal Files:').fontSize(10).fontWeight(FontWeight.Bold).margin({ top: 4 })
        Text(this.actionJournalLogFiles).fontSize(9).lineHeight(14).maxLines(3)
      }
      if (this.actionJournalEntries.length > 0) {
        Text('Journal Entries:').fontSize(10).fontWeight(FontWeight.Bold).margin({ top: 2 })
        Text(this.actionJournalEntries).fontSize(9).lineHeight(14).maxLines(5)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%');
  }
  
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
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Debug Mode',
        description: '调试模式和性能信息',
        showActionBar: true,
        actionButtons: (): void => this.actionButtonsBuilder(),
        mapContent: ():void => this.mapContentBuilder()
      });
    }
    .width('100%')
    .height('100%');
  }
}