/**
 * 相机监听器测试页面
 * 
 * 用于测试相机事件监听器功能
 */

import { NativeMapView } from 'maplibre_harmony/src/main/ets/maps/NativeMapView';
import { maplibre } from 'maplibre_harmony';
import { MapLibreMap } from 'maplibre_harmony/src/main/ets/maps/MapLibreMap';
import { MapLibreMapOptions } from 'maplibre_harmony/src/main/ets/maps/MapLibreMapOptions';
import { CameraPosition, createCameraPosition } from 'maplibre_harmony/src/main/ets/maps/camera/CameraPosition';
import { OnCameraIdleListener, OnCameraMoveStartedListener,
         OnCameraMoveListener, OnCameraMoveCanceledListener } from 'maplibre_harmony/src/main/ets/maps/camera/CameraListener';
import { CameraMoveReason, getCameraMoveReasonText } from 'maplibre_harmony/src/main/ets/maps/camera/CameraMoveReason';
import { router } from '@kit.ArkUI';
import { TestPageLayout } from '../components/TestPageLayout';

// 相机空闲监听器实现
class CameraIdleListenerImpl implements OnCameraIdleListener {
  private testPage: CameraListenerTestPage;

  constructor(testPage: CameraListenerTestPage) {
    this.testPage = testPage;
  }

  onCameraIdle(): void {
    this.testPage.addLog('✅ onCameraIdle');
    this.testPage.cameraStatus = 'idle';
  }
}

// 相机移动开始监听器实现
class CameraMoveStartedListenerImpl implements OnCameraMoveStartedListener {
  private testPage: CameraListenerTestPage;

  constructor(testPage: CameraListenerTestPage) {
    this.testPage = testPage;
  }

  onCameraMoveStarted(reason: CameraMoveReason): void {
    const reasonText = getCameraMoveReasonText(reason);
    this.testPage.addLog(`🚀 onCameraMoveStarted: ${reasonText} (${reason})`);
    this.testPage.cameraStatus = 'moving';
    this.testPage.lastMoveReason = reasonText;
  }
}

// 相机移动监听器实现
class CameraMoveListenerImpl implements OnCameraMoveListener {
  private testPage: CameraListenerTestPage;

  constructor(testPage: CameraListenerTestPage) {
    this.testPage = testPage;
  }

  onCameraMove(): void {
    // 移动事件触发太频繁，限制日志输出
    if (this.testPage.eventLogs.length === 0 || !this.testPage.eventLogs[0].startsWith('📍 onCameraMove')) {
      this.testPage.addLog('📍 onCameraMove (持续中...)');
    }
  }
}

// 相机移动取消监听器实现
class CameraMoveCanceledListenerImpl implements OnCameraMoveCanceledListener {
  private testPage: CameraListenerTestPage;

  constructor(testPage: CameraListenerTestPage) {
    this.testPage = testPage;
  }

  onCameraMoveCanceled(): void {
    this.testPage.addLog('❌ onCameraMoveCanceled');
    this.testPage.cameraStatus = 'canceled';
  }
}

@Entry
@Component
struct CameraListenerTestPage {
  @State eventLogs: string[] = [];
  @State maxLogs: number = 50; // 最多显示50条日志
  @State cameraStatus: string = 'idle';
  @State lastMoveReason: string = '';
  
  private mapLibreMap: MapLibreMap | null = null;
  
  // 监听器实例
  private onCameraIdleListener: OnCameraIdleListener = new CameraIdleListenerImpl(this);
  private onCameraMoveStartedListener: OnCameraMoveStartedListener = new CameraMoveStartedListenerImpl(this);
  private onCameraMoveListener: OnCameraMoveListener = new CameraMoveListenerImpl(this);
  private onCameraMoveCanceledListener: OnCameraMoveCanceledListener = new CameraMoveCanceledListenerImpl(this);
  
  /**
   * 添加日志
   */
  public addLog(message: string): void {
    const timestamp = new Date().toLocaleTimeString();
    this.eventLogs.unshift(`[${timestamp}] ${message}`);
    
    // 限制日志数量
    if (this.eventLogs.length > this.maxLogs) {
      this.eventLogs = this.eventLogs.slice(0, this.maxLogs);
    }
  }
  
  /**
   * 地图准备回调
   */
  private onMapReady(nativeMapView?: maplibre.NativeMapView) {
    try {
      if (!nativeMapView) {
        this.addLog('❌ NativeMapView is null');
        return;
      }
      
      const latLng = new maplibre.LatLng(39.9042, 116.4074);
      const cameraPos = createCameraPosition(latLng, 12, 0, 0);
      const options = new MapLibreMapOptions();
      options.cameraPosition = cameraPos;
      options.styleUrl = 'https://demotiles.maplibre.org/style.json';
      
      this.mapLibreMap = new MapLibreMap(nativeMapView, options);
      this.addLog('🗺️ 地图创建成功');
      
      // 注册所有监听器
      this.registerListeners();
    } catch (error) {
      this.addLog(`❌ 地图初始化失败: ${error}`);
    }
  }
  
  /**
   * 注册监听器
   */
  private registerListeners(): void {
    if (!this.mapLibreMap) return;
    
    this.mapLibreMap.addOnCameraIdleListener(this.onCameraIdleListener);
    this.mapLibreMap.addOnCameraMoveStartedListener(this.onCameraMoveStartedListener);
    this.mapLibreMap.addOnCameraMoveListener(this.onCameraMoveListener);
    this.mapLibreMap.addOnCameraMoveCanceledListener(this.onCameraMoveCanceledListener);
    
    this.addLog('✅ 所有监听器已注册');
  }
  
  /**
   * 移除监听器
   */
  private removeListeners(): void {
    if (!this.mapLibreMap) return;
    
    this.mapLibreMap.removeOnCameraIdleListener(this.onCameraIdleListener);
    this.mapLibreMap.removeOnCameraMoveStartedListener(this.onCameraMoveStartedListener);
    this.mapLibreMap.removeOnCameraMoveListener(this.onCameraMoveListener);
    this.mapLibreMap.removeOnCameraMoveCanceledListener(this.onCameraMoveCanceledListener);
    
    this.addLog('❌ 所有监听器已移除');
  }
  
  /**
   * 测试 jumpTo (立即跳转)
   */
  private testJumpTo(): void {
    if (!this.mapLibreMap) return;
    
    const lat: number = 39.9 + (Math.random() - 0.5) * 0.1;
    const lng: number = 116.4 + (Math.random() - 0.5) * 0.1;
    
    this.addLog(`🎯 调用 jumpTo(${lat.toFixed(4)}, ${lng.toFixed(4)})`);
    this.mapLibreMap.jumpTo(0, lat, lng, 0, 12);
  }
  
  /**
   * 测试 easeTo (缓动动画)
   */
  private testEaseTo(): void {
    if (!this.mapLibreMap) return;
    
    const lat: number = 39.9 + (Math.random() - 0.5) * 0.1;
    const lng: number = 116.4 + (Math.random() - 0.5) * 0.1;
    
    this.addLog(`🎯 调用 easeTo(${lat.toFixed(4)}, ${lng.toFixed(4)}, 1000ms)`);
    this.mapLibreMap.easeTo({
      center: new maplibre.LatLng(lat, lng),
      zoom: 13
    }, 1000);
  }
  
  /**
   * 测试 moveBy (相对移动)
   */
  private testMoveBy(): void {
    if (!this.mapLibreMap) return;
    
    const dx = (Math.random() - 0.5) * 200;
    const dy = (Math.random() - 0.5) * 200;
    
    this.addLog(`🎯 调用 moveBy(${dx.toFixed(0)}, ${dy.toFixed(0)}, 500ms)`);
    this.mapLibreMap.moveBy(dx, dy, 500);
  }
  
  /**
   * 清空日志
   */
  private clearLogs(): void {
    this.eventLogs = [];
    this.addLog('🧹 日志已清空');
  }

  @Builder
  MapAreaBuilder() {
    NativeMapView({
      onMapReady: (nativeMapView?: maplibre.NativeMapView) => {
        this.onMapReady(nativeMapView);
      }
    })
      .width('100%')
      .height('100%')
  }

  @Builder
  ControlAreaBuilder() {
    // 状态信息
    Row() {
            Text(`状态: ${this.cameraStatus}`)
              .fontSize(14)
              .fontColor(this.cameraStatus === 'moving' ? '#FF6B00' : '#4CAF50')
              .layoutWeight(1)
            
            Text(`原因: ${this.lastMoveReason || '无'}`)
              .fontSize(12)
              .fontColor('#666666')
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#F8F8F8')
          .margin({ bottom: 8 })
          
          // 测试相机操作
          Text('测试相机操作')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ top: 8, bottom: 8 })
            .width('100%')
          
          Row() {
            Button('jumpTo')
              .onClick(() => this.testJumpTo())
              .margin({ right: 8 })
              .layoutWeight(1)
            
            Button('easeTo')
              .onClick(() => this.testEaseTo())
              .margin({ right: 8 })
              .layoutWeight(1)
            
            Button('moveBy')
              .onClick(() => this.testMoveBy())
              .layoutWeight(1)
          }
          .width('100%')
          .margin({ bottom: 8 })
          
          Row() {
            Button('移除监听器')
              .onClick(() => this.removeListeners())
              .backgroundColor('#FF6B00')
              .margin({ right: 8 })
              .layoutWeight(1)
            
            Button('重新注册')
              .onClick(() => this.registerListeners())
              .backgroundColor('#4CAF50')
              .margin({ right: 8 })
              .layoutWeight(1)
            
            Button('清空日志')
              .onClick(() => this.clearLogs())
              .backgroundColor('#9E9E9E')
              .layoutWeight(1)
          }
          .width('100%')
          .margin({ bottom: 8 })
          
          Divider().height(1).color('#E0E0E0').margin({ top: 8, bottom: 8 })
          
          // 事件日志列表
          Text(`事件日志 (最新在上，共${this.eventLogs.length}条)`)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 8 })
            .width('100%')
          
          Column() {
            ForEach(this.eventLogs, (log: string, index: number) => {
              Text(log)
                .fontSize(11)
                .fontColor('#333333')
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .width('100%')
                .backgroundColor(index % 2 === 0 ? '#FFFFFF' : '#F9F9F9')
                .border({ width: { bottom: 0.5 }, color: '#E0E0E0' })
            }, (log: string, index: number) => `${index}-${log}`)
          }
          .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
        title: '相机监听器测试',
        mapArea: (): void => this.MapAreaBuilder(),
        controlArea: (): void => this.ControlAreaBuilder()
      })
    }
    .width('100%')
    .height('100%')
  }
}

