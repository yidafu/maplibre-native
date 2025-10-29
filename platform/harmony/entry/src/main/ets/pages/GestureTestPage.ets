/**
 * 手势测试页面
 * 
 * 用于测试和演示地图手势功能
 */

import { NativeMapView } from 'maplibre_harmony/src/main/ets/maps/NativeMapView';
import { maplibre } from 'maplibre_harmony';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { router } from '@kit.ArkUI';
import { DOMAIN } from '../constants/HiLogConstants';
const TAG = 'GestureTestPage';

@Entry
@Component
struct GestureTestPage {
  @State private gestureInfo: string = '等待手势...';
  @State private moveCount: number = 0;
  @State private scaleCount: number = 0;
  @State private rotateCount: number = 0;
  @State private clickCount: number = 0;
  @State private tiltCount: number = 0;
  @State private quickZoomCount: number = 0;
  
  private mapViewRef: NativeMapView | null = null;

  build() {
    Column() {
      // 标题栏
      Row() {
        Button('返回')
          .fontSize(16)
          .backgroundColor(Color.Transparent)
          .fontColor('#2196F3')
          .onClick(() => {
            router.back();
          })
          .margin({ left: 5 })

        Text('地图手势测试')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 60 })
      }
      .width('100%')
      .height(56)
      .backgroundColor('#F5F5F5')

      // 地图区域（60%）
      NativeMapView({
        styleUrl: "https://demotiles.maplibre.org/style.json",
        initialLatitude: 30.2741,
        initialLongitude: 120.1551,
        initialZoom: 6,
        initialBearing: 0,
        initialPitch: 0,
        onMapReady: () => {
          hilog.info(DOMAIN, TAG, 'Map ready, setting up gesture listeners');
        }
      })
        .width('100%')
        .height('60%')

      // 测试按钮区域（40%，可滚动）
      Scroll() {
        Column() {
          // 状态信息
          Text(this.gestureInfo)
            .fontSize(14)
            .fontColor('#333333')
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding(12)
            .backgroundColor('#F8F8F8')
            .margin({ bottom: 8 })

          // 手势计数
          Row() {
            Text(`平移:${this.moveCount}`)
              .fontSize(11)
              .margin({ right: 8 })
            Text(`缩放:${this.scaleCount}`)
              .fontSize(11)
              .margin({ right: 8 })
            Text(`旋转:${this.rotateCount}`)
              .fontSize(11)
              .margin({ right: 8 })
            Text(`点击:${this.clickCount}`)
              .fontSize(11)
              .margin({ right: 8 })
            Text(`倾斜:${this.tiltCount}`)
              .fontSize(11)
              .margin({ right: 8 })
            Text(`快速缩放:${this.quickZoomCount}`)
              .fontSize(11)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ bottom: 12 })

          // 基础控制
          Text('基础手势控制')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row() {
            Button('重置计数')
              .fontSize(12)
              .onClick(() => {
                this.moveCount = 0;
                this.scaleCount = 0;
                this.rotateCount = 0;
                this.clickCount = 0;
                this.tiltCount = 0;
                this.quickZoomCount = 0;
                this.gestureInfo = '计数已重置';
              })
              .layoutWeight(1)
              .margin({ right: 4 })

            Button('禁用平移')
              .fontSize(12)
              .onClick(() => {
                if (this.mapViewRef) {
                  const uiSettings = this.mapViewRef.getUiSettings();
                  const enabled = !uiSettings.isScrollGesturesEnabled();
                  uiSettings.setScrollGesturesEnabled(enabled);
                  this.gestureInfo = enabled ? '平移已启用' : '平移已禁用';
                }
              })
              .layoutWeight(1)
              .margin({ right: 4 })

            Button('禁用缩放')
              .fontSize(12)
              .onClick(() => {
                if (this.mapViewRef) {
                  const uiSettings = this.mapViewRef.getUiSettings();
                  const enabled = !uiSettings.isZoomGesturesEnabled();
                  uiSettings.setZoomGesturesEnabled(enabled);
                  this.gestureInfo = enabled ? '缩放已启用' : '缩放已禁用';
                }
              })
              .layoutWeight(1)
              .margin({ right: 4 })

            Button('禁用旋转')
              .fontSize(12)
              .onClick(() => {
                if (this.mapViewRef) {
                  const uiSettings = this.mapViewRef.getUiSettings();
                  const enabled = !uiSettings.isRotateGesturesEnabled();
                  uiSettings.setRotateGesturesEnabled(enabled);
                  this.gestureInfo = enabled ? '旋转已启用' : '旋转已禁用';
                }
              })
              .layoutWeight(1)
          }
          .width('100%')
          .margin({ bottom: 12 })

          Divider().height(1).color('#E0E0E0').margin({ bottom: 12 })

          // 惯性动画控制
          Text('惯性动画控制')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row() {
            Button('Fling动画')
              .fontSize(12)
              .onClick(() => {
                if (this.mapViewRef) {
                  const uiSettings = this.mapViewRef.getUiSettings();
                  const enabled = !uiSettings.isFlingVelocityAnimationEnabled();
                  uiSettings.setFlingVelocityAnimationEnabled(enabled);
                  this.gestureInfo = enabled ? 'Fling动画已启用' : 'Fling动画已禁用';
                }
              })
              .layoutWeight(1)
              .margin({ right: 4 })

            Button('缩放动画')
              .fontSize(12)
              .onClick(() => {
                if (this.mapViewRef) {
                  const uiSettings = this.mapViewRef.getUiSettings();
                  const enabled = !uiSettings.isScaleVelocityAnimationEnabled();
                  uiSettings.setScaleVelocityAnimationEnabled(enabled);
                  this.gestureInfo = enabled ? '缩放动画已启用' : '缩放动画已禁用';
                }
              })
              .layoutWeight(1)
              .margin({ right: 4 })

            Button('旋转动画')
              .fontSize(12)
              .onClick(() => {
                if (this.mapViewRef) {
                  const uiSettings = this.mapViewRef.getUiSettings();
                  const enabled = !uiSettings.isRotateVelocityAnimationEnabled();
                  uiSettings.setRotateVelocityAnimationEnabled(enabled);
                  this.gestureInfo = enabled ? '旋转动画已启用' : '旋转动画已禁用';
                }
              })
              .layoutWeight(1)
              .margin({ right: 4 })

            Button('减速率')
              .fontSize(12)
              .onClick(() => {
                if (this.mapViewRef) {
                  const uiSettings = this.mapViewRef.getUiSettings();
                  const rates = [0.1, 0.35, 0.8];
                  const current = uiSettings.getDecelerationRate();
                  const currentIndex = rates.findIndex(r => Math.abs(r - current) < 0.01);
                  const nextIndex = (currentIndex + 1) % rates.length;
                  uiSettings.setDecelerationRate(rates[nextIndex]);
                  this.gestureInfo = `减速率: ${rates[nextIndex]}`;
                }
              })
              .layoutWeight(1)
          }
          .width('100%')
          .margin({ bottom: 12 })

          Divider().height(1).color('#E0E0E0').margin({ bottom: 12 })

          // 倾斜控制
          Text('倾斜（Tilt）控制')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })

          Row() {
            Button('禁用Tilt')
              .fontSize(12)
              .onClick(() => {
                if (this.mapViewRef) {
                  const uiSettings = this.mapViewRef.getUiSettings();
                  const enabled = !uiSettings.isTiltGesturesEnabled();
                  uiSettings.setTiltGesturesEnabled(enabled);
                  this.gestureInfo = enabled ? 'Tilt已启用' : 'Tilt已禁用';
                }
              })
              .layoutWeight(1)
              .margin({ right: 4 })

            Button('设置俯仰45°')
              .fontSize(12)
              .onClick(() => {
                if (this.mapViewRef) {
                  this.mapViewRef.setPitch(45, 500);
                  this.gestureInfo = '设置俯仰角为 45°';
                }
              })
              .layoutWeight(1)
              .margin({ right: 4 })

            Button('重置俯仰')
              .fontSize(12)
              .onClick(() => {
                if (this.mapViewRef) {
                  this.mapViewRef.setPitch(0, 500);
                  this.gestureInfo = '重置俯仰角为 0°';
                }
              })
              .layoutWeight(1)
              .margin({ right: 4 })

            Button('获取俯仰')
              .fontSize(12)
              .onClick(() => {
                if (this.mapViewRef) {
                  const pitch: number = this.mapViewRef.getPitch();
                  this.gestureInfo = `当前俯仰角: ${pitch.toFixed(2)}°`;
                }
              })
              .layoutWeight(1)
          }
          .width('100%')
        }
        .padding({ left: 12, right: 12, top: 8, bottom: 12 })
        .width('100%')
      }
      .width('100%')
      .height('40%')
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
  }

  aboutToAppear() {
    hilog.info(DOMAIN, TAG, 'GestureTestPage aboutToAppear');
  }

  aboutToDisappear() {
    hilog.info(DOMAIN, TAG, 'GestureTestPage aboutToDisappear');
  }
}

