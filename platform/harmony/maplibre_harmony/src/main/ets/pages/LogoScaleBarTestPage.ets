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
import { MapLibreMap } from '../maps/MapLibreMap';
import { MapLibreMapOptions } from '../maps/MapLibreMapOptions';
import { LogoView } from '../maps/widgets/LogoView';
import { ScaleBarView, ScaleBarUnit } from '../maps/widgets/ScaleBarView';
import { CompassPosition } from '../maps/widgets/CompassPosition';
import { UiSettings } from '../maps/UiSettings';


@Entry
@Component
struct LogoScaleBarTestPage {
  // XComponent 控制器
  private xComponentController: XComponentController = new XComponentController();
  
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
  
  private initMap(surfaceId: string): void {
    try {
      hilog.info(DOMAIN, 'LogoScaleBarTestPage', `Initializing map with surfaceId: ${surfaceId}`);
      
      const nativeMapView = new maplibre.NativeMapView(surfaceId);
      const options = new MapLibreMapOptions();
      options.styleUrl = 'https://demotiles.maplibre.org/style.json';
      
      const map = new MapLibreMap(nativeMapView, options);
      this.mapLibreMap = map;
      
      // 设置初始视图
      map.setLatLng(30.2741, 120.1551, undefined, 0);
      map.setZoom(12, undefined, undefined, 0);
      
      // 设置 ScaleBar 更新回调
      map.onScaleBarUpdate = (metersPerPixel: number) => {
        this.metersPerPixel = metersPerPixel;
      };
      
      // 配置 UiSettings
      const uiSettings = map.getUiSettings();
      this.setupUiSettings(uiSettings);
      
      // 初始化 ScaleBar
      this.metersPerPixel = map.getMetersPerPixelAtLatitude(map.getLatLng().latitude);
      
      this.isMapReady = true;
      hilog.info(DOMAIN, 'LogoScaleBarTestPage', 'Map initialized successfully');
      
    } catch (error) {
      hilog.error(DOMAIN, 'LogoScaleBarTestPage', `Failed to initialize map: ${error.message}`);
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
  
  private getLogoPositionStyle(): Position {
    const positionStyle: Position = {};
    const margin = 10;
    
    switch (this.logoPosition) {
      case CompassPosition.TopLeft:
        positionStyle.top = margin;
        positionStyle.left = margin;
        break;
      case CompassPosition.TopRight:
        positionStyle.top = margin;
        positionStyle.right = margin;
        break;
      case CompassPosition.BottomLeft:
        positionStyle.bottom = margin + 80;
        positionStyle.left = margin;
        break;
      case CompassPosition.BottomRight:
        positionStyle.bottom = margin + 80;
        positionStyle.right = margin;
        break;
    }
    
    return positionStyle;
  }
  
  private getScaleBarPositionStyle(): Position {
    const positionStyle: Position = {};
    const margin = 10;
    
    switch (this.scaleBarPosition) {
      case CompassPosition.TopLeft:
        positionStyle.top = margin;
        positionStyle.left = margin;
        break;
      case CompassPosition.TopRight:
        positionStyle.top = margin;
        positionStyle.right = margin;
        break;
      case CompassPosition.BottomLeft:
        positionStyle.bottom = margin + 80;
        positionStyle.left = margin;
        break;
      case CompassPosition.BottomRight:
        positionStyle.bottom = margin + 80;
        positionStyle.right = margin;
        break;
    }
    
    return positionStyle;
  }
  
  build() {
    Column() {
      // 标题栏
      Row() {
        Button('返回')
          .fontSize(16)
          .onClick(() => {
            router.back();
          })
        
        Text('Logo & ScaleBar 测试')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        Row().width(60)
      }
      .width('100%')
      .height(56)
      .padding({ left: 10, right: 10 })
      .backgroundColor('#2196F3')
      .justifyContent(FlexAlign.SpaceBetween)
      
      // 地图容器
      Stack() {
        // 地图视图
        XComponent({
          id: 'logo-scalebar-test-map',
          type: XComponentType.SURFACE,
          controller: this.xComponentController
        })
          .width('100%')
          .height('100%')
          .onLoad(() => {
            hilog.info(DOMAIN, 'LogoScaleBarTestPage', 'XComponent loaded');
            const surfaceId = this.xComponentController.getXComponentSurfaceId();
            this.initMap(surfaceId);
          })
        
        // Logo 组件
        if (this.logoEnabled && this.isMapReady) {
          LogoView({
            enabled: this.logoEnabled,
            logoWidth: 50,
            logoHeight: 30
          })
            .position(this.getLogoPositionStyle())
        }
        
        // ScaleBar 组件
        if (this.scaleBarEnabled && this.isMapReady) {
          ScaleBarView({
            enabled: this.scaleBarEnabled,
            metersPerPixel: this.metersPerPixel,
            unitSystem: this.scaleBarUnit,
            useDarkStyles: this.scaleBarUseDarkStyles
          })
            .position(this.getScaleBarPositionStyle())
        }
        
        // 控制面板
        Column() {
          Text(`比例: 1 px = ${this.metersPerPixel.toFixed(2)} m`)
            .fontSize(12)
            .fontColor(Color.White)
            .backgroundColor('#000000AA')
            .padding(6)
            .borderRadius(4)
            .margin({ bottom: 10 })
          
          Column() {
            Text('Logo 配置')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 8 })
            
            Row() {
              Text('显示 Logo:')
                .fontSize(12)
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
            .padding(4)
            
            Divider().margin({ top: 8, bottom: 8 })
            
            Text('ScaleBar 配置')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 8 })
            
            Row() {
              Text('显示比例尺:')
                .fontSize(12)
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
            .padding(4)
            
            Row() {
              Text('深色样式:')
                .fontSize(12)
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
            .padding(4)
            
            Button(`单位: ${this.scaleBarUnit === ScaleBarUnit.Metric ? '公制' : '英制'}`)
              .fontSize(12)
              .width('100%')
              .margin({ top: 8 })
              .onClick(() => {
                this.scaleBarUnit = this.scaleBarUnit === ScaleBarUnit.Metric 
                  ? ScaleBarUnit.Imperial 
                  : ScaleBarUnit.Metric;
                if (this.mapLibreMap) {
                  this.mapLibreMap.getUiSettings().setScaleBarUnit(this.scaleBarUnit);
                }
              })
          }
          .backgroundColor('#FFFFFFDD')
          .borderRadius(8)
          .padding(12)
        }
        .width('90%')
        .position({ bottom: 10, left: '5%' })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}

