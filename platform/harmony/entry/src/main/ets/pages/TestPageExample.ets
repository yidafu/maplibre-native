/**
 * TestPageExample - TestPageLayout 使用示例
 * 
 * 展示如何使用 TestPageLayout 组件创建统一风格的测试页面
 */

import { TestPageLayout } from '../components/TestPageLayout';
import { NativeMapView } from 'maplibre_harmony/src/main/ets/maps/NativeMapView';
import maplibre from 'libmaplibre_native.so';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../constants/HiLogConstants';

@Entry
@Component
struct TestPageExample {
  @State currentTitle: string = 'TestPageLayout 使用示例';
  @State markerCount: number = 0;
  @State mapReady: boolean = false;
  @State statusMessage: string = '等待操作...';
  
  private mapView: maplibre.NativeMapView | null = null;

  /**
   * 地图区域构建器
   * 可以是地图组件，也可以是其他内容
   */
  @Builder
  MapAreaBuilder() {
    // 示例1：使用真实地图
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
    
    // 示例2：无地图时，可以显示说明信息
    // Column() {
    //   Text('这里可以显示地图')
    //     .fontSize(24)
    //     .fontWeight(FontWeight.Bold)
    //   
    //   Text('或者任何其他内容')
    //     .fontSize(14)
    //     .fontColor('#666666')
    //     .margin({ top: 12 })
    // }
    // .width('100%')
    // .height('100%')
    // .justifyContent(FlexAlign.Center)
    // .backgroundColor('#F5F5F5')
  }

  /**
   * 控制区域构建器
   * 包含所有测试按钮和控制组件
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
    
    // 功能分组1：地图控制
    Text('地图控制')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Row() {
      Button('放大')
        .width('48%')
        .onClick(() => {
          this.zoomIn();
        })
        .enabled(this.mapReady)
      
      Button('缩小')
        .width('48%')
        .margin({ left: 8 })
        .onClick(() => {
          this.zoomOut();
        })
        .enabled(this.mapReady)
    }
    .width('100%')
    
    Divider()
    
    // 功能分组2：Marker 控制
    Text('Marker 控制')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Row() {
      Button('添加 Marker')
        .width('48%')
        .onClick(() => {
          this.addMarker();
        })
        .enabled(this.mapReady)
      
      Button('清除 Marker')
        .width('48%')
        .margin({ left: 8 })
        .onClick(() => {
          this.clearMarkers();
        })
        .enabled(this.mapReady)
    }
    .width('100%')
    
    // 统计信息
    Text(`当前 Marker 数量: ${this.markerCount}`)
      .fontSize(14)
      .fontColor('#2196F3')
      .width('100%')
    
    Divider()
    
    // 功能分组3：相机动画
    Text('相机动画')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
    Row() {
      Button('飞到北京')
        .width('48%')
        .onClick(() => {
          this.flyToBeijing();
        })
        .enabled(this.mapReady)
      
      Button('飞到上海')
        .width('48%')
        .margin({ left: 8 })
        .onClick(() => {
          this.flyToShanghai();
        })
        .enabled(this.mapReady)
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
        title: this.currentTitle,
        onBack: (): void => this.customBackAction(),
        mapArea: (): void => this.MapAreaBuilder(),
        controlArea: (): void => this.ControlAreaBuilder()
      })
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 自定义返回逻辑
   */
  customBackAction() {
    hilog.info(DOMAIN, 'TestPageExample', '执行自定义返回逻辑');
    // 这里可以添加自定义返回逻辑，比如保存状态、弹出确认对话框等
  }

  /**
   * 地图就绪回调
   */
  private onMapReady(mapView?: maplibre.NativeMapView): void {
    if (mapView) {
      this.mapView = mapView;
      this.mapReady = true;
      this.statusMessage = '✅ 地图加载成功';
      hilog.info(DOMAIN, 'TestPageExample', 'Map ready');
    }
  }

  /**
   * 放大地图
   */
  private zoomIn(): void {
    if (!this.mapView) return;
    
    const currentZoom = this.mapView.getZoom();
    this.mapView.setZoom(currentZoom + 1, 300);
    this.statusMessage = `✅ 放大到 Zoom ${(currentZoom + 1).toFixed(1)}`;
  }

  /**
   * 缩小地图
   */
  private zoomOut(): void {
    if (!this.mapView) return;
    
    const currentZoom = this.mapView.getZoom();
    this.mapView.setZoom(currentZoom - 1, 300);
    this.statusMessage = `✅ 缩小到 Zoom ${(currentZoom - 1).toFixed(1)}`;
  }

  /**
   * 添加 Marker
   */
  private addMarker(): void {
    this.markerCount++;
    this.statusMessage = `✅ 已添加 Marker (总数: ${this.markerCount})`;
    hilog.info(DOMAIN, 'TestPageExample', `Marker count: ${this.markerCount}`);
  }

  /**
   * 清除所有 Marker
   */
  private clearMarkers(): void {
    this.markerCount = 0;
    this.statusMessage = '✅ 已清除所有 Marker';
    hilog.info(DOMAIN, 'TestPageExample', 'Markers cleared');
  }

  /**
   * 飞到北京
   */
  private flyToBeijing(): void {
    if (!this.mapView) return;
    
    const options: maplibre.CameraOptions = {
      center: { latitude: 39.9042, longitude: 116.4074 },
      zoom: 10,
      bearing: 0,
      pitch: 0
    };
    this.mapView.flyTo(options, 2000);
    this.statusMessage = '✈️ 飞往北京...';
  }

  /**
   * 飞到上海
   */
  private flyToShanghai(): void {
    if (!this.mapView) return;
    
    const options: maplibre.CameraOptions = {
      center: { latitude: 31.2304, longitude: 121.4737 },
      zoom: 10,
      bearing: 0,
      pitch: 0
    };
    this.mapView.flyTo(options, 2000);
    this.statusMessage = '✈️ 飞往上海...';
  }
}