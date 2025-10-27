import { NativeMapView } from '../maps/NativeMapView';
import { MapLibreMap } from '../maps/MapLibreMap';
import { MapLibreMapOptions } from '../maps/MapLibreMapOptions';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import maplibre from 'libmaplibre_native.so';
import { DOMAIN } from '../constants/HiLogConstants';
const TAG = 'StyleUrlTestPage';

/**
 * Style URL 测试页面
 * 
 * 测试功能：
 * 1. 切换不同的地图样式 URL
 * 2. 查看样式信息（URI、JSON）
 * 3. 样式加载状态监控
 * 
 * 使用新的 NAPI API：
 * - const style = mapLibreMap.getStyle()
 * - style.getUri()
 * - style.getJson()
 * - style.isFullyLoaded()
 */

// 样式URL配置接口
interface StyleUrlItem {
  name: string;
  url: string;
  description: string;
}

@Entry
@Component
struct StyleUrlTestPage {
  @State message: string = 'Style URL 切换测试';
  private nativeMapView: maplibre.NativeMapView | null = null;
  private mapLibreMap: MapLibreMap | null = null;
  @State currentStyleName: string = 'MapLibre Demo';
  @State currentStyleUrl: string = '';
  @State styleJsonLength: number = 0;
  @State mapReady: boolean = false;
  @State isInitializing: boolean = false;
  
  // 免费样式列表
  private styleUrls: StyleUrlItem[] = [
    {
      name: 'MapLibre Demo',
      url: 'https://demotiles.maplibre.org/style.json',
      description: 'MapLibre 官方演示样式'
    },
    {
      name: 'Americana',
      url: 'https://americanamap.org/style.json',
      description: '美式地图风格'
    },
    {
      name: 'VersaTiles Colorful',
      url: 'https://tiles.versatiles.org/assets/styles/colorful.json',
      description: '多彩样式'
    },
    {
      name: 'VersaTiles Grayscale',
      url: 'https://tiles.versatiles.org/assets/styles/grayscale.json',
      description: '灰度样式'
    },
    {
      name: 'OSM Bright',
      url: 'https://tiles.versatiles.org/assets/styles/osm-bright.json',
      description: 'OSM 明亮样式'
    }
  ];

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

        Text(this.message)
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
          styleUrl: this.styleUrls[0].url,
          initialLatitude: 20.0,
          initialLongitude: 0.0,
          initialZoom: 1.5,
          initialBearing: 0,
          initialPitch: 0,
          onMapReady: (mapView?: maplibre.NativeMapView) => {
            this.initializeMap(mapView);
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
            
            Text('地图加载中...')
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
      .height('60%')

      // 测试按钮区域（40%，可滚动）
      Scroll() {
        Column({ space: 8 }) {
          // 样式信息显示
          Column() {
            Text(`当前样式: ${this.currentStyleName}`)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .width('100%')
            
            Text(`URL: ${this.currentStyleUrl}`)
              .fontSize(12)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
              .margin({ top: 4 })
            
            Text(`Style JSON 大小: ${this.styleJsonLength} 字符`)
              .fontSize(12)
              .width('100%')
              .margin({ top: 4 })
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#F8F8F8')
          .margin({ bottom: 8 })
          Text('选择地图样式')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .padding({ left: 16, top: 8 })

          ForEach(this.styleUrls, (item: StyleUrlItem) => {
            Column() {
              Button(item.name)
                .onClick(() => this.switchStyle(item))
                .width('100%')
                .backgroundColor(this.currentStyleName === item.name ? '#4CAF50' : '#2196F3')
              
              Text(item.description)
                .fontSize(12)
                .fontColor('#666')
                .width('100%')
                .textAlign(TextAlign.Center)
                .margin({ top: 4 })
            }
            .width('90%')
          })

          Divider().strokeWidth(2).margin({ top: 8, bottom: 8 })

          Button('获取当前样式信息')
            .onClick(() => this.getStyleInfo())
            .width('90%')
            .backgroundColor('#FF9800')
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 12 })
      }
      .width('100%')
      .height('40%')
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 初始化地图
   */
  private initializeMap(mapView?: maplibre.NativeMapView) {
    if (this.isInitializing) {
      hilog.warn(DOMAIN, TAG, 'Map is already initializing');
      return;
    }
    
    if (!mapView) {
      hilog.error(DOMAIN, TAG, 'onMapReady: mapView is null');
      this.message = '❌ 地图初始化失败';
      return;
    }
    
    this.isInitializing = true;
    
    try {
      this.nativeMapView = mapView;
      const options = new MapLibreMapOptions();
      this.mapLibreMap = new MapLibreMap(mapView, options);
      
      this.mapReady = true;
      this.message = '✅ 地图已就绪';
      
      // 获取初始样式信息
      this.getStyleInfo();
      
      hilog.info(DOMAIN, TAG, 'Map initialized successfully');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed to initialize map: ${errorMsg}`);
      this.message = `❌ 初始化失败: ${errorMsg}`;
      this.mapReady = false;
    } finally {
      this.isInitializing = false;
    }
  }

  /**
   * 切换地图样式
   */
  private switchStyle(item: StyleUrlItem) {
    if (!this.mapLibreMap) {
      hilog.error(DOMAIN, TAG, 'Map not initialized');
      return;
    }

    try {
      hilog.info(DOMAIN, TAG, `Switching to style: ${item.name}`);
      
      // 切换样式
      this.mapLibreMap.setStyleUrl(item.url);
      
      // 更新状态
      this.currentStyleName = item.name;
      this.currentStyleUrl = item.url;
      this.message = `已切换到: ${item.name}`;
      
      // 延迟获取样式信息（等待样式加载）
      setTimeout(() => {
        this.getStyleInfo();
      }, 2000);
      
      hilog.info(DOMAIN, TAG, `Style switched to: ${item.name}`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed to switch style: ${errorMsg}`);
      this.message = `切换样式失败: ${errorMsg}`;
    }
  }

  /**
   * 获取样式信息
   */
  private getStyleInfo() {
    if (!this.mapLibreMap) return;
    
    try {
      const style = this.mapLibreMap.getStyle();
      if (!style) {
        hilog.warn(DOMAIN, TAG, 'Style not available');
        return;
      }
      
      // 使用新的 NAPI API
      const uri = style.getUri();
      const json = style.getJson();
      const loaded = style.isFullyLoaded();
      
      this.currentStyleUrl = uri;
      this.styleJsonLength = json.length;
      
      hilog.info(DOMAIN, TAG, `Style Info:`);
      hilog.info(DOMAIN, TAG, `  URI: ${uri}`);
      hilog.info(DOMAIN, TAG, `  JSON Length: ${json.length}`);
      hilog.info(DOMAIN, TAG, `  Fully Loaded: ${loaded}`);
      
      this.message = `✅ 样式信息已更新 (${loaded ? '已加载' : '加载中'})`;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed to get style info: ${errorMsg}`);
    }
  }
}

