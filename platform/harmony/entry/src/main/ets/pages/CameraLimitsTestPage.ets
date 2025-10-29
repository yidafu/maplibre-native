/**
 * CameraLimitsTestPage - 相机参数限制测试页面
 * 
 * 测试接口：
 * - setMinZoom/getMinZoom - 最小缩放级别
 * - setMaxZoom/getMaxZoom - 最大缩放级别
 * - setMinPitch/getMinPitch - 最小倾斜角度
 * - setMaxPitch/getMaxPitch - 最大倾斜角度
 */

import { TestPageLayout } from '../components/TestPageLayout';
import { NativeMapView } from 'maplibre_harmony/src/main/ets/maps/NativeMapView';
import maplibre from 'libmaplibre_native.so';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../constants/HiLogConstants';

@Entry
@Component
struct CameraLimitsTestPage {
  @State statusMessage: string = '等待操作...';
  @State mapReady: boolean = false;
  @State limitsInfo: string = '';
  
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
    
    // 限制参数信息
    if (this.limitsInfo) {
      Text(this.limitsInfo)
        .fontSize(12)
        .width('100%')
        .padding(12)
        .backgroundColor('#E8F5E9')
        .borderRadius(4)
        .fontColor('#2E7D32')
    }
    
    // 缩放限制测试
    Text('缩放限制测试')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Row() {
      Button('设置 Zoom 5-15')
        .width('48%')
        .onClick(() => {
          this.setZoomLimits();
        })
        .enabled(this.mapReady)
      
      Button('重置 Zoom 限制')
        .width('48%')
        .margin({ left: 8 })
        .onClick(() => {
          this.resetZoomLimits();
        })
        .enabled(this.mapReady)
    }
    .width('100%')
    
    Divider()
    
    // 倾斜限制测试
    Text('倾斜限制测试')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Row() {
      Button('设置 Pitch 0-45°')
        .width('48%')
        .onClick(() => {
          this.setPitchLimits();
        })
        .enabled(this.mapReady)
      
      Button('重置 Pitch 限制')
        .width('48%')
        .margin({ left: 8 })
        .onClick(() => {
          this.resetPitchLimits();
        })
        .enabled(this.mapReady)
    }
    .width('100%')
    
    Divider()
    
    // 显示当前限制
    Button('显示当前限制参数')
      .width('100%')
      .onClick(() => {
        this.showCurrentLimits();
      })
      .enabled(this.mapReady)
  }

  build() {
    Column() {
      TestPageLayout({
        title: '相机参数限制测试',
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
      this.showCurrentLimits();
      hilog.info(DOMAIN, 'CameraLimitsTestPage', 'Map ready');
    }
  }

  /**
   * 设置缩放限制 (5-15)
   */
  private setZoomLimits(): void {
    if (!this.mapView) return;
    
    try {
      this.mapView.setMinZoom(5);
      this.mapView.setMaxZoom(15);
      
      this.statusMessage = '✅ 已设置缩放范围 5-15';
      this.showCurrentLimits();
      
      hilog.info(DOMAIN, 'CameraLimitsTestPage', 'Set zoom limits: 5-15');
    } catch (error) {
      this.statusMessage = `❌ 设置失败: ${error.message}`;
      hilog.error(DOMAIN, 'CameraLimitsTestPage', `Failed to set zoom limits: ${error.message}`);
    }
  }

  /**
   * 重置缩放限制
   */
  private resetZoomLimits(): void {
    if (!this.mapView) return;
    
    try {
      this.mapView.setMinZoom(0);
      this.mapView.setMaxZoom(22);
      
      this.statusMessage = '✅ 已重置缩放限制 (0-22)';
      this.showCurrentLimits();
      
      hilog.info(DOMAIN, 'CameraLimitsTestPage', 'Reset zoom limits');
    } catch (error) {
      this.statusMessage = `❌ 重置失败: ${error.message}`;
      hilog.error(DOMAIN, 'CameraLimitsTestPage', `Failed to reset zoom limits: ${error.message}`);
    }
  }

  /**
   * 设置倾斜限制 (0-45°)
   */
  private setPitchLimits(): void {
    if (!this.mapView) return;
    
    try {
      this.mapView.setMinPitch(0);
      this.mapView.setMaxPitch(45);
      
      this.statusMessage = '✅ 已设置倾斜范围 0-45°';
      this.showCurrentLimits();
      
      hilog.info(DOMAIN, 'CameraLimitsTestPage', 'Set pitch limits: 0-45');
    } catch (error) {
      this.statusMessage = `❌ 设置失败: ${error.message}`;
      hilog.error(DOMAIN, 'CameraLimitsTestPage', `Failed to set pitch limits: ${error.message}`);
    }
  }

  /**
   * 重置倾斜限制
   */
  private resetPitchLimits(): void {
    if (!this.mapView) return;
    
    try {
      this.mapView.setMinPitch(0);
      this.mapView.setMaxPitch(60);
      
      this.statusMessage = '✅ 已重置倾斜限制 (0-60°)';
      this.showCurrentLimits();
      
      hilog.info(DOMAIN, 'CameraLimitsTestPage', 'Reset pitch limits');
    } catch (error) {
      this.statusMessage = `❌ 重置失败: ${error.message}`;
      hilog.error(DOMAIN, 'CameraLimitsTestPage', `Failed to reset pitch limits: ${error.message}`);
    }
  }

  /**
   * 显示当前限制参数
   */
  private showCurrentLimits(): void {
    if (!this.mapView) return;
    
    try {
      const minZoom = this.mapView.getMinZoom();
      const maxZoom = this.mapView.getMaxZoom();
      const minPitch = this.mapView.getMinPitch();
      const maxPitch = this.mapView.getMaxPitch();
      
      this.limitsInfo = `当前限制参数:\n` +
        `缩放: ${minZoom.toFixed(1)} - ${maxZoom.toFixed(1)}\n` +
        `倾斜: ${minPitch.toFixed(1)}° - ${maxPitch.toFixed(1)}°`;
      
      hilog.info(DOMAIN, 'CameraLimitsTestPage', 
        `Limits - Zoom: ${minZoom}-${maxZoom}, Pitch: ${minPitch}-${maxPitch}`);
    } catch (error) {
      this.statusMessage = `❌ 获取失败: ${error.message}`;
      hilog.error(DOMAIN, 'CameraLimitsTestPage', `Failed to get limits: ${error.message}`);
    }
  }
}

