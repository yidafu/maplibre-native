/**
 * OSM 栅格瓦片地图测试页面
 * 
 * 功能说明：
 * - 展示 OpenStreetMap 栅格瓦片地图
 * - 使用 RasterSource 加载 OSM 瓦片
 * - 支持全球地图浏览
 * - 随机位置跳转测试
 * 
 * 数据源：
 * - URL: https://tile.openstreetmap.org/{z}/{x}/{y}.png
 * - 类型: RasterSource
 */

import { TestPageLayout } from '../components/TestPageLayout';
import { maplibre } from 'maplibre_harmony';
import { NativeMapView } from 'maplibre_harmony/src/main/ets/maps/NativeMapView';
import { MapLibreMap } from 'maplibre_harmony/src/main/ets/maps/MapLibreMap';
import { MapLibreMapOptions } from 'maplibre_harmony/src/main/ets/maps/MapLibreMapOptions';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../constants/HiLogConstants';

const TAG = 'OSMRasterMapPage';

/**
 * 随机位置接口
 */
interface RandomLocation {
  name: string;
  longitude: number;
  latitude: number;
  zoom: number;
}

@Entry
@Component
struct OSMRasterMapPage {
  @State statusMessage: string = '等待地图加载...';
  @State mapReady: boolean = false;
  @State currentLocation: string = '北京';
  
  private mapView: maplibre.NativeMapView | null = null;
  private map: MapLibreMap | null = null;
  
  // 预设的有趣位置
  private locations: RandomLocation[] = [
    { name: '北京', longitude: 116.4074, latitude: 39.9042, zoom: 12 },
    { name: '上海', longitude: 121.4737, latitude: 31.2304, zoom: 12 },
    { name: '纽约', longitude: -74.0060, latitude: 40.7128, zoom: 12 },
    { name: '伦敦', longitude: -0.1278, latitude: 51.5074, zoom: 12 },
    { name: '巴黎', longitude: 2.3522, latitude: 48.8566, zoom: 12 },
    { name: '东京', longitude: 139.6917, latitude: 35.6895, zoom: 12 },
    { name: '悉尼', longitude: 151.2093, latitude: -33.8688, zoom: 12 },
    { name: '开罗', longitude: 31.2357, latitude: 30.0444, zoom: 12 },
    { name: '里约热内卢', longitude: -43.1729, latitude: -22.9068, zoom: 12 },
    { name: '莫斯科', longitude: 37.6173, latitude: 55.7558, zoom: 12 }
  ];

  /**
   * 地图区域构建器
   */
  @Builder
  MapAreaBuilder() {
    Stack() {
      NativeMapView({
        // 使用空样式，稍后添加 OSM 栅格图层
        styleUrl: 'https://demotiles.maplibre.org/style.json',
        initialLatitude: 39.9042,
        initialLongitude: 116.4074,
        initialZoom: 10,
        initialBearing: 0,
        initialPitch: 0,
        onMapReady: (mapView?: maplibre.NativeMapView) => {
          this.onMapReady(mapView);
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
          
          Text('加载 OSM 栅格地图...')
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
  ControlAreaBuilder() {
    Column({ space: 12 }) {
      // 状态信息
      Text(this.statusMessage)
        .fontSize(14)
        .width('100%')
        .padding(12)
        .backgroundColor('#F8F8F8')
        .borderRadius(4)
      
      Text(`当前位置: ${this.currentLocation}`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('100%')
      
      // 功能说明
      Text('功能说明')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8 })
      
      Text('• 使用 OpenStreetMap 栅格瓦片')
        .fontSize(13)
        .width('100%')
        .fontColor('#666666')
      
      Text('• 支持全球地图浏览')
        .fontSize(13)
        .width('100%')
        .fontColor('#666666')
      
      Text('• 点击按钮跳转到世界各地')
        .fontSize(13)
        .width('100%')
        .fontColor('#666666')
      
      Divider()
        .margin({ top: 8, bottom: 8 })
      
      // 位置跳转按钮
      Text('快速跳转')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
      
      // 使用网格布局显示位置按钮
      Grid() {
        ForEach(this.locations, (location: RandomLocation) => {
          GridItem() {
            Button(location.name)
              .fontSize(12)
              .width('100%')
              .height(40)
              .onClick(() => {
                this.jumpToLocation(location);
              })
              .enabled(this.mapReady)
              .backgroundColor(this.currentLocation === location.name ? '#4CAF50' : '#2196F3')
          }
        })
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(8)
      .columnsGap(8)
      .width('100%')
      
      Divider()
        .margin({ top: 8, bottom: 8 })
      
      Button('随机位置')
        .width('100%')
        .backgroundColor('#FF9800')
        .onClick(() => {
          this.jumpToRandomLocation();
        })
        .enabled(this.mapReady)
      
      Button('重新加载 OSM 图层')
        .width('100%')
        .backgroundColor('#9C27B0')
        .onClick(() => {
          this.reloadOSMLayer();
        })
        .enabled(this.mapReady)
    }
    .padding(16)
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
        title: 'OSM 栅格瓦片地图',
        mapArea: (): void => this.MapAreaBuilder(),
        controlArea: (): void => this.ControlAreaBuilder()
      })
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 地图就绪回调
   */
  private onMapReady(mapView?: maplibre.NativeMapView): void {
    if (mapView) {
      this.mapView = mapView;
      
      // 创建 MapLibreMap 实例
      const options = new MapLibreMapOptions();
      this.map = new MapLibreMap(mapView, options);
      
      // 等待样式加载完成后添加 OSM 栅格图层
      setTimeout(() => {
        this.addOSMRasterLayer();
      }, 1000);
      
      this.mapReady = true;
      this.statusMessage = '✅ 地图已加载，可以开始浏览';
      
      hilog.info(DOMAIN, TAG, 'Map ready');
    }
  }

  /**
   * 添加 OSM 栅格图层
   */
  private addOSMRasterLayer(): void {
    if (!this.map) return;
    
    try {
      const style = this.map.getStyle();
      if (!style) {
        hilog.error(DOMAIN, TAG, 'Style not available');
        return;
      }
      
      // 移除旧的数据源（如果存在）
      try {
        style.removeSource('osm-raster-source');
      } catch (e) {
        // 忽略不存在的情况
      }
      
      // 创建 OSM 栅格数据源
      const source: maplibre.RasterSource = new maplibre.RasterSource('osm-raster-source');
      source.setUrl('https://tile.openstreetmap.org/{z}/{x}/{y}.png');
      source.setTileSize(256);
      
      // 添加数据源
      style.addSource(source);
      
      hilog.info(DOMAIN, TAG, 'OSM Raster layer added successfully');
      hilog.info(DOMAIN, TAG, `  Source ID: ${source.getId()}`);
      hilog.info(DOMAIN, TAG, `  Source URL: ${source.getUrl()}`);
      // Note: getTileSize() is not available, tile size is set during creation
      
      this.statusMessage = '✅ OSM 栅格图层已加载';
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed to add OSM raster layer: ${errorMsg}`);
      this.statusMessage = `❌ 加载失败: ${errorMsg}`;
    }
  }

  /**
   * 跳转到指定位置
   */
  private jumpToLocation(location: RandomLocation): void {
    if (!this.map) return;
    
    try {
      const options: maplibre.CameraOptions = {
        center: new maplibre.LatLng(location.latitude, location.longitude),
        zoom: location.zoom,
        bearing: 0,
        pitch: 0
      };
      
      this.map.flyTo(options, 2000);
      this.currentLocation = location.name;
      this.statusMessage = `✈️ 正在飞往 ${location.name}...`;
      
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
    const location = this.locations[randomIndex];
    this.jumpToLocation(location);
  }

  /**
   * 重新加载 OSM 图层
   */
  private reloadOSMLayer(): void {
    this.statusMessage = '🔄 重新加载 OSM 图层...';
    this.addOSMRasterLayer();
  }
}

