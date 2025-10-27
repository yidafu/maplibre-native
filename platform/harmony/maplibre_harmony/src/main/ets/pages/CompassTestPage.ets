/**
 * CompassTestPage - 指南针组件测试页面
 * 
 * 测试指南针的各种功能：
 * 1. 自动旋转跟随地图
 * 2. 点击归正北
 * 3. 可见性模式切换
 * 4. 启用/禁用
 * 5. 淡出配置
 */

import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import maplibre from 'libmaplibre_native.so';
import { DOMAIN } from '../constants/HiLogConstants';
import { NativeMapView } from '../maps/NativeMapView';
import { MapLibreMap } from '../maps/MapLibreMap';
import { MapLibreMapOptions } from '../maps/MapLibreMapOptions';
import { CameraPosition, createCameraPosition } from '../maps/camera/CameraPosition';
import { CompassView } from '../maps/widgets/CompassView';
import { CompassVisibility } from '../maps/widgets/CompassVisibility';
import { CompassPosition } from '../maps/widgets/CompassPosition';
import { UiSettings } from '../maps/UiSettings';


@Entry
@Component
struct CompassTestPage {
  // 地图相关
  @State private mapLibreMap: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  
  // 指南针状态
  @State private currentBearing: number = 0;
  @State private compassEnabled: boolean = true;
  @State private compassVisibility: CompassVisibility = CompassVisibility.Adaptive;
  @State private compassFadeWhenFacingNorth: boolean = true;
  @State private compassPosition: CompassPosition = CompassPosition.TopRight;
  
  // Compass 引用
  private compassViewRef?: CompassView;
  
  /**
   * 页面加载
   */
  aboutToAppear() {
    hilog.info(DOMAIN, 'CompassTestPage', 'Page loading');
  }
  
  /**
   * 页面卸载
   */
  aboutToDisappear() {
    hilog.info(DOMAIN, 'CompassTestPage', 'Page unloading');
    if (this.mapLibreMap) {
      this.mapLibreMap.destroy();
    }
  }
  
  /**
   * 地图准备回调
   */
  private onMapReady(nativeMapView?: maplibre.NativeMapView): void {
    try {
      hilog.info(DOMAIN, 'CompassTestPage', 'Initializing map');
      
      if (!nativeMapView) {
        hilog.error(DOMAIN, 'CompassTestPage', 'NativeMapView is null');
        return;
      }
      
      const latLng = new maplibre.LatLng(30.2741, 120.1551);
      const cameraPos = createCameraPosition(latLng, 12, 0, 0);
      const options = new MapLibreMapOptions();
      options.cameraPosition = cameraPos;
      options.styleUrl = 'https://demotiles.maplibre.org/style.json';
      
      this.mapLibreMap = new MapLibreMap(nativeMapView, options);
      
      // 设置指南针更新回调
      this.mapLibreMap.onCompassUpdate = (bearing: number) => {
        this.currentBearing = bearing;
        hilog.info(DOMAIN, 'CompassTestPage', `Bearing updated: ${bearing}`);
      };
      
      // 配置 UiSettings
      const uiSettings = this.mapLibreMap.getUiSettings();
      this.setupUiSettings(uiSettings);
      
      // 初始化指南针方向
      this.currentBearing = this.mapLibreMap.getBearing();
      
      this.isMapReady = true;
      hilog.info(DOMAIN, 'CompassTestPage', 'Map initialized successfully');
      
    } catch (error) {
      hilog.error(DOMAIN, 'CompassTestPage', `Failed to initialize map: ${error}`);
    }
  }
  
  /**
   * 设置 UI 配置
   */
  private setupUiSettings(uiSettings: UiSettings): void {
    uiSettings.setCompassEnabled(this.compassEnabled);
    uiSettings.setCompassVisibility(this.compassVisibility);
    uiSettings.setCompassFadeFacingNorth(this.compassFadeWhenFacingNorth);
    uiSettings.setCompassPosition(this.compassPosition);
    
    // 监听配置变更
    uiSettings.onCompassConfigChanged = () => {
      this.compassEnabled = uiSettings.isCompassEnabled();
      this.compassVisibility = uiSettings.getCompassVisibility();
      this.compassFadeWhenFacingNorth = uiSettings.isCompassFadeWhenFacingNorth();
      this.compassPosition = uiSettings.getCompassPosition();
    };
  }
  
  /**
   * 指南针点击处理
   */
  private handleCompassClick(): void {
    hilog.info(DOMAIN, 'CompassTestPage', 'Compass clicked');
    if (this.mapLibreMap) {
      this.mapLibreMap.resetNorth();
    }
  }
  
  /**
   * 旋转地图到指定角度（测试用）
   */
  private rotateTo(degrees: number): void {
    if (this.mapLibreMap) {
      this.mapLibreMap.setBearing(degrees, 500);
    }
  }
  
  /**
   * 切换可见性模式
   */
  private toggleVisibility(): void {
    const modes = [CompassVisibility.Adaptive, CompassVisibility.Visible, CompassVisibility.Hidden];
    const currentIndex = modes.indexOf(this.compassVisibility);
    const nextIndex = (currentIndex + 1) % modes.length;
    this.compassVisibility = modes[nextIndex];
    
    if (this.mapLibreMap) {
      this.mapLibreMap.getUiSettings().setCompassVisibility(this.compassVisibility);
    }
  }
  
  /**
   * 获取可见性模式名称
   */
  private getVisibilityName(): string {
    switch (this.compassVisibility) {
      case CompassVisibility.Adaptive:
        return 'Adaptive';
      case CompassVisibility.Visible:
        return 'Visible';
      case CompassVisibility.Hidden:
        return 'Hidden';
      default:
        return 'Unknown';
    }
  }
  
  /**
   * 获取指南针位置的 x 偏移
   */
  private getCompassX(): number {
    const margin = 10;
    switch (this.compassPosition) {
      case CompassPosition.TopLeft:
      case CompassPosition.BottomLeft:
        return margin;
      case CompassPosition.TopRight:
      case CompassPosition.BottomRight:
        return -margin;
      default:
        return margin;
    }
  }
  
  /**
   * 获取指南针位置的 y 偏移
   */
  private getCompassY(): number {
    const margin = 10;
    switch (this.compassPosition) {
      case CompassPosition.TopLeft:
      case CompassPosition.TopRight:
        return margin;
      case CompassPosition.BottomLeft:
      case CompassPosition.BottomRight:
        return -margin - 60; // 避开控制面板
      default:
        return margin;
    }
  }
  
  /**
   * 获取指南针对齐方式
   */
  private getCompassAlignment(): Alignment {
    switch (this.compassPosition) {
      case CompassPosition.TopLeft:
        return Alignment.TopStart;
      case CompassPosition.TopRight:
        return Alignment.TopEnd;
      case CompassPosition.BottomLeft:
        return Alignment.BottomStart;
      case CompassPosition.BottomRight:
        return Alignment.BottomEnd;
      default:
        return Alignment.TopEnd;
    }
  }
  
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
        
        Text('指南针测试')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 60 })
      }
      .width('100%')
      .height(56)
      .backgroundColor('#F5F5F5')
      
      // 地图容器
      Stack() {
        // 地图视图
        NativeMapView({
          onMapReady: (nativeMapView?: maplibre.NativeMapView) => {
            this.onMapReady(nativeMapView);
          }
        })
          .width('100%')
          .height('100%')
        
        // 指南针组件
        if (this.compassEnabled && this.isMapReady) {
          CompassView({
            compassEnabled: this.compassEnabled,
            compassVisibility: this.compassVisibility,
            fadeWhenFacingNorth: this.compassFadeWhenFacingNorth,
            onCompassClick: () => {
              this.handleCompassClick();
            }
          })
            .offset({ x: this.getCompassX(), y: this.getCompassY() })
        }
      }
      .width('100%')
      .height('60%')
      .alignContent(this.getCompassAlignment())
      
      // 测试按钮区域（40%，可滚动）
      Scroll() {
        Column() {
          // 状态信息
          Text(`方位角: ${this.currentBearing.toFixed(1)}°`)
            .fontSize(14)
            .width('100%')
            .padding(12)
            .backgroundColor('#F8F8F8')
            .margin({ bottom: 8 })
          
          // 旋转控制
          Text('旋转测试')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })
          
          Row() {
            Button('0°')
              .fontSize(12)
              .layoutWeight(1)
              .onClick(() => this.rotateTo(0))
              .margin({ right: 4 })
            Button('45°')
              .fontSize(12)
              .layoutWeight(1)
              .onClick(() => this.rotateTo(45))
              .margin({ right: 4 })
            Button('90°')
              .fontSize(12)
              .layoutWeight(1)
              .onClick(() => this.rotateTo(90))
              .margin({ right: 4 })
            Button('180°')
              .fontSize(12)
              .layoutWeight(1)
              .onClick(() => this.rotateTo(180))
          }
          .width('100%')
          .margin({ bottom: 12 })
          
          Divider().height(1).color('#E0E0E0').margin({ bottom: 12 })
          
          // 指南针配置
          Text('指南针配置')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })
          
          Row() {
            Text('启用指南针:')
              .fontSize(14)
              .layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.compassEnabled })
              .onChange((isOn: boolean) => {
                this.compassEnabled = isOn;
                if (this.mapLibreMap) {
                  this.mapLibreMap.getUiSettings().setCompassEnabled(isOn);
                }
              })
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#FFFFFF')
          .border({ width: 1, color: '#E0E0E0' })
          .borderRadius(4)
          .margin({ bottom: 8 })
          
          Row() {
            Text('正北淡出:')
              .fontSize(14)
              .layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.compassFadeWhenFacingNorth })
              .onChange((isOn: boolean) => {
                this.compassFadeWhenFacingNorth = isOn;
                if (this.mapLibreMap) {
                  this.mapLibreMap.getUiSettings().setCompassFadeFacingNorth(isOn);
                }
              })
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#FFFFFF')
          .border({ width: 1, color: '#E0E0E0' })
          .borderRadius(4)
          .margin({ bottom: 8 })
          
          Button(`可见性: ${this.getVisibilityName()}`)
            .fontSize(14)
            .width('100%')
            .onClick(() => this.toggleVisibility())
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
}

