/**
 * Location Map Change Test Page
 * 定位地图变化测试页面
 * 
 * 测试功能:
 * - 地图样式变化时的定位状态保持
 * - 样式切换时LocationComponent的表现
 */

import { TestPageLayout } from '../common/TestPageLayout';
import {
  NativeMapView,
  MapLibreMap,
  MapLibreMapOptions,
  LocationComponent,
  LocationComponentOptions,
  RenderMode,
  CameraMode,
  PermissionManager
} from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import { MapView } from 'maplibre_harmony';

@Entry
@Component
struct LocationMapChangeTestPage {
  private mapController: MapLibreMap | null = null;
  private locationComponent: LocationComponent | null = null;
  @State private locationActive: boolean = false;
  @State private currentStyle: string = 'Streets';
  @State private permissionGranted: boolean = false;
  
  private styles: Array<Record<string, string>> = [
    { 'name': 'Streets', 'url': DEFAULT_STYLE_URLS.streets },
    { 'name': 'Satellite', 'url': DEFAULT_STYLE_URLS.satellite },
    { 'name': 'OSM', 'url': 'https://demotiles.maplibre.org/style.json' }
  ]
  
  aboutToDisappear() {
    if (this.locationComponent) {
      this.locationComponent.setLocationComponentEnabled(false);
    }
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.mapController.setStyleUrl(this.styles[0].url);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 12);
    
    setTimeout(() => this.initLocationComponent(), 1500);
  };
  
  private initLocationComponent = async (): Promise<void> => {
    if (!this.mapController) return;
    
    try {
      const result = await PermissionManager.requestLocationPermission(getContext(this));
      this.permissionGranted = result.granted;
      
      if (!this.permissionGranted) {
        showToast('定位权限被拒绝');
        return;
      }
      
      this.locationComponent = this.mapController.getLocationComponent();
      const options = new LocationComponentOptions();
      this.locationComponent.activateLocationComponent(options);
      
      showToast('定位组件已初始化');
    } catch (error) {
      console.error('[LocationMapChangeTestPage] Init failed:', error);
    }
  };
  
  private toggleLocation = (): void => {
    if (!this.locationComponent) {
      showToast('定位组件未初始化');
      return;
    }
    
    if (this.locationActive) {
      this.locationComponent.setLocationComponentEnabled(false);
      this.locationActive = false;
      showToast('定位已停止');
    } else {
      this.locationComponent.setLocationComponentEnabled(true);
      this.locationComponent.setRenderMode(RenderMode.NORMAL);
      this.locationComponent.setCameraMode(CameraMode.TRACKING);
      this.locationActive = true;
      showToast('定位已启动');
    }
  };
  
  private switchStyle = (styleName: string, styleUrl: string): void => {
    if (!this.mapController) return;
    
    this.currentStyle = styleName;
    this.mapController.setStyleUrl(styleUrl);
    
    // 样式切换后，重新初始化定位组件
    setTimeout(() => {
      if (this.locationActive && this.locationComponent) {
        try {
          this.locationComponent.setLocationComponentEnabled(true);
          this.locationComponent.setRenderMode(RenderMode.NORMAL);
          showToast(`样式已切换: ${styleName}，定位状态已恢复`);
        } catch (error) {
          console.error('[LocationMapChangeTestPage] Failed to restore location:', error);
        }
      }
    }, 1500);
    
    showToast(`正在切换样式: ${styleName}...`);
  };
  
  @Builder
  buildMapContent() {
    MapView({
      onMapReady: this.onMapReady,
            styleUrl: DEFAULT_STYLE_URLS.bright,
            initialLatitude: 39.9,
            initialLongitude: 116.4,
            initialZoom: 10
    })
  }
  
  @Builder
  buildControlPanel() {
    Column({ space: 12 }) {
      Text('定位控制')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Button(this.locationActive ? '停止定位' : '启动定位')
        .width('100%')
        .backgroundColor(this.locationActive ? '#FF6B6B' : '#4CAF50')
        .enabled(this.permissionGranted)
        .onClick(() => this.toggleLocation())
      
      Text(`状态: ${this.locationActive ? '定位中' : '未定位'}`)
        .fontSize(12)
        .fontColor(this.locationActive ? '#4CAF50' : '#666')
      
      Divider()
      
      Text('样式切换测试')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Text(`当前样式: ${this.currentStyle}`)
        .fontSize(14)
        .fontColor('#666')
      
      ForEach(this.styles, (style: Record<string, string>) => {
        Button(style.name)
          .width('100%')
          .backgroundColor(this.currentStyle === style.name ? '#2196F3' : '#9E9E9E')
          .onClick(() => this.switchStyle(style.name, style.url))
      })
      
      Text('说明: 切换样式时，定位状态应该保持')
        .fontSize(12)
        .fontColor('#666')
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Location Map Change',
        description: '定位地图变化测试',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      })
    }
    .width('100%')
    .height('100%')
  }
}
