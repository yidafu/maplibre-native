/**
 * Basic Location Pulsing Circle Test Page
 * 基础定位脉冲圆测试页面
 * 
 * 测试功能:
 * - 基础定位脉冲圆效果
 * - 使用LocationComponent的脉冲功能
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
struct BasicLocationPulsingCircleTestPage {
  private mapController: MapLibreMap | null = null;
  private locationComponent: LocationComponent | null = null;
  @State private pulsingEnabled: boolean = false;
  @State private permissionGranted: boolean = false;
  @State private statusMessage: string = '等待初始化...';
  
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
    console.info('[BasicLocationPulsingCircleTestPage] onMapReady');
    this.mapController = map;
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 15);
    
    setTimeout(() => this.initLocationComponent(), 1500);
  };
  
  /**
   * 初始化定位组件
   */
  private initLocationComponent = async (): Promise<void> => {
    if (!this.mapController) return;
    
    try {
      // 请求权限
      const result = await PermissionManager.requestLocationPermission(getContext(this));
      this.permissionGranted = result.granted;
      
      if (!this.permissionGranted) {
        this.statusMessage = '定位权限被拒绝';
        showToast('定位权限被拒绝');
        return;
      }
      
      // 获取定位组件
      this.locationComponent = this.mapController.getLocationComponent();
      
      // 配置脉冲圆选项
      const options = new LocationComponentOptions();
      options.pulseEnabled = true;
      options.pulseColor = '#4A90E2';
      options.pulseMaxRadius = 50;
      
      // 激活定位组件
      this.locationComponent.activateLocationComponent(options);
      this.locationComponent.setRenderMode(RenderMode.NORMAL);
      
      this.statusMessage = '定位组件已初始化（脉冲圆启用）';
      showToast('定位组件已初始化');
    } catch (error) {
      console.error('[BasicLocationPulsingCircleTestPage] Init failed:', error);
      this.statusMessage = `初始化失败: ${error}`;
    }
  };
  
  /**
   * 启用定位（含脉冲圆）
   */
  private enableLocationWithPulsing = (): void => {
    if (!this.locationComponent) {
      showToast('定位组件未初始化');
      return;
    }
    
    try {
      this.locationComponent.setLocationComponentEnabled(true);
      this.pulsingEnabled = true;
      this.statusMessage = '定位已启用（脉冲圆启用）';
      showToast('定位已启用（脉冲圆启用）');
    } catch (error) {
      console.error('[BasicLocationPulsingCircleTestPage] Enable failed:', error);
    }
  };
  
  /**
   * 禁用定位
   */
  private disableLocation = (): void => {
    if (!this.locationComponent) return;
    
    try {
      this.locationComponent.setLocationComponentEnabled(false);
      this.pulsingEnabled = false;
      this.statusMessage = '定位已禁用';
      showToast('定位已禁用');
    } catch (error) {
      console.error('[BasicLocationPulsingCircleTestPage] Disable failed:', error);
    }
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
      Text('状态')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Text(this.statusMessage)
        .fontSize(12)
        .fontColor('#666')
        .padding(8)
        .backgroundColor('#F5F5F5')
        .borderRadius(4)
        .width('100%')
      
      Divider()
      
      Text('脉冲圆控制')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      
      Button(this.pulsingEnabled ? '禁用定位' : '启用定位（含脉冲）')
        .width('100%')
        .backgroundColor(this.pulsingEnabled ? '#FF6B6B' : '#4CAF50')
        .enabled(this.permissionGranted)
        .onClick(() => {
          if (this.pulsingEnabled) {
            this.disableLocation();
          } else {
            this.enableLocationWithPulsing();
          }
        })
      
      Text('说明: 使用LocationComponentOptions.pulsingEnabled')
        .fontSize(12)
        .fontColor('#666')
        .margin({ top: 8 })
      
      Text('脉冲圆会自动在定位点周围产生扩散动画效果')
        .fontSize(12)
        .fontColor('#666')
    }
    .width('100%')
    .padding(16)
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Basic Location Pulsing Circle',
        description: '基础定位脉冲圆',
        showActionBar: true,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%')
  }
}
