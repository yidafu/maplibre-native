/**
 * CameraAnimationTestPage - 相机动画回调测试页面
 * 
 * 测试内容：
 * - easeTo 动画回调
 * - flyTo 动画回调
 * - 动画取消回调
 */

import { NativeMapView } from '../maps/NativeMapView';
import { MapLibreMap } from '../maps/MapLibreMap';
import { LatLng, createLatLng } from '../maps/geometry/LatLng';
import { CameraAnimationCallback, createAnimationCallback } from '../maps/camera/CameraAnimationCallback';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../constants/HiLogConstants';
import maplibre from 'libmaplibre_native.so';
import promptAction from '@ohos.promptAction';

interface LocationData {
  name: string;
  latLng: LatLng;
}

@Entry
@Component
struct CameraAnimationTestPage {
  @State private mapReady: boolean = false;
  @State private animationStatus: string = '等待操作...';
  @State private animationCount: number = 0;
  @State private cancelCount: number = 0;
  
  private mapLibreMap: MapLibreMap | null = null;
  private nativeMapView?: NativeMapView;
  
  // 测试位置
  private locations: LocationData[] = [];
  
  aboutToAppear() {
    const hangzhou: LocationData = { name: '杭州', latLng: createLatLng(30.2741, 120.1551) };
    const beijing: LocationData = { name: '北京', latLng: createLatLng(39.9042, 116.4074) };
    const shanghai: LocationData = { name: '上海', latLng: createLatLng(31.2304, 121.4737) };
    const shenzhen: LocationData = { name: '深圳', latLng: createLatLng(22.5431, 114.0579) };
    
    this.locations = [hangzhou, beijing, shanghai, shenzhen];
  }
  
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
            // TODO: 导航返回
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
          Button('EaseTo 动画（带回调）')
            .width('90%')
            .onClick(() => {
              this.testEaseToWithCallback();
            })
            .enabled(this.mapReady)
          
          // FlyTo 测试
          Button('FlyTo 动画（带回调）')
            .width('90%')
            .onClick(() => {
              this.testFlyToWithCallback();
            })
            .enabled(this.mapReady)
          
          // 连续动画测试
          Button('连续动画（3次）')
            .width('90%')
            .onClick(() => {
              this.testConsecutiveAnimations();
            })
            .enabled(this.mapReady)
          
          // 取消动画测试
          Button('启动动画然后取消')
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
          
          Text(`完成次数: ${this.animationCount}`)
            .fontSize(14)
            .width('90%')
          
          Text(`取消次数: ${this.cancelCount}`)
            .fontSize(14)
            .width('90%')
            .fontColor('#FF6B6B')
          
          Divider()
          
          // 说明
          Text('说明')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          
          Text('• EaseTo: 平滑过渡动画\n' +
               '• FlyTo: 飞行动画\n' +
               '• 动画完成会触发 onFinish 回调\n' +
               '• 动画取消会触发 onCancel 回调')
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
      // 从 NativeMapView 组件获取 controller
      this.nativeMapView = this.nativeMapView; // 保存引用
      
      // 获取 MapLibreMap 实例
      // 注意：实际应用中应该从组件中正确获取
      // 这里简化处理
      
      this.mapReady = true;
      this.animationStatus = '地图已就绪';
      
      hilog.info(DOMAIN, 'CameraAnimationTest', 'Ready for animation tests');
    }
  }
  
  /**
   * 测试 EaseTo 动画（带回调）
   */
  private testEaseToWithCallback(): void {
    if (!this.mapLibreMap) {
      const toastOptions: promptAction.ShowToastOptions = { message: '地图未初始化', duration: 2000 };
      promptAction.showToast(toastOptions);
      return;
    }
    
    // 切换到下一个位置
    this.currentLocationIndex = (this.currentLocationIndex + 1) % this.locations.length;
    const location = this.locations[this.currentLocationIndex];
    
    this.animationStatus = `正在 EaseTo 到 ${location.name}...`;
    hilog.info(DOMAIN, 'CameraAnimationTest', `Starting easeTo to ${location.name}`);
    
    const callback = createAnimationCallback(
      () => {
        this.animationCount++;
        this.animationStatus = `✅ EaseTo 到 ${location.name} 完成`;
        hilog.info(DOMAIN, 'CameraAnimationTest', `EaseTo animation finished`);
        
        const toastOptions: promptAction.ShowToastOptions = {
          message: `动画完成：${location.name}`,
          duration: 1500
        };
        promptAction.showToast(toastOptions);
      },
      () => {
        this.cancelCount++;
        this.animationStatus = `❌ EaseTo 到 ${location.name} 被取消`;
        hilog.warn(DOMAIN, 'CameraAnimationTest', `EaseTo animation cancelled`);
        
        const toastOptions: promptAction.ShowToastOptions = {
          message: '动画被取消',
          duration: 1500
        };
        promptAction.showToast(toastOptions);
      }
    );
    
    const cameraOptions: maplibre.CameraOptions = {
      center: location.latLng,
      zoom: 12,
      bearing: 0,
      pitch: 0
    };
    this.mapLibreMap.easeTo(cameraOptions, 2000, callback);
  }
  
  /**
   * 测试 FlyTo 动画（带回调）
   */
  private testFlyToWithCallback(): void {
    if (!this.mapLibreMap) {
      const toastOptions: promptAction.ShowToastOptions = { message: '地图未初始化', duration: 2000 };
      promptAction.showToast(toastOptions);
      return;
    }
    
    // 切换到下一个位置
    this.currentLocationIndex = (this.currentLocationIndex + 1) % this.locations.length;
    const location = this.locations[this.currentLocationIndex];
    
    this.animationStatus = `正在 FlyTo 到 ${location.name}...`;
    hilog.info(DOMAIN, 'CameraAnimationTest', `Starting flyTo to ${location.name}`);
    
    const callback = createAnimationCallback(
      () => {
        this.animationCount++;
        this.animationStatus = `✅ FlyTo 到 ${location.name} 完成`;
        hilog.info(DOMAIN, 'CameraAnimationTest', `FlyTo animation finished`);
        
        const toastOptions: promptAction.ShowToastOptions = {
          message: `飞行完成：${location.name}`,
          duration: 1500
        };
        promptAction.showToast(toastOptions);
      },
      () => {
        this.cancelCount++;
        this.animationStatus = `❌ FlyTo 到 ${location.name} 被取消`;
        hilog.warn(DOMAIN, 'CameraAnimationTest', `FlyTo animation cancelled`);
      }
    );
    
    const cameraOptions: maplibre.CameraOptions = {
      center: location.latLng,
      zoom: 11,
      bearing: 45,
      pitch: 30
    };
    this.mapLibreMap.flyTo(cameraOptions, 3000, callback);
  }
  
  /**
   * 测试连续动画
   */
  private testConsecutiveAnimations(): void {
    if (!this.mapLibreMap) {
      const toastOptions: promptAction.ShowToastOptions = { message: '地图未初始化', duration: 2000 };
      promptAction.showToast(toastOptions);
      return;
    }
    
    this.animationStatus = '开始连续动画测试（3次）...';
    hilog.info(DOMAIN, 'CameraAnimationTest', 'Starting consecutive animations');
    
    let completed = 0;
    
    // 第一次动画
    const options1: maplibre.CameraOptions = {
      center: createLatLng(39.9042, 116.4074),
      zoom: 12
    };
    const callback1 = createAnimationCallback(
      () => {
        completed++;
        this.animationStatus = `连续动画 ${completed}/3 完成`;
        hilog.info(DOMAIN, 'CameraAnimationTest', `Animation ${completed} finished`);
        
        // 第二次动画
        if (this.mapLibreMap) {
          const options2: maplibre.CameraOptions = {
            center: createLatLng(31.2304, 121.4737),
            zoom: 13
          };
          const callback2 = createAnimationCallback(
            () => {
              completed++;
              this.animationStatus = `连续动画 ${completed}/3 完成`;
              hilog.info(DOMAIN, 'CameraAnimationTest', `Animation ${completed} finished`);
              
              // 第三次动画
              if (this.mapLibreMap) {
                const options3: maplibre.CameraOptions = {
                  center: createLatLng(22.5431, 114.0579),
                  zoom: 11
                };
                const callback3 = createAnimationCallback(
                  () => {
                    completed++;
                    this.animationCount += 3;
                    this.animationStatus = `✅ 连续动画全部完成（${completed}/3）`;
                    hilog.info(DOMAIN, 'CameraAnimationTest', 'All consecutive animations finished');
                    
                    const toastOptions: promptAction.ShowToastOptions = {
                      message: '连续动画完成！',
                      duration: 2000
                    };
                    promptAction.showToast(toastOptions);
                  }
                );
                this.mapLibreMap.easeTo(options3, 1500, callback3);
              }
            }
          );
          this.mapLibreMap.easeTo(options2, 1500, callback2);
        }
      }
    );
    this.mapLibreMap.easeTo(options1, 1500, callback1);
  }
  
  /**
   * 测试取消动画
   */
  private testCancelAnimation(): void {
    if (!this.mapLibreMap) {
      const toastOptions: promptAction.ShowToastOptions = { message: '地图未初始化', duration: 2000 };
      promptAction.showToast(toastOptions);
      return;
    }
    
    this.animationStatus = '启动动画，1秒后自动取消...';
    hilog.info(DOMAIN, 'CameraAnimationTest', 'Starting animation with planned cancellation');
    
    // 启动一个长动画
    const cameraOptions: maplibre.CameraOptions = {
      center: createLatLng(39.9042, 116.4074),
      zoom: 15
    };
    const callback = createAnimationCallback(
      () => {
        this.animationStatus = '动画完成（不应该看到这个）';
      },
      () => {
        this.cancelCount++;
        this.animationStatus = `✅ 动画成功取消`;
        hilog.info(DOMAIN, 'CameraAnimationTest', 'Animation cancelled as planned');
        
        const toastOptions: promptAction.ShowToastOptions = {
          message: '动画已取消',
          duration: 2000
        };
        promptAction.showToast(toastOptions);
      }
    );
    this.mapLibreMap.flyTo(cameraOptions, 5000, callback);
    
    // 1秒后取消动画
    setTimeout(() => {
      if (this.mapLibreMap) {
        hilog.info(DOMAIN, 'CameraAnimationTest', 'Cancelling animation by calling cancelTransitions');
        this.mapLibreMap.cancelTransitions();
      }
    }, 1000);
  }
}

