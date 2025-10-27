import { MapViewComponentController } from '../maps/MapViewComponentController';
import { MapLibreMap } from '../maps/MapLibreMap';
import { LocationComponent } from '../maps/location/LocationComponent';
import { LocationComponentOptions } from '../maps/location/LocationComponentOptions';
import { CameraMode } from '../maps/location/modes/CameraMode';
import { RenderMode } from '../maps/location/modes/RenderMode';
import { LatLng } from '../maps/geometry/LatLng';
import { router } from '@kit.ArkUI';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * LocationComponent 测试页面
 * 演示用户定位功能的使用
 */
@Entry
@Component
struct LocationComponentTestPage {
  @State mapController: MapViewComponentController = new MapViewComponentController();
  @State locationEnabled: boolean = false;
  @State currentMode: string = 'NONE';
  @State currentRenderMode: string = 'NORMAL';
  @State hasPermission: boolean = false;

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
   * 地图加载完成回调
   */
  onMapReady(map: MapLibreMap) {
    console.info('LocationComponentTestPage: Map ready');
    this.maplibreMap = map;

    // 设置地图中心到北京
    map.setCenterCoordinate(new LatLng(39.9042, 116.4074));
    map.setZoom(15);

    // 等待样式加载完成后初始化 LocationComponent
    map.addOnStyleLoadedListener({
      onStyleLoaded: () => {
        console.info('LocationComponentTestPage: Style loaded, initializing LocationComponent');
        this.initializeLocationComponent();
      }
    });
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
      this.locationComponent.addOnCameraTrackingChangedListener({
        onCameraTrackingChanged: (mode: number) => {
          this.currentMode = CameraMode.getName(mode);
          console.info(`Camera tracking mode changed: ${this.currentMode}`);
        },
        onCameraTrackingDismissed: () => {
          console.info('Camera tracking dismissed by user');
        }
      });

      this.locationComponent.addOnRenderModeChangedListener({
        onRenderModeChanged: (mode: number) => {
          this.currentRenderMode = RenderMode.getName(mode);
          console.info(`Render mode changed: ${this.currentRenderMode}`);
        }
      });

      this.locationComponent.addOnLocationStaleListener({
        onStaleStateChange: (isStale: boolean) => {
          console.info(`Location stale state: ${isStale}`);
        }
      });

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
        Text('LocationComponent 测试')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })

        Blank()

        Button('返回')
          .onClick(() => {
            router.back();
          })
          .margin({ right: 16 })
      }
      .width('100%')
      .height(56)
      .backgroundColor('#F5F5F5')

      // 地图视图
      Stack() {
        MapViewComponent({
          controller: this.mapController,
          onMapReady: (map: MapLibreMap) => {
            this.onMapReady(map);
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
      .layoutWeight(1)

      // 控制面板
      Column() {
        // 基础控制
        Row() {
          Button(this.locationEnabled ? '关闭定位' : '开启定位')
            .onClick(() => {
              this.toggleLocation();
            })
            .type(ButtonType.Normal)
            .backgroundColor(this.locationEnabled ? '#FF6B6B' : '#4CAF50')
            .layoutWeight(1)

          Button('模拟位置')
            .onClick(() => {
              this.simulateLocation();
            })
            .margin({ left: 8 })
            .layoutWeight(1)
        }
        .width('100%')
        .padding(8)

        Divider().height(1).color('#E0E0E0')

        // 相机模式
        Text('相机模式')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 8, bottom: 4 })

        Row() {
          Button('无')
            .onClick(() => {
              this.setCameraMode(CameraMode.NONE);
            })
            .fontSize(12)
            .layoutWeight(1)

          Button('跟踪')
            .onClick(() => {
              this.setCameraMode(CameraMode.TRACKING);
            })
            .fontSize(12)
            .margin({ left: 4 })
            .layoutWeight(1)

          Button('跟踪+指南针')
            .onClick(() => {
              this.setCameraMode(CameraMode.TRACKING_COMPASS);
            })
            .fontSize(12)
            .margin({ left: 4 })
            .layoutWeight(1)

          Button('跟踪+GPS')
            .onClick(() => {
              this.setCameraMode(CameraMode.TRACKING_GPS);
            })
            .fontSize(12)
            .margin({ left: 4 })
            .layoutWeight(1)
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
            .layoutWeight(1)

          Button('指南针')
            .onClick(() => {
              this.setRenderMode(RenderMode.COMPASS);
            })
            .fontSize(12)
            .margin({ left: 8 })
            .layoutWeight(1)

          Button('GPS')
            .onClick(() => {
              this.setRenderMode(RenderMode.GPS);
            })
            .fontSize(12)
            .margin({ left: 8 })
            .layoutWeight(1)
        }
        .width('100%')
        .padding(8)
      }
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 16, topRight: 16 })
      .shadow({ radius: 8, color: 'rgba(0,0,0,0.1)' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

// 注意：MapViewComponent 是一个占位符，实际实现需要根据项目的 MapView 组件来定义
@Component
struct MapViewComponent {
  controller: MapViewComponentController = new MapViewComponentController();
  onMapReady?: (map: MapLibreMap) => void;

  build() {
    Stack() {
      Text('地图视图占位')
        .fontSize(16)
        .fontColor(Color.Gray)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#E8E8E8')
  }
}

