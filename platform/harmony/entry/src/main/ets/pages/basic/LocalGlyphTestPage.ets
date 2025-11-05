/**
 * Local Glyph Test Page
 * 本地字体测试页面
 * 
 * 参考: platform/android/MapLibreAndroidTestApp/src/main/java/org/maplibre/android/testapp/activity/maplayout/LocalGlyphActivity.kt
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap, CameraPosition, LatLng, GeoJson, GeoJsonSource, SymbolLayer } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import { image } from '@kit.ImageKit';
import { resourceManager } from '@kit.LocalizationKit';

import type { JSONValue } from 'libmaplibre.so';
class LanguageText {
  language: string = '';
  text: string = '';
  lng: number = 0;
  lat: number = 0;
  color: string = '';
  icon: string = '';  // marker 图标名称
}

@Entry
@Component
struct LocalGlyphTestPage {
  private mapController: MapLibreMap | null = null;
  @State private useLocalGlyphs: boolean = false;
  
  aboutToDisappear() {
    if (this.mapController) {
      this.mapController.destroy();
      this.mapController = null;
    }
  }
  
  private onMapReady = async (map: MapLibreMap): Promise<void> => {
    console.info('[LocalGlyphTestPage] onMapReady');
    this.mapController = map;

    // 先启用本地字体（在加载样式之前）
    console.info('🔤 [LocalGlyphTestPage] 先启用本地字体...');
    this.enableLocalGlyphs();
    
    // 然后加载样式（使用回调确保样式完全加载）
    console.info('🎨 [LocalGlyphTestPage] 加载样式...');
    map.setStyleWithCallback(DEFAULT_STYLE_URLS.bright, async (style) => {
      console.info('✅ [LocalGlyphTestPage] 样式加载完成，添加图层...');
      
      // 样式加载完成后再添加图层
      await this.addMultiLanguageTextLayer();
      
      // 设置相机位置以显示所有文本
      this.mapController!.jumpTo(0, 30, 50, 0, 2.5);
    });
  };
  
  /**
   * 启用本地字体
   */
  private enableLocalGlyphs = (): void => {
    this.useLocalGlyphs = true;
    
    if (this.mapController) {
      // 使用HarmonyOS系统字体
      this.mapController.setLocalIdeographFontFamily("HarmonyOS_Sans");
      
      // 验证是否设置成功
      const currentFont = this.mapController.getLocalIdeographFontFamily();
      console.info('🔤 [LocalGlyphTestPage] 本地字体已启用:', currentFont);
      console.info('🔤 [LocalGlyphTestPage] 设置值: HarmonyOS_Sans');
      
      showToast('本地字体已启用（HarmonyOS_Sans）');
    }
  };
  
  /**
   * 禁用本地字体
   */
  private disableLocalGlyphs = (): void => {
    this.useLocalGlyphs = false;
    
    if (this.mapController) {
      // 设置为null禁用本地字体，将从服务器加载字形
      this.mapController.setLocalIdeographFontFamily(null);
      showToast('本地字体已禁用，将从服务器加载');
      console.info('[LocalGlyphTestPage] Local ideograph font family disabled');
    }
  };
  
  /**
   * 加载单个 marker 图标
   * @param iconName 图标名称（如 'marker_0'）
   * @param filename 文件名（如 'marker_0.png'）
   */
  private async loadMarkerIconByName(iconName: string, filename: string): Promise<void> {
    if (!this.mapController) return;
    
    try {
      const context = getContext(this);
      const resourceMgr = context.resourceManager;
      
      // 从 rawfile 读取 PNG 文件
      const imageBuffer = await resourceMgr.getRawFileContent(filename);
      
      // 创建 ImageSource 并解码为 PixelMap
      const imageSource = image.createImageSource(imageBuffer.buffer);
      const pixelMap = await imageSource.createPixelMap({
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      });
      imageSource.release();
      
      // 获取图片信息
      const imageInfo = await pixelMap.getImageInfo();
      const width = imageInfo.size.width;
      const height = imageInfo.size.height;
      
      // 读取 RGBA 数据
      const pixelBytes = new ArrayBuffer(width * height * 4);
      await pixelMap.readPixelsToBuffer(pixelBytes);
      
      // 添加图标到样式
      const style = this.mapController.getStyle();
      if (style) {
        style.addImage(iconName, pixelBytes, width, height, false);
        console.info(`✅ ${iconName} 图标已添加: ${width}x${height}`);
      }
      
      pixelMap.release();
    } catch (error) {
      console.error(`加载 ${iconName} 失败: ${error}`);
      throw new Error(`加载 ${iconName} 失败: ${error}`);
    }
  }
  
  /**
   * 加载所有语言 marker 图标（7种语言对应7个图标）
   */
  private async loadAllLanguageMarkers(): Promise<void> {
    if (!this.mapController) return;
    
    const markers = [
      'marker_0', 'marker_1', 'marker_2', 'marker_3', 
      'marker_4', 'marker_5', 'marker_6'
    ];
    
    for (const markerName of markers) {
      await this.loadMarkerIconByName(markerName, `${markerName}.png`);
    }
    
    console.info(`✅ 共加载 ${markers.length} 个语言 marker 图标`);
  }
  
  /**
   * 添加多语言文本测试图层
   * 包含中文、日文、韩语、英文、法语、西班牙语、阿拉伯语的文本
   * 
   * 参考 SymbolLayerTestPage 实现
   */
  private async addMultiLanguageTextLayer(): Promise<void> {
    if (!this.mapController) return;
    
    try {
      const style = this.mapController.getStyle();
      if (!style) {
        console.warn('[LocalGlyphTestPage] ⚠️ 样式未加载，请稍候...');
        showToast('样式未加载，请稍候...');
        return;
      }
      
      console.info('[LocalGlyphTestPage] ✅ 样式已就绪，开始添加图层');
      
      // 1. 加载所有 marker 图标
      let iconsLoaded = false;
      console.info('🖼️ 开始加载语言 marker 图标...');
      try {
        await this.loadAllLanguageMarkers();
        const testIcon = style.getImage('marker_0');
        iconsLoaded = testIcon !== null;
        console.info(iconsLoaded ? '✅ 图标加载成功' : '⚠️ 图标未找到');
      } catch (iconError) {
        console.error('⚠️ 图标加载失败:', iconError);
        iconsLoaded = false;
      }
      
      // 2. 定义多语言测试文本（包含语言名称和示例文本）
      const text1 = new LanguageText();
      text1.language = '中文';
      text1.text = '北京欢迎你 - Chinese Text';
      text1.lng = 116.4;
      text1.lat = 39.9;
      text1.color = '#E91E63';
      text1.icon = 'marker_0';
      
      const text2 = new LanguageText();
      text2.language = '日本語';
      text2.text = 'こんにちは世界 - Japanese Text';
      text2.lng = 139.7;
      text2.lat = 35.7;
      text2.color = '#9C27B0';
      text2.icon = 'marker_1';
      
      const text3 = new LanguageText();
      text3.language = '한국어';
      text3.text = '안녕하세요 - Korean Text';
      text3.lng = 126.98;
      text3.lat = 37.56;
      text3.color = '#3F51B5';
      text3.icon = 'marker_2';
      
      const text4 = new LanguageText();
      text4.language = 'English';
      text4.text = 'Hello World - English Text';
      text4.lng = -0.12;
      text4.lat = 51.5;
      text4.color = '#2196F3';
      text4.icon = 'marker_3';
      
      const text5 = new LanguageText();
      text5.language = 'Français';
      text5.text = 'Bonjour le monde - French Text';
      text5.lng = 2.35;
      text5.lat = 48.85;
      text5.color = '#009688';
      text5.icon = 'marker_4';
      
      const text6 = new LanguageText();
      text6.language = 'Español';
      text6.text = 'Hola Mundo - Spanish Text';
      text6.lng = -3.7;
      text6.lat = 40.4;
      text6.color = '#FF9800';
      text6.icon = 'marker_5';
      
      const text7 = new LanguageText();
      text7.language = 'العربية';
      text7.text = 'مرحبا بالعالم - Arabic Text';
      text7.lng = 39.2;
      text7.lat = 21.5;
      text7.color = '#795548';
      text7.icon = 'marker_6';
      
      const multiLanguageTexts: LanguageText[] = [text1, text2, text3, text4, text5, text6, text7];
      
      console.info(`✅ 创建 ${multiLanguageTexts.length} 个多语言文本标记`);
      
      // 3. 创建 GeoJSON 数据
      const features = multiLanguageTexts.map(item => {
        const props: Record<string, JSONValue> = {
          'text': item.text,
          'language': item.language,
          'color': item.color
        };
        // 只有图标加载成功时才包含 icon 属性
        if (iconsLoaded) {
          props['icon'] = item.icon;
        }
        return GeoJson.pointFeature([item.lng, item.lat], props);
      });
      
      const geojson = GeoJson.featureCollection(features);
      const source = new GeoJsonSource('multilang-text-source');
      source.setGeoJson(geojson);
      
      // 4. 创建文本图层（参考 SymbolLayerTestPage 配置）
      const layer = new SymbolLayer('multilang-text-layer', 'multilang-text-source');
      
      // Layout 属性（必须在 addLayer 之前设置）
      layer.setTextField(['get', 'text']);
      layer.setTextMaxWidth(30);  // 增加文字最大宽度以容纳更多内容
      layer.setTextAnchor('top');  // 文字在图标上方
      layer.setTextOffset([0, -1.5]);  // 向上偏移
      layer.setTextSize(16);  // 参考 SymbolLayerTestPage 的字号
      layer.setTextOptional(false);  // 文本不可选：优先显示文本
      
      console.info('🔤 [LocalGlyphTestPage] SymbolLayer text 配置完成');
      
      // ✅ 设置图标（如果已加载）- 参考 SymbolLayerTestPage
      if (iconsLoaded) {
        layer.setIconImage(['get', 'icon']);
        layer.setIconAnchor('bottom');
        // 不设置 IconIgnorePlacement 和 IconAllowOverlap，使用默认值
        // layer.setIconOptional(true);  // 保留注释，可选项
      }
      
      // Paint 属性 - 参考 SymbolLayerTestPage 的默认样式
      layer.setTextColor('#000000');  // 黑色文字（更清晰）
      layer.setTextHaloColor('#FFFFFF');  // 白色光晕
      layer.setTextHaloWidth(2);  // 正常光晕宽度
      layer.setTextOpacity(1.0);
      
      console.info('🎨 [LocalGlyphTestPage] Text properties:');
      console.info('   - textSize: 16');
      console.info('   - textColor: #000000 (黑色)');
      console.info('   - textHaloColor: #FFFFFF');
      console.info('   - textHaloWidth: 2');
      
      if (iconsLoaded) {
        layer.setIconSize(1.0);  // 图标大小
        console.info('   - iconSize: 1.0');
      }
      
      // 5. 添加数据源和图层 - 参考 SymbolLayerTestPage
      this.mapController.addSource(source);
      this.mapController.addLayer(layer);
      
      console.info('✅ [LocalGlyphTestPage] 图层已添加，无需延迟或刷新！');
      showToast(`多语言文本图层已添加 (${multiLanguageTexts.length} 种语言)`);
    } catch (error) {
      console.error('❌ 添加多语言文本图层失败:', error);
      showToast(`添加失败: ${error}`);
    }
  }
  
  /**
   * 切换到不同城市查看字体
   */
  private showCity = (city: LatLng, name: string): void => {
    if (this.mapController) {
      this.mapController.jumpTo(0, city.latitude, city.longitude, 0, 12);
      showToast(`显示: ${name}`);
    }
  };
  
  @Builder
  actionButtonsBuilder() {
    // 本地字体状态显示
    Column() {
      Text('本地字体设置')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 6 });
      
      Text(this.useLocalGlyphs ? '✓ 使用本地字体渲染' : '✗ 从服务器加载字体')
        .fontSize(12)
        .fontColor(this.useLocalGlyphs ? '#4CAF50' : '#F44336')
        .margin({ bottom: 12 });
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    
    // 本地字体开关按钮
    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
      Button(this.useLocalGlyphs ? '禁用本地字体' : '启用本地字体')
        .fontSize(12)
        .backgroundColor(this.useLocalGlyphs ? '#4CAF50' : '#9E9E9E')
        .margin({ right: 8, bottom: 8 })
        .onClick(() => {
          if (this.useLocalGlyphs) {
            this.disableLocalGlyphs();
          } else {
            this.enableLocalGlyphs();
          }
        });
    }
    .width('100%')
    
    // 分隔线
    Divider()
      .strokeWidth(1)
      .color('#E0E0E0')
      .margin({ top: 4, bottom: 12 });
    
    // 多语言测试说明
    Column() {
      Text('多语言测试：')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 4 });
      
      Text('中文 • 日本語 • 한국어 • English • Français • Español • العربية')
        .fontSize(11)
        .fontColor('#666666')
        .margin({ bottom: 8 });
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    
    // 导航按钮 - Flex 自动排布
    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
      Button('查看全部')
        .fontSize(12)
        .margin({ right: 8, bottom: 8 })
        .onClick(() => {
          if (this.mapController) {
            this.mapController.jumpTo(0, 30, 50, 0, 2.5);
            showToast('显示全部语言');
          }
        });
      
      Button('中文 🇨🇳')
        .fontSize(12)
        .margin({ right: 8, bottom: 8 })
        .onClick(() => {
          if (this.mapController) {
            this.mapController.jumpTo(0, 39.9, 116.4, 0, 10);
            showToast('显示: 中文');
          }
        });
      
      Button('日语 🇯🇵')
        .fontSize(12)
        .margin({ right: 8, bottom: 8 })
        .onClick(() => {
          if (this.mapController) {
            this.mapController.jumpTo(0, 35.7, 139.7, 0, 10);
            showToast('显示: 日本語');
          }
        });
      
      Button('韩语 🇰🇷')
        .fontSize(12)
        .margin({ right: 8, bottom: 8 })
        .onClick(() => {
          if (this.mapController) {
            this.mapController.jumpTo(0, 37.56, 126.98, 0, 10);
            showToast('显示: 한국어');
          }
        });
      
      Button('英语 🇬🇧')
        .fontSize(12)
        .margin({ right: 8, bottom: 8 })
        .onClick(() => {
          if (this.mapController) {
            this.mapController.jumpTo(0, 51.5, -0.12, 0, 10);
            showToast('显示: English');
          }
        });
      
      Button('法语 🇫🇷')
        .fontSize(12)
        .margin({ right: 8, bottom: 8 })
        .onClick(() => {
          if (this.mapController) {
            this.mapController.jumpTo(0, 48.85, 2.35, 0, 10);
            showToast('显示: Français');
          }
        });
      
      Button('西班牙语 🇪🇸')
        .fontSize(12)
        .margin({ right: 8, bottom: 8 })
        .onClick(() => {
          if (this.mapController) {
            this.mapController.jumpTo(0, 40.4, -3.7, 0, 10);
            showToast('显示: Español');
          }
        });
      
      Button('阿拉伯语 🇸🇦')
        .fontSize(12)
        .margin({ right: 8, bottom: 8 })
        .onClick(() => {
          if (this.mapController) {
            this.mapController.jumpTo(0, 21.5, 39.2, 0, 10);
            showToast('显示: العربية');
          }
        });
    }
    .width('100%')
    
    // 分隔线
    Divider()
      .strokeWidth(1)
      .color('#E0E0E0')
      .margin({ top: 4, bottom: 8 });
    
    // 说明文字
    Column() {
      Text('说明：')
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 4 });
      
      Text('本地字体可提高表意文字的渲染性能，避免从网络加载大量字形数据。')
        .fontSize(10)
        .fontColor('#666666');
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
  
  @Builder
  mapContentBuilder() {
    MapView({
      onMapReady: this.onMapReady,
      // 不在这里设置 styleUrl，在 onMapReady 中手动加载
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 10
    })
      .width('100%')
      .height('100%');
  }
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Local Glyph',
        description: '本地字体',
        showActionBar: true,
        actionButtons: (): void => this.actionButtonsBuilder(),
        mapContent: (): void => this.mapContentBuilder()
      });
    }
    .width('100%')
    .height('100%');
  }
}