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
    { 'name': 'OSM', 'url': DEFAULT_STYLE_URLS.bright },
    { 'name': 'Streets', 'url': DEFAULT_STYLE_URLS.streets },
    { 'name': 'Satellite', 'url': DEFAULT_STYLE_URLS.satellite },
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
    // this.mapController.setStyleUrl(this.styles[0].url);
    // this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 12);
    
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
  buildActionButtons() {
    Button(this.locationActive ? '停止定位' : '启动定位')
      .enabled(this.permissionGranted)
      .onClick(() => this.toggleLocation())
    
    ForEach(this.styles, (style: Record<string, string>) => {
      Button(style.name)
        .onClick(() => this.switchStyle(style.name, style.url))
    })
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Location Map Change',
        description: '定位地图变化测试',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        actionButtons: (): void => this.buildActionButtons()
      })
    }
    .width('100%')
    .height('100%')
  }
}
