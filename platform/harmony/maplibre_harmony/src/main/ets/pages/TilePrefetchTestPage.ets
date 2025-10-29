/**
 * TilePrefetchTestPage - 瓦片预加载测试页面
 * 
 * 测试接口：
 * - setPrefetchTiles/getPrefetchTiles - 启用/禁用预加载
 * - setPrefetchZoomDelta/getPrefetchZoomDelta - 预加载层级差
 */

import { TestPageLayout } from '../components/TestPageLayout';
import { NativeMapView } from '../maps/NativeMapView';
import maplibre from 'libmaplibre_native.so';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../constants/HiLogConstants';

@Entry
@Component
struct TilePrefetchTestPage {
  @State statusMessage: string = '等待操作...';
  @State mapReady: boolean = false;
  @State prefetchInfo: string = '';
  @State prefetchEnabled: boolean = false;
  
  private mapView: maplibre.NativeMapView | null = null;

  /**
   * 地图区域构建器
   */
  @Builder
  MapAreaBuilder() {
    NativeMapView({
      styleUrl: 'https://demotiles.maplibre.org/style.json',
      initialLatitude: 39.9042,
      initialLongitude: 116.4074,
      initialZoom: 10,
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
   * 控制区域构建器
   */
  @Builder
  ControlAreaBuilder() {
    // 状态信息
    Text(this.statusMessage)
      .fontSize(14)
      .width('100%')
      .padding(12)
      .backgroundColor('#F8F8F8')
      .borderRadius(4)
    
    // 预加载配置信息
    if (this.prefetchInfo) {
      Text(this.prefetchInfo)
        .fontSize(12)
        .width('100%')
        .padding(12)
        .backgroundColor(this.prefetchEnabled ? '#E8F5E9' : '#FFEBEE')
        .borderRadius(4)
        .fontColor(this.prefetchEnabled ? '#2E7D32' : '#C62828')
    }
    
    // 预加载控制
    Text('瓦片预加载控制')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Row() {
      Button('启用预加载')
        .width('48%')
        .backgroundColor('#4CAF50')
        .onClick(() => {
          this.enablePrefetch();
        })
        .enabled(this.mapReady && !this.prefetchEnabled)
      
      Button('禁用预加载')
        .width('48%')
        .margin({ left: 8 })
        .backgroundColor('#F44336')
        .onClick(() => {
          this.disablePrefetch();
        })
        .enabled(this.mapReady && this.prefetchEnabled)
    }
    .width('100%')
    
    Divider()
    
    // 预加载层级差配置
    Text('预加载层级差配置')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Row() {
      Button('Delta = 1')
        .width('48%')
        .onClick(() => {
          this.setPrefetchDelta(1);
        })
        .enabled(this.mapReady)
      
      Button('Delta = 2')
        .width('48%')
        .margin({ left: 8 })
        .onClick(() => {
          this.setPrefetchDelta(2);
        })
        .enabled(this.mapReady)
    }
    .width('100%')
    
    Button('显示当前配置')
      .width('100%')
      .onClick(() => {
        this.showCurrentConfig();
      })
      .enabled(this.mapReady)
    
    Divider()
    
    // 功能说明
    Text('功能说明')
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Text('• 预加载：提前加载周边瓦片\n• Delta：预加载的缩放层级差\n• Delta越大，预加载范围越广')
      .fontSize(12)
      .width('100%')
      .fontColor('#666666')
  }

  build() {
    Column() {
      TestPageLayout({
        title: '瓦片预加载测试',
        mapArea: this.MapAreaBuilder,
        controlArea: this.ControlAreaBuilder
      })
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 地图就绪回调
   */
  private onMapReady(mapView?: maplibre.NativeMapView): void {
    if (mapView) {
      this.mapView = mapView;
      this.mapReady = true;
      this.statusMessage = '✅ 地图加载成功';
      this.showCurrentConfig();
      hilog.info(DOMAIN, 'TilePrefetchTestPage', 'Map ready');
    }
  }

  /**
   * 启用瓦片预加载
   */
  private enablePrefetch(): void {
    if (!this.mapView) return;
    
    try {
      this.mapView.setPrefetchTiles(true);
      this.prefetchEnabled = true;
      
      this.statusMessage = '✅ 已启用瓦片预加载';
      this.showCurrentConfig();
      
      hilog.info(DOMAIN, 'TilePrefetchTestPage', 'Prefetch enabled');
    } catch (error) {
      this.statusMessage = `❌ 启用失败: ${error.message}`;
      hilog.error(DOMAIN, 'TilePrefetchTestPage', `Failed to enable prefetch: ${error.message}`);
    }
  }

  /**
   * 禁用瓦片预加载
   */
  private disablePrefetch(): void {
    if (!this.mapView) return;
    
    try {
      this.mapView.setPrefetchTiles(false);
      this.prefetchEnabled = false;
      
      this.statusMessage = '✅ 已禁用瓦片预加载';
      this.showCurrentConfig();
      
      hilog.info(DOMAIN, 'TilePrefetchTestPage', 'Prefetch disabled');
    } catch (error) {
      this.statusMessage = `❌ 禁用失败: ${error.message}`;
      hilog.error(DOMAIN, 'TilePrefetchTestPage', `Failed to disable prefetch: ${error.message}`);
    }
  }

  /**
   * 设置预加载层级差
   */
  private setPrefetchDelta(delta: number): void {
    if (!this.mapView) return;
    
    try {
      this.mapView.setPrefetchZoomDelta(delta);
      
      this.statusMessage = `✅ 已设置预加载层级差为 ${delta}`;
      this.showCurrentConfig();
      
      hilog.info(DOMAIN, 'TilePrefetchTestPage', `Set prefetch delta: ${delta}`);
    } catch (error) {
      this.statusMessage = `❌ 设置失败: ${error.message}`;
      hilog.error(DOMAIN, 'TilePrefetchTestPage', `Failed to set prefetch delta: ${error.message}`);
    }
  }

  /**
   * 显示当前配置
   */
  private showCurrentConfig(): void {
    if (!this.mapView) return;
    
    try {
      this.prefetchEnabled = this.mapView.getPrefetchTiles();
      const delta = this.mapView.getPrefetchZoomDelta();
      
      this.prefetchInfo = `当前预加载配置:\n` +
        `状态: ${this.prefetchEnabled ? '已启用' : '已禁用'}\n` +
        `层级差 (Delta): ${delta}`;
      
      hilog.info(DOMAIN, 'TilePrefetchTestPage', 
        `Prefetch - Enabled: ${this.prefetchEnabled}, Delta: ${delta}`);
    } catch (error) {
      this.statusMessage = `❌ 获取配置失败: ${error.message}`;
      hilog.error(DOMAIN, 'TilePrefetchTestPage', `Failed to get config: ${error.message}`);
    }
  }
}

