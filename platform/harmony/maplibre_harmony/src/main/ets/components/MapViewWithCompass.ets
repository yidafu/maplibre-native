/**
 * MapViewWithCompass - 带指南针的地图视图组件
 * 
 * 这是一个完整的地图视图组件示例，展示如何集成指南针
 */

import { MapLibreMap } from '../maps/MapLibreMap';
import { CompassView } from '../maps/widgets/CompassView';
import { CompassVisibility } from '../maps/widgets/CompassVisibility';
import { CompassPosition } from '../maps/widgets/CompassPosition';
import { UiSettings } from '../maps/UiSettings';
import maplibre from 'libmaplibre_native.so';

@Component
export struct MapViewWithCompass {
  // 地图相关
  private xComponentController: XComponentController = new XComponentController();
  @State private mapLibreMap: MapLibreMap | null = null;
  @State private currentBearing: number = 0;
  
  // 指南针配置
  @State private compassEnabled: boolean = true;
  @State private compassVisibility: CompassVisibility = CompassVisibility.Adaptive;
  @State private compassFadeWhenFacingNorth: boolean = true;
  
  // 回调
  onMapReady?: (map: MapLibreMap) => void;
  
  // Compass 引用
  private compassViewRef?: CompassView;
  
  /**
   * 地图初始化完成后的回调
   */
  private handleMapReady(nativeMapView: maplibre.NativeMapView): void {
    const map = new MapLibreMap(nativeMapView, {
      // MapLibreMapOptions
    } as any);
    
    this.mapLibreMap = map;
    
    // 设置指南针更新回调
    map.onCompassUpdate = (bearing: number) => {
      this.currentBearing = bearing;
      // 更新指南针
      if (this.compassViewRef) {
        this.compassViewRef.update(bearing);
      }
    };
    
    // 配置 UiSettings
    const uiSettings = map.getUiSettings();
    this.setupUiSettings(uiSettings);
    
    // 初始化指南针方向
    this.currentBearing = map.getBearing();
    if (this.compassViewRef) {
      this.compassViewRef.update(this.currentBearing);
    }
    
    // 触发外部回调
    if (this.onMapReady) {
      this.onMapReady(map);
    }
  }
  
  /**
   * 设置 UI 配置
   */
  private setupUiSettings(uiSettings: UiSettings): void {
    uiSettings.setCompassEnabled(this.compassEnabled);
    uiSettings.setCompassVisibility(this.compassVisibility);
    uiSettings.setCompassFadeFacingNorth(this.compassFadeWhenFacingNorth);
    
    // 监听配置变更
    uiSettings.onCompassConfigChanged = () => {
      this.compassEnabled = uiSettings.isCompassEnabled();
      this.compassVisibility = uiSettings.getCompassVisibility();
      this.compassFadeWhenFacingNorth = uiSettings.isCompassFadeWhenFacingNorth();
    };
  }
  
  /**
   * 指南针点击处理
   */
  private handleCompassClick(): void {
    if (this.mapLibreMap) {
      this.mapLibreMap.resetNorth();
    }
  }
  
  /**
   * 获取指南针位置样式
   */
  private getCompassPosition(): Position {
    const uiSettings = this.mapLibreMap?.getUiSettings();
    const position = uiSettings?.getCompassPosition() ?? CompassPosition.TopRight;
    const margins = uiSettings?.getCompassMargins();
    
    const positionStyle: Position = {};
    
    switch (position) {
      case CompassPosition.TopLeft:
        positionStyle.top = margins?.top ?? 10;
        positionStyle.left = margins?.left ?? 10;
        break;
      case CompassPosition.TopRight:
        positionStyle.top = margins?.top ?? 10;
        positionStyle.right = margins?.right ?? 10;
        break;
      case CompassPosition.BottomLeft:
        positionStyle.bottom = margins?.bottom ?? 10;
        positionStyle.left = margins?.left ?? 10;
        break;
      case CompassPosition.BottomRight:
        positionStyle.bottom = margins?.bottom ?? 10;
        positionStyle.right = margins?.right ?? 10;
        break;
    }
    
    return positionStyle;
  }
  
  build() {
    Stack() {
      // 地图 XComponent
      XComponent({
        id: 'maplibre-map',
        type: XComponentType.SURFACE,
        controller: this.xComponentController
      })
        .width('100%')
        .height('100%')
        .onLoad(() => {
          // XComponent 加载完成，创建地图
          const nativeMapView = new maplibre.NativeMapView(
            this.xComponentController.getXComponentSurfaceId()
          );
          this.handleMapReady(nativeMapView);
        })
      
      // 指南针组件
      if (this.compassEnabled) {
        CompassView({
          enabled: this.compassEnabled,
          compassVisibility: this.compassVisibility,
          fadeWhenFacingNorth: this.compassFadeWhenFacingNorth,
          onCompassClick: () => {
            this.handleCompassClick();
          }
        })
          .position(this.getCompassPosition())
      }
    }
    .width('100%')
    .height('100%')
  }
}

