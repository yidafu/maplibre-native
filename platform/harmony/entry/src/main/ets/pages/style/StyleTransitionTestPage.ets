import {maplibre, MapView, NativeMapView, MapLibreMap} from 'maplibre_harmony';
/**
 * StyleTransitionTestPage - 样式过渡选项测试页面
 * 
 * 测试接口：
 * - getTransitionOptions() - 获取过渡选项
 * - setTransitionOptions() - 设置过渡选项
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';
import type { JsonObject } from '../../types/EntryTypes';

@Entry
@Component
struct StyleTransitionTestPage {
  @State statusMessage: string = '等待操作...';
  @State mapReady: boolean = false;
  @State transitionInfo: string = '';
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
    Column() {

    MapView({
      styleUrl: this.styleUrls[0],
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 10,
      initialBearing: 0,
      initialPitch: 0,
      onMapReady: (map: MapLibreMap) => {
        this.onMapReady(map);
      }
    })
    }
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
      .backgroundColor('#F8F8F8')
      .borderRadius(4)
    
    // 过渡配置信息
    if (this.transitionInfo) {
      Text(this.transitionInfo)
        .fontSize(12)
        .width('100%')
        .backgroundColor('#F3E5F5')
        .borderRadius(4)
        .fontColor('#6A1B9A')
    }
    
    // 过渡速度配置
    Text('过渡速度配置')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    Row() {
      Button('快速 (100ms)')
        .width('48%')
        .onClick(() => {
          this.setFastTransition();
        })
        .enabled(this.mapReady)
      
      Button('慢速 (1000ms)')
        .width('48%')
        .margin({ left: 8 })
        .onClick(() => {
          this.setSlowTransition();
        })
        .enabled(this.mapReady)
    }
    .width('100%')
    Row() {
      Button('默认 (300ms)')
        .width('48%')
        .onClick(() => {
          this.setDefaultTransition();
        })
        .enabled(this.mapReady)
      
      Button('显示当前配置')
        .width('48%')
        .margin({ left: 8 })
        .onClick(() => {
          this.showCurrentTransition();
        })
        .enabled(this.mapReady)
    }
    .width('100%')
    Divider()
    
    // 样式切换测试
    Text('样式切换测试')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    Text('切换样式可查看过渡效果')
      .fontSize(13)
      .width('100%')
    
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
        title: '样式过渡选项测试',
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
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
      this.statusMessage = '✅ 地图加载成功';
      this.showCurrentTransition();
      hilog.info(DOMAIN, 'StyleTransitionTestPage', 'Map ready');
    }
  }

  /**
   * 设置快速过渡
   */
  private setFastTransition(): void {
    if (!this.mapView) return;
    
    try {
      this.mapView.setTransitionOptions({ duration: 100, delay: 0 });
      
      this.statusMessage = '✅ 已设置快速过渡 (100ms)';
      this.showCurrentTransition();
      
      hilog.info(DOMAIN, 'StyleTransitionTestPage', 'Set fast transition');
    } catch (error) {
      this.statusMessage = `❌ 设置失败: ${error.message}`;
      hilog.error(DOMAIN, 'StyleTransitionTestPage', `Failed to set fast transition: ${error.message}`);
    }
  }

  /**
   * 设置慢速过渡
   */
  private setSlowTransition(): void {
    if (!this.mapView) return;
    
    try {
      this.mapView.setTransitionOptions({ duration: 1000, delay: 100 });
      
      this.statusMessage = '✅ 已设置慢速过渡 (1000ms)';
      this.showCurrentTransition();
      
      hilog.info(DOMAIN, 'StyleTransitionTestPage', 'Set slow transition');
    } catch (error) {
      this.statusMessage = `❌ 设置失败: ${error.message}`;
      hilog.error(DOMAIN, 'StyleTransitionTestPage', `Failed to set slow transition: ${error.message}`);
    }
  }

  /**
   * 设置默认过渡
   */
  private setDefaultTransition(): void {
    if (!this.mapView) return;
    
    try {
      this.mapView.setTransitionOptions({ duration: 300, delay: 0 });
      
      this.statusMessage = '✅ 已设置默认过渡 (300ms)';
      this.showCurrentTransition();
      
      hilog.info(DOMAIN, 'StyleTransitionTestPage', 'Set default transition');
    } catch (error) {
      this.statusMessage = `❌ 设置失败: ${error.message}`;
      hilog.error(DOMAIN, 'StyleTransitionTestPage', `Failed to set default transition: ${error.message}`);
    }
  }

  /**
   * 显示当前过渡配置
   */
  private showCurrentTransition(): void {
    if (!this.mapView) return;
    
    try {
      const options: Record<string, Object> | null = this.mapView.getTransitionOptions() as Record<string, Object> | null;
      
      if (options) {
        this.transitionInfo = `当前过渡配置:\n` +
          `持续时间: ${options.duration ?? 0}ms\n` +
          `延迟: ${options.delay ?? 0}ms`;
        
        hilog.info(DOMAIN, 'StyleTransitionTestPage', 
          `Transition - Duration: ${options.duration}, Delay: ${options.delay}`);
      }
    } catch (error) {
      this.statusMessage = `❌ 获取配置失败: ${error.message}`;
      hilog.error(DOMAIN, 'StyleTransitionTestPage', `Failed to get transition: ${error.message}`);
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
      
      this.statusMessage = `✨ 正在切换样式... (样式 ${this.currentStyleIndex + 1})`;
      
      hilog.info(DOMAIN, 'StyleTransitionTestPage', `Switched to style: ${newStyleUrl}`);
    } catch (error) {
      this.statusMessage = `❌ 切换失败: ${error.message}`;
      hilog.error(DOMAIN, 'StyleTransitionTestPage', `Failed to switch style: ${error.message}`);
    }
  }
}

