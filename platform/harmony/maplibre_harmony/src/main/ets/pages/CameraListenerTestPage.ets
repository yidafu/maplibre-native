/**
 * 相机监听器测试页面
 * 
 * 用于测试相机事件监听器功能
 */

import { MapViewComponentController } from '../maps/MapViewComponentController';
import { MapLibreMap } from '../maps/MapLibreMap';
import { OnCameraIdleListener, OnCameraMoveStartedListener,
         OnCameraMoveListener, OnCameraMoveCanceledListener } from '../maps/camera/CameraListener';
import { CameraMoveReason, getCameraMoveReasonText } from '../maps/camera/CameraMoveReason';

@Entry
@Component
struct CameraListenerTestPage {
  @State eventLogs: string[] = [];
  @State maxLogs: number = 50; // 最多显示50条日志
  @State cameraStatus: string = 'idle';
  @State lastMoveReason: string = '';
  
  private mapController = new MapViewComponentController();
  private mapLibreMap: MapLibreMap | null = null;
  
  // 监听器实例
  private onCameraIdleListener: OnCameraIdleListener = {
    onCameraIdle: () => {
      this.addLog('✅ onCameraIdle');
      this.cameraStatus = 'idle';
    }
  };
  
  private onCameraMoveStartedListener: OnCameraMoveStartedListener = {
    onCameraMoveStarted: (reason: CameraMoveReason) => {
      const reasonText = getCameraMoveReasonText(reason);
      this.addLog(`🚀 onCameraMoveStarted: ${reasonText} (${reason})`);
      this.cameraStatus = 'moving';
      this.lastMoveReason = reasonText;
    }
  };
  
  private onCameraMoveListener: OnCameraMoveListener = {
    onCameraMove: () => {
      // 移动事件触发太频繁，限制日志输出
      if (this.eventLogs.length === 0 || !this.eventLogs[0].startsWith('📍 onCameraMove')) {
        this.addLog('📍 onCameraMove (持续中...)');
      }
    }
  };
  
  private onCameraMoveCanceledListener: OnCameraMoveCanceledListener = {
    onCameraMoveCanceled: () => {
      this.addLog('❌ onCameraMoveCanceled');
      this.cameraStatus = 'canceled';
    }
  };
  
  /**
   * 添加日志
   */
  private addLog(message: string): void {
    const timestamp = new Date().toLocaleTimeString();
    this.eventLogs.unshift(`[${timestamp}] ${message}`);
    
    // 限制日志数量
    if (this.eventLogs.length > this.maxLogs) {
      this.eventLogs = this.eventLogs.slice(0, this.maxLogs);
    }
  }
  
  /**
   * 地图创建回调
   */
  private onMapCreated = (map: MapLibreMap) => {
    this.mapLibreMap = map;
    this.addLog('🗺️ 地图创建成功');
    
    // 注册所有监听器
    this.registerListeners();
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
    
    const lat = 39.9 + (Math.random() - 0.5) * 0.1;
    const lng = 116.4 + (Math.random() - 0.5) * 0.1;
    
    this.addLog(`🎯 调用 jumpTo(${lat.toFixed(4)}, ${lng.toFixed(4)})`);
    this.mapLibreMap.jumpTo(0, lat, lng, 0, 12);
  }
  
  /**
   * 测试 easeTo (缓动动画)
   */
  private testEaseTo(): void {
    if (!this.mapLibreMap) return;
    
    const lat = 39.9 + (Math.random() - 0.5) * 0.1;
    const lng = 116.4 + (Math.random() - 0.5) * 0.1;
    
    this.addLog(`🎯 调用 easeTo(${lat.toFixed(4)}, ${lng.toFixed(4)}, 1000ms)`);
    this.mapLibreMap.easeTo({
      center: { latitude: lat, longitude: lng },
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
  
  build() {
    Column() {
      // 标题栏
      Row() {
        Text('相机监听器测试')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
        
        Blank()
        
        Text(`状态: ${this.cameraStatus}`)
          .fontSize(14)
          .fontColor(this.cameraStatus === 'moving' ? '#FF6B00' : '#4CAF50')
          .margin({ right: 16 })
      }
      .width('100%')
      .height(50)
      .backgroundColor('#FFFFFF')
      
      // 地图视图
      MapViewComponent({
        controller: this.mapController,
        onMapCreated: this.onMapCreated
      })
        .width('100%')
        .height('50%')
      
      // 控制按钮
      Column() {
        Text('测试相机操作')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 12, bottom: 8 })
        
        Row() {
          Button('jumpTo')
            .onClick(() => this.testJumpTo())
            .margin({ right: 8 })
          
          Button('easeTo')
            .onClick(() => this.testEaseTo())
            .margin({ right: 8 })
          
          Button('moveBy')
            .onClick(() => this.testMoveBy())
        }
        .margin({ bottom: 8 })
        
        Row() {
          Button('移除监听器')
            .onClick(() => this.removeListeners())
            .backgroundColor('#FF6B00')
            .margin({ right: 8 })
          
          Button('重新注册')
            .onClick(() => this.registerListeners())
            .backgroundColor('#4CAF50')
            .margin({ right: 8 })
          
          Button('清空日志')
            .onClick(() => this.clearLogs())
            .backgroundColor('#9E9E9E')
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .backgroundColor('#F5F5F5')
      
      // 事件日志列表
      Column() {
        Text('事件日志 (最新在上)')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 8, bottom: 8, left: 16 })
        
        List() {
          ForEach(this.eventLogs, (log: string, index: number) => {
            ListItem() {
              Text(log)
                .fontSize(12)
                .fontColor('#333333')
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .width('100%')
            }
            .backgroundColor(index % 2 === 0 ? '#FFFFFF' : '#F9F9F9')
          }, (log: string, index: number) => `${index}-${log}`)
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 1, color: '#E0E0E0' })
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

// MapViewComponent 组件引用（假设已存在）
@Component
struct MapViewComponent {
  private controller: MapViewComponentController | null = null;
  private onMapCreated: ((map: MapLibreMap) => void) | null = null;
  
  build() {
    Stack() {
      // 这里应该是实际的地图组件
      // 暂时用占位符
      Text('地图组件占位符\n使用手势可以触发相机事件')
        .fontSize(16)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#E8F5E9')
  }
}

