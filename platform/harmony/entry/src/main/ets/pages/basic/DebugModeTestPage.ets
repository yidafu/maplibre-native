/**
 * Debug Mode Test Page
 * 调试模式测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/maplayout/DebugModeActivity.kt
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, CameraPosition, LatLng, MapDebugOptions } from 'maplibre_harmony';
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