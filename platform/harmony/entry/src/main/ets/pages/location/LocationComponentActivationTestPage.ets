/**
 * Location Component Activation Test Page
 * 定位组件激活测试页面
 * 
 * 测试功能:
 * - 定位组件激活流程
 * - 权限请求处理
 * - LocationComponent完整生命周期
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
struct LocationComponentActivationTestPage {
  private mapController: MapLibreMap | null = null;
  private locationComponent: LocationComponent | null = null;
  @State private activationStep: number = 0; // 0:未开始, 1:权限请求, 2:组件激活, 3:定位启用
  @State private permissionGranted: boolean = false;
  @State private componentActivated: boolean = false;
  @State private locationEnabled: boolean = false;
  @State private statusLog:  string[] = [];
  
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
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 12);
    this.addLog('地图已初始化');
    this.activationStep = 1;
  };
  
  /**
   * 添加日志
   */
  private addLog = (message: string): void => {
    const timestamp = new Date().toLocaleTimeString();
    this.statusLog.unshift(`[${timestamp}] ${message}`);
    if (this.statusLog.length > 12) {
      this.statusLog.pop();
    }
  };
  
  /**
   * 步骤1: 请求权限
   */
  private requestPermissions = async (): Promise<void> => {
    this.addLog('步骤1: 请求定位权限...');
    
    try {
      const result = await PermissionManager.requestLocationPermission(getContext(this));
      this.permissionGranted = result.granted;
      
      if (this.permissionGranted) {
        this.addLog('✓ 定位权限已授予');
        this.activationStep = 2;
        showToast('定位权限已授予');
      } else {
        this.addLog('✗ 定位权限被拒绝');
        showToast('定位权限被拒绝');
      }
    } catch (error) {
      this.addLog(`✗ 权限请求失败: ${error}`);
    }
  };
  
  /**
   * 步骤2: 激活定位组件
   */
  private activateComponent = (): void => {
    if (!this.mapController) {
      this.addLog('✗ 地图未初始化');
      return;
    }
    
    this.addLog('步骤2: 激活定位组件...');
    
    try {
      // 获取定位组件
      this.locationComponent = this.mapController.getLocationComponent();
      
      // 配置选项
      const options = new LocationComponentOptions();
      options.pulseEnabled = true;
      
      // 激活组件
      this.locationComponent.activateLocationComponent(options);
      
      this.componentActivated = true;
      this.activationStep = 3;
      this.addLog('✓ 定位组件已激活');
      showToast('定位组件已激活');
    } catch (error) {
      this.addLog(`✗ 激活失败: ${error}`);
      console.error('[LocationComponentActivationTestPage] Activation failed:', error);
    }
  };
  
  /**
   * 步骤3: 启用定位
   */
  private enableLocation = (): void => {
    if (!this.locationComponent) {
      this.addLog('✗ 定位组件未激活');
      return;
    }
    
    this.addLog('步骤3: 启用定位...');
    
    try {
      this.locationComponent.setLocationComponentEnabled(true);
      this.locationComponent.setRenderMode(RenderMode.NORMAL);
      this.locationComponent.setCameraMode(CameraMode.TRACKING);
      
      this.locationEnabled = true;
      this.addLog('✓ 定位已启用');
      this.addLog('✓ 渲染模式: NORMAL');
      this.addLog('✓ 相机模式: TRACKING');
      showToast('定位已启用');
    } catch (error) {
      this.addLog(`✗ 启用失败: ${error}`);
    }
  };
  
  /**
   * 停用定位组件
   */
  private deactivateComponent = (): void => {
    if (!this.locationComponent) return;
    
    try {
      this.locationComponent.setLocationComponentEnabled(false);
      this.locationEnabled = false;
      this.componentActivated = false;
      this.activationStep = 2;
      this.addLog('✓ 定位已停用');
      showToast('定位已停用');
    } catch (error) {
      this.addLog(`✗ 停用失败: ${error}`);
    }
  };
  
  /**
   * 重置流程
   */
  private reset = (): void => {
    if (this.locationComponent) {
      this.locationComponent.setLocationComponentEnabled(false);
    }
    this.permissionGranted = false;
    this.componentActivated = false;
    this.locationEnabled = false;
    this.activationStep = 1;
    this.statusLog = [];
    this.addLog('流程已重置');
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
    Scroll() {
      Column({ space: 12 }) {
        Text('定位组件激活流程')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        
        Text(`当前步骤: ${this.activationStep}/3`)
          .fontSize(14)
          .fontColor(this.locationEnabled ? '#4CAF50' : '#666')
          .fontWeight(FontWeight.Medium)
        
        Divider()
        
        Text('步骤 1: 请求权限')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
        
        Button(`请求定位权限 ${this.permissionGranted ? '✓' : ''}`)
          .width('100%')
          .backgroundColor(this.permissionGranted ? '#4CAF50' : '#2196F3')
          .enabled(this.activationStep >= 1 && !this.permissionGranted)
          .onClick(() => this.requestPermissions())
        
        Divider()
        
        Text('步骤 2: 激活组件')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
        
        Button(`激活定位组件 ${this.componentActivated ? '✓' : ''}`)
          .width('100%')
          .backgroundColor(this.componentActivated ? '#4CAF50' : '#2196F3')
          .enabled(this.activationStep >= 2 && !this.componentActivated)
          .onClick(() => this.activateComponent())
        
        Divider()
        
        Text('步骤 3: 启用定位')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
        
        Button(this.locationEnabled ? '停用定位' : `启用定位 ${this.locationEnabled ? '✓' : ''}`)
          .width('100%')
          .backgroundColor(this.locationEnabled ? '#FF6B6B' : '#2196F3')
          .enabled(this.activationStep >= 3)
          .onClick(() => {
            if (this.locationEnabled) {
              this.deactivateComponent();
            } else {
              this.enableLocation();
            }
          })
        
        Divider()
        
        Button('重置流程')
          .width('100%')
          .backgroundColor('#FF9800')
          .onClick(() => this.reset())
        
        Divider()
        
        Text('状态日志')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
        
        Column() {
          ForEach(this.statusLog, (log: string, index: number) => {
            Text(log)
              .fontSize(10)
              .fontFamily('monospace')
              .width('100%')
              .padding(4)
              .backgroundColor(index % 2 === 0 ? '#F5F5F5' : '#FFFFFF')
          })
        }
        .width('100%')
        .backgroundColor('#F9F9F9')
        .border({ width: 1, color: '#DDD' })
        .borderRadius(4)
        .padding(8)
        .height(180)
      }
      .width('100%')
      .padding(16)
    }
    .height('100%')
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Location Component Activation',
        description: '定位组件激活',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      })
    }
    .width('100%')
    .height('100%')
  }
}
