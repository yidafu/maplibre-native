/**
 * Customized Location Pulsing Circle Test Page
 * 自定义定位脉冲圆测试页面
 * 
 * 测试功能:
 * - 高度自定义脉冲圆样式
 * - 颜色、半径、透明度、速度控制
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { 
  NativeMapView, 
  MapLibreMap, 
  MapLibreMapOptions,
  LocationComponent,
  LocationComponentOptions,
  RenderMode,
  PermissionManager
} from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import { MapView } from 'maplibre_harmony';

@Entry
@Component
struct CustomizedLocationPulsingCircleTestPage {
  private mapController: MapLibreMap | null = null;
  private locationComponent: LocationComponent | null = null;
  @State private pulsingEnabled: boolean = false;
  @State private pulseColor: string = '#4A90E2';
  @State private pulseMaxRadius: number = 80;
  @State private permissionGranted: boolean = false;
  
  // 颜色预设
  private colorPresets: string[] = ['#4A90E2', '#E74C3C', '#2ECC71', '#F39C12', '#9B59B6', '#1ABC9C']
  
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
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 15);
    
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
      this.applyPulsingConfig();
      
      showToast('定位组件已初始化');
    } catch (error) {
      console.error('[CustomizedLocationPulsingCircleTestPage] Init failed:', error);
    }
  };
  
  /**
   * 应用脉冲配置
   */
  private applyPulsingConfig = (): void => {
    if (!this.locationComponent) return;
    
    const options = new LocationComponentOptions();
    options.pulseEnabled = true;
    options.pulseColor = this.pulseColor;
    options.pulseMaxRadius = this.pulseMaxRadius;
    
    this.locationComponent.applyStyle(options);
  };
  
  /**
   * 启用脉冲
   */
  private startPulsing = (): void => {
    if (!this.locationComponent) return;
    
    this.applyPulsingConfig();
    this.locationComponent.setLocationComponentEnabled(true);
    this.locationComponent.setRenderMode(RenderMode.NORMAL);
    this.pulsingEnabled = true;
    showToast('自定义脉冲已启动');
  };
  
  /**
   * 停止脉冲
   */
  private stopPulsing = (): void => {
    if (!this.locationComponent) return;
    
    this.locationComponent.setLocationComponentEnabled(false);
    this.pulsingEnabled = false;
    showToast('脉冲已停止');
  };
  
  /**
   * 更新脉冲颜色
   */
  private updateColor = (color: string): void => {
    this.pulseColor = color;
    if (this.pulsingEnabled) {
      this.applyPulsingConfig();
    }
    showToast(`颜色已更新: ${color}`);
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
    Button(this.pulsingEnabled ? '停止脉冲' : '开始脉冲')
      .enabled(this.permissionGranted)
      .onClick(() => {
        if (this.pulsingEnabled) {
          this.stopPulsing();
        } else {
          this.startPulsing();
        }
      })
    
    Button('蓝色')
      .backgroundColor('#4A90E2')
      .onClick(() => this.updateColor('#4A90E2'))
    
    Button('红色')
      .backgroundColor('#E74C3C')
      .onClick(() => this.updateColor('#E74C3C'))
    
    Button('绿色')
      .backgroundColor('#2ECC71')
      .onClick(() => this.updateColor('#2ECC71'))
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Customized Pulsing Circle',
        description: '自定义脉冲圆',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        actionButtons: (): void => this.buildActionButtons()
      })
    }
    .width('100%')
    .height('100%')
  }
}
