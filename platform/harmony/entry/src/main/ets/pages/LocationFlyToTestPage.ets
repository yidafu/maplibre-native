/**
 * LocationFlyToTestPage - 定位组件测试页面（flyTo到定位位置）
 * 
 * 测试内容：
 * - 获取设备定位
 * - 使用flyTo动画移动到定位位置（zoom=6）
 */

import { NativeMapView } from 'maplibre_harmony/src/main/ets/maps/NativeMapView';
import { MapLibreMap } from 'maplibre_harmony/src/main/ets/maps/MapLibreMap';
import { MapLibreMapOptions } from 'maplibre_harmony/src/main/ets/maps/MapLibreMapOptions';
import { CameraPosition, createCameraPosition } from 'maplibre_harmony/src/main/ets/maps/camera/CameraPosition';
import { LatLng } from 'maplibre_harmony/src/main/ets/maps/geometry/LatLng';
import { router } from '@kit.ArkUI';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import geoLocationManager from '@ohos.geoLocationManager';
import promptAction from '@ohos.promptAction';
import maplibre from 'libmaplibre_native.so';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../constants/HiLogConstants';

/**
 * 定位组件测试页面（flyTo功能）
 */
@Entry
@Component
struct LocationFlyToTestPage {
  @State public hasPermission: boolean = false;
  @State public locationStatus: string = '准备获取定位';
  @State public currentLocation: string = '未获取';
  @State public isGettingLocation: boolean = false;

  private maplibreMap?: MapLibreMap;

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
      
      // 请求权限
      const requestResult = await atManager.requestPermissionsFromUser(
        getContext(this),
        permissions
      );

      if (requestResult.authResults[0] === 0 && requestResult.authResults[1] === 0) {
        this.hasPermission = true;
        this.locationStatus = '权限已授予';
        hilog.info(DOMAIN, 'LocationFlyTo', 'Location permission granted');
      } else {
        this.locationStatus = '权限被拒绝';
        hilog.warn(DOMAIN, 'LocationFlyTo', 'Location permission denied');
        promptAction.showToast({
          message: '需要定位权限才能使用此功能',
          duration: 2000
        });
      }
    } catch (err) {
      hilog.error(DOMAIN, 'LocationFlyTo', `Failed to request permissions: ${JSON.stringify(err)}`);
      this.locationStatus = `权限请求失败: ${err}`;
    }
  }

  /**
   * 地图准备回调
   */
  private onMapReady(nativeMapView?: maplibre.NativeMapView) {
    try {
      if (!nativeMapView) {
        hilog.error(DOMAIN, 'LocationFlyTo', 'NativeMapView is null');
        return;
      }
      
      // 创建地图选项
      const options = new MapLibreMapOptions();
      options.styleUrl = 'https://demotiles.maplibre.org/style.json';
      options.cameraPosition = createCameraPosition(
        new maplibre.LatLng(39.9042, 116.4074), // 北京天安门
        10, // 初始缩放
        0,  // 方位
        0   // 俯仰角
      );
      
      this.maplibreMap = new MapLibreMap(nativeMapView, options);
      hilog.info(DOMAIN, 'LocationFlyTo', 'Map ready');
    } catch (error) {
      hilog.error(DOMAIN, 'LocationFlyTo', `Map initialization failed: ${error}`);
      promptAction.showToast({
        message: `地图初始化失败: ${error}`,
        duration: 2000
      });
    }
  }

  /**
   * 获取当前位置并flyTo
   */
  async getCurrentLocationAndFlyTo() {
    if (!this.hasPermission) {
      promptAction.showToast({
        message: '请先授予定位权限',
        duration: 2000
      });
      return;
    }

    if (!this.maplibreMap) {
      promptAction.showToast({
        message: '地图未就绪',
        duration: 2000
      });
      return;
    }

    this.isGettingLocation = true;
    this.locationStatus = '正在获取定位...';

    try {
      // 检查位置服务是否开启
      if (!geoLocationManager.isLocationEnabled()) {
        this.locationStatus = '位置服务未开启';
        promptAction.showToast({
          message: '请先在设置中开启位置服务',
          duration: 2000
        });
        this.isGettingLocation = false;
        return;
      }

      hilog.info(DOMAIN, 'LocationFlyTo', 'Getting last known location');
      
      // 获取最后已知位置
      const location = geoLocationManager.getLastLocation();
      
      if (location) {
        const latitude = location.latitude;
        const longitude = location.longitude;
        
        hilog.info(DOMAIN, 'LocationFlyTo', 
          `Location: lat=${latitude}, lng=${longitude}`);
        
        this.currentLocation = `${latitude.toFixed(6)}, ${longitude.toFixed(6)}`;
        this.locationStatus = '定位成功，正在移动...';
        
        // 使用flyTo移动到定位位置，zoom=6
        this.flyToLocation(latitude, longitude);
      } else {
        this.locationStatus = '无法获取定位';
        promptAction.showToast({
          message: '无法获取最后已知位置',
          duration: 2000
        });
      }
    } catch (error) {
      hilog.error(DOMAIN, 'LocationFlyTo', `Failed to get location: ${error}`);
      this.locationStatus = `获取定位失败: ${error}`;
      promptAction.showToast({
        message: `获取定位失败: ${error}`,
        duration: 2000
      });
    } finally {
      this.isGettingLocation = false;
    }
  }

  /**
   * 使用flyTo动画移动到指定位置
   */
  private flyToLocation(latitude: number, longitude: number) {
    if (!this.maplibreMap) {
      return;
    }

    try {
      hilog.info(DOMAIN, 'LocationFlyTo', 
        `Flying to location: lat=${latitude}, lng=${longitude}, zoom=6`);
      
      // 创建CameraOptions对象
      const cameraOptions: maplibre.CameraOptions = {
        center: new maplibre.LatLng(latitude, longitude),
        zoom: 6,        // 缩放级别设置为6
        bearing: 0,     // 方位角
        pitch: 0        // 俯仰角
      };
      
      // 使用flyTo方法，duration=2000ms
      this.maplibreMap.flyTo(cameraOptions, 2000);
      
      this.locationStatus = '定位成功！已移动到目标位置';
      
      hilog.info(DOMAIN, 'LocationFlyTo', 'flyTo completed successfully');
    } catch (error) {
      hilog.error(DOMAIN, 'LocationFlyTo', `flyTo failed: ${error}`);
      this.locationStatus = `移动失败: ${error}`;
      promptAction.showToast({
        message: `移动地图失败: ${error}`,
        duration: 2000
      });
    }
  }

  /**
   * 使用自定义位置测试（用于调试）
   */
  testWithCustomLocation() {
    if (!this.maplibreMap) {
      return;
    }

    // 测试坐标：杭州西湖
    const latitude = 30.2591;
    const longitude = 120.1328;
    
    this.currentLocation = `${latitude.toFixed(6)}, ${longitude.toFixed(6)}`;
    this.locationStatus = '使用测试位置';
    
    this.flyToLocation(latitude, longitude);
  }

  /**
   * 重置地图
   */
  resetMap() {
    if (!this.maplibreMap) {
      return;
    }

    try {
      // 重置到北京天安门，zoom=10
      this.maplibreMap.jumpTo(
        0,          // bearing
        39.9042,    // latitude
        116.4074,   // longitude
        0,          // pitch
        10          // zoom
      );
      
      this.currentLocation = '未获取';
      this.locationStatus = '地图已重置';
      
      hilog.info(DOMAIN, 'LocationFlyTo', 'Map reset to Beijing');
    } catch (error) {
      hilog.error(DOMAIN, 'LocationFlyTo', `Reset failed: ${error}`);
    }
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

        Text('定位测试（flyTo）')
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
          Text(`状态: ${this.locationStatus}`)
            .fontSize(14)
            .fontColor(Color.White)
            .padding(8)
            .backgroundColor('rgba(0,0,0,0.7)')
            .borderRadius(4)

          if (this.currentLocation !== '未获取') {
            Text(`坐标: ${this.currentLocation}`)
              .fontSize(12)
              .fontColor(Color.White)
              .padding(8)
              .backgroundColor('rgba(0,0,0,0.7)')
              .borderRadius(4)
              .margin({ top: 4 })
          }

          Text('缩放级别: 6')
            .fontSize(12)
            .fontColor(Color.White)
            .padding(8)
            .backgroundColor('rgba(0,0,0,0.7)')
            .borderRadius(4)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ top: 16, left: 16 })
      }
      .width('100%')
      .height('60%')

      // 控制区（40%）
      Scroll() {
        Column({ space: 12 }) {
          // 状态信息
          Text('定位测试')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .margin({ top: 8 })

          Text('点击"获取定位并移动"按钮将获取当前位置，并使用flyTo动画移动到该位置，缩放级别为6。')
            .fontSize(14)
            .fontColor('#666666')
            .width('100%')
            .lineHeight(20)
            .margin({ bottom: 8 })

          Divider().height(1).color('#E0E0E0')

          // 主操作按钮
          Row() {
            Button('获取定位并移动')
              .type(ButtonType.Normal)
              .backgroundColor('#4CAF50')
              .fontColor(Color.White)
              .onClick(() => {
                this.getCurrentLocationAndFlyTo();
              })
              .enabled(!this.isGettingLocation)
              .width('48%')

            Button('测试位置')
              .type(ButtonType.Normal)
              .backgroundColor('#2196F3')
              .fontColor(Color.White)
              .onClick(() => {
                this.testWithCustomLocation();
              })
              .margin({ left: 8 })
              .width('48%')
          }
          .width('100%')
          .height(56)

          Button('重置地图')
            .type(ButtonType.Normal)
            .backgroundColor('#FF9800')
            .fontColor(Color.White)
            .onClick(() => {
              this.resetMap();
            })
            .width('48%')
            .margin({ top: 8 })

          Divider().height(1).color('#E0E0E0')
            .margin({ top: 8, bottom: 8 })

          // 说明
          Column({ space: 8 }) {
            Text('功能说明：')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .width('100%')

            Text('1. 获取定位：使用鸿蒙定位服务获取当前位置')
              .fontSize(13)
              .fontColor('#666666')
              .width('100%')

            Text('2. flyTo动画：使用平滑飞行动画移动到定位位置')
              .fontSize(13)
              .fontColor('#666666')
              .width('100%')

            Text('3. 缩放级别：自动设置zoom=6，适合显示城市范围')
              .fontSize(13)
              .fontColor('#666666')
              .width('100%')

            Text('4. 测试位置：使用杭州坐标（30.2591, 120.1328）进行测试')
              .fontSize(13)
              .fontColor('#666666')
              .width('100%')
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .margin({ top: 8 })
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

