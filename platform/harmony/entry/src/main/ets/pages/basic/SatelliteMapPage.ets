import { LatLng, RasterSource, MapView, MapLibreMap, MapLibreMapOptions, Marker, Icon, NativeMapView} from 'maplibre_harmony';
import { TestPageLayout } from '../common/TestPageLayout';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';

/**
 * 卫星地图测试页面
 * 
 * 功能说明：
 * - 展示全球卫星影像地图
 * - 使用 RasterSource 加载卫星瓦片
 * - 支持全球卫星影像浏览
 * - 随机位置跳转测试
 * 
 * 数据源：
 * - URL: https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}
 * - 类型: RasterSource
 * - 提供商: Esri World Imagery
 */

const TAG = 'SatelliteMapPage';

/**
 * 有趣的卫星影像位置
 */
interface SatelliteLocation {
  name: string;
  description: string;
  longitude: number;
  latitude: number;
  zoom: number;
}

@Entry
@Component
struct SatelliteMapPage {
  @State statusMessage: string = '等待地图加载...';
  @State mapReady: boolean = false;
  @State currentLocation: string = '北京';
  @State locationDescription: string = '';
  
  private mapView: NativeMapView | null = null;
  private map: MapLibreMap | null = null;
  
  // 预设的有趣卫星影像位置
  private locations: SatelliteLocation[] = [
    { 
      name: '长城', 
      description: '中国万里长城',
      longitude: 116.5704, 
      latitude: 40.4319, 
      zoom: 15 
    },
    { 
      name: '金字塔', 
      description: '埃及吉萨金字塔',
      longitude: 31.1342, 
      latitude: 29.9792, 
      zoom: 16 
    },
    { 
      name: '大峡谷', 
      description: '美国科罗拉多大峡谷',
      longitude: -112.1129, 
      latitude: 36.0544, 
      zoom: 13 
    },
    { 
      name: '亚马逊雨林', 
      description: '南美亚马逊热带雨林',
      longitude: -60.0217, 
      latitude: -3.4653, 
      zoom: 12 
    },
    { 
      name: '珠穆朗玛峰', 
      description: '世界最高峰',
      longitude: 86.9250, 
      latitude: 27.9881, 
      zoom: 13 
    },
    { 
      name: '悉尼歌剧院', 
      description: '澳大利亚地标建筑',
      longitude: 151.2153, 
      latitude: -33.8568, 
      zoom: 17 
    },
    { 
      name: '迪拜棕榈岛', 
      description: '人工岛屿奇迹',
      longitude: 55.1376, 
      latitude: 25.1124, 
      zoom: 14 
    },
    { 
      name: '撒哈拉沙漠', 
      description: '世界最大的沙漠',
      longitude: 2.5, 
      latitude: 25.0, 
      zoom: 8 
    },
    { 
      name: '大堡礁', 
      description: '世界最大的珊瑚礁系统',
      longitude: 147.7, 
      latitude: -18.3, 
      zoom: 11 
    },
    { 
      name: '冰岛火山', 
      description: '冰与火的国度',
      longitude: -18.0, 
      latitude: 64.9, 
      zoom: 10 
    },
    { 
      name: '威尼斯', 
      description: '水城威尼斯',
      longitude: 12.3155, 
      latitude: 45.4408, 
      zoom: 14 
    },
    { 
      name: '纳斯卡线条', 
      description: '秘鲁神秘地画',
      longitude: -75.1, 
      latitude: -14.7, 
      zoom: 13 
    }
  ]

  /**
   * 地图区域构建器
   */
  @Builder
  buildMapContent() {
    Stack() {
      MapView({
        // 使用空样式，稍后添加卫星图层
        styleUrl: 'https://demotiles.maplibre.org/style.json',
        initialLatitude: 39.9,
        initialLongitude: 116.4,
        initialZoom: 5,
        initialBearing: 0,
        initialPitch: 0,
        onMapReady: (map: MapLibreMap) => {
          this.onMapReady(map);
        }
      })
      .width('100%')
      .height('100%')
      
      // 加载指示器
      if (!this.mapReady) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
            .color('#2196F3')
          
          Text('加载卫星影像...')
            .fontSize(16)
            .margin({ top: 10 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('rgba(255, 255, 255, 0.8)')
      }
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 控制区域构建器
   */
  @Builder
  buildControlPanel() {
    Scroll() {
      Column({ space: 12 }) {
        // 状态信息
        Text(this.statusMessage)
          .fontSize(14)
          .width('100%')
          .backgroundColor('#F8F8F8')
          .borderRadius(4)
        
        Text(`当前位置: ${this.currentLocation}`)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        if (this.locationDescription) {
          Text(this.locationDescription)
            .fontSize(12)
            .width('100%')
            .fontStyle(FontStyle.Italic)
        }
        
        // 功能说明
        Text('功能说明')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        
        Text('• 使用 Esri 世界卫星影像')
          .fontSize(13)
          .width('100%')
        
        Text('• 高清晰度卫星图片')
          .fontSize(13)
          .width('100%')
        
        Text('• 探索世界著名地标')
          .fontSize(13)
          .width('100%')
        
        Divider()
          .margin({ top: 8, bottom: 8 })
        
        // 位置跳转按钮
        Text('探索世界')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        // 位置列表
        ForEach(this.locations, (location: SatelliteLocation) => {
          Column() {
            Button() {
              Column() {
                Text(location.name)
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                
                Text(location.description)
                  .fontSize(11)
                  .fontColor('#E0E0E0')
                  .margin({ top: 2 })
              }
              .width('100%')
              .padding(8)
            }
            .width('100%')
            .onClick(() => {
              this.jumpToLocation(location);
            })
            .enabled(this.mapReady)
            .backgroundColor(this.currentLocation === location.name ? '#4CAF50' : '#2196F3')
          }
          .width('100%')
        
        Divider()
          .margin({ top: 8, bottom: 8 })
        
        Button('随机地点')
          .width('100%')
          .onClick(() => {
            this.jumpToRandomLocation();
          })
          .enabled(this.mapReady)
        
        Button('重新加载卫星图层')
          .width('100%')
          .onClick(() => {
            this.reloadSatelliteLayer();
          })
          .enabled(this.mapReady)
      }
      .padding(16)
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }

  build() {
    Column() {
      TestPageLayout({
        showActionBar: true,
        title: '卫星影像地图',
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      })
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 地图就绪回调
   */
  private onMapReady(map?: MapLibreMap): void {
    if (this.mapView) {
      this.mapView = this.mapView;
      
      // 创建 MapLibreMap 实例
      const options = new MapLibreMapOptions();
      this.map = new MapLibreMap(this.mapView, options);
      
      // 等待样式加载完成后添加卫星图层
      setTimeout(() => {
        this.addSatelliteLayer();
      }, 1000);
      
      this.mapReady = true;
      this.currentLocation = '长城';
      this.locationDescription = '中国万里长城';
      this.statusMessage = '✅ 地图已加载，开始探索世界吧！';
      
      hilog.info(DOMAIN, TAG, 'Map ready');
    }
  }

  /**
   * 添加卫星图层
   */
  private addSatelliteLayer(): void {
    if (!this.map) return;
    
    try {
      const style = this.map.getStyle();
      if (!style) {
        hilog.error(DOMAIN, TAG, 'Style not available');
        return;
      }
      
      // 移除旧的数据源（如果存在）
      try {
        style.removeSource('satellite-source');
      } catch (e) {
        // 忽略不存在的情况
      }
      
      // 创建卫星影像数据源
      const source: RasterSource = new RasterSource('satellite-source');
      // 使用 Esri World Imagery 服务
      source.setUrl('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}');
      source.setTileSize(256);
      
      // 添加数据源
      style.addSource(source.getNative());
      
      hilog.info(DOMAIN, TAG, 'Satellite layer added successfully');
      hilog.info(DOMAIN, TAG, `  Source ID: ${source.getId()}`);
      hilog.info(DOMAIN, TAG, `  Source URL: ${source.getUrl()}`);
      // Note: getTileSize() is not available, tile size is set during creation
      
      this.statusMessage = '✅ 卫星影像图层已加载';
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed to add satellite layer: ${errorMsg}`);
      this.statusMessage = `❌ 加载失败: ${errorMsg}`;
    }
  }

  /**
   * 跳转到指定位置
   */
  private jumpToLocation(location: SatelliteLocation): void {
    if (!this.map) return;
    
    try {
      const options = {
        center: LatLng.create(location.latitude, location.longitude),
        zoom: location.zoom,
        bearing: 0,
        pitch: 0
      };
      
      this.map.flyTo(options, 2000);
      this.currentLocation = location.name;
      this.locationDescription = location.description;
      this.statusMessage = `🛰️ 正在飞往 ${location.name}...`;
      
      hilog.info(DOMAIN, TAG, `Flying to ${location.name} (${location.latitude}, ${location.longitude})`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed to jump to location: ${errorMsg}`);
      this.statusMessage = `❌ 跳转失败: ${errorMsg}`;
    }
  }

  /**
   * 跳转到随机位置
   */
  private jumpToRandomLocation(): void {
    const randomIndex = Math.floor(Math.random() * this.locations.length);
    const location = this.locations[randomIndex]
    this.jumpToLocation(location);
  }

  /**
   * 重新加载卫星图层
   */
  private reloadSatelliteLayer(): void {
    this.statusMessage = '🔄 重新加载卫星图层...';
    this.addSatelliteLayer();
  }
}

