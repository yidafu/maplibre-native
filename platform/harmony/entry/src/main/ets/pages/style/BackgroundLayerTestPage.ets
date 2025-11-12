import { BackgroundLayer, MapLibreMap, MapView } from 'maplibre_harmony';
/**
 * Background Layer Test Page
 * 背景图层测试
 * 参考 Android BackgroundLayer 测试
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { DEFAULT_STYLE_URLS, showToast } from '../common/TestUtils';
import image from '@ohos.multimedia.image';
import { common } from '@kit.AbilityKit';

class BackgroundPatternResource {
  readonly name: string;
  readonly filename: string;
  readonly label: string;

  constructor(name: string, filename: string, label: string) {
    this.name = name;
    this.filename = filename;
    this.label = label;
  }
}

@Entry
@Component
struct BackgroundLayerTestPage {
  private mapController: MapLibreMap | null = null;
  @State private currentStyleIndex: number = 0;
  private readonly STYLES: string[] = [DEFAULT_STYLE_URLS.streets, DEFAULT_STYLE_URLS.bright];
  private readonly PATTERN_RESOURCES: BackgroundPatternResource[] = [
    new BackgroundPatternResource('background-watermark', 'background_pattern_watermark.png', '水印'),
    new BackgroundPatternResource('background-random', 'background_pattern_random.png', '随机')
  ];
  private patternImagesLoaded: boolean = false;
  private patternIndex: number = 0;
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Background Layer',
        description: '背景图层颜色',
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
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 5,
      onMapReady: (map: MapLibreMap) => {
        this.mapController = map;
        map.jumpTo(0, 0, 0, 0, 2);
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
        Button('重置图层')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.resetLayer())
        
        Button('切换样式')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeMapStyle())
      }
      
      Text('背景样式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('背景颜色')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeBackgroundColor())
        
        Button('背景透明度')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeBackgroundOpacity())
        
        Button('背景图案')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => { void this.changeBackgroundPattern(); })
      }
      
      Text('显示模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Button('重置视图')
        .fontSize(14)
        .width('100%')
        .onClick(() => this.resetView())
    }
    .width('100%')
  }

  // 重置图层
  private resetLayer(): void {
    if (!this.mapController) return;
    
    try {
      const layers = this.mapController.getLayers();
      for (const layer of layers) {
        if (layer instanceof BackgroundLayer) {
          layer.setBackgroundColor('#F2F2F2');
          layer.setBackgroundOpacity(1.0);
          showToast('背景图层已重置');
          return;
        }
      }
      showToast('未找到背景图层');
    } catch (error) {
      showToast(`重置失败: ${error}`);
    }
  }

  // 切换地图样式
  private changeMapStyle(): void {
    if (!this.mapController) return;
    
    try {
      this.currentStyleIndex = (this.currentStyleIndex + 1) % this.STYLES.length;
      const newStyleUrl = this.STYLES[this.currentStyleIndex];
      
      this.mapController.setStyleUrl(newStyleUrl);
      this.patternImagesLoaded = false;
      this.patternIndex = 0;
      showToast(`正在切换到样式 ${this.currentStyleIndex + 1}`);
    } catch (error) {
      showToast(`切换样式失败: ${error}`);
    }
  }

  // 改变背景颜色
  private changeBackgroundColor(): void {
    if (!this.mapController) return;
    
    try {
      const layers = this.mapController.getLayers();
      for (const layer of layers) {
        if (layer instanceof BackgroundLayer) {
          const colors: string[] = ['#2196F3', '#FF9800', '#4CAF50', '#F44336', '#9C27B0', '#212121'];
          const randomColor: string = colors[Math.floor(Math.random() * colors.length)];
          
          layer.setBackgroundColor(randomColor);
          showToast(`背景颜色: ${randomColor}`);
          return;
        }
      }
      showToast('未找到背景图层');
    } catch (error) {
      showToast(`更改颜色失败: ${error}`);
    }
  }

  // 改变背景透明度
  private changeBackgroundOpacity(): void {
    if (!this.mapController) return;
    
    try {
      const layers = this.mapController.getLayers();
      for (const layer of layers) {
        if (layer instanceof BackgroundLayer) {
          const opacity = 0.3 + Math.random() * 0.7; // 0.3-1.0
          
          layer.setBackgroundOpacity(opacity);
          showToast(`背景透明度: ${opacity.toFixed(2)}`);
          return;
        }
      }
      showToast('未找到背景图层');
    } catch (error) {
      showToast(`更改透明度失败: ${error}`);
    }
  }

  private async ensureBackgroundPatternsLoaded(): Promise<boolean> {
    if (!this.mapController) {
      showToast('地图未初始化');
      return false;
    }

    if (this.patternImagesLoaded) {
      return true;
    }

    const map = this.mapController;
    const style = map.getStyle();
    if (!style) {
      showToast('样式未加载');
      return false;
    }

    try {
      const context = getContext(this) as common.UIAbilityContext;
      const resourceMgr = context.resourceManager;

      for (const pattern of this.PATTERN_RESOURCES) {
        if (style.getImage(pattern.name)) {
          continue;
        }

        const rawResult = await resourceMgr.getRawFileContent(pattern.filename);
        if (!(rawResult instanceof Uint8Array)) {
          console.error(`加载背景图案失败: ${pattern.filename} 返回类型异常`);
          continue;
        }
        const rawContent: Uint8Array = rawResult;
        const arrayBuffer = new ArrayBuffer(rawContent.byteLength);
        const bufferView = new Uint8Array(arrayBuffer);
        bufferView.set(rawContent);
        const imageSource = image.createImageSource(arrayBuffer);
        let pixelMap: image.PixelMap | null = null;
        try {
          pixelMap = await imageSource.createPixelMap({
            desiredPixelFormat: image.PixelMapFormat.RGBA_8888
          });
        } finally {
          imageSource.release();
        }

        if (!pixelMap) {
          console.error(`加载背景图案失败: ${pattern.filename} PixelMap 创建失败`);
          continue;
        }

        try {
          map.addImage(pattern.name, pixelMap, 1.0, false);
        } finally {
          pixelMap.release();
        }
      }

      this.patternImagesLoaded = true;
      return true;
    } catch (error) {
      console.error('加载背景图案失败:', error);
      showToast(`加载背景图案失败: ${error}`);
      return false;
    }
  }

  private async changeBackgroundPattern(): Promise<void> {
    if (!this.mapController) return;

    const style = this.mapController.getStyle();
    if (!style) {
      showToast('样式未加载');
      return;
    }

    const loaded = await this.ensureBackgroundPatternsLoaded();
    if (!loaded) {
      return;
    }

    if (this.PATTERN_RESOURCES.length === 0) {
      showToast('未配置背景图案');
      return;
    }

    const pattern = this.PATTERN_RESOURCES[this.patternIndex % this.PATTERN_RESOURCES.length];
    this.patternIndex = (this.patternIndex + 1) % this.PATTERN_RESOURCES.length;

    const layers = this.mapController.getLayers();
    for (const layer of layers) {
      if (layer instanceof BackgroundLayer) {
        layer.setBackgroundPattern(pattern.name);
        showToast(`背景图案: ${pattern.label}`);
        return;
      }
    }

    showToast('未找到背景图层');
  }

  // 重置视图
  private resetView(): void {
    if (!this.mapController) return;
    
    this.mapController.jumpTo(0, 0, 0, 0, 2);
    showToast('视图已重置');
  }
}

