import { 
  LatLng, 
  Marker,
  Icon,
  MarkerOptions, 
  OnMarkerClickListener,
  OnMarkerSelectListener,
  NativeMapView,
  MapLibreMap,
  MapLibreMapOptions,
  AnnotationViewAdapter,
  AnnotationViewDelegate,
  AnnotationViewConfig,
  IconFactory,
  CameraOptions
} from 'maplibre_harmony';
import { TestPageLayout } from '../common/TestPageLayout';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { DEFAULT_MAP_CONFIG } from '../common/TestUtils';
import { MapView } from 'maplibre_harmony';
import { showToast, DEFAULT_STYLE_URLS, TEST_LOCATIONS, randomLatLng  } from '../common/TestUtils';

/**
 * AnnotationViewTestPage - AnnotationView 自定义视图测试页面
 * 
 * 测试功能：
 * 1. 基础自定义视图 - 使用自定义 Builder 创建不同样式的 Marker
 * 2. 视图复用 - 添加多个相同样式的 Marker，观察复用效果
 * 3. 可拖拽 Marker - 长按拖动，显示拖拽动画
 * 4. 视图变换：
 *    - scalesWithViewingDistance（倾斜地图观察缩放）
 *    - rotatesToMatchCamera（旋转地图观察旋转）
 * 5. 选中状态 - 点击 Marker 显示选中效果
 * 
 * 参考:
 * - iOS: MLNAnnotationView
 * - Android: Annotation View Examples
 */

interface TestMarkerData {
  lat: number;
  lng: number;
  type: string;
  title: string;
  subtitle?: string;
  description?: string;
  buttonLabel?: string;
  buttonActionText?: string;
  highlightColor?: string;
}

const STAR_ANNOTATION_POINTS: number[][] = [
  [50, 0],
  [62, 34],
  [98, 38],
  [72, 60],
  [82, 96],
  [50, 76],
  [18, 96],
  [28, 60],
  [2, 38],
  [38, 34]
];

/**
 * Marker 点击监听器
 */
class MarkerClickListenerImpl implements OnMarkerClickListener {
  private testPage: AnnotationViewTestPage;
  
  constructor(testPage: AnnotationViewTestPage) {
    this.testPage = testPage;
  }
  
  onMarkerClick(marker: Marker): boolean {
    const title = marker.getTitle() || 'Unknown';
    const pos = marker.getPosition();
    
    this.testPage.selectedMarkerId = marker.getId();
    this.testPage.statusMessage = `🎯 点击: ${title} (${pos.latitude.toFixed(4)}, ${pos.longitude.toFixed(4)})`;
    
    hilog.info(DOMAIN, 'AnnotationViewTest', `Marker clicked: ${title}`);
    
    promptAction.showToast({
      message: `点击: ${title}`,
      duration: 2000
    });
    
    return true;
  }
}

/**
 * Marker 选中监听器
 */
class MarkerSelectListenerImpl implements OnMarkerSelectListener {
  private testPage: AnnotationViewTestPage;
  
  constructor(testPage: AnnotationViewTestPage) {
    this.testPage = testPage;
  }
  
  onMarkerSelect(marker: Marker): void {
    const title = marker.getTitle() || 'Unknown';
    this.testPage.statusMessage = `✅ 选中: ${title}`;
    hilog.info(DOMAIN, 'AnnotationViewTest', `Marker selected: ${title}`);
  }
  
  onMarkerDeselect(marker: Marker): void {
    const title = marker.getTitle() || 'Unknown';
    this.testPage.statusMessage = `⭕ 取消选中: ${title}`;
    hilog.info(DOMAIN, 'AnnotationViewTest', `Marker deselected: ${title}`);
  }
}

/**
 * 自定义 AnnotationView 委托
 * 
 * 使用新的 Delegate API 提供自定义视图内容
 */
class TestAnnotationViewDelegate implements AnnotationViewDelegate {
  private testPage: AnnotationViewTestPage;
  
  constructor(testPage: AnnotationViewTestPage) {
    this.testPage = testPage;
  }
  
  viewForAnnotation(marker: Marker): AnnotationViewConfig | null {
    const type = marker.getSnippet();
    
    if (type === 'annotation-text') {
      return this.buildTextAnnotationConfig(marker);
    }

    if (type === 'annotation-button') {
      return this.buildButtonAnnotationConfig(marker);
    }

    if (type === 'annotation-star') {
      return this.buildStarAnnotationConfig(marker);
    }

    if (type === 'custom-pin') {
      // Pin 类型：配置高级特性
      const config: AnnotationViewConfig = {
        reuseIdentifier: 'custom-pin',
        draggable: this.testPage.testMode === 'draggable',
        scalesWithViewingDistance: this.testPage.scalesEnabled,
        rotatesToMatchCamera: this.testPage.rotatesEnabled,
        centerOffset: { dx: 0, dy: -24 },
        zIndex: 10
      };
      return config;
    } else if (type === 'custom-dot') {
      // Dot 类型：简单配置
      const config: AnnotationViewConfig = {
        reuseIdentifier: 'custom-dot',
        draggable: this.testPage.testMode === 'draggable',
        scalesWithViewingDistance: this.testPage.scalesEnabled,
        rotatesToMatchCamera: this.testPage.rotatesEnabled,
        centerOffset: { dx: 0, dy: -12 },
        zIndex: 5
      };
      return config;
    }
    
    // 其他类型使用默认图标
    return null;
  }

  private buildTextAnnotationConfig(marker: Marker): AnnotationViewConfig {
    return {
      reuseIdentifier: 'annotation-text',
      contentBuilder: this.testPage.createTextAnnotationBuilder(marker),
      draggable: this.testPage.testMode === 'draggable',
      scalesWithViewingDistance: this.testPage.scalesEnabled,
      rotatesToMatchCamera: this.testPage.rotatesEnabled,
      centerOffset: { dx: 0, dy: -56 },
      size: { width: 220, height: 120 },
      alpha: 1,
      zIndex: 18
    };
  }

  private buildButtonAnnotationConfig(marker: Marker): AnnotationViewConfig {
    return {
      reuseIdentifier: 'annotation-button',
      contentBuilder: this.testPage.createButtonAnnotationBuilder(marker),
      draggable: this.testPage.testMode === 'draggable',
      scalesWithViewingDistance: this.testPage.scalesEnabled,
      rotatesToMatchCamera: this.testPage.rotatesEnabled,
      centerOffset: { dx: 0, dy: -58 },
      size: { width: 240, height: 112 },
      alpha: 1,
      zIndex: 20
    };
  }

  private buildStarAnnotationConfig(marker: Marker): AnnotationViewConfig {
    return {
      reuseIdentifier: 'annotation-star',
      contentBuilder: this.testPage.createStarAnnotationBuilder(marker),
      draggable: this.testPage.testMode === 'draggable',
      scalesWithViewingDistance: this.testPage.scalesEnabled,
      rotatesToMatchCamera: this.testPage.rotatesEnabled,
      centerOffset: { dx: 0, dy: -72 },
      size: { width: 180, height: 160 },
      alpha: 1,
      zIndex: 24
    };
  }
  
  /**
   * 处理选中事件
   */
  didSelectAnnotationView(marker: Marker): void {
    const title = marker.getTitle() || 'Unknown';
    this.testPage.statusMessage = `✅ Delegate 选中: ${title}`;
    hilog.info(DOMAIN, 'AnnotationViewTest', `Delegate - Selected: ${title}`);
  }
  
  /**
   * 处理取消选中事件
   */
  didDeselectAnnotationView(marker: Marker): void {
    const title = marker.getTitle() || 'Unknown';
    this.testPage.statusMessage = `⭕ Delegate 取消选中: ${title}`;
    hilog.info(DOMAIN, 'AnnotationViewTest', `Delegate - Deselected: ${title}`);
  }
  
  /**
   * 处理拖拽开始事件
   */
  annotationViewWillStartDragging(marker: Marker): void {
    const title = marker.getTitle() || 'Unknown';
    this.testPage.statusMessage = `🔄 开始拖拽: ${title}`;
    // 可以在这里修改 Marker 样式
    marker.setAlpha(0.7);
  }
  
  /**
   * 处理拖拽结束事件
   */
  annotationViewDidEndDragging(marker: Marker, finalPosition: LatLng): void {
    const title = marker.getTitle() || 'Unknown';
    this.testPage.statusMessage = 
      `✓ 拖拽结束: ${title}\n新位置: (${finalPosition.latitude.toFixed(4)}, ${finalPosition.longitude.toFixed(4)})`;
    // 恢复 Marker 样式
    marker.setAlpha(1.0);
  }
  
  /**
   * 获取复用标识符
   */
  getReuseIdentifier(marker: Marker): string | undefined {
    const snippet = marker.getSnippet();
    return snippet || 'default';
  }
}

@Entry
@Component
struct AnnotationViewTestPage {
  @State statusMessage: string = '等待地图加载...';
  @State markerCount: number = 0;
  @State mapReady: boolean = false;
  @State testMode: string = 'basic'; // 'basic', 'draggable', 'transform'
  @State selectedMarkerId: number = -1;
  @State scalesEnabled: boolean = false;
  @State rotatesEnabled: boolean = false;
  @State autoFlyToMarkers: boolean = true; // 添加 Markers 后自动 flyTo
  @State currentIconTheme: string = 'all-random'; // 当前图标主题，默认为随机模式
  
  private mapLibreMap: MapLibreMap | null = null;
  private markerList: Marker[] = [];
  private markerLocations: TestMarkerData[] = [];
  // 使用新的 Delegate API（替代旧的 Adapter）
  private annotationViewDelegate: TestAnnotationViewDelegate | null = null;
  private iconFactory: IconFactory | null = null;
  // 存储所有可用的图标
  private markerIcons: Map<string, Icon> = new Map();

  aboutToDisappear() {
    hilog.info(DOMAIN, 'AnnotationViewTest', 'aboutToDisappear');
    if (this.mapLibreMap) {
      this.mapLibreMap.destroy();
    }
  }

  /**
   * 地图区域构建器
   */
  @Builder
  buildMapContent() {
    Stack() {
      MapView({
        styleUrl: DEFAULT_STYLE_URLS.bright,
        initialLatitude: 39.9,
        initialLongitude: 116.4,
        initialZoom: 5,
        initialBearing: 0,
        initialPitch: 0,
        onMapReady: this.onMapReady
      })
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 操作按钮构建器
   */
  @Builder
  buildActionButtons() {
    Scroll() {
      Column({ space: 12 }) {
        Text('AnnotationView 功能测试')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        Text('✨ 10 个自定义图标可选')
          .fontSize(11)
          .fontColor('#4caf50')
          .width('100%')
        
        Text('默认：蓝色图钉 + 绿色圆点 | 可切换主题或随机')
          .fontSize(11)
          .fontColor('#999')
          .width('100%')
        // 基础操作
        Text('基础操作')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .width('100%')
        
        Button('添加自定义 Markers')
          .width('100%')
          .onClick(() => {
            this.addCustomMarkers();
          })
        
        Button('清除所有 Markers')
          .width('100%')
          .onClick(() => {
            this.clearMarkers();
          })
        
        Row() {
          Text('添加后自动定位')
            .fontSize(14)
          .layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.autoFlyToMarkers })
            .onChange((isOn: boolean) => {
              this.autoFlyToMarkers = isOn;
            })
        }
        .width('100%')
        .backgroundColor('#f5f5f5')
        .borderRadius(8)
        .margin({ top: 8 })
        
        Divider()
          .margin({ top: 12, bottom: 12 })
        
        // 自定义视图测试
        Text('自定义视图测试')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .width('100%')
        Button('添加自定义视图')
          .width('100%')
          .onClick(() => {
            this.addCustomAnnotationViews();
          })
        
        Button('切换图标主题')
          .width('100%')
          .onClick(() => {
            this.switchIconTheme();
          })
        
        Text(`当前主题：${this.getIconThemeDescription()}`)
          .fontSize(11)
          .fontColor('#666')
          .width('100%')
        
        Row({ space: 8 }) {
          Button('加载全部图标')
            .layoutWeight(1)
            .fontSize(12)
            .onClick(() => {
              this.loadAllIcons();
            })
          
          Button('随机图标')
            .layoutWeight(1)
            .fontSize(12)
            .onClick(() => {
              this.applyRandomIcons();
            })
        }
        .width('100%')
        Divider()
          .margin({ top: 12, bottom: 12 })
        
        // 测试模式
        Text('测试模式')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .width('100%')
        Row({ space: 8 }) {
          Button('基础模式')
            .width('30%')
            .fontSize(12)
            .type(this.testMode === 'basic' ? ButtonType.Normal : ButtonType.Capsule)
            .onClick(() => {
              this.switchMode('basic');
            })
          
          Button('拖拽模式')
            .width('30%')
            .fontSize(12)
            .type(this.testMode === 'draggable' ? ButtonType.Normal : ButtonType.Capsule)
            .onClick(() => {
              this.switchMode('draggable');
            })
          
          Button('变换模式')
            .width('30%')
            .fontSize(12)
            .type(this.testMode === 'transform' ? ButtonType.Normal : ButtonType.Capsule)
          .onClick(() => {
              this.switchMode('transform');
          })
      }
      .width('100%')
        
        Divider()
          .margin({ top: 12, bottom: 12 })
        
        // 视图变换选项
        Text('视图变换选项')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .width('100%')
        Row() {
          Text('距离缩放')
            .fontSize(14)
            .layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.scalesEnabled })
            .onChange((isOn: boolean) => {
              this.scalesEnabled = isOn;
              this.updateMarkersTransform();
            })
        }
        .width('100%')
        .backgroundColor('#f5f5f5')
        .borderRadius(8)
        
        Text('启用后，Marker 会根据倾斜角度自动缩放')
          .fontSize(11)
          .fontColor('#999')
          .width('100%')
        Row() {
          Text('跟随旋转')
            .fontSize(14)
            .layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.rotatesEnabled })
            .onChange((isOn: boolean) => {
              this.rotatesEnabled = isOn;
              this.updateMarkersTransform();
            })
        }
        .width('100%')
        .backgroundColor('#f5f5f5')
        .borderRadius(8)
        .margin({ top: 8 })
        
        Text('启用后，Marker 会跟随地图旋转')
          .fontSize(11)
          .fontColor('#999')
          .width('100%')
        Divider()
          .margin({ top: 12, bottom: 12 })
        
        // 状态信息
        Text('状态信息')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .width('100%')
        Column({ space: 8 }) {
          Row() {
            Text('Markers: ')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
            Text(`${this.markerCount}`)
              .fontSize(12)
              .fontColor('#2196F3')
          }
          .width('100%')
          Row() {
            Text('模式: ')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
            Text(this.getModeDescription())
              .fontSize(12)
              .fontColor('#2196F3')
          }
          .width('100%')
          Row() {
            Text('选中: ')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
            Text(this.selectedMarkerId >= 0 ? `ID ${this.selectedMarkerId}` : '无')
              .fontSize(12)
              .fontColor('#2196F3')
          }
          .width('100%')
        }
        .width('100%')
        .backgroundColor('#e3f2fd')
        .borderRadius(8)
        .padding(12)
        
        Text(this.statusMessage)
          .fontSize(12)
          .fontColor('#666')
          .width('100%')
          .maxLines(4)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        Divider()
          .margin({ top: 12, bottom: 12 })
        
        // 功能说明
        Text('ℹ️ 功能说明')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .width('100%')
        Column({ space: 6 }) {
          Text('✅ 已实现：')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4CAF50')
            .width('100%')
          
          Text('• 真实添加/删除 Markers')
            .fontSize(10)
            .width('100%')
          
          Text('• 点击和选中事件')
            .fontSize(10)
            .width('100%')
          
          Text('• 拖拽模式切换')
            .fontSize(10)
            .width('100%')
          
          Text('• 飞行动画和定位')
            .fontSize(10)
            .width('100%')
          
          Text('• 自定义图标（10 个可选）')
            .fontSize(10)
            .width('100%')
          
          Text('• 图标主题切换')
            .fontSize(10)
            .width('100%')
          
          Text('• 随机图标应用')
            .fontSize(10)
            .width('100%')
          
          Text('🎉 新功能：')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2196F3')
            .width('100%')
            .margin({ top: 6 })
          
          Text('• AnnotationViewDelegate API')
            .fontSize(10)
            .width('100%')
          
          Text('• 距离缩放（scalesWithViewingDistance）')
            .fontSize(10)
            .width('100%')
          
          Text('• 跟随旋转（rotatesToMatchCamera）')
            .fontSize(10)
            .width('100%')
          
          Text('• 拖拽事件回调')
            .fontSize(10)
            .width('100%')
          
          Text('• 视图复用机制')
            .fontSize(10)
            .width('100%')
          
          Text('• 中心偏移配置（centerOffset）')
            .fontSize(10)
            .width('100%')
          
          Text('💡 提示：')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF9800')
            .width('100%')
            .margin({ top: 6 })
          
          Text('• 使用 Icon 实现自定义样式')
            .fontSize(10)
            .width('100%')
          
          Text('• Delegate 自动应用配置到 Marker')
            .fontSize(10)
            .width('100%')
          
          Text('• 倾斜地图观察距离缩放')
            .fontSize(10)
            .width('100%')
          
          Text('• 旋转地图观察跟随旋转')
            .fontSize(10)
            .width('100%')
          
          Text('⚠️ 限制：')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#F44336')
            .width('100%')
            .margin({ top: 6 })
          
          Text('• contentBuilder 暂不可用（ArkTS 限制）')
            .fontSize(10)
            .width('100%')
          
          Text('• 使用 Icon 作为替代方案')
            .fontSize(10)
            .width('100%')
        }
        .width('100%')
        .backgroundColor('#f9f9f9')
        .borderRadius(8)
        .padding(16)
      }
      .padding(16)
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }

  private onMapReady = async (map: MapLibreMap): Promise<void> => {
    try {
      this.mapLibreMap = map;
      
      this.mapReady = true;
      this.statusMessage = '✅ 地图已就绪 - 正在加载自定义图标...';
      
      // 设置事件监听器
      this.setupEventListeners();
      
      // 设置 AnnotationView 适配器（已在 MapLibreMap 中设置）
      // this.setupAnnotationViewAdapter();
      
      // 加载自定义图标（异步）
      await this.loadCustomIcons();
      
      hilog.info(DOMAIN, 'AnnotationViewTest', 'Map ready and listeners configured');
      
      promptAction.showToast({
        message: '地图已就绪',
        duration: 2000
      });
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to initialize: ${errorMsg}`);
      this.statusMessage = `❌ 初始化失败: ${errorMsg}`;
    }
  }

  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    if (!this.mapLibreMap) return;
    
    // 创建监听器实例
    const markerClickListener = new MarkerClickListenerImpl(this);
    const markerSelectListener = new MarkerSelectListenerImpl(this);
    
    // 设置监听器
    this.mapLibreMap.setOnMarkerClickListener(markerClickListener);
    this.mapLibreMap.setOnMarkerSelectListener(markerSelectListener);
    
    // 创建并设置 AnnotationView 委托（新API）
    this.annotationViewDelegate = new TestAnnotationViewDelegate(this);
    this.mapLibreMap.setAnnotationViewDelegate(this.annotationViewDelegate);
    
    hilog.info(DOMAIN, 'AnnotationViewTest', 'Event listeners and AnnotationView delegate configured');
  }

  /**
   * 加载自定义图标（根据主题）
   */
  private async loadCustomIcons(): Promise<void> {
    try {
      // 获取应用上下文和 ResourceManager
      const context = getContext(this) as common.UIAbilityContext;
      const resourceMgr = context.resourceManager;
      
      // 创建 IconFactory 实例
      this.iconFactory = IconFactory.getInstance(resourceMgr);
      
      // 根据当前主题加载不同的图标
      await this.loadIconsForTheme(this.currentIconTheme);
      
      this.statusMessage = '✅ 地图已就绪 - 自定义图标已加载！\n点击"添加自定义 Markers"开始测试';
      
      hilog.info(DOMAIN, 'AnnotationViewTest', `Custom icons loaded successfully (theme: ${this.currentIconTheme})`);
      
      promptAction.showToast({
        message: '自定义图标加载成功',
        duration: 2000
      });
    } catch (e) {
      const errorMsg = e instanceof Error ? e.message : String(e);
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to load custom icons: ${errorMsg}`);
      this.statusMessage = `⚠️ 图标加载失败，使用默认图标\n${errorMsg}`;
      
      // 即使图标加载失败，也不影响其他功能
      promptAction.showToast({
        message: '图标加载失败，使用默认图标',
        duration: 2000
      });
    }
  }

  /**
   * 根据主题加载图标
   */
  private async loadIconsForTheme(theme: string): Promise<void> {
    if (!this.iconFactory) {
      throw new Error('IconFactory not initialized');
    }
    
    // 清除旧图标
    this.markerIcons.clear();
    
    if (theme === 'all-random') {
      // 加载所有图标供随机选择
      await this.loadAllIconsInternal();
    } else {
      // 加载特定主题的图标
      switch (theme) {
        case 'blue-green':
          // 蓝色图钉 + 绿色圆点
          const bluePin = await this.iconFactory.fromResource(
            $r('app.media.marker_pin_blue'),
            'custom-pin'
          );
          this.markerIcons.set('custom-pin', bluePin);
          
          const greenDot = await this.iconFactory.fromResource(
            $r('app.media.marker_dot_green'),
            'custom-dot'
          );
          this.markerIcons.set('custom-dot', greenDot);
          break;
          
        case 'red-yellow':
          // 红色图钉 + 黄色圆点
          const redPin = await this.iconFactory.fromResource(
            $r('app.media.marker_pin_red'),
            'custom-pin'
          );
          this.markerIcons.set('custom-pin', redPin);
          
          const yellowDot = await this.iconFactory.fromResource(
            $r('app.media.marker_dot_yellow'),
            'custom-dot'
          );
          this.markerIcons.set('custom-dot', yellowDot);
          break;
          
        case 'orange-cyan':
          // 橙色图钉 + 青色圆点
          const orangePin = await this.iconFactory.fromResource(
            $r('app.media.marker_pin_orange'),
            'custom-pin'
          );
          this.markerIcons.set('custom-pin', orangePin);
          
          const cyanDot = await this.iconFactory.fromResource(
            $r('app.media.marker_dot_cyan'),
            'custom-dot'
          );
          this.markerIcons.set('custom-dot', cyanDot);
          break;
          
        case 'purple-blue':
          // 紫色图钉 + 蓝色圆点
          const purplePin = await this.iconFactory.fromResource(
            $r('app.media.marker_pin_purple'),
            'custom-pin'
          );
          this.markerIcons.set('custom-pin', purplePin);
          
          const blueDot = await this.iconFactory.fromResource(
            $r('app.media.marker_dot_blue'),
            'custom-dot'
          );
          this.markerIcons.set('custom-dot', blueDot);
          break;
      }
    }
    
    hilog.info(DOMAIN, 'AnnotationViewTest', `Loaded icons for theme: ${theme}`);
  }

  /**
   * 内部方法：加载所有图标
   */
  private async loadAllIconsInternal(): Promise<void> {
    if (!this.iconFactory) return;
    
    // 加载所有 Pin 图标
    const pinColors = ['red', 'blue', 'green', 'orange', 'purple']
    for (const color of pinColors) {
      const icon = await this.iconFactory.fromResource(
        $r(`app.media.marker_pin_${color}`),
        `pin-${color}`
      );
      this.markerIcons.set(`pin-${color}`, icon);
    }
    
    // 加载所有 Dot 图标
    const dotColors = ['red', 'blue', 'green', 'yellow', 'cyan']
    for (const color of dotColors) {
      const icon = await this.iconFactory.fromResource(
        $r(`app.media.marker_dot_${color}`),
        `dot-${color}`
      );
      this.markerIcons.set(`dot-${color}`, icon);
    }
  }

  /**
   * 切换图标主题
   */
  private async switchIconTheme(): Promise<void> {
    const themes = ['all-random', 'blue-green', 'red-yellow', 'orange-cyan', 'purple-blue']
    const currentIndex = themes.indexOf(this.currentIconTheme);
    const nextIndex = (currentIndex + 1) % themes.length;
    this.currentIconTheme = themes[nextIndex]
    
    this.statusMessage = '正在切换图标主题...';
    
    try {
      // 重新加载图标
      await this.loadIconsForTheme(this.currentIconTheme);
      
      // 如果有 Markers，重新应用图标
      if (this.markerList.length > 0) {
        if (this.currentIconTheme === 'all-random') {
          // 随机主题：为每个 Marker 随机分配图标
          await this.applyRandomIconsToMarkers();
        } else {
          // 固定主题：根据类型应用图标
          await this.reapplyIcons();
        }
      }
      
      this.statusMessage = `✅ 已切换到：${this.getIconThemeDescription()}`;
      
      promptAction.showToast({
        message: `主题：${this.getIconThemeDescription()}`,
        duration: 2000
      });
      
      hilog.info(DOMAIN, 'AnnotationViewTest', `Switched to theme: ${this.currentIconTheme}`);
    } catch (e) {
      const errorMsg = e instanceof Error ? e.message : String(e);
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to switch theme: ${errorMsg}`);
      this.statusMessage = `❌ 切换失败: ${errorMsg}`;
    }
  }

  /**
   * 加载所有可用图标（10个）- 公开方法
   */
  private async loadAllIcons(): Promise<void> {
    if (!this.iconFactory) {
      this.statusMessage = 'IconFactory 未初始化';
      return;
    }
    
    this.statusMessage = '正在加载所有图标...';
    
    try {
      // 清除旧图标
      this.markerIcons.clear();
      
      await this.loadAllIconsInternal();
      
      // 设置为随机主题
      this.currentIconTheme = 'all-random';
      
      this.statusMessage = `✅ 已加载全部 10 个图标！\n5 个 Pin + 5 个 Dot\n主题已切换为"随机模式"`;
      
      promptAction.showToast({
        message: '已加载全部 10 个图标',
        duration: 2000
      });
      
      hilog.info(DOMAIN, 'AnnotationViewTest', `Loaded all ${this.markerIcons.size} icons`);
    } catch (e) {
      const errorMsg = e instanceof Error ? e.message : String(e);
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to load all icons: ${errorMsg}`);
      this.statusMessage = `❌ 加载失败: ${errorMsg}`;
    }
  }

  /**
   * 为 Markers 应用随机图标（按钮触发）
   */
  private async applyRandomIcons(): Promise<void> {
    if (this.markerList.length === 0) {
      this.statusMessage = '请先添加 Markers';
      promptAction.showToast({
        message: '请先添加 Markers',
        duration: 2000
      });
      return;
    }
    
    if (this.markerIcons.size === 0) {
      this.statusMessage = '请先加载全部图标';
      promptAction.showToast({
        message: '请先点击"加载全部图标"',
        duration: 2000
      });
      return;
    }
    
    await this.applyRandomIconsToMarkers();
  }

  /**
   * 为 Markers 应用随机图标（内部方法）
   */
  private async applyRandomIconsToMarkers(): Promise<void> {
    try {
      const availableIconIds: string[] = Array.from(this.markerIcons.values()).map((icon: Icon) => icon.getId());
      
      if (availableIconIds.length === 0) {
        hilog.warn(DOMAIN, 'AnnotationViewTest', 'No icons available for random assignment');
        return;
      }
      
      for (const marker of this.markerList as Marker[]) {
        // 随机选择一个图标 ID
        const randomIconId: string = availableIconIds[Math.floor(Math.random() * availableIconIds.length)]
        marker.setIcon(randomIconId);
      }
      
      // 通过 MapLibreMap 更新，触发视图刷新
      if (this.mapLibreMap) {
        for (const marker of this.markerList) {
          this.mapLibreMap.updateMarker(marker);
        }
      }
      
      this.statusMessage = `✅ 已为 ${this.markerList.length} 个 Markers 应用随机图标\n从 ${this.markerIcons.size} 个图标中随机选择`;
      
      promptAction.showToast({
        message: '随机图标已应用',
        duration: 2000
      });
      
      hilog.info(DOMAIN, 'AnnotationViewTest', 'Applied random icons to all markers');
    } catch (e) {
      const errorMsg = e instanceof Error ? e.message : String(e);
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to apply random icons: ${errorMsg}`);
      this.statusMessage = `❌ 应用失败: ${errorMsg}`;
    }
  }

  /**
   * 重新应用当前主题的图标到所有 Markers
   */
  private async reapplyIcons(): Promise<void> {
    if (!this.mapLibreMap) return;
    
    try {
      for (let i = 0; i < this.markerList.length; i++) {
        const marker: Marker = this.markerList[i]
        const loc = this.markerLocations[i]
        
        const customIcon: Icon | undefined = this.markerIcons.get(loc.type);
        if (customIcon) {
          // 设置图标 ID
          marker.setIcon(customIcon.getId());
          // 更新 Marker
          this.mapLibreMap.updateMarker(marker);
        }
      }
      
      hilog.info(DOMAIN, 'AnnotationViewTest', 'Reapplied icons to all markers');
    } catch (e) {
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to reapply icons: ${e}`);
    }
  }

  /**
   * 获取图标主题描述
   */
  private getIconThemeDescription(): string {
    switch (this.currentIconTheme) {
      case 'all-random':
        return '随机模式（10 个图标）';
      case 'blue-green':
        return '蓝色图钉 + 绿色圆点';
      case 'red-yellow':
        return '红色图钉 + 黄色圆点';
      case 'orange-cyan':
        return '橙色图钉 + 青色圆点';
      case 'purple-blue':
        return '紫色图钉 + 蓝色圆点';
      default:
        return '未知主题';
    }
  }

  /**
   * 添加自定义 Markers
   */
  private async addCustomMarkers(): Promise<void> {
    if (!this.mapLibreMap) {
      this.statusMessage = '地图未就绪';
      promptAction.showToast({
        message: '地图未就绪',
        duration: 2000
      });
      return;
    }
    
    // 清除现有的
    await this.clearMarkers();
    
    // 中国主要城市测试点（分布范围更大）
    this.markerLocations = [
      { lat: 39.9042, lng: 116.4074, type: 'custom-pin', title: '北京' },
      { lat: 31.2304, lng: 121.4737, type: 'custom-dot', title: '上海' },
      { lat: 23.1291, lng: 113.2644, type: 'custom-pin', title: '广州' },
      { lat: 30.5728, lng: 104.0668, type: 'custom-dot', title: '成都' },
    ]
    
    let addedCount = 0;
    
    try {
      for (const loc of this.markerLocations) {
        // 创建 MarkerOptions，根据类型设置不同的视觉属性
        const options = new MarkerOptions()
          .position(new LatLng(loc.lat, loc.lng))
          .title(loc.title)
          .snippet(loc.type)
          .draggable(this.testMode === 'draggable');
        
        // 根据主题设置图标
        if (this.currentIconTheme === 'all-random' && this.markerIcons.size > 0) {
          // 随机模式：从所有图标中随机选择
          const availableIcons: Icon[] = Array.from(this.markerIcons.values());
          const randomIcon: Icon = availableIcons[Math.floor(Math.random() * availableIcons.length)]
          options.icon(randomIcon)
            .alpha(1.0)
            .zIndex(Math.floor(Math.random() * 20));
        } else {
          // 固定主题：根据类型选择图标
          const customIcon: Icon | undefined = this.markerIcons.get(loc.type);
          if (customIcon) {
            // 使用自定义图标
            options.icon(customIcon)
              .alpha(1.0)
              .zIndex(loc.type === 'custom-pin' ? 10 : 5);
          } else {
            // 如果图标未加载，使用默认图标并通过旋转区分
            if (loc.type === 'custom-pin') {
              options.alpha(1.0).rotation(0).zIndex(10);
            } else {
              options.alpha(0.85).rotation(45).zIndex(5);
            }
          }
        }
        
        // 添加 Marker
        const marker = await this.mapLibreMap.addMarker(options);
        this.markerList.push(marker);
        addedCount++;
        
        hilog.info(DOMAIN, 'AnnotationViewTest', 
          `Added marker: ${loc.title} (${loc.type}) at (${loc.lat}, ${loc.lng}), ID=${marker.getId()}`);
      }
      
      this.markerCount = addedCount;
      const hasCustomIcons = this.markerIcons.size > 0;
      const iconStatus = hasCustomIcons ? '使用自定义图标' : '使用默认图标';
      
      let iconDescription = '';
      if (this.currentIconTheme === 'all-random') {
        iconDescription = '每个 Marker 使用随机图标';
      } else if (hasCustomIcons) {
        iconDescription = `Pin类型（北京/广州）+ Dot类型（上海/成都）`;
      } else {
        iconDescription = '使用默认红点图标';
      }
      
      this.statusMessage = `✅ 已添加 ${addedCount} 个 Markers（${iconStatus}）\n` +
                          `${iconDescription}\n` +
                          `当前主题: ${this.getIconThemeDescription()}\n` +
                          (this.testMode === 'draggable' ? '长按可拖拽' : '点击可选中');
      
      promptAction.showToast({
        message: `成功添加 ${addedCount} 个 Markers`,
        duration: 2000
      });
      
      // 自动飞到 Markers 位置
      if (this.autoFlyToMarkers && addedCount > 0) {
        setTimeout(() => {
          this.flyToAllMarkers();
        }, 500);
      }
    } catch (e) {
      const errorMsg = e instanceof Error ? e.message : String(e);
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to add markers: ${errorMsg}`);
      this.statusMessage = `❌ 添加失败: ${errorMsg}`;
      
      promptAction.showToast({
        message: `添加失败: ${errorMsg}`,
        duration: 2000
      });
    }
  }

  /**
   * 添加自定义视图（使用 AnnotationView）
   */
  private async addCustomAnnotationViews(): Promise<void> {
    if (!this.mapLibreMap) {
      this.statusMessage = 'MapLibreMap 未初始化';
      return;
    }
    
    this.statusMessage = '正在添加自定义视图...';
    
    try {
      await this.clearMarkers();

      const customAnnotations: TestMarkerData[] = [
        {
          lat: 39.9042,
          lng: 116.4074,
          type: 'annotation-text',
          title: '北京 · 文本标签',
          subtitle: '首都建筑与文化地标',
          description: '使用 Column + Text 展示细节信息'
        },
        {
          lat: 31.2304,
          lng: 121.4737,
          type: 'annotation-button',
          title: '上海 · 交互按钮',
          description: '点击按钮触发自定义事件',
          buttonLabel: '查看详情',
          buttonActionText: '来自按钮类型的交互'
        },
        {
          lat: 30.5728,
          lng: 104.0668,
          type: 'annotation-star',
          title: '成都 · 五角星徽章',
          description: 'ArkUI Polygon 绘制五角星',
          highlightColor: '#FFB300'
        }
      ];

      this.markerLocations = customAnnotations;

      let addedCount = 0;
      const baseZIndex = 20;

      for (let i = 0; i < customAnnotations.length; i++) {
        const sample = customAnnotations[i];
        const options = new MarkerOptions()
          .position(new LatLng(sample.lat, sample.lng))
          .title(sample.title)
          .snippet(sample.type)
          .draggable(this.testMode === 'draggable')
          .alpha(1.0)
          .zIndex(baseZIndex + i);

        const marker = await this.mapLibreMap.addMarker(options);
        this.markerList.push(marker);
        addedCount++;

        hilog.info(
          DOMAIN,
          'AnnotationViewTest',
          `Added custom annotation marker: ${sample.title} (${sample.type}) id=${marker.getId()}`
        );
      }

      this.markerCount = addedCount;

      this.statusMessage = '✅ 自定义 AnnotationView 已添加\n' +
                          '包含: 文本标签 / 按钮卡片 / 五角星徽章';

      promptAction.showToast({
        message: '已添加自定义 AnnotationView',
        duration: 2000
      });

      if (this.autoFlyToMarkers && addedCount > 0) {
        setTimeout(() => {
          this.flyToAllMarkers();
        }, 500);
      }

      hilog.info(DOMAIN, 'AnnotationViewTest', 'Custom annotation views added via customContentBuilder');
    } catch (e) {
      const errorMsg = e instanceof Error ? e.message : String(e);
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to add custom annotation views: ${errorMsg}`);
      this.statusMessage = `❌ 添加失败: ${errorMsg}`;
      
      promptAction.showToast({
        message: `添加失败: ${errorMsg}`,
        duration: 2000
      });
    }
  }

  /**
   * 清除所有 Markers
   */
  private async clearMarkers(): Promise<void> {
    if (!this.mapLibreMap) {
      return;
    }
    
    try {
      // 移除所有 Markers
      for (const marker of this.markerList) {
        await this.mapLibreMap.removeMarker(marker);
      }
      
      this.markerList = [];
      this.markerLocations = [];
      this.markerCount = 0;
      this.selectedMarkerId = -1;
      this.statusMessage = '已清除所有 Markers';
      
      hilog.info(DOMAIN, 'AnnotationViewTest', 'Cleared all markers');
      
      promptAction.showToast({
        message: '已清除所有 Markers',
        duration: 2000
      });
    } catch (e) {
      const errorMsg = e instanceof Error ? e.message : String(e);
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to clear markers: ${errorMsg}`);
    }
  }

  /**
   * 刷新所有自定义 AnnotationView
   */
  private refreshAnnotationViews(): void {
    if (!this.mapLibreMap || this.markerList.length === 0) {
      return;
    }

    try {
      const annotationManager = this.mapLibreMap
        .getMarkerManager()
        .getAnnotationViewManager();

      this.markerList.forEach(marker => {
        annotationManager.createOrUpdateView(marker);
      });

      hilog.info(
        DOMAIN,
        'AnnotationViewTest',
        `Refreshed annotation views for ${this.markerList.length} markers`
      );
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN, 'AnnotationViewTest', `refreshAnnotationViews failed: ${errorMsg}`);
    }
  }

  public getMarkerDataById(markerId: number): TestMarkerData | undefined {
    const index = this.markerList.findIndex((marker: Marker) => marker.getId() === markerId);
    if (index >= 0 && index < this.markerLocations.length) {
      return this.markerLocations[index];
    }
    return undefined;
  }

  public createTextAnnotationBuilder(marker: Marker): () => void {
    const markerData = this.getMarkerDataById(marker.getId());
    const title = marker.getTitle() || '文本标签';
    const subtitle = markerData?.subtitle ?? '自定义文本视图';
    const description = markerData?.description ?? '使用 customContentBuilder 渲染文本内容。';
    const position = marker.getPosition();
    const coordinateText = `经纬度: ${position.latitude.toFixed(3)}, ${position.longitude.toFixed(3)}`;
    return () => {
      this.renderTextAnnotationContent(title, subtitle, description, coordinateText);
    };
  }

  public createButtonAnnotationBuilder(marker: Marker): () => void {
    const markerData = this.getMarkerDataById(marker.getId());
    const title = marker.getTitle() || '交互按钮';
    const description = markerData?.description ?? '点击下面的按钮触发交互。';
    const buttonLabel = markerData?.buttonLabel ?? '立即执行';
    const actionText = markerData?.buttonActionText ?? '按钮类型 AnnotationView 已被点击';
    return () => {
      this.renderButtonAnnotationContent(marker, title, description, buttonLabel, actionText);
    };
  }

  public createStarAnnotationBuilder(marker: Marker): () => void {
    const markerData = this.getMarkerDataById(marker.getId());
    const title = marker.getTitle() || '五角星徽章';
    const description = markerData?.description ?? 'Polygon 生成的五角星示例。';
    const position = marker.getPosition();
    const positionText = `位置: ${position.latitude.toFixed(2)}°, ${position.longitude.toFixed(2)}°`;
    const fillColor = markerData?.highlightColor ?? '#FFC107';
    return () => {
      this.renderStarAnnotationContent(title, description, positionText, fillColor);
    };
  }

  @Builder
  private renderTextAnnotationContent(title: string, subtitle: string, description: string, coordinateText: string) {
    Column({ space: 6 }) {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .width('100%');

      Text(subtitle)
        .fontSize(12)
        .fontColor('rgba(255,255,255,0.85)')
        .width('100%');

      Text(description)
        .fontSize(12)
        .fontColor('rgba(255,255,255,0.9)')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%');

      Text(coordinateText)
        .fontSize(11)
        .fontColor('rgba(255,255,255,0.7)')
        .width('100%');
    }
    .padding(14)
    .backgroundColor('rgba(33, 150, 243, 0.92)')
    .borderRadius(12)
    .shadow({ radius: 8, color: 'rgba(33,150,243,0.35)', offsetX: 0, offsetY: 4 });
  }

  @Builder
  private renderButtonAnnotationContent(marker: Marker, title: string, description: string, buttonLabel: string, actionText: string) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1A237E')
        .width('100%');

      Text(description)
        .fontSize(12)
        .fontColor('#3F51B5')
        .opacity(0.85)
        .width('100%');

      Button(buttonLabel)
        .type(ButtonType.Capsule)
        .fontSize(12)
        .onClick(() => {
          this.statusMessage = `🟢 按钮点击: ${marker.getTitle() || '未知标记'}`;
          promptAction.showToast({
            message: actionText,
            duration: 2000
          });
          hilog.info(DOMAIN, 'AnnotationViewTest', `Button annotation clicked: ${marker.getTitle()}`);
        });
    }
    .padding(16)
    .backgroundColor('rgba(227, 242, 253, 0.95)')
    .borderRadius(16)
    .shadow({ radius: 10, color: 'rgba(25,118,210,0.25)', offsetX: 0, offsetY: 6 });
  }

  @Builder
  private renderStarAnnotationContent(title: string, description: string, positionText: string, fillColor: string) {
    Column({ space: 8 }) {
      Stack() {
        Polygon()
          .points(STAR_ANNOTATION_POINTS)
          .fill(fillColor)
          .width(110)
          .height(110)
          .shadow({ radius: 12, color: 'rgba(0,0,0,0.25)', offsetX: 0, offsetY: 6 });

        Column() {
          Text('★')
            .fontSize(38)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Bold);
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);
      }
      .width(110)
      .height(110);

      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#4E342E')
        .width('100%');

      Text(description)
        .fontSize(12)
        .fontColor('#6D4C41')
        .opacity(0.9)
        .width('100%');

      Text(positionText)
        .fontSize(11)
        .fontColor('#795548')
        .width('100%');
    }
    .padding(14)
    .backgroundColor('rgba(255, 248, 225, 0.95)')
    .borderRadius(18)
    .shadow({ radius: 14, color: 'rgba(255, 179, 0, 0.35)', offsetX: 0, offsetY: 8 });
  }

  /**
   * 飞到所有 Markers（计算边界并显示所有 Markers）
   */
  private flyToAllMarkers(): void {
    if (!this.mapLibreMap || this.markerLocations.length === 0) {
      this.statusMessage = '没有可飞往的 Markers';
      promptAction.showToast({
        message: '请先添加 Markers',
        duration: 2000
      });
      return;
    }
    
    try {
      // 计算所有 Markers 的中心点
      let totalLat = 0;
      let totalLng = 0;
      
      this.markerLocations.forEach((loc: TestMarkerData) => {
        totalLat += loc.lat;
        totalLng += loc.lng;
      });
      
      const centerLat = totalLat / this.markerLocations.length;
      const centerLng = totalLng / this.markerLocations.length;
      
      // 使用 flyTo 方法飞到中心点（缩小 zoom 以显示更大范围）
      const options: CameraOptions = {
        center: LatLng.create(centerLat, centerLng),
        zoom: 5
      };
      this.mapLibreMap.flyTo(options, 2000);
      
      this.statusMessage = `飞往 ${this.markerLocations.length} 个 Markers 的中心位置\n` +
                          `中心坐标: (${centerLat.toFixed(4)}, ${centerLng.toFixed(4)})`;
      
      promptAction.showToast({
        message: '飞往所有 Markers',
        duration: 2000
      });
      
      hilog.info(DOMAIN, 'AnnotationViewTest', 
        `Flying to center: (${centerLat}, ${centerLng})`);
    } catch (e) {
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to fly to markers: ${e}`);
      this.statusMessage = `飞行失败: ${e}`;
    }
  }

  /**
   * 飞到指定索引的 Marker
   */
  private flyToMarkerByIndex(index: number): void {
    if (!this.mapLibreMap || index < 0 || index >= this.markerLocations.length) {
      this.statusMessage = 'Marker 不存在';
      promptAction.showToast({
        message: `Marker ${index + 1} 不存在`,
        duration: 2000
      });
      return;
    }
    
    try {
      const loc = this.markerLocations[index]
      
      // 飞到指定 Marker，zoom 10，动画时长 2000ms
      const options: CameraOptions = {
        center: LatLng.create(loc.lat, loc.lng),
        zoom: 10
      };
      this.mapLibreMap.flyTo(options, 2000);
      
      // 如果有对应的 Marker 对象，选中它
      if (index < this.markerList.length) {
        const marker = this.markerList[index]
        this.selectedMarkerId = marker.getId();
      }
      
      this.statusMessage = `飞往 ${loc.title}\n` +
                          `坐标: (${loc.lat.toFixed(4)}, ${loc.lng.toFixed(4)})`;
      
      promptAction.showToast({
        message: `飞往: ${loc.title}`,
        duration: 2000
      });
      
      hilog.info(DOMAIN, 'AnnotationViewTest', 
        `Flying to marker ${index}: ${loc.title} at (${loc.lat}, ${loc.lng})`);
    } catch (e) {
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to fly to marker: ${e}`);
      this.statusMessage = `飞行失败: ${e}`;
    }
  }

  /**
   * 逐个飞往 Markers（循环展示）
   */
  private flyToMarkersSequentially(): void {
    if (!this.mapLibreMap || this.markerLocations.length === 0) {
      this.statusMessage = '没有可飞往的 Markers';
      promptAction.showToast({
        message: '请先添加 Markers',
        duration: 2000
      });
      return;
    }
    
    this.statusMessage = '开始逐个飞行展示...';
    
    // 使用递归实现顺序飞行
    const flyToNext = (index: number) => {
      if (index >= this.markerLocations.length) {
        // 所有 Markers 飞行完成，回到中心
        setTimeout(() => {
          this.flyToAllMarkers();
        }, 3000);
        return;
      }
      
      // 飞到当前 Marker
      this.flyToMarkerByIndex(index);
      
      // 3秒后飞到下一个
      setTimeout(() => {
        flyToNext(index + 1);
      }, 3000);
    };
    
    // 从第一个 Marker 开始
    flyToNext(0);
    
    promptAction.showToast({
      message: '开始逐个飞行展示',
      duration: 2000
    });
    
    hilog.info(DOMAIN, 'AnnotationViewTest', 'Starting sequential flyTo');
  }

  /**
   * 切换测试模式
   */
  private switchMode(mode: string): void {
    this.testMode = mode;
    
    // 如果有 Markers，重新应用拖拽属性
    if (this.markerList.length > 0) {
      const isDraggable = (mode === 'draggable');
      this.markerList.forEach(marker => {
        marker.setDraggable(isDraggable);
      });
    }

    this.refreshAnnotationViews();
    
    this.statusMessage = `已切换到${this.getModeDescription()}`;
    
    hilog.info(DOMAIN, 'AnnotationViewTest', `Switched to mode: ${mode}`);
    
    promptAction.showToast({
      message: `模式：${this.getModeDescription()}`,
      duration: 2000
    });
  }
  
  /**
   * 更新 Markers 变换
   */
  private updateMarkersTransform(): void {
    const scalesStr = this.scalesEnabled ? '启用' : '禁用';
    const rotatesStr = this.rotatesEnabled ? '启用' : '禁用';
    
    this.statusMessage = `距离缩放: ${scalesStr}\n跟随旋转: ${rotatesStr}\n` +
                        `倾斜或旋转地图查看效果`;

    this.refreshAnnotationViews();

    hilog.info(
      DOMAIN,
      'AnnotationViewTest',
      `Transform updated - scales: ${this.scalesEnabled}, rotates: ${this.rotatesEnabled}`
    );
  }

  /**
   * 设置地图倾斜角度
   */
  private setPitch(pitch: number): void {
    if (!this.mapLibreMap) {
      return;
    }
    
    try {
      this.mapLibreMap.setPitch(pitch, 500);
      
      this.statusMessage = `地图倾斜至 ${pitch}°\n` +
                          (this.scalesEnabled ? 'Marker 会根据距离自动缩放' : '未启用距离缩放');
      
    promptAction.showToast({
        message: `倾斜: ${pitch}°`,
        duration: 2000
      });
      
      hilog.info(DOMAIN, 'AnnotationViewTest', `Set pitch: ${pitch}`);
    } catch (e) {
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to set pitch: ${e}`);
    }
  }

  /**
   * 设置地图旋转角度
   */
  private setBearing(bearing: number): void {
    if (!this.mapLibreMap) {
      return;
    }
    
    try {
      // 使用 setBearing 方法
      this.mapLibreMap.setBearing(bearing, 500);
      
      this.statusMessage = `地图旋转至 ${bearing}°\n` +
                          (this.rotatesEnabled ? 'Marker 会跟随地图旋转' : '未启用跟随旋转');
      
      promptAction.showToast({
        message: `旋转: ${bearing}°`,
        duration: 2000
      });
      
      hilog.info(DOMAIN, 'AnnotationViewTest', `Set bearing: ${bearing}`);
    } catch (e) {
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to set bearing: ${e}`);
    }
  }

  /**
   * 恢复正常视角
   */
  private resetCamera(): void {
    if (!this.mapLibreMap) {
      return;
    }
    
    try {
      // 使用 easeTo 方法重置视角（中国中心）
      const options: CameraOptions = {
        center: LatLng.create(35.0, 105.0),
        zoom: 5,
        bearing: 0,
        pitch: 0
      };
      this.mapLibreMap.easeTo(options, 1000);
      
      this.statusMessage = '相机已恢复正常视角';
      
    promptAction.showToast({
        message: '已恢复正常视角',
      duration: 2000
    });
      
      hilog.info(DOMAIN, 'AnnotationViewTest', 'Camera reset');
    } catch (e) {
      hilog.error(DOMAIN, 'AnnotationViewTest', `Failed to reset camera: ${e}`);
    }
  }

  /**
   * 获取模式描述
   */
  private getModeDescription(): string {
    switch (this.testMode) {
      case 'basic':
        return '基础模式 - 展示自定义视图和选中效果';
      case 'draggable':
        return '拖拽模式 - 长按可拖拽 Marker';
      case 'transform':
        return '变换模式 - 观察缩放和旋转效果';
      default:
        return '未知模式';
    }
  }

  build() {
    Column() {
      TestPageLayout({
        showActionBar: true,
        title: 'AnnotationView 测试',
        mapContent: (): void => this.buildMapContent(),
        actionButtons: (): void => this.buildActionButtons()
      })
    }
    .width('100%')
    .height('100%')
  }
}
