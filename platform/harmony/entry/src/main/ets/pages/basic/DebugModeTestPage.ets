/**
 * Debug Mode Test Page
 * 调试模式测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/maplayout/DebugModeActivity.kt
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { NativeMapView, MapLibreMap, CameraPosition, LatLng } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS } from '../common/TestUtils';

@Entry
@Component
struct DebugModeTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isDebugEnabled: boolean = false;
  @State private showTileBoundaries: boolean = false;
  @State private showCollisionBoxes: boolean = false;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[DebugModeTestPage] onMapReady');
    this.mapController = map;
    map.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    
    // 设置初始相机位置
    map.jumpTo(0, 39.9042, 116.4074, 0, 12);
  };
  
  /**
   * 切换调试模式
   */
  private toggleDebugMode = (): void => {
    this.isDebugEnabled = !this.isDebugEnabled;
    if (this.mapController) {
      // TODO: 实现 setDebugActive 方法
      // this.mapController.setDebugActive(this.isDebugEnabled);
      console.warn('TODO: Implement setDebugActive');
      showToast(`调试模式: ${this.isDebugEnabled ? '开启' : '关闭'}`);
    }
  };
  
  /**
   * 切换瓦片边界显示
   */
  private toggleTileBoundaries = (): void => {
    this.showTileBoundaries = !this.showTileBoundaries;
    if (this.mapController) {
      // TODO: 实现 setShowTileBoundaries 方法
      console.warn('TODO: Implement setShowTileBoundaries');
      showToast(`瓦片边界: ${this.showTileBoundaries ? '显示' : '隐藏'}`);
    }
  };
  
  /**
   * 切换碰撞检测框显示
   */
  private toggleCollisionBoxes = (): void => {
    this.showCollisionBoxes = !this.showCollisionBoxes;
    if (this.mapController) {
      // TODO: 实现 setShowCollisionBoxes 方法
      console.warn('TODO: Implement setShowCollisionBoxes');
      showToast(`碰撞检测框: ${this.showCollisionBoxes ? '显示' : '隐藏'}`);
    }
  };
  
  @Builder
  actionButtonsBuilder() {
    Button('调试模式')
      .fontSize(14)
      .backgroundColor(this.isDebugEnabled ? '#4CAF50' : '#9E9E9E')
      .onClick(this.toggleDebugMode);
    
    Button('瓦片边界')
      .fontSize(14)
      .backgroundColor(this.showTileBoundaries ? '#4CAF50' : '#9E9E9E')
      .onClick(this.toggleTileBoundaries);
    
    Button('碰撞框')
      .fontSize(14)
      .backgroundColor(this.showCollisionBoxes ? '#4CAF50' : '#9E9E9E')
      .onClick(this.toggleCollisionBoxes);
  }
  
  build() {
    Column() {
      TestPageLayout({
      title: 'Debug Mode',
      description: '调试模式和性能信息',
      showActionBar: true,
      actionButtons: this.actionButtonsBuilder,
      mapContent: () => {
        NativeMapView({
          onMapReady: this.onMapReady
        })
          .width('100%')
          .height('100%');
      }
    });
    }
    .width('100%')
    .height('100%');
  }
}