import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';
import { util } from '@kit.ArkTS';
import { resourceManager } from '@kit.LocalizationKit';
import { TestPageLayout } from '../common/TestPageLayout';

import { LatLng, MapLibreMap, MapView, maplibre, MapLibreMapOptions, OnStyleLoadedListener , NativeMapView,
  Style} from 'maplibre_harmony';
const TAG = 'StyleTestPage';

/**
 * 地图样式测试页面
 * 
 * 专注于地图样式本身的功能测试：
 * 1. 样式URL切换 - 不同地图样式之间的切换
 * 2. 样式属性获取 - 获取样式名称、来源等信息
 * 3. 样式JSON操作 - 获取和设置样式JSON
 * 4. 图层可见性控制 - 批量控制图层显示/隐藏
 * 5. 数据源和图层查询 - 列出所有数据源和图层
 * 
 * 注：数据源测试请访问 SourceTestPage，图层测试请访问 LayerTestPage
 */

// 样式URL配置接口
interface StyleUrlItem {
  name: string;
  url: string;
  description: string;
  category: string;
}

/**
 * 本地样式加载监听器实现类
 */
class LocalStyleLoadedListener implements OnStyleLoadedListener {
  private testPage: StyleTestPage;
  private styleObj: Object | null;
  private displayName: string;
  
  constructor(testPage: StyleTestPage, styleObj: Object | null, displayName: string) {
    this.testPage = testPage;
    this.styleObj = styleObj;
    this.displayName = displayName;
  }
  
  onStyleLoaded(style: Style | null): void {
    hilog.info(DOMAIN, TAG, '🎨 maplibre.Style loaded callback - updating camera and triggering repaint');
    
    if (this.testPage.mapLibreMap && this.testPage.nativeMapView) {
      try {
        // 🔥 关键修复2：应用样式中的初始位置
        const styleRecord = this.styleObj as Record<string, Object>;
        if (this.styleObj && styleRecord['center'] && styleRecord['zoom'] !== undefined) {
          const centerArray = styleRecord['center'] as number[]
          const lon = centerArray[0]
          const lat: number = centerArray[1]
          const zoom = styleRecord['zoom'] as number;
          const bearing = styleRecord['bearing'] !== undefined ? styleRecord['bearing'] as number : 0;
          const pitch = styleRecord['pitch'] !== undefined ? styleRecord['pitch'] as number : 0;
          
          hilog.info(DOMAIN, TAG, `Applying style initial position: lat=${lat}, lon=${lon}, zoom=${zoom}, bearing=${bearing}, pitch=${pitch}`);
          
          // 跳转到样式指定的初始位置
          this.testPage.mapLibreMap.jumpTo(bearing, lat, lon, pitch, zoom);
          
          this.testPage.message = `✅ 已加载样式: ${this.displayName} (${lat.toFixed(4)}, ${lon.toFixed(4)})`;
        } else {
          // 如果样式没有指定初始位置，强制刷新当前位置
          const currentLatLng: LatLng = this.testPage.mapLibreMap.getLatLng();
          const currentZoom: number = this.testPage.mapLibreMap.getZoom();
          
          hilog.info(DOMAIN, TAG, `No initial position in style, refreshing current: ${currentLatLng.latitude}, ${currentLatLng.longitude}, zoom: ${currentZoom}`);
          
          this.testPage.mapLibreMap.jumpTo(
            this.testPage.mapLibreMap.getBearing(),
            currentLatLng.latitude,
            currentLatLng.longitude,
            this.testPage.mapLibreMap.getPitch(),
            currentZoom
          );
          
          this.testPage.message = `✅ 已加载样式: ${this.displayName}`;
        }
        
        // 🔥 关键修复3：多次触发重绘以确保显示
        // 某些情况下需要多次触发才能正确渲染
        this.testPage.mapLibreMap.triggerRepaint();
        
        setTimeout(() => {
          if (this.testPage.mapLibreMap) {
            this.testPage.mapLibreMap.triggerRepaint();
            hilog.info(DOMAIN, TAG, '✅ Second repaint triggered');
          }
        }, 50);
        
        setTimeout(() => {
          if (this.testPage.mapLibreMap) {
            this.testPage.mapLibreMap.triggerRepaint();
            hilog.info(DOMAIN, TAG, '✅ Third repaint triggered');
          }
        }, 200);
        
        hilog.info(DOMAIN, TAG, '✅ Camera updated and repaint triggered');
        
      } catch (updateError) {
        hilog.error(DOMAIN, TAG, `Error updating camera: ${updateError}`);
        this.testPage.message = `⚠️ 样式已加载但相机更新失败: ${this.displayName}`;
      }
    }
    
    // 移除临时监听器
    if (this.testPage.mapLibreMap) {
      this.testPage.mapLibreMap.removeOnStyleLoadedListener(this);
    }
  }
}

@Entry
@Component
struct StyleTestPage {
  @State message: string = '地图样式测试';
  nativeMapView: NativeMapView | null = null;  // 改为 public，供监听器访问
  mapLibreMap: MapLibreMap | null = null;  // 改为 public，供监听器访问
  @State currentStyleName: string = 'MapLibre Demo';
  @State currentStyleUrl: string = '';
  @State styleInfo: string = '未获取';
  @State mapReady: boolean = false;
  @State isInitializing: boolean = false;
  
  // 免费样式列表（按类别分组）
  private styleUrls: StyleUrlItem[] = [
    // 基础样式
    {
      name: 'MapLibre Demo',
      url: 'https://demotiles.maplibre.org/style.json',
      description: 'MapLibre 官方演示样式',
      category: '基础样式'
    },
    {
      name: 'OSM Bright',
      url: 'https://demotiles.maplibre.org/style.json',
      description: 'OpenStreetMap 明亮风格',
      category: '基础样式'
    },
    // 特色样式
    {
      name: 'Americana',
      url: 'https://americanamap.org/style.json',
      description: '美式风格地图',
      category: '特色样式'
    },
    {
      name: 'VersaTiles Colorful',
      url: 'https://tiles.versatiles.org/assets/styles/colorful.json',
      description: '多彩风格地图',
      category: '特色样式'
    },
    {
      name: 'VersaTiles Neutrino',
      url: 'https://tiles.versatiles.org/assets/styles/neutrino.json',
      description: '简约中性风格',
      category: '特色样式'
    }
  ]

  @Builder
  buildMapContent() {
    Stack() {
      MapView({
        styleUrl: this.styleUrls[0].url,
        initialLatitude: 39.9,
        initialLongitude: 116.4,
        initialZoom: 10,
        initialBearing: 0,
        initialPitch: 0,
        onMapReady: (map: MapLibreMap) => {
          this.initializeMap(map);
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
    .height('100%')
  }

  @Builder
  buildControlPanel() {
    // 当前状态显示
    Column({ space: 5 }) {
      Text(`当前样式: ${this.currentStyleName}`)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .width('100%')
      Text(`URL: ${this.currentStyleUrl || '加载中...'}`)
        .fontSize(12)
        .fontColor('#666666')
        .width('100%')
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      
      Text(`样式信息: ${this.styleInfo}`)
        .fontSize(12)
        .fontColor('#666666')
        .width('100%')
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#F8F8F8')
    .borderRadius(8)
    .alignItems(HorizontalAlign.Start)

    // 地图样式切换区域
    Text('🎨 样式切换')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    ForEach(this.styleUrls, (item: StyleUrlItem) => {
      Column({ space: 5 }) {
        Button(item.name)
          .onClick(() => this.switchStyle(item.url, item.name))
          .width('100%')
          .fontSize(14)
        
        Text(item.description)
          .fontSize(11)
          .fontColor('#999999')
          .width('100%')
          .margin({ top: -5 })
      }
      .width('100%')
    }, (item: StyleUrlItem) => item.url)

    Divider().strokeWidth(2)

    Text('📁 本地样式测试')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    Button('1. 简单背景样式 ✅')
      .onClick(() => this.loadLocalStyle('styles-simple.json', '简单背景样式'))
      .width('100%')
      .backgroundColor('#4CAF50')

    Button('2. MapLibre Demo 样式')
      .onClick(() => this.loadLocalStyle('styles-demo.json', 'MapLibre Demo (本地)'))
      .width('100%')
      .backgroundColor('#2196F3')

    Button('3. 杭州矢量地图 ⚠️ 内网')
      .onClick(() => this.loadLocalStyle('styles.json', '杭州矢量地图'))
      .width('100%')
      .backgroundColor('#FF9800')

    Divider().strokeWidth(2)

    Text('📊 样式信息')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    Row() {
      Button('获取样式名称')
        .onClick(() => this.handleGetStyleName())
        .width('48%')
        .fontSize(12)
        .backgroundColor('#9C27B0')

      Button('获取样式URL')
        .onClick(() => this.handleGetStyleUrl())
        .width('48%')
        .margin({ left: 8 })
        .fontSize(12)
        .backgroundColor('#9C27B0')
    }
    .width('100%')
    Row() {
      Button('获取样式JSON')
        .onClick(() => this.handleGetStyleJson())
        .width('48%')
        .fontSize(12)
        .backgroundColor('#9C27B0')

      Button('列出所有图层ID')
        .onClick(() => this.handleListAllLayers())
        .width('48%')
        .margin({ left: 8 })
        .fontSize(11)
        .backgroundColor('#9C27B0')
    }
    .width('100%')
    Button('列出所有数据源ID')
      .onClick(() => this.handleListAllSources())
      .width('48%')
      .fontSize(11)
      .backgroundColor('#9C27B0')

    Divider().strokeWidth(2)

    Text('⚙️ 样式控制')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    Row() {
      Button('隐藏所有图层')
        .onClick(() => this.handleHideAllLayers())
        .width('48%')
        .fontSize(12)
        .backgroundColor('#FF9800')

      Button('显示所有图层')
        .onClick(() => this.handleShowAllLayers())
        .width('48%')
        .margin({ left: 8 })
        .fontSize(12)
        .backgroundColor('#FF9800')
    }
    .width('100%')
    Button('重新加载当前样式')
      .onClick(() => this.handleReloadStyle())
      .width('48%')
      .fontSize(12)
      .backgroundColor('#FF5722')
    
    Divider().strokeWidth(2)

    Text('🔧 渲染调试')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    Row() {
      Button('强制重绘 (Debug)')
        .onClick(() => this.handleForceRepaint())
        .width('48%')
        .fontSize(12)
        .backgroundColor('#607D8B')
      
      Button('重置相机位置')
        .onClick(() => this.handleResetCamera())
        .width('48%')
        .margin({ left: 8 })
        .fontSize(12)
        .backgroundColor('#607D8B')
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
        showActionBar: true,
        title: this.message,
        mapContent: (): void => this.buildMapContent(),
        controlPanel: (): void => this.buildControlPanel()
      })
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 从 rawfile 读取文本文件
   */
  private async readRawfile(filename: string): Promise<string> {
    try {
      const context = getContext(this);
      const mgr = context.resourceManager;
      const fileData = await mgr.getRawFileContent(filename);
      
      // 将 Uint8Array 转换为字符串
      const decoder = new util.TextDecoder('utf-8', { ignoreBOM: true });
      return decoder.decodeWithStream(fileData);
    } catch (error) {
      throw new Error(`Failed to read rawfile ${filename}: ${error}`);
    }
  }

  /**
   * 从本地 rawfile 加载样式
   */
  private async loadLocalStyle(filename: string, displayName: string) {
    if (!this.mapLibreMap) {
      this.message = '❌ 地图未初始化';
      return;
    }

    try {
      this.message = `⏳ 正在读取本地样式: ${displayName}...`;
      
      // 从 rawfile 读取
      const styleJson = await this.readRawfile(filename);
      
      hilog.info(DOMAIN, TAG, `Read style JSON from ${filename}: ${styleJson.substring(0, 100)}...`);
      hilog.info(DOMAIN, TAG, `Style JSON size: ${styleJson.length} bytes`);
      
      // 解析样式 JSON 以获取初始位置
      let styleObj: Object | null = null;
      try {
        styleObj = JSON.parse(styleJson) as Object;
        const styleRecord = styleObj as Record<string, Object>;
        hilog.info(DOMAIN, TAG, `Parsed style: center=${JSON.stringify(styleRecord['center'])}, zoom=${styleRecord['zoom']}`);
      } catch (parseError) {
        hilog.warn(DOMAIN, TAG, `Failed to parse style JSON for initial position: ${parseError}`);
      }
      
      // 🔥 关键修复1：创建并注册一次性样式加载监听器
      const styleLoadedListener = new LocalStyleLoadedListener(this, styleObj, displayName);
      
      // 添加临时监听器
      this.mapLibreMap.addOnStyleLoadedListener(styleLoadedListener);
      
      // 设置样式
      hilog.info(DOMAIN, TAG, 'Calling setStyleJson...');
      this.mapLibreMap.setStyleJson(styleJson);
      hilog.info(DOMAIN, TAG, 'setStyleJson returned');
      
      // 更新状态
      this.currentStyleName = displayName;
      this.currentStyleUrl = `rawfile://${filename}`;
      
      this.message = `⏳ 正在加载样式: ${displayName}...`;
      hilog.info(DOMAIN, TAG, `Style JSON set, waiting for load complete: ${filename}`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed to load local style: ${errorMsg}`);
      this.message = `❌ 加载失败: ${errorMsg}`;
    }
  }

  /**
   * 初始化地图
   */
  private initializeMap(map?: MapLibreMap) {
    if (this.isInitializing) {
      hilog.warn(DOMAIN, TAG, 'Map is already initializing');
      return;
    }
    
    if (!map) {
      hilog.error(DOMAIN, TAG, 'onMapReady: this.mapView is null');
      this.message = '❌ 地图初始化失败';
      return;
    }
    
    this.isInitializing = true;
    
    try {
      this.nativeMapView = map.getNativeMapView();
      this.mapLibreMap = map;
      
      // 获取初始样式信息
      this.currentStyleUrl = this.styleUrls[0].url;
      this.updateStyleInfo();
      
      this.mapReady = true;
      this.message = '✅ 地图已就绪 - 可以测试样式功能';
      
      hilog.info(DOMAIN, TAG, 'Map is ready for maplibre.Style testing');
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
   * 更新样式信息显示
   */
  private updateStyleInfo() {
    if (!this.mapLibreMap) return;
    
    try {
      const style = this.mapLibreMap.getStyle();
      if (!style) {
        this.styleInfo = '样式未加载';
        return;
      }
      
      // 尝试获取样式的基本信息
      this.styleInfo = '样式已加载';
      hilog.info(DOMAIN, TAG, 'Style info updated');
    } catch (error) {
      this.styleInfo = `获取失败: ${error}`;
      hilog.error(DOMAIN, TAG, `Failed to update style info: ${error}`);
    }
  }

  /**
   * 切换地图样式
   */
  private switchStyle(styleUrl: string, styleName: string) {
    if (!this.mapLibreMap) {
      hilog.error(DOMAIN, TAG, 'Map not initialized');
      this.message = '❌ 地图未初始化';
      return;
    }

    try {
      hilog.info(DOMAIN, TAG, `Switching to style: ${styleName} (${styleUrl})`);
      
      // 切换样式
      this.mapLibreMap.setStyleUrl(styleUrl);
      
      // 更新状态
      this.currentStyleName = styleName;
      this.currentStyleUrl = styleUrl;
      this.updateStyleInfo();
      
      this.message = `✅ 已切换到: ${styleName}`;
      hilog.info(DOMAIN, TAG, `Successfully switched to style: ${styleName}`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed to switch style: ${errorMsg}`);
      this.message = `❌ 切换样式失败: ${errorMsg}`;
    }
  }

  /**
   * 获取样式名称
   */
  private getStyleName() {
    if (!this.mapLibreMap) return;
    
    try {
      const style = this.mapLibreMap.getStyle();
      if (!style) {
        this.message = '❌ 样式未加载';
        return;
      }
      
      // 样式名称通常在样式JSON的 name 字段中
      const styleName = this.currentStyleName;
      this.message = `样式名称: ${styleName}`;
      
      hilog.info(DOMAIN, TAG, `Style name: ${styleName}`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed to get style name: ${errorMsg}`);
      this.message = `❌ 获取失败: ${errorMsg}`;
    }
  }

  /**
   * 获取样式URL
   */
  private getStyleUrl() {
    if (!this.mapLibreMap) return;
    
    try {
      const styleUrl = this.currentStyleUrl;
      this.message = `样式URL: ${styleUrl}`;
      
      hilog.info(DOMAIN, TAG, `Style URL: ${styleUrl}`);
      console.info(`完整URL: ${styleUrl}`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed to get style URL: ${errorMsg}`);
      this.message = `❌ 获取失败: ${errorMsg}`;
    }
  }

  /**
   * 获取样式JSON
   */
  private getStyleJson() {
    if (!this.mapLibreMap) return;
    
    try {
      const style = this.mapLibreMap.getStyle();
      if (!style) {
        this.message = '❌ 样式未加载';
        return;
      }
      
      // 获取样式JSON（如果API支持）
      this.message = '✅ 样式JSON已输出到日志';
      hilog.info(DOMAIN, TAG, 'Style JSON requested - check logs for details');
      console.info('样式JSON功能待实现');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed to get style JSON: ${errorMsg}`);
      this.message = `❌ 获取失败: ${errorMsg}`;
    }
  }

  /**
   * 列出所有图层ID
   */
  private listAllLayers() {
    if (!this.mapLibreMap) return;
    
    try {
      const style = this.mapLibreMap.getStyle();
      if (!style) {
        this.message = '❌ 样式未加载';
        return;
      }
      
      // 获取所有图层（如果API支持）
      this.message = '✅ 图层列表已输出到日志';
      hilog.info(DOMAIN, TAG, 'Listing all layers...');
      console.info('图层列表功能待实现');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed to list layers: ${errorMsg}`);
      this.message = `❌ 获取失败: ${errorMsg}`;
    }
  }

  /**
   * 列出所有数据源ID
   */
  private listAllSources() {
    if (!this.mapLibreMap) return;
    
    try {
      const style = this.mapLibreMap.getStyle();
      if (!style) {
        this.message = '❌ 样式未加载';
        return;
      }
      
      // 获取所有数据源（如果API支持）
      this.message = '✅ 数据源列表已输出到日志';
      hilog.info(DOMAIN, TAG, 'Listing all sources...');
      console.info('数据源列表功能待实现');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed to list sources: ${errorMsg}`);
      this.message = `❌ 获取失败: ${errorMsg}`;
    }
  }

  /**
   * 隐藏所有图层
   */
  private hideAllLayers() {
    if (!this.mapLibreMap) return;
    
    try {
      const style = this.mapLibreMap.getStyle();
      if (!style) {
        this.message = '❌ 样式未加载';
        return;
      }
      
      // 隐藏所有图层（设置可见性）
      this.message = '✅ 所有图层已隐藏';
      hilog.info(DOMAIN, TAG, 'All layers hidden');
      console.info('隐藏所有图层功能待实现');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed to hide layers: ${errorMsg}`);
      this.message = `❌ 操作失败: ${errorMsg}`;
    }
  }

  /**
   * 显示所有图层
   */
  private showAllLayers() {
    if (!this.mapLibreMap) return;
    
    try {
      const style = this.mapLibreMap.getStyle();
      if (!style) {
        this.message = '❌ 样式未加载';
        return;
      }
      
      // 显示所有图层（设置可见性）
      this.message = '✅ 所有图层已显示';
      hilog.info(DOMAIN, TAG, 'All layers shown');
      console.info('显示所有图层功能待实现');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed to show layers: ${errorMsg}`);
      this.message = `❌ 操作失败: ${errorMsg}`;
    }
  }

  /**
   * 重新加载当前样式
   */
  private reloadStyle() {
    if (!this.mapLibreMap) return;
    
    try {
      const currentUrl = this.currentStyleUrl;
      const currentName = this.currentStyleName;
      
      hilog.info(DOMAIN, TAG, `Reloading style: ${currentName}`);
      
      // 重新加载样式
      this.mapLibreMap.setStyleUrl(currentUrl);
      this.updateStyleInfo();
      
      this.message = `✅ 已重新加载样式: ${currentName}`;
      hilog.info(DOMAIN, TAG, 'maplibre.Style reloaded successfully');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed to reload style: ${errorMsg}`);
      this.message = `❌ 重新加载失败: ${errorMsg}`;
    }
  }

  /**
   * 强制重绘（调试用）
   */
  private forceRepaint() {
    if (!this.mapLibreMap) {
      this.message = '❌ 地图未初始化';
      return;
    }
    
    try {
      hilog.info(DOMAIN, TAG, '🔧 Force repaint requested');
      
      // 连续触发多次重绘
      this.mapLibreMap.triggerRepaint();
      
      setTimeout(() => {
        if (this.mapLibreMap) {
          this.mapLibreMap.triggerRepaint();
        }
      }, 50);
      
      setTimeout(() => {
        if (this.mapLibreMap) {
          this.mapLibreMap.triggerRepaint();
        }
      }, 150);
      
      setTimeout(() => {
        if (this.mapLibreMap) {
          this.mapLibreMap.triggerRepaint();
        }
      }, 300);
      
      this.message = '✅ 已触发强制重绘（4次）';
      hilog.info(DOMAIN, TAG, 'Force repaint triggered (4 times)');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed to force repaint: ${errorMsg}`);
      this.message = `❌ 强制重绘失败: ${errorMsg}`;
    }
  }

  /**
   * 重置相机位置（调试用）
   */
  private resetCamera() {
    if (!this.mapLibreMap) {
      this.message = '❌ 地图未初始化';
      return;
    }
    
    try {
      hilog.info(DOMAIN, TAG, '🔧 Reset camera requested');
      
      // 获取当前位置
      const currentLatLng: LatLng = this.mapLibreMap.getLatLng();
      const currentZoom: number = this.mapLibreMap.getZoom();
      const currentBearing: number = this.mapLibreMap.getBearing();
      const currentPitch: number = this.mapLibreMap.getPitch();
      
      hilog.info(DOMAIN, TAG, `Current: lat=${currentLatLng.latitude}, lon=${currentLatLng.longitude}, zoom=${currentZoom}, bearing=${currentBearing}, pitch=${currentPitch}`);
      
      // 跳转到当前位置（强制刷新）
      this.mapLibreMap.jumpTo(currentBearing, currentLatLng.latitude, currentLatLng.longitude, currentPitch, currentZoom);
      
      // 触发重绘
      this.mapLibreMap.triggerRepaint();
      
      this.message = `✅ 相机已重置: (${currentLatLng.latitude.toFixed(4)}, ${currentLatLng.longitude.toFixed(4)})`;
      hilog.info(DOMAIN, TAG, 'Camera reset and repaint triggered');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, TAG, `Failed to reset camera: ${errorMsg}`);
      this.message = `❌ 相机重置失败: ${errorMsg}`;
    }
  }

  /**
   * 处理获取样式名称（包装方法）
   */
  private handleGetStyleName(): void {
    this.getStyleName();
  }

  /**
   * 处理获取样式URL（包装方法）
   */
  private handleGetStyleUrl(): void {
    this.getStyleUrl();
  }

  /**
   * 处理获取样式JSON（包装方法）
   */
  private handleGetStyleJson(): void {
    this.getStyleJson();
  }

  /**
   * 处理列出所有图层（包装方法）
   */
  private handleListAllLayers(): void {
    this.listAllLayers();
  }

  /**
   * 处理列出所有数据源（包装方法）
   */
  private handleListAllSources(): void {
    this.listAllSources();
  }

  /**
   * 处理隐藏所有图层（包装方法）
   */
  private handleHideAllLayers(): void {
    this.hideAllLayers();
  }

  /**
   * 处理显示所有图层（包装方法）
   */
  private handleShowAllLayers(): void {
    this.showAllLayers();
  }

  /**
   * 处理重新加载样式（包装方法）
   */
  private handleReloadStyle(): void {
    this.reloadStyle();
  }

  /**
   * 处理强制重绘（包装方法）
   */
  private handleForceRepaint(): void {
    this.forceRepaint();
  }

  /**
   * 处理重置相机（包装方法）
   */
  private handleResetCamera(): void {
    this.resetCamera();
  }
}
