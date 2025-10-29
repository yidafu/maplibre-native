/**
 * CameraAnimationTestPage - 相机动画测试页面
 * 
 * 测试内容：
 * - easeTo 相机平滑动画
 * - flyTo 相机飞行动画
 * - 动画取消功能
 * 
 * 注意：当前 NAPI 层的 easeTo/flyTo 暂不支持回调参数
 */

import { NativeMapView } from '../maps/NativeMapView';
import { createLatLng } from '../maps/geometry/LatLng';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../constants/HiLogConstants';
import maplibre from 'libmaplibre_native.so';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';

interface LocationData {
  name: string;
  lat: number;
  lng: number;
  zoom: number;
  bearing: number;
  pitch: number;
}

@Entry
@Component
struct CameraAnimationTestPage {
  @State private mapReady: boolean = false;
  @State private animationStatus: string = '等待操作...';
  @State private currentLocation: string = '杭州';
  
  private nativeMapView: maplibre.NativeMapView | null = null;
  
  // 测试位置
  private locations: LocationData[] = [
    { name: '杭州', lat: 30.2741, lng: 120.1551, zoom: 12, bearing: 0, pitch: 0 },
    { name: '北京', lat: 39.9042, lng: 116.4074, zoom: 12, bearing: 0, pitch: 0 },
    { name: '上海', lat: 31.2304, lng: 121.4737, zoom: 13, bearing: 45, pitch: 30 },
    { name: '深圳', lat: 22.5431, lng: 114.0579, zoom: 11, bearing: 0, pitch: 0 },
  ];
  
  private currentLocationIndex: number = 0;
  
  build() {
    Column() {
      // 标题栏
      Row() {
        Text('相机动画回调测试')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
        
        Blank()
        
        Button('返回')
          .onClick(() => {
            hilog.info(DOMAIN, 'CameraAnimationTest', 'Navigating back');
            router.back();
          })
          .margin({ right: 16 })
      }
      .width('100%')
      .height(56)
      .backgroundColor('#F7F7F7')
      
      // 地图视图
      NativeMapView({
        styleUrl: 'https://demotiles.maplibre.org/style.json',
        initialLatitude: 30.2741,
        initialLongitude: 120.1551,
        initialZoom: 10,
        initialBearing: 0,
        initialPitch: 0,
        debugMode: false,
        onMapReady: (mapView?: maplibre.NativeMapView) => {
          this.onMapReady(mapView);
        }
      })
      .width('100%')
      .height('60%')
      .id('camera_animation_test_map')
      
      // 控制区
      Scroll() {
        Column({ space: 12 }) {
          Text('动画测试')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          
          // EaseTo 测试
          Button('EaseTo 平滑动画')
            .width('90%')
            .onClick(() => {
              this.testEaseTo();
            })
            .enabled(this.mapReady)
          
          // FlyTo 测试
          Button('FlyTo 飞行动画')
            .width('90%')
            .onClick(() => {
              this.testFlyTo();
            })
            .enabled(this.mapReady)
          
          // 取消动画测试
          Button('取消动画')
            .width('90%')
            .backgroundColor('#FF6B6B')
            .onClick(() => {
              this.testCancelAnimation();
            })
            .enabled(this.mapReady)
          
          Divider()
          
          // 状态显示
          Text('动画状态')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          
          Text(this.animationStatus)
            .fontSize(14)
            .width('90%')
            .fontColor(Color.Gray)
          
          Text(`当前位置: ${this.currentLocation}`)
            .fontSize(14)
            .width('90%')
          
          Divider()
          
          // 说明
          Text('说明')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          
          Text('• EaseTo: 平滑过渡动画（缓动）\n' +
               '• FlyTo: 飞行动画（弧线运动）\n' +
               '• cancelTransitions: 取消正在进行的动画\n' +
               '• 动画时长: EaseTo=2s, FlyTo=3s')
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
    hilog.info(DOMAIN, 'CameraAnimationTest', 'Map ready');
    
    if (mapView) {
      this.nativeMapView = mapView;
      this.mapReady = true;
      this.animationStatus = '地图已就绪';
      
      hilog.info(DOMAIN, 'CameraAnimationTest', 'Ready for animation tests');
    }
  }
  
  /**
   * 测试 EaseTo 动画
   */
  private testEaseTo(): void {
    if (!this.nativeMapView) {
      promptAction.showToast({ message: '地图未初始化', duration: 2000 });
      return;
    }
    
    // 切换到下一个位置
    this.currentLocationIndex = (this.currentLocationIndex + 1) % this.locations.length;
    const location = this.locations[this.currentLocationIndex];
    
    this.animationStatus = `正在 EaseTo 到 ${location.name}...`;
    this.currentLocation = location.name;
    hilog.info(DOMAIN, 'CameraAnimationTest', `Starting easeTo to ${location.name}`);
    
    const cameraOptions: maplibre.CameraOptions = {
      center: createLatLng(location.lat, location.lng),
      zoom: location.zoom,
      bearing: location.bearing,
      pitch: location.pitch
    };
    this.nativeMapView.easeTo(cameraOptions, 2000);
    
    // 模拟动画完成（2秒后）
    setTimeout(() => {
      this.animationStatus = `✅ EaseTo 到 ${location.name} 完成`;
      promptAction.showToast({ message: `已移动到 ${location.name}`, duration: 1500 });
    }, 2000);
  }
  
  /**
   * 测试 FlyTo 动画
   */
  private testFlyTo(): void {
    if (!this.nativeMapView) {
      promptAction.showToast({ message: '地图未初始化', duration: 2000 });
      return;
    }
    
    // 切换到下一个位置
    this.currentLocationIndex = (this.currentLocationIndex + 1) % this.locations.length;
    const location = this.locations[this.currentLocationIndex];
    
    this.animationStatus = `正在 FlyTo 到 ${location.name}...`;
    this.currentLocation = location.name;
    hilog.info(DOMAIN, 'CameraAnimationTest', `Starting flyTo to ${location.name}`);
    
    const cameraOptions: maplibre.CameraOptions = {
      center: createLatLng(location.lat, location.lng),
      zoom: location.zoom,
      bearing: location.bearing,
      pitch: location.pitch
    };
    this.nativeMapView.flyTo(cameraOptions, 3000);
    
    // 模拟动画完成（3秒后）
    setTimeout(() => {
      this.animationStatus = `✅ FlyTo 到 ${location.name} 完成`;
      promptAction.showToast({ message: `已飞行到 ${location.name}`, duration: 1500 });
    }, 3000);
  }
  
  /**
   * 测试取消动画
   */
  private testCancelAnimation(): void {
    if (!this.nativeMapView) {
      promptAction.showToast({ message: '地图未初始化', duration: 2000 });
      return;
    }
    
    this.animationStatus = '启动5秒飞行动画，1秒后自动取消...';
    hilog.info(DOMAIN, 'CameraAnimationTest', 'Starting animation with planned cancellation');
    
    // 启动一个长动画（5秒）
    const cameraOptions: maplibre.CameraOptions = {
      center: createLatLng(39.9042, 116.4074),
      zoom: 15,
      bearing: 180,
      pitch: 60
    };
    this.nativeMapView.flyTo(cameraOptions, 5000);
    
    // 1秒后取消动画
    setTimeout(() => {
      if (this.nativeMapView) {
        hilog.info(DOMAIN, 'CameraAnimationTest', 'Cancelling animation');
        this.nativeMapView.cancelTransitions();
        this.animationStatus = '✅ 动画已取消';
        promptAction.showToast({ message: '动画已取消', duration: 2000 });
      }
    }, 1000);
  }
}

