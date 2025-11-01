/**
 * Map Change Test Page
 * 地图事件监听测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/maplayout/MapChangeActivity.kt
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, CameraPosition, LatLng } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';

@Entry
@Component
struct MapChangeTestPage {
  private mapController: MapLibreMap | null = null;
  @State private eventLog:  string[] = [];
  
  aboutToDisappear() {
    if (this.mapController) {
      // 移除事件监听器
      // TODO: 实现 removeAllListeners
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[MapChangeTestPage] onMapReady');
    this.mapController = map;
    map.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    
    // TODO: Use jumpTo instead of CameraPosition
    // TODO: map.setCameraPosition(initialPosition);
    
    // 添加事件监听器
    this.setupEventListeners(map);
    
    this.addEventLog('地图初始化完成');
  };
  
  /**
   * 设置事件监听器
   */
  private setupEventListeners(map: MapLibreMap): void {
    // TODO: 实现各种地图事件监听器
    // map.addOnWillStartLoadingMapListener(() => {
    //   this.addEventLog('开始加载地图');
    // });
    
    // map.addOnDidFinishLoadingMapListener(() => {
    //   this.addEventLog('地图加载完成');
    // });
    
    // map.addOnDidFinishLoadingStyleListener(() => {
    //   this.addEventLog('样式加载完成');
    // });
    
    // map.addOnCameraMoveListener(() => {
    //   this.addEventLog('相机移动');
    // });
    
    console.warn('TODO: Implement map event listeners');
  }
  
  /**
   * 添加事件日志
   */
  private addEventLog(event: string): void {
    const timestamp = new Date().toLocaleTimeString();
    const logEntry = `[${timestamp}] ${event}`;
    
    this.eventLog = [logEntry, ...this.eventLog].slice(0, 20); // 保留最近20条
  }
  
  /**
   * 清空日志
   */
  private clearLog = (): void => {
    this.eventLog = [];
    showToast('日志已清空');
  };
  
  /**
   * 触发相机移动事件
   */
  private triggerCameraMove = (): void => {
    if (this.mapController) {
      this.mapController.jumpTo(45, TEST_LOCATIONS.shanghai.latitude, TEST_LOCATIONS.shanghai.longitude, 30, 12);
    }
  };
  
  @Builder
  actionButtonsBuilder() {
    Button('移动相机')
      .fontSize(14)
      .onClick(this.triggerCameraMove);
    
    Button('清空日志')
      .fontSize(14)
      .onClick(this.clearLog);
  }
  
  @Builder
  controlPanelBuilder() {
    Column() {
      Text('事件日志')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 });
      
      Scroll() {
        Column() {
          ForEach(this.eventLog, (log: string, index: number) => {
            Text(log)
              .fontSize(12)
              .fontFamily('monospace')
              .margin({ bottom: 4 });
          }, (log: string, index: number) => `${index}-${log}`);
        }
        .alignItems(HorizontalAlign.Start);
      }
      .height(200)
      .width('100%');
    }
    .alignItems(HorizontalAlign.Start)
    .width(300);
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
        title: 'Map Change',
        description: '地图事件监听',
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