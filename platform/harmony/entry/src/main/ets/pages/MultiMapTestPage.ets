/**
 * 多地图实例测试页面
 * 测试多个地图实例的同时显示、独立交互和资源管理
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { maplibre } from 'maplibre_harmony';
import { NativeMapView } from 'maplibre_harmony/src/main/ets/maps/NativeMapView';
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { DOMAIN } from '../constants/HiLogConstants';
import { TestPageLayout } from '../components/TestPageLayout';

const TAG = 'MultiMapTestPage';

// 地图实例配置
interface MapInstanceConfig {
  id: number;
  name: string;
  latitude: number;
  longitude: number;
  zoom: number;
  icon: string;
  mapView: maplibre.NativeMapView | null;
}

@Entry
@Component
struct MultiMapTestPage {
  @State mapInstancesReady: number = 0;
  @State totalMapInstances: number = 3;
  @State dynamicMapsCount: number = 0;
  @State testMode: string = 'static'; // 'static' 或 'dynamic'
  
  // 静态地图配置
  private staticMapConfigs: MapInstanceConfig[] = [
    {
      id: 1,
      name: '杭州 - 西湖',
      latitude: 30.2489,
      longitude: 120.1363,
      zoom: 10,
      icon: '🏞️',
      mapView: null
    },
    {
      id: 2,
      name: '北京 - 天安门',
      latitude: 39.9042,
      longitude: 116.4074,
      zoom: 10,
      icon: '🏛️',
      mapView: null
    },
    {
      id: 3,
      name: '上海 - 东方明珠',
      latitude: 31.2397,
      longitude: 121.4997,
      zoom: 10,
      icon: '🗼',
      mapView: null
    }
  ];
  
  // 动态地图配置
  @State dynamicMapConfigs: MapInstanceConfig[] = [];

  @Builder
  MapAreaBuilder() {
    Column() {
      // 状态信息栏
      Row() {
        Text(`已就绪: ${this.mapInstancesReady}/${this.testMode === 'static' ? this.totalMapInstances : this.dynamicMapsCount}`)
          .fontSize(14)
          .fontColor('#666')
          .margin({ left: 15 })
        
        Blank()
        
        Text(`模式: ${this.testMode === 'static' ? '静态' : '动态'}`)
          .fontSize(14)
          .fontColor('#666')
          .margin({ right: 15 })
      }
      .width('100%')
      .height(40)
      .backgroundColor('#FFFACD')

      // 测试模式切换
      Row() {
        Button('静态模式')
          .fontSize(14)
          .backgroundColor(this.testMode === 'static' ? '#2196F3' : '#CCCCCC')
          .fontColor(Color.White)
          .layoutWeight(1)
          .onClick(() => {
            this.testMode = 'static';
            this.mapInstancesReady = 0;
          })
        
        Button('动态模式')
          .fontSize(14)
          .backgroundColor(this.testMode === 'dynamic' ? '#2196F3' : '#CCCCCC')
          .fontColor(Color.White)
          .layoutWeight(1)
          .onClick(() => {
            this.testMode = 'dynamic';
            this.mapInstancesReady = 0;
            this.dynamicMapsCount = 0;
            this.dynamicMapConfigs = [];
          })
      }
      .width('100%')
      .padding(10)
      .backgroundColor('#F5F5F5')

      // 动态模式控制按钮
      if (this.testMode === 'dynamic') {
        Row() {
          Button('添加地图')
            .fontSize(14)
            .backgroundColor('#4CAF50')
            .fontColor(Color.White)
            .layoutWeight(1)
            .onClick(() => {
              this.addDynamicMap();
            })
          
          Button('移除地图')
            .fontSize(14)
            .backgroundColor('#F44336')
            .fontColor(Color.White)
            .layoutWeight(1)
            .enabled(this.dynamicMapsCount > 0)
            .onClick(() => {
              this.removeDynamicMap();
            })
          
          Button('清空所有')
            .fontSize(14)
            .backgroundColor('#FF9800')
            .fontColor(Color.White)
            .layoutWeight(1)
            .enabled(this.dynamicMapsCount > 0)
            .onClick(() => {
              this.clearAllDynamicMaps();
            })
        }
        .width('100%')
        .padding(10)
        .backgroundColor('#F5F5F5')
      }

      // 地图显示区域
      Scroll() {
        Column() {
          if (this.testMode === 'static') {
            // 静态模式 - 显示3个固定地图
            this.buildStaticMaps()
          } else {
            // 动态模式 - 显示动态添加的地图
            this.buildDynamicMaps()
          }
        }
        .width('100%')
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
      .scrollBarColor('#888888')
      .scrollBarWidth(4)
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
      .width('100%')

      // 测试说明
      Column() {
        Text('测试说明')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 5 })
        
        Text('静态模式：同时显示3个固定地图，测试基础多实例功能')
          .fontSize(12)
          .fontColor('#666')
          .margin({ bottom: 3 })
        
        Text('动态模式：测试地图的动态添加和删除，验证资源管理')
          .fontSize(12)
          .fontColor('#666')
          .margin({ bottom: 3 })
        
        Text('预期结果：所有地图都能正常显示和独立交互，无白屏/黑屏')
          .fontSize(12)
          .fontColor('#4CAF50')
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .padding(15)
      .backgroundColor('#F5F5F5')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ControlAreaBuilder() {
    Text('控制区（本页面特殊，主要内容在地图区）')
      .fontSize(14)
      .fontColor('#999999')
  }

  build() {
    Column() {
      TestPageLayout({
        title: '多地图实例测试',
        mapArea: (): void => this.MapAreaBuilder(),
        controlArea: (): void => this.ControlAreaBuilder()
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildStaticMaps() {
    Column() {
      ForEach(this.staticMapConfigs, (config: MapInstanceConfig, index: number) => {
        Column() {
          // 地图标题
          Row() {
            Text(config.icon)
              .fontSize(18)
              .margin({ right: 8 })
            
            Text(`地图 #${config.id}: ${config.name}`)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            
            Blank()
            
            if (config.mapView !== null) {
              Text('✅ 已就绪')
                .fontSize(12)
                .fontColor('#4CAF50')
            } else {
              Text('⏳ 加载中...')
                .fontSize(12)
                .fontColor('#FF9800')
            }
          }
          .width('100%')
          .padding({ left: 15, right: 15, top: 10, bottom: 10 })
          .backgroundColor('#E3F2FD')

          // 地图视图
          NativeMapView({
            styleUrl: "https://demotiles.maplibre.org/style.json",
            initialLatitude: config.latitude,
            initialLongitude: config.longitude,
            initialZoom: config.zoom,
            initialBearing: 0,
            initialPitch: 0,
            onMapReady: (mapView?: maplibre.NativeMapView) => {
              if (mapView) {
                config.mapView = mapView;
                this.mapInstancesReady++;
                hilog.info(DOMAIN, TAG, `静态地图 #${config.id} 已就绪 (${this.mapInstancesReady}/${this.totalMapInstances})`);
              } else {
                hilog.error(DOMAIN, TAG, `静态地图 #${config.id} 初始化失败`);
              }
            }
          })
            .width('100%')
            .height(250)

          // 分隔线
          if (index < this.staticMapConfigs.length - 1) {
            Divider()
              .height(8)
              .color('#EEEEEE')
          }
        }
        .width('100%')
      }, (config: MapInstanceConfig) => `static-map-${config.id}`)
    }
    .width('100%')
  }

  @Builder
  buildDynamicMaps() {
    Column() {
      if (this.dynamicMapConfigs.length === 0) {
        // 空状态提示
        Column() {
          Text('📭')
            .fontSize(48)
            .margin({ bottom: 10 })
          
          Text('暂无地图实例')
            .fontSize(16)
            .fontColor('#999')
            .margin({ bottom: 5 })
          
          Text('点击"添加地图"按钮开始测试')
            .fontSize(14)
            .fontColor('#CCC')
        }
        .width('100%')
        .height(300)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        ForEach(this.dynamicMapConfigs, (config: MapInstanceConfig, index: number) => {
          Column() {
            // 地图标题
            Row() {
              Text(config.icon)
                .fontSize(18)
                .margin({ right: 8 })
              
              Text(`地图 #${config.id}: ${config.name}`)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
              
              Blank()
              
              if (config.mapView !== null) {
                Text('✅ 已就绪')
                  .fontSize(12)
                  .fontColor('#4CAF50')
              } else {
                Text('⏳ 加载中...')
                  .fontSize(12)
                  .fontColor('#FF9800')
              }
            }
            .width('100%')
            .padding({ left: 15, right: 15, top: 10, bottom: 10 })
            .backgroundColor('#FFF3E0')

            // 地图视图
            NativeMapView({
              styleUrl: "https://demotiles.maplibre.org/style.json",
              initialLatitude: config.latitude,
              initialLongitude: config.longitude,
              initialZoom: config.zoom,
              initialBearing: 0,
              initialPitch: 0,
              onMapReady: (mapView?: maplibre.NativeMapView) => {
                if (mapView) {
                  config.mapView = mapView;
                  this.mapInstancesReady++;
                  hilog.info(DOMAIN, TAG, `动态地图 #${config.id} 已就绪 (${this.mapInstancesReady}/${this.dynamicMapsCount})`);
                } else {
                  hilog.error(DOMAIN, TAG, `动态地图 #${config.id} 初始化失败`);
                }
              }
            })
              .width('100%')
              .height(250)

            // 分隔线
            if (index < this.dynamicMapConfigs.length - 1) {
              Divider()
                .height(8)
                .color('#EEEEEE')
            }
          }
          .width('100%')
        }, (config: MapInstanceConfig) => `dynamic-map-${config.id}`)
      }
    }
    .width('100%')
  }

  /**
   * 添加动态地图
   */
  private addDynamicMap(): void {
    interface CityInfo {
      name: string;
      lat: number;
      lon: number;
      icon: string;
    }
    
    const cities: CityInfo[] = [
      { name: '杭州 - 西湖', lat: 30.2489, lon: 120.1363, icon: '🏞️' },
      { name: '北京 - 天安门', lat: 39.9042, lon: 116.4074, icon: '🏛️' },
      { name: '上海 - 东方明珠', lat: 31.2397, lon: 121.4997, icon: '🗼' },
      { name: '深圳 - 深圳湾', lat: 22.5431, lon: 113.9547, icon: '🌊' },
      { name: '成都 - 锦里', lat: 30.6517, lon: 104.0468, icon: '🏮' },
      { name: '广州 - 小蛮腰', lat: 23.1291, lon: 113.2644, icon: '🏗️' },
      { name: '西安 - 兵马俑', lat: 34.3416, lon: 109.2778, icon: '🏛️' },
      { name: '南京 - 夫子庙', lat: 32.0603, lon: 118.7969, icon: '🏯' },
    ];

    const cityIndex = this.dynamicMapsCount % cities.length;
    const city = cities[cityIndex];
    
    const newId = this.dynamicMapsCount + 1;
    const newConfig: MapInstanceConfig = {
      id: newId,
      name: city.name,
      latitude: city.lat,
      longitude: city.lon,
      zoom: 10,
      icon: city.icon,
      mapView: null
    };
    
    this.dynamicMapConfigs.push(newConfig);
    this.dynamicMapsCount++;
    
    hilog.info(DOMAIN, TAG, `添加动态地图 #${newId}: ${city.name}`);
    
    promptAction.showToast({
      message: `添加地图 #${newId}: ${city.name}`,
      duration: 1500
    });
  }

  /**
   * 移除最后一个动态地图
   */
  private removeDynamicMap(): void {
    if (this.dynamicMapConfigs.length === 0) {
      return;
    }
    
    const removedConfig = this.dynamicMapConfigs.pop();
    if (removedConfig) {
      this.dynamicMapsCount--;
      if (removedConfig.mapView !== null) {
        this.mapInstancesReady--;
      }
      
      hilog.info(DOMAIN, TAG, `移除动态地图 #${removedConfig.id}: ${removedConfig.name}`);
      
      promptAction.showToast({
        message: `移除地图 #${removedConfig.id}`,
        duration: 1500
      });
    }
  }

  /**
   * 清空所有动态地图
   */
  private clearAllDynamicMaps(): void {
    const count = this.dynamicMapConfigs.length;
    this.dynamicMapConfigs = [];
    this.dynamicMapsCount = 0;
    this.mapInstancesReady = 0;
    
    hilog.info(DOMAIN, TAG, `清空所有动态地图 (${count} 个)`);
    
    promptAction.showToast({
      message: `已清空 ${count} 个地图`,
      duration: 1500
    });
  }
}

