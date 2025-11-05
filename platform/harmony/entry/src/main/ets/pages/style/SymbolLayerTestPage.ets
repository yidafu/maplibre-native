/**
 * Symbol Layer Test Page
 * 符号图层测试
 * 参考 Android: SymbolLayerActivity
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { 
  GeoJson, 
  GeoJsonSource, 
  MapLibreMap, 
  MapView, 
  SymbolLayer,
  StyleBuilder
} from 'maplibre_harmony';
import type { OnStyleLoadedListener, Style } from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, TEST_LOCATIONS, showToast , DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import type { JsonObject } from '../../types/EntryTypes';
import image from '@ohos.multimedia.image';
import { common } from '@kit.AbilityKit';

import type { JSONValue } from 'libmaplibre.so';
// 城市数据接口
interface CityMarker {
  name: string;
  lng: number;
  lat: number;
  icon: string;
}

@Entry
@Component
struct SymbolLayerTestPage {
  private mapController: MapLibreMap | null = null;
  @State private currentStyleIndex: number = 0;
  @State private currentMarkerMode: 'text' | 'icon' | 'both' = 'both';
  @State private layerVisible: boolean = true;
  @State private iconAllowOverlap: boolean = false;
  @State private textAllowOverlap: boolean = false;
  @State private textAnchor: string = 'center';
  @State private iconAnchor: string = 'center';
  private readonly STYLES = [DEFAULT_STYLE_URLS.streets, DEFAULT_STYLE_URLS.bright];
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Symbol Layer',
        description: '符号图层功能测试',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        actionButtons: (): void => this.buildActionButtons()
      })
    }
    .width('100%')

    .height('100%')
  }

  @Builder
  buildMapContent() {
    MapView({
      styleUrl: DEFAULT_STYLE_URLS.streets,
      initialLatitude: 35,
      initialLongitude: 112,
      initialZoom: 4,
      onMapReady: async (map: MapLibreMap) => {
        this.mapController = map;
        
        console.info('✨ 立即添加符号图层（图标+文字模式）...');
        
        await this.addSymbolLayer();
      }
    })
  }

  @Builder
  buildActionButtons() {
    // 移除内层 Scroll，TestPageLayout 已经提供了外层 Scroll
    Column({ space: 8 }) {
      Text('基础操作')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('重新加载图层')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.reloadLayer())
        
        Button('切换样式')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeMapStyle())
      }
      
      Text('Marker 模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button(`纯文字${this.currentMarkerMode === 'text' ? ' ✓' : ''}`)
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.switchMarkerMode('text'))
          .backgroundColor(this.currentMarkerMode === 'text' ? '#007DFF' : '#cccccc')
        
        Button(`纯图标${this.currentMarkerMode === 'icon' ? ' ✓' : ''}`)
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.switchMarkerMode('icon'))
          .backgroundColor(this.currentMarkerMode === 'icon' ? '#007DFF' : '#cccccc')
        
        Button(`图标+文字${this.currentMarkerMode === 'both' ? ' ✓' : ''}`)
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.switchMarkerMode('both'))
          .backgroundColor(this.currentMarkerMode === 'both' ? '#007DFF' : '#cccccc')
      }
      
      Text('文本样式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('文本颜色')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeTextColor())
        
        Button('文本大小')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeTextSize())
      }
      
      Row({ space: 8 }) {
        Button('文本透明度')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeTextOpacity())
        
        Button('文本偏移')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeTextOffset())
      }
      
      Row({ space: 8 }) {
        Button('文本锚点')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeTextAnchor())
        
        Button('最大宽度')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeTextMaxWidth())
      }
      
      Button('切换文本重叠')
        .fontSize(14)
        .width('100%')
        .onClick(() => this.toggleTextAllowOverlap())
      
      Text('文本光晕')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('光晕颜色')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeTextHaloColor())
        
        Button('光晕宽度')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeTextHaloWidth())
      }
      
      Text('图标样式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('图标颜色')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeIconColor())
        
        Button('图标大小')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeIconSize())
      }
      
      Row({ space: 8 }) {
        Button('图标透明度')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeIconOpacity())
        
        Button('图标旋转')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeIconRotate())
      }
      
      Row({ space: 8 }) {
        Button('图标偏移')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeIconOffset())
        
        Button('图标锚点')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeIconAnchor())
      }
      
      Button('切换图标重叠')
        .fontSize(14)
        .width('100%')
        .onClick(() => this.toggleIconAllowOverlap())
      
      Text('图标光晕')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('光晕颜色')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeIconHaloColor())
        
        Button('光晕宽度')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeIconHaloWidth())
      }
      
      Text('显示模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('显示/隐藏')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.toggleVisibility())
        
        Button('重置视图')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.resetView())
      }
    }
    .width('100%')
  }
  
  /**
   * 从 rawfile 加载单个 marker 图标
   */
  private async loadMarkerIconByName(iconName: string, filename: string): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
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
      const style = this.mapController!.getStyle();
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
   * 加载所有 marker 图标（10种颜色）
   */
  private async loadAllMarkerIcons(): Promise<void> {
    if (!this.mapController) return;
    
    const markers = [
      'marker_0', 'marker_1', 'marker_2', 'marker_3', 'marker_4',
      'marker_5', 'marker_6', 'marker_7', 'marker_8', 'marker_9'
    ];
    
    for (const markerName of markers) {
      await this.loadMarkerIconByName(markerName, `${markerName}.png`);
    }
    
    console.info(`✅ 共加载 ${markers.length} 个 marker 图标`);
  }
  
  /**
   * 添加符号图层 - 使用新的 StyleBuilder API
   * 展示最佳实践：无需延迟，无需手动刷新属性
   */
  private async addSymbolLayer(): Promise<void> {
    if (!this.mapController) return;
    
    try {
      const style = this.mapController.getStyle();
      if (!style) {
        showToast('样式未加载，请稍候...');
        return;
      }
      
      // 1. 加载所有 marker 图标
      let iconsLoaded = false;
      console.info('🖼️ 开始加载 marker 图标...');
      try {
        await this.loadAllMarkerIcons();
        const testIcon = style.getImage('marker_0');
        iconsLoaded = testIcon !== null;
        console.info(iconsLoaded ? '✅ 图标加载成功' : '⚠️ 图标未找到');
      } catch (iconError) {
        console.error('⚠️ 图标加载失败:', iconError);
        iconsLoaded = false;
      }
      
      // 2. ✅ 恢复10个城市（现已支持中文，也可测试拼音）
      const currentLatLng = this.mapController.getLatLng();
      console.info(`🔍 当前相机位置: lng=${currentLatLng.longitude}, lat=${currentLatLng.latitude}`);
      
      // ✅ 可选：使用拼音名称测试英文渲染
      const usePinyin = false;  // 改为 true 使用拼音
      
      const cities: CityMarker[] = usePinyin ? [
        { name: 'Beijing', lng: 116.4, lat: 39.9, icon: 'marker_0' },
        { name: 'Shanghai', lng: 121.5, lat: 31.2, icon: 'marker_1' },
        { name: 'Guangzhou', lng: 113.3, lat: 23.1, icon: 'marker_2' },
        { name: 'Shenzhen', lng: 114.1, lat: 22.5, icon: 'marker_3' },
        { name: 'Chengdu', lng: 104.1, lat: 30.7, icon: 'marker_4' },
        { name: 'Hangzhou', lng: 120.2, lat: 30.3, icon: 'marker_5' },
        { name: 'Wuhan', lng: 114.3, lat: 30.6, icon: 'marker_6' },
        { name: 'Xian', lng: 108.9, lat: 34.3, icon: 'marker_7' },
        { name: 'Nanjing', lng: 118.8, lat: 32.1, icon: 'marker_8' },
        { name: 'Chongqing', lng: 106.5, lat: 29.6, icon: 'marker_9' }
      ] : [
        { name: '北京', lng: 116.4, lat: 39.9, icon: 'marker_0' },
        { name: '上海', lng: 121.5, lat: 31.2, icon: 'marker_1' },
        { name: '广州', lng: 113.3, lat: 23.1, icon: 'marker_2' },
        { name: '深圳', lng: 114.1, lat: 22.5, icon: 'marker_3' },
        { name: '成都', lng: 104.1, lat: 30.7, icon: 'marker_4' },
        { name: '杭州', lng: 120.2, lat: 30.3, icon: 'marker_5' },
        { name: '武汉', lng: 114.3, lat: 30.6, icon: 'marker_6' },
        { name: '西安', lng: 108.9, lat: 34.3, icon: 'marker_7' },
        { name: '南京', lng: 118.8, lat: 32.1, icon: 'marker_8' },
        { name: '重庆', lng: 106.5, lat: 29.6, icon: 'marker_9' }
      ];
      console.info(`✅ 创建 ${cities.length} 个城市markers（${usePinyin ? '拼音' : '中文'}）`);
      
      // 3. 创建 GeoJSON 数据
      const features = cities.map(city => {
        const props: Record<string, JSONValue> = { 'title': city.name };
        // ✅ 根据模式决定是否包含 icon 属性
        if (iconsLoaded && this.currentMarkerMode !== 'text') {
          props['icon'] = city.icon;
        }
        return GeoJson.pointFeature([city.lng, city.lat], props);
      });
      
      const geojson = GeoJson.featureCollection(features);
      const source = new GeoJsonSource('symbol-source');
      source.setGeoJson(geojson);
      
      // 4. 创建图层并设置属性（根据模式配置）
      const layer = new SymbolLayer('symbol-layer', 'symbol-source');
      
      // Layout 属性（必须在 addLayer 之前）
      layer.setTextField(['get', 'title']);
      layer.setTextMaxWidth(10);
      layer.setTextAnchor('top');  // 文字在图标上方
      layer.setTextOffset([0, -1.5]);  // 向上偏移
      layer.setTextSize(16);  // 适中字号
      layer.setTextOptional(false);  // 文本不可选：优先显示文本
      
      // ✅ 根据模式决定是否显示图标
      if (iconsLoaded && this.currentMarkerMode !== 'text') {
        layer.setIconImage(['get', 'icon']);
        layer.setIconAnchor('bottom');
        // layer.setIconIgnorePlacement(true);
        // layer.setIconAllowOverlap(true);
        // layer.setIconOptional(true);  // 图标可选，不影响文字
      }
      
      // Paint 属性 - 默认样式
      layer.setTextColor('#000000');  // 黑色文字
      layer.setTextHaloColor('#FFFFFF');  // 白色光晕
      layer.setTextHaloWidth(2);  // 正常光晕宽度
      layer.setTextOpacity(1.0);
      // layer.setTextOptional(false)
      // layer.setTextIgnorePlacement(true)
      
      if (this.currentMarkerMode !== 'text' && iconsLoaded) {
        layer.setIconSize(1.0);
      }
      
      // 5. 添加数据源和图层
      this.mapController.addSource(source);
      this.mapController.addLayer(layer);
      
      console.info('✅ 图层已添加，无需延迟或刷新！');
      showToast(`符号图层已添加 (${cities.length} 个城市)`);
    } catch (error) {
      console.error('❌ 添加符号图层失败:', error);
      showToast(`添加失败: ${error}`);
    }
  }

  // 重新加载图层
  private async reloadLayer(): Promise<void> {
    if (!this.mapController) return;
    
    try {
      // 先移除旧图层和源
      try {
        this.mapController.removeLayer('symbol-layer');
        this.mapController.removeSource('symbol-source');
        console.info('✅ 旧图层已移除');
      } catch (e) {
        console.warn('移除旧图层失败（可能不存在）:', e);
      }
      
      // ⏰ 延迟一帧，确保移除完成
      await new Promise<void>((resolve) => setTimeout(() => resolve(), 100));
      
      // 重新添加图层（确保所有属性在 addLayer 之前设置）
      await this.addSymbolLayer();
      showToast('图层已重新加载');
    } catch (error) {
      console.error('重新加载图层失败:', error);
      showToast(`重新加载失败: ${error}`);
    }
  }

  // 切换地图样式 - 使用新的生命周期回调
  private async changeMapStyle(): Promise<void> {
    if (!this.mapController) return;
    
    try {
      this.currentStyleIndex = (this.currentStyleIndex + 1) % this.STYLES.length;
      const newStyleUrl = this.STYLES[this.currentStyleIndex];
      
      // ✨ 使用 setStyleWithCallback，无需手动延迟！
      this.mapController.setStyleWithCallback(newStyleUrl, async (style) => {
        console.info('✨ 样式加载完成回调，立即添加图层');
        await this.addSymbolLayer();
      });
      
      showToast(`正在切换到样式 ${this.currentStyleIndex + 1}`);
    } catch (error) {
      showToast(`切换样式失败: ${error}`);
    }
  }

  // ========== 文本样式方法 ==========

  // 改变文本颜色
  private changeTextColor(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('symbol-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      const colors: string[] = ['#2196F3', '#FF9800', '#4CAF50', '#F44336', '#9C27B0', '#000000'];
      const randomColor: string = colors[Math.floor(Math.random() * colors.length)];
      
      layer.setTextColor(randomColor);
      showToast(`文本颜色: ${randomColor}`);
    } catch (error) {
      showToast(`更改文本颜色失败: ${error}`);
    }
  }

  // 改变文本大小
  private changeTextSize(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('symbol-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      const size = 10 + Math.random() * 20; // 10-30
      layer.setTextSize(size);
      showToast(`文本大小: ${size.toFixed(1)}`);
    } catch (error) {
      showToast(`更改文本大小失败: ${error}`);
    }
  }

  // 改变文本透明度
  private changeTextOpacity(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('symbol-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      const opacity = 0.3 + Math.random() * 0.7; // 0.3-1.0
      layer.setTextOpacity(opacity);
      showToast(`文本透明度: ${opacity.toFixed(2)}`);
    } catch (error) {
      showToast(`更改文本透明度失败: ${error}`);
    }
  }

  // 改变文本偏移
  private changeTextOffset(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('symbol-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      const x = Math.random() * 4 - 2; // -2 到 2
      const y = Math.random() * 4 - 2;
      layer.setTextOffset([x, y]);
      showToast(`文本偏移: [${x.toFixed(1)}, ${y.toFixed(1)}]`);
    } catch (error) {
      showToast(`更改文本偏移失败: ${error}`);
    }
  }

  // 改变文本锚点
  private changeTextAnchor(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('symbol-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      const anchors: string[] = ['center', 'top', 'bottom', 'left', 'right', 'top-left', 'top-right', 'bottom-left', 'bottom-right'];
      const currentIndex = anchors.indexOf(this.textAnchor);
      this.textAnchor = anchors[(currentIndex + 1) % anchors.length];
      
      layer.setTextAnchor(this.textAnchor);
      showToast(`文本锚点: ${this.textAnchor}`);
    } catch (error) {
      showToast(`更改文本锚点失败: ${error}`);
    }
  }

  // 改变最大宽度
  private changeTextMaxWidth(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('symbol-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      const maxWidth = 5 + Math.random() * 15; // 5-20
      layer.setTextMaxWidth(maxWidth);
      showToast(`最大宽度: ${maxWidth.toFixed(1)}`);
    } catch (error) {
      showToast(`更改最大宽度失败: ${error}`);
    }
  }

  // 切换文本重叠
  private toggleTextAllowOverlap(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('symbol-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      this.textAllowOverlap = !this.textAllowOverlap;
      layer.setTextAllowOverlap(this.textAllowOverlap);
      showToast(`文本重叠: ${this.textAllowOverlap ? '允许' : '禁止'}`);
    } catch (error) {
      showToast(`切换文本重叠失败: ${error}`);
    }
  }

  // 改变文本光晕颜色
  private changeTextHaloColor(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('symbol-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      const colors: string[] = ['#FFFFFF', '#000000', '#FF0000', '#00FF00', '#0000FF', '#FFFF00'];
      const randomColor: string = colors[Math.floor(Math.random() * colors.length)];
      
      layer.setTextHaloColor(randomColor);
      showToast(`文本光晕: ${randomColor}`);
    } catch (error) {
      showToast(`更改文本光晕颜色失败: ${error}`);
    }
  }

  // 改变文本光晕宽度
  private changeTextHaloWidth(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('symbol-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      const width = Math.random() * 5; // 0-5
      layer.setTextHaloWidth(width);
      showToast(`文本光晕宽度: ${width.toFixed(1)}`);
    } catch (error) {
      showToast(`更改文本光晕宽度失败: ${error}`);
    }
  }

  // ========== 图标样式方法 ==========

  // 改变图标颜色
  private changeIconColor(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('symbol-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      const colors: string[] = ['#2196F3', '#FF9800', '#4CAF50', '#F44336', '#9C27B0', '#000000'];
      const randomColor: string = colors[Math.floor(Math.random() * colors.length)];
      
      layer.setIconColor(randomColor);
      showToast(`图标颜色: ${randomColor}`);
    } catch (error) {
      showToast(`更改图标颜色失败: ${error}`);
    }
  }

  // 改变图标大小
  private changeIconSize(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('symbol-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      const size = 0.5 + Math.random() * 2; // 0.5-2.5
      layer.setIconSize(size);
      showToast(`图标大小: ${size.toFixed(2)}`);
    } catch (error) {
      showToast(`更改图标大小失败: ${error}`);
    }
  }

  // 改变图标透明度
  private changeIconOpacity(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('symbol-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      const opacity = 0.3 + Math.random() * 0.7; // 0.3-1.0
      layer.setIconOpacity(opacity);
      showToast(`图标透明度: ${opacity.toFixed(2)}`);
    } catch (error) {
      showToast(`更改图标透明度失败: ${error}`);
    }
  }

  // 改变图标旋转
  private changeIconRotate(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('symbol-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      const rotate = Math.random() * 360; // 0-360
      layer.setIconRotate(rotate);
      showToast(`图标旋转: ${rotate.toFixed(0)}°`);
    } catch (error) {
      showToast(`更改图标旋转失败: ${error}`);
    }
  }

  // 改变图标偏移
  private changeIconOffset(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('symbol-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      const x = Math.random() * 4 - 2; // -2 到 2
      const y = Math.random() * 4 - 2;
      layer.setIconOffset([x, y]);
      showToast(`图标偏移: [${x.toFixed(1)}, ${y.toFixed(1)}]`);
    } catch (error) {
      showToast(`更改图标偏移失败: ${error}`);
    }
  }

  // 改变图标锚点
  private changeIconAnchor(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('symbol-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      const anchors: string[] = ['center', 'top', 'bottom', 'left', 'right', 'top-left', 'top-right', 'bottom-left', 'bottom-right'];
      const currentIndex = anchors.indexOf(this.iconAnchor);
      this.iconAnchor = anchors[(currentIndex + 1) % anchors.length];
      
      layer.setIconAnchor(this.iconAnchor);
      showToast(`图标锚点: ${this.iconAnchor}`);
    } catch (error) {
      showToast(`更改图标锚点失败: ${error}`);
    }
  }

  // 切换图标重叠
  private toggleIconAllowOverlap(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('symbol-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      this.iconAllowOverlap = !this.iconAllowOverlap;
      layer.setIconAllowOverlap(this.iconAllowOverlap);
      showToast(`图标重叠: ${this.iconAllowOverlap ? '允许' : '禁止'}`);
    } catch (error) {
      showToast(`切换图标重叠失败: ${error}`);
    }
  }

  // 改变图标光晕颜色
  private changeIconHaloColor(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('symbol-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      const colors: string[] = ['#FFFFFF', '#000000', '#FF0000', '#00FF00', '#0000FF', '#FFFF00'];
      const randomColor: string = colors[Math.floor(Math.random() * colors.length)];
      
      layer.setIconHaloColor(randomColor);
      showToast(`图标光晕: ${randomColor}`);
    } catch (error) {
      showToast(`更改图标光晕颜色失败: ${error}`);
    }
  }

  // 改变图标光晕宽度
  private changeIconHaloWidth(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('symbol-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      const width = Math.random() * 5; // 0-5
      layer.setIconHaloWidth(width);
      showToast(`图标光晕宽度: ${width.toFixed(1)}`);
    } catch (error) {
      showToast(`更改图标光晕宽度失败: ${error}`);
    }
  }

  // 切换显示/隐藏
  private toggleVisibility(): void {
    if (!this.mapController) return;
    
    try {
      const layer = this.mapController.getLayer('symbol-layer');
      
      if (!layer || !(layer instanceof SymbolLayer)) {
        showToast('未找到符号图层');
        return;
      }
      
      this.layerVisible = !this.layerVisible;
      layer.setVisibility(this.layerVisible ? 'visible' : 'none');
      showToast(`图层: ${this.layerVisible ? '显示' : '隐藏'}`);
    } catch (error) {
      showToast(`切换显示失败: ${error}`);
    }
  }

  // 切换 Marker 模式
  private async switchMarkerMode(mode: 'text' | 'icon' | 'both'): Promise<void> {
    if (!this.mapController) return;
    
    this.currentMarkerMode = mode;
    console.info(`🔄 切换到 ${mode} 模式`);
    
    // 重新加载图层
    await this.reloadLayer();
    
    let modeName = '';
    if (mode === 'text') {
      modeName = '纯文字';
    } else if (mode === 'icon') {
      modeName = '纯图标';
    } else {
      modeName = '图标+文字';
    }
    showToast(`已切换到${modeName}模式`);
  }
  
  // 重置视图
  private resetView(): void {
    if (!this.mapController) return;
    
    this.mapController.jumpTo(0, 35, 112, 0, 4);  // ✅ 修复：中国中部，zoom=4
    showToast('视图已重置');
  }
}

