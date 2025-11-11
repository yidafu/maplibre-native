import { MapView, Marker, Icon, NativeMapView, MapLibreMap } from 'maplibre_harmony';
import { TestPageLayout } from '../common/TestPageLayout';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';

/**
 * MapStateTestPage - 地图状态测试页面
 * 
 * 测试接口：
 * - isFullyLoaded() - 检查地图是否加载完成
 * - triggerRepaint() - 触发重绘
 */

@Entry
@Component
struct MapStateTestPage {
  @State statusMessage: string = '等待操作...';
  @State mapReady: boolean = false;
  @State stateInfo: string = '';
  @State isLoaded: boolean = false;
  @State currentStyleIndex: number = 0;
  
  private mapView: NativeMapView | null = null;
  
  // 测试样式列表
  private readonly styleUrls: string[] = [
    'https://demotiles.maplibre.org/style.json',
    'https://tiles.versatiles.org/styles/dark-matter/style.json',
  ]

  /**
   * 地图区域构建器
   */
  @Builder
  buildMapContent() {
    MapView({
      styleUrl: this.styleUrls[0],
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 5,
      initialBearing: 0,
      initialPitch: 0,
      onMapReady: this.onMapReady,
    })
  }

  /**
   * 控制区域构建器
   */
  @Builder
  buildControlPanel() {
    // 状态信息
    Text(this.statusMessage)
      .fontSize(14)
      .width('100%')
      .padding(12)
      .backgroundColor('#F8F8F8')
      .borderRadius(4)
    
    // 地图状态信息
    if (this.stateInfo) {
      Text(this.stateInfo)
        .fontSize(12)
        .width('100%')
        .padding(12)
        .backgroundColor(this.isLoaded ? '#E8F5E9' : '#FFF3E0')
        .borderRadius(4)
        .fontColor(this.isLoaded ? '#2E7D32' : '#E65100')
    }
    
    // 状态检查
    Text('地图状态检查')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Row() {
      Button('检查加载状态')
        .width('48%')
        .onClick(() => {
          this.checkLoadState();
        })
        .enabled(this.mapReady)
      
      Button('自动检测')
        .width('48%')
        .margin({ left: 8 })
        .onClick(() => {
          this.autoCheckState();
        })
        .enabled(this.mapReady)
    }
    .width('100%')
    
    Divider()
    
    // 重绘测试
    Text('重绘测试')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Button('触发强制重绘')
      .width('100%')
      .onClick(() => {
        this.triggerRepaint();
      })
      .enabled(this.mapReady)
    
    Divider()
    
    // 样式切换测试
    Text('样式切换测试')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Text('切换样式会改变加载状态')
      .fontSize(13)
      .width('100%')
      .fontColor('#666666')
    
    Button('切换地图样式')
      .width('100%')
      .onClick(() => {
        this.switchStyle();
      })
      .enabled(this.mapReady)
  }

  build() {
    Column() {
      TestPageLayout({
        showActionBar: true,
        title: '地图状态测试',
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      })
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 地图就绪回调
   */
  private onMapReady(map?: MapLibreMap): void {
    if (this.mapView) {
      this.mapView = this.mapView;
      this.mapReady = true;
      this.statusMessage = '✅ 地图初始化成功';
      
      // 延迟检查加载状态
      setTimeout(() => {
        this.checkLoadState();
      }, 1000);
      
      hilog.info(DOMAIN, 'MapStateTestPage', 'Map ready');
    }
  }

  /**
   * 检查加载状态
   */
  private checkLoadState(): void {
    if (!this.mapView) return;
    
    try {
      this.isLoaded = this.mapView.isFullyLoaded();
      
      const timestamp = new Date().toLocaleTimeString();
      
      this.stateInfo = `地图加载状态:\n\n` +
        `状态: ${this.isLoaded ? '✅ 已完全加载' : '⏳ 加载中...'}\n` +
        `检查时间: ${timestamp}`;
      
      this.statusMessage = this.isLoaded ? 
        '✅ 地图已完全加载' : 
        '⏳ 地图仍在加载中';
      
      hilog.info(DOMAIN, 'MapStateTestPage', `Map fully loaded: ${this.isLoaded}`);
    } catch (error) {
      this.statusMessage = `❌ 检查失败: ${error.message}`;
      hilog.error(DOMAIN, 'MapStateTestPage', `Failed to check load state: ${error.message}`);
    }
  }

  /**
   * 自动检测加载状态
   */
  private autoCheckState(): void {
    if (!this.mapView) return;
    
    this.statusMessage = '🔄 开始自动检测...';
    
    let checkCount = 0;
    const maxChecks = 10;
    
    const checkInterval = setInterval(() => {
      if (!this.mapView) {
        clearInterval(checkInterval);
        return;
      }
      
      try {
        this.isLoaded = this.mapView.isFullyLoaded();
        checkCount++;
        
        this.stateInfo = `自动检测进行中...\n\n` +
          `检测次数: ${checkCount}/${maxChecks}\n` +
          `当前状态: ${this.isLoaded ? '✅ 已加载' : '⏳ 加载中'}`;
        
        if (this.isLoaded) {
          this.statusMessage = `✅ 地图已完全加载（第${checkCount}次检测）`;
          clearInterval(checkInterval);
        } else if (checkCount >= maxChecks) {
          this.statusMessage = `⏱️ 达到最大检测次数，地图仍在加载`;
          clearInterval(checkInterval);
        }
      } catch (error) {
        this.statusMessage = `❌ 检测失败: ${error.message}`;
        clearInterval(checkInterval);
      }
    }, 500); // 每500ms检测一次
  }

  /**
   * 触发重绘
   */
  private triggerRepaint(): void {
    if (!this.mapView) return;
    
    try {
      this.mapView.triggerRepaint();
      
      this.statusMessage = '✅ 已触发地图重绘';
      
      hilog.info(DOMAIN, 'MapStateTestPage', 'Triggered repaint');
    } catch (error) {
      this.statusMessage = `❌ 触发失败: ${error.message}`;
      hilog.error(DOMAIN, 'MapStateTestPage', `Failed to trigger repaint: ${error.message}`);
    }
  }

  /**
   * 切换地图样式
   */
  private switchStyle(): void {
    if (!this.mapView) return;
    
    try {
      // 切换到下一个样式
      this.currentStyleIndex = (this.currentStyleIndex + 1) % this.styleUrls.length;
      const newStyleUrl = this.styleUrls[this.currentStyleIndex]
      
      this.mapView.setStyleUrl(newStyleUrl);
      
      // 样式切换后，地图会重新加载
      this.isLoaded = false;
      this.stateInfo = '⏳ 正在加载新样式...';
      this.statusMessage = `🔄 正在切换到样式 ${this.currentStyleIndex + 1}`;
      
      // 延迟检查加载状态
      setTimeout(() => {
        this.autoCheckState();
      }, 500);
      
      hilog.info(DOMAIN, 'MapStateTestPage', `Switched to style: ${newStyleUrl}`);
    } catch (error) {
      this.statusMessage = `❌ 切换失败: ${error.message}`;
      hilog.error(DOMAIN, 'MapStateTestPage', `Failed to switch style: ${error.message}`);
    }
  }
}

