/**
 * TileLodTestPage - 瓦片LOD配置测试页面
 * 
 * 测试接口：
 * - setTileLodMinRadius/getTileLodMinRadius - LOD最小半径
 * - setTileLodScale/getTileLodScale - LOD缩放因子
 * - setTileLodPitchThreshold/getTileLodPitchThreshold - LOD倾斜阈值
 * - setTileLodZoomShift/getTileLodZoomShift - LOD缩放偏移
 */

import { TestPageLayout } from '../components/TestPageLayout';
import { maplibre } from 'maplibre_harmony';
import { NativeMapView } from 'maplibre_harmony/src/main/ets/maps/NativeMapView';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../constants/HiLogConstants';

@Entry
@Component
struct TileLodTestPage {
  @State statusMessage: string = '等待操作...';
  @State mapReady: boolean = false;
  @State lodInfo: string = '';
  
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
      initialZoom: 12,
      initialBearing: 0,
      initialPitch: 45,
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
    
    // LOD配置信息
    if (this.lodInfo) {
      Text(this.lodInfo)
        .fontSize(12)
        .width('100%')
        .padding(12)
        .backgroundColor('#E1F5FE')
        .borderRadius(4)
        .fontColor('#01579B')
    }
    
    // LOD预设配置
    Text('LOD 预设配置')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Row() {
      Button('默认配置')
        .width('48%')
        .onClick(() => {
          this.setDefaultLod();
        })
        .enabled(this.mapReady)
      
      Button('高性能配置')
        .width('48%')
        .margin({ left: 8 })
        .onClick(() => {
          this.setHighPerformanceLod();
        })
        .enabled(this.mapReady)
    }
    .width('100%')
    
    Button('显示当前LOD配置')
      .width('100%')
      .onClick(() => {
        this.showCurrentLod();
      })
      .enabled(this.mapReady)
    
    Divider()
    
    // 功能说明
    Text('LOD 参数说明')
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Text('• MinRadius: LOD最小半径\n• Scale: LOD缩放因子\n• PitchThreshold: 倾斜阈值\n• ZoomShift: 缩放偏移')
      .fontSize(12)
      .width('100%')
      .fontColor('#666666')
  }

  build() {
    Column() {
      TestPageLayout({
        title: '瓦片LOD配置测试',
        mapArea: (): void => this.MapAreaBuilder(),
        controlArea: (): void => this.ControlAreaBuilder()
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
      this.showCurrentLod();
      hilog.info(DOMAIN, 'TileLodTestPage', 'Map ready');
    }
  }

  /**
   * 设置默认LOD配置
   */
  private setDefaultLod(): void {
    if (!this.mapView) return;
    
    try {
      this.mapView.setTileLodMinRadius(1.0);
      this.mapView.setTileLodScale(1.0);
      this.mapView.setTileLodPitchThreshold(60.0);
      this.mapView.setTileLodZoomShift(0.0);
      
      this.statusMessage = '✅ 已应用默认LOD配置';
      this.showCurrentLod();
      
      hilog.info(DOMAIN, 'TileLodTestPage', 'Set default LOD configuration');
    } catch (error) {
      this.statusMessage = `❌ 设置失败: ${error.message}`;
      hilog.error(DOMAIN, 'TileLodTestPage', `Failed to set default LOD: ${error.message}`);
    }
  }

  /**
   * 设置高性能LOD配置
   */
  private setHighPerformanceLod(): void {
    if (!this.mapView) return;
    
    try {
      // 高性能配置：减少细节以提高性能
      this.mapView.setTileLodMinRadius(1.5);
      this.mapView.setTileLodScale(0.8);
      this.mapView.setTileLodPitchThreshold(45.0);
      this.mapView.setTileLodZoomShift(1.0);
      
      this.statusMessage = '✅ 已应用高性能LOD配置';
      this.showCurrentLod();
      
      hilog.info(DOMAIN, 'TileLodTestPage', 'Set high performance LOD configuration');
    } catch (error) {
      this.statusMessage = `❌ 设置失败: ${error.message}`;
      hilog.error(DOMAIN, 'TileLodTestPage', `Failed to set high performance LOD: ${error.message}`);
    }
  }

  /**
   * 显示当前LOD配置
   */
  private showCurrentLod(): void {
    if (!this.mapView) return;
    
    try {
      const minRadius = this.mapView.getTileLodMinRadius();
      const scale: number = this.mapView.getTileLodScale();
      const pitchThreshold = this.mapView.getTileLodPitchThreshold();
      const zoomShift = this.mapView.getTileLodZoomShift();
      
      this.lodInfo = `当前LOD配置:\n` +
        `MinRadius: ${minRadius.toFixed(2)}\n` +
        `Scale: ${scale.toFixed(2)}\n` +
        `PitchThreshold: ${pitchThreshold.toFixed(1)}°\n` +
        `ZoomShift: ${zoomShift.toFixed(2)}`;
      
      hilog.info(DOMAIN, 'TileLodTestPage', 
        `LOD - MinRadius: ${minRadius}, Scale: ${scale}, Pitch: ${pitchThreshold}, Zoom: ${zoomShift}`);
    } catch (error) {
      this.statusMessage = `❌ 获取失败: ${error.message}`;
      hilog.error(DOMAIN, 'TileLodTestPage', `Failed to get LOD config: ${error.message}`);
    }
  }
}

