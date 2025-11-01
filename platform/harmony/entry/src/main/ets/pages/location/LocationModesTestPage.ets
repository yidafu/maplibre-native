/**
 * Location Modes Test Page
 * 定位模式测试页面
 * 
 * 参考: platform/android/.../location/LocationModesActivity.kt
 * 
 * 测试功能:
 * - 定位模式切换（NORMAL, COMPASS, GPS）
 * - 相机跟踪模式
 * - 定位点击监听
 * 
 * 使用 MapLibre LocationComponent API
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
  OnLocationClickListener,
  OnCameraTrackingChangedListener,
  PermissionManager
} from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import geoLocationManager from '@ohos.geoLocationManager';
import { MapView } from 'maplibre_harmony';

@Entry
@Component
struct LocationModesTestPage {
  private mapController: MapLibreMap | null = null;
  private locationComponent: LocationComponent | null = null;
  @State private currentRenderMode: number = RenderMode.NORMAL;
  @State private currentCameraMode: number = CameraMode.NONE;
  @State private locationEnabled: boolean = false;
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
    console.info('[LocationModesTestPage] onMapReady');
    this.mapController = map;
    this.mapController.setStyleUrl(DEFAULT_STYLE_URLS.streets);
    this.mapController.jumpTo(0, 39.9042, 116.4074, 0, 12);
    
    // 等待样式加载后初始化定位组件
    setTimeout(() => {
      this.initLocationComponent();
    }, 1500);
  };
  
  /**
   * 初始化定位组件
   */
  private initLocationComponent = async (): Promise<void> => {
    if (!this.mapController) return;
    
    try {
      // 先请求权限
      await this.requestPermissions();
      
      // 获取定位组件
      this.locationComponent = this.mapController.getLocationComponent();
      
      // 配置定位选项
      const options = new LocationComponentOptions();
      
      // 激活定位组件
      this.locationComponent.activateLocationComponent(options);
      
      // 添加定位点击监听器
      class ClickListener implements OnLocationClickListener {
        onLocationComponentClick(): void {
          showToast('定位点被点击');
        }
      }
      this.locationComponent.addOnLocationClickListener(new ClickListener());
      
      // 添加相机跟踪监听器
      class TrackingListener implements OnCameraTrackingChangedListener {
        page: LocationModesTestPage;
        
        constructor(page: LocationModesTestPage) {
          this.page = page;
        }
        
        onCameraTrackingDismissed(): void {
          this.page.statusMessage = '相机跟踪已取消';
        }
        
        onCameraTrackingChanged(currentMode: number): void {
          this.page.currentCameraMode = currentMode;
          this.page.statusMessage = `相机模式: ${CameraMode.getName(currentMode)}`;
        }
      }
      this.locationComponent.addOnCameraTrackingChangedListener(new TrackingListener(this));
      
      this.statusMessage = '定位组件已初始化';
      showToast('定位组件已初始化');
    } catch (error) {
      console.error('[LocationModesTestPage] Failed to init location component:', error);
      this.statusMessage = `初始化失败: ${error}`;
      showToast(`初始化失败: ${error}`);
    }
  };
  
  /**
   * 请求定位权限
   */
  private requestPermissions = async (): Promise<void> => {
    try {
      const result = await PermissionManager.requestLocationPermission(getContext(this));
      const granted = result.granted;
      this.permissionGranted = granted;
      
      if (granted) {
        this.statusMessage = '定位权限已授予';
      } else {
        this.statusMessage = '定位权限被拒绝';
        showToast('定位权限被拒绝');
      }
    } catch (error) {
      console.error('[LocationModesTestPage] Permission request failed:', error);
      this.statusMessage = `权限请求失败: ${error}`;
    }
  };
  
  /**
   * 启用定位
   */
  private enableLocation = (): void => {
    if (!this.locationComponent) {
      showToast('定位组件未初始化');
      return;
    }
    
    try {
      this.locationComponent.setLocationComponentEnabled(true);
      this.locationEnabled = true;
      this.statusMessage = '定位已启用';
      showToast('定位已启用');
    } catch (error) {
      console.error('[LocationModesTestPage] Failed to enable location:', error);
      showToast(`启用定位失败: ${error}`);
    }
  };
  
  /**
   * 禁用定位
   */
  private disableLocation = (): void => {
    if (!this.locationComponent) return;
    
    try {
      this.locationComponent.setLocationComponentEnabled(false);
      this.locationEnabled = false;
      this.statusMessage = '定位已禁用';
      showToast('定位已禁用');
    } catch (error) {
      console.error('[LocationModesTestPage] Failed to disable location:', error);
    }
  };
  
  /**
   * 切换渲染模式
   */
  private switchRenderMode = (mode: number): void => {
    if (!this.locationComponent) {
      showToast('定位组件未初始化');
      return;
    }
    
    try {
      this.locationComponent.setRenderMode(mode);
      this.currentRenderMode = mode;
      this.statusMessage = `渲染模式: ${RenderMode.getName(mode)}`;
      showToast(`渲染模式: ${RenderMode.getName(mode)}`);
    } catch (error) {
      console.error('[LocationModesTestPage] Failed to switch render mode:', error);
    }
  };
  
  /**
   * 切换相机跟踪模式
   */
  private switchCameraMode = (mode: number): void => {
    if (!this.locationComponent) {
      showToast('定位组件未初始化');
      return;
    }
    
    try {
      this.locationComponent.setCameraMode(mode);
      this.currentCameraMode = mode;
      this.statusMessage = `相机模式: ${CameraMode.getName(mode)}`;
      showToast(`相机模式: ${CameraMode.getName(mode)}`);
    } catch (error) {
      console.error('[LocationModesTestPage] Failed to switch camera mode:', error);
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
    Scroll() {
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
        
        Text('定位控制')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        
        Button(this.locationEnabled ? '禁用定位' : '启用定位')
          .width('100%')
          .backgroundColor(this.locationEnabled ? '#FF6B6B' : '#4CAF50')
          .enabled(this.permissionGranted)
          .onClick(() => {
            if (this.locationEnabled) {
              this.disableLocation();
            } else {
              this.enableLocation();
            }
          })
        
        Divider()
        
        Text('渲染模式 (RenderMode)')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        
        Button(`NORMAL ${this.currentRenderMode === RenderMode.NORMAL ? '✓' : ''}`)
          .width('100%')
          .backgroundColor(this.currentRenderMode === RenderMode.NORMAL ? '#2196F3' : '#9E9E9E')
          .enabled(this.locationEnabled)
          .onClick(() => this.switchRenderMode(RenderMode.NORMAL))
        
        Button(`COMPASS ${this.currentRenderMode === RenderMode.COMPASS ? '✓' : ''}`)
          .width('100%')
          .backgroundColor(this.currentRenderMode === RenderMode.COMPASS ? '#2196F3' : '#9E9E9E')
          .enabled(this.locationEnabled)
          .onClick(() => this.switchRenderMode(RenderMode.COMPASS))
        
        Button(`GPS ${this.currentRenderMode === RenderMode.GPS ? '✓' : ''}`)
          .width('100%')
          .backgroundColor(this.currentRenderMode === RenderMode.GPS ? '#2196F3' : '#9E9E9E')
          .enabled(this.locationEnabled)
          .onClick(() => this.switchRenderMode(RenderMode.GPS))
        
        Divider()
        
        Text('相机跟踪模式 (CameraMode)')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        
        Button(`NONE ${this.currentCameraMode === CameraMode.NONE ? '✓' : ''}`)
          .width('100%')
          .fontSize(12)
          .backgroundColor(this.currentCameraMode === CameraMode.NONE ? '#2196F3' : '#9E9E9E')
          .enabled(this.locationEnabled)
          .onClick(() => this.switchCameraMode(CameraMode.NONE))
        
        Button(`TRACKING ${this.currentCameraMode === CameraMode.TRACKING ? '✓' : ''}`)
          .width('100%')
          .fontSize(12)
          .backgroundColor(this.currentCameraMode === CameraMode.TRACKING ? '#2196F3' : '#9E9E9E')
          .enabled(this.locationEnabled)
          .onClick(() => this.switchCameraMode(CameraMode.TRACKING))
        
        Button(`TRACKING_COMPASS ${this.currentCameraMode === CameraMode.TRACKING_COMPASS ? '✓' : ''}`)
          .width('100%')
          .fontSize(11)
          .backgroundColor(this.currentCameraMode === CameraMode.TRACKING_COMPASS ? '#2196F3' : '#9E9E9E')
          .enabled(this.locationEnabled)
          .onClick(() => this.switchCameraMode(CameraMode.TRACKING_COMPASS))
        
        Button(`TRACKING_GPS ${this.currentCameraMode === CameraMode.TRACKING_GPS ? '✓' : ''}`)
          .width('100%')
          .fontSize(11)
          .backgroundColor(this.currentCameraMode === CameraMode.TRACKING_GPS ? '#2196F3' : '#9E9E9E')
          .enabled(this.locationEnabled)
          .onClick(() => this.switchCameraMode(CameraMode.TRACKING_GPS))
        
        Text('说明: 使用MapLibre LocationComponent')
          .fontSize(12)
          .fontColor('#666')
          .margin({ top: 8 })
      }
      .width('100%')
      .padding(16)
    }
    .height('100%')
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Location Modes',
        description: '定位模式测试',
        showActionBar: true,
        mapContent: this.buildMapContent,
        controlPanel: this.buildControlPanel
      })
    }
    .width('100%')
    .height('100%')
  }
}

