/**
 * ProjectionTestPage - Projection API 测试页面
 * 
 * 测试内容：
 * - 地理坐标和屏幕坐标转换
 * - VisibleRegion 计算
 * - Attribution Button 显示
 */

import { NativeMapView } from 'maplibre_harmony/src/main/ets/maps/NativeMapView';
import { maplibre } from 'maplibre_harmony';
import { createLatLng } from 'maplibre_harmony/src/main/ets/maps/geometry/LatLng';
import { AttributionButton, DEFAULT_ATTRIBUTIONS } from 'maplibre_harmony/src/main/ets/maps/widgets/AttributionButton';
import { ScaleBarView, ScaleBarUnit } from 'maplibre_harmony/src/main/ets/maps/widgets/ScaleBarView';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../constants/HiLogConstants';
import router from '@ohos.router';

@Entry
@Component
struct ProjectionTestPage {
  @State private mapReady: boolean = false;
  @State private centerLatitude: number = 30.2741;
  @State private centerLongitude: number = 120.1551;
  @State private visibleRegionText: string = '未计算';
  @State private metersPerPixel: number = 0;
  
  private nativeMapView: maplibre.NativeMapView | null = null;
  
  build() {
    Column() {
      // 标题栏
      Row() {
        Text('Projection API 测试')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
        
        Blank()
        
        Button('返回')
          .onClick(() => {
            hilog.info(DOMAIN, 'ProjectionTest', 'Navigating back');
            router.back();
          })
          .margin({ right: 16 })
      }
      .width('100%')
      .height(56)
      .backgroundColor('#F7F7F7')
      
      // 地图视图
      Stack() {
        NativeMapView({
          styleUrl: 'https://demotiles.maplibre.org/style.json',
          initialLatitude: this.centerLatitude,
          initialLongitude: this.centerLongitude,
          initialZoom: 12,
          initialBearing: 0,
          initialPitch: 0,
          debugMode: false,
          onMapReady: (mapView?: maplibre.NativeMapView) => {
            this.onMapReady(mapView);
          }
        })
        .width('100%')
        .height('60%')
        .id('projection_test_map')
        
        // ScaleBar - 左下角
        ScaleBarView({
          isEnabled: true,
          unitSystem: ScaleBarUnit.Metric,
          maxWidth: 200
        })
        .position({ x: 8, y: '60%' })
        .translate({ y: -40 })
        .id('scaleBar')
        
        // Attribution Button - 右下角
        AttributionButton({
          isEnabled: true,
          tintColor: '#000000',
          iconSize: 24,
          attributions: DEFAULT_ATTRIBUTIONS
        })
        .position({ x: '100%', y: '60%' })
        .translate({ x: -40, y: -40 })
      }
      .width('100%')
      .height('60%')
      
      // 测试控制区
      Scroll() {
        Column({ space: 12 }) {
          Text('坐标转换测试')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          
          // 测试按钮
          Button('获取可见区域')
            .width('90%')
            .onClick(() => {
              this.testVisibleRegion();
            })
            .enabled(this.mapReady)
          
          Button('转换屏幕中心点')
            .width('90%')
            .onClick(() => {
              this.testScreenCenter();
            })
            .enabled(this.mapReady)
          
          Button('批量坐标转换')
            .width('90%')
            .onClick(() => {
              this.testBatchConversion();
            })
            .enabled(this.mapReady)
          
          Divider()
          
          // 结果显示
          Text('测试结果')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          
          Text(`地图中心: ${this.centerLatitude.toFixed(6)}, ${this.centerLongitude.toFixed(6)}`)
            .fontSize(14)
            .width('90%')
          
          Text(`每像素米数: ${this.metersPerPixel.toFixed(6)}`)
            .fontSize(14)
            .width('90%')
          
          Text('可见区域:')
            .fontSize(14)
            .width('90%')
          
          Text(this.visibleRegionText)
            .fontSize(12)
            .width('90%')
            .fontColor(Color.Gray)
        }
        .width('100%')
        .padding(16)
      }
      .width('100%')
      .height('40%')
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
  
  /**
   * 地图就绪回调
   */
  private onMapReady(mapView?: maplibre.NativeMapView): void {
    hilog.info(DOMAIN, 'ProjectionTest', 'Map ready');
    
    if (mapView) {
      this.nativeMapView = mapView;
      this.mapReady = true;
      
      // 初始化 metersPerPixel
      this.updateMetersPerPixel();
      
      hilog.info(DOMAIN, 'ProjectionTest', 'Map initialized');
    }
  }
  
  /**
   * 测试可见区域
   */
  private testVisibleRegion(): void {
    if (!this.nativeMapView) {
      hilog.warn(DOMAIN, 'ProjectionTest', 'Map not initialized');
      return;
    }
    
    try {
      const bounds = this.nativeMapView.getVisibleCoordinateBounds() as maplibre.LatLng[];
      
      if (bounds && bounds.length >= 2) {
        this.visibleRegionText = 
          `西南角: ${bounds[0].latitude.toFixed(6)}, ${bounds[0].longitude.toFixed(6)}\n` +
          `东北角: ${bounds[1].latitude.toFixed(6)}, ${bounds[1].longitude.toFixed(6)}\n` +
          `可见区域已计算`;
        
        hilog.info(DOMAIN, 'ProjectionTest', `Visible region calculated`);
      } else {
        this.visibleRegionText = '无法获取可见区域';
      }
    } catch (err) {
      const error = err as Error;
      hilog.error(DOMAIN, 'ProjectionTest', `Error getting visible region: ${error.message}`);
      this.visibleRegionText = `错误: ${error.message}`;
    }
  }
  
  /**
   * 测试屏幕中心点转换
   */
  private testScreenCenter(): void {
    if (!this.nativeMapView) {
      hilog.warn(DOMAIN, 'ProjectionTest', 'Map not initialized');
      return;
    }
    
    try {
      // 获取地图中心点
      const center: maplibre.LatLng = this.nativeMapView.getLatLng();
      
      this.centerLatitude = center.latitude;
      this.centerLongitude = center.longitude;
      
      hilog.info(DOMAIN, 'ProjectionTest', 
        `Map center: ${center.latitude.toFixed(6)}, ${center.longitude.toFixed(6)}`);
        
    } catch (error) {
      hilog.error(DOMAIN, 'ProjectionTest', `Error getting center: ${error}`);
    }
  }
  
  /**
   * 测试批量坐标转换
   */
  private testBatchConversion(): void {
    if (!this.nativeMapView) {
      hilog.warn(DOMAIN, 'ProjectionTest', 'Map not initialized');
      return;
    }
    
    try {
      // 创建测试坐标
      const testLatLngs = [
        createLatLng(30.27, 120.15),
        createLatLng(30.28, 120.16),
        createLatLng(30.29, 120.17),
        createLatLng(30.30, 120.18)
      ];
      
      // 批量转换（使用单个转换模拟批量）
      const startTime = Date.now();
      for (let i = 0; i < testLatLngs.length; i++) {
        const pixel = this.nativeMapView.pixelForLatLng(testLatLngs[i].latitude, testLatLngs[i].longitude);
        hilog.info(DOMAIN, 'ProjectionTest', 
          `[${i}] (${testLatLngs[i].latitude}, ${testLatLngs[i].longitude}) -> (${pixel.x}, ${pixel.y})`);
      }
      const endTime = Date.now();
      
      hilog.info(DOMAIN, 'ProjectionTest', 
        `Batch conversion of ${testLatLngs.length} points took ${endTime - startTime}ms`);
      
    } catch (error) {
      hilog.error(DOMAIN, 'ProjectionTest', `Error in batch conversion: ${error}`);
    }
  }
  
  /**
   * 更新每像素米数
   */
  private updateMetersPerPixel(): void {
    if (!this.nativeMapView) return;
    
    try {
      const zoom: number = this.nativeMapView.getZoom();
      this.metersPerPixel = this.nativeMapView.getMetersPerPixelAtLatitude(this.centerLatitude, zoom);
    } catch (error) {
      hilog.error(DOMAIN, 'ProjectionTest', `Error getting meters per pixel: ${error}`);
    }
  }
}

