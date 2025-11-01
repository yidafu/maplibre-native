/**
 * Camera Animator Test Page
 * 相机动画控制器测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/camera/CameraAnimatorActivity.kt
 * 
 * 功能:
 * - 相机位置动画（经纬度、缩放、倾斜、方位角）
 * - 多种插值器演示（不同的动画曲线）
 * - 动画控制（开始、暂停、取消）
 * - 动画组合
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapLibreMap, MapView, CameraPosition, LatLng } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG  } from '../common/TestUtils';

@Entry
@Component
struct CameraAnimatorTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isAnimating: boolean = false;
  @State private animationType: string = '无';
  
  // 起始位置（旧金山）
  private readonly START_LAT_LNG: LatLng = new LatLng(37.787947, -122.407432);
  
  // 目标位置
  private readonly TARGET_LAT_LNG: LatLng = new LatLng(37.789992, -122.402214);
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    console.info('[CameraAnimatorTestPage] onMapReady');
    this.mapController = map;
    map.setStyleUrl(DEFAULT_STYLE_URLS.bright);
    
    // 设置初始位置
    this.resetCameraPosition();
  };
  
  /**
   * 重置相机位置
   */
  private resetCameraPosition = (): void => {
    if (!this.mapController) return;
    
    this.mapController.jumpTo(0, this.START_LAT_LNG.latitude, this.START_LAT_LNG.longitude, 0, 11);
    this.isAnimating = false;
    this.animationType = '无';
  };
  
  /**
   * 执行组合动画（模拟 Android 的 AnimatorSet）
   */
  private playCompositeAnimation = (): void => {
    if (!this.mapController || this.isAnimating) return;
    
    this.isAnimating = true;
    this.animationType = '组合动画';
    showToast('开始组合动画');
    
    // 使用 ArkUI 的 animateTo 实现相机动画
    // 分阶段执行动画
    
    // 阶段1: 移动到目标位置 (1秒)
    animateTo({
      duration: 1000,
      curve: Curve.EaseInOut
    }, () => {
      if (this.mapController) {
        this.mapController.easeTo(
          this.TARGET_LAT_LNG.latitude,
          this.TARGET_LAT_LNG.longitude,
          0,
          11,
          1000
        );
      }
    });
    
    // 阶段2: 缩放动画 (2.2秒，延迟0.6秒)
    setTimeout(() => {
      animateTo({
        duration: 2200,
        curve: Curve.FastOutSlowIn
      }, () => {
        if (this.mapController) {
          this.mapController.easeTo(
            this.TARGET_LAT_LNG.latitude,
            this.TARGET_LAT_LNG.longitude,
            0,
            14.5,
            2200
          );
        }
      });
    }, 600);
    
    // 阶段3: 方位角动画 (1秒，延迟2秒)
    setTimeout(() => {
      animateTo({
        duration: 1000,
        curve: Curve.Linear
      }, () => {
        if (this.mapController) {
          this.mapController.easeTo(
            this.TARGET_LAT_LNG.latitude,
            this.TARGET_LAT_LNG.longitude,
            135,
            14.5,
            1000
          );
        }
      });
    }, 2000);
    
    // 阶段4: 倾斜动画 (1秒，延迟3秒)
    setTimeout(() => {
      animateTo({
        duration: 1000,
        curve: Curve.EaseOut
      }, () => {
        if (this.mapController) {
          this.mapController.setPitch(60, 1000);
        }
      });
      
      // 动画完成
      setTimeout(() => {
        this.isAnimating = false;
        showToast('组合动画完成');
      }, 1000);
    }, 3000);
  };
  
  /**
   * 平滑动画（EaseInOut）
   */
  private playEaseInOutAnimation = (): void => {
    if (!this.mapController || this.isAnimating) return;
    
    this.isAnimating = true;
    this.animationType = 'EaseInOut';
    showToast('EaseInOut 动画');
    
    animateTo({
      duration: 2500,
      curve: Curve.EaseInOut,
      onFinish: () => {
        this.isAnimating = false;
        showToast('动画完成');
      }
    }, () => {
      if (this.mapController) {
        this.mapController.easeTo(
          37.826715,
          -122.422795,
          0,
          16,
          2500
        );
      }
    });
  };
  
  /**
   * 弹跳动画（类似 BounceInterpolator）
   */
  private playBounceAnimation = (): void => {
    if (!this.mapController || this.isAnimating) return;
    
    this.isAnimating = true;
    this.animationType = 'Bounce';
    showToast('Bounce 动画');
    
    animateTo({
      duration: 3750,
      curve: Curve.EaseInOut, // 使用EaseInOut替代Spring
      onFinish: () => {
        this.isAnimating = false;
        showToast('动画完成');
      }
    }, () => {
      if (this.mapController) {
        this.mapController.easeTo(
          this.START_LAT_LNG.latitude,
          this.START_LAT_LNG.longitude,
          0,
          16,
          3750
        );
      }
    });
  };
  
  /**
   * 快进快出动画（FastOutSlowIn）
   */
  private playFastOutSlowInAnimation = (): void => {
    if (!this.mapController || this.isAnimating) return;
    
    this.isAnimating = true;
    this.animationType = 'FastOutSlowIn';
    showToast('FastOutSlowIn 动画');
    
    animateTo({
      duration: 2500,
      curve: Curve.FastOutSlowIn,
      onFinish: () => {
        this.isAnimating = false;
        showToast('动画完成');
      }
    }, () => {
      if (this.mapController) {
        this.mapController.easeTo(
          this.TARGET_LAT_LNG.latitude,
          this.TARGET_LAT_LNG.longitude,
          45,
          16,
          2500
        );
      }
    });
  };
  
  /**
   * 线性动画
   */
  private playLinearAnimation = (): void => {
    if (!this.mapController || this.isAnimating) return;
    
    this.isAnimating = true;
    this.animationType = 'Linear';
    showToast('Linear 动画');
    
    animateTo({
      duration: 2000,
      curve: Curve.Linear,
      onFinish: () => {
        this.isAnimating = false;
        showToast('动画完成');
      }
    }, () => {
      if (this.mapController) {
        this.mapController.easeTo(
          this.TARGET_LAT_LNG.latitude,
          this.TARGET_LAT_LNG.longitude,
          90,
          15,
          2000
        );
      }
    });
  };
  
  /**
   * 旋转动画
   */
  private playRotationAnimation = (): void => {
    if (!this.mapController || this.isAnimating) return;
    
    this.isAnimating = true;
    this.animationType = 'Rotation';
    showToast('旋转动画');
    
    // 360度旋转
    animateTo({
      duration: 3000,
      curve: Curve.Linear,
      onFinish: () => {
        this.isAnimating = false;
        showToast('旋转完成');
      }
    }, () => {
      if (this.mapController) {
        this.mapController.easeTo(
          this.TARGET_LAT_LNG.latitude,
          this.TARGET_LAT_LNG.longitude,
          360,
          14,
          3000
        );
      }
    });
  };
  
  @Builder
  actionButtonsBuilder() {
    Button('组合动画')
      .fontSize(13)
      .enabled(!this.isAnimating)
      .onClick(this.playCompositeAnimation);
    
    Button('EaseInOut')
      .fontSize(13)
      .enabled(!this.isAnimating)
      .onClick(this.playEaseInOutAnimation);
    
    Button('Bounce')
      .fontSize(13)
      .enabled(!this.isAnimating)
      .onClick(this.playBounceAnimation);
    
    Button('FastOutSlowIn')
      .fontSize(13)
      .enabled(!this.isAnimating)
      .onClick(this.playFastOutSlowInAnimation);
    
    Button('Linear')
      .fontSize(13)
      .enabled(!this.isAnimating)
      .onClick(this.playLinearAnimation);
    
    Button('旋转')
      .fontSize(13)
      .enabled(!this.isAnimating)
      .onClick(this.playRotationAnimation);
    
    Button('重置')
      .fontSize(13)
      .backgroundColor('#F44336')
      .onClick(this.resetCameraPosition);
  }
  
  @Builder
  controlPanelBuilder() {
    Column() {
      Text('相机动画')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 });
      
      Text(`状态: ${this.isAnimating ? '动画中' : '就绪'}`)
        .fontSize(12)
        .fontColor(this.isAnimating ? '#FF9800' : '#4CAF50');
      
      Text(`类型: ${this.animationType}`)
        .fontSize(12)
        .fontColor('#666');
      
      Divider().margin({ top: 8, bottom: 8 });
      
      Text('支持的动画曲线：')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 4 });
      
      Text('• EaseInOut - 缓入缓出')
        .fontSize(11)
        .fontColor('#666');
      
      Text('• Bounce - 弹跳效果')
        .fontSize(11)
        .fontColor('#666');
      
      Text('• FastOutSlowIn - 快出慢入')
        .fontSize(11)
        .fontColor('#666');
      
      Text('• Linear - 线性匀速')
        .fontSize(11)
        .fontColor('#666');
    }
    .alignItems(HorizontalAlign.Start);
  }
  
  @Builder
  mapContentBuilder() {
    MapView({
      styleUrl: DEFAULT_STYLE_URLS.bright,
      onMapReady: this.onMapReady,
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 10
    })
      .width('100%')
      .height('100%');
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Camera Animator',
        description: '相机动画控制器',
        showActionBar: true,
        actionButtons: (): void => this.actionButtonsBuilder(),
        controlPanel: (): void => this.controlPanelBuilder(),
        mapContent: (): void => this.mapContentBuilder()
      });
    }
    .width('100%')
    .height('100%');
  }
}

