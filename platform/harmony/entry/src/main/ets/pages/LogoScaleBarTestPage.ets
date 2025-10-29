/**
 * LogoScaleBarTestPage - Logo 和 ScaleBar 测试页面
 * 
 * 测试功能：
 * 1. Logo 显示和位置配置
 * 2. ScaleBar 动态更新
 * 3. 单位切换（公制/英制）
 * 4. 样式切换（浅色/深色）
 */

import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import maplibre from 'libmaplibre_native.so';
import { DOMAIN } from '../constants/HiLogConstants';
import { NativeMapView } from 'maplibre_harmony/src/main/ets/maps/NativeMapView';
import { MapLibreMap } from 'maplibre_harmony/src/main/ets/maps/MapLibreMap';
import { MapLibreMapOptions } from 'maplibre_harmony/src/main/ets/maps/MapLibreMapOptions';
import { CameraPosition, createCameraPosition } from 'maplibre_harmony/src/main/ets/maps/camera/CameraPosition';
import { LogoView } from 'maplibre_harmony/src/main/ets/maps/widgets/LogoView';
import { ScaleBarView, ScaleBarUnit } from 'maplibre_harmony/src/main/ets/maps/widgets/ScaleBarView';
import { CompassPosition } from 'maplibre_harmony/src/main/ets/maps/widgets/CompassPosition';
import { UiSettings } from 'maplibre_harmony/src/main/ets/maps/UiSettings';


@Entry
@Component
struct LogoScaleBarTestPage {
  // 地图相关
  @State private mapLibreMap: MapLibreMap | null = null;
  @State private isMapReady: boolean = false;
  
  // Logo 状态
  @State private logoEnabled: boolean = true;
  @State private logoPosition: CompassPosition = CompassPosition.BottomLeft;
  
  // ScaleBar 状态
  @State private scaleBarEnabled: boolean = true;
  @State private scaleBarUnit: ScaleBarUnit = ScaleBarUnit.Metric;
  @State private scaleBarUseDarkStyles: boolean = false;
  @State private scaleBarPosition: CompassPosition = CompassPosition.TopLeft;
  @State private metersPerPixel: number = 0;
  
  aboutToAppear() {
    hilog.info(DOMAIN, 'LogoScaleBarTestPage', 'Page loading');
  }
  
  aboutToDisappear() {
    hilog.info(DOMAIN, 'LogoScaleBarTestPage', 'Page unloading');
    if (this.mapLibreMap) {
      this.mapLibreMap.destroy();
    }
  }
  
  private onMapReady(nativeMapView?: maplibre.NativeMapView): void {
    try {
      hilog.info(DOMAIN, 'LogoScaleBarTestPage', 'Initializing map');
      
      if (!nativeMapView) {
        hilog.error(DOMAIN, 'LogoScaleBarTestPage', 'NativeMapView is null');
        return;
      }
      
      const latLng = new maplibre.LatLng(30.2741, 120.1551);
      const cameraPos = createCameraPosition(latLng, 12, 0, 0);
      const options = new MapLibreMapOptions();
      options.cameraPosition = cameraPos;
      options.styleUrl = 'https://demotiles.maplibre.org/style.json';
      
      this.mapLibreMap = new MapLibreMap(nativeMapView, options);
      
      // 设置 ScaleBar 更新回调
      this.mapLibreMap.onScaleBarUpdate = (metersPerPixel: number) => {
        this.metersPerPixel = metersPerPixel;
      };
      
      // 配置 UiSettings
      const uiSettings = this.mapLibreMap.getUiSettings();
      this.setupUiSettings(uiSettings);
      
      // 初始化 ScaleBar
      this.metersPerPixel = this.mapLibreMap.getMetersPerPixelAtLatitude(this.mapLibreMap.getLatLng().latitude);
      
      this.isMapReady = true;
      hilog.info(DOMAIN, 'LogoScaleBarTestPage', 'Map initialized successfully');
      
    } catch (error) {
      hilog.error(DOMAIN, 'LogoScaleBarTestPage', `Failed to initialize map: ${error}`);
    }
  }
  
  private setupUiSettings(uiSettings: UiSettings): void {
    // Logo 配置
    uiSettings.setLogoEnabled(this.logoEnabled);
    uiSettings.setLogoPosition(this.logoPosition);
    
    // ScaleBar 配置
    uiSettings.setScaleBarEnabled(this.scaleBarEnabled);
    uiSettings.setScaleBarUnit(this.scaleBarUnit);
    uiSettings.setScaleBarUseDarkStyles(this.scaleBarUseDarkStyles);
    uiSettings.setScaleBarPosition(this.scaleBarPosition);
    
    // 监听配置变更
    uiSettings.onLogoConfigChanged = () => {
      this.logoEnabled = uiSettings.isLogoEnabled();
      this.logoPosition = uiSettings.getLogoPosition();
    };
    
    uiSettings.onScaleBarConfigChanged = () => {
      this.scaleBarEnabled = uiSettings.isScaleBarEnabled();
      this.scaleBarUnit = uiSettings.getScaleBarUnit();
      this.scaleBarUseDarkStyles = uiSettings.isScaleBarUseDarkStyles();
      this.scaleBarPosition = uiSettings.getScaleBarPosition();
    };
  }
  
  private getLogoX(): number {
    const margin = 10;
    switch (this.logoPosition) {
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
  
  private getLogoY(): number {
    const margin = 10;
    switch (this.logoPosition) {
      case CompassPosition.TopLeft:
      case CompassPosition.TopRight:
        return margin;
      case CompassPosition.BottomLeft:
      case CompassPosition.BottomRight:
        return -margin - 80;
      default:
        return margin;
    }
  }
  
  private getLogoAlignment(): Alignment {
    switch (this.logoPosition) {
      case CompassPosition.TopLeft:
        return Alignment.TopStart;
      case CompassPosition.TopRight:
        return Alignment.TopEnd;
      case CompassPosition.BottomLeft:
        return Alignment.BottomStart;
      case CompassPosition.BottomRight:
        return Alignment.BottomEnd;
      default:
        return Alignment.BottomStart;
    }
  }
  
  private getScaleBarX(): number {
    const margin = 10;
    switch (this.scaleBarPosition) {
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
  
  private getScaleBarY(): number {
    const margin = 10;
    switch (this.scaleBarPosition) {
      case CompassPosition.TopLeft:
      case CompassPosition.TopRight:
        return margin;
      case CompassPosition.BottomLeft:
      case CompassPosition.BottomRight:
        return -margin - 80;
      default:
        return margin;
    }
  }
  
  private getScaleBarAlignment(): Alignment {
    switch (this.scaleBarPosition) {
      case CompassPosition.TopLeft:
        return Alignment.TopStart;
      case CompassPosition.TopRight:
        return Alignment.TopEnd;
      case CompassPosition.BottomLeft:
        return Alignment.BottomStart;
      case CompassPosition.BottomRight:
        return Alignment.BottomEnd;
      default:
        return Alignment.BottomEnd;
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
        
        Text('Logo & ScaleBar 测试')
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
      Stack() {
        // 地图视图
        NativeMapView({
        onMapReady: (nativeMapView?: maplibre.NativeMapView) => {
          this.onMapReady(nativeMapView);
        }
        })
          .width('100%')
          .height('100%')
        
        // Logo 组件
        if (this.logoEnabled && this.isMapReady) {
          LogoView({
            logoEnabled: this.logoEnabled,
            logoWidth: 50,
            logoHeight: 30
          })
            .offset({ x: this.getLogoX(), y: this.getLogoY() })
        }
        
        // ScaleBar 组件
        if (this.scaleBarEnabled && this.isMapReady) {
          ScaleBarView({
            isEnabled: this.scaleBarEnabled,
            metersPerPixel: this.metersPerPixel,
            unitSystem: this.scaleBarUnit,
            useDarkStyles: this.scaleBarUseDarkStyles
          })
            .offset({ x: this.getScaleBarX(), y: this.getScaleBarY() })
        }
      }
      .width('100%')
      .height('60%')
      .alignContent(this.getLogoAlignment())
      
      // 测试按钮区域（40%，可滚动）
      Scroll() {
        Column() {
          // 状态信息
          Text(`比例: 1 px = ${this.metersPerPixel.toFixed(2)} m`)
            .fontSize(14)
            .width('100%')
            .padding(12)
            .backgroundColor('#F8F8F8')
            .margin({ bottom: 8 })
          
          // Logo 配置
          Text('Logo 配置')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })
          
          Row() {
            Text('显示 Logo:')
              .fontSize(14)
              .layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.logoEnabled })
              .onChange((isOn: boolean) => {
                this.logoEnabled = isOn;
                if (this.mapLibreMap) {
                  this.mapLibreMap.getUiSettings().setLogoEnabled(isOn);
                }
              })
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#FFFFFF')
          .border({ width: 1, color: '#E0E0E0' })
          .borderRadius(4)
          .margin({ bottom: 12 })
          
          Divider().height(1).color('#E0E0E0').margin({ bottom: 12 })
          
          // ScaleBar 配置
          Text('ScaleBar 配置')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })
          
          Row() {
            Text('显示比例尺:')
              .fontSize(14)
              .layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.scaleBarEnabled })
              .onChange((isOn: boolean) => {
                this.scaleBarEnabled = isOn;
                if (this.mapLibreMap) {
                  this.mapLibreMap.getUiSettings().setScaleBarEnabled(isOn);
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
            Text('深色样式:')
              .fontSize(14)
              .layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.scaleBarUseDarkStyles })
              .onChange((isOn: boolean) => {
                this.scaleBarUseDarkStyles = isOn;
                if (this.mapLibreMap) {
                  this.mapLibreMap.getUiSettings().setScaleBarUseDarkStyles(isOn);
                }
              })
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#FFFFFF')
          .border({ width: 1, color: '#E0E0E0' })
          .borderRadius(4)
          .margin({ bottom: 8 })
          
          Button(`单位: ${this.scaleBarUnit === ScaleBarUnit.Metric ? '公制' : '英制'}`)
            .fontSize(14)
            .width('100%')
            .margin({ top: 4 })
            .onClick(() => {
              this.scaleBarUnit = this.scaleBarUnit === ScaleBarUnit.Metric 
                ? ScaleBarUnit.Imperial 
                : ScaleBarUnit.Metric;
              if (this.mapLibreMap) {
                this.mapLibreMap.getUiSettings().setScaleBarUnit(this.scaleBarUnit);
              }
            })
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

