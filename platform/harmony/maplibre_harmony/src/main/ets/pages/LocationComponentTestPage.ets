import { NativeMapView } from '../maps/NativeMapView';
import { MapLibreMap } from '../maps/MapLibreMap';
import { MapLibreMapOptions } from '../maps/MapLibreMapOptions';
import { CameraPosition, createCameraPosition } from '../maps/camera/CameraPosition';
import { LocationComponent } from '../maps/location/LocationComponent';
import { LocationComponentOptions } from '../maps/location/LocationComponentOptions';
import { CameraMode } from '../maps/location/modes/CameraMode';
import { RenderMode } from '../maps/location/modes/RenderMode';
import { LatLng } from '../maps/geometry/LatLng';
import { router } from '@kit.ArkUI';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { BusinessError } from '@kit.BasicServicesKit';
import maplibre from 'libmaplibre_native.so';
import { OnStyleLoadedListener } from '../maps/listeners/OnStyleLoadedListener';
import { OnCameraTrackingChangedListener } from '../maps/location/listeners/OnCameraTrackingChangedListener';
import { OnRenderModeChangedListener } from '../maps/location/listeners/OnRenderModeChangedListener';
import { OnLocationStaleListener } from '../maps/location/listeners/OnLocationStaleListener';

// 样式加载监听器实现
class StyleLoadedListenerImpl implements OnStyleLoadedListener {
  private testPage: LocationComponentTestPage;

  constructor(testPage: LocationComponentTestPage) {
    this.testPage = testPage;
  }

  onStyleLoaded(): void {
    console.info('LocationComponentTestPage: Style loaded, initializing LocationComponent');
    this.testPage.initializeLocationComponent();
  }
}

// 相机跟踪监听器实现
class CameraTrackingListenerImpl implements OnCameraTrackingChangedListener {
  private testPage: LocationComponentTestPage;

  constructor(testPage: LocationComponentTestPage) {
    this.testPage = testPage;
  }

  onCameraTrackingChanged(mode: number): void {
    this.testPage.currentMode = CameraMode.getName(mode);
    console.info(`Camera tracking mode changed: ${this.testPage.currentMode}`);
  }

  onCameraTrackingDismissed(): void {
    console.info('Camera tracking dismissed by user');
  }
}

// 渲染模式监听器实现
class RenderModeListenerImpl implements OnRenderModeChangedListener {
  private testPage: LocationComponentTestPage;

  constructor(testPage: LocationComponentTestPage) {
    this.testPage = testPage;
  }

  onRenderModeChanged(mode: number): void {
    this.testPage.currentRenderMode = RenderMode.getName(mode);
    console.info(`Render mode changed: ${this.testPage.currentRenderMode}`);
  }
}

// 位置陈旧监听器实现
class StaleListenerImpl implements OnLocationStaleListener {
  private testPage: LocationComponentTestPage;

  constructor(testPage: LocationComponentTestPage) {
    this.testPage = testPage;
  }

  onStaleStateChange(isStale: boolean): void {
    console.info(`Location stale state: ${isStale}`);
  }
}

/**
 * LocationComponent 测试页面
 * 演示用户定位功能的使用
 */
@Entry
@Component
struct LocationComponentTestPage {
  @State public locationEnabled: boolean = false;
  @State public currentMode: string = 'NONE';
  @State public currentRenderMode: string = 'NORMAL';
  @State public hasPermission: boolean = false;

  private maplibreMap?: MapLibreMap;
  private locationComponent?: LocationComponent;

  aboutToAppear() {
    // 检查并请求权限
    this.checkAndRequestPermissions();
  }

  /**
   * 检查并请求位置权限
   */
  async checkAndRequestPermissions() {
    const permissions: Array<Permissions> = [
      'ohos.permission.APPROXIMATELY_LOCATION',
      'ohos.permission.LOCATION'
    ];

    try {
      const atManager = abilityAccessCtrl.createAtManager();
      
      // 检查权限
      const grantStatus = await atManager.checkAccessToken(
        12345, // tokenID，实际使用时应该获取当前应用的 tokenID
        permissions[0]
      );

      if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        this.hasPermission = true;
        return;
      }

      // 请求权限
      const requestResult = await atManager.requestPermissionsFromUser(
        getContext(this),
        permissions
      );

      if (requestResult.authResults[0] === 0) {
        this.hasPermission = true;
        console.info('Location permission granted');
      } else {
        console.warn('Location permission denied');
      }
    } catch (err) {
      console.error('Failed to request permissions:', JSON.stringify(err));
    }
  }

  /**
   * 地图准备回调
   */
  private onMapReady(nativeMapView?: maplibre.NativeMapView) {
    try {
      if (!nativeMapView) {
        console.error('LocationComponentTestPage: NativeMapView is null');
        return;
      }
      
      const latLng = new maplibre.LatLng(39.9042, 116.4074);
      const cameraPos = createCameraPosition(latLng, 15, 0, 0);
      const options = new MapLibreMapOptions();
      options.cameraPosition = cameraPos;
      options.styleUrl = 'https://demotiles.maplibre.org/style.json';
      
      this.maplibreMap = new MapLibreMap(nativeMapView, options);
      console.info('LocationComponentTestPage: Map ready');

      // 等待样式加载完成后初始化 LocationComponent
      const styleLoadedListener = new StyleLoadedListenerImpl(this);
      this.maplibreMap.addOnStyleLoadedListener(styleLoadedListener);
    } catch (error) {
      console.error('LocationComponentTestPage: Map initialization failed:', error);
    }
  }

  /**
   * 初始化 LocationComponent
   */
  initializeLocationComponent() {
    if (!this.maplibreMap) {
      console.error('MapLibreMap not ready');
      return;
    }

    try {
      // 获取位置组件
      this.locationComponent = this.maplibreMap.getLocationComponent();

      // 创建配置
      const options = LocationComponentOptions.builder()
        .setAccuracyAlpha(0.2)
        .setAccuracyColor('#4264fb')
        .setEnableStaleState(true)
        .setStaleStateTimeout(60000)
        .setCompassAnimationEnabled(true)
        .setAccuracyAnimationEnabled(true)
        .setTrackingAnimationDurationMultiplier(1.1)
        .build();

      // 激活组件
      this.locationComponent.activateLocationComponent(options);

      // 添加监听器
      const cameraTrackingListener = new CameraTrackingListenerImpl(this);
      this.locationComponent.addOnCameraTrackingChangedListener(cameraTrackingListener);

      const renderModeListener = new RenderModeListenerImpl(this);
      this.locationComponent.addOnRenderModeChangedListener(renderModeListener);

      const staleListener = new StaleListenerImpl(this);
      this.locationComponent.addOnLocationStaleListener(staleListener);

      console.info('LocationComponent initialized successfully');
    } catch (err) {
      console.error('Failed to initialize LocationComponent:', JSON.stringify(err));
    }
  }

  /**
   * 切换位置组件启用状态
   */
  toggleLocation() {
    if (!this.locationComponent) {
      console.warn('LocationComponent not initialized');
      return;
    }

    if (!this.hasPermission) {
      console.warn('No location permission');
      return;
    }

    this.locationEnabled = !this.locationEnabled;
    this.locationComponent.setLocationComponentEnabled(this.locationEnabled);
    
    if (this.locationEnabled) {
      // 启用后设置默认的相机模式
      this.locationComponent.setCameraMode(CameraMode.TRACKING);
    }
  }

  /**
   * 设置相机模式
   */
  setCameraMode(mode: number) {
    if (!this.locationComponent || !this.locationEnabled) {
      return;
    }
    this.locationComponent.setCameraMode(mode);
  }

  /**
   * 设置渲染模式
   */
  setRenderMode(mode: number) {
    if (!this.locationComponent || !this.locationEnabled) {
      return;
    }
    this.locationComponent.setRenderMode(mode);
  }

  /**
   * 模拟位置更新（用于测试）
   */
  simulateLocation() {
    if (!this.locationComponent) {
      return;
    }

    // 模拟在北京天安门附近的位置
    const lat = 39.9042 + (Math.random() - 0.5) * 0.01;
    const lng = 116.4074 + (Math.random() - 0.5) * 0.01;
    const bearing = Math.random() * 360;
    const accuracy = 10 + Math.random() * 20;

    this.locationComponent.forceLocationUpdate(lat, lng, bearing, accuracy);
    console.info(`Simulated location: ${lat}, ${lng}`);
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

        Text('LocationComponent 测试')
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
        NativeMapView({
        onMapReady: (nativeMapView?: maplibre.NativeMapView) => {
          this.onMapReady(nativeMapView);
        }
        })
          .width('100%')
          .height('100%')

        // 状态显示
        Column() {
          Text(`定位: ${this.locationEnabled ? '开启' : '关闭'}`)
            .fontSize(14)
            .fontColor(Color.White)
            .padding(8)
            .backgroundColor('rgba(0,0,0,0.6)')
            .borderRadius(4)

          Text(`相机: ${this.currentMode}`)
            .fontSize(14)
            .fontColor(Color.White)
            .padding(8)
            .backgroundColor('rgba(0,0,0,0.6)')
            .borderRadius(4)
            .margin({ top: 4 })

          Text(`渲染: ${this.currentRenderMode}`)
            .fontSize(14)
            .fontColor(Color.White)
            .padding(8)
            .backgroundColor('rgba(0,0,0,0.6)')
            .borderRadius(4)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ top: 16, left: 16 })
      }
      .width('100%')
      .height('60%')

      // 测试按钮区域（40%，可滚动）
      Scroll() {
        Column() {
        // 基础控制
        Row() {
          Button(this.locationEnabled ? '关闭定位' : '开启定位')
            .onClick(() => {
              this.toggleLocation();
            })
            .type(ButtonType.Normal)
            .backgroundColor(this.locationEnabled ? '#FF6B6B' : '#4CAF50')
            .width('48%')

          Button('模拟位置')
            .onClick(() => {
              this.simulateLocation();
            })
            .margin({ left: 8 })
            .width('48%')
        }
        .width('100%')
        .padding(8)

        Divider().height(1).color('#E0E0E0')

        // 相机模式
        Text('相机模式')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 8, bottom: 4 })

        Column({ space: 8 }) {
          Row() {
            Button('无')
              .onClick(() => {
                this.setCameraMode(CameraMode.NONE);
              })
              .fontSize(12)
              .width('48%')

            Button('跟踪')
              .onClick(() => {
                this.setCameraMode(CameraMode.TRACKING);
              })
              .fontSize(12)
              .margin({ left: 8 })
              .width('48%')
          }
          .width('100%')

          Row() {
            Button('跟踪+指南针')
              .onClick(() => {
                this.setCameraMode(CameraMode.TRACKING_COMPASS);
              })
              .fontSize(12)
              .width('48%')

            Button('跟踪+GPS')
              .onClick(() => {
                this.setCameraMode(CameraMode.TRACKING_GPS);
              })
              .fontSize(12)
              .margin({ left: 8 })
              .width('48%')
          }
          .width('100%')
        }
        .width('100%')
        .padding(8)

        Divider().height(1).color('#E0E0E0')

        // 渲染模式
        Text('渲染模式')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 4, bottom: 4 })

        Row() {
          Button('普通')
            .onClick(() => {
              this.setRenderMode(RenderMode.NORMAL);
            })
            .fontSize(12)
            .width('48%')

          Button('指南针')
            .onClick(() => {
              this.setRenderMode(RenderMode.COMPASS);
            })
            .fontSize(12)
            .margin({ left: 8 })
            .width('48%')
        }
        .width('100%')
        .padding(8)

        Row() {
          Button('GPS')
            .onClick(() => {
              this.setRenderMode(RenderMode.GPS);
            })
            .fontSize(12)
            .width('48%')
        }
        .width('100%')
        .padding({ top: 0 })
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

