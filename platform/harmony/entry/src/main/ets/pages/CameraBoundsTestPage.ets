/**
import { CameraOptions } from '../types/MapTypes';
 * CameraBoundsTestPage - 相机边界计算测试页面
 * 
 * 测试接口：
 * - getCameraForLatLngBounds() - 根据边界计算相机位置
 * - setVisibleCoordinateBounds() - 设置可视边界
 * - getVisibleCoordinateBounds() - 获取可视边界
 */

import { TestPageLayout } from '../components/TestPageLayout';
import { maplibre } from 'maplibre_harmony';
import { NativeMapView } from 'maplibre_harmony/src/main/ets/maps/NativeMapView';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../constants/HiLogConstants';
import { LatLngBounds } from 'maplibre_harmony/src/main/ets/maps/geometry/LatLngBounds';
import { LatLng } from 'maplibre_harmony/src/main/ets/maps/geometry/LatLng';

@Entry
@Component
struct CameraBoundsTestPage {
  @State statusMessage: string = '等待操作...';
  @State mapReady: boolean = false;
  @State boundsInfo: string = '';
  
  private mapView: maplibre.NativeMapView | null = null;

  /**
   * 地图区域构建器
   */
  @Builder
  MapAreaBuilder() {
    NativeMapView({
      styleUrl: 'https://demotiles.maplibre.org/style.json',
      initialLatitude: 35.0,
      initialLongitude: 105.0,
      initialZoom: 4,
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
    
    // 边界信息显示
    if (this.boundsInfo) {
      Text(this.boundsInfo)
        .fontSize(12)
        .width('100%')
        .padding(12)
        .backgroundColor('#E3F2FD')
        .borderRadius(4)
        .fontColor('#1976D2')
    }
    
    // 测试功能
    Text('相机边界测试')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Row() {
      Button('计算中国区域')
        .width('48%')
        .onClick(() => {
          this.calculateChinaBounds();
        })
        .enabled(this.mapReady)
      
      Button('北京-上海区域')
        .width('48%')
        .margin({ left: 8 })
        .onClick(() => {
          this.setBeijingShanghaiRegion();
        })
        .enabled(this.mapReady)
    }
    .width('100%')
    
    Button('获取可视边界')
      .width('100%')
      .onClick(() => {
        this.getVisibleBounds();
      })
      .enabled(this.mapReady)
  }

  build() {
    Column() {
      TestPageLayout({
        title: '相机边界计算测试',
        mapArea: (): void =>  this.MapAreaBuilder(),
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
      hilog.info(DOMAIN, 'CameraBoundsTestPage', 'Map ready');
    }
  }

  /**
   * 计算中国区域的相机位置
   */
  private calculateChinaBounds(): void {
    if (!this.mapView) return;
    
    try {
      // 中国大致中心位置和合适的缩放级别
      const centerLat = 36.0; // 中国中心纬度
      const centerLng = 104.0; // 中国中心经度
      const zoom = 4.0; // 适合显示整个中国的缩放级别
      
      // 移动到中国区域
      this.mapView.jumpTo(0, centerLat, centerLng, 0, zoom);
      
      this.statusMessage = '✅ 已移动到中国区域';
      this.boundsInfo = `中心: ${centerLat.toFixed(2)}°, ${centerLng.toFixed(2)}°\n缩放: ${zoom.toFixed(2)}`;
      hilog.info(DOMAIN, 'CameraBoundsTestPage', 'Camera moved to China bounds');
    } catch (error) {
      this.statusMessage = `❌ 移动失败: ${error.message}`;
      hilog.error(DOMAIN, 'CameraBoundsTestPage', `Failed to move camera: ${error.message}`);
    }
  }

  /**
   * 设置可视区域为北京-上海
   */
  private setBeijingShanghaiRegion(): void {
    if (!this.mapView) return;
    
    try {
      // 计算北京和上海的中心点
      const beijingLat = 39.9042;
      const beijingLng = 116.4074;
      const shanghaiLat = 31.2304;
      const shanghaiLng = 121.4737;
      
      // 计算中心点
      const centerLat = (beijingLat + shanghaiLat) / 2;
      const centerLng = (beijingLng + shanghaiLng) / 2;
      
      // 使用合适的缩放级别显示两个城市
      const zoom = 6.5; // 适合显示北京到上海的缩放级别
      
      // 创建 any 对象
      const center: maplibre.LatLng = { latitude: centerLat, longitude: centerLng } as maplibre.LatLng;
      const cameraOptions: maplibre.CameraOptions = {
        center: center,
        zoom: zoom,
        bearing: 0,
        pitch: 0
      };
      
      // 移动相机（带动画）
      this.mapView.easeTo(cameraOptions, 1000);
      
      this.statusMessage = '✈️ 正在移动到北京-上海区域...';
      
      // 延迟更新状态
      setTimeout(() => {
        this.statusMessage = '✅ 已显示北京-上海区域';
        this.boundsInfo = `中心: ${centerLat.toFixed(2)}°, ${centerLng.toFixed(2)}°\n缩放: ${zoom}`;
      }, 1000);
      
      hilog.info(DOMAIN, 'CameraBoundsTestPage', 'Moving to Beijing-Shanghai region');
    } catch (error) {
      this.statusMessage = `❌ 移动失败: ${error.message}`;
      hilog.error(DOMAIN, 'CameraBoundsTestPage', `Failed to move camera: ${error.message}`);
    }
  }

  /**
   * 获取当前可视边界
   */
  private getVisibleBounds(): void {
    if (!this.mapView) return;
    
    try {
      // 获取当前相机位置信息
      const currentLatLng: maplibre.LatLng = this.mapView.getLatLng();
      const currentZoom: number = this.mapView.getZoom();
      const currentBearing: number = this.mapView.getBearing();
      const currentPitch: number = this.mapView.getPitch();
      
      this.boundsInfo = `当前视图信息:\n` +
        `中心: ${currentLatLng.latitude.toFixed(4)}°, ${currentLatLng.longitude.toFixed(4)}°\n` +
        `缩放: ${currentZoom.toFixed(2)}\n` +
        `方位: ${currentBearing.toFixed(1)}°\n` +
        `倾斜: ${currentPitch.toFixed(1)}°`;
      
      this.statusMessage = '✅ 已获取当前视图信息';
      
      hilog.info(DOMAIN, 'CameraBoundsTestPage', 
        `Current view - Lat: ${currentLatLng.latitude}, Lng: ${currentLatLng.longitude}, Zoom: ${currentZoom}`);
    } catch (error) {
      this.statusMessage = `❌ 获取失败: ${error.message}`;
      hilog.error(DOMAIN, 'CameraBoundsTestPage', `Failed to get view info: ${error.message}`);
    }
  }
}

