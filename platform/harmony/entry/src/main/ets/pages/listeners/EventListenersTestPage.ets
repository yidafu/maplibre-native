/**
 * 事件监听器集成测试页面
 * 
 * 完整测试所有 MapLibre 事件监听器：
 * - 相机事件：OnCameraWillChange, OnCameraIsChanging, OnCameraDidChange
 * - 地图加载：OnWillStartLoadingMap, OnDidFinishLoadingMap, OnDidFailLoadingMap
 * - 渲染事件：OnDidFinishRenderingFrame, OnDidFinishRenderingFrameWithStats
 * - 样式事件：OnDidFinishLoadingStyle, OnStyleImageMissing
 * - 状态事件：OnDidBecomeIdle, OnSourceChanged
 * 
 * 参考: Android/iOS MapLibre 事件监听器 API
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { maplibre } from 'maplibre_harmony';
import { NativeMapView } from 'maplibre_harmony/src/main/ets/maps/NativeMapView';
import { MapLibreMap } from 'maplibre_harmony/src/main/ets/maps/MapLibreMap';
import { MapLibreMapOptions } from 'maplibre_harmony/src/main/ets/maps/MapLibreMapOptions';
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
  OnSourceChangedListener
} from 'maplibre_harmony/src/main/ets/maps/listeners/MapEventListeners';
import { RenderingStats } from 'maplibre_harmony/src/main/ets/maps/renderer/RenderingStats';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';

@Entry
@Component
struct EventListenersTestPage {
  @State statusMessage: string = '等待地图加载...';
  @State eventCount: number = 0;
  @State mapReady: boolean = false;
  @State eventLog: string[] = [];
  @State eventStats: Record<string, number> = {}; // 事件统计
  @State showRenderingEvents: boolean = false; // 是否显示渲染事件（会很频繁）
  @State lastRenderingStats: string = '等待渲染数据...'; // 最后的渲染统计
  
  private mapView: maplibre.NativeMapView | null = null;
  private map: MapLibreMap | null = null;
  private nativeMapViewComponent: NativeMapView | null = null;
  
  // 测试用样式列表
  private currentStyleIndex: number = 0;
  private styleUrls: string[] = [
    'https://demotiles.maplibre.org/style.json',
    'https://demotiles.maplibre.org/style.json', // 同一个样式用于测试重载
  ];

  /**
   * 地图区域构建器
   */
  @Builder
  MapAreaBuilder() {
    NativeMapView({
      styleUrl: 'https://demotiles.maplibre.org/style.json',
      initialLatitude: 39.9042,
      initialLongitude: 116.4074,
      initialZoom: 12,
      initialBearing: 0,
      initialPitch: 0,
      onMapReady: (mapView?: maplibre.NativeMapView) => {
        this.onMapReady(mapView);
      }
    })
    .width('100%')
    .height('100%')
  }

  /**
   * 操作按钮构建器
   */
  @Builder
  ControlButtonsBuilder() {
    Column({ space: 12 }) {
      Text('事件监听器测试')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
      
      // 事件统计面板
      Text('事件统计')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ top: 8 })
      
      Column() {
        if (Object.keys(this.eventStats).length > 0) {
          ForEach(Object.entries(this.eventStats), (entry: [string, number]) => {
            Row() {
              Text(entry[0])
                .fontSize(12)
                .width('60%')
              Text(entry[1].toString())
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.getCategoryColor(entry[0]))
                .width('40%')
                .textAlign(TextAlign.End)
            }
            .width('100%')
            .padding(4)
          }, (item: [string, number]) => item[0])
        } else {
          Text('暂无事件')
            .fontSize(12)
            .fontColor('#999')
            .width('100%')
            .padding(8)
        }
      }
      .width('100%')
      .backgroundColor('#f9f9f9')
      .border({ width: 1, color: '#ddd' })
      .borderRadius(4)
      .padding(8)
      
      // 渲染统计
      if (this.showRenderingEvents) {
        Text(this.lastRenderingStats)
          .fontSize(11)
          .fontColor('#666')
          .width('100%')
          .margin({ top: 4 })
      }
      
      Divider()
        .margin({ top: 8, bottom: 8 })
      
      // 控制开关
      Text('监听器控制')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .width('100%')
      
      Row() {
        Text('显示渲染事件')
          .fontSize(13)
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.showRenderingEvents })
          .onChange((isOn: boolean) => {
            this.showRenderingEvents = isOn;
            this.logEvent('控制', `渲染事件显示: ${isOn ? '开启' : '关闭'}`);
          })
      }
      .width('100%')
      .padding(8)
      .backgroundColor('#f5f5f5')
      .borderRadius(4)
      
      Divider()
        .margin({ top: 8, bottom: 8 })
      
      // 测试按钮组
      Text('测试操作')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .width('100%')
      
      Row() {
        Button('相机移动')
          .fontSize(12)
          .width('48%')
          .onClick(() => {
            this.testCameraMove();
          })
          .enabled(this.mapReady)
        
        Button('相机动画')
          .fontSize(12)
          .width('48%')
          .margin({ left: 8 })
          .onClick(() => {
            this.testCameraAnimation();
          })
          .enabled(this.mapReady)
      }
      .width('100%')
      
      Row() {
        Button('切换样式')
          .fontSize(12)
          .width('48%')
          .onClick(() => {
            this.testStyleChange();
          })
          .enabled(this.mapReady)
        
        Button('重置视图')
          .fontSize(12)
          .width('48%')
          .margin({ left: 8 })
          .onClick(() => {
            this.testResetView();
          })
          .enabled(this.mapReady)
      }
      .width('100%')
      
      Row() {
        Button('清除日志')
          .fontSize(12)
          .width('48%')
          .backgroundColor('#FF6B6B')
          .onClick(() => {
            this.clearLog();
          })
        
        Button('清除统计')
          .fontSize(12)
          .width('48%')
          .margin({ left: 8 })
          .backgroundColor('#FFA500')
          .onClick(() => {
            this.clearStats();
          })
      }
      .width('100%')
      
      Divider()
        .margin({ top: 8, bottom: 8 })
      
      // 事件日志
      Text('事件日志')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .width('100%')
      
      Scroll() {
        Column() {
          if (this.eventLog.length > 0) {
            ForEach(this.eventLog, (event: string, index: number) => {
              Text(event)
                .fontSize(10)
                .fontFamily('monospace')
                .width('100%')
                .padding(6)
                .backgroundColor(index % 2 === 0 ? '#ffffff' : '#f5f5f5')
                .fontColor(this.getEventColor(event))
            }, (item: string, index: number) => `${index}_${item}`)
          } else {
            Text('暂无事件日志')
              .fontSize(12)
              .fontColor('#999')
              .width('100%')
              .padding(12)
              .textAlign(TextAlign.Center)
          }
        }
      }
      .width('100%')
      .height(180)
      .backgroundColor('#f9f9f9')
      .border({ width: 1, color: '#ddd' })
      .borderRadius(4)
      
      Text(this.statusMessage)
        .fontSize(11)
        .fontColor('#666')
        .width('100%')
        .margin({ top: 8 })
    }
    .padding(16)
    .width('100%')
  }

  /**
   * 地图准备完成
   */
  private onMapReady(mapView?: maplibre.NativeMapView): void {
    if (mapView) {
      this.mapView = mapView;
      
      // 创建 MapLibreMap 实例
      const options = new MapLibreMapOptions();
      this.map = new MapLibreMap(mapView, options);
      
      this.mapReady = true;
      this.logEvent('生命周期', '✅ 地图初始化完成');
      this.statusMessage = '地图已就绪，事件监听器已激活';
      
      // 注册所有事件监听器
      this.registerAllListeners();
      
      hilog.info(DOMAIN, 'EventListenersTest', 'Map ready and listeners registered');
    }
  }

  /**
   * 注册所有事件监听器
   */
  private registerAllListeners(): void {
    if (!this.mapView) {
      hilog.error(DOMAIN, 'EventListenersTest', 'Cannot register listeners: mapView is null');
      return;
    }
    
    // 保存 NativeMapView 组件引用（通过全局查找）
    // 注意：这里我们直接使用 mapView 的方法，因为 NativeMapView 组件已经在 onMapReady 中准备好了
    
    // ========== 相机事件监听器 ==========
    
    this.mapView.addOnCameraWillChangeListener((animated: boolean) => {
      this.logEvent('相机', `📷 相机即将改变 (动画: ${animated ? '是' : '否'})`);
    });
    
    this.mapView.addOnCameraIsChangingListener(() => {
      // 这个事件非常频繁，只在启用渲染事件时显示
      if (this.showRenderingEvents) {
        this.logEvent('相机', '📷 相机正在改变...');
      }
    });
    
    this.mapView.addOnCameraDidChangeListener((animated: boolean) => {
      this.logEvent('相机', `📷 相机已改变 (动画: ${animated ? '是' : '否'})`);
    });
    
    // ========== 地图加载事件监听器 ==========
    
    this.mapView.addOnWillStartLoadingMapListener(() => {
      this.logEvent('加载', '🔄 地图即将开始加载');
    });
    
    this.mapView.addOnDidFinishLoadingMapListener(() => {
      this.logEvent('加载', '✅ 地图加载完成');
    });
    
    this.mapView.addOnDidFailLoadingMapListener((errorMessage: string) => {
      this.logEvent('加载', `❌ 地图加载失败: ${errorMessage}`);
    });
    
    // ========== 渲染事件监听器 ==========
    
    this.mapView.addOnWillStartRenderingFrameListener(() => {
      if (this.showRenderingEvents) {
        this.logEvent('渲染', '🎬 帧即将开始渲染');
      }
    });
    
    this.mapView.addOnDidFinishRenderingFrameListener((fully: boolean, frameEncodingTime: number, frameRenderingTime: number) => {
      if (this.showRenderingEvents) {
        this.logEvent('渲染', `🎨 帧渲染完成 (完整: ${fully ? '是' : '否'}, 编码: ${frameEncodingTime.toFixed(2)}ms, 渲染: ${frameRenderingTime.toFixed(2)}ms)`);
      }
    });
    
    // 使用帧渲染监听器计算 FPS
    let frameCount = 0;
    let lastFpsUpdateTime = Date.now();
    this.mapView.addOnDidFinishRenderingFrameListener((fully: boolean, frameEncodingTime: number, frameRenderingTime: number) => {
      if (this.showRenderingEvents) {
        frameCount++;
        const now = Date.now();
        const elapsed = now - lastFpsUpdateTime;
        
        // 每秒更新一次 FPS 统计
        if (elapsed >= 1000) {
          const fps = frameCount / (elapsed / 1000);
          this.lastRenderingStats = `FPS: ${fps.toFixed(1)} | 编码: ${frameEncodingTime.toFixed(2)}ms | 渲染: ${frameRenderingTime.toFixed(2)}ms`;
          frameCount = 0;
          lastFpsUpdateTime = now;
        }
      }
    });
    
    this.mapView.addOnWillStartRenderingMapListener(() => {
      this.logEvent('渲染', '🗺️ 地图即将开始渲染');
    });
    
    this.mapView.addOnDidFinishRenderingMapListener((fully: boolean) => {
      this.logEvent('渲染', `🗺️ 地图渲染完成 (完整: ${fully ? '是' : '否'})`);
    });
    
    // ========== 样式事件监听器 ==========
    
    this.mapView.addOnDidFinishLoadingStyleListener(() => {
      this.logEvent('样式', '🎨 样式加载完成');
    });
    
    this.mapView.addOnStyleImageMissingListener((id: string) => {
      this.logEvent('样式', `⚠️ 样式图片缺失: ${id}`);
    });
    
    // ========== 其他事件监听器 ==========
    
    this.mapView.addOnDidBecomeIdleListener(() => {
      this.logEvent('状态', '💤 地图进入空闲状态');
    });
    
    this.mapView.addOnSourceChangedListener((id: string) => {
      this.logEvent('状态', `🔄 数据源改变: ${id}`);
    });
    
    this.logEvent('系统', '✅ 所有事件监听器已注册');
    hilog.info(DOMAIN, 'EventListenersTest', 'All event listeners registered');
  }

  /**
   * 测试相机移动 (flyTo)
   */
  private testCameraMove(): void {
    if (!this.map) {
      this.logEvent('测试', '❌ 地图未就绪');
      return;
    }
    
    this.logEvent('测试', '🎬 触发相机移动 (flyTo 上海)');
    
    try {
      // flyTo 到上海
      const options: maplibre.CameraOptions = {
        center: new maplibre.LatLng(31.2304, 121.4737),
        zoom: 13
      };
      this.map.flyTo(options, 3000);
      this.statusMessage = '正在飞往上海...';
    } catch (error) {
      this.logEvent('测试', `❌ 相机移动失败: ${error.message}`);
      hilog.error(DOMAIN, 'EventListenersTest', `flyTo failed: ${error.message}`);
    }
  }

  /**
   * 测试相机动画 (easeTo)
   */
  private testCameraAnimation(): void {
    if (!this.map) {
      this.logEvent('测试', '❌ 地图未就绪');
      return;
    }
    
    this.logEvent('测试', '🎬 触发相机动画 (easeTo 深圳)');
    
    try {
      // easeTo 到深圳
      const options: maplibre.CameraOptions = {
        center: new maplibre.LatLng(22.5431, 114.0579),
        zoom: 12
      };
      this.map.easeTo(options, 2000);
      this.statusMessage = '正在移动到深圳...';
    } catch (error) {
      this.logEvent('测试', `❌ 相机动画失败: ${error.message}`);
      hilog.error(DOMAIN, 'EventListenersTest', `easeTo failed: ${error.message}`);
    }
  }

  /**
   * 测试样式切换
   */
  private testStyleChange(): void {
    if (!this.mapView) {
      this.logEvent('测试', '❌ 地图未就绪');
      return;
    }
    
    this.currentStyleIndex = (this.currentStyleIndex + 1) % this.styleUrls.length;
    const newStyle = this.styleUrls[this.currentStyleIndex];
    
    this.logEvent('测试', `🎬 切换样式 (索引: ${this.currentStyleIndex})`);
    
    try {
      this.mapView.setStyleUrl(newStyle);
      this.statusMessage = '正在切换样式...';
    } catch (error) {
      this.logEvent('测试', `❌ 样式切换失败: ${error.message}`);
      hilog.error(DOMAIN, 'EventListenersTest', `setStyleUrl failed: ${error.message}`);
    }
  }

  /**
   * 测试重置视图
   */
  private testResetView(): void {
    if (!this.map) {
      this.logEvent('测试', '❌ 地图未就绪');
      return;
    }
    
    this.logEvent('测试', '🎬 重置视图 (返回北京)');
    
    try {
      this.map.jumpTo(0, 39.9042, 116.4074, 0, 12);
      this.statusMessage = '视图已重置';
    } catch (error) {
      this.logEvent('测试', `❌ 重置视图失败: ${error.message}`);
      hilog.error(DOMAIN, 'EventListenersTest', `jumpTo failed: ${error.message}`);
    }
  }

  /**
   * 清除日志
   */
  private clearLog(): void {
    this.eventLog = [];
    this.eventCount = 0;
    this.statusMessage = '日志已清除';
    hilog.info(DOMAIN, 'EventListenersTest', 'Event log cleared');
  }

  /**
   * 清除统计
   */
  private clearStats(): void {
    this.eventStats = {};
    this.statusMessage = '统计已清除';
    hilog.info(DOMAIN, 'EventListenersTest', 'Event stats cleared');
  }

  /**
   * 添加事件日志 (增强版，支持分类统计)
   */
  private logEvent(category: string, message: string): void {
    const timestamp = new Date().toLocaleTimeString('zh-CN', { 
      hour12: false,
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      fractionalSecondDigits: 3
    });
    const logMessage = `[${timestamp}] [${category}] ${message}`;
    this.eventLog.unshift(logMessage);
    this.eventCount++;
    
    // 更新统计
    this.eventStats[category] = (this.eventStats[category] || 0) + 1;
    
    // 限制日志数量
    if (this.eventLog.length > 100) {
      this.eventLog = this.eventLog.slice(0, 100);
    }
    
    hilog.info(DOMAIN, 'EventListenersTest', logMessage);
  }

  /**
   * 根据事件内容获取颜色
   */
  private getEventColor(event: string): string {
    if (event.includes('[相机]')) return '#2196F3';
    if (event.includes('[加载]')) return '#4CAF50';
    if (event.includes('[渲染]')) return '#FF9800';
    if (event.includes('[样式]')) return '#9C27B0';
    if (event.includes('[状态]')) return '#00BCD4';
    if (event.includes('[测试]')) return '#E91E63';
    if (event.includes('[系统]')) return '#607D8B';
    if (event.includes('[生命周期]')) return '#8BC34A';
    if (event.includes('[控制]')) return '#FF5722';
    return '#333333';
  }

  /**
   * 根据分类获取颜色
   */
  private getCategoryColor(category: string): string {
    if (category === '相机') return '#2196F3';
    if (category === '加载') return '#4CAF50';
    if (category === '渲染') return '#FF9800';
    if (category === '样式') return '#9C27B0';
    if (category === '状态') return '#00BCD4';
    if (category === '测试') return '#E91E63';
    if (category === '系统') return '#607D8B';
    if (category === '生命周期') return '#8BC34A';
    if (category === '控制') return '#FF5722';
    return '#333333';
  }

  build() {
    Column() {
      TestPageLayout({
        title: '事件监听器测试',
        mapArea: (): void => this.MapAreaBuilder(),
        controlArea: (): void => this.ControlButtonsBuilder()
      })
    }
    .width('100%')
    .height('100%')
  }
}
