/**
 * CoordinateConversionTestPage - 坐标转换计算测试页面
 * 
 * 测试接口：
 * - pixelForLatLng() - 经纬度转屏幕坐标
 * - latLngForPixel() - 屏幕坐标转经纬度
 * - projectedMetersForLatLng() - 经纬度转投影米
 * - latLngForProjectedMeters() - 投影米转经纬度
 * - getMetersPerPixelAtLatitude() - 计算每像素米数
 */

import { TestPageLayout } from '../components/TestPageLayout';
import { NativeMapView } from '../maps/NativeMapView';
import maplibre from 'libmaplibre_native.so';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../constants/HiLogConstants';

@Entry
@Component
struct CoordinateConversionTestPage {
  @State statusMessage: string = '等待操作...';
  @State mapReady: boolean = false;
  @State conversionResult: string = '';
  
  private mapView: maplibre.NativeMapView | null = null;
  
  // 测试坐标：北京天安门
  private readonly testLat: number = 39.9042;
  private readonly testLng: number = 116.4074;

  /**
   * 地图区域构建器
   */
  @Builder
  MapAreaBuilder() {
    NativeMapView({
      styleUrl: 'https://demotiles.maplibre.org/style.json',
      initialLatitude: this.testLat,
      initialLongitude: this.testLng,
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
    
    // 转换结果
    if (this.conversionResult) {
      Text(this.conversionResult)
        .fontSize(12)
        .width('100%')
        .padding(12)
        .backgroundColor('#E0F7FA')
        .borderRadius(4)
        .fontColor('#006064')
        .maxLines(10)
    }
    
    // 屏幕坐标转换
    Text('屏幕坐标转换')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Row() {
      Button('经纬度→屏幕')
        .width('48%')
        .onClick(() => {
          this.latLngToPixel();
        })
        .enabled(this.mapReady)
      
      Button('屏幕→经纬度')
        .width('48%')
        .margin({ left: 8 })
        .onClick(() => {
          this.pixelToLatLng();
        })
        .enabled(this.mapReady)
    }
    .width('100%')
    
    Divider()
    
    // 投影坐标转换
    Text('投影坐标转换')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Row() {
      Button('经纬度→投影米')
        .width('48%')
        .onClick(() => {
          this.latLngToProjectedMeters();
        })
        .enabled(this.mapReady)
      
      Button('投影米→经纬度')
        .width('48%')
        .margin({ left: 8 })
        .onClick(() => {
          this.projectedMetersToLatLng();
        })
        .enabled(this.mapReady)
    }
    .width('100%')
    
    Divider()
    
    // 分辨率计算
    Text('地图分辨率')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Button('计算地图分辨率')
      .width('100%')
      .onClick(() => {
        this.calculateMapResolution();
      })
      .enabled(this.mapReady)
  }

  build() {
    Column() {
      TestPageLayout({
        title: '坐标转换计算测试',
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
      hilog.info(DOMAIN, 'CoordinateConversionTestPage', 'Map ready');
    }
  }

  /**
   * 经纬度转屏幕坐标
   */
  private latLngToPixel(): void {
    if (!this.mapView) return;
    
    try {
      const point = this.mapView.pixelForLatLng(this.testLat, this.testLng);
      
      if (point) {
        this.conversionResult = `经纬度→屏幕坐标:\n\n` +
          `输入:\n` +
          `  纬度: ${this.testLat}°\n` +
          `  经度: ${this.testLng}°\n\n` +
          `输出:\n` +
          `  X: ${point.x.toFixed(2)} px\n` +
          `  Y: ${point.y.toFixed(2)} px`;
        
        this.statusMessage = '✅ 转换成功';
        
        hilog.info(DOMAIN, 'CoordinateConversionTestPage', 
          `LatLng to Pixel: (${this.testLat}, ${this.testLng}) -> (${point.x}, ${point.y})`);
      }
    } catch (error) {
      this.statusMessage = `❌ 转换失败: ${error.message}`;
      hilog.error(DOMAIN, 'CoordinateConversionTestPage', `LatLng to Pixel failed: ${error.message}`);
    }
  }

  /**
   * 屏幕坐标转经纬度
   */
  private pixelToLatLng(): void {
    if (!this.mapView) return;
    
    try {
      // 使用屏幕中心点 (0, 0)
      const latLng = this.mapView.latLngForPixel(0, 0);
      
      if (latLng) {
        this.conversionResult = `屏幕坐标→经纬度:\n\n` +
          `输入:\n` +
          `  X: 0 px (屏幕中心)\n` +
          `  Y: 0 px (屏幕中心)\n\n` +
          `输出:\n` +
          `  纬度: ${latLng.latitude.toFixed(6)}°\n` +
          `  经度: ${latLng.longitude.toFixed(6)}°`;
        
        this.statusMessage = '✅ 转换成功';
        
        hilog.info(DOMAIN, 'CoordinateConversionTestPage', 
          `Pixel to LatLng: (0, 0) -> (${latLng.latitude}, ${latLng.longitude})`);
      }
    } catch (error) {
      this.statusMessage = `❌ 转换失败: ${error.message}`;
      hilog.error(DOMAIN, 'CoordinateConversionTestPage', `Pixel to LatLng failed: ${error.message}`);
    }
  }

  /**
   * 经纬度转投影米
   */
  private latLngToProjectedMeters(): void {
    if (!this.mapView) return;
    
    try {
      const meters = this.mapView.projectedMetersForLatLng(this.testLat, this.testLng);
      
      if (meters) {
        this.conversionResult = `经纬度→投影米:\n\n` +
          `输入:\n` +
          `  纬度: ${this.testLat}°\n` +
          `  经度: ${this.testLng}°\n\n` +
          `输出:\n` +
          `  北向: ${meters.northing.toFixed(2)} m\n` +
          `  东向: ${meters.easting.toFixed(2)} m`;
        
        this.statusMessage = '✅ 转换成功';
        
        hilog.info(DOMAIN, 'CoordinateConversionTestPage', 
          `LatLng to Meters: (${this.testLat}, ${this.testLng}) -> (${meters.northing}, ${meters.easting})`);
      }
    } catch (error) {
      this.statusMessage = `❌ 转换失败: ${error.message}`;
      hilog.error(DOMAIN, 'CoordinateConversionTestPage', `LatLng to Meters failed: ${error.message}`);
    }
  }

  /**
   * 投影米转经纬度
   */
  private projectedMetersToLatLng(): void {
    if (!this.mapView) return;
    
    try {
      // 先获取测试点的投影米坐标
      const meters = this.mapView.projectedMetersForLatLng(this.testLat, this.testLng);
      
      if (meters) {
        // 再转换回经纬度
        const latLng = this.mapView.latLngForProjectedMeters(meters.northing, meters.easting);
        
        if (latLng) {
          this.conversionResult = `投影米→经纬度:\n\n` +
            `输入:\n` +
            `  北向: ${meters.northing.toFixed(2)} m\n` +
            `  东向: ${meters.easting.toFixed(2)} m\n\n` +
            `输出:\n` +
            `  纬度: ${latLng.latitude.toFixed(6)}°\n` +
            `  经度: ${latLng.longitude.toFixed(6)}°`;
          
          this.statusMessage = '✅ 转换成功';
          
          hilog.info(DOMAIN, 'CoordinateConversionTestPage', 
            `Meters to LatLng: (${meters.northing}, ${meters.easting}) -> (${latLng.latitude}, ${latLng.longitude})`);
        }
      }
    } catch (error) {
      this.statusMessage = `❌ 转换失败: ${error.message}`;
      hilog.error(DOMAIN, 'CoordinateConversionTestPage', `Meters to LatLng failed: ${error.message}`);
    }
  }

  /**
   * 计算地图分辨率
   */
  private calculateMapResolution(): void {
    if (!this.mapView) return;
    
    try {
      const currentZoom = this.mapView.getZoom();
      const currentLat = this.mapView.getLatLng().latitude;
      
      // 计算当前位置和缩放级别下的分辨率
      const metersPerPixel = this.mapView.getMetersPerPixelAtLatitude(currentLat, currentZoom);
      
      // 计算不同缩放级别的分辨率
      const zoom10 = this.mapView.getMetersPerPixelAtLatitude(currentLat, 10);
      const zoom15 = this.mapView.getMetersPerPixelAtLatitude(currentLat, 15);
      const zoom20 = this.mapView.getMetersPerPixelAtLatitude(currentLat, 20);
      
      this.conversionResult = `地图分辨率计算:\n\n` +
        `当前位置: ${currentLat.toFixed(4)}°\n` +
        `当前缩放: ${currentZoom.toFixed(2)}\n\n` +
        `分辨率:\n` +
        `  当前: ${metersPerPixel.toFixed(4)} m/px\n` +
        `  Zoom 10: ${zoom10.toFixed(4)} m/px\n` +
        `  Zoom 15: ${zoom15.toFixed(4)} m/px\n` +
        `  Zoom 20: ${zoom20.toFixed(4)} m/px`;
      
      this.statusMessage = '✅ 计算完成';
      
      hilog.info(DOMAIN, 'CoordinateConversionTestPage', 
        `Resolution at zoom ${currentZoom}: ${metersPerPixel} m/px`);
    } catch (error) {
      this.statusMessage = `❌ 计算失败: ${error.message}`;
      hilog.error(DOMAIN, 'CoordinateConversionTestPage', `Resolution calculation failed: ${error.message}`);
    }
  }
}

