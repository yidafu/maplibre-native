/**
 * 事件监听器集成测试页面
 * 
 * 测试所有 Android/iOS 风格的监听器 API
 */

import { NativeMapView } from '../../maps/NativeMapView';
import router from '@ohos.router';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';
import {
  OnCameraWillChangeListener,
  OnCameraIsChangingListener,
  OnCameraDidChangeListener,
  OnWillStartLoadingMapListener,
  OnDidFinishLoadingMapListener,
  OnDidFailLoadingMapListener,
  OnWillStartRenderingFrameListener,
  OnDidFinishRenderingFrameListener,
  OnDidFinishRenderingFrameWithStatsListener,
  OnWillStartRenderingMapListener,
  OnDidFinishRenderingMapListener,
  OnDidFinishLoadingStyleListener,
  OnStyleImageMissingListener,
  OnDidBecomeIdleListener,
  OnSourceChangedListener,
  OnMapReadyCallback
} from '../../maps/listeners/MapEventListeners';
import { RenderingStats } from '../../maps/RenderingStats';

@Entry
@Component
struct EventListenersTestPage {
  @State private eventLog: string[] = [];
  @State private fps: string = '--';
  @State private cameraChangeCount: number = 0;
  @State private frameCount: number = 0;
  private mapView: NativeMapView | null = null;
  private scrollerController: Scroller = new Scroller();

  // 监听器对象
  private cameraWillChangeListener: OnCameraWillChangeListener = {
    onCameraWillChange: (animated: boolean) => {
      this.logEvent(`📹 Camera will change (animated: ${animated})`);
    }
  };

  private cameraIsChangingListener: OnCameraIsChangingListener = {
    onCameraIsChanging: () => {
      this.cameraChangeCount++;
    }
  };

  private cameraDidChangeListener: OnCameraDidChangeListener = {
    onCameraDidChange: (animated: boolean) => {
      this.logEvent(`📹 Camera did change (animated: ${animated})`);
    }
  };

  private mapLoadingListener: OnWillStartLoadingMapListener = {
    onWillStartLoadingMap: () => {
      this.logEvent(`🗺️ Map will start loading`);
    }
  };

  private mapLoadedListener: OnDidFinishLoadingMapListener = {
    onDidFinishLoadingMap: () => {
      this.logEvent(`✅ Map finished loading`);
    }
  };

  private mapLoadErrorListener: OnDidFailLoadingMapListener = {
    onDidFailLoadingMap: (errorMessage: string) => {
      this.logEvent(`❌ Map load failed: ${errorMessage}`);
    }
  };

  private styleLoadedListener: OnDidFinishLoadingStyleListener = {
    onDidFinishLoadingStyle: () => {
      this.logEvent(`🎨 Style finished loading`);
    }
  };

  private frameStatsListener: OnDidFinishRenderingFrameWithStatsListener = {
    onDidFinishRenderingFrame: (fully: boolean, stats: RenderingStats) => {
      this.frameCount++;
      this.fps = stats.getEstimatedFps().toFixed(1);
      
      // 每 60 帧记录一次
      if (this.frameCount % 60 === 0) {
        this.logEvent(`🎬 60 frames rendered, avg FPS: ${this.fps}`);
      }
    }
  };

  private idleListener: OnDidBecomeIdleListener = {
    onDidBecomeIdle: () => {
      this.logEvent(`😴 Map became idle`);
    }
  };

  /**
   * 添加事件日志
   */
  private logEvent(message: string): void {
    const timestamp = new Date().toLocaleTimeString();
    this.eventLog.unshift(`[${timestamp}] ${message}`);
    
    // 限制日志数量
    if (this.eventLog.length > 50) {
      this.eventLog = this.eventLog.slice(0, 50);
    }
    
    hilog.info(DOMAIN, 'EventListenersTest', message);
  }

  /**
   * 注册所有监听器
   */
  private registerAllListeners(): void {
    if (!this.mapView) {
      return;
    }

    this.logEvent(`📝 Registering all event listeners...`);

    // 相机事件
    this.mapView.addOnCameraWillChangeListener(this.cameraWillChangeListener);
    this.mapView.addOnCameraIsChangingListener(this.cameraIsChangingListener);
    this.mapView.addOnCameraDidChangeListener(this.cameraDidChangeListener);

    // 地图加载事件
    this.mapView.addOnWillStartLoadingMapListener(this.mapLoadingListener);
    this.mapView.addOnDidFinishLoadingMapListener(this.mapLoadedListener);
    this.mapView.addOnDidFailLoadingMapListener(this.mapLoadErrorListener);

    // 渲染事件
    this.mapView.addOnDidFinishRenderingFrameWithStatsListener(this.frameStatsListener);

    // 样式事件
    this.mapView.addOnDidFinishLoadingStyleListener(this.styleLoadedListener);

    // 其他事件
    this.mapView.addOnDidBecomeIdleListener(this.idleListener);

    this.logEvent(`✅ All listeners registered`);
  }

  /**
   * 清除所有日志
   */
  private clearLog(): void {
    this.eventLog = [];
    this.cameraChangeCount = 0;
    this.frameCount = 0;
  }

  /**
   * 页面出现
   */
  onPageShow() {
    if (this.mapView) {
      this.mapView.onPageShow();
      this.logEvent(`📱 Page shown - Map rendering resumed`);
    }
  }

  /**
   * 页面隐藏
   */
  onPageHide() {
    if (this.mapView) {
      this.mapView.onPageHide();
      this.logEvent(`📱 Page hidden - Map rendering paused`);
    }
  }

  /**
   * 页面即将消失
   */
  aboutToDisappear() {
    // 移除所有监听器
    if (this.mapView) {
      this.mapView.removeOnCameraWillChangeListener(this.cameraWillChangeListener);
      this.mapView.removeOnCameraIsChangingListener(this.cameraIsChangingListener);
      this.mapView.removeOnCameraDidChangeListener(this.cameraDidChangeListener);
      this.mapView.removeOnWillStartLoadingMapListener(this.mapLoadingListener);
      this.mapView.removeOnDidFinishLoadingMapListener(this.mapLoadedListener);
      this.mapView.removeOnDidFailLoadingMapListener(this.mapLoadErrorListener);
      this.mapView.removeOnDidFinishRenderingFrameWithStatsListener(this.frameStatsListener);
      this.mapView.removeOnDidFinishLoadingStyleListener(this.styleLoadedListener);
      this.mapView.removeOnDidBecomeIdleListener(this.idleListener);
      
      hilog.info(DOMAIN, 'EventListenersTest', 'All listeners removed');
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Button('← 返回')
          .fontSize(14)
          .onClick(() => {
            router.back();
          })
        
        Text('事件监听器测试')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        Button('清除日志')
          .fontSize(14)
          .onClick(() => {
            this.clearLog();
          })
      }
      .width('100%')
      .padding(10)
      .backgroundColor('#f0f0f0')
      .justifyContent(FlexAlign.SpaceBetween)

      // 统计信息栏
      Row() {
        Text(`FPS: ${this.fps}`)
          .fontSize(14)
          .margin({ right: 20 })
        
        Text(`相机变化: ${this.cameraChangeCount}`)
          .fontSize(14)
          .margin({ right: 20 })
        
        Text(`帧数: ${this.frameCount}`)
          .fontSize(14)
      }
      .width('100%')
      .padding(10)
      .backgroundColor('#e8f5e9')
      .justifyContent(FlexAlign.SpaceAround)

      // 地图区域
      Stack() {
        NativeMapView({
          styleUrl: "https://demotiles.maplibre.org/style.json",
          initialLatitude: 39.9042,
          initialLongitude: 116.4074,
          initialZoom: 12,
          initialBearing: 0,
          initialPitch: 0,
          onMapReady: (mapView) => {
            this.mapView = mapView;
            this.logEvent(`🗺️ Map ready!`);
            
            // 注册所有监听器
            setTimeout(() => {
              this.registerAllListeners();
            }, 100);
          }
        })
          .width('100%')
          .height('60%')
        
        // 测试按钮组
        Column() {
          Button('缩放到 15')
            .fontSize(12)
            .width(120)
            .margin({ bottom: 5 })
            .onClick(() => {
              if (this.mapView) {
                this.mapView.setZoom(15, undefined, undefined, 500);
              }
            })
          
          Button('旋转 45°')
            .fontSize(12)
            .width(120)
            .margin({ bottom: 5 })
            .onClick(() => {
              if (this.mapView) {
                this.mapView.setBearing(45, 500);
              }
            })
          
          Button('设置俯仰 60°')
            .fontSize(12)
            .width(120)
            .margin({ bottom: 5 })
            .onClick(() => {
              if (this.mapView) {
                this.mapView.setPitch(60, 500);
              }
            })
          
          Button('飞到北京')
            .fontSize(12)
            .width(120)
            .onClick(() => {
              if (this.mapView) {
                const beijing = new LatLng(39.9042, 116.4074);
                this.mapView.flyTo(beijing, 15, 0, 45, 2000);
              }
            })
        }
        .position({ x: 10, y: 10 })
      }
      .width('100%')
      .height('60%')

      // 事件日志区域
      Column() {
        Text('事件日志')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .padding(10)
          .backgroundColor('#e3f2fd')

        Scroll(this.scrollerController) {
          Column() {
            ForEach(this.eventLog, (event: string, index: number) => {
              Text(event)
                .fontSize(11)
                .fontFamily('monospace')
                .width('100%')
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .backgroundColor(index % 2 === 0 ? '#ffffff' : '#f5f5f5')
            })
          }
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#ffffff')
    }
    .width('100%')
    .height('100%')
  }
}

